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

# ============================================================
# Protokoll: der vollstaendige Lauf landet in einer Datei
#
# Anlass: Ein roter Lauf wurde durch `tail -3` geschickt; die rote Zeile stand
# oberhalb des Fensters, und danach liess sich der Lauf nicht mehr herstellen.
# Welche Pruefung gefallen war, blieb unbekannt (REIHENREGELN 2).
#
# Zwei Dateien, aus zwei verschiedenen Gruenden:
#
#   logs/pruefung-letzter.txt         jeder Lauf, wird ueberschrieben
#   logs/pruefung-rot-<Zeitstempel>   NUR ein roter Lauf, wird nie ueberschrieben
#
# Warum nicht jeder Lauf mit Zeitstempel: Dann liegen nach einer Woche
# hunderte gruene Protokolle da, die niemand liest, und das eine rote ist
# schwerer zu finden, nicht leichter. Gruen ist der Normalfall und interessiert
# nur bis zum naechsten Lauf; rot ist die Ausnahme und muss jeden spaeteren
# Lauf ueberleben. Genau das war der Fall von heute: ein roter Lauf, dem 28
# gruene folgten -- unter einem festen Namen waere der Beleg beim zweiten Lauf
# weg gewesen.
#
# Umgesetzt ueber einen Selbstaufruf statt `exec > >(tee …)`: Bei der
# Prozessersetzung wartet die Shell nicht auf `tee`, die letzten Zeilen koennen
# beim Beenden fehlen. Eine gewoehnliche Pipe hat das Problem nicht, und
# PIPESTATUS liefert den Exit-Code des Skripts.
# ============================================================
if [ -z "${PRUEF_INNEN:-}" ]; then
    mkdir -p logs
    PROTOKOLL="logs/pruefung-letzter.txt"
    PRUEF_INNEN=1 "$0" "$@" 2>&1 | tee "$PROTOKOLL"
    ERGEBNIS=${PIPESTATUS[0]}
    # Nicht nur die Zeilen mit dem Haken: Eine rote Pruefung kann darunter
    # Details fuehren, die sagen, WORAN es lag ("Zeile 2145: e.dateiname").
    # Die tragen kein Zeichen und fehlten bisher im Auszug -- wer nur `tail`
    # las, erfuhr welche Pruefung fiel, nicht warum.
    ROTE=$(awk '
        /^  ✗ / { drin = 1; print; next }
        drin && /^    [^ ]/ { print; next }
        { drin = 0 }
    ' "$PROTOKOLL" || true)
    if [ -n "$ROTE" ]; then
        ROTDATEI="logs/pruefung-rot-$(date +%Y%m%d-%H%M%S).txt"
        cp "$PROTOKOLL" "$ROTDATEI"
        # Die roten Zeilen noch einmal ans Ende, damit sie auch in einem
        # `tail -5` stehen. Der Pfad kommt zuletzt: Er ist die Schlusszeile,
        # und er fuehrt zum vollstaendigen Lauf, wenn mehr rote Zeilen da
        # sind, als in das Fenster passen.
        {
            echo ""
            echo "ROT – die gefallenen Prüfungen noch einmal:"
            printf '%s\n' "$ROTE"
            echo "Vollständiger Lauf: $ROTDATEI"
        } | tee -a "$PROTOKOLL" "$ROTDATEI"
    else
        echo "Vollständiger Lauf: $PROTOKOLL" | tee -a "$PROTOKOLL"
    fi
    exit "$ERGEBNIS"
fi

FEHLER=0
GRUEN=0
gruen() { echo "  ✓ $1"; GRUEN=$((GRUEN + 1)); }
rot()   { echo "  ✗ $1"; FEHLER=$((FEHLER + 1)); }

# Kommentarentferner fuer /* */, // und <!-- -->. Er erhaelt die Zeilenzahl:
# Jede Eingabezeile erzeugt genau eine Ausgabezeile, damit eine Fundstelle
# ihre Zeilennummer behaelt. Zwei Rubriken benutzen ihn -- Rohfarben und
# CSS-Variablen --, und beide brauchen dasselbe: Was in einer Erklaerung
# steht, ist keine Sache, sondern ihre Beschreibung (REIHENREGELN 2).
STRIP_AWK='
BEGIN { blk = 0; htm = 0 }
{
  zeile = $0; aus = ""; i = 1; n = length(zeile)
  while (i <= n) {
    z2 = substr(zeile, i, 2); z3 = substr(zeile, i, 3); z4 = substr(zeile, i, 4)
    if (blk) { if (z2 == "*/") { blk = 0; i += 2 } else i++; continue }
    if (htm) { if (z3 == "-->") { htm = 0; i += 3 } else i++; continue }
    if (z2 == "/*")   { blk = 1; i += 2; continue }
    if (z4 == "<!--") { htm = 1; i += 4; continue }
    if (z2 == "//")   { break }
    aus = aus substr(zeile, i, 1); i++
  }
  print aus
}'

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
# ------------------------------------------------------------------
# GELTUNGSBEREICH: das ganze `frontend/` ohne `vendor/`, nicht eine
# einzelne Datei.
#
# ANLASS: Diese Pruefung las bis zum 10.09.2026 nur `style.css`. Sie hat
# deshalb sieben Hexwerte in `app.js` nie gesehen -- und zwar zweimal
# nicht: Beim Kompetenzauswahl-Auftrag waren es sechs, danach kam eine
# siebte dazu, ohne dass etwas ansprang. Gruen war eine Aussage ueber die
# Pruefstelle, nicht ueber den Bestand (REIHENREGELN 2).
#
# WAS ZULAESSIG BLEIBT, und warum:
#
#   * Der `:root`-Block einer eigenen Stilvorlage. Dort gehoert eine
#     Kategorienpalette hin (REIHENREGELN 7). Geprueft wird alles
#     DANACH -- der Block wird zeilenerhaltend geleert, damit
#     Fundstellen ihre Zeilennummer behalten.
#   * `frontend/vendor/` gar nicht. Diese Dateien gehoeren dem
#     Quell-Repo; wir duerfen sie nicht aendern (REIHENREGELN 6). Eine
#     rote Zeile, die niemand beheben darf, blockiert den Deploy fuer
#     etwas Fremdes und wird dann abgeschaltet. Ein Fund dort ist eine
#     Meldung an `koordination`, kein Mangel dieses Projekts. Heute
#     fuehren `ci-shell.css` und `ci-komponenten.css` null Rohfarben;
#     `ci-tokens.css` ist der vorgesehene Ort fuer alle 56.
#   * Eine Zeile mit dem Vermerk `rohfarbe-erlaubt: <Grund>`, in der
#     Syntax ihrer Datei. Form aus E43.
#
# EIN RUECKFALL IST KEINE AUSNAHME: `var(--x,#wert)` faellt durch. Der
# Wert ist ungeprueft -- `#f59e0b` erreichte auf Weiss 2.15 --, und wo
# die Variable fehlt, verdeckt der Rueckfall genau den Fehler, den die
# Variablenpruefung sichtbar machen soll.
#
# KOMMENTARE WERDEN VORHER ENTFERNT, der Vermerk aber in der
# UNVERAENDERTEN Zeile gesucht. Anders ginge beides nicht zugleich: Der
# Vermerk steht in einem Kommentar, und eine Farbe in einer Erklaerung
# ist keine Farbe an einem Element.
#
# GRENZEN:
#   1. Der Vermerk befreit die ZEILE, nicht die einzelne Angabe -- eine
#      Zeile mit zwei Werten, von denen nur einer begruendet ist, kommt
#      durch. Dieselbe Ungenauigkeit hat E43 fuer die Maskierung
#      benannt; im Bestand tritt der Fall nicht auf, nachgesehen.
#   2. Ein zur Laufzeit zusammengesetzter Wert ('#' + wert) wird nicht
#      gesehen.
#   3. Sie sagt nichts ueber Farbnamen (`red`, `steelblue`). Im Bestand
#      kommen keine vor.
# ------------------------------------------------------------------
ROHF_DATEIEN=$(find frontend -type f \( -name '*.css' -o -name '*.js' -o -name '*.html' \) \
               ! -path 'frontend/vendor/*' | sort)
ROHF_D_ZAHL=$(printf '%s\n' "$ROHF_DATEIEN" | grep -c . || true)

# Sucht ein Muster in allen Dateien und gibt je Fundstelle eine Zeile aus:
#   ROT <datei>:<zeile> <werte>    -- unbegruendet
#   OK  <datei>:<zeile> <werte>    -- Zeile traegt den Vermerk
rohfarben_suchen() {
    local muster="$1" f text nr rest orig werte
    for f in $ROHF_DATEIEN; do
        text=$(awk "$STRIP_AWK" "$f")
        if [ "${f##*.}" = "css" ]; then
            # Den ersten :root-Block leeren, Zeilenzahl erhalten.
            text=$(printf '%s\n' "$text" | awk 'BEGIN{drin=1}
                { if (drin) { if ($0 ~ /^\}/) drin=0; print ""; next } print }')
        fi
        printf '%s\n' "$text" | grep -nE "$muster" | while IFS=: read -r nr rest; do
            orig=$(sed -n "${nr}p" "$f")
            werte=$(printf '%s' "$rest" \
                    | grep -oE '#[0-9a-fA-F]{3,8}|rgba?\([^)]*\)|hsla?\([^)]*\)' \
                    | tr '\n' ' ')
            case "$orig" in
                *rohfarbe-erlaubt:*) printf 'OK %s:%s %s\n'  "$f" "$nr" "$werte" ;;
                *)                   printf 'ROT %s:%s %s\n' "$f" "$nr" "$werte" ;;
            esac
        done
    done
}

# `&#8964;` ist eine HTML-Entitaet und keine Farbe: Vor dem `#` darf
# deshalb kein `&` und kein Namenszeichen stehen.
ROHF_HEX='(^|[^&A-Za-z0-9_])#([0-9a-fA-F]{8}|[0-9a-fA-F]{6}|[0-9a-fA-F]{4}|[0-9a-fA-F]{3})([^0-9a-fA-F]|$)'
ROHF_FUNK='rgba?\([^)]*\)|hsla?\([^)]*\)'

if [ "$ROHF_D_ZAHL" -eq 0 ]; then
    rot "keine eigene Frontend-Datei gefunden – Voraussetzung der Rohfarbenpruefung fehlt"
    rot "keine eigene Frontend-Datei gefunden – Voraussetzung der Rohfarbenpruefung fehlt"
