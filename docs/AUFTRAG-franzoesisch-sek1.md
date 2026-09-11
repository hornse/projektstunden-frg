# Auftrag: Französisch Sekundarstufe I importieren

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

Der Kompetenzrahmen für Französisch wird aus
`docs/curricula/g9_f_klp_3410_2019_06_23.pdf` neu aufgebaut. Ein Rahmen mit
diesem Kürzel existiert vermutlich nicht — bei Englisch war er entgegen der
Annahme gelöscht statt entleert. Nachsehen, nicht übernehmen.

Zu bauen sind ein Erzeuger `sql/gen/gen_franzoesisch_klp.py` und ein Seed unter
der nächsten freien Nummer.

**Neu an diesem Fach: eine Achse, die es bisher nicht gab.** Französisch führt
drei Bildungsgänge, nicht drei Phasen:

| Kapitel | Bildungsgang | Erwartungen |
|---|---|---|
| 2.2.1 | zweite Fremdsprache, Erste Stufe | 55 |
| 2.2.2 | zweite Fremdsprache, Zweite Stufe | 74 |
| 2.3 | ab Jahrgangsstufe 5 | **keine eigenen** |
| 2.4 | dritte Fremdsprache, Ende der Sek I | 73 |

Zusammen **202**, und die Markerzählung bestätigt es: `à` kommt im Dokument
202-mal vor.

**Kapitel 2.3 bekommt keinen Zweig.** Es verweist ausdrücklich auf 2.2 — „der
Unterricht ab Jahrgangsstufe 5 orientiert sich an den Kompetenzerwartungen, die
in Kapitel 2.2 aufgeführt sind". Die sechs `•` dort sind Fließtext.

**Der Bildungsgang wird ein Wurzelknoten** mit `art = 'bildungsgang'`, darunter
die von Englisch bekannte Gliederung. Das Schema bleibt unverändert; der Baum
aus E29b trägt es. `phase` bleibt `erste_stufe` und `zweite_stufe` für die
zweite Fremdsprache und `sek1_uebergreifend` für die dritte, die „am Ende der
Sekundarstufe I" gilt und keiner Stufe zugeordnet ist.

Verworfen wurden: der Bildungsgang als Teil der Phase — der ENUM wüchse je Fach
und die Farbpalette aus E59 bräuchte neue Einträge; und zwei getrennte Rahmen —
ein Fach mit zwei Einträgen im Katalog verlangt beim Anlegen einer Werkstatt zu
wissen, welcher gilt.

**An der Schule werden beide Bildungsgänge angeboten**, die dritte Fremdsprache
kommt selten zustande. Beide werden importiert.

## Schritt 0 — Voraussetzungen prüfen

```bash
./tests-projektstunden.sh; echo "Exit: $?"
git status --short
shasum -a 256 docs/curricula/g9_f_klp_3410_2019_06_23.pdf
which pdftotext
ls -1 sql/ | tail -5
```

