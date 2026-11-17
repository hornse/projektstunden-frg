#!/bin/bash
# ============================================================
# tests/anmeldung_db_test.sh – die Anmeldung, ausgeführt
#
# Auftrag A (koordination AUFTRAG-projektstunden-A-anmeldung-modul.md,
# Paket 2; Befund §5 „Anmeldung“): POST /api/auth/login gegen php -S, mit
# eigener MariaDB und einem WebUntis-Ersatz über HTTPS
# (tests/daten/webuntis_ersatz.php). Je Fall drei Prüfungen: Statuscode,
# Satz, und ob der Versuch in der Bremse zählt (Zeile in anmeldebremse).
#
# Entstanden aus dem Messskript von Schritt 1 (12.11.2026), das Z. 7 und
# Z. 8 des Befunds ausgeführt bestätigt hat: -8500 → 401 und gezählt,
# HTTP 404 → 503 „nicht erreichbar“ und nicht gezählt.
#
# Die SÄTZE sind Erwartungswerte aus FALLSTRICKE 8, keine Abschrift aus dem
# Code. Kennungen, Namen und Passwörter sind ERFUNDEN.
#
# Die Voraussetzung stellt das Skript selbst her, wie kontotyp_db_test.sh:
# MariaDB im Wegwerfverzeichnis, Schema aus sql/, Probebaum mit
# konfiguration.php aus der Vorlage. Die echte Konfiguration wird nicht
# kopiert.
#
# Exit 0 grün, 1 rot, 3 ÜBERSPRUNGEN (kein mariadbd) – Pflichtschritt wie
# kontotyp_db_test.sh.
#
# SPDX-License-Identifier: GPL-3.0-or-later
# ============================================================
set -u
export LC_ALL=C
R="$(cd "$(dirname "$0")/.." && pwd)"
cd "$R" || exit 1

MARIADBD="${MARIADBD:-$(command -v mariadbd || true)}"
if [ -z "$MARIADBD" ] || [ ! -x "$MARIADBD" ]; then
    echo "  –  ÜBERSPRUNGEN: mariadbd nicht gefunden – Anmeldung nicht mit Datenbank ausgeführt"
    exit 3
fi
BIN="$(dirname "$MARIADBD")"
KLIENT="$BIN/mariadb"; [ -x "$KLIENT" ] || KLIENT="$BIN/mysql"

GRUEN=0; FEHLER=0
pr() { # ok(1/0) Text [Detail]
    if [ "$1" = 1 ]; then echo "  ✓ $2"; GRUEN=$((GRUEN + 1))
    else echo "  ✗ $2"; [ -n "${3:-}" ] && echo "      $3"; FEHLER=$((FEHLER + 1)); fi
}
ende() { echo "  $GRUEN/$((GRUEN + FEHLER)) Anmeldung ausgeführt bestanden"; [ "$FEHLER" -eq 0 ] && exit 0; exit 1; }

T="$(mktemp -d "${TMPDIR:-/tmp}/ps-anm.XXXXXX")" || { echo "  ✗ mktemp gescheitert"; exit 1; }
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
root -e "CREATE DATABASE an CHARACTER SET utf8mb4; CREATE USER 'an'@'127.0.0.1' IDENTIFIED BY 'an'; GRANT ALL ON an.* TO 'an'@'127.0.0.1';" \
    || { pr 0 "Probedatenbank angelegt"; ende; }
db() { "$KLIENT" --no-defaults -h127.0.0.1 -P"$DBPORT" -uan -pan an "$@"; }
schema_fehler=""; schema_zahl=0
for f in sql/[0-9][0-9]_*.sql; do
    case "$f" in sql/02_seed.sql) ;; *_seed_*) continue ;; esac
    schema_zahl=$((schema_zahl + 1))
    db < "$f" > /dev/null 2>> "$T/schema.err" || schema_fehler="$schema_fehler $f"
done
HASH=$(php -r 'echo password_hash("ada-probe-pw", PASSWORD_BCRYPT);')
db -e "INSERT INTO benutzer (id, schule_id, vorname, nachname, email, passwort_hash, rolle, kuerzel, aktiv)
       VALUES (4711, 1, 'Ada', 'Probe', 'ada@probe.invalid', '$HASH', 'admin', 'Prb', 1)" 2>> "$T/schema.err" \
    || schema_fehler="$schema_fehler probekonto"

# ---- WebUntis-Ersatz ----------------------------------------------------
mkdir -p "$T/wu" "$T/sess"
php tests/daten/webuntis_ersatz.php zertifikate "$T/wu" || { pr 0 "Zertifikate des Ersatzes erzeugt"; ende; }
WPORT=$(freier_port)
php tests/daten/webuntis_ersatz.php dienen "$WPORT" "$T/wu" > "$T/wu.log" 2>&1 &
PIDS="$PIDS $!"
warte "[ -f '$T/wu/bereit' ]" || { pr 0 "WebUntis-Ersatz gestartet"; ende; }

