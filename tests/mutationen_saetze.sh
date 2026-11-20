#!/bin/bash
# ============================================================
# tests/mutationen_saetze.sh – Gegenproben zu Paket 5 (Wartesatz)
#
# Auftrag A, Paket 5 (E68, FALLSTRICKE 8). Jede Mutation beschädigt den
# geprüften Code an einer Stelle; die erwartete Zeile muss rot werden.
#   B = tests/anmeldebremse_test.php  (Bremse mit gestellter Uhr, handle_auth ausgeführt)
#   A = tests/anmeldung_db_test.sh    (ausgeführt: php -S, MariaDB, WebUntis-Ersatz)
#   N = tests/anmeldung_test.js       (Hilfe in der App, ausgeführt in node)
#   H = tests/handbuch_test.php       (Benutzerhandbuch)
#
#   P1 satzWarten: anderer Wortlaut                     W2, W3 rot – #31 GRÜN (gewollt, s. u.)
#   P2 Antwort baut den Satz an satzWarten vorbei       #31 rot
#   P3 andere Zahl im Satz als im Retry-After           A9 Retry-After rot
#   P4 satzWarten: keine Einzahl mehr                   W2 rot
#   P5 satzWarten: Einzahl auch bei 2                   W3 rot
#   P6 Hilfe: der alte Satz zurück                      Hilfe zitiert den Wartesatz
#   P7 Handbuch: der alte Satz zurück                   Handbuch zitiert den Wartesatz
#   H1 Harmlos: der alte Satz als Kommentar in anmeldung.php – grün
#
# P1 ist die Arbeitsteilung, nicht eine Lücke: #31 hält die ANTWORT an die
# eine Quelle (satzWarten), W1–W3 halten den WORTLAUT gegen feste
# Zeichenketten. Ein geänderter Wortlaut in satzWarten lässt #31 deshalb
# grün und muss W2/W3 rot machen. Ein Satz an satzWarten vorbei, der Byte für
# Byte gleich ist, ist an keiner Ausgabe zu erkennen – P2 nimmt den alten
# Wortlaut, den realistischen Fall.
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
    *.js)  node --check "$2" > /dev/null 2>&1 || { echo "$1: MUTATION KAPUTT – Syntaxfehler nach dem Einbau"; return 1; } ;;
  esac
}
ruecknahme() {    # NAME DATEI
  cp "$SICH/sicherung" "$2"; OFFEN=""
  [ "$(summe "$2")" = "$VORHER" ] || { echo "ABBRUCH: Rücknahme von $1 misslungen"; exit 2; }
}
pruefung() {      # B|A|N|H → Ausgabe in PA, Exit-Code in PE
  case "$1" in
    B) PA=$(php "$R/tests/anmeldebremse_test.php" 2>/dev/null); PE=$? ;;
    A) PA=$("$R/tests/anmeldung_db_test.sh" 2>/dev/null); PE=$? ;;
    N) PA=$(node "$R/tests/anmeldung_test.js" 2>/dev/null); PE=$? ;;
    H) PA=$(php "$R/tests/handbuch_test.php" 2>/dev/null); PE=$? ;;
  esac
}
zeilen() { printf '%s\n' "$PA" | grep -cF "$1" || true; }

# mut NAME B|A|N|H DATEI PERL-AUSDRUCK ROT-ZEILE [GRÜN-ZEILE …]
# Die ROT-Zeilen stehen durch „|“ getrennt; jede muss rot sein. Jede
# GRÜN-Zeile muss grün bleiben. Anfang der Zeile genügt.
mut() {
  local name=$1 wer=$2 datei="$R/$3" ausdruck=$4 rot=$5 z ok=1 bericht=""
  shift 5
  GELAUFEN=$((GELAUFEN + 1))
  if ! einbauen "$name" "$datei" "$ausdruck"; then
    FEHLT=$((FEHLT + 1))
  else
    pruefung "$wer"
    [ "$PE" -ne 0 ] || { ok=0; bericht="$bericht exit=0;"; }
    IFS='|' read -r -a ROTE <<< "$rot"
    for z in "${ROTE[@]}"; do
      [ "$(zeilen "✗ $z")" -ge 1 ] || { ok=0; bericht="$bericht nicht rot: „$z“;"; }
    done
    for z in "$@"; do
      [ "$(zeilen "✓ $z")" -ge 1 ] || { ok=0; bericht="$bericht nicht grün: „$z“;"; }
    done
    if [ "$ok" = 1 ]; then
      echo "$name: angeschlagen („$rot“)$([ $# -gt 0 ] && printf ', grün wie erwartet: „%s“' "$*")"
    else
      echo "$name: NICHT WIE ERWARTET –$bericht"; FEHLT=$((FEHLT + 1))
    fi
  fi
  ruecknahme "$name" "$datei"
}
harmlos() {       # NAME B|A|N|H DATEI PERL-AUSDRUCK
  GELAUFEN=$((GELAUFEN + 1))
  if ! einbauen "$1" "$R/$3" "$4"; then FEHLT=$((FEHLT + 1))
  else
    pruefung "$2"
    if [ "$PE" = 0 ]; then echo "$1: richtig nicht angeschlagen (grün)"
    else echo "$1: FALSCH ANGESCHLAGEN (exit=$PE)"; FEHLT=$((FEHLT + 1)); fi
  fi
  ruecknahme "$1" "$R/$3"
}

