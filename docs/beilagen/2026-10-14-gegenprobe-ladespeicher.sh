#!/bin/bash
# Gegenprobe zur Pruefung "Ladespeicher" in tests-projektstunden.sh (E65),
# gefahren am 14.10.2026 vor Commit c36b3ee. Beleg nach REIHENREGELN 2: Das
# Werkzeug der Gegenprobe gehoert zu den Belegen.
#
# Zehn Eingriffe in Serie, jeder mit Wirkungsnachweis und Ruecknahme aus einer
# Sicherungskopie, belegt ueber die Pruefsumme. Aendert CLAUDE.md und
# FALLSTRICKE.md voruebergehend; bricht ab, wenn eine Ruecknahme nicht ankommt.
# Die Grenzwerte in G und H gelten fuer den Stand vom 14.10.2026 (85 744 Bytes)
# und muessen bei einem anderen Stand angepasst werden.
#
# Aufruf aus beliebigem Verzeichnis: docs/beilagen/2026-10-14-gegenprobe-ladespeicher.sh
#
# SPDX-License-Identifier: GPL-3.0-or-later
set -u
export LC_ALL=C
S=$(mktemp -d)
cd "$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
SOLL_C=$(shasum CLAUDE.md | cut -d' ' -f1)
SOLL_F=$(shasum FALLSTRICKE.md | cut -d' ' -f1)
cp CLAUDE.md "$S/CLAUDE.md.sicher"; cp FALLSTRICKE.md "$S/FALLSTRICKE.md.sicher"
lauf() { ./tests-projektstunden.sh 2>&1 | grep -A3 '^Ladespeicher' | sed -n '2,4p' | grep -v '^$'; }
zurueck() {
  cp "$S/CLAUDE.md.sicher" CLAUDE.md; cp "$S/FALLSTRICKE.md.sicher" FALLSTRICKE.md
  [ "$(shasum CLAUDE.md | cut -d' ' -f1)" = "$SOLL_C" ] && [ "$(shasum FALLSTRICKE.md | cut -d' ' -f1)" = "$SOLL_F" ] \
    && echo "   Rücknahme belegt (Prüfsummen = Soll)" || { echo "   RÜCKNAHME FEHLGESCHLAGEN – Sicherungen bleiben in $S"; exit 1; }
}
probe() { # name, sed-ausdruck auf CLAUDE.md (Zeile nach "Ergänzend:")
  echo "== $1"
  printf '%s\n' "$2" > "$S/zeile.txt"
  awk -v f="$S/zeile.txt" '{print} /^Ergänzend:/{while((getline l < f)>0) print l}' "$S/CLAUDE.md.sicher" > CLAUDE.md
  echo "   Eingriff: $(grep -c 'ENTSCHEIDUNGEN\|gibt-es-nicht' "$S/CLAUDE.md.sicher") -> $(grep -c 'ENTSCHEIDUNGEN\|gibt-es-nicht' CLAUDE.md) Zeilen mit dem Ziel"
  lauf; zurueck
}
echo "== 0 Ausgangslauf"; lauf
probe "A Import wieder eingesetzt (erwartet: rot)" "- Entscheidungen: @docs/ENTSCHEIDUNGEN.md"
probe "B derselbe Import in Backticks (erwartet: grün)" "- Entscheidungen: \`@docs/ENTSCHEIDUNGEN.md\`"
probe "C derselbe Import im Codeblock (erwartet: grün)" $'```\n@docs/ENTSCHEIDUNGEN.md\n```'
probe "D derselbe Import im HTML-Kommentar (erwartet: grün)" "<!-- @docs/ENTSCHEIDUNGEN.md -->"
probe "E Import auf fehlende Datei (erwartet: rot, FEHLT)" "- Weg: @docs/gibt-es-nicht.md"
echo "== F verschachtelt: FALLSTRICKE.md importiert das Protokoll (erwartet: rot)"
printf '\n@docs/ENTSCHEIDUNGEN.md\n' >> FALLSTRICKE.md
echo "   Eingriff: $(grep -c '@docs/ENTSCHEIDUNGEN' "$S/FALLSTRICKE.md.sicher") -> $(grep -c '@docs/ENTSCHEIDUNGEN' FALLSTRICKE.md)"
lauf; zurueck
echo "== G Grenze genau auf der Summe (erwartet: grün)"; IMPORT_GRENZE=85744 lauf
echo "== H Grenze ein Byte darunter (erwartet: rot)"; IMPORT_GRENZE=85743 lauf
echo "== I benutzerweite CLAUDE.md, 1000 Bytes, über HOME (erwartet: grün, 86744, 6 Dateien, ja)"
mkdir -p "$S/heim/.claude"; head -c 1000 /dev/zero | tr '\0' x > "$S/heim/.claude/CLAUDE.md"
echo "   Eingriff: $(wc -c < "$S/heim/.claude/CLAUDE.md") Bytes angelegt"
HOME="$S/heim" lauf
echo "== J ohne CLAUDE.md (erwartet: rot)"
mv CLAUDE.md "$S/CLAUDE.md.weg"; ls CLAUDE.md 2>&1 | sed 's/^/   /'; lauf; mv "$S/CLAUDE.md.weg" CLAUDE.md; zurueck
echo "== Z Endlauf"; ./tests-projektstunden.sh 2>&1 | tail -3 | head -2; git status --short
rm -rf "$S"
