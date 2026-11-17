#!/bin/bash
# ============================================================
# tests/fristen_db_test.sh – Fristen und sql/24, ausgeführt
#
# Auftrag A, Paket 3 (E68): audit_log mit Frist „Schuljahr + 1“ und ohne
# ip_adresse, anmeldeverlauf mit 30 Tagen; sql/24 räumt nach der Abnahme
# auf (webuntis_login_log, audit_log.ip_adresse). Die Prüfungen selbst stehen
# in tests/fristen_test.php; dieses Skript stellt die Voraussetzung her:
# MariaDB im Wegwerfverzeichnis, Schema aus sql/ OHNE sql/24, Probebaum mit
# konfiguration.php aus der Vorlage. Dann vor24, sql/24 zweimal, nach24.
#
# Exit 0 grün, 1 rot, 3 ÜBERSPRUNGEN (kein mariadbd) – Pflichtschritt wie
# anmeldung_db_test.sh.
#
# SPDX-License-Identifier: GPL-3.0-or-later
# ============================================================
set -u
export LC_ALL=C
R="$(cd "$(dirname "$0")/.." && pwd)"
cd "$R" || exit 1

MARIADBD="${MARIADBD:-$(command -v mariadbd || true)}"
if [ -z "$MARIADBD" ] || [ ! -x "$MARIADBD" ]; then
    echo "  –  ÜBERSPRUNGEN: mariadbd nicht gefunden – Fristen nicht mit Datenbank ausgeführt"
    exit 3
fi
BIN="$(dirname "$MARIADBD")"
KLIENT="$BIN/mariadb"; [ -x "$KLIENT" ] || KLIENT="$BIN/mysql"

GRUEN=0; FEHLER=0
pr() { # ok(1/0) Text [Detail]
    if [ "$1" = 1 ]; then echo "  ✓ $2"; GRUEN=$((GRUEN + 1))
    else echo "  ✗ $2"; [ -n "${3:-}" ] && echo "      $3"; FEHLER=$((FEHLER + 1)); fi
}
ende() { echo "  $GRUEN/$((GRUEN + FEHLER)) Fristen bestanden"; [ "$FEHLER" -eq 0 ] && exit 0; exit 1; }
# Ausgabe von fristen_test.php übernehmen und zählen
uebernehmen() {
    local z
    while IFS= read -r z; do
        case "$z" in
            "  ✓ "*) echo "$z"; GRUEN=$((GRUEN + 1)) ;;
            "  ✗ "*) echo "$z"; FEHLER=$((FEHLER + 1)) ;;
            "      "*) echo "$z" ;;
        esac
    done <<< "$1"
}

T="$(mktemp -d "${TMPDIR:-/tmp}/ps-frist.XXXXXX")" || { echo "  ✗ mktemp gescheitert"; exit 1; }
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
warte() { for _ in $(seq 1 100); do eval "$1" && return 0; perl -e 'select(undef,undef,undef,0.1)'; done; return 1; }

# ---- MariaDB ----------------------------------------------------------
DBPORT=$(freier_port)
"$BIN/mariadb-install-db" --no-defaults --datadir="$T/data" --auth-root-authentication-method=normal \
    --skip-test-db > "$T/install.log" 2>&1 || { pr 0 "MariaDB eingerichtet"; ende; }
(cd "$T/data" && exec "$MARIADBD" --no-defaults --datadir="$T/data" --socket=m.sock --port="$DBPORT" \
    --bind-address=127.0.0.1 --pid-file="$T/m.pid" --log-error="$T/err.log" > /dev/null 2>&1) &
PIDS="$PIDS $!"
warte "root -e 'SELECT 1' > /dev/null 2>&1" || { pr 0 "MariaDB gestartet"; ende; }
root -e "CREATE DATABASE fr CHARACTER SET utf8mb4; CREATE USER 'fr'@'127.0.0.1' IDENTIFIED BY 'fr'; GRANT ALL ON fr.* TO 'fr'@'127.0.0.1';" \
    || { pr 0 "Probedatenbank angelegt"; ende; }
db() { "$KLIENT" --no-defaults -h127.0.0.1 -P"$DBPORT" -ufr -pfr fr "$@"; }
schema_fehler=""; schema_zahl=0
for f in sql/[0-9][0-9]_*.sql; do
    case "$f" in sql/02_seed.sql) ;; *_seed_*) continue ;; sql/24_*) continue ;; esac
    schema_zahl=$((schema_zahl + 1))
    db < "$f" > /dev/null 2>> "$T/schema.err" || schema_fehler="$schema_fehler $f"
