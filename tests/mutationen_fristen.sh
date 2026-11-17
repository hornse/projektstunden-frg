#!/bin/bash
# ============================================================
# tests/mutationen_fristen.sh – Gegenproben zu tests/fristen_db_test.sh
#
# Auftrag A, Paket 3 (E68). Jede Mutation beschädigt den geprüften Code an
# einer Stelle; die erwartete Zeile muss rot werden. Die Prüfung läuft
# ausgeführt (MariaDB), nicht am Quelltext – außer F7.
#
#   F1  audit() schreibt wieder ip_adresse (Auftrag, Paket 3 b): nach sql/24
#       geht der Eintrag still verloren, die Zeilenzahl steigt nicht
#   F2  audit_grenze: Schuljahr ab September statt August (>= 8 → >= 9)
#   F3  audit_grenze: vorletzter → letzter Schuljahresbeginn
#   F4  audit: Grenze schließt den 01.08. mit ein (< → <=)
#   F5  audit: kein Aufräumen
#   F6  audit: erstellt_am aus der Datenbank (DEFAULT), nicht aus der PHP-Uhr
#   F7  audit: catch (Throwable) statt catch (Exception)
#   F8  audit: Fehler ohne Eintrag im Protokoll
#   F9  Verlauf: Grenze über 30 × 86 400 s statt modify('-30 days')
#   F10 Verlauf: Grenze schließt den Eintrag genau darauf mit ein (< → <=)
#   F11 Verlauf: kein Aufräumen
#   F12 sql/24: ALTER ohne IF EXISTS – zweites Einspielen scheitert
#   F13 sql/24: webuntis_login_log bleibt
#   E1  Ist die Fristenprüfung rot, muss tests-projektstunden.sh rot sein
#   H1  Harmlos: ein Kommentar „catch (Throwable $e)“ in audit() – grün
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

# mut NAME DATEI PERL-AUSDRUCK ERWARTETE-ZEILE
mut() {
  local name=$1 datei="$R/$2" ausdruck=$3 erwartet=$4 aus e treffer
  GELAUFEN=$((GELAUFEN + 1))
  if ! einbauen "$name" "$datei" "$ausdruck"; then
    FEHLT=$((FEHLT + 1))
  else
    aus=$("$R/tests/fristen_db_test.sh" 2>/dev/null); e=$?
    treffer=$(printf '%s\n' "$aus" | grep -cF "✗ $erwartet" || true)
    if [ "$e" -ne 0 ] && [ "$treffer" -ge 1 ]; then echo "$name: angeschlagen („$erwartet“)"
    else echo "$name: NICHT ANGESCHLAGEN (exit=$e, „$erwartet“ rot: $treffer)"; FEHLT=$((FEHLT + 1)); fi
  fi
  ruecknahme "$name" "$datei"
}

# Vorprüfung: unverändert grün, und jede erwartete Zeile steht genau einmal
# in der Ausgabe (REIHENREGELN 2) – gemessen an der Ausgabe, nicht am Quelltext.
GRUEN_AUS=$("$R/tests/fristen_db_test.sh" 2>/dev/null) || { echo "ABBRUCH: Fristenprüfung schon vor der Serie rot"; exit 2; }
ERWARTET=(
  "audit nach sql/24 (ohne Spalte ip_adresse): Zeilenzahl steigt um eins"
  "audit_grenze: Stichtag 01.08., erste Sekunde des neuen Schuljahrs"
  "audit_grenze: Stichtag im Januar"
  "audit, Stichtag 2031-01-15 10:00:00: Eintrag vom 01.08.2029 bleibt"
  "audit, Stichtag 2031-01-15 10:00:00: Eintrag vom 31.07.2029 gelöscht"
  "audit: erstellt_am kommt aus der PHP-Uhr"
  "audit(), Quelltext: fängt Exception, nicht Throwable"
  "audit ohne Tabelle: Fehlerprotokoll nennt audit_log"
  "Verlauf: Grenze über das Datum, nicht 30 × 86 400 s"
  "Verlauf: Eintrag genau auf der Grenze bleibt"
  "Verlauf: Eintrag eine Sekunde vor der Grenze (30 Tage) gelöscht"
  "sql/24_aufraeumen_nach_abnahme.sql zweimal eingespielt, ohne Fehler"
  "sql/24: Tabelle webuntis_login_log entfernt"
)
for z in "${ERWARTET[@]}"; do
  n=$(printf '%s\n' "$GRUEN_AUS" | grep -cF "✓ $z" || true)
  [ "$n" = 1 ] || { echo "ABBRUCH: „$z“ steht $n-mal in der grünen Ausgabe, erwartet einmal"; exit 2; }
done

K=backend/kern.php
N=backend/auth/anmeldung.php
S24=sql/24_aufraeumen_nach_abnahme.sql
mut F1  $K 's/alt_wert, neu_wert, erstellt_am\)\n             VALUES \(\?, \?, \?, \?, \?, \?, \?\)/alt_wert, neu_wert, erstellt_am, ip_adresse)\n             VALUES (?, ?, ?, ?, ?, ?, ?, NULL)/' \
  "audit nach sql/24 (ohne Spalte ip_adresse): Zeilenzahl steigt um eins"
mut F2  $K 's/format\(\x27n\x27\) >= 8 \?/format(\x27n\x27) >= 9 ?/' \
  "audit_grenze: Stichtag 01.08., erste Sekunde des neuen Schuljahrs"
mut F3  $K 's/setDate\(\$beginn - 1, 8, 1\)/setDate(\$beginn, 8, 1)/' \
  "audit_grenze: Stichtag im Januar"
