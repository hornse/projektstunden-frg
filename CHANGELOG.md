# Changelog

Alle wesentlichen Änderungen an diesem Projekt werden hier dokumentiert.
Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.0.0/).

---

## [Unreleased]

### Sicherheit
- **Gespeichertes XSS im Rückmeldungs-Freitext behoben** (E40).
  `werkstatt_rueckmeldungen.freitext` war das einzige Textfeld ohne
  `clean()` beim Schreiben und wurde an zwei Stellen roh in `innerHTML`
  eingesetzt – in der Bewertungsansicht und im **Schülerportal**. Eine
  Lehrkraft mit Schreibrecht auf eine Werkstatt konnte damit Markup in die
  Ansicht eines Minderjährigen schreiben. Maskiert wird jetzt bei der
  Ausgabe, durch `escHtml()`; der Freitext bleibt beim Schreiben
  absichtlich unmaskiert, weil zweimal maskieren aus „Toll & gut" sichtbar
  „Toll &amp; gut" machte.
  **Das schützt auch die vier Zeilen, die vor der Behebung entstanden sind** –
  eine Eingangsprüfung hätte das nicht getan.
- **Rubrik „Maskierung" in `tests-projektstunden.sh`** – drei Prüfungen über
  den Quelltext ohne Kommentare: beide Ausgabestellen maskieren, `escHtml`
  ersetzt alle fünf Zeichen und `&` als erstes, und beim Schreiben wird
  **nicht** zusätzlich maskiert. **59 → 62 Prüfungen.**

### Hinzugefügt
- **Klassen sind nachträglich änderbar** (E38) – der Bearbeiten-Screen bekommt
  ein Klassenfeld, der PUT-Zweig wertet `klasse_ids` aus. Bisher schrieb er
  `projekt_klassen` nie; die Zuordnung stand nach dem Anlegen fest, und damit
  liess sich niemand aus einer neuen Klasse aufnehmen. Fehlendes Feld und leere
  Liste werden unterschieden, wie bei `schueler_ids`.
- **Teilnehmer bleiben sichtbar, wenn ihre Klasse entfernt wird** –
  `GET /api/werkstatt/{id}/schueler` vereinigt jetzt die Schüler der
  zugeordneten Klassen mit den tatsächlichen Teilnehmern. Ohne das verschwand
  ein Teilnehmer aus dem Details-Modal, sobald seine Klasse nicht mehr
  zugeordnet war – seine Zeile blieb, die Stundenanrechnung lief weiter, nur
  bedienen konnte ihn niemand mehr.
- **`projekte.klasse_id` wird nur nachgezogen, wenn der bisherige Wert
  herausfällt** – sonst wechselte die „Hauptklasse" bei jedem Umsortieren.
- **Rubrik „Zugehörigkeit und Konfiguration" in `tests-projektstunden.sh`** –
  drei Prüfungen: Teilnahmeprüfung vor dem Schreiben (Reihenfolge, nicht nur
  Vorkommen), `klasse_ids` im PUT mit `isset`, und dass `config.php` alle Namen
  aus `config.example.php` führt. **62 → 65 Prüfungen.**
- **`sql/18_migration_verwaiste_rueckmeldungen.sql`** (E37) – löscht
  Rückmeldungen ohne Teilnehmerbeitrag über die Bedingung, nicht über feste
  IDs. Nicht additiv; `mysqldump` ist Voraussetzung, nicht Empfehlung.

### Behoben
- **`POST /api/rueckmeldung/{id}` schrieb ungeprüft** (E36). Für jede
  übergebene `schueler_id` entstand eine Rückmeldung, auch wenn die Person
  keine Teilnehmerin der Werkstatt war. Jetzt werden alle IDs zuerst geprüft;
  ist eine ungültig, wird nichts geschrieben, und die Antwort nennt alle
  ungültigen.

### Hinzugefügt (vorheriger Auftrag)
- **Teilnehmer sind nachträglich änderbar** – der Bearbeiten-Screen bekommt
  eine Teilnehmerauswahl, der PUT-Zweig wertet `schueler_ids` aus (E34, E35).
  Bisher schrieb er `projekt_schueler` nie; die Teilnehmerliste stand nach dem
  Anlegen fest. Fehlendes Feld und leere Liste werden unterschieden: ein
  fehlendes `schueler_ids` lässt die Teilnehmer unangetastet.
- **Auswahlhilfe bei der Teilnehmerauswahl** in beiden Ansichten – aus dem
  `select multiple` werden anklickbare Namensfelder, gruppiert nach Klasse,
  mit „Alle hinzufügen", „Auswahl aufheben" und je Klasse einer eigenen
  Schaltfläche. Die Auswahl liegt in einer Menge ausserhalb des DOM (E33).
- **Rückfrage vor dem Entfernen eines Teilnehmers**, die zählt, was
  verlorengeht – Einschätzungen, Rückmeldung, Abschlussvermerk (E34). Gelöscht
  wird ausdrücklich programmiert; auf `projekt_schueler` zeigt kein
  Fremdschlüssel, eine Kaskade gibt es dort nicht.
