# Entscheidungen

Chronologisch, mit Begründung. Neue Einträge unten anfügen, **alte nie
ändern** — überholte werden durch einen neuen Eintrag aufgehoben, nicht
weggelöscht.

Zweck: Diskussionen finden im Chat statt, Entscheidungen gehören ins Repo.
Sonst muss beim nächsten Mal alles neu erklärt werden.

---

## E1 — WebUntis ergänzt den lokalen Login, ersetzt ihn nicht (08.07.2026)

**Anlass:** Für die Anmeldung stand die Wahl zwischen WebUntis als alleinigem
Verfahren (so macht es das Schwesterprojekt Schulprozesse) und einem zweiten
Weg über E-Mail und Passwort.

**Entscheidung:** Beide Wege bleiben. Der Login-Handler probiert zuerst den
lokalen Weg, wenn die Eingabe wie eine E-Mail aussieht, danach WebUntis.

**Warum:** WebUntis ist ein fremder Dienst. Fällt er aus oder ändert sich die
API, kommt sonst niemand mehr in die Anwendung — auch kein Administrator, der
den Ausfall beheben müsste.

**Was das nicht heißt:** Lehrkräfte brauchen keinen lokalen Account. Der
lokale Weg ist für Administratoren im Notfall gedacht, nicht für den Alltag.

---

## E2 — Keine manuelle Zuordnung von WebUntis-Kürzeln (08.07.2026)

**Anlass:** Der erste Entwurf verlangte, dass für jede Lehrkraft das
WebUntis-Kürzel von Hand in der Spalte `benutzer.webuntis_user` hinterlegt
wird. Bei rund hundert Lehrkräften und wechselndem Kollegium ist das
Dauerpflege.

**Entscheidung:** Wer sich erfolgreich gegen WebUntis authentifiziert, bekommt
eine Session, ohne dass ein Datenbankeintrag existieren muss
(`benutzer_id = 0`). Die Rolle ergibt sich aus dem personType: 16 wird
`admin`, 2 wird `lernbegleiter`. Zusätzlich kann `admin_kuerzel` in der
Konfiguration einzelne Lehrkräfte zu Administratoren machen. Existiert ein
lokaler Eintrag mit passendem Kürzel, hat dessen Rolle Vorrang.

**Warum:** Die Pflege entfällt vollständig. Wer in WebUntis Lehrkraft ist, ist
es hier auch — eine zweite Wahrheit über dieselbe Sache entsteht gar nicht
erst.

**Was das nicht heißt:** `benutzer_id = 0` ist kein gültiger Fremdschlüssel.
Alles, was einen Benutzer referenziert, muss diesen Fall abfangen. Er hat
bereits einmal zu einem stillen 401 geführt (siehe CLAUDE.md).

---

## E3 — Schüleridentität über `schild_id` = WebUntis-`key` (09.07.2026)

**Anlass:** Auch Schüler sollen sich anmelden können. Eine eigene Zuordnung
zwischen WebUntis-Konto und Datensatz wäre bei über 800 Schülern nicht
pflegbar.

**Entscheidung:** Der `key` aus `getStudents()` ist die interne Schild-Nummer.
Sie steht bereits als `schueler.schild_id` in der Datenbank, weil beide
Systeme ihre Daten aus Schild-NRW beziehen. Der Abgleich läuft darüber.

**Warum:** Kein Mapping, keine Pflege, kein zusätzliches Feld. Die
Übereinstimmung wurde am Produktivsystem geprüft, nicht angenommen.

**Was das nicht heißt:** Die Annahme gilt für diese Schule. Verwendet eine
andere Schule WebUntis ohne Schild-Import, trägt sie nicht.

---

## E4 — Kein Bulk-Abgleich der Schüler aus WebUntis (09.07.2026)

**Anlass:** Ziel war, die Schülerdaten nur noch in WebUntis zu pflegen und den
CSV-Import aus Schild abzuschaffen.

**Entscheidung:** Der CSV-Import bleibt der Weg für den Bestand. Aus WebUntis
kommen Schüler nur einzeln beim ersten Login dazu.

