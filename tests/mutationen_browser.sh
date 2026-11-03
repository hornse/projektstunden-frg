#!/bin/bash
# Gegenproben zu tests/browser_test.mjs (Eingabetaste, Hilfe vor der
# Anmeldung), S73-Nachgang.
#
# Jede Mutation wird an einer KOPIE von frontend/ angebracht, nicht im Repo.
# Gemessen wird je Mutation:
#   - ob sie angekommen ist (Prüfsumme der Kopie vorher ≠ nachher),
#   - was die bisherige Quelltextprüfung sagt (derselbe DOMDocument-Ausdruck
#     wie in tests-projektstunden.sh, Abschnitt „Anmeldemaske ist ein Formular"),
#   - ob im Browser die erwarteten Prüfungen fallen (Wort in der Bezeichnung:
#     „Enter“ oder „Hilfe“; „-“ heißt harmlos, nichts darf fallen).
# Das Repo wird nicht angefasst; die Prüfsumme von frontend/ wird vorher und
# nachher verglichen.
#
# SPDX-License-Identifier: GPL-3.0-or-later
set -u
export LC_ALL=C
cd "$(dirname "$0")/.."

summe() { find "$1" -type f -print0 | sort -z | xargs -0 shasum -a 256 | sed "s#$1##" | shasum -a 256 | cut -c1-16; }
REPO_VORHER=$(summe frontend)

quelltext() { # derselbe Ausdruck wie in der Suite
  php -r '
    libxml_use_internal_errors(true);
    $d = new DOMDocument(); $d->loadHTML(file_get_contents($argv[1]));
    $x = new DOMXPath($d);
    $form = function (string $id) use ($x) {
        $n = $x->query("//*[@id=\"$id\"]")->item(0);
        while ($n && $n->nodeName !== "form") $n = $n->parentNode;
        return $n;
    };
    $f = $form("l-email");
    $ok = $f !== null && $f === $form("l-pass")
       && $x->query(".//button[@type=\"submit\"]", $f)->length === 1
       && str_contains((string)$f->getAttribute("onsubmit"), "preventDefault")
       && str_contains((string)$f->getAttribute("onsubmit"), "doLogin(");
    echo $ok ? "grün" : "rot";' "$1"
}

# Name | Datei | Perl-Ersetzung | erwartet rot: Enter, Hilfe oder - (harmlos)
MUTATIONEN=(
  "E1 Knopf disabled|index.html|s#<button type=\"submit\" class=\"btn btn-p btn-full\">#<button type=\"submit\" disabled class=\"btn btn-p btn-full\">#|Enter"
  "E2 Enter im Passwortfeld geschluckt|index.html|s#<input type=\"password\" id=\"l-pass\"#<input type=\"password\" onkeydown=\"if(event.key===\x27Enter\x27)event.preventDefault()\" id=\"l-pass\"#|Enter"
  "E3 verstecktes Pflichtfeld im Formular|index.html|s#(<form id=\"login-form\"[^>]*>)#\$1<input type=\"hidden\" name=\"x\"><input name=\"y\" required style=\"display:none\">#|Enter"
  "E4 Knopf type=button|index.html|s#<button type=\"submit\" class=\"btn btn-p btn-full\">#<button type=\"button\" class=\"btn btn-p btn-full\">#|Enter"
  "E5 ohne preventDefault|index.html|s#onsubmit=\"event.preventDefault\(\); doLogin\(\);\"#onsubmit=\"doLogin();\"#|Enter"
  "E6 doLogin liest falsches Feld|app.js|s#(async function doLogin\(\) \{\n  const email = document.getElementById\()'l-email'#\$1'l-mail'#|Enter"
  "E7 Formular endet vor dem Passwortfeld|index.html|s#(<input type=\"text\" id=\"l-email\"[^>]*>)#\$1</form><form>#|Enter"
  "X1 Hilfe-Knopf versteckt|index.html|s#<button type=\"button\" class=\"btn btn-full\" onclick=\"hilfeVorAnmeldung\(\)\">#<button type=\"button\" hidden class=\"btn btn-full\" onclick=\"hilfeVorAnmeldung()\">#|Hilfe"
  "X2 hilfeVorAnmeldung ohne go|app.js|s#(function hilfeVorAnmeldung\(\) \{\n)  go\(\x27hilfe\x27\);\n#\$1#|Hilfe"
  # X3: Ohne type ist der Knopf im Formular ein Absendeknopf – der Klick auf
  # „Hilfe“ schickt eine Anmeldung ab. Erwartet war zuerst „Enter“; gemessen
  # fällt H2 („1 × POST“), Enter meldet weiter an, weil submit doLogin ruft.
  "X3 Hilfe-Knopf im Formular, ohne type|index.html|s#\n    <button type=\"button\" class=\"btn btn-full\" onclick=\"hilfeVorAnmeldung\(\)\">Hilfe zur Anmeldung</button>##; s#(<form id=\"login-form\"[^>]*>)#\$1<button class=\"btn btn-full\" onclick=\"hilfeVorAnmeldung()\">Hilfe zur Anmeldung</button>#|Hilfe"
  "H3 harmlos: Hilfe-Knopf anders beschriftet|index.html|s#>Hilfe zur Anmeldung</button>#>Hilfe</button>#|-"
  "H1 harmlos: Knopftext|index.html|s#>Anmelden</button>#>Einloggen</button>#|-"
  "H2 harmlos: Kommentar in der Maske|index.html|s#(<form id=\"login-form\"[^>]*>)#\$1<!-- Kommentar -->#|-"
)

