# Changelog

Alle wesentlichen Änderungen an diesem Projekt werden hier dokumentiert.
Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.0.0/).

---

## [Unreleased]

### Entfernt
- **Sieben tote CSS-Regeln** (`.imp-row`, `.imp-row:last-child`, `.imp-icon`,
  `.imp-neu`, `.imp-upd`, `.imp-ok`, `.imp-err`) aus einer früheren Fassung der
  Import-Vorschau, die heute mit `.stat` und `.sec` arbeitet (E61). Keine der
  Klassen wurde gesetzt – in `app.js`, `index.html` und im Backend gesucht,
  auch auf zusammengesetzte Namen.
- **Die Tokens `--imp-upd` und `--imp-err`**, deren letzte Verwendung diese
  Regeln waren. `--imp-neu` bleibt: `.pok`, `.dok` und der Hilfetext lesen es.
- **`setProperty('--accent-dark', …)`** in `applyEinstellungen` – die Variable
  wurde bei jeder Einstellungsänderung geschrieben und im ganzen `frontend/`
  nirgends gelesen. Im Browser belegt: Farbe ändern und zurücksetzen verhält
  sich unverändert, nur eine Variable weniger steht am `:root`.

### Geändert
- **Das Stundenkontingent kennt zwei Zustände statt drei** (E60): Soll erreicht
  = grün, darunter neutral. Vorher färbte der Balken bei **≥ 100 % rot** und
  unter 40 % orange – Rot heißt in dieser Anwendung „Fehler", und
  Übererfüllung ist keiner. Die 40-Prozent-Grenze entfällt ersatzlos: Das Soll
  ist ein Jahreswert, und dieselbe Zahl bedeutet im November etwas anderes als
  im Juni.
- **Die Prozentzahl wird nicht mehr gedeckelt.** `Math.min(100, …)` machte aus
  150 % eine 100, während daneben „3 / 2 Std." stand. Jetzt steht dort 150 %.
  Der **Balken** bleibt gedeckelt, sonst schiebt er sich aus seinem Rahmen.
  Im Browser gemessen: `3 / 2 Std.` zeigt vorher `100%`/rot, nachher
  `150%`/grün bei unveränderter Balkenbreite (624 px von 624 px).
- **Der Hilfetext beschreibt jetzt, was geschieht**, statt dessen, was einmal
  gedacht war.
- **Vier tote CSS-Regeln entfernt** – `.dwarn`, `.dover`, `.pwarn`, `.pover`
  werden nirgends mehr gesetzt (E55). Vorher geprüft, ob die Tokens dahinter
  noch gebraucht werden.
- **Zwei Prüfungen dazu** – die Prozentzahl darf nicht gedeckelt sein und die
  Balkenbreite muss es, geprüft über die Namen `pct` und `breite` statt über
  Textnähe; und keine der vier alten Klassen darf noch vorkommen.
  **73 → 75 Prüfungen.**

### Geändert (vorheriger Vorgang)
- **Die Phasenpalette des Kompetenzkatalogs steht jetzt im `:root`-Block**
  (E59). Sieben Hexwerte lagen in `app.js`, wo die Rohfarbenprüfung sie nie
  gesehen hat. Je Phase zwei Variablen: `--phase-<x>` für Punkt und Kante,
  `--phase-<x>-bg` für die Fläche des Etiketts – letztere entstand bisher durch
  Anhängen von `33` an den Hexwert, was mit einer Variablen **still**
  fehlgeschlagen wäre (`var(--x)33` ist keine gültige Angabe).
- **Die Namen stehen ausgeschrieben in `KAT_PHASEN`**, nicht aus dem Schlüssel
  zusammengesetzt: So sieht die Variablenprüfung aus E58 sie. Belegt – ein
  Vertipper bei `sek1_uebergreifend` macht den Lauf rot.
- **Vier Werte, die vorhandene Tokens wortgleich wiederholten**, nennen jetzt
  `var(--bew-1/2/3)` und `var(--bew-3-bg)`. Im Browser gemessen: unverändert.
- **Die zwei toten Rückfälle `var(--warn,#f59e0b)` sind entfallen.** Ein
  Rückfall mit Rohfarbe ist künftig verboten – ist die Variable definiert, ist
  er totes Gewicht mit einem ungeprüften Wert (2.15 Kontrast); fehlt sie,
  verdeckt er genau den Fehler, den E58 sichtbar machen soll.
- **Die Rohfarbenprüfung liest `frontend/` statt `frontend/style.css`** –
  ohne `vendor/`, mit der `:root`-Ausnahme und mit einem Vermerk
  `rohfarbe-erlaubt: <Grund>` auf der Zeile (Form aus E43). Die grüne Zeile
  nennt geprüfte Dateien und begründete Ausnahmen. **Prüfungszahl bleibt 73** –
  es kommt keine Prüfung hinzu, die vorhandenen lesen mehr. Der Beleg ist der
  erste Lauf: **72/73 mit 19 Fundstellen**.

