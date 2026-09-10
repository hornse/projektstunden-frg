# Auftrag: Rohfarben aus `app.js`, Prüfung auf `frontend/` ausweiten

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

Zwei Teile, und der zweite ist der wichtigere.

**Teil 1 — Die Phasenpalette verlässt `app.js`.** `KAT_PHASEN` führt sieben
Hexwerte (Zeilen 1575–1581), die Farben der Schulphasen im Kompetenzkatalog.
Dazu zweimal `var(--warn,#f59e0b)` (2174, 2220): Der Rückfall ist tot, weil
`--warn` definiert ist — und er wäre falsch, wenn er je zöge; `#f59e0b`
erreicht auf Weiß einen Kontrast von 2.15.

REIHENREGELN 7 verlangt Farbwerte in `ci-tokens.css` oder als Kategorienpalette
im `:root`-Block des Projekts, mit Kommentar. Eine Palette, die nur dieses
Projekt braucht, ist der ausdrücklich vorgesehene Fall.

**Teil 2 — Die Rohfarbenprüfung liest nur `frontend/style.css`.** Deshalb hat
sie die sieben Werte nie gesehen. Sie wird auf `frontend/` insgesamt
ausgeweitet.

**Ohne Teil 2 ist Teil 1 folgenlos.** Die Palette wandert, und die nächste
Rohfarbe in `app.js` bleibt wieder unsichtbar. Der Befund wurde in dieser Reihe
zweimal gemeldet — beim Kompetenzauswahl-Auftrag mit sechs Farben und jetzt mit
sieben.

## Schritt 0 — Voraussetzungen prüfen

```bash
./tests-projektstunden.sh; echo "Exit: $?"
git status --short
```

Erwartet: 73/73 grün, sauberer Arbeitsbaum.

**Den Bestand messen, bevor entschieden wird**, wie weit Teil 2 reicht:

```bash
grep -rnoE '#[0-9a-fA-F]{3,8}\b|rgba?\([^)]*\)' frontend/ --include='*.js' --include='*.html' | wc -l
grep -rnoE '#[0-9a-fA-F]{3,8}\b|rgba?\([^)]*\)' frontend/ --include='*.js' --include='*.html' | head -40
```

Wie viele Rohfarben außerhalb von `style.css` es gibt, weiß ich nicht. Sieben
plus zwei sind belegt; ob es dabei bleibt, entscheidet den Zuschnitt.

## Schritt 1 — Ausgangsstand

```bash
./tests-projektstunden.sh
```
Prüfungszahl notieren (erwartet 73).

Die gemessene Zahl der Rohfarben je Datei festhalten. Sie ist der Sollwert,
gegen den Teil 2 anschlägt.

## Schritt 2 — Zuschnitt, dann anhalten

**Erstens: Wohin gehört die Palette?**

Vorgegeben ist der `:root`-Block des Projekts, mit Kommentar — nicht
`ci-tokens.css`, das vendored ist und nach REIHENREGELN 6 nur in der Quelle
geändert wird. Zu klären ist die Form: sieben eigene Variablen
(`--phase-erprobungsstufe` und so fort), oder eine andere Ordnung. Vorschlag mit
Begründung.

Dabei zu bedenken: `KAT_PHASEN` führt neben der Farbe auch Schlüssel und
Beschriftung, und die Reihenfolge der Liste bestimmt die Reihenfolge der Tabs.
Nur die Farbe wandert; die Liste bleibt, wo sie ist.

**Zweitens: Wie weit reicht die Prüfung?**

Sie soll `frontend/` lesen statt einer Datei. Offen ist, was als Ausnahme
zulässig bleibt:

- Vendorte Stilvorlagen — sie führen Farben, und sie gehören nicht diesem
  Projekt. Ausschließen oder mitprüfen?
- Rückfälle in `var(--x, #wert)` — sie sind Rohfarben und zugleich ein
  Zweitwert, den jemand bewusst genannt hat. Nach E58 zählt der Rückfall bereits
  als Verwendung; ob er auch als Rohfarbe zählt, ist neu zu entscheiden.
- Ein Vermerk am Ort, wie ihn E43 für die Maskierung eingeführt hat, oder keine
  Ausnahme.