ARBEIT=$(mktemp -d)
trap 'rm -rf "$ARBEIT"' EXIT
BELEGT=0; NICHT=0
printf '%-42s %-10s %-10s %s\n' "Mutation" "Quelltext" "Browser" "Urteil"
for m in "${MUTATIONEN[@]}"; do
  IFS='|' read -r name datei ausdruck erwartet <<< "$m"
  rm -rf "$ARBEIT/fe"; cp -R frontend "$ARBEIT/fe"
  vor=$(shasum -a 256 "$ARBEIT/fe/$datei" | cut -c1-16)
  perl -0777 -pi -e "$ausdruck" "$ARBEIT/fe/$datei"
  nach=$(shasum -a 256 "$ARBEIT/fe/$datei" | cut -c1-16)
  if [ "$vor" = "$nach" ]; then
    printf '%-42s %s\n' "$name" "NICHT ANGEKOMMEN – Ersetzung griff nicht"; NICHT=$((NICHT+1)); continue
  fi
  qt=$(quelltext "$ARBEIT/fe/index.html")
  aus=$(node tests/browser_test.mjs "$ARBEIT/fe" 2>&1)
  alle_rot=$(printf '%s\n' "$aus" | grep -c '✗' || true)
  [ "$erwartet" = - ] && rote=0 || rote=$(printf '%s\n' "$aus" | grep '✗' | grep -c "$erwartet" || true)
  vor_rot=$(printf '%s\n' "$aus" | grep -c '✗ Voraussetzung' || true)
  [ "$alle_rot" -gt 0 ] && br="rot($alle_rot)" || br="grün"
  if   [ "$erwartet" != - ] && [ "$rote" -gt 0 ] && [ "$vor_rot" -eq 0 ]; then u="belegt"; BELEGT=$((BELEGT+1))
  elif [ "$erwartet" = - ]  && [ "$alle_rot" -eq 0 ]; then u="belegt (bleibt grün)"; BELEGT=$((BELEGT+1))
  else u="NICHT BELEGT"; NICHT=$((NICHT+1)); printf '%s\n' "$aus" | grep '✗' | sed 's/^/      /'; fi
  printf '%-42s %-10s %-10s %s\n' "$name" "$qt" "$br" "$u"
done
REPO_NACHHER=$(summe frontend)
echo ""
echo "frontend/ vorher $REPO_VORHER, nachher $REPO_NACHHER $([ "$REPO_VORHER" = "$REPO_NACHHER" ] && echo '– unverändert' || echo '– VERÄNDERT')"
echo "$BELEGT/${#MUTATIONEN[@]} belegt, $NICHT nicht"
[ "$NICHT" -eq 0 ] && [ "$REPO_VORHER" = "$REPO_NACHHER" ]