**Warum:** `getStudents()` liefert an dieser WebUntis-Instanz **kein**
`idOfClass`. Geprüft wurde: `getStudents()` ohne Filter (3563 Datensätze, kein
Klassenfeld), `getStudents(klasseId=…)` (Method not found), vier
REST-Endpunkte (alle Fehler), `getTimetable` für eine Klasse (liefert Lehrer,
Fach, Raum — keine Schülerliste). Die Klassenzugehörigkeit steht nur in der
`authenticate`-Antwort des einzelnen Schülers. Ohne Klasse ist ein
Massenimport wertlos, weil sich keine Werkstatt planen lässt.

**Was das nicht heißt:** Die Frage ist nicht abschließend beantwortet. Untis
bietet eine Partner-API zur Schülerverwaltung, die diese Daten enthält; sie
verlangt eine Freischaltung. Der Weg ist offen, nur nicht gegangen.

---

## E5 — Bewerten ist ein eigener Screen, kein Teil des Bearbeiten-Formulars (07.07.2026)

**Anlass:** Bewertungstabelle und Rückmeldungen hingen zunächst unten am
Formular „Werkstatt bearbeiten".

**Entscheidung:** Eigener Navigationspunkt „Bewertungen" mit Auswahl der
Werkstatt über ein Dropdown.

**Warum:** Es sind zwei verschiedene Tätigkeiten zu zwei verschiedenen
Zeitpunkten. Die Werkstatt wird einmal am Anfang eingerichtet; bewertet wird
über Wochen hinweg immer wieder. Wer bewerten will, sollte nicht durch ein
Formular scrollen müssen, in dem er nichts ändern will.

**Was das nicht heißt:** Die Zuordnung der Kompetenzen zur Werkstatt bleibt im
Bearbeiten-Formular. Das ist Einrichtung, keine Bewertung.

---

## E6 — Kritische IDs liegen im DOM, nicht in JavaScript-Variablen (07.07.2026)

**Anlass:** Nach einem Deploy schlug das Speichern im Bearbeiten-Formular mit
einem 500er fehl, weil `WS_EDIT_ID` `undefined` war.

**Entscheidung:** Werte, ohne die ein Formular nicht abschickbar ist, kommen
in ein verstecktes `<input>`. Die JavaScript-Variable bleibt als Fallback.

**Warum:** Ein Deploy lädt die Seite neu, ohne dass der Benutzer es merkt. Der
sichtbare Zustand des Formulars bleibt, der JavaScript-Zustand nicht. Der
Fehler tritt nur nach einem Deploy auf und ist deshalb im Test kaum zu finden.

---

## E7 — WebUntis-Auth wird ein eigenes Repository (09.07.2026)

**Anlass:** Dieselbe Anmeldelogik wurde zum zweiten Mal geschrieben — einmal
für Schulprozesse, einmal hier. Beide Male mit denselben Stolperstellen.

**Entscheidung:** `hornse/webuntis-auth-php`, öffentlich, GPL v3. Enthält
`WebUntisAuth`, `WebUntisSession`, die Migration für das Login-Protokoll, ein
Verwendungsbeispiel und eine Dokumentation der Fallstricke.

**Warum:** Die drei teuersten Fehler (Cookie-Name zu spät, fehlendes
Secure-Flag, `empty(0)`) sind nicht projektspezifisch. Sie einmal zu
dokumentieren ist billiger, als sie im dritten Projekt wieder zu suchen.

**Was das nicht heißt:** Das Modul wird nicht als Submodul eingebunden. Es
wird kopiert. Eine Änderung dort erreicht dieses Projekt nicht automatisch —
der Abgleich ist Handarbeit und muss beim Aktualisieren geprüft werden.

---

## E8 — Die vorhandenen Kernlehrplandaten werden verworfen, nicht korrigiert (10.07.2026)

**Anlass:** Beim Vergleich des Kompetenzkatalogs mit dem PDF des
Kernlehrplans Deutsch stellte sich heraus, dass die Daten nicht stimmen.

