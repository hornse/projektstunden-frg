# CLAUDE.md – Projektstunden NRW

Diese Datei gibt Claude (und anderen KI-Assistenten) sofortigen Kontext
über das Projekt, die Infrastruktur und alle bekannten Fallstricke.
**Bitte zu Beginn jeder Session lesen.**

---

## Projektkontext

| Was | Wert |
|---|---|
| **App** | Projektstunden NRW – Verwaltung von Projektstunden an NRW-Schulen |
| **Schule** | Friedrich-Rückert-Gymnasium Düsseldorf |
| **Entwickler** | Sebastian Horn (IT-Administrator und Lehrer) |
| **Lokaler Pfad** | `/Users/sebastianhorn/Projekte/projektstunden` |
| **Server** | `hornse@halimede.uberspace.de` |
| **Work-Tree** | `/home/hornse/projektstunden` |
| **Bare Repo** | `/home/hornse/repos/projektstunden.git` |
| **Domain** | `projektstunden.hornse.de` |
| **Port** | `8082` |
| **Datenbank** | `hornse_projektstunden` (MariaDB) |
| **GitHub** | `hornse/projektstunden` (privat) |
| **Deploy** | `./deploy.sh "commit message"` |

---

## Stack

| Schicht | Technologie |
|---|---|
| Frontend | Vanilla JS, HTML, CSS – kein Build-Schritt |
| Backend | PHP 8.1+, kein Framework, eigener Router |
| Datenbank | MariaDB 10.6, PDO |
| Auth | WebUntis JSON-RPC + lokales E-Mail/Passwort |
| Hosting | Uberspace 7, PHP built-in Server, supervisord |

---

## Dateistruktur

```
projektstunden/
├── backend/
│   ├── router.php          ← HTTPS + session_name GANZ OBEN (kritisch!)
│   ├── config.php          ← NICHT in git (.gitignore)
│   ├── config.example.php  ← Vorlage in git
│   ├── auth/
│   │   └── WebUntisAuth.php
│   └── api/
│       └── index.php       ← API-Router + alle Handler
├── frontend/
│   ├── index.html          ← SPA
│   └── app.js              ← Vanilla JS
├── sql/
│   ├── 01_schema.sql
│   ├── 02_seed.sql
│   ├── 03_migration_schuljahr_schueler_werkstatt.sql
│   ├── 04_migration_werkstatt_detail.sql
│   ├── 05_migration_rueckmeldungen.sql
│   ├── 06_migration_webuntis_auth.sql
│   └── 09_seed_sport_konkrete_erwartungen.sql
├── docs/
│   ├── INSTALL.md
│   ├── BENUTZERHANDBUCH.md
│   └── CONFIG.md
├── deploy/
│   └── uberspace.md
├── deploy.sh
├── CHANGELOG.md
├── README.md
├── LICENSE (GPL v3)
└── .gitignore
```

---

## WebUntis-Konfiguration

| Was | Wert |
|---|---|
| `base_url` | `https://frg-dusseldorf.webuntis.com` |
| `school` | `frg-dusseldorf` |
| `client` | `ProjektstundenNRW` |
| `allowed_person_types` | `[2, 16, 5]` |
| `admin_kuerzel` | `['Hor']` |
| personType 2 | Lehrkraft → `lernbegleiter` |
| personType 16 | WebUntis-Admin → `admin`, personId = **-1** |
| personType 5 | Schüler → Schüler-Portal |
| Schüler `key` | = `schild_id` in der DB (aus Schild-NRW) |

---

## Rollen

| Rolle | Rechte |
|---|---|
| `admin` | Alles inkl. Schuljahre, Import, alle Werkstätten |
| `lernbegleiter` | Eigene Werkstätten, Bewertungen, Rückmeldungen |
| `schueler` | Schüler-Portal (nur lesen + Selbsteinschätzung) |

---

## Kritische Regeln (IMMER beachten)

