# Ausrollanleitung: Auftrag A (Anmeldung aus dem Modul, Kern versioniert)

Geschrieben am 20.11.2026, nach Paket 6. **Ausgeführt wird sie von
Sebastian**, nicht aus einer Sitzung. Begründung der Schritte: E68.

**Keine Werte in einer Ausgabe** – gezählt wird, ausgegeben werden Namen und
Zahlen. Wo unten „erwartet“ steht und etwas anderes erscheint: **anhalten**,
nichts weiter ausführen, melden.

## Stand (21.11.2026)

**Schritte 0–5 erledigt am 21.11.2026**, ausgeführt von Sebastian,
ausgeliefert `e4f42c7..5d28d5c`. **Schritt 6 (Aufräumen) offen**, bewusst:
geplant Mitte der Woche ab 23.11., nach echter Nutzung. Bis dahin ist der
Rückweg der billige (unten).

| Schritt | Gemeldet (nur Zahlen) |
|---|---|
| 0 | Suite 393/393, karg gleich; 11 Commits wie in der Tabelle; Rückweg-Stand `e4f42c7` |
| 1 | `RUNNING`; Sitzungsdateien 100; `webuntis_login_log` 170; Vergleichssitzung über ein WebUntis-Kürzel, `id` 0 |
| 2 | `anmeldebremse`, `anmeldeverlauf` angelegt |
| 3 | Ableitung am Server: 12 Namen, sieben „gleich“, `session_start_secure`: Betriebsfassung (E68) – **die Prüfsumme ist damit am Server belegt** |
| 4 | `deploy.sh` mit 393/393, Commit `5d28d5c` |
| 5 | alles bestanden: Sitzung von vorher trägt mit `id` 0; Sitzungsdateien 111; Cookie-Attribute; `401` und `anmeldeverlauf` 0 → 1; `webuntis_login_log` unverändert; `app.js` enthält den neuen Satz |

**Abweichung von der Anleitung:** `webuntis_login_log` stand nach dem
Ausliefern bei 173 statt 170. Die drei Zeilen stammen von 09:23–09:24,
**vor** dem Ausliefern – Anmeldungen unter dem alten Code zwischen Schritt 1
und Schritt 4; seitdem keine. Die Vergleichszahl für Abnahme 5 wurde deshalb
nach dem Ausliefern genommen (173). Die Schritte 4 und 5 unten sehen das seit
diesem Stand so vor, ebenso Zugangsdaten über `read -s` und das Aufräumen
der Cookie-Dateien.

**Nebenbefund beim Ausliefern:** `frontend/index.html` lädt `app.js` ohne
`?v=`; `deploy.sh` stempelt nur, was schon einen Stempel trägt. Beschrieben
im `CHANGELOG.md` unter „Offen“, nicht behoben (eigener Auftrag).

## Was hinausgeht

Alles zwischen dem ausgelieferten Stand und dem Commit dieser Anleitung. Der
zuletzt bekannte ausgelieferte Stand ist `e4f42c7` (Spanisch Sek I, nach B0
`cc51ecf`) – so steht es in der lokalen Verfolgung `uberspace/main`, nicht am
Server gemessen:

| Commit | Inhalt |
|---|---|
| `0e80957` | `sql/gen/abgleich.py`, Dokumentation – **kein Anwendungscode** |
| `ebf9a2b` | Paket 1: `backend/kern.php`, `konfiguration.php`, Ableitung |
| `9b7dc73`, `91b1859` | Browsertest: Zeitgrenze, `--use-mock-keychain` (nur Prüfung) |
| `03e7015` | Paket 2: Anmeldebremse aus dem Modul, `sql/22`, `sql/23` |
| `ebed08e` | Paket 3: Fristen, `sql/24` |
| `710282f` | Paket 4: Sitzung an einer Stelle |
| `83fc455` | Paket 5: Wartesatz |
| `055c01d` | Betriebsfassung von `session_start_secure` |
| `23b3147` | Paket 6: übersprungene Schritte gezählt |
| (dieser Commit) | E68, Dokumentation, diese Anleitung |

B0 ist schon draußen (Nachtrag 12.11.); diese Anleitung deckt es nicht ab.
Die Liste nachprüfen, bevor es losgeht:

```bash
git fetch uberspace && git log --oneline uberspace/main..main
```

Erwartet: genau die Commits der Tabelle. Steht dort mehr oder weniger:
anhalten.

