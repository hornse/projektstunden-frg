
// ============================================================
// KONFIGURATION
// API_BASE: Im Produktivbetrieb auf Uberspace leer lassen (relativer Pfad).
// Für lokale Entwicklung gegen das Backend: 'https://DEINE-DOMAIN.uberspace.de'
// ============================================================
const API_BASE = '';

// ============================================================
// API-Hilfsfunktionen
// ============================================================
async function api(method, path, body) {
  const opts = {
    method,
    credentials: 'include',
    headers: { 'Content-Type': 'application/json' },
  };
  if (body) opts.body = JSON.stringify(body);
  const r = await fetch(API_BASE + '/api/' + path, opts);
  if (r.status === 401) {
    // Nur zum Login wenn wir nicht gerade einloggen
    if (path !== 'auth/login' && path !== 'auth/me') showLogin();
    return null;
  }
  if (!r.ok) {
    const e = await r.json().catch(() => ({ error: 'Netzwerkfehler' }));
    throw new Error(e.error || 'Fehler ' + r.status);
  }
  const ct = r.headers.get('Content-Type') || '';
  if (ct.includes('text/csv')) return r.blob();
  return r.json();
}
const GET    = (path)        => api('GET',    path);
const POST   = (path, body)  => api('POST',   path, body);
const DELETE = (path)        => api('DELETE', path);