**Befund:** Der Bestand nennt für Deutsch die Kompetenzbereiche „Sprechen und
Zuhören", „Schreiben", „Lesen und Umgang mit Texten und Medien", „Sprache und
Sprachgebrauch untersuchen". Diese Gliederung stammt aus dem G8-Lehrplan; im
G9-Lehrplan von 2019 kommt sie nicht mehr vor. Dort gibt es vier Inhaltsfelder
(Sprache, Texte, Kommunikation, Medien) und zwei Kompetenzbereiche (Rezeption,
Produktion). Die einzelnen Einträge sind außerdem keine
Kompetenzerwartungen, sondern Zusammenfassungen wie „informierende Texte
verfassen". Bei Sport stehen 227 Bereiche mit je genau einer Kompetenz —
Bereich und Kompetenz wurden dort offenbar eins zu eins angelegt. Betroffen
sind alle 21 Fachrahmen. Der Medienkompetenzrahmen ist korrekt, er kam aus
einer eigenen Vorlage.

**Entscheidung:** Alle Fachrahmen werden gelöscht und aus den PDFs neu
aufgebaut. Der MKR bleibt unangetastet.

**Warum:** Die Daten sind nicht teilweise falsch, sondern nach einem anderen
Schema gebaut. Eine Korrektur müsste jeden Eintrag einzeln prüfen und käme
teurer als der Neuaufbau — und ließe offen, was übersehen wurde.

**Was das nicht heißt:** Kein Neuaufbau ins Blaue. Jedes Fach wird aus dem
zugehörigen PDF befüllt, nicht aus dem Gedächtnis eines Modells. Fehlt ein
PDF, wird das Fach nicht angelegt.

---

## E9 — Chat entscheidet, Claude Code baut (10.07.2026)

**Anlass:** Bisher lief beides im selben Gespräch. Entscheidungen waren
danach nur im Chatverlauf auffindbar, also praktisch nicht.

**Entscheidung:** Richtungsentscheidungen fallen im Chat und werden hier
festgehalten. Umsetzung, Tests und Auslieferung laufen in Claude Code über
`docs/AUFTRAG-*.md`. Dauerregeln stehen in `CLAUDE.md`.

**Warum:** E8 wäre bei dieser Arbeitsweise Monate früher aufgefallen — die
Herkunft der Kompetenzdaten wäre ein Eintrag hier gewesen, mit der Frage,
woher sie stammen.

**Was das nicht heißt:** Nicht jede Kleinigkeit wird ein Eintrag. Hier steht,
wovon jemand später denken könnte „warum eigentlich so?".

---

## E11 — Kompetenzbereiche werden ein Baum, nicht drei feste Spalten (02.09.2026)

**Anlass:** Für den Neuaufbau des Kompetenzkatalogs (E8) war ein Schema mit den
Spalten `phase`, `inhaltsfeld` und `kompetenzbereich` vorgesehen. Vor der
Umsetzung wurden alle 36 Kernlehrpläne auf ihre Gliederung hin ausgewertet.

**Befund:** Die Fächer gliedern unterschiedlich tief. Deutsch, die
Naturwissenschaften und die Gesellschaftswissenschaften haben zwei Ebenen
(Inhaltsfeld, darunter der Kompetenzbereich). Englisch, Französisch und
Spanisch haben drei (Funktionale kommunikative Kompetenz, darunter sieben
Teilbereiche wie Hörverstehen und Sprachmittlung, darunter die Erwartungen) und
kennen in dieser Achse gar kein Inhaltsfeld. Mathematik hat zwei gleichrangige
Gliederungen nebeneinander — prozessbezogen (Operieren, Modellieren,
Problemlösen, Argumentieren, Kommunizieren) und inhaltsbezogen
(Arithmetik/Algebra, Funktionen, Geometrie, Stochastik). Sport führt zusätzlich
zu den Inhaltsfeldern a bis f eine zweite Inhaltsachse mit Bewegungsfeldern.

**Entscheidung:** `kompetenzbereiche` bekommt `parent_id` als Selbstreferenz.
Dazu `phase` als eigene Spalte, weil die Phase quer zu allen Ebenen liegt, und
`art`, damit die Oberfläche weiß, was ein Knoten darstellt.

**Warum:** Drei feste Spalten hätten bei Englisch eine Ebene verloren und bei
Mathematik eine der beiden Gliederungen. Beides wäre erst beim Befüllen des
jeweiligen Fachs aufgefallen — also nach dem Import von Deutsch und mehreren
anderen Fächern, mit einer erneuten Migration über den gesamten Bestand als
Folge.

