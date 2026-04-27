
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
  if (r.status === 401) { showLogin(); return null; }
  if (!r.ok) {
    const e = await r.json().catch(() => ({ error: 'Netzwerkfehler' }));
    throw new Error(e.error || 'Fehler ' + r.status);
  }
  // Export-Endpunkte liefern Blobs zurück
  const ct = r.headers.get('Content-Type') || '';
  if (ct.includes('text/csv')) return r.blob();
  return r.json();
}
const GET    = (path)        => api('GET',    path);
const POST   = (path, body)  => api('POST',   path, body);
const DELETE = (path)        => api('DELETE', path);

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
    if (me && me.id) { STATE.user = me; showApp(); }
    else showLogin();
  } catch { showLogin(); }
}
function showLogin() {
  document.getElementById('login-view').style.display = 'flex';
  document.getElementById('app-view').style.display   = 'none';
}
async function showApp() {
  document.getElementById('login-view').style.display = 'none';
  document.getElementById('app-view').style.display   = 'flex';
  // Admin-Klasse am Shell-Element setzen (steuert Sichtbarkeit admin-only Elemente)
  if (STATE.user && STATE.user.rolle === 'admin') {
    document.getElementById('app-view').classList.add('is-admin');
  } else {
    document.getElementById('app-view').classList.remove('is-admin');
  }
  await loadState();
  go('dashboard');
}
async function doLogin() {
  const email = document.getElementById('l-email').value.trim();
  const pass  = document.getElementById('l-pass').value;
  try {
    // Login-Response direkt in STATE.user speichern, damit showApp()
    // die Rolle kennt und Admin-UI korrekt ein-/ausblendet.
    const me = await POST('auth/login', { email, passwort: pass });
    STATE.user = me;
    showApp();
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
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('on'));
  document.querySelectorAll('.nv').forEach(b => b.classList.remove('on'));
  document.getElementById('s-' + id).classList.add('on');
  document.querySelectorAll('.nv').forEach(b => {
    if ((b.getAttribute('onclick') || '').includes("'" + id + "'")) b.classList.add('on');
  });
  const init = { dashboard: initDash, projekt: initProjekt, schueler: initSchueler,
                 klassen: initKlassen, katalog: initKatalog, export: initExport,
                 benutzer: initBenutzer, schuljahre: initSchuljahre, import: initImport };
  if (init[id]) init[id]();
}

