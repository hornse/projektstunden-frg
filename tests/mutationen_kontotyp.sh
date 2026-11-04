#!/bin/bash
# ============================================================
# tests/mutationen_kontotyp.sh – prüft die Prüfungen des Kontotyp-Filters
#
# Baut nacheinander bewusste Fehler in Filter (A), Wächter (B), Liste und
# Frontend ein und belegt je Fehler, dass tests/kontotyp_test.php (K) bzw.
# tests/kontotyp_db_test.sh (D) rot wird – an der erwarteten Zeile. Dazu:
#   E1  Ist K rot, muss auch tests-projektstunden.sh rot sein.
#   E2  Fehlt mariadbd, endet tests-projektstunden.sh mit 3, sichtbar.
#   E3  deploy.sh hält bei Exit 3 an (in einem Klon ohne Gegenstellen).
#   H1  Eine harmlose Änderung (ein Kommentar) darf NICHT anschlagen.
#
# Vor der Serie: K und D laufen unverändert grün, und jede erwartete Zeile
# steht in deren Ausgabe GENAU EINMAL (REIHENREGELN 2). Je Mutation:
# Suchmuster genau einmal → Sicherung → Eingriff → Prüfsumme anders, php -l
# heil → Suite → Rücknahme aus der Sicherung (nie aus dem Index) →
# Prüfsumme gleich vorher. Am Ende: git diff über die Dateien leer.
#
# Wird nicht von tests-projektstunden.sh aufgerufen – sie verändert
# vorübergehend den Code. Aufruf im Projektordner:
#   ./tests/mutationen_kontotyp.sh
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
  rm -rf "${SICH:?}"
}
trap zuruecknehmen EXIT

I=backend/api/index.php
K=backend/api/kontotyp.php
A=frontend/app.js
DATEIEN="$I $K $A"
for d in $DATEIEN; do cp "$R/$d" "$SICH/soll-$(basename "$d")"; done

suite() { # K | D | KD → Ausgabe, Exit-Code in SUITE_EXIT
  local aus="" e=0 x
  case "$1" in *K*) aus=$(php "$R/tests/kontotyp_test.php" 2>/dev/null); x=$?; [ $x -ne 0 ] && e=$x ;; esac
  case "$1" in *D*) aus="$aus
$("$R/tests/kontotyp_db_test.sh" 2>/dev/null)"; x=$?; [ $x -ne 0 ] && e=$x ;; esac
  printf '%s\n' "$aus"; return $e
}

# ---- Vorprüfung --------------------------------------------------------
ERWARTET=(
  "Schüler und ohne typ: /api/schueler –"
  "Schüler und ohne typ: /api/einstellungen –"
  "Lehrkraft: /api/schueler –"
  "Ohne Cookie: /api/einstellungen/logo"
  "Erlaubnisliste im Code gleich der Erwartung"
  "Schüleransicht (app.js, index.html) ruft genau"
  "Verteiler ruft kontotyp_gefiltert()"
  "Wächter: jeder der"
  "Sätze von Filter, Wächter"
  "Schüler 101: GET /api/schueler → 403 Filter"
  "Schüler 57 (Nummer wie Lehrkraft 57): GET /api/projekte/71 →"
  "Stufe B allein (ohne Filter): Schüler 57"
  "Stufe A allein (ohne Wächter): Schüler 57"
)
SAUBER=$(suite KD) || { echo "ABBRUCH: K oder D schon vor der Serie rot"; exit 2; }
for t in "${ERWARTET[@]}"; do
  n=$(printf '%s\n' "$SAUBER" | grep -cF "  ✓ $t" || true)
  [ "$n" = 1 ] || { echo "ABBRUCH: Vorprüfung – „$t“ steht ${n}-mal in der grünen Ausgabe, erwartet genau einmal"; exit 2; }
done
echo "Vorprüfung: ${#ERWARTET[@]} erwartete Zeilen je genau einmal in der grünen Ausgabe von K und D"

