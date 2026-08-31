# Auftrag: Testskript anlegen

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

Ein Skript `test.sh` im Wurzelverzeichnis, das ohne Netzzugang und ohne
laufenden Server prüft, ob die Fallen aus `CLAUDE.md` wieder aufgestellt
wurden. Es geht nicht um fachliche Tests der Anwendung, sondern um die
Handvoll Stellen, an denen dieses Projekt schon einmal stundenlang
festgehangen hat. Das Skript soll bei jedem Deploy laufen können und in
Sekunden fertig sein.

Ein zweiter, getrennter Teil prüft gegen den laufenden Server. Der braucht
Zugangsdaten und läuft nur auf Zuruf.

## Schritt 0 — Voraussetzung prüfen

Prüfen, ob im Wurzelverzeichnis bereits ein Testskript existiert — unter
irgendeinem Namen (`test.sh`, `tests/`, `check.sh`, `Makefile`). Nachsehen,
nicht annehmen. Falls eines existiert: hier anhalten und melden, was es
prüft, statt ein zweites danebenzulegen.

`git status` muss sauber sein. Falls nicht: anhalten und melden.

## Schritt 1 — Ausgangsstand

Es gibt keinen. Das ist der Grund für diesen Auftrag. Notieren, welche
Dateien im Wurzelverzeichnis liegen, damit später nachvollziehbar ist, was
dazugekommen ist.

## Schritt 2 — Analyse, und dann anhalten

Aus `CLAUDE.md`, Abschnitt „Regeln, die schon einmal Schaden angerichtet
haben", eine Liste ableiten: welche dieser Regeln lassen sich statisch aus
den Dateien prüfen, welche nur gegen den laufenden Server, welche gar nicht?

Für jede statisch prüfbare Regel den konkreten Prüfausdruck vorschlagen —
und dazu, wie die **Gegenprobe** aussieht, also welche Änderung an welcher
Datei den Test rot machen muss.

Ein Beispiel für die erwartete Genauigkeit: Die Regel „`session_name()` steht
vor jedem `require`" lässt sich nicht daran prüfen, ob `session_name` in der
Datei vorkommt. Geprüft werden muss die **Reihenfolge** — die Zeilennummer des
ersten `require` gegen die Zeilennummer von `session_name`. Ein Test, der nur
das Vorkommen prüft, geht auch dann grün, wenn der Aufruf am Ende der Datei
steht, und wäre wertlos.

Dann anhalten und berichten. Nicht bauen. Ich entscheide, welche Prüfungen
hineinkommen.

## Schritt 3 — Umsetzung

Erst nach meiner Freigabe.

- Das Skript endet mit Exit-Code 1, sobald eine Prüfung fehlschlägt.
- Es gibt am Ende die Zahl der bestandenen Prüfungen aus, in der Form
  `OK: n/m`.
- Eine Prüfung, deren Voraussetzung fehlt — die Datei existiert nicht, das
  Werkzeug fehlt — gilt **nicht** als bestanden. Sie sagt es und zählt als
  Fehlschlag.
- Kein `|| true`, außer um den echten Erfolgsfall abzufangen.
- Der Serverteil liegt in einer eigenen Datei oder hinter einem Schalter und
  läuft nicht mit, wenn nur `./test.sh` aufgerufen wird.

Nicht dazu gehört: fachliche Tests der Werkstatt-, Bewertungs- oder
Kompetenzlogik. Auch nicht: ein Testframework installieren. Bash reicht.

## Schritt 4 — Tests

Jede Prüfung braucht ihre Gegenprobe. Vorgehen je Prüfung: Fehlerfall in
einer Kopie der Datei herstellen, Skript laufen lassen, Rotwerden belegen,
Kopie zurücknehmen. Das Ergebnis dieser Gegenproben gehört in den Bericht —
eine Prüfung ohne belegte Gegenprobe zählt nicht.

Erwartete Prüfungszahl: ergibt sich aus Schritt 2 und wird dort festgelegt.

## Schritt 5 — Dokumentation

- `CLAUDE.md`, Abschnitt „Vor jeder Auslieferung wirklich prüfen": den
  Hinweis „Dieses Projekt hat kein Testskript" entfernen und durch den
  Aufruf ersetzen.
- `CHANGELOG.md`: Eintrag mit der Prüfungszahl, damit später vergleichbar
  ist, ob sie gefallen ist.
- `docs/ENTSCHEIDUNGEN.md`: nur, falls in Schritt 2 eine Entscheidung fiel,
  die später jemanden wundern könnte.

## Schritt 6 — Ausliefern

```bash
./test.sh          # muss grün sein
./deploy.sh "test: Prüfskript für die bekannten Fallstricke"
```

Bei Rot: anhalten und melden.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung.
- Bei Unklarheit nachfragen statt vermuten.