**Was das nicht heißt:** Die Alternative — nur die Erwartungen speichern und die
Gliederung als Anzeigetext mitführen — wurde verworfen, weil sich damit nicht
mehr abfragen lässt, welche Erwartungen zu einem Inhaltsfeld gehören. Genau das
braucht die Zuordnung von Kompetenzen zu einer Werkstatt.

---

## E12 — Deutsch Sek I bleibt, E8 gilt nur noch für die übrigen Fächer (02.09.2026)

**Anlass:** Zwischen E8 und heute wurde der Rahmen `DEU_KLP` von jemandem neu
befüllt. Die Herkunft war zunächst unklar — dieselbe Lage, die zu E8 geführt
hatte.

**Befund:** Die Daten wurden gegen `g9_d_klp_3409_2019_06_23.pdf` geprüft. 28
Bereiche, 226 Kompetenzerwartungen, Gliederung „Phase · Inhaltsfeld ·
Kompetenzbereich", Codes nach dem Muster `DE_EP_UEB_REZ_01`. Vier Bereiche
wurden ausgezählt und stimmen exakt; die Formulierungen sind wörtlich aus dem
Lehrplan übernommen, keine Zusammenfassungen.

**Entscheidung:** `DEU_KLP` bleibt erhalten. E8 gilt unverändert für alle
übrigen Fachrahmen. Die Gliederung und das Code-Schema von Deutsch sind ab
sofort die Vorlage für alle weiteren Fächer.

**Warum:** Ein Neuaufbau würde geprüfte Daten durch ungeprüfte ersetzen.

**Was das nicht heißt:** Ein Mangel bleibt. Die 21 übergeordneten Erwartungen
aus Kapitel 2.3 des Lehrplans sind als `Zweite Stufe` eingetragen, gelten aber
für die gesamte Sekundarstufe I. Sie bekommen die Phase `sek1_uebergreifend`.
Doppelt anlegen — je einmal für Erste und Zweite Stufe — wurde verworfen, weil
dann jede Korrektur zweimal erfolgen müsste.

---

## E13 — Offene Punkte am Kompetenzkatalog (02.09.2026)

Kein Beschluss, sondern eine Merkliste, damit die Lücken nicht im Chatverlauf
verschwinden. Wird gestrichen, sobald jeder Punkt erledigt ist.

- **WP Wirtschaft** (`WPWI_KLP`): Es gibt einen eigenen Lehrplan, er liegt noch
  nicht vor. Der Rahmen bleibt bis dahin unbefüllt und wird nicht gestrichen.
- **Latein Oberstufe**: wird an der Schule nicht unterrichtet. Kein GOSt-Rahmen
  anlegen.
- **Deutsch GOSt**: Grundlage ist `gost_klp_d_2026_08_24.pdf`, die verabschiedete
  Fassung. Der Entwurf vom 31.07.2025, der in früheren Notizen auftaucht, ist
  überholt und wird nicht verwendet.

---

## E14 — Kompetenz-Codes werden mit der Phase korrigiert (02.09.2026)

**Anlass:** Die 21 übergeordneten Erwartungen der Sekundarstufe I bekommen nach
E12 die Phase `sek1_uebergreifend`. Ihre Codes lauten `DE_S2_UEB_REZ_01` ff. und
behaupten weiterhin „Zweite Stufe".

**Befund:** `projekt_schueler_kompetenzen` enthält null Zuweisungen für Deutsch —
das Werkzeug ist noch nicht im Produktivbetrieb. Die Codes werden weder im
Frontend noch im Backend gegen feste Werte geprüft; sie werden ausschließlich
generisch gelesen und angezeigt. Die Zuordnung von Kompetenzen läuft über
`kompetenz_id`, nicht über den Code.

**Entscheidung:** Die Codes werden auf `DE_S1U_UEB_REZ_01` ff. umbenannt,
zusammen mit der Phasenkorrektur und in derselben Transaktion.

**Warum:** Ein Code, der etwas anderes behauptet als die Spalte daneben, wird
irgendwann geglaubt. Solange nichts zugewiesen ist und die Codes nirgends
außerhalb der Datenbank auftauchen, kostet die Umbenennung nichts. Nach der
Inbetriebnahme kostet sie eine Datenmigration und die Frage, was in bereits
ausgegebenen Nachweisen steht.

**Was das nicht heißt:** Ob Codes später außerhalb der Anwendung sichtbar werden
— in Exporten, Listen, Zeugnissen — ist offen. Genau deshalb jetzt.