### Behoben
- **Neun Stellen im Frontend nannten CSS-Variablen, die es nicht gibt** (E58):
  `var(--err)` fünfmal, `var(--ok)` viermal. Eine undefinierte Variable bricht
  nichts – der Text erbt seine Farbe. Betroffen waren die Fehlerausgaben der
  Import-Vorschau: „n Fehler", die Überschrift und jede einzelne Fehlerzeile
  standen in gewöhnlichem Schwarz. Im Browser gemessen: vorher
  `rgb(28,39,51)`, nachher `rgb(168,50,45)` für Fehler und `rgb(30,125,62)`
  für „neu".
- **`--err` entfällt, `--ok` wird definiert.** Für Rot gibt es `--danger`; ein
  zweiter Name dafür wäre eine zweite Wahrheit. Für Grün gab es gar nichts –
  `--ok:var(--ci-erfolg)` steht jetzt neben `--danger`. **Nicht** die
  Importpalette: `--imp-neu` erreicht als Text auf der weißen Karte nur 4.19,
  `--ci-erfolg` 5.17.
- **Prüfung „CSS-Variablen"** – jede in `frontend/` verwendete Variable muss
  definiert sein, in `style.css`, in den vendorten Stilvorlagen oder inline.
  Zielt ausdrücklich nicht auf `--err`. Kommentare werden auf beiden Seiten
  entfernt, ein Modifikatorname (`.ci-knopf--gefahr:hover`) gilt nicht als
  Definition und ein Rückfall (`var(--warn,#f59e0b)`) auch nicht.
  **72 → 73 Prüfungen.**

### Behoben (vorheriger Vorgang)
- **Die Schuljahr-Auswahl beim CSV-Import war wirkungslos** (E56, E57). Das
  Frontend hängte `schuljahr_id` an ein `FormData`; der Handler las `$body`,
  das aus `php://input` stammt – und das ist bei `multipart/form-data` **leer**.
  Die Oberfläche hat die Fähigkeit dabei ausdrücklich zugesagt: „Du kannst auch
  ein zukünftiges Schuljahr wählen." Wer sie nutzte, bekam eine Erfolgsmeldung
  und einen Import ins aktive Jahr.
- **Anzeige statt Auswahl.** Die Importseite zeigt jetzt an, in welches Jahr
  importiert wird; der Handler ermittelt es ohne Vorbedingung und nimmt die
  Angabe nicht mehr entgegen. Ohne aktives Jahr steht dort der Satz, den auch
  das Backend ausgibt – das Dateifeld bleibt bedienbar, damit nicht zwei
  Stellen dieselbe Bedingung entscheiden.
- **Der Fehler kehrt nirgends wieder** – gesucht, nicht vermutet: `new FormData`
  kommt im Frontend zweimal vor (beide im Import), `$_FILES` im Backend an
  denselben zwei Stellen, und **`$_POST` hat im gesamten Backend null
  Vorkommen**. Der Logo-Upload geht als Base64 in einem JSON-Rumpf.
- **Rubrik „Import und aktives Schuljahr"** – zwei Prüfungen: `handle_import`
  darf `schuljahr_id` **gar nicht** aus dem Rumpf lesen und muss das aktive
  Jahr ermitteln; im Frontend darf kein Auswahlfeld zurückkehren, und die
  Anzeige muss da sein. **70 → 72 Prüfungen.**
- **Ein roter Testlauf wiederholt jetzt auch die Detailzeilen** unter einer
  gefallenen Prüfung. Bisher stand am Ende nur „✗ …"; welche Zeile gemeint
  war, stand allein im Protokoll – und ein `tail -3` verlor sie.
- **Der Hinweis „Kein aktives Schuljahr gefunden" war schwarz statt rot.**
  Er stand auf `var(--err)` – ein Token dieses Namens gibt es nicht, das
  Projekt führt `--danger`. In Chrome nachgesehen, dann berichtigt. **Fünf
  weitere Stellen in der Import-Vorschau tragen denselben Tippfehler**
  (`app.js` 1985, 2173, 2218, 2251, 2256) – gemeldet, nicht in diesem
  Commit mitbehoben.
- **`.komp-cb{display:none}` in `style.css` entfernt** (E55) – tote Regel;
  die Kästchen sind bereits über `.komp-pill input[type=checkbox]` verborgen.
  Vorher in Chrome belegt: mit und ohne die Regel `display=none, breite=0px`.

