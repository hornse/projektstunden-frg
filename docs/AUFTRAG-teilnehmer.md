# Auftrag: Teilnehmer einer Werkstatt ändern können

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

Drei Befunde an der Teilnehmerauswahl, gefunden beim Durchsehen vor dem
Produktivstart. Der erste ist eine fehlende Funktion, die anderen beiden
Bedienung und Darstellung.

**Befund 1 — Teilnehmer sind nach dem Anlegen unveränderlich.** Der
Bearbeiten-Screen führt `we-lehrer` (index.html:318), aber kein Schülerfeld.
`schueler_ids` kommt im Frontend nur in `projektSpeichern` vor (app.js:576) und
im Backend nur im POST-Zweig (index.php:713–762) sowie im
Rückmeldungs-Handler. Der PUT-Zweig fasst `projekt_schueler` nicht an.

Kein Datenverlust — anders als bei den Kompetenzen (E33) wird nichts
Leeres geschickt, sondern gar nichts. Aber wer im Betrieb einen Schüler
nachträgt oder herausnimmt, hat keinen Weg in der Oberfläche. Das Detail-Modal
markiert Teilnehmer nur als absolviert.

**Befund 2 — 284 Schüler in einem Mehrfachauswahlfeld.** `p-schueler`
(index.html:243) ist ein `<select multiple>` ohne Auswahlhilfe. Eine Werkstatt
mit einer ganzen Klasse verlangt 28 Klicks mit gedrückter Steuertaste, bei
mehreren Klassen entsprechend mehr.

**Befund 3 — die Überschrift „Neuen Schüler anlegen" klebt am Vornamenfeld.**
Sichtbar auf dem Schüler-Screen; sie sitzt offenbar im selben Rasterelement wie
das Formular statt darüber.

## Schritt 0 — Voraussetzungen prüfen

```bash
./tests-projektstunden.sh; echo "Exit: $?"
git status --short
```

Erwartet: 57/57 grün, sauberer Arbeitsbaum.

**Die Prämisse von Befund 1 nachprüfen, nicht übernehmen.** Der Schluss stützt
sich darauf, dass `schueler_ids` im PUT-Zweig nicht vorkommt. Der Zweig könnte
`projekt_schueler` unter einem anderen Namen anfassen:

```bash
awk '/PUT.*projekte|method === .PUT./,/^}/' backend/api/index.php | grep -n "projekt_schueler"
grep -n "projekt_schueler" backend/api/index.php
```

Fasst der PUT-Zweig `projekt_schueler` doch an, ist die Lage eine andere — dann
hier anhalten und melden.

Prüfen, was beim Entfernen eines Teilnehmers mit seinen Bewertungen geschieht:

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SHOW CREATE TABLE projekt_schueler_kompetenzen\G
SHOW CREATE TABLE werkstatt_rueckmeldungen\G'"
```

Die Fremdschlüssel entscheiden Schritt 2. Steht dort `ON DELETE CASCADE`,
nimmt das Entfernen eines Teilnehmers seine Bewertungen und Rückmeldungen mit.

## Schritt 1 — Ausgangsstand

```bash
./tests-projektstunden.sh
```
Prüfungszahl notieren (erwartet 57).

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SELECT p.id, p.name,
       COUNT(DISTINCT ps.schueler_id) AS teilnehmer,
       COUNT(DISTINCT psk.schueler_id) AS mit_kompetenzen,
       COUNT(DISTINCT r.schueler_id) AS mit_rueckmeldung
FROM projekte p
LEFT JOIN projekt_schueler ps ON ps.projekt_id = p.id
LEFT JOIN projekt_schueler_kompetenzen psk ON psk.projekt_id = p.id
LEFT JOIN werkstatt_rueckmeldungen r ON r.projekt_id = p.id
GROUP BY p.id ORDER BY p.id;'"
```

Diese Zahlen dürfen sich durch den Auftrag nicht ändern.

## Schritt 2 — Was beim Entfernen geschieht, dann anhalten

Das ist die Entscheidung, die den Auftrag trägt. Alles andere folgt daraus.

**Ein Teilnehmer, der Bewertungen oder eine Rückmeldung hat, darf nicht
stillschweigend verschwinden.** Drei Wege, mit dem Ergebnis aus Schritt 0
vorzulegen:

- **Verweigern.** Wer Bewertungen hat, lässt sich nicht entfernen; die
  Oberfläche sagt warum. Streng, verlangt aber einen Weg für den Fall, dass
  jemand versehentlich zugeordnet und schon bewertet wurde.
- **Warnen und mitlöschen.** Rückfrage mit Nennung dessen, was verloren geht,
  dann Löschen. Bequem, aber unwiederbringlich.
- **Entfernen ohne Löschen.** Die Zuordnung fällt weg, Bewertungen bleiben als
  verwaiste Zeilen. Verlockend, aber es entstünden Daten ohne Bezug — und
  spätere Auswertungen müssten sie kennen.

Ich neige zum ersten, will aber die Fremdschlüssel sehen, bevor ich entscheide.

