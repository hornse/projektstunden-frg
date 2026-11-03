#!/bin/bash
# ============================================================
# tests/mutationen_anmeldung.sh – prüft die Prüfungen von Anmelden und
# Abmelden im Browser-Code (S73)
#
# Baut nacheinander bewusste Fehler in frontend/app.js und
# frontend/index.html ein und belegt je Fehler, dass die Prüfung an der
# erwarteten Zeile rot wird:
#   F…  Mutationen an app.js – geprüft mit tests/anmeldung_test.js (node)
#   M…  Mutationen an index.html – geprüft mit tests-projektstunden.sh
#       (der DOM-Ersatz der node-Prüfung liest index.html mit, M1 gehört
#       deshalb zur node-Prüfung)
#   E1  Die Einbindung: Ist die node-Prüfung rot, ist die Suite rot.
#   H…  Harmlose Änderungen (Kommentare) dürfen NICHT anschlagen.
#
# Mehrere F-Mutationen bauen die frühere, belegte Fassung wieder ein
# (Befund koordination 2026-11-03-doku-hilfe §2) – REIHENREGELN 2: die
# falsche Fassung ausdrücklich suchen.
#
# Je Mutation: Prüfsumme vorher → Sicherung → Eingriff → Nachweis, dass er
# angekommen ist (Prüfsumme anders; bei app.js `node --check` heil) →
# Prüfung → Rücknahme aus der Sicherung (nie aus dem Index) → Prüfsumme
# gleich vorher.
#
# Wird nicht von tests-projektstunden.sh aufgerufen – sie verändert
# vorübergehend den Code. Aufruf im Projektordner:
#   ./tests/mutationen_anmeldung.sh
#
# SPDX-License-Identifier: GPL-3.0-or-later
# ============================================================
set -u
export LC_ALL=C
R="$(cd "$(dirname "$0")/.." && pwd)"
command -v node > /dev/null 2>&1 || { echo "ABBRUCH: node fehlt – die Serie braucht es"; exit 2; }
SICH="$(mktemp -d)"
OFFEN=""
FEHLT=0
GELAUFEN=0
summe() { shasum "$1" | cut -c1-12; }
zuruecknehmen() {
  if [ -n "$OFFEN" ]; then cp "$SICH/sicherung" "$OFFEN"; echo "Abbruch: offene Mutation in $OFFEN zurückgenommen."; fi
  rm -rf "$SICH"
}
trap zuruecknehmen EXIT

einbauen() {      # NAME DATEI AUSDRUCK → 0 wenn angekommen und heil
  VORHER=$(summe "$2"); cp "$2" "$SICH/sicherung"; OFFEN="$2"
  perl -0777 -i -pe "$3" "$2"
  if [ "$(summe "$2")" = "$VORHER" ]; then echo "$1: MUTATION NICHT ANGEKOMMEN – Suchmuster prüfen"; return 1; fi
  case "$2" in
    *.js) node --check "$2" > /dev/null 2>&1 || { echo "$1: MUTATION KAPUTT – Syntaxfehler nach dem Einbau"; return 1; } ;;
  esac
}
ruecknahme() {    # NAME DATEI
  cp "$SICH/sicherung" "$2"; OFFEN=""
  [ "$(summe "$2")" = "$VORHER" ] || { echo "ABBRUCH: Rücknahme von $1 misslungen"; exit 2; }
}

# mut NAME DATEI PERL-AUSDRUCK ERWARTETE-ZEILE WOMIT(node|suite)
mut() {
  local name=$1 datei="$R/$2" ausdruck=$3 erwartet=$4 womit=$5 aus e treffer
  GELAUFEN=$((GELAUFEN + 1))
  if ! einbauen "$name" "$datei" "$ausdruck"; then
    FEHLT=$((FEHLT + 1))
  else
    if [ "$womit" = node ]; then
      aus=$(node "$R/tests/anmeldung_test.js" 2>/dev/null); e=$?
    else
      (cd "$R" && ./tests-projektstunden.sh > /dev/null 2>&1); e=$?
      aus=$(cat "$R/logs/pruefung-letzter.txt")
    fi
    treffer=$(printf '%s\n' "$aus" | grep -cF "✗ $erwartet" || true)
    if [ "$e" -ne 0 ] && [ "$treffer" -ge 1 ]; then echo "$name: angeschlagen („$erwartet“)"
    else echo "$name: NICHT ANGESCHLAGEN (exit=$e, „$erwartet“ rot: $treffer)"; FEHLT=$((FEHLT + 1)); fi
  fi
  ruecknahme "$name" "$datei"
}

node "$R/tests/anmeldung_test.js" > /dev/null 2>&1 || { echo "ABBRUCH: node-Prüfung schon vor der Serie rot"; exit 2; }

