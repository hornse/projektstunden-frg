#!/bin/bash
# ============================================================
# deploy.sh – überträgt NUR Dateien. SQL-Migrationen werden
# getrennt eingespielt (siehe ROLLOUT.md).
# ============================================================
set -e
export LC_ALL=C

cd "$(dirname "$0")"

# AUSGELIEFERT WIRD, WAS COMMITTET IST (E293, koordination B57).
#
# ABWEICHUNG VON REIHENREGELN 6, ausdruecklich und gemeldet: Dort steht als
# Muster "git add -A, dann if ! git diff --cached --quiet; then git commit".
# Am 06.10.2026 lag eine RTF mit einer ungeschwaerzten Kennung ungetrackt im
# Repo - "git add -A" haette sie beim naechsten Ausliefern nach GitHub
# gebracht. Deshalb ZUERST anhalten, wenn etwas Ungetracktes oder ungeprueft
# Geaendertes da ist, und es nennen; und unten nur committen, was dieses
# Skript selbst aendert. Der Zweck der alten Zeile bleibt: Ohne Aenderung
# erreicht das Skript den Push.
#
# ZUERST, vor der Suite: tests/auf_dem_server.sh packt ungetrackte Dateien
# mit ein - ohne diesen Halt ginge eine solche Datei sogar auf den Server.
tests/vor_auslieferung.sh

echo "== Prüfungen vor dem Push =="
tests/pruefe_alles.sh

# DIESELBE SUITE AUF DEM SERVER (E195), unter der PHP-Fassung des
# Dienstes. Scheitert sie dort, bricht set -e hier ab – vor Commit und
# Push. Es kann keine Auslieferung stattfinden, die dort nicht liefe.
tests/auf_dem_server.sh

MELDUNG="${1:-Auslieferung $(date +%Y-%m-%d\ %H:%M)}"

# ---- Cache-Busting -----------------------------------------------------
# Ohne das liefern Browser nach einem Deploy weiter das alte CSS aus:
# In index.html steht "?v=DEV", und was sich nie ändert, wird nie neu
# geladen.
#
# Der Ausdruck matcht JEDEN Wert, nicht nur Ziffern. In projektstunden und
# schulprozesse steht dort "\?v=\d+" – der trifft das "DEV" im Auslieferungs-
# zustand nicht, das sed läuft ins Leere, es gibt nichts zu committen, und
# unter "set -e" bricht deploy.sh dann vor dem Push ab. Gefunden am
# 17.08.2026. Kein sed -i: BSD (macOS) und GNU erwarten dort Verschiedenes.
STEMPEL=$(date -u +%Y%m%d%H%M%S)
if [ -f frontend/index.html ]; then
  sed "s/?v=[^\"']*/?v=$STEMPEL/g" frontend/index.html > frontend/index.html.neu
  mv frontend/index.html.neu frontend/index.html
  echo "== Cache-Busting: ?v=$STEMPEL =="
fi

# Die oberste Version des CHANGELOG (E213) - VOR dem Commit ermittelt, weil
# sie in backend/stand.php mit hineingeht.
VERSION=$(grep -m1 -oE '^## v[0-9]+\.[0-9]+\.[0-9]+' CHANGELOG.md | sed 's/^## //' || true)
if [ -z "$VERSION" ]; then
  echo "!! Keine Version im CHANGELOG.md - Abbruch vor dem Push (E213)"
  exit 1
fi

# DER STAND, DEN PHP AUSFUEHRT (Frage 108, E375): "vX.Y.Z JJJJMMTTHHMMSS" in
# eine PHP-Konstante. Jede Antwort traegt ihn als X-Lernzeiten-Stand.
sed "s/^const LZ_STAND = '[^']*';/const LZ_STAND = '$VERSION $STEMPEL';/" backend/stand.php > backend/stand.php.neu
mv backend/stand.php.neu backend/stand.php
echo "== Stand: $VERSION $STEMPEL =="

# NUR, WAS DIESES SKRIPT SELBST AENDERT (B57): die ?v=-Werte und der Stand.
# Alles andere ist vorher namentlich committet - sonst haette
# tests/vor_auslieferung.sh oben angehalten.
if [ -f frontend/index.html ]; then
  git add frontend/index.html
fi
git add backend/stand.php
if ! git diff --cached --quiet; then
  git commit -m "$MELDUNG"
else
  echo "  (nichts zu committen)"
fi

# ---- Tag (E213) ---------------------------------------------------------
# Die oberste Version des CHANGELOG auf den AUSLIEFERUNGSCOMMIT - er ist,
# was auf dem Server liegt. Nicht rueckwirkend: Tags gibt es ab v0.36.11.
# Traegt die Version schon einen Tag, gab es keinen neuen Eintrag im
# CHANGELOG; der Tag bleibt, wo er ist, und das wird gesagt.
# tests/tag_pruefung.sh faengt einen vergessenen Tag beim naechsten Lauf.
# $VERSION steht seit E375 oben, vor dem Commit.
if git rev-parse -q --verify "refs/tags/$VERSION" > /dev/null; then
  echo "== Tag $VERSION gibt es schon (auf $(git rev-parse --short "$VERSION^{commit}")) - kein neuer CHANGELOG-Eintrag? =="
else
  git tag -a "$VERSION" -m "$MELDUNG"
  echo "== Tag $VERSION auf $(git rev-parse --short HEAD) =="
fi

# GitHub zuerst. Scheitert der Push – etwa an einer Branch-Protection-
# Regel –, würde "set -e" den Uberspace-Push verhindern. Deshalb hier
# bewusst abgefangen und am Ende geprüft.
echo "== Push nach GitHub =="
git push github main "refs/tags/$VERSION" || echo "  !! GitHub-Push fehlgeschlagen – wird unten geprüft"

echo "== Push nach Uberspace =="
git push uberspace main "refs/tags/$VERSION"

echo "== Kontrolle =="
git log --oneline -1 uberspace/main
git log --oneline -1 github/main || echo "  !! GitHub hängt hinterher"

echo ""
echo "Dateien übertragen. SQL-Migrationen nicht vergessen – siehe ROLLOUT.md."
