# Auftrag: Kompetenzbereiche auf den Baum umformen

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

E29 hat entschieden, dass `kompetenzbereiche` eine Selbstreferenz bekommt.
Dieser Auftrag setzt das um — für die vier vorhandenen Rahmen und in den drei
vorhandenen Erzeugern.

Vier Schritte, jeder mit eigener Prüfung:

1. Migration 15 legt `parent_id` an. Additiv.
2. Die drei Erzeuger bauen den Baum statt der flachen Spalten.
3. Der MKR wird umgesetzt — er hat keinen Erzeuger und wird per SQL behandelt.
4. `inhaltsfeld`, `kompetenzbereich` und `teilbereich` entfallen — **erst
   nachdem** die Umformung belegt ist, und in einer eigenen Migration.

**Es wird nichts neu erhoben.** Alle vier Rahmen sind geprüft; die Zahlen
müssen am Ende dieselben sein. Was sich ändert, ist ausschließlich die Form der
Gliederung.

## Schritt 0 — Voraussetzungen prüfen

```bash
./tests-projektstunden.sh; echo "Exit: $?"
git status --short
ls -1 sql/ | tail -5
ls -1 sql/gen/
```

Erwartet: 52/52 grün, sauberer Arbeitsbaum, Migrationsnummern 15 und 16 frei,
drei Erzeuger vorhanden.

Prüfen, ob Kompetenzen zugewiesen sind — die Seeds löschen ihre Rahmen:

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SELECT kr.kuerzel, COUNT(*) AS zuweisungen
FROM projekt_schueler_kompetenzen psk
JOIN kompetenzen k ON k.id = psk.kompetenz_id
JOIN kompetenzbereiche kb ON kb.id = k.bereich_id
JOIN kompetenzrahmen kr ON kr.id = kb.rahmen_id
GROUP BY kr.id;'"
```

Zuletzt bekannt: 228 Zuweisungen, alle am MKR, keine an den drei anderen. **Der
MKR wird in diesem Auftrag umgeformt** — die 228 Zuweisungen hängen an
`kompetenz_id`, nicht an `bereich_id`, und dürfen deshalb nicht betroffen sein.
Das ist zu prüfen, nicht anzunehmen. Ist eine Zahl anders als erwartet:
anhalten.

## Schritt 1 — Ausgangsstand

```bash
./tests-projektstunden.sh
```
Prüfungszahl notieren (erwartet 52).

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e '
SELECT COUNT(*) AS bereiche, (SELECT COUNT(*) FROM kompetenzen) AS kompetenzen,
       (SELECT COUNT(*) FROM projekt_schueler_kompetenzen) AS zuweisungen
FROM kompetenzbereiche;
SELECT kr.kuerzel, COUNT(DISTINCT kb.id) AS bereiche, COUNT(k.id) AS kompetenzen
FROM kompetenzrahmen kr
LEFT JOIN kompetenzbereiche kb ON kb.rahmen_id = kr.id
LEFT JOIN kompetenzen k ON k.bereich_id = kb.id
GROUP BY kr.id HAVING kompetenzen > 0 ORDER BY kr.kuerzel;'"
```

Erwartet: 118 Bereiche, 649 Kompetenzen, 228 Zuweisungen;
`DEU_KLP 28/226`, `DEU_KLP_SII 30/197`, `MKR 6/106`, `SPO_KLP 54/120`.

**Die Zahl der Bereiche wird sich ändern** — der Baum führt Zwischenknoten ein,
die es flach nicht gab. Die Zahl der **Kompetenzen** und der **Zuweisungen**
darf sich nicht ändern. Das ist die Grenze.

## Schritt 2 — Knotenmodell festlegen, dann anhalten

Zu entscheiden ist, welche Knoten der Baum führt und was in `art` steht. Zwei
Fragen, beide mit Folgen für jede spätere Abfrage:

**Ist die Phase ein Knoten oder bleibt sie eine Spalte?** E29 sagt: Spalte, weil
sie quer zur Schachtelung liegt. Dann trägt jeder Knoten seine Phase, auch die
Blätter. Die Gegenposition wäre ein Phasenknoten als Wurzel je Phase — dann
steht die Phase nur einmal, aber jede Abfrage nach Phase muss den Baum
hinaufsteigen. Vorschlag mit Begründung vorlegen.

**Welche Werte nimmt `art` an?** Aus dem Bestand ergeben sich mindestens
`inhaltsfeld`, `bewegungsfeld`, `kompetenzbereich`. Der MKR bringt eine eigene
Sorte mit. Die Liste gehört in den Spaltenkommentar, nicht in ein ENUM (so
entschieden beim Sport-Auftrag).

Dazu die Frage, die niemand gestellt hat: **Hängen Kompetenzen nur an Blättern
oder auch an Zwischenknoten?** Bei Deutsch hängen sie an
`Inhaltsfeld › Rezeption`, also am Blatt. Bei Englisch werden sie später an
`Verfügen über sprachliche Mittel › Grammatik` hängen — auch am Blatt. Ob das
immer so ist, ist offen. Wenn ja, ist es eine prüfbare Zusicherung.

Vorlegen und **anhalten**. Ich entscheide, bevor gebaut wird.

## Schritt 3a — Migration 15

`sql/15_migration_kompetenzbereiche_baum.sql`:

- `parent_id INT UNSIGNED NULL` mit Fremdschlüssel auf `kompetenzbereiche(id)`,
  `ON DELETE CASCADE`.
- `NULL` heißt Wurzelknoten.

Additiv, kein `DROP`/`DELETE`/`TRUNCATE`, zweimal ausführbar. Die alten Spalten
bleiben zunächst stehen — sie entfallen erst in Schritt 3d.