# ---- Probebaum: backend/ ohne echte Konfiguration, frontend/ ------------
B="$T/baum"
(find backend frontend -type f ! -name 'config.php*' ! -name 'konfiguration.php*' -print) | while IFS= read -r f; do
    mkdir -p "$B/$(dirname "$f")"; cp "$f" "$B/$f"
done
php -r '
  $k = file_get_contents($argv[1]); $n = 0;
  foreach ([
    "ini_set(\x27session.save_path\x27, \x27/home/hornse/tmp/sessions\x27);" => "ini_set(\x27session.save_path\x27, \x27$argv[3]\x27);",
    "define(\x27DB_PORT\x27,    3306);" => "define(\x27DB_PORT\x27,    $argv[4]);",
    "define(\x27DB_NAME\x27,    \x27hornse_projektstunden\x27);" => "define(\x27DB_NAME\x27,    \x27an\x27);",
    "define(\x27DB_USER\x27,    \x27hornse\x27);" => "define(\x27DB_USER\x27,    \x27an\x27);",
    "define(\x27DB_PASS\x27,    \x27DEIN_DATENBANKPASSWORT\x27);" => "define(\x27DB_PASS\x27,    \x27an\x27);",
    "\x27base_url\x27             => \x27https://frg-dusseldorf.webuntis.com\x27" => "\x27base_url\x27             => \x27https://127.0.0.1:$argv[5]\x27",
    "\x27timeout\x27              => 10," => "\x27timeout\x27              => 2,",
  ] as $a => $z) { $k = str_replace($a, $z, $k, $c); $n += $c; }
  file_put_contents($argv[2], $k); exit($n === 7 ? 0 : 1);' \
  backend/konfiguration.example.php "$B/backend/konfiguration.php" "$T/sess" "$DBPORT" "$WPORT"
KONF=$?

AP=$(freier_port)
(cd "$B" && exec php -d openssl.cafile="$T/wu/ca.pem" -S "127.0.0.1:$AP" backend/router.php > "$T/app.log" 2>&1) &
PIDS="$PIDS $!"
warte "curl -s -o /dev/null http://127.0.0.1:$AP/api/auth/me"
pr "$([ -z "$schema_fehler" ] && [ "$schema_zahl" -gt 0 ] && [ "$KONF" = 0 ] && echo 1 || echo 0)" \
    "Voraussetzung: $schema_zahl Schemadateien, Probekonto, Konfiguration (7 Ersetzungen), Ersatz und php -S gestartet" \
    "gescheitert:${schema_fehler:- nichts}, Konfiguration Exit $KONF"

# ---- Anmelden -------------------------------------------------------------
# anmelden KENNUNG PASSWORT → CODE, SATZ, RETRY
VERSUCHE=0
anmelden() {
    rm -f "${T:?}/kopf" "${T:?}/rumpf"
    CODE=$(curl -s -m 20 -D "$T/kopf" -o "$T/rumpf" -w '%{http_code}' -H 'Content-Type: application/json' \
        -d "{\"username\":\"$1\",\"passwort\":\"$2\"}" "http://127.0.0.1:$AP/api/auth/login")
    SATZ=$(php -r '$j=json_decode((string)@file_get_contents($argv[1]),true); echo is_array($j)?($j["error"]??($j["ok"]??false?"ok":"")):"";' "$T/rumpf")
    RETRY=$(tr -d '\r' < "$T/kopf" | sed -n 's/^[Rr]etry-[Aa]fter: *//p')
    VERSUCHE=$((VERSUCHE + 1))
}
# zaehlt KENNUNG → Zahl der Fehlversuche in der Bremse (erfolg = 0)
zaehlt() { db -N -e "SELECT COUNT(*) FROM anmeldebremse WHERE kennung = '$1' AND erfolg = 0" 2>/dev/null || echo "?"; }

ABGELEHNT='Ungültige Anmeldedaten.'
AUSFALL='WebUntis ist gerade nicht erreichbar. Bitte in ein paar Minuten erneut versuchen.'
SCHULE='Die Anmeldung ist gerade nicht möglich. Bitte der Schule Bescheid geben.'
BREMSE='Die Anmeldung ist gerade nicht möglich – die Prüfung der Anmeldeversuche antwortet nicht. Bitte in ein paar Minuten noch einmal.'

fall() { # Nr Beschreibung Kennung Passwort Status Satz Zahl-in-der-Bremse
    anmelden "$3" "$4"
    local z; z=$(zaehlt "$3")
    pr "$([ "$CODE" = "$5" ] && echo 1 || echo 0)" "$1 $2: Status $5" "bekam $CODE"
    pr "$([ "$SATZ" = "$6" ] && echo 1 || echo 0)" "$1 $2: Satz „$6“" "bekam „$SATZ“"
    pr "$([ "$z" = "$7" ] && echo 1 || echo 0)" "$1 $2: $([ "$7" = 0 ] && echo 'zählt nicht' || echo "zählt ($7 Fehlversuch)")" "Zeilen mit erfolg=0: $z"
}