**Drittens: Was ist mit den zwei toten Rückfällen?** `var(--warn,#f59e0b)` —
entfernen, weil `--warn` definiert ist und der Rückfall nie zieht, oder stehen
lassen? Wenn entfernen: Gilt das für alle Rückfälle im Bestand, oder nur für
die, deren Variable definiert ist?

Vorlegen und **anhalten**.

## Schritt 3 — Umsetzung

Erst nach Freigabe.

**Was dabei nicht kaputtgehen darf:** Die Phasenfarben erscheinen als
Hintergrund der Etiketten im Kompetenzkatalog. Wandert die Farbe in eine
Variable, muss die Stelle, die sie setzt, sie auch lesen können — heute steht
sie als Zeichenkette in einem `style`-Attribut.

E58 hat gezeigt, dass `app.js:1336` mit
`querySelector('span[style*="--ok"]')` nach einem Namen im Attribut sucht.
Prüfen, ob eine solche Stelle auch für die Phasenfarben existiert, bevor die
Schreibweise geändert wird.

**Nicht dazu gehört:** `ci-tokens.css` ändern, die Farbwerte selbst ändern, die
Importpalette anfassen.

## Schritt 4 — Tests

Die bestehende Rohfarbenprüfung wird ausgeweitet, nicht verdoppelt. Ob die Zahl
dadurch steigt, hängt vom Zuschnitt ab — die tatsächliche nennen.

Gegenproben:

- Eine Rohfarbe in `app.js` einfügen → rot, mit Fundstelle.
- Eine Rohfarbe in `index.html` einfügen → rot.
- Entwertung: die Prüfung findet keine Datei mehr → rot mit „Voraussetzung
  fehlt", nicht grün.
- Nach E58, beidseitig: eine Rohfarbe nur im Kommentar → grün. Eine echte
  Rohfarbe neben einem Kommentar, der eine Ausnahme zu begründen scheint → rot.

**Von Hand zu prüfen und zu belegen:** Der Kompetenzkatalog mit einem Rahmen,
der mehrere Phasen führt — Deutsch Sek I hat vier. Alle Tabs und Etiketten
müssen dieselben Farben zeigen wie vorher. Gemessen mit
`getComputedStyle()`, nicht angesehen; die Werte vorher und nachher gehören in
den Bericht.

`sek1_uebergreifend` trägt `#5eead4` und ist der zuletzt hinzugekommene — die
Stelle, an der ein Übertragungsfehler am ehesten unbemerkt bliebe.

## Schritt 5 — Dokumentation

- `CHANGELOG.md`: Prüfungszahl vorher und nachher.
- `docs/ENTSCHEIDUNGEN.md`: die Entscheidungen aus Schritt 2. Insbesondere, was
  als Ausnahme zulässig bleibt — das ist die Auskunft, die beim nächsten
  Farbwert gebraucht wird.
- Der Kommentar an der Palette im `:root`-Block hält fest, warum sie dort steht
  und nicht in `ci-tokens.css`. REIHENREGELN 7 verlangt das ausdrücklich.

## Schritt 6 — Ausliefern

```bash
./tests-projektstunden.sh
./deploy.sh "refactor(css): Phasenpalette in den :root-Block, Rohfarbenprüfung auf frontend/"
```

Kein SQL. Nach dem Deploy die Handprüfung.

Bei Rot: anhalten, nicht ausliefern.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

Zusätzlich: die Zahl der Rohfarben je Datei vorher und nachher, die gemessenen
Farbwerte der Phasenetiketten vorher und nachher, und was die ausgeweitete
Prüfung beim ersten Lauf gemeldet hat.

## Ein Befund für `koordination`, der hier nur zu melden ist

Dieser Auftrag behebt zum zweiten Mal denselben Befund: Eine Prüfung liest eine
bestimmte Datei und prüft deshalb diese Datei, nicht die Regel. Beim ersten Mal
waren es sechs Farben, jetzt sieben — dieselbe Stelle, dazwischen eine
Erweiterung, die niemandem auffiel.

Ob daraus für die Reihe etwas folgt — etwa dass eine Prüfung ihren
Geltungsbereich selbst nennt, statt ihn im Ausdruck zu verstecken —, ist dort zu
entscheiden. Hier nur zu melden.

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung.
- Bei Unklarheit nachfragen statt vermuten.
