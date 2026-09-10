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

---

## E17 — Ein 401 beim Login erzeugt einen TypeError statt einer Meldung (05.09.2026)

**Anlass:** Beim Durchsehen des Frontends im Zuge der Prüfungserweiterung
gefunden, nicht gesucht.

**Befund:** `api()` gibt bei Status 401 `null` zurück. Für `auth/login` und
`auth/me` unterbleibt dabei der Sprung zurück auf die Anmeldemaske — sonst
verließe der Benutzer sie beim ersten Tippfehler. Der Rückgabewert bleibt aber
`null`. `doLogin()` liest anschließend `me.typ` ohne Nullprüfung. Der TypeError
wird von der umgebenden Fehlerbehandlung gefangen und als Meldung ausgegeben.
Wer sein Passwort falsch eingibt, liest also eine JavaScript-Fehlermeldung statt
„Ungültige Anmeldedaten."

**Herkunft:** Die Ausnahme in `api()` stammt aus einer Änderung vom 07.07.2026.
Sie behebt ein echtes Problem — der Sprung zurück zur Anmeldemaske beim ersten
Fehlversuch — und hat die Folge für `doLogin()` nicht mitbedacht.

**Entscheidung:** Wird festgehalten, nicht jetzt behoben. Die Behebung ist ein
eigener Vorgang mit eigener Prüfung.

**Warum nicht jetzt:** Es ist keine Sicherheitslücke und kein Datenverlust,
sondern eine unbrauchbare Meldung im häufigsten Fehlerfall. Sie nebenbei zu
beheben hieße, an der Anmeldung zu arbeiten, während eine andere Sache läuft —
und die Anmeldung ist die Stelle, an der ein Fehler alle aussperrt.

**Was das nicht heißt:** Die Ausnahme in `api()` wird nicht zurückgenommen. Sie
ist richtig; fehlerhaft ist die fehlende Nullprüfung in `doLogin()`.

---

## E18 — E11 wird aufgehoben: benannte Spalten statt eines Baums (05.09.2026)

**Anlass:** E11 hat entschieden, `kompetenzbereiche` eine Selbstreferenz zu
geben. Begründet wurde das mit zwei Fächern: Englisch, weil es eine Ebene mehr
habe, und Sport, weil es zwei Inhaltsachsen gleichzeitig führe.

**Befund:** Beide Begründungen halten der Prüfung am Lehrplan nicht stand.

Bei Sport hängt die Bewegungs- und Wahrnehmungskompetenz an den
Bewegungsfeldern, Sach-, Methoden- und Urteilskompetenz hängen an den
Inhaltsfeldern. Die Achsen liegen nebeneinander, nicht übereinander. Die
Überschriften „Bewegungsfeld übergreifende" und „Bewegungsfeld spezifische
Kompetenzerwartungen" (Kapitel 2.4.1 und 2.4.2) benennen genau diese beiden
Achsen und sind keine weitere Ebene. Die Rechnung geht auf: 6 Inhaltsfelder × 3
Kompetenzbereiche × 2 Phasen = 36, plus 9 Bewegungsfelder × 2 Phasen = 18,
zusammen 54 — genau der Bestand in der Datenbank.

Bei Englisch liegt unter der Funktionalen kommunikativen Kompetenz eine Ebene
mit sieben Teilbereichen. Das ist eine fehlende Spalte, keine fehlende
Struktur.

Über alle 36 ausgewerteten Lehrpläne liegen unterhalb der Phase **nie mehr als
zwei** Gruppierungsebenen. Nur ihre Bedeutung wechselt: bei Deutsch und Sport
Inhaltsfeld und Kompetenzbereich, bei den Fremdsprachen Kompetenzbereich und
Teilbereich.

**Entscheidung:** E11 wird aufgehoben. Es bleibt bei benannten Spalten. Zu den
vorhandenen `phase`, `inhaltsfeld` und `kompetenzbereich` kommen
`teilbereich VARCHAR(80) NULL` für die Fremdsprachen und `art VARCHAR(30) NULL`,
das festhält, was in `inhaltsfeld` steht — bei Sport stehen dort Inhaltsfelder
und Bewegungsfelder nebeneinander, derzeit nur durch die Namenskonvention
`a:` gegen `BF/SB 1:` unterscheidbar. `parent_id` entfällt.

**Warum:** Eine Abfrage `WHERE inhaltsfeld = 'Sprache'` sagt einem Menschen, was
sie tut; ein rekursiver Ausdruck über `parent_id` verlangt, dass er erst
herausfindet, welche Knotenart auf welcher Ebene liegt. Dieses Datenmodell wird
über Jahre von wenigen Leuten angefasst, meist nach längerer Pause. Dazu kommt:
Jeder der siebzehn ausstehenden Fachimporte müsste beim Baum selbst für
Konsistenz sorgen — Elternknoten anlegen, ID merken, Kinder daranhängen. Bei
Spalten ist eine Zeile eine Zeile.

**Was das nicht heißt:** Die Tiefe ist damit fest. Taucht in einem Fach eine
dritte Gruppierungsebene auf, ist es wieder eine Migration. Die Auswertung
stützt sich auf die Gliederungsüberschriften aller 36 Pläne, nicht auf eine
vollständige Lektüre jedes einzelnen. Bei Sport hat sich eine Vermutung über
eine vierte Ebene erst durch Nachsehen erledigt.

---

## E19 — Erzeugte Fachdaten führen ihren Erzeuger und ihre Quelle mit (05.09.2026)

**Anlass:** `sql/11_seed_deutsch_sii.sql` nennt im Kopf `gen_deutsch_sii.py` als
Erzeuger. Ein `find` über das gesamte Repo findet keine einzige Python-Datei.
Die 197 Kompetenzerwartungen der Sekundarstufe II stehen in der Datenbank, ohne
dass nachvollziehbar wäre, wie sie dorthin kamen.

Derselbe Seed nennt als Quelle den Entwurf vom 31.07.2025 — überholt seit der
verabschiedeten Fassung vom 24.08.2026. Erkennbar war das nur an einer
Kommentarzeile, die ebenso gut hätte falsch sein können.

**Entscheidung:** Wo Fachdaten maschinell aus einer Quelle erzeugt werden,
gehören zwei Dinge ins Repo: das erzeugende Skript, und im Kopf der erzeugten
Datei der Dateiname der Quelle samt ihrer SHA256-Summe.

**Warum:** Ohne Erzeuger ist eine Korrektur nur von Hand möglich, und bei
mehreren hundert Einträgen heißt das: gar nicht. Ohne Prüfsumme ist die
Quellenangabe eine Behauptung — genau die, die hier ein Jahr lang falsch war,
ohne dass es jemandem auffiel.

**Was das nicht heißt:** Die Quell-PDFs selbst werden nicht mit versioniert. Die
Prüfsumme genügt, um festzustellen, ob eine vorliegende Datei dieselbe ist.

---

## E20 — Die Quell-PDFs werden doch versioniert (05.09.2026)

**Anlass:** E19 hält fest, dass die Prüfsumme genüge und die PDFs draußen
bleiben. Diese Festlegung stützte sich auf eine Größenannahme, die ich nie
geprüft hatte.

**Befund:** Der vollständige Bestand aus 37 Kernlehrplänen umfasst rund 16 MB;
die größte Einzeldatei liegt bei 1,0 MB. Kernlehrpläne werden zudem nicht
geändert, sondern durch eine neue Fassung unter neuem Dateinamen ersetzt — das
Verzeichnis wächst durch Zugänge, nicht durch Änderungen.

Geprüft wurde außerdem, ob die Ablage unter `docs/` erreichbar wäre: Neun
Abrufe auf Dateien außerhalb von `frontend/` — darunter `sql/01_schema.sql`,
`deploy.sh` und `backend/config.php` — liefern durchweg 500 mit der
1250-Byte-Fehlerseite von Uberspace, keinen Inhalt.

**Entscheidung:** Die PDFs liegen unter `docs/curricula/` im Repo, mit
unveränderten Dateinamen. `docs/curricula/INDEX.md` führt Datei, Fach, Stufe,
Stand und Prüfsumme zusammen. E19 gilt im Übrigen weiter — Erzeuger und
Prüfsumme im Kopf jedes Seeds bleiben Pflicht.

**Warum:** Ohne die Quelle ist der Erzeuger aus E19 nutzlos; ein Skript, das
ein PDF verarbeitet, das nirgends liegt, lässt sich nicht erneut ausführen. Die
Verweise auf die Lehrplannavigator-Seiten sind zudem unzuverlässig — sie zeigen
mal auf `schulentwicklung.nrw.de`, mal auf `lehrplannavigator.nrw.de`, einer
enthält ein URL-kodiertes Leerzeichen. Und bei Deutsch GOSt hat gerade das
Fehlen der Quelle dazu geführt, dass ein Entwurf ein Jahr lang unbemerkt als
verabschiedete Fassung galt.

**Was das nicht heißt:** Der Schutz vor Auslieferung ist keine Regel, sondern
eine Folge der Serverkonfiguration — `doc_root` ist beschränkt und der Dienst
läuft aus der Projektwurzel. Ändert jemand das eine oder das andere, wird
`docs/` erreichbar, und dann auch `backend/config.php`. Diese Abhängigkeit ist
als Befund für `koordination` vorgemerkt.

Die PDFs gehen über `deploy.sh` mit auf den Server. Bei 16 MB ist das
hingenommen, nicht übersehen.

---

## E21 — Der Quellennachweis wird an der Deklaration geprüft, nicht am Seed (06.09.2026)

**Anlass:** E19 verlangt, dass erzeugte Fachdaten Quelle, Prüfsumme und Erzeuger
im Kopf führen. Beim Bau der Prüfung stellte sich heraus, dass drei von vier
Seeds das nicht tun: `10_seed_deutsch_klp.sql` und `12_seed_sport_klp.sql`
nennen einen Erzeuger, der nicht existiert, und keiner der drei nennt Quelle
oder Prüfsumme. `sql/gen/` gibt es noch nicht.

**Entscheidung:** Die Prüfung greift für jeden Seed, der eine `-- Quelle:`-Zeile
führt: Die genannte Datei muss unter `docs/curricula/` liegen, ihre SHA256 muss
mit der angegebenen übereinstimmen, und ein genannter Erzeuger muss existieren.
Seeds ohne Quellenangabe fallen nicht durch.

**Warum:** Die Prüfung wörtlich zu bauen hieße, `deploy.sh` zu blockieren, bis
Deutsch Sek I und Sport nachgezogen sind — zwei Fächer, die nicht beauftragt
waren. Damit stünde auch der Auftrag still, in dessen Rahmen die Prüfung
entsteht.

**Was das nicht heißt:** Die Prüfung ist damit umgehbar, indem man die Zeile
weglässt. Sie wird erst dicht, wenn eine zweite dazukommt, die jeden Seed zur
Quellenangabe verpflichtet. Diese zweite Prüfung setzt voraus, dass
`10_seed_deutsch_klp.sql` und `12_seed_sport_klp.sql` ihre Quellen und Erzeuger
nachgetragen bekommen — offen, und hiermit festgehalten, damit der Rückstand
nicht in dieser Entscheidung verschwindet.

---

## E22 — Silbentrennung wird am Dokument selbst entschieden (06.09.2026)

**Anlass:** In den Kernlehrplan-PDFs ist der Trennstrich am Zeilenende dasselbe
Zeichen wie ein echter Bindestrich. Geprüft am Deutsch-GOSt-Plan: 609× U+002D,
kein einziger Soft Hyphen. Eine Regel, die alle Bindestriche am Zeilenende
auflöst, zerstört `nicht-fiktionalen`, `historisch-gesellschaftliche` und
`(fach-)sprachlich`.

**Entscheidung:** Für jede Trennstelle `A-` / `B` entscheidet das Dokument
selbst, in dieser Reihenfolge:

1. `B` ∈ {und, oder, bzw., sowie} → Ellipse (`Figuren- und Handlungsebene`),
   Bindestrich bleibt.
2. `AB` kommt ungetrennt im Dokument vor, `A-B` nicht → Trennung auflösen.
3. `A-B` kommt ungetrennt vor, `AB` nicht → echter Bindestrich, bleibt.
4. Sonst → auflösen.

Fortsetzungszeilen werden über die Einrückung erkannt, nicht über Satzzeichen.

**Warum:** Die Ellipsenregel und die beiden Wörterbuchregeln decken im
Deutsch-GOSt-Plan 106 von 130 Entscheidungen belegt ab. Regel 4 ist der einzige
ungestützte Zweig; ihre 24 Fälle wurden einzeln durchgesehen. Eine Regel „bis
zum nächsten Komma" für Fortsetzungszeilen ist nachweislich falsch — Einträge
enthalten Kommata mitten im Satz.

**Was das nicht heißt:** Regel 4 bleibt eine Vermutung je Einzelfall. Bei jedem
weiteren Fach gehört die Liste der nach Regel 4 entschiedenen Fälle in den
Bericht, damit sie durchgesehen werden kann.

