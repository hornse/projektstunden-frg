# Erzeuger für die Fachdaten

Hier liegen die Skripte, die aus den Kernlehrplan-PDFs unter
`docs/curricula/` die Seed-Dateien in `sql/` erzeugen.

**Die erzeugten Seeds werden nicht von Hand geändert.** Eine Korrektur
gehört in den Erzeuger; die Datei wird daraus neu geschrieben. So bleibt
nachvollziehbar, wie die Daten in die Datenbank kamen (E19).

## Voraussetzung

`pdftotext` aus poppler:

```bash
brew install poppler
```

Ein anderer Extraktor ist **kein** Ersatz. Die Sollzahlen in den Erzeugern
wurden gegen `pdftotext -layout` ermittelt; ein anderes Werkzeug bricht die
Zeilen anders um, und die Erkennung der Fortsetzungszeilen hängt genau an
diesen Umbrüchen.

## Aufruf

Aus der Projektwurzel:

```bash
python3 sql/gen/gen_deutsch_sii.py
```

Das Skript prüft zuerst die SHA256-Summe des Quell-PDFs. Stimmt sie nicht,
bricht es ab — dann ist es eine andere Fassung als die, aus der die
Sollzahlen stammen.

Danach zählt es die erzeugten Einträge je Gliederungseinheit gegen die im
Skript hinterlegten Sollzahlen. **Weicht eine einzige Einheit ab, wird
nichts geschrieben** und der Lauf endet mit Exit-Code 1. Ein leerer oder
halber Seed entsteht so gar nicht erst.

Bei Erfolg gibt das Skript aus, welche Silbentrennungen es nach Regel 4
entschieden hat (E22) — also ohne Beleg im Dokument. Diese Liste gehört in
den Bericht des jeweiligen Auftrags und wird durchgesehen.

## Wie ein Erzeuger den Baum aufbaut

Seit E29b bilden `kompetenzbereiche` einen Baum über `parent_id`. Das Muster
ist bei allen drei Erzeugern dasselbe und die Vorlage für die sechzehn
ausstehenden Fächer:

**Zwei INSERT-Anweisungen, nicht eine.** Die Wurzelknoten werden mit
`parent_id = NULL` als `VALUES`-Liste eingefügt; die Blätter folgen mit einem
`INSERT … SELECT`, das `parent_id` über den **Code** des Elternknotens
auflöst:

```sql
INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art) VALUES
(@rahmen, NULL, 'DE_EP_SPR', 'Erprobungsstufe · Sprache', 4, 'erprobungsstufe', 'inhaltsfeld'), …;

INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art)
SELECT @rahmen, p.id, t.code, t.name, t.reihenfolge, t.phase, t.art
FROM (
  SELECT 'DE_EP_SPR_REZ' AS code, … , 'DE_EP_SPR' AS pcode
  UNION ALL …
) t JOIN kompetenzbereiche p ON p.rahmen_id = @rahmen AND p.code = t.pcode;
```

`INSERT … SELECT` aus derselben Tabelle ist in MariaDB erlaubt (geprüft, nicht
angenommen) — anders als `UPDATE` oder `DELETE` mit Selbstbezug.

**Der Blattcode bleibt der alte.** An ihm hängen die Kompetenzcodes
(`DE_EP_SPR_REZ_01`). Der Wurzelcode ist der gemeinsame Präfix.

**`art` steht an jedem Knoten** und sagt, was der Knoten ist — nicht mehr, was
in einer Spalte steht: `inhaltsfeld`, `bewegungsfeld`, `kompetenzbereich`,
`medienkompetenzbereich` (E31).

**`phase` bleibt eine Spalte** und steht an jedem Knoten, auch am Blatt. Sie
liegt quer zur Schachtelung, und das Frontend filtert über sie.

**Kompetenzen hängen nur an Blättern.** Ein Knoten mit Kindern trägt keine.
Das ist eine Festlegung für den Aufbau, keine Beobachtung über alle 37 Pläne —
verletzt ein Fach sie, schlägt die Prüfung an, und dann wird entschieden.

### Die Prüflücke beim MKR

