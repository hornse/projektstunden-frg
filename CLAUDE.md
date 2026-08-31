# Projektgedächtnis: Projektstunden NRW

Diese Datei wird bei jedem Sessionstart automatisch gelesen. Was hier
steht, muss nicht mehr erklärt werden.

Ergänzend:
- Entscheidungen mit Begründung: @docs/ENTSCHEIDUNGEN.md
- Serverkonfiguration: @deploy/uberspace.md
- Konfigurationsreferenz: @docs/CONFIG.md

## Was das Projekt ist

Webanwendung zur Verwaltung von Projektstunden am Friedrich-Rückert-Gymnasium
Düsseldorf. Lernbegleiter legen Werkstätten an, ordnen Schüler zu, rechnen
Projektstunden auf Fächer an, dokumentieren Kompetenzen aus KLP und MKR,
bewerten vierstufig und schreiben Rückmeldungen. Schüler sehen ihre eigenen
Werkstätten und geben eine Selbsteinschätzung ab.

Stand: v0.7.x, im Produktivbetrieb unter `projektstunden.hornse.de`.
Der Kompetenzkatalog ist inhaltlich unbrauchbar (siehe E8) und wird neu
aufgebaut.

## Der Stack — nicht verhandelbar

| Schicht | Technologie |
|---|---|
| Frontend | Vanilla JS, HTML, CSS — kein Build-Schritt, kein Framework |
| Backend | PHP 8.1+, kein Framework, eigener Router in `backend/router.php` |
| Datenbank | MariaDB 10.6 über PDO, Datenbank `hornse_projektstunden` |
| Auth | WebUntis JSON-RPC **und** lokales bcrypt-Passwort (beides, siehe E1) |
| Auslieferung | Uberspace 7, PHP built-in Server hinter SSL-Proxy, supervisord, Port 8082 |
| Lizenz | GPL v3 |

Arbeitsverzeichnis lokal: `/Users/sebastianhorn/Projekte/projektstunden`
Work-Tree auf dem Server: `/home/hornse/projektstunden`
Zwei Remotes: `github` und `uberspace`. `deploy.sh` pusht auf beide.

## Regeln, die schon einmal Schaden angerichtet haben

**`session_name()` und `$_SERVER['HTTPS']` stehen in `backend/router.php`
ganz oben, vor jedem `require`.**
Vorfall (08.07.2026): Der Login gab 200 zurück, der Cookie war im Browser
gesetzt, die Session-Datei lag korrekt in `~/tmp/sessions` — und trotzdem
antwortete jeder Folgeaufruf mit 401. Ursache: PHP liest den Cookie-Namen
beim ersten Session-Zugriff; `session_name()` kam zu spät und PHP legte bei
jedem Request eine neue leere Session an. Ohne `HTTPS = 'on'` fehlt zusätzlich
das `Secure`-Flag, weil Uberspace SSL vor dem PHP-Prozess terminiert — Chrome
verwirft solche Cookies auf HTTPS-Seiten stillschweigend. Die Suche hat einen
halben Tag gekostet.

**Für `benutzer_id` niemals `empty()`.**
Vorfall (08.07.2026): WebUntis-Lehrer ohne lokalen Datenbankeintrag bekommen
`benutzer_id = 0`. `empty(0)` ist in PHP `true`, also galten sie als
ausgeloggt. Der Fehler war unsichtbar, weil die Session-Datei nachweislich
korrekt war — erst ein `error_log(json_encode($_SESSION))` in `require_auth()`
hat es gezeigt. Richtig ist:
```php
if (!isset($_SESSION['benutzer_id']) || $_SESSION['benutzer_id'] === null)
```
Dasselbe gilt im Frontend: `if (me && me.id)` wirft den WebUntis-Lehrer zurück
auf den Login. Es muss `if (me && (me.id || me.id === 0))` heißen.

**`session.save_path` gehört nach `~/etc/php.d/sessions.ini`, nicht in
`ini_set()`.**
Vorfall (08.07.2026): `ini_set('session.save_path', ...)` in der `config.php`
greift bei PHP-FPM zu spät. Global setzen und `uberspace tools restart php`.

**Der JSESSIONID-Cookie aus `authenticate` muss an alle Folgeaufrufe.**
Vorfall (08.07.2026): `getTeachers()` lieferte eine leere Antwort, weil der
Aufruf ohne Session-Cookie ging. Ergebnis war ein Login mit leerem Vor- und
Nachnamen — ohne Fehlermeldung. In `WebUntisAuth.php` wird der Cookie aus dem
`Set-Cookie`-Header gelesen und intern gehalten.