fall A1 "WebUntis -8504 (falsches Passwort)"       probe.falsch  x 401 "$ABGELEHNT" 1
fall A2 "WebUntis -8500 (Schule unbekannt)"        probe.schule  x 503 "$SCHULE"    0
fall A3 "WebUntis HTTP 404"                        probe.vier    x 401 "$ABGELEHNT" 1
fall A4 "WebUntis HTTP 503"                        probe.fuenf   x 503 "$AUSFALL"   0
fall A5 "WebUntis Zeitüberschreitung"              probe.langsam x 503 "$AUSFALL"   0
fall A6 "WebUntis Erfolg (Lehrkraft)"              probe.gut     x 200 "ok"         0
fall A7 "lokal falsch, WebUntis fällt aus (E66)"   ada@probe.invalid falsch 401 "$ABGELEHNT" 1
# A8 nach A7, dieselbe Kennung: Der Fehlversuch aus A7 bleibt stehen – eine
# gelungene Anmeldung löscht nichts, sie setzt über die Nummer zurück. Erwartet
# ist deshalb 1, und eigens eine Zeile mit erfolg = 1 (erster roter Lauf:
# die Erwartung 0 übersah A7).
fall A8 "lokal richtig (nach A7)"                  ada@probe.invalid ada-probe-pw 200 "ok" 1
ERF=$(db -N -e "SELECT COUNT(*) FROM anmeldebremse WHERE kennung = 'ada@probe.invalid' AND erfolg = 1" 2>/dev/null || echo "?")
pr "$([ "$ERF" = 1 ] && echo 1 || echo 0)" "A8 lokal richtig: eine Zeile mit erfolg = 1 – setzt zurück" "Zeilen mit erfolg=1: $ERF"

# A9: probe.falsch hat 1 Fehlversuch; 7 weitere, dann der neunte Versuch
for _ in 2 3 4 5 6 7 8; do anmelden probe.falsch x; done
anmelden probe.falsch x
N=$(printf '%s' "$SATZ" | sed -nE 's/.* ([0-9]+) Sekunden?\.$/\1/p')
pr "$([ "$CODE" = 429 ] && [ -n "$N" ] && [ "$N" -ge 1 ] && [ "$N" -le 60 ] && echo 1 || echo 0)" \
    "A9 neunter Versuch nach acht Fehlversuchen: 429, Satz endet mit 1–60 Sekunden" "bekam $CODE „$SATZ“"
pr "$([ -n "$RETRY" ] && [ "$RETRY" = "$N" ] && echo 1 || echo 0)" \
    "A9 Retry-After nennt dieselben Sekunden wie der Satz" "Retry-After '$RETRY', Satz '$N'"

# A10: die Tabelle der Bremse fehlt
db -e 'RENAME TABLE anmeldebremse TO anmeldebremse_weg' 2>/dev/null
anmelden ada@probe.invalid ada-probe-pw
db -e 'RENAME TABLE anmeldebremse_weg TO anmeldebremse' 2>/dev/null
pr "$([ "$CODE" = 503 ] && [ "$SATZ" = "$BREMSE" ] && echo 1 || echo 0)" \
    "A10 Bremse ohne Tabelle: 503 mit eigenem Satz, auch vor dem richtigen lokalen Passwort" "bekam $CODE „$SATZ“"

# Ziel und Verlauf
ZIELE=$(db -N -e "SELECT CONCAT(kennung, '=', ziel) FROM anmeldebremse WHERE kennung IN ('probe.falsch', 'ada@probe.invalid') GROUP BY kennung, ziel ORDER BY kennung" 2>/dev/null | tr '\n' ' ')
pr "$([ "$ZIELE" = "ada@probe.invalid=lokal probe.falsch=webuntis:127.0.0.1 " ] && echo 1 || echo 0)" \
    "Ziel: E-Mail-Kennung zählt unter „lokal“, Kürzel unter „webuntis:<Host>“" "bekam: $ZIELE"
VERLAUF=$(db -N -e 'SELECT COUNT(*) FROM anmeldeverlauf' 2>/dev/null || echo "?")
pr "$([ "$VERLAUF" = "$VERSUCHE" ] && echo 1 || echo 0)" \
    "Verlauf: jeder der $VERSUCHE Versuche hat eine Zeile in anmeldeverlauf (auch Wartezeit, Ausfall, Bremse ohne Tabelle)" "Zeilen: $VERLAUF"
ADRESSE=$(db -N -e "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'an' AND table_name IN ('anmeldeverlauf', 'anmeldebremse') AND (column_name LIKE '%ip%' OR column_name LIKE '%adresse%')" 2>/dev/null || echo "?")
SPALTEN=$(db -N -e "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'an' AND table_name = 'anmeldeverlauf'" 2>/dev/null || echo 0)
pr "$([ "$ADRESSE" = 0 ] && [ "$SPALTEN" -gt 0 ] && echo 1 || echo 0)" \
    "Verlauf und Bremse ohne Spalte für eine Adresse ($SPALTEN Spalten im Verlauf gelesen)" "Adressspalten: $ADRESSE"

ende