- **Rubrik „Teilnehmer" in `tests-projektstunden.sh`** – zwei Prüfungen über
  den PUT-Zweig ohne Kommentare: dass er `schueler_ids` auswertet und
  `projekt_schueler` schreibt, und dass er fehlendes Feld von leerer Liste
  unterscheidet. **57 → 59 Prüfungen.**
- **`GET /api/projekte/{id}` liefert `klasse_ids`** und je Teilnehmer
  `klasse`, `abgeschlossen`, `bewertungen` und `rueckmeldungen`. `bewertungen`
  zählt nur Zeilen mit Inhalt – der PUT legt in
  `projekt_schueler_kompetenzen` für jeden Teilnehmer mal jede Kompetenz eine
  leere Zeile an, Zeilenexistenz heisst dort nicht „bewertet".

### Behoben
- **Die Überschrift „Neuen Schüler anlegen" stand neben dem Formular statt
  darüber.** Ursache war `.is-admin .admin-only{display:flex}`: Die Karte
  `#sch-anlegen-card` trägt beide Klassen und wurde dadurch zum
  Flex-Container in Zeilenrichtung. Die Regel bleibt – die
  Navigationsschaltflächen brauchen sie –, die Karte bekommt eine eigene.

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
- **Migration 13** – `teilbereich VARCHAR(80) NULL` und `art VARCHAR(30) NULL`
  auf `kompetenzbereiche` (E18). Rein additiv, zweimal ausführbar.
  `teilbereich` bleibt vorerst leer und kommt mit Englisch.
- **Sport mit Quellennachweis und gefüllter `art`** – `sql/gen/gen_sport_klp.py`
  erzeugt `12_seed_sport_klp.sql` aus
  `docs/curricula/g9_sp_klp_3426_2019_06_23.pdf`. 120 Kompetenzerwartungen in
  54 Bereichen, unverändert; `art` trennt jetzt die 36 Inhaltsfeld- von den
  18 Bewegungsfeld-Bereichen, die zuvor nur an der Namenskonvention
  unterscheidbar waren.
- **Dritte Prüfung in der Rubrik „Fachdaten"** – wo ein Seed die Spalte `art`
  deklariert, führt jede Bereichszeile sie auch gefüllt mit.
- **Migration 14** – Phase `sek1_uebergreifend` im ENUM von
  `kompetenzbereiche.phase`, eingeordnet zwischen `erprobungsstufe` und
  `erste_stufe` (E12/E14). Rein additiv, zweimal ausführbar.
- **Deutsch Sek I mit Quellennachweis** – `sql/gen/gen_deutsch_klp.py` erzeugt
  `10_seed_deutsch_klp.sql` aus `docs/curricula/g9_d_klp_3409_2019_06_23.pdf`.
  226 Kompetenzerwartungen in 28 Bereichen, unverändert. Damit führt **jede**
  Datei mit Fachdaten einen Quellennachweis; der Rückstand aus E21 ist
  erledigt (E29).
- **21 übergeordnete Erwartungen umgehängt** – Phase `zweite_stufe` →
  `sek1_uebergreifend`, Codes `DE_S2_UEB_…` → `DE_S1U_UEB_…` (E12/E14). Der
  Wortlaut aller 21 ist unverändert.
- **Vierte Prüfung in der Rubrik „Fachdaten"** – jede Datei, die in
  `kompetenzen` oder `kompetenzbereiche` schreibt, deklariert eine Quelle
  (E27). Erkannt wird sie am Inhalt, nicht am Dateinamen. Zusammen mit der
  ersten Prüfung schließt sie das Schlupfloch aus E21/E23.
- **Kompetenzbereiche als Baum** (E29b, E31) – `kompetenzbereiche` bekommt
  `parent_id` als Selbstreferenz (Migration 15). Die drei Erzeuger bauen
  zweistufige Bäume: je Phase und Gegenstand ein Wurzelknoten, darunter die
  Kompetenzbereiche als Blätter. Der MKR bleibt flach — sechs Wurzelknoten,
  die zugleich Blätter sind (Migration 16, per `UPDATE`, weil an seinen
  Kompetenzen alle 228 Zuweisungen hängen).
  **Bereiche 118 → 177** (59 neue Zwischenknoten); Kompetenzen unverändert 649,
  Zuweisungen unverändert 228, alle Wortlaute unverändert.
- **`inhaltsfeld`, `kompetenzbereich`, `teilbereich` entfallen**
  (Migration 17) – ihre Information steht im Baum. `phase` bleibt Spalte und
  steht an jedem Knoten; `art` sagt jetzt, was ein Knoten **ist**.
- **Drei Baumprüfungen in `tests-projektstunden.sh`** – Elternknoten im selben
  Rahmen, kein Zyklus, `art` an jedem Knoten. Statisch am Seed, damit
  `deploy.sh` sie ausführt.
