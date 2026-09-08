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
GRUEN=0
gruen() { echo "  ✓ $1"; GRUEN=$((GRUEN + 1)); }
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
GESAMT=$((GRUEN + FEHLER))
echo "$GRUEN/$GESAMT bestanden, $FEHLER rot"
if [ "$FEHLER" -eq 0 ]; then echo "ALLES GRÜN"; exit 0; fi
exit 1
