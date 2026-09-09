# Auftrag: Eine Antwort auf „wer gehört zur Werkstatt"

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

E39 hat festgehalten, dass drei Ansichten dieselbe Frage verschieden
beantworten, und die Zusammenführung als fachliche Entscheidung ausgewiesen.
Diese Entscheidung ist gefallen:

**`projekt_schueler` ist die Antwort. Die anderen beiden sind abgeleitet.**
`projekt_klassen` sagt, woher Kandidaten kommen. `projekt_schueler_kompetenzen`
sagt, was der Werkstatt zugewiesen wurde. Keines von beiden sagt, wer dabei ist.

Vor E35 war das anders vertretbar: Solange Teilnehmer nach dem Anlegen
unveränderlich waren, musste das Details-Modal die Klassenschüler zeigen, weil
es sonst keinen Weg gab, jemanden nachzutragen. Diesen Grund gibt es nicht mehr.

Drei Befunde folgen daraus.

**Befund 1 — Das Details-Modal listet alle Schüler aller zugeordneten Klassen.**
Bei Werkstatt 4 waren es zuletzt 189 Namen für 12 Teilnehmer. Nicht-Teilnehmer
erscheinen unangehakt und sehen aus wie Teilnehmer, die noch nicht absolviert
haben.

**Befund 2 — Ein Haken bei einem Nicht-Teilnehmer meldet Erfolg und tut
nichts.** `PUT /api/werkstatt/{id}/abschluss` ist ein reines `UPDATE` ohne
`INSERT`. Es trifft null Zeilen, antwortet `{"ok":true}`, und der Haken
verschwindet erst beim Neuladen. Das ist derselbe Fehlermodus wie bei
`POST /rueckmeldung` vor E36 — dort abweisen, hier melden statt schweigen.

**Befund 3 — Die Bewertungstabelle hängt an
`projekt_schueler_kompetenzen`.** Ein Teilnehmer ohne zugewiesene Kompetenzen
erscheint dort nicht und kann keine Rückmeldung bekommen. Werkstatt 2 hat zwei
Teilnehmer, null Kompetenzzeilen und zwei Rückmeldungen — die Ansicht zeigt
nichts, obwohl beides existiert.

## Schritt 0 — Voraussetzungen prüfen

```bash
./tests-projektstunden.sh; echo "Exit: $?"
git status --short
```

Erwartet: 66/66 grün, sauberer Arbeitsbaum.

Den Bestand messen, statt die Zahlen aus diesem Auftrag zu übernehmen — sie
stammen aus einem Bericht von vorgestern, und die Klassenzuordnung hat sich
seither geändert:

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SELECT p.id, p.name,
       (SELECT COUNT(*) FROM projekt_schueler ps WHERE ps.projekt_id = p.id) AS teilnehmer,
       (SELECT COUNT(DISTINCT s.id) FROM projekt_klassen pk
          JOIN schueler s ON s.klasse_id = pk.klasse_id AND s.aktiv = 1
         WHERE pk.projekt_id = p.id) AS im_modal_gelistet,
       (SELECT COUNT(DISTINCT psk.schueler_id) FROM projekt_schueler_kompetenzen psk
         WHERE psk.projekt_id = p.id) AS mit_kompetenzen,
       (SELECT COUNT(*) FROM werkstatt_rueckmeldungen r WHERE r.projekt_id = p.id) AS rueckmeldungen
