# Auftrag: Deutsch Sekundarstufe II neu erzeugen

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

Der Kompetenzrahmen `DEU_KLP_SII` steht in der Datenbank, stammt aber aus dem
Entwurf vom 31.07.2025. Die verabschiedete Fassung vom 24.08.2026 liegt unter
`docs/curricula/gost_klp_d_2026_08_24.pdf`. Beide unterscheiden sich im
Wortlaut, mindestens an einer Stelle inhaltlich.

Zu bauen sind zwei Dinge: ein Erzeuger unter `sql/gen/gen_deutsch_sii.py`, der
aus dem PDF die Seed-Datei erzeugt, und die erzeugte
`sql/11_seed_deutsch_sii.sql` — **an Ort und Stelle ersetzt**, nicht als neue
Nummer danebengelegt. Seeds beschreiben einen Sollzustand und löschen ihren
eigenen Rahmen, bevor sie ihn aufbauen; zwei Dateien für denselben Rahmen wären
eine zweite Wahrheit.

Nicht dazu: die Spalten `teilbereich` und `art` aus E18. Deutsch GOSt füllt
beide nicht, eine Prüfung darauf hätte keine Voraussetzung. Sie kommen mit dem
Englisch-Auftrag.

## Schritt 0 — Voraussetzungen prüfen

Alles nachsehen, nichts annehmen. Bei einem Fehlschlag hier anhalten und melden.

```bash
./tests-projektstunden.sh; echo "Exit: $?"
git status --short
shasum -a 256 docs/curricula/gost_klp_d_2026_08_24.pdf
```

Die Prüfsumme muss lauten:
`00694903d6a16447989fd476d9ce91c8e0e7b8cb0e114fa3cfd3ed773d981c29`

Weicht sie ab, ist es eine andere Datei als die, aus der die Sollzahlen unten
stammen — dann anhalten.

Prüfen, ob `pdftotext` vorhanden ist. Fehlt es, anhalten und melden, statt auf
eine andere Bibliothek auszuweichen: Die Sollzahlen unten wurden mit
`pdftotext -layout` ermittelt, ein anderer Extraktor liefert andere
Umbrüche.

## Schritt 1 — Ausgangsstand

```bash
./tests-projektstunden.sh
```
Prüfungszahl notieren.

```bash
ssh hornse@halimede.uberspace.de "mysql hornse_projektstunden -e \"
SELECT phase, COUNT(DISTINCT kb.id) AS bereiche, COUNT(k.id) AS kompetenzen
FROM kompetenzbereiche kb
JOIN kompetenzrahmen kr ON kr.id = kb.rahmen_id
LEFT JOIN kompetenzen k ON k.bereich_id = kb.id
WHERE kr.kuerzel = 'DEU_KLP_SII' GROUP BY phase;\""
```

Erwartet: `einfuehrungsphase 10/58`, `qualifikationsphase_gk 10/66`,
`qualifikationsphase_lk 10/73`. Diese Zahlen bleiben nach dem Lauf gleich —
sie stimmen in beiden Fassungen überein. Geändert wird der **Wortlaut**.

## Schritt 2 — Extraktion, und dann anhalten

Die Textumwandlung ist hier die eigentliche Schwierigkeit. Drei belegte Fallen:

**`pdftotext` ohne `-layout` verliert Text.** Bei dieser Datei 91 207 gegen
106 153 Zeichen, rund 16 Prozent. Sätze brechen mitten ab. `-layout` verwenden.

**Silbentrennung am Zeilenende.** `Gestal-` / `tungselemente` muss zu
`Gestaltungselemente` werden. Zugleich gibt es echte Bindestriche im Wortlaut,
die stehen bleiben müssen: `sach-, adressaten- und situationsgerecht`,
`(fach-)sprachlich`, `kritisch-produktiven`. Eine Regel, die alle Bindestriche
am Zeilenende auflöst, zerstört die erste Sorte nicht, die zweite schon, wenn
sie zufällig dort steht.

**Fortsetzungszeilen erkennen.** Ein Aufzählungspunkt läuft über mehrere
Zeilen. Die Regel „bis zum nächsten Komma" ist falsch — Einträge enthalten
Kommata mitten im Satz. Das war bei der Vorbereitung dieses Auftrags der
Grund, warum ein erster Vergleich 26 Abweichungen meldete, von denen fast alle
Artefakte waren.

