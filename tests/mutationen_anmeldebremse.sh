#!/bin/bash
# ============================================================
# tests/mutationen_anmeldebremse.sh – prüft die Prüfungen der Anmeldebremse
#
# Baut nacheinander bewusste Fehler in die Bremse ein und belegt je Fehler,
# dass tests/anmeldebremse_test.php rot wird – an der erwarteten Zeile.
# Dazu zwei Gegenproben:
#   E1  Ist die Suite rot, muss auch tests-projektstunden.sh rot sein
#       (die Einbindung, nicht nur die Suite).
#   H1  Eine harmlose Änderung (ein Kommentar) darf NICHT anschlagen –
#       sonst schlägt die Suite auf alles an und belegt nichts.
#
# Je Mutation: Prüfsumme vorher → Sicherung → Eingriff → Nachweis, dass er
# angekommen ist (Prüfsumme anders, php -l heil) → Suite → Rücknahme aus der
# Sicherung (nie aus dem Index) → Prüfsumme gleich vorher.
#
# Wird nicht von tests-projektstunden.sh aufgerufen – sie verändert
# vorübergehend den Code. Aufruf im Projektordner:
#   ./tests/mutationen_anmeldebremse.sh
#
# SPDX-License-Identifier: GPL-3.0-or-later
# ============================================================
set -u
export LC_ALL=C
R="$(cd "$(dirname "$0")/.." && pwd)"
SICH="$(mktemp -d)"
OFFEN=""
FEHLT=0
GELAUFEN=0
summe() { shasum "$1" | cut -c1-12; }
zuruecknehmen() {
  if [ -n "$OFFEN" ]; then cp "$SICH/sicherung" "$OFFEN"; echo "Abbruch: offene Mutation in $OFFEN zurückgenommen."; fi
  rm -rf "$SICH"
}
trap zuruecknehmen EXIT

# In der Hauptschale aufrufen, nie in $(…): VORHER und OFFEN gingen sonst
# verloren, und die Rücknahme hätte keinen Sollstand.
einbauen() {      # NAME DATEI AUSDRUCK → 0 wenn angekommen und heil
  VORHER=$(summe "$2"); cp "$2" "$SICH/sicherung"; OFFEN="$2"
  perl -0777 -i -pe "$3" "$2"
  if [ "$(summe "$2")" = "$VORHER" ]; then echo "$1: MUTATION NICHT ANGEKOMMEN – Suchmuster prüfen"; return 1; fi
  php -l "$2" > /dev/null 2>&1 || { echo "$1: MUTATION KAPUTT – Syntaxfehler nach dem Einbau"; return 1; }
}
ruecknahme() {    # NAME DATEI
  cp "$SICH/sicherung" "$2"; OFFEN=""
  [ "$(summe "$2")" = "$VORHER" ] || { echo "ABBRUCH: Rücknahme von $1 misslungen"; exit 2; }
}

# mut NAME DATEI PERL-AUSDRUCK ERWARTETE-ZEILE
mut() {
  local name=$1 datei="$R/$2" ausdruck=$3 erwartet=$4 aus e treffer
  GELAUFEN=$((GELAUFEN + 1))
  if ! einbauen "$name" "$datei" "$ausdruck"; then
    FEHLT=$((FEHLT + 1))
  else
    aus=$(php "$R/tests/anmeldebremse_test.php" 2>/dev/null); e=$?
    treffer=$(printf '%s\n' "$aus" | grep -cF "✗ $erwartet" || true)
    if [ "$e" -ne 0 ] && [ "$treffer" -ge 1 ]; then echo "$name: angeschlagen („$erwartet“)"
    else echo "$name: NICHT ANGESCHLAGEN (exit=$e, „$erwartet“ rot: $treffer)"; FEHLT=$((FEHLT + 1)); fi
  fi
  ruecknahme "$name" "$datei"
}

# mutdb NAME DATEI PERL-AUSDRUCK ERWARTETE-ZEILE – wie mut, aber gemessen an
# der AUSGEFÜHRTEN Anmeldung (tests/anmeldung_db_test.sh, php -S, MariaDB,
# WebUntis-Ersatz). Für alles, was nur über HTTP zu sehen ist (Z. 7, Z. 8).
mutdb() {
  local name=$1 datei="$R/$2" ausdruck=$3 erwartet=$4 aus e treffer
  GELAUFEN=$((GELAUFEN + 1))
  if ! einbauen "$name" "$datei" "$ausdruck"; then
    FEHLT=$((FEHLT + 1))
  else
    aus=$("$R/tests/anmeldung_db_test.sh" 2>/dev/null); e=$?
    treffer=$(printf '%s\n' "$aus" | grep -cF "✗ $erwartet" || true)
    if [ "$e" -ne 0 ] && [ "$treffer" -ge 1 ]; then echo "$name: angeschlagen („$erwartet“, ausgeführt)"
    else echo "$name: NICHT ANGESCHLAGEN (exit=$e, „$erwartet“ rot: $treffer)"; FEHLT=$((FEHLT + 1)); fi
  fi
  ruecknahme "$name" "$datei"
}

