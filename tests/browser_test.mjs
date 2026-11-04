// Verhaltensprüfungen im echten Browser (S73-Nachgang).
//
// Was der Quelltext nicht zeigt, zeigt nur ein Browser: ob die Eingabetaste
// anmeldet und ob die Hilfe vor der Anmeldung erreichbar ist. Diese Datei
// startet einen Chromium ohne Fenster, liefert frontend/ über einen kleinen
// Ersatz-Server aus (die API antwortet mit festen Antworten, keine Datenbank)
// und steuert die Seite über das DevTools-Protokoll mit ECHTEN Tasten- und
// Mausereignissen – nicht mit element.click() oder form.submit(). Gemessen
// wird, was danach passiert: welche Anfragen der Server bekommt, was sichtbar
// ist.
//
// Aufruf: node tests/browser_test.mjs [frontend-Verzeichnis]
// Chromium: $CHROME, sonst Google Chrome, sonst der headless shell aus dem
// Playwright-Cache. Fehlt jeder, endet die Datei mit „ÜBERSPRUNGEN“ und
// Exit 3 – sichtbar, nicht grün.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import http from 'node:http';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawn } from 'node:child_process';

const FE = path.resolve(process.argv[2] || new URL('../frontend', import.meta.url).pathname);

function findeChrome() {
  const kandidaten = [process.env.CHROME,
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/chromium', '/usr/bin/chromium-browser', '/usr/bin/google-chrome'];
  const cache = path.join(os.homedir(), 'Library/Caches/ms-playwright');
  try {
    for (const d of fs.readdirSync(cache).filter(n => n.startsWith('chromium_headless_shell-')).sort().reverse())
      for (const u of fs.readdirSync(path.join(cache, d)))
        kandidaten.push(path.join(cache, d, u, 'chrome-headless-shell'));
  } catch { /* kein Cache */ }
  return kandidaten.find(k => k && fs.existsSync(k));
}

const CHROME = findeChrome();
if (!CHROME) { console.log('  ÜBERSPRUNGEN: kein Chromium gefunden ($CHROME setzen)'); process.exit(3); }

let gruen = 0, rot = 0;
const pruefe = (ok, text, warum = '') => {
  if (ok) { gruen++; console.log('  ✓ ' + text); }
  else    { rot++;   console.log('  ✗ ' + text + (warum ? ' – ' + warum : '')); }
};

// ---- Ersatz-Server ---------------------------------------------------
// Antwort auf auth/login je Lauf umschaltbar: 'ok' oder 'falsch'.
let LOGIN = 'ok';
const anfragen = [];
const MIME = { html: 'text/html; charset=utf-8', js: 'application/javascript', css: 'text/css', svg: 'image/svg+xml' };
const srv = http.createServer((q, r) => {
  const u = new URL(q.url, 'http://x').pathname;
  if (u.startsWith('/api/')) {
    anfragen.push(q.method + ' ' + u);
    const json = (status, body) => { r.writeHead(status, { 'Content-Type': 'application/json' }); r.end(JSON.stringify(body)); };
    if (u === '/api/auth/login') {
      if (LOGIN === 'schueler')    // Schülermodus (Z1): Antwort wie die Schüleranmeldung, Daten ERFUNDEN
        return json(200, { ok: true, typ: 'schueler', rolle: 'schueler', id: 157, vorname: 'Probe', nachname: 'Schueler' });
      return LOGIN === 'ok' ? json(200, { typ: 'lehrer', rolle: 'lehrer', vorname: 'Erika', nachname: 'Muster' })
                            : json(401, { error: 'Ungültige Anmeldedaten.' });
    }
    if (u === '/api/schueler-portal')
      return json(200, { werkstaetten: [{ id: 71, name: 'Probewerkstatt', datum_von: '2031-09-01', datum_bis: null,
        status: 'aktiv', kompetenzen_anzahl: 1, abgeschlossen: 0, lernbegleiter: 'Probe' }] });
    if (u === '/api/schueler-portal/71')
      return json(200, { id: 71, name: 'Probewerkstatt', datum_von: '2031-09-01', datum_bis: null, status: 'aktiv',
        kompetenzen: [{ kompetenz_id: 5, code: 'P1', kompetenz_name: 'Probekompetenz', bereich_name: 'Probebereich',
                        fremd_stufe: null, selbst_stufe: null }], rueckmeldungen: [] });
    if (u === '/api/auth/me') return json(401, { error: 'Nicht angemeldet' });
    if (u === '/api/einstellungen/logo') { r.writeHead(404); return r.end(); }
    return json(200, u === '/api/einstellungen' ? {} : []);
  }
  const f = path.join(FE, u === '/' ? 'index.html' : u);
  if (!f.startsWith(FE + path.sep) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { r.writeHead(404); return r.end(); }
  r.writeHead(200, { 'Content-Type': MIME[f.split('.').pop()] || 'application/octet-stream' });
  r.end(fs.readFileSync(f));
});
await new Promise(res => srv.listen(0, '127.0.0.1', res));
const BASIS = `http://127.0.0.1:${srv.address().port}/`;

// ---- Browser ---------------------------------------------------------
const profil = fs.mkdtempSync(path.join(os.tmpdir(), 'ps-browser-'));
const chrome = spawn(CHROME, ['--headless=new', '--remote-debugging-port=0', '--no-first-run',
  '--user-data-dir=' + profil, '--window-size=1280,900', 'about:blank'], { stdio: ['ignore', 'ignore', 'pipe'] });
const ende = (code) => {
  chrome.kill(); srv.close();
  setTimeout(() => { try { fs.rmSync(profil, { recursive: true, force: true }); } catch {} process.exit(code); }, 300);
};
const wsUrl = await new Promise((res, rej) => {
  let b = ''; const t = setTimeout(() => rej(new Error('Chromium startet nicht')), 15000);
  chrome.stderr.on('data', d => { b += d; const m = b.match(/ws:\/\/\S+/); if (m) { clearTimeout(t); res(m[0]); } });
});
const ws = new WebSocket(wsUrl);
await new Promise(r => ws.onopen = r);
let nr = 0; const offen = {}; const fehler = [];
ws.onmessage = e => {
  const m = JSON.parse(e.data);
  if (m.id && offen[m.id]) { offen[m.id](m); delete offen[m.id]; }
  else if (m.method === 'Runtime.exceptionThrown') fehler.push(m.params.exceptionDetails?.exception?.description || 'Ausnahme');
};
let S;
const cdp = (method, params = {}) => new Promise(r => { const i = ++nr; offen[i] = r; ws.send(JSON.stringify({ id: i, method, params, sessionId: S })); });
const werte = async (ausdruck) => {
  const m = await cdp('Runtime.evaluate', { expression: ausdruck, awaitPromise: true, returnByValue: true });
  return m.result?.result?.value;
};
const pause = (ms) => new Promise(r => setTimeout(r, ms));
const bis = async (ausdruck, ms = 3000) => { const t = Date.now(); while (Date.now() - t < ms) { if (await werte(ausdruck)) return true; await pause(50); } return false; };

const { result: { targetId } } = await cdp('Target.createTarget', { url: 'about:blank' });
S = (await cdp('Target.attachToTarget', { targetId, flatten: true })).result.sessionId;
await cdp('Runtime.enable'); await cdp('Page.enable');

// Echte Tasten. Für Buchstaben reicht key/code/text; Enter und Tab mit Code.
const TASTE = { Enter: ['Enter', 13, '\r'], Tab: ['Tab', 9, ''] };
async function taste(key) {
  const [code, vk, text] = TASTE[key] || ['Key' + key.toUpperCase(), key.toUpperCase().charCodeAt(0), key];
  await cdp('Input.dispatchKeyEvent', { type: 'keyDown', key, code, windowsVirtualKeyCode: vk, text: text || undefined });
  await cdp('Input.dispatchKeyEvent', { type: 'keyUp', key, code, windowsVirtualKeyCode: vk });
}
async function tippe(s) { for (const c of s) await taste(c); }
// Ein echter Mausklick auf die Mitte eines Elements – trifft, was dort
// tatsächlich oben liegt, wie beim Menschen.
async function klicke(selektorAusdruck) {
  const p = await werte(`(() => { const e = ${selektorAusdruck}; if (!e) return null;
    e.scrollIntoView({block:'center'}); const r = e.getBoundingClientRect();
    return r.width && r.height ? {x: r.x + r.width/2, y: r.y + r.height/2} : null; })()`);
  if (!p) return false;
  for (const type of ['mousePressed', 'mouseReleased'])
    await cdp('Input.dispatchMouseEvent', { type, x: p.x, y: p.y, button: 'left', clickCount: 1 });
  return true;
}
async function frisch() {
  anfragen.length = 0; fehler.length = 0;
  await cdp('Page.navigate', { url: BASIS });
  await bis(`document.readyState === 'complete' && getComputedStyle(document.getElementById('login-view')).display !== 'none'`, 5000);
  await pause(300);
  anfragen.length = 0;
}
const maskeSichtbar = `(() => { const v = document.getElementById('login-view'); return !!v && getComputedStyle(v).display !== 'none' && v.getBoundingClientRect().height > 0; })()`;
const logins = () => anfragen.filter(a => a === 'POST /api/auth/login').length;

// ---- Voraussetzung ---------------------------------------------------
await frisch();
const fokusFeld = await werte(`(document.getElementById('l-email')?.focus(), document.activeElement?.id)`);
pruefe(await werte(maskeSichtbar) && fokusFeld === 'l-email',
  'Voraussetzung: Anmeldemaske sichtbar, E-Mail-Feld nimmt den Fokus');

// ---- Eingabetaste ----------------------------------------------------
// B1/B2: wie ein Mensch – tippen, Tab, tippen, Enter. Erfolgsfall.
LOGIN = 'ok';
await frisch();
await werte(`document.getElementById('l-email').focus()`);
await tippe('abc'); await taste('Tab');
const imPasswort = await werte(`document.activeElement.id`);
await tippe('geheim'); await taste('Enter');
await bis(`!${maskeSichtbar}`, 3000);
pruefe(imPasswort === 'l-pass' && logins() === 1,
  'Enter im Passwortfeld schickt genau eine Anmeldung ab',
  `Fokus ${imPasswort}, ${logins()} × POST auth/login`);
pruefe(!(await werte(maskeSichtbar)) && logins() === 1,
  'Enter im Passwortfeld meldet an: die Maske ist danach weg',
  `Maske ${await werte(maskeSichtbar) ? 'noch sichtbar' : 'weg'}, Fehler: ${fehler.join(' | ') || 'keine'}`);

// B3: abgewiesen – der Satz des Servers steht unter der Maske, kein Neuladen.
LOGIN = 'falsch';
await frisch();
await werte(`window.__ohneNeuladen = 1; document.getElementById('l-email').focus()`);
await tippe('abc'); await taste('Tab'); await tippe('falsch'); await taste('Enter');
await bis(`(document.getElementById('l-msg')?.textContent || '').length > 0`, 3000);
pruefe(logins() === 1 && await werte(`window.__ohneNeuladen === 1`)
       && await werte(`document.getElementById('l-msg').textContent.includes('Ungültige Anmeldedaten.')`),
  'Enter bei falschem Passwort: Satz des Servers unter der Maske, Seite nicht neu geladen',
  `${logins()} × POST, Meldung „${await werte(`document.getElementById('l-msg')?.textContent || ''`)}“`);

// B4: Enter schon im E-Mail-Feld (beide Felder gefüllt) meldet ebenso an.
LOGIN = 'ok';
await frisch();
await werte(`document.getElementById('l-pass').focus()`);
await tippe('geheim');
await werte(`document.getElementById('l-email').focus()`);
await tippe('abc'); await taste('Enter');
await bis(`!${maskeSichtbar}`, 3000);
pruefe(logins() === 1 && !(await werte(maskeSichtbar)),
  'Enter im E-Mail-Feld meldet ebenso an', `${logins()} × POST auth/login`);

// ---- Hilfe vor der Anmeldung -----------------------------------------
// H1: Auf der Anmeldeseite gibt es etwas Sichtbares, das „Hilfe“ heißt
// (Text oder zugänglicher Name). Gesucht wird im ganzen Dokument, nicht
// nur in der Maske – aber nur, was man sieht und was nicht verdeckt ist.
LOGIN = 'ok';
await frisch();
const hilfeWeg = `(() => {
  const kand = [...document.querySelectorAll('a, button, [role=button], [role=link]')].filter(e => {
    const name = (e.getAttribute('aria-label') || e.textContent || '').trim();
    if (!/hilfe/i.test(name)) return false;
    const r = e.getBoundingClientRect();
    if (!r.width || !r.height || getComputedStyle(e).visibility === 'hidden') return false;
    const oben = document.elementFromPoint(r.x + r.width / 2, r.y + r.height / 2);
    return oben && (oben === e || e.contains(oben));
  });
  return kand[0] || null; })()`;
const gefunden = await werte(`!!${hilfeWeg}`);
pruefe(gefunden, 'Vor der Anmeldung: ein sichtbarer, nicht verdeckter Weg zur Hilfe',
  'auf der Anmeldeseite ist nichts mit „Hilfe“ sichtbar');

// H2: Der Weg führt hin – nach einem echten Klick steht die Hilfe da, mit der
// Anmeldekarte, und es wurde dafür nicht angemeldet.
let hilfeDa = false, hilfeText = 0;
if (gefunden && await klicke(hilfeWeg)) {
  hilfeDa = await bis(`(() => { const h = document.getElementById('hilfe-inhalt'); if (!h) return false;
    const r = h.getBoundingClientRect(); const o = document.elementFromPoint(r.x + 5, r.y + 5);
    return r.height > 0 && h.innerText.includes('Wie melde ich mich an') && !!o && (h.contains(o) || o.contains(h)); })()`, 3000);
  hilfeText = await werte(`(document.getElementById('hilfe-inhalt')?.innerText || '').length`);
}
pruefe(hilfeDa && logins() === 0,
  'Vor der Anmeldung: die Hilfe öffnet sich, mit der Anmeldekarte, ohne Anmeldung',
  gefunden ? `Hilfe ${hilfeDa ? 'sichtbar' : 'nicht sichtbar'} (${hilfeText} Zeichen), ${logins()} × POST` : 'kein Weg (H1)');

// ---- Schüleransicht (Z1) ----------------------------------------------
// Welche Anfragen stellt die Seite nach einer Schüleranmeldung? Jede muss auf
// der ERWARTUNG tests/daten/kontotyp_erlaubt.json stehen – Route UND Methode.
// Gemessen am Ersatz-Server, nicht am Quelltext. Wo möglich, werden Detail
// und Selbsteinschätzung mit echten Klicks ausgelöst.
// S88 („Schüleransicht nie eingeblendet“) wird BEOBACHTET und ausgegeben,
// nicht als Prüfung gezählt und nicht behoben (eigener Auftrag).
const ERWARTUNG = JSON.parse(fs.readFileSync(new URL('./daten/kontotyp_erlaubt.json', import.meta.url), 'utf8')).erlaubt;
const erlaubt = (anfrage) => {
  const [m, pfad] = anfrage.split(' ');
  const teile = pfad.split('/');            // ['', 'api', route, sub, …]
  const route = teile[2] || '', sub = teile[3] || '';
  return ERWARTUNG.some(e => e.route === route && (e.methode === '*' || e.methode === m) && (e.sub === '*' || e.sub === sub));
};
LOGIN = 'schueler';
await frisch();
await werte(`document.getElementById('l-email').focus()`);
await tippe('abc'); await taste('Tab'); await tippe('geheim'); await taste('Enter');
await bis(`!${maskeSichtbar}`, 3000);
await bis(`(document.getElementById('schueler-portal-liste')?.innerHTML || '').includes('proj-card')`, 3000);
const sichtbar = (id) => `(() => { const e = document.getElementById('${id}'); if (!e) return false;
  const r = e.getBoundingClientRect(); return getComputedStyle(e).display !== 'none' && r.width > 0 && r.height > 0; })()`;
const portalSichtbar = await werte(sichtbar('s-schueler-portal'));
const karteGeklickt = await klicke(`document.querySelector('#schueler-portal-liste .proj-card')`);
let chipGeklickt = false;
if (karteGeklickt && await bis(`!!document.querySelector('#schueler-portal-detail .bew-chip')`, 3000)) {
  chipGeklickt = await klicke(`document.querySelector('#schueler-portal-detail .bew-chip')`);
  await bis(`false`, 500);
}
const nachAnmeldung = anfragen.slice();
const fremd = nachAnmeldung.filter(a => !erlaubt(a));
pruefe(nachAnmeldung.includes('POST /api/auth/login') && nachAnmeldung.includes('GET /api/schueler-portal') && fremd.length === 0,
  'Schüleransicht: nach der Anmeldung nur Anfragen der Erlaubnisliste (Route und Methode)',
  `außerhalb: ${fremd.join(', ') || 'keine'}; gesehen: ${nachAnmeldung.join(', ')}`);
console.log(`  ·  Anfragen der Schüleransicht: ${[...new Set(nachAnmeldung)].join(', ')}`);
console.log(`  ·  Beobachtung S88: #s-schueler-portal ${portalSichtbar ? 'SICHTBAR' : 'NICHT sichtbar'};`
  + ` Werkstattkarte per Klick ${karteGeklickt ? 'erreicht' : 'nicht erreichbar'};`
  + ` Selbsteinschätzung ${chipGeklickt ? 'geklickt' : 'nicht erreicht'}`);

ws.close();
console.log(`  ${gruen}/${gruen + rot} im Browser bestanden`);
ende(rot ? 1 : 0);