// ============================================================
// Benutzertext in HTML einsetzen
//
// Fast jedes Textfeld wird im Backend beim Schreiben durch `clean()`
// geschickt (htmlspecialchars) und steht deshalb bereits maskiert in der
// Datenbank; roh in `innerHTML` eingesetzt zeigt es sich richtig an.
//
// `werkstatt_rueckmeldungen.freitext` ist die Ausnahme: Er wird
// **absichtlich unmaskiert gespeichert** und erst hier maskiert. Zwei
// Gründe. Erstens schützt eine Eingangsprüfung die vier Zeilen nicht, die
// vor ihr entstanden sind -- und genau die standen ungeprüft im Bestand.
// Zweitens ist die Zusicherung „jeder Schreibweg ruft clean()" in diesem
// Projekt nachweislich nicht wahr: Der CSV-Import schreibt Namen mit
// blossem `trim()`.
//
// Maskiert wird genau EINMAL. Käme `clean()` beim Schreiben dazu, stünde
// `&amp;` in der Datenbank, diese Funktion machte `&amp;amp;` daraus, und
// aus „Toll & gut" würde sichtbar „Toll &amp; gut". Das Testskript prüft
// deshalb beides: dass hier maskiert wird, und dass es beim Schreiben
// nicht geschieht.
function escHtml(wert) {
  return String(wert ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

// ============================================================
// STATE – globale In-Memory-Daten (werden nach Login geladen)
// ============================================================
let STATE = { faecher: [], klassen: [], lehrer: [], rahmen: [], kompetenzen: [], user: null };

async function loadState() {
  const [faecher, klassen, lehrer, rahmen] = await Promise.all([
    GET('faecher'), GET('klassen'), GET('lehrer'), GET('kompetenzrahmen'),
  ]);
  STATE.faecher  = faecher  || [];
  STATE.klassen  = klassen  || [];
  STATE.lehrer   = lehrer   || [];
  STATE.rahmen   = rahmen   || [];
}

// ============================================================
// LOGIN / LOGOUT
// ============================================================
async function checkAuth() {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const r = await fetch(API_BASE + '/api/auth/me', {
      credentials: 'include',
      signal: controller.signal
    });
    clearTimeout(timeout);
    if (r.status === 401 || !r.ok) { showLogin(); return; }
    const me = await r.json().catch(() => null);
    if (me && (me.id || me.id === 0)) {
      STATE.user = me;
      if (me.typ === 'schueler') {
        showSchuelerPortal(me);
      } else {
        showApp();
      }
    } else showLogin();
  } catch { showLogin(); }
}
/**
 * Zeigt die Anmeldemaske INNERHALB der Huelle.
 *
 * Vorher lag sie daneben, und die Huelle wurde ausgeblendet - die
 * Maske schwebte dann ohne Leiste im Nichts. Jetzt bleibt die Leiste
 * mit der Marke stehen, nur die Navigationspunkte verschwinden: Wer
 * nicht angemeldet ist, kann keinen davon nutzen.
 */
function showLogin() {
  document.getElementById('login-view').style.display = 'flex';
  document.getElementById('app-view').style.display   = 'flex';
  // Alle Ansichten aus, sonst stuende der letzte Bildschirm unter der
  // Anmeldemaske.
  document.querySelectorAll('.screen').forEach(e => e.classList.remove('on'));
  navSichtbar(false);
  ladeLoginLogo();
}

/**
 * Blendet die Navigationspunkte aus oder ein.
 *
 * Die Leiste selbst bleibt stehen - sie zeigt mit Logo und Titel, wo
 * man ist. Verborgen wird nur, was ohne Anmeldung nicht nutzbar ist;
 * „Abmelden" ohne Anmeldung waere schlicht falsch.
 */
function navSichtbar(an) {
  const nav = document.querySelector('.ci-nav');
  if (nav) nav.hidden = !an;
  const schalter = document.querySelector('[data-ci-schalter]');
  if (schalter) schalter.hidden = !an;
}
async function showApp() {
  document.getElementById('login-view').style.display = 'none';
  document.getElementById('app-view').style.display   = 'flex';
  navSichtbar(true);
  if (STATE.user && STATE.user.rolle === 'admin') {
    document.getElementById('app-view').classList.add('is-admin');
  } else {
    document.getElementById('app-view').classList.remove('is-admin');
  }
  // Einstellungen (Logo, Farben, Name) laden
  await ladeEinstellungenApp();
  await loadState();
  go('dashboard');
}
async function doLogin() {
  const email = document.getElementById('l-email').value.trim();
  const pass  = document.getElementById('l-pass').value;
  try {
    const me = await POST('auth/login', { email, username: email, passwort: pass });
    STATE.user = me;
    // Kurze Pause damit der Browser den Session-Cookie speichern kann
    await new Promise(resolve => setTimeout(resolve, 100));
    if (me.typ === 'schueler') {
      showSchuelerPortal(me);
    } else {
      showApp();
    }
  } catch(e) { showMsg('l-msg', e.message, 'err'); }
}
async function doLogout() {
  await POST('auth/logout', {});
  showLogin();
}

// ============================================================
// NAVIGATION
// ============================================================
function go(id) {
  // klassen ist in schueler integriert
  if (id === 'klassen') id = 'schueler';

  document.querySelectorAll('.screen').forEach(s => s.classList.remove('on'));
  // aria-current statt einer eigenen Klasse: ci-shell.css und
  // Bildschirmleser lesen dasselbe Attribut, der Zustand ist damit
  // nicht nur sichtbar, sondern auch hörbar.
  document.querySelectorAll('.nv, .nv-child').forEach(b => {
    b.classList.remove('on');
    b.removeAttribute('aria-current');
  });

  const screen = document.getElementById('s-' + id);
  if (screen) screen.classList.add('on');

  // Hauptnav markieren
  document.querySelectorAll('.nv').forEach(b => {
    if ((b.getAttribute('onclick') || '').includes("'" + id + "'")) {
      b.setAttribute('aria-current', 'page');
    }
  });

  // Admin-Sub: aufklappen wenn Admin-Screen aktiv
  const adminScreens = ['einstellungen','benutzer','schuljahre','import'];
  if (adminScreens.includes(id)) {
    const sub    = document.getElementById('admin-sub');
    const toggle = document.querySelector('.nv-group-toggle');
    if (sub)    sub.style.display = 'block';
    if (toggle) toggle.classList.add('open');
    // Kind-Button markieren
    document.querySelectorAll('.nv-child').forEach(b => {
      if ((b.getAttribute('onclick') || '').includes("'" + id + "'")) {
        b.setAttribute('aria-current', 'page');
      }
    });
  }

  const init = { dashboard: initDash, projekt: initProjekt, schueler: initSchueler,
                 klassen: initSchueler, katalog: initKatalog, export: initExport,
                 benutzer: initBenutzer, schuljahre: initSchuljahre, import: initImport,
                 bewertung: initBewertung, hilfe: initHilfe, einstellungen: initEinstellungen,
                 'werkstatt-edit': () => {} };
  if (init[id]) init[id]();

  fokusAufInhalt();
}

/**
 * Setzt den Fokus auf den Inhaltsbereich.
 *
 * Die Anwendung tauscht ihre Ansicht aus, statt die Seite neu zu laden.
 * Ohne diesen Sprung bliebe der Tastaturfokus dort, wo er war – meist
 * auf einem Navigationsknopf –, und der nächste Tabulatorsprung führte
 * wieder durch die ganze Navigation. Bildschirmleser bekämen vom
 * Wechsel gar nichts mit.
 *
 * preventScroll, damit die Seite nicht springt: Der Bereich steht
 * ohnehin oben.
 */
function fokusAufInhalt() {
  const ziel = document.getElementById('hauptinhalt');
  if (ziel) ziel.focus({ preventScroll: true });
}

function toggleAdminGruppe() {
  const sub  = document.getElementById('admin-sub');
  const btn  = document.querySelector('.nv-group-toggle');
  const open = sub.style.display === 'none';
  sub.style.display = open ? 'block' : 'none';
  btn.classList.toggle('open', open);
}

function toggleKlasseAnlegen() {
  const el = document.getElementById('kl-anlegen-block');
  el.style.display = el.style.display === 'none' ? 'block' : 'none';
}

// ============================================================
// DASHBOARD
// ============================================================
async function initDash() {
  // Klassen-Dropdown befüllen
  const kEl = document.getElementById('f-kl');
  const cur  = kEl.value;
  kEl.innerHTML = '<option value="">Alle Klassen</option>' +
    STATE.klassen.map(k => `<option value="${k.id}"${k.id==cur?' selected':''}>${escHtml(k.bezeichnung)} (${escHtml(k.schuljahr)})</option>`).join('');
  await renderDash();
}
async function dashFilter() {
  const kl = document.getElementById('f-kl').value;
  const sEl = document.getElementById('f-s');
  // Schüler für Klasse laden
  const schueler = kl ? await GET(`schueler?klasse_id=${kl}`) : [];
  sEl.innerHTML = '<option value="">Alle Schüler</option>' +
    (schueler || []).map(s => `<option value="${s.id}">${escHtml(s.vorname)} ${escHtml(s.nachname)} (${escHtml(s.klasse)})</option>`).join('');
  renderDash();
}
async function renderDash() {
  const kl = document.getElementById('f-kl').value;
  const sid= document.getElementById('f-s').value;
  let url  = 'dashboard';
  if (kl)  url += '?klasse_id=' + kl;
  if (sid) url += (kl ? '&' : '?') + 'schueler_id=' + sid;

  const data = await GET(url);
  if (!data) return;

  // Statistik-Kacheln
  const totalK = [...new Set(data.flatMap(s => (s.kompetenzen || []).map(k => k.id)))].length;
  document.getElementById('dash-stats').innerHTML = `
    <div class="stat"><div class="stat-v">${data.length}</div><div class="stat-l">Schüler</div></div>
    <div class="stat"><div class="stat-v">${STATE.klassen.length}</div><div class="stat-l">Klassen</div></div>
    <div class="stat"><div class="stat-v">${totalK}</div><div class="stat-l">Kompetenzen</div></div>
  `;

  const el = document.getElementById('dash-list');
  if (!data.length) { el.innerHTML = '<div class="empty">Keine Schüler gefunden. Zuerst Schüler unter "Schüler verwalten" anlegen.</div>'; return; }

  el.innerHTML = data.map(s => {
    const uid = 'sc' + s.id;
    // Fachzeilen
    const fRows = s.faecher.filter(f => f.soll > 0).map(f => {
      // ZWEI ZUSTAENDE, NICHT DREI (E60).
      //
      // Vorher: rot ab 100 %, gelb ab 40 %, sonst orange. Beides war falsch.
      // Rot heisst in dieser Anwendung "Fehler" -- die Fehlerzahl der
      // Import-Vorschau, der Loeschen-Knopf, die Bewertungsstufe 1.
      // Uebererfuellung ist kein Fehler und darf nicht dieselbe Farbe tragen.
      //
      // Die 40-Prozent-Grenze ist ersatzlos entfallen. Das Soll ist ein
      // Jahreswert (soll_jg5 bis soll_jg10); dieselbe Zahl bedeutet im
      // November etwas anderes als im Juni, und die Farbe weiss nichts vom
      // Datum. Eine Bewertung auszusprechen, fuer die es keine Regel gibt,
      // ist schlechter als keine.
      //
      // KEIN DECKEL AUF DER ZAHL, WOHL ABER AUF DEM BALKEN: `Math.min(100, …)`
      // machte aus 150 % eine 100, waehrend die Zeile daneben "3 / 2 Std."
      // zeigte -- zwei Angaben ueber dieselbe Sache, die sich widersprachen.
      // Der Balken bleibt gedeckelt, sonst schiebt er sich aus seinem Rahmen.
      //
      // Die Farbe folgt der ANGEZEIGTEN Zahl, nicht dem ungerundeten
      // Verhaeltnis: Sonst koennte dort "100%" stehen und der Punkt trotzdem
      // grau sein. Beide Angaben duerfen einander nie widersprechen.
      const pct    = f.soll > 0 ? Math.round(f.projekt_stunden / f.soll * 100) : 0;
      const breite = Math.min(100, pct);
      const voll   = pct >= 100;
      const dc = voll ? 'dok' : 'dnone';
      const fc = voll ? 'pok' : 'pnone';
      return `<div class="f-row">
        <span class="dot ${dc}"></span>
        <span class="f-lbl">${f.fach_name}</span>
        <span class="f-nums">${f.projekt_stunden} / ${f.soll} Std.</span>
        <div class="pbar"><div class="pfill ${fc}" style="width:${breite}%"></div></div>
        <span style="font-size:11px;color:var(--text3);min-width:30px;text-align:right;font-family:'DM Mono',monospace">${pct}%</span>
      </div>`;
    }).join('');

    // Kompetenz-Pillen
    const komps = s.kompetenzen || [];
    const kHTML = komps.length
      ? komps.map(k => {
          const cls = k.rahmen === 'MKR' ? 'pill mkr' : k.rahmen === 'MA_KLP' ? 'pill ma' : 'pill';
          return `<span class="${cls}">[${k.rahmen}] ${k.code ? k.code + ' ' : ''}${k.kurzname}</span>`;
        }).join('')
      : '<span style="font-size:12px;color:var(--text3)">Noch keine Kompetenzen erfasst</span>';

    const totalIst = s.faecher.reduce((a, f) => a + f.projekt_stunden, 0);
    const totalSoll= s.faecher.filter(f => f.soll > 0).reduce((a, f) => a + f.soll, 0);

    return `<div class="s-card">
      <div class="s-hdr" id="h${uid}" onclick="toggleCard('${uid}')">
        <div class="avatar">${escHtml(s.vorname[0])}${escHtml(s.nachname[0])}</div>
        <div><div class="s-name">${escHtml(s.vorname)} ${escHtml(s.nachname)}</div>
          <div class="s-meta">Klasse ${escHtml(s.klasse)} · ${Math.round(totalIst*10)/10}/${totalSoll} Projektstd. · ${komps.length} Kompetenzen</div>
        </div>
        <span class="chevron" id="ch${uid}">&#8964;</span>
      </div>
      <div class="s-body" id="${uid}">
        <div class="sec" style="margin-top:0">Stundenkontingent</div>
        ${fRows}
        <div class="k-sum">
          <div class="sec" style="margin-top:0">Erworbene Kompetenzen (${komps.length})</div>
          <div class="k-pills">${kHTML}</div>
        </div>
      </div>
    </div>`;
  }).join('');
}

function toggleCard(uid) {
  document.getElementById(uid).classList.toggle('op');
  document.getElementById('ch' + uid).classList.toggle('op');
  document.getElementById('h' + uid).classList.toggle('op');
}

// ============================================================
// PROJEKT EINTRAGEN
// ============================================================
let KOMPETENZEN_CACHE = {}; // { fach_id: [...kompetenzen] }
let AKTIVER_RAHMEN    = 0;

async function initProjekt() {
  // Schuljahr-Filter-Dropdown (oben in der Liste)
  const sjData = await GET('schuljahre');
  const sjEl = document.getElementById('p-schuljahr');
  sjEl.innerHTML = '<option value="">– alle Schuljahre –</option>' +
    (sjData || []).map(s =>
      `<option value="${s.id}" ${s.status === 'aktiv' ? 'selected' : ''}>${s.name}${s.status === 'aktiv' ? ' ✓' : ''}</option>`
    ).join('');

  // Schuljahr im Formular
  const sjFormEl = document.getElementById('p-schuljahr-form');
  if (sjFormEl) {
    sjFormEl.innerHTML = '<option value="">– kein –</option>' +
      (sjData || []).map(s =>
        `<option value="${s.id}" ${s.status === 'aktiv' ? 'selected' : ''}>${s.name}${s.status === 'aktiv' ? ' ✓' : ''}</option>`
      ).join('');
  }

  // Klassen Multi-Select
  const kEl = document.getElementById('p-kl');
  kEl.innerHTML = STATE.klassen.map(k =>
    `<option value="${k.id}">${escHtml(k.bezeichnung)} (${escHtml(k.schuljahr)})</option>`
  ).join('');

  // Lernbegleiter Multi-Select (eigene ID vorausgewählt)
  const lEl = document.getElementById('p-lehrer');
  lEl.innerHTML = STATE.lehrer.map(l =>
    `<option value="${l.id}" ${l.id === STATE.user?.id ? 'selected' : ''}>${/* keine-maskierung: benutzer, beim Schreiben maskiert */ l.vorname} ${l.nachname}${l.kuerzel ? ' (' + l.kuerzel + ')' : ''}</option>`
  ).join('');

  // Fach-Grid aufbauen
  buildFachGrid();
  // Startdatum: heute
  document.getElementById('p-von').valueAsDate = new Date();
  // Kompetenzen laden
  await loadKompetenzenFuerFaecher([]);
  renderRahmenTabs();
  await renderProjektListe();
}

function toggleNeueWerkstatt() {
  const wrap = document.getElementById('neue-ws-wrap');
  const btn  = document.getElementById('btn-neue-ws');
  const open = wrap.style.display === 'none';
  wrap.style.display = open ? 'block' : 'none';
  btn.textContent = open ? '✕ Abbrechen' : '+ Neue Werkstatt';
  if (open) {
    // Zum Formular scrollen
    wrap.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
}

function buildFachGrid() {
  document.getElementById('p-fach-grid').innerHTML = STATE.faecher.map(f =>
    `<div class="fach-item">
       <span>${f.name}</span>
       <input type="number" min="0" max="40" step="0.5" placeholder="0"
              data-fid="${f.id}" data-fkuerzel="${f.kuerzel}"
              oninput="onStundenChange()">
     </div>`
  ).join('');
}

function onStundenChange() {
  let s = 0;
  document.querySelectorAll('#p-fach-grid input').forEach(i => s += parseFloat(i.value) || 0);
  document.getElementById('p-summe').textContent = Math.round(s * 10) / 10;
  // Kompetenzen für beteiligte Fächer nachladen
  const fids = getStundenFachIds();
  loadKompetenzenFuerFaecher(fids).then(renderRahmenTabs);
}

function getStundenFachIds() {
  return [...document.querySelectorAll('#p-fach-grid input')]
    .filter(i => parseFloat(i.value) > 0)
    .map(i => parseInt(i.dataset.fid));
}

async function loadKompetenzenFuerFaecher(fachIds) {
  // Immer fächerübergreifende (MKR) laden + fachbezogene für ausgewählte Fächer
  const promises = [GET('kompetenzen')]; // alle inkl. fächerübergreifend
  for (const fid of fachIds) {
    if (!KOMPETENZEN_CACHE[fid]) {
      promises.push(GET(`kompetenzen?fach_id=${fid}`).then(d => { KOMPETENZEN_CACHE[fid] = d || []; }));
    }
  }
  const all = await promises[0];
  STATE.kompetenzen = all || [];
}

function renderRahmenTabs() {
  const fids  = getStundenFachIds();
  // Wenn kein Fach gewählt: nur fächerübergreifende Rahmen (MKR)
  // Wenn Fach gewählt: auch fachspezifische Rahmen für diese Fächer
  const relRahmen = STATE.rahmen.filter(r => {
    if (!r.fach_kuerzel) return true; // MKR immer anzeigen
    if (!fids.length) return false;   // Kein Fach → keine KLPs
    return fids.some(fid => {
      const f = STATE.faecher.find(x => x.id == fid);
      return f && f.kuerzel === r.fach_kuerzel;
    });
  });

  const tabEl = document.getElementById('rahmen-tabs');
  if (!relRahmen.length) { tabEl.innerHTML = ''; document.getElementById('komp-bereich-list').innerHTML = ''; return; }

  if (!AKTIVER_RAHMEN || !relRahmen.find(r => r.id === AKTIVER_RAHMEN)) {
    AKTIVER_RAHMEN = relRahmen[0].id;
  }
  tabEl.innerHTML = relRahmen.map(r =>
    `<button class="rtab${r.id === AKTIVER_RAHMEN ? ' on' : ''}"
             onclick="switchRahmen(${r.id})">${r.kuerzel} – ${r.name}</button>`
  ).join('');
  renderKompBereichList(AKTIVER_RAHMEN, fids);
}

function switchRahmen(rid) {
  AKTIVER_RAHMEN = rid;
  renderRahmenTabs();
}

function renderKompBereichList(rahmen_id, fachIds) {
  const fids = fachIds || getStundenFachIds();
  const r = STATE.rahmen.find(x => x.id === rahmen_id);
  if (!r) return;

  // Kompetenzen für diesen Rahmen filtern
  const komp = STATE.kompetenzen.filter(k => {
    if (k.rahmen_kuerzel !== r.kuerzel) return false;
    if (k.fach_kuerzel && fids.length > 0)
      return fids.some(fid => { const f = STATE.faecher.find(x => x.id == fid); return f && f.kuerzel === k.fach_kuerzel; });
    return true;
  });

  // Index: id → kompetenz
  const byId = {};
  komp.forEach(k => { byId[k.id] = k; });

  // Allgemeine Kompetenzen (eltern=null) und Erwartungen (eltern=id) trennen
  const allgemeine = komp.filter(k => !k.eltern_kompetenz_id);
  const erwartungen = komp.filter(k => k.eltern_kompetenz_id);

  // Erwartungen nach eltern_kompetenz_id gruppieren
  const erwByEltern = {};
  erwartungen.forEach(e => {
    const pid = e.eltern_kompetenz_id;
    (erwByEltern[pid] = erwByEltern[pid] || []).push(e);
  });

  // Nach Bereichen gruppieren
  const bereiche = {};
  allgemeine.forEach(k => {
    const b = k.bereich_code + ': ' + k.bereich_name;
    (bereiche[b] = bereiche[b] || []).push(k);
  });

  const el = document.getElementById('komp-bereich-list');
  if (!Object.keys(bereiche).length) {
    el.innerHTML = '<p style="font-size:12px;color:var(--text3)">Für die gewählten Fächer keine Kompetenzen verfügbar.</p>';
    return;
  }

  el.innerHTML = Object.entries(bereiche).map(([b, ks]) => {
    const items = ks.map(k => {
      const kinder = erwByEltern[k.id] || [];
      const hasKinder = kinder.length > 0;
      const toggleId = 'erw-' + k.id;

      // Allgemeine Kompetenz als wählbares Pill
      let html = `<div class="komp-eltern-row">
        <label class="komp-pill">
          <input type="checkbox" class="komp-cb" value="${k.id}">
          <span class="pill-label" title="${k.beschreibung || ''}">${k.kurzname}</span>
        </label>`;

      if (hasKinder) {
        html += `<button class="komp-eltern-toggle" title="${kinder.length} konkrete Kompetenzerwartungen aufklappen" onclick="toggleErw('${toggleId}', this)">▸ ${kinder.length}</button>`;
      }
      html += `</div>`;

      // Konkrete Erwartungen (aufklappbar, ebenfalls wählbar)
      if (hasKinder) {
        html += `<div class="komp-erwartungen" id="${toggleId}">` +
          kinder.map(e =>
            `<label class="komp-pill erw">
               <input type="checkbox" class="komp-cb" value="${e.id}">
               <span class="pill-label" title="${e.beschreibung || ''}">${e.kurzname}</span>
             </label>`
          ).join('') +
        `</div>`;
      }
      return html;
    }).join('');

    return `<div class="bereich-block">
      <div class="bereich-title">${b}</div>
      <div class="komp-grid">${items}</div>
    </div>`;
  }).join('');
}

function toggleKatErw(id, triggerEl) {
  const el = document.getElementById(id);
  if (!el) return;
  const open = el.classList.toggle('open');
  if (triggerEl) {
    const arrow = triggerEl.querySelector('.kat-arrow');
    if (arrow) arrow.textContent = (open ? '▾ ' : '▸ ') + arrow.textContent.replace(/[▸▾]\s*/, '');
  }
}
function toggleErw(id, triggerEl) {
  const el = document.getElementById(id);
  if (!el) return;
  const open = el.classList.toggle('open');
  // Update Pfeil im auslösenden Element (Button oder Span)
  if (triggerEl) {
    const arrow = triggerEl.querySelector('span') || triggerEl;
    const txt = arrow.textContent;
    if (open) {
      arrow.textContent = txt.replace('▸', '▾');
      triggerEl.textContent = triggerEl.textContent.replace('▸', '▾');
    } else {
      triggerEl.textContent = triggerEl.textContent.replace('▾', '▸');
    }
  }
}

// ============================================================
//  TEILNEHMERAUSWAHL  (E34, E35)
//
//  Zwei Ansichten, ein Verfahren: `p` = Werkstatt anlegen,
//  `we` = Werkstatt bearbeiten.
//
//  Die Auswahl liegt in einer Menge, nicht im DOM. Vorher war sie ein
//  `select multiple` -- dort IST die Auswahl das DOM (`selectedOptions`),
//  und die Optionsliste wird bei jedem Klassenwechsel neu gezeichnet. Das
//  ist genau der Verlust, den E33 bei den Kompetenzen beschreibt, nur an
//  einer anderen Stelle.
//
//  `kandidaten` sind die wählbaren Schüler, `bestand` beim Bearbeiten die
//  Teilnehmer, wie sie in der Datenbank stehen -- mit dem, was beim
//  Entfernen verlorenginge.
// ============================================================
const TEILN = {
  p:  { ids: new Set(), kandidaten: [], bestand: [] },
  we: { ids: new Set(), kandidaten: [], bestand: [] }
};

function teilnIds(pfx) { return [...TEILN[pfx].ids]; }

function teilnMax(pfx) {
  const el = document.getElementById(pfx + '-max');
  const v  = el && el.value ? parseInt(el.value) : NaN;
  return Number.isFinite(v) && v > 0 ? v : null;
}

// Kandidaten setzen und zeichnen. Bereits gewählte IDs, die nicht mehr unter
// den Kandidaten sind, bleiben in der Menge -- sonst verlöre ein
// Klassenwechsel beim Anlegen die Auswahl der vorigen Klasse, und beim
// Bearbeiten einen Teilnehmer, der die Klasse gewechselt hat.
function teilnKandidaten(pfx, liste) {
  TEILN[pfx].kandidaten = liste || [];
  renderTeilnehmer(pfx);
}

function teilnUmschalten(pfx, id, an) {
  if (an) TEILN[pfx].ids.add(Number(id));
  else    TEILN[pfx].ids.delete(Number(id));
  teilnKopf(pfx);
}

// „Alle hinzufügen" fügt höchstens bis zum Maximum hinzu und sagt, wie viele
// es ausgelassen hat (E35). Ohne diese Grenze wäre die Auswahlhilfe der
// bequemste Weg, das Maximum zu überschreiten.
function teilnAlle(pfx, klasseId) {
  const max  = teilnMax(pfx);
  const kand = TEILN[pfx].kandidaten.filter(s => !klasseId || Number(s.klasse_id) === Number(klasseId));
  let ausgelassen = 0;
  for (const s of kand) {
    if (TEILN[pfx].ids.has(Number(s.id))) continue;
    if (max !== null && TEILN[pfx].ids.size >= max) { ausgelassen++; continue; }
    TEILN[pfx].ids.add(Number(s.id));
  }
  renderTeilnehmer(pfx);
  if (ausgelassen) {
    showMsg(pfx + '-msg',
      `${ausgelassen} nicht hinzugefügt – das Maximum von ${max} ist erreicht.`, 'err');
  }
}

function teilnKeine(pfx) {
  TEILN[pfx].ids.clear();
  renderTeilnehmer(pfx);
}

// Kopfzeile: Zählwert, Maximum, Auswahlhilfen. Getrennt vom Zeichnen der
// Kacheln, damit ein Klick nicht die ganze Liste neu aufbaut.
function teilnKopf(pfx) {
  const el = document.getElementById(pfx + '-teiln-kopf');
  if (!el) return;
  const n   = TEILN[pfx].ids.size;
  const max = teilnMax(pfx);
  const ueber = max !== null && n > max;

  // Klassen in der Reihenfolge, in der sie in der Kandidatenliste stehen
  const klassen = [];
  for (const s of TEILN[pfx].kandidaten) {
    if (!klassen.some(k => Number(k.id) === Number(s.klasse_id))) {
      klassen.push({ id: s.klasse_id, name: s.klasse,
                     n: TEILN[pfx].kandidaten.filter(x => Number(x.klasse_id) === Number(s.klasse_id)).length });
    }
  }

  el.innerHTML =
    `<span class="teiln-zahl${ueber ? ' ueber' : ''}">${n} gewählt` +
    (max !== null ? ` von max. ${max}` : '') +
    (ueber ? ' – über dem Maximum' : '') + `</span>` +
    (klassen.length > 1
      ? klassen.map(k => `<button type="button" class="btn btn-sm" onclick="teilnAlle('${pfx}', ${k.id})">+ ${k.name} (${k.n})</button>`).join('')
      : '') +
    `<button type="button" class="btn btn-sm" onclick="teilnAlle('${pfx}')">Alle hinzufügen</button>` +
    `<button type="button" class="btn btn-sm" onclick="teilnKeine('${pfx}')">Auswahl aufheben</button>`;
}

function renderTeilnehmer(pfx) {
  const el = document.getElementById(pfx + '-teiln-list');
  if (!el) return;
  teilnKopf(pfx);

  if (!TEILN[pfx].kandidaten.length) {
    el.innerHTML = '<p style="font-size:12px;color:var(--text3)">Keine Schüler zur Auswahl.</p>';
    return;
  }

  // Was zu einem Teilnehmer schon erfasst ist – nur beim Bearbeiten belegt.
  const info = {};
  for (const b of TEILN[pfx].bestand) info[Number(b.id)] = b;

  const gruppen = {};
  for (const s of TEILN[pfx].kandidaten) {
    const g = s.klasse || '– ohne Klasse –';
    (gruppen[g] = gruppen[g] || []).push(s);
  }

  // Jede Kachel liest ihren Zustand aus der Menge – nie umgekehrt (E33).
  // Number() an jeder Stelle: Die Menge führt Zahlen, und ob die API eine ID
  // als Zahl oder als Zeichenkette liefert, ist nicht durchgängig belegt.
  el.innerHTML = Object.entries(gruppen).map(([g, ks]) => {
    const items = ks.map(s => {
      const b = info[Number(s.id)];
      const erfasst = b && (Number(b.bewertungen) > 0 || Number(b.rueckmeldungen) > 0
                            || Number(b.abgeschlossen) === 1);
      return `<label class="teiln-pill">` +
        `<input type="checkbox" class="${pfx}-teiln-cb" value="${s.id}"` +
        `${TEILN[pfx].ids.has(Number(s.id)) ? ' checked' : ''}` +
        ` onchange="teilnUmschalten('${pfx}', ${Number(s.id)}, this.checked)">` +
        `<span class="pill-label"${erfasst ? ` title="${teilnWasErfasst(b)}"` : ''}>` +
        `${escHtml(s.nachname)}, ${escHtml(s.vorname)}` +
        `${erfasst ? '<span class="warn-punkt">!</span>' : ''}</span></label>`;
    }).join('');
    return `<div class="teiln-gruppe"><div class="teiln-gruppe-titel">${g} (${ks.length})</div>` +
           `<div class="teiln-grid">${items}</div></div>`;
  }).join('');
}

// Was bei diesem Teilnehmer verlorenginge, als Text. „Bewertet" ist dabei
// nicht die Zeilenexistenz in projekt_schueler_kompetenzen -- der PUT legt
// dort für jeden Teilnehmer mal jede Kompetenz eine leere Zeile an. Das
// Backend zählt deshalb nur, was Inhalt trägt (E34).
function teilnWasErfasst(b) {
  const t = [];
  const bw = Number(b.bewertungen) || 0;
  if (bw > 0) t.push(bw + (bw === 1 ? ' Einschätzung' : ' Einschätzungen'));
  if (Number(b.rueckmeldungen) > 0) t.push('Rückmeldung vorhanden');
  if (Number(b.abgeschlossen) === 1) t.push('als abgeschlossen markiert');
  return t.join(', ');
}

// Kandidaten der Bearbeiten-Ansicht neu laden, wenn die Klassenauswahl sich
// ändert (E38).
//
// Das ist die Stelle, an der die Auswahl verlorengehen kann: Die Kachelliste
// wird komplett neu gezeichnet. Sie überlebt es, weil `TEILN.we.ids` hier
// **nicht angefasst** wird -- die Menge ist die Wahrheit, das DOM nur ihre
// Anzeige (E33). Und die bisherigen Teilnehmer kommen unabhängig von der
// Klassenwahl in die Kandidatenliste: Wer nicht gezeichnet wird, liesse sich
// nicht mehr abwählen.
async function loadSchuelerForWerkstattEdit() {
  const klassen = [...document.getElementById('we-kl').selectedOptions].map(o => o.value);
  const liste = klassen.length ? (await GET(`schueler?klassen=${klassen.join(',')}`) || []) : [];
  for (const t of TEILN.we.bestand) {
    if (!liste.some(k => Number(k.id) === Number(t.id))) liste.push(t);
  }
  teilnKandidaten('we', liste);
}

function loadSchuelerForProjekt() {
  const selected = [...document.getElementById('p-kl').selectedOptions].map(o => o.value);
  if (!selected.length) { teilnKandidaten('p', []); return; }
  GET(`schueler?klassen=${selected.join(',')}`).then(list => {
    teilnKandidaten('p', list || []);
  });
}

async function projektSpeichern() {
  const name        = document.getElementById('p-name').value.trim();
  const klasse_ids  = [...document.getElementById('p-kl').selectedOptions].map(o => parseInt(o.value));
  const klasse_id   = klasse_ids[0] || 0;
  const schuljahr_id = parseInt(document.getElementById('p-schuljahr-form')?.value) || null;
  const datum_von   = document.getElementById('p-von').value;
  const datum_bis   = document.getElementById('p-bis').value || null;
  const praesentation_datum = document.getElementById('p-praesentation').value || null;
  const laufzeit    = document.getElementById('p-laufzeit').value;
  const max_schueler = document.getElementById('p-max').value ? parseInt(document.getElementById('p-max').value) : null;
  const beschreibung = document.getElementById('p-desc').value.trim();
  const status      = document.getElementById('p-status').value;
  const lehrer_ids  = [...document.getElementById('p-lehrer').selectedOptions].map(o => parseInt(o.value));
  const schueler_ids = teilnIds('p');

  if (!name || !klasse_ids.length || !datum_von)
    return showMsg('p-msg', 'Werkstattname, mind. eine Klasse und Startdatum sind Pflichtfelder.', 'err');
  if (!lehrer_ids.length)
    return showMsg('p-msg', 'Mindestens einen Lernbegleiter auswählen.', 'err');
  if (max_schueler && schueler_ids.length > max_schueler)
    return showMsg('p-msg', `Zu viele Teilnehmer: max. ${max_schueler} erlaubt, ${schueler_ids.length} ausgewählt.`, 'err');

  const stunden = [...document.querySelectorAll('#p-fach-grid input')]
    .filter(i => parseFloat(i.value) > 0)
    .map(i => ({ fach_id: parseInt(i.dataset.fid), stunden: parseFloat(i.value) }));
  if (!stunden.length) return showMsg('p-msg', 'Mindestens einem Fach Stunden zuweisen.', 'err');

  const kompIds = [...document.querySelectorAll('.komp-cb:checked')].map(c => parseInt(c.value));
  const kompetenzen = [];
  for (const sid of schueler_ids) {
    for (const kid of kompIds) kompetenzen.push({ schueler_id: sid, kompetenz_id: kid });
  }

  try {
    await POST('projekte', {
      name, klasse_id, klasse_ids, schuljahr_id, datum_von, datum_bis,
      praesentation_datum, laufzeit, max_schueler,
      beschreibung, status, lehrer_ids, schueler_ids, stunden, kompetenzen
    });
    showMsg('p-msg', 'Werkstatt gespeichert ✓', 'ok');
    document.getElementById('p-name').value = '';
    document.getElementById('p-desc').value = '';
    document.getElementById('p-max').value = '';
    document.getElementById('p-praesentation').value = '';
    document.querySelectorAll('#p-fach-grid input').forEach(i => i.value = '');
    document.querySelectorAll('.komp-cb').forEach(c => c.checked = false);
    document.getElementById('p-summe').textContent = '0';
    teilnKeine('p');
    // Formular einklappen und Liste aktualisieren
    document.getElementById('neue-ws-wrap').style.display = 'none';
    document.getElementById('btn-neue-ws').textContent = '+ Neue Werkstatt';
    renderProjektListe();
  } catch(e) { showMsg('p-msg', e.message, 'err'); }
}

async function renderProjektListe() {
  const sjId = document.getElementById('p-schuljahr')?.value;
  const url  = 'projekte' + (sjId ? '?schuljahr_id=' + sjId : '');
  const data = await GET(url);
  const el   = document.getElementById('proj-liste');
  if (!data || !data.length) {
    el.innerHTML = '<div class="empty">Noch keine Werkstätten vorhanden. Klicke auf „+ Neue Werkstatt" um zu starten.</div>';
    return;
  }
  el.innerHTML = data.map(p => `
    <div class="proj-card">
      <div class="proj-row">
        <div style="flex:1">
          <div class="proj-name">${p.name}</div>
          <div class="proj-meta">
            ${p.datum_von}${p.datum_bis ? ' – ' + p.datum_bis : ''}
            ${p.klassen ? ' · ' + p.klassen : ''}
            ${/* keine-maskierung: schuljahre.name, beim Schreiben maskiert */ p.schuljahr_name ? ' · ' + p.schuljahr_name : ''}
            · ${p.schueler_anzahl} Schüler/innen
          </div>
          <div class="proj-meta" style="margin-top:2px">
            👤 ${/* keine-maskierung: benutzer (GROUP_CONCAT), beim Schreiben maskiert */ p.lernbegleiter || '–'}
            ${p.praesentation_datum ? ' · 🎤 ' + p.praesentation_datum : ''}
            ${p.max_schueler ? ' · max. ' + p.max_schueler + ' TN' : ''}
          </div>
          <div class="tags" style="margin-top:6px">
            <span class="tag-f">${p.laufzeit === 'halbjahr' ? 'Halbjahr' : 'Ganzjährig'}</span>
            <span class="tag-k">${p.kompetenzen_anzahl} Kompetenzen</span>
            <span class="tag-f">${p.status}</span>
          </div>
        </div>
        <div style="display:flex;flex-direction:column;gap:6px;align-self:center;margin-left:12px">
          <button class="btn btn-p" style="font-size:12px;padding:6px 12px"
                  onclick="openWerkstattDetail(${p.id})">Details</button>
        </div>
      </div>
    </div>`
  ).join('');
}

// ============================================================
// WERKSTATT-DETAIL MODAL
// ============================================================
async function openWerkstattDetail(id) {
  const modal = document.getElementById('ws-modal');
  modal.style.cssText = 'display:block;position:fixed;inset:0;z-index:200';
  modal.innerHTML = `<div class="modal-wrap"><div class="modal" style="width:560px;max-height:85vh;overflow-y:auto">
    <button class="modal-close" onclick="closeWsModal()">✕</button>
    <div style="color:var(--text3);font-size:13px;padding:40px 0;text-align:center">Lade…</div>
  </div></div>`;

  try {
    const [proj, schueler] = await Promise.all([
      GET(`projekte/${id}`),
      GET(`werkstatt/${id}/schueler`)
    ]);
    renderWerkstattDetail(proj, schueler || []);
  } catch(e) {
    modal.innerHTML = `<div class="modal-wrap"><div class="modal">
      <button class="modal-close" onclick="closeWsModal()">✕</button>
      <p style="color:var(--danger)">${e.message}</p>
    </div></div>`;
  }
}

function closeWsModal() {
  const modal = document.getElementById('ws-modal');
  modal.style.display = 'none';
  modal.innerHTML = '';
  renderProjektListe();
}

function renderWerkstattDetail(p, schueler) {
  const modal = document.getElementById('ws-modal');

  const lb = (p.lernbegleiter || []).map(l =>
    `<span class="tag-k">${/* keine-maskierung: benutzer, beim Schreiben maskiert */ l.vorname} ${l.nachname} (${l.rolle})</span>`
  ).join(' ');

  const statusOptionen = ['geplant','aktiv','abgeschlossen','abgesagt']
    .map(s => `<option value="${s}" ${s === p.status ? 'selected' : ''}>${s}</option>`).join('');

  const schuelerRows = schueler.map(s => `
    <div style="display:flex;align-items:center;gap:8px;padding:7px 0;border-bottom:1px solid var(--border)">
      <input type="checkbox" id="abs-${s.id}"
             ${s.abgeschlossen ? 'checked' : ''}
             onchange="toggleAbschluss(${p.id}, ${s.id}, this.checked)">
      <label for="abs-${s.id}" style="flex:1;cursor:pointer;font-size:13px;line-height:1.4">
        ${escHtml(s.nachname)}, ${escHtml(s.vorname)}
        <span style="color:var(--text3);font-size:11px">(${escHtml(s.klasse)})</span>
        ${s.abgeschlossen ? '<span style="color:var(--ok);font-size:11px;margin-left:4px">✓</span>' : ''}
      </label>
    </div>`
  ).join('');

  modal.innerHTML = `
  <div class="modal-wrap" onclick="if(event.target===this)closeWsModal()">
    <div class="modal" style="width:520px;max-height:88vh;overflow-y:auto">
      <button class="modal-close" onclick="closeWsModal()">✕</button>

      <h2>${p.name}</h2>
      <p class="modal-sub">
        ${p.datum_von}${p.datum_bis ? ' – ' + p.datum_bis : ''}
        ${/* keine-maskierung: schuljahre.name, beim Schreiben maskiert */ p.schuljahr_name ? ' · ' + p.schuljahr_name : ''}
      </p>
      <div style="margin-bottom:14px">${lb}</div>

      <!-- Status -->
      <div style="display:flex;gap:8px;align-items:flex-end;margin-bottom:16px">
        <div style="flex:1">
          <label style="font-size:12px;color:var(--text3)">Status</label>
          <select id="ws-status" style="width:100%">${statusOptionen}</select>
        </div>
        <button class="btn btn-p" style="white-space:nowrap" onclick="saveWsStatus(${p.id})">Speichern</button>
      </div>

      <!-- Teilnehmer -->
      <div class="sec" style="margin:0 0 8px">Teilnehmer/innen</div>
      <div style="margin-bottom:10px;display:flex;gap:8px">
        <button class="btn" style="font-size:12px" onclick="alleAbschliessen(${p.id}, true)">Alle ✓</button>
        <button class="btn" style="font-size:12px" onclick="alleAbschliessen(${p.id}, false)">Alle zurücksetzen</button>
      </div>
      <div id="ws-schueler-liste" style="max-height:300px;overflow-y:auto">
        ${schuelerRows || '<p style="color:var(--text3);font-size:13px">Keine Teilnehmer zugeordnet.</p>'}
      </div>

      <div class="modal-footer">
        <button class="btn btn-danger" onclick="werkstattLoeschen(${p.id})">Löschen</button>
        <button class="btn" onclick="closeWsModal()">Schließen</button>
        <button class="btn btn-p" onclick="closeWsModal();openWerkstattBearbeiten(${p.id})">✏️ Bearbeiten</button>
      </div>
    </div>
  </div>`;
}

// ============================================================
// WERKSTATT BEARBEITEN – eigene Seite
// ============================================================
let WS_EDIT_ID = null; // aktuelle Werkstatt-ID beim Bearbeiten
let WS_EDIT_AKTIVER_RAHMEN = 0;

// Die gewählten Kompetenzen beim Bearbeiten – ausserhalb des DOM (E33).
//
// Warum nicht aus den Häkchen lesen: Der Phasenfilter zeichnet nur die
// Kacheln der gewählten Phase. Was nicht gezeichnet ist, hat kein Häkchen –
// ein Phasenwechsel wäre Datenverlust. Die Menge ist die Wahrheit, das DOM
// nur ihre Anzeige.
//
// Kein Widerspruch zu E6 (kritische IDs ins DOM): E6 löst „überlebt einen
// Seitenneuladen", hier geht es um „überlebt ein Neuzeichnen".
let WS_EDIT_KOMP_IDS = new Set();
let WS_EDIT_PHASE = 'alle';

// Die Klassen, wie sie beim Öffnen zugeordnet waren (E38). Nur dafür da,
// beim Speichern zu zählen, wie viele Teilnehmer zu einer entfernten Klasse
// gehören.
let WS_EDIT_KLASSEN = [];

async function openWerkstattBearbeiten(id) {
  WS_EDIT_ID = id;
  go('werkstatt-edit');
  document.getElementById('we-id').value = id;

  // Zuerst leeren: Bricht das Laden ab, stünden sonst die Teilnehmer der
  // zuvor geöffneten Werkstatt in der Menge -- und ein Speichern schriebe
  // sie in diese hier.
  TEILN.we = { ids: new Set(), kandidaten: [], bestand: [] };

  // Daten laden
  const [proj, sjData] = await Promise.all([
    GET(`projekte/${id}`),
    GET('schuljahre')
  ]);

  // Untertitel
  document.getElementById('we-sub').textContent = `Werkstatt: ${proj.name}`;

  // Schuljahr
  const sjEl = document.getElementById('we-schuljahr');
  sjEl.innerHTML = '<option value="">– kein –</option>' +
    (sjData || []).map(s =>
      `<option value="${s.id}" ${/* keine-maskierung: s ist hier ein Schuljahr, beim Schreiben maskiert */ s.id == proj.schuljahr_id ? 'selected' : ''}>${s.name}</option>`
    ).join('');

  // Felder befüllen
  document.getElementById('we-name').value       = proj.name || '';
  document.getElementById('we-von').value        = proj.datum_von || '';
  document.getElementById('we-bis').value        = proj.datum_bis || '';
  document.getElementById('we-praesentation').value = proj.praesentation_datum || '';
  document.getElementById('we-max').value        = proj.max_schueler || '';
  document.getElementById('we-desc').value       = proj.beschreibung || '';
  document.getElementById('we-laufzeit').value   = proj.laufzeit || 'jahr';
  document.getElementById('we-status').value     = proj.status || 'geplant';

  // Lernbegleiter
  const lbIds = (proj.lernbegleiter || []).map(l => l.id);
  const lEl = document.getElementById('we-lehrer');
  lEl.innerHTML = STATE.lehrer.map(l =>
    `<option value="${l.id}" ${lbIds.includes(l.id) ? 'selected' : ''}>${/* keine-maskierung: benutzer, beim Schreiben maskiert */ l.vorname} ${l.nachname}${l.kuerzel ? ' (' + l.kuerzel + ')' : ''}</option>`
  ).join('');

  // Klassen (E38). Vorbelegt mit den zugeordneten; das Feld gab es vorher
  // nicht, die Zuordnung war unveränderlich.
  const wsKl = (proj.klasse_ids || []).map(Number);
  WS_EDIT_KLASSEN = wsKl.slice();   // Ausgangsstand für die Rückfrage beim Speichern
  document.getElementById('we-kl').innerHTML = STATE.klassen.map(k =>
    `<option value="${k.id}" ${wsKl.includes(Number(k.id)) ? 'selected' : ''}>${escHtml(k.bezeichnung)} (${escHtml(k.schuljahr)})</option>`
  ).join('');

  // Teilnehmer (E34, E35)
  //
  // Vorbelegung ist die gefährliche Stelle: Schlägt sie fehl und ersetzt das
  // Speichern die Liste, sind alle Teilnehmer weg. Bei den Kompetenzen hat
  // genau das drei Monate lang unbemerkt stattgefunden (E33). Deshalb wird
  // die Menge hier gefüllt, BEVOR gezeichnet wird, und jede Kachel liest
  // ihren Zustand aus ihr.
  TEILN.we.bestand = proj.schueler || [];
  TEILN.we.ids     = new Set(TEILN.we.bestand.map(x => Number(x.id)));

  // Wählbar sind die Schüler der Klassen dieser Werkstatt. Teilnehmer, die
  // in keiner davon sind -- etwa nach einem Klassenwechsel --, kommen
  // hinzu: Wer nicht gezeichnet wird, liesse sich sonst nicht abwählen.
  await loadSchuelerForWerkstattEdit();

  // Fach-Grid mit vorhandenen Stunden
  document.getElementById('we-fach-grid').innerHTML = STATE.faecher.map(f => {
    const st = (proj.stunden || []).find(s => s.fach_id == f.id);
    return `<div class="fach-item">
      <span>${f.name}</span>
      <input type="number" min="0" max="40" step="0.5" placeholder="0"
             data-fid="${f.id}" data-fkuerzel="${f.kuerzel}"
             value="${st ? st.stunden : ''}"
             oninput="onWeStundenChange()">
    </div>`;
  }).join('');
  onWeStundenChange();

  // Vorhandene Kompetenzen in die Menge übernehmen, BEVOR gezeichnet wird
  // (E33). Vorher lief das über einen setTimeout und den Selektor
  // `#we-komp-bereich-list .komp-cb` – der traf nichts, weil hier
  // `we-komp-cb` gezeichnet wird. Ein CSS-Klassenselektor trifft ganze
  // Klassennamen, keine Teilzeichenketten. Folge: kein Häkchen wurde
  // gesetzt, und beim Speichern ging die gesamte Auswahl verloren.
  WS_EDIT_KOMP_IDS = new Set((proj.kompetenzen || []).map(k => parseInt(k.id)));
  WS_EDIT_PHASE = 'alle';

  await loadKompetenzenFuerFaecherWe([]);
  renderRahmenTabsWe();
}

function onWeStundenChange() {
  let s = 0;
  document.querySelectorAll('#we-fach-grid input').forEach(i => s += parseFloat(i.value) || 0);
  document.getElementById('we-summe').textContent = Math.round(s * 10) / 10;
  const fids = [...document.querySelectorAll('#we-fach-grid input')]
    .filter(i => parseFloat(i.value) > 0).map(i => parseInt(i.dataset.fid));
  loadKompetenzenFuerFaecherWe(fids).then(renderRahmenTabsWe);
}

async function loadKompetenzenFuerFaecherWe(fachIds) {
  const all = await GET('kompetenzen');
  STATE.kompetenzen = all || [];
}

function renderRahmenTabsWe() {
  const fids = [...document.querySelectorAll('#we-fach-grid input')]
    .filter(i => parseFloat(i.value) > 0).map(i => parseInt(i.dataset.fid));
  const relRahmen = STATE.rahmen.filter(r => {
    if (!r.fach_kuerzel) return true;
    if (!fids.length) return false;
    return fids.some(fid => {
      const f = STATE.faecher.find(x => x.id == fid);
      return f && f.kuerzel === r.fach_kuerzel;
    });
  });
  const tabEl = document.getElementById('we-rahmen-tabs');
  if (!relRahmen.length) { tabEl.innerHTML = ''; return; }
  if (!WS_EDIT_AKTIVER_RAHMEN || !relRahmen.find(r => r.id === WS_EDIT_AKTIVER_RAHMEN)) {
    WS_EDIT_AKTIVER_RAHMEN = relRahmen[0].id;
  }
  tabEl.innerHTML = relRahmen.map(r =>
    `<button class="rtab${r.id === WS_EDIT_AKTIVER_RAHMEN ? ' on' : ''}"
             onclick="switchRahmenWe(${r.id})">${r.kuerzel} – ${r.name}</button>`
  ).join('');
  renderKompBereichListWe(WS_EDIT_AKTIVER_RAHMEN, fids);
}

function switchRahmenWe(rid) {
  WS_EDIT_AKTIVER_RAHMEN = rid;
  renderRahmenTabsWe();
}

// Ein Klick pflegt die Menge, nicht das DOM. Aufgerufen aus dem onchange
// jeder Kachel; das Häkchen selbst ist nur Anzeige.
function weKompUmschalten(id, an) {
  if (an) WS_EDIT_KOMP_IDS.add(Number(id));
  else    WS_EDIT_KOMP_IDS.delete(Number(id));
  weAuswahlzahlZeigen();
}

// Zeigt, wie viele Kompetenzen insgesamt gewählt sind – über alle Phasen.
// Ohne diese Zahl wäre nach einem Phasenwechsel nicht erkennbar, dass in
// einer anderen Phase noch etwas ausgewählt ist.
function weAuswahlzahlZeigen() {
  const el = document.getElementById('we-phase-tabs');
  if (!el) return;
  const zaehler = el.querySelector('.we-komp-zahl');
  if (zaehler) zaehler.textContent = WS_EDIT_KOMP_IDS.size + ' gewählt';
}

function switchWePhase(key) {
  WS_EDIT_PHASE = key;
  renderRahmenTabsWe();
}

function renderKompBereichListWe(rahmen_id, fachIds) {
  // Gleiche Logik wie renderKompBereichList aber für #we-komp-bereich-list
  const fids = fachIds || [];
  const r = STATE.rahmen.find(x => x.id === rahmen_id);
  if (!r) return;
  let komp = STATE.kompetenzen.filter(k => {
    if (k.rahmen_kuerzel !== r.kuerzel) return false;
    if (k.fach_kuerzel && fids.length > 0)
      return fids.some(fid => { const f = STATE.faecher.find(x => x.id == fid); return f && f.kuerzel === k.fach_kuerzel; });
    return true;
  });

  // Phasen-Tabs wie im Katalog (Befund 3). Ohne sie zeigt Deutsch 226
  // gleichrangige Kacheln in 28 Blöcken.
  //
  // Der Filter blendet nur die ANZEIGE. Die Auswahl steht in
  // WS_EDIT_KOMP_IDS und bleibt über einen Phasenwechsel hinweg erhalten.
  const tabsEl = document.getElementById('we-phase-tabs');
  const phasen = phasenAusKompetenzen(komp);
  if (tabsEl) {
    if (phasen.length) {
      if (WS_EDIT_PHASE !== 'alle' && !phasen.some(p => p.key === WS_EDIT_PHASE)) WS_EDIT_PHASE = 'alle';
      const tab = (key, label, color) =>
        `<button type="button" class="ptab${WS_EDIT_PHASE === key ? ' on' : ''}" onclick="switchWePhase('${key}')">` +
        (color ? `<span class="dot" style="background:${color}"></span>` : '') + `${label}</button>`;
      tabsEl.innerHTML = tab('alle', 'Alle Phasen', null) +
        phasen.map(p => tab(p.key, p.label, p.color)).join('') +
        `<span class="we-komp-zahl" style="margin-left:auto;font-size:11px;color:var(--text2)">${WS_EDIT_KOMP_IDS.size} gewählt</span>`;
      tabsEl.style.display = 'flex';
      if (WS_EDIT_PHASE !== 'alle') komp = komp.filter(k => k.phase === WS_EDIT_PHASE);
    } else {
      tabsEl.innerHTML = '';
      tabsEl.style.display = 'none';
    }
  }

  const allgemeine = komp.filter(k => !k.eltern_kompetenz_id);
  const erwartungen = komp.filter(k => k.eltern_kompetenz_id);
  const erwByEltern = {};
  erwartungen.forEach(e => { (erwByEltern[e.eltern_kompetenz_id] = erwByEltern[e.eltern_kompetenz_id] || []).push(e); });
  const bereiche = {};
  allgemeine.forEach(k => { const b = k.bereich_code + ': ' + k.bereich_name; (bereiche[b] = bereiche[b] || []).push(k); });
  const el = document.getElementById('we-komp-bereich-list');
  if (!Object.keys(bereiche).length) { el.innerHTML = '<p style="font-size:12px;color:var(--text3)">Keine Kompetenzen verfügbar.</p>'; return; }

  // Jede Kachel liest ihren Zustand aus WS_EDIT_KOMP_IDS – nie umgekehrt.
  // Sonst laufen Menge und Anzeige beim Neuzeichnen auseinander (E33).
  // Number() an jeder Stelle: Die Menge führt Zahlen, und ob die API eine ID
  // als Zahl oder als Zeichenkette liefert, ist nicht durchgängig belegt —
  // der Bestand vergleicht an manchen Stellen lose (`==`), an anderen streng.
  // Ein Set unterscheidet 42 und "42"; ohne Number() träfe `has` dann nie.
  const cb = k => `<input type="checkbox" class="we-komp-cb" value="${k.id}"` +
    `${WS_EDIT_KOMP_IDS.has(Number(k.id)) ? ' checked' : ''}` +
    ` onchange="weKompUmschalten(${Number(k.id)}, this.checked)">`;

  el.innerHTML = Object.entries(bereiche).map(([b, ks]) => {
    const items = ks.map(k => {
      const kinder = erwByEltern[k.id] || [];
      const tid = 'we-erw-' + k.id;
      let html = `<div class="komp-eltern-row"><label class="komp-pill">
        ${cb(k)}
        <span class="pill-label" title="${k.beschreibung||''}">${k.kurzname}</span></label>`;
      if (kinder.length) html += `<button type="button" class="komp-eltern-toggle" onclick="toggleErw('${tid}',this)">▸ ${kinder.length}</button>`;
      html += `</div>`;
      if (kinder.length) {
        html += `<div class="komp-erwartungen" id="${tid}">` +
          kinder.map(e => `<label class="komp-pill erw">${cb(e)}
            <span class="pill-label" title="${e.beschreibung||''}">${e.kurzname}</span></label>`).join('') + `</div>`;
      }
      return html;
    }).join('');
    return `<div class="bereich-block"><div class="bereich-title">${b}</div><div class="komp-grid">${items}</div></div>`;
  }).join('');
}

async function werkstattEditSpeichern() {
  const id = parseInt(document.getElementById('we-id').value) || WS_EDIT_ID;
  if (!id) return showMsg('we-msg', 'Fehler: Werkstatt-ID nicht gefunden. Bitte neu öffnen.', 'err');

  const name       = document.getElementById('we-name').value.trim();
  const datum_von  = document.getElementById('we-von').value;
  const datum_bis  = document.getElementById('we-bis').value || null;
  const praesentation_datum = document.getElementById('we-praesentation').value || null;
  const laufzeit   = document.getElementById('we-laufzeit').value;
  const max_schueler = document.getElementById('we-max').value ? parseInt(document.getElementById('we-max').value) : null;
  const beschreibung = document.getElementById('we-desc').value.trim();
  const status     = document.getElementById('we-status').value;
  const schuljahr_id = parseInt(document.getElementById('we-schuljahr').value) || null;
  const lehrer_ids = [...document.getElementById('we-lehrer').selectedOptions].map(o => parseInt(o.value));

  const stunden = [...document.querySelectorAll('#we-fach-grid input')]
    .filter(i => parseFloat(i.value) > 0)
    .map(i => ({ fach_id: parseInt(i.dataset.fid), stunden: parseFloat(i.value) }));

  // Aus der Menge, nicht aus dem DOM (E33): Was der Phasenfilter gerade
  // nicht zeichnet, hat kein Häkchen — wäre die Quelle das DOM, löschte
  // ein Phasenwechsel die Auswahl der übrigen Phasen.
  const kompIds = [...WS_EDIT_KOMP_IDS];

  // Teilnehmer aus derselben Menge, aus demselben Grund.
  const schueler_ids = teilnIds('we');
  const klasse_ids   = [...document.getElementById('we-kl').selectedOptions].map(o => parseInt(o.value));

  if (!name || !datum_von) return showMsg('we-msg', 'Name und Startdatum sind Pflichtfelder.', 'err');
  if (!lehrer_ids.length) return showMsg('we-msg', 'Mindestens einen Lernbegleiter wählen.', 'err');
  if (!klasse_ids.length) return showMsg('we-msg', 'Mindestens eine Klasse wählen.', 'err');

  // Rückfrage vor dem Entfernen (E34). Gefragt wird beim Speichern, nicht
  // beim Abwählen: Abwählen ist ein Versuch, gelöscht wird erst hier -- und
  // die Rückfrage nennt in einem Zug alles, was verlorengeht.
  //
  // Wer nichts Erfasstes hat, geht ohne Rückfrage. Der Schutz ist nicht die
  // Unmöglichkeit des Entfernens, sondern die Sichtbarkeit dessen, was
  // verschwindet -- es gibt keinen Papierkorb.
  const weg = TEILN.we.bestand.filter(b => !TEILN.we.ids.has(Number(b.id)));
  const wegMitInhalt = weg.filter(b => teilnWasErfasst(b) !== '');

  // Zusätzlich gefragt wird, wenn ALLE Teilnehmer verschwänden -- auch wenn
  // zu keinem etwas erfasst ist. Genau so sah der Fehler aus E33 aus: eine
  // leere Liste ist ein gültiger Wert und deshalb von einer fehlgeschlagenen
  // Vorbelegung nicht zu unterscheiden. Die Rückfrage ist die einzige
  // Stelle, an der ein Mensch den Unterschied sieht.
  const leertAlle = TEILN.we.bestand.length > 0 && TEILN.we.ids.size === 0;

  if (wegMitInhalt.length || leertAlle) {
    let text;
    if (wegMitInhalt.length) {
      const zeilen = wegMitInhalt
        .map(b => `\u2022 ${/* keine-maskierung: Text einer confirm-Rueckfrage, kein HTML */ b.nachname}, ${b.vorname}: ${teilnWasErfasst(b)}`).join('\n');
      text = `${wegMitInhalt.length === 1 ? 'Ein Teilnehmer wird' : wegMitInhalt.length + ' Teilnehmer werden'} `
           + `entfernt. Das Erfasste geht dabei unwiderruflich verloren:\n\n${zeilen}\n\n`;
      if (leertAlle) text += `Die Werkstatt hat danach keine Teilnehmer mehr.\n\n`;
    } else {
      text = `Alle ${TEILN.we.bestand.length} Teilnehmer werden entfernt. `
           + `Die Werkstatt hat danach keine Teilnehmer mehr.\n\n`;
    }
    if (!confirm(text + 'Wirklich entfernen?')) return;
  }

  // Rückfrage beim Entfernen einer Klasse (E38). Sie zählt und blockiert
  // nicht: Die Teilnehmer bleiben, nichts wird gelöscht. Gesagt werden muss
  // es trotzdem -- sonst merkt niemand, dass die Werkstatt danach Teilnehmer
  // aus einer nicht zugeordneten Klasse führt.
  const wegKlassen = WS_EDIT_KLASSEN.filter(k => !klasse_ids.includes(Number(k)));
  if (wegKlassen.length) {
    const betroffen = TEILN.we.bestand.filter(b =>
      TEILN.we.ids.has(Number(b.id)) && wegKlassen.includes(Number(b.klasse_id)));
    const namen = wegKlassen
      .map(k => (STATE.klassen.find(x => Number(x.id) === Number(k)) || {}).bezeichnung || k)
      .join(', ');
    let text = `Klasse${wegKlassen.length === 1 ? '' : 'n'} ${namen} wird von dieser Werkstatt entfernt.\n\n`;
    text += betroffen.length
      ? `${betroffen.length} Teilnehmer ${betroffen.length === 1 ? 'gehört' : 'gehören'} dazu. `
        + `${betroffen.length === 1 ? 'Er bleibt' : 'Sie bleiben'} Teilnehmer – es geht nichts verloren.\n\n`
      : 'Kein Teilnehmer gehört dazu.\n\n';
    if (!confirm(text + 'Fortfahren?')) return;
  }

  try {
    const r = await fetch('/api/projekte/' + id, {
      method: 'PUT',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name, datum_von, datum_bis, laufzeit, praesentation_datum,
        max_schueler, beschreibung, status, schuljahr_id,
        lehrer_ids, stunden, kompetenz_ids: kompIds, schueler_ids, klasse_ids
      })
    });
    const data = await r.json();
    if (!r.ok) throw new Error(data.error || 'Fehler');
    showMsg('we-msg', 'Gespeichert ✓', 'ok');
    setTimeout(() => {
      go('projekt');
      renderProjektListe();
    }, 800);
  } catch(e) { showMsg('we-msg', e.message, 'err'); }
}