# In der Hauptschale aufrufen, nie in $(…).
einbauen() {      # NAME DATEI SUCHMUSTER(perl) AUSDRUCK → 0 wenn angekommen und heil
  local n
  n=$(perl -0777 -ne "\$n = () = /$3/g; print \$n" "$2")
  if [ "$n" != "1" ]; then echo "$1: VORPRÜFUNG – Suchmuster kommt ${n}-mal vor, erwartet genau einmal"; return 1; fi
  VORHER=$(summe "$2"); cp "$2" "$SICH/sicherung"; OFFEN="$2"
  perl -0777 -i -pe "$4" "$2"
  if [ "$(summe "$2")" = "$VORHER" ]; then echo "$1: MUTATION NICHT ANGEKOMMEN"; return 1; fi
  case "$2" in *.php) php -l "$2" > /dev/null 2>&1 || { echo "$1: MUTATION KAPUTT – Syntaxfehler"; return 1; } ;; esac
  case "$2" in *.js) node --check "$2" > /dev/null 2>&1 || { echo "$1: MUTATION KAPUTT – Syntaxfehler"; return 1; } ;; esac
}
ruecknahme() {    # NAME DATEI
  [ -n "$OFFEN" ] || return 0
  cp "$SICH/sicherung" "$2"; OFFEN=""
  [ "$(summe "$2")" = "$VORHER" ] || { echo "ABBRUCH: Rücknahme von $1 misslungen"; exit 2; }
}

# mut NAME SUITE DATEI SUCHMUSTER AUSDRUCK ERWARTETE-ROTE-ZEILE [ZWEITE]
mut() {
  local name=$1 s=$2 datei="$R/$3" aus e t1 t2
  GELAUFEN=$((GELAUFEN + 1))
  if ! einbauen "$name" "$datei" "$4" "$5"; then
    FEHLT=$((FEHLT + 1))
  else
    aus=$(suite "$s"); e=$?
    t1=$(printf '%s\n' "$aus" | grep -cF "✗ $6" || true)
    t2=1; [ -n "${7:-}" ] && t2=$(printf '%s\n' "$aus" | grep -cF "✗ $7" || true)
    if [ "$e" -ne 0 ] && [ "$t1" -ge 1 ] && [ "$t2" -ge 1 ]; then
      echo "$name: angeschlagen („$6“${7:+, „$7“}; rot gesamt: $(printf '%s\n' "$aus" | grep -c '✗'))"
    else
      echo "$name: NICHT ANGESCHLAGEN (exit=$e, „$6“: $t1${7:+, „$7“: $t2})"; FEHLT=$((FEHLT + 1))
    fi
  fi
  ruecknahme "$name" "$datei"
}

FILTER_IF='if \(kontotyp_gefiltert\(\) && !schueler_route_erlaubt\(\$method, \$route, \$sub\)\) \{'

# M1 – der Filteraufruf entfernt (der ganze Block)
mut M1 K $I '(?s)\/\/ ----- Filter nach Kontotyp \(Z1\) -----\n.*?\n\}\n' \
  's/(?s)\/\/ ----- Filter nach Kontotyp \(Z1\) -----\n.*?\n\}\n//' \
  "Schüler und ohne typ: /api/schueler –" "Verteiler ruft kontotyp_gefiltert()"
# M2 – dieselbe Entfernung, gemessen MIT Datenbank: Der Wächter fängt, aber mit
#      seinem Satz – D verlangt den des Filters, und Stufe A allein fehlt.
mut M2 D $I '(?s)\/\/ ----- Filter nach Kontotyp \(Z1\) -----\n.*?\n\}\n' \
  's/(?s)\/\/ ----- Filter nach Kontotyp \(Z1\) -----\n.*?\n\}\n//' \
  "Schüler 101: GET /api/schueler → 403 Filter" "Stufe A allein (ohne Wächter): Schüler 57"
# M3 – eine Route auf die Liste, die nicht hingehört
mut M3 K $K '\x27auth\x27 +=> true,\n' \
  's/(\x27auth\x27 +=> true,\n)/$1        \x27schueler\x27 => true,\n/' \
  "Erlaubnisliste im Code gleich der Erwartung" "Schüler und ohne typ: /api/schueler –"
# M4 – der Filter entwertet, nicht entfernt (greift nie): Die Quelltextprüfung
#      K8 bleibt grün – nur die Wirkung darf anschlagen.
mut M4 K $I 'if \(kontotyp_gefiltert\(\) &&' \
  's/if \(kontotyp_gefiltert\(\) &&/if (false \&\& kontotyp_gefiltert() \&\&/' \
  "Schüler und ohne typ: /api/schueler –"
# M5 – der Filter greift immer (if (true)): auch Lehrkräfte und Anonyme
mut M5 K $I 'if \(kontotyp_gefiltert\(\) &&' \
  's/if \(kontotyp_gefiltert\(\) &&/if (true || kontotyp_gefiltert() \&\&/' \
  "Lehrkraft: /api/schueler –" "Ohne Cookie: /api/einstellungen/logo"
# M6 – nur typ 'schueler' gefiltert statt alles außer 'benutzer'
mut M6 K $K 'return \(\$_SESSION\[\x27typ\x27\] \?\? null\) !== \x27benutzer\x27;' \
  's/return \(\$_SESSION\[\x27typ\x27\] \?\? null\) !== \x27benutzer\x27;/return (\$_SESSION[\x27typ\x27] ?? null) === \x27schueler\x27;/' \
  "Schüler und ohne typ: /api/schueler –"
