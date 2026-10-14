#!/bin/bash
# ============================================================
# tests/vor_auslieferung.sh – ginge etwas mit, das niemand angesehen hat?
# (E293, koordination B57)
#
# ANLASS (06.10.2026): Ein Sondierungsbericht lag als RTF UNGETRACKT im
# Repo, mit der ungeschwaerzten Benutzerkennung eines echten Kontos.
# deploy.sh machte "git add -A" und haette ihn beim naechsten Ausliefern
# committet und nach GitHub gepusht. Gefunden wurde er, weil er vorher
# gelesen wurde - Glueck, keine Bauart.
#
# AUSGELIEFERT WIRD, WAS COMMITTET IST. Dieses Skript haelt an, solange
#   - eine Datei UNGETRACKT ist (und nicht in .gitignore steht), oder
#   - eine getrackte Datei GEAENDERT oder gestaget, aber nicht committet ist,
# und NENNT sie. Wer sieht, was dazukaeme, entscheidet: namentlich
# committen, verschieben, oder in .gitignore - vorher, nicht nachher.
#
# Rein lesend. Aufruf: tests/vor_auslieferung.sh [Repo-Verzeichnis]
# ============================================================
set -e
export LC_ALL=C
cd "${1:-$(dirname "$0")/..}"

# -z: Namen mit Leerzeichen und Umlauten erscheinen, wie sie heissen -
# ohne -z stuenden Umlaute als Oktalfolge da ("\303\244").
UNGETRACKT=$(git ls-files -o --exclude-standard -z | tr '\0' '\n')
GEAENDERT=$(git status --porcelain -z --untracked-files=no | tr '\0' '\n')

if [ -n "$UNGETRACKT" ] || [ -n "$GEAENDERT" ]; then
  echo "!! Ausgeliefert wird, was committet ist (B57). Vorher entscheiden:"
  if [ -n "$UNGETRACKT" ]; then
    echo "   UNGETRACKT – namentlich committen, verschieben oder in .gitignore:"
    printf '%s\n' "$UNGETRACKT" | sed 's/^/     /'
  fi
  if [ -n "$GEAENDERT" ]; then
    echo "   GEAENDERT, nicht committet – namentlich committen oder zuruecknehmen:"
    printf '%s\n' "$GEAENDERT" | sed 's/^/     /'
  fi
  exit 1
fi
echo "== Vor der Auslieferung: nichts Ungetracktes, nichts ungeprueft Geaendertes =="
