# Auftrag: Sport — Spalten `teilbereich`/`art` und Quellennachweis

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

Zwei Dinge, in dieser Reihenfolge, mit einer Prüfung dazwischen.

**Erstens** die Spalten aus E18: `teilbereich` und `art` in `kompetenzbereiche`.
Additiv, `NULL`-fähig, ohne Vorgabewert.

**Zweitens** der Quellennachweis für `12_seed_sport_klp.sql` nach E19: ein
Erzeuger unter `sql/gen/gen_sport_klp.py`, Quelle und Prüfsumme im Kopf des
Seeds — und die Spalte `art` gefüllt.

Sport ist das einzige Fach, in dem `inhaltsfeld` zwei verschiedene Dinge
enthält: sechs Inhaltsfelder (`Inhaltsfeld a:` bis `f:`) und neun
Bewegungsfelder (`BF/SB 1:` bis `9:`). Heute sind sie nur an der
Namenskonvention unterscheidbar. Genau dafür wurde `art` beschlossen; deshalb
kommt die Migration hier und nicht erst mit Englisch.

**Der Bestand ist inhaltlich geprüft.** 54 Bereiche, 120 Kompetenzerwartungen,
gegen den Lehrplan ausgezählt (Tabelle unten, Übereinstimmung ohne Abweichung).
Es wird also **nichts neu erhoben**. Der Erzeuger muss den vorhandenen Bestand
reproduzieren; tut er es nicht, ist das ein Befund, kein Fortschritt.

Nicht dazu: `teilbereich` befüllen. Sport hat keine dritte Ebene; die Spalte
bleibt hier leer und bekommt ihre Daten mit Englisch.

## Schritt 0 — Voraussetzungen prüfen

```bash
./tests-projektstunden.sh; echo "Exit: $?"
git status --short
shasum -a 256 docs/curricula/g9_sp_klp_3426_2019_06_23.pdf
which pdftotext
ls -1 sql/ | tail -5
```

Erwartet: 50/50 grün, sauberer Arbeitsbaum, `pdftotext` vorhanden, und die
Prüfsumme
`815f985166f45bc136ae3fc28aff4b0214b29b9862aa0eb33df312e32e950351`.

Die höchste vergebene Migrationsnummer nachsehen, nicht annehmen. Ist `13`
bereits vergeben, anhalten und melden.

Weicht etwas ab: hier anhalten.

## Schritt 1 — Ausgangsstand

```bash
./tests-projektstunden.sh
```
Prüfungszahl notieren (erwartet 50).

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

Erwartet: `DEU_KLP 28/226`, `DEU_KLP_SII 30/197`, `MKR 6/106`, `SPO_KLP 54/120`.
Diese Zahlen müssen am Ende unverändert sein — beide Schritte ändern keine
Datenmenge.

## Schritt 2 — entfällt

Die Entscheidungen sind gefallen: E18 (benannte Spalten), E19 (Quellennachweis),
E22 (Silbentrennung, gilt auch hier). Der Bestand ist ausgezählt, die Sollzahlen
stehen unten. Nicht neu aufrollen.

**Eine Ausnahme, bei der doch anzuhalten ist:** Weicht der erzeugte Wortlaut in
Schritt 4 vom Bestand ab, hier anhalten und die Liste vorlegen. Nicht
überschreiben. Bei Deutsch GOSt hat genau diese Liste fünf Extraktionsfehler
zutage gefördert, die niemand bemerkt hatte — sie ist der Grund, warum
Zählwerte allein nicht genügen.

## Schritt 3a — Migration 13

`sql/13_migration_klp_spalten.sql`:

- `teilbereich VARCHAR(80) NULL` — für die Fremdsprachen, bleibt hier leer.
- `art VARCHAR(30) NULL` — was in `inhaltsfeld` steht. Vorgesehene Werte:
  `inhaltsfeld`, `bewegungsfeld`.

Beide `NULL`-fähig, ohne Vorgabe, damit der Bestand unverändert gültig bleibt.
Kein `DROP`, `DELETE` oder `TRUNCATE` in der Datei. Zweimal ausführbar.

