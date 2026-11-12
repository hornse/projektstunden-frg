#!/bin/bash
# ============================================================
# bin/konfiguration-ableiten.sh – backend/konfiguration.php aus der alten
# backend/config.php ableiten (Auftrag A, Paket 1, E68)
#
#   ./bin/konfiguration-ableiten.sh lokal            trocken, am Rechner
#   SCHREIBEN=1 ./bin/konfiguration-ableiten.sh lokal
#   ./bin/konfiguration-ableiten.sh server           trocken, auf dem Server
#   SCHREIBEN=1 ./bin/konfiguration-ableiten.sh server
#   ./bin/konfiguration-ableiten.sh server-pruefen   nach der Auslieferung:
#                                                    Namen gegen die Vorlage
#
# Vergleichsmaßstab sind die Funktionen der Vorlage vom Stand VOR Auftrag A
# (tests/daten/config.example-0e80957.php): Trägt die config.php des Ziels
# genau diesen Code, ändert der Umzug nur, was Auftrag A ändern will. Die
# Namen kommen aus backend/konfiguration.example.php. Beides wird HIER, am
# Rechner, berechnet und als Argument mitgegeben – auf dem Server liegt vor
# der Auslieferung weder das Skript noch die Vorlage. Das PHP-Skript geht
# über die Standardeingabe hinüber; auf dem Server entsteht keine
# Zwischendatei.
#
# Ausgegeben werden nur Namen und Zahlen, nie ein Wert (REIHENREGELN 9).
# Trocken ist der Standard (REIHENREGELN 3).
#
# SPDX-License-Identifier: GPL-3.0-or-later
# ============================================================
set -eu
export LC_ALL=C
cd "$(dirname "$0")/.."

ZIEL_HOST="hornse@halimede.uberspace.de"
ZIEL_DIR="projektstunden"
SKRIPT=bin/konfiguration-ableiten.php
NAMEN=$(php "$SKRIPT" namen backend/konfiguration.example.php)
FINGER=$(php "$SKRIPT" fingerabdruecke tests/daten/config.example-0e80957.php)
[ -n "$NAMEN" ] && [ -n "$FINGER" ] || { echo "HALT: Namen oder Fingerabdrücke leer"; exit 1; }
echo "Vorlage: $(printf '%s' "$NAMEN" | tr ',' '\n' | grep -c .) Namen, Maßstab: $(printf '%s' "$FINGER" | tr ',' '\n' | grep -c .) Funktionen"

case "${1:-}" in
    lokal)
        SCHREIBEN="${SCHREIBEN:-0}" php "$SKRIPT" ableiten backend/config.php backend/konfiguration.php "$NAMEN" "$FINGER"
        ;;
    lokal-pruefen)
        php "$SKRIPT" pruefen backend/konfiguration.php "$NAMEN"
        ;;
    server)
        S="${SCHREIBEN:-0}"
        ssh "$ZIEL_HOST" "cd $ZIEL_DIR && SCHREIBEN=$S php -- ableiten backend/config.php backend/konfiguration.php $(printf '%q' "$NAMEN") $(printf '%q' "$FINGER")" < "$SKRIPT"
        ;;
    server-pruefen)
        ssh "$ZIEL_HOST" "cd $ZIEL_DIR && php -- pruefen backend/konfiguration.php $(printf '%q' "$NAMEN")" < "$SKRIPT"
        ;;
    *)
        echo "Aufruf: $0 lokal|lokal-pruefen|server|server-pruefen   (SCHREIBEN=1 schreibt)" >&2
        exit 2
        ;;
esac
echo "ENDE konfiguration-ableiten"