**WebUntis-Admins haben `personId = -1`.**
Vorfall (08.07.2026): personType 16 taucht nicht in `getTeachers()` auf, weil
Admins keine Stundenplan-Personen sind. Die Suche nach `personId` lief ins
Leere. Bei `personId <= 0` wird `getTeachers()` übersprungen und der Name über
das Kürzel aus der lokalen Datenbank geholt.

**Ein `UPDATE` darf keine Fremdschlüsselspalte auf 0 setzen.**
Vorfall (07.07.2026): Das Bearbeiten-Formular schickte kein `klasse_id`, der
Handler machte daraus `0`, der Fremdschlüssel schlug fehl. Der PHP-Fehler kam
als HTML zurück, im Browser erschien
`Unexpected token '<', "<!DOCTYPE "... is not valid JSON` — eine Meldung, die
nichts über die Ursache sagt. Bei fehlendem Wert die Spalte aus dem `UPDATE`
weglassen, nicht auf 0 setzen. Im selben Block war `$schuljahr_id` undefiniert.

**JavaScript-Variablen überleben keinen Deploy.**
Vorfall (07.07.2026): Die Werkstatt-ID lag in `WS_EDIT_ID`. Nach einem Deploy
lud der Browser die Seite neu, die Variable war `undefined`, das Speichern
schlug fehl. Kritische IDs gehören in ein verstecktes `<input>` im DOM, die
Variable bleibt nur Fallback.

**Von einer KI erzeugte Fachdaten gelten als unbelegt, bis sie gegen die
Quelle geprüft sind.**
Vorfall (10.07.2026): Die Kompetenzrahmen aller Fächer stammten aus einer
früheren KI-Sitzung. Die Struktur sah plausibel aus und war vollständig falsch
— G8-Kompetenzbereiche statt der G9-Inhaltsfelder, bei Sport 227 „Bereiche"
mit je genau einer Kompetenz. Aufgefallen ist es erst beim Abgleich mit dem
PDF des Kernlehrplans, Monate später. Siehe E8.

## Vor jeder Auslieferung wirklich prüfen

```bash
# 1. Läuft der Dienst?
ssh hornse@halimede.uberspace.de 'supervisorctl status projektstunden'

# 2. Trägt eine Session über zwei Requests?  (deckt die Session-Fallen oben ab)
curl -s -X POST https://projektstunden.hornse.de/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"<mail>","passwort":"<pw>"}' -c /tmp/c.txt > /dev/null && \
curl -s https://projektstunden.hornse.de/api/auth/me -b /tmp/c.txt
# Erwartet: JSON mit id/vorname/rolle. Bei {"error":"Nicht eingeloggt."} anhalten.

# 3. Hat der Cookie das Secure-Flag?
curl -s -X POST https://projektstunden.hornse.de/api/auth/login \
  -H "Content-Type: application/json" -d '{"username":"x","passwort":"x"}' \
  -D - -o /dev/null | grep -i set-cookie
# Erwartet: "; secure; HttpOnly; SameSite=Lax"

# 4. Serverfehler seit dem letzten Deploy?
ssh hornse@halimede.uberspace.de 'supervisorctl tail projektstunden stderr' | tail -20

# 5. Ausliefern
./deploy.sh "<commit message>"
```

**Offen: Dieses Projekt hat kein Testskript.** Solange das so ist, sind
„Ausgangsstand" und „erwartete Prüfungszahl" in jedem Auftrag leer. Das ist
eine bekannte Lücke, keine Nachlässigkeit im Einzelfall — siehe
`docs/AUFTRAG-testskript.md`.

## Was nicht in git gehört

`backend/config.php` steht in `.gitignore` und enthält das Datenbankpasswort
und die WebUntis-Konfiguration. Sie wird beim Deploy **nicht** überschrieben.
Änderungen daran müssen auf dem Server von Hand nachgezogen und hier vermerkt
werden, sonst gehen sie beim nächsten Aufsetzen verloren.

## Arbeitsweise

- „Ich weiß es nicht" statt einer plausiblen Vermutung. Besonders bei
  Fachdaten aus Lehrplänen: lieber die Quelle anfordern als rekonstruieren.
- Rückfragen vor Entscheidungen mit Tragweite, nicht danach.
- Gefundene Fehler werden mitbehoben und benannt, auch außerhalb des Auftrags.
- Bei einem roten Testlauf anhalten und melden, nicht reparieren.
