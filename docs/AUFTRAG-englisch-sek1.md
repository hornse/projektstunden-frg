# Auftrag: Englisch Sekundarstufe I importieren

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

Der Kompetenzrahmen `ENG_KLP` wird neu aufgebaut aus
`docs/curricula/g9_e_klp_3417_2019_06_23.pdf`. Der vorhandene Bestand stammt
aus der in E8 verworfenen Vorgängerlieferung (231 Bereiche mit je einer
Kompetenz) und wird ersetzt.

Zu bauen sind ein Erzeuger `sql/gen/gen_englisch_klp.py` und ein Seed
`sql/19_seed_englisch_klp.sql` — Nummer nachsehen, nicht übernehmen.

**Dieser Import ist in drei Punkten der erste seiner Art:**

Er trägt eine **dritte Gliederungsebene**. Unter „Verfügen über sprachliche
Mittel" liegen Wortschatz, Grammatik, Aussprache und Intonation, Orthografie.
Der Baum aus E29b bekommt damit zum ersten Mal eine Tiefe, die das vorherige
Spaltenmodell nicht hätte abbilden können.

Der Plan ist **zweispaltig** gesetzt. Links stehen die Kompetenzerwartungen,
rechts die fachlichen Konkretisierungen. `pdftotext -layout` verschränkt beide
zeilenweise.

Er führt **zwei Aufzählungsmarker mit derselben Bedeutung**, und zwar
unangekündigt.

## Schritt 0 — Voraussetzungen prüfen

```bash
./tests-projektstunden.sh; echo "Exit: $?"
git status --short
shasum -a 256 docs/curricula/g9_e_klp_3417_2019_06_23.pdf
which pdftotext
ls -1 sql/ | tail -5
ls -1 sql/gen/
```

Erwartet: 66/66 grün, sauberer Arbeitsbaum, `pdftotext` vorhanden, Prüfsumme
`96a12dca0a6b7d81d75367d1c870aa48013db9bae84671d7add9e7bb55329ead`.

Prüfen, ob Kompetenzen aus `ENG_KLP` zugewiesen sind — der Seed löscht den
Rahmen:

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SELECT COUNT(*) FROM projekt_schueler_kompetenzen psk
JOIN kompetenzen k ON k.id = psk.kompetenz_id
JOIN kompetenzbereiche kb ON kb.id = k.bereich_id
JOIN kompetenzrahmen kr ON kr.id = kb.rahmen_id
WHERE kr.kuerzel = \"ENG_KLP\";'"
```

Erwartet: 0. Ist die Zahl größer, **anhalten** — dann nimmt der Seed
Bewertungen mit.

`docs/curricula/STRUKTUR.md` zum Abschnitt Englisch lesen. Was dort steht, gilt;
weicht dieser Auftrag davon ab, ist das ein Widerspruch und gehört gemeldet.

## Schritt 1 — Ausgangsstand

```bash
./tests-projektstunden.sh
```
Prüfungszahl notieren (erwartet 66).

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SELECT COUNT(*) AS knoten FROM kompetenzbereiche;
SELECT COUNT(*) AS kompetenzen FROM kompetenzen;
SELECT kr.kuerzel, COUNT(DISTINCT kb.id) AS knoten, COUNT(k.id) AS kompetenzen
FROM kompetenzrahmen kr
LEFT JOIN kompetenzbereiche kb ON kb.rahmen_id = kr.id
LEFT JOIN kompetenzen k ON k.bereich_id = kb.id
GROUP BY kr.id HAVING kompetenzen > 0 ORDER BY kr.kuerzel;'"
```

## Schritt 2 — Spaltentrennung, dann anhalten

**Das ist der Kern des Auftrags.** Alles andere folgt bekannten Mustern.

Der Plan setzt zwei Spalten. `pdftotext -layout` gibt sie zeilenweise
verschränkt aus — eine Fortsetzungszeile des linken Eintrags und eine Zeile der
rechten Spalte stehen nebeneinander in derselben Textzeile:

    •   unter Einsatz von Texterschlie-          adaptierte sowie authentische Texte, Le-
        ßungsverfahren authentische Tex-         setexte, Hör-/Hörsehtexte, mehrfach ko-

Die Regel „Fortsetzung an der Einrückung erkennen", die bei Deutsch und Sport
getragen hat, bricht hier: Sie zöge `adaptierte sowie authentische Texte` in
die Kompetenzerwartung.

