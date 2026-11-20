#!/bin/bash
# ============================================================
# tests/mutationen_uebersprungen.sh – Gegenproben zu Paket 6
#
# Auftrag A, Paket 6: Jeder übersprungene Schritt geht durch uebersprungen()
# in tests-projektstunden.sh und wird gezählt. Drei Läufe mit veränderter
# Umgebung (G) und vier Eingriffe in die Suite (U), jeder gegen die ganze
# Suite gefahren:
#
#   G5a  node fehlt nur im kargen Lauf (Verweisverzeichnis)  → „karg:“ rot, an
#        der Zahl der Übersprungenen (innen > 0, normal 0) – G5 aus B0
#   G5b  node fehlt im PATH (normaler Lauf)                  → Schlusszeile nennt
#        3 übersprungen, 3 Zeilen „–“, Exit 0
#   G6   mariadbd fehlt (MARIADBD=/nichtda, ohne kargen Lauf) → 3 Pflichtschritte,
#        3 Zeilen „–“ mit dem Grund aus dem Teilskript, Exit 3
#   U1   alte Form „echo …node nicht vorhanden“ zurück       → Prüfung „an einer Stelle“ rot
#   U2   alte Durchreichung (grep auf die Zeile des Teilskripts) zurück → dieselbe rot
#   U3   uebersprungen() zählt nicht mehr                    → unter G5b: Schlusszeile 0 statt 3
#   U4   Kontotyp (DB) ohne „pflicht“                        → unter G6: 2 Pflicht, 1 übersprungen
#   H1   alte Form als Kommentarzeile                        → grün
#
# In jedem Lauf mit „–“-Zeilen wird zusätzlich an der AUSGABE gezählt: Zeilen
# „  –  “ = übersprungen + Pflicht aus der Schlusszeile. Das sieht auch eine
# Ausgabe, die die Prüfung am Quelltext nicht sieht.
#
# Rücknahme aus einer Sicherungskopie, mit Prüfsumme belegt (REIHENREGELN 3).
# Dauer: rund zwölf Minuten (sechs Läufe mit, drei ohne kargen Lauf).
# SPDX-License-Identifier: GPL-3.0-or-later
# ============================================================
set -u
export LC_ALL=C
R="$(cd "$(dirname "$0")/.." && pwd)"
cd "$R" || exit 1
T=tests-projektstunden.sh
SICH="$(mktemp -d)"
OHNE_NODE="$(mktemp -d)"
OFFEN=""
FEHLT=0
GELAUFEN=0
summe() { shasum "$1" | cut -c1-12; }
zuruecknehmen() {
  if [ -n "$OFFEN" ]; then cp "$SICH/sicherung" "$OFFEN"; echo "Abbruch: offene Mutation in $OFFEN zurückgenommen."; fi
  rm -rf "${SICH:?}" "${OHNE_NODE:?}"
}
trap zuruecknehmen EXIT
SOLL=$(summe "$T")