Vorgehen: Verfahren entwerfen, an den fünf unten genannten Stichproben prüfen,
**dann berichten und anhalten**. Ich entscheide, ob es taugt, bevor 197
Einträge erzeugt werden.

## Schritt 3 — Umsetzung

Erst nach Freigabe von Schritt 2.

`sql/gen/gen_deutsch_sii.py` liest das PDF und schreibt die Seed-Datei. Dazu
`sql/gen/README.md` mit dem Aufruf — dieselbe Ablage gilt für alle künftigen
Fachimporte.

Der Kopf der erzeugten Datei nennt nach E19:

```
-- Quelle: docs/curricula/gost_klp_d_2026_08_24.pdf
-- SHA256: 00694903d6a16447989fd476d9ce91c8e0e7b8cb0e114fa3cfd3ed773d981c29
-- Erzeugt von: sql/gen/gen_deutsch_sii.py
```

Gliederung wie bei `10_seed_deutsch_klp.sql`, damit Sek I und Sek II gleich
aussehen: Bereichsname als `Phase · Inhaltsfeld · Kompetenzbereich`, Spalten
`phase`, `inhaltsfeld`, `kompetenzbereich` gefüllt. Für die übergeordneten
Erwartungen ist `inhaltsfeld` der Wert `Übergeordnet`, wie bereits im Bestand.

Robustheit:
- **Was darf nicht verlorengehen?** Nichts außerhalb von `DEU_KLP_SII`. Das
  `DELETE` im Seed muss auf diesen Rahmen beschränkt bleiben.
- **Was bei Fehlschlag?** Der Seed läuft in einer Transaktion. Bricht er ab,
  bleibt der alte Stand.
- **Zweimal einspielen** muss dasselbe Ergebnis liefern.

## Schritt 4 — Tests

**Sollzahlen** aus `gost_klp_d_2026_08_24.pdf`, ermittelt mit `pdftotext -layout`
und Zählung der Aufzählungszeichen je Abschnitt. Sie stammen aus einem anderen
Verfahren als der Erzeuger — weicht er ab, ist zuerst zu klären, welche der
beiden Zählungen falsch ist, nicht welche recht hat.

| Phase | Inhaltsfeld | Rezeption | Produktion |
|---|---|---|---|
| EF | Übergeordnet | 8 | 11 |
| EF | Sprache | 6 | 3 |
| EF | Texte | 8 | 6 |
| EF | Kommunikation | 5 | 3 |
| EF | Medien | 5 | 3 |
| Q-GK | Übergeordnet | 9 | 11 |
| Q-GK | Sprache | 6 | 2 |
| Q-GK | Texte | 14 | 6 |
| Q-GK | Kommunikation | 5 | 3 |
| Q-GK | Medien | 7 | 3 |
| Q-LK | Übergeordnet | 11 | 11 |
| Q-LK | Sprache | 7 | 3 |
| Q-LK | Texte | 14 | 6 |
| Q-LK | Kommunikation | 7 | 3 |
| Q-LK | Medien | 8 | 3 |

Summen: EF 58, Q-GK 66, Q-LK 73 — zusammen 197 in 30 Bereichen.

**Zählwerte allein genügen hier nicht.** Der Entwurf vom 31.07.2025 hat
dieselben Zahlen. Was die Fassungen unterscheidet, ist der Wortlaut. Deshalb
zusätzlich diese fünf Stichproben, die im Entwurf nachweislich anders lauten
oder eine Falle enthalten:

1. Q-LK, Medien, Produktion — muss enthalten:
   `gestalten auch bei einer kritisch-produktiven Verwendung von KI-Werkzeugen
   Texte eigenständig und verantwortlich`
   (Entwurf: *„gestalten bei einer produktiven Verwendung … auch kritisch im
   Hinblick auf Fragen der Autorenschaft"* — steht das dort, wurde die falsche
   Quelle verarbeitet.)
2. Q-LK, Texte, Rezeption — `nichtfiktionalen`, nicht `nicht-fiktionalen`.
3. Irgendwo — `(fach-)sprachlich differenziert`, nicht `(fach)sprachlich`.
4. EF, Sprache, Rezeption, erster Eintrag — `beschreiben verschiedene Ebenen
   des Systems Sprache (phonologische, morphologische, syntaktische,
   semantische und pragmatische Aspekte)`. Prüft, ob die Klammer vollständig
   übernommen wurde; sie steht im PDF über zwei Zeilen.