# M7 – Sitzung auch ohne Cookie gestartet
mut M7 K $K 'if \(!isset\(\$_COOKIE\[SESSION_NAME\]\)\) return false;\n' \
  's/    if \(!isset\(\$_COOKIE\[SESSION_NAME\]\)\) return false;\n//' \
  "Ohne Cookie: /api/einstellungen/logo"
# M8 – Code gelöscht, Kommentar bleibt: K8 darf ihn nicht zählen
mut M8 K $I "$FILTER_IF" \
  's/if \(kontotyp_gefiltert\(\) && !schueler_route_erlaubt\(\$method, \$route, \$sub\)\) \{/if (false \/* kontotyp_gefiltert() \&\& !schueler_route_erlaubt(\$method, \$route, \$sub) *\/) {/' \
  "Verteiler ruft kontotyp_gefiltert()" "Schüler und ohne typ: /api/schueler –"
# M9 – das Logo nicht mehr auf den Unterpfad beschränkt
mut M9 K $K '\$method === \x27GET\x27 && \$sub === \x27logo\x27' \
  's/\$method === \x27GET\x27 && \$sub === \x27logo\x27/\$method === \x27GET\x27/' \
  "Erlaubnisliste im Code gleich der Erwartung" "Schüler und ohne typ: /api/einstellungen –"
# M10 – der Wächter in einem Handler zurück auf require_auth()
mut M10 K $I 'function handle_lehrer\(string \$method\): void \{\n    \$user = require_lehrkraft\(\);' \
  's/(function handle_lehrer\(string \$method\): void \{\n    \$user = )require_lehrkraft\(\);/$1require_auth();/' \
  "Wächter: jeder der"
# M11 – der Wächter entwertet: K9 (Quelltext) bleibt grün, D7 (Wirkung) nicht
mut M11 D $K 'if \(\(\$_SESSION\[\x27typ\x27\] \?\? null\) !== \x27benutzer\x27\) \{' \
  's/if \(\(\$_SESSION\[\x27typ\x27\] \?\? null\) !== \x27benutzer\x27\) \{/if (false) {/' \
  "Stufe B allein (ohne Filter): Schüler 57"
# M12 – Satz des Wächters gleich dem des Filters
mut M12 K $K 'KONTOTYP_SATZ_WAECHTER = \x27Nur für Konten von Lehrkräften.\x27;' \
  's/KONTOTYP_SATZ_WAECHTER = \x27Nur für Konten von Lehrkräften.\x27;/KONTOTYP_SATZ_WAECHTER = \x27Für Schülerkonten nicht freigegeben.\x27;/' \
  "Sätze von Filter, Wächter"
# M13 – die Schüleransicht ruft eine Route außerhalb der Liste
mut M13 K $A 'async function ladeSchuelerPortal\(schueler_id\) \{\n' \
  's/(async function ladeSchuelerPortal\(schueler_id\) \{\n)/$1  await GET(\x27lehrer\x27);\n/' \
  "Schüleransicht (app.js, index.html) ruft genau"

# E1 – die Einbindung: Ist K rot, muss tests-projektstunden.sh rot sein.
GELAUFEN=$((GELAUFEN + 1))
if einbauen E1 "$R/$K" '\x27auth\x27 +=> true,\n' 's/(\x27auth\x27 +=> true,\n)/$1        \x27schueler\x27 => true,\n/'; then
  if (cd "$R" && ./tests-projektstunden.sh > /dev/null 2>&1); then
    echo "E1: NICHT ANGESCHLAGEN – tests-projektstunden.sh übersieht die rote Suite"; FEHLT=$((FEHLT + 1))
  elif grep -qF "✗ Kontotyp: Erlaubnisliste im Code gleich der Erwartung" "$R/logs/pruefung-letzter.txt"; then
    echo "E1: angeschlagen (tests-projektstunden.sh rot, an der erwarteten Zeile)"
  else
    echo "E1: NICHT AN DER ERWARTETEN ZEILE"; FEHLT=$((FEHLT + 1))
  fi
else
  FEHLT=$((FEHLT + 1))
fi
ruecknahme E1 "$R/$K"

