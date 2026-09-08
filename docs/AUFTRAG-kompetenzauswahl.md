# Auftrag: Kompetenzauswahl vor dem Produktivstart

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

Drei Befunde am Frontend, alle beim Durchsehen vor dem Produktivstart gefunden,
alle in `frontend/app.js` und `frontend/index.html`. Kein SQL, keine Migration,
keine Änderung an den Fachdaten.

**Befund 1 — `sek1_uebergreifend` fehlt in `KAT_PHASEN`.** Die Liste in
`app.js:1180` führt sechs Phasen. Migration 14 hat einen siebten ENUM-Wert
angelegt, das Frontend kennt ihn nicht. `phasenPresent` in Zeile 1209 filtert
`KAT_PHASEN` gegen die vorkommenden Werte — ein unbekannter Wert fällt still
weg. Betroffen sind bei `DEU_KLP` drei Bereiche mit 21 Kompetenzerwartungen:
kein Tab, kein Etikett, über den Filter nicht erreichbar.

**Befund 2 — zwei Auswahlfelder erlauben widersprüchliche Kombinationen.**
`kat-rahmen` und `kat-fach` (Zeilen 1201/1202) sind unabhängige Und-Filter.
Belegt: Rahmen „Sport KLP NRW G9 Sek I" zusammen mit Fach „Spanisch" ergibt
„Keine Kompetenzen gefunden." Das Fachfeld listet zudem alle Fächer auf,
obwohl nur vier Rahmen befüllt sind — Mathematik, Physik, Latein und die
übrigen führen zu einer leeren Ansicht.

**Befund 3 — kein Phasenfilter beim Anlegen einer Werkstatt.**
`renderKompBereichListWe` (ab Zeile 866) filtert nach Rahmen und Fach, nicht
nach Phase. Bei Deutsch erscheinen 226 gleichrangige Kacheln in 28 Blöcken,
von der Erprobungsstufe bis zur Qualifikationsphase Leistungskurs. Der MKR ist
mit 24 Elternkompetenzen und 82 aufklappbaren Kindern bedienbar, Deutsch nicht.
Belegt: `DEU_KLP` hat 226 Kompetenzen ohne `eltern_kompetenz_id`.

## Schritt 0 — Voraussetzungen prüfen

```bash
./tests-projektstunden.sh; echo "Exit: $?"
git status --short
```

Erwartet: 55/55 grün, sauberer Arbeitsbaum.

Den Bestand nachsehen, statt ihn anzunehmen:

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SELECT kr.kuerzel, kr.name, f.name AS fach, kb.phase, COUNT(k.id) AS kompetenzen
FROM kompetenzrahmen kr
LEFT JOIN faecher f ON f.id = kr.fach_id
JOIN kompetenzbereiche kb ON kb.rahmen_id = kr.id
LEFT JOIN kompetenzen k ON k.bereich_id = kb.id
GROUP BY kr.id, kb.phase ORDER BY kr.kuerzel, kb.phase;'"
```

Erwartet: vier Rahmen mit Kompetenzen, `MKR` mit `phase = NULL`,
`DEU_KLP` unter anderem mit `sek1_uebergreifend`.

## Schritt 1 — Ausgangsstand

```bash
./tests-projektstunden.sh
```
Prüfungszahl notieren (erwartet 55).

Vor der Änderung festhalten, wie viele Kacheln die Werkstatt-Auswahl heute
zeigt — je Rahmen. Die Zahl gehört in den Bericht, damit die Wirkung von
Befund 3 belegbar ist und nicht behauptet.

## Schritt 2 — Zuschnitt der Rahmenauswahl, dann anhalten

Befund 1 und 3 sind entschieden (siehe Schritt 3a und 3c). Bei Befund 2 ist der
Weg vorgegeben, der Zuschnitt nicht.

**Vorgegeben:** ein Auswahlfeld statt zwei, mit `<optgroup>` je Fach:

```
Deutsch
  Deutsch KLP NRW G9 Sek I
  Deutsch KLP GOSt
Sport
  Sport KLP NRW G9 Sek I
Fächerübergreifend
  Medienkompetenzrahmen NRW
