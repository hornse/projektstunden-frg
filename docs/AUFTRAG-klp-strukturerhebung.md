# Auftrag: Strukturerhebung über alle Kernlehrpläne

Einzelauftrag. Nach Erledigung bleibt die Datei als Beleg liegen.
**Arbeitsverzeichnis: `/Users/sebastianhorn/Projekte/projektstunden`.**

## Was gebaut werden soll

Eine Befundtabelle über alle 37 Kernlehrpläne unter `docs/curricula/`.
Ergebnis ist `docs/curricula/STRUKTUR.md` — **kein Code, keine Migration, keine
Entscheidung.**

Anlass: Das Datenmodell für die Kompetenzrahmen wurde zweimal auf Grundlage
einer Stichprobe der Gliederungsüberschriften festgelegt und beide Male
widerlegt. E11 nahm an, Sport habe zwei sich kreuzende Inhaltsachsen — hat es
nicht. E18 nahm an, unterhalb der Phase lägen nie mehr als zwei
Gliederungsebenen — bei Englisch sind es drei. Ein drittes Mal auf einer
Stichprobe zu entscheiden, ist nicht zu rechtfertigen.

Zweiter, gleichrangiger Zweck: Jedes der drei bisher importierten Fächer hat
eine Eigenheit der Textextraktion mitgebracht, die niemand vermutet hatte —
Sport ein Steuerzeichen mitten im Satz und einen Seitenumbruch am Zeilenanfang,
Deutsch Sek I ein C1-Zeichen als Aufzählungsmarker, Englisch ein zweispaltiges
Layout. Bei sechzehn ausstehenden Fächern sind das sechzehn Anhaltepunkte. Wenn
sie vorher erhoben sind, stehen sie im jeweiligen Auftrag, bevor der Lauf
beginnt.

## Schritt 0 — Voraussetzungen prüfen

```bash
./tests-projektstunden.sh; echo "Exit: $?"
git status --short
ls -1 docs/curricula/*.pdf | wc -l
which pdftotext
```

Erwartet: 52/52 grün, sauberer Arbeitsbaum, 37 PDFs, `pdftotext` vorhanden.

Die Prüfsummen aller 37 gegen `docs/curricula/INDEX.md` halten. Weicht eine ab,
anhalten — dann ist eine Datei nicht die, für die sie sich ausgibt.

## Schritt 1 — Ausgangsstand

`./tests-projektstunden.sh`, Prüfungszahl notieren. Die Datenbank wird nicht
angefasst; eine Erhebung von dort ist nicht nötig.

## Schritt 2 — Verfahren festlegen, dann anhalten

**Das ist der Kern des Auftrags, und hier ist am ehesten etwas falsch zu
machen.** Bei der Vorbereitung wurde ein automatisches Verfahren versucht, das
Überschriften an Formmerkmalen erkennt — kurze Zeile, Großbuchstabe am Anfang,
kein Satzzeichen am Ende. Es ist gescheitert, und zwar nicht sichtbar:

- Es hielt `Die Schülerinnen und Schüler` für eine Gliederungsebene.
- Es zog inhaltliche Schwerpunkte wie `Standardreaktionsenthalpien, Satz von
  Hess` als Überschrift ein.
- Bei Musik meldete es Tiefe 5. Tatsächlich sind es zwei; was es für
  Gliederungsebenen hielt (`Rhythmik`, `Melodik`, `Harmonik`, `Tempo`), steht
  in der **rechten Spalte** eines zweispaltigen Satzes und gehört zu den
  Ordnungssystemen musikalischer Strukturen.
- Bei Deutsch fand es 8 statt 226 Erwartungen, weil es die Marker `à` und
  `\x83` nicht kannte.

Daraus folgt: Ein Verfahren, das die Gliederung aus der Form erschließt, ist
nicht belastbar. Gebraucht wird eines, das die Pläne **liest**.

Vorgehen: an drei Plänen mit bekannter Struktur erproben und das Ergebnis
gegen das Bekannte halten —

| Plan | bekannte Struktur |
|---|---|
| `g9_d_klp_3409_2019_06_23.pdf` | Phase › Inhaltsfeld › Rezeption/Produktion, Tiefe 2, einspaltig, Marker `à` und `\x83` |
| `g9_sp_klp_3426_2019_06_23.pdf` | Phase › Inhaltsfeld **oder** Bewegungsfeld › Kompetenzbereich, Tiefe 2, einspaltig, Marker `à` |
| `g9_e_klp_3417_2019_06_23.pdf` | Phase › Kompetenzbereich › Teilbereich › **Unterbereich**, Tiefe 3, **zweispaltig**, Marker `à` |

Trifft das Verfahren diese drei nicht, taugt es für die übrigen 34 erst recht
nicht. Dann berichten und anhalten, statt es an den Rest zu lassen.

Danach das Verfahren beschreiben und **anhalten**. Ich entscheide, bevor 37
Pläne damit gelesen werden.

## Schritt 3 — Erhebung

Erst nach Freigabe. Je Plan zu erheben:

1. **Fach und Stufe** — aus der Titelseite, nicht aus dem Dateikürzel.
   `g9_s_klp` ist Spanisch, `g9_sp_klp` ist Sport.