### Behoben (vorheriger Vorgang)
- **`import_log.dateiname` wurde roh ausgegeben.** Der Name der hochgeladenen
  Datei geht ungefiltert aus `$_FILES` in die Datenbank und stand von dort
  roh im Import-Protokoll – dieselbe Bauform wie E42, nur **über die
  Datenbank und damit dauerhaft**. Maskiert wird jetzt bei der Ausgabe (E40),
  nicht beim Schreiben; das schützt auch die drei vorhandenen Zeilen.
- **Die Feldliste der Prüfung „Roh gespeicherte Felder bei der Ausgabe"**
  (vormals „Namen bei der Ausgabe") führt jetzt auch `dateiname`. Die
  Prüfungszahl bleibt bei **70** – es ist dieselbe Regel und derselbe
  Mechanismus, erweitert wurde die Liste, nicht die Zahl.

### Behoben (vorheriger Vorgang)
- **Die Fehlerliste der Import-Vorschau zeigte „12: [object Object]"** (E44).
  Das Frontend las ein Feld `meldung`; das Backend liefert `zeile`, `grund`
  und `daten`. Jetzt steht dort „Zeile 4: Pflichtfelder fehlen (ID, Name,
  Klasse oder Jahrgang) – Max Mustermann".
- **`daten` und `grund` laufen durch `escHtml`.** `daten` ist Inhalt der
  hochgeladenen Datei; die naheliegende Behebung — nur den Feldnamen
  richtigstellen — hätte den Zustand wiederhergestellt, den E41 und E42
  beseitigt haben.
- **Prüfung „Fehlerliste der Import-Vorschau"** – misst feldweise: jedes
  Vorkommen von `f.daten` und `f.grund` muss in `escHtml` liegen, und
  `f.meldung` darf nicht zurückkehren. Fängt auch den Umweg über eine
  Zwischenvariable. **69 → 70 Prüfungen.**

### Behoben (vorheriger Vorgang)
- **Kästchen erbten `width:100%` von der Eingabefeld-Regel** und wurden zu
  Balken. In der Rückmeldungsansicht war „Sofort für Schüler sichtbar"
  **348 statt 16 Pixel breit** (in Chrome gemessen) und schob seine
  Beschriftung an den Kartenrand, wo sie umbrach. Eine Regel
  `input[type=checkbox],input[type=radio]{width:16px;height:16px;padding:0;flex-shrink:0;cursor:pointer}`
  steht jetzt direkt unter der Regel, die sie berichtigt.
- **Zwei Einzelangaben in `app.js` sind entfallen** – im Details-Modal und in
  der Empfängerliste stand `width:16px;height:16px` im `style`-Attribut, um
  denselben Fehler von Hand auszugleichen. Beide rendern unverändert 16px.
- **Prüfung „Kaestchen"** – die Regel muss es geben, sie darf **nicht** selbst
  `width:100%` setzen, und kein Kästchen im ganzen `frontend/` darf eine
  eigene Breite tragen. **68 → 69 Prüfungen.**

### Behoben (vorheriger Vorgang)
- **Das Details-Modal listete alle Schüler aller zugeordneten Klassen** (E39,
  E53). Bei Werkstatt 4 waren das 189 Namen für 12 Teilnehmer, insgesamt
  **323 Namen für 23 Teilnehmer**. Nicht-Teilnehmer sahen aus wie Teilnehmer
  ohne Abschlussvermerk. `GET /api/werkstatt/{id}/schueler` liefert jetzt die
  Teilnehmer.
- **Ein Haken bei einem Nicht-Teilnehmer meldete Erfolg und tat nichts.**
  `PUT /api/werkstatt/{id}/abschluss` war ein reines `UPDATE` ohne `INSERT`.
  Jetzt wird die Teilnahme vorher geprüft und mit Nennung der ID abgewiesen –
  **nicht** über `rowCount()`, das „kein Teilnehmer" und „Wert unverändert"
  nicht unterscheidet.
- **Die Bewertungstabelle zeigte keinen Teilnehmer ohne zugewiesene
  Kompetenz.** Ihre Zeilen kamen aus `projekt_schueler_kompetenzen`; wer dort
  fehlte, war nicht bewertbar und bekam keine Rückmeldung. Zeilen kommen jetzt
  aus `projekt_schueler`, Spalten weiterhin aus den zugewiesenen Kompetenzen.
- **Die Empfängerliste für Rückmeldungen behielt die Namen der zuvor
  gewählten Werkstatt**, wenn die neue keine Kompetenzzeilen hatte. Sie wird
  jetzt in jedem Fall gesetzt, auch auf leer.
- **Zwei verschiedene Hinweise** statt einem: „keine Teilnehmer" und „keine
  Kompetenzen zugewiesen". Werkstatt 5 bekam bisher den falschen.

### Hinzugefügt
- **`tests-projektstunden.sh` hält seinen Lauf selbst fest.** Der vollständige
  Lauf steht in `logs/pruefung-letzter.txt`, dessen Pfad die letzte Zeile
  nennt; ein **roter** Lauf wird zusätzlich unter
  `logs/pruefung-rot-<Zeitstempel>.txt` abgelegt und von keinem späteren Lauf
  überschrieben. Bei Rot stehen die gefallenen Prüfungen noch einmal am Ende,
  damit ein `tail -5` sie zeigt. Anlass: Ein roter Lauf ging durch `tail -3`,
  die rote Zeile lag oberhalb des Fensters, und 28 grüne Läufe später war
  nicht mehr feststellbar, welche Prüfung gefallen war.
- **Rubrik „Wer gehoert zur Werkstatt" in `tests-projektstunden.sh`** – zwei
  Prüfungen: `PUT /abschluss` prüft die Teilnahme **vor** dem Schreiben
  (Reihenfolge gemessen, nicht Vorkommen), und die Bewertungstabelle nimmt
  ihre Zeilen aus den Teilnehmern (tragend: `schuelerMap` ist verschwunden).
  **66 → 68 Prüfungen.**
- **Englisch Sek I** (E46, E49) – `ENG_KLP` aus
  `docs/curricula/g9_e_klp_3417_2019_06_23.pdf`: **177 Kompetenzerwartungen an
  48 Blättern, 57 Knoten** (EP 53, S1 67, S2 57). Der Rahmen existierte bisher
  gar nicht; der Seed legt ihn an.
- **`sql/gen/gen_englisch_klp.py`** – erster Erzeuger mit **Spaltentrennung
  über Koordinaten** (E47) und **drei Gliederungsebenen** (E46). Der Plan ist
  zweispaltig gesetzt und führt zwei Aufzählungsmarker mit derselben
  Bedeutung: 170× `à`, 7× `•`.
- **`sql/19_seed_englisch_klp.sql`** – drei INSERTs auf `kompetenzbereiche`
  statt der bisherigen zwei, weil der Baum hier drei Ebenen tief wird.
- **E22 bekommt eine sechste Trennregel** (E45, E48): Ist die linke Hälfte im
  Dokument als linke Hälfte eines ungetrennt belegten Bindestrich-Kompositums
  mit **kleingeschriebener** rechter Hälfte belegt, bleibt der Bindestrich.
  Sie greift bei Englisch zweimal (`kritisch-reflektiert`,
  `kritisch-distanzierend`); die drei vorhandenen Seeds bleiben byteweise
  unverändert.

Prüfungszahl unverändert **66** – der Seed fällt unter die bestehenden
Fachdatenprüfungen, die jetzt vier statt drei Erzeuger und fünf statt vier
Dateien mit Fachdaten sehen.

### Sicherheit
- **Namen werden bei der Ausgabe maskiert** (E41, E43). `schueler.vorname`,
  `nachname`, `klassen.bezeichnung` und `klassen.schuljahr` stehen roh in der
  Datenbank – Import und WebUntis-Selbstanlage schreiben ohne `clean()` – und
  wurden roh in `innerHTML` eingesetzt. 46 Einbettungen laufen jetzt durch
  `escHtml` (46 auf 24 Zeilen).
- **Zuerst die Import-Vorschau** (E42): Sie zeigte Namen direkt aus der
  hochgeladenen Datei, ohne Umweg über die Datenbank. Wer eine Datei hochlud,
  sah ihren Inhalt sofort als lebendes Markup – vor jedem Import.
- **`clean()` verlässt `POST /schueler` und `POST /klassen`**, damit beide
  Felder eine Konvention haben. Ohne das zeigte die Ausgabemaskierung für von
  Hand angelegte Personen `O&#039;Brien`. Keine Datenmigration nötig: 0 von 299
  Namen und 0 von 12 Klassenbezeichnungen enthalten ein betroffenes Zeichen –
  vor und nach dem Umbau belegt.
- **42 Einbettungen bleiben bewusst roh** und tragen den Grund an Ort und
  Stelle: `${/* keine-maskierung: … */ …}`. Sie stammen aus `benutzer` und
  `schuljahre`, wo beim Schreiben maskiert wird, oder ihre Senke ist gar kein
  HTML.
- **Prüfung „Namen bei der Ausgabe"** – lehnt ab, was sie nicht kennt: Jede
  Einbettung eines Namensträgers muss maskiert oder begründet sein. Eine neu
  hinzugefügte rohe Stelle fällt durch, ohne dass die Prüfung angefasst wird.
  Ihre drei Lücken stehen im Kopfkommentar. **65 → 66 Prüfungen.**

### Sicherheit (vorheriger Auftrag)
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
