# Auftrag: Deutsch Sekundarstufe I — Quellennachweis und Phasenkorrektur

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

Drei Dinge, die zusammengehören, weil alle denselben Seed betreffen.

**Erstens** der Quellennachweis für `10_seed_deutsch_klp.sql` nach E19: ein
Erzeuger unter `sql/gen/gen_deutsch_klp.py`, Quelle und Prüfsumme im Kopf.
Es ist der letzte Seed ohne Nachweis.

**Zweitens** die Umsetzung von E12 und E14, die seit dem 02.09.2026 offen
stehen. 21 Kompetenzerwartungen aus Kapitel 2.3 des Lehrplans sind als
`zweite_stufe` eingetragen, gelten aber für die gesamte Sekundarstufe I. Sie
bekommen die Phase `sek1_uebergreifend` und die Codes `DE_S1U_UEB_…` statt
`DE_S2_UEB_…`. Dafür ist der ENUM zu erweitern.

**Drittens** die zweite Quellenprüfung: Jeder Seed muss eine Quelle
deklarieren. Sie schließt das Schlupfloch aus E21 und E23 — bisher entgeht der
Prüfung, wer die Zeile weglässt. Sie lässt sich erst jetzt bauen, weil bis
heute ein Seed ohne Quelle im Repo lag.

**Der Bestand ist zweifach geprüft.** 28 Bereiche, 226 Kompetenzerwartungen,
im Juli 2026 gegen den Lehrplan verglichen und am 06.09.2026 unabhängig neu
ausgezählt — alle 28 Einzelzählungen stimmen überein (Tabelle unten). Es wird
**nichts neu erhoben**; der Erzeuger muss den Bestand reproduzieren. Einzige
gewollte Änderung sind Phase und Codes der 21 übergeordneten Erwartungen.

## Schritt 0 — Voraussetzungen prüfen

```bash
./tests-projektstunden.sh; echo "Exit: $?"
git status --short
shasum -a 256 docs/curricula/g9_d_klp_3409_2019_06_23.pdf
which pdftotext
ls -1 sql/ | tail -5
```

Erwartet: 51/51 grün, sauberer Arbeitsbaum, `pdftotext` vorhanden, Prüfsumme
`844fdfe8c875433c2775c899b74a2d83d466a19a4d3cc5d88630d7b7d66cb94c`.

Migrationsnummer 14 muss frei sein. Ist sie vergeben: anhalten und melden.

Prüfen, ob Kompetenzen aus `DEU_KLP` bereits Schülern zugewiesen sind:

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SELECT COUNT(*) FROM projekt_schueler_kompetenzen psk
JOIN kompetenzen k ON k.id = psk.kompetenz_id
JOIN kompetenzbereiche kb ON kb.id = k.bereich_id
JOIN kompetenzrahmen kr ON kr.id = kb.rahmen_id
WHERE kr.kuerzel = \"DEU_KLP\";'"
```

Erwartet: 0. Ist die Zahl größer, **anhalten** — dann löscht der Seed über
`ON DELETE CASCADE` Bewertungen mit, und das ist neu zu entscheiden.

## Schritt 1 — Ausgangsstand

```bash
./tests-projektstunden.sh
```
Prüfungszahl notieren (erwartet 51).

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SELECT COUNT(*) AS bereiche_gesamt FROM kompetenzbereiche;
SELECT COUNT(*) AS kompetenzen_gesamt FROM kompetenzen;
SELECT kr.kuerzel, COUNT(DISTINCT kb.id) AS bereiche, COUNT(k.id) AS kompetenzen
FROM kompetenzrahmen kr
LEFT JOIN kompetenzbereiche kb ON kb.rahmen_id = kr.id
LEFT JOIN kompetenzen k ON k.bereich_id = kb.id
GROUP BY kr.id HAVING kompetenzen > 0 ORDER BY kr.kuerzel;'"
```

Erwartet: 118 / 649 gesamt; `DEU_KLP 28/226`, `DEU_KLP_SII 30/197`,
`MKR 6/106`, `SPO_KLP 54/120`. Diese Zahlen bleiben am Ende unverändert.

## Schritt 2 — Zuschnitt der zweiten Prüfung, dann anhalten

Die Prüfung soll lauten: *Jeder Seed deklariert eine Quelle.* Offen ist, woran
ein Seed erkannt wird.

Am Dateinamen (`*seed*`) wäre es eine Konvention, kein Merkmal — REIHENREGELN 4
warnt davor. `02_seed.sql` heißt anders als `10_seed_deutsch_klp.sql`, und der
nächste Import könnte wieder anders heißen.