FROM projekte p ORDER BY p.id;'"
```

Die Spalte `im_modal_gelistet` gegenüber `teilnehmer` ist Befund 1 in Zahlen.

## Schritt 1 — Ausgangsstand

```bash
./tests-projektstunden.sh
```
Prüfungszahl notieren (erwartet 66).

Die Zahlen aus Schritt 0 festhalten. Nach diesem Auftrag müssen `teilnehmer`,
`mit_kompetenzen` und `rueckmeldungen` unverändert sein — geändert wird nur,
was angezeigt und was abgewiesen wird.

## Schritt 2 — Drei Fragen, dann anhalten

Die fachliche Entscheidung steht. Offen ist, wie sie umzusetzen ist.

**Erstens: Wie unterscheidet `GET /api/werkstatt/{id}/schueler` seine zwei
Zwecke?**

Der Endpunkt speist heute zwei Ansichten mit verschiedenem Bedarf. Das
Details-Modal braucht die Teilnehmer. Die Teilnehmerauswahl im Bearbeiten-Screen
braucht Kandidaten — nach E38 die Vereinigung aus „Schüler der zugeordneten
Klassen" und „vorhandene Teilnehmer", damit ein Teilnehmer aus einer entfernten
Klasse nicht verschwindet.

Drei Wege: ein Abfrageparameter, zwei Endpunkte, oder ein Feld je Zeile, das
sagt, ob die Person Teilnehmerin ist, und die Ansicht filtert. Vorschlag mit
Begründung vorlegen. **Nicht nebenbei ändern**, was E38 dort eingebaut hat — die
Vereinigung hat einen Grund und eine Gegenprobe.

**Zweitens: Was zeigt die Bewertungstabelle bei einem Teilnehmer ohne
zugewiesene Kompetenzen?**

Er muss erscheinen, sonst ist er nicht bewertbar und bekommt keine Rückmeldung.
Aber eine Zeile ohne Spalten ist auch keine Auskunft. Zu klären: Erscheint er
mit einem Hinweis? Wird die Tabelle überhaupt gezeigt, wenn der Werkstatt keine
Kompetenzen zugewiesen sind, oder tritt an ihre Stelle ein Hinweis mit dem Weg
dorthin?

Dabei zu bedenken: Die Empfängerliste für Rückmeldungen stammt heute aus
derselben Abfrage. Nach E36 dürfen Rückmeldungen nur an Teilnehmer gehen — die
Liste muss also ohnehin auf `projekt_schueler` umgestellt werden, sonst kann
die Oberfläche jemanden anbieten, den das Backend abweist.

**Drittens: Was tut `PUT /abschluss` bei einem Nicht-Teilnehmer?**

Nach der Umstellung kann die Oberfläche den Fall nicht mehr herstellen — das
Modal zeigt nur Teilnehmer. Die Lücke bleibt für Direktaufrufe. E36 hat für den
gleichgelagerten Fall entschieden: prüfen, abweisen, nichts schreiben. Ob
dasselbe hier gilt oder ob eine `UPDATE`-Anweisung, die null Zeilen trifft,
schon durch die Prüfung der betroffenen Zeilen abgedeckt wäre, ist vorzulegen.

Vorlegen und **anhalten**.

## Schritt 3 — Umsetzung

Erst nach Freigabe.

**Was nicht dazugehört:** Die Tabellen zusammenlegen, `projekt_klassen`
abschaffen, das Datenmodell ändern. Es bleibt bei drei Tabellen mit drei
Aufgaben; geändert wird, welche Ansicht welche befragt.

Ebenfalls nicht: die Teilnehmerauswahl im Bearbeiten-Screen. Sie ist nach E35
und E38 richtig und hat ihre Gegenproben.

## Schritt 4 — Tests

Statisch prüfbar:

- **`PUT /abschluss` prüft die Teilnahme.** Gegenprobe: Prüfung entfernen → rot.
  Entwertung: Prüfung stehen lassen, wirkungslos machen → rot.
- **Die Bewertungstabelle liest `projekt_schueler`**, nicht allein
  `projekt_schueler_kompetenzen`. Ob das statisch geht, ist im Bericht zu
  begründen; geht es nicht, keine schwache Prüfung bauen.

Erwartete Prüfungszahl: **66 + 1 oder + 2**, je nach Ausgang. Die Zahl nennen,
die sich ergibt.

**Von Hand zu prüfen und einzeln im Bericht zu belegen:**

1. Details-Modal bei der Werkstatt mit den meisten Klassenschülern — wie viele
   Namen vorher, wie viele nachher? Die Nachher-Zahl muss die Teilnehmerzahl
   sein.
2. Einen Teilnehmer als absolviert markieren, Modal schließen, erneut öffnen —
   ist der Haken da? Das ist die Funktion, die nicht kaputtgehen darf.
3. Werkstatt 2 (zwei Teilnehmer, null Kompetenzzeilen, zwei Rückmeldungen):
   Erscheinen die Teilnehmer in der Bewertungsansicht? Sind die beiden
   vorhandenen Rückmeldungen sichtbar? Lässt sich eine neue schreiben?
4. Werkstatt 4 (zwölf Teilnehmer, 228 Kompetenzzeilen): unverändert bewertbar,
   alle zwölf in der Tabelle?
5. `PUT /abschluss` für einen Nicht-Teilnehmer, direkt aufgerufen — geschieht,
   was Schritt 2 entschied?

Prüfung 3 ist die aussagekräftigste: Sie ist der Fall, den die heutige Ansicht
gar nicht darstellen kann.

## Schritt 5 — Dokumentation

- `CHANGELOG.md`: Prüfungszahl vorher und nachher.
- `docs/ENTSCHEIDUNGEN.md`: ein Eintrag, der E39 abschließt — welche Tabelle
  welche Frage beantwortet, und welche Ansicht welche befragt. Das ist die
  Auskunft, die beim nächsten Anbau gebraucht wird.
- `docs/BENUTZERHANDBUCH.md`: dass im Details-Modal nur Teilnehmer stehen und
  wo Teilnehmer geändert werden.

## Schritt 6 — Ausliefern

```bash
./tests-projektstunden.sh
./deploy.sh "fix: Teilnehmer sind, wer in projekt_schueler steht (E39)"
```

Kein SQL. Nach dem Deploy die fünf Handprüfungen.

Danach die Zählung aus Schritt 0 wiederholen: `teilnehmer`, `mit_kompetenzen`
und `rueckmeldungen` unverändert.

Bei Rot: anhalten, nicht ausliefern.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

Zusätzlich: die Tabelle aus Schritt 0 vorher und nachher, und die fünf
Handprüfungen einzeln.

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung.
- Bei Unklarheit nachfragen statt vermuten.