5. Irgendein Eintrag mit `sach-, adressaten- und situationsgerecht` — prüft,
   dass echte Bindestriche die Entsilbentrennung überlebt haben.

**Zwei neue Prüfungen in `tests-projektstunden.sh`**, Rubrik „Fachdaten":

- Der Kopf jedes Seeds nennt eine Quelle unter `docs/curricula/`, und die dort
  angegebene SHA256 stimmt mit der tatsächlichen Datei überein.
  Gegenprobe: eine Ziffer der Summe im Kopf ändern → rot.
- Zu jedem Seed, dessen Kopf einen Erzeuger nennt, existiert diese Datei.
  Gegenprobe: die Zeile auf einen nicht vorhandenen Pfad zeigen lassen → rot.

Die erwartete Prüfungszahl wird genannt, wenn feststeht, welche Prüfungen
geschrieben werden — nicht vorab geschätzt.

## Schritt 5 — Dokumentation

- `CHANGELOG.md`: Eintrag mit Prüfungszahl vorher und nachher.
- `docs/ENTSCHEIDUNGEN.md`: nur, wenn in Schritt 2 eine Entscheidung fiel, die
  über diesen Auftrag hinaus gilt — etwa zum Umgang mit Silbentrennung, der bei
  jedem weiteren Fach wiederkehrt.
- `docs/curricula/INDEX.md`: unverändert. Die Datei ist dieselbe.

## Schritt 6 — Ausliefern

```bash
./tests-projektstunden.sh
./deploy.sh "feat(klp): Deutsch GOSt aus der verabschiedeten Fassung (E19)"
ssh hornse@halimede.uberspace.de \
  "mysql hornse_projektstunden < /home/hornse/projektstunden/sql/11_seed_deutsch_sii.sql"
```

Danach die Zählung aus Schritt 1 wiederholen. Erwartet: dieselben Zahlen.
Weichen sie ab, anhalten und melden — dann stimmt etwas an der Extraktion.

Bei Rot in `tests-projektstunden.sh`: anhalten, nicht ausliefern.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

Zusätzlich: die Liste der Einträge, die sich gegenüber dem bisherigen Bestand
im Wortlaut geändert haben. Sie belegt, dass die Quelle tatsächlich gewechselt
hat. Kommt sie leer zurück, wurde dieselbe Fassung ein zweites Mal verarbeitet.

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung.
- Bei Unklarheit nachfragen statt vermuten.

---

## Nachtrag (06.09.2026) — zwei Stichproben waren falsch

Der Bericht zu Schritt 2 hat zwei Angaben in Schritt 4 widerlegt. Der Text oben
bleibt stehen, es gilt zusätzlich:

**Stichprobe 1, Ortsangabe berichtigt.** Der Satz *„gestalten auch bei einer
kritisch-produktiven Verwendung von KI-Werkzeugen Texte eigenständig und
verantwortlich"* steht dreimal unter **Übergeordnet · Produktion** (EF, Q-GK,
Q-LK), nicht unter Medien · Produktion. Der Wortlaut selbst stimmt.

**Stichprobe 2 war falsch: richtig ist `nicht-fiktionalen`, mit Bindestrich.**
Beleg: Zeile 938 (Q-GK) führt das Wort ungetrennt mitten in der Zeile mit
Bindestrich. Die Sollvorgabe `nichtfiktionalen` entstand bei der Vorbereitung
dieses Auftrags durch eine Normalisierung, die jeden Bindestrich am Zeilenende
ungeprüft auflöste — genau die Falle, die Schritt 2 benennt.

**Prüfung aus Schritt 4, Rubrik „Fachdaten":** greift nur für Seeds mit einer
`-- Quelle:`-Zeile (E21). `10_seed_deutsch_klp.sql` und `12_seed_sport_klp.sql`
fallen damit nicht durch; ihr Rückstand ist in E21 festgehalten.

**Codeschema:** `DE_EF_…`, `DE_QGK_…`, `DE_QLK_…` wie im Bestand beibehalten.

Erwartete Prüfungszahl: **48 + 2 = 50**.

**Nachtrag 2 (06.09.2026):** Die Fachdatenprüfung übergeht Quellenangaben, die
mit `http://` oder `https://` beginnen (E23). `02_seed.sql` fällt damit nicht
durch.