Die drei Baumprüfungen in `tests-projektstunden.sh` laufen **statisch am
Seed**, damit `deploy.sh` sie ausführen kann. Der Medienkompetenzrahmen hat
keinen Seed: Er stammt aus einer eigenen Vorlage, ist flach und wird per
`UPDATE` behandelt (`sql/16_migration_mkr_baum.sql`).

**Er liegt damit außerhalb dieser drei Prüfungen.** Für ihn gilt die
Baumintegrität nur gegen die Datenbank, nicht beim Deploy. Wer den MKR
anfasst, prüft von Hand:

```sql
SELECT COUNT(*) AS knoten, SUM(parent_id IS NULL) AS wurzeln,
       SUM(art IS NULL) AS ohne_art
FROM kompetenzbereiche kb JOIN kompetenzrahmen kr ON kr.id = kb.rahmen_id
WHERE kr.kuerzel = 'MKR';
-- Erwartet: 6 / 6 / 0
```

Die Lücke schließt sich, sobald der MKR einen Seed bekommt — dafür fehlt eine
Quelldatei (E19/E20).

## Was ein Erzeuger einhält

- **Kopf der erzeugten Datei** nennt Quelle, SHA256 und Erzeuger (E19).
- **Silbentrennung** nach den fünf Regeln aus E22 und E28; Fortsetzungszeilen
  werden über die Einrückung erkannt, nie über Satzzeichen. Die fünfte Regel
  (Großbuchstabe = echter Bindestrich) steht **hinter** den beiden, die das
  Dokument befragen: wo ein Beleg vorliegt, gilt der Beleg.
- **Steuerzeichen** nach E25 — C0 wird zu Leerzeichen, **C1 bleibt**.
- **Das `DELETE` bleibt auf den eigenen Rahmen beschränkt.** Ein Seed
  beschreibt einen Sollzustand und baut nur seinen eigenen Rahmen neu auf.
- **Der Seed läuft in einer Transaktion.** Bricht er ab, bleibt der alte
  Stand stehen.
- **Zweimal einspielen liefert dasselbe Ergebnis.**
- **Codeschema und Kurznamen-Kürzung** werden aus dem Bestand übernommen,
  nicht neu erfunden — sonst wechseln bei jedem Lauf Codes, an denen
  Zuweisungen hängen könnten.

## Bestand

| Erzeuger | Seed | Quelle |
|---|---|---|
| `gen_deutsch_sii.py` | `sql/11_seed_deutsch_sii.sql` | `gost_klp_d_2026_08_24.pdf` |
| `gen_sport_klp.py` | `sql/12_seed_sport_klp.sql` | `g9_sp_klp_3426_2019_06_23.pdf` |
| `gen_deutsch_klp.py` | `sql/10_seed_deutsch_klp.sql` | `g9_d_klp_3409_2019_06_23.pdf` |
| `gen_englisch_klp.py` | `sql/19_seed_englisch_klp.sql` | `g9_e_klp_3417_2019_06_23.pdf` |

Damit führt **jede** Datei mit Fachdaten einen Quellennachweis; der Rückstand
aus E21 ist erledigt. Das Testskript prüft beides: dass eine Quelle deklariert
ist (E27) und dass sie stimmt (E21).

## Was bei jedem neuen Fach zu prüfen ist

Jedes der drei bisherigen Fächer hat eine eigene Falle mitgebracht, die vorher
niemand vermutet hatte. Alle waren unsichtbar und wurden durch eine **Zahl**
oder einen **Vergleich** gefunden, nie durch Hinsehen:

- **Das Aufzählungszeichen ist nicht überall `•`.** Deutsch GOSt verwendet `•`,
  Sport `à` — einen falsch dekodierten Wingdings-Pfeil, wobei `•` dort
  ebenfalls im Dokument steht, nur an anderer Stelle. Vor dem Bauen auszählen,
  welches Zeichen wie oft am Zeilenanfang steht.
- **Ein Plan kann zwei Marker führen.** Deutsch Sek I verwendet `\x83` für die
  42 übergeordneten und `à` für die 184 konkretisierten Erwartungen. Dann prüft
  der Erzeuger die **Aufteilung je Marker**, nicht nur die Summe (E28) — sonst
  bliebe eine falsch erkannte Gliederung unbemerkt, weil die Gesamtzahl
  weiterhin stimmt.
