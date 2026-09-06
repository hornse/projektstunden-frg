# Changelog

Alle wesentlichen Änderungen an diesem Projekt werden hier dokumentiert.
Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.0.0/).

---

## [Unreleased]

### Hinzugefügt
- **Deutsch GOSt aus der verabschiedeten Fassung** – `DEU_KLP_SII` wird
  nicht mehr aus dem Entwurf vom 31.07.2025 aufgebaut, sondern aus
  `docs/curricula/gost_klp_d_2026_08_24.pdf`. 197 Kompetenzerwartungen in
  30 Bereichen, Zahlen unverändert; geändert hat sich der Wortlaut in
  **11 Einträgen** – 6 inhaltliche Änderungen der neuen Fassung,
  5 Extraktionsfehler des alten Bestands.
- **`sql/gen/gen_deutsch_sii.py`** – Erzeuger, der die Seed-Datei aus dem
  PDF schreibt (E19). Prüft die SHA256 der Quelle und die Zählwerte je
  Gliederungseinheit; weicht eine ab, wird nichts geschrieben.
- **`sql/gen/README.md`** – Ablage und Regeln für alle künftigen
  Fachimporte.
- **Rubrik „Fachdaten" in `tests-projektstunden.sh`** – zwei Prüfungen:
  Quellenangabe samt Prüfsumme, und Existenz eines genannten Erzeugers
  (E19/E21/E23).

### Behoben
- **`(fach)sprachlich` → `(fach-)sprachlich`** (2 Einträge) – ein echter
  Bindestrich war beim früheren Lauf der Entsilbentrennung verlorengegangen.
- **Kapitelüberschrift im Eintrag** – `DE_EF_MED_PRO_03` schleppte
  „2.3 Kompetenzerwartungen und inhaltliche Schwerpunkte bis zum Ende der
  Qualifikationsphase" mit.
- **Unvollständige Klammern** – `DE_EF_SPR_REZ_03` fehlte
  „Geschlechterstereotype in der Sprache"; zwei weitere Einträge fehlte ein
  Komma vor „auch unter Verwendung von KI-Werkzeugen".

**Prüfungen: 48 → 50.**

Geplant:
- Prüfungszahl in der Ausgabe von `tests-projektstunden.sh` (E24)
- Quelle und Erzeuger für `10_seed_deutsch_klp.sql` und
  `12_seed_sport_klp.sql` nachziehen (E21)
- Schulanpassung (Logo, Schulname) – eigener Admin-Bereich
- Schüler-Sync direkt aus WebUntis (ohne CSV-Import)

---

## [0.7.0] – 2026-07-08

### Hinzugefügt
- **WebUntis-Authentifizierung** – Lehrer und Schüler können sich
  zusätzlich per WebUntis-Kürzel/Passwort anmelden; E-Mail/Passwort
  bleibt erhalten
- **Kein manuelles Kürzel-Mapping** – Lehrer werden on-the-fly
  authentifiziert; Schüler über `key` (WebUntis) = `schild_id` (Schild-NRW)
- **Rollen aus WebUntis** – personType 16 (WebUntis-Admin) → `admin`;
  personType 2 (Lehrkraft) → `lernbegleiter`; `admin_kuerzel` in Config
  für zusätzliche Admins
- **Schüler-Portal** – eigene Ansicht nach Schüler-Login: Werkstätten,
  Kompetenzen mit Lehrereinschätzung, Selbsteinschätzung (1–4),
  sichtbare Rückmeldungen
- **Selbsteinschätzung** – Schüler können pro Kompetenz ihre eigene
  Einschätzung setzen (1–4 Chips)
- **`backend/auth/WebUntisAuth.php`** – eigenständiges Auth-Modul
  mit Session-Cookie-Handling, Brute-Force-Schutz, getTeachers/getStudents
- **Migration 06** – `webuntis_login_log`-Tabelle für Brute-Force-Schutz
- **Hilfe-Seite** – drei Tabs in der App: Schnellstart, FAQ, Handbuch