Z_W2="W2 bei 1 Sekunde Einzahl"
Z_W3="W3 bei 2 Sekunden Mehrzahl"
Z_31="#31 lokal, Schwelle erreicht gerade eben"
Z_A9R="A9 Retry-After nennt dieselben Sekunden wie der Satz"
Z_HILFE="Hilfe zitiert den Wartesatz"
Z_HB="Handbuch zitiert den Wartesatz"

# Vorprüfung: alle vier unverändert grün, jede erwartete Zeile genau einmal in
# der Ausgabe (REIHENREGELN 2) – gemessen an der Ausgabe, nicht am Quelltext.
vorpruefung() {   # WER ZEILE…
  local wer=$1 z n; shift
  pruefung "$wer"; [ "$PE" = 0 ] || { echo "ABBRUCH: Prüfung $wer schon vor der Serie rot"; exit 2; }
  for z in "$@"; do
    n=$(zeilen "✓ $z")
    [ "$n" = 1 ] || { echo "ABBRUCH: „$z“ steht $n-mal in der grünen Ausgabe von $wer, erwartet einmal"; exit 2; }
  done
}
vorpruefung B "$Z_W2" "$Z_W3" "$Z_31"
vorpruefung A "$Z_A9R"
vorpruefung N "$Z_HILFE"
vorpruefung H "$Z_HB"

AN=backend/auth/anmeldung.php
IX=backend/api/index.php
J=frontend/app.js
D=docs/BENUTZERHANDBUCH.md
mut P1 B $AN "s/return \\x27Zu viele Fehlversuche\\. Bitte in \\x27 \\. \\\$sekunden/return \\x27Zu viele Fehlversuche. Bitte nach \\x27 . \\\$sekunden/" \
  "$Z_W2|$Z_W3" "$Z_31"
mut P2 B $IX "s/json_error\\(Anmeldung::satzWarten\\(\\(int\\)\\\$r\\[\\x27sekunden\\x27\\]\\), 429\\);/json_error(\\x27Zu viele Fehlversuche. Erneut versuchen in noch \\x27 . (int)\\\$r[\\x27sekunden\\x27] . \\x27 Sekunden.\\x27, 429);/" \
  "$Z_31"
mut P3 A $IX "s/json_error\\(Anmeldung::satzWarten\\(\\(int\\)\\\$r\\[\\x27sekunden\\x27\\]\\), 429\\);/json_error(Anmeldung::satzWarten((int)\\\$r[\\x27sekunden\\x27] - 1), 429);/" \
  "$Z_A9R"
mut P4 B $AN "s/\\(\\\$sekunden === 1 \\? \\x27 Sekunde\\x27 : \\x27 Sekunden\\x27\\)/\\x27 Sekunden\\x27/" "$Z_W2"
mut P5 B $AN "s/\\(\\\$sekunden === 1 \\? /(\\\$sekunden <= 2 ? /" "$Z_W3"
mut P6 N $J "s/„Zu viele Fehlversuche\\. Bitte in … Sekunden erneut versuchen\\.“/„Zu viele Fehlversuche. Erneut versuchen in noch … Sekunden.“/" "$Z_HILFE"
mut P7 H $D "s/„Zu viele\\nFehlversuche\\. Bitte in … Sekunden erneut versuchen\\.“/„Zu viele\\nFehlversuche. Erneut versuchen in noch … Sekunden.“/" "$Z_HB"
harmlos H1 B $AN "s/(    public static function satzWarten\\(int \\\$sekunden\\): string\\n)/    \\/\\/ früher: \\x27Zu viele Fehlversuche. Erneut versuchen in noch \\x27 . \\\$sekunden . \\x27 Sekunden.\\x27\\n\$1/"

echo
if [ "$FEHLT" = 0 ]; then echo "ALLE $GELAUFEN MUTATIONEN BELEGT"; else echo "$FEHLT VON $GELAUFEN NICHT BELEGT"; fi
for f in $AN $IX $J $D; do echo "$f: $(summe "$R/$f")"; done
[ "$FEHLT" = 0 ]