- **`\x83` ist ein C1-Steuerzeichen (U+0083).** Die Bereinigung nach E25 gilt
  ausdrücklich nur für **C0**. Wer den Ausdruck „vorsichtshalber" auf C1
  ausweitet, löscht bei Deutsch Sek I 42 von 226 Erwartungen spurlos.
- **Steuerzeichen (E25).** `pdftotext` liefert vereinzelt `U+0003` statt eines
  Leerzeichens und setzt Seitenumbrüche `\x0c` mitten vor eine
  Aufzählungszeile. Beides ist im Text unsichtbar. Eine Auszählung der Zeichen
  oberhalb des druckbaren Bereichs gehört in den Bericht jedes Fachimports.
- **Verschluckte Wortabstände.** An einer Stelle des Deutsch-Sek-I-Plans steht
  `Satz-und` ohne jedes Zeichen dazwischen — der Abstand ist im PDF zu eng
  gesetzt, `pdftotext` lässt ihn weg. Dagegen hilft die Ellipsenregel
  **innerhalb** der Zeile (E28).
- **Der Wortlautvergleich gegen einen vorhandenen Bestand fängt alles davon.**
  Bei einem Fach ohne Vorgänger gibt es diesen Vergleich nicht — dort sind die
  Zeichenauszählung und die Aufteilung je Marker die einzige Absicherung.
- **Zweispaltiger Satz** (E47). Die sechs Sprachpläne setzen den Kompetenzteil
  zweispaltig: links die Erwartungen, rechts die fachlichen Konkretisierungen.
  `pdftotext -layout` zieht beide in dieselbe Textzeile, und weil der linke
  Block im Blocksatz steht, beginnt die rechte Spalte je nach Zeile bei
  Zeichen 41, 45 oder 51 — eine feste Schnittstelle im Textbild gibt es nicht.
  Ein Seitenzuschnitt über `-x/-y/-W/-H` scheitert daran, dass auf derselben
  Seite ein- und zweispaltige Blöcke stehen.

  Der Weg geht über `pdftotext -bbox-layout`: Zeilen aus den Wörtern über die
  Grundlinie neu bilden, Blöcke aus Markerzeile plus Fortsetzungen bilden,
  **die Spaltenfrage am Block entscheiden** und innerhalb zweispaltiger Blöcke
  am ersten Wort ab der Spaltengrenze trennen. Die Rinne ist zu messen, nicht
  zu übernehmen — bei Englisch liegt sie zwischen 293 und 300 pt.
- **Zwei Marker für dieselbe Sache, unangekündigt.** Englisch führt 170 `à`
  und 7 `•`; letztere nur in einem einzigen Abschnitt. Wer nur `à` kennt,
  bekommt 170 und eine Summe, die stimmig aussieht. Die Aufteilung je Marker
  gehört deshalb in die Sollzahlen (E28).
- **Überschriften haben in einem Plan mehrere Formen.** Bei Englisch drei:
  Kapitälchen, kurze Zeile mit Doppelpunkt, kurze Zeile ohne. Wer über die
  Form entscheidet, verliert eine davon; wer über ein Verzeichnis der
  erwarteten Namen entscheidet, bekommt beim Fehlen einen Abbruch statt einer
  stillen Fehlzuordnung.
- **Kapitälchen kommen zerlegt an** (E47): `I NTERKULTURELLE KOMMUNIKATIVE
  K OMPETENZ`. Zwei Ersetzungen bauen sie zurück.

Die Formregeln — Codeschema, Kürzungsgrenze, Sortierung, Behandlung des
Schlusszeichens — werden aus dem Bestand rekonstruiert und gegen ihn geprüft,
nicht neu erfunden. Sie unterscheiden sich zwischen den Fächern, und zwar
selbst innerhalb eines Fachs: Deutsch **GOSt** behält den Schlusspunkt,
Deutsch **Sek I** und Sport entfernen ihn. Die Kürzungsgrenze liegt bei allen
dreien bei 120 Zeichen — geprüft, nicht angenommen. Wo dagegen der Lehrplan
selbst etwas sagt, gilt der Lehrplan, auch gegen den Bestand (E26).