Am Inhalt wäre es ein Wesensmerkmal: Eine Datei unter `sql/`, die in
`kompetenzen` oder `kompetenzbereiche` schreibt, führt Fachdaten und muss eine
Quelle deklarieren. Migrationen, die nur Spalten anlegen, fallen nicht darunter.

Vorgehen: beide Fassungen gegen den Bestand durchspielen — welche Dateien
trifft jede, welche nicht —, dann berichten und anhalten. Insbesondere die
Frage, ob `01_schema.sql` oder eine der Migrationen 03 bis 08 mitgefangen wird.
Ich entscheide, bevor gebaut wird.

## Schritt 3a — Migration 14

`sql/14_migration_phase_sek1uebergreifend.sql`: Der ENUM von
`kompetenzbereiche.phase` wird um `sek1_uebergreifend` erweitert. Die
Reihenfolge der Werte soll der zeitlichen Abfolge entsprechen — der neue Wert
gehört zwischen `erprobungsstufe` und `erste_stufe`, nicht ans Ende.

Kein `DROP`, `DELETE` oder `TRUNCATE`. Zweimal ausführbar. Bestehende Werte
bleiben gültig.

**Danach anhalten und prüfen**, bevor der Seed angefasst wird:

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SHOW COLUMNS FROM kompetenzbereiche LIKE \"phase\";
SELECT COUNT(*) FROM kompetenzbereiche;
SELECT COUNT(*) FROM kompetenzen;
SELECT phase, COUNT(*) FROM kompetenzbereiche GROUP BY phase;'"
```

118 und 649 müssen unverändert sein, und kein Bereich darf seine Phase verloren
haben. Weicht etwas ab: anhalten.

## Schritt 3b — Erzeuger und Seed

`sql/gen/gen_deutsch_klp.py` nach dem Muster von `gen_sport_klp.py`: Prüfsumme
zuerst, `pdftotext` ausdrücklich verlangen, C0-Steuerzeichen vor der
Normalisierung entfernen (E25), gegen die Sollzahlen zählen und bei einer
einzigen Abweichung nichts schreiben.

Eigenheiten dieses Plans, bei der Vorbereitung belegt:

- **Zwei Aufzählungszeichen.** `\x83` leitet die 42 übergeordneten Erwartungen
  ein, `à` die 184 konkretisierten. Zusammen 226. Beide sind falsch dekodierte
  Wingdings-Zeichen.
- **`–` leitet inhaltliche Schwerpunkte ein**, 98-mal, und zählt nicht mit.
- **`\x03` kommt 15-mal vor.** E25 greift also auch hier, nicht nur bei Sport.
- **Vier Abschnitte, nicht drei.** Zwischen `2.3` und `2.3.1` liegt der Block
  der übergeordneten Erwartungen für die gesamte Sekundarstufe I — das ist der
  Gegenstand von E12. Er steht im Lehrplan vor der Ersten Stufe, weil er für
  beide Stufen gilt.
- Silbentrennung nach E22.

Kopf nach E19:

```
-- Quelle: docs/curricula/g9_d_klp_3409_2019_06_23.pdf
-- SHA256: 844fdfe8c875433c2775c899b74a2d83d466a19a4d3cc5d88630d7b7d66cb94c
-- Erzeugt von: sql/gen/gen_deutsch_klp.py
```

**E12 und E14 umsetzen:** Die 21 Erwartungen aus dem Block zwischen `2.3` und
`2.3.1` bekommen `phase = 'sek1_uebergreifend'` und die Codes
`DE_S1U_UEB_REZ_01` bis `_08` sowie `DE_S1U_UEB_PRO_01` bis `_13`. Ihre
Reihenfolge bleibt vor der Ersten Stufe.

**Alles andere aus dem Bestand rekonstruieren, nicht neu erfinden** — Codes,
Bereichsnamen, Kürzungsgrenze, Sortierung. Bei Deutsch GOSt lag sie bei 120
Zeichen und der Schlusspunkt blieb erhalten; bei Sport wurde er entfernt. Erst
nachsehen, was `10_seed_deutsch_klp.sql` tut.

`art` bleibt hier `NULL` — Deutsch führt nur eine Inhaltsachse. `teilbereich`
ebenfalls.

Robustheit: `DELETE` auf `DEU_KLP` beschränkt, alles in einer Transaktion,
zweimaliges Einspielen liefert dasselbe.

## Schritt 4 — Tests

**Sollzahlen** aus `g9_d_klp_3409_2019_06_23.pdf`, ermittelt mit
`pdftotext -layout` und Zählung der `\x83`- und `à`-Zeilen je Abschnitt.
Unabhängig vom Erzeuger gewonnen.

| Phase | Inhaltsfeld | Rezeption | Produktion |
|---|---|---|---|
| Erprobungsstufe | Übergeordnet | 8 | 13 |
| Erprobungsstufe | Sprache | 10 | 6 |
| Erprobungsstufe | Texte | 10 | 6 |
| Erprobungsstufe | Kommunikation | 7 | 7 |
| Erprobungsstufe | Medien | 7 | 8 |
| **sek1_uebergreifend** | Übergeordnet | 8 | 13 |
| Erste Stufe | Sprache | 9 | 5 |
| Erste Stufe | Texte | 13 | 9 |
| Erste Stufe | Kommunikation | 6 | 4 |
| Erste Stufe | Medien | 10 | 7 |
| Zweite Stufe | Sprache | 9 | 6 |
| Zweite Stufe | Texte | 9 | 10 |
| Zweite Stufe | Kommunikation | 4 | 6 |
| Zweite Stufe | Medien | 9 | 7 |

Summen: Erprobungsstufe 10 Bereiche / 82, sek1_uebergreifend 2 / 21,
Erste Stufe 8 / 63, Zweite Stufe 8 / 60 — zusammen **28 Bereiche, 226
Erwartungen**, identisch mit dem Bestand.

**Wortlautvergleich gegen den Bestand.** Erwartet sind genau 21 Abweichungen,
und zwar ausschließlich in Phase und Code der übergeordneten Erwartungen. Jede
Abweichung im **Kompetenztext** ist ein Befund: in Schritt 2 zurückfallen und
vorlegen, nicht überschreiben. Bei Deutsch GOSt waren fünf von elf
Abweichungen Fehler des Bestands, bei Sport zwei von drei.

**Die zweite Prüfung** in `tests-projektstunden.sh`, Rubrik „Fachdaten", nach
dem in Schritt 2 entschiedenen Zuschnitt. Gegenproben:
- Die `-- Quelle:`-Zeile aus einem Seed entfernen → rot.
- Entwertung: die Prüfung so verändern, dass sie keine Datei mehr findet → rot,
  nicht still grün.

Erwartete Prüfungszahl: **51 + 1 = 52**.

## Schritt 5 — Dokumentation

- `CHANGELOG.md`: Eintrag mit Prüfungszahl vorher und nachher.
- `docs/ENTSCHEIDUNGEN.md`: ein Eintrag, der festhält, dass E12, E14 und der
  Rückstand aus E21 erledigt sind — nach REIHENREGELN 10 als neuer Eintrag,
  nicht als Änderung der alten.
- `sql/gen/README.md`: die Eigenheiten dieses Plans ergänzen, insbesondere die
  zwei verschiedenen Aufzählungszeichen. Drittes Fach, dritte eigene Falle.

## Schritt 6 — Ausliefern

```bash
./tests-projektstunden.sh
./deploy.sh "feat(klp): Deutsch Sek I – Quellennachweis (E19), Phase sek1_uebergreifend (E12/E14)"
ssh hornse@halimede.uberspace.de \
  "mysql hornse_projektstunden < /home/hornse/projektstunden/sql/14_migration_phase_sek1uebergreifend.sql"
