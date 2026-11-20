<?php
/**
 * Projektstunden NRW – tests/handbuch_test.php
 * Das Benutzerhandbuch zitiert, was die Anwendung sagt (S73, C)
 *
 * docs/BENUTZERHANDBUCH.md nennt die Sätze der Anmeldung und die Schwelle
 * der Anmeldebremse. Diese Prüfung hält beide an backend/auth/
 * anmeldung.php (vor Auftrag A: Anmeldebremse.php): Ändert sich einer, wird sie rot – dann veraltet das
 * Handbuch nicht mehr still. Gegenstück für die Hilfe in der App:
 * tests/anmeldung_test.js (ausgeführt in node).
 *
 * Markdown bricht Zeilen um; verglichen wird deshalb mit zu einem
 * Leerzeichen zusammengezogenem Leerraum.
 *
 * Aufruf: php tests/handbuch_test.php   → Exit-Code 0 = alles grün
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

declare(strict_types=1);

$fehler = 0;
function pruefe(string $name, bool $ok): void
{
    global $fehler;
    echo ($ok ? '  ✓ ' : '  ✗ ') . $name . PHP_EOL;
    if (!$ok) $fehler++;
}

$W = dirname(__DIR__);
require_once "$W/backend/auth/anmeldung.php";
$roh = (string)file_get_contents("$W/docs/BENUTZERHANDBUCH.md");
// HTML-Kommentare sind Beschreibung, nicht Text, den jemand liest – sie
// werden vor dem Vergleich entfernt (REIHENREGELN 2).
$md = (string)preg_replace('/<!--.*?-->/s', '', $roh);
$text = (string)preg_replace('/\s+/u', ' ', $md);

$abgelehnt = Anmeldung::SATZ_ABGELEHNT;
$ausfall   = Anmeldung::SATZ_AUSFALL;
$warten    = Anmeldung::satzWarten(Anmeldung::WARTEZEIT_S);
// Das Handbuch zitiert den Wartesatz mit „…“ an der Stelle der Zahl; die
// Zahl (Anmeldung::WARTEZEIT_S) steht genau einmal im Satz.
$zahlen_w  = preg_match_all('/\d+/', $warten, $zw) ? $zw[0] : [];
$zitat     = (string)preg_replace('/\d+/', '…', $warten, 1);

pruefe('Voraussetzung: Handbuch gelesen, Sätze aus anmeldung.php, Wartesatz mit genau einer Zahl',
    strlen($md) > 1000 && $zahlen_w === [(string)Anmeldung::WARTEZEIT_S] && $abgelehnt !== '' && $ausfall !== '');
pruefe("Handbuch zitiert „{$abgelehnt}“ wie der Server", str_contains($text, "„{$abgelehnt}“"));
pruefe("Handbuch zitiert „{$ausfall}“ wie der Server", str_contains($text, "„{$ausfall}“"));
pruefe("Handbuch zitiert den Wartesatz „{$zitat}“ wie der Server", str_contains($text, "„{$zitat}“"));

$ZAHLWORT = ['null', 'eins', 'zwei', 'drei', 'vier', 'fünf', 'sechs', 'sieben', 'acht', 'neun', 'zehn', 'elf', 'zwölf'];
preg_match_all('/(\S+) Fehlversuch/iu', $text, $m);
$zahlen = array_values(array_filter(array_map(fn($w) => mb_strtolower($w), $m[1]),
    fn($w) => in_array($w, $ZAHLWORT, true) || ctype_digit($w)));
$soll = $ZAHLWORT[Anmeldung::SCHWELLE];
pruefe("Handbuch nennt die Schwelle als „{$soll} Fehlversuch…“ wie Anmeldung::SCHWELLE – und keine andere Zahl davor",
    count($zahlen) >= 1 && count(array_filter($zahlen, fn($w) => $w !== $soll && $w !== (string)Anmeldung::SCHWELLE)) === 0);

pruefe('Handbuch: kein Satz, den es nach FALLSTRICKE 8 nicht geben darf (Passwort stimmte, Kontotyp, Datensatz …)',
    preg_match('/Passwort (stimmt|stimmte|war richtig|ist richtig|korrekt)|Kontotyp|freigeschaltet|Schild-ID|Datensatz|nicht zugelassen/iu', $text) === 0);

$schnell = preg_match('/## Schnelleinstieg(.*?)\n---/s', $md, $s) === 1 ? $s[1] : null;
pruefe('Handbuch, Schnelleinstieg: beide Wege (WebUntis und E-Mail-Adresse) – nicht mehr nur „E-Mail und Passwort eingeben“',
    $schnell !== null && str_contains($schnell, 'WebUntis') && str_contains($schnell, 'E-Mail')
    && !str_contains($schnell, 'E-Mail und Passwort eingeben'));

echo PHP_EOL . ($fehler === 0 ? 'ALLE TESTS GRÜN' : "$fehler ROT") . PHP_EOL;
exit($fehler === 0 ? 0 : 1);