done
SPALTE=$(db -N -e "SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA='fr' AND TABLE_NAME='audit_log' AND COLUMN_NAME='ip_adresse'" 2>/dev/null)

# ---- Probebaum: backend/ ohne echte Konfiguration ---------------------
B="$T/baum"
find backend -type f ! -name 'config.php*' ! -name 'konfiguration.php*' -print | while IFS= read -r f; do
    mkdir -p "$B/$(dirname "$f")"; cp "$f" "$B/$f"
done
mkdir -p "$T/sess"
php -r '
  $k = file_get_contents($argv[1]); $n = 0;
  foreach ([
    "ini_set(\x27session.save_path\x27, \x27/home/hornse/tmp/sessions\x27);" => "ini_set(\x27session.save_path\x27, \x27$argv[3]\x27);",
    "define(\x27DB_PORT\x27,    3306);" => "define(\x27DB_PORT\x27,    $argv[4]);",
    "define(\x27DB_NAME\x27,    \x27hornse_projektstunden\x27);" => "define(\x27DB_NAME\x27,    \x27fr\x27);",
    "define(\x27DB_USER\x27,    \x27hornse\x27);" => "define(\x27DB_USER\x27,    \x27fr\x27);",
    "define(\x27DB_PASS\x27,    \x27DEIN_DATENBANKPASSWORT\x27);" => "define(\x27DB_PASS\x27,    \x27fr\x27);",
  ] as $a => $z) { $k = str_replace($a, $z, $k, $c); $n += $c; }
  file_put_contents($argv[2], $k); exit($n === 5 ? 0 : 1);' \
  backend/konfiguration.example.php "$B/backend/konfiguration.php" "$T/sess" "$DBPORT"
KONF=$?
pr "$([ -z "$schema_fehler" ] && [ "$schema_zahl" -gt 0 ] && [ "$KONF" = 0 ] && [ "$SPALTE" = 1 ] && echo 1 || echo 0)" \
    "Voraussetzung: $schema_zahl Schemadateien ohne sql/24, audit_log mit ip_adresse, Konfiguration (5 Ersetzungen)" \
    "gescheitert:${schema_fehler:- nichts}, Konfiguration Exit $KONF, Spalte ip_adresse: ${SPALTE:-?}"

# ---- vor sql/24 -----------------------------------------------------------
phase() { # vor24|nach24 – Ausgabe übernehmen; endet PHP ohne rote Zeile mit Fehler, ist das rot
    local aus e
    aus=$(php tests/fristen_test.php "$B" "$1" "$T/fehler.log" 2>&1); e=$?
    uebernehmen "$aus"
    if [ "$e" -ne 0 ] && ! printf '%s\n' "$aus" | grep -q '^  ✗ '; then
        pr 0 "fristen_test.php $1 endete mit $e ohne rote Zeile" "$(printf '%s\n' "$aus" | grep -v '^  [✓✗]' | head -3)"
    fi
}
phase vor24

# ---- sql/24, zweimal (FALLSTRICKE 4: SQL zweimal einspielen) --------------
S24=$(ls sql/24_*.sql 2>/dev/null | head -1)
if [ -z "$S24" ]; then
    pr 0 "sql/24 vorhanden und zweimal eingespielt" "keine Datei sql/24_*.sql"
else
    e1=0; e2=0
    db < "$S24" > /dev/null 2>> "$T/s24.err" || e1=$?
    db < "$S24" > /dev/null 2>> "$T/s24.err" || e2=$?
    pr "$([ "$e1" = 0 ] && [ "$e2" = 0 ] && echo 1 || echo 0)" "$S24 zweimal eingespielt, ohne Fehler" \
        "Exit $e1 und $e2"
fi

# ---- nach sql/24 ------------------------------------------------------------
phase nach24

# Die Zahl der Prüfungen steht fest: 1 Voraussetzung, 17 vor sql/24, 1 sql/24,
# 3 danach. Fehlt eine, ist das rot – eine fehlende Zeile sähe sonst aus wie
# eine bestandene (REIHENREGELN 2).
SOLL=22
[ $((GRUEN + FEHLER)) -eq "$SOLL" ] || pr 0 "Zahl der Prüfungen: $((GRUEN + FEHLER)) statt $SOLL"
ende