# E2 – mariadbd fehlt: tests-projektstunden.sh endet mit 3, sichtbar.
GELAUFEN=$((GELAUFEN + 1))
(cd "$R" && MARIADBD=/gibt/es/nicht ./tests-projektstunden.sh > /dev/null 2>&1); e=$?
if [ "$e" = 3 ] && grep -qF "ÜBERSPRUNGEN: mariadbd nicht gefunden" "$R/logs/pruefung-letzter.txt" \
   && grep -qF "PFLICHTSCHRITT(E) ÜBERSPRUNGEN" "$R/logs/pruefung-letzter.txt" \
   && ! grep -qF "✓ Kontotyp (DB):" "$R/logs/pruefung-letzter.txt"; then
  echo "E2: angeschlagen (Exit 3, ÜBERSPRUNGEN sichtbar, keine DB-Zeile gezählt)"
else
  echo "E2: NICHT ANGESCHLAGEN (exit=$e)"; FEHLT=$((FEHLT + 1))
fi

# E3 – deploy.sh hält bei Exit 3 an. In einem Klon OHNE Gegenstellen: Ein
#      Push ist dort unmöglich, auch wenn der Halt versagte.
GELAUFEN=$((GELAUFEN + 1))
KL="$SICH/klon"
git clone -q "$R" "$KL" && for g in $(git -C "$KL" remote); do git -C "$KL" remote remove "$g"; done
# backend/config.php ist nicht versioniert, die Suite verlangt sie
# (Konfigurationsprüfung). Im Klon aus der Vorlage – ohne Zugangsdaten.
# Ohne sie war die Suite im Klon aus diesem Grund rot, und deploy.sh hielt
# mit „Tests rot“ an statt am Übersprung (erster Lauf der Serie, 04.11.2026).
[ -d "$KL" ] && cp "$KL/backend/config.example.php" "$KL/backend/config.php"
if [ -d "$KL" ] && [ -z "$(git -C "$KL" remote)" ]; then
  KOPF=$(git -C "$KL" rev-parse HEAD)
  (cd "$KL" && MARIADBD=/gibt/es/nicht ./deploy.sh "Probe E3" > "$SICH/e3.txt" 2>&1); e=$?
  if [ "$e" -ne 0 ] && grep -qF "Pflichtpruefung uebersprungen (Kontotyp mit Datenbank) - kein Deploy." "$SICH/e3.txt" \
     && [ "$(git -C "$KL" rev-parse HEAD)" = "$KOPF" ] && [ -z "$(git -C "$KL" status --porcelain --untracked-files=no)" ]; then
    echo "E3: angeschlagen (deploy.sh hält mit eigenem Satz an, kein Commit, index.html unverändert)"
  else
    echo "E3: NICHT ANGESCHLAGEN (exit=$e; letzte Zeile: $(tail -1 "$SICH/e3.txt"))"; FEHLT=$((FEHLT + 1))
  fi
else
  echo "E3: Klon ohne Gegenstellen nicht herstellbar"; FEHLT=$((FEHLT + 1))
fi

# H1 – harmlos: ein Kommentar ändert sich. K und D müssen grün bleiben.
GELAUFEN=$((GELAUFEN + 1))
if einbauen H1 "$R/$K" ' \* Darf eine Sitzung, die keine Lehrkraft ist,' 's/ \* Darf eine Sitzung, die keine Lehrkraft ist,/ * Darf eine Sitzung, die keine Lehrkraft ist (harmlos geändert),/'; then
  if suite KD > /dev/null; then
    echo "H1: richtig nicht angeschlagen (harmlose Änderung, K und D grün)"
  else
    echo "H1: FALSCH ANGESCHLAGEN"; FEHLT=$((FEHLT + 1))
  fi
else
  FEHLT=$((FEHLT + 1))
fi
ruecknahme H1 "$R/$K"

# Rücknahme der ganzen Serie: jede Datei gleich ihrem Stand davor, git diff leer.
for d in $DATEIEN; do
  cmp -s "$R/$d" "$SICH/soll-$(basename "$d")" || { echo "ABBRUCH: $d weicht nach der Serie vom Stand davor ab"; exit 2; }
done
if git -C "$R" diff --quiet -- $DATEIEN; then
  echo "Rücknahme belegt: $DATEIEN gleich dem Stand vor der Serie, git diff leer"
else
  echo "Rücknahme belegt gegen die Sicherung; git diff NICHT leer (Stand vor der Serie war schon geändert)"
fi

echo ""
[ "$GELAUFEN" -ge 17 ] || { echo "FEHLER: nur $GELAUFEN Mutationen gelaufen, erwartet 17"; exit 1; }
if [ "$FEHLT" -eq 0 ]; then echo "ALLE $GELAUFEN MUTATIONEN BELEGT"; exit 0; fi
echo "$FEHLT VON $GELAUFEN MUTATION(EN) OHNE BELEG"; exit 1
