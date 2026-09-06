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
- **Silbentrennung** nach den vier Regeln aus E22; Fortsetzungszeilen
  werden über die Einrückung erkannt, nie über Satzzeichen.
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

`sql/10_seed_deutsch_klp.sql` nennt im Kopf einen Erzeuger, der es nie ins Repo
geschafft hat. Der Rückstand ist in E21 festgehalten und noch offen.

## Was bei jedem neuen Fach zu prüfen ist

Die beiden bisherigen Fächer haben je eine Falle mitgebracht, die vorher
niemand vermutet hatte. Beide waren unsichtbar und wurden nur durch eine
**Zahl** gefunden, nicht durch Hinsehen:

- **Das Aufzählungszeichen ist nicht überall `•`.** Der Sport-Plan verwendet
  `à` — einen falsch dekodierten Wingdings-Pfeil. `•` steht dort ebenfalls im
  Dokument, nur an anderer Stelle. Vor dem Bauen auszählen, welches Zeichen
  wie oft am Zeilenanfang steht.
- **Steuerzeichen (E25).** `pdftotext` liefert vereinzelt `U+0003` statt eines
  Leerzeichens und setzt Seitenumbrüche `\x0c` mitten vor eine
  Aufzählungszeile. Beides ist im Text unsichtbar. Eine Auszählung der Zeichen
  oberhalb des druckbaren Bereichs gehört in den Bericht jedes Fachimports.
- **Der Wortlautvergleich gegen einen vorhandenen Bestand fängt beides.** Bei
  einem Fach ohne Vorgänger gibt es diesen Vergleich nicht — dort ist die
  Zeichenauszählung die einzige Absicherung.

Die Formregeln — Codeschema, Kürzungsgrenze, Sortierung, Behandlung des
Schlusszeichens — werden aus dem Bestand rekonstruiert und gegen ihn geprüft,
nicht neu erfunden. Sie unterscheiden sich zwischen den Fächern: Deutsch
behält den Schlusspunkt, Sport entfernt ihn. Wo dagegen der Lehrplan selbst
etwas sagt, gilt der Lehrplan, auch gegen den Bestand (E26).