mut F4  $K 's/DELETE FROM audit_log WHERE erstellt_am < \?/DELETE FROM audit_log WHERE erstellt_am <= ?/' \
  "audit, Stichtag 2031-01-15 10:00:00: Eintrag vom 01.08.2029 bleibt"
mut F5  $K 's/        \$db->prepare\(\x27DELETE FROM audit_log WHERE erstellt_am < \?\x27\)\n           ->execute\(\[audit_grenze\(\$jetzt\)->format\(\x27Y-m-d H:i:s\x27\)\]\);\n//' \
  "audit, Stichtag 2031-01-15 10:00:00: Eintrag vom 31.07.2029 gelöscht"
mut F6  $K 's/alt_wert, neu_wert, erstellt_am\)\n             VALUES \(\?, \?, \?, \?, \?, \?, \?\)/alt_wert, neu_wert)\n             VALUES (?, ?, ?, ?, ?, ?)/; s/            \$jetzt->format\(\x27Y-m-d H:i:s\x27\),\n        \]\);/        ]);/' \
  "audit: erstellt_am kommt aus der PHP-Uhr"
mut F7  $K 's/\} catch \(Exception \$e\) \{\n        error_log\(\x27projektstunden: audit_log/} catch (Throwable \$e) {\n        error_log(\x27projektstunden: audit_log/' \
  "audit(), Quelltext: fängt Exception, nicht Throwable"
mut F8  $K 's/        error_log\(\x27projektstunden: audit_log nicht geschrieben.*?\n.*?\n//s' \
  "audit ohne Tabelle: Fehlerprotokoll nennt audit_log"
mut F9  $N 's/\(new DateTimeImmutable\(\x27@\x27 \. \$jetzt\)\)/(new DateTimeImmutable(\x27@\x27 . (\$jetzt - self::FRIST_VERLAUF_TAGE * 86400)))/; s/->modify\(\x27-\x27 \. self::FRIST_VERLAUF_TAGE \. \x27 days\x27\)//' \
  "Verlauf: Grenze über das Datum, nicht 30 × 86 400 s"
mut F10 $N 's/DELETE FROM anmeldeverlauf WHERE zeitpunkt < \?/DELETE FROM anmeldeverlauf WHERE zeitpunkt <= ?/' \
  "Verlauf: Eintrag genau auf der Grenze bleibt"
mut F11 $N 's/            \$db->prepare\(\x27DELETE FROM anmeldeverlauf WHERE zeitpunkt < \?\x27\)\n               ->execute\(\[\$grenze->format\(\x27Y-m-d H:i:s\x27\)\]\);\n//' \
  "Verlauf: Eintrag eine Sekunde vor der Grenze (30 Tage) gelöscht"
mut F12 $S24 's/DROP COLUMN IF EXISTS ip_adresse/DROP COLUMN ip_adresse/' \
  "sql/24_aufraeumen_nach_abnahme.sql zweimal eingespielt, ohne Fehler"
mut F13 $S24 's/DROP TABLE IF EXISTS webuntis_login_log;\n//' \
  "sql/24: Tabelle webuntis_login_log entfernt"

# E1 – Einbindung: Fristenprüfung rot → Suite rot, an der erwarteten Zeile.
GELAUFEN=$((GELAUFEN + 1))
if einbauen E1 "$R/$K" 's/format\(\x27n\x27\) >= 8 \?/format(\x27n\x27) >= 9 ?/'; then
  if (cd "$R" && ./tests-projektstunden.sh > /dev/null 2>&1); then
    echo "E1: NICHT ANGESCHLAGEN – tests-projektstunden.sh übersieht die rote Fristenprüfung"; FEHLT=$((FEHLT + 1))
  elif grep -qF "✗ Fristen (DB): audit_grenze: Stichtag 01.08." "$R/logs/pruefung-letzter.txt"; then
    echo "E1: angeschlagen (tests-projektstunden.sh rot, an der erwarteten Zeile)"
  else
    echo "E1: NICHT AN DER ERWARTETEN ZEILE"; FEHLT=$((FEHLT + 1))
  fi
else
  FEHLT=$((FEHLT + 1))
fi
ruecknahme E1 "$R/$K"

# H1 – harmlos: der falsche catch als KOMMENTAR darf F7s Prüfung nicht rot machen.
GELAUFEN=$((GELAUFEN + 1))
if einbauen H1 "$R/$K" 's/(    \$jetzt \?\?= new DateTimeImmutable\(\x27now\x27\);\n)/$1    \/\/ früher: } catch (Throwable \$e) {} – schluckte jeden Fehler\n/'; then
  if "$R/tests/fristen_db_test.sh" > /dev/null 2>&1; then echo "H1: richtig nicht angeschlagen (Kommentar, grün)"
  else echo "H1: FALSCH ANGESCHLAGEN – die Prüfung liest einen Kommentar"; FEHLT=$((FEHLT + 1)); fi
else
  FEHLT=$((FEHLT + 1))
fi
ruecknahme H1 "$R/$K"

echo ""
[ "$GELAUFEN" -ge 15 ] || { echo "FEHLER: nur $GELAUFEN Mutationen gelaufen, erwartet 15"; exit 1; }
if [ "$FEHLT" -eq 0 ]; then echo "ALLE $GELAUFEN MUTATIONEN BELEGT"; exit 0; fi
echo "$FEHLT VON $GELAUFEN MUTATION(EN) OHNE BELEG"; exit 1