php "$R/tests/anmeldebremse_test.php" > /dev/null 2>&1 || { echo "ABBRUCH: Suite schon vor der Serie rot"; exit 2; }
"$R/tests/anmeldung_db_test.sh" > /dev/null 2>&1 || { echo "ABBRUCH: ausgeführte Anmeldung schon vor der Serie rot"; exit 2; }

# Seit Auftrag A (E68): Die Bremse ist vendort (Modul v2.0.2, dort mit
# eigenen Mutationen belegt). Mutiert wird, was projekteigen ist:
# anmeldung.php (Schwelle, Ziel, Sätze, Verlauf), handle_auth (Ausgänge) und
# WebUntisAuth.php (Z. 7, Z. 8). M0 belegt die Prüfung „vendort, byte-gleich“.
B=backend/auth/Anmeldebremse.php
N=backend/auth/anmeldung.php
A=backend/api/index.php
WU=backend/auth/WebUntisAuth.php
V=backend/konfiguration.example.php
mut M0  $B 's/\x27wartezeit_s\x27    => 60, /\x27wartezeit_s\x27    => 61, /' "#1 backend/auth/Anmeldebremse.php ist Modul v2.0.2"
mut M1  $N 's/public const SCHWELLE = 8;/public const SCHWELLE = 9;/' "#2 Schwelle"
mut M2  $N 's/\[\x27schwelle\x27 => self::SCHWELLE,/[\x27schwelle\x27 => 5,/' "#3 unter der Schwelle"
mut M3  $N 's/FILTER_VALIDATE_EMAIL\)\) return \x27lokal\x27;/FILTER_VALIDATE_EMAIL)) return \x27webuntis:\x27;/' "N5 Ziel"
mut M4  $N 's/return \x27webuntis:\x27 \. strtolower\(/return \x27webuntis:\x27 . (/' "N5 Ziel"
mut M5  $N 's/date\(\x27Y-m-d H:i:s\x27, \$jetzt\)/date(\x27Y-m-d H:i:s\x27)/' "N6 Verlauf"
mut M6  $A 's/\$r = \$bremse->beginnen\(\$username, \$ziel\);/\$r = \$bremse->beginnen(\$username, \x27\x27);/' "#29 lokal, richtiges Passwort"
mut M7  $A 's/\$ende\(\$versuch, Anmeldebremse::ERFOLG, true, \x27lokal\x27\);/\$ende(\$versuch, Anmeldebremse::FEHLSCHLAG, true, \x27lokal\x27);/' "#29 lokal, richtiges Passwort"
mut M8  $A 's/\$ende\(\$versuch, Anmeldebremse::OHNE_ENTSCHEID, false, \x27schule_unbekannt\x27\);/\$ende(\$versuch, Anmeldebremse::FEHLSCHLAG, false, \x27schule_unbekannt\x27);/' "N1 WebUntis -8500"
mut M9  $A 's/\$ende\(\$versuch, Anmeldebremse::OHNE_ENTSCHEID, false, \x27webuntis_nicht_erreichbar\x27\);/\$ende(\$versuch, Anmeldebremse::FEHLSCHLAG, false, \x27webuntis_nicht_erreichbar\x27);/' "#32 kein lokales Konto"
mut M10 $A 's/if \(\$keinEntscheid && \$lokalFalsch\) \{/if (false) {/' "N2 WebUntis -8500 nach falschem lokalem Passwort"
mut M11 $A 's/            Anmeldung::verlauf\(\$db, \$username, \$ziel, false, \x27wartezeit\x27\);\n//' "#31 lokal, Schwelle erreicht"
mut M12 $A 's/json_error\(Anmeldung::SATZ_BREMSE_FEHLER, 503\);/json_error(Anmeldung::SATZ_ABGELEHNT, 401);/' "#34 die Zählung scheitert"
mut M13 $A 's/\$ende\(\$versuch, Anmeldebremse::FEHLSCHLAG, false, \x27schueler_id_fehlt\x27\);/\$ende(\$versuch, Anmeldebremse::ERFOLG, false, \x27schueler_id_fehlt\x27);/' "#38 WebUntis: Schüler ohne Schild-ID"
mut M14 $A 's/json_error\(Anmeldung::SATZ_ABGELEHNT, 401\);\n            \}\n\n            if \(\$result !== null\)/json_error(\x27Ungültige Anmeldedaten.\x27, 401);\n            }\n\n            if (\$result !== null)/' "#41"
mut M15 $V 's/(\$WEBUNTIS_CONFIG = \[\n)/$1    \x27lockout_minutes\x27      => 15,\n/' "#42 die Vorlage nennt weder Schwelle noch Zählfenster"
mutdb D1 $WU 's/if \(\(int\)\(\$authResponse\[\x27error\x27\]\[\x27code\x27\] \?\? 0\) === -8500\) \{/if (false) {/' "A2 WebUntis -8500 (Schule unbekannt): Status 503"
mutdb D2 $WU 's/\$this->grund = \$this->transportfehler \? \x27ohne_entscheid\x27 : \x27http_abgelehnt\x27;/\$this->grund = \x27ohne_entscheid\x27;/' "A3 WebUntis HTTP 404: Status 401"
mutdb D3 $WU 's/(if \(\$httpCode >= 500 && \$httpCode <= 599\) \{\n[^\n]*\n)            \$this->transportfehler = true;\n/$1/' "A4 WebUntis HTTP 503: Status 503"
mutdb D4 $WU 's/(cURL-Fehler bei method=\{\$method\}: \{\$curlErr\}"\);\n)            \$this->transportfehler = true;\n/$1/' "A5 WebUntis Zeitüberschreitung: Status 503"
mutdb D5 $A 's/header\(\x27Retry-After: \x27 \. \(int\)\$r\[\x27sekunden\x27\]\);/header(\x27Retry-After: 61\x27);/' "A9 Retry-After"

