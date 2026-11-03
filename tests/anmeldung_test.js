// ============================================================
// tests/anmeldung_test.js – Anmelden und Abmelden, AUSGEFÜHRT (S73)
//
// Bis hier prüfte die Suite JavaScript nur mit `node --check`. Zwei Fehler
// der Anmeldung standen deshalb unbemerkt im Betrieb (Befund koordination
// 2026-11-03-doku-hilfe §2):
//   - Ein 401 beim Anmelden zeigte den Text eines TypeError statt des
//     Satzes der Anwendung (api() gab null zurück, doLogin las me.typ).
//   - Nach dem Abmelden stand das Passwort noch im Feld.
//
// Wie: Die Funktionen werden aus frontend/app.js GESCHNITTEN und in
// node:vm ausgeführt, mit Ersatz nur für die Ränder (fetch, location,
// DOM). Vorbild: lernzeiten tests/anzeige_test.js.
//
// DER DOM-ERSATZ IST NACHGEBILDET, nicht belegt. Er kennt aber nur
// Kennungen, die in frontend/index.html stehen: getElementById liefert für
// jede andere null, wie der Browser. Sonst verdeckte der Ersatz eine
// Kennung, die das HTML gar nicht hat (REIHENREGELN 7).
//
// DIE SÄTZE KOMMEN AUS PHP (backend/auth/Anmeldebremse.php), nicht aus
// einer Abschrift: Was der Server sagt, muss der Browser zeigen.
//
// Was hier NICHT gemessen wird und deshalb Abnahmepunkt im Browser bleibt:
// dass das Passwortfeld nach dem Neuladen leer ist, wo die Meldungen
// erscheinen, und die Eingabetaste im Formular.
//
// Aufruf: node tests/anmeldung_test.js   → Exit-Code 0 = alles grün
//
// SPDX-License-Identifier: GPL-3.0-or-later
// ============================================================

'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const { execFileSync } = require('child_process');

let fehler = 0;
function pruefe(name, ok) {
  console.log((ok ? '  ✓ ' : '  ✗ ') + name);
  if (!ok) fehler++;
}
process.on('uncaughtException', e => {
  console.log('  ✗ Suite abgebrochen: ' + (e && e.stack || e));
  process.exit(1);
});

const W = path.join(__dirname, '..');
const appJs = fs.readFileSync(path.join(W, 'frontend/app.js'), 'utf8');
const html  = fs.readFileSync(path.join(W, 'frontend/index.html'), 'utf8');

// ---- Die Sätze des Servers ------------------------------------------------
let saetze = null;
try {
  saetze = JSON.parse(execFileSync('php', ['-r', `
    require ${JSON.stringify(path.join(W, 'backend/auth/Anmeldebremse.php'))};
    $w = Anmeldebremse::urteil(['fehlversuche' => Anmeldebremse::SCHWELLE, 'seit' => 0], Anmeldebremse::SCHWELLE);
    echo json_encode([
      'abgelehnt' => Anmeldebremse::SATZ_ABGELEHNT,
      'ausfall'   => Anmeldebremse::SATZ_AUSFALL,
      'warten'    => $w['meldung'],
      'schwelle'  => Anmeldebremse::SCHWELLE,
    ]);`], { encoding: 'utf8' }));
} catch (e) {
  saetze = null;
}

// ---- Funktionen aus app.js schneiden ---------------------------------------
function schneide(name) {
  const m = appJs.match(new RegExp('^(?:async )?function ' + name + '\\(.*?^\\}', 'ms'));
  return m ? m[0] : null;
}
const PFLICHT = ['api', 'doLogin', 'doLogout', 'showMsg'];
const teile = PFLICHT.map(schneide);
const leer = schneide('leererState');     // gibt es erst mit der Behebung
const apiBase = (appJs.match(/^const API_BASE = .*;$/m) || [null])[0];
// GET, POST, DELETE sind Pfeilfunktionen in const, keine Deklarationen.
const kurz = (appJs.match(/^const (GET|POST|DELETE) +=.*;$/gm) || []);

pruefe('Voraussetzung: api, GET/POST/DELETE, doLogin, doLogout, showMsg und API_BASE aus app.js gelesen, Sätze aus Anmeldebremse.php',
  teile.every(Boolean) && apiBase !== null && kurz.length === 3 && saetze !== null
  && typeof saetze.abgelehnt === 'string' && typeof saetze.ausfall === 'string');