Zu entwerfen ist ein Verfahren, das die linke Spalte gewinnt. Mögliche Wege,
nicht abschließend:

- `pdftotext -x -y -W -H` beschränkt die Extraktion auf einen Bereich. Dann ist
  zu klären, ob die Spaltengrenze über den ganzen Plan konstant liegt — bei
  einseitigen Abschnitten wie den einleitenden Kapiteln gibt es sie gar nicht.
- Spaltenposition je Zeile aus der Einrückung ableiten und ab einer Grenze
  abschneiden.
- Ein Werkzeug mit Spaltenerkennung. Dann gilt REIHENREGELN 3: erst prüfen, ob
  es auf dem Zielrechner vorhanden ist. Und: Die Sollzahlen unten wurden mit
  `pdftotext -layout` ermittelt; ein anderer Extraktor liefert andere Umbrüche
  und damit andere Silbentrennungsentscheidungen.

**Erproben an drei Stellen**, bevor irgendetwas erzeugt wird:

1. Erprobungsstufe, Hör-/Hörsehverstehen — 3 Erwartungen, einspaltiger Anfang.
2. Zweite Stufe, Text- und Medienkompetenz ab Zeile 1477 — 7 Erwartungen, die
   verschränkte Stelle von oben.
3. Verfügen über sprachliche Mittel, Grammatik, Erste Stufe — 9 Erwartungen,
   die tiefste Schachtelung.

Vorlegen und **anhalten**. Ich entscheide, bevor 177 Einträge erzeugt werden.

## Schritt 3 — Umsetzung

Erst nach Freigabe.

**Zwei Marker mit derselben Bedeutung.** `à` trägt 170 Erwartungen, `•` sieben
— letztere ausschließlich im Abschnitt Text- und Medienkompetenz der Zweiten
Stufe. Beide sind Kompetenzerwartungen. Ein Erzeuger, der nur `à` kennt, liefert
170 statt 177, und die Summe sähe stimmig aus.

Nach E28 prüft der Erzeuger die **Aufteilung je Marker**, nicht nur die Summe:
53 / 67 / 57 je Phase, davon in der Zweiten Stufe 50 mit `à` und 7 mit `•`.

**`−` leitet die fachlichen Konkretisierungen ein**, 89-mal. Sie stehen in der
rechten Spalte und sind keine Kompetenzerwartungen.

**Silbentrennung nach E22 und E28**, einschließlich der fünften Regel.
Steuerzeichen nach E25 — die C0-Zeichen entfernen, C1 **nicht**: Ob dieser Plan
ein C1-Zeichen tragend verwendet, ist zu prüfen, nicht anzunehmen.

**Baumaufbau nach E29b und E31.** Die Tiefe schwankt innerhalb des Plans: Unter
der Funktionalen kommunikativen Kompetenz liegen sieben Teilbereiche, unter
einem davon vier Unterbereiche; die vier übrigen Kompetenzbereiche tragen ihre
Erwartungen direkt. Kompetenzen hängen nur an Blättern (E31) — das ist hier zum
ersten Mal eine Zusicherung, die etwas kostet.

`art` je Knoten. Welche Werte Englisch braucht, ergibt sich aus der Gliederung
und gehört in den Bericht; `inhaltsfeld` kommt hier nicht vor.

Kopf nach E19, Quellenangabe und Prüfsumme wie bei den drei vorigen Fächern.

**Codes:** Es gibt keinen Bestand, an dem man sich ausrichten könnte — der alte
ist verworfen. Das Schema ist zu entwerfen, nach dem Muster von Deutsch
(`DE_EP_UEB_REZ_01`), und im Bericht zu begründen. Es ist die einzige
Festlegung dieses Auftrags, die sich später nur mit Aufwand ändern lässt.

## Schritt 4 — Tests

**Sollzahlen** aus `g9_e_klp_3417_2019_06_23.pdf`, ermittelt mit
`pdftotext -layout` und Zählung beider Marker je Abschnitt. Unabhängig vom
Erzeuger gewonnen — weicht er ab, ist zuerst zu klären, welche Zählung falsch
ist.

