# Auftrag: Kompetenzbereiche als Baum

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

Die Tabelle `kompetenzbereiche` kann derzeit nur eine flache Liste je
Kompetenzrahmen abbilden. Die Kernlehrpläne verlangen mehr: bei Deutsch zwei
Ebenen (Inhaltsfeld, darunter Rezeption und Produktion), bei den modernen
Fremdsprachen drei (Funktionale kommunikative Kompetenz, darunter
Hörverstehen und sechs weitere, darunter die Erwartungen), bei Mathematik
zwei gleichrangige Bäume nebeneinander (prozessbezogen und inhaltsbezogen).

Dieser Auftrag legt die Struktur dafür an — und **nur** die Struktur. Es
werden keine Daten geschrieben, geändert oder gelöscht. Begründung in
`docs/ENTSCHEIDUNGEN.md`, E11.

## Schritt 0 — Voraussetzung prüfen

`./test.sh` muss existieren und grün sein. Falls nicht vorhanden: hier
anhalten und melden — dieser Auftrag setzt `docs/AUFTRAG-testskript.md`
voraus.

`git status` muss sauber sein.

Die höchste vergebene Migrationsnummer in `sql/` nachsehen, nicht annehmen.
Die neue Datei bekommt die nächste freie Nummer. Ist `08` bereits vergeben:
anhalten und melden, denn dann hat jemand anders am Schema gearbeitet.

## Schritt 1 — Ausgangsstand

```bash
./test.sh
```
Prüfungszahl notieren.

Struktur und Umfang der betroffenen Tabellen festhalten, damit nachher
belegbar ist, dass sich an den Daten nichts geändert hat:

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SHOW CREATE TABLE kompetenzbereiche\\G
SELECT COUNT(*) AS bereiche FROM kompetenzbereiche;
SELECT COUNT(*) AS kompetenzen FROM kompetenzen;'"
```

## Schritt 2 — entfällt

Die Designentscheidung ist gefallen (E11). Nicht neu aufrollen.

## Schritt 3 — Umsetzung

Neue Datei `sql/<nr>_migration_klp_baum.sql` mit drei zusätzlichen Spalten
in `kompetenzbereiche`:

- `parent_id INT UNSIGNED NULL` — Selbstreferenz auf `kompetenzbereiche.id`,
  Fremdschlüssel mit `ON DELETE CASCADE`. `NULL` heißt Wurzelknoten.
- `phase VARCHAR(40) NULL` — freier Text, kein ENUM. Vorgesehene Werte:
  `erprobungsstufe`, `sek1_erste_stufe`, `sek1_zweite_stufe`,
  `einfuehrungsphase`, `qualifikationsphase_gk`, `qualifikationsphase_lk`.
- `art VARCHAR(30) NULL` — was der Knoten ist. Vorgesehene Werte:
  `inhaltsfeld`, `kompetenzbereich`, `teilbereich`, `bewegungsfeld`.

Alle drei `NULL`-fähig und ohne Default, damit der bestehende Bestand
unverändert gültig bleibt.

**Robustheit — ausdrücklich zu bedenken:**
- Was darf nicht verlorengehen? Nichts. Die Migration ist additiv. Ein
  `DROP`, `DELETE` oder `TRUNCATE` darf in der Datei nicht vorkommen.
- Was passiert bei erneutem Ausführen? Die Migration muss ein zweites Mal
  laufen können, ohne abzubrechen. MariaDB 10.6 kennt kein
  `ADD COLUMN IF NOT EXISTS` in allen Fällen zuverlässig — prüfen, ob es
  auf dieser Version funktioniert, sonst über `information_schema` absichern.
- Was bei Fehlschlag? Die Datei so schreiben, dass sie entweder ganz oder
  gar nicht wirkt.

**Nicht dazu gehört:** Daten einfügen, Daten löschen, den
Kompetenzkatalog-Screen anfassen, die API ändern. Das sind eigene Aufträge.

## Schritt 4 — Tests

Zwei neue Prüfungen in `test.sh`:

1. Die Migrationsdatei enthält kein `DROP`, `DELETE`, `TRUNCATE`.
   Gegenprobe: Zeile mit `DELETE FROM` einfügen, Test muss rot werden.
2. Jede Datei in `sql/` hat eine eindeutige führende Nummer.
   Gegenprobe: Datei mit doppelter Nummer anlegen, Test muss rot werden.

Die erwartete Prüfungszahl wird genannt, nachdem feststeht, welche Prüfungen
geschrieben werden (REIHENREGELN 2) – nicht vorab geschätzt.

Migration gegen eine Kopie der Produktivdatenbank fahren, nicht gegen die
Produktivdatenbank:

```bash
ssh hornse@halimede.uberspace.de
mysqldump hornse_projektstunden > /tmp/vorher.sql
mysql -e "CREATE DATABASE IF NOT EXISTS hornse_klp_probe"
mysql hornse_klp_probe < /tmp/vorher.sql
mysql hornse_klp_probe < /home/hornse/projektstunden/sql/<nr>_migration_klp_baum.sql
mysql hornse_klp_probe < /home/hornse/projektstunden/sql/<nr>_migration_klp_baum.sql  # zweiter Lauf
mysql hornse_klp_probe -e "SHOW CREATE TABLE kompetenzbereiche\G"
mysql hornse_klp_probe -e "SELECT COUNT(*) FROM kompetenzbereiche; SELECT COUNT(*) FROM kompetenzen;"
```

Beide Zählungen müssen den Werten aus Schritt 1 entsprechen. Der zweite Lauf
muss ohne Fehler durchgehen. Danach:

```bash
mysql -e "DROP DATABASE hornse_klp_probe"
```

## Schritt 5 — Dokumentation

- `CHANGELOG.md`: Eintrag mit Prüfungszahl vorher und nachher.
- `docs/ENTSCHEIDUNGEN.md`: nur falls unterwegs eine Entscheidung fiel, die
  E11 ergänzt oder aufhebt.
- `CLAUDE.md`: nur falls eine Dauerregel dazukommt.

## Schritt 6 — Ausliefern

```bash
./test.sh
./deploy.sh "feat: Kompetenzbereiche als Baum – Schema (E11)"
```

Danach auf dem Server einspielen:

```bash
ssh hornse@halimede.uberspace.de \
  "mysql hornse_projektstunden < /home/hornse/projektstunden/sql/<nr>_migration_klp_baum.sql"
```

Bei Rot in `test.sh`: anhalten und melden, nicht ausliefern.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

Zusätzlich: die Zeilenzahlen von `kompetenzbereiche` und `kompetenzen` vor
und nach der Migration. Sie müssen gleich sein.

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung.
- Bei Unklarheit nachfragen statt vermuten.