async function saveWsStatus(id) {
  const status = document.getElementById('ws-status').value;
  try {
    const r = await fetch('/api/werkstatt/' + id + '/status', {
      method: 'PUT',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status })
    });
    const data = await r.json();
    if (!r.ok) throw new Error(data.error || 'Fehler');
    // Kurze Bestätigung im Modal
    const btn = document.querySelector(`button[onclick="saveWsStatus(${id})"]`);
    if (btn) { btn.textContent = '✓'; setTimeout(() => btn.textContent = 'Speichern', 1500); }
  } catch(e) { alert('Status konnte nicht gespeichert werden: ' + e.message); }
}

async function toggleAbschluss(proj_id, schueler_id, abgeschlossen) {
  try {
    await fetch(`/api/werkstatt/${proj_id}/abschluss`, {
      method: 'PUT',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ schueler_id, abgeschlossen })
    });
    const lbl = document.querySelector(`label[for="abs-${schueler_id}"]`);
    if (!lbl) return;
    const haken = lbl.querySelector('span[style*="--ok"]');
    if (abgeschlossen && !haken) {
      lbl.insertAdjacentHTML('beforeend',
        '<span style="color:var(--ok);font-size:11px;margin-left:4px">✓</span>');
    } else if (!abgeschlossen && haken) {
      haken.remove();
    }
  } catch(e) { alert(e.message); }
}