**Zweite Frage:** Ersetzt das Speichern die Teilnehmerliste vollständig, wie es
`lehrer_ids` und `klasse_ids` tun, oder wird nur die Differenz angewandt? Bei
vollständigem Ersetzen genügt ein vergessenes Feld, um alle zu entfernen — das
war der Mechanismus hinter E33.

**Dritte Frage:** Gilt die Prüfung auf `max_schueler` auch beim Bearbeiten? Im
POST-Zweig steht sie (index.php:714). Im PUT wäre sie neu.

Vorlegen und **anhalten**.

## Schritt 3a — Befund 1

Schülerfeld im Bearbeiten-Screen, nach dem Muster des Anlegen-Screens, mit den
Teilnehmern vorbelegt. `werkstattEditSpeichern` schickt `schueler_ids`, der
PUT-Zweig wertet sie aus.

**Die Vorbelegung ist die gefährliche Stelle.** Bei den Kompetenzen hat genau
dort ein Selektor drei Monate lang nicht getroffen (E33), ohne dass es auffiel,
weil eine leere Liste wie ein gültiger Wert aussah. Hier gilt dasselbe: Wenn
die Vorbelegung fehlschlägt und das Speichern die Liste ersetzt, sind alle
Teilnehmer weg.

Zwei Vorkehrungen: Die Auswahl lebt außerhalb des DOM, wie in E33 entschieden.
Und der PUT-Zweig unterscheidet **fehlendes Feld** von **leerer Liste** — ein
fehlendes `schueler_ids` lässt die Teilnehmer unangetastet, eine ausdrücklich
leere Liste entfernt sie. Sonst genügt ein Aufruf von außen, der das Feld
vergisst, um eine Werkstatt zu leeren.

## Schritt 3b — Befund 2

Auswahlhilfe bei der Teilnehmerauswahl, in beiden Ansichten. Vorschlag: „Alle
hinzufügen" und „Auswahl aufheben", dazu je gewählter Klasse eine Schaltfläche,
die deren Schüler hinzufügt — das ist der häufige Fall.

Ob das Mehrfachauswahlfeld bleibt oder Kacheln mit Häkchen daraus werden, ist
eine Entscheidung des Laufs und gehört in den Bericht. Kacheln wären
einheitlich mit der Kompetenzauswahl, sind aber mehr Arbeit; bei 284 Einträgen
ist die Frage der Bedienbarkeit ernst.

Die Prüfung auf `max_schueler` muss auch für die Auswahlhilfe greifen.

## Schritt 3c — Befund 3

Überschrift und Formular trennen. Kosmetik, aber sie sieht nach Fehler aus.

## Schritt 4 — Tests

Statisch prüfbar und deshalb ins Testskript:

- **Der PUT-Zweig wertet `schueler_ids` aus.** Gegenprobe: die Auswertung
  entfernen → rot. Das ist die Prüfung, die Befund 1 künftig fängt.
- **Fehlendes Feld und leere Liste werden unterschieden.** Ein
  `?? []` allein genügt nicht — es macht aus „nicht geschickt" ein „leer".
  Gegenprobe: auf `?? []` zurückbauen → rot.

Erwartete Prüfungszahl: **57 + 2 = 59**. Geht eine nicht statisch, die Zahl
nennen, die sich ergibt, und warum.

**Von Hand zu prüfen und einzeln im Bericht zu belegen:**

1. Werkstatt bearbeiten, nichts an den Teilnehmern ändern, speichern —
   sind alle noch da?
2. Einen Teilnehmer hinzufügen, speichern, erneut öffnen — ist er da?
3. Einen Teilnehmer ohne Bewertungen entfernen, speichern — ist er weg?
4. Einen Teilnehmer **mit** Bewertungen entfernen — geschieht, was in Schritt 2
   entschieden wurde?
5. „Alle hinzufügen" bei einer Werkstatt mit `max_schueler` unter der
   Schülerzahl — greift die Prüfung?

Prüfung 1 ist die wichtigste. Sie ist der Fall, der bei den Kompetenzen drei
Monate lang stillschweigend Daten gelöscht hat.

## Schritt 5 — Dokumentation

- `CHANGELOG.md`: Prüfungszahl vorher und nachher.
- `docs/ENTSCHEIDUNGEN.md`: die Entscheidung aus Schritt 2 — was beim Entfernen
  eines bewerteten Teilnehmers geschieht. Sie gilt über diesen Auftrag hinaus.
- `docs/BENUTZERHANDBUCH.md`: dass Teilnehmer nachträglich änderbar sind, und
  was beim Entfernen geschieht.

## Schritt 6 — Ausliefern

```bash
./tests-projektstunden.sh
./deploy.sh "feat(werkstatt): Teilnehmer nachträglich änderbar, Auswahlhilfe"
```

Kein SQL. Nach dem Deploy die fünf Handprüfungen im Browser.

Danach die Zählung aus Schritt 1 wiederholen — unverändert.

Bei Rot in `tests-projektstunden.sh`: anhalten, nicht ausliefern.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

Zusätzlich: die fünf Handprüfungen einzeln, und die Teilnehmerzahlen je
Werkstatt vorher und nachher.

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung.
- Bei Unklarheit nachfragen statt vermuten.