J=frontend/app.js
H=frontend/index.html
# A2 – 401 beim Anmelden
mut F1 $J 's/    if \(path === \x27auth\/login\x27\) \{/    if (false) {/' "401:" node
mut F2 $J 's/throw new Error\(e\.error \|\| \x27Fehler 401\x27\);/throw new Error(\x27Fehler 401\x27);/' "401:" node
# A1 – Abmelden gelingt
mut F3 $J 's/  \}\n  location\.reload\(\);\n\}/  }\n  showLogin();\n}/' "Abmelden gelingt" node
mut F4 $J 's/  try \{\n    await POST\(\x27auth\/logout\x27, \{\}\);/  location.reload();\n  try {\n    await POST(\x27auth\/logout\x27, {});/' \
  "Abmelden gelingt" node
# A1 – Abmelden scheitert
mut F5 $J 's/    showMsg\(msgId, \x27Abmelden ist fehlgeschlagen\./    location.reload();\n    showMsg(msgId, \x27Abmelden ist fehlgeschlagen./' \
  "Abmelden scheitert" node
mut F6 $J 's/    document\.getElementById\(\x27l-pass\x27\)\.value = \x27\x27;\n    STATE = leererState\(\);/    STATE = leererState();/' \
  "Abmelden scheitert" node
mut F7 $J 's/    STATE = leererState\(\);\n    showMsg/    showMsg/' "Abmelden scheitert" node
mut F8 $J 's/kompetenzen: \[\], user: null \};\n\}/kompetenzen: [], user: {} };\n}/' "Abmelden scheitert" node
mut F9 $J 's/\x27Abmelden ist fehlgeschlagen\. Bitte erneut versuchen oder den Browser schließen\.\x27/\x27Abmelden fehlgeschlagen.\x27/' \
  "Abmelden scheitert" node
# catch → finally: Das return im finally schluckt die Ausnahme, der
# Fehlerfall sieht richtig aus – aber nach gelungenem Abmelden wird nicht
# mehr neu geladen. Anschlagen muss deshalb „Abmelden gelingt“.
mut F10 $J 's/  \} catch \{\n    document\.getElementById\(\x27l-pass\x27\)/  } finally {\n    document.getElementById(\x27l-pass\x27)/' \
  "Abmelden gelingt" node
# Der DOM-Ersatz liest index.html: fehlt die Meldestelle dort, wird es rot.
mut M1 $H 's/    <div id="abmelden-msg" role="status" aria-live="polite"><\/div>\n//' "Abmelden scheitert" node
# A5 – Formular
mut M2 $H 's/<button type="submit" class="btn btn-p btn-full">Anmelden/<button type="button" class="btn btn-p btn-full">Anmelden/' \
  "Anmeldung: kein <form>" suite
mut M3 $H 's/onsubmit="event\.preventDefault\(\); doLogin\(\);"/onsubmit="doLogin();"/' "Anmeldung: kein <form>" suite
mut M4 $H 's/<button type="submit" class="btn btn-p btn-full">Anmelden/<button type="submit" class="btn btn-p btn-full" onclick="doLogin()">Anmelden/' \
  "Anmeldung: onclick mit doLogin( steht noch in index.html" suite
mut M5 $H 's/    <form id="login-form" onsubmit="event\.preventDefault\(\); doLogin\(\);">\n(.*?)    <\/form>\n/$1/s' \
  "Anmeldung: kein <form>" suite

# C – Hilfe und Handbuch zitieren die Anwendung. Je Seite: der Text ändert
# sich, der Code ändert sich, die alte Fassung kommt zurück, ein verbotener
# Satz kommt dazu.
B=backend/auth/Anmeldebremse.php
D=docs/BENUTZERHANDBUCH.md
mut C1 $J 's/zeigt die App „Ungültige Anmeldedaten\.“ Nach acht/zeigt die App „Ungültige Anmeldedaten!“ Nach acht/' \
  "Hilfe zitiert „Ungültige Anmeldedaten.“" node
mut C2 $B 's/Bitte in ein paar Minuten erneut versuchen\.\x27;/Bitte gleich erneut versuchen.\x27;/' \
  "Hilfe zitiert „WebUntis ist gerade nicht erreichbar." node
mut C3 $B 's/Bitte in ein paar Minuten erneut versuchen\.\x27;/Bitte gleich erneut versuchen.\x27;/' \
  "Handbuch: Handbuch zitiert „WebUntis ist gerade nicht erreichbar." suite
mut C4 $B 's/public const SCHWELLE = 8;/public const SCHWELLE = 9;/' "Hilfe nennt die Schwelle" node
mut C5 $J 's/Nach acht Fehlversuchen heißt es/Nach fünf Fehlversuchen heißt es/' "Hilfe nennt die Schwelle" node
mut C6 $J 's/Eltern haben keinen Zugang, auch nicht mit einem WebUntis-Konto für Eltern\.\x27/Eltern haben keinen Zugang: Das Passwort stimmt dann, aber der Kontotyp ist nicht freigeschaltet.\x27/' \
  "Hilfe: kein Satz, den es nach FALLSTRICKE 8" node
mut C7 $J 's/text: \x27Lehrkräfte: WebUntis-Kürzel und WebUntis-Passwort\..*?\x27 \},/text: \x27E-Mail-Adresse und Passwort eingeben. Bei Problemen an den Administrator wenden – dieser kann Konten anlegen und Passwörter zurücksetzen.\x27 },/s' \
  "Hilfe, Anmeldekarte" node