**Danach anhalten und prüfen**, bevor der Seed angefasst wird:

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SHOW COLUMNS FROM kompetenzbereiche;
SELECT COUNT(*) FROM kompetenzbereiche;
SELECT COUNT(*) FROM kompetenzen;'"
```

Die beiden Zählwerte müssen denen aus Schritt 1 entsprechen. Weichen sie ab,
anhalten — dann hat die Migration mehr getan als angelegt.

## Schritt 3b — Erzeuger und Seed

`sql/gen/gen_sport_klp.py`, nach dem Muster von `gen_deutsch_sii.py`: erst die
SHA256 der Quelle prüfen und bei Abweichung abbrechen, `pdftotext` ausdrücklich
verlangen, danach je Gliederungseinheit gegen die Sollzahlen unten zählen und
bei einer einzigen Abweichung nichts schreiben.

Eigenheiten des Sport-Plans, belegt bei der Vorbereitung:

- **Das Aufzählungszeichen ist `à`**, nicht `•` — ein falsch dekodierter
  Wingdings-Pfeil. `•` kommt im Dokument 20-mal vor, aber an anderer Stelle.
- **`–` leitet inhaltliche Schwerpunkte ein**, keine Kompetenzerwartungen. Es
  kommt 108-mal vor und darf nicht mitgezählt werden.
- **Zwei Achsen, ein Feld.** Unter `2.4.1` und `2.5.1` stehen die Inhaltsfelder
  a–f mit Sach-, Methoden- und Urteilskompetenz; unter `2.4.2` und `2.5.2` die
  Bewegungsfelder 1–9 mit der Bewegungs- und Wahrnehmungskompetenz. Die
  Überschriften „Bewegungsfeld übergreifend" und „spezifisch" benennen diese
  beiden Achsen und sind keine weitere Ebene.
- Silbentrennung nach E22.

`sql/11_seed_deutsch_sii.sql` ist die Vorlage für Kopf und Aufbau. Der Kopf
nennt:

```
-- Quelle: docs/curricula/g9_sp_klp_3426_2019_06_23.pdf
-- SHA256: 815f985166f45bc136ae3fc28aff4b0214b29b9862aa0eb33df312e32e950351
-- Erzeugt von: sql/gen/gen_sport_klp.py
```

`art` wird gefüllt: `inhaltsfeld` für die sechs Inhaltsfelder,
`bewegungsfeld` für die neun Bewegungsfelder.

**Codes und Anzeigenamen aus dem Bestand rekonstruieren, nicht neu erfinden.**
Bei Deutsch GOSt wären sonst 139 von 197 Codes ohne Not gewechselt. Erst
nachsehen, welches Schema `12_seed_sport_klp.sql` verwendet.

Robustheit: Das `DELETE` bleibt auf `SPO_KLP` beschränkt, alles läuft in einer
Transaktion, zweimaliges Einspielen liefert dasselbe Ergebnis.

## Schritt 4 — Tests

**Sollzahlen** aus `g9_sp_klp_3426_2019_06_23.pdf`, ermittelt mit
`pdftotext -layout` und Zählung der `à`-Zeilen je Abschnitt. Sie stammen aus
einem anderen Verfahren als der Erzeuger — weicht er ab, ist zuerst zu klären,
welche der beiden Zählungen falsch ist.

| Gegenstand | Kompetenzbereich | Erprobungsstufe | Sek I |
|---|---|---|---|
| Inhaltsfeld a | Sachkompetenz | 2 | 2 |
| Inhaltsfeld a | Methodenkompetenz | 2 | 3 |
| Inhaltsfeld a | Urteilskompetenz | 1 | 3 |
| Inhaltsfeld b | Sachkompetenz | 2 | 2 |
| Inhaltsfeld b | Methodenkompetenz | 2 | 3 |
| Inhaltsfeld b | Urteilskompetenz | 1 | 2 |
| Inhaltsfeld c | Sachkompetenz | 1 | 3 |
| Inhaltsfeld c | Methodenkompetenz | 1 | 2 |
| Inhaltsfeld c | Urteilskompetenz | 1 | 1 |
| Inhaltsfeld d | Sachkompetenz | 3 | 3 |
| Inhaltsfeld d | Methodenkompetenz | 1 | 2 |
| Inhaltsfeld d | Urteilskompetenz | 1 | 2 |
| Inhaltsfeld e | Sachkompetenz | 2 | 2 |
| Inhaltsfeld e | Methodenkompetenz | 2 | 3 |
| Inhaltsfeld e | Urteilskompetenz | 1 | 1 |
| Inhaltsfeld f | Sachkompetenz | 2 | 2 |
| Inhaltsfeld f | Methodenkompetenz | 1 | 2 |
| Inhaltsfeld f | Urteilskompetenz | 1 | 1 |
| BF/SB 1 | Bewegungs- und Wahrnehmungskompetenz | 4 | 4 |
| BF/SB 2 | Bewegungs- und Wahrnehmungskompetenz | 4 | 2 |
| BF/SB 3 | Bewegungs- und Wahrnehmungskompetenz | 3 | 4 |
| BF/SB 4 | Bewegungs- und Wahrnehmungskompetenz | 4 | 3 |
| BF/SB 5 | Bewegungs- und Wahrnehmungskompetenz | 3 | 3 |
| BF/SB 6 | Bewegungs- und Wahrnehmungskompetenz | 2 | 3 |
| BF/SB 7 | Bewegungs- und Wahrnehmungskompetenz | 3 | 4 |
| BF/SB 8 | Bewegungs- und Wahrnehmungskompetenz | 2 | 2 |
| BF/SB 9 | Bewegungs- und Wahrnehmungskompetenz | 2 | 2 |

Summen: Erprobungsstufe 27 Bereiche / 54 Erwartungen, Sek I 27 / 66.
Zusammen **54 Bereiche, 120 Erwartungen** — identisch mit dem Bestand.

**Wortlautvergleich gegen den Bestand.** Jede Abweichung auflisten, nicht
überschreiben. Ist die Liste leer, ist das hier das erwartete Ergebnis — anders
als bei Deutsch GOSt, wo die Quelle gewechselt hatte. Ist sie nicht leer, in
Schritt 2 zurückfallen und vorlegen.

**Eine neue Prüfung** in `tests-projektstunden.sh`, Rubrik „Fachdaten":
`art` ist gesetzt, wo `inhaltsfeld` gesetzt ist — oder die Prüfung wird anders
gefasst, falls sie ohne Datenbank nicht statisch geht. Dann stattdessen im
Seed prüfen, dass jede Zeile mit `inhaltsfeld` auch `art` mitführt.
Gegenprobe: in einer Zeile `art` entfernen → rot.

Erwartete Prüfungszahl: **50 + 1 = 51**.

## Schritt 5 — Dokumentation

- `CHANGELOG.md`: Eintrag mit Prüfungszahl vorher und nachher.
- `docs/ENTSCHEIDUNGEN.md`: nur, wenn unterwegs eine Entscheidung fiel, die
  über diesen Auftrag hinaus gilt.
- `docs/curricula/INDEX.md`: unverändert.

## Schritt 6 — Ausliefern

```bash
./tests-projektstunden.sh
./deploy.sh "feat(klp): Sport – Spalten teilbereich/art (E18) und Quellennachweis (E19)"
ssh hornse@halimede.uberspace.de \
  "mysql hornse_projektstunden < /home/hornse/projektstunden/sql/13_migration_klp_spalten.sql"
ssh hornse@halimede.uberspace.de \
  "mysql hornse_projektstunden < /home/hornse/projektstunden/sql/12_seed_sport_klp.sql"
```

Danach die Zählung aus Schritt 1 wiederholen, das Seed ein zweites Mal
einspielen und erneut zählen. Erwartet: dreimal dieselben Zahlen. Zusätzlich:

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SELECT art, COUNT(*) FROM kompetenzbereiche kb
JOIN kompetenzrahmen kr ON kr.id = kb.rahmen_id
WHERE kr.kuerzel = \"SPO_KLP\" GROUP BY art;'"
```

Erwartet: `inhaltsfeld 36`, `bewegungsfeld 18`.

Bei Rot in `tests-projektstunden.sh`: anhalten, nicht ausliefern.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

Zusätzlich: die Liste der Wortlautabweichungen gegenüber dem Bestand — auch
wenn sie leer ist —, und die nach E22 Regel 4 entschiedenen Trennfälle.

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung.
- Bei Unklarheit nachfragen statt vermuten.
