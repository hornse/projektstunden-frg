#!/bin/bash
# ============================================================
# tests/mutationen_sitzung.sh – Gegenproben zu Paket 4 (Sitzung)
#
# Auftrag A, Paket 4 (E68). Jede Mutation beschädigt den geprüften Code an
# einer Stelle; die erwartete Zeile muss rot werden. Zwei Prüfungen:
#   K = tests/kern_test.php        (Quelltext über den Tokenizer, Ableitung ausgeführt)
#   A = tests/anmeldung_db_test.sh (ausgeführt: php -S, MariaDB, WebUntis-Ersatz)
#
#   M1  Router: $_SERVER['HTTPS'] = 'on' wieder da                  K6 alte Fassung
#   M2  Router: session_name('proj_session') wieder da               K6 alte Fassung
#   M3  Vorlage: zweite Definition von SESSION_NAME                  K6 genau einmal
#   M4  Vorlage: ini_set('session.save_path', …) wieder da           K6 kein Speicherort
#   M5  Kern: SESSION_LIFETIME nicht mehr im Kern                    K6 genau einmal
#   M6  Ableitung: entfernt keine Sitzungsanweisung (Stufe 1)        K4 Speicherort
#   M7  Ableitung: Stufe 2 (Halt bei Rest) ausgehängt                K4 in einer Bedingung
#   M8  Ableitung: SESSION_NAME nicht mehr in der Liste              K4 Sitzungswerte
#   M9  Ableitung: Doc-Kommentar auch vor Sitzungsanweisungen weg    K4 Kopfkommentar bleibt
#   M10 pruefen: hält bei einem Sitzungswert nicht an                K4 pruefen SESSION_NAME
#   D1  Kern: benutzer_id 0 gilt als „nicht gesetzt“ (empty)         S2 id 0
#   D2  Kern: secure => false                                        S1 Set-Cookie
#   D3  Kern: SameSite Strict                                        S1 Set-Cookie
#   D4  Kern: httponly => false                                      S1 Set-Cookie
#   D5  Kern: anderer Sitzungsname                                   S5 niemand abgemeldet
#   D6  Kern: SESSION_LIFETIME 9 Stunden                             S1 Set-Cookie
#   D7  Kern: session_name() nicht gerufen (PHPSESSID)               S1 Set-Cookie
#   D8  Bremse (vendort): keine Rücksetzung nach Erfolg              S3 Rücksetzung
#   E1  Ist die Anmeldeprüfung rot, muss tests-projektstunden.sh rot sein
#   H1  Harmlos: die alte Fassung als KOMMENTAR im Router – grün
#   H2  Harmlos: der Satz session_name('proj_session') als Zeichenkette – grün
#
# D5 macht auch S1 rot (kein proj_session im Set-Cookie); geprüft wird S5,
# weil S5 sonst keine eigene Gegenprobe hätte. D8 macht auch die Prüfsumme
# der vendorten Bremse rot (anmeldebremse_test #1) – die läuft hier nicht mit.
#
# Rücknahme aus einer Sicherungskopie, mit Prüfsumme belegt (REIHENREGELN 3).
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
  rm -rf "${SICH:?}"
}
trap zuruecknehmen EXIT

# In der Hauptschale aufrufen, nie in $(…): VORHER und OFFEN gingen sonst verloren.
einbauen() {      # NAME DATEI AUSDRUCK → 0 wenn angekommen und heil
  VORHER=$(summe "$2"); cp "$2" "$SICH/sicherung"; OFFEN="$2"
  perl -0777 -i -pe "$3" "$2"
  if [ "$(summe "$2")" = "$VORHER" ]; then echo "$1: MUTATION NICHT ANGEKOMMEN – Suchmuster prüfen"; return 1; fi
  case "$2" in
    *.php) php -l "$2" > /dev/null 2>&1 || { echo "$1: MUTATION KAPUTT – Syntaxfehler nach dem Einbau"; return 1; } ;;
  esac
}
ruecknahme() {    # NAME DATEI
  cp "$SICH/sicherung" "$2"; OFFEN=""
  [ "$(summe "$2")" = "$VORHER" ] || { echo "ABBRUCH: Rücknahme von $1 misslungen"; exit 2; }
}
pruefung() {      # K|A → Ausgabe, Exit-Code in PE
  case "$1" in
    K) PA=$(php "$R/tests/kern_test.php" 2>/dev/null); PE=$? ;;
    A) PA=$("$R/tests/anmeldung_db_test.sh" 2>/dev/null); PE=$? ;;
  esac
}