| Kompetenzbereich | Teilbereich | Unterbereich | EP | 1. St | 2. St |
|---|---|---|---|---|---|
| Funktionale kommunikative Kompetenz | Hör-/Hörsehverstehen | — | 3 | 4 | 3 |
| Funktionale kommunikative Kompetenz | Leseverstehen | — | 2 | 3 | 3 |
| Funktionale kommunikative Kompetenz | Sprechen: an Gesprächen teilnehmen | — | 3 | 4 | 4 |
| Funktionale kommunikative Kompetenz | Sprechen: zusammenhängendes Sprechen | — | 4 | 4 | 3 |
| Funktionale kommunikative Kompetenz | Schreiben | — | 3 | 3 | 4 |
| Funktionale kommunikative Kompetenz | Sprachmittlung | — | 3 | 3 | 3 |
| Funktionale kommunikative Kompetenz | Verfügen über sprachliche Mittel | Wortschatz | 3 | 4 | 2 |
| Funktionale kommunikative Kompetenz | Verfügen über sprachliche Mittel | Grammatik | 7 | 9 | 5 |
| Funktionale kommunikative Kompetenz | Verfügen über sprachliche Mittel | Aussprache und Intonation | 3 | 4 | 4 |
| Funktionale kommunikative Kompetenz | Verfügen über sprachliche Mittel | Orthografie | 3 | 4 | 2 |
| Interkulturelle kommunikative Kompetenz | — | — | 6 | 7 | 7 |
| Text- und Medienkompetenz | — | — | 4 | 6 | **7 ¹** |
| Sprachlernkompetenz | — | — | 5 | 6 | 5 |
| Sprachbewusstheit | — | — | 4 | 6 | 5 |

¹ Die einzigen sieben Erwartungen des Plans mit `•` statt `à`.

Summen: Erprobungsstufe 53, Erste Stufe 67, Zweite Stufe 57 — zusammen **177**.
Blätter: 14 / 14 / 14 = 42.

**Es gibt keinen Wortlautvergleich.** Bei den drei vorigen Fächern hat er
Fehler gefunden — fünf, zwei, null —, weil ein geprüfter Bestand danebenlag.
Hier gibt es keinen; der alte ist verworfen. Was ihn ersetzt:

- Die Zählung je Gliederungseinheit, aus einem anderen Verfahren als der
  Erzeuger.
- Die Aufteilung je Marker.
- **Stichproben im Wortlaut**, an den Stellen, an denen die Spaltentrennung
  fehlschlagen würde. Mindestens diese drei, jeweils vollständig und ohne
  Fremdtext aus der rechten Spalte:
  - Zweite Stufe, Text- und Medienkompetenz, erster Eintrag — beginnt mit
    „unter Einsatz von Texterschließungsverfahren" und darf kein „adaptierte
    sowie authentische Texte" enthalten.
  - Erste Stufe, Grammatik, ein Eintrag mit Klammer über den Zeilenumbruch.
  - Erprobungsstufe, Sprachmittlung, ein Eintrag mit echtem Bindestrich.

Die Stichproben gehören vollständig in den Bericht, nicht nur als „bestanden".

**Prüfungen im Testskript:** Der Seed fällt unter die bestehenden — Quelle,
Prüfsumme, Erzeuger, Baumintegrität, `art`. Eine neue Prüfung ist nicht
vorgesehen; die Prüfungszahl bleibt bei **66**. Bleibt sie es nicht, im Bericht
begründen.

## Schritt 5 — Dokumentation

- `CHANGELOG.md`: Prüfungszahl, Knoten- und Kompetenzzahl.
- `docs/ENTSCHEIDUNGEN.md`: das Codeschema, das Verfahren zur Spaltentrennung —
  beides gilt für Französisch und Spanisch mit.
- `sql/gen/README.md`: Spaltentrennung und der zweite Marker. Viertes Fach,
  vierte eigene Falle.

## Schritt 6 — Ausliefern

```bash
./tests-projektstunden.sh
./deploy.sh "feat(klp): Englisch Sek I (E19, E29b)"
ssh hornse@halimede.uberspace.de \
  "mysql hornse_projektstunden < /home/hornse/projektstunden/sql/<nr>_seed_englisch_klp.sql"
```

Zweimal einspielen, danach zählen. Erwartet: `ENG_KLP` mit 177 Kompetenzen an
42 Blättern; alle anderen Rahmen unverändert.

Bei Rot: anhalten, nicht ausliefern.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

Zusätzlich: das Verfahren zur Spaltentrennung und woran es scheitern würde, die
drei Wortlaut-Stichproben vollständig, die nach E22 Regel 4 entschiedenen
Trennfälle, die Zeichenauszählung nach E25, das Codeschema mit Begründung, und
die Knotenzahl je Ebene.

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung.
- Bei Unklarheit nachfragen statt vermuten.
