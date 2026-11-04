#!/bin/bash
# ============================================================
# tests/kontotyp_db_test.sh – Filter nach Kontotyp (Z1/Z2), mit Datenbank
#
# Was tests/kontotyp_test.php ohne Datenbank nicht sehen kann:
#   - Z2: ein Schüler mit derselben Nummer wie eine Lernbegleitung
#   - die Lehrkraftseite MIT Inhalt (nicht nur „nicht abgewiesen“)
#   - jede Stufe EINZELN, die andere ausgehängt (REIHENREGELN 2):
#     A = Filter im Verteiler, B = Wächter require_lehrkraft()
#
# Die Voraussetzung stellt das Skript selbst her: eine eigene MariaDB in
# einem Wegwerfverzeichnis, nur 127.0.0.1, Schema aus sql/, Probebestand
# tests/daten/kontotyp_probedaten.sql (ERFUNDEN). Drei Probebäume unter
# php -S: vollständig, ohne A, ohne B. Ausgehängt wird nur in der KOPIE.
# Die echte backend/config.php wird nicht kopiert.
#
# Exit 0 grün, 1 rot, 3 ÜBERSPRUNGEN (kein mariadbd). Übersprungen ist
# sichtbar und hält deploy.sh an (Entscheidung Sebastian, 04.11.2026).
# MARIADBD=/pfad setzt den Server fest – auch für die Gegenprobe „fehlt“.
#
# Aufruf im Projektordner:  ./tests/kontotyp_db_test.sh
#
# SPDX-License-Identifier: GPL-3.0-or-later
# ============================================================
set -u
export LC_ALL=C
R="$(cd "$(dirname "$0")/.." && pwd)"
cd "$R" || exit 1

MARIADBD="${MARIADBD:-$(command -v mariadbd || true)}"
if [ -z "$MARIADBD" ] || [ ! -x "$MARIADBD" ]; then
    echo "  –  ÜBERSPRUNGEN: mariadbd nicht gefunden – Z2 und Stufen A/B einzeln nicht mit Datenbank geprüft"
    exit 3
fi
BIN="$(dirname "$MARIADBD")"
INSTALL="$BIN/mariadb-install-db"
KLIENT="$BIN/mariadb"; [ -x "$KLIENT" ] || KLIENT="$BIN/mysql"

GRUEN=0; FEHLER=0
pr() { # ok(1/0) Text [Detail]
    if [ "$1" = 1 ]; then echo "  ✓ $2"; GRUEN=$((GRUEN + 1))
    else echo "  ✗ $2"; [ -n "${3:-}" ] && echo "      $3"; FEHLER=$((FEHLER + 1)); fi
}
ende() { echo "  $GRUEN/$((GRUEN + FEHLER)) mit Datenbank bestanden"; [ "$FEHLER" -eq 0 ] && exit 0; exit 1; }

if [ ! -x "$INSTALL" ] || [ ! -x "$KLIENT" ]; then
    pr 0 "MariaDB-Werkzeuge neben $MARIADBD vollständig" "mariadb-install-db oder Klient fehlt"
    ende
fi

T="$(mktemp -d "${TMPDIR:-/tmp}/ps-ktdb.XXXXXX")" || { echo "  ✗ mktemp gescheitert"; exit 1; }
PIDS=""
aufraeumen() {
    for p in $PIDS; do kill "$p" 2>/dev/null; done
    [ -f "$T/m.pid" ] && kill "$(cat "$T/m.pid")" 2>/dev/null
    for p in $PIDS; do wait "$p" 2>/dev/null; done
    rm -rf "${T:?}"
}
trap aufraeumen EXIT

freier_port() { php -r '$s=stream_socket_server("tcp://127.0.0.1:0");$n=stream_socket_get_name($s,false);echo substr($n,strrpos($n,":")+1);'; }
root() { (cd "$T/data" && "$KLIENT" --no-defaults --socket=m.sock -uroot "$@"); }

# ---- Server ---------------------------------------------------------
DBPORT=$(freier_port)
"$INSTALL" --no-defaults --datadir="$T/data" --auth-root-authentication-method=normal \
    --skip-test-db > "$T/install.log" 2>&1 || { pr 0 "MariaDB eingerichtet" "mariadb-install-db: Exit $?"; ende; }