2. **Aufzählungsmarker** der Kompetenzerwartungen, mit Codepoint und Anzahl.
   Führt ein Plan mehrere, alle nennen — bei Deutsch Sek I sind es zwei mit
   unterschiedlicher Bedeutung.
3. **Marker anderer Aufzählungen**, die *nicht* mitzählen dürfen — inhaltliche
   Schwerpunkte, fachliche Konkretisierungen.
4. **Spaltigkeit.** Einspaltig oder zweispaltig; bei zweispaltig: was steht
   rechts, und an welcher Spalte verläuft die Grenze.
5. **Gliederungspfad** zwischen Phase und Erwartung, im Wortlaut, mit Tiefe.
   Bei Tiefe 3 oder mehr: der vollständige Pfad eines Beispiels.
6. **Phasen** des Plans, im Wortlaut der Kapitelüberschriften.
7. **Anzahl der Kompetenzerwartungen** gesamt und je Phase.
8. **Steuerzeichen** oberhalb des druckbaren Bereichs, mit Anzahl und
   Bedeutung — trägt eines die Gliederung wie bei Deutsch Sek I?
9. **Unsicherheit.** Wo die Gliederung sich nicht eindeutig lesen lässt: als
   unsicher kennzeichnen, mit der Stelle und beiden Lesarten. Ein als unsicher
   markierter Plan ist ein brauchbares Ergebnis; ein falsch als sicher
   ausgewiesener nicht.

Nicht dazu gehört: Daten erzeugen, Migrationen schreiben, das Schema ändern,
einen Erzeuger bauen. Auch nicht: eine Empfehlung, wie das Datenmodell
aussehen soll — die Tabelle ist die Grundlage dafür, nicht ihr Ersatz.

## Schritt 4 — Prüfungen

Die Erhebung selbst ist zu prüfen, sonst ist sie eine Behauptung über 37
Dateien.

**Gegen Bekanntes.** Die vier importierten Rahmen sind in der Datenbank
belegt. Die erhobenen Zahlen müssen treffen:

| Plan | Bereiche | Erwartungen |
|---|---|---|
| Deutsch Sek I | 28 | 226 |
| Deutsch GOSt | 30 | 197 |
| Sport Sek I | 54 | 120 |

Weicht eine Zahl ab, ist entweder die Erhebung falsch oder der Import — beides
ist ein Befund, keines ein Grund weiterzumachen.

**Zwei Wege je Zahl.** Die Gesamtzahl der Erwartungen eines Plans muss aus der
Summe je Gliederungseinheit hervorgehen. Stimmen Summe und Einzelzählung nicht
überein, ist die Gliederung nicht vollständig erfasst.

**Bei mehreren Markern die Aufteilung prüfen**, nicht nur die Summe (E28). Bei
Deutsch Sek I sind es 42 zu 184.

Eine neue Prüfung in `tests-projektstunden.sh` ist **nicht** vorgesehen — die
Tabelle ist ein Dokument, kein Code. Die Prüfungszahl bleibt bei 52. Bleibt sie
es nicht, ist das im Bericht zu begründen.

## Schritt 5 — Dokumentation

- `docs/curricula/STRUKTUR.md` ist das Ergebnis. Aufbau: eine Übersichtstabelle
  über alle 37, danach je Plan ein Abschnitt mit den Punkten aus Schritt 3.
- `docs/curricula/INDEX.md`: einen Verweis auf `STRUKTUR.md` aufnehmen.
- `docs/ENTSCHEIDUNGEN.md`: **nichts**. Die Entscheidung über das Datenmodell
  fällt im Chat, nachdem die Tabelle vorliegt.
- `CHANGELOG.md`: Eintrag mit Prüfungszahl.

## Schritt 6 — Ausliefern

```bash
./tests-projektstunden.sh
./deploy.sh "docs(klp): Strukturerhebung über alle 37 Kernlehrpläne"
```

Kein SQL, keine Datenbankänderung.

## Schritt 7 — Bericht

1. Ausgangsstand
2. Was die Analyse ergab, und was anders war als vermutet
3. Welche Entscheidungen fielen, mit Begründung
4. Prüfungszahl vorher und nachher
5. **Was nicht umgesetzt wurde und warum**
6. **Was unterwegs gefunden wurde, das nicht zum Auftrag gehörte**
7. Commit-Hashes

Zusätzlich, und das ist der Teil, auf den es ankommt:

- **Die größte gefundene Gliederungstiefe**, mit dem vollständigen Pfad im
  Wortlaut und der Fundstelle.
- **Alle Pläne mit Tiefe 3 oder mehr**, einzeln aufgeführt.
- **Alle als unsicher gekennzeichneten Pläne**, mit beiden Lesarten.
- **Alle zweispaltigen Pläne**, weil dort die Extraktion anders anzusetzen ist.
- **Alle Marker**, die im Bestand vorkommen, als eine Liste.

## Grundsätzliches

- Vermutungen als Vermutungen kennzeichnen, mit dem Versuch dazu.
- „Ich weiß es nicht" statt einer plausiblen Vermutung. Bei diesem Auftrag
  besonders: Ein als unsicher markierter Plan kostet eine Rückfrage, ein falsch
  als sicher ausgewiesener kostet eine Migration.
- Bei Unklarheit nachfragen statt vermuten.