---

## E15 — Testskript um die Fallstricke erweitern (05.09.2026)

**Vorbemerkung zur Nummer:** E10 ist nie geschrieben worden — der Block blieb
unausgeführt. Die Nummer bleibt unbesetzt, ihr Inhalt steht als E16.

**Anlass:** Schritt 0 des Auftrags `docs/AUFTRAG-testskript.md` hat die Annahme
widerlegt, es gebe kein Testskript. `tests-projektstunden.sh` liegt seit fd0412e
im Repo, 47 Prüfungen, alle grün, Exit-Code 0.

**Befund:** Der Schwerpunkt liegt auf dem CI-Umbau. Von den Fallstricken aus
`FALLSTRICKE.md` prüft es einen einzigen, und den als reine Vorkommensprüfung:
`grep -q "session_name('proj_session')"` geht auch dann grün, wenn die Zeile ans
Dateiende rutscht — also im Fehlerfall. Nicht geprüft: `empty()` auf eine ID,
die 0 sein kann, `session.save_path` per `ini_set()`, JSESSIONID-Weitergabe,
`personId <= 0`, Fremdschlüssel auf 0 im `UPDATE`, kritische IDs im DOM.

Zwei weitere Befunde sind keine Entscheidung, sondern Verstöße gegen
REIHENREGELN 2: Fehlt `node` oder `php`, zählt die Prüfung weder grün noch rot;
und das Skript wird nirgends aufgerufen — weder in `deploy.sh` noch in
`CLAUDE.md`.

**Entscheidung:** `tests-projektstunden.sh` bekommt eine Rubrik „Fallstricke".
Die Vorkommensprüfung auf `session_name` und `$_SERVER['HTTPS']` wird durch eine
Reihenfolgeprüfung **ersetzt**, nicht ergänzt. `deploy.sh` ruft das Skript vor
dem Push auf und bricht bei Exit-Code ungleich 0 ab. Kein zweites Skript
daneben.

**Warum:** Eine Vorkommensprüfung, die im Fehlerfall grün geht, ist schlechter
als keine — sie sieht aus wie Absicherung. Ein zweiter Aufruf beim Deploy würde
vergessen; die 47 vorhandenen Prüfungen belegen das, sie laufen heute nirgends.

**Was das nicht heißt:** Die CI-Prüfungen bleiben unangetastet. Sie stammen aus
einem anderen Arbeitsstrang.

---

## E16 — WebUntisAuth ist auseinandergelaufen, Zusammenführung wird vertagt (05.09.2026)

**Anlass:** Ein Vergleich der Projektstunden-Kopie mit `hornse/webuntis-auth-php`
zeigte drei verschiedene Stände. Das Modul-Repo hat genau einen Commit, c257d19
vom 09.07.2026. In den Projekten wurde seither weitergearbeitet, ohne dass etwas
zurückfloss — entgegen REIHENREGELN 6.

**Befund:** Die Projektstunden-Kopie hat `authenticateAndGetDetails()` als
öffentliche Methode und `authenticate()` nur als Alias; im Modul ist es umgekehrt
und `authenticateAndGetDetails()` fehlt ganz. Ein Überschreiben der Datei gäbe
einen Fatal Error beim ersten Anmeldeversuch. In **beiden** Fassungen fehlt die
Auswertung von `klasseId` und die Selbstanlage des Schülers beim ersten Login —
beides am 09.07.2026 gebaut, nie ausgeliefert. E3 beschreibt damit einen Zustand,
den der Code nicht hat.

**Entscheidung:** Die Zusammenführung wird nicht nebenbei erledigt, sondern als
eigener Auftrag, nachdem E15 umgesetzt ist. Bis dahin bleibt jede Kopie, wie sie
ist.

**Warum:** Drei Stände zusammenzuführen ist kein Kopiervorgang, und die
betroffene Stelle ist die Anmeldung — ein Fehler dort sperrt alle aus, auch den,
der ihn beheben müsste. Ohne die Prüfungen aus E15 wäre das Ergebnis nicht
belegbar.

**Was das nicht heißt:** E7 gilt weiter. Das Modul bleibt der Ort, an dem
gepflegt wird; es ist nur derzeit nicht der aktuelle Stand.