### 1. router.php – zwei Zeilen GANZ OBEN
```php
$_SERVER['HTTPS'] = 'on';
session_name('proj_session');
// DANN erst require bootstrap/config
```
Uberspace terminiert SSL vor PHP. Ohne diese Zeilen:
- Kein `Secure`-Flag → Browser verwirft Cookie auf HTTPS
- Falscher Cookie-Name → Session-Wiederherstellung schlägt fehl

### 2. require_auth() – NIEMALS empty()
```php
// ✗ FALSCH – WebUntis-Lehrer haben benutzer_id=0
if (empty($_SESSION['benutzer_id'])) { /* 401 */ }

// ✓ RICHTIG
if (!isset($_SESSION['benutzer_id']) || $_SESSION['benutzer_id'] === null) { /* 401 */ }
```

### 3. session.save_path – per php.d
```bash
# ~/etc/php.d/sessions.ini
session.save_path = /home/hornse/tmp/sessions
```
`ini_set()` greift bei PHP-FPM zu spät.

### 4. WebUntis-Admin (personType 16) hat personId = -1
Kein Eintrag in `getTeachers()`. Name aus DB per Kürzel nachschlagen.

### 5. WebUntis JSESSIONID-Cookie
Nach `authenticate` den `JSESSIONID`-Cookie aus `Set-Cookie` speichern
und bei `getTeachers()`, `getStudents()`, `logout()` als Header mitschicken.
→ In `WebUntisAuth.php` bereits implementiert (`$this->sessionCookie`).

### 6. getStudents() liefert kein idOfClass
Bei `frg-dusseldorf.webuntis.com` kein `idOfClass`-Feld in `getStudents()`.
`klasseId` kommt nur beim Schüler-Login in `authenticate`-Antwort zurück.

### 7. WebUntis-Lehrer ohne DB-Eintrag haben id=0
```javascript
// ✗ FALSCH – springt zurück zum Login
if (me && me.id) { showApp(); }

// ✓ RICHTIG
if (me && (me.id || me.id === 0)) { showApp(); }
```

---

## Bekannte Bugs und Fixes (bereits behoben)

| Bug | Fix |
|---|---|
| Session geht nach Login verloren | `session_name()` in router.php ganz oben |
| Cookie ohne Secure-Flag | `$_SERVER['HTTPS'] = 'on'` in router.php |
| 401 obwohl Session vorhanden | `empty(0)` → `!isset() || === null` |
| `<!DOCTYPE` statt JSON | 500-Fehler: `supervisorctl tail projektstunden stderr` |
| WebUntis-Admin Name leer | personId=-1 → aus DB per Kürzel nachschlagen |
| Bearbeiten-Seite 500 | `$schuljahr_id` undefined + `klasse_id=0` FK-Violation |

---

## Häufige Debug-Befehle

```bash
# Server-Log
supervisorctl tail projektstunden stderr | tail -20

# Session prüfen
cat ~/tmp/sessions/sess_SESSIONID

# API direkt testen
curl -s https://projektstunden.hornse.de/api/auth/me \
  -H "Cookie: proj_session=SESSIONID"

# DB-Status
mysql hornse_projektstunden -e "SHOW TABLES;"
```

---

## Aktueller Stand (v0.7.0 – Juli 2026)

**Fertig:**
- Werkstätten (anlegen, bearbeiten, Details, Status, Abschluss)
- Bewertungen (4-stufige Fremdeinschätzung, Kompetenz × Schüler)
- Rückmeldungen (persistent, Sichtbarkeit steuerbar)
- Dashboard (Stundenkontingent Soll/Ist, Kompetenzen)
- WebUntis-Auth (Lehrer + Admin + Schüler)
- Schüler-Portal (lesen + Selbsteinschätzung)
- Hilfe-Seite (Schnellstart, FAQ, Handbuch)
- CSV-Import aus Schild-NRW

**Noch offen:**
- Schulanpassung (Logo, Schulname) – Priorität 4
- WebUntis-Schüler-Sync (Bulk-Import via API) – zurückgestellt