# Socket relativ zum Datenverzeichnis: absolute Pfade unter $TMPDIR können
# die Grenze von 103 Zeichen überschreiten (beobachtet 04.11.2026).
(cd "$T/data" && exec "$MARIADBD" --no-defaults --datadir="$T/data" --socket=m.sock \
    --port="$DBPORT" --bind-address=127.0.0.1 --pid-file="$T/m.pid" --log-error="$T/err.log" > "$T/start.log" 2>&1) &
PIDS="$PIDS $!"
bereit=0
for _ in $(seq 1 100); do
    if root -e 'SELECT 1' > /dev/null 2>&1; then bereit=1; break; fi
    perl -e 'select(undef,undef,undef,0.1)'
done
[ "$bereit" = 1 ] || { pr 0 "MariaDB gestartet" "keine Antwort nach 10 s"; ende; }
root -e "CREATE DATABASE kt CHARACTER SET utf8mb4; CREATE USER 'kt'@'127.0.0.1' IDENTIFIED BY 'kt'; GRANT ALL ON kt.* TO 'kt'@'127.0.0.1';" \
    || { pr 0 "Probedatenbank angelegt"; ende; }
db() { "$KLIENT" --no-defaults -h127.0.0.1 -P"$DBPORT" -ukt -pkt kt "$@"; }

# ---- Schema und Probebestand ----------------------------------------
# Schema und Migrationen aus sql/ in Nummernfolge; die Seeds der Kataloge
# (ausser 02, Schule und Fächer) gehören nicht zur Zugriffsfrage.
schema_fehler=""; schema_zahl=0
for f in sql/[0-9][0-9]_*.sql; do
    [ -f "$f" ] || continue
    case "$f" in sql/02_seed.sql) ;; *_seed_*) continue ;; esac
    schema_zahl=$((schema_zahl + 1))
    db < "$f" > /dev/null 2>> "$T/schema.err" || schema_fehler="$schema_fehler $f"
done
php -r 'echo str_replace("@@HASH@@", password_hash("kt-probe-pw", PASSWORD_BCRYPT), file_get_contents($argv[1]));' \
    tests/daten/kontotyp_probedaten.sql | db 2>> "$T/schema.err" || schema_fehler="$schema_fehler probedaten"
ZAEHL=$(db -N -e "SELECT CONCAT_WS(',', (SELECT COUNT(*) FROM schueler), (SELECT COUNT(*) FROM benutzer),
    (SELECT COUNT(*) FROM projekte), (SELECT COUNT(*) FROM projekt_lehrer), (SELECT COUNT(*) FROM projekt_schueler),
    (SELECT COUNT(*) FROM projekt_schueler_kompetenzen), (SELECT COUNT(*) FROM werkstatt_rueckmeldungen))" 2>/dev/null)
pr "$([ -z "$schema_fehler" ] && [ "$schema_zahl" -gt 0 ] && [ "$ZAEHL" = "6,3,2,2,3,1,2" ] && echo 1 || echo 0)" \
    "Probebestand: $schema_zahl Schemadateien, Zählung schueler,benutzer,projekte,projekt_lehrer,projekt_schueler,kompetenzen,rueckmeldungen = $ZAEHL" \
    "erwartet 6,3,2,2,3,1,2; gescheitert:${schema_fehler:- nichts}"

