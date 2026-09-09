# Auftrag: Namen bei der Ausgabe maskieren

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

E40 hat den Freitext einer Rückmeldung bei der Ausgabe maskiert und dabei
gemeldet, dass dieselbe Bauform bei Namen offen bleibt: Der CSV-Import und die
WebUntis-Selbstanlage schreiben `vorname`, `nachname`, `bezeichnung` und
`klassenlehrer` ohne `clean()`, und rund 26 Zeilen in `frontend/app.js` geben
Namen roh in `innerHTML` aus.

Es ist die letzte bekannte Lücke dieser Art.

**Der Weg hinein ist enger als beim Freitext** — er verlangt Zugriff auf Schild
oder WebUntis, also auf die Schulverwaltung. **Die Fläche ist größer:** Namen
erscheinen in Schülerlisten, der Bewertungstabelle, dem Dashboard, den
Werkstattkarten und im Schülerportal. Sie sieht jeder, nicht nur der eine
Schüler, dem eine Rückmeldung gilt.

**Behoben wird auf der Ausgabeseite, nicht beim Schreiben.** Begründung
in Schritt 2 zu bestätigen oder zu widerlegen; sie steht dort, damit sie
geprüft und nicht übernommen wird.

## Schritt 0 — Voraussetzungen prüfen

```bash
./tests-projektstunden.sh; echo "Exit: $?"
git status --short
grep -c "escHtml" frontend/app.js
```

Erwartet: 65/65 grün, sauberer Arbeitsbaum, `escHtml` vorhanden (aus E40).

**Die Zahl 26 nachzählen, nicht übernehmen.** Sie stammt aus einem Bericht,
nicht aus einer Messung für diesen Auftrag. Ermitteln, an wie vielen Stellen
`vorname`, `nachname`, `bezeichnung` oder `klassenlehrer` in eine
Vorlagenzeichenkette eingebettet werden, und wie viele davon bereits `escHtml`
verwenden. Weicht die Zahl deutlich ab, im Bericht sagen warum.

## Schritt 1 — Ausgangsstand

```bash
./tests-projektstunden.sh
```
Prüfungszahl notieren (erwartet 65).

Festhalten, welche Felder heute wie behandelt werden — das ist die Grundlage
für den Eintrag in `CLAUDE.md` aus Schritt 5:

- Welche Felder werden beim Schreiben durch `clean()` geschickt?
- Welche nicht?
- Welche werden bei der Ausgabe maskiert?

## Schritt 2 — Zwei Fragen, dann anhalten

**Erstens: Trägt die Begründung für die Ausgabeseite?**

Vorgelegt wird sie hier, zu prüfen ist sie am Code:

Der CSV-Import vergleicht eingehende Namen mit den gespeicherten, um „neu /
aktualisiert / unverändert" zu unterscheiden. Schriebe er künftig
`O&#039;Brien` und verglichen den beim nächsten Lauf gegen `O'Brien` aus der
Datei, meldete er jeden Namen mit Apostroph dauerhaft als geändert — die
Vorschau würde unbrauchbar, und es fiele erst beim zweiten Import auf.

**Das ist zu belegen, nicht zu glauben.** Wie vergleicht der Import
tatsächlich? Über den vollen Namen, über die Schild-Nummer, feldweise? Wenn er
gar nicht auf Namen vergleicht, fällt dieses Argument weg — dann bleibt nur
noch, dass die 284 vorhandenen Namen roh in der Datenbank stehen und eine
Schreibprüfung sie nicht schützt.

Kommt die Prüfung zu einem anderen Ergebnis: berichten und anhalten.

**Zweitens: Wie erkennt die Prüfung eine übersehene Stelle?**

Das ist die eigentliche Arbeit. Bei 26 Stellen gegen eine ist die Gefahr nicht,
dass die Behebung nicht funktioniert, sondern dass eine Stelle übrig bleibt und
niemand es merkt.

Eine Prüfung, die zählt, wie oft `escHtml` vorkommt, taugt nicht — sie geht
grün, sobald irgendwo genug Aufrufe stehen. Gebraucht wird eine, die jede
Einbettung von `vorname`, `nachname`, `bezeichnung` oder `klassenlehrer` in
eine Vorlagenzeichenkette findet und verlangt, dass sie durch `escHtml` läuft.