Nebenbefund: Zeichenzahlen aus `pdftotext` sind versionsabhängig — dieselbe
Datei ergab 106 153 und 106 149 Zeichen bei verschiedenen poppler-Ständen.
Als Sollwert taugen nur Strukturzahlen.

---

## E23 — Eine Quellenangabe mit Schema ist ein Literaturhinweis (06.09.2026)

**Anlass:** Die Prüfung aus E21 meldete `02_seed.sql` rot. Die Datei führt seit
jeher `-- Quelle: https://medienkompetenzrahmen.nrw`. Der Medienkompetenzrahmen
ist der eine Rahmen, der laut E8 korrekt ist — er kam aus einer eigenen Vorlage
und wurde nie aus einem PDF erzeugt.

**Entscheidung:** Die Prüfung greift nur für Quellenangaben, die auf einen Pfad
zeigen. Beginnt die Angabe mit `http://` oder `https://`, gilt sie als
Literaturhinweis und wird übergangen.

**Warum:** Eine Webadresse hat keine Prüfsumme. Die Prüfung auf sie anzuwenden
hieße, einen Gegenstand zu verlangen, den es nicht gibt — und der einzige
Rahmen, der von Anfang an stimmte, fiele als erster durch.

**Verworfen:** `02_seed.sql` die Zeile in `-- Herkunft:` umzubenennen. Dann
hinge die Bedeutung von `-- Quelle:` an einer Namenskonvention, die niemand
kennt, und eine Datei außerhalb des laufenden Auftrags wäre geändert worden.

**Was das nicht heißt:** E21 wird dadurch nicht dichter. Wer die Prüfung
umgehen will, schreibt eine URL hin. Das ist dasselbe Schlupfloch, das E21
bereits benennt, und es schließt erst die zweite Prüfung, die jeden Seed zur
Quellenangabe verpflichtet.

---

## E24 — Das Testskript gibt keine Prüfungszahl aus (06.09.2026)

**Anlass:** Beim Bau der Fachdatenprüfungen fiel auf, dass
`tests-projektstunden.sh` „ALLES GRÜN" oder „n FEHLER" ausgibt, sonst nichts.
Die Zahlen 48 und 50 in den Berichten dieser Sitzung wurden durch Abzählen der
Häkchen ermittelt, nicht abgelesen.

`CLAUDE.md` behauptet seit `f160c2a`, das Skript gebe die Zahl aus. Das ist
falsch und stammt aus einem Text, der geschrieben und nicht nachgesehen wurde —
in derselben Sitzung bereits der dritte Fall dieser Art.

**Entscheidung:** Wird festgehalten, nicht in diesem Auftrag behoben. Die
Behebung ist der erste Punkt des nächsten.

**Warum das zählt:** REIHENREGELN 2 verlangt die Prüfungszahl in der
Commit-Meldung, damit auffällt, wenn eine Erweiterung nicht wirksam wird oder
eine Prüfung verschwindet. Solange die Zahl abgezählt werden muss, hängt die
Regel an der Sorgfalt des Einzelnen — und eine Angabe, die nicht gepflegt wird,
ist schlechter als keine.

**Nachtrag zu E22 (06.09.2026):** Der einzige Regel-4-Fall mit inhaltlichem
Gewicht — `Autor-` / `schaft` in DE_QGK_UEB_REZ_08 und DE_QLK_UEB_REZ_08 — ist
belegt, nicht mehr nur gestützt. Der Entwurf vom 31.07.2025 führt denselben Satz
ungetrennt: „…sprachlich-stilistische Angemessenheit und im Hinblick auf Fragen
der Autorschaft". Die einzige `Autorenschaft` steht in beiden Fassungen in
Kapitel 3, außerhalb des Kompetenzteils. Der Lehrplan verwendet beide Wörter,
jedes an seinem Ort. Damit sind alle 24 Regel-4-Fälle eindeutig.

Verfahrenshinweis für künftige Fächer: Wo Regel 4 über ein inhaltlich relevantes
Wort entscheidet, lohnt der Blick in eine frühere Fassung derselben Quelle. Ein
anderer Satzspiegel bricht an anderer Stelle um und liefert das Wort ungetrennt.

---

## E25 — Steuerzeichen aus PDF-Text werden vor der Normalisierung entfernt (06.09.2026)

**Anlass:** Der Wortlautvergleich beim Sport-Import meldete eine Abweichung, die
im Text unsichtbar war: `… auf<U+0003>grundlegendem Niveau bewerten`. An dieser
einen Stelle liefert `pdftotext` ein Steuerzeichen statt eines Leerzeichens.

**Befund:** `U+0003` ist in Python kein `\s`; `re.sub(r"\s+", " ", …)` fasst es
nicht. Im PDF kommt es 26-mal vor, davon 25-mal im Inhaltsverzeichnis und genau
einmal im Kompetenzteil. Der Bestand enthält es nicht — der frühere Erzeuger hat
es behandelt, ohne dass es irgendwo vermerkt war.

Im selben Lauf fiel eine zweite Form auf: Drei von 120 Aufzählungszeilen
beginnen mit einem Seitenumbruch `\x0c` statt einem Leerzeichen. Ein Ausdruck
`^ *à` verliert sie. Aufgefallen ist es nicht durch Suche, sondern weil die Zahl
117 nicht zu den erwarteten 120 passte.

**Entscheidung:** Jeder Erzeuger wandelt vor der Normalisierung alle
C0-Steuerzeichen außer Tabulator, Zeilen- und Seitenumbruch in Leerzeichen. Die
Erkennung von Aufzählungszeilen berücksichtigt einen führenden Seitenumbruch.

**Warum:** Beides ist unsichtbar und wandert stillschweigend in die Daten. Nur
der Wortlautvergleich gegen einen vorhandenen Bestand hat es gefangen — bei
einem Fach ohne Vorgänger gäbe es diesen Vergleich nicht.

**Was das nicht heißt:** Die Liste der Steuerzeichen ist aus einem Dokument
gewonnen. Bei jedem weiteren Fach gehört eine Auszählung der Zeichen oberhalb
des druckbaren Bereichs in den Bericht.

---

## E26 — Bei Widerspruch zwischen Bestand und Quelle gilt die Quelle (06.09.2026)

**Anlass:** Der Sport-Import fand zwei Bereichsnamen, in denen der Bestand von
seiner eigenen Quelle abweicht: `Rollsport/Bootssport/Wintersport` gegenüber
`Rollsport, Bootssport, Wintersport` im Lehrplan. Beide Fundstellen im PDF
führen Kommas; eine dritte Schreibweise gibt es nicht.

**Entscheidung:** Der Erzeuger folgt der Quelle. Die Anweisung in Auftragsdateien
„Codes und Anzeigenamen aus dem Bestand rekonstruieren, nicht neu erfinden"
gilt für Formregeln — Codeschema, Kürzungsgrenzen, Sortierung —, also für
Festlegungen, die im Lehrplan nicht stehen. Wo der Lehrplan etwas sagt, gilt er.

**Warum:** Eine Ausnahme im Erzeuger, die eine abweichende Schreibweise erhält,
schreibt einen Übertragungsfehler fest und macht ihn unauffindbar.

**Was das nicht heißt:** Abweichungen werden nicht stillschweigend übernommen.
Sie werden vorgelegt und einzeln entschieden — bei Deutsch GOSt waren fünf von
elf Fehler des Bestands, bei Sport zwei von drei. Ohne den Vergleich wäre keiner
davon aufgefallen.

---

## E27 — Fachdaten werden am Inhalt erkannt, nicht am Dateinamen (06.09.2026)

**Anlass:** Für die zweite Quellenprüfung — jeder Seed deklariert eine Quelle —
war offen, woran ein Seed zu erkennen ist. Drei Fassungen wurden in einem
Probebaum gegen den Bestand und gegen drei erfundene Fälle durchgespielt.

**Befund:** Alle drei treffen heute dieselben vier Dateien. Sie laufen erst in
der Zukunft auseinander. Die Fassung über den Dateinamen (`*seed*`) hat beide
Fehlerarten: Sie verfehlt einen künftigen Fachimport, der anders heißt, und
verlangt eine Quelle von Testdaten, die keine Fachdaten führen. Die Fassung
über den Inhalt, zeilenweise angewandt, verfehlt ein `INSERT INTO`, dessen
Tabellenname in der nächsten Zeile steht.

**Entscheidung:** Eine Datei unter `sql/` führt Fachdaten, wenn sie nach
Entfernen aller Kommentarzeilen ein `INSERT [IGNORE] INTO kompetenzen` oder
`… kompetenzbereiche` enthält — dateiweit geprüft, nicht zeilenweise. Nur diese
Dateien müssen eine Quelle deklarieren.

**Warum:** Der Name ist eine Konvention, das Schreiben in die Fachtabellen ein
Wesensmerkmal (REIHENREGELN 4). Die Kommentarentfernung verhindert, dass der
Ausdruck auf die Beschreibung der Regel anschlägt statt auf die Sache; sie hat
eine eigene Gegenprobe.

**Was das nicht heißt:** Die Prüfung sagt nur, dass eine Quelle deklariert ist.
Ob sie stimmt, prüft die Regel aus E21 — beide zusammen schließen das
Schlupfloch, keine allein.

---

## E28 — E22 bekommt eine fünfte Regel, und E25 eine Grenze (06.09.2026)

**Anlass:** Der Deutsch-Sek-I-Import erzeugte zwei falsche Kompetenztexte:
`LautBuchstaben-Ebene` statt `Laut-Buchstaben-Ebene`, und `Satz-und Textebene`
statt `Satz- und Textebene`. Beide wurden nur durch den Wortlautvergleich gegen
den geprüften Bestand gefunden.

**Erstens — Großbuchstabe heißt echter Bindestrich.** In E22 wird zwischen
Regel 3 und Regel 4 eingeschoben: *Beginnt die Fortsetzung mit einem
Großbuchstaben, gilt der Bindestrich als echt und bleibt stehen.*

Begründung nicht statistisch, sondern orthografisch: Eine Silbentrennung führt
nie zu einem Großbuchstaben; ein Bindestrich vor einem Großbuchstaben ist ein
Kompositum-Bindestrich. Über die drei bisher importierten Fächer hinweg gibt es
genau einen Regel-4-Fall mit Großbuchstaben-Fortsetzung — diesen, und er war
falsch entschieden.

Die Stellung ist nicht beliebig: Die neue Regel steht **hinter** den Regeln 2
und 3, die das Dokument selbst befragen. Wo ein Beleg vorliegt, gilt der Beleg;
die Faustregel greift nur, wo keiner vorliegt.

**Zweitens — Ellipsenregel auch innerhalb der Zeile.** Wo ein Bindestrich
unmittelbar an `und`, `oder`, `bzw.` oder `sowie` stößt, wird ein Leerzeichen
eingefügt. Bisher galt E22 Regel 1 nur über Zeilengrenzen hinweg. `Satz-und`
ist im Deutschen keine mögliche Wortform, gleich woher die Lücke stammt — hier
verschluckt `pdftotext` den Wortabstand, im PDF ist er zu eng gesetzt. Im
gesamten Dokument trifft die Regel genau eine Stelle.

**Drittens — E25 gilt für C0, nicht für C1.** Der Deutsch-Sek-I-Plan verwendet
`U+0083`, ein C1-Steuerzeichen, als Aufzählungsmarker für die 42 übergeordneten
Kompetenzerwartungen. Eine Ausweitung der Steuerzeichen-Entfernung auf C1 hätte
sie spurlos gelöscht — und die Gesamtzahl hätte weiter gestimmt, weil die
Zählung dieselbe Quelle liest.

Deshalb zusätzlich: Wo ein Plan mehrere Aufzählungsmarker führt, prüft der
Erzeuger die Aufteilung je Marker, nicht nur die Summe. Beim Deutsch-Sek-I-Plan
sind das 42 zu 184.

**Was das nicht heißt:** Regel 4 bleibt der ungestützte Zweig. Ihre Fälle
gehören weiterhin einzeln in den Bericht.

---

## E29 — E12, E14 und der Rückstand aus E21 sind erledigt (06.09.2026)

**Anlass:** Drei Festlegungen standen offen, alle am selben Seed. Dieser
Eintrag hält fest, dass sie umgesetzt sind — nach REIHENREGELN 10 als neuer
Eintrag, nicht als Änderung der alten.

**E12 und E14, offen seit dem 02.09.2026:** Die 21 übergeordneten
Kompetenzerwartungen aus Kapitel 2.3 des Deutsch-Lehrplans Sek I trugen die
Phase `zweite_stufe`, gelten aber für die gesamte Sekundarstufe I. Sie haben
jetzt `sek1_uebergreifend` und die Codes `DE_S1U_UEB_REZ_01` bis `_08` sowie
`DE_S1U_UEB_PRO_01` bis `_13`. Migration 14 hat den ENUM erweitert; der neue
Wert steht zwischen `erprobungsstufe` und `erste_stufe`, weil die Reihenfolge
eines ENUM in MariaDB die Sortierreihenfolge ist.