# mut NAME K|A DATEI PERL-AUSDRUCK ERWARTETE-ZEILE (Anfang der Zeile genügt)
mut() {
  local name=$1 wer=$2 datei="$R/$3" ausdruck=$4 erwartet=$5 treffer
  GELAUFEN=$((GELAUFEN + 1))
  if ! einbauen "$name" "$datei" "$ausdruck"; then
    FEHLT=$((FEHLT + 1))
  else
    pruefung "$wer"
    treffer=$(printf '%s\n' "$PA" | grep -cF "✗ $erwartet" || true)
    if [ "$PE" -ne 0 ] && [ "$treffer" -ge 1 ]; then echo "$name: angeschlagen („$erwartet“)"
    else echo "$name: NICHT ANGESCHLAGEN (exit=$PE, „$erwartet“ rot: $treffer)"; FEHLT=$((FEHLT + 1)); fi
  fi
  ruecknahme "$name" "$datei"
}

# Vorprüfung: beide unverändert grün, jede erwartete Zeile genau einmal in der
# Ausgabe (REIHENREGELN 2) – gemessen an der Ausgabe, nicht am Quelltext.
pruefung K; GRUEN_K=$PA; [ "$PE" = 0 ] || { echo "ABBRUCH: kern_test.php schon vor der Serie rot"; exit 2; }
pruefung A; GRUEN_A=$PA; [ "$PE" = 0 ] || { echo "ABBRUCH: anmeldung_db_test.sh schon vor der Serie rot"; exit 2; }
Z_ALT="K6 Router ohne die alte Fassung"
Z_NAME="K6 SESSION_NAME ist genau einmal definiert, in backend/kern.php"
Z_DAUER="K6 SESSION_LIFETIME ist genau einmal definiert, in backend/kern.php"
Z_ORT="K6 keine Datei unter backend/ setzt session.save_path"
Z_K4_ORT="K4 Speicherort: die Beilage setzt ihn mit ini_set (1×), das Ergebnis nicht"
Z_K4_BED="K4 Speicherort in einer Bedingung (nicht entfernbar)"
Z_K4_WERTE="K4 Sitzungswerte: SESSION_NAME und SESSION_LIFETIME"
Z_K4_PRUEF="K4 pruefen: definiert konfiguration.php SESSION_NAME"
Z_S1="S1 Set-Cookie: proj_session mit secure, HttpOnly, SameSite=Lax"
Z_S2="S2 Lehrkraft ohne lokalen Eintrag, erste Anfrage nach der Anmeldung"
Z_S3="S3 Rücksetzung über den Router"
Z_S5="S5 Ausliefern meldet niemanden ab"
for z in "$Z_ALT" "$Z_NAME" "$Z_DAUER" "$Z_ORT" "$Z_K4_ORT" "$Z_K4_BED" "$Z_K4_WERTE" "$Z_K4_PRUEF"; do
  n=$(printf '%s\n' "$GRUEN_K" | grep -cF "✓ $z" || true)
  [ "$n" = 1 ] || { echo "ABBRUCH: „$z“ steht $n-mal in der grünen Ausgabe von kern_test.php, erwartet einmal"; exit 2; }
done
for z in "$Z_S1" "$Z_S2" "$Z_S3" "$Z_S5"; do
  n=$(printf '%s\n' "$GRUEN_A" | grep -cF "✓ $z" || true)
  [ "$n" = 1 ] || { echo "ABBRUCH: „$z“ steht $n-mal in der grünen Ausgabe von anmeldung_db_test.sh, erwartet einmal"; exit 2; }
done