# ---- Drei Probebäume --------------------------------------------------
mkdir -p "$T/sess"
baum() { # NAME
    local b="$T/$1"
    mkdir -p "$b"
    (cd "$R" && find backend -type f ! -name 'config.php*' -print) | while IFS= read -r f; do
        mkdir -p "$b/$(dirname "$f")"; cp "$R/$f" "$b/$f"
    done
    php -r '
        $k = file_get_contents($argv[1]); $n = 0;
        foreach ([
          "ini_set(\x27session.save_path\x27, \x27/home/hornse/tmp/sessions\x27);" => "ini_set(\x27session.save_path\x27, \x27$argv[3]\x27);",
          "define(\x27DB_PORT\x27,    3306);" => "define(\x27DB_PORT\x27,    $argv[4]);",
          "define(\x27DB_NAME\x27,    \x27hornse_projektstunden\x27);" => "define(\x27DB_NAME\x27,    \x27kt\x27);",
          "define(\x27DB_USER\x27,    \x27hornse\x27);" => "define(\x27DB_USER\x27,    \x27kt\x27);",
          "define(\x27DB_PASS\x27,    \x27DEIN_DATENBANKPASSWORT\x27);" => "define(\x27DB_PASS\x27,    \x27kt\x27);",
          "define(\x27WEBUNTIS_ENABLED\x27, true);" => "define(\x27WEBUNTIS_ENABLED\x27, false);",
        ] as $a => $z) { $k = str_replace($a, $z, $k, $c); $n += $c; }
        file_put_contents($argv[2], $k); exit($n === 6 ? 0 : 1);' \
        "$R/backend/config.example.php" "$b/backend/config.php" "$T/sess" "$DBPORT"
}
# aushaengen NAME DATEI MUSTER(perl) AUSDRUCK → 0, wenn genau ein Treffer und angekommen
aushaengen() {
    local d="$T/$1/$2" n vorher
    [ -f "$d" ] || { echo "      Aushängen in $1/$2: Datei fehlt"; return 1; }
    n=$(perl -0777 -ne "\$n = () = /$3/g; print \$n" "$d")
    [ "$n" = "1" ] || { echo "      Aushängen in $1/$2: Muster ${n}-mal, erwartet genau einmal"; return 1; }
    vorher=$(shasum "$d"); perl -0777 -i -pe "$4" "$d"
    [ "$(shasum "$d")" != "$vorher" ] && php -l "$d" > /dev/null 2>&1
}
starten() { # NAME → setzt PORT_<NAME>
    local p; p=$(freier_port)
    (cd "$T/$1" && exec php -S "127.0.0.1:$p" backend/router.php > /dev/null 2>&1) &
    PIDS="$PIDS $!"
    for _ in $(seq 1 50); do
        curl -s -o /dev/null "http://127.0.0.1:$p/api/auth/me" && break
        perl -e 'select(undef,undef,undef,0.1)'
    done
    eval "PORT_$1=$p"
}
baeume_ok=1
baum voll  || baeume_ok=0
baum ohneA || baeume_ok=0
baum ohneB || baeume_ok=0
OHNE_A=0; OHNE_B=0
aushaengen ohneA backend/api/index.php \
    'if \(kontotyp_gefiltert\(\) && !schueler_route_erlaubt\(\$method, \$route, \$sub\)\) \{' \
    's/if \(kontotyp_gefiltert\(\) && !schueler_route_erlaubt\(\$method, \$route, \$sub\)\) \{/if (false) {/' && OHNE_A=1
aushaengen ohneB backend/api/kontotyp.php \
    'function require_lehrkraft\(\): array\n\{\n' \
    's/(function require_lehrkraft\(\): array\n\{\n)/$1    return require_auth();\n/' && OHNE_B=1
starten voll; starten ohneA; starten ohneB

SATZ_F=$(php -r 'require $argv[1]; echo defined("KONTOTYP_SATZ_FILTER") ? KONTOTYP_SATZ_FILTER : "";' "$R/backend/api/kontotyp.php" 2>/dev/null)
SATZ_W=$(php -r 'require $argv[1]; echo defined("KONTOTYP_SATZ_WAECHTER") ? KONTOTYP_SATZ_WAECHTER : "";' "$R/backend/api/kontotyp.php" 2>/dev/null)

# ---- Sitzungen --------------------------------------------------------
# Schüler: genau die Schlüssel der Schüleranmeldung (index.php). Die
# Anmeldung selbst geht nur über WebUntis und ist hier nicht ausgeführt.
for n in 57 101; do
    printf 'benutzer_id|i:%d;rolle|s:8:"schueler";schule_id|i:1;typ|s:8:"schueler";' "$n" > "$T/sess/sess_ktschueler$n"