const KENNUNGEN = new Set([...html.matchAll(/\bid="([^"]+)"/g)].map(m => m[1]));

function element(id) {
  return {
    id, value: '', textContent: '', className: '', style: {}, attrs: {},
    setAttribute(k, v) { this.attrs[k] = v; },
    classList: { add() {}, remove() {} },
  };
}

// Eine frische Umgebung je Fall. `antworten` ordnet einem Pfad eine
// Antwort zu: {status, body} oder 'netz' (fetch scheitert).
function umgebung(antworten) {
  const protokoll = [];
  const els = new Map();
  for (const id of KENNUNGEN) els.set(id, element(id));
  const document = {
    getElementById: id => els.get(id) || null,
    querySelectorAll: () => [],
    querySelector: () => null,
  };
  const fetch = (url, opts) => {
    const pfad = url.replace(/^\/api\//, '');
    protokoll.push('fetch ' + pfad);
    const a = antworten[pfad];
    return new Promise((ok, nein) => setImmediate(() => {
      if (a === 'netz' || a === undefined) { protokoll.push('netzfehler ' + pfad); nein(new TypeError('Failed to fetch')); return; }
      protokoll.push('antwort ' + pfad);
      ok({
        status: a.status, ok: a.status >= 200 && a.status < 300,
        json: async () => a.body,
        headers: { get: () => 'application/json' },
      });
    }));
  };
  const ctx = vm.createContext({
    document, fetch, console, setTimeout, clearTimeout, setImmediate, Promise, JSON, Error, TypeError,
    location: { reload() { protokoll.push('reload'); }, replace() { protokoll.push('replace'); } },
    showLogin() { protokoll.push('showLogin'); },
    showApp() { protokoll.push('showApp'); },
    showSchuelerPortal() { protokoll.push('showSchuelerPortal'); },
  });
  const quelle = [apiBase, ...kurz, ...teile, leer || '',
    // Ein voller Zustand, wie nach einer Sitzung mit Daten.
    "let STATE = { faecher: [{id: 1}], klassen: [{id: 2}], lehrer: [{id: 3}], rahmen: [{id: 4}], kompetenzen: [{id: 5}], user: {id: 7} };",
    "globalThis.__state = () => STATE;",
    "globalThis.__aufruf = (n, ...a) => ({ doLogin, doLogout })[n](...a);",
  ].join('\n');
  vm.runInContext(quelle, ctx);
  return { ctx, els, protokoll };
}

async function fall(antworten, vorbereiten, aufruf, ...arg) {
  const u = umgebung(antworten);
  if (vorbereiten) vorbereiten(u.els);
  let wurf = null;
  try { await u.ctx.__aufruf(aufruf, ...arg); } catch (e) { wurf = e; }
  return { ...u, wurf, state: u.ctx.__state() };
}

(async () => {
  if (!teile.every(Boolean) || apiBase === null || kurz.length !== 3 || saetze === null) {
    console.log('\nALLE TESTS GRÜN NICHT MÖGLICH – Voraussetzung fehlt');
    process.exit(1);
  }

  console.log('\nAbmelden (A1)');
  {
    const r = await fall({ 'auth/logout': { status: 200, body: { ok: true } } },
      els => { els.get('l-pass').value = 'geheim'; }, 'doLogout');
    const iAntwort = r.protokoll.indexOf('antwort auth/logout');
    const iReload  = r.protokoll.indexOf('reload');
    pruefe('Abmelden gelingt: die Seite wird neu geladen – genau einmal, erst nach der Antwort von auth/logout',
      r.wurf === null && iAntwort >= 0 && iReload > iAntwort
      && r.protokoll.filter(z => z === 'reload').length === 1);
  }
  {
    const r = await fall({ 'auth/logout': 'netz' },
      els => { els.get('l-pass').value = 'geheim'; }, 'doLogout');
    const s = r.state || {};
    const leerer = s.user === null && ['faecher', 'klassen', 'lehrer', 'rahmen', 'kompetenzen']
      .every(k => Array.isArray(s[k]) && s[k].length === 0);
    const msg = r.els.get('abmelden-msg');
    pruefe('Abmelden scheitert: nicht neu geladen, Passwortfeld und STATE leer, „Abmelden ist fehlgeschlagen. …“ am Knopf',
      r.wurf === null && !r.protokoll.includes('reload') && r.els.get('l-pass').value === ''
      && leerer && msg !== undefined && msg !== null
      && msg.textContent === 'Abmelden ist fehlgeschlagen. Bitte erneut versuchen oder den Browser schließen.');
  }

  console.log('\nAnmelden: der Satz des Servers erscheint (A2)');
  const anmelden = async (status, satz) => {
    const r = await fall({ 'auth/login': { status, body: { error: satz } } },
      els => { els.get('l-email').value = 'jemand'; els.get('l-pass').value = 'falsch'; }, 'doLogin');
    return r.els.get('l-msg').textContent;
  };
  pruefe('401: „' + saetze.abgelehnt + '“ in l-msg – kein TypeError-Text',
    (await anmelden(401, saetze.abgelehnt)) === saetze.abgelehnt);
  pruefe('429: der Wartesatz des Servers in l-msg',
    (await anmelden(429, saetze.warten)) === saetze.warten);
  pruefe('503: „' + saetze.ausfall + '“ in l-msg',
    (await anmelden(503, saetze.ausfall)) === saetze.ausfall);

  console.log('\n' + (fehler === 0 ? 'ALLE TESTS GRÜN' : fehler + ' ROT'));
  process.exit(fehler === 0 ? 0 : 1);
})();