- **`docs/curricula/STRUKTUR.md`** – Strukturerhebung über alle 37
  Kernlehrpläne: Aufzählungsmarker mit Codepoint, Spaltigkeit des
  Kompetenzteils, Gliederungstiefe, Steuerzeichen und Zählwerte je Plan.
  21 Pläne gelesen und durch zwei Zählwege gestützt, **16 als unsicher
  gekennzeichnet** mit der jeweils offenen Frage. Grundlage für die
  Entscheidung über das Datenmodell — keine Empfehlung dazu.
  Neu gefunden: vier Markerarten, die in den bisher importierten Fächern nicht
  vorkommen (`U+F0FA`, `U+F0A7`, `U+25CF`, nummerierte Klammern), sowie
  übergeordnete Erwartungen ganz ohne Marker in Tabellenform.

- **Phasen-Tabs beim Anlegen und Bearbeiten einer Werkstatt** – dieselbe
  Bauform wie im Kompetenzkatalog. Ohne Filter zeigte Deutsch 226 Kacheln in
  28 Blöcken; mit „Erprobungsstufe" sind es 82.
- **Ein Auswahlfeld für den Kompetenzkatalog** (E32) – `kat-fach` entfällt,
  `kat-rahmen` gruppiert nach Fach und nennt je Rahmen die Zahl seiner
  Kompetenzen; leere Rahmen sind als leer gekennzeichnet. Zwei unabhängige
  Und-Filter konnten einander widerlegen.
- **Zwei Prüfungen in `tests-projektstunden.sh`** – `KAT_PHASEN` deckt jeden
  ENUM-Wert der Phase ab; `kat-fach` kommt nicht mehr vor.

### Behoben
- **`(fach)sprachlich` → `(fach-)sprachlich`** (2 Einträge) – ein echter
  Bindestrich war beim früheren Lauf der Entsilbentrennung verlorengegangen.
- **Kapitelüberschrift im Eintrag** – `DE_EF_MED_PRO_03` schleppte
  „2.3 Kompetenzerwartungen und inhaltliche Schwerpunkte bis zum Ende der
  Qualifikationsphase" mit.
- **Unvollständige Klammern** – `DE_EF_SPR_REZ_03` fehlte
  „Geschlechterstereotype in der Sprache"; zwei weitere Einträge fehlte ein
  Komma vor „auch unter Verwendung von KI-Werkzeugen".
- **Steuerzeichen aus PDF-Text** (E25) – an einer Stelle des Sport-Plans
  lieferte `pdftotext` `U+0003` statt eines Leerzeichens, und drei von 120
  Aufzählungszeilen begannen mit einem Seitenumbruch. Beides ist unsichtbar;
  gefunden hat es der Wortlautvergleich, nicht das Lesen.
- **`Rollsport/Bootssport/Wintersport` → `Rollsport, Bootssport, Wintersport`**
  (2 Bereichsnamen) – der Bestand wich hier von seiner eigenen Quelle ab (E26).
- **`sek1_uebergreifend` fehlte in `KAT_PHASEN`** – Migration 14 legte den
  siebten ENUM-Wert an, das Frontend kannte ihn nicht, und der Filter ließ
  ihn still wegfallen: 21 Kompetenzerwartungen ohne Tab und über den Filter
  nicht erreichbar. Ein unbekannter Phasenwert wird jetzt gemeldet und ohne
  Farbe angezeigt, statt zu verschwinden.
- **Beim Bearbeiten einer Werkstatt gingen alle gewählten Kompetenzen
  verloren** (E33) – die Vorbelegung suchte `.komp-cb`, gezeichnet wurde
  `.we-komp-cb`; ein Klassenselektor trifft keine Teilzeichenketten. Es wurde
  kein Häkchen gesetzt, und das Speichern schickte eine leere Liste. Die
  Auswahl liegt jetzt in `WS_EDIT_KOMP_IDS` außerhalb des DOM.
- **Silbentrennung: fünfte Regel** (E28) – beginnt die Fortsetzung mit einem
  Großbuchstaben, bleibt der Bindestrich stehen. Sie steht hinter den beiden
  Regeln, die das Dokument befragen. Fing `LautBuchstaben-Ebene` statt
  `Laut-Buchstaben-Ebene`.
- **Ellipsenregel auch innerhalb der Zeile** (E28) – `Satz-und Textebene` statt
  `Satz- und Textebene`; `pdftotext` verschluckt dort den Wortabstand.

**Prüfungen: 48 → 50 → 51 → 52 → 55 → 57.** Die Strukturerhebung brachte keine
neue Prüfung mit — sie ist ein Dokument, kein Code; die Baumumformung bringt
drei.

Geplant:
- `teilbereich` befüllen (Englisch, E18)
- WP Wirtschaft: Lehrplan liegt noch nicht vor (E13)
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