else
    ROHF_H=$(rohfarben_suchen "$ROHF_HEX")
    ROHF_H_ROT=$(printf '%s\n' "$ROHF_H" | grep -c '^ROT' || true)
    ROHF_H_OK=$(printf '%s\n' "$ROHF_H" | grep -c '^OK' || true)
    if [ "$ROHF_H_ROT" -gt 0 ]; then
        rot "$ROHF_H_ROT Hexfarben ausserhalb des :root-Blocks, unbegruendet ($ROHF_H_OK begruendet):"
        printf '%s\n' "$ROHF_H" | grep '^ROT' | sed 's/^ROT /    /'
    else
        gruen "keine Hexfarben ausserhalb des :root-Blocks in $ROHF_D_ZAHL Dateien ($ROHF_H_OK begruendet)"
    fi

    ROHF_F=$(rohfarben_suchen "$ROHF_FUNK")
    ROHF_F_ROT=$(printf '%s\n' "$ROHF_F" | grep -c '^ROT' || true)
    ROHF_F_OK=$(printf '%s\n' "$ROHF_F" | grep -c '^OK' || true)
    if [ "$ROHF_F_ROT" -gt 0 ]; then
        rot "$ROHF_F_ROT rgb/hsl-Angaben ausserhalb des :root-Blocks, unbegruendet ($ROHF_F_OK begruendet):"
        printf '%s\n' "$ROHF_F" | grep '^ROT' | sed 's/^ROT /    /'
    else
        gruen "keine rgb/hsl-Angaben ausserhalb des :root-Blocks ($ROHF_F_OK begruendet)"
    fi
fi

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
echo "Gerüst"
grep -q 'class="ci-huelle"' "$HTML" \
    && gruen "Seitenleisten-Variante eingebunden" || rot "kein ci-huelle"
grep -q 'id="app-view" class="ci-huelle"' "$HTML" \
    && gruen "Hülle ist app-view selbst" || rot "keine Hülle an app-view"
# Die Anmeldemaske liegt INNERHALB der Hülle, damit die Leiste mit der
# Marke stehen bleibt. Lag sie daneben, schwebte das Formular im Nichts.
perl -0777 -ne 'exit(!(/ci-inhalt-innen.*?id="login-view"/s))' "$HTML" \
    && gruen "Anmeldemaske liegt in der Hülle" \
    || rot "Anmeldemaske außerhalb – Leiste fehlt beim Anmelden"
# Die Attribute stehen ueber zwei Zeilen, deshalb ueber die ganze Datei.
perl -0777 -ne 'exit(!(/id="app-view"[^>]*display:flex/s))' "$HTML" \
    && gruen "Hülle ist von Anfang an sichtbar" \
    || rot "Hülle startet verborgen – die Marke fehlt beim Anmelden"
grep -q "navSichtbar" "$JS" \
    && gruen "Navigationspunkte werden gesteuert" \
    || rot "keine Steuerung der Navigationspunkte"
for D in ci-komponenten.css ci-shell.css ci-shell.js ci-icons.svg; do
    [ -f "frontend/vendor/ci-css/$D" ] && gruen "$D vendored" || rot "$D fehlt"
done
grep -q 'ci-shell.js' "$HTML" && gruen "ci-shell.js eingebunden" || rot "ci-shell.js fehlt"
grep -q 'data-ci-schalter' "$HTML" \
    && gruen "Leiste ist einklappbar" || rot "kein Einklapp-Schalter"
grep -q 'aria-current' "$JS" \
    && gruen "aktiver Punkt über aria-current" || rot "aktiver Punkt nur über Klasse"
grep -qE '^aside\{|^\.logo\{|^\.nv\{' "$CSS" \
    && rot "eigene Shell-Regeln noch vorhanden" || gruen "keine doppelten Shell-Regeln"
grep -q '^\.shell{' "$CSS" \
    && rot ".shell noch da – zwei Flex-Hüllen kommen sich in die Quere" \
    || gruen "keine zweite Flex-Hülle"
# Untermenues kennt das Modul nicht; sie bleiben projekteigen.
grep -q '^\.nv-sub{' "$CSS" \
    && gruen "Administrationsgruppe bleibt projekteigen" || rot "Untermenü verschwunden"
grep -q 'el.hidden = false' "$JS" \
    && gruen "Logo nutzt hidden, nicht style.display" \
    || rot "style.display blendet den Platzhalter nicht aus"

ALTE=$(grep -c '<svg width=' "$HTML" || true)
[ "$ALTE" -le 2 ] \
    && gruen "Navigationssymbole kommen aus dem Sprite ($ALTE außerhalb)" \
    || rot "$ALTE eingebettete SVGs – Sprite nicht durchgängig"

FEHLENDE=""
for N in $(grep -oE "ci-i-[a-z]+" "$HTML" | sort -u); do
    grep -q "id=\"$N\"" frontend/vendor/ci-css/ci-icons.svg || FEHLENDE="$FEHLENDE $N"
done
[ -z "$FEHLENDE" ] && gruen "alle benutzten Symbole existieren im Sprite" \
    || rot "im Sprite fehlen:$FEHLENDE"

echo ""
echo "Behobene Mängel"
grep -q 'class="skip-link"' "$HTML" && gruen "Sprungmarke vorhanden" || rot "keine Sprungmarke"
grep -q 'id="hauptinhalt" tabindex="-1"' "$HTML" \
    && gruen "Inhaltsbereich ist Sprung- und Fokusziel" || rot "Inhaltsbereich nicht fokussierbar"
grep -q "fokusAufInhalt" "$JS" \
    && gruen "Fokus springt nach dem Ansichtswechsel" || rot "kein Fokussprung"
grep -q "setAttribute('role', 'status')" "$JS" \
    && gruen "Meldungen werden angesagt" || rot "Meldungen ohne role=status"
# Das <img> traegt seit dem Geruest-Umbau zusaetzlich eine Klasse;
# deshalb ueber die ganze Datei pruefen statt zeilenweise.
perl -0777 -ne 'exit(!(/id="nav-logo"[^>]*alt=""/s))' "$HTML" \
    && gruen "Logo ist als dekorativ ausgezeichnet" || rot "alt am Logo prüfen"
grep -q -- '--text3:var(--ci-text-schwach)' "$CSS" \
    && gruen "--text3 erreicht AA (4.62 statt 2.76)" || rot "--text3 mit eigenem Wert"