# E1 – die Einbindung: Ist die Suite rot, muss tests-projektstunden.sh rot sein.
GELAUFEN=$((GELAUFEN + 1))
if einbauen E1 "$R/$N" 's/public const SCHWELLE = 8;/public const SCHWELLE = 9;/'; then
  if (cd "$R" && ./tests-projektstunden.sh > /dev/null 2>&1); then
    echo "E1: NICHT ANGESCHLAGEN – tests-projektstunden.sh übersieht die rote Suite"; FEHLT=$((FEHLT + 1))
  elif grep -qF "✗ Anmeldebremse: #2 Schwelle" "$R/logs/pruefung-letzter.txt"; then
    echo "E1: angeschlagen (tests-projektstunden.sh rot, an der erwarteten Zeile)"
  else
    echo "E1: NICHT AN DER ERWARTETEN ZEILE – tests-projektstunden.sh rot, aber nicht wegen der Bremse"; FEHLT=$((FEHLT + 1))
  fi
else
  FEHLT=$((FEHLT + 1))
fi
ruecknahme E1 "$R/$N"

# H1 – harmlos: ein Kommentar ändert sich. Die Suite muss grün bleiben.
GELAUFEN=$((GELAUFEN + 1))
if einbauen H1 "$R/$N" 's/ \* DAS ZIEL\./ * DAS ZIEL (harmlos geändert)./'; then
  if php "$R/tests/anmeldebremse_test.php" > /dev/null 2>&1; then
    echo "H1: richtig nicht angeschlagen (harmlose Änderung, Suite grün)"
  else
    echo "H1: FALSCH ANGESCHLAGEN – die Suite wird bei einer harmlosen Änderung rot"; FEHLT=$((FEHLT + 1))
  fi
else
  FEHLT=$((FEHLT + 1))
fi
ruecknahme H1 "$R/$N"

# H2, H3 – die Sätze und der alte Schlüssel als KOMMENTAR dürfen nicht
# anschlagen: Die Prüfungen lesen Zeichenketten über den Tokenizer, nicht Text.
for h in "H2|$A|s/(function handle_auth\\()/\\/\\/ json_error(\x27Ungültige Anmeldedaten.\x27, 401);\\n\$1/" \
         "H3|$V|s/(\\\$WEBUNTIS_CONFIG = \\[\\n)/\$1    \\/\\/ \x27max_failed_logins\x27 => 5,\\n/"; do
  hn=${h%%|*}; rest=${h#*|}; hd=${rest%%|*}; ha=${rest#*|}
  GELAUFEN=$((GELAUFEN + 1))
  if einbauen "$hn" "$R/$hd" "$ha"; then
    if php "$R/tests/anmeldebremse_test.php" > /dev/null 2>&1; then
      echo "$hn: richtig nicht angeschlagen (Kommentar, Suite grün)"
    else
      echo "$hn: FALSCH ANGESCHLAGEN – die Prüfung liest einen Kommentar"; FEHLT=$((FEHLT + 1))
    fi
  else
    FEHLT=$((FEHLT + 1))
  fi
  ruecknahme "$hn" "$R/$hd"
done

echo ""
# Null gelaufene Mutationen sind ein Fehler, kein sauberer Lauf.
[ "$GELAUFEN" -ge 25 ] || { echo "FEHLER: nur $GELAUFEN Mutationen gelaufen, erwartet 25"; exit 1; }
if [ "$FEHLT" -eq 0 ]; then echo "ALLE $GELAUFEN MUTATIONEN BELEGT"; exit 0; fi
echo "$FEHLT VON $GELAUFEN MUTATION(EN) OHNE BELEG"; exit 1