```

**Offen und vorzulegen:**

- Werden nur befüllte Rahmen aufgeführt, oder alle 38 mit einem Hinweis? Ein
  leerer Rahmen ist heute nicht unterscheidbar von einem, den es nicht gibt.
  Bei „nur befüllte": woher kommt die Auskunft, ob ein Rahmen befüllt ist —
  liefert die API sie schon, oder braucht es eine Zählung?
- Wohin gehört der MKR? Er hat kein Fach (`fach_id IS NULL`). Vorschlag
  „Fächerübergreifend" als eigene Gruppe — bestätigen oder widersprechen.
- Was passiert mit der bestehenden Fach-Filterung in `renderKompBereichListWe`?
  Dort wird nach `fach_kuerzel` gefiltert (Zeile 871–874). Bleibt das, oder
  wird es durch dieselbe Rahmenauswahl ersetzt? **Nicht nebenbei ändern** —
  wenn es bleibt, sagen warum.

Vorlegen und **anhalten**. Ich entscheide, bevor gebaut wird.

## Schritt 3a — Befund 1

`sek1_uebergreifend` in `KAT_PHASEN` aufnehmen, zwischen `erprobungsstufe` und
`erste_stufe` — die Reihenfolge der Liste bestimmt die Reihenfolge der Tabs,
und der Wert gilt für beide Stufen der Sekundarstufe I.

Label und Farbe: Vorschlag `Sek I übergreifend`. Die Farbe muss sich von den
sechs vorhandenen unterscheiden; welche, ist eine Entscheidung des Laufs und
gehört in den Bericht.

**Der eigentliche Fehler ist nicht die fehlende Zeile, sondern dass sie still
fehlt.** Ein Phasenwert aus der Datenbank, den `KAT_PHASEN` nicht kennt,
verschwindet ohne Meldung. Das ist zu beheben: Bei einem unbekannten Wert
gehört eine Meldung auf die Konsole und der Wert in die Anzeige, notfalls ohne
Farbe. Sonst wiederholt sich der Fall beim nächsten ENUM-Zugang.

## Schritt 3b — Befund 2

Nach dem in Schritt 2 entschiedenen Zuschnitt. `kat-fach` entfällt,
`kat-rahmen` wird zur gruppierten Liste.

**Nicht dazu:** die Auswahl an anderen Stellen der Anwendung ändern. Wenn
`renderRahmenTabs` oder `renderRahmenTabsWe` dieselbe Logik führen, bleiben sie
unangetastet und werden im Bericht genannt.

## Schritt 3c — Befund 3

Phasen-Tabs in `renderKompBereichListWe`, wie im Katalog. Dieselbe Bauform,
damit die Bedienung an beiden Stellen gleich ist.

**Ausdrücklich nicht:** die Phase aus den Jahrgängen der beteiligten Klassen
ableiten. Das führte eine Zuordnung Jahrgang → Phase ein, die niemand
beschlossen hat, und sie bräuchte sofort Ausnahmen für jahrgangsübergreifende
Werkstätten und für `sek1_uebergreifend`, das für zwei Stufen zugleich gilt.

Die Vorauswahl ist „Alle Phasen", wie im Katalog. Wer eine Werkstatt für
Jahrgang 6 anlegt, schaltet auf Erprobungsstufe.

**Beim Bearbeiten einer bestehenden Werkstatt** dürfen bereits gewählte
Kompetenzen nicht verlorengehen, wenn ihre Phase gerade ausgeblendet ist. Das
ist die Stelle, an der ein Filter Daten zerstören kann: `we-komp-cb` sammelt
die Häkchen aus dem DOM, und was nicht gezeichnet ist, hat kein Häkchen. Wie
das gelöst wird — Auswahl außerhalb des DOM halten, oder alle Phasen zeichnen
und nur verbergen —, gehört in den Bericht.

## Schritt 4 — Tests

Die drei Befunde sind Anzeigefehler; sie lassen sich nicht vollständig statisch
prüfen. Prüfbar ist der Teil, der es ist:

- **`KAT_PHASEN` deckt alle ENUM-Werte ab.** Die Werte aus
  `sql/14_migration_phase_sek1uebergreifend.sql` beziehungsweise aus der
  Spaltendefinition gegen die Schlüssel in `app.js:1180` halten. Gegenprobe:
  einen Eintrag aus `KAT_PHASEN` entfernen → rot.
  Das ist die Prüfung, die Befund 1 künftig fängt.
- **`kat-fach` kommt in `app.js` und `index.html` nicht mehr vor.**
  Gegenprobe: die Zeichenfolge wieder einfügen → rot.

Erwartete Prüfungszahl: **55 + 2 = 57**. Geht eine der beiden nicht statisch,
die Zahl nennen, die sich ergibt, und warum.

**Von Hand zu prüfen und im Bericht zu belegen**, weil kein Testskript es
sieht:

1. Katalog, Deutsch Sek I: Erscheint ein Tab `Sek I übergreifend`, und zeigt er
   die 21 Kompetenzerwartungen?
2. Katalog: Ist eine widersprüchliche Kombination noch wählbar?
3. Werkstatt anlegen, Deutsch: Wie viele Kacheln bei „Alle Phasen", wie viele
   bei „Erprobungsstufe"?
4. Werkstatt bearbeiten: Kompetenzen aus zwei Phasen wählen, Phase umschalten,
   speichern — sind beide noch da?

Punkt 4 ist der wichtigste. Er prüft die Stelle, an der ein Anzeigefilter Daten
löschen kann.

## Schritt 5 — Dokumentation

- `CHANGELOG.md`: Prüfungszahl vorher und nachher.
- `docs/ENTSCHEIDUNGEN.md`: die Entscheidung aus Schritt 2, und die aus
  Schritt 3c, wie die Auswahl über einen Phasenwechsel hinweg erhalten bleibt —
  beide gelten über diesen Auftrag hinaus.
- `docs/BENUTZERHANDBUCH.md`: die Phasen-Tabs beim Anlegen einer Werkstatt
  aufnehmen. Sie ändern die Bedienung an der Stelle, an der Lernbegleiter am
  häufigsten arbeiten.

## Schritt 6 — Ausliefern

```bash
./tests-projektstunden.sh
./deploy.sh "fix(frontend): Phasenfilter in der Werkstatt-Auswahl, sek1_uebergreifend, Rahmenauswahl"
```

Kein SQL, keine Datenbankänderung. Nach dem Deploy die vier Handprüfungen aus
Schritt 4 durchführen — im Browser, nicht per curl.

Bei Rot in `tests-projektstunden.sh`: anhalten, nicht ausliefern.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

Zusätzlich: die Kachelzahl je Rahmen vorher und nachher, das Ergebnis der vier
Handprüfungen einzeln, und die Farbe, die `sek1_uebergreifend` bekommen hat.

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung.
- Bei Unklarheit nachfragen statt vermuten.