**Danach anhalten und prüfen:** 118 / 649 / 228 unverändert.

## Schritt 3b — Erzeuger umstellen

Die drei Erzeuger unter `sql/gen/` bauen den Baum. Reihenfolge der Arbeit:
einen umstellen, das Ergebnis prüfen, dann den nächsten — nicht alle drei auf
einmal, sonst ist bei einer Abweichung nicht zu trennen, woher sie kommt.

Für jeden Erzeuger gilt: **Die Kompetenzen müssen wortgleich bleiben.** Ein
Wortlautvergleich gegen den ausgelieferten Stand gehört dazu; er muss leer
ausgehen. Geändert wird nur, wie die Bereiche zueinander stehen.

Die Bereichsnamen tragen die Gliederung bereits mit `·` als Trennzeichen —
`Erprobungsstufe · Sprache · Rezeption`. Ob die Knotennamen daraus abgeleitet
oder neu gesetzt werden, ist eine Entscheidung aus Schritt 2.

## Schritt 3c — MKR

Der MKR hat keinen Erzeuger und keine Quelldatei; er stammt aus einer eigenen
Vorlage und ist nach E8 der einzige von Anfang an korrekte Rahmen. Seine sechs
Bereiche werden zu sechs Wurzelknoten — flach bleibt flach.

**Achtung:** An ihm hängen alle 228 Zuweisungen. Sie hängen an `kompetenz_id`;
solange die Kompetenzen nicht gelöscht werden, sind sie nicht betroffen. Wenn
sich für den MKR ein `UPDATE` statt eines Neuaufbaus anbietet, ist das der
sicherere Weg — begründen und vorlegen.

## Schritt 3d — Alte Spalten entfernen

**Erst wenn Schritt 4 vollständig grün ist.** Eigene Migration
`sql/16_migration_klp_spalten_entfernen.sql`, die `inhaltsfeld`,
`kompetenzbereich` und `teilbereich` fallen lässt.

Vorher prüfen, dass keine Abfrage im Code sie noch liest:

```bash
grep -rn "inhaltsfeld\|kompetenzbereich\b\|teilbereich" backend/ frontend/ \
  --include=*.php --include=*.js
```

Findet sich etwas, gehört die Anpassung in diesen Auftrag — sonst bricht die
Anwendung nach der Migration. Das ist der einzige Punkt, an dem dieser Auftrag
den laufenden Betrieb berührt.

## Schritt 4 — Tests

**Unveränderlich:**

| | vorher | nachher |
|---|---|---|
| Kompetenzen gesamt | 649 | 649 |
| Zuweisungen | 228 | 228 |
| DEU_KLP Kompetenzen | 226 | 226 |
| DEU_KLP_SII Kompetenzen | 197 | 197 |
| MKR Kompetenzen | 106 | 106 |
| SPO_KLP Kompetenzen | 120 | 120 |

Die Zahl der Bereiche steigt und ist im Bericht zu nennen — vorher 118, nachher
offen.

**Wortlautvergleich** je Rahmen gegen den ausgelieferten Stand: muss leer
ausgehen. Jede Abweichung im Kompetenztext ist ein Befund, kein Fortschritt.

**Baumintegrität**, drei Prüfungen in `tests-projektstunden.sh`, Rubrik
„Fachdaten":

- Jeder Knoten mit `parent_id` verweist auf einen Knoten desselben Rahmens.
  Gegenprobe: `parent_id` auf einen fremden Rahmen zeigen lassen → rot.
- Kein Zyklus: Kein Knoten ist sein eigener Vorfahre.
  Gegenprobe: einen Knoten auf sich selbst zeigen lassen → rot.
- `art` ist gesetzt, wo `parent_id` gesetzt ist — oder anders gefasst, falls
  das nicht trägt. Gegenprobe wie bei der bestehenden `art`-Prüfung.

Ob diese Prüfungen statisch am Seed oder gegen die Datenbank laufen, ist im
Bericht zu begründen. Statisch ist vorzuziehen, weil `deploy.sh` sie ausführt.

Erwartete Prüfungszahl: **52 + 3 = 55**, sofern alle drei statisch gehen.
Andernfalls die Zahl nennen, die sich ergibt, und warum.

## Schritt 5 — Dokumentation

- `CHANGELOG.md`: Prüfungszahl vorher und nachher, Bereichszahl vorher und
  nachher.
- `docs/ENTSCHEIDUNGEN.md`: die Entscheidungen aus Schritt 2, falls sie über
  diesen Auftrag hinaus gelten — insbesondere die Frage, ob Kompetenzen nur an
  Blättern hängen.
- `sql/gen/README.md`: wie ein Erzeuger den Baum aufbaut. Das ist die Vorlage
  für sechzehn weitere Fächer.

## Schritt 6 — Ausliefern

```bash
./tests-projektstunden.sh
./deploy.sh "refactor(klp): Kompetenzbereiche als Baum (E29)"
```

Dann auf dem Server, in dieser Reihenfolge, mit Zählung nach jedem Schritt:
Migration 15, die drei Seeds, der MKR, zuletzt Migration 16. Jeden Seed zweimal
einspielen.

**Vor Migration 16 ein `mysqldump`.** Sie ist die einzige nicht additive
Änderung in diesem Auftrag.

Bei Rot in `tests-projektstunden.sh`: anhalten, nicht ausliefern.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

Zusätzlich: die Bereichszahl je Rahmen vorher und nachher, ein Beispielpfad je
Rahmen im Wortlaut, und die Bestätigung, dass die 228 Zuweisungen unberührt
sind.

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung.
- Bei Unklarheit nachfragen statt vermuten.