Erwartet: 76/76 grün, sauberer Arbeitsbaum, `pdftotext` vorhanden, Prüfsumme
`dbcaea789b7b7f3a937c14c3b17989ba6a0523e187371638271c7795f1925d57`.

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SELECT kr.id, kr.kuerzel, kr.fach_id, f.name AS fach
FROM kompetenzrahmen kr LEFT JOIN faecher f ON f.id = kr.fach_id
ORDER BY kr.kuerzel;
SELECT id, name, kuerzel FROM faecher WHERE name LIKE \"%ranz%\";'"
```

Existiert ein Französisch-Rahmen und trägt er Zuweisungen, anhalten und melden.
Die `fach_id` nachsehen — beim Englisch-Vorgang war es 16 für Französisch, aber
das gehört geprüft.

`docs/curricula/STRUKTUR.md` zum Abschnitt Französisch lesen. Weicht dieser
Auftrag davon ab, ist das ein Widerspruch und gehört gemeldet.

## Schritt 1 — Ausgangsstand

```bash
./tests-projektstunden.sh
```
Prüfungszahl notieren (erwartet 76). Knoten- und Kompetenzzahl je Rahmen
festhalten.

## Schritt 2 — Zwei Lücken schließen, dann anhalten

**Der Auftrag hat zwei Stellen, an denen ich keine Zahl nennen kann.** Sie
stehen hier als Lücken und nicht als Vermutung — bei Englisch stand an der
entsprechenden Stelle eine Zahl, die falsch war (E46).

**Erstens: die Aufteilung der Interkulturellen kommunikativen Kompetenz.**

Sie hat in jedem Bildungsgang sieben Erwartungen — das ist belegt. Sie hat
außerdem drei Unterbereiche, an einem Doppelpunkt erkennbar und am linken Rand
stehend:

- Soziokulturelles Orientierungswissen
- Interkulturelle Einstellungen und Bewusstheit
- Interkulturelles Verstehen und Handeln

Der mittlere steht im Text über den Zeilenumbruch getrennt
(`Interkulturelle Einstellungen und Be-` / `wusstheit:`). **Wie sich die sieben
auf die drei verteilen, ist nicht ermittelt.** Bei Englisch war es 1/2/4;
ob Französisch dasselbe Verhältnis hat, ist unbekannt.

Ermitteln und vorlegen. Daraus folgt auch die Blätterzahl: 15 oder 16 je
Bildungsgang, also 45 oder 48 insgesamt.

**Zweitens: die Rinne.**

`STRUKTUR.md` gibt für Französisch „x ≈ 300" an — das ist aus Englisch
übernommen, nicht gemessen. Eine grobe Messung über die linken Wortkanten auf
den 28 Seiten mit Markern zeigt etwas anderes: Die rechte Spalte beginnt bei
**303** und **321**, nicht bei 302 und 320 wie bei Englisch. Die Zone 293 bis
302 ist dünn besetzt, aber nicht leer — zwischen 1 und 10 Wörter je Position.

Ein Schwellenwert von 300 zöge die Wörter bei 301 und 302 fälschlich nach
rechts. Ob sie überhaupt in Erwartungsblöcken stehen, sagt meine Messung nicht;
dafür braucht es die Blockbildung aus E47.

Die Rinne messen und vorlegen, mit der Zahl der Trennungen und den
tatsächlichen rechten Spaltenrändern — wie beim Englisch-Vorgang, wo es 117
Trennungen an vier Rändern ohne Ausreißer waren.

Vorlegen und **anhalten**.

## Schritt 3 — Umsetzung

Erst nach Freigabe. Das Verfahren ist das aus E47: `pdftotext -bbox-layout`,
Zeilen über die Grundlinie neu bilden, Blöcke aus Markerzeile plus
Fortsetzungen, die Spaltenfrage am Block entscheiden, innerhalb zweispaltiger
Blöcke am ersten Wort ab der Grenze trennen.

Eigenheiten, bei der Vorbereitung belegt:

- **Ein Marker.** `à`, 202-mal. Anders als bei Englisch gibt es keinen zweiten
  — aber das ist zu prüfen, nicht zu glauben: Bei Englisch trugen sieben
  Erwartungen `•`, und die Summe sah ohne sie stimmig aus.
- **Kapitälchen kommen zerlegt an** (E47): `I NTERKULTURELLE`. Zwei Ersetzungen
  stellen die Überschriften wieder her.
- **`−` leitet die fachlichen Konkretisierungen ein**, rechte Spalte, zählt
  nicht mit.
- Silbentrennung nach E22, E28 und E48 — einschließlich der sechsten Regel in
  der engen Fassung.
- Steuerzeichen nach E25: C0 tilgen, C1 prüfen statt annehmen.

**Codeschema** nach dem Muster von Englisch (E46), erweitert um den
Bildungsgang. Vorschlag zur Prüfung, nicht als Vorgabe: `FR_2FS_S1_HOR_01`,
`FR_2FS_S2_VSM_GRA_01`, `FR_3FS_IKK_SOW_01`. Ob der Bildungsgang vor oder nach
der Stufe steht und wie die dritte Fremdsprache ohne Stufe aussieht, gehört
begründet.

## Schritt 4 — Tests

**Belegte Sollzahlen.** Sie stammen aus einem anderen Verfahren als der
Erzeuger; weicht er ab, ist zuerst zu klären, welche Zählung falsch ist.

| Kompetenzbereich | Teilbereich | Unterbereich | 2FS S1 | 2FS S2 | 3FS |
|---|---|---|---|---|---|
| Funktionale kommunikative Kompetenz | Hör-/Hörsehverstehen | — | 4 | 4 | 4 |
| Funktionale kommunikative Kompetenz | Leseverstehen | — | 2 | 4 | 4 |
| Funktionale kommunikative Kompetenz | Sprechen: an Gesprächen teilnehmen | — | 4 | 5 | 5 |
| Funktionale kommunikative Kompetenz | Sprechen: zusammenhängendes Sprechen | — | 4 | 4 | 4 |
| Funktionale kommunikative Kompetenz | Schreiben | — | 5 | 6 | 6 |
| Funktionale kommunikative Kompetenz | Sprachmittlung | — | 3 | 4 | 4 |
| Funktionale kommunikative Kompetenz | Verfügen über sprachliche Mittel | Wortschatz | 3 | 5 | 4 |
| Funktionale kommunikative Kompetenz | Verfügen über sprachliche Mittel | Grammatik | 3 | 6 | 6 |
| Funktionale kommunikative Kompetenz | Verfügen über sprachliche Mittel | Aussprache und Intonation | 3 | 3 | 3 |
| Funktionale kommunikative Kompetenz | Verfügen über sprachliche Mittel | Orthografie | 2 | 3 | 3 |
| Interkulturelle kommunikative Kompetenz | — | **drei, Aufteilung offen** | 7 | 7 | 7 |
| Text- und Medienkompetenz | — | — | 4 | 11 | 11 |
| Sprachlernkompetenz | — | — | 7 | 7 | 7 |
| Sprachbewusstheit | — | — | 4 | 5 | 5 |

Summen: **55 / 74 / 73 = 202.**

**Kein Wortlautvergleich** — es gibt keinen geprüften Bestand. Was ihn ersetzt:
die Zählung je Einheit aus einem anderen Verfahren, die Markeraufteilung, und
Wortlaut-Stichproben. Mindestens diese drei, jeweils vollständig:

1. Zweite Fremdsprache, Erste Stufe, Leseverstehen — nur zwei Erwartungen, der
   kleinste Block, und damit der, bei dem ein Fehler in der Blockbildung am
   ehesten durchrutscht.
2. Der IKK-Block einer Stufe vollständig, mit der Zuordnung zu den drei
   Unterbereichen — die Stelle aus Schritt 2.
3. Ein Eintrag aus dem Bereich, in dem die Rinne am engsten ist, gemessen in
   Schritt 2 — er darf keinen Fremdtext aus der rechten Spalte tragen.

Die Stichproben gehören vollständig in den Bericht, nicht als „bestanden".

**Prüfungen:** Der Seed fällt unter die bestehenden. Die Prüfungszahl bleibt
bei **76**, es sei denn, der Bildungsgang verlangt eine eigene — dann die Zahl
nennen und begründen.

## Schritt 5 — Dokumentation

- `CHANGELOG.md`: Prüfungszahl, Knoten- und Kompetenzzahl.
- `docs/ENTSCHEIDUNGEN.md`: der Bildungsgang als Wurzelknoten und
  `art = 'bildungsgang'`, das Codeschema, die gemessene Rinne. Alle drei gelten
  für Spanisch mit.
- `sql/gen/README.md`: die Rinne je Fach, und dass Kapitel ohne eigene
  Erwartungen keinen Zweig bekommen.
- `docs/curricula/STRUKTUR.md`: den Abschnitt Französisch berichtigen, falls die
  gemessene Rinne von „x ≈ 300" abweicht.

## Schritt 6 — Ausliefern

```bash
./tests-projektstunden.sh
./deploy.sh "feat(klp): Französisch Sek I – zweite und dritte Fremdsprache"
ssh hornse@halimede.uberspace.de \
  "mysql hornse_projektstunden < /home/hornse/projektstunden/sql/<nr>_seed_franzoesisch_klp.sql"
```

Zweimal einspielen, danach zählen. Erwartet: 202 Kompetenzen, alle anderen
Rahmen unverändert. Zusätzlich gegen die Datenbank prüfen: Kompetenzen an
Knoten mit Kindern = 0, und die Verteilung von `art`.

Bei Rot: anhalten, nicht ausliefern.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

Zusätzlich: die Aufteilung der IKK auf ihre drei Unterbereiche, die gemessene
Rinne mit Trennungszahl und Spaltenrändern, die drei Stichproben vollständig,
die Regel-4-Fälle nach E22, die Zeichenauszählung nach E25, und die Knotenzahl
je Ebene.

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung.
- Bei Unklarheit nachfragen statt vermuten.