done
S57="proj_session=ktschueler57"; S101="proj_session=ktschueler101"
# Lehrkraft: über den echten lokalen Anmeldeweg, durch die Bremse.
LK=$(curl -s -D - -o /dev/null -X POST "http://127.0.0.1:$PORT_voll/api/auth/login" -H 'Content-Type: application/json' \
    -d '{"email":"lb57@probe.invalid","username":"lb57@probe.invalid","passwort":"kt-probe-pw"}' \
    | tr -d '\r' | sed -n 's/^[Ss]et-[Cc]ookie: \(proj_session=[^;]*\).*/\1/p' | tail -1)
pr "$([ -n "$LK" ] && [ "$baeume_ok" = 1 ] && echo 1 || echo 0)" \
    "Lehrkraft 57 über POST /api/auth/login angemeldet (drei Probebäume gebaut)" \
    "Cookie: ${LK:+ja}${LK:-nein}, Probebäume: $baeume_ok"

# ruf BAUM COOKIE METHODE PFAD [KÖRPER] → setzt CODE, ZAHL (Listenlänge, sonst -1),
# FEHLER_SATZ, ZEILEN (nichtleere Zeilen bei Text)
ruf() {
    local d=() a="$T/antwort"
    [ $# -ge 5 ] && d=(-H 'Content-Type: application/json' -d "$5")
    rm -f "${a:?}"
    eval "local port=\$PORT_$1"
    CODE=$(curl -s -o "$a" -w '%{http_code}' -X "$3" -H "Cookie: $2" ${d[@]+"${d[@]}"} "http://127.0.0.1:$port/api/$4")
    [ -f "$a" ] || : > "$a"
    ZAHL=$(php -r '$j=json_decode(file_get_contents($argv[1]),true); echo is_array($j)&&array_is_list($j)?count($j):-1;' "$a")
    FEHLER_SATZ=$(php -r '$j=json_decode(file_get_contents($argv[1]),true); echo is_array($j)?($j["error"]??""):"";' "$a")
    ZEILEN=$(grep -c . "$a" || true)
    PORTAL=$(php -r '$j=json_decode(file_get_contents($argv[1]),true); echo isset($j["werkstaetten"])?count($j["werkstaetten"]):-1;' "$a")
}
ist() { [ "$1" = "$2" ] && echo 1 || echo 0; }
gefiltert() { [ "$CODE" = 403 ] && [ -n "$SATZ_F" ] && [ "$FEHLER_SATZ" = "$SATZ_F" ] && echo 1 || echo 0; }
bewacht()   { [ "$CODE" = 403 ] && [ -n "$SATZ_W" ] && [ "$FEHLER_SATZ" = "$SATZ_W" ] && echo 1 || echo 0; }
wie() { echo "bekam $CODE „$FEHLER_SATZ“, Zahl $ZAHL"; }

# ---- D3 – Lehrkraft mit Inhalt ---------------------------------------
ruf voll "$LK" GET schueler;           pr "$([ "$CODE" = 200 ] && ist "$ZAHL" 6)" "Lehrkraft: GET /api/schueler → 200, 6 Schüler" "$(wie)"
ruf voll "$LK" GET lehrer;             pr "$([ "$CODE" = 200 ] && ist "$ZAHL" 3)" "Lehrkraft: GET /api/lehrer → 200, 3 Konten" "$(wie)"
ruf voll "$LK" GET dashboard;          pr "$([ "$CODE" = 200 ] && ist "$ZAHL" 6)" "Lehrkraft: GET /api/dashboard → 200, 6 Schüler" "$(wie)"
ruf voll "$LK" GET export/stunden;     pr "$([ "$CODE" = 200 ] && ist "$ZEILEN" 7)" "Lehrkraft: GET /api/export/stunden → 200, 7 Zeilen (Kopf + 6)" "bekam $CODE, $ZEILEN Zeilen"
ruf voll "$LK" GET projekte;           pr "$([ "$CODE" = 200 ] && ist "$ZAHL" 1)" "Lehrkraft: GET /api/projekte → 200, 1 eigene Werkstatt" "$(wie)"
ruf voll "$LK" GET projekte/71;        pr "$(ist "$CODE" 200)" "Lehrkraft: GET /api/projekte/71 → 200" "$(wie)"
ruf voll "$LK" GET 'rueckmeldung?projekt_id=71'; pr "$([ "$CODE" = 200 ] && ist "$ZAHL" 2)" "Lehrkraft: GET /api/rueckmeldung?projekt_id=71 → 200, 2 Rückmeldungen" "$(wie)"

# ---- D4 – Schüler auf der Erlaubnisliste -----------------------------
ruf voll "$S101" GET schueler-portal
pr "$([ "$CODE" = 200 ] && ist "$PORTAL" 1)" "Schüler 101: GET /api/schueler-portal → 200, 1 Werkstatt" "bekam $CODE, Werkstätten $PORTAL"
KID=$(db -N -e 'SELECT kompetenz_id FROM projekt_schueler_kompetenzen WHERE projekt_id=71 AND schueler_id=101' 2>/dev/null)
ruf voll "$S101" PUT selbsteinschaetzung/71 "{\"kompetenz_id\":${KID:-0},\"selbst_stufe\":3}"
STUFE=$(db -N -e 'SELECT selbst_stufe FROM projekt_schueler_kompetenzen WHERE projekt_id=71 AND schueler_id=101' 2>/dev/null)
pr "$([ "$CODE" = 200 ] && ist "$STUFE" 3)" "Schüler 101: PUT /api/selbsteinschaetzung/71 → 200, Stufe 3 steht in der Tabelle" "bekam $CODE „$FEHLER_SATZ“, Stufe $STUFE"

# ---- D5 – Z1: Schüler 101 außerhalb der Liste -------------------------
for p in schueler lehrer dashboard export/stunden; do
    ruf voll "$S101" GET "$p"; pr "$(gefiltert)" "Schüler 101: GET /api/$p → 403 Filter" "$(wie)"
done
VOR=$(db -N -e 'SELECT COUNT(*) FROM schueler' 2>/dev/null)
ruf voll "$S101" POST schueler '{"vorname":"Probe","nachname":"Neuanlage","klasse_id":41}'
NACH=$(db -N -e 'SELECT COUNT(*) FROM schueler' 2>/dev/null)
pr "$([ "$(gefiltert)" = 1 ] && ist "$NACH" "$VOR")" "Schüler 101: POST /api/schueler → 403 Filter, Zahl der Schüler unverändert ($VOR)" "$(wie), vorher $VOR, nachher $NACH"

# ---- D6 – Z2: Schüler 57, Nummer wie Lehrkraft 57 ----------------------
for p in projekte projekte/71 'bewertung?projekt_id=71' 'rueckmeldung?projekt_id=71'; do
    ruf voll "$S57" GET "$p"; pr "$(gefiltert)" "Schüler 57 (Nummer wie Lehrkraft 57): GET /api/$p → 403 Filter" "$(wie)"
done

# ---- D7 – Stufe B allein (Filter ausgehängt) -------------------------
ruf ohneA "$S57" GET projekte/71
pr "$([ "$OHNE_A" = 1 ] && bewacht | grep -q 1 && echo 1 || echo 0)" "Stufe B allein (ohne Filter): Schüler 57 GET /api/projekte/71 → 403 Wächter" "Aushängen: $OHNE_A, $(wie)"
ruf ohneA "$S101" GET schueler
pr "$([ "$OHNE_A" = 1 ] && bewacht | grep -q 1 && echo 1 || echo 0)" "Stufe B allein (ohne Filter): Schüler 101 GET /api/schueler → 403 Wächter" "Aushängen: $OHNE_A, $(wie)"

# ---- D8 – Stufe A allein (Wächter ausgehängt) ------------------------
ruf ohneB "$S57" GET projekte/71
pr "$([ "$OHNE_B" = 1 ] && gefiltert | grep -q 1 && echo 1 || echo 0)" "Stufe A allein (ohne Wächter): Schüler 57 GET /api/projekte/71 → 403 Filter" "Aushängen: $OHNE_B, $(wie)"

ende