Die Umbenennung kostete nichts, weil `projekt_schueler_kompetenzen` null
Zuweisungen auf `DEU_KLP` führt — geprüft, nicht angenommen. Alle 228
vorhandenen Zuweisungen hängen am MKR, den der Seed nicht berührt. Nach der
Inbetriebnahme wäre dieselbe Änderung eine Datenmigration gewesen; genau das
war die Begründung von E14.

**Der Rückstand aus E21:** `10_seed_deutsch_klp.sql` war die letzte Datei mit
Fachdaten ohne Quellennachweis. Sie hat jetzt einen Erzeuger, Quelle und
Prüfsumme im Kopf. Damit ist die zweite Quellenprüfung (E27) überhaupt erst
grün zu bekommen — sie lief beim Bau nachweislich rot und wurde es durch diese
Umsetzung.

**Was das nicht heißt:** Der Kompetenzkatalog ist damit nicht fertig. Von 21
Fachrahmen sind drei befüllt und belegt; `teilbereich` (E18) wartet weiterhin
auf Englisch, und WP Wirtschaft aus E13 liegt weiterhin nicht vor.

---

## E29 — E18 wird aufgehoben: doch der Baum (06.09.2026)

**Anlass:** Die Strukturerhebung über alle 37 Kernlehrpläne (Commit 65ef22a,
`docs/curricula/STRUKTUR.md`). Sie wurde beauftragt, weil das Datenmodell
zweimal auf einer Stichprobe der Gliederungsüberschriften entschieden und
zweimal widerlegt worden war.

**Befund:** Die größte belegte Tiefe ist 3 — Englisch, Französisch und Spanisch
der Sekundarstufe I führen unter „Verfügen über sprachliche Mittel" eine vierte
Ebene mit Wortschatz, Grammatik, Aussprache und Intonation, Orthografie.

Wichtiger als diese Zahl ist eine andere: **Bei 16 der 37 Pläne ist die
Gliederung nicht gelesen.** Marker, Spaltigkeit, Steuerzeichen und Zählwerte
sind für alle erhoben, die Ebenen darunter bei 16 offen — darunter alle
Naturwissenschaften der Oberstufe, Sozialwissenschaften mit 68 Seiten und zwei
Fächern sowie beide Mathematikpläne.

Drittens schwankt die Tiefe innerhalb eines Plans: Bei Englisch führen zwei der
fünf Kompetenzbereiche eine dritte Ebene, drei haben Tiefe 1.

**Entscheidung:** E18 wird aufgehoben. `kompetenzbereiche` bekommt `parent_id`
als Selbstreferenz. `phase` und `art` bleiben eigene Spalten — die Phase liegt
quer zur Schachtelung, `art` sagt, was ein Knoten ist. `inhaltsfeld`,
`kompetenzbereich` und `teilbereich` entfallen, nachdem die vier vorhandenen
Rahmen umgeformt sind.

**Warum:** Ein Schema mit fester Tiefe setzt voraus, dass die größte Tiefe
bekannt ist. Sie ist es bei 16 Plänen nicht, und sie zu ermitteln kostet einen
zweiten Lesedurchgang — nach dem immer noch offen bliebe, ob eine künftige
Lehrplanfassung eine Ebene ergänzt. Der Baum braucht diese Kenntnis nicht.

Die Umformung ist heute so billig, wie sie je sein wird: Für Deutsch Sek I,
Deutsch GOSt und Sport existieren Erzeuger, die sich neu laufen lassen; der MKR
ist flach und wird zu sechs Wurzelknoten. Bei sechzehn weiteren Fächern wäre
sie es nicht mehr.

**Was das nicht heißt:** Die Gründe aus E18 gelten weiter. Eine Abfrage über
`parent_id` ist schwerer zu lesen als eine über `inhaltsfeld`, und jeder
Erzeuger muss die Baumkonsistenz selbst herstellen. Das ist der Preis, nicht
ein Einwand, der sich erledigt hätte. Er ist über `art` und sprechende
Knotennamen zu mildern, nicht aufzuheben.

**Zur Vorgeschichte:** E11 hat den Baum beschlossen, E18 ihn verworfen, E29
stellt ihn wieder her. Der Fehler lag beide Male in derselben Stelle — E18
stützte sich auf eine Auswertung der Gliederungsüberschriften und hielt im
selben Eintrag fest, dass diese keine vollständige Lektüre ersetzt.

---

## E30 — Zwei Einträge tragen die Nummer E29 (07.09.2026)

**Anlass:** Beim Bau des Baum-Auftrags fiel auf, dass `docs/ENTSCHEIDUNGEN.md`
zwei Einträge mit der Nummer E29 führt, beide vom 06.09.2026: den Abschluss von
E12, E14 und dem Rückstand aus E21, und die Aufhebung von E18 zugunsten des
Baums. Sie entstanden in zwei Vorgängen, die dieselbe höchste Nummer vorfanden.

**Entscheidung:** Beide Einträge bleiben, wie sie sind. Umnummerieren wäre eine
Änderung an einem alten Eintrag (REIHENREGELN 10). Zur Unterscheidung gilt:
**E29a** ist der Abschlusseintrag zu E12/E14/E21, **E29b** die Aufhebung von
E18. Verweise auf den Baum-Beschluss nennen E29b.

**Warum:** Ein Verweis auf „E29" ist nicht mehr eindeutig, und der Baum-Beschluss
wird künftig oft zitiert — in `sql/gen/README.md`, in jedem Fachimport.

**Vorbeugend:** Wer einen Eintrag anfügt, sieht vorher die höchste vergebene
Nummer nach. Dass zwei Vorgänge am selben Tag dieselbe vorfanden, lag daran,
dass der eine seinen Eintrag schrieb, während der andere lief.

---

## E31 — Knotenmodell des Kompetenzbaums (07.09.2026)

**Anlass:** Umsetzung von E29b. Vier Fragen waren offen, die jede spätere
Abfrage betreffen.

**Phase bleibt Spalte, wird kein Knoten.** Belegt am Code: `app.js:1209` filtert
die Katalogansicht über `k.phase`, `index.php:541` liefert `kb.phase` mit jeder
Kompetenz aus. Ein Phasenknoten zwänge diese Abfragen, den Baum hinaufzusteigen.
Dazu liegt die Phase quer zur Schachtelung — bei Deutsch Sek I tragen vier
Phasen dieselben Inhaltsfelder; Phasenknoten würden die Inhaltsfeldnamen
vervierfachen, ohne eine Beziehung auszudrücken, die es gibt.

**Kompetenzen hängen nur an Blättern.** Ein Knoten mit Kindern trägt keine
Kompetenzen. Das ist statisch am Seed prüfbar und fängt den Fehler, bei dem ein
Erzeuger eine Ebene vergisst und die Kompetenzen zu hoch anhängt.

Ausdrücklich: Das ist eine **Festlegung für den Aufbau, keine Beobachtung über
alle 37 Lehrpläne** — bei 16 ist die Gliederung nicht gelesen (E29b). Verletzt
ein künftiges Fach sie, schlägt die Prüfung an, und dann wird entschieden, nicht
stillschweigend angepasst.

**`art` steht an jedem Knoten** und sagt, was der Knoten ist. Werte:
`inhaltsfeld`, `bewegungsfeld`, `kompetenzbereich`, `medienkompetenzbereich`.
Die Liste steht im Spaltenkommentar, nicht in einem ENUM.