mut C8 $J 's/„Zu viele Fehlversuche\. Erneut versuchen in noch … Sekunden\.“ Danach geht es wieder – gesperrt wird nichts\. Eine gelungene Anmeldung setzt die Zählung zurück\.\x27/„Zu viele Fehlversuche.“ Danach geht es wieder – gesperrt wird nichts. Eine gelungene Anmeldung setzt die Zählung zurück.\x27/' \
  "Hilfe zitiert den Wartesatz" node
mut C9 $D 's/2\. Anmelden – Lehrkräfte mit WebUntis-Kürzel.*?→ \*\*Anmelden\*\*/2. E-Mail und Passwort eingeben → **Anmelden**/s' \
  "Handbuch: Handbuch, Schnelleinstieg" suite
mut C10 $D 's/„Zu viele\nFehlversuche\. Erneut versuchen in noch … Sekunden\.“/„Zu viele\nFehlversuche.“/' \
  "Handbuch: Handbuch zitiert den Wartesatz" suite
mut C11 $D 's/Eltern haben keinen Zugang, auch\nnicht mit einem WebUntis-Konto für Eltern\./Eltern haben keinen Zugang: Das Passwort stimmt,\naber der Kontotyp ist nicht freigeschaltet./' \
  "Handbuch: Handbuch: kein Satz, den es nach FALLSTRICKE 8" suite
mut C12 $D 's/Anmeldedaten\.“ Nach acht Fehlversuchen/Anmeldedaten.“ Nach fünf Fehlversuchen/' \
  "Handbuch: Handbuch nennt die Schwelle" suite
mut C13 $D 's/zeigt die App „Ungültige\nAnmeldedaten\.“/zeigt die App „Ungültige\nZugangsdaten.“/' \
  "Handbuch: Handbuch zitiert „Ungültige Anmeldedaten.“" suite

# E1 – Einbindung: node-Prüfung rot → Suite rot, an der erwarteten Zeile.
GELAUFEN=$((GELAUFEN + 1))
if einbauen E1 "$R/$J" 's/    if \(path === \x27auth\/login\x27\) \{/    if (false) {/'; then
  if (cd "$R" && ./tests-projektstunden.sh > /dev/null 2>&1); then
    echo "E1: NICHT ANGESCHLAGEN – tests-projektstunden.sh übersieht die rote node-Prüfung"; FEHLT=$((FEHLT + 1))
  elif grep -qF "✗ Anmeldung (node): 401:" "$R/logs/pruefung-letzter.txt"; then
    echo "E1: angeschlagen (tests-projektstunden.sh rot, an der erwarteten Zeile)"
  else
    echo "E1: NICHT AN DER ERWARTETEN ZEILE"; FEHLT=$((FEHLT + 1))
  fi
else
  FEHLT=$((FEHLT + 1))
fi
ruecknahme E1 "$R/$J"

# H1, H2 – harmlos: ein Kommentar in app.js, ein HTML-Kommentar mit
# „<form>“ und „onclick="doLogin()"“ außerhalb der Maske.
harmlos() {   # NAME DATEI AUSDRUCK WOMIT
  GELAUFEN=$((GELAUFEN + 1))
  if einbauen "$1" "$R/$2" "$3"; then
    if [ "$4" = node ]; then node "$R/tests/anmeldung_test.js" > /dev/null 2>&1; else (cd "$R" && ./tests-projektstunden.sh > /dev/null 2>&1); fi
    if [ $? -eq 0 ]; then echo "$1: richtig nicht angeschlagen (harmlose Änderung, grün)"
    else echo "$1: FALSCH ANGESCHLAGEN – harmlose Änderung macht rot"; FEHLT=$((FEHLT + 1)); fi
  else
    FEHLT=$((FEHLT + 1))
  fi
  ruecknahme "$1" "$R/$2"
}
harmlos H1 $J 's/ \* Abmelden \(S73\)\. Gelingt es,/ * Abmelden (S73, harmlos geändert). Gelingt es,/' node
harmlos H3 $J 's/(  const fragen = \[\n    \{ f: \x27Ich habe mich vertippt)/  \/\/ Nie erklären, dass das Passwort stimmte oder der Kontotyp nicht freigeschaltet ist.\n$1/' node
harmlos H4 $D 's/(\*\*Können Eltern sich anmelden\?\*\*)/<!-- Nie erklären: Passwort stimmt, Kontotyp nicht freigeschaltet. -->\n$1/' suite
harmlos H2 $H 's/(    <div id="l-msg")/    <!-- früher: <button onclick="doLogin()"> ohne <form> -->\n$1/' suite

echo ""
[ "$GELAUFEN" -ge 33 ] || { echo "FEHLER: nur $GELAUFEN Mutationen gelaufen, erwartet 33"; exit 1; }
if [ "$FEHLT" -eq 0 ]; then echo "ALLE $GELAUFEN MUTATIONEN BELEGT"; exit 0; fi
echo "$FEHLT VON $GELAUFEN MUTATION(EN) OHNE BELEG"; exit 1