Vorschlag mit Gegenprobe vorlegen: An welcher Form macht sie es fest, und was
passiert bei einer Schreibweise, die sie nicht kennt — etwa
`${s.vorname + ' ' + s.nachname}` oder eine Zwischenvariable? Eine Prüfung, die
solche Fälle stillschweigend übergeht, wiegt in falscher Sicherheit.

Wenn sich zeigt, dass keine tragfähige Prüfung möglich ist, ist das ein
Ergebnis. Dann berichten, statt eine schwache zu bauen.

Vorlegen und **anhalten**.

## Schritt 3 — Umsetzung

Erst nach Freigabe. `escHtml` an allen gefundenen Stellen.

**Nicht dazu gehört:**
- `clean()` beim CSV-Import oder bei der WebUntis-Selbstanlage ergänzen. Nach
  E40 macht die eine Hälfte ohne die andere es schlimmer.
- Die dreizehn Felder umstellen, die heute beim Schreiben maskiert werden. Sie
  stehen maskiert in der Datenbank; `escHtml` bei der Ausgabe erzeugte dort
  `&amp;amp;`.

**Was dabei zu bedenken ist:** Namen erscheinen nicht nur im Text, sondern auch
in Attributen — `title=`, `alt=`, `value=`. Dort gelten andere Regeln als im
Textinhalt. Ob `escHtml` beides abdeckt, ist zu prüfen; ein Anführungszeichen
in einem Attribut bricht aus, auch wenn `<` maskiert ist.

## Schritt 4 — Tests

Die Prüfung nach dem in Schritt 2 entschiedenen Zuschnitt, mit mindestens
diesen Gegenproben:

- Eine maskierte Stelle zurückbauen → rot.
- Eine neue rohe Einbettung hinzufügen → rot. Das ist die wichtigere: Sie
  belegt, dass die Prüfung künftige Stellen fängt und nicht nur die heutigen.
- Entwertung: `escHtml` durch eine Funktion ersetzen, die nichts tut → sollte
  rot werden. Geht das nicht statisch, im Bericht sagen warum.

**Von Hand zu prüfen und im Bericht zu belegen:** Ein Schüler mit einem Namen
aus `<script>alert(1)</script>` oder `O'Brien & Söhne` — in der Schülerliste,
in der Bewertungstabelle, im Dashboard und im Schülerportal. Nirgends darf
lebendes Markup ankommen, und `O'Brien & Söhne` muss überall genau so
dastehen, nicht als `O&#039;Brien &amp; Söhne`.

Der zweite Teil ist so wichtig wie der erste: Eine Maskierung, die zu viel tut,
zeigt jedem Lehrer verstümmelte Namen.

Der Prüfschüler wird danach entfernt.

Erwartete Prüfungszahl: **65 + 1**, sofern eine Prüfung genügt.

## Schritt 5 — Dokumentation

- `CHANGELOG.md`: Prüfungszahl vorher und nachher.
- `docs/ENTSCHEIDUNGEN.md`: die Entscheidung aus Schritt 2, und der Abschluss
  des in E40 gemeldeten offenen Punktes — nach REIHENREGELN 10 als neuer
  Eintrag.
- **`CLAUDE.md`:** welchem Verfahren ein neues Feld folgt. Nach diesem Auftrag
  gibt es zwei: dreizehn Felder maskiert in der Datenbank, `freitext` und die
  Namen maskiert bei der Ausgabe. Das ist tragfähig, solange es festgehalten
  ist — wer künftig ein Feld hinzufügt, muss wissen, welchem Weg es folgt, und
  dass beides zugleich `&amp;amp;` erzeugt.

## Schritt 6 — Ausliefern

```bash
./tests-projektstunden.sh
./deploy.sh "fix(sicherheit): Namen bei der Ausgabe maskiert (E40)"
```

Kein SQL. Nach dem Deploy die Handprüfung im Browser.

Bei Rot in `tests-projektstunden.sh`: anhalten, nicht ausliefern.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

Zusätzlich: die tatsächliche Zahl der Stellen gegenüber den vermuteten 26, das
Ergebnis der Prüfung zum CSV-Vergleich aus Schritt 2, und ob `escHtml` auch
für Attribute trägt.

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung.
- Bei Unklarheit nachfragen statt vermuten.