echo ""
echo "Anmeldung"
# Nachdem ein Passwort geprueft wurde, darf kein Fehlschlag anders aussehen
# als ein falsches Passwort. Sonst unterscheidet ein Angreifer "Passwort
# falsch" von "Passwort richtig, kein Datensatz" — hier auf Konten
# Minderjaehriger. FALLSTRICKE.md Abschnitt 8.
#
# Der Bereich wird ueber CODE abgegrenzt, nicht ueber einen Kommentar: ab dem
# Aufruf, der das Passwort prueft, bis zum Ende des Login-Zweigs. Eine
# Abgrenzung an einer Ueberschrift wuerde die Beschreibung der Regel messen
# statt der Sache (REIHENREGELN.md 2).
#
# Rechtepruefungen an einer bestehenden Sitzung liegen ausserhalb und
# duerfen unterscheiden — dort war kein Passwort im Spiel.
API=backend/api/index.php
ZWEIG=$(awk '
    /if \(\$method === .POST. && \$sub === .login.\) \{/ { f = 1 }
    f {
        buf = buf $0 "\n"
        n = gsub(/\{/, "{"); m = gsub(/\}/, "}"); tiefe += n - m
        if (tiefe == 0) { printf "%s", buf; exit }
    }' "$API" 2>/dev/null)
NACH_PASSWORT=$(printf '%s\n' "$ZWEIG" | awk '/authenticateAndGetDetails\(/ {f=1} f {print}' | tr '\n' ' ')
if [ -z "$NACH_PASSWORT" ]; then
    rot "Anmeldung: Login-Zweig oder Passwortpruefung nicht gefunden – die Pruefung fand ihre Voraussetzung nicht"
else
    ALLE=$(printf '%s' "$NACH_PASSWORT" | awk '{
        n = split($0, t, /json_error\(/)
        for (i = 2; i <= n; i++) {
            u = t[i]; sub(/\);.*/, "", u)
            if (match(u, /[0-9][0-9][0-9][ \t]*$/)) print substr(u, RSTART, 3)
        }
    }' | sort -u)
    VIERER=$(printf '%s\n' "$ALLE" | grep '^4' | tr '\n' ' ' | sed 's/ *$//')
    FUENFER=$(printf '%s\n' "$ALLE" | grep '^5' | tr '\n' ' ' | sed 's/ *$//')
    if [ -z "$VIERER" ]; then
        rot "Anmeldung: kein 4xx nach der Passwortpruefung gefunden – prueft die Pruefung noch etwas?"
    elif [ "$VIERER" = "401" ]; then
        gruen "Anmeldung lehnt einheitlich mit 401 ab${FUENFER:+ (unberührt: $FUENFER)}"
    else
        rot "Anmeldung lehnt uneinheitlich ab (Statuscodes: $VIERER)"
    fi
fi

echo ""
echo "Fachdaten"
# E19: erzeugte Fachdaten fuehren Quelle, Pruefsumme und Erzeuger im Kopf.
# E21: geprueft wird an der Deklaration. Jeder Seed, der eine "-- Quelle:"-Zeile
# fuehrt, muss sie einloesen; Seeds ohne Quellenangabe fallen nicht durch. Der
# Rueckstand bei 10_seed_deutsch_klp.sql ist in E21 festgehalten, nicht hier
# verschwiegen.
#
# Der Bestand wird ermittelt, nicht aufgezaehlt (REIHENREGELN 4): kein
# Dateiname steht in dieser Pruefung.
summe_von() {
    if command -v shasum > /dev/null 2>&1; then
        shasum -a 256 "$1" | awk '{print $1}'
    elif command -v sha256sum > /dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    fi
}
if ! command -v shasum > /dev/null 2>&1 && ! command -v sha256sum > /dev/null 2>&1; then
    rot "Fachdaten: weder shasum noch sha256sum vorhanden – die Prüfung fand ihre Voraussetzung nicht"
    rot "Fachdaten: Erzeuger nicht prüfbar – kein Prüfsummenwerkzeug"
else
    MIT_QUELLE=$(grep -l '^-- Quelle:' sql/*.sql 2>/dev/null || true)
    if [ -z "$MIT_QUELLE" ]; then
        # Null Funde sind ein Fehler, kein Ergebnis (REIHENREGELN 2).
        rot "Fachdaten: kein Seed nennt eine Quelle – die Prüfung fand ihre Voraussetzung nicht"
        rot "Fachdaten: kein Seed nennt einen Erzeuger – die Prüfung fand ihre Voraussetzung nicht"
    else
        # --- Prüfung 1: Quelle liegt unter docs/curricula/ und die Summe stimmt
        MANGEL=""
        ANZ_Q=0
        for SEED in $MIT_QUELLE; do
            Q=$(sed -n 's/^-- Quelle: *//p' "$SEED" | head -1)
            S_SOLL=$(sed -n 's/^-- SHA256: *//p' "$SEED" | head -1)
            # E23: Eine Angabe mit Schema ist ein Literaturhinweis, kein
            # Dateiverweis. Eine Webadresse hat keine Pruefsumme; sie hier zu
            # verlangen hiesse, einen Gegenstand zu fordern, den es nicht gibt.
            case "$Q" in
                http://*|https://*) continue ;;
            esac
            ANZ_Q=$((ANZ_Q + 1))
            case "$Q" in
                docs/curricula/*) ;;
                *) MANGEL="$MANGEL $(basename "$SEED"):Quelle-nicht-unter-docs/curricula"; continue ;;
            esac
            # Anwesenheit durch Auflisten, nicht durch grep (REIHENREGELN 3)
            if ! ls -1 "$Q" > /dev/null 2>&1; then
                MANGEL="$MANGEL $(basename "$SEED"):Quelldatei-fehlt"; continue
            fi
            if [ -z "$S_SOLL" ]; then
                MANGEL="$MANGEL $(basename "$SEED"):keine-SHA256-Zeile"; continue
            fi
            S_IST=$(summe_von "$Q")
            [ "$S_IST" = "$S_SOLL" ] || MANGEL="$MANGEL $(basename "$SEED"):Summe-weicht-ab"
        done
        if [ "$ANZ_Q" -eq 0 ]; then
            # Alle Angaben waren Literaturhinweise – dann hat die Prüfung
            # nichts geprüft. Null Funde sind ein Fehler (REIHENREGELN 2).
            rot "Fachdaten: kein Seed nennt eine Datei als Quelle – die Prüfung fand ihre Voraussetzung nicht"
        else
            [ -z "$MANGEL" ] \
                && gruen "Quellenangabe und Prüfsumme stimmen ($ANZ_Q Seed(s) mit Dateiquelle)" \
                || rot "Quellennachweis mangelhaft:$MANGEL"
        fi

        # --- Prüfung 2: ein genannter Erzeuger existiert auch
        FEHLT=""
        ANZ_E=0
        for SEED in $MIT_QUELLE; do
            E=$(sed -n 's/^-- Erzeugt von: *//p' "$SEED" | head -1)
            [ -n "$E" ] || continue
            ANZ_E=$((ANZ_E + 1))
            ls -1 "$E" > /dev/null 2>&1 || FEHLT="$FEHLT $(basename "$SEED")→$E"
        done
        if [ "$ANZ_E" -eq 0 ]; then
            rot "Fachdaten: kein Seed mit Quelle nennt einen Erzeuger – die Prüfung fand ihre Voraussetzung nicht"
        else
            [ -z "$FEHLT" ] \
                && gruen "jeder genannte Erzeuger existiert ($ANZ_E geprüft)" \
                || rot "Erzeuger fehlt:$FEHLT"
        fi
    fi
fi

# --- Prüfung 3: wo `art` deklariert ist, führt jede Wertezeile sie auch (E18)
# Sport ist das einzige Fach, in dem `inhaltsfeld` zwei Dinge enthält --
# Inhaltsfelder und Bewegungsfelder. `art` hält fest, welches von beiden.
# Bleibt sie in einer Zeile leer, ist der Unterschied wieder nur an der
# Namenskonvention erkennbar, und genau das sollte die Spalte beenden.
#
# Geprüft wird an der Deklaration, nicht an einem Dateinamen (REIHENREGELN 4):
# betroffen ist jeder Seed, dessen Spaltenliste `art` nennt. Seeds ohne die
# Spalte -- Deutsch führt sie nicht -- fallen nicht durch.
MIT_ART=$(grep -l 'INSERT INTO kompetenzbereiche (.*[ (]art[,)]' sql/*.sql 2>/dev/null || true)
if [ -z "$MIT_ART" ]; then
    rot "Fachdaten: kein Seed deklariert die Spalte art – die Prüfung fand ihre Voraussetzung nicht"
else
    LUECKE=""
    ANZ_A=0
    for SEED in $MIT_ART; do
        ANZ_A=$((ANZ_A + 1))
        BEFUND=$(awk '
            # Zählt Felder auf oberster Ebene; SQL-Hochkommata werden dabei
            # beachtet, weil Bereichsnamen selbst Kommata enthalten
            # ("Gleiten, Fahren, Rollen"). Ein verdoppeltes '\''\'''\'' ist
            # ein Zeichen im String, kein Ende.
            function felder(s,   i, c, inq, n) {
                n = 1; inq = 0
                for (i = 1; i <= length(s); i++) {
                    c = substr(s, i, 1)
                    if (c == "'\''") {
                        if (inq && substr(s, i + 1, 1) == "'\''") i++
                        else inq = !inq
                    } else if (c == "," && !inq) n++
                }
                return n
            }
            function feld(s, k,   i, c, inq, n, aus) {
                n = 1; inq = 0; aus = ""
                for (i = 1; i <= length(s); i++) {
                    c = substr(s, i, 1)
                    if (c == "'\''") {
                        if (inq && substr(s, i + 1, 1) == "'\''") { aus = aus "'\''"; i++ }
                        else inq = !inq
                    } else if (c == "," && !inq) { n++; if (n > k) break }
                    else if (n == k) aus = aus c
                }
                gsub(/^[ \t]+|[ \t]+$/, "", aus)
                return aus
            }
            /INSERT INTO kompetenzbereiche \(/ {
                sp = $0
                sub(/.*INSERT INTO kompetenzbereiche \(/, "", sp)
                sub(/\).*/, "", sp)
                spalten = felder(sp)
                artpos = 0
                for (i = 1; i <= spalten; i++) if (feld(sp, i) == "art") artpos = i
                next
            }
            /^\(@rahmen,/ && artpos > 0 {
                z = $0
                sub(/^\(/, "", z); sub(/\)[,;]?[ \t]*$/, "", z)
                if (felder(z) != spalten) { print "Feldzahl " felder(z) " statt " spalten " in Zeile " NR; fehler++ }
                else {
                    w = feld(z, artpos)
                    if (w == "" || w == "NULL") { print "art leer in Zeile " NR; fehler++ }
                }
            }
            END { if (artpos == 0) print "keine Spaltenliste mit art gefunden" }
        ' "$SEED")
        [ -n "$BEFUND" ] && LUECKE="$LUECKE $(basename "$SEED"):$(printf '%s' "$BEFUND" | head -1)"
    done
    [ -z "$LUECKE" ] \
        && gruen "art ist in jeder Bereichszeile gesetzt ($ANZ_A Seed(s) mit art-Spalte)" \
        || rot "art fehlt:$LUECKE"
fi

# --- Prüfung 4: jede Datei mit Fachdaten deklariert eine Quelle (E19/E27)
# Diese Prüfung schliesst das Schlupfloch der Prüfung 1: dort entgeht der
# Kontrolle, wer die "-- Quelle:"-Zeile einfach weglaesst. Erst beide zusammen
# greifen -- die eine verlangt die Deklaration, die andere loest sie ein.
#
# Woran eine Datei Fachdaten fuehrt, entscheidet ihr Inhalt, nicht ihr Name
# (E27, REIHENREGELN 4): Sie schreibt in `kompetenzen` oder `kompetenzbereiche`.
# Der Name waere eine Konvention -- ein kuenftiger Import, der anders heisst,
# entkaeme ihr, und Testdaten mit "seed" im Namen fielen grundlos durch.
#
# Geprueft wird dateiweit, nicht zeilenweise: ein `INSERT INTO`, dessen
# Tabellenname erst in der naechsten Zeile steht, wuerde sonst entgehen.
# Kommentarzeilen werden vorher entfernt, damit der Ausdruck nicht auf die
# Beschreibung der Regel anschlaegt statt auf die Sache (REIHENREGELN 2).
OHNE_QUELLE=""
ANZ_F=0
UNLESBAR=""
for DATEI in sql/*.sql; do
    # Anwesenheit durch Auflisten, nicht durch das Werkzeug daneben
    # (REIHENREGELN 3). Ohne das meldete ein leergelaufenes Muster
    # "ohne Quellenangabe" statt "Datei nicht da" – eine Auskunft in die
    # falsche Richtung.
    if ! ls -1 "$DATEI" > /dev/null 2>&1; then
        UNLESBAR="$UNLESBAR $DATEI"; continue
    fi
    perl -0777 -ne 's{^\s*--.*$}{}gm;
        exit(!(/INSERT\s+(?:IGNORE\s+)?INTO\s+(?:kompetenzen|kompetenzbereiche)\b/is))' \
        "$DATEI" || continue
    ANZ_F=$((ANZ_F + 1))
    grep -q '^-- Quelle:' "$DATEI" || OHNE_QUELLE="$OHNE_QUELLE $(basename "$DATEI")"
done
if [ -n "$UNLESBAR" ]; then
    rot "Fachdaten: Datei nicht lesbar:$UNLESBAR – die Prüfung fand ihre Voraussetzung nicht"
elif [ "$ANZ_F" -eq 0 ]; then
    # Null Funde sind ein Fehler, kein Ergebnis (REIHENREGELN 2).
    rot "Fachdaten: keine Datei mit Fachdaten gefunden – die Prüfung fand ihre Voraussetzung nicht"
else
    [ -z "$OHNE_QUELLE" ] \
        && gruen "jede Datei mit Fachdaten deklariert eine Quelle ($ANZ_F geprüft)" \
        || rot "ohne Quellenangabe:$OHNE_QUELLE"
fi

# --- Prüfungen 5 bis 7: Baumintegrität (E29b, E31)
# Geprüft wird statisch am Seed, nicht gegen die Datenbank: `deploy.sh` führt
# dieses Skript aus, und dort steht keine Datenbank zur Verfügung. Ein Seed
# baut genau einen Rahmen auf, alle parent_id-Verweise liegen also in der
# Datei und lassen sich verfolgen.
#
# LÜCKE, die dazugesagt gehört: Der MKR hat keinen Seed — er wird per UPDATE
# behandelt (Migration 16) und liegt damit außerhalb dieser drei Prüfungen.
# Für ihn gilt die Integrität nur gegen die Datenbank.
BAUM_SEEDS=$(grep -l 'INSERT INTO kompetenzbereiche (rahmen_id, parent_id' sql/*.sql 2>/dev/null || true)
if [ -z "$BAUM_SEEDS" ]; then
    rot "Baum: kein Seed baut einen Baum – die Prüfung fand ihre Voraussetzung nicht"
    rot "Baum: keine Zyklusprüfung möglich – die Prüfung fand ihre Voraussetzung nicht"
    rot "Baum: keine art-Prüfung möglich – die Prüfung fand ihre Voraussetzung nicht"
else
    FREMD=""; ZYKLUS=""; OHNE_ART=""; ANZ_B=0
    for SEED in $BAUM_SEEDS; do
        ANZ_B=$((ANZ_B + 1))
        BEFUND=$(awk '
            # Wurzelzeile:  (@rahmen, NULL, CODE, NAME, N, PHASE, ART)
            /^\(@rahmen, NULL, / {
                if (match($0, /'"'"'[A-Z][A-Z0-9_]*'"'"'/)) {
                    c = substr($0, RSTART+1, RLENGTH-2); ist_knoten[c] = 1
                    n = split($0, f, /'"'"', '"'"'/)
                    art = f[n]; sub(/'"'"'\).*/, "", art)
                    if (art == "" || art == "NULL") print "art fehlt an Wurzel " c
                }
                next
            }
            # Blattzeile:  SELECT CODE AS code, ... ART AS art, PCODE AS pcode
            /AS code,/ && /AS pcode/ {
                if (match($0, /SELECT '"'"'[A-Z][A-Z0-9_]*'"'"'/)) {
                    c = substr($0, RSTART+8, RLENGTH-9); ist_knoten[c] = 1
                }
                if (match($0, /'"'"'[a-z_]+'"'"' AS art/)) {
                    a = substr($0, RSTART+1, RLENGTH-9); gsub(/'"'"' *$/, "", a)
                    if (a == "") print "art fehlt an Blatt " c
                } else print "art fehlt an Blatt " c
                if (match($0, /'"'"'[A-Z][A-Z0-9_]*'"'"' AS pcode/)) {
                    p = substr($0, RSTART+1, RLENGTH-11); gsub(/'"'"' *$/, "", p)
                    eltern[c] = p
                }
                next
            }
            END {
                for (c in eltern) {
                    if (!(eltern[c] in ist_knoten))
                        print "Elternknoten fremd oder unbekannt: " c " -> " eltern[c]
                    # Zyklus: vom Knoten aus die Elternkette verfolgen
                    k = c; tiefe = 0
                    while (k in eltern && tiefe < 50) {
                        k = eltern[k]; tiefe++
                        if (k == c) { print "Zyklus ueber " c; break }
                    }
                    if (tiefe >= 50) print "Elternkette zu tief ab " c
                }
            }' "$SEED")
        printf '%s' "$BEFUND" | grep -q 'fremd oder unbekannt' && FREMD="$FREMD $(basename "$SEED")"
        printf '%s' "$BEFUND" | grep -qE 'Zyklus|zu tief'       && ZYKLUS="$ZYKLUS $(basename "$SEED")"
        printf '%s' "$BEFUND" | grep -q 'art fehlt'             && OHNE_ART="$OHNE_ART $(basename "$SEED")"
    done
    [ -z "$FREMD" ] \
        && gruen "jeder Elternknoten liegt im selben Rahmen ($ANZ_B Seed(s) mit Baum)" \
        || rot "Elternknoten fremd:$FREMD"
    [ -z "$ZYKLUS" ] \
        && gruen "kein Knoten ist sein eigener Vorfahre ($ANZ_B geprüft)" \
        || rot "Zyklus im Baum:$ZYKLUS"
    [ -z "$OHNE_ART" ] \
        && gruen "art ist an jedem Knoten gesetzt ($ANZ_B geprüft)" \
        || rot "art fehlt an einem Knoten:$OHNE_ART"
fi

echo ""
echo "Kompetenzauswahl"
# Prüfung 1: KAT_PHASEN deckt jeden ENUM-Wert von kompetenzbereiche.phase ab.
#
# Der Fehler, den das fängt: Migration 14 legte `sek1_uebergreifend` an, das
# Frontend kannte den Wert nicht, und `phasenPresent` filterte ihn still weg —
# 21 Kompetenzerwartungen ohne Tab, ohne Etikett, über den Filter nicht
# erreichbar. Ein Test auf Vorhandensein einer Zeile fängt das nicht; geprüft
# wird die VERBINDUNG zwischen Migration und Frontend (REIHENREGELN 2).
MIG_PHASE=$(ls -1 sql/*_migration_phase_*.sql 2>/dev/null | tail -1)
if [ -z "$MIG_PHASE" ] || [ ! -f "$MIG_PHASE" ]; then
    rot "Phasen: keine Phasen-Migration gefunden – die Prüfung fand ihre Voraussetzung nicht"
else
    ENUM_WERTE=$(sed -n '/MODIFY COLUMN phase/,/) NULL/p' "$MIG_PHASE" \
        | grep -oE "'[a-z0-9_]+'" | tr -d "'" | sort -u)
    JS_WERTE=$(sed -n '/^const KAT_PHASEN = \[/,/^\];/p' frontend/app.js \
        | grep -oE "key: '[a-z0-9_]+'" | sed "s/key: '//;s/'//" | sort -u)
    if [ -z "$ENUM_WERTE" ] || [ -z "$JS_WERTE" ]; then
        # Null Funde sind ein Fehler, kein Ergebnis (REIHENREGELN 2).
        rot "Phasen: ENUM-Werte oder KAT_PHASEN nicht lesbar – die Prüfung fand ihre Voraussetzung nicht"
    else
        FEHLEND=$(comm -23 <(printf '%s\n' "$ENUM_WERTE") <(printf '%s\n' "$JS_WERTE") | tr '\n' ' ')
        ZUVIEL=$(comm -13 <(printf '%s\n' "$ENUM_WERTE") <(printf '%s\n' "$JS_WERTE") | tr '\n' ' ')
        ANZ_P=$(printf '%s\n' "$ENUM_WERTE" | wc -l | tr -d ' ')
        if [ -n "$FEHLEND" ]; then
            rot "KAT_PHASEN fehlt ein ENUM-Wert: $FEHLEND"
        elif [ -n "$ZUVIEL" ]; then
            rot "KAT_PHASEN kennt einen Wert, den der ENUM nicht führt: $ZUVIEL"
        else
            gruen "KAT_PHASEN deckt alle $ANZ_P ENUM-Werte der Phase ab"
        fi
    fi
fi

# Prüfung 2: `kat-fach` ist verschwunden (E32).
# Zwei unabhängige Und-Filter konnten einander widerlegen; das Fachfeld
# entfällt, `kat-rahmen` führt die gruppierte Liste.
TREFFER=$(grep -rl 'kat-fach' frontend/ 2>/dev/null | tr '\n' ' ')
[ -z "$TREFFER" ] \
    && gruen "kat-fach kommt in frontend/ nicht mehr vor" \
    || rot "kat-fach noch vorhanden in: $TREFFER"

echo ""
echo "Teilnehmer"
# ------------------------------------------------------------------
# Befund: Teilnehmer waren nach dem Anlegen unveränderlich. Der PUT-Zweig
# las `projekt_schueler` (für die Kompetenzen), schrieb aber nie hinein.
# E34 und E35 entscheiden, wie er es jetzt tut.
#
# Beide Prüfungen laufen NUR über den PUT-Zweig, nicht über die ganze
# Datei: Im POST-Zweig steht `schueler_ids` seit jeher, ein Ausdruck über
# index.php insgesamt wäre also von Anfang an grün gewesen -- und hätte den
# Befund nie gefangen.
#
# Und sie laufen über den Zweig OHNE Kommentare. Die Regeln sind dort in
# Prosa erklärt, samt `?? []` und `schueler_ids`; ein ungeankerter Ausdruck
# träfe die Erklärung statt der Sache (REIHENREGELN 2). Gegenprobe dazu:
# den Code löschen, den Kommentar stehen lassen -- die Prüfung muss rot
# werden.
# ------------------------------------------------------------------
API=backend/api/index.php
if [ ! -f "$API" ]; then
    rot "$API fehlt"
    rot "$API fehlt (zweite Teilnehmerprüfung nicht ausführbar)"
else
    PUT_ZWEIG=$(awk '/\/\/ ----- PUT \/projekte\/\{id\} -----/,/\/\/ ----- DELETE \/projekte\/\{id\} -----/' "$API" \
        | perl -0777 -pe 's{/\*.*?\*/}{}gs' | grep -v '^[[:space:]]*//')

    if [ -z "$PUT_ZWEIG" ]; then
        # Ohne Voraussetzung gilt eine Prüfung nicht als bestanden, sie sagt
        # es (REIHENREGELN 2). Ein leerer Zweig sähe sonst sauber aus.
        rot "PUT-Zweig in $API nicht gefunden – Markierungskommentare geändert?"
        rot "PUT-Zweig in $API nicht gefunden (zweite Teilnehmerprüfung nicht ausführbar)"
    else
        # Prüfung 1: Der PUT-Zweig wertet `schueler_ids` aus UND schreibt
        # damit `projekt_schueler`. Lesen allein genügt nicht -- genau das
        # tat er vorher schon.
        P1_LIEST=$(printf '%s' "$PUT_ZWEIG" | grep -c "body\['schueler_ids'\]" || true)
        P1_FUEGT=$(printf '%s' "$PUT_ZWEIG" | grep -c "INSERT IGNORE INTO projekt_schueler " || true)
        P1_LOEST=$(printf '%s' "$PUT_ZWEIG" | grep -c "DELETE FROM projekt_schueler " || true)
        if [ "$P1_LIEST" -gt 0 ] && [ "$P1_FUEGT" -gt 0 ] && [ "$P1_LOEST" -gt 0 ]; then
            gruen "PUT-Zweig wertet schueler_ids aus und schreibt projekt_schueler"
        else
            rot "PUT-Zweig ändert die Teilnehmer nicht (liest=$P1_LIEST, fügt=$P1_FUEGT, löscht=$P1_LOEST)"
        fi

        # Prüfung 2: Fehlendes Feld und leere Liste werden unterschieden.
        # `isset` muss da sein UND `?? []` darf nicht danebenstehen -- die
        # Anwesenheit der richtigen Form schliesst die falsche nicht aus
        # (REIHENREGELN 2). Mit `?? []` würde ein Aufrufer, der das Feld
        # vergisst, die Werkstatt leeren.
        P2_ISSET=$(printf '%s' "$PUT_ZWEIG" | grep -c "isset(\$body\['schueler_ids'\])" || true)
        P2_FALSCH=$(printf '%s' "$PUT_ZWEIG" | grep -c "body\['schueler_ids'\][[:space:]]*??" || true)
        if [ "$P2_ISSET" -gt 0 ] && [ "$P2_FALSCH" -eq 0 ]; then
            gruen "PUT-Zweig unterscheidet fehlendes schueler_ids von leerer Liste"
        elif [ "$P2_FALSCH" -gt 0 ]; then
            rot "PUT-Zweig macht mit ?? [] aus 'nicht geschickt' ein 'alle entfernen'"
        else
            rot "PUT-Zweig prüft schueler_ids nicht mit isset()"
        fi
    fi
fi

echo ""
echo "Maskierung"
# ------------------------------------------------------------------
# `werkstatt_rueckmeldungen.freitext` war das einzige Textfeld, das weder
# beim Schreiben noch bei der Ausgabe maskiert wurde. Ausgegeben wird er an
# zwei Stellen roh in innerHTML -- eine davon das Schülerportal.
#
# Maskiert wird genau EINMAL, bei der Ausgabe. Die drei Prüfungen sichern
# beide Hälften dieser Festlegung: dass dort maskiert wird, und dass es
# beim Schreiben NICHT geschieht. Zweimal maskieren ist kein Sicherheits-
# gewinn, sondern ein Anzeigefehler: aus "Toll & gut" würde "Toll &amp; gut".
#
# Alle drei laufen über den Quelltext OHNE Kommentare -- die Erklärung
# dieser Regel steht in denselben Dateien und enthält ihre eigenen
# Stichwörter (REIHENREGELN 2).
# ------------------------------------------------------------------
API=backend/api/index.php
JS_OHNE=$(perl -0777 -pe 's{/\*.*?\*/}{}gs' "$JS" | grep -v '^[[:space:]]*//')
PHP_OHNE=$(perl -0777 -pe 's{/\*.*?\*/}{}gs' "$API" | grep -v '^[[:space:]]*//')

# Prüfung 1: beide Ausgabestellen maskieren, keine roh
ESC=$(printf '%s' "$JS_OHNE" | grep -c 'escHtml(r\.freitext)' || true)
ROH=$(printf '%s' "$JS_OHNE" | grep -c '${r\.freitext}' || true)
if [ "$ESC" -eq 2 ] && [ "$ROH" -eq 0 ]; then
    gruen "freitext wird an beiden Ausgabestellen maskiert"
else
    rot "freitext-Ausgabe: $ESC maskiert (erwartet 2), $ROH roh (erwartet 0)"
fi

# Prüfung 2: escHtml maskiert alle fünf Zeichen, und & zuerst.
# Stünde & nicht zuerst, machte die Funktion aus einem erzeugten &lt;
# ein &amp;lt; -- die Maskierung wäre kaputt, ohne dass ein Zeichen fehlte.
ESC_RUMPF=$(printf '%s' "$JS_OHNE" | awk '/^function escHtml\(/{an=1} an{print} an&&/^}/{exit}')
if [ -z "$ESC_RUMPF" ]; then
    rot "escHtml() nicht gefunden"
else
    FEHLT=""
    for PAAR in '/&/g:&amp;' '/</g:&lt;' '/>/g:&gt;' '/"/g:&quot;' "/'/g:&#39;"; do
        MUSTER="${PAAR%%:*}"; ERSATZ="${PAAR##*:}"
        printf '%s' "$ESC_RUMPF" | grep -qF "replace($MUSTER, '$ERSATZ')" || FEHLT="$FEHLT $MUSTER"
    done
    POS_AMP=$(printf '%s' "$ESC_RUMPF" | grep -nF "replace(/&/g" | head -1 | cut -d: -f1)
    POS_LT=$(printf '%s' "$ESC_RUMPF" | grep -nF "replace(/</g" | head -1 | cut -d: -f1)
    if [ -n "$FEHLT" ]; then
        rot "escHtml maskiert nicht:$FEHLT"
    elif [ -z "$POS_AMP" ] || [ -z "$POS_LT" ] || [ "$POS_AMP" -ge "$POS_LT" ]; then
        rot "escHtml ersetzt & nicht als erstes – die Maskierung maskiert sich selbst"
    else
        gruen "escHtml maskiert & < > \" ' und & als erstes"
    fi
fi

# Prüfung 3: beim Schreiben wird NICHT maskiert.
# Das ist die Gegenrichtung: Die Anwesenheit der Ausgabemaskierung schliesst
# eine zweite beim Schreiben nicht aus.
DOPPELT=$(printf '%s' "$PHP_OHNE" | grep -c "clean(\$body\['freitext'\]\|clean(\$freitext" || true)
[ "$DOPPELT" -eq 0 ] \
    && gruen "freitext wird beim Schreiben nicht zusätzlich maskiert" \
    || rot "freitext wird zweimal maskiert – Anzeigefehler statt Sicherheitsgewinn"

echo ""
echo "Zugehoerigkeit und Konfiguration"
# ------------------------------------------------------------------
# Drei Pruefungen zu E36 (Teilnahmepruefung bei Rueckmeldungen),
# E38 (Klassenzuordnung im PUT) und dem Konfigurationsabgleich.
# Alle drei arbeiten auf dem Quelltext OHNE Kommentare -- die Regeln sind
# in denselben Dateien in Prosa erklaert (REIHENREGELN 2).
# ------------------------------------------------------------------
API=backend/api/index.php
if [ ! -f "$API" ]; then
    rot "$API fehlt"
    rot "$API fehlt (zweite Pruefung nicht ausfuehrbar)"
else
    # Pruefung 1: POST /rueckmeldung prueft die Teilnahme, und zwar VOR dem
    # Schreiben. Gemessen wird die Abfrage gegen projekt_schueler plus der
    # Abbruch -- die blosse Anwesenheit eines der beiden genuegt nicht.
    # Zuerst den Zweig aus der DATEI schneiden, dann die Kommentare
    # entfernen -- nicht umgekehrt. Die Markierung des PUT-Zweigs ist selbst
    # ein Kommentar; wer erst entkommentiert, sucht sie danach vergeblich.
    # Genau daran ist die Klassenpruefung beim ersten Lauf rot geworden.
    RM_ZWEIG=$(awk '/function handle_rueckmeldung/{an=1} an{print} an&&/^}/{exit}' "$API" \
               | perl -0777 -pe 's{/\*.*?\*/}{}gs' | grep -v '^[[:space:]]*//')
    if [ -z "$RM_ZWEIG" ]; then
        rot "handle_rueckmeldung nicht gefunden"
    else
        # Gemessen wird die REIHENFOLGE, nicht nur das Vorkommen: Abfrage
        # gegen projekt_schueler, dann der Abbruch, dann erst das INSERT.
        # Stuende der Abbruch dahinter, waeren schon Zeilen geschrieben.
        # Dazu die Waechterbedingung selbst -- sonst bliebe die Pruefung
        # gruen, wenn jemand sie zu `if (false)` entwertet.
        P_ABFRAGE=$(printf '%s\n' "$RM_ZWEIG" | grep -n "FROM projekt_schueler" | head -1 | cut -d: -f1)
        P_ABBRUCH=$(printf '%s\n' "$RM_ZWEIG" | grep -n "json_error" | awk -F: -v a="${P_ABFRAGE:-0}" '$1>a{print $1; exit}')
        P_INSERT=$(printf '%s\n' "$RM_ZWEIG" | grep -n "INSERT INTO werkstatt_rueckmeldungen" | head -1 | cut -d: -f1)
        P_WAECHTER=$(printf '%s' "$RM_ZWEIG" | grep -c 'if (!empty($fremde))' || true)
        if [ -z "$P_ABFRAGE" ] || [ -z "$P_ABBRUCH" ] || [ -z "$P_INSERT" ]; then
            rot "POST /rueckmeldung: Abfrage, Abbruch oder INSERT nicht gefunden"
        elif [ "$P_WAECHTER" -eq 0 ]; then
            rot "POST /rueckmeldung: die Waechterbedingung auf \$fremde fehlt"
        elif [ "$P_ABFRAGE" -lt "$P_ABBRUCH" ] && [ "$P_ABBRUCH" -lt "$P_INSERT" ]; then
            gruen "POST /rueckmeldung prueft die Teilnahme vor dem Schreiben"
        else
            rot "POST /rueckmeldung prueft nicht vor dem Schreiben (Abfrage=$P_ABFRAGE, Abbruch=$P_ABBRUCH, INSERT=$P_INSERT)"
        fi
    fi

    # Pruefung 2: Der PUT-Zweig wertet klasse_ids aus, mit isset statt ?? [].
    # Dieselbe Form wie bei schueler_ids (E35).
    PUT_ZWEIG=$(awk '/\/\/ ----- PUT \/projekte\/\{id\} -----/,/\/\/ ----- DELETE \/projekte\/\{id\} -----/' "$API" \
                | perl -0777 -pe 's{/\*.*?\*/}{}gs' | grep -v '^[[:space:]]*//')
    if [ -z "$PUT_ZWEIG" ]; then
        rot "PUT-Zweig nicht gefunden (Klassenpruefung nicht ausfuehrbar)"
    else
        K_ISSET=$(printf '%s' "$PUT_ZWEIG" | grep -c "isset(\$body\['klasse_ids'\])" || true)
        K_SCHREIBT=$(printf '%s' "$PUT_ZWEIG" | grep -c "INTO projekt_klassen" || true)
        K_LOESCHT=$(printf '%s' "$PUT_ZWEIG" | grep -c "DELETE FROM projekt_klassen" || true)
        K_FALSCH=$(printf '%s' "$PUT_ZWEIG" | grep -c "body\['klasse_ids'\][[:space:]]*??" || true)
        if [ "$K_FALSCH" -gt 0 ]; then
            rot "PUT-Zweig macht mit ?? [] aus 'nicht geschickt' ein 'alle entfernen'"
        elif [ "$K_ISSET" -gt 0 ] && [ "$K_SCHREIBT" -gt 0 ] && [ "$K_LOESCHT" -gt 0 ]; then
            gruen "PUT-Zweig aendert projekt_klassen und unterscheidet fehlendes Feld"
        else
            rot "PUT-Zweig aendert die Klassen nicht (isset=$K_ISSET, fuegt=$K_SCHREIBT, loescht=$K_LOESCHT)"
        fi
    fi
fi

# Pruefung 3: config.php fuehrt jede Konstante und jede globale Variable aus
# config.example.php.
#
# NUR NAMEN, KEINE WERTE. Die Datei enthaelt das Datenbankpasswort; sie wird
# gelesen, aber keine ihrer Zeilen wird ausgegeben -- gemeldet werden
# ausschliesslich die Namen aus der Beispieldatei, die dort fehlen.
#
# Was sie nicht kann: abweichende WERTE sehen. Genau daran ist die
# Konfiguration zuletzt auseinandergelaufen (secure=false gegen true). Das
# waere nur mit einer Inhaltspruefung zu fangen, und die ist bei einer Datei
# mit Zugangsdaten der falsche Weg.
BSP=backend/config.example.php
CFG=backend/config.php
if [ ! -f "$BSP" ]; then
    rot "$BSP fehlt – Voraussetzung der Konfigurationspruefung"
elif [ ! -f "$CFG" ]; then
    rot "$CFG fehlt – Voraussetzung der Konfigurationspruefung, nicht bestanden"
else
    NAMEN=$(perl -0777 -pe 's{/\*.*?\*/}{}gs' "$BSP" | grep -v '^[[:space:]]*//' \
            | grep -oE "define\('[A-Z_0-9]+'|^\\\$[A-Za-z_][A-Za-z_0-9]*" \
            | sed "s/define('//;s/'$//" | sort -u)
    ANZ=$(printf '%s\n' "$NAMEN" | grep -c . || true)
    CFG_OHNE=$(perl -0777 -pe 's{/\*.*?\*/}{}gs' "$CFG" | grep -v '^[[:space:]]*//')
    if [ "$ANZ" -eq 0 ]; then
        rot "keine Namen in $BSP gefunden – die Pruefung prueft nichts"
    else
        FEHLT=""
        for N in $NAMEN; do
            case "$N" in
                \$*) printf '%s' "$CFG_OHNE" | grep -qF "$N" || FEHLT="$FEHLT $N" ;;
                *)   printf '%s' "$CFG_OHNE" | grep -qF "define('$N'" || FEHLT="$FEHLT $N" ;;
            esac
        done
        [ -z "$FEHLT" ] \
            && gruen "config.php fuehrt alle $ANZ Namen aus config.example.php" \
            || rot "config.php fehlen Namen aus config.example.php:$FEHLT"
    fi