**Die Schüleranmeldung (`personType 5`) bleibt aus.** A ändert
`allowed_person_types` nicht; die Ableitung übernimmt den Wert der
Server-`config.php` unverändert. Ist sie dort heute aus, bleibt sie aus.

## 0 — Am Rechner

1. **Leseregeln** in `~/.claude/settings.json` (auf diesem Rechner seit dem
   20.11. gesetzt und geprüft, je mit Read und `cat`: abgewiesen):
   `Read(//**/konfiguration.php)` und `Read(//**/konfiguration.php.*)`.
   Auf jedem weiteren Rechner, bevor dort `konfiguration.php` entsteht. Die
   Vorlage in `koordination` (`docs/betrieb/claude/settings.json`) kennt die
   Datei noch nicht.
2. `./bin/konfiguration-ableiten.sh lokal-pruefen` → `in Ordnung: alle
   Namen da, keine Funktion`.
3. `./tests-projektstunden.sh` → **393/393 bestanden, 0 rot, 0 übersprungen,
   0 Pflichtschritt(e)**, karg dieselben Zahlen. `deploy.sh` lässt die Suite
   ohnehin laufen; dieser Lauf ist der Vergleich dafür.

## 1 — Am Server, vorher zählen

```bash
ssh hornse@halimede.uberspace.de 'supervisorctl status projektstunden'
ssh hornse@halimede.uberspace.de 'ls ~/tmp/sessions | wc -l'
ssh hornse@halimede.uberspace.de 'mysql -N hornse_projektstunden -e "SELECT COUNT(*) FROM webuntis_login_log"'
```

Notieren: Dienst `RUNNING`, Zahl der Sitzungsdateien, Zahl der Zeilen in
`webuntis_login_log`. **Nur Zahlen.** Die Zahl aus `webuntis_login_log` ist
hier nur ein Anhalt; die Vergleichszahl für Abnahme 5 wird direkt nach
`deploy.sh` genommen (Schritt 4) – bis dahin schreibt der alte Code bei jeder
Anmeldung weiter hinein (am 21.11.: 170 hier, 173 nach dem Ausliefern).

Dazu eine Sitzung, die das Ausliefern überleben muss. Die Zugangsdaten
werden mit `read -s` gelesen, nicht in den Befehl geschrieben (sonst stehen
sie in der Shell-Historie und, als Argument von `curl`, in der
Prozessliste); `printf` ist eingebaut und reicht sie über die
Standardeingabe weiter:

```bash
read -r -p 'Mail: ' PS_MAIL; read -r -s -p 'Passwort: ' PS_PW; echo
printf '{"username":"%s","passwort":"%s"}' "$PS_MAIL" "$PS_PW" | \
  curl -s -X POST https://projektstunden.hornse.de/api/auth/login \
  -H "Content-Type: application/json" --data-binary @- \
  -c /tmp/c-vorher.txt > /dev/null && \
curl -s https://projektstunden.hornse.de/api/auth/me -b /tmp/c-vorher.txt
unset PS_PW
```

Erwartet: JSON mit `id`/`vorname`/`rolle`. Ein Passwort mit `"` oder `\`
geht so nicht als gültiges JSON hinüber – dann eine andere Vergleichssitzung
nehmen. `/tmp/c-vorher.txt` trägt eine gültige Sitzung: Sie wird nach der
Abnahme abgemeldet und gelöscht (Abnahme 7).

## 2 — Tabellen anlegen (`sql/22`, `sql/23`)

Die Dateien liegen auf dem Server noch nicht; sie gehen über die
Standardeingabe hinüber. Der alte Code benutzt keine der beiden Tabellen.

```bash
ssh hornse@halimede.uberspace.de 'mysql hornse_projektstunden' < sql/22_anmeldebremse.sql
ssh hornse@halimede.uberspace.de 'mysql hornse_projektstunden' < sql/23_migration_anmeldeverlauf.sql
ssh hornse@halimede.uberspace.de 'mysql -N hornse_projektstunden -e "SHOW TABLES LIKE \"anmelde%\""'
```

Erwartet: keine Fehlermeldung, dann `anmeldebremse` und `anmeldeverlauf`.
Zweimal einspielen ist unschädlich.

## 3 — Wertedatei ableiten

```bash
./bin/konfiguration-ableiten.sh server
```

Erwartet, trocken:

```
Vorlage: 10 Namen, Maßstab: 8 Funktionen
Quelle: config.php, 8 Funktionen, … Namen
  get_db: gleich
  session_start_secure: Betriebsfassung (E68)
  require_auth: gleich
  …                                  (die übrigen fünf: gleich)
