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

Die Formregeln — Codeschema, Kürzungsgrenze, Sortierung, Behandlung des
Schlusszeichens — werden aus dem Bestand rekonstruiert und gegen ihn geprüft,
nicht neu erfunden. Sie unterscheiden sich zwischen den Fächern, und zwar
selbst innerhalb eines Fachs: Deutsch **GOSt** behält den Schlusspunkt,
Deutsch **Sek I** und Sport entfernen ihn. Die Kürzungsgrenze liegt bei allen
dreien bei 120 Zeichen — geprüft, nicht angenommen. Wo dagegen der Lehrplan
selbst etwas sagt, gilt der Lehrplan, auch gegen den Bestand (E26).