`medienkompetenzbereich` ist eine eigene Sorte, weil ein MKR-Bereich („Bedienen
und Anwenden") inhaltlich gliedert, ein Kompetenzbereich bei Deutsch
(„Rezeption") dagegen Rezeption von Produktion unterscheidet. Dasselbe Wort für
beides wäre die Zweideutigkeit, die `art` beenden soll.

Der MKR ist zudem der einzige Rahmen, dessen Knoten **Wurzel und Blatt zugleich**
sind — ein flacher Rahmen im Baummodell. Das gehört in den Spaltenkommentar,
sonst hält es jemand für einen Fehler.

**Knotennamen behalten den vollen Pfad**, also `Erprobungsstufe · Sprache ·
Rezeption`. Im Baum ist das redundant, aber `bereich_name` geht heute so an das
Frontend. Der Wechsel auf Kurznamen wäre eine Änderung an der Oberfläche und
gehört in einen eigenen Vorgang.

**Was das nicht heißt:** Die drei Baumprüfungen laufen statisch am Seed. Der MKR
wird per `UPDATE` behandelt und liegt damit außerhalb — für ihn gilt die
Integrität nur gegen die Datenbank, nicht beim Deploy. Diese Lücke ist bekannt
und in `sql/gen/README.md` festzuhalten.

---

## E32 — Ein Auswahlfeld für den Kompetenzkatalog, gruppiert nach Fach (07.09.2026)

**Anlass:** Der Kompetenzkatalog führte zwei unabhängige Und-Filter, `kat-rahmen`
und `kat-fach`. Belegt: Rahmen „Sport KLP NRW G9 Sek I" zusammen mit Fach
„Spanisch" ergibt „Keine Kompetenzen gefunden."

**Befund:** `kat-fach` wird aus `STATE.faecher` gefüllt — 18 Fächer, von denen
zwei Kompetenzen führen. Die 106 Kompetenzen des MKR zählen bei keinem Fach, weil
er `fach_id IS NULL` hat. Sechzehn von achtzehn Einträgen führen in eine leere
Ansicht.

**Entscheidung:** `kat-fach` entfällt. `kat-rahmen` wird ein Auswahlfeld mit
`<optgroup>` je Fach, jeder Eintrag mit der Zahl seiner Kompetenzen. Der MKR
steht unter „Fächerübergreifend". Aufgeführt werden alle Rahmen, auch leere —
sie sind dann als leer erkennbar statt als nicht vorhanden.

**Warum:** Zwei Felder, von denen jedes das andere widerlegen kann, sind ein Feld
zu viel. Die Zahl dahinter kostet nichts — `STATE.kompetenzen` liegt ohnehin im
Frontend — und sie beantwortet die Frage, die sonst nur ein leerer Bildschirm
beantwortet. Der Fall ist eingetreten: `WPWI_KLP` war nach E13 angelegt und
unbefüllt.

**Nicht geändert:** Die Fach-Filterung in `renderKompBereichListWe`. Sie tut
etwas anderes — dort leitet sich die Rahmenauswahl aus den angerechneten Stunden
ab (`#we-fach-grid`), ist also keine Filterbedienung, sondern eine Folge der
Stundenverteilung. Sie durch dieselbe Auswahl zu ersetzen hieße, einen Rahmen
wählbar zu machen, für den keine Stunden angerechnet sind. Das wäre eine
fachliche Änderung, keine Anzeigekorrektur. Ebenso unangetastet bleiben
`renderRahmenTabs` und `renderRahmenTabsWe`.

---

## E33 — Die Kompetenzauswahl beim Bearbeiten lebt außerhalb des DOM (07.09.2026)

**Anlass:** Beim Bau des Phasenfilters für die Werkstatt-Kompetenzauswahl fiel
ein Fehler auf, der älter ist und schwerer wiegt.

**Befund:** `openWerkstattBearbeiten` belegt die Auswahl über den Selektor
`#we-komp-bereich-list .komp-cb` vor. Gezeichnet wird aber
`class="we-komp-cb"`. Ein CSS-Klassenselektor trifft ganze Klassennamen, keine
Teilzeichenketten — `.komp-cb` trifft `we-komp-cb` nicht. Die Klasse `komp-cb`
gibt es nur in der Anlegen-Ansicht.

Folge: Beim Bearbeiten wird kein Häkchen gesetzt. Wer eine Werkstatt öffnet,
etwas anderes ändert und speichert, schickt `kompetenz_ids: []` — die
vorhandene Auswahl wird gelöscht. Der Fehler stammt aus dem Juli 2026 und ist
seither unbemerkt geblieben, weil eine leere Liste beim Speichern wie ein
gültiger Wert aussieht.

**Entscheidung:** Der Fehler wird behoben, und die Auswahl wandert aus dem DOM
in eine Menge `WS_EDIT_KOMP_IDS`. Sie wird beim Öffnen aus `proj.kompetenzen`
gefüllt, bei jedem Klick gepflegt und beim Speichern gelesen. Das DOM wird
gezeichnet, nicht befragt.

**Warum:** Ein Anzeigefilter, der Kacheln nicht zeichnet, entfernt sonst auch
ihre Häkchen — bei einer Werkstatt über zwei Phasen wäre der Phasenwechsel
Datenverlust. Die Alternative, alle Phasen zu zeichnen und per CSS zu verbergen,
löst weder den Selektor-Fehler noch das Mengenproblem: Bei Deutsch blieben 226
Kacheln im DOM, und genau das sollte der Filter vermeiden.

**Verhältnis zu E6:** E6 hat entschieden, kritische Werte ins DOM zu legen, weil
JavaScript-Variablen einen Deploy nicht überleben. Das ist kein Widerspruch,
sondern ein anderes Problem. E6 löst „überlebt einen Seitenneuladen"; hier geht
es um „überlebt ein Neuzeichnen innerhalb derselben Seite". Lädt die Seite
während des Bearbeitens neu, ist die Bearbeitung ohnehin verloren — die
Anwendung startet im Dashboard.

**Was dabei zu beachten ist:** Ersetzt `innerHTML` die Kachelliste, gehen daran
hängende Ereignisbehandlungen verloren. Jede Kachel muss ihren Zustand beim
Zeichnen aus der Menge lesen, sonst laufen Menge und Anzeige auseinander — das
wäre derselbe Fehler in neuer Form.

---

## E34 — Entfernen eines bewerteten Teilnehmers: warnen und mitlöschen (08.09.2026)

**Anlass:** Der Bearbeiten-Screen bekommt eine Teilnehmerverwaltung. Zu klären
war, was geschieht, wenn ein Teilnehmer entfernt wird, zu dem schon etwas
erfasst ist.

**Befund, der die Frage dreht:** „Bewertet" ist nicht an der Zeilenexistenz
ablesbar. Der PUT-Zweig legt beim Speichern der Kompetenzen für jeden
Teilnehmer × jede Kompetenz eine Zeile in `projekt_schueler_kompetenzen` an,
mit `fremd_stufe`, `selbst_stufe` und `notiz` sämtlich `NULL`. Werkstatt 4 hat
228 solcher Zeilen, davon 32 mit einer Fremdeinschätzung. Eine Zeile bedeutet
„diese Kompetenz gehört zu dieser Werkstatt", nicht „dieser Schüler wurde
bewertet".

Bewertet heißt deshalb:
`fremd_stufe IS NOT NULL OR selbst_stufe IS NOT NULL OR (notiz IS NOT NULL AND notiz <> '')`.
Bei `werkstatt_rueckmeldungen` ist jede Zeile Inhalt — sie entsteht nur durch
eine Eingabe.

**Entscheidung:** Gestaffelt. Ein Teilnehmer ohne Bewertung, ohne Rückmeldung
und ohne `abgeschlossen = 1` wird ohne Rückfrage entfernt. Andernfalls kommt
eine Rückfrage, die zählt, was verloren geht — „n Fremdeinschätzungen,
Rückmeldung vorhanden, als abgeschlossen markiert" —, und erst dann wird
entfernt.

Gelöscht wird ausdrücklich programmiert, in einer Transaktion, in dieser
Reihenfolge: `projekt_schueler_kompetenzen`, `werkstatt_rueckmeldungen`,
`projekt_schueler`. Nicht der Datenbank über `ON DELETE CASCADE` überlassen.

**Warum nicht verweigern:** „Verweigern" macht die Teilnehmerliste nach der
ersten Bewertung wieder unveränderlich — also genau den Zustand, den dieser
Auftrag beheben soll. Ein Schüler, der die Schule verlässt oder die Werkstatt
wechselt, bliebe dauerhaft eingetragen.

**Warum nicht ohne Löschen entfernen:** Verwaiste Zeilen tauchen in der
Kompetenzansicht wieder auf, weil sie über `projekt_id` und `schueler_id`
gelesen wird, nicht über den Teilnehmerbeitritt. Der Zustand existiert bereits
zweimal im Bestand; ihn zum Regelfall zu machen hieße, jede spätere Auswertung
an einen Sonderfall zu binden.

**Was das nicht heißt:** Das Löschen ist unwiederbringlich; es gibt kein
Papierkorb-Konzept. Der Schutz ist nicht die Unmöglichkeit des Entfernens,
sondern die Sichtbarkeit dessen, was verschwindet.

**Zu den zwei vorhandenen Waisen:** Sie werden aufgeräumt, aber erst nachdem
ihr Inhalt angesehen wurde. Trägt eine von ihnen eine Fremdeinschätzung, wird
sie vorgelegt statt gelöscht.

---

## E35 — Wie der PUT-Zweig Teilnehmer behandelt (08.09.2026)

**Anlass:** Umsetzung der Teilnehmerverwaltung im Bearbeiten-Screen.

**Fehlendes Feld ist nicht leere Liste.** `$body['schueler_ids'] ?? []` macht
aus „nicht geschickt" ein „alle entfernen". Geprüft wird mit `isset`, wie es
der Kompetenzblock in Zeile 898 bereits tut — nicht wie `lehrer_ids` in Zeile
872, wo `!empty()` verhindert, dass der letzte Lernbegleiter entfernt werden
kann. Für Teilnehmer wäre das falsch.

Dies ist derselbe Mechanismus wie `empty(0)` in FALLSTRICKE 3: ein
Sprachkonstrukt, das zwei verschiedene Zustände zu einem zusammenzieht.

**Der Teilnehmerblock steht vor dem Kompetenzblock.** Der Kompetenzblock liest
`projekt_schueler`, um jedem Teilnehmer die Kompetenzzeilen anzulegen. Steht er
davor, bekommt ein neu hinzugefügter Teilnehmer keine Kompetenzzeilen und
erscheint im Bewertungsscreen ohne jede Kompetenz.

**Der Teilnehmerblock trägt Kompetenzzeilen für neue Teilnehmer selbst nach.**
Sonst hinge das Ergebnis daran, dass ein Aufrufer `kompetenz_ids` immer
mitschickt. Eine Zusicherung, die von der Disziplin des Aufrufers abhängt, ist
keine.

**`max_schueler` greift nur bei Zuwachs.** Der PUT speichert das Maximum bisher
ohne jede Prüfung; so ist Werkstatt 4 mit zwölf Teilnehmern bei einem Maximum
von zehn entstanden. Eine harte Prüfung machte sie unspeicherbar, ohne dass
jemand etwas an ihr geändert hätte. Deshalb: Ein Speichern, das die
Teilnehmerzahl gleich lässt oder senkt, geht immer durch. Die Oberfläche zeigt
den Verstoß an, ohne zu blockieren. „Alle hinzufügen" fügt höchstens bis zum
Maximum hinzu und nennt, wie viele es ausgelassen hat.

---

## E36 — Rückmeldungen nur an Teilnehmer, Prüfung vor dem Schreiben (08.09.2026)

**Anlass:** `POST /api/rueckmeldung/{id}` schrieb für jede übergebene
`schueler_id`, ohne die Teilnahme zu prüfen.

**Befund:** Über die Oberfläche ist der Fall heute nicht mehr herstellbar. Die
Empfängerliste stammt aus `GET /bewertung`, das
`projekt_schueler_kompetenzen` liest — und seit E35 löscht das Entfernen eines
Teilnehmers dessen Kompetenzzeilen mit. Die Lücke bleibt für Direktaufrufe,
ältere Clients und künftige Oberflächen.

**Entscheidung:** Alle IDs werden zuerst gegen `projekt_schueler` geprüft. Ist
eine ungültig, wird nichts geschrieben; die Antwort nennt alle ungültigen IDs.

**Warum nicht überspringen:** Wer fünf Namen anhakt und „5 Rückmeldung(en)
gespeichert ✓" liest, verlässt sich darauf. Eine Meldung „3 von 5, 2
übersprungen" liest sich schnell weg. Wenn schon ein Sonderfall, dann einer,
der stehenbleibt.

Dass ein Aufruf mit gemischter Liste dann vollständig scheitert, kostet nichts:
Über die Oberfläche tritt er nicht auf, und wo er auftritt, ist der Aufruf
falsch zusammengesetzt.

**Nebenbei festgehalten:** Die Schreibschleife läuft ohne Transaktion. Mit der
Vorprüfung ist das unerheblich, weil vorher nichts geschrieben wird.

---

## E37 — Die zwei verwaisten Rückmeldungen werden gelöscht (08.09.2026)

**Anlass:** Zwei Zeilen in `werkstatt_rueckmeldungen` zu Werkstatt 2, deren
Personen keine Teilnehmer sind.

**Entscheidung:** Löschen, in einer eigenen Migration, mit `mysqldump` davor,
über die Bedingung „nicht Teilnehmer" statt über feste IDs — nach der Behebung
aus E36, sonst kann dieselbe Lücke sie sofort wieder erzeugen.

**Warum:** Beide tragen `bewertung_stufe = 3` ohne Freitext, in einer Werkstatt
namens „asdases". Sie sind ohne Bezug und ohne Inhalt.

**Was das nicht heißt — und was der Auftrag falsch behauptet hat:** Die
Auftragsdatei nannte E36 „die Ursache von Befund 2". Das ist unbelegt. Der
Endpunkt *erlaubt* es; dass es so geschah, weiß niemand. Die Oberfläche spricht
sogar dagegen: Bei Werkstatt 2 gibt es keine Kompetenzzeilen, also käme dort
keine Empfängerliste zustande. Es müsste ein früherer Stand, ein Direktaufruf
oder ein inzwischen gelöschter Kompetenzbestand gewesen sein. Der Versuch, der
es entscheiden würde, existiert nicht mehr.

Was belegt ist: Beide Betroffenen sind in Klasse 5, der Werkstatt 2
zugeordneten Klasse; die beiden echten Teilnehmer sind andere; beide Zeilen
entstanden in derselben Sekunde von Benutzer 1. Das Muster passt zu „vier Namen
angehakt, zwei davon keine Teilnehmer" — als Vermutung.

---

## E38 — Klassen entfernen ist zugelassen, Teilnehmer bleiben (08.09.2026)

**Anlass:** `projekt_klassen` wurde im PUT nie geschrieben; die
Klassenzuordnung war unveränderlich.

**Entscheidung, drei Teile:**

Das Entfernen einer Klasse wird nicht verweigert und löst keine Löschung von
Teilnehmern aus. Eine Klassenzuordnung ist eine organisatorische Angabe, keine
Aussage über Personen — wer sie ändert, sagt nicht „diese Schüler sollen weg".

`GET /api/werkstatt/{id}/schueler` liefert zusätzlich die tatsächlichen
Teilnehmer, auch wenn deren Klasse nicht mehr zugeordnet ist. Ohne das kostete
„zulassen und behalten" stillschweigend Bedienbarkeit: Der Endpunkt speist das
Details-Modal, in dem Teilnehmer als absolviert markiert werden. Ein Teilnehmer
aus einer entfernten Klasse verschwände dort — seine Zeile bliebe, die
Stundenanrechnung liefe weiter, nur bedienen könnte ihn niemand mehr.

Eine Rückfrage zählt, wie viele Teilnehmer zu den entfernten Klassen gehören,
ohne zu blockieren.

**Warum nicht verweigern:** Dieselbe Sackgasse wie bei E34. Werkstatt 4 hat alle
zwölf Teilnehmer aus einer Klasse; Verweigern hieße, diese Klasse wäre dort auf
Dauer nicht mehr entfernbar.

**Warum nicht mitlöschen:** E34 löscht mit, weil dort ein Mensch eine Person
abwählt und dazu gefragt wird. Hier wählt er eine Klasse ab; dass daran zwölf
Bewertungen hängen, ist eine Nebenfolge. Ein Klick auf „Klasse entfernen" darf
nicht 228 Kompetenzzeilen und 12 Rückmeldungen kosten.

**Form:** `isset($body['klasse_ids'])` wie bei `schueler_ids` (E35), nicht
`?? []`.

**`projekte.klasse_id`** wird nur nachgezogen, wenn der bisherige Wert nicht
mehr unter den zugeordneten Klassen ist. Sonst wechselte die „Hauptklasse" bei
jedem Umsortieren. Die Spalte wird an einer Stelle gelesen
(`index.php:592`), das Ergebnis verwendet das Frontend nirgends — der `INNER
JOIN` auf sie ist aber scharf: Zeigte sie ins Leere, lieferte
`GET /projekte/{id}` ein 404 „Werkstatt nicht gefunden", ohne dass etwas von
einer Klasse spräche. Die Absicherung `if ($klasse_id)` bleibt (FALLSTRICKE 4).

---

## E39 — Drei Antworten auf „wer gehört zu dieser Werkstatt" (08.09.2026)

**Anlass:** Beim Bau von E38 fielen drei Ansichten auf, die dieselbe Frage
verschieden beantworten.

**Befund:** `projekt_schueler` sagt, wer Teilnehmer ist. `projekt_klassen` sagt,
welche Klassen zugeordnet sind — und das Details-Modal listet daraus **alle**
Schüler dieser Klassen, bei Werkstatt 4 also 189 Namen für 12 Teilnehmer. Ein
Haken bei einem Nicht-Teilnehmer ruft `PUT /werkstatt/{id}/abschluss`, ein
reines `UPDATE` ohne `INSERT`: Es trifft null Zeilen, meldet `{"ok":true}`, und
der Haken verschwindet erst beim Neuladen.
`projekt_schueler_kompetenzen` speist die Bewertungstabelle — ein Teilnehmer
ohne zugewiesene Kompetenzen erscheint dort nicht und kann keine Rückmeldung
bekommen. Deshalb ist die Rückmeldungsansicht von Werkstatt 2 leer, obwohl vier
Rückmeldungen existieren.

**Entscheidung:** Festgehalten, nicht in diesem Auftrag behoben. Es sind drei
verschiedene Ansichten mit je eigener Begründung; sie zusammenzuführen ist eine
fachliche Entscheidung darüber, was eine Werkstatt ist, und kein Anhang an eine
Fehlerbehebung.

**Warum das zählt:** Eine Schaltfläche, die `{"ok":true}` meldet und nichts tut,
ist schlimmer als eine, die einen Fehler zeigt. Und eine Rückmeldungsansicht,
die vier vorhandene Rückmeldungen nicht zeigt, lässt den Benutzer glauben, es
gebe keine.

---

## E40 — Benutzertext wird genau einmal maskiert, und zwar bei der Ausgabe (08.09.2026)

**Anlass:** `werkstatt_rueckmeldungen.freitext` wurde weder beim Schreiben
noch bei der Ausgabe maskiert. Er landet an zwei Stellen roh in `innerHTML`:
in der Bewertungsansicht (`app.js`) und im **Schülerportal**. Eine Lehrkraft
mit Schreibrecht auf eine Werkstatt konnte damit Markup in die Ansicht eines
Minderjährigen schreiben.

**Befund:** `freitext` war das einzige Textfeld aus dem JSON-Body ohne
`clean()` — alle dreizehn anderen Fundstellen rufen es. Nachgewiesen mit einem
Freitext aus `<script>`, `<img onerror=…>`, `&` und Anführungszeichen: Er stand
unverändert in der Datenbank und kam durch beide Ansichten als lebendes Markup
heraus.

**Entscheidung:** Maskiert wird **einmal, bei der Ausgabe**, durch `escHtml()`
in `frontend/app.js`. `freitext` bleibt beim Schreiben absichtlich unmaskiert.

**Warum nicht beim Schreiben, wie der Rest:** Zwei Gründe, und der zweite ist
der wichtigere.

Erstens schützt eine Eingangsprüfung nicht, was vor ihr entstanden ist. Im
Bestand standen vier ungeprüfte Rückmeldungen; sie blieben gefährlich.

Zweitens gilt die Zusicherung „jeder Schreibweg ruft `clean()`" in diesem
Projekt nachweislich nicht. Der CSV-Import schreibt `vorname`, `nachname`,
`bezeichnung` und `klassenlehrer` mit blossem `trim()`, die WebUntis-Selbstanlage
ebenso. Wer sich auf die Schreibseite verlässt, verlässt sich auf eine Zusage,
die an anderer Stelle bereits gebrochen ist.

**Warum nicht beides:** Weil Maskierung nicht idempotent ist. Stünde `&amp;` in
der Datenbank und maskierte `escHtml()` erneut, käme `&amp;amp;` heraus, und
aus „Toll & gut" würde für den Leser sichtbar „Toll &amp; gut". Doppelt
maskieren ist kein Sicherheitsgewinn, sondern ein Anzeigefehler. Das Testskript
prüft deshalb ausdrücklich **beide Hälften**: dass bei der Ausgabe maskiert
wird, und dass es beim Schreiben nicht geschieht.

**Was das nicht heißt:** Die übrigen Felder werden **nicht** umgestellt. Sie
stehen maskiert in der Datenbank und werden roh ausgegeben; das zeigt sich
richtig an und ist gegen Einschleusung dicht, solange der Schreibweg `clean()`
ruft. Wer dort `escHtml()` ergänzt, ohne gleichzeitig `clean()` zu entfernen,
erzeugt genau den Anzeigefehler von oben. Die Umstellung wäre ein eigener
Vorgang mit einer Datenmigration.

**Offen, gemeldet, nicht behoben:** Der CSV-Import und die WebUntis-Selbstanlage
schreiben Namen ohne `clean()`, und 26 Zeilen in `app.js` geben Namen roh aus.
Ein Schülername aus einer feindlichen Importdatei wäre dieselbe Bauform. Das
braucht eine eigene Entscheidung — Schreibseite nachziehen oder Ausgabeseite
umstellen —, und die eine Hälfte ohne die andere macht es schlimmer.

---

## E41 — Namen werden bei der Ausgabe maskiert, `clean()` verlässt die Handanlage (08.09.2026)

**Anlass:** E40 meldete als offenen Punkt, dass Namen aus dem CSV-Import und der
WebUntis-Selbstanlage ohne `clean()` geschrieben und roh ausgegeben werden.

**Warum die Ausgabeseite, belegt am Code:** Der CSV-Import vergleicht feldweise
und zeichengenau gegen den Wert aus der Datei, der nur durch `trim()` gegangen
ist — in der Vorschau (`index.php:1942`) und im Zähler (`index.php:2079`).
Schriebe der Import maskiert, stünde `O&#039;Brien` in der Datenbank und
`O'Brien` in der Datei; jeder Lauf meldete diesen Schüler dauerhaft als
geändert. Betroffen wären Namen mit `&`, `<`, `>`, `"` oder Apostroph —
realistisch also O'Brien, D'Angelo und `&` in Klassenbezeichnungen.

Schwerer wiegt der Klassenabgleich (`index.php:2024`): Die Klasse wird über ihre
`bezeichnung` gesucht. Eine maskiert gespeicherte Bezeichnung würde beim
nächsten Import nicht gefunden, und es entstünde eine zweite Klasse gleichen
Namens. Das ist kein Anzeigefehler mehr, sondern doppelte Datenhaltung.

**Entscheidung, drei Teile:**

`escHtml` an allen Einbettungen mit Quelle `schueler` oder `klassen`,
einschließlich der Aliase `klasse` und `schuljahr`.

**`clean()` verlässt `POST /schueler` und `POST /klassen`.** Ohne das hätten
beide Felder zwei Schreibwege mit verschiedener Behandlung: Ein von Hand
angelegter `O'Brien` stünde maskiert in der Datenbank und würde bei der Ausgabe
ein zweites Mal maskiert — sichtbar als `O&#039;Brien`. E40 verbietet, `clean()`
zu ergänzen; es zu entfernen stellt die Konvention erst her. Keine
Datenmigration nötig: Kein Name und keine Bezeichnung im Bestand enthält ein
Zeichen, das `clean()` verändert hätte. Diese Zahl wird vor und nach dem Umbau
belegt.

Zeilen, die bewusst roh bleiben, tragen den Vermerk
`// keine-maskierung: <Grund>` am Ort.

**Warum der Vermerk in der Quelldatei und nicht als Liste im Testskript:**
Zeilennummern verrutschen bei jeder Änderung, und die Begründung stünde dort,
wo niemand sie liest. Am Ort steht sie vor der Nase dessen, der die Zeile
ändert.

**Warum nicht die vom Auftrag skizzierte Prüfung:** Sie hätte verlangt, dass
jede Einbettung eines Namensträgers durch `escHtml` läuft — und damit 40
Einbettungen zu Unrecht angemahnt, jede davon eine Stelle, an der Maskierung
falsch ist. Eine Prüfung, die in 45 Prozent der Fälle das Gegenteil des
Richtigen verlangt, wird abgeschaltet.

**Was die Prüfung nicht fängt — vollständig:**

1. Ein neuer Alias. Die Prüfung kennt die Feldnamen, die man ihr nennt. Genau
   daran ist die erste Zählung gescheitert: `${s.klasse}` ist
   `klassen.bezeichnung`, und keine Suche nach „bezeichnung" findet es. Benennt
   eine künftige API-Antwort ein Feld anders, bleibt die Stelle unsichtbar. Das
   ist die ernsteste Lücke, und es ist kein statisches Mittel dagegen bekannt.
2. Umweg über eine Variable. `const n = s.vorname; … ${n}` wird nicht gesehen.
   Das Muster gibt es bereits (`app.js:1416`).
3. Die falsche Wahl. Wer ein Feld maskiert, das bereits maskiert gespeichert
   ist, erzeugt `&amp;amp;` und kommt grün durch. Dagegen hilft nur die
   Handprüfung.

Die Entwertung von `escHtml` selbst ist abgedeckt — die Prüfung aus E40
verlangt alle fünf Ersetzungen und `&` als erste.

**Was das nicht heißt:** Die dreizehn Felder, die beim Schreiben maskiert
werden, bleiben unverändert. Sie stehen maskiert in der Datenbank und werden roh
ausgegeben. Wer dort `escHtml` ergänzt, ohne `clean()` zu entfernen, erzeugt
`&amp;amp;`.

---

## E42 — Zwei Befunde aus der Ausgabemaskierung, gemeldet und nicht behoben (08.09.2026)

**Erstens, und dringend: Die Import-Vorschau führt hochgeladenen Inhalt aus.**
`app.js:2206` und `2210` zeigen Namen direkt aus der hochgeladenen CSV-Datei,
ohne Umweg über die Datenbank. Wer eine Datei hochlädt, sieht ihren Inhalt
sofort als lebendes Markup — vor jedem Import, ohne dass etwas gespeichert
wurde. Der Weg hinein ist eine Datei; Dateien wandern per E-Mail. Das ist die
einzige Stelle ohne jeden Zwischenschritt und wird deshalb als erstes behoben,
mit eigener Handprüfung.

**Zweitens: `app.js:1463` ist heute schon funktionsunfähig.** Dort steht der
Name in einer JavaScript-Zeichenkette innerhalb eines HTML-Attributs — als
zweites Argument eines `onclick`-Aufrufs. Der Browser dekodiert Entities, bevor
der JS-Parser den Wert sieht: Aus einer maskierten Apostroph-Entity wird wieder
ein Apostroph, und dieser bricht aus der Zeichenkette aus.

`escHtml` genügt dort **nicht**. Das muss der Vermerk an der Zeile sagen, sonst
liest es jemand als „geprüft und in Ordnung".

Ein Schüler namens O'Brien macht damit heute die Schaltfläche „entfernen"
funktionsunfähig, ganz ohne Angriff. Die Behebung hat eine andere Bauform — den
Namen nicht durch den Aufruf reichen, sondern beim Klick aus dem DOM lesen —
und gehört in einen eigenen Vorgang.

---

## E43 — Der Vermerk steht in der Einbettung, nicht am Zeilenende (09.09.2026)

**Anlass:** Umsetzung von E41. Dort ist der Vermerk als
`// keine-maskierung: <Grund>` beschrieben, also als Zeilenkommentar. Das geht
nicht.

**Befund:** Von den 26 Zeilen, die bewusst roh bleiben, stehen **15 innerhalb
einer Vorlagenzeichenkette**. Ein `//` ist dort kein Kommentar, sondern Text —
er landete in der ausgelieferten Seite. Ein Blockkommentar **innerhalb der
Einbettung** funktioniert dagegen in beiden Zusammenhängen und erzeugt nichts:

```js
${/* keine-maskierung: benutzer, beim Schreiben maskiert */ b.vorname}
```

**Entscheidung:** Das ist die Form. Der Grund steht damit an der Einbettung
selbst, nicht an der Zeile — noch dichter am Gegenstand, als E41 vorsah.

Die Prüfung sucht nach der Zeichenfolge `${/* keine-maskierung:`. Diese Form
kann in Prosa nicht versehentlich entstehen; ein Ausdruck auf das blosse Wort
hätte auf jede Erklärung der Regel angeschlagen (REIHENREGELN 2).

**Eine Ungenauigkeit, die bleibt:** Der Vermerk befreit die **ganze Zeile**,
nicht nur die Einbettung, an der er steht. Eine Zeile mit zwei Trägern, von
denen nur einer begründet ist, kommt durch. Beim Bestand tritt der Fall nicht
auf — geprüft, nicht angenommen —, aber er ist möglich.

**Zahlen zur Umsetzung, gemessen statt geschätzt:**

| | |
|---|---|
| Einbettungen mit Namensträger insgesamt | 88 auf 50 Zeilen |
| davon maskiert | 46 auf 24 Zeilen |
| davon begründet roh | 42 auf 26 Zeilen |

Der Auftrag ging von „rund 26 Stellen" aus. Das war eine Zeilenzahl über zwei
der vier Feldnamen. Die Lücke lag woanders: **Die API liefert
`klassen.bezeichnung` als `klasse` aus** — `${s.klasse}` ist eine Einbettung
genau dieses Feldes, und keine Suche nach dem Spaltennamen findet sie. Dasselbe
gilt für `klassen.schuljahr`.

**`klassenlehrer` war nie betroffen:** Die Spalte heisst `klassenlehrer_name`,
wird ausschliesslich vom Import geschrieben und **nie gelesen** — kein `SELECT`,
keine Ausgabe.

**Belege zum Entfernen von `clean()` aus der Handanlage:** Vor dem Umbau 299
Schüler, davon 0 von Hand angelegt (alle mit `schild_id`), 0 mit einem Zeichen,
das `clean()` verändert hätte, 0 mit einer bereits gespeicherten Entity; 12
Klassen ebenso. Nach dem Umbau dieselben Zahlen. Eine Datenmigration war damit
nicht nötig, und das ist nachgerechnet, nicht angenommen.

---

## E44 — Die Fehlerliste der Import-Vorschau ist kaputt, und ihre Behebung ist eine Falle (08.09.2026)

**Anlass:** Beim Maskieren der Namensausgaben (E41) gefunden, nicht gesucht.

**Befund:** Das Frontend liest bei den Fehlern der Import-Vorschau ein Feld
`meldung`. Das Backend liefert an dieser Stelle `grund` und `daten`
(`index.php:1902`). Das gelesene Feld ist damit immer undefiniert, und weil die
Ausgabe auf das ganze Objekt zurückfällt, liest der Benutzer Zeilen der Form
„12: [object Object]" statt einer Fehlerbeschreibung.

Wer eine CSV-Datei mit fehlerhaften Zeilen hochlädt, erfährt also nicht, was an
ihnen fehlerhaft ist.

**Entscheidung:** Festgehalten, nicht behoben. Es ist ein Anzeigefehler, kein
Sicherheitsloch, und er lag außerhalb des laufenden Auftrags.

**Warum das trotzdem ins Protokoll gehört:** Die naheliegende Behebung ist eine
Sicherheitslücke. `daten` enthält den rohen Inhalt der hochgeladenen Zeile. Wer
nur den Feldnamen richtigstellt und den Wert wie bisher einbettet, stellt genau
den Zustand wieder her, den E41 und E42 beseitigt haben — hochgeladener Inhalt,
der ohne Umweg über die Datenbank als Markup ausgeführt wird.

Der nächste Bearbeiter sieht „falscher Feldname" und hält es für eine
Kleinigkeit. Deshalb steht es hier und nicht in einer Merkliste.

**Was bei der Behebung gilt:** `grund` ist eine Meldung aus dem Programm und
unbedenklich. `daten` stammt aus der hochgeladenen Datei und muss durch
`escHtml` — oder gar nicht angezeigt werden. Die Prüfung aus E41 fängt den Fall
nicht, weil `daten` kein Namensträger ist.

---

## E45 — E22 bekommt eine sechste Regel: belegte linke Kompositumshälfte (09.09.2026)

**Anlass:** Beim Englisch-Import fielen von 27 Trennstellen nach E22 Regel 4
zwei falsch aus: `kritisch- / reflektiert` und `kritisch- / distanzierend`
wurden zu `kritischreflektiert` und `kritischdistanzierend` aufgelöst.

**Befund:** Regel 5 greift nicht, weil die Fortsetzung mit einem Kleinbuchstaben
beginnt. Die Regeln 2 und 3 finden keinen Beleg, weil beide Wörter im Dokument
nur an dieser einen, getrennten Stelle vorkommen. Der Beleg liegt aber im
Dokument, nur an anderer Stelle: `kritisch-konstruktiv` steht dort ungetrennt.
`kritisch-` ist damit als linke Hälfte eines echten Kompositums belegt.

**Entscheidung:** E22 bekommt eine sechste Regel, eingeordnet **hinter Regel 3
und vor Regel 5**: *Kommt die linke Hälfte im Dokument als linke Hälfte eines
ungetrennt belegten Bindestrich-Kompositums vor, gilt der Bindestrich als echt.*

**Warum diese Stellung:** Die Regel stützt sich auf einen Beleg im Dokument,
wie die Regeln 2 und 3. Regel 5 ist eine orthografische Faustregel. Wo ein
Beleg vorliegt, gilt der Beleg — das ist dieselbe Ordnung, die E28 für Regel 5
festgelegt hat.

**Auflagen:** Vor dem Einbau ist zu belegen, dass die übrigen 25 Regel-4-Fälle
unberührt bleiben; die Zahl gehört in den Bericht. Und wie bei E28 sind die drei
vorhandenen Erzeuger mit der neuen Regel laufen zu lassen und gegen die
ausgelieferten Seeds zu halten. Erwartet ist keine Abweichung; kommt eine,
anhalten statt ausliefern.

**Was das nicht heißt:** Regel 4 bleibt der ungestützte Zweig. Ihre Fälle
gehören weiterhin einzeln in den Bericht.

---

## E46 — Knotenmodell und Codeschema für Englisch (09.09.2026)

**Anlass:** Englisch ist der erste Fachimport mit dritter Gliederungsebene.

**Die Interkulturelle kommunikative Kompetenz hat drei Unterbereiche.** Die
Sollzahlentabelle des Auftrags führte sie flach; `docs/curricula/STRUKTUR.md`
und der Lehrplan gliedern sie in Soziokulturelles Orientierungswissen,
Interkulturelle Einstellungen und Bewusstheit sowie Interkulturelles Verstehen
und Handeln. Die Summen stimmen (6 / 7 / 7), die Gliederung nicht.

**Entscheidung:** Die Ebene kommt mit. Damit 16 Blätter je Phase, zusammen
**48**, nicht die im Auftrag angesagten 42.

**Warum:** Nach E26 gilt bei Widerspruch zwischen Vorgabe und Quelle die Quelle.
Ohne die Ebene hingen 20 Erwartungen an einem Knoten, der laut Lehrplan Kinder
hat — ein Verstoß gegen E31.

**Codeschema:** `EN_<Phase>_<Kompetenzbereich>[_<Unterbereich>]_<lfd>`, mit den
Phasen EP / S1 / S2 wie bei Deutsch. Beispiele: `EN_EP_HOR_01`,
`EN_S1_VSM_GRA_01`, `EN_S2_TMK_01`, `EN_EP_IKK_SOW_01`.

Der Unterbereich steht nur, wo es einen gibt. Der Code ist damit unterschiedlich
lang — er bildet den Baum ab, statt eine feste Tiefe zu behaupten, die es nicht
gibt. Bei Englisch treten die sieben Teilbereiche der Funktionalen
kommunikativen Kompetenz an die Stelle, an der bei Deutsch das Inhaltsfeld
steht; `inhaltsfeld` kommt hier nicht vor.

**`art`:** `kompetenzbereich`, `teilbereich`, `unterbereich`.

**Was das nicht heißt:** Das Schema gilt für Englisch, Französisch und Spanisch,
die dieselbe Gliederung führen. Für Fächer mit anderer Struktur ist es neu zu
entscheiden.

---

## E47 — Zwei Eigenheiten des Englisch-Plans (09.09.2026)

Festgehalten, weil sie für Französisch und Spanisch wiederkehren.

**Zweispaltiger Satz, Trennung über Koordinaten.** `pdftotext -layout` taugt
hier nicht: Der linke Block ist im Blocksatz gesetzt, die rechte Spalte beginnt
je nach Zeile bei Zeichen 41, 45 oder 51. Ein Seitenzuschnitt über `-x/-y/-W/-H`
taugt ebenfalls nicht, weil auf derselben Seite ein- und zweispaltige Blöcke
stehen.

Das Verfahren arbeitet mit `pdftotext -bbox-layout`: Zeilen aus den Wörtern über
die Grundlinie neu bilden, Blöcke aus Markerzeile plus Fortsetzungen bilden, die
Spaltenfrage **am Block** entscheiden — deckt eine Zeile des Blocks die Rinne
zwischen 293 und 300 pt ab, ist der Block einspaltig —, und innerhalb
zweispaltiger Blöcke am ersten Wort ab 300 pt mit mindestens 8 pt Abstand
trennen.

Belegt: 117 Trennungen, die rechte Hälfte beginnt ausnahmslos an einem der vier
tatsächlichen Spaltenränder (302, 303, 320, 331), keine Ausreißer.

Die Blockentscheidung ist nicht Formsache, sondern die Lehre aus einem
Fehlschlag: Eine zeilenweise Entscheidung zog `nische Texte; Videoclips` aus der
rechten Spalte in eine Kompetenzerwartung.

**Grenzen:** Die Rinne ist gemessen, nicht allgemein — für jedes weitere Fach
neu zu bestimmen. Ein einspaltiger Block, dessen Zeilen zufällig alle einen
Wortzwischenraum auf der Rinne haben, würde zerschnitten; im Bestand tritt das
nicht auf.

**Kapitälchen kommen zerlegt an.** `pdftotext` setzt hinter jeden großen
Anfangsbuchstaben ein Leerzeichen: `I NTERKULTURELLE KOMMUNIKATIVE K OMPETENZ`,
`T EXT - UND M EDIENKOMPETENZ`. Zwei Ersetzungen stellen alle zwölf
Überschriften wieder her — Leerzeichen nach einem einzelnen Großbuchstaben
tilgen, Leerzeichen vor `-`, `/` und `:` tilgen.

---

## E48 — Regel 6 zählt nur Belege mit kleingeschriebener rechter Hälfte (09.09.2026)

**Anlass:** Die Auflage aus E45 — die drei vorhandenen Erzeuger mit der neuen
Regel gegen die ausgelieferten Seeds halten — hat eine Abweichung gefunden.
Regel 6 in der Fassung von E45 ändert `sql/11_seed_deutsch_sii.sql` an zwei
Stellen: `Autorschaft` wird zu `Autor-schaft`, in `DE_QGK_UEB_REZ_08` und
`DE_QLK_UEB_REZ_10`.

**Befund:** Das ist nachweislich falsch, und es ist genau die Stelle, die der
Nachtrag zu E22 einzeln abgesichert hat — dort wurde `Autorschaft` über den
Entwurf vom 31.07.2025 belegt, wo derselbe Satz ungetrennt steht.

Der Beleg, auf den Regel 6 sich stützte, ist `Autor-Rezipienten`: ein
Substantiv-Substantiv-Kompositum mit großgeschriebener rechter Hälfte. Das ist
eine andere Bauform als `Autor-schaft`. Bei Englisch dagegen ist der Beleg
`kritisch-konstruktiv` — Adjektiv-Adjektiv, rechte Hälfte klein, dieselbe
Bauform wie `kritisch-distanzierend`.

**Entscheidung:** Regel 6 zählt nur Belege, deren rechte Hälfte
kleingeschrieben ist.

**Warum das keine Zurechtbiegung auf den Einzelfall ist:** Regel 5 entscheidet
großgeschriebene Fortsetzungen bereits vollständig (E28). Regel 6 wird also nur
für kleingeschriebene Fortsetzungen überhaupt befragt — dann darf sie sich auch
nur auf Belege ihrer eigenen Bauform stützen. Ein Beleg mit großgeschriebener
rechter Hälfte gehört zu einer Bauform, über die Regel 6 nie zu entscheiden hat.

**Gemessen:** Unter der engen Fassung sind alle drei Seeds byteweise identisch
mit den ausgelieferten. `kritisch-reflektiert` und `kritisch-distanzierend`
werden weiterhin richtig entschieden, die übrigen 25 Regel-4-Fälle bei Englisch
bleiben unberührt. Die Menge der belegten linken Hälften schrumpft bei Englisch
von 18 auf 10; die zehn sind durchweg Adjektive und Adverbien — analytisch,
darstellerisch, didaktisch, kreativ, kritisch, literarisch, respektvoll,
sprachlich, tolerant, weltoffen.

**Was das über das Verfahren sagt:** Die Auflage aus E45 war keine Formalie. Sie
hat einen Fehler gefunden, der beim Formulieren der Regel entstanden ist und den
kein Testlauf am neuen Fach gezeigt hätte — er lag in einem Fach, das seit Tagen
ausgeliefert war.

---

## E49 — Englisch Sek I ist eingespielt (09.09.2026)

Abschlusseintrag nach REIHENREGELN 10, mit den gemessenen Zahlen.

**177 Kompetenzerwartungen an 48 Blättern, 57 Knoten insgesamt.** Die
Knotenzahl steht in keiner Vorgabe und ergibt sich aus dem Baum: je Phase ein
Wurzelknoten für jeden der fünf Kompetenzbereiche, darunter sieben
Teilbereiche unter der Funktionalen kommunikativen Kompetenz und drei
Unterbereiche unter der Interkulturellen, dazu vier Unterbereiche unter
„Verfügen über sprachliche Mittel" — 19 Knoten je Phase, davon 16 Blätter.

Aufteilung: Erprobungsstufe 53, Erste Stufe 67, Zweite Stufe 57. Marker: 170
`à` und 7 `•`. Alle Zahlen stimmen mit den unabhängig ausgezählten Sollwerten
überein, bis auf die Blätterzahl, die der Auftrag mit 42 angab (E46).

**Regel 6 hat im ganzen Plan genau zweimal gegriffen** —
`kritisch-reflektiert` und `kritisch-distanzierend` —, Regel 4 fünfundzwanzigmal.
Die drei vorhandenen Seeds bleiben unter der engen Fassung byteweise
unverändert (E48).

**Eine dritte Form der Überschrift**, die weder E46 noch E47 nennt: Die vier
Unterbereiche von „Verfügen über sprachliche Mittel" stehen als kurze Zeile am
linken Rand **ohne** Doppelpunkt (`Wortschatz`, `Grammatik`, `Aussprache und
Intonation`, `Orthografie`), während die drei der Interkulturellen Kompetenz
einen tragen und die Kompetenzbereiche in Kapitälchen stehen. Der Erzeuger
entscheidet deshalb nicht über die Form, sondern über das Verzeichnis: Steht
der Text dort, ist es eine Überschrift. Das ist zugleich die Absicherung
dagegen, dass eine unbekannte Überschrift stillschweigend als Fließtext
durchgeht — sie führte zum Abbruch „Erwartung ohne Blatt", und genau so ist
diese Form gefunden worden.

**Was das nicht heißt:** Das Codeschema lässt die Funktionale kommunikative
Kompetenz im Code aus (`EN_EP_HOR_01`, nicht `EN_EP_FKK_HOR_01`), behält aber
die Interkulturelle (`EN_EP_IKK_SOW_01`). Das folgt den Beispielen aus E46 und
ist eine Festlegung, keine Ableitung: FKK ist die Klammer über sieben
Teilbereiche, deren Kürzel schon für sich eindeutig sind; IKK trägt drei
Unterbereiche, deren Kürzel es ohne den Bereich nicht wären.

---

## E53 — E39 ist abgeschlossen: `projekt_schueler` ist die Antwort (09.09.2026)

**Vorbemerkung zur Nummer:** Die Entscheidungen zu diesem Auftrag wurden im
Chat als E50, E51 und E52 angekündigt; im Protokoll stehen sie nicht — weder in
der Datei noch irgendwo in der Historie. Die höchste vergebene Nummer war E49.
Dieser Eintrag nimmt deshalb **E53** und lässt E50 bis E52 frei, damit nicht
noch einmal zwei Einträge dieselbe Nummer tragen (E30).

**Welche Tabelle welche Frage beantwortet** — das ist die Auskunft, die beim
nächsten Anbau gebraucht wird:

| Tabelle | Frage |
|---|---|
| `projekt_schueler` | **Wer gehört zur Werkstatt.** Die Antwort. |
| `projekt_klassen` | Woher Kandidaten kommen. |
| `projekt_schueler_kompetenzen` | Was der Werkstatt zugewiesen ist. |

**Welche Ansicht welche befragt:**

| Ansicht | Quelle |
|---|---|
| Details-Modal (Abschlussvermerk) | `projekt_schueler` |
| Bewertungstabelle, Zeilen | `projekt_schueler` |
| Bewertungstabelle, Spalten | `projekt_schueler_kompetenzen` |
| Empfängerliste für Rückmeldungen | `projekt_schueler` |
| Teilnehmerauswahl beim Bearbeiten | `projekt_klassen` ∪ `projekt_schueler` |

Die letzte Zeile ist die einzige, die zwei Quellen führt, und sie tut es aus
gutem Grund: Dort werden **Kandidaten** gebraucht, nicht Teilnehmer, und ein
Teilnehmer aus einer entfernten Klasse muss abwählbar bleiben (E38). Diese
Vereinigung liegt im Frontend (`loadSchuelerForWerkstattEdit`) und bleibt.

**Der Endpunkt `GET /api/werkstatt/{id}/schueler` hatte nie zwei Zwecke.** Die
Auftragsdatei ging davon aus, er speise auch die Teilnehmerauswahl. Er hat
genau zwei Aufrufstellen, und beide zeichnen das Details-Modal. Deshalb braucht
er keinen Parameter, keinen Zwilling und kein Feld je Zeile — er liefert die
Teilnehmer.

**Die Vereinigung aus E38 entfällt dort, ihre Zusicherung wird stärker.** E38
hatte sie eingebaut, damit ein Teilnehmer aus einer entfernten Klasse nicht aus
dem Modal verschwindet. Geht die Abfrage von `projekt_schueler` aus, kann er
nicht mehr fehlen: Seine Klasse kommt aus `schueler.klasse_id`. Die Gegenprobe
zu E38 wurde unter der neuen Abfrage neu geführt, nicht angenommen.

**`rowCount()` taugt nicht als Teilnahmeprüfung.** `MYSQL_ATTR_FOUND_ROWS` ist
nicht gesetzt, also zählt es die **geänderten** Zeilen. Am Server nachgestellt:

```
Teilnehmer, Wert unverändert : rowCount = 0
Nicht-Teilnehmer             : rowCount = 0
Teilnehmer, Wert geändert    : rowCount = 1
```

Wer daraus einen Fehler ableitet, meldet „kein Teilnehmer", sobald jemand einen
Haken setzt, der schon gesetzt war. Geprüft wird deshalb ausdrücklich vorher,
wie bei den Rückmeldungen (E36).

**Ein Fehler, den erst die Messung zeigte:** `ladeBewertungTabelle` kehrte bei
null Bewertungszeilen zurück, **bevor** sie die Empfängerliste anfasste. Beim
Wechsel von Werkstatt 4 auf Werkstatt 2 blieben deren zwölf Namen stehen,
während `BEW_PROJEKT_ID` schon auf 2 zeigte. Vor E36 hätte ein Klick
Rückmeldungen in die falsche Werkstatt geschrieben — die Bauform der beiden
Waisen, die Migration 18 entfernt hat. Die Liste wird jetzt in jedem Fall
gesetzt, auch auf leer.

**Was das nicht heißt:** Die drei Tabellen bleiben drei Tabellen mit drei
Aufgaben. Zusammengelegt wird nichts.

---

## E50 — E39 abgeschlossen: `projekt_schueler` beantwortet die Frage (09.09.2026)

**Nachgetragen am 09.09.2026.** Die Entscheidung fiel im Chat, der Eintrag wurde
nicht ausgeführt; der Lauf hat die Lücke bemerkt und seinen Abschlusseintrag auf
E53 gelegt, statt eine Nummer doppelt zu vergeben (E30). Der Inhalt gilt seit
der Entscheidung, nicht erst seit diesem Eintrag.

**Anlass:** E39 hielt fest, dass drei Tabellen dieselbe Frage verschieden
beantworten, und wies die Zusammenführung als fachliche Entscheidung aus.

**Entscheidung:** `projekt_schueler` sagt, wer zur Werkstatt gehört.
`projekt_klassen` sagt, woher Kandidaten kommen. `projekt_schueler_kompetenzen`
sagt, was der Werkstatt zugewiesen wurde. Keines der beiden letzteren sagt, wer
dabei ist.

Vor E35 war das anders vertretbar: Solange Teilnehmer nach dem Anlegen
unveränderlich waren, musste das Details-Modal die Klassenschüler zeigen, weil
es sonst keinen Weg gab, jemanden nachzutragen. Diesen Grund gibt es nicht mehr.

**Der Endpunkt liefert die Teilnehmer, ohne Parameter und ohne Kennzeichen je
Zeile.** Der Auftrag ging von zwei Zwecken aus; der Code trägt das nicht.
`GET /api/werkstatt/{id}/schueler` hat zwei Aufrufstellen, beide speisen das
Details-Modal. Die Teilnehmerauswahl im Bearbeiten-Screen benutzt ihn nicht —
sie holt die Klassenschüler über `GET /schueler?klassen=…` und vereinigt sie im
Frontend mit den vorhandenen Teilnehmern.

**Zum Verhältnis zu E38:** Die dortige Vereinigung im Endpunkt wird
gegenstandslos, ihre Zusicherung aber stärker. E38 baute sie ein, damit ein
Teilnehmer aus einer entfernten Klasse nicht aus dem Modal verschwindet. Geht
die Abfrage von `projekt_schueler` aus, kann er gar nicht verschwinden — seine
Klasse kommt aus `schueler.klasse_id`, nicht aus `projekt_klassen`. Die
Gegenprobe zu E38 gilt weiter und ist neu zu führen. Die Vereinigung im
Frontend bleibt unangetastet; dort hat sie ihren Grund.

---

## E51 — Die Bewertungsansicht geht von den Teilnehmern aus (09.09.2026)

**Nachgetragen, siehe E50.**

**Anlass:** Die Bewertungstabelle baute ihre Zeilen aus
`projekt_schueler_kompetenzen`. Ein Teilnehmer ohne zugewiesene Kompetenzen
erschien nicht und war nicht bewertbar.

**Befund, schwerer als angenommen:** `ladeBewertungTabelle` kehrt bei null
Bewertungszeilen zurück, **bevor** die Empfängerliste für Rückmeldungen gefüllt
wird. Die Liste wird also nie geleert. Wer Werkstatt 4 ansieht und dann auf
Werkstatt 2 wechselt, hat zwölf fremde Namen vor sich, während die
Werkstatt-Kennung schon auf 2 steht.

Vor E36 hätte ein Klick auf „speichern" Rückmeldungen für Schüler der Werkstatt
4 in Werkstatt 2 geschrieben — die Bauform der beiden Waisen, die Migration 18
entfernt hat. E37 hielt fest, dass ihre Entstehung unbekannt bleibt; dies ist
ein Kandidat, der passt, aber kein Beleg.

**Entscheidung, drei Teile:** Die Zeilen der Tabelle kommen aus
`projekt_schueler`; die Spalten bleiben die zugewiesenen Kompetenzen. Sind der
Werkstatt keine Kompetenzen zugewiesen, tritt an die Stelle der Tabelle ein
Hinweis mit dem Weg dorthin — die Empfängerliste wird trotzdem gefüllt. Hat die
Werkstatt keine Teilnehmer, tritt ein anderer Hinweis an die Stelle; bisher
stand dort der Kompetenzhinweis, der den Benutzer ins Bearbeiten-Formular
schickt, wo er Kompetenzen wählen kann, die dann an niemandem hängen.

**Damit wird die Empfängerliste in jedem Fall gesetzt, auch auf leer.** Das
schließt den Wechselfehler. Es ist der Fall aus E36 von der anderen Seite: Dort
wies das Backend ab, was die Oberfläche anbot; hier hört die Oberfläche auf, es
anzubieten.

---

## E52 — `PUT /abschluss` prüft die Teilnahme, nicht die Zahl geänderter Zeilen (09.09.2026)

**Nachgetragen, siehe E50.**

**Anlass:** Ein Haken bei einem Nicht-Teilnehmer im Details-Modal meldete Erfolg
und tat nichts. Nach E50 kann die Oberfläche den Fall nicht mehr herstellen; die
Lücke bleibt für Direktaufrufe.

**Warum nicht über die Zahl geänderter Zeilen:** Am Server gemessen, nicht
überlegt. `MYSQL_ATTR_FOUND_ROWS` ist nicht gesetzt, die Rückgabe zählt bei
einem `UPDATE` also die **geänderten** Zeilen. Ein Teilnehmer mit unverändertem
Wert liefert 0, ein Nicht-Teilnehmer liefert 0, ein Teilnehmer mit geändertem
Wert liefert 1. Null heißt beides. Wer daraus einen Fehler ableitet, meldet
„kein Teilnehmer", wenn jemand einen bereits gesetzten Haken erneut setzt.

**Entscheidung:** Abfrage gegen `projekt_schueler` vor dem `UPDATE`, bei
Fehlschlag Abweisung mit Nennung der betroffenen Kennung, nichts geschrieben —
wie E36. Der Zweig, der alle Teilnehmer betrifft, braucht nichts: Er arbeitet
über die Werkstatt-Kennung und trifft nur Teilnehmer.

**Gemeldet, nicht behoben:** Dieser Zweig gibt eine Zahl `aktualisiert` zurück,
und das ist nach derselben Messung die Zahl der **geänderten** Zeilen. Bei zwölf
Teilnehmern, von denen zehn schon abgeschlossen waren, steht dort 2. Wer das als
„zwölf markiert" liest, liest falsch.

---

## E54 — Das Entfernen eines Teilnehmers hinterlässt keine brauchbare Spur (09.09.2026)

**Anlass:** Nach dem Auftrag zu E39 stimmten die Teilnehmerzahlen von Werkstatt
4 nicht mehr: 12 auf 10. Aufgefallen ist es nur, weil eine Zahl vor und nach dem
Auftrag verglichen wurde.

**Befund:** Die Ursache war eine Testlöschung über den Bearbeiten-Screen. Das
Verhalten aus E34 hat gegriffen — 228 minus 190 sind 38 Kompetenzzeilen, genau
zweimal 19, und 12 minus 10 sind 2 Rückmeldungen. Mitgelöscht nach Rückfrage,
wie beschlossen. Das ist der erste Fall, in dem E34 im Betrieb ausgelöst wurde,
und es hat funktioniert.

Was nicht funktioniert hat, ist die Spur. Der PUT protokolliert nur
`audit(…, 'projekte', $id, 'UPDATE', null, ['name' => $name])`. Dass dabei zwei
Teilnehmer samt 38 Kompetenzzeilen und 2 Rückmeldungen gelöscht wurden, steht
nirgends. Rekonstruierbar war **wann** und **über welchen Weg**, nicht **was**.

**Entscheidung:** Festgehalten, nicht behoben. Was protokolliert werden soll,
ist eine eigene Entscheidung — sie betrifft nicht nur diesen Endpunkt, sondern
die Frage, welche Wirkungen einer Änderung überhaupt festzuhalten sind.

**Warum das zählt:** Bei einer Testlöschung ist es folgenlos. Im Betrieb ist es
der Unterschied zwischen „wir wissen, was weg ist" und „wir wissen, dass etwas
weg ist". E34 hat das Löschen ausdrücklich zugelassen, weil die Rückfrage den
Schutz bildet — die Rückfrage sieht aber nur, wer sie beantwortet, und nur in
dem Augenblick.

**Gemeldet im selben Zug:** Der Zweig von `PUT /abschluss`, der alle Teilnehmer
betrifft, gibt eine Zahl `aktualisiert` zurück. Das ist die Zahl der
**geänderten** Zeilen (E52). Bei zehn Teilnehmern, von denen acht schon
abgeschlossen waren, steht dort 2. Wer das als „zehn markiert" liest, liest
falsch.

---

## E55 — `.komp-cb{display:none}` ist der Rest eines Selektors, der nie traf (09.09.2026)

**Anlass:** Bei der Bestandsaufnahme der Kästchen gefunden.

**Befund:** Die Regel in `frontend/style.css` verbirgt Elemente mit der Klasse
`komp-cb`. Beide Kästchen mit dieser Klasse liegen in `.komp-pill`, und die
Regel `.komp-pill input[type=checkbox]{display:none}` verbirgt sie bereits. Die
Zeile ist wirkungslos.

Sie stammt aus der Zeit vor E33 — dort suchte die Vorbelegung des
Bearbeiten-Screens `#we-komp-bereich-list .komp-cb`, während
`class="we-komp-cb"` gezeichnet wurde. Der Selektor traf drei Monate lang nicht
und löschte bei jeder Bearbeitung die Kompetenzauswahl.

**Entscheidung:** Gemeldet, nicht entfernt. Sie ist harmlos, und ihre Entfernung
ist ein eigener Handgriff.

**Warum sie trotzdem hier steht:** Eine tote Regel ist eine falsche Auskunft
über den Bestand. Wer sie liest, nimmt an, es gebe Kästchen, die nur über diese
Klasse verborgen werden — und richtet sich beim nächsten Anbau danach.

---

## E56 — Die Schuljahr-Auswahl beim Import hat keine Wirkung (10.09.2026)

**Anlass:** Beim Maskieren des Import-Dateinamens gefunden, nicht gesucht — der
Lauf musste für die Handprüfung wissen, gegen welches Schuljahr importiert wird.

**Befund:** Das Frontend hängt `schuljahr_id` an das Formular (`app.js:2190`
und `2264`). Der Handler liest sie aus `$body`, und `$body` entsteht aus
`json_decode(file_get_contents('php://input'))`. Bei `multipart/form-data` ist
`php://input` in PHP leer; der Wert landet in `$_POST` und wird nie gelesen.

Der Import läuft also immer gegen das aktive Schuljahr, gleich was im Feld
steht. Die Oberfläche meldet Erfolg.

**Warum das gefährlich ist:** Der Import inaktiviert Schüler, die nicht in der
Datei stehen. Wer beim Schuljahreswechsel die neue Datei hochlädt und dabei das
neue Schuljahr auswählt, importiert in Wahrheit ins alte — und inaktiviert dort
jeden, der in der neuen Datei fehlt. Bei einem Jahrgangswechsel ist das der
gesamte abgehende Jahrgang, und die Meldung sagt „unverändert" oder
„aktualisiert", nicht was tatsächlich geschah.

**Entscheidung:** Festgehalten, nicht behoben. Die Behebung ist nicht nur das
Lesen aus `$_POST` — dahinter steht eine fachliche Frage: **Soll überhaupt in
ein nicht aktives Schuljahr importiert werden dürfen?** Davon hängt ab, ob das
Feld eine Auswahl bleibt, eine Anzeige wird oder verschwindet, und wie sich die
Inaktivierung dazu verhält.

**Was das nicht heißt:** Es ist kein Anzeigefehler. Solange das Feld eine
Auswahl anbietet, die nichts bewirkt, ist jede Nutzung davon eine falsche
Zusicherung an den Benutzer.

---

## E57 — E56 abgeschlossen: Der Import zeigt das aktive Schuljahr, statt es zur Wahl zu stellen (10.09.2026)

**Was die Oberfläche zugesagt hat.** E56 beschreibt ein wirkungsloses Feld. Es
war mehr als das: Über der Auswahl stand wörtlich

> „Standard: aktives Schuljahr. **Du kannst auch ein zukünftiges Schuljahr
> wählen.**"

Das ist keine stillschweigende Unwirksamkeit, sondern eine ausdrücklich
zugesagte Fähigkeit, die es nie gab. Wer sie nutzte, bekam keinen Fehler,
sondern eine Erfolgsmeldung — und einen Import ins alte Jahr.

**Entscheidung, drei Teile:**

Der Handler ermittelt das aktive Schuljahr **ohne Vorbedingung** und nimmt die
Angabe nicht mehr entgegen. `import_log.schuljahr_id` bleibt, wie es ist — es
war schon immer richtig gefüllt: Alle drei vorhandenen Zeilen tragen das aktive
Jahr, weil der Wert nie ankam und der Rückfall immer lief.

**Keine ausdrückliche Zurückweisung.** Ein Aufrufer, der `schuljahr_id`
mitschickt, bewirkt nichts; ein Fehler dafür bestrafte ihn für eine Angabe, die
seit jeher wirkungslos war, und das Frontend schickt sie nicht mehr.

**Bei keinem aktiven Jahr** zeigt die Anzeige denselben Satz, den das Backend
ausgibt, und das Dateifeld bleibt bedienbar. **Nicht sperren:** Zwei Stellen,
die dieselbe Bedingung entscheiden, sind der Mechanismus, aus dem dieser Fehler
entstanden ist.

**Der Fall ist enger, als er aussieht.** Der Auftrag nahm an, „Schuljahre"
erlaube, alle abzuschließen. Das stimmt nicht: Abschließen geschieht nur als
Nebenwirkung des Aktivierens eines anderen Jahres, in einer Transaktion, und das
aktive Jahr lässt sich ausdrücklich nicht löschen (`index.php:1754`). Erreichbar
ist der Zustand nur vor der ersten Aktivierung — bei einer frischen
Installation.

**Kehrt der Fehler anderswo wieder? Nein — gesucht, nicht vermutet:**

| Suche | Treffer |
|---|---|
| `new FormData` im gesamten Frontend | 2 — beide im Import |
| `fetch`-Rümpfe, die kein JSON sind | 2 — dieselben |
| `$_FILES` im gesamten Backend | 2 — dieselben Endpunkte |
| **`$_POST` im gesamten Backend** | **0** |

Der einzige weitere Upload — das Schullogo — geht als Base64 in einem
JSON-Rumpf; dort ist `php://input` gefüllt.

**Die Regel, die beim nächsten Upload gebraucht wird:**

> **Wer im Frontend `FormData` benutzt, muss im Backend `$_FILES` und `$_POST`
> lesen, nicht `$body`.**

`$body` entsteht aus `php://input`, und das ist bei `multipart/form-data` leer.
Der Fehler ist nicht „jemand hat ein Feld vergessen", sondern eine Eigenschaft
der Übertragungsart. Dass `$_POST` heute **null** Vorkommen hat, ist die
Kehrseite derselben Sache: Das Projekt liest sonst überall JSON — und genau
deshalb fiel niemandem auf, dass eine Stelle es nicht tut.

**Was das nicht heißt:** Die Inaktivierungslogik bleibt unangetastet. Sie
bezieht sich weiter auf den Bestand des aktiven Jahres; das war nie falsch,
sondern nur unsichtbar, solange ein anderes Jahr wählbar schien.

---

## E58 — Jede verwendete CSS-Variable muss definiert sein (10.09.2026)

**Anlass:** `var(--err)` an fünf Stellen und `var(--ok)` an vier — beide Namen
hat es nie gegeben. Gefunden wurde der erste beim Bau der Schuljahr-Anzeige
(E57), und zwar daran, dass ein Hinweis im Browser **schwarz** war, wo er rot
sein sollte. Der zweite fiel erst der Prüfung auf, nicht dem Auge.

**Warum das eine eigene Sorte Fehler ist:** Eine undefinierte CSS-Variable
bricht nichts. `color:var(--err)` ohne Definition ist gültiges CSS; der Text
erbt seine Farbe und sieht aus wie gewöhnlicher Text. Es gibt keine
Fehlermeldung, keinen Eintrag in der Konsole und keinen Unterschied zu „hier
war keine Farbe vorgesehen". Betroffen waren ausgerechnet die
Fehlerausgaben der Import-Vorschau — die Stelle, an der ein Benutzer auf die
Farbe angewiesen ist.

**Entscheidung, zwei Teile:**

`--err` entfällt ersatzlos; die fünf Stellen nennen `--danger`, das es gibt.
Ein zweiter Name für dieselbe Sache wäre eine zweite Wahrheit.

`--ok` bekommt eine Definition (`--ok:var(--ci-erfolg)`), weil es kein
Gegenstück gab. `--danger`, `--warn` und `--info` sind da, ein Erfolgston
fehlte.

**Nicht die Importpalette — gerechnet, nicht geschätzt.** Naheliegend wäre
gewesen, im Importbildschirm `--imp-neu` und `--imp-err` zu nehmen: Sie stehen
zwei Zeilen weiter an den Balken. Als **Text auf der weißen Karte** erreicht
`--imp-neu` aber nur 4.19 und `--imp-upd` 2.78 — beide unter AA.
`--ci-erfolg` erreicht 5.17, `--ci-fehler` 6.65. Die Palette ist für Flächen
gemacht, und der Kommentar in `style.css` sagt genau das („auf ihrer
jeweiligen Fläche").

**Die Prüfung:** Jede in `frontend/` verwendete Variable muss definiert sein —
in `style.css`, in den vendorten Stilvorlagen oder inline. Sie zielt
ausdrücklich **nicht** auf `--err`: Ein Ausdruck gegen einen bekannten falschen
Namen fängt den nächsten nicht.

**Kommentare werden auf beiden Seiten entfernt**, bevor gezählt wird. Sonst
entstünde eine Scheindefinition, sobald eine Erklärung `--x:` schreibt — und
die Prüfung ginge gerade dort grün, wo jemand die Regel sorgfältig
aufgeschrieben hat (REIHENREGELN 2). Die Gegenprobe dazu ist geführt: Ein
Kommentar mit `--phantom3:` und eine echte Verwendung daneben ergeben **rot**,
nicht grün.

**Ein Modifikatorname ist keine Definition.** `.ci-knopf--gefahr:hover` sieht
wie `--gefahr:` aus. Vor den zwei Bindestrichen muss deshalb ein Zeichen
stehen, das kein Namenszeichen ist, oder der Zeilenanfang. Ohne diese
Bedingung hätte die Prüfung zwei Klassennamen der vendorten Stilvorlage für
Variablen gehalten.

**Ein Rückfall ist keine Definition.** `var(--warn,#f59e0b)` zählt als
Verwendung von `--warn`. Wer einen Rückfall angibt, hat einen Zweitwert
genannt, keine Variable definiert — und der stille Rückfall ist genau das, was
die Prüfung sichtbar machen soll.

**Was sie nicht kann:** einen zur Laufzeit zusammengesetzten Namen
(`'var(--bew-' + n + ')'` — im Bestand nicht vorhanden, nachgesehen); den
Geltungsbereich einer Definition; und ob die gewählte Farbe die richtige ist.
Dass `--imp-neu` als Text zu blass ist, fällt ihr nicht auf — das musste
gerechnet werden.

**Gemeldet, nicht behoben:** In `app.js` stehen weiterhin Rohfarben —
sieben Hexwerte in `KAT_PHASEN` (Zeilen 1575–1581) und zweimal der tote
Rückfall `#f59e0b`. Die Prüfung „Keine Rohfarben außerhalb des
`:root`-Blocks" liest nur die Stilvorlage; sie sieht davon nichts. Das ist
derselbe Fall, den REIHENREGELN 2 unter „eine Prüfung, die eine bestimmte
Datei liest, prüft diese Datei" beschreibt.
