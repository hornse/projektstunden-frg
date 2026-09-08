# Auftrag: Verwaiste Rückmeldungen, Klassenzuordnung, Konfigurationsabgleich

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

Vier Befunde aus dem Teilnehmer-Auftrag, die dort gemeldet und nicht behoben
wurden. Die ersten drei hängen zusammen: Sie betreffen alle die Frage, wer zu
einer Werkstatt gehört.

**Befund 1 — `POST /api/rueckmeldung/{id}` prüft die Teilnahme nicht.**
`index.php:2101` schreibt für jede übergebene `schueler_id` eine Rückmeldung,
ohne nachzusehen, ob die Person Teilnehmerin der Werkstatt ist. Das ist die
Ursache von Befund 2, und es kann weiterhin Waisen erzeugen.

**Befund 2 — zwei verwaiste Rückmeldungen im Bestand.** In
`werkstatt_rueckmeldungen` stehen die Zeilen 3 und 4 zu Werkstatt 2
(„asdases"), beide mit `bewertung_stufe = 3`, ohne Freitext, für den Schüler
sichtbar, zur selben Sekunde erzeugt am 07.07.2026. Die zugehörigen Personen
sind keine Teilnehmer. Nach E34 wurden sie vorgelegt statt gelöscht.

**Befund 3 — `projekt_klassen` wird im PUT nie geschrieben.**
`$klasse_ids_put` (Zeile 821) dient nur dazu, `$klasse_id` abzuleiten. Die
Klassenzuordnung ist damit so unveränderlich, wie es die Teilnehmerliste vor
E35 war. Das schränkt die gerade gebaute Teilnehmerverwaltung ein: Die Auswahl
bietet nur Schüler der zugeordneten Klassen an, also lässt sich niemand aus
einer neuen Klasse aufnehmen.

**Befund 4 — die nicht versionierte Konfiguration driftet unbemerkt.**
`backend/config.php` lag lokal drei Generationen hinter dem Server: `secure`
auf `false`, `samesite` auf `Strict`, `require_auth` noch mit
`empty($_SESSION['benutzer_id'])`, kein WebUntis-Block, kein `typ`. Aufgefallen
ist es zufällig. Die Datei steht aus gutem Grund in `.gitignore` — geprüft
werden kann trotzdem ihre **Struktur**.

## Schritt 0 — Voraussetzungen prüfen

```bash
./tests-projektstunden.sh; echo "Exit: $?"
git status --short
git check-ignore -v backend/config.php
```

Erwartet: 59/59 grün, sauberer Arbeitsbaum, `config.php` ausgeschlossen.

Den Bestand nachsehen, statt ihn aus diesem Auftrag zu übernehmen:

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SELECT r.id, r.projekt_id, r.schueler_id, s.nachname, s.vorname,
       r.bewertung_stufe, LEFT(COALESCE(r.freitext,\"\"),40) AS freitext,
       r.sichtbar, r.erstellt_am
FROM werkstatt_rueckmeldungen r
LEFT JOIN schueler s ON s.id = r.schueler_id
WHERE NOT EXISTS (SELECT 1 FROM projekt_schueler ps
                  WHERE ps.projekt_id = r.projekt_id
                    AND ps.schueler_id = r.schueler_id);

SELECT p.id, p.name, p.klasse_id,
       GROUP_CONCAT(pk.klasse_id ORDER BY pk.klasse_id) AS projekt_klassen
FROM projekte p LEFT JOIN projekt_klassen pk ON pk.projekt_id = p.id
GROUP BY p.id ORDER BY p.id;'"
```

Sind es mehr oder weniger als zwei Waisen, oder tragen sie einen Freitext:
anhalten und melden. Die Entscheidung aus Schritt 2 hängt an ihrem Inhalt.

## Schritt 1 — Ausgangsstand

```bash
./tests-projektstunden.sh
```
Prüfungszahl notieren (erwartet 59).

Teilnehmer-, Bewertungs- und Rückmeldungszahlen je Werkstatt festhalten, wie im
vorigen Auftrag. Sie dürfen sich nur dort ändern, wo es beabsichtigt ist.

## Schritt 2 — Drei Entscheidungen, dann anhalten

**Erstens: Was tut `POST /rueckmeldung` mit einer Nicht-Teilnehmerin?**

- **Abweisen** mit Fehlermeldung. Sauber, aber ein Aufruf mit einer gemischten
  Liste — mehrere Schüler auf einmal, wie die Oberfläche es tut — scheitert
  dann vollständig, auch für die gültigen.
- **Die Ungültigen überspringen** und melden, wie viele. Der Aufruf gelingt für
  die Gültigen.
- **Abweisen, aber erst nachdem alle geprüft sind**, mit Nennung aller
  ungültigen IDs. Nichts wird geschrieben, der Aufrufer weiß, was zu
  korrigieren ist.

Vorschlag mit Begründung vorlegen. Wichtig ist, was die Oberfläche tatsächlich
schickt — nachsehen, nicht annehmen.

**Zweitens: Was geschieht mit den zwei Waisen?**

Nach E34 wird gelöscht, was verwaist ist — aber E34 regelt das Entfernen eines
Teilnehmers, nicht den Altbestand. Beide Zeilen tragen `bewertung_stufe = 3`
ohne Freitext, in einer Werkstatt namens „asdases". Vorschlag: löschen, in
derselben Änderung wie Befund 1, damit sie nicht wiederkommen.

Dagegen spräche, dass es eine Datenänderung ist, die niemand rückgängig machen
kann. Sie gehört deshalb in eine eigene Migration mit `mysqldump` davor, nicht
in ein `mysql -e` von Hand.

**Drittens: Wie behandelt der PUT die Klassenzuordnung?**

`schueler_ids` folgt seit E35 der `isset`-Form: fehlendes Feld lässt
unangetastet, leere Liste entfernt. Für `klasse_ids` läge dasselbe nahe — mit
einer Frage, die es bei Teilnehmern nicht gibt:

**Was, wenn eine Klasse entfernt wird, deren Schüler Teilnehmer sind?** Die
Teilnehmer hängen an `projekt_schueler`, nicht an der Klasse; sie blieben also
stehen und wären Teilnehmer ohne zugeordnete Klasse. Drei Möglichkeiten:
verweigern, die betroffenen Teilnehmer mitentfernen (mit Rückfrage wie E34),
oder zulassen und die Teilnehmer behalten.

Dazu: `projekte.klasse_id` wird aus `klasse_ids[0]` abgeleitet. Ändert sich die
erste Klasse, ändert sich dieser Wert — mit welcher Folge, ist zu prüfen. Wer
liest die Spalte?

Vorlegen und **anhalten**. Alle drei Entscheidungen gelten über diesen Auftrag
hinaus.

## Schritt 3a — Befund 1

Teilnahmeprüfung in `POST /api/rueckmeldung/{id}`, nach dem in Schritt 2
entschiedenen Weg.

## Schritt 3b — Befund 2

Eigene Migration. `mysqldump` davor — es ist die zweite nicht additive
Datenänderung überhaupt in diesem Projekt.

Das `DELETE` benennt die Zeilen über die Bedingung „nicht Teilnehmer", nicht
über feste IDs. Feste IDs träfen nach einem Neuaufbau der Tabelle andere
Zeilen.

## Schritt 3c — Befund 3

`klasse_ids` im PUT auswerten, nach dem in Schritt 2 entschiedenen Weg, und mit
derselben `isset`-Unterscheidung wie `schueler_ids` (E35).

**Reihenfolge beachten**, wie bei den Teilnehmern: Der Klassenblock muss stehen,
bevor etwas ihn liest. Wo genau, ist am Code zu klären, nicht zu raten.

Das Frontend braucht ein Klassenfeld im Bearbeiten-Screen — heute gibt es
`we-lehrer`, aber weder `we-klassen` noch `we-schueler` vor diesem Auftrag.
Ob die Teilnehmerauswahl beim Wechsel der Klassen neu geladen wird, ist die
Stelle, an der die Auswahl verlorengehen kann: `loadSchuelerForProjekt`
zeichnet neu, und die Menge außerhalb des DOM muss das überstehen. Das ist
derselbe Mechanismus wie E33 — beim Anlegen bereits gelöst, beim Bearbeiten
neu.

## Schritt 3d — Befund 4

Eine Prüfung, die vergleicht, ob jede Konstante und jede globale Variable aus
`backend/config.example.php` auch in `backend/config.php` vorkommt. **Nur
Namen, keine Werte** — das Datenbankpasswort darf nirgends auftauchen, weder in
der Ausgabe noch in einer Zwischendatei.

Fehlt `config.php`, gilt die Prüfung als **nicht bestanden**, nicht als
übersprungen (REIHENREGELN 2).

Was sie fängt: den Fall, der eben aufgetreten ist — `WEBUNTIS_ENABLED` und
`$WEBUNTIS_CONFIG` fehlten lokal vollständig. Was sie nicht fängt: abweichende
Werte wie `secure => false`. Das ist eine Einschränkung, die in den Bericht
gehört und nicht durch eine Wertprüfung ersetzt werden soll — dafür müsste die
Prüfung die Datei lesen und ihren Inhalt bewerten, und das ist bei einer Datei
mit Zugangsdaten der falsche Weg.

## Schritt 4 — Tests

Neu, alle statisch:

- **`POST /rueckmeldung` prüft die Teilnahme.** Gegenprobe: Prüfung entfernen →
  rot. Entwertung: Prüfung stehen lassen, aber wirkungslos machen → rot.
- **Der PUT-Zweig wertet `klasse_ids` aus**, mit `isset`, nicht mit `?? []`.
  Gegenproben wie bei `schueler_ids` im vorigen Auftrag.
- **`config.php` führt alle Konstanten aus `config.example.php`.**
  Gegenprobe: eine Konstante aus `config.php` entfernen → rot. Zweite
  Gegenprobe: `config.php` wegbewegen → rot mit dem Hinweis, dass die
  Voraussetzung fehlt, nicht grün.

Alle Ausdrücke arbeiten auf dem Quelltext ohne Kommentare — ein erklärender
Kommentar darf die Prüfung nicht grün machen (REIHENREGELN 2).

Erwartete Prüfungszahl: **59 + 3 = 62**, sofern alle drei statisch gehen.
Andernfalls die Zahl nennen, die sich ergibt, und warum.

**Von Hand zu prüfen und einzeln im Bericht zu belegen:**

1. Rückmeldung an einen Nicht-Teilnehmer — geschieht, was Schritt 2 entschied?
2. Rückmeldung an mehrere, davon einer kein Teilnehmer — was passiert mit den
   Gültigen?
3. Werkstatt bearbeiten, Klasse hinzufügen, speichern, erneut öffnen — ist sie
   da, und erscheinen deren Schüler in der Teilnehmerauswahl?
4. Werkstatt bearbeiten, Klassen unverändert lassen, speichern — sind alle noch
   da? (der Fall, der bei den Kompetenzen drei Monate lang Daten löschte)
5. Klasse entfernen, deren Schüler Teilnehmer sind — geschieht, was Schritt 2
   entschied?

## Schritt 5 — Dokumentation

- `CHANGELOG.md`: Prüfungszahl vorher und nachher.
- `docs/ENTSCHEIDUNGEN.md`: die drei Entscheidungen aus Schritt 2.
- `docs/BENUTZERHANDBUCH.md`: dass Klassen nachträglich änderbar sind, und was
  beim Entfernen geschieht.
- `docs/CONFIG.md`: die neue Strukturprüfung erwähnen — sie ist der Weg, eine
  abgedriftete Konfiguration zu bemerken.

## Schritt 6 — Ausliefern

```bash
./tests-projektstunden.sh
./deploy.sh "fix: Teilnahmeprüfung bei Rückmeldungen, Klassenzuordnung im PUT, Konfigurationsabgleich"
```

Dann auf dem Server: `mysqldump`, danach die Migration aus Schritt 3b, zweimal
einspielen, danach zählen.

Bei Rot in `tests-projektstunden.sh`: anhalten, nicht ausliefern.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

Zusätzlich: die fünf Handprüfungen einzeln, die Zahl der Waisen vorher und
nachher, und was die Strukturprüfung beim ersten Lauf gemeldet hat.

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung.
- Bei Unklarheit nachfragen statt vermuten.