### Behoben
- **Session-Cookie `Secure`-Flag** – PHP built-in Server hinter
  Uberspace SSL-Proxy setzte keinen Secure-Flag;
  Fix: `$_SERVER['HTTPS'] = 'on'` und `session_name()` in `router.php`
  ganz oben (vor jedem require)
- **`empty(0)` Bug** – `benutzer_id=0` (WebUntis-Lehrer ohne DB-Eintrag)
  wurde von `empty()` als "nicht eingeloggt" behandelt;
  Fix: `!isset() || === null` in `require_auth()`
- **WebUntis-Admin `personId=-1`** – Admins tauchen nicht in
  `getTeachers()` auf; Name wird aus lokaler DB nachgeschlagen
- **Session-Pfad** – `session.save_path` per `~/etc/php.d/sessions.ini`
  global gesetzt statt per `ini_set` (greift zu spät)

---

## [0.6.0] – 2026-07-07

### Hinzugefügt
- **Bewertungen-Screen** – eigener Nav-Eintrag; Werkstatt wählen →
  Bewertungstabelle (Schüler × Kompetenzen, Chips 1–4 farbig)
- **Rückmeldungen persistent** – Tabelle `werkstatt_rueckmeldungen`;
  Bewertungsstufe + Freitext; Sichtbarkeit steuerbar
- **Kompetenzrahmen-Fix** – initial nur MKR; KLP-Tabs nach Fachauswahl
- **Max-Teilnehmer-Prüfung** – Frontend und Backend
- **Migration 05** – `werkstatt_rueckmeldungen`

### Behoben
- Modal-Teilnehmerliste: sauberes Layout
- Status-Speichern: eigener Endpunkt `PUT /api/werkstatt/{id}/status`
- Bearbeiten-Seite: ID im DOM gespeichert – kein 500 nach Reload
- PUT 500-Fehler: `$schuljahr_id` und `klasse_id=0`

---

## [0.5.0] – 2026-07-07

### Hinzugefügt
- **Werkstätten-Seite umstrukturiert** – Liste oben, Formular aufklappbar
- **Bearbeiten als eigene Seite** – vollständiges Formular vorausgefüllt
- **Detail-Modal verschlankt** – Status, Teilnehmer, Bearbeiten, Löschen

### Behoben
- Modal `position:fixed` – erscheint zuverlässig
- Dashboard: nur abgeschlossene Werkstätten anrechnen

---

## [0.4.0] – 2026-07-05

### Hinzugefügt
- **Werkstatt-Detailansicht** – Modal mit Status, Abschluss-Markierung
- **Multi-Klassen-Auswahl** – jahrgangsübergreifende Werkstätten
- **Abschluss je Schüler** – `abgeschlossen`-Flag in `projekt_schueler`
- **Migration 04** – `abgeschlossen`-Flag, `projekt_klassen`

---

## [0.3.0] – 2026-06-26

### Hinzugefügt
- **Werkstätten-Formular** – Schuljahr, Laufzeit, Max-Teilnehmer,
  Präsentationsdatum, Multi-Select Lernbegleiter, Zugangskontrolle
- **deploy.sh** – Cache-Busting, interaktive Commit-Nachricht
- **deploy/uberspace.md** – Serverdokumentation

### Behoben
- supervisord Interface `100.64.47.2` → `0.0.0.0:8082`
- post-receive Hook: `GIT_DIR` explizit gesetzt

---

## [0.2.0] – 2026-04-27

### Hinzugefügt
- CSV-Import aus Schild-NRW
- Schuljahrverwaltung

---

## [0.1.0] – 2026-04-03

### Hinzugefügt
- Grundstruktur Werkstätten, Kompetenzrahmen, Dashboard, Export

---

## [0.0.1] – 2026-03-30

### Hinzugefügt
- Login/Auth, Schüler/Klassen, API-Router, Audit-Log, Single Page App