fi

echo ""
echo "Roh gespeicherte Felder bei der Ausgabe"
# ------------------------------------------------------------------
# E41: Namen und Klassenbezeichnungen stehen roh in der Datenbank -- Import
# und WebUntis-Selbstanlage schreiben sie ohne clean(), und seit E41 tut es
# auch die Handanlage nicht mehr. Maskiert wird bei der Ausgabe.
#
# Die Liste unten fuehrt nicht "Namen", sondern ROH GESPEICHERTE FELDER. Dazu
# gehoert seit dem Befund aus 1b7a7a7 auch `dateiname`: Der Name der
# hochgeladenen Datei geht ungefiltert aus $_FILES in `import_log` und von
# dort in die Anzeige -- dieselbe Bauform wie E42, nur ueber die Datenbank
# und damit dauerhaft.
#
# Erweitert wurde die Liste, nicht die Zahl der Pruefungen: Es ist dieselbe
# Regel (einmal maskieren, bei der Ausgabe) und derselbe Mechanismus
# (Ablehnung als Standard, Vermerk als Ausnahme). Eine zweite Pruefung mit
# eigener Feldliste haette dieselbe Sache an zwei Orten entschieden -- und
# das naechste roh gespeicherte Feld haette die Frage ein drittes Mal
# gestellt.
#
# Die Pruefung lehnt ab, was sie nicht kennt: Jede Einbettung eines
# Namenstraegers muss entweder durch escHtml() laufen oder die Zeile traegt
# den Vermerk `${/* keine-maskierung: <Grund> */ ...}`. Eine neu
# hinzugefuegte rohe Einbettung faellt also durch, ohne dass jemand die
# Pruefung anfassen muss.
#
# WAS SIE NICHT FAENGT -- drei Luecken, benannt statt verschwiegen (E41):
#
#   1. Einen neuen ALIAS. Die Pruefung kennt die Feldnamen, die hier stehen.
#      Genau daran ist die erste Zaehlung gescheitert: ${s.klasse} ist
#      `klassen.bezeichnung`, und keine Suche nach "bezeichnung" findet es.
#      Benennt eine kuenftige API-Antwort ein Feld anders, bleibt die Stelle
#      unsichtbar. Das ist die ernsteste Luecke; ein statisches Mittel
#      dagegen ist nicht bekannt.
#   2. Den UMWEG UEBER EINE VARIABLE. `const n = s.vorname; ... ${n}` wird
#      nicht gesehen. Das Muster gibt es bereits (app.js, Suchzeichenkette).
#   3. Die FALSCHE WAHL. Wer ein Feld maskiert, das bereits maskiert
#      gespeichert ist, erzeugt &amp;amp; und kommt hier gruen durch.
#      Dagegen hilft nur die Handpruefung.
#
# Die Entwertung von escHtml selbst ist abgedeckt -- die Pruefung in der
# Rubrik "Maskierung" verlangt alle fuenf Ersetzungen und & als erste.
# ------------------------------------------------------------------
if [ ! -f "$JS" ]; then
    rot "$JS fehlt – Voraussetzung der Namenspruefung"