async function alleAbschliessen(proj_id, abgeschlossen) {
  try {
    await fetch(`/api/werkstatt/${proj_id}/abschluss`, {
      method: 'PUT',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ alle: true, abgeschlossen })
    });
    // Modal neu laden
    const [proj, schueler] = await Promise.all([
      GET(`projekte/${proj_id}`),
      GET(`werkstatt/${proj_id}/schueler`)
    ]);
    renderWerkstattDetail(proj, schueler || []);
  } catch(e) { alert(e.message); }
}

async function werkstattLoeschen(id) {
  if (!confirm('Werkstatt wirklich löschen? Alle Daten (Stunden, Kompetenzen) werden entfernt.')) return;
  try {
    await DELETE(`projekte/${id}`);
    closeWsModal();
  } catch(e) { alert(e.message); }
}

// ============================================================
// SCHÜLER
// ============================================================
// ============================================================
// SCHÜLER & KLASSEN (zusammengeführt)
// ============================================================
let SCHUELER_ALLE = []; // Cache für Suche/Sortierung

async function initSchueler() {
  const isAdmin = STATE.user?.rolle === 'admin';

  // Klassen-Dropdown für Anlegen (nur Admin sieht Card)
  const klSel = document.getElementById('s-kl');
  if (klSel) {
    klSel.innerHTML = '<option value="">– wählen –</option>' +
      STATE.klassen.map(k => `<option value="${k.id}">${escHtml(k.bezeichnung)} (${escHtml(k.schuljahr)})</option>`).join('');
  }

  // Klassen-Filter befüllen
  const ksEl = document.getElementById('sch-klasse');
  if (ksEl) {
    ksEl.innerHTML = '<option value="">Alle Klassen</option>' +
      STATE.klassen.map(k => `<option value="${escHtml(k.bezeichnung)}">${escHtml(k.bezeichnung)}</option>`).join('');
  }

  // Schuljahr-Feld vorausfüllen
  const sjEl = document.getElementById('kl-sj');
  if (sjEl && !sjEl.value) {
    const aktiv = STATE.schuljahre?.find(s => s.aktiv);
    if (aktiv) sjEl.value = aktiv.name;
  }

  // Schüler laden
  SCHUELER_ALLE = await GET('schueler') || [];
  schuelerRendern();
}

function schuelerRendern() {
  const suche = (document.getElementById('sch-suche')?.value || '').toLowerCase();
  const klass = document.getElementById('sch-klasse')?.value || '';
  const sort  = document.getElementById('sch-sort')?.value  || 'nachname_asc';
  const isAdmin = STATE.user?.rolle === 'admin';

  let liste = SCHUELER_ALLE.filter(s => {
    const volname = `${/* keine-maskierung: Suchzeichenkette, wird nie ausgegeben */ s.vorname} ${s.nachname} ${s.klasse}`.toLowerCase();
    const klasseOk = !klass || s.klasse === klass;
    return klasseOk && (!suche || volname.includes(suche));
  });

  // Sortieren
  const [feld, richtung] = sort.split('_');
  liste.sort((a, b) => {
    const va = (a[feld] || '').toLowerCase();
    const vb = (b[feld] || '').toLowerCase();
    return richtung === 'asc' ? va.localeCompare(vb) : vb.localeCompare(va);
  });

  // Statistik
  const stats = document.getElementById('sch-stats');
  if (stats) {
    stats.textContent = `${liste.length} von ${SCHUELER_ALLE.length} Schüler/innen`;
  }

  const el = document.getElementById('s-liste');
  if (!liste.length) {
    el.innerHTML = '<div class="empty">Keine Schüler gefunden.</div>';
    return;
  }

  // Klassen-Gruppen
  const gruppen = {};
  liste.forEach(s => (gruppen[s.klasse] = gruppen[s.klasse] || []).push(s));

  el.innerHTML = Object.keys(gruppen).sort().map(kl => {
    const klInfo = STATE.klassen.find(k => k.bezeichnung === kl);
    return `
    <div class="card" style="margin-bottom:12px">
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:8px">
        <div>
          <strong>Klasse ${kl}</strong>
          <span style="font-size:11px;color:var(--text3);margin-left:8px">
            ${klInfo?.schuljahr ? escHtml(klInfo.schuljahr) + ' · ' : ''}${gruppen[kl].length} Schüler/innen
          </span>
        </div>
      </div>
      ${gruppen[kl].map(s => `
        <div style="display:flex;align-items:center;gap:10px;padding:6px 0;border-bottom:1px solid var(--border)">
          <div class="avatar">${escHtml(s.vorname[0])}${escHtml(s.nachname[0])}</div>
          <div style="flex:1">
            <span style="font-size:13px">${escHtml(s.nachname)}, ${escHtml(s.vorname)}</span>
          </div>
          ${/* keine-maskierung: escHtml genuegt hier NICHT: Name in einer JS-Zeichenkette im Attribut, siehe E42 */ isAdmin ? `<button class="btn btn-sm btn-d" onclick="delSchueler(${s.id}, '${s.vorname} ${s.nachname}')">entfernen</button>` : ''}
        </div>`
      ).join('')}
    </div>`;
  }).join('');
}

async function schuelerSpeichern() {
  const vorname   = document.getElementById('s-vor').value.trim();
  const nachname  = document.getElementById('s-nach').value.trim();
  const klasse_id = parseInt(document.getElementById('s-kl').value);
  if (!vorname || !nachname || !klasse_id)
    return showMsg('s-msg', 'Alle Felder ausfüllen.', 'err');
  try {
    await POST('schueler', { vorname, nachname, klasse_id });
    showMsg('s-msg', vorname + ' ' + nachname + ' angelegt.', 'ok');
    document.getElementById('s-vor').value = '';
    document.getElementById('s-nach').value = '';
    SCHUELER_ALLE = await GET('schueler') || [];
    schuelerRendern();
  } catch(e) { showMsg('s-msg', e.message, 'err'); }
}

async function delSchueler(id, name) {
  if (!confirm(`${name} wirklich entfernen?`)) return;
  try {
    await DELETE('schueler/' + id);
    SCHUELER_ALLE = SCHUELER_ALLE.filter(s => s.id !== id);
    schuelerRendern();
  } catch(e) { alert(e.message); }
}

// Klasse anlegen (nur Admin, im aufklappbaren Block)
async function klasseSpeichern() {
  const bezeichnung = document.getElementById('kl-bez').value.trim();
  const jahrgang    = parseInt(document.getElementById('kl-jg').value);
  const schuljahr   = document.getElementById('kl-sj').value.trim();
  if (!bezeichnung || !jahrgang || !schuljahr)
    return showMsg('kl-msg', 'Alle Felder ausfüllen.', 'err');
  try {
    await POST('klassen', { bezeichnung, jahrgang, schuljahr });
    showMsg('kl-msg', 'Klasse ' + bezeichnung + ' angelegt.', 'ok');
    document.getElementById('kl-bez').value = '';
    document.getElementById('kl-jg').value  = '';
    await loadState();
    // Dropdowns aktualisieren
    const klSel = document.getElementById('s-kl');
    if (klSel) {
      klSel.innerHTML = '<option value="">– wählen –</option>' +
        STATE.klassen.map(k => `<option value="${k.id}">${escHtml(k.bezeichnung)} (${escHtml(k.schuljahr)})</option>`).join('');
    }
    const ksEl = document.getElementById('sch-klasse');
    if (ksEl) {
      ksEl.innerHTML = '<option value="">Alle Klassen</option>' +
        STATE.klassen.map(k => `<option value="${escHtml(k.bezeichnung)}">${escHtml(k.bezeichnung)}</option>`).join('');
    }
  } catch(e) { showMsg('kl-msg', e.message, 'err'); }
}

// initKlassen leitet jetzt auf Schüler-Screen weiter
async function initKlassen() { initSchueler(); }
async function renderKlassenListe() {}

// ============================================================
// KOMPETENZKATALOG
// ============================================================
async function initKatalog() {
  const all = await GET('kompetenzen');
  STATE.kompetenzen = all || [];
  renderKatRahmenAuswahl();
  renderKatalog();
}

// Ein Auswahlfeld statt zwei (E32), gruppiert nach Fach, jeder Rahmen mit der
// Zahl seiner Kompetenzen. Zwei unabhängige Und-Filter konnten einander
// widerlegen — Rahmen „Sport" plus Fach „Spanisch" ergab eine leere Ansicht.
//
// Die Zahl kommt aus STATE.kompetenzen, das ohnehin im Frontend liegt; dafür
// braucht es keine API-Änderung. Leere Rahmen werden aufgeführt und als leer
// gekennzeichnet — sonst sind sie nicht von nicht vorhandenen zu unterscheiden.
function renderKatRahmenAuswahl() {
  const rEl = document.getElementById('kat-rahmen');
  if (!rEl) return;
  const anzahl = {};
  STATE.kompetenzen.forEach(k => {
    anzahl[k.rahmen_kuerzel] = (anzahl[k.rahmen_kuerzel] || 0) + 1;
  });
  // Nach Fach gruppieren; Rahmen ohne Fach kommen unter „Fächerübergreifend".
  const gruppen = new Map();
  STATE.rahmen.forEach(r => {
    const g = r.fach_name || 'Fächerübergreifend';
    if (!gruppen.has(g)) gruppen.set(g, []);
    gruppen.get(g).push(r);
  });
  const sortiert = [...gruppen.entries()].sort((a, b) => {
    if (a[0] === 'Fächerübergreifend') return 1;   // ans Ende
    if (b[0] === 'Fächerübergreifend') return -1;
    return a[0].localeCompare(b[0], 'de');
  });
  rEl.innerHTML = '<option value="">Alle Rahmen</option>' + sortiert.map(([fach, rs]) =>
    `<optgroup label="${fach}">` + rs.map(r => {
      const n = anzahl[r.kuerzel] || 0;
      const zusatz = n ? ` (${n})` : ' – noch nicht befüllt';
      return `<option value="${r.id}">${r.name}${zusatz}</option>`;
    }).join('') + `</optgroup>`
  ).join('');
}
// Phasen-Metadaten (Reihenfolge + Farbe pro Schulphase).
// Die Reihenfolge dieser Liste bestimmt die Reihenfolge der Tabs; die
// Schlüssel müssen den ENUM-Werten von kompetenzbereiche.phase entsprechen.
// Das prüft tests-projektstunden.sh gegen sql/14_… — ein Wert, der hier
// fehlt, fiel früher still weg (Befund 1).
//
// Die FARBEN stehen in style.css im :root-Block (REIHENREGELN 7); hier
// stehen nur ihre Namen. Zwei je Phase: `color` faerbt Punkt und Kante,
// `flaeche` das Etikett -- frueher entstand die Flaeche durch Anhaengen
// von "33" an den Hexwert, und genau das ginge mit einer Variablen still
// schief.
//
// Die Namen sind AUSGESCHRIEBEN und nicht aus `key` zusammengesetzt. Das
// ist Absicht: Die Pruefung "CSS-Variablen" (E58) sieht ausgeschriebene
// Namen und meldet einen, den es nicht gibt. Ein Vertipper bei
// `sek1_uebergreifend` -- dem zuletzt hinzugekommenen Wert -- wird damit
// rot, statt eine farblose Kachel zu erzeugen.
const KAT_PHASEN = [
  { key: 'erprobungsstufe',        label: 'Erprobungsstufe',       // hellblau
    color: 'var(--phase-erprobungsstufe)',          flaeche: 'var(--phase-erprobungsstufe-bg)' },
  { key: 'sek1_uebergreifend',     label: 'Sek I übergreifend',    // helltürkis
    color: 'var(--phase-sek1-uebergreifend)',       flaeche: 'var(--phase-sek1-uebergreifend-bg)' },
  { key: 'erste_stufe',            label: 'Erste Stufe',           // hellgrün
    color: 'var(--phase-erste-stufe)',              flaeche: 'var(--phase-erste-stufe-bg)' },
  { key: 'zweite_stufe',           label: 'Zweite Stufe',          // hellgelb
    color: 'var(--phase-zweite-stufe)',             flaeche: 'var(--phase-zweite-stufe-bg)' },
  { key: 'einfuehrungsphase',      label: 'Einführungsphase',      // hellorange
    color: 'var(--phase-einfuehrungsphase)',        flaeche: 'var(--phase-einfuehrungsphase-bg)' },
  { key: 'qualifikationsphase_gk', label: 'Q-Phase Grundkurs',     // hellrot
    color: 'var(--phase-qualifikationsphase-gk)',   flaeche: 'var(--phase-qualifikationsphase-gk-bg)' },
  { key: 'qualifikationsphase_lk', label: 'Q-Phase Leistungskurs', // helllila
    color: 'var(--phase-qualifikationsphase-lk)',   flaeche: 'var(--phase-qualifikationsphase-lk-bg)' },
];
let AKT_KAT_PHASE = 'alle';

// Bereits gemeldete unbekannte Phasenwerte – damit die Konsole bei jedem
// Neuzeichnen nicht dieselbe Meldung wiederholt.
const PHASEN_UNBEKANNT = new Set();

// Liefert die Phasen, die in `komps` wirklich vorkommen, in der Reihenfolge
// von KAT_PHASEN. Ein Wert, den KAT_PHASEN nicht kennt, wird NICHT
// verschluckt: Er wird gemeldet und ohne Farbe angehängt.
//
// Das ist der eigentliche Gegenstand von Befund 1. Die fehlende Zeile für
// `sek1_uebergreifend` war nur die Auswirkung; der Fehler war, dass ein
// unbekannter Wert spurlos verschwand – samt seiner 21 Kompetenzerwartungen.
function phasenAusKompetenzen(komps) {
  const bekannt = KAT_PHASEN.filter(p => komps.some(k => k.phase === p.key));
  const fremd = [];
  komps.forEach(k => {
    if (!k.phase) return;                                   // NULL ist zulässig (MKR)
    if (KAT_PHASEN.some(p => p.key === k.phase)) return;
    if (fremd.some(f => f.key === k.phase)) return;
    fremd.push({ key: k.phase, label: k.phase, color: null, flaeche: null });
    if (!PHASEN_UNBEKANNT.has(k.phase)) {
      PHASEN_UNBEKANNT.add(k.phase);
      console.warn('[Kompetenzkatalog] Unbekannter Phasenwert "' + k.phase +
        '" – bitte in KAT_PHASEN aufnehmen (app.js). Wird ohne Farbe angezeigt.');
    }
  });
  return bekannt.concat(fremd);
}

// Beim Wechsel von Rahmen-/Fachfilter Phasenauswahl zurücksetzen
function katRahmenWechsel() {
  AKT_KAT_PHASE = 'alle';
  renderKatalog();
}
function switchKatPhase(key) {
  AKT_KAT_PHASE = key;
  renderKatalog();
}

