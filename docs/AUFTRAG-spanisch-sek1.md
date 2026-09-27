# Auftrag: Spanisch Sekundarstufe I importieren

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

Der Kompetenzrahmen für Spanisch wird aus
`docs/curricula/g9_s_klp_3416_2019_06_23.pdf` aufgebaut. Ein Rahmen mit diesem
Kürzel existiert vermutlich nicht — bei Englisch und Französisch waren sie
gelöscht statt entleert. Nachsehen, nicht übernehmen.

Zu bauen sind `sql/gen/gen_spanisch_klp.py` und ein Seed unter der nächsten
freien Nummer.

**Die Anlage ist die von Französisch (E63):** drei Bildungsgänge, nicht drei
Phasen.

| Kapitel | Bildungsgang | Erwartungen |
|---|---|---|
| 2.2.1 | zweite Fremdsprache, Erste Stufe | 41 |
| 2.2.2 | zweite Fremdsprache, Zweite Stufe | 52 |
| 2.3 | ab Jahrgangsstufe 5 | **keine eigenen** |
| 2.4 | dritte Fremdsprache, Ende der Sek I | 51 |

Zusammen **144**. Der Bildungsgang wird Wurzelknoten mit
`art = 'bildungsgang'`, `phase` bleibt `erste_stufe`, `zweite_stufe` und
`sek1_uebergreifend`. Codeschema wie bei Französisch, mit `ES_` als Präfix —
oder `SPA_`, je nachdem, was zum Fachkürzel passt; nachsehen und begründen.

Kapitel 2.3 bekommt keinen Zweig; es verweist auf 2.2.

## Die Zeile aus der Strukturerhebung

Nach E64 gehört sie zitiert, nicht verwiesen.
`docs/curricula/STRUKTUR.md`, Zeile 15:

```
| 15 | g9_s_klp_3416_… | Spanisch | Sek I | à+4/+3/+1 · •+3 | zwei | 3 | 144 | ? |
```

Was darin steht und was daraus folgt:

**`à` auf drei Einrückungstiefen (+4/+3/+1).** Diese Auskunft habe ich nicht
nachgeprüft. Sie könnte den drei Bildungsgängen entsprechen oder etwas anderem.
Ein Erzeuger, der eine feste Einrückung erwartet, verliert die Erwartungen der
übrigen Tiefen — und die Summe sähe stimmig aus, wenn er sie gar nicht erst
findet. In Schritt 2 zu klären.

**`•`+3 ist dort als zweiter Marker geführt — das ist irreführend.** Gemessen:
34 Bullets, keiner in einem Erwartungskapitel (22 in Kapitel 1, 6 in Kapitel
2.3 als Aufzählung innerhalb eines Satzes, 6 in Kapitel 3). Das ist derselbe
Mangel, der für Französisch am 11.09. berichtigt wurde; die Spanisch-Zeile
trägt ihn unberichtigt. **Die Berichtigung gehört in diesen Vorgang.**

**Zweispaltig.** Die Rinne ist zu messen, nicht zu übernehmen — E47, und
Französisch hat gezeigt, warum: Dort lag sie bei 302.9 statt bei den aus
Englisch übernommenen 300.

**Drei Phasen** nennt die Spalte. Die Erhebung hat die drei Abschnitte gesehen
und sie Phasen genannt; wir nennen sie Bildungsgänge.

**144 Erwartungen.** Meine unabhängige Messung kommt auf dieselbe Zahl — anders
als bei Französisch, wo 204 gegen 202 standen. Bei Spanisch fallen Marker- und
Zeichenzählung zusammen: `à` kommt 144-mal am Zeilenanfang und 144-mal im
ganzen Dokument vor, kein spanisches Wort kommt dazwischen.

**Vorverarbeitung nach E64, im Bericht je Punkt nachzuweisen:** Seitenumbruch
tilgen, **Seitenzahlzeilen verwerfen**, C0 ersetzen und C1 nicht. Die
Seitenzahlregel ist die, die bei Englisch und Französisch gefehlt hat und neun
beziehungsweise sechs Einträge beschädigt hat — bei einem zweispaltigen Plan
ist sie zu erwarten, nicht zu hoffen.