entfällt: … – die Sitzung steht im Kern, der Speicherort in sessions.ini (E68)
Ergebnis: keine Funktion, 10 Namen, alle 10 der Vorlage, php -l sauber
trocken: nichts geschrieben (SCHREIBEN=1 schreibt konfiguration.php)
ENDE konfiguration-ableiten
```

**Anhalten bei** jeder Zeile `HALT`, bei `abweichend` oder `fehlt`, und
wenn `session_start_secure` etwas anderes zeigt als „Betriebsfassung (E68)“
– die Prüfsumme ist nur am Rechner gemessen (E68, Abschnitt
Betriebsfassung); dieser Lauf ist ihr Beleg am Server. Die Zeile
„entfällt“ nennt, was die alte Datei zur Sitzung setzte (am 18.11. gezählt:
`session.save_path` einmal, dazu `SESSION_NAME`, `SESSION_LIFETIME`).

Dann schreiben und prüfen:

```bash
SCHREIBEN=1 ./bin/konfiguration-ableiten.sh server
./bin/konfiguration-ableiten.sh server-pruefen
```

Erwartet: `geschrieben: konfiguration.php, Rechte 0600`, danach
`in Ordnung: alle Namen da, keine Funktion`. Die Ableitung überschreibt nie;
liegt dort schon eine `konfiguration.php`, hält sie an.

Der laufende (alte) Code lädt `konfiguration.php` nicht – bis hier ist am
Betrieb nichts verändert.

## 4 — Ausliefern

```bash
./deploy.sh "Auftrag A: Anmeldung aus dem Modul, Kern versioniert (E68)"
```

Erwartet: Suite in `deploy.sh` mit 393/393, 0 rot, 0 übersprungen; Push
nach `github` und `uberspace`; „✓ Deploy erfolgreich auf Uberspace“.

**Direkt danach** die Vergleichszahl für Abnahme 5 nehmen:

```bash
ssh hornse@halimede.uberspace.de 'mysql -N hornse_projektstunden -e "SELECT COUNT(*) FROM webuntis_login_log"'
```

Ab hier schreibt niemand mehr hinein. Weicht sie von Schritt 1 ab, ist das
kein Halt: Es waren Anmeldungen unter dem alten Code dazwischen. Notieren,
mit welcher Zahl verglichen wird.

## 5 — Abnahme

1. **Dienst und Fehler:** die Prüfungen 1 und 4 aus `CLAUDE.md` („Vor jeder
   Auslieferung“). Erwartet: `RUNNING`, im stderr nichts Neues seit dem
   Ausliefern.
2. **Wertedatei am Platz:** `./bin/konfiguration-ableiten.sh server-pruefen`
   → `in Ordnung`.
3. **Niemand ist abgemeldet:**
   `curl -s https://projektstunden.hornse.de/api/auth/me -b /tmp/c-vorher.txt`
   → dasselbe JSON wie in Schritt 1. Und
   `ssh … 'ls ~/tmp/sessions | wc -l'` → nicht kleiner als vorher.
4. **Sitzung über zwei Anfragen, Cookie:** Prüfungen 2 und 3 aus `CLAUDE.md`.
   Erwartet: JSON mit `id`; `; secure; HttpOnly; SameSite=Lax`.
5. **Ein Fehlversuch, und wo er landet:**
   ```bash
   ssh hornse@halimede.uberspace.de 'mysql -N hornse_projektstunden -e "SELECT COUNT(*) FROM anmeldeverlauf"'
   curl -s -o /dev/null -w '%{http_code}\n' -X POST https://projektstunden.hornse.de/api/auth/login \
     -H "Content-Type: application/json" -d '{"username":"abnahme@probe.invalid","passwort":"falsch"}'
   ssh hornse@halimede.uberspace.de 'mysql -N hornse_projektstunden -e "SELECT COUNT(*) FROM anmeldeverlauf"'
   ssh hornse@halimede.uberspace.de 'mysql -N hornse_projektstunden -e "SELECT COUNT(*) FROM webuntis_login_log"'
   ```
   Erwartet: `401`; `anmeldeverlauf` eine Zeile mehr; `webuntis_login_log`
   **unverändert** gegen die Zahl direkt nach `deploy.sh` (Schritt 4; der
   neue Code schreibt nicht mehr hinein). „Eine Zeile mehr“ gilt nur, wenn
   gerade niemand sonst sich anmeldet – jede gleichzeitige Anmeldung, auch
   eine erfolgreiche, schreibt ebenfalls in `anmeldeverlauf`. Sind es mehr:
   kein Halt, die Zählung einmal wiederholen; mindestens eine mehr muss es
   sein.