RT=backend/router.php
V=backend/konfiguration.example.php
K=backend/kern.php
AB=bin/konfiguration-ableiten.php
BR=backend/auth/Anmeldebremse.php
NACH_KOPF='s/(\n \*\/\n\n)(\$uri  = )/$1'
mut M1  K $RT "${NACH_KOPF}\\\$_SERVER[\\x27HTTPS\\x27] = \\x27on\\x27;\\n\$2/" "$Z_ALT"
mut M2  K $RT "${NACH_KOPF}session_name(\\x27proj_session\\x27);\\n\$2/" "$Z_ALT"
mut M3  K $V 's/(define\(\x27SCHULE_ID\x27, 1\);\n)/$1define(\x27SESSION_NAME\x27, \x27proj_session\x27);\n/' "$Z_NAME"
mut M4  K $V 's/(ini_set\(\x27display_errors\x27, 0\);\n)/ini_set(\x27session.save_path\x27, \x27\/home\/hornse\/tmp\/sessions\x27);\n$1/' "$Z_ORT"
mut M5  K $K 's/const SESSION_LIFETIME = 8 \* 3600;\n//' "$Z_DAUER"
mut M6  K $AB 's/if \(\$tiefe\[\$a\[\x27i\x27\]\] !== 0 \|\| !anweisungsbeginn\(\$t, \$a\[\x27i\x27\]\)\) continue;/continue;/' "$Z_K4_ORT"
mut M7  K $AB 's/    if \(\$rest !== \[\]\) halt\(/    if (false) halt(/' "$Z_K4_BED"
mut M8  K $AB 's/const SITZUNG = \[\x27SESSION_LIFETIME\x27, \x27SESSION_NAME\x27\];/const SITZUNG = [\x27SESSION_LIFETIME\x27];/' "$Z_K4_WERTE"
mut M9  K $AB 's/if \(in_array\(\$d, \$dekl, true\) && \$j >= 0/if (\$j >= 0/' "$Z_K4_ORT"
mut M10 K $AB 's/    if \(\$sitz !== \[\]\) halt\(/    if (false) halt(/' "$Z_K4_PRUEF"
mut D1  A $K 's/if \(!isset\(\$_SESSION\[\x27benutzer_id\x27\]\) \|\| \$_SESSION\[\x27benutzer_id\x27\] === null\)/if (empty(\$_SESSION[\x27benutzer_id\x27]))/' "$Z_S2"
mut D2  A $K "s/\\x27secure\\x27   => true,/\\x27secure\\x27   => false,/" "$Z_S1"
mut D3  A $K "s/\\x27samesite\\x27 => \\x27Lax\\x27,/\\x27samesite\\x27 => \\x27Strict\\x27,/" "$Z_S1"
mut D4  A $K "s/\\x27httponly\\x27 => true,/\\x27httponly\\x27 => false,/" "$Z_S1"
mut D5  A $K "s/const SESSION_NAME     = \\x27proj_session\\x27;/const SESSION_NAME     = \\x27proj_sitzung\\x27;/" "$Z_S5"
mut D6  A $K 's/const SESSION_LIFETIME = 8 \* 3600;/const SESSION_LIFETIME = 9 * 3600;/' "$Z_S1"
mut D7  A $K 's/    session_name\(SESSION_NAME\);\n//' "$Z_S1"
mut D8  A $BR 's/\(int\)\$z\[\x27id\x27\] <= \$letzterErfolg\) continue;/(int)\$z[\x27id\x27] <= 0) continue;/' "$Z_S3"

# E1 – Einbindung: Anmeldeprüfung rot → Suite rot, an der erwarteten Zeile.
GELAUFEN=$((GELAUFEN + 1))
if einbauen E1 "$R/$K" 's/if \(!isset\(\$_SESSION\[\x27benutzer_id\x27\]\) \|\| \$_SESSION\[\x27benutzer_id\x27\] === null\)/if (empty(\$_SESSION[\x27benutzer_id\x27]))/'; then
  if (cd "$R" && ./tests-projektstunden.sh > /dev/null 2>&1); then
    echo "E1: NICHT ANGESCHLAGEN – tests-projektstunden.sh übersieht die rote Anmeldeprüfung"; FEHLT=$((FEHLT + 1))
  elif grep -qF "✗ Anmeldung (DB): $Z_S2" "$R/logs/pruefung-letzter.txt"; then
    echo "E1: angeschlagen (tests-projektstunden.sh rot, an der erwarteten Zeile)"
  else
    echo "E1: NICHT AN DER ERWARTETEN ZEILE"; FEHLT=$((FEHLT + 1))
  fi
else
  FEHLT=$((FEHLT + 1))
fi
ruecknahme E1 "$R/$K"

# H1/H2 – harmlos: die alte Fassung als Kommentar und als Zeichenkette darf K6
# nicht rot machen (REIHENREGELN 2: Kommentar und Zeichenkette sind kein Code).
harmlos() {       # NAME DATEI AUSDRUCK
  GELAUFEN=$((GELAUFEN + 1))
  if einbauen "$1" "$R/$2" "$3"; then
    if php "$R/tests/kern_test.php" > /dev/null 2>&1; then echo "$1: richtig nicht angeschlagen (grün)"
    else echo "$1: FALSCH ANGESCHLAGEN – die Prüfung liest keinen Code"; FEHLT=$((FEHLT + 1)); fi
  else
    FEHLT=$((FEHLT + 1))
  fi
  ruecknahme "$1" "$R/$2"
}
harmlos H1 $RT "${NACH_KOPF}\\/\\/ früher: \\\$_SERVER[\\x27HTTPS\\x27] = \\x27on\\x27; session_name(\\x27proj_session\\x27);\\n\$2/"
harmlos H2 $RT "${NACH_KOPF}\\\$frueher = \\x27session_name(\\x27 . \"\\x27proj_session\\x27);\";\\n\$2/"

echo ""
[ "$GELAUFEN" -ge 21 ] || { echo "FEHLER: nur $GELAUFEN Mutationen gelaufen, erwartet 21"; exit 1; }
if [ "$FEHLT" -eq 0 ]; then echo "ALLE $GELAUFEN MUTATIONEN BELEGT"; exit 0; fi
echo "$FEHLT VON $GELAUFEN MUTATION(EN) OHNE BELEG"; exit 1
