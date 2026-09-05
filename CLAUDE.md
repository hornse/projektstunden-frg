# Projektgedächtnis: Projektstunden NRW

Diese Datei wird bei jedem Sessionstart automatisch gelesen. Was hier
steht, muss nicht mehr erklärt werden.

Ergänzend:
- Entscheidungen mit Begründung: @docs/ENTSCHEIDUNGEN.md
- Serverkonfiguration: @deploy/uberspace.md
- Konfigurationsreferenz: @docs/CONFIG.md
- Regeln der Reihe: @REIHENREGELN.md
- Fallstricke PHP/Router/WebUntis: @FALLSTRICKE.md

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
| Frontend | Vanilla JS, HTML, CSS |
| Backend | PHP 8.1+, eigener Router in `backend/router.php` |
| Datenbank | MariaDB 10.6 über PDO, Datenbank `hornse_projektstunden` |
| Auth | WebUntis JSON-RPC **und** lokales bcrypt-Passwort (beides, siehe E1) |
| Auslieferung | Uberspace 7, PHP built-in Server hinter SSL-Proxy, supervisord, Port 8082 |

Arbeitsverzeichnis lokal: `/Users/sebastianhorn/Projekte/projektstunden`
Work-Tree auf dem Server: `/home/hornse/projektstunden`
Zwei Remotes: `github` und `uberspace`. `deploy.sh` pusht auf beide.

## Eigene Werte und eigene Vorfälle

- **`session.save_path` steht in `~/etc/php.d/sessions.ini`**, nicht in
  einem `ini_set()`. Nach einer Änderung `uberspace tools restart php`.
  Die Sitzungsdateien liegen in `~/tmp/sessions`.
- **Der Schlüssel in der Sitzung heißt `benutzer_id`**, und
  WebUntis-Lehrkräfte ohne lokalen Datenbankeintrag bekommen dort die
  `0`. Sichtbar wurde das erst durch ein
  `error_log(json_encode($_SESSION))` in `require_auth()` — die
  Sitzungsdatei war nachweislich korrekt. Im Frontend muss es
  `if (me && (me.id || me.id === 0))` heißen.
- **Bei `personId <= 0` wird `getTeachers()` übersprungen** und der Name
  über das Kürzel aus der lokalen Datenbank geholt.
- **`WS_EDIT_ID`** war die Werkstatt-ID, die einen Deploy nicht
  überlebte. Kritische IDs liegen seither in einem versteckten `<input>`.
- **Beim Bearbeiten-Formular fehlte `klasse_id`**, der Handler machte
  daraus `0`, der Fremdschlüssel schlug fehl; im selben Block war
  `$schuljahr_id` undefiniert. Vorfall vom 07.07.2026.
- **Der Kompetenzkatalog stammte aus einer früheren KI-Sitzung** und war
  vollständig falsch: G8-Kompetenzbereiche statt der G9-Inhaltsfelder,
  bei Sport 227 „Bereiche" mit je genau einer Kompetenz. Aufgefallen erst
  beim Abgleich mit dem PDF des Kernlehrplans, Monate später (E8).

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