6. **Im Browser** (nicht offline messbar, REIHENREGELN 2): Anmelden mit der
   Eingabetaste; die Hilfe vor der Anmeldung zitiert „Zu viele
   Fehlversuche. Bitte in … Sekunden erneut versuchen.“; eine Lehrkraft per
   WebUntis kommt hinein und bleibt beim Seitenwechsel angemeldet.
7. **Aufräumen am Rechner:** Die Cookie-Dateien tragen gültige Sitzungen –
   erst abmelden, dann löschen:
   ```bash
   for c in /tmp/c-vorher.txt /tmp/c.txt; do
     [ -f "$c" ] && curl -s -o /dev/null -X POST https://projektstunden.hornse.de/api/auth/logout -b "$c"
   done
   rm -f /tmp/c-vorher.txt /tmp/c.txt
   ```
   (`/tmp/c.txt` stammt aus Prüfung 2 in `CLAUDE.md`.)

Die Wartezeit selbst (429 nach acht Fehlversuchen) ist ausgeführt geprüft
(`tests/anmeldung_db_test.sh` A9); am Betrieb nicht nötig.

## 6 — Aufräumen, erst nach der Abnahme

```bash
ssh hornse@halimede.uberspace.de 'ls -1 ~/projektstunden/backend/ | grep -c "^config\.php"'
ssh hornse@halimede.uberspace.de 'rm ~/projektstunden/backend/config.php'
ssh hornse@halimede.uberspace.de 'mysql hornse_projektstunden < ~/projektstunden/sql/24_aufraeumen_nach_abnahme.sql'
ssh hornse@halimede.uberspace.de 'mysql -N hornse_projektstunden -e "SHOW TABLES LIKE \"webuntis_login_log\""'
```

Die erste Zeile zählt, wie viele Dateien mit `config.php` beginnen. Ist es
mehr als eine (eine Sicherung wie `config.php.alt-…` am Rechner): nicht
mitlöschen, melden – sie trägt das Datenbankpasswort, und was mit ihr
geschieht, ist eine eigene Entscheidung.

Erwartet nach `sql/24`: keine Ausgabe der letzten Zeile (Tabelle weg). Dann
Abnahme 4 und 5 noch einmal (ohne die Zeile zu `webuntis_login_log`).

## Rückweg

**Vor Schritt 6** ist er billig: Die alte `config.php` liegt noch, die neuen
Tabellen stören den alten Code nicht, `konfiguration.php` lädt er nicht.

```bash
git revert --no-edit <erster>^..<letzter>   # die Anwendungs-Commits der Tabelle
./tests-projektstunden.sh
./deploy.sh "Rückweg Auftrag A"
```

Die Suite am alten Stand meldet die Strukturprüfung der alten `config.php`
als übersprungen, wenn am Rechner keine liegt. Danach Abnahme wie vor A:
Prüfungen 1–4 aus `CLAUDE.md`.

**Nach Schritt 6** fehlen dem alten Code `config.php`, `webuntis_login_log`
und `audit_log.ip_adresse`. Dann vor dem Rückweg: `config.php` aus der
Vorlage `0e80957` (`tests/daten/config.example-0e80957.php`) mit den Werten
aus `konfiguration.php` neu anlegen (von Hand, Rechte 0600),
die Tabelle `webuntis_login_log` mit dem **ersten Block** von
`sql/06_migration_webuntis_auth.sql` neu anlegen (`CREATE TABLE IF NOT
EXISTS …`) – **nicht die ganze Datei**: Ihr `ALTER TABLE benutzer` legt
`uq_webuntis_user` ohne `IF NOT EXISTS` an und bricht beim zweiten
Einspielen ab. Dann die Spalte wieder anlegen:
`ALTER TABLE audit_log ADD COLUMN IF NOT EXISTS ip_adresse VARCHAR(45) NULL`
(Typ aus `sql/01_schema.sql`). Der alte
`audit()` schreibt sie; ohne die Spalte schluckt sein `catch (Throwable)`
jeden Eintrag still. Deshalb Schritt 6 erst, wenn die Abnahme trägt.
