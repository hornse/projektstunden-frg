
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
function showLogin() {
  document.getElementById('login-view').style.display = 'flex';
  document.getElementById('app-view').style.display   = 'none';
}
async function showApp() {
  document.getElementById('login-view').style.display = 'none';
  document.getElementById('app-view').style.display   = 'flex';
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
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('on'));
  document.querySelectorAll('.nv').forEach(b => b.classList.remove('on'));
  document.getElementById('s-' + id).classList.add('on');
  document.querySelectorAll('.nv').forEach(b => {
    if ((b.getAttribute('onclick') || '').includes("'" + id + "'")) b.classList.add('on');
  });
  const init = { dashboard: initDash, projekt: initProjekt, schueler: initSchueler,
                 klassen: initKlassen, katalog: initKatalog, export: initExport,
                 benutzer: initBenutzer, schuljahre: initSchuljahre, import: initImport,
                 bewertung: initBewertung, hilfe: initHilfe,
                 'werkstatt-edit': () => {} };
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
    `<option value="${k.id}">${k.bezeichnung} (${k.schuljahr})</option>`
  ).join('');

  // Lernbegleiter Multi-Select (eigene ID vorausgewählt)
  const lEl = document.getElementById('p-lehrer');
  lEl.innerHTML = STATE.lehrer.map(l =>
    `<option value="${l.id}" ${l.id === STATE.user?.id ? 'selected' : ''}>${l.vorname} ${l.nachname}${l.kuerzel ? ' (' + l.kuerzel + ')' : ''}</option>`
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

function loadSchuelerForProjekt() {
  const selected = [...document.getElementById('p-kl').selectedOptions].map(o => o.value);
  if (!selected.length) { document.getElementById('p-schueler').innerHTML = ''; return; }
  GET(`schueler?klassen=${selected.join(',')}`).then(list => {
    document.getElementById('p-schueler').innerHTML = (list || [])
      .map(s => `<option value="${s.id}">${s.nachname}, ${s.vorname} (${s.klasse})</option>`).join('');
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
  const schueler_ids = [...document.getElementById('p-schueler').selectedOptions].map(o => parseInt(o.value));

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
            ${p.schuljahr_name ? ' · ' + p.schuljahr_name : ''}
            · ${p.schueler_anzahl} Schüler/innen
          </div>
          <div class="proj-meta" style="margin-top:2px">
            👤 ${p.lernbegleiter || '–'}
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
    `<span class="tag-k">${l.vorname} ${l.nachname} (${l.rolle})</span>`
  ).join(' ');

  const statusOptionen = ['geplant','aktiv','abgeschlossen','abgesagt']
    .map(s => `<option value="${s}" ${s === p.status ? 'selected' : ''}>${s}</option>`).join('');

  const schuelerRows = schueler.map(s => `
    <div style="display:flex;align-items:center;gap:8px;padding:7px 0;border-bottom:1px solid var(--border)">
      <input type="checkbox" id="abs-${s.id}"
             ${s.abgeschlossen ? 'checked' : ''}
             onchange="toggleAbschluss(${p.id}, ${s.id}, this.checked)"
             style="flex-shrink:0;width:16px;height:16px;cursor:pointer">
      <label for="abs-${s.id}" style="flex:1;cursor:pointer;font-size:13px;line-height:1.4">
        ${s.nachname}, ${s.vorname}
        <span style="color:var(--text3);font-size:11px">(${s.klasse})</span>
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
        ${p.schuljahr_name ? ' · ' + p.schuljahr_name : ''}
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

async function openWerkstattBearbeiten(id) {
  WS_EDIT_ID = id;
  go('werkstatt-edit');
  document.getElementById('we-id').value = id;

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
      `<option value="${s.id}" ${s.id == proj.schuljahr_id ? 'selected' : ''}>${s.name}</option>`
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
    `<option value="${l.id}" ${lbIds.includes(l.id) ? 'selected' : ''}>${l.vorname} ${l.nachname}${l.kuerzel ? ' (' + l.kuerzel + ')' : ''}</option>`
  ).join('');

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

  // Kompetenzen laden und vorhandene vorauswählen
  await loadKompetenzenFuerFaecherWe([]);
  renderRahmenTabsWe();

  // Vorhandene Kompetenzen markieren
  const vorhandeneKompIds = (proj.kompetenzen || []).map(k => k.id);
  setTimeout(() => {
    document.querySelectorAll('#we-komp-bereich-list .komp-cb').forEach(cb => {
      cb.checked = vorhandeneKompIds.includes(parseInt(cb.value));
    });
  }, 200);
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

function renderKompBereichListWe(rahmen_id, fachIds) {
  // Gleiche Logik wie renderKompBereichList aber für #we-komp-bereich-list
  const fids = fachIds || [];
  const r = STATE.rahmen.find(x => x.id === rahmen_id);
  if (!r) return;
  const komp = STATE.kompetenzen.filter(k => {
    if (k.rahmen_kuerzel !== r.kuerzel) return false;
    if (k.fach_kuerzel && fids.length > 0)
      return fids.some(fid => { const f = STATE.faecher.find(x => x.id == fid); return f && f.kuerzel === k.fach_kuerzel; });
    return true;
  });
  const allgemeine = komp.filter(k => !k.eltern_kompetenz_id);
  const erwartungen = komp.filter(k => k.eltern_kompetenz_id);
  const erwByEltern = {};
  erwartungen.forEach(e => { (erwByEltern[e.eltern_kompetenz_id] = erwByEltern[e.eltern_kompetenz_id] || []).push(e); });
  const bereiche = {};
  allgemeine.forEach(k => { const b = k.bereich_code + ': ' + k.bereich_name; (bereiche[b] = bereiche[b] || []).push(k); });
  const el = document.getElementById('we-komp-bereich-list');
  if (!Object.keys(bereiche).length) { el.innerHTML = '<p style="font-size:12px;color:var(--text3)">Keine Kompetenzen verfügbar.</p>'; return; }
  el.innerHTML = Object.entries(bereiche).map(([b, ks]) => {
    const items = ks.map(k => {
      const kinder = erwByEltern[k.id] || [];
      const tid = 'we-erw-' + k.id;
      let html = `<div class="komp-eltern-row"><label class="komp-pill">
        <input type="checkbox" class="we-komp-cb" value="${k.id}">
        <span class="pill-label" title="${k.beschreibung||''}">${k.kurzname}</span></label>`;
      if (kinder.length) html += `<button class="komp-eltern-toggle" onclick="toggleErw('${tid}',this)">▸ ${kinder.length}</button>`;
      html += `</div>`;
      if (kinder.length) {
        html += `<div class="komp-erwartungen" id="${tid}">` +
          kinder.map(e => `<label class="komp-pill erw"><input type="checkbox" class="we-komp-cb" value="${e.id}">
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

  const kompIds = [...document.querySelectorAll('.we-komp-cb:checked')].map(c => parseInt(c.value));

  if (!name || !datum_von) return showMsg('we-msg', 'Name und Startdatum sind Pflichtfelder.', 'err');
  if (!lehrer_ids.length) return showMsg('we-msg', 'Mindestens einen Lernbegleiter wählen.', 'err');

  try {
    const r = await fetch('/api/projekte/' + id, {
      method: 'PUT',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name, datum_von, datum_bis, laufzeit, praesentation_datum,
        max_schueler, beschreibung, status, schuljahr_id,
        lehrer_ids, stunden, kompetenz_ids: kompIds
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


// ============================================================
// BEWERTUNGEN & RÜCKMELDUNGEN – eigener Screen
// ============================================================
let BEW_PROJEKT_ID = null;

async function initBewertung() {
  const data = await GET('projekte');
  const sel  = document.getElementById('bew-werkstatt');
  sel.innerHTML = '<option value="">– Werkstatt auswählen –</option>' +
    (data || []).map(p =>
      `<option value="${p.id}">${p.name}${p.schuljahr_name ? ' · ' + p.schuljahr_name : ''} (${p.status})</option>`
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
  const bewertungen = await GET(`bewertung?projekt_id=${projekt_id}`);
  const el = document.getElementById('bew-tabelle');
  if (!el) return;

  if (!bewertungen || !bewertungen.length) {
    el.innerHTML = '<p style="font-size:13px;color:var(--text3)">Noch keine Kompetenzen für diese Werkstatt zugewiesen. Bitte zuerst unter „Werkstätten" → Bearbeiten Kompetenzen auswählen und speichern.</p>';
    return;
  }

  // Eindeutige Kompetenzen und Schüler
  const kompMap = {};
  const schuelerMap = {};
  bewertungen.forEach(b => {
    kompMap[b.kompetenz_id] = { id: b.kompetenz_id, name: b.kompetenz_name, code: b.code, bereich: b.bereich_name };
    schuelerMap[b.schueler_id] = { id: b.schueler_id, vorname: b.vorname, nachname: b.nachname };
  });
  const komps    = Object.values(kompMap);
  const schueler = Object.values(schuelerMap).sort((a,b) => a.nachname.localeCompare(b.nachname));

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
      <td class="name-col">${s.nachname}, ${s.vorname}</td>
      ${zellen}
    </tr>`;
  }).join('');

  el.innerHTML = `<table class="bew-table"><thead>${header}</thead><tbody>${rows}</tbody></table>`;

  // Empfänger-Liste für Rückmeldungen befüllen
  const empfEl = document.getElementById('bew-empfaenger');
  if (empfEl) {
    empfEl.innerHTML = schueler.map(s => `
      <div style="display:flex;align-items:center;gap:8px;padding:5px 0;border-bottom:1px solid var(--border)">
        <input type="checkbox" class="bew-emp-cb" value="${s.id}"
               id="be-${s.id}" style="flex-shrink:0;width:16px;height:16px;cursor:pointer">
        <label for="be-${s.id}" style="flex:1;cursor:pointer;font-size:13px">
          ${s.nachname}, ${s.vorname}
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
          <strong style="font-size:13px">${r.nachname}, ${r.vorname}</strong>
          ${r.bewertung_stufe ? `<span class="bew-chip bew-${r.bewertung_stufe}" style="margin-left:6px">${STUFEN[r.bewertung_stufe]}</span>` : ''}
        </div>
        <label style="display:flex;align-items:center;gap:6px;font-size:12px;cursor:pointer;white-space:nowrap;flex-shrink:0">
          <input type="checkbox" ${r.sichtbar ? 'checked' : ''}
                 onchange="toggleBewRueckSichtbar(${projekt_id}, ${r.schueler_id}, this.checked)">
          sichtbar
        </label>
      </div>
      ${r.freitext ? `<p style="font-size:13px;color:var(--text2);margin:6px 0 0">${r.freitext}</p>` : ''}
      <p style="font-size:11px;color:var(--text3);margin:4px 0 0">
        ${r.lb_vorname} ${r.lb_nachname} · ${(r.geaendert_am || r.erstellt_am || '').substring(0,10)}
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
      Farben: <span style="color:#065f46">grün ≥ 100%</span> ·
      <span style="color:#b45309">gelb ≥ 40%</span> ·
      <span style="color:#b91c1c">rot &lt; 40%</span>.</p>
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
    `Hallo, ${me.vorname} ${me.nachname}!`;
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
            ${w.schuljahr_name ? ' · ' + w.schuljahr_name : ''}
          </div>
          <div class="proj-meta" style="margin-top:2px">
            👤 ${w.lernbegleiter || '–'}
          </div>
          <div class="tags">
            <span class="tag-f">${w.status}</span>
            <span class="tag-k">${w.kompetenzen_anzahl || 0} Kompetenzen</span>
            ${w.abgeschlossen ? '<span class="tag-f" style="background:#d1fae5;color:#065f46">✓ Absolviert</span>' : ''}
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
      ${r.freitext ? `<p style="font-size:13px;margin:0 0 4px">${r.freitext}</p>` : ''}
      <p style="font-size:11px;color:var(--text3);margin:0">
        ${r.lb_vorname} ${r.lb_nachname} · ${(r.geaendert_am || r.erstellt_am || '').substring(0,10)}
      </p>
    </div>`
  ).join('');

  detail.innerHTML = `
    <button class="btn" onclick="schuelerZurueck()" style="margin-bottom:16px">← Zurück</button>
    <h2>${data.name}</h2>
    <p style="font-size:13px;color:var(--text3);margin-bottom:16px">
      ${data.datum_von}${data.datum_bis ? ' – ' + data.datum_bis : ''}
      ${data.schuljahr_name ? ' · ' + data.schuljahr_name : ''}
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