else
    NAMEN_BERICHT=$(perl -ne '
        BEGIN { $traeger = qr/(?:vorname|nachname|bezeichnung|klassenlehrer|\.klasse\b|schuljahr|lernbegleiter|dateiname)/;
                $gesamt = 0; $offen = 0; }
        my $zeile = $_;
        my $vermerkt = ($zeile =~ /\$\{\/\* keine-maskierung:/);
        while ($zeile =~ /\$\{((?:[^{}]|\{[^{}]*\})*)\}/g) {
            my $a = $1;
            next unless $a =~ $traeger;
            $gesamt++;
            next if $a =~ /escHtml/ or $vermerkt;
            $offen++;
            print "    Zeile $.: $a\n";
        }
        END { print "ZAHLEN $gesamt $offen\n"; }
    ' "$JS")
    NAMEN_GESAMT=$(printf '%s\n' "$NAMEN_BERICHT" | awk '/^ZAHLEN/{print $2}')
    NAMEN_OFFEN=$(printf '%s\n' "$NAMEN_BERICHT" | awk '/^ZAHLEN/{print $3}')
    if [ "${NAMEN_GESAMT:-0}" -eq 0 ]; then
        # Null Funde sind ein Fehler, kein Ergebnis (REIHENREGELN 2).
        rot "keine einzige Einbettung eines roh gespeicherten Feldes in $JS gefunden – die Pruefung prueft nichts"
    elif [ "${NAMEN_OFFEN:-1}" -eq 0 ]; then
        gruen "alle $NAMEN_GESAMT Einbettungen roh gespeicherter Felder maskiert oder begruendet"
    else
        rot "$NAMEN_OFFEN von $NAMEN_GESAMT Einbettungen roh gespeicherter Felder weder maskiert noch begruendet:"
        printf '%s\n' "$NAMEN_BERICHT" | grep -v '^ZAHLEN'
    fi
fi

echo ""
echo "Wer gehoert zur Werkstatt"
# ------------------------------------------------------------------
# E39: `projekt_schueler` ist die Antwort. `projekt_klassen` sagt, woher
# Kandidaten kommen, `projekt_schueler_kompetenzen`, was zugewiesen ist --
# keines von beiden sagt, wer dabei ist.
#
# Beide Pruefungen arbeiten auf dem Quelltext OHNE Kommentare: Die Regel ist
# in denselben Dateien in Prosa erklaert, samt ihrer Stichwoerter
# (REIHENREGELN 2).
#
# Sie lesen je EINE Datei, und das ist hier richtig: Den Endpunkt gibt es nur
# in backend/api/index.php, die Bewertungsansicht nur in frontend/app.js.
# Gesagt sei es trotzdem -- eine bestandene Pruefung verraet nicht, wo sie
# hingesehen hat (REIHENREGELN 2).
# ------------------------------------------------------------------
API=backend/api/index.php
if [ ! -f "$API" ]; then
    rot "$API fehlt – Voraussetzung der Abschlusspruefung"
else
    # Nur der Einzelschueler-Zweig. Der `alle`-Zweig darueber schreibt
    # ebenfalls in projekt_schueler und wuerde jede Reihenfolgemessung
    # verfaelschen.
    ABS_ZWEIG=$(awk "/if \\(\\\$method === 'PUT' && \\\$sub === 'abschluss'\\)/,/Unbekannte Werkstatt-Aktion/" "$API" \
                | perl -0777 -pe 's{/\*.*?\*/}{}gs' | grep -v '^[[:space:]]*//')
    P_START=$(printf '%s\n' "$ABS_ZWEIG" | grep -n "body\['schueler_id'\]" | head -1 | cut -d: -f1)
    if [ -z "$P_START" ]; then
        rot "Einzelschueler-Zweig von PUT /abschluss nicht gefunden"
    else
        P_CHK=$(printf '%s\n' "$ABS_ZWEIG" | grep -n "FROM projekt_schueler" | awk -F: -v a="$P_START" '$1>a{print $1; exit}')
        P_ERR=$(printf '%s\n' "$ABS_ZWEIG" | grep -n "json_error" | awk -F: -v a="${P_CHK:-0}" '$1>a{print $1; exit}')
        P_UPD=$(printf '%s\n' "$ABS_ZWEIG" | grep -n "UPDATE projekt_schueler" | awk -F: -v a="$P_START" '$1>a{print $1; exit}')
        P_WAECHTER=$(printf '%s' "$ABS_ZWEIG" | grep -c 'if (!$chk->fetch())' || true)
        if [ -z "$P_CHK" ] || [ -z "$P_ERR" ] || [ -z "$P_UPD" ]; then
            rot "PUT /abschluss: Abfrage, Abbruch oder UPDATE nicht gefunden"
        elif [ "$P_WAECHTER" -eq 0 ]; then
            rot "PUT /abschluss: die Waechterbedingung auf \$chk fehlt"
        elif [ "$P_CHK" -lt "$P_ERR" ] && [ "$P_ERR" -lt "$P_UPD" ]; then
            gruen "PUT /abschluss prueft die Teilnahme vor dem Schreiben"
        else
            rot "PUT /abschluss prueft nicht vor dem Schreiben (Abfrage=$P_CHK, Abbruch=$P_ERR, UPDATE=$P_UPD)"
        fi
    fi
fi

# Die Bewertungstabelle nimmt ihre ZEILEN aus den Teilnehmern, nicht aus den
# Bewertungszeilen. Der tragende Teil ist, dass `schuelerMap` verschwunden
# ist: Solange die Schueler aus `bewertungen` zusammengesucht werden, fehlt
# jeder Teilnehmer ohne zugewiesene Kompetenz -- und ist damit weder
# bewertbar noch Empfaenger einer Rueckmeldung.
if [ ! -f "$JS" ]; then
    rot "$JS fehlt – Voraussetzung der Bewertungstabellenpruefung"
else
    BEW_FKT=$(awk '/^async function ladeBewertungTabelle\(/{an=1} an{print} an&&/^}/{exit}' "$JS" \
              | perl -0777 -pe 's{/\*.*?\*/}{}gs' | grep -v '^[[:space:]]*//')
    if [ -z "$BEW_FKT" ]; then
        rot "ladeBewertungTabelle nicht gefunden"
    else
        B_HOLT=$(printf '%s' "$BEW_FKT" | grep -c 'werkstatt/${projekt_id}/schueler' || true)
        B_ZEILEN=$(printf '%s' "$BEW_FKT" | grep -c 'teilnehmer || \[\]' || true)
        B_ALT=$(printf '%s' "$BEW_FKT" | grep -c 'schuelerMap' || true)
        if [ "$B_ALT" -gt 0 ]; then
            rot "Bewertungstabelle sammelt die Schueler noch aus den Bewertungszeilen (schuelerMap)"
        elif [ "$B_HOLT" -gt 0 ] && [ "$B_ZEILEN" -gt 0 ]; then
            gruen "Bewertungstabelle nimmt ihre Zeilen aus den Teilnehmern"
        else
            rot "Bewertungstabelle liest die Teilnehmer nicht (holt=$B_HOLT, Zeilen=$B_ZEILEN)"
        fi
    fi
fi

echo ""
echo "Kaestchen"
# ------------------------------------------------------------------
# `input,select,textarea{width:100%}` gilt fuer `input` ohne Ansehen des Typs
# und macht aus einem Kaestchen einen Balken -- in der Rueckmeldungsansicht
# 348 statt 13 Pixel, gemessen. Zwei Stellen hatten das von Hand mit
# `width:16px` im style-Attribut ausgeglichen; die Regel loest beides ab.
#
# Zwei Haelften, eine Pruefung: Die Regel muss es geben, UND kein Kaestchen
# darf eine eigene Breite tragen. Die zweite Haelfte ist die tragende -- sie
# ist es, die die Regel zur einzigen Wahrheit macht. Eine Pruefung nur auf
# "die Regel gibt es" ginge gruen, waehrend daneben drei Einzelangaben
# stehen.
#
# Gesucht wird im ganzen Verzeichnis `frontend/`, nicht in den zwei Dateien,
# in denen die Kaestchen heute stehen (REIHENREGELN 2, v1.9.0). Das vendorte
# Modul fuehrt keine Kaestchenregel -- nachgesehen, nicht angenommen.
#
# Der Ausdruck laeuft ueber das CSS OHNE Kommentare: Der Kommentar an der
# Regel nennt `width:16px;height:16px` als Zitat der alten Einzelangaben und
# wuerde sonst selbst als Fund gelten.
# ------------------------------------------------------------------
if [ ! -f "$CSS" ]; then
    rot "$CSS fehlt – Voraussetzung der Kaestchenpruefung"
else
    CSS_OHNE=$(perl -0777 -pe 's{/\*.*?\*/}{}gs' "$CSS")
    REGEL=$(printf '%s' "$CSS_OHNE" | grep -c 'input\[type=checkbox\][^{]*{[^}]*width:' || true)
    # Ausdruecklich nach der falschen Fassung suchen, nicht nur nach der
    # richtigen (REIHENREGELN 2): `input[type=checkbox]{width:100%}` wuerde
    # die erste Haelfte erfuellen und den Fehler wieder einbauen.
    FALSCH=$(printf '%s' "$CSS_OHNE" | grep -c 'input\[type=checkbox\][^{]*{[^}]*width:[[:space:]]*100%' || true)
    # Kaestchen und Radios mit eigener Breite, im ganzen frontend/
    EIGEN=$(find frontend -type f \( -name '*.html' -o -name '*.js' \) -print0 \
            | xargs -0 perl -0777 -ne '
                while (/<input[^>]*type=["\x27]?(?:checkbox|radio)[^>]*>/gs) {
                    my $t = $&;
                    print "$ARGV\n" if $t =~ /width\s*:/;
                }' | sort -u)
    ANZ_EIGEN=$(printf '%s' "$EIGEN" | grep -c . || true)
    if [ "$REGEL" -eq 0 ]; then
        rot "keine Regel input[type=checkbox]{…width…} in $CSS – Kaestchen erben width:100%"
    elif [ "$FALSCH" -gt 0 ]; then
        rot "die Kaestchenregel setzt selbst width:100% – der Fehler ist zurueck"
    elif [ "$ANZ_EIGEN" -gt 0 ]; then
        rot "Kaestchen mit eigener Breite in: $(printf '%s' "$EIGEN" | tr '\n' ' ')"
    else
        gruen "Kaestchen: eine Regel im CSS, keine Einzelangabe im Bestand"
    fi
fi

echo ""
echo "Fehlerliste der Import-Vorschau"
# ------------------------------------------------------------------
# E44: Das Frontend las ein Feld `meldung`, das es nicht gibt; das Backend
# liefert `zeile`, `grund` und `daten`. Der Rueckfall gab das ganze Objekt
# aus -- "12: [object Object]".
#
# Die naheliegende Behebung ist die Falle: `daten` ist Inhalt der
# hochgeladenen Datei und darf nicht roh eingebettet werden. Die Pruefung aus
# E41 fasst den Fall nicht, weil `daten` kein Namenstraeger ist.
#
# Gemessen wird deshalb feldweise: JEDES Vorkommen von `f.daten` und
# `f.grund` in impVorschau muss unmittelbar in escHtml stehen. Das faengt
# auch den Umweg ueber eine Zwischenvariable -- anders als ein Ausdruck, der
# nur nach `${f.` in der Vorlage sucht.
#
# WAS SIE NICHT FAENGT: eine Umbenennung des Feldes. Traegt das Backend den
# Rohtext kuenftig als `rohzeile` aus, kennt die Pruefung den Namen nicht.
# Das ist dieselbe Luecke wie bei E41 und mit einem statischen Mittel nicht
# zu schliessen.
# ------------------------------------------------------------------
if [ ! -f "$JS" ]; then
    rot "$JS fehlt – Voraussetzung der Fehlerlistenpruefung"
else
    VOR_FKT=$(awk '/^async function impVorschau\(/{an=1} an{print} an&&/^}/{exit}' "$JS" \
              | perl -0777 -pe 's{/\*.*?\*/}{}gs' | grep -v '^[[:space:]]*//')
    if [ -z "$VOR_FKT" ]; then
        rot "impVorschau nicht gefunden"
    else
        ALT=$(printf '%s' "$VOR_FKT" | grep -c 'f\.meldung' || true)
        OFFEN=""
        for FELD in daten grund; do
            GES=$(printf '%s' "$VOR_FKT" | grep -o "f\.$FELD" | grep -c . || true)
            ESC=$(printf '%s' "$VOR_FKT" | grep -o "escHtml(f\.$FELD" | grep -c . || true)
            [ "$GES" -eq 0 ] && OFFEN="$OFFEN $FELD:fehlt"
            [ "$GES" -ne "$ESC" ] && OFFEN="$OFFEN $FELD:$ESC/$GES"
        done
        if [ "$ALT" -gt 0 ]; then
            rot "Fehlerliste liest wieder f.meldung – das Feld gibt es nicht (E44)"
        elif [ -n "$OFFEN" ]; then
            rot "Fehlerliste: nicht jedes Vorkommen liegt in escHtml –$OFFEN"
        else
            gruen "Fehlerliste liest grund und daten, beide vollstaendig maskiert"
        fi
    fi
fi

echo ""
echo "Import und aktives Schuljahr"
# ------------------------------------------------------------------
# E56: Das Frontend haengte `schuljahr_id` an ein `FormData`, der Handler las
# sie aus `$body` -- und `$body` entsteht aus php://input, das bei
# `multipart/form-data` leer ist. Die Auswahl war wirkungslos, und die
# Oberflaeche sagte ausdruecklich zu, sie wirke.
#
# Gefaehrlich war das, weil der Import Schueler inaktiviert, die nicht in der
# Datei stehen: Wer beim Schuljahreswechsel das neue Jahr waehlte,
# importierte ins alte.
#
# Pruefung 1 ist ABSICHTLICH STRENGER als die Anforderung: Sie verbietet, den
# Wert ueberhaupt zu LESEN, nicht ihn zu verwenden. Ein
# `$egal = (int)($body['schuljahr_id'] ?? 0);` faellt durch, obwohl es
# harmlos waere.
#
# GRENZE, benannt statt verschwiegen: Sie trennt nicht "liest und verwendet"
# von "liest und verwirft". Das ginge nur, wenn sie dem Wert durch die
# Funktion folgte -- statisch nicht zu haben, und eine Naeherung waere die
# schwache Pruefung, die hier nichts zu suchen hat. Die strenge Fassung ist
# in dieser Richtung ungefaehrlich: Wer nicht liest, kann nicht versehentlich
# verwenden.
#
# Beide Pruefungen laufen ohne Kommentare -- der Kommentar am Handler zitiert
# die alte Zeile im Wortlaut und wuerde sonst selbst als Fund gelten.
# ------------------------------------------------------------------
API=backend/api/index.php
if [ ! -f "$API" ]; then
    rot "$API fehlt – Voraussetzung der Schuljahrpruefung"
else
    IMP_FKT=$(awk '/^function handle_import\(/{an=1} an{print} an&&/^}/{exit}' "$API" \
              | perl -0777 -pe 's{/\*.*?\*/}{}gs' | grep -v '^[[:space:]]*//')
    if [ -z "$IMP_FKT" ]; then
        rot "handle_import nicht gefunden"
    else
        LIEST=$(printf '%s' "$IMP_FKT" | grep -c "body\['schuljahr_id'\]" || true)
        AKTIV=$(printf '%s' "$IMP_FKT" | grep -c 'status = "aktiv"' || true)
        if [ "$LIEST" -gt 0 ]; then
            rot "handle_import liest schuljahr_id aus dem Rumpf – bei multipart ist der leer (E56)"
        elif [ "$AKTIV" -eq 0 ]; then
            rot "handle_import ermittelt das aktive Schuljahr nicht"
        else
            gruen "Import ermittelt das aktive Schuljahr und liest schuljahr_id nicht aus dem Rumpf"
        fi
    fi
fi

# Kein Auswahlfeld mehr -- in beiden Haelften, damit nicht die eine ohne die
# andere verschwindet. `imp-sj-anzeige` ist die Anzeige und bleibt.
AUSW_HTML=$(grep -c 'id="imp-sj"' "$HTML" || true)
AUSW_JS=$(grep -c "getElementById('imp-sj')" "$JS" || true)
ANZEIGE=$(grep -c 'imp-sj-anzeige' "$HTML" || true)
if [ "$AUSW_HTML" -gt 0 ] || [ "$AUSW_JS" -gt 0 ]; then
    rot "Auswahlfeld fuers Schuljahr wieder da (HTML=$AUSW_HTML, JS=$AUSW_JS) – es waere wirkungslos"
elif [ "$ANZEIGE" -eq 0 ]; then
    rot "weder Auswahl noch Anzeige des Schuljahrs auf der Importseite"
else
    gruen "Importseite zeigt das Schuljahr an, statt es zur Wahl zu stellen"
fi

echo ""
echo "Stundenkontingent"
# ------------------------------------------------------------------
# Zwei Eigenschaften der Fachzeile im Dashboard (E60).
#
# ERSTENS: Die Prozentzahl ist NICHT gedeckelt, der Balken schon.
# `Math.min(100, …)` machte aus 150 % eine 100, waehrend die Zeile
# daneben "3 / 2 Std." zeigte -- zwei Angaben ueber dieselbe Sache, die
# sich widersprachen. Der Balken braucht den Deckel, sonst schiebt er
# sich aus seinem Rahmen.
#
# Geprueft wird ueber die NAMEN, nicht ueber die Nachbarschaft zweier
# Zeilen: `pct` ist die Zahl, `breite` der Balken. Eine Pruefung auf
# Textnaehe waere gruen geblieben, sobald jemand die Zeilen umstellt
# (REIHENREGELN 2).
#
# ZWEITENS: Die vier Klassen der alten Dreiteilung kommen nirgends mehr
# vor -- weder gesetzt noch als Regel. Das ist die Suche nach der
# bekannten falschen Fassung: Dass `.dok` da ist, schliesst nicht aus,
# dass `.dover` danebensteht (REIHENREGELN 2, E55).
#
# GRENZE: Beide Pruefungen haengen an den Namen `pct` und `breite`. Wer
# umbenennt, bekommt Rot und muss die Pruefung nachziehen. Das ist der
# Preis dafuer, die Rollen zu pruefen statt der Reihenfolge.
# ------------------------------------------------------------------
if [ ! -f "$JS" ]; then
    rot "$JS fehlt – Voraussetzung der Kontingentpruefung fehlt"
    rot "$JS fehlt – Voraussetzung der Kontingentpruefung fehlt"
else
    KONT_TEXT=$(awk "$STRIP_AWK" "$JS")
    KONT_PCT=$(printf '%s\n' "$KONT_TEXT" | grep -cE 'const[[:space:]]+pct[[:space:]]*=' || true)
    KONT_PCT_MIN=$(printf '%s\n' "$KONT_TEXT" | grep -E 'const[[:space:]]+pct[[:space:]]*=' \
                   | grep -c 'Math\.min' || true)
    KONT_BREITE=$(printf '%s\n' "$KONT_TEXT" \
                  | grep -cE 'const[[:space:]]+breite[[:space:]]*=[[:space:]]*Math\.min\(100,[[:space:]]*pct\)' || true)
    KONT_BALKEN=$(printf '%s\n' "$KONT_TEXT" | grep -c 'width:${breite}%' || true)
    KONT_ZAHL=$(printf '%s\n' "$KONT_TEXT" | grep -c '${pct}%<' || true)

    if [ "$KONT_PCT" -ne 1 ]; then
        rot "die Zuweisung von pct steht $KONT_PCT-mal in $JS – erwartet genau einmal"
    elif [ "$KONT_PCT_MIN" -gt 0 ]; then
        rot "die Prozentzahl wird gedeckelt (Math.min in der Zuweisung von pct) – 150 % erschienen als 100 %"
    elif [ "$KONT_BREITE" -ne 1 ]; then
        rot "der Balken wird nicht gedeckelt: kein 'const breite = Math.min(100, pct)' gefunden"
    elif [ "$KONT_BALKEN" -ne 1 ] || [ "$KONT_ZAHL" -ne 1 ]; then
        rot "Zahl und Balken verwechselt oder nicht gefunden (width:\${breite}=$KONT_BALKEN, \${pct}%=$KONT_ZAHL)"
    else
        gruen "Prozentzahl ungedeckelt, Balkenbreite gedeckelt"
    fi

    # Kommentare vorher entfernen. Ohne das schlaegt die Pruefung auf den
    # Kommentar an, der die Entfernung ERKLAERT -- beim Bau genau passiert:
    # Der Vermerk in style.css nennt `.pwarn` und `.pover` beim Namen.
    # Gegenprobe dazu: den Code loeschen, den Kommentar stehen lassen (gruen);
    # den Code wieder einsetzen (rot).
    KONT_DATEIEN=$(find frontend -type f \
                   \( -name '*.css' -o -name '*.js' -o -name '*.html' \) \
                   ! -path 'frontend/vendor/*' | sort)
    KONT_FUND=$(for f in $KONT_DATEIEN; do
                    awk "$STRIP_AWK" "$f" | grep -nE 'dwarn|dover|pwarn|pover' | sed "s|^|$f:|"
                done)
    if [ -n "$KONT_FUND" ]; then
        rot "die Klassen der alten Dreiteilung kommen noch vor:"
        printf '%s\n' "$KONT_FUND" | sed 's/^/    /'
    else
        gruen "keine Spur der alten Dreiteilung (dwarn, dover, pwarn, pover)"
    fi
fi

echo ""
echo "CSS-Variablen"
# ------------------------------------------------------------------
# Jede in frontend/ verwendete CSS-Variable muss definiert sein.
#
# ANLASS: `var(--err)` an fuenf Stellen und `var(--ok)` an vier -- beide
# Namen gab es nie. Eine undefinierte Variable faellt still zurueck: Der
# Text erbt seine Farbe, statt rot oder gruen zu sein. Nichts bricht,
# nichts meldet sich; aufgefallen ist es nur, weil ein Hinweis im
# Browser schwarz war, wo er rot sein sollte.
#
# WAS SIE MISST: die Namen, nicht die Werte. Verwendungen (`var(--x`)
# gegen Definitionen (`--x:`), ueber alle .css, .js und .html unter
# frontend/ -- eine Definition darf also auch inline stehen.
#
# KOMMENTARE WERDEN VORHER ENTFERNT, auf beiden Seiten. Ohne das
# entstuende eine Scheindefinition, sobald eine Erklaerung `--x:`
# schreibt -- und die Pruefung ginge gerade dort gruen, wo jemand die
# Regel sorgfaeltig aufgeschrieben hat (REIHENREGELN 2). Gegenprobe
# dazu: Der Vergleich beider Mengen mit und ohne Entfernen ergab
# dieselbe Verwendungsliste, aber zwei Scheindefinitionen weniger.
#
# WARUM DIE DEFINITION NICHT PER `grep -- '--x:'` ALLEIN: Ein
# Modifikator-Klassenname mit Pseudoklasse sieht genauso aus.
# `.ci-knopf--gefahr:hover` ist keine Variablendefinition. Deshalb muss
# vor den zwei Bindestrichen ein Zeichen stehen, das kein Namenszeichen
# ist -- oder der Zeilenanfang.
#
# EIN RUECKFALL IST KEINE DEFINITION: `var(--warn,#f59e0b)` gilt hier
# als Verwendung von `--warn`. Wer einen Rueckfall angibt, hat einen
# Zweitwert genannt, aber keine Variable definiert -- und ein Rueckfall
# ist genau das, was diese Pruefung sichtbar machen soll.
#
# GRENZEN, benannt statt verschwiegen:
#   1. Ein Name, der zur Laufzeit zusammengesetzt wird
#      (`'var(--bew-' + n + ')'`), wird nicht gesehen. Im Bestand kommt
#      das nicht vor -- nachgesehen, nicht angenommen.
#   2. Sie prueft die Existenz des Namens, nicht seinen Wert und nicht,
#      ob die Definition im richtigen Geltungsbereich steht. Eine
#      Definition in einer Medienabfrage zaehlt mit.
#   3. Sie sagt nichts darueber, ob die gewaehlte Farbe die richtige
#      ist. Dass `--imp-neu` als Text auf Weiss nur 4.19 erreicht,
#      faellt ihr nicht auf.
# ------------------------------------------------------------------
# Derselbe Entferner wie oben (STRIP_AWK).

VAR_DATEIEN=$(find frontend -type f \( -name '*.css' -o -name '*.js' -o -name '*.html' \) | sort)
VAR_STILE=$(printf '%s\n' "$VAR_DATEIEN" | grep -c '\.css$' || true)

if [ "$VAR_STILE" -eq 0 ]; then
    # Entwertung: ohne Stilvorlage gibt es nichts, wogegen geprueft wuerde.
    # Das ist kein bestandener Lauf, sondern eine fehlende Voraussetzung.
    rot "keine Stilvorlage unter frontend/ gefunden – Voraussetzung der Variablenpruefung fehlt"
else
    VAR_TEXT=$(printf '%s\n' "$VAR_DATEIEN" | while read -r f; do awk "$STRIP_AWK" "$f"; done)
    VAR_BENUTZT=$(printf '%s\n' "$VAR_TEXT" \
        | grep -oE 'var\([[:space:]]*--[A-Za-z0-9_-]+' \
        | sed -E 's/^var\([[:space:]]*//' | sort -u)
    VAR_DEF=$(printf '%s\n' "$VAR_TEXT" \
        | grep -oE '(^|[^A-Za-z0-9_-])--[A-Za-z0-9_-]+[[:space:]]*:' \
        | grep -oE -- '--[A-Za-z0-9_-]+' | sort -u)
    VAR_B_ZAHL=$(printf '%s\n' "$VAR_BENUTZT" | grep -c '^--' || true)
    VAR_D_ZAHL=$(printf '%s\n' "$VAR_DEF"     | grep -c '^--' || true)

    if [ "$VAR_B_ZAHL" -eq 0 ]; then
        rot "keine einzige var(--…)-Verwendung in frontend/ gefunden – die Pruefung misst nichts"
    elif [ "$VAR_D_ZAHL" -eq 0 ]; then
        rot "keine einzige Variablendefinition in frontend/ gefunden – Voraussetzung der Variablenpruefung fehlt"
    else
        VAR_FEHLT=$(comm -23 <(printf '%s\n' "$VAR_BENUTZT") <(printf '%s\n' "$VAR_DEF"))
        VAR_F_ZAHL=$(printf '%s\n' "$VAR_FEHLT" | grep -c '^--' || true)
        if [ "$VAR_F_ZAHL" -eq 0 ]; then
            gruen "alle $VAR_B_ZAHL verwendeten CSS-Variablen sind definiert ($VAR_D_ZAHL Definitionen)"
        else
            rot "$VAR_F_ZAHL von $VAR_B_ZAHL verwendeten CSS-Variablen sind nirgends definiert:"
            printf '%s\n' "$VAR_FEHLT" | grep '^--' | while read -r v; do
                ORT=$(printf '%s\n' "$VAR_DATEIEN" | while read -r f; do
                          grep -n "var($v)" "$f" | head -1 | sed "s|^|$f:|"
                      done | head -1)
                printf '    %s (z. B. %s)\n' "$v" "${ORT:-Fundstelle nicht ermittelbar}"
            done
        fi
    fi
fi

echo ""
GESAMT=$((GRUEN + FEHLER))
echo "$GRUEN/$GESAMT bestanden, $FEHLER rot"
if [ "$FEHLER" -eq 0 ]; then echo "ALLES GRÜN"; exit 0; fi
exit 1
