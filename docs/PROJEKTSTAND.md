# Projektstunden NRW – Projektstand

## Server & Infrastruktur
- **URL:** https://projektstunden.hornse.de
- **Server:** Uberspace (hornse@hornse.de), PHP Built-in Server Port 8082
- **Datenbank:** MariaDB, Datenbank: hornse_projektstunden
- **Supervisor:** `supervisorctl restart projektstunden`
- **Deploy:** `git push uberspace main` → Hook deployt automatisch

## Git-Workflow
- **Lokal:** `~/projekte/projektstunden` (IntelliJ)
- **GitHub:** https://github.com/hornse/projektstunden-frg (privat)
- **Remote uberspace:** `hornse@hornse.de:~/repos/projektstunden.git`
- **Deploy-Befehl:** `git push github main && git push uberspace main`

## Projektstruktur
```
projektstunden/
├── frontend/
│   ├── index.html      # HTML-Gerüst (kein JS!)
│   └── app.js          # Gesamtes JavaScript (ausgelagert wegen 63KB-Proxy-Limit)
├── backend/
│   ├── api/index.php   # PHP-Backend, alle API-Endpunkte
│   ├── router.php      # PHP Built-in Server Router
│   └── config.php      # DB-Zugangsdaten (nicht im Git)
└── sql/
    ├── 01_schema.sql
    ├── 02_seed.sql
    └── 03_migration_schuljahr_schueler_werkstatt.sql
```

## Wichtige Technische Hinweise
- **JS muss in app.js bleiben** – Uberspace-Proxy begrenzt HTML auf ~63KB
- **router.php** liest Frontend aus `~/projektstunden/frontend/`
- **app.js** muss in `frontend/` liegen damit router.php sie findet
- **Cloudflare:** NICHT aktiv – Domain läuft über 1blu Nameserver
- **Deploy:** Niemals HTML/JS direkt über Browser herunterladen

## Datenbankstruktur (aktuell)
Tabellen: schulen, benutzer, faecher, klassen, schueler, projekte,
projekt_schueler, projekt_stunden, projekt_schueler_kompetenzen,
kompetenzrahmen, kompetenzbereiche, kompetenzen, audit_log,
fach_lehrer_klasse, klassenleitung,
**NEU (Migration 03):** schuljahre, schueler_schuljahr, import_log,
projekt_lehrer, bewertungsstufen

## Fach-Kürzel in DB
DE, EN, L2, MA, BI, CH, PH, IF, GE, EK, WP, KU, MU, RE, SP, FRA, LAT, SPA

## API-Endpunkte (aktuell)
- GET/POST `/api/auth/login|logout|me`
- GET/POST/PUT/DELETE `/api/benutzer`
- GET/POST `/api/klassen`
- GET/POST/DELETE `/api/schueler`
- GET/POST `/api/projekte`
- GET `/api/faecher|lehrer|dashboard|kompetenzrahmen|kompetenzen`
- GET `/api/export/stunden|kompetenzen`
- **NEU:** GET/POST/PUT/DELETE `/api/schuljahre`
- **NEU:** POST `/api/schuljahre/{id}/aktivieren`
- **NEU:** POST `/api/import/vorschau`
- **NEU:** POST `/api/import/ausfuehren`

## Was funktioniert
- ✅ Login/Logout
- ✅ Benutzerverwaltung (Admin)
- ✅ Klassen verwalten
- ✅ Schüler verwalten (manuell)
- ✅ Projekte eintragen mit Stunden und Kompetenzen
- ✅ Kompetenzkatalog (alle 21 KLPs + MKR eingespielt)
- ✅ Dashboard mit Stundenkontingent
- ✅ Export CSV
- ✅ Schuljahrverwaltung (Frontend + Backend fertig, noch nicht getestet)
- ✅ CSV-Import aus Schild-NRW (Backend fertig, noch nicht getestet)

## Was noch fehlt
- ⬜ Schuljahr anlegen und testen
- ⬜ CSV-Import testen mit echter Schild-Datei
- ⬜ Werkstätten (erweitertes Projekt-Formular):
  - Mehrere Lernbegleiter pro Projekt
  - Schuljahr-Zuordnung
  - Laufzeit (Halbjahr/Jahr)
  - Präsentationsdatum
  - Max. Teilnehmerzahl
  - Status (geplant/aktiv/abgeschlossen/abgesagt)
  - Schüler optional (Projekt ohne Schüler möglich)
- ⬜ Bewertungsskala (4-stufig: mit Unterstützung/teilweise/weitgehend/sicher)
- ⬜ Selbst- und Fremdeinschätzung von Kompetenzen
- ⬜ Schülerlogin (aufgeschoben)

## Pädagogisches Konzept
Orientiert an Werkstattidee der Gesamtschule Am Schießberg Siegen:
- Werkstätten = Projekte mit min. Halbjahr Laufzeit
- Jahrgangs- und fächerübergreifend, mehrere Lernbegleiter
- 4 Kompetenzbereiche: fachlich, methodisch, sozial, persönlich
- Präsentationstag am Ende jedes Halbjahres
- Bewertungsskala 1-4 (mit Unterstützung → sicher und reflektiert)
- Selbst- und Fremdeinschätzung (Selbsteinschätzung zunächst für Lehrer nicht sichtbar)

## Admin-Zugangsdaten (für Tests)
In config.php auf dem Server – nicht im Git.