function renderKatalog() {
  const rid = parseInt(document.getElementById('kat-rahmen').value) || 0;
  let komps = STATE.kompetenzen;
  if (rid) komps = komps.filter(k => { const r = STATE.rahmen.find(x => x.id === rid); return r && k.rahmen_kuerzel === r.kuerzel; });

  // Phasen-Tabs: nur anzeigen, wenn die gefilterten Kompetenzen Phasen-Angaben haben
  const tabsEl = document.getElementById('kat-phase-tabs');
  const phasenPresent = phasenAusKompetenzen(komps);
  if (phasenPresent.length && tabsEl) {
    if (AKT_KAT_PHASE !== 'alle' && !phasenPresent.some(p => p.key === AKT_KAT_PHASE)) AKT_KAT_PHASE = 'alle';
    const tab = (key, label, color) =>
      `<button class="ptab${AKT_KAT_PHASE === key ? ' on' : ''}" onclick="switchKatPhase('${key}')">` +
      (color ? `<span class="dot" style="background:${color}"></span>` : '') + `${label}</button>`;
    tabsEl.innerHTML = tab('alle', 'Alle Phasen', null) +
      phasenPresent.map(p => tab(p.key, p.label, p.color)).join('');
    tabsEl.style.display = 'flex';
    if (AKT_KAT_PHASE !== 'alle') komps = komps.filter(k => k.phase === AKT_KAT_PHASE);
  } else if (tabsEl) {
    tabsEl.innerHTML = '';
    tabsEl.style.display = 'none';
  }

  // Allgemeine und Erwartungen trennen
  const allgemeine = komps.filter(k => !k.eltern_kompetenz_id);
  const erwartungen = komps.filter(k => k.eltern_kompetenz_id);
  const erwByEltern = {};
  erwartungen.forEach(e => { (erwByEltern[e.eltern_kompetenz_id] = erwByEltern[e.eltern_kompetenz_id] || []).push(e); });

  // Nach Bereichen gruppieren (nur allgemeine)
  const bereiche = {};
  allgemeine.forEach(k => {
    const b = (k.rahmen_kuerzel || '') + '|' + k.bereich_code + '|' + k.bereich_name;
    (bereiche[b] = bereiche[b] || []).push(k);
  });

  const el = document.getElementById('kat-list');
  if (!Object.keys(bereiche).length) { el.innerHTML = '<div class="empty">Keine Kompetenzen gefunden.</div>'; return; }
  el.innerHTML = Object.entries(bereiche).map(([b, ks]) => {
    const [rahmen, , bereichName] = b.split('|');
    const pMeta = KAT_PHASEN.find(p => p.key === ks[0].phase);
    const cardStyle = pMeta ? ` style="border-left:4px solid ${pMeta.color}"` : '';
    const phaseBadge = pMeta
      ? `<span style="font-size:10px;font-weight:600;color:var(--text2);background:${pMeta.flaeche};padding:2px 8px;border-radius:99px;margin-left:8px">${pMeta.label}</span>`
      : '';
    const items = ks.map(k => {
      const kinder = erwByEltern[k.id] || [];
      if (!kinder.length) {
        return `<span class="pill" title="${k.beschreibung || ''}">${k.kurzname}</span>`;
      }
      const kid_id = 'kat-erw-' + k.id;
      return `<div style="width:100%;margin-bottom:4px">
        <span class="pill" style="cursor:pointer" onclick="toggleKatErw('${kid_id}', this)" title="${k.beschreibung || ''}">
          ${k.kurzname} <span class="kat-arrow" style="font-size:10px;opacity:.6">▸ ${kinder.length}</span>
        </span>
        <div id="${kid_id}" class="komp-erwartungen" style="margin-top:6px;padding-left:12px">
          ${kinder.map(e => `<span class="pill" style="font-size:11px;border-style:dashed;opacity:.9" title="${e.beschreibung || ''}">${e.kurzname}</span>`).join('')}
        </div>
      </div>`;
    }).join('');
    return `<div class="card"${cardStyle}>
      <div style="font-size:11px;color:var(--text3);font-weight:600;text-transform:uppercase;letter-spacing:.08em;margin-bottom:4px">${rahmen}</div>
      <h2>${bereichName}${phaseBadge}</h2>
      <div class="k-pills" style="flex-wrap:wrap;gap:6px">${items}</div>
    </div>`;
  }).join('');
}

// ============================================================
// EXPORT
// ============================================================
function initExport() {
  const el = document.getElementById('ex-kl');
  el.innerHTML = '<option value="">Alle Klassen</option>' +
    STATE.klassen.map(k => `<option value="${k.id}">${escHtml(k.bezeichnung)} (${escHtml(k.schuljahr)})</option>`).join('');
}
async function exportCsv(typ) {
  const kl  = document.getElementById('ex-kl').value;
  const url = API_BASE + '/api/export/' + typ + (kl ? '?klasse_id=' + kl : '');
  const blob = await fetch(url, { credentials: 'include' }).then(r => r.blob());
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = typ + '_export.csv';
  a.click();
}

// ============================================================
// HILFSFUNKTIONEN
// ============================================================
/**
 * Zeigt eine kurze Rückmeldung an einer bestimmten Stelle.
 *
 * role="status" und aria-live werden hier gesetzt statt im HTML: Die
 * Meldungsziele liegen über die ganze Anwendung verteilt und werden
 * teils erst zur Laufzeit erzeugt. Ohne die beiden Angaben erschien
 * und verschwand eine Meldung, ohne dass ein Bildschirmleser etwas
 * mitbekam – wer nicht sieht, erfuhr nicht, ob das Speichern geklappt
 * hat.
 *
 * "polite" statt "assertive", damit die Ansage eine laufende Vorlesung
 * nicht unterbricht.
 */
function showMsg(elId, txt, type) {
  const el = document.getElementById(elId);
  if (!el) return;
  el.setAttribute('role', 'status');
  el.setAttribute('aria-live', 'polite');
  el.className = 'msg msg-' + (type === 'ok' ? 'ok' : 'err');
  el.textContent = txt;
  setTimeout(() => el.textContent = '', 4000);
}

// ============================================================
//  BENUTZERVERWALTUNG
// ============================================================

// Alle Benutzer laden und Tabelle rendern
async function initBenutzer() {
  const data = await GET('benutzer');
  const tbody = document.getElementById('bu-tbody');
  if (!data || !data.length) {
    tbody.innerHTML = '<tr><td colspan="6" class="empty">Keine Benutzer gefunden.</td></tr>';
    return;
  }
  tbody.innerHTML = data.map(b => {
    const rolleCls = !b.aktiv ? 'rolle-inaktiv' : b.rolle === 'admin' ? 'rolle-admin' : 'rolle-lehrer';
    const rolleLabel = !b.aktiv ? 'inaktiv' : b.rolle;
    return `<tr>
      <td><strong>${/* keine-maskierung: benutzer, beim Schreiben maskiert */ b.vorname} ${b.nachname}</strong></td>
      <td style="color:var(--text2)">${b.email}</td>
      <td><code style="font-size:12px;background:var(--surface2);padding:2px 6px;border-radius:4px">${b.kuerzel || '–'}</code></td>
      <td><span class="rolle-badge ${rolleCls}">${rolleLabel}</span></td>
      <td style="font-size:12px;color:var(--text3)">${b.aktiv ? 'Aktiv' : 'Deaktiviert'}</td>
      <td style="white-space:nowrap">
        <button class="btn btn-sm" onclick="buBearbeiten(${b.id})" style="margin-right:4px">Bearbeiten</button>
        <button class="btn btn-sm" onclick="buPasswort(${b.id},'${/* keine-maskierung: benutzer, beim Schreiben maskiert */ b.vorname} ${b.nachname}')">Passwort</button>
        ${b.aktiv
          ? `<button class="btn btn-sm btn-d" onclick="buDeaktivieren(${b.id},'${/* keine-maskierung: benutzer, beim Schreiben maskiert */ b.vorname} ${b.nachname}')" style="margin-left:4px">Deaktivieren</button>`
          : `<button class="btn btn-sm" onclick="buAktivieren(${b.id})" style="margin-left:4px">Reaktivieren</button>`}
      </td>
    </tr>`;
  }).join('');
}

// Modal anzeigen
function showModal(html) {
  const wrap = document.getElementById('bu-modal');
  wrap.style.display = 'flex';
  wrap.className = 'modal-wrap';
  wrap.innerHTML = html;
  // Klick außerhalb schließt Modal
  wrap.addEventListener('click', e => { if (e.target === wrap) closeModal(); });
}
function closeModal() {
  const wrap = document.getElementById('bu-modal');
  wrap.style.display = 'none';
  wrap.innerHTML = '';
}

// ---- Neuen Benutzer anlegen ----
function buNeu() {
  showModal(`
    <div class="modal">
      <button class="modal-close" onclick="closeModal()">&#x2715;</button>
      <h2>Neuen Benutzer anlegen</h2>
      <p class="modal-sub">Lehrkraft oder Administrator hinzufügen</p>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
        <div><label>Vorname *</label><input id="m-vor" placeholder="Erika"></div>
        <div><label>Nachname *</label><input id="m-nach" placeholder="Muster"></div>
      </div>
      <label>E-Mail *</label>
      <input id="m-email" type="email" placeholder="e.muster@schule.de">
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
        <div>
          <label>Rolle *</label>
          <select id="m-rolle">
            <option value="lehrer">Lehrer/in</option>
            <option value="admin">Administrator/in</option>
          </select>
        </div>
        <div><label>Kürzel</label><input id="m-kuerzel" placeholder="MUS" maxlength="10"></div>
      </div>
      <label>Passwort * <span style="font-weight:300;color:var(--text3)">(min. 8 Zeichen, 1 Großbuchstabe, 1 Zahl)</span></label>
      <input id="m-pass" type="password" placeholder="Sicheres Passwort">
      <label>Passwort wiederholen *</label>
      <input id="m-pass2" type="password" placeholder="Passwort bestätigen">
      <div id="m-msg"></div>
      <div class="modal-footer">
        <button class="btn" onclick="closeModal()">Abbrechen</button>
        <button class="btn btn-p" onclick="buSpeichern()">Benutzer anlegen</button>
      </div>
    </div>
  `);
}

async function buSpeichern() {
  const vorname  = document.getElementById('m-vor').value.trim();
  const nachname = document.getElementById('m-nach').value.trim();
  const email    = document.getElementById('m-email').value.trim();
  const rolle    = document.getElementById('m-rolle').value;
  const kuerzel  = document.getElementById('m-kuerzel').value.trim();
  const pass     = document.getElementById('m-pass').value;
  const pass2    = document.getElementById('m-pass2').value;
  const msgEl    = document.getElementById('m-msg');

  if (pass !== pass2) {
    msgEl.className = 'msg msg-err'; msgEl.textContent = 'Passwörter stimmen nicht überein.'; return;
  }
  try {
    await POST('benutzer', { vorname, nachname, email, rolle, kuerzel, passwort: pass });
    closeModal();
    showMsg('bu-msg', `${/* keine-maskierung: showMsg schreibt textContent, kein HTML */ vorname} ${nachname} wurde angelegt.`, 'ok');
    initBenutzer();
  } catch(e) {
    msgEl.className = 'msg msg-err'; msgEl.textContent = e.message;
  }
}

// ---- Benutzer bearbeiten ----
async function buBearbeiten(id) {
  const b = await GET('benutzer/' + id);
  if (!b) return;
  showModal(`
    <div class="modal">
      <button class="modal-close" onclick="closeModal()">&#x2715;</button>
      <h2>Benutzer bearbeiten</h2>
      <p class="modal-sub">${/* keine-maskierung: benutzer, beim Schreiben maskiert */ b.vorname} ${b.nachname}</p>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
        <div><label>Vorname *</label><input id="m-vor" value="${/* keine-maskierung: benutzer, beim Schreiben maskiert */ b.vorname}"></div>
        <div><label>Nachname *</label><input id="m-nach" value="${/* keine-maskierung: benutzer, beim Schreiben maskiert */ b.nachname}"></div>
      </div>
      <label>E-Mail *</label>
      <input id="m-email" type="email" value="${b.email}">
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
        <div>
          <label>Rolle *</label>
          <select id="m-rolle">
            <option value="lehrer" ${b.rolle==='lehrer'?'selected':''}>Lehrer/in</option>
            <option value="admin"  ${b.rolle==='admin' ?'selected':''}>Administrator/in</option>
          </select>
        </div>
        <div><label>Kürzel</label><input id="m-kuerzel" value="${b.kuerzel||''}" maxlength="10"></div>
      </div>
      <label>Status</label>
      <select id="m-aktiv">
        <option value="1" ${b.aktiv?'selected':''}>Aktiv</option>
        <option value="0" ${!b.aktiv?'selected':''}>Deaktiviert</option>
      </select>
      <div id="m-msg"></div>
      <div class="modal-footer">
        <button class="btn" onclick="closeModal()">Abbrechen</button>
        <button class="btn btn-p" onclick="buUpdate(${id})">Speichern</button>
      </div>
    </div>
  `);
}

async function buUpdate(id) {
  const vorname  = document.getElementById('m-vor').value.trim();
  const nachname = document.getElementById('m-nach').value.trim();
  const email    = document.getElementById('m-email').value.trim();
  const rolle    = document.getElementById('m-rolle').value;
  const kuerzel  = document.getElementById('m-kuerzel').value.trim();
  const aktiv    = parseInt(document.getElementById('m-aktiv').value);
  const msgEl    = document.getElementById('m-msg');
  try {
    await api('PUT', 'benutzer/' + id, { vorname, nachname, email, rolle, kuerzel, aktiv });
    closeModal();
    showMsg('bu-msg', `${/* keine-maskierung: showMsg schreibt textContent, kein HTML */ vorname} ${nachname} aktualisiert.`, 'ok');
    // STATE.user aktualisieren wenn eigener Account
    if (STATE.user && STATE.user.id === id) STATE.user.rolle = rolle;
    initBenutzer();
  } catch(e) {
    msgEl.className = 'msg msg-err'; msgEl.textContent = e.message;
  }
}

// ---- Passwort ändern ----
function buPasswort(id, name) {
  const istEigen = STATE.user && STATE.user.id === id;
  showModal(`
    <div class="modal">
      <button class="modal-close" onclick="closeModal()">&#x2715;</button>
      <h2>Passwort ändern</h2>
      <p class="modal-sub">${name}</p>
      ${istEigen ? `
        <label>Aktuelles Passwort *</label>
        <input id="m-alt" type="password" placeholder="Aktuelles Passwort">
      ` : ''}
      <label>Neues Passwort * <span style="font-weight:300;color:var(--text3)">(min. 8 Zeichen, 1 Großbuchstabe, 1 Zahl)</span></label>
      <input id="m-pass" type="password" placeholder="Neues Passwort">
      <label>Passwort wiederholen *</label>
      <input id="m-pass2" type="password" placeholder="Passwort bestätigen">
      <div id="m-msg"></div>
      <div class="modal-footer">
        <button class="btn" onclick="closeModal()">Abbrechen</button>
        <button class="btn btn-p" onclick="buPasswortSpeichern(${id},${istEigen})">Passwort setzen</button>
      </div>
    </div>
  `);
}

async function buPasswortSpeichern(id, istEigen) {
  const neues  = document.getElementById('m-pass').value;
  const neues2 = document.getElementById('m-pass2').value;
  const msgEl  = document.getElementById('m-msg');
  if (neues !== neues2) {
    msgEl.className = 'msg msg-err'; msgEl.textContent = 'Passwörter stimmen nicht überein.'; return;
  }
  const body = { neues_passwort: neues };
  if (istEigen) body.altes_passwort = document.getElementById('m-alt').value;
  try {
    await api('PUT', `benutzer/${id}/passwort`, body);
    closeModal();
    showMsg('bu-msg', 'Passwort wurde geändert.', 'ok');
  } catch(e) {
    msgEl.className = 'msg msg-err'; msgEl.textContent = e.message;
  }
}

// ---- Deaktivieren / Reaktivieren ----
async function buDeaktivieren(id, name) {
  if (!confirm(`${name} wirklich deaktivieren? Die Person kann sich dann nicht mehr einloggen.`)) return;
  try {
    await DELETE('benutzer/' + id);
    showMsg('bu-msg', `${name} wurde deaktiviert.`, 'ok');
    initBenutzer();
  } catch(e) { showMsg('bu-msg', e.message, 'err'); }
}