# Ein PATH ohne node: jedes ausführbare Programm aus dem PATH als Verweis,
# das erste gewinnt, nur node nicht.
IFS=: read -r -a PFADE <<< "$PATH"
for d in "${PFADE[@]}"; do
  [ -d "$d" ] || continue
  for f in "$d"/*; do
    n=$(basename "$f")
    [ "$n" = node ] && continue
    [ -x "$f" ] && [ ! -e "$OHNE_NODE/$n" ] && ln -s "$f" "$OHNE_NODE/$n"
  done
done
PATH_OHNE_NODE="$OHNE_NODE:/usr/bin:/bin:/usr/sbin:/sbin"
if PATH="$PATH_OHNE_NODE" command -v node > /dev/null 2>&1; then
  echo "ABBRUCH: node ist im PATH ohne node noch zu finden"; exit 2
fi
PATH="$PATH_OHNE_NODE" command -v php > /dev/null 2>&1 || { echo "ABBRUCH: php fehlt im PATH ohne node"; exit 2; }

lauf() {          # [ENV …] → Ausgabe in LA, Exit in LE
  LA=$(env "$@" ./"$T" 2>&1); LE=$?
}
schluss() {       # → SG (bestanden) SU (übersprungen) SP (Pflicht) SZ (Zeilen „–“)
  local z
  z=$(printf '%s\n' "$LA" | grep -E '^[0-9]+/[0-9]+ bestanden, ' | tail -1 || true)
  SG=$(printf '%s' "$z" | sed -nE 's#^([0-9]+)/.*#\1#p')
  SU=$(printf '%s' "$z" | sed -nE 's#^.* rot, ([0-9]+) übersprungen.*#\1#p')
  SP=$(printf '%s' "$z" | sed -nE 's#^.*, ([0-9]+) Pflichtschritt.*#\1#p')
  SZ=$(printf '%s\n' "$LA" | grep -c '^  –  ' || true)
}
melde() {         # NAME OK BERICHT
  GELAUFEN=$((GELAUFEN + 1))
  if [ "$2" = 1 ]; then echo "$1: $3"; else echo "$1: NICHT WIE ERWARTET – $3"; FEHLT=$((FEHLT + 1)); fi
}
einbauen() {      # NAME AUSDRUCK → 0 wenn angekommen und heil
  VORHER=$(summe "$T"); cp "$T" "$SICH/sicherung"; OFFEN="$T"
  perl -0777 -i -pe "$2" "$T"
  if [ "$(summe "$T")" = "$VORHER" ]; then echo "$1: MUTATION NICHT ANGEKOMMEN – Suchmuster prüfen"; return 1; fi
  bash -n "$T" 2> /dev/null || { echo "$1: MUTATION KAPUTT – Syntaxfehler nach dem Einbau"; return 1; }
}
ruecknahme() {
  cp "$SICH/sicherung" "$T"; OFFEN=""
  [ "$(summe "$T")" = "$SOLL" ] || { echo "ABBRUCH: Rücknahme von $1 misslungen"; exit 2; }
}
Z_STELLE="übersprungen: jede Zeile „–  ÜBERSPRUNGEN“ kommt aus uebersprungen()"

# Vorprüfung: unverändert grün, 0 übersprungen, die geprüfte Zeile genau einmal.
lauf; schluss
n=$(printf '%s\n' "$LA" | grep -cF "✓ $Z_STELLE" || true)
if [ "$LE" != 0 ] || [ "$SU" != 0 ] || [ "$SP" != 0 ] || [ "$n" != 1 ]; then
  echo "ABBRUCH: Vorprüfung – Exit $LE, $SU übersprungen, $SP Pflicht, Zeile „$Z_STELLE“ ${n}-mal"; exit 2
fi
echo "Vorprüfung: $SG bestanden, 0 übersprungen, die Zeile einmal"

# ---- G5a: node fehlt nur im kargen Lauf ---------------------------------
if einbauen G5a 's/for W in php node mariadbd mariadb mariadb-install-db; do/for W in php mariadbd mariadb mariadb-install-db; do/'; then
  lauf
  kz=$(printf '%s\n' "$LA" | grep -E '^  ✗ karg: [0-9]+ bestanden, ' || true)
  ku=$(printf '%s' "$kz" | sed -nE 's#^.* rot, ([0-9]+) übersprungen, .*– normal [0-9]+, [0-9]+, ([0-9]+), .*#\1 \2#p')
  set -- $ku
  if [ "$LE" != 0 ] && [ "${1:-0}" -gt 0 ] 2>/dev/null && [ "${2:-x}" = 0 ]; then
    melde G5a 1 "„karg:“ rot an den Übersprungenen – innen $1, normal $2"
  else
    melde G5a 0 "Exit $LE, Zeile „$kz“"
  fi
else FEHLT=$((FEHLT + 1)); fi
ruecknahme G5a

# ---- G5b: node fehlt im PATH ---------------------------------------------
lauf PATH="$PATH_OHNE_NODE"; schluss
if [ "$LE" = 0 ] && [ "$SU" = 3 ] && [ "$SP" = 0 ] && [ "$SZ" = 3 ]; then
  melde G5b 1 "Schlusszeile nennt $SU übersprungen, $SZ Zeilen „–“, $SG bestanden, Exit 0"
else
  melde G5b 0 "Exit $LE, $SU übersprungen, $SP Pflicht, $SZ Zeilen „–“"
fi

# ---- G6: mariadbd fehlt ----------------------------------------------------
lauf PRUEF_KARG=1 MARIADBD=/nichtda; schluss
G6G=$(printf '%s\n' "$LA" | grep -c '^  –  ÜBERSPRUNGEN: mariadbd nicht gefunden – ' || true)
if [ "$LE" = 3 ] && [ "$SU" = 0 ] && [ "$SP" = 3 ] && [ "$SZ" = 3 ] && [ "$G6G" = 3 ]; then
  melde G6 1 "Exit 3, $SP Pflichtschritte, $SZ Zeilen „–“, alle mit dem Grund des Teilskripts"
else
  melde G6 0 "Exit $LE, $SU übersprungen, $SP Pflicht, $SZ Zeilen „–“, $G6G mit Grund"
fi

# ---- U1/U2: alte Formen zurück → Prüfung am Quelltext rot -----------------
for u in U1 U2; do
  case $u in
    U1) A='s/uebersprungen "node nicht vorhanden – app.js nicht auf Syntax geprüft"/echo "  –  node nicht vorhanden"/' ;;
    U2) A='s/uebersprungen "\$\(ueb_grund "\$KTDB_AUS" "Kontotyp mit Datenbank"\)" pflicht/printf \x27%s\\n\x27 "\$KTDB_AUS" | grep \x27^  –  \x27 || echo "  –  ÜBERSPRUNGEN: Kontotyp mit Datenbank"\n    PFLICHT_UEBERSPRUNGEN=\$((PFLICHT_UEBERSPRUNGEN + 1))/' ;;
  esac
  if einbauen $u "$A"; then
    lauf PRUEF_KARG=1
    r=$(printf '%s\n' "$LA" | grep -E '^  ✗ übersprungen: Zeilen mit „–“ außerhalb' | head -1 || true)
    if [ "$LE" != 0 ] && [ -n "$r" ]; then melde $u 1 "angeschlagen (${r#  ✗ })"
    else melde $u 0 "Exit $LE, keine rote Zeile „an einer Stelle“"; fi
  else FEHLT=$((FEHLT + 1)); fi
  ruecknahme $u
done

# ---- U3: uebersprungen() zählt nicht → unter G5b sichtbar ------------------
if einbauen U3 's/(    else\n        )UEBERSPRUNGEN=\$\(\(UEBERSPRUNGEN \+ 1\)\)/$1:/'; then
  lauf PRUEF_KARG=1 PATH="$PATH_OHNE_NODE"; schluss
  if [ "$SU" != 3 ] && [ "$SZ" = 3 ]; then melde U3 1 "angeschlagen: Schlusszeile $SU übersprungen bei $SZ Zeilen „–“"
  else melde U3 0 "Schlusszeile $SU übersprungen, $SZ Zeilen „–“"; fi
else FEHLT=$((FEHLT + 1)); fi
ruecknahme U3

# ---- U4: Kontotyp (DB) ohne „pflicht“ → unter G6 sichtbar ------------------
if einbauen U4 's/(uebersprungen "\$\(ueb_grund "\$KTDB_AUS" "Kontotyp mit Datenbank"\)") pflicht/$1/'; then
  lauf PRUEF_KARG=1 MARIADBD=/nichtda; schluss
  if [ "$SP" = 2 ] && [ "$SU" = 1 ]; then melde U4 1 "angeschlagen: $SP Pflicht, $SU übersprungen statt 3 und 0"
  else melde U4 0 "Exit $LE, $SP Pflicht, $SU übersprungen"; fi
else FEHLT=$((FEHLT + 1)); fi
ruecknahme U4

# ---- H1: alte Form als Kommentarzeile → grün -------------------------------
if einbauen H1 's/(\nif command -v node > \/dev\/null 2>&1; then\n    node --check)/\n#   früher: echo "  –  node nicht vorhanden"$1/'; then
  lauf PRUEF_KARG=1
  n=$(printf '%s\n' "$LA" | grep -cF "✓ $Z_STELLE" || true)
  if [ "$LE" = 0 ] && [ "$n" = 1 ]; then melde H1 1 "richtig nicht angeschlagen (grün)"
  else melde H1 0 "FALSCH ANGESCHLAGEN (Exit $LE)"; fi
else FEHLT=$((FEHLT + 1)); fi
ruecknahme H1

echo
if [ "$FEHLT" = 0 ]; then echo "ALLE $GELAUFEN GEGENPROBEN BELEGT"; else echo "$FEHLT VON $GELAUFEN NICHT BELEGT"; fi
echo "$T: $(summe "$T") (Sollstand $SOLL)"
[ "$FEHLT" = 0 ]