// ============================================================
// DASHBOARD
// ============================================================
async function initDash() {
  // Klassen-Dropdown befüllen
  const kEl = document.getElementById('f-kl');
  const cur  = kEl.value;
  kEl.innerHTML = '<option value="">Alle Klassen</option>' +
    STATE.klassen.map(k => `<option value="${k.id}"${k.id==cur?' selected':''}>${k.bezeichnung} (${k.schuljahr})</option>`).join('');
  await renderDash();
}
async function dashFilter() {
  const kl = document.getElementById('f-kl').value;
  const sEl = document.getElementById('f-s');
  // Schüler für Klasse laden
  const schueler = kl ? await GET(`schueler?klasse_id=${kl}`) : [];
  sEl.innerHTML = '<option value="">Alle Schüler</option>' +
    (schueler || []).map(s => `<option value="${s.id}">${s.vorname} ${s.nachname} (${s.klasse})</option>`).join('');
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
      const pct = f.soll > 0 ? Math.min(100, Math.round(f.projekt_stunden / f.soll * 100)) : 0;
      let dc = 'dnone', fc = '';
      if (f.soll > 0 && f.projekt_stunden > 0) {
        const r = f.projekt_stunden / f.soll;
        dc = r >= 1 ? 'dover' : r >= 0.4 ? 'dok' : 'dwarn';
        fc = r >= 1 ? 'pover' : r >= 0.4 ? 'pok'  : 'pwarn';
      }
      return `<div class="f-row">
        <span class="dot ${dc}"></span>
        <span class="f-lbl">${f.fach_name}</span>
        <span class="f-nums">${f.projekt_stunden} / ${f.soll} Std.</span>
        <div class="pbar"><div class="pfill ${fc}" style="width:${pct}%"></div></div>
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
        <div class="avatar">${s.vorname[0]}${s.nachname[0]}</div>
        <div><div class="s-name">${s.vorname} ${s.nachname}</div>
          <div class="s-meta">Klasse ${s.klasse} · ${Math.round(totalIst*10)/10}/${totalSoll} Projektstd. · ${komps.length} Kompetenzen</div>
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
  // Klassen-Dropdown
  const kEl = document.getElementById('p-kl');
  kEl.innerHTML = '<option value="">– wählen –</option>' +
    STATE.klassen.map(k => `<option value="${k.id}">${k.bezeichnung} (${k.schuljahr})</option>`).join('');

  // Lehrer-Dropdown
  const lEl = document.getElementById('p-lehrer');
  lEl.innerHTML = '<option value="">– wählen –</option>' +
    STATE.lehrer.map(l => `<option value="${l.id}">${l.vorname} ${l.nachname}${l.kuerzel ? ' (' + l.kuerzel + ')' : ''}</option>`).join('');

  // Fach-Grid aufbauen
  buildFachGrid();
  // Datum: heute
  document.getElementById('p-von').valueAsDate = new Date();
  // Kompetenzen: alle Rahmen laden (initial fächerübergreifend = MKR)
  await loadKompetenzenFuerFaecher([]);
  renderRahmenTabs();
  await renderProjektListe();
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
  // Rahmen, die relevant sind: fächerübergreifende immer + Fach-Rahmen für beteiligte Fächer
  const relRahmen = STATE.rahmen.filter(r => !r.fach_kuerzel || fids.some(fid => {
    const f = STATE.faecher.find(x => x.id == fid);
    return f && f.kuerzel === r.fach_kuerzel;
  }));

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

function loadSchuelerForProjekt() {
  const kl = document.getElementById('p-kl').value;
  if (!kl) { document.getElementById('p-schueler').innerHTML = ''; return; }
  GET(`schueler?klasse_id=${kl}`).then(list => {
    document.getElementById('p-schueler').innerHTML = (list || [])
      .map(s => `<option value="${s.id}">${s.vorname} ${s.nachname}</option>`).join('');
  });
}

async function projektSpeichern() {
  const name      = document.getElementById('p-name').value.trim();
  const klasse_id = parseInt(document.getElementById('p-kl').value);
  const datum_von = document.getElementById('p-von').value;
  const datum_bis = document.getElementById('p-bis').value || null;
  const beschreibung = document.getElementById('p-desc').value.trim();
  const status    = document.getElementById('p-status').value;
  const lehrer_id = parseInt(document.getElementById('p-lehrer').value) || null;
  const schueler_ids = [...document.getElementById('p-schueler').selectedOptions].map(o => parseInt(o.value));
  if (!name || !klasse_id || !datum_von || !schueler_ids.length)
    return showMsg('p-msg', 'Bitte Pflichtfelder füllen und Schüler auswählen.', 'err');

  // Stunden
  const stunden = [...document.querySelectorAll('#p-fach-grid input')]
    .filter(i => parseFloat(i.value) > 0)
    .map(i => ({ fach_id: parseInt(i.dataset.fid), stunden: parseFloat(i.value) }));
  if (!stunden.length) return showMsg('p-msg', 'Mindestens einem Fach Stunden zuweisen.', 'err');

  // Kompetenzen: für alle gewählten Schüler gleich
  const kompIds = [...document.querySelectorAll('.komp-cb:checked')].map(c => parseInt(c.value));
  const kompetenzen = [];
  for (const sid of schueler_ids) {
    for (const kid of kompIds) kompetenzen.push({ schueler_id: sid, kompetenz_id: kid });
  }

  try {
    await POST('projekte', { name, klasse_id, datum_von, datum_bis, beschreibung, status,
                              lehrer_id, schueler_ids, stunden, kompetenzen });
    showMsg('p-msg', 'Projekt gespeichert.', 'ok');
    // Reset
    document.getElementById('p-name').value = '';
    document.getElementById('p-desc').value = '';
    document.querySelectorAll('#p-fach-grid input').forEach(i => i.value = '');
    document.querySelectorAll('.komp-cb').forEach(c => c.checked = false);
    document.getElementById('p-summe').textContent = '0';
    renderProjektListe();
  } catch(e) { showMsg('p-msg', e.message, 'err'); }
}

async function renderProjektListe() {
  const kl = document.getElementById('p-kl').value;
  const data = await GET('projekte' + (kl ? '?klasse_id=' + kl : ''));
  const el = document.getElementById('proj-liste');
  if (!data || !data.length) { el.innerHTML = '<div class="empty">Noch keine Projekte eingetragen.</div>'; return; }
  el.innerHTML = data.map(p =>
    `<div class="proj-card">
       <div class="proj-row">
         <div>
           <div class="proj-name">${p.name}</div>
           <div class="proj-meta">${p.datum_von} · Klasse ${p.klasse} · ${p.schueler_anzahl} Schüler · ${p.lehrer}</div>
           <div class="tags">
             <span class="tag-f">${p.schueler_anzahl} Schüler</span>
             <span class="tag-k">${p.kompetenzen_anzahl} Kompetenzen</span>
             <span class="tag-f">${p.status}</span>
           </div>
         </div>
       </div>
     </div>`
  ).join('');
}

// ============================================================
// SCHÜLER
// ============================================================
async function initSchueler() {
  const el = document.getElementById('s-kl');
  el.innerHTML = '<option value="">– wählen –</option>' +
    STATE.klassen.map(k => `<option value="${k.id}">${k.bezeichnung} (${k.schuljahr})</option>`).join('');
  renderSchuelerListe();
}
async function schuelerSpeichern() {
  const vorname  = document.getElementById('s-vor').value.trim();
  const nachname = document.getElementById('s-nach').value.trim();
  const klasse_id = parseInt(document.getElementById('s-kl').value);
  if (!vorname || !nachname || !klasse_id)
    return showMsg('s-msg', 'Alle Felder ausfüllen.', 'err');
  try {
    await POST('schueler', { vorname, nachname, klasse_id });
    showMsg('s-msg', vorname + ' ' + nachname + ' angelegt.', 'ok');
    document.getElementById('s-vor').value = '';
    document.getElementById('s-nach').value = '';
    renderSchuelerListe();
  } catch(e) { showMsg('s-msg', e.message, 'err'); }
}
async function renderSchuelerListe() {
  const data = await GET('schueler');
  const el = document.getElementById('s-liste');
  if (!data || !data.length) { el.innerHTML = '<div class="empty">Noch keine Schüler.</div>'; return; }
  const gr = {};
  data.forEach(s => (gr[s.klasse] = gr[s.klasse] || []).push(s));
  el.innerHTML = Object.keys(gr).sort().map(kl =>
    `<div class="card">
       <div class="sec" style="margin-top:0">Klasse ${kl}</div>
       ${gr[kl].map(s =>
         `<div style="display:flex;align-items:center;justify-content:space-between;padding:5px 0;border-bottom:1px solid var(--border)">
            <div style="display:flex;align-items:center;gap:10px">
              <div class="avatar">${s.vorname[0]}${s.nachname[0]}</div>
              <span>${s.vorname} ${s.nachname}</span>
            </div>
            <button class="btn btn-sm btn-d" onclick="delSchueler(${s.id})">entfernen</button>
          </div>`
       ).join('')}
     </div>`
  ).join('');
}
async function delSchueler(id) {
  if (!confirm('Schüler wirklich entfernen?')) return;
  await DELETE('schueler/' + id);
  renderSchuelerListe();
}

// ============================================================
// KLASSEN
// ============================================================
async function initKlassen() { renderKlassenListe(); }
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
    await loadState(); // STATE.klassen aktualisieren
    renderKlassenListe();
  } catch(e) { showMsg('kl-msg', e.message, 'err'); }
}
async function renderKlassenListe() {
  const el = document.getElementById('kl-liste');
  if (!STATE.klassen.length) { el.innerHTML = '<div class="empty">Noch keine Klassen.</div>'; return; }
  el.innerHTML = STATE.klassen.map(k =>
    `<div class="card" style="display:flex;align-items:center;justify-content:space-between">
       <div>
         <strong>${k.bezeichnung}</strong>
         <span style="font-size:12px;color:var(--text3);margin-left:10px">Jg. ${k.jahrgang} · ${k.schuljahr} · ${k.schueler_anzahl} Schüler</span>
       </div>
     </div>`
  ).join('');
}

// ============================================================
// KOMPETENZKATALOG
// ============================================================
async function initKatalog() {
  const rEl = document.getElementById('kat-rahmen');
  const fEl = document.getElementById('kat-fach');
  rEl.innerHTML = '<option value="">Alle Rahmen</option>' +
    STATE.rahmen.map(r => `<option value="${r.id}">${r.name}</option>`).join('');
  fEl.innerHTML = '<option value="">Alle Fächer</option>' +
    STATE.faecher.map(f => `<option value="${f.id}">${f.name}</option>`).join('');
  const all = await GET('kompetenzen');
  STATE.kompetenzen = all || [];
  renderKatalog();
}
function renderKatalog() {
  const rid = parseInt(document.getElementById('kat-rahmen').value) || 0;
  const fid = parseInt(document.getElementById('kat-fach').value)   || 0;
  let komps = STATE.kompetenzen;
  if (rid) komps = komps.filter(k => { const r = STATE.rahmen.find(x => x.id === rid); return r && k.rahmen_kuerzel === r.kuerzel; });
  if (fid) { const selFach = STATE.faecher.find(x => x.id == fid); komps = komps.filter(k => selFach && k.fach_kuerzel === selFach.kuerzel); }

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
    return `<div class="card">
      <div style="font-size:11px;color:var(--text3);font-weight:600;text-transform:uppercase;letter-spacing:.08em;margin-bottom:4px">${rahmen}</div>
      <h2>${bereichName}</h2>
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
    STATE.klassen.map(k => `<option value="${k.id}">${k.bezeichnung} (${k.schuljahr})</option>`).join('');
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
function showMsg(elId, txt, type) {
  const el = document.getElementById(elId);
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
      <td><strong>${b.vorname} ${b.nachname}</strong></td>
      <td style="color:var(--text2)">${b.email}</td>
      <td><code style="font-size:12px;background:var(--surface2);padding:2px 6px;border-radius:4px">${b.kuerzel || '–'}</code></td>
      <td><span class="rolle-badge ${rolleCls}">${rolleLabel}</span></td>
      <td style="font-size:12px;color:var(--text3)">${b.aktiv ? 'Aktiv' : 'Deaktiviert'}</td>
      <td style="white-space:nowrap">
        <button class="btn btn-sm" onclick="buBearbeiten(${b.id})" style="margin-right:4px">Bearbeiten</button>
        <button class="btn btn-sm" onclick="buPasswort(${b.id},'${b.vorname} ${b.nachname}')">Passwort</button>
        ${b.aktiv
          ? `<button class="btn btn-sm btn-d" onclick="buDeaktivieren(${b.id},'${b.vorname} ${b.nachname}')" style="margin-left:4px">Deaktivieren</button>`
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
    showMsg('bu-msg', `${vorname} ${nachname} wurde angelegt.`, 'ok');
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
      <p class="modal-sub">${b.vorname} ${b.nachname}</p>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
        <div><label>Vorname *</label><input id="m-vor" value="${b.vorname}"></div>
        <div><label>Nachname *</label><input id="m-nach" value="${b.nachname}"></div>
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
    showMsg('bu-msg', `${vorname} ${nachname} aktualisiert.`, 'ok');
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
            <button class="btn" style="padding:4px 10px;font-size:12px;color:var(--err)"
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
  // Schuljahr-Auswahl befüllen
  const sel = document.getElementById('imp-sj');
  const data = await GET('schuljahre');
  if (data && data.length) {
    sel.innerHTML = data.map(sj =>
      `<option value="${sj.id}"${sj.status === 'aktiv' ? ' selected' : ''}>${sj.name}${sj.status === 'aktiv' ? ' (aktiv)' : ''}</option>`
    ).join('');
  } else {
    sel.innerHTML = '<option value="">– Kein Schuljahr vorhanden –</option>';
  }
  // Import-Log laden
  await impLogLaden();
}

async function impLogLaden() {
  const logEl = document.getElementById('imp-log-liste');
  try {
    const data = await GET('import/log');
    if (data && data.length) {
      logEl.innerHTML = data.map(e => `
        <div class="card" style="margin-bottom:8px;font-size:13px">
          <div style="font-weight:600">${e.dateiname}</div>
          <div style="color:var(--text3);font-size:12px;margin-top:2px">
            ${new Date(e.erstellt_am).toLocaleString('de-DE')} &nbsp;·&nbsp;
            ${e.schuljahr_name ?? ''} &nbsp;·&nbsp;
            ${e.vorname ?? ''} ${e.nachname ?? ''}
          </div>
          <div style="margin-top:4px">
            <span style="color:var(--ok)">+${e.neu} neu</span> &nbsp;·&nbsp;
            <span style="color:var(--warn,#f59e0b)">${e.aktualisiert} aktualisiert</span> &nbsp;·&nbsp;
            ${e.unveraendert} unverändert
            ${e.inaktiviert ? `&nbsp;·&nbsp;<span style="color:var(--text3)">${e.inaktiviert} inaktiviert</span>` : ''}
            ${e.fehler ? `&nbsp;·&nbsp;<span style="color:var(--err)">${e.fehler} Fehler</span>` : ''}
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

  const sjId = document.getElementById('imp-sj').value;
  const fd = new FormData();
  fd.append('datei', IMP_DATEI);
  if (sjId) fd.append('schuljahr_id', sjId);

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
      <div class="stat"><div class="stat-val" style="color:var(--warn,#f59e0b)">${v.aktualisiert?.length ?? 0}</div><div class="stat-lbl">Aktualisiert</div></div>
      <div class="stat"><div class="stat-val">${v.unveraendert?.length ?? 0}</div><div class="stat-lbl">Unverändert</div></div>
      <div class="stat"><div class="stat-val" style="color:var(--err)">${v.fehler?.length ?? 0}</div><div class="stat-lbl">Fehler</div></div>`;

    let detail = '';
    if (v.neu?.length)
      detail += `<div class="sec" style="margin-top:12px">Neue Schüler (${v.neu.length})</div>` +
        v.neu.slice(0, 10).map(s => `<div style="font-size:13px;padding:3px 0">${s.vorname} ${s.nachname} – Klasse ${s.klasse}</div>`).join('') +
        (v.neu.length > 10 ? `<div style="font-size:12px;color:var(--text3)">… und ${v.neu.length - 10} weitere</div>` : '');
    if (v.aktualisiert?.length)
      detail += `<div class="sec" style="margin-top:12px">Aktualisiert (${v.aktualisiert.length})</div>` +
        v.aktualisiert.slice(0, 5).map(s => `<div style="font-size:13px;padding:3px 0">${s.vorname} ${s.nachname}</div>`).join('') +
        (v.aktualisiert.length > 5 ? `<div style="font-size:12px;color:var(--text3)">… und ${v.aktualisiert.length - 5} weitere</div>` : '');
    if (v.fehler?.length)
      detail += `<div class="sec" style="margin-top:12px;color:var(--err)">Fehler (${v.fehler.length})</div>` +
        v.fehler.map(f => `<div style="font-size:12px;color:var(--err);padding:2px 0">${f.zeile ?? ''}: ${f.meldung ?? f}</div>`).join('');

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

  const sjId = document.getElementById('imp-sj').value;
  const fd = new FormData();
  fd.append('datei', IMP_DATEI);
  if (sjId) fd.append('schuljahr_id', sjId);

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