## Schritt 0 — Voraussetzungen prüfen

```bash
./tests-projektstunden.sh; echo "Exit: $?"
git status --short
shasum -a 256 docs/curricula/g9_s_klp_3416_2019_06_23.pdf
which pdftotext
ls -1 sql/ | tail -5
```

Erwartet: 77/77 grün, sauberer Arbeitsbaum, `pdftotext` vorhanden, Prüfsumme
`119d7166a93d0c925fcb42ff4edf54ad37dd2aaf1041f571cb5dc60aed77f6d9`.

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SELECT kr.kuerzel, kr.fach_id, f.name FROM kompetenzrahmen kr
LEFT JOIN faecher f ON f.id = kr.fach_id ORDER BY kr.kuerzel;
SELECT id, name, kuerzel FROM faecher WHERE name LIKE \"%panisch%\";'"
```

Beim Englisch-Vorgang war 18 die `fach_id` für Spanisch — prüfen.

## Schritt 1 — Ausgangsstand

`./tests-projektstunden.sh`, Prüfungszahl notieren (erwartet 77). Knoten- und
Kompetenzzahl je Rahmen festhalten, dazu die Zahl der Zuweisungen.

## Schritt 2 — Drei Lücken schließen, dann anhalten

**Erstens: die drei Einrückungstiefen.** Was `+4/+3/+1` bedeutet, ist offen.
Ermitteln, wo die Marker tatsächlich stehen, und ob eine Erkennung über die
Einrückung überhaupt nötig ist oder das Zeichen am Zeilenanfang genügt.

**Zweitens: die Aufteilung der Interkulturellen kommunikativen Kompetenz.**
Sie hat drei Unterbereiche mit Doppelpunkt, einer davon über den Zeilenumbruch
getrennt. Meine Erkennung findet sie nicht zuverlässig — in der Ersten Stufe
gar keinen, in den anderen beiden je einen von dreien. Die Aufteilung ist
unbelegt. Bei Englisch war sie 1/2/4, bei Französisch 1/3/3; Spanisch kann ein
drittes Verhältnis haben.

**Drittens: die Rinne.** Nach dem Verfahren aus E47 messen, am Block, nicht
über rohe Wortkanten. Bei Französisch hat eine Messung über Wortkanten eine
Zone als „dünn besetzt" gemeldet, die in zweispaltigen Blöcken leer war — wer
über Wortkanten misst, misst die Seite; wer über Blöcke misst, misst die
Spalte.

Vorlegen und **anhalten**.

## Schritt 3 — Umsetzung

Erst nach Freigabe. Verfahren aus E47 und E63.

Eigenheiten, bei der Vorbereitung gemessen:

- **Ein Marker**, `à`, 144-mal — 41 / 52 / 51 auf die drei Kapitel. Die 34
  Bullets liegen außerhalb. Der Erzeuger führt `•: 0` als Sollzahl im
  Erwartungsteil und bricht ab, falls doch eines auftaucht.
- **`−` leitet die fachlichen Konkretisierungen ein**, rechte Spalte.
- **Kapitälchen kommen zerlegt an** (E47).
- **`U+0003` 19-mal, kein C1** — E25 in der C0-Fassung, geprüft.
- Silbentrennung nach E22, E28 und E48, sechste Regel in der engen Fassung.

**Eine Eigenheit, die Französisch nicht hat:** Grammatik trägt in allen drei
Bildungsgängen **genau eine** Kompetenzerwartung; die Einzelheiten stehen als
fachliche Konkretisierungen rechts (`artículo determinado`, `verbos
regulares`, `futuro perifrástico`). Das ist geprüft und kein Zählfehler — bei
Französisch waren es 3 bis 6. Wer die Zahl für falsch hält und sucht, sucht
umsonst.

## Schritt 4 — Tests

**Belegte Sollzahlen je Bildungsgang: 41 / 52 / 51 = 144.** Die Aufteilung auf
die Kompetenzbereiche ergibt sich aus Schritt 2; meine Zählung ist an zwei
Stellen unzuverlässig und geht deshalb nicht als Vorgabe ein.

**Kein Wortlautvergleich** — es gibt keinen Bestand. Was ihn ersetzt:

- Zählung je Einheit aus einem anderen Verfahren als der Erzeuger.
- **Ein vollständiger Diff gegen den erzeugten Seed**, nicht nur Stichproben.
  Bei Englisch haben drei von neun beschädigten Einträgen auf einem heilen Wort
  geendet — keine Prüfung und keine Stichprobe hätte sie gefunden, nur der
  vollständige Vergleich.
- **Der Selbstvergleich der Kapitel 2.2.2 und 2.4**, wie bei Französisch: Sie
  beschreiben dieselben Kompetenzen für zwei Bildungsgänge. Dort waren 62 von
  73 wortgleich und die elf Unterschiede sämtlich inhaltlich. Ein
  abgeschnittener Text fiele als Unterschied auf, wo keiner sein darf.
- Drei Wortlaut-Stichproben, vollständig im Bericht: der kleinste Block, der
  IKK-Block einer Stufe mit Zuordnung, und eine Stelle an der engsten Rinne.

**Prüfungen:** Der Seed fällt unter die bestehenden, einschließlich der
Endeprüfung aus E64. Die Prüfungszahl bleibt bei **77**, es sei denn, die
Einrückungsfrage verlangt eine eigene.

## Schritt 5 — Dokumentation

- `CHANGELOG.md`: Prüfungszahl, Knoten- und Kompetenzzahl.
- `docs/ENTSCHEIDUNGEN.md`: das Codeschema-Präfix, die gemessene Rinne, die
  IKK-Aufteilung.
- `docs/curricula/STRUKTUR.md`, **Zeile 15**: `•`+3 als Erwartungsmarker
  streichen, mit derselben Begründung wie bei Französisch; die gemessene
  Spaltengrenze eintragen; die Einrückungsangabe berichtigen oder bestätigen.
- `sql/gen/README.md`: die Rinne je Fach ergänzen.

## Schritt 6 — Ausliefern

```bash
./tests-projektstunden.sh
./deploy.sh "feat(klp): Spanisch Sek I – zweite und dritte Fremdsprache"
ssh hornse@halimede.uberspace.de \
  "mysql hornse_projektstunden < /home/hornse/projektstunden/sql/<nr>_seed_spanisch_klp.sql"
