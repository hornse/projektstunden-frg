#!/usr/bin/env bash
# ============================================================
# tests-projektstunden.sh – Prüfung des CI-Umbaus
#
# Aufruf im Projektordner:  ./tests-projektstunden.sh
#
# SPDX-License-Identifier: GPL-3.0-or-later
# ============================================================
set -uo pipefail
export LC_ALL=C
cd "$(dirname "$0")"

FEHLER=0
gruen() { echo "  ✓ $1"; }
rot()   { echo "  ✗ $1"; FEHLER=$((FEHLER + 1)); }

CSS=frontend/style.css
JS=frontend/app.js
HTML=frontend/index.html
TOK=frontend/vendor/ci-css/ci-tokens.css
RT=backend/router.php

echo "Dateien"
for D in "$CSS" "$JS" "$HTML" "$TOK" "$RT"; do
    [ -f "$D" ] && gruen "$D vorhanden" || rot "$D fehlt"
done

echo ""
echo "Aufbau"
AUF=$(tr -cd '{' < "$CSS" | wc -c | tr -d ' ')
ZU=$(tr -cd '}' < "$CSS" | wc -c | tr -d ' ')
[ "$AUF" -eq "$ZU" ] && gruen "Klammern ausgeglichen ($AUF)" \
    || rot "$AUF öffnende, $ZU schließende Klammern"
if command -v node > /dev/null 2>&1; then
    node --check "$JS" > /dev/null 2>&1 \
        && gruen "app.js ist syntaktisch fehlerfrei" || rot "app.js hat einen Syntaxfehler"
else
    echo "  –  node nicht vorhanden"
fi
if command -v php > /dev/null 2>&1; then
    php -l "$RT" > /dev/null 2>&1 \
        && gruen "router.php ist syntaktisch fehlerfrei" || rot "router.php hat einen Syntaxfehler"
else
    echo "  –  php nicht vorhanden"
fi

echo ""
echo "Datenschutz"
# Bei jedem Aufruf ging die IP an einen Google-Server.
# Kommentare vorher entfernen: Die Erklärung, warum der @import weg ist,
# darf nicht als Fund gelten.
OHNE_KOMM=$(perl -0777 -pe 's{/\*.*?\*/}{}gs' "$CSS"; perl -0777 -pe 's{<!--.*?-->}{}gs' "$HTML")
printf '%s' "$OHNE_KOMM" | grep -qi "googleapis\|gstatic\|fonts.google" \
    && rot "externe Schriften werden noch geladen" \
    || gruen "keine externen Schriften mehr"
grep -qE "https?://" "$CSS" \
    && rot "externe Ressource im CSS" || gruen "keine externen Ressourcen im CSS"

echo ""
echo "Sicherheit im Router"
grep -q "realpath" "$RT" \
    && gruen "Pfade werden über realpath aufgelöst" || rot "keine realpath-Prüfung"
grep -q "str_starts_with(\$datei, \$frontendReal" "$RT" \
    && gruen "Ergebnis wird gegen frontend/ geprüft" || rot "keine Verzeichnisprüfung"
RT_OHNE=$(perl -0777 -pe 's{/\*.*?\*/}{}gs' "$RT" | grep -v '^\s*//')
printf '%s' "$RT_OHNE" | grep -q "tempnam" \
    && rot "tempnam-Block noch vorhanden (Anfragekörper landete in /tmp)" \
    || gruen "kein tempnam-Block mehr"
grep -q "\$_SERVER\['HTTPS'\] = 'on'" "$RT" \
    && gruen "HTTPS-Flag gesetzt" || rot "HTTPS-Flag fehlt (kein Secure am Cookie)"
grep -q "session_name('proj_session')" "$RT" \
    && gruen "session_name gesetzt" || rot "session_name fehlt"

echo ""
echo "Keine Rohfarben außerhalb des :root-Blocks"
REST=$(perl -0777 -pe 's{/\*.*?\*/}{}gs' "$CSS" | perl -0777 -pe 's{^.*?\n\}\n}{}s')
TREFFER=$(printf '%s' "$REST" | grep -oE '#[0-9a-fA-F]{3,8}\b' | sort -u || true)
[ -z "$TREFFER" ] && gruen "keine Hexfarben" || rot "Hexfarben: $(echo "$TREFFER" | tr '\n' ' ')"
TREFFER=$(printf '%s' "$REST" | grep -oE 'rgba?\([^)]*\)' | sort -u || true)
[ -z "$TREFFER" ] && gruen "keine rgb/rgba-Angaben" || rot "rgba: $(echo "$TREFFER" | tr '\n' ' ')"

echo ""
echo "Tokens vollständig"
UNBEKANNT=""
for V in $(grep -ohE 'var\(--ci-[a-z0-9-]+' "$CSS" | sed 's/var(//' | sort -u); do
    grep -qE "^[[:space:]]*$V:" "$TOK" || UNBEKANNT="$UNBEKANNT $V"
done
[ -z "$UNBEKANNT" ] && gruen "alle benutzten ci-Tokens sind definiert" \
    || rot "nicht definiert:$UNBEKANNT"

echo ""
echo "Einbindung"
grep -q 'data-projekt="projektstunden"' "$HTML" \
    && gruen "Projektfarbe gesetzt" || rot "data-projekt fehlt"
grep -q '/style.css' "$HTML" && gruen "style.css eingebunden" || rot "style.css nicht eingebunden"
grep -q 'ci-tokens.css' "$HTML" && gruen "Tokens eingebunden" || rot "Tokens nicht eingebunden"
grep -q '<style>' "$HTML" \
    && rot "es steht noch ein style-Block im HTML" || gruen "kein style-Block mehr im HTML"

GROESSE=$(wc -c < "$HTML" | tr -d ' ')
[ "$GROESSE" -lt 40000 ] \
    && gruen "index.html ist $GROESSE Bytes (war 45505, Proxy-Grenze 63 KB)" \
    || rot "index.html ist mit $GROESSE Bytes weiterhin groß"

echo ""
echo "Behobene Mängel"
grep -q 'class="skip-link"' "$HTML" && gruen "Sprungmarke vorhanden" || rot "keine Sprungmarke"
grep -q 'id="hauptinhalt" tabindex="-1"' "$HTML" \
    && gruen "Inhaltsbereich ist Sprung- und Fokusziel" || rot "Inhaltsbereich nicht fokussierbar"
grep -q "fokusAufInhalt" "$JS" \
    && gruen "Fokus springt nach dem Ansichtswechsel" || rot "kein Fokussprung"
grep -q "setAttribute('role', 'status')" "$JS" \
    && gruen "Meldungen werden angesagt" || rot "Meldungen ohne role=status"
grep -q 'id="nav-logo" src="" alt=""' "$HTML" \
    && gruen "Logo ist als dekorativ ausgezeichnet" || rot "alt am Logo prüfen"
grep -q -- '--text3:var(--ci-text-schwach)' "$CSS" \
    && gruen "--text3 erreicht AA (4.62 statt 2.76)" || rot "--text3 mit eigenem Wert"

echo ""
if [ "$FEHLER" -eq 0 ]; then echo "ALLES GRÜN"; exit 0; fi
echo "$FEHLER FEHLER"; exit 1