ssh hornse@halimede.uberspace.de \
  "mysql hornse_projektstunden < /home/hornse/projektstunden/sql/10_seed_deutsch_klp.sql"
```

Danach die Zählung aus Schritt 1 wiederholen, ein zweites Mal einspielen,
erneut zählen. Erwartet: dreimal 118 / 649 und `DEU_KLP 28/226`. Zusätzlich:

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SELECT phase, COUNT(DISTINCT kb.id) AS bereiche, COUNT(k.id) AS kompetenzen
FROM kompetenzbereiche kb
JOIN kompetenzrahmen kr ON kr.id = kb.rahmen_id
LEFT JOIN kompetenzen k ON k.bereich_id = kb.id
WHERE kr.kuerzel = \"DEU_KLP\" GROUP BY phase ORDER BY phase;'"
```

Erwartet: `erprobungsstufe 10/82`, `sek1_uebergreifend 2/21`,
`erste_stufe 8/63`, `zweite_stufe 8/60`.

Bei Rot in `tests-projektstunden.sh`: anhalten, nicht ausliefern.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

Zusätzlich: die Liste der Wortlautabweichungen, die nach E22 Regel 4
entschiedenen Trennfälle, und die Zeichenauszählung nach E25.

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung.
- Bei Unklarheit nachfragen statt vermuten.