```

Zweimal einspielen, danach zählen. Erwartet: 144 Kompetenzen, alle anderen
Rahmen unverändert, Kompetenzen an Knoten mit Kindern = 0.

Bei Rot: anhalten, nicht ausliefern.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

Zusätzlich, nach E64: **je Punkt der Vorverarbeitung, wo im Erzeuger er steht** —
Seitenumbruch, Seitenzahlzeilen, C0. Dazu die IKK-Aufteilung, die gemessene
Rinne mit Trennungszahl und Rändern, das Ergebnis des Selbstvergleichs 2.2.2
gegen 2.4, die drei Stichproben vollständig, die Regel-4-Fälle, und die
Knotenzahl je Ebene.

## Ein Befund, der über diesen Auftrag hinausgeht

Die Tabelle in `STRUKTUR.md` zeigt drei Dinge, die künftige Fachimporte
betreffen und hier nur zu melden sind:

**Fünf Pläne tragen `U+F0FA` oder `U+F0A7` als Marker** — WP Wirtschaft,
Praktische Philosophie, Englisch GOSt, Französisch GOSt, Spanisch GOSt. Das
sind Wingdings-Zeichen aus dem Privatbereich der Zeichentabelle, nicht `à`. Ein
Erzeuger, der `à` erwartet, findet dort nichts.

**Mathematik GOSt trägt `(n)`** — nummerierte Erwartungen statt
Aufzählungszeichen, eine eigene Bauform.

**Sieben Pläne führen zwei Zahlen** wie `104 + 101` oder `596 / 435`. Was der
zweite Wert bedeutet, sagt die Tabelle nicht — vermutlich Grund- und
Leistungskurs. Das ist geraten und gehört geklärt, bevor einer davon
beauftragt wird.

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung.
- Bei Unklarheit nachfragen statt vermuten.
