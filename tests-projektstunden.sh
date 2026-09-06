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

echo ""
GESAMT=$((GRUEN + FEHLER))
echo "$GRUEN/$GESAMT bestanden, $FEHLER rot"
if [ "$FEHLER" -eq 0 ]; then echo "ALLES GRÜN"; exit 0; fi
exit 1