// ============================================================
// SCHULJAHRE
// ============================================================
async function initSchuljahre() {
  const liste = document.getElementById('sj-liste');
  liste.innerHTML = '<div class="empty">Wird geladen …</div>';
  const data = await GET('schuljahre');
  if (!data || !data.length) {
    liste.innerHTML = '<div class="empty">Noch keine Schuljahre angelegt.</div>';
    return;
  }
  const statusLabel = { aktiv: 'Aktiv', zukuenftig: 'Geplant', abgeschlossen: 'Abgeschlossen' };
  const statusCls   = { aktiv: 'pill', zukuenftig: 'pill mkr', abgeschlossen: 'pill ma' };
  liste.innerHTML = data.map(sj => `
    <div class="card" style="margin-bottom:10px">
      <div style="display:flex;justify-content:space-between;align-items:flex-start;gap:12px">
        <div>
          <div style="font-weight:600;font-size:15px;margin-bottom:4px">${sj.name}</div>
          <div style="font-size:12px;color:var(--text3)">
            ${sj.beginn} – ${sj.ende} &nbsp;·&nbsp;
            ${sj.klassen_anzahl} Klassen &nbsp;·&nbsp;
            ${sj.schueler_anzahl} Schüler &nbsp;·&nbsp;
            ${sj.projekte_anzahl} Projekte
          </div>
        </div>
        <div style="display:flex;align-items:center;gap:8px;flex-shrink:0">
          <span class="${statusCls[sj.status] || 'pill'}">${statusLabel[sj.status] || sj.status}</span>
          ${sj.status !== 'aktiv' && sj.status !== 'abgeschlossen' ? `
            <button class="btn btn-p" style="padding:4px 10px;font-size:12px"
              onclick="sjAktivieren(${sj.id}, '${sj.name.replace(/'/g, "\\'")}')">Aktivieren</button>` : ''}
          ${sj.status !== 'aktiv' ? `
            <button class="btn" style="padding:4px 10px;font-size:12px;color:var(--danger)"
              onclick="sjLoeschen(${sj.id}, '${sj.name.replace(/'/g, "\\'")}')">Löschen</button>` : ''}
          ${sj.status !== 'abgeschlossen' ? `
            <button class="btn" style="padding:4px 10px;font-size:12px"
              onclick="sjBearbeiten(${sj.id}, '${sj.name.replace(/'/g, "\\'")}', '${sj.beginn}', '${sj.ende}')">Bearbeiten</button>` : ''}
        </div>
      </div>
    </div>`).join('');
}

function sjNeu() {
  document.getElementById('sj-modal').style.display = 'block';
  document.getElementById('sj-modal').innerHTML = `
    <div class="modal-backdrop" onclick="sjModalClose()"></div>
    <div class="modal">
      <div class="modal-header">
        <span>Neues Schuljahr</span>
        <button class="modal-close" onclick="sjModalClose()">✕</button>
      </div>
      <div style="display:flex;flex-direction:column;gap:12px;padding:16px">
        <div>
          <label>Name *</label>
          <input id="sj-name" placeholder="z.B. 2025/26" style="margin-top:4px">
        </div>
        <div style="display:flex;gap:12px">
          <div style="flex:1"><label>Beginn *</label><input id="sj-beginn" type="date" style="margin-top:4px"></div>
          <div style="flex:1"><label>Ende *</label><input id="sj-ende" type="date" style="margin-top:4px"></div>
        </div>
        <div>
          <label>Status</label>
          <select id="sj-status" style="margin-top:4px">
            <option value="zukuenftig">Geplant (noch nicht aktiv)</option>
            <option value="aktiv">Sofort aktivieren</option>
          </select>
        </div>
        <div id="sj-modal-msg"></div>
        <div style="display:flex;gap:8px;justify-content:flex-end;margin-top:4px">
          <button class="btn" onclick="sjModalClose()">Abbrechen</button>
          <button class="btn btn-p" onclick="sjSpeichern()">Speichern</button>
        </div>
      </div>
    </div>`;
}

function sjBearbeiten(id, name, beginn, ende) {
  document.getElementById('sj-modal').style.display = 'block';
  document.getElementById('sj-modal').innerHTML = `
    <div class="modal-backdrop" onclick="sjModalClose()"></div>
    <div class="modal">
      <div class="modal-header">
        <span>Schuljahr bearbeiten</span>
        <button class="modal-close" onclick="sjModalClose()">✕</button>
      </div>
      <div style="display:flex;flex-direction:column;gap:12px;padding:16px">
        <div>
          <label>Name *</label>
          <input id="sj-name" value="${name}" style="margin-top:4px">
        </div>
        <div style="display:flex;gap:12px">
          <div style="flex:1"><label>Beginn *</label><input id="sj-beginn" type="date" value="${beginn}" style="margin-top:4px"></div>
          <div style="flex:1"><label>Ende *</label><input id="sj-ende" type="date" value="${ende}" style="margin-top:4px"></div>
        </div>
        <div id="sj-modal-msg"></div>
        <div style="display:flex;gap:8px;justify-content:flex-end;margin-top:4px">
          <button class="btn" onclick="sjModalClose()">Abbrechen</button>
          <button class="btn btn-p" onclick="sjUpdate(${id})">Speichern</button>
        </div>
      </div>
    </div>`;
}

function sjModalClose() {
  const m = document.getElementById('sj-modal');
  m.style.display = 'none';
  m.innerHTML = '';
}

async function sjSpeichern() {
  const name   = document.getElementById('sj-name').value.trim();
  const beginn = document.getElementById('sj-beginn').value;
  const ende   = document.getElementById('sj-ende').value;
  const status = document.getElementById('sj-status').value;
  const msgEl  = document.getElementById('sj-modal-msg');
  if (!name || !beginn || !ende) {
    msgEl.className = 'msg msg-err'; msgEl.textContent = 'Bitte alle Pflichtfelder ausfüllen.'; return;
  }
  try {
    await POST('schuljahre', { name, beginn, ende, status });
    sjModalClose();
    showMsg('sj-msg', 'Schuljahr wurde angelegt.', 'ok');
    initSchuljahre();
  } catch(e) {
    msgEl.className = 'msg msg-err'; msgEl.textContent = e.message;
  }
}

async function sjUpdate(id) {
  const name   = document.getElementById('sj-name').value.trim();
  const beginn = document.getElementById('sj-beginn').value;
  const ende   = document.getElementById('sj-ende').value;
  const msgEl  = document.getElementById('sj-modal-msg');
  if (!name || !beginn || !ende) {
    msgEl.className = 'msg msg-err'; msgEl.textContent = 'Bitte alle Pflichtfelder ausfüllen.'; return;
  }
  try {
    await api('PUT', `schuljahre/${id}`, { name, beginn, ende });
    sjModalClose();
    showMsg('sj-msg', 'Schuljahr wurde aktualisiert.', 'ok');
    initSchuljahre();
  } catch(e) {
    msgEl.className = 'msg msg-err'; msgEl.textContent = e.message;
  }
}

async function sjAktivieren(id, name) {
  if (!confirm(`"${name}" wirklich aktivieren? Das aktuell aktive Schuljahr wird dabei abgeschlossen.`)) return;
  try {
    await POST(`schuljahre/${id}/aktivieren`, {});
    showMsg('sj-msg', `"${name}" ist jetzt das aktive Schuljahr.`, 'ok');
    initSchuljahre();
  } catch(e) { showMsg('sj-msg', e.message, 'err'); }
}

async function sjLoeschen(id, name) {
  if (!confirm(`"${name}" wirklich löschen? Dies ist nur möglich wenn noch keine Schüler oder Projekte zugeordnet sind.`)) return;
  try {
    await DELETE(`schuljahre/${id}`);
    showMsg('sj-msg', `"${name}" wurde gelöscht.`, 'ok');
    initSchuljahre();
  } catch(e) { showMsg('sj-msg', e.message, 'err'); }
}

// ============================================================
// IMPORT (Schild-NRW)
// ============================================================

let IMP_DATEI = null; // aktuell gewählte Datei merken

async function initImport() {
  // Das aktive Schuljahr ANZEIGEN, nicht zur Wahl stellen (E56).
  //
  // Vorher stand hier eine Auswahl, deren Wert nie beim Handler ankam. Wer in
  // ein anderes Jahr importieren will, aktiviert es unter „Schuljahre“.
  //
  // Ist kein Jahr aktiv, steht hier derselbe Satz, den auch das Backend
  // ausgibt. Das Dateifeld bleibt bedienbar: Die Bedingung wird an EINER
  // Stelle entschieden, im Backend. Zwei Stellen, die dieselbe Bedingung
  // entscheiden, sind der Mechanismus, aus dem dieser Fehler entstanden ist.
  //
  // textContent, nicht innerHTML -- der Name ist ein schlichter Wert.
  const anzeige = document.getElementById('imp-sj-anzeige');
  const data = await GET('schuljahre');
  const aktiv = (data || []).find(sj => sj.status === 'aktiv');
  if (aktiv) {
    anzeige.textContent = aktiv.name;
    anzeige.style.color = '';
  } else {
    anzeige.textContent = 'Kein aktives Schuljahr gefunden. Bitte zuerst ein Schuljahr aktivieren.';
    // `--danger`, nicht `--err`: Ein Token dieses Namens gibt es nicht. Wo es
    // steht, erbt der Text seine Farbe und der Hinweis sieht aus wie eine
    // gewoehnliche Zeile. Fuenf weitere Stellen in der Import-Vorschau haben
    // denselben Tippfehler -- gemeldet, nicht hier mitbehoben.
    anzeige.style.color = 'var(--danger)';
  }
  // Import-Log laden
  await impLogLaden();
}

async function impLogLaden() {
  const logEl = document.getElementById('imp-log-liste');
  try {
    const data = await GET('import/log');
    if (data && data.length) {
      // `dateiname` kommt ungefiltert aus $_FILES in die Datenbank und von
      // dort hierher -- dieselbe Bauform wie E42, nur ueber die Datenbank
      // und damit dauerhaft. Nach E40 wird bei der AUSGABE maskiert, nicht
      // beim Schreiben: Das schuetzt auch die Zeilen, die vor dieser
      // Behebung entstanden sind, und der CSV-Import vergleicht ohnehin
      // zeichengenau gegen die Datei.
      logEl.innerHTML = data.map(e => `
        <div class="card" style="margin-bottom:8px;font-size:13px">
          <div style="font-weight:600">${escHtml(e.dateiname ?? '')}</div>
          <div style="color:var(--text3);font-size:12px;margin-top:2px">
            ${new Date(e.erstellt_am).toLocaleString('de-DE')} &nbsp;·&nbsp;
            ${/* keine-maskierung: schuljahre.name, beim Schreiben maskiert */ e.schuljahr_name ?? ''} &nbsp;·&nbsp;
            ${/* keine-maskierung: benutzer, beim Schreiben maskiert */ e.vorname ?? ''} ${e.nachname ?? ''}
          </div>
          <div style="margin-top:4px">
            <span style="color:var(--ok)">+${e.neu} neu</span> &nbsp;·&nbsp;
            <span style="color:var(--warn)">${e.aktualisiert} aktualisiert</span> &nbsp;·&nbsp;
            ${e.unveraendert} unverändert
            ${e.inaktiviert ? `&nbsp;·&nbsp;<span style="color:var(--text3)">${e.inaktiviert} inaktiviert</span>` : ''}
            ${e.fehler ? `&nbsp;·&nbsp;<span style="color:var(--danger)">${e.fehler} Fehler</span>` : ''}
          </div>
        </div>`).join('');
      return data[0]; // neuesten Eintrag zurückgeben für Erfolgsmeldung
    } else {
      logEl.innerHTML = '<div class="empty">Noch keine Importe durchgeführt.</div>';
    }
  } catch {
    logEl.innerHTML = '<div class="empty">Noch keine Importe durchgeführt.</div>';
  }
  return null;
}

async function impVorschau() {
  const fileInput = document.getElementById('imp-datei');
  const ladeinfo  = document.getElementById('imp-ladeinfo');
  const vorschauWrap = document.getElementById('imp-vorschau-wrap');
  const msgEl = document.getElementById('imp-msg');
  msgEl.innerHTML = '';
  vorschauWrap.style.display = 'none';

  if (!fileInput.files.length) return;
  IMP_DATEI = fileInput.files[0];
  ladeinfo.textContent = `Datei: ${IMP_DATEI.name} (${Math.round(IMP_DATEI.size / 1024)} KB) – wird analysiert …`;

  // Nur die Datei. `schuljahr_id` wurde frueher mitgeschickt und nie gelesen
  // (E56): `$body` im Backend entsteht aus php://input, und das ist bei
  // multipart/form-data leer.
  const fd = new FormData();
  fd.append('datei', IMP_DATEI);

  try {
    const r = await fetch(API_BASE + '/api/import/vorschau', {
      method: 'POST', credentials: 'include', body: fd
    });
    if (!r.ok) {
      const err = await r.json().catch(() => ({}));
      throw new Error(err.error || 'Fehler beim Analysieren der Datei.');
    }
    const v = await r.json();

    document.getElementById('imp-stats').innerHTML = `
      <div class="stat"><div class="stat-val" style="color:var(--ok)">${v.neu?.length ?? 0}</div><div class="stat-lbl">Neu</div></div>
      <div class="stat"><div class="stat-val" style="color:var(--warn)">${v.aktualisiert?.length ?? 0}</div><div class="stat-lbl">Aktualisiert</div></div>
      <div class="stat"><div class="stat-val">${v.unveraendert?.length ?? 0}</div><div class="stat-lbl">Unverändert</div></div>
      <div class="stat"><div class="stat-val" style="color:var(--danger)">${v.fehler?.length ?? 0}</div><div class="stat-lbl">Fehler</div></div>`;

    // Achtung: `v` kommt aus der hochgeladenen Datei, nicht aus der
    // Datenbank. Was hier gezeigt wird, hat noch keinen Schreibweg passiert --
    // dies ist die einzige Stelle, an der Fremdinhalt ohne jeden
    // Zwischenschritt in die Anzeige gelangt (E42). Jede Einbettung eines
    // Namens läuft deshalb durch escHtml.
    let detail = '';
    if (v.neu?.length)
      detail += `<div class="sec" style="margin-top:12px">Neue Schüler (${v.neu.length})</div>` +
        v.neu.slice(0, 10).map(s => `<div style="font-size:13px;padding:3px 0">${escHtml(s.vorname)} ${escHtml(s.nachname)} – Klasse ${escHtml(s.klasse)}</div>`).join('') +
        (v.neu.length > 10 ? `<div style="font-size:12px;color:var(--text3)">… und ${v.neu.length - 10} weitere</div>` : '');
    if (v.aktualisiert?.length)
      detail += `<div class="sec" style="margin-top:12px">Aktualisiert (${v.aktualisiert.length})</div>` +
        v.aktualisiert.slice(0, 5).map(s => `<div style="font-size:13px;padding:3px 0">${escHtml(s.vorname)} ${escHtml(s.nachname)}</div>`).join('') +
        (v.aktualisiert.length > 5 ? `<div style="font-size:12px;color:var(--text3)">… und ${v.aktualisiert.length - 5} weitere</div>` : '');
    if (v.fehler?.length)
      // Das Backend liefert `zeile`, `grund` und `daten` (index.php, analyse_import).
      // Gelesen wurde bisher `meldung` -- ein Feld, das es nicht gibt. Der
      // Rueckfall `?? f` gab dann das ganze Objekt aus, und der Benutzer las
      // "12: [object Object]" statt einer Fehlerbeschreibung (E44).
      //
      // `daten` ist Inhalt der hochgeladenen Datei -- heute `vorname nachname`
      // der fehlerhaften Zeile. Es laeuft durch escHtml. `grund` ist eine
      // Zeichenkette aus dem Programm und heute unbedenklich; es laeuft
      // trotzdem durch escHtml, denn nichts maskiert es beim Schreiben, eine
      // doppelte Maskierung kann also nicht entstehen -- und die Zusicherung
      // "grund ist immer eine Konstante" muesste sonst jeder pruefen, der
      // eine zweite Fehlerart ergaenzt. Genau diese Falle beschreibt E44.
      //
      // Die Werte werden vor der Vorlage maskiert und nicht in ihr: So steht
      // in der Vorlage kein `${f.…}`, und die Pruefung kann verlangen, dass
      // jedes Vorkommen von `f.daten` und `f.grund` in escHtml liegt.
      detail += `<div class="sec" style="margin-top:12px;color:var(--danger)">Fehler (${v.fehler.length})</div>` +
        v.fehler.map(f => {
          const wo  = escHtml(f.zeile ?? '?');
          const was = escHtml(f.grund ?? 'Unbekannter Fehler');
          const wer = escHtml(f.daten ?? '');
          return `<div style="font-size:12px;color:var(--danger);padding:2px 0">Zeile ${wo}: ${was}${wer ? ' – ' + wer : ''}</div>`;
        }).join('');

    document.getElementById('imp-vorschau-detail').innerHTML = detail;
    vorschauWrap.style.display = 'block';
    ladeinfo.textContent = `${IMP_DATEI.name} analysiert.`;
  } catch(e) {
    ladeinfo.textContent = '';
    msgEl.className = 'msg msg-err'; msgEl.textContent = e.message;
  }
}

async function impAusfuehren() {
  const msgEl = document.getElementById('imp-msg');
  const btn   = document.getElementById('imp-btn-ausfuehren');
  if (!IMP_DATEI) { msgEl.className='msg msg-err'; msgEl.textContent='Keine Datei gewählt.'; return; }

  // Nur die Datei. `schuljahr_id` wurde frueher mitgeschickt und nie gelesen
  // (E56): `$body` im Backend entsteht aus php://input, und das ist bei
  // multipart/form-data leer.
  const fd = new FormData();
  fd.append('datei', IMP_DATEI);

  btn.disabled = true;
  btn.textContent = 'Wird importiert …';
  try {
    const r = await fetch(API_BASE + '/api/import/ausfuehren', {
      method: 'POST', credentials: 'include', body: fd
    });
    if (!r.ok) {
      const err = await r.json().catch(() => ({}));
      throw new Error(err.error || 'Fehler beim Import.');
    }
    await r.json(); // Erfolg bestätigt
    impReset();
    // Erfolgsmeldung aus dem frisch geladenen Log lesen – zuverlässiger als API-Response parsen
    const letzter = await impLogLaden();
    msgEl.className = 'msg msg-ok';
    if (letzter) {
      const teile = [
        `${letzter.neu} neu`,
        `${letzter.aktualisiert} aktualisiert`,
        `${letzter.unveraendert} unverändert`,
        letzter.inaktiviert ? `${letzter.inaktiviert} inaktiviert` : null,
        letzter.fehler      ? `${letzter.fehler} Fehler`           : null,
      ].filter(Boolean).join(', ');
      msgEl.textContent = `Import abgeschlossen: ${teile}.`;
    } else {
      msgEl.textContent = 'Import abgeschlossen.';
    }
  } catch(e) {
    msgEl.className = 'msg msg-err'; msgEl.textContent = e.message;
  } finally {
    btn.disabled = false;
    btn.textContent = 'Import durchführen';
  }
}

function impReset() {
  IMP_DATEI = null;
  document.getElementById('imp-datei').value = '';
  document.getElementById('imp-ladeinfo').textContent = '';
  document.getElementById('imp-vorschau-wrap').style.display = 'none';
  document.getElementById('imp-stats').innerHTML = '';
  document.getElementById('imp-vorschau-detail').innerHTML = '';
}

checkAuth();


// ============================================================
// BEWERTUNGEN & RÜCKMELDUNGEN – eigener Screen
// ============================================================
let BEW_PROJEKT_ID = null;

async function initBewertung() {
  const data = await GET('projekte');
  const sel  = document.getElementById('bew-werkstatt');
  sel.innerHTML = '<option value="">– Werkstatt auswählen –</option>' +
    (data || []).map(p =>
      `<option value="${p.id}">${p.name}${/* keine-maskierung: schuljahre.name, beim Schreiben maskiert */ p.schuljahr_name ? ' · ' + p.schuljahr_name : ''} (${p.status})</option>`
    ).join('');
  document.getElementById('bew-inhalt').style.display = 'none';
  BEW_PROJEKT_ID = null;
}

async function bewertungWerkstattGewaehlt() {
  const id = parseInt(document.getElementById('bew-werkstatt').value);
  if (!id) { document.getElementById('bew-inhalt').style.display = 'none'; return; }
  BEW_PROJEKT_ID = id;
  document.getElementById('bew-inhalt').style.display = 'block';
  await Promise.all([
    ladeBewertungTabelle(id),
    ladeBewRueckmeldungen(id)
  ]);
}

async function ladeBewertungTabelle(projekt_id) {
  // Zwei Quellen mit zwei Aufgaben (E39): Die ZEILEN sind die Teilnehmer,
  // die SPALTEN die zugewiesenen Kompetenzen.
  //
  // Vorher kam beides aus `bewertung` -- also aus
  // `projekt_schueler_kompetenzen`. Wer keine zugewiesene Kompetenz hatte,
  // erschien nicht, war nicht bewertbar und bekam keine Rückmeldung.
  // Werkstatt 2 hat zwei Teilnehmer, null Kompetenzzeilen und zwei
  // Rückmeldungen; die Ansicht konnte diesen Fall gar nicht darstellen.
  const [bewertungen, teilnehmer] = await Promise.all([
    GET(`bewertung?projekt_id=${projekt_id}`),
    GET(`werkstatt/${projekt_id}/schueler`)
  ]);
  const el = document.getElementById('bew-tabelle');
  if (!el) return;

  const schueler = (teilnehmer || []).slice()
    .sort((a, b) => a.nachname.localeCompare(b.nachname));

  // Die Empfängerliste wird IN JEDEM FALL gesetzt, auch auf leer.
  // Vorher kehrte die Funktion bei null Bewertungszeilen zurück, bevor sie
  // die Liste anfasste -- beim Wechsel von Werkstatt 4 auf Werkstatt 2
  // blieben deren zwölf Namen stehen, während BEW_PROJEKT_ID schon auf 2
  // zeigte. Vor E36 hätte ein Klick Rückmeldungen in die falsche Werkstatt
  // geschrieben; seither weist das Backend ab, und die Oberfläche bietet
  // etwas an, das sie nicht darf.
  fuelleEmpfaengerliste(schueler);

  if (!schueler.length) {
    el.innerHTML = '<p style="font-size:13px;color:var(--text3)">Diese Werkstatt hat keine Teilnehmer. Bitte zuerst unter „Werkstätten" → Bearbeiten Teilnehmer auswählen und speichern.</p>';
    return;
  }

  if (!bewertungen || !bewertungen.length) {
    el.innerHTML = '<p style="font-size:13px;color:var(--text3)">Noch keine Kompetenzen für diese Werkstatt zugewiesen. Bitte zuerst unter „Werkstätten" → Bearbeiten Kompetenzen auswählen und speichern. Rückmeldungen sind trotzdem möglich.</p>';
    return;
  }

  // Nur noch die SPALTEN kommen aus den Bewertungszeilen.
  const kompMap = {};
  bewertungen.forEach(b => {
    kompMap[b.kompetenz_id] = { id: b.kompetenz_id, name: b.kompetenz_name, code: b.code, bereich: b.bereich_name };
  });
  const komps = Object.values(kompMap);

  // Index
  const idx = {};
  bewertungen.forEach(b => {
    if (!idx[b.schueler_id]) idx[b.schueler_id] = {};
    idx[b.schueler_id][b.kompetenz_id] = b;
  });

  const header = `<tr>
    <th class="name-col" style="min-width:160px">Schüler/in</th>
    ${komps.map(k => `<th title="${k.bereich}: ${k.name}" style="max-width:80px;font-size:11px">${k.code || k.name.substring(0,10)}</th>`).join('')}
  </tr>`;

  const rows = schueler.map(s => {
    const zellen = komps.map(k => {
      const bew   = idx[s.id]?.[k.id];
      const stufe = bew?.fremd_stufe || 0;
      const chips = [1,2,3,4].map(n =>
        `<span class="bew-chip bew-${n}${stufe===n?' on':''}"
               onclick="setBewertung(${projekt_id},${s.id},${k.id},${n},this)">${n}</span>`
      ).join('');
      return `<td><div class="bew-cell">${chips}</div></td>`;
    }).join('');
    return `<tr>
      <td class="name-col">${escHtml(s.nachname)}, ${escHtml(s.vorname)}</td>
      ${zellen}
    </tr>`;
  }).join('');

  el.innerHTML = `<table class="bew-table"><thead>${header}</thead><tbody>${rows}</tbody></table>`;
}


// Empfängerliste für Rückmeldungen. Sie steht in einer eigenen Funktion,
// weil sie auch dann gesetzt werden muss, wenn die Tabelle nicht gezeichnet
// wird -- und weil "auf leer setzen" ein gültiger Fall ist.
function fuelleEmpfaengerliste(schueler) {
  const empfEl = document.getElementById('bew-empfaenger');
  if (empfEl) {
    empfEl.innerHTML = schueler.map(s => `
      <div style="display:flex;align-items:center;gap:8px;padding:5px 0;border-bottom:1px solid var(--border)">
        <input type="checkbox" class="bew-emp-cb" value="${s.id}"
               id="be-${s.id}">
        <label for="be-${s.id}" style="flex:1;cursor:pointer;font-size:13px">
          ${escHtml(s.nachname)}, ${escHtml(s.vorname)}
        </label>
      </div>`
    ).join('');
  }
}

async function setBewertung(projekt_id, schueler_id, kompetenz_id, stufe, chipEl) {
  const row    = chipEl.closest('div');
  const aktiv  = chipEl.classList.contains('on');
  const neue_stufe = aktiv ? null : stufe;
  row.querySelectorAll('.bew-chip').forEach(c => c.classList.remove('on'));
  if (!aktiv) chipEl.classList.add('on');
  try {
    await fetch(`/api/bewertung/${projekt_id}`, {
      method: 'PUT',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ schueler_id, kompetenz_id, fremd_stufe: neue_stufe })
    });
  } catch(e) { alert('Bewertung konnte nicht gespeichert werden: ' + e.message); }
}

async function ladeBewRueckmeldungen(projekt_id) {
  const rueckmeldungen = await GET(`rueckmeldung?projekt_id=${projekt_id}`);
  const listeEl = document.getElementById('bew-rueckmeldung-liste');
  if (!listeEl) return;

  if (!rueckmeldungen || !rueckmeldungen.length) {
    listeEl.innerHTML = '<p style="font-size:13px;color:var(--text3);margin-bottom:10px">Noch keine Rückmeldungen vorhanden.</p>';
    return;
  }

  const STUFEN = { 1: '1 – Mit Unterstützung', 2: '2 – Teilweise', 3: '3 – Weitgehend', 4: '4 – Sicher' };
  listeEl.innerHTML = rueckmeldungen.map(r => `
    <div class="rueck-row">
      <div style="display:flex;align-items:flex-start;justify-content:space-between;gap:8px">
        <div>
          <strong style="font-size:13px">${escHtml(r.nachname)}, ${escHtml(r.vorname)}</strong>
          ${r.bewertung_stufe ? `<span class="bew-chip bew-${r.bewertung_stufe}" style="margin-left:6px">${STUFEN[r.bewertung_stufe]}</span>` : ''}
        </div>
        <label style="display:flex;align-items:center;gap:6px;font-size:12px;cursor:pointer;white-space:nowrap;flex-shrink:0">
          <input type="checkbox" ${r.sichtbar ? 'checked' : ''}
                 onchange="toggleBewRueckSichtbar(${projekt_id}, ${r.schueler_id}, this.checked)">
          sichtbar
        </label>
      </div>
      ${r.freitext ? `<p style="font-size:13px;color:var(--text2);margin:6px 0 0">${escHtml(r.freitext)}</p>` : ''}
      <p style="font-size:11px;color:var(--text3);margin:4px 0 0">
        ${/* keine-maskierung: benutzer, beim Schreiben maskiert */ r.lb_vorname} ${r.lb_nachname} · ${(r.geaendert_am || r.erstellt_am || '').substring(0,10)}
      </p>
    </div>`
  ).join('');
}

function alleBewEmpfaenger(checked) {
  document.querySelectorAll('.bew-emp-cb').forEach(cb => cb.checked = checked);
}

async function bewRueckmeldungSpeichern() {
  const projekt_id = BEW_PROJEKT_ID;
  if (!projekt_id) return showMsg('bew-rueck-msg', 'Bitte zuerst eine Werkstatt wählen.', 'err');

  const schueler_ids    = [...document.querySelectorAll('.bew-emp-cb:checked')].map(c => parseInt(c.value));
  if (!schueler_ids.length) return showMsg('bew-rueck-msg', 'Mindestens einen Schüler auswählen.', 'err');

  const bewertung_stufe = document.getElementById('bew-rueck-stufe').value || null;
  const freitext        = document.getElementById('bew-rueck-text').value.trim();
  const sichtbar        = document.getElementById('bew-rueck-sichtbar').checked ? 1 : 0;

  if (!freitext && !bewertung_stufe) {
    return showMsg('bew-rueck-msg', 'Bitte Bewertungsstufe oder Freitext angeben.', 'err');
  }

  try {
    const r = await fetch(`/api/rueckmeldung/${projekt_id}`, {
      method: 'POST',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ schueler_ids, bewertung_stufe, freitext, sichtbar })
    });
    const data = await r.json();
    if (!r.ok) throw new Error(data.error || 'Fehler');
    showMsg('bew-rueck-msg', `${data.anzahl} Rückmeldung(en) gespeichert ✓`, 'ok');
    document.getElementById('bew-rueck-stufe').value = '';
    document.getElementById('bew-rueck-text').value  = '';
    document.getElementById('bew-rueck-sichtbar').checked = false;
    alleBewEmpfaenger(false);
    ladeBewRueckmeldungen(projekt_id);
  } catch(e) { showMsg('bew-rueck-msg', e.message, 'err'); }
}

async function toggleBewRueckSichtbar(projekt_id, schueler_id, sichtbar) {
  try {
    await fetch(`/api/rueckmeldung/${projekt_id}`, {
      method: 'PUT',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ schueler_id, sichtbar: sichtbar ? 1 : 0 })
    });
  } catch(e) { alert(e.message); }
}

// ============================================================
// HILFE-SEITE
// ============================================================
function initHilfe() {
  hilfeTab('schnellstart', document.querySelector('#hilfe-tabs .rtab'));
}

function hilfeTab(id, btn) {
  document.querySelectorAll('#hilfe-tabs .rtab').forEach(b => b.classList.remove('on'));
  if (btn) btn.classList.add('on');
  const el = document.getElementById('hilfe-inhalt');
  el.innerHTML = '';
  if (id === 'schnellstart') el.innerHTML = hilfeSchnellstart();
  else if (id === 'faq')     el.innerHTML = hilfeFaq();
  else                       el.innerHTML = hilfeHandbuch();
  // FAQ-Aufklapp-Logik
  el.querySelectorAll('.faq-frage').forEach(btn => {
    btn.addEventListener('click', () => {
      const antwort = btn.nextElementSibling;
      const offen = antwort.classList.toggle('open');
      btn.querySelector('.faq-chev').textContent = offen ? '▾' : '▸';
    });
  });
}

function hilfeSchnellstart() {
  const karten = [
    { icon: '📋', titel: 'Was ist Projektstunden NRW?',
      text: 'Eine Web-App zur Verwaltung von Projektstunden an NRW-Schulen. Werkstätten anlegen, Schüler zuordnen, Stunden auf Fächer anrechnen, Kompetenzen aus KLPs und MKR dokumentieren und Rückmeldungen schreiben.' },
    { icon: '🔑', titel: 'Wie melde ich mich an?',
      text: 'E-Mail-Adresse und Passwort eingeben. Bei Problemen an den Administrator wenden – dieser kann Konten anlegen und Passwörter zurücksetzen.' },
    { icon: '🏗️', titel: 'Erste Werkstatt anlegen',
      text: 'Navigation → <strong>Werkstätten</strong> → <strong>+ Neue Werkstatt</strong>. Pflichtfelder: Name, mind. eine Klasse, Startdatum, mind. ein Lernbegleiter. Dann Stunden je Fach eintragen und Kompetenzen wählen.' },
    { icon: '👥', titel: 'Schüler zuweisen',
      text: 'Im Formular Klasse(n) wählen (Strg/Cmd für mehrere) → Schüler erscheinen → mit Strg/Cmd mehrere auswählen. Max-Teilnehmerzahl wird beim Speichern geprüft.' },
    { icon: '⭐', titel: 'Bewertungen vergeben',
      text: 'Navigation → <strong>Bewertungen</strong> → Werkstatt wählen. Tabelle zeigt alle Schüler × alle Kompetenzen. Stufe 1–4 per Klick setzen (nochmal klicken = entfernen).' },
    { icon: '✉️', titel: 'Rückmeldungen schreiben',
      text: 'Im Bewertungs-Screen unten: Empfänger auswählen (einzeln, alle oder Teilmenge), Bewertungsstufe optional, Freitext eingeben. Sichtbarkeit für Schüler separat steuerbar.' },
    { icon: '📊', titel: 'Dashboard auswerten',
      text: 'Zeigt Stunden und Kompetenzen je Schüler – aber nur für abgeschlossene Werkstätten (Status = abgeschlossen) oder individuell als absolviert markierte Schüler.' },
    { icon: '📥', titel: 'CSV importieren (Admin)',
      text: 'Navigation → <strong>Schüler importieren</strong>. CSV-Datei aus Schild-NRW hochladen, Vorschau prüfen, Import durchführen. Klassen werden automatisch angelegt.' },
  ];
  return `
    <div class="hilfe-grid">
      ${karten.map(k => `
        <div class="hilfe-karte">
          <div class="hilfe-karte-icon">${k.icon}</div>
          <div>
            <h4>${k.titel}</h4>
            <p>${k.text}</p>
          </div>
        </div>`).join('')}
    </div>
    <div class="card" style="margin-top:8px">
      <h3 style="font-size:14px;font-weight:600;margin-bottom:12px">Typischer Workflow</h3>
      <ol style="font-size:13px;color:var(--text2);line-height:2;padding-left:18px;margin:0">
        <li>Schuljahr anlegen und aktivieren <span style="color:var(--text3)">(Admin)</span></li>
        <li>Schüler per CSV importieren <span style="color:var(--text3)">(Admin)</span></li>
        <li>Werkstatt anlegen – Klassen, Lernbegleiter, Stunden, Kompetenzen</li>
        <li>Schüler der Werkstatt zuweisen</li>
        <li>Werkstatt durchführen → Status auf „aktiv" setzen</li>
        <li>Bewertungen (1–4) pro Schüler und Kompetenz vergeben</li>
        <li>Rückmeldungen schreiben und für Schüler freischalten</li>
        <li>Abschluss: Schüler als „absolviert" markieren, Status → „abgeschlossen"</li>
        <li>Dashboard zeigt angerechnete Stunden und Kompetenzen</li>
      </ol>
    </div>`;
}

function hilfeFaq() {
  const fragen = [
    { f: 'Warum sehe ich keine Stunden im Dashboard?',
      a: 'Die Werkstatt muss den Status „abgeschlossen" haben oder der Schüler muss individuell als „absolviert" markiert sein (Details-Modal → Teilnehmer).' },
    { f: 'Warum erscheinen KLP-Tabs nicht beim Anlegen?',
      a: 'KLP-Tabs erscheinen erst wenn beim zugehörigen Fach Stunden eingetragen wurden. Der MKR ist immer verfügbar.' },
    { f: 'Warum sehe ich die Werkstatt eines Kollegen nicht?',
      a: 'Lernbegleiter sehen nur Werkstätten bei denen sie als Lernbegleiter eingetragen sind. Admins sehen alle Werkstätten.' },
    { f: 'Wie setze ich den Status einer Werkstatt?',
      a: 'Details-Button auf der Werkstattkarte → Status-Dropdown → Speichern.' },
    { f: 'Kann ich mehr Schüler zuweisen als das Maximum erlaubt?',
      a: 'Nein – die App prüft beim Speichern ob das Limit überschritten wird und zeigt eine Fehlermeldung.' },
    { f: 'Wie weise ich Schüler aus mehreren Klassen zu?',
      a: 'Im Klassen-Feld Strg/Cmd gedrückt halten und mehrere Klassen anklicken. Die Schülerliste zeigt dann alle Schüler aus allen gewählten Klassen.' },
    { f: 'Warum sieht ein Schüler seine Rückmeldung nicht?',
      a: 'Die Rückmeldung muss als „sichtbar" markiert sein. Im Bewertungs-Screen die Checkbox „sichtbar" neben der Rückmeldung aktivieren.' },
    { f: 'Kann ich eine Rückmeldung nachträglich ändern?',
      a: 'Ja – einfach erneut für denselben Schüler speichern. Pro Schüler pro Werkstatt gibt es eine Rückmeldung; erneutes Speichern überschreibt sie.' },
    { f: 'Was bedeutet die Bewertungsskala 1–4?',
      a: '1 = Mit Unterstützung · 2 = Teilweise selbstständig · 3 = Weitgehend sicher · 4 = Sicher und reflektiert. Die Skala folgt dem NRW-Kompetenzkonzept.' },
    { f: 'Was passiert wenn ich eine Werkstatt lösche?',
      a: 'Alle zugehörigen Daten werden unwiderruflich gelöscht: Schülerzuordnungen, Stunden, Kompetenzen, Bewertungen und Rückmeldungen. Nur Admins können löschen.' },
    { f: 'Wie importiere ich Schüler aus Schild-NRW?',
      a: 'Navigation → Schüler importieren → Schuljahr wählen → CSV-Datei hochladen → Vorschau prüfen → Import durchführen. Klassen werden automatisch angelegt. Schüler die nicht mehr in der CSV stehen werden inaktiviert.' },
    { f: 'Kann ich die App auf dem Smartphone nutzen?',
      a: 'Ja – die App ist responsiv. Einfach die URL im Smartphone-Browser aufrufen, keine separate App nötig.' },
  ];
  return `<div>${fragen.map((f,i) => `
    <div class="faq-item">
      <button class="faq-frage">
        <span>${f.f}</span>
        <span class="faq-chev">▸</span>
      </button>
      <div class="faq-antwort">${f.a}</div>
    </div>`).join('')}</div>`;
}

function hilfeHandbuch() {
  return `
  <div>
    <div class="hb-section">
      <h3>1. Dashboard</h3>
      <p>Das Dashboard zeigt für jeden Schüler das Stundenkontingent je Fach sowie erworbene Kompetenzen.</p>
      <h4>Stundenkontingent</h4>
      <p>Jede Fachzeile zeigt Ist-Stunden / Soll-Stunden mit Fortschrittsbalken und Prozentzahl.
      Ist das Soll erreicht, sind Punkt und Balken
      <span style="color:var(--imp-neu)">grün</span>; darunter bleiben sie neutral.
      Über 100 % nennt die Prozentzahl den tatsächlichen Wert – der Balken bleibt
      dabei voll, weil er nicht weiter kann.</p>
      <h4>Erworbene Kompetenzen</h4>
      <p>Farbige Pillen zeigen MKR- und KLP-Kompetenzen. Nur Kompetenzen aus
      abgeschlossenen Werkstätten oder individuell absolvierten Teilnahmen erscheinen hier.</p>
      <h4>Filter</h4>
      <p>Klasse und Schüler über Dropdowns einschränken.</p>
    </div>

    <div class="hb-section">
      <h3>2. Werkstätten</h3>
      <h4>Übersicht</h4>
      <p>Listet alle zugänglichen Werkstätten. Schuljahr-Filter oben. Admins sehen alle,
      Lernbegleiter nur eigene.</p>
      <h4>Neue Werkstatt anlegen</h4>
      <ul>
        <li><strong>Pflichtfelder:</strong> Name, mind. eine Klasse, Startdatum, mind. ein Lernbegleiter</li>
        <li><strong>Klassen:</strong> Strg/Cmd für Mehrfachauswahl (jahrgangsübergreifend)</li>
        <li><strong>Lernbegleiter:</strong> Erster Eintrag = Leitung (kann bearbeiten),
        weitere = Begleitung</li>
        <li><strong>Max. Teilnehmer:</strong> Optional; wird beim Speichern geprüft</li>
        <li><strong>Kompetenzen:</strong> Erst Fächer mit Stunden eintragen → passende
        KLP-Tabs erscheinen; MKR immer verfügbar</li>
      </ul>
      <h4>Details-Modal</h4>
      <p>Klick auf „Details" öffnet ein Modal mit Statusänderung, Teilnehmerliste
      zum Abhaken (absolviert), Bearbeiten-Button und Löschen (nur Admin).</p>
      <h4>Werkstatt bearbeiten</h4>
      <p>Vollständige Bearbeiten-Seite mit allen Feldern vorausgefüllt. Stunden und
      Kompetenzen aktualisierbar. „← Zurück" führt zur Werkstattliste.</p>
    </div>

    <div class="hb-section">
      <h3>3. Bewertungen &amp; Rückmeldungen</h3>
      <h4>Werkstatt wählen</h4>
      <p>Dropdown oben → Bewertungstabelle und Rückmeldungsbereich erscheinen.</p>
      <h4>Bewertungstabelle</h4>
      <p>Schüler in Zeilen, Kompetenzen in Spalten. Horizontaler Scroll bei vielen
      Kompetenzen; Schülernamen bleiben links fixiert.</p>
      <table class="hb-table">
        <tr><th>Chip</th><th>Stufe</th><th>Bedeutung</th></tr>
        <tr><td><span class="bew-chip bew-1">1</span></td><td>1</td><td>Mit Unterstützung</td></tr>
        <tr><td><span class="bew-chip bew-2">2</span></td><td>2</td><td>Teilweise selbstständig</td></tr>
        <tr><td><span class="bew-chip bew-3">3</span></td><td>3</td><td>Weitgehend sicher</td></tr>
        <tr><td><span class="bew-chip bew-4">4</span></td><td>4</td><td>Sicher und reflektiert</td></tr>
      </table>
      <p>Klick auf Chip setzt Stufe; nochmal klicken entfernt sie. Wird sofort gespeichert.</p>
      <h4>Rückmeldungen</h4>
      <ul>
        <li>Empfänger per Checkbox wählen (einzeln, alle, Teilmenge)</li>
        <li>Bewertungsstufe optional (Gesamteinschätzung)</li>
        <li>Freitext – individuelle Rückmeldung</li>
        <li>„Für Schüler sichtbar" – sofort oder später aktivieren</li>
        <li>Pro Schüler pro Werkstatt eine Rückmeldung (erneutes Speichern überschreibt)</li>
      </ul>
    </div>

    <div class="hb-section">
      <h3>4. Schüler importieren (Admin)</h3>
      <ol>
        <li>Schuljahr wählen (aktives Schuljahr vorausgewählt)</li>
        <li>CSV-Datei aus Schild-NRW hochladen</li>
        <li>Vorschau prüfen: neu / aktualisiert / unverändert / Fehler</li>
        <li>Import durchführen</li>
      </ol>
      <p><strong>Benötigte Felder:</strong> Interne ID-Nummer, Vorname, Nachname, Klasse,
      Jahrgang, Geschlecht, Geburtsdatum, Klassenlehrer: Name, Klassenlehrer: Vorname.</p>
      <p>Schüler die nicht mehr in der CSV erscheinen werden automatisch inaktiviert.
      Das Import-Log zeigt die letzten 20 Importe mit Statistik.</p>
    </div>

    <div class="hb-section">
      <h3>5. Schuljahre (Admin)</h3>
      <table class="hb-table">
        <tr><th>Aktion</th><th>Bedingung</th></tr>
        <tr><td>Anlegen</td><td>Name (z. B. 2026/27), Beginn, Ende, Status</td></tr>
        <tr><td>Aktivieren</td><td>Nur ein aktives Schuljahr; vorheriges wird abgeschlossen</td></tr>
        <tr><td>Löschen</td><td>Nur wenn keine Werkstätten oder Schüler zugeordnet</td></tr>
      </table>
    </div>

    <div class="hb-section">
      <h3>6. Benutzerverwaltung (Admin)</h3>
      <table class="hb-table">
        <tr><th>Rolle</th><th>Rechte</th></tr>
        <tr><td>Admin</td><td>Alle Funktionen inkl. Schülerimport, Schuljahre, alle Werkstätten</td></tr>
        <tr><td>Lernbegleiter</td><td>Eigene Werkstätten anlegen/bearbeiten, Bewertungen, Rückmeldungen</td></tr>
      </table>
      <p><strong>Passwort-Anforderungen:</strong> Mind. 8 Zeichen, 1 Großbuchstabe, 1 Zahl.</p>
      <p>Admins können alle Passwörter ändern, Lernbegleiter nur ihr eigenes
      (altes Passwort erforderlich).</p>
    </div>

    <div class="hb-section">
      <h3>7. Export</h3>
      <ul>
        <li><strong>Stundenkontingent</strong> – alle Schüler, Stunden je Fach, Gesamtsumme</li>
        <li><strong>Kompetenzen</strong> – alle Schüler, Kompetenzen je Werkstatt</li>
      </ul>
      <p>Beide Formate: CSV, UTF-8 mit BOM (Excel-kompatibel), Semikolon-getrennt.
      Optional nach Klasse filtern.</p>
    </div>

    <div class="hb-section">
      <h3>8. Berechtigungsmodell</h3>
      <table class="hb-table">
        <tr><th>Aktion</th><th>Admin</th><th>Lernbegleiter</th></tr>
        <tr><td>Schuljahr verwalten</td><td>✓</td><td>–</td></tr>
        <tr><td>Schüler importieren</td><td>✓</td><td>–</td></tr>
        <tr><td>Benutzer verwalten</td><td>✓</td><td>–</td></tr>
        <tr><td>Alle Werkstätten sehen</td><td>✓</td><td>– (nur eigene)</td></tr>
        <tr><td>Werkstatt anlegen</td><td>✓</td><td>✓</td></tr>
        <tr><td>Werkstatt bearbeiten</td><td>✓</td><td>✓ (Leitung)</td></tr>
        <tr><td>Werkstatt löschen</td><td>✓</td><td>–</td></tr>
        <tr><td>Bewertungen vergeben</td><td>✓</td><td>✓ (eigene WS)</td></tr>
        <tr><td>Rückmeldungen schreiben</td><td>✓</td><td>✓ (eigene WS)</td></tr>
        <tr><td>Dashboard / Export</td><td>✓</td><td>✓</td></tr>
      </table>
    </div>

    <div class="hb-section">
      <h3>9. Datenschutz</h3>
      <p>Gespeichert werden ausschließlich schulbezogene Koordinationsdaten:
      Schülernamen, Klassen, Projektstunden, Kompetenzen, Bewertungen, Rückmeldungen.
      Kein Tracking. Alle Daten verbleiben auf dem Schulserver.</p>
    </div>
  </div>`;
}

// ============================================================
// SCHÜLER-PORTAL (nur für Schüler-Login via WebUntis)
// ============================================================
async function showSchuelerPortal(me) {
  document.getElementById('login-view').style.display = 'none';
  document.getElementById('app-view').style.display   = 'flex';
  // Nur Schüler-Screen sichtbar – Navigation ausblenden
  document.querySelector('aside').style.display = 'none';
  document.getElementById('schueler-portal-sub').textContent =
    `Hallo, ${/* keine-maskierung: textContent, kein HTML */ me.vorname} ${me.nachname}!`;
  await ladeSchuelerPortal(me.id);
}

async function ladeSchuelerPortal(schueler_id) {
  // Werkstätten des Schülers laden
  const data = await GET(`schueler-portal`);
  const el   = document.getElementById('schueler-portal-liste');

  if (!data || !data.werkstaetten || !data.werkstaetten.length) {
    el.innerHTML = '<div class="empty">Du bist noch keiner Werkstatt zugeordnet.</div>';
    return;
  }

  el.innerHTML = data.werkstaetten.map(w => `
    <div class="proj-card" style="cursor:pointer" onclick="schuelerWerkstattDetail(${w.id})">
      <div class="proj-row">
        <div style="flex:1">
          <div class="proj-name">${w.name}</div>
          <div class="proj-meta">
            ${w.datum_von}${w.datum_bis ? ' – ' + w.datum_bis : ''}
            ${/* keine-maskierung: schuljahre.name, beim Schreiben maskiert */ w.schuljahr_name ? ' · ' + w.schuljahr_name : ''}
          </div>
          <div class="proj-meta" style="margin-top:2px">
            👤 ${/* keine-maskierung: benutzer (GROUP_CONCAT), beim Schreiben maskiert */ w.lernbegleiter || '–'}
          </div>
          <div class="tags">
            <span class="tag-f">${w.status}</span>
            <span class="tag-k">${w.kompetenzen_anzahl || 0} Kompetenzen</span>
            ${w.abgeschlossen ? '<span class="tag-f" style="background:var(--bew-3-bg);color:var(--bew-3)">✓ Absolviert</span>' : ''}
          </div>
        </div>
        <div style="font-size:18px;color:var(--text3);align-self:center">›</div>
      </div>
    </div>`
  ).join('');
}

async function schuelerWerkstattDetail(werkstatt_id) {
  const detail = document.getElementById('schueler-portal-detail');
  const liste  = document.getElementById('schueler-portal-liste');

  detail.style.display = 'block';
  liste.style.display  = 'none';
  detail.innerHTML = '<p style="color:var(--text3);font-size:13px">Lade…</p>';

  const data = await GET(`schueler-portal/${werkstatt_id}`);
  if (!data) {
    detail.innerHTML = '<p style="color:var(--danger)">Fehler beim Laden.</p>';
    return;
  }

  const STUFEN = { 1: 'Mit Unterstützung', 2: 'Teilweise', 3: 'Weitgehend', 4: 'Sicher' };

  // Kompetenzen mit Fremd- und Selbsteinschätzung
  const kompRows = (data.kompetenzen || []).map(k => {
    const fremd = k.fremd_stufe
      ? `<span class="bew-chip bew-${k.fremd_stufe}">${k.fremd_stufe} – ${STUFEN[k.fremd_stufe]}</span>`
      : '<span style="color:var(--text3);font-size:12px">noch keine</span>';

    const selbstChips = [1,2,3,4].map(n =>
      `<span class="bew-chip bew-${n}${k.selbst_stufe===n?' on':''}"
             onclick="selbstEinschaetzung(${werkstatt_id},${k.kompetenz_id},${n},this)">${n}</span>`
    ).join('');

    return `
      <div style="padding:10px 0;border-bottom:1px solid var(--border)">
        <div style="font-size:13px;font-weight:500;margin-bottom:6px">
          ${k.code ? '[' + k.code + '] ' : ''}${k.kompetenz_name}
          <span style="color:var(--text3);font-size:11px">${k.bereich_name}</span>
        </div>
        <div style="display:flex;align-items:center;gap:12px;flex-wrap:wrap;font-size:12px">
          <div>
            <span style="color:var(--text3)">Einschätzung Lehrer: </span>${fremd}
          </div>
          <div style="display:flex;align-items:center;gap:6px">
            <span style="color:var(--text3)">Meine Selbsteinschätzung: </span>
            <div class="bew-cell">${selbstChips}</div>
          </div>
        </div>
      </div>`;
  }).join('');

  // Rückmeldungen (nur sichtbare)
  const rueckRows = (data.rueckmeldungen || []).map(r => `
    <div class="rueck-row">
      ${r.bewertung_stufe
        ? `<span class="bew-chip bew-${r.bewertung_stufe}" style="margin-bottom:6px;display:inline-block">
           ${r.bewertung_stufe} – ${STUFEN[r.bewertung_stufe]}</span>` : ''}
      ${r.freitext ? `<p style="font-size:13px;margin:0 0 4px">${escHtml(r.freitext)}</p>` : ''}
      <p style="font-size:11px;color:var(--text3);margin:0">
        ${/* keine-maskierung: benutzer, beim Schreiben maskiert */ r.lb_vorname} ${r.lb_nachname} · ${(r.geaendert_am || r.erstellt_am || '').substring(0,10)}
      </p>
    </div>`
  ).join('');

  detail.innerHTML = `
    <button class="btn" onclick="schuelerZurueck()" style="margin-bottom:16px">← Zurück</button>
    <h2>${data.name}</h2>
    <p style="font-size:13px;color:var(--text3);margin-bottom:16px">
      ${data.datum_von}${data.datum_bis ? ' – ' + data.datum_bis : ''}
      ${/* keine-maskierung: schuljahre.name, beim Schreiben maskiert */ data.schuljahr_name ? ' · ' + data.schuljahr_name : ''}
    </p>

    ${kompRows ? `
      <div class="card">
        <h2>Kompetenzen & Selbsteinschätzung</h2>
        <p style="font-size:12px;color:var(--text3);margin-bottom:10px">
          Klicke auf einen Chip um deine Selbsteinschätzung zu setzen.
        </p>
        ${kompRows}
      </div>` : ''}

    ${rueckRows ? `
      <div class="card" style="margin-top:16px">
        <h2>Rückmeldungen</h2>
        ${rueckRows}
      </div>` : '<div class="card" style="margin-top:16px"><p style="font-size:13px;color:var(--text3)">Noch keine Rückmeldungen.</p></div>'}

    <button class="btn" style="margin-top:16px;color:var(--danger)" onclick="doLogout()">Abmelden</button>
  `;
}

function schuelerZurueck() {
  document.getElementById('schueler-portal-detail').style.display = 'none';
  document.getElementById('schueler-portal-liste').style.display  = 'block';
}

async function selbstEinschaetzung(werkstatt_id, kompetenz_id, stufe, chipEl) {
  const row   = chipEl.closest('div');
  const aktiv = chipEl.classList.contains('on');
  const neue_stufe = aktiv ? null : stufe;
  row.querySelectorAll('.bew-chip').forEach(c => c.classList.remove('on'));
  if (!aktiv) chipEl.classList.add('on');
  try {
    await fetch(`/api/selbsteinschaetzung/${werkstatt_id}`, {
      method: 'PUT',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ kompetenz_id, selbst_stufe: neue_stufe })
    });
  } catch(e) { alert('Selbsteinschätzung konnte nicht gespeichert werden: ' + e.message); }
}

// ============================================================
// EINSTELLUNGEN
// ============================================================
// Vorgabefarben der Schule. KEINE Anzeigefarbe, sondern ein Datenwert:
// `applyEinstellungen` schreibt ihn IN `--accent` hinein. Ein Token zu
// lesen, um dasselbe Token zu setzen, waere ein Kreis -- und beim
// Zuruecksetzen ist ausdruecklich der Vorgabewert gemeint, nicht der
// gerade eingestellte.
//
// Die Wahrheit liegt im Backend (`index.php`, Vorgaben der Einstellungen).
// Dass sie hier noch einmal steht, ist eine zweite Wahrheit und als
// Befund gemeldet.
const STANDARD_AKZENT    = '#3d6b4f'; /* rohfarbe-erlaubt: Vorgabewert der Einstellungen, keine Darstellung */
const STANDARD_SEKUNDAER = '#2c4f3a'; /* rohfarbe-erlaubt: Vorgabewert der Einstellungen, keine Darstellung */

async function initEinstellungen() {
  const data = await GET('einstellungen');
  if (!data) return;

  document.getElementById('ein-schulname').value   = data.schulname       || '';
  document.getElementById('ein-titel').value        = data.app_titel       || '';
  document.getElementById('ein-untertitel').value   = data.app_untertitel  || '';

  const akzent = data.farbe_akzent    || STANDARD_AKZENT;
  const sek    = data.farbe_sekundaer || STANDARD_SEKUNDAER;
  document.getElementById('ein-farbe-akzent').value     = akzent;
  document.getElementById('ein-farbe-akzent-hex').value = akzent;
  document.getElementById('ein-farbe-sek').value         = sek;
  document.getElementById('ein-farbe-sek-hex').value     = sek;

  // Color-Picker ↔ Hex-Feld synchronisieren
  document.getElementById('ein-farbe-akzent').oninput = e => {
    document.getElementById('ein-farbe-akzent-hex').value = e.target.value;
  };
  document.getElementById('ein-farbe-akzent-hex').oninput = e => {
    if (/^#[0-9A-Fa-f]{6}$/.test(e.target.value))
      document.getElementById('ein-farbe-akzent').value = e.target.value;
  };
  document.getElementById('ein-farbe-sek').oninput = e => {
    document.getElementById('ein-farbe-sek-hex').value = e.target.value;
  };
  document.getElementById('ein-farbe-sek-hex').oninput = e => {
    if (/^#[0-9A-Fa-f]{6}$/.test(e.target.value))
      document.getElementById('ein-farbe-sek').value = e.target.value;
  };

  // Logo-Vorschau
  const vorschauEl = document.getElementById('ein-logo-vorschau');
  const loeschenBtn = document.getElementById('ein-logo-loeschen-btn');
  if (data.hat_logo) {
    vorschauEl.innerHTML = `<img src="/api/einstellungen/logo?v=${Date.now()}"
      style="max-height:80px;max-width:200px;object-fit:contain;border:1px solid var(--border);border-radius:8px;padding:8px">`;
    loeschenBtn.style.display = 'inline-flex';
  } else {
    vorschauEl.innerHTML = '<p style="font-size:13px;color:var(--text3)">Kein Logo hochgeladen.</p>';
    loeschenBtn.style.display = 'none';
  }
}

async function einstellungenSpeichern() {
  const body = {
    schulname:      document.getElementById('ein-schulname').value.trim(),
    app_titel:      document.getElementById('ein-titel').value.trim(),
    app_untertitel: document.getElementById('ein-untertitel').value.trim(),
  };
  try {
    const r = await fetch('/api/einstellungen', {
      method: 'POST', credentials: 'include',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify(body)
    });
    const data = await r.json();
    if (!r.ok) throw new Error(data.error);
    showMsg('ein-msg', 'Gespeichert ✓', 'ok');
    // Login-Box aktualisieren
    applyEinstellungen(body);
  } catch(e) { showMsg('ein-msg', e.message, 'err'); }
}

async function farbenanSpeichern() {
  const body = {
    farbe_akzent:    document.getElementById('ein-farbe-akzent-hex').value,
    farbe_sekundaer: document.getElementById('ein-farbe-sek-hex').value,
  };
  try {
    const r = await fetch('/api/einstellungen', {
      method: 'POST', credentials: 'include',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify(body)
    });
    const data = await r.json();
    if (!r.ok) throw new Error(data.error);
    showMsg('ein-farb-msg', 'Farben gespeichert ✓', 'ok');
    applyEinstellungen(body);
  } catch(e) { showMsg('ein-farb-msg', e.message, 'err'); }
}

async function einstellungenZuruecksetzen() {
  if (!confirm('Alle Einstellungen und das Logo auf Standard zurücksetzen?')) return;
  try {
    const r = await fetch('/api/einstellungen/zuruecksetzen', {
      method: 'POST', credentials: 'include',
      headers: {'Content-Type':'application/json'}, body: '{}'
    });
    if (!r.ok) throw new Error('Fehler');
    showMsg('ein-farb-msg', 'Zurückgesetzt ✓', 'ok');
    initEinstellungen();
    applyEinstellungen({
      schulname: 'Friedrich-Rückert-Gymnasium Düsseldorf',
      app_titel: 'Projektstunden NRW',
      app_untertitel: 'Gymnasium G9 – Kompetenz- und Stunden-Tracking',
      farbe_akzent: STANDARD_AKZENT,
      farbe_sekundaer: STANDARD_SEKUNDAER,
    });
  } catch(e) { showMsg('ein-farb-msg', e.message, 'err'); }
}

// Logo
let LOGO_BASE64 = null;

function logoGewaehlt(input) {
  const file = input.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = e => {
    LOGO_BASE64 = e.target.result.split(',')[1];
    document.getElementById('ein-logo-upload-btn').disabled = false;
    // Vorschau
    document.getElementById('ein-logo-vorschau').innerHTML =
      `<img src="${e.target.result}"
        style="max-height:80px;max-width:200px;object-fit:contain;border:1px solid var(--border);border-radius:8px;padding:8px">`;
  };
  reader.readAsDataURL(file);
}

async function logoHochladen() {
  if (!LOGO_BASE64) return;
  try {
    const r = await fetch('/api/einstellungen/logo', {
      method: 'POST', credentials: 'include',
      headers: {'Content-Type':'application/json'},
      body: JSON.stringify({ daten: LOGO_BASE64 })
    });
    const data = await r.json();
    if (!r.ok) throw new Error(data.error);
    showMsg('ein-logo-msg', 'Logo gespeichert ✓', 'ok');
    LOGO_BASE64 = null;
    document.getElementById('ein-logo-upload-btn').disabled = true;
    document.getElementById('ein-logo-loeschen-btn').style.display = 'inline-flex';
    // Nav-Logo aktualisieren
    ladeNavLogo();
  } catch(e) { showMsg('ein-logo-msg', e.message, 'err'); }
}

async function logoLoeschen() {
  if (!confirm('Logo entfernen?')) return;
  try {
    await fetch('/api/einstellungen/logo/loeschen', {
      method: 'POST', credentials: 'include',
      headers: {'Content-Type':'application/json'}, body: '{}'
    });
    showMsg('ein-logo-msg', 'Logo entfernt ✓', 'ok');
    document.getElementById('ein-logo-vorschau').innerHTML =
      '<p style="font-size:13px;color:var(--text3)">Kein Logo hochgeladen.</p>';
    document.getElementById('ein-logo-loeschen-btn').style.display = 'none';
    ladeNavLogo();
  } catch(e) { showMsg('ein-logo-msg', e.message, 'err'); }
}

// ── Einstellungen auf die App anwenden (CSS-Variablen + Texte) ──────────────
function applyEinstellungen(data) {
  if (data.farbe_akzent) {
    document.documentElement.style.setProperty('--accent', data.farbe_akzent);
    // `--accent-dark` wurde hier ebenfalls gesetzt und im ganzen frontend/
    // nirgends gelesen -- weder in einer Stilvorlage noch im JavaScript.
    // Weder die Pruefung "benutzt, aber nicht definiert" (E58) noch ihre
    // Gegenrichtung haetten das gefunden: Der Name kam ueberhaupt nur an
    // dieser einen Stelle vor.
  }
  if (data.farbe_sekundaer) {
    document.documentElement.style.setProperty('--nav-bg', data.farbe_sekundaer);
  }
  if (data.schulname) {
    const el = document.getElementById('nav-schulname');
    if (el) el.textContent = data.schulname;
  }
  if (data.app_titel) {
    const el = document.getElementById('nav-app-titel');
    if (el) el.textContent = data.app_titel;
    document.title = data.app_titel;
  }
}

/**
 * Zeigt das Logo ueber der Anmeldemaske, falls eines hinterlegt ist.
 *
 * Der Endpunkt ist oeffentlich - er muss es sein, denn hier ist noch
 * niemand angemeldet. Er liefert nur das Bild, keine weiteren Daten.
 *
 * complete pruefen statt nur auf 'load' warten: Das src-Attribut steht
 * im HTML, das Bild laedt also schon beim Parsen. Wenn dieser Code
 * laeuft, ist das Ereignis unter Umstaenden vorbei.
 */
function ladeLoginLogo() {
  const bild = document.getElementById('login-logo');
  if (!bild) return;
  const entscheiden = () => { bild.hidden = !(bild.naturalWidth > 0); };
  if (bild.complete) { entscheiden(); return; }
  bild.addEventListener('load', entscheiden);
  bild.addEventListener('error', () => { bild.hidden = true; });
}

async function ladeNavLogo() {
  const el = document.getElementById('nav-logo');
  const platz = document.getElementById('nav-platzhalter');
  if (!el) return;

  // hidden statt style.display: Das Modul blendet damit auch den
  // Platzhalter aus (.ci-schild-logo[hidden] in ci-shell.css). Ohne
  // das stuenden beide nebeneinander - in einem Flex-Behaelter setzt
  // der Browser display sonst auf block und ueberschreibt hidden.
  try {
    // Cache-Busting via Timestamp
    const r = await fetch(`/api/einstellungen/logo?v=${Date.now()}`, {credentials:'include'});
    if (r.ok) {
      const blob = await r.blob();
      el.src = URL.createObjectURL(blob);
      el.hidden = false;
      if (platz) platz.hidden = true;
      return;
    }
  } catch (e) {
    /* Ohne Logo bleibt der Platzhalter - kein Grund fuer eine Meldung. */
  }
  el.hidden = true;
  if (platz) platz.hidden = false;
}

async function ladeEinstellungenApp() {
  try {
    const data = await GET('einstellungen');
    if (data) applyEinstellungen(data);
    ladeNavLogo();
  } catch { /* Einstellungen optional */ }
}
