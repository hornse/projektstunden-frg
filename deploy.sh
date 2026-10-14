#!/bin/bash
# deploy.sh – Projektstunden NRW deployen
# Aktualisiert Cache-Busting-Timestamp und pusht auf GitHub + Uberspace.
#
# Verwendung:
#   ./deploy.sh "Commit-Nachricht"
#   ./deploy.sh  (ohne Nachricht: interaktiv fragen)

set -e
export LC_ALL=C
cd "$(dirname "$0")"

# AUSGELIEFERT WIRD, WAS COMMITTET IST. Muster aus lernzeiten
# (tests/vor_auslieferung.sh, E293 dort, koordination B57), Vorbild beigelegt
# unter docs/beilagen/. Bis zum 14.10.2026 stand hier "git add -A": Eine Datei,
# die unverfolgt im Baum lag, waere ungesehen committet und nach GitHub
# gepusht worden (REIHENREGELN 6). Deshalb ZUERST anhalten und nennen, was
# dazukaeme -- vor den Tests, vor Commit und Push. Wer es sieht, entscheidet:
# namentlich committen, verschieben oder in .gitignore.
# -z: Namen mit Umlauten erscheinen, wie sie heissen, nicht als Oktalfolge.
UNGETRACKT=$(git ls-files -o --exclude-standard -z | tr '\0' '\n')
GEAENDERT=$(git status --porcelain -z --untracked-files=no | tr '\0' '\n')
if [ -n "$UNGETRACKT" ] || [ -n "$GEAENDERT" ]; then
  echo "!! Ausgeliefert wird, was committet ist. Vorher entscheiden:" >&2
  if [ -n "$UNGETRACKT" ]; then
    echo "   UNVERFOLGT – namentlich committen, verschieben oder in .gitignore:" >&2
    printf '%s\n' "$UNGETRACKT" | sed 's/^/     /' >&2
  fi
  if [ -n "$GEAENDERT" ]; then
    echo "   GEAENDERT, nicht committet – namentlich committen oder zuruecknehmen:" >&2
    printf '%s\n' "$GEAENDERT" | sed 's/^/     /' >&2
  fi
  echo "Kein Deploy." >&2
  exit 1
fi
echo "== Vor der Auslieferung: nichts Unverfolgtes, nichts ungeprueft Geaendertes =="

# Tests vor allem anderen. Eine Pruefung ohne ihre Voraussetzung gilt nicht
# als bestanden (REIHENREGELN 2) - ein fehlendes Skript bricht ab, statt
# den Deploy stillschweigend durchzulassen.
if [ -x ./tests-projektstunden.sh ]; then
  ./tests-projektstunden.sh || { echo "Tests rot - kein Deploy." >&2; exit 1; }
else
  echo "FEHLER: tests-projektstunden.sh fehlt oder ist nicht ausfuehrbar." >&2
  exit 1
fi

MSG="${1}"
if [ -z "$MSG" ]; then
  read -p "Commit-Nachricht: " MSG
fi
if [ -z "$MSG" ]; then
  echo "Fehler: Keine Commit-Nachricht angegeben." >&2
  exit 1
fi

# Cache-Busting-Timestamp aktualisieren
# Ausdruck über beliebige Zeichen, nicht nur Ziffern: "\?v=\d+" traf das
# "?v=DEV" im Auslieferungszustand nicht, das sed lief ins Leere, es gab
# nichts zu committen, und unter "set -e" brach der Commit-Schritt vor dem
# Push ab. Gefunden am 17.08.2026. Kein sed -i: BSD (macOS) und GNU
# erwarten dort Verschiedenes.
STEMPEL=$(date -u +%Y%m%d%H%M%S)
sed "s/?v=[^\"']*/?v=$STEMPEL/g" frontend/index.html > frontend/index.html.neu
mv frontend/index.html.neu frontend/index.html
echo "Cache-Busting: ?v=$STEMPEL"

# Committen und pushen. NUR, was dieses Skript selbst aendert: den ?v=-Stempel.
# Alles andere ist vorher namentlich committet -- sonst haette der Halt oben
# angehalten.
git add frontend/index.html
if ! git diff --cached --quiet; then
  git commit -m "$MSG"
else
  echo "  (nichts zu committen)"
fi
git push github main && git push uberspace main

echo ""
echo "✓ Deploy abgeschlossen ($(date '+%d.%m.%Y %H:%M'))"
