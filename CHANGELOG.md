# Changelog

Alle wesentlichen Änderungen an diesem Projekt werden hier dokumentiert.
Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.0.0/).

---

## [Unreleased]

Geplant:
- WebUntis-Authentifizierung für Lehrer und Schüler
- Schüler-Lesezugriff auf eigene Werkstätten und Rückmeldungen
- Schulanpassung (Logo, Schulname) – eigener Admin-Bereich
- Selbsteinschätzung durch Schüler (4-stufige Skala)

---

## [0.6.0] – 2026-07-07

### Hinzugefügt
- **Bewertungen-Screen** – eigener Nav-Eintrag; Werkstatt wählen →
  Bewertungstabelle (Schüler × Kompetenzen, Chips 1–4 farbig) mit
  horizontalem Scroll und fixierten Schülernamen; Rückmeldungsbereich
  darunter mit Empfänger-Auswahl (einzeln/alle/Teilmenge)
- **Rückmeldungen persistent** – neue Tabelle `werkstatt_rueckmeldungen`;
  Bewertungsstufe (optional) + Freitext je Schüler; Sichtbarkeit für
  Schüler steuerbar; UPSERT-Logik (eine Rückmeldung pro Schüler+Werkstatt)
- **Bewertungsskala API** – `GET/PUT /api/bewertung`, `GET/POST/PUT /api/rueckmeldung`
- **Kompetenzrahmen-Fix** – beim Anlegen/Bearbeiten initial nur MKR-Tabs;
  KLP-Tabs erscheinen erst nach Eingabe von Stunden beim zugehörigen Fach
- **Max-Teilnehmer-Prüfung** – Frontend und Backend prüfen ob Schüleranzahl
  das gesetzte Limit überschreitet
- **Migration 05** – Tabelle `werkstatt_rueckmeldungen`

### Behoben
- Modal-Teilnehmerliste: Checkbox links, Name rechts, kein horizontaler Scroll
- Status-Speichern im Modal funktioniert jetzt über eigenen schlanken
  Endpunkt `PUT /api/werkstatt/{id}/status`
- Bearbeiten-Seite: `WS_EDIT_ID` wird zusätzlich im DOM gespeichert –
  kein 500-Fehler mehr nach Deploy/Reload
- PUT 500-Fehler: `$schuljahr_id` undefined und Foreign-Key-Violation
  auf `klasse_id=0` behoben

---

## [0.5.0] – 2026-07-07

### Hinzugefügt
- **Werkstätten-Seite umstrukturiert** – Liste oben mit Schuljahr-Filter
  und „Details"-Button pro Card; „+ Neue Werkstatt" klappt Formular auf
- **Bearbeiten als eigene Seite** – vollständiges Formular vorausgefüllt,
  gleiche UX wie beim Anlegen; erreichbar über „✏️ Bearbeiten" im Modal
- **Detail-Modal verschlankt** – nur noch Status, Teilnehmer abhaken,
  Schließen/Löschen/Bearbeiten; Schülerliste mit max. 300px Scroll
- **Nav-Eintrag** umbenannt: „Werkstatt eintragen" → „Werkstätten"

### Behoben
- Modal `position:fixed` – Modal erscheint jetzt zuverlässig beim Klick
- Dashboard: Stunden und Kompetenzen nur für abgeschlossene Werkstätten
  (`status='abgeschlossen'` oder Schüler individuell `abgeschlossen=1`)

---

## [0.4.0] – 2026-07-05

### Hinzugefügt
- **Werkstatt-Detailansicht** – klickbare Cards öffnen Modal mit Status,
  Teilnehmer als „absolviert" markieren (einzeln oder alle), Löschen
- **Multi-Klassen-Auswahl** – Klassen-Dropdown wird zu Multi-Select;
  Schülerliste zeigt alle Schüler aus gewählten Klassen mit Klassenangabe
- **Abschluss je Schüler** – neues Feld `abgeschlossen` in `projekt_schueler`;
  individuell oder alle auf einmal markierbar
- **Migration 04** – `abgeschlossen`-Flag, neue Tabelle `projekt_klassen`
- **API** – `GET /api/werkstatt/{id}/schueler`,
  `PUT /api/werkstatt/{id}/abschluss`, `PUT /api/werkstatt/{id}/status`
- **Schüler-Suche über mehrere Klassen** – `?klassen=1,2,3`

---

## [0.3.0] – 2026-06-26 (Werkstätten-Feature)

### Hinzugefügt
- **Werkstätten – erweitertes Formular** – Umbenennung Projekt → Werkstatt;
  Schuljahr, Laufzeit (Halbjahr/Ganzjährig), Max-Teilnehmer, Präsentationsdatum
- **Multi-Select Lernbegleiter** – erster Eintrag = Leitung, weitere = Begleitung;
  Tabelle `projekt_lehrer` mit Rolle
- **Zugangskontrolle** – Lernbegleiter sehen nur eigene Werkstätten;
  Bearbeiten nur durch Leitungsperson; Admins sehen alles
- **PUT /api/projekte/{id}** – Werkstatt bearbeiten inkl. Stunden-Update
- **deploy.sh** – Deploy-Script mit Cache-Busting und interaktiver
  Commit-Nachricht
- **deploy/uberspace.md** – vollständige Serverdokumentation

### Behoben
- supervisord Interface `100.64.47.2` → `0.0.0.0:8082`
- post-receive Hook: `GIT_DIR` explizit gesetzt

---

## [0.2.0] – 2026-04-27

### Hinzugefügt
- **CSV-Import aus Schild-NRW** – Vorschau, Import, Inaktivierung fehlender
  Schüler, Import-Log mit Statistik
- **Schuljahrverwaltung** – anlegen, aktivieren, abschließen, löschen
- **Schüler-Schuljahr-Verlauf** – Tabelle `schueler_schuljahr`
- **GET /api/import/log** – letzte 20 Importe abrufbar

### Geändert
- Klassen werden beim Import automatisch angelegt
- Klassenlehrer-Name aus CSV in `klassen.klassenlehrer_name`

---

## [0.1.0] – 2026-04-03

### Hinzugefügt
- **Grundstruktur** – Werkstätten anlegen mit Name, Klasse, Datum,
  Beschreibung, Status, Lehrer; Schüler zuordnen; Stunden je Fach;
  Kompetenzen je Schüler
- **Kompetenzrahmen** – KLPs und MKR; aufklappbare Erwartungen
- **Dashboard** – Stundenkontingent Soll/Ist je Schüler und Fach
- **Export** – CSV für Stunden und Kompetenzen (Excel-kompatibel)
- **Benutzerverwaltung** – Admin: anlegen, bearbeiten, deaktivieren
- **Migration 03** – Schuljahre, Import, Werkstatt-Erweiterungen,
  Bewertungsstufen, `projekt_lehrer`

---

## [0.0.1] – 2026-03-30

### Hinzugefügt
- **Login/Auth** mit Rollenverwaltung (`admin`/`lernbegleiter`)
- **Session-Sicherheit** – HttpOnly, SameSite, session_regenerate_id
- **Schüler verwalten** – anlegen, Soft-Delete, Filter nach Klasse
- **Klassen verwalten** – anlegen, deaktivieren (nur Admin)
- **Fächer** – Stunden-Soll je Jahrgang
- **Kompetenzrahmen und Kompetenzen** – lesend
- **API-Router** – PHP built-in server, Routing über PATH_INFO
- **Audit-Log** – alle schreibenden Operationen protokolliert
- **Single Page App** – Vanilla JS, Navigation über `go()`
