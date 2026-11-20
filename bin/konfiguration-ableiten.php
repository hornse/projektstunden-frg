<?php
/**
 * Projektstunden NRW – bin/konfiguration-ableiten.php
 * Aus einer alten backend/config.php (Werte UND Code) die Wertedatei
 * backend/konfiguration.php ableiten (Auftrag A, Paket 1, E68).
 *
 * Gerufen über bin/konfiguration-ableiten.sh – lokal oder, per ssh über
 * die Standardeingabe, auf dem Server, wo das Skript noch nicht liegt.
 *
 * Arten:
 *   namen VORLAGE                 Namen der Werte (define, globale Variablen), Komma
 *   fingerabdruecke REFERENZ      name:prüfsumme je Funktion, Komma
 *   ableiten QUELLE ZIEL NAMEN FINGERABDRUECKE
 *                                 trocken, außer SCHREIBEN=1 steht in der Umgebung
 *   pruefen DATEI NAMEN           führt DATEI alle NAMEN und keine Funktion?
 *
 * Was „ableiten“ tut: Es entfernt die Funktionsdeklarationen aus QUELLE und
 * lässt alles andere byte-gleich stehen. Vorher misst es:
 *   - jede Funktion der Quelle ist eine der erwarteten, sonst HALT;
 *   - jede erwartete Funktion ist „gleich“ (Tokenfolge ohne Leerraum und
 *     Kommentare) – „abweichend“ oder „fehlt“ ist ein HALT: Dann trug der
 *     Server anderen Code als die Vorlage, und der Umzug änderte Verhalten;
 *   - das Ergebnis hat keine Funktion, alle Namen der Quelle, alle NAMEN
 *     der Vorlage, und php -l ist sauber (geprüft über die Standardeingabe,
 *     ohne Zwischendatei).
 * Seit Paket 4 (E68) entfallen dabei auch drei Anweisungen, je als ganze
 * Anweisung auf oberster Ebene: ini_set('session.save_path', …) – maßgeblich
 * ist sessions.ini des Servers – und define('SESSION_NAME'|'SESSION_LIFETIME',
 * …), die jetzt in backend/kern.php stehen. Stünden sie zusätzlich in der
 * Wertedatei, warnte PHP bei jeder Anfrage. Die Ausgabe nennt sie beim Namen;
 * steht danach noch einer im Ergebnis, ist das ein HALT. „pruefen“ hält an,
 * wenn eine Wertedatei einen davon setzt.
 * Eine Ausnahme vom „abweichend“: die BETRIEBSFASSUNG von session_start_secure
 * (E68), lokal und auf dem Server, mit einem Block, der hinter dem Proxy
 * $_SERVER['HTTPS'] setzt – ohne Wirkung, denn kein Code liest es (K6) und
 * secure steht fest in session_set_cookie_params. Erkannt an genau einer
 * Prüfsumme und nur für diese Funktion; jede andere Fassung bleibt HALT.
 * ZIEL wird nie überschrieben. Geschrieben wird mit Rechten 0600.
 *
 * AUSGEGEBEN WERDEN NUR NAMEN UND ZAHLEN, NIE EIN WERT (REIHENREGELN 9).
 * Die Quelle enthält das Datenbankpasswort.
 *
 * Exit 0 = in Ordnung, 1 = Halt, 2 = Aufruf falsch.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

declare(strict_types=1);

function halt(string $grund): never
{
    fwrite(STDOUT, "HALT: $grund\n");
    exit(1);
}

/** @return list<array{name:string, von:int, bis:int}> Funktionsdeklarationen auf oberster Ebene (Tokenindizes) */
function deklarationen(array $t): array
{
    $erg = [];
    $tiefe = 0;
    for ($i = 0, $n = count($t); $i < $n; $i++) {
        $x = $t[$i];
        if ($x === '{' || (is_array($x) && in_array($x[0], [T_CURLY_OPEN, T_DOLLAR_OPEN_CURLY_BRACES], true))) { $tiefe++; continue; }
        if ($x === '}') { $tiefe--; continue; }
        if (is_array($x) && in_array($x[0], [T_CLASS, T_INTERFACE, T_TRAIT, T_ENUM], true) && $tiefe === 0) {
            halt('die Quelle enthält eine Klasse oder Schnittstelle – nicht vorgesehen');
        }
        if ($tiefe !== 0 || !is_array($x) || $x[0] !== T_FUNCTION) continue;
        $name = null;
        for ($j = $i + 1; $j < $n; $j++) {
            if (is_array($t[$j]) && in_array($t[$j][0], [T_WHITESPACE, T_COMMENT, T_DOC_COMMENT], true)) continue;
            if ($t[$j] === '&') continue;
            if (is_array($t[$j]) && $t[$j][0] === T_STRING) $name = $t[$j][1];
            break;
        }
        if ($name === null) continue;   // Closure auf oberster Ebene: bleibt stehen
        // Ende: die schließende Klammer des Rumpfs
        $k = $i; $d = 0; $offen = false;
        for (; $k < $n; $k++) {
            $y = $t[$k];
            if ($y === '{' || (is_array($y) && in_array($y[0], [T_CURLY_OPEN, T_DOLLAR_OPEN_CURLY_BRACES], true))) { $d++; $offen = true; }
            if ($y === '}') { $d--; if ($offen && $d === 0) break; }
        }
        if ($k >= $n) halt("Rumpf der Funktion $name nicht abgeschlossen");
        $erg[] = ['name' => $name, 'von' => $i, 'bis' => $k];
        $i = $k;
    }
    return $erg;
}

function text(array|string $x): string { return is_array($x) ? $x[1] : $x; }

/** Index des nächsten Tokens ab $i, das weder Leerraum noch Kommentar ist. */
function naechster(array $t, int $i): int
{
    for ($n = count($t); $i < $n; $i++) {
        if (is_array($t[$i]) && in_array($t[$i][0], [T_WHITESPACE, T_COMMENT, T_DOC_COMMENT], true)) continue;
        return $i;
    }
    return $n;
}

/** Was seit Paket 4 der Kern definiert (E68). Der Speicherort kommt aus sessions.ini. */
const SITZUNG = ['SESSION_LIFETIME', 'SESSION_NAME'];

/**
 * Bekannte Betriebsfassungen (E68): Funktionsname → Fingerabdruck. Gemessen
 * lokal am 20.11.2026 (fingerabdruecke backend/config.php), gleich der aus
 * der Abschrift nachgebauten; der Server trägt laut diff dieselbe Funktion.
 * Keine allgemeine Ausnahme – je Funktion genau eine Prüfsumme.
 */
const BETRIEBSFASSUNGEN = ['session_start_secure' => '0a9cd10e251be449'];
const BETRIEBSFASSUNG = 'Betriebsfassung (E68)';
const SPEICHERORT = 'session.save_path';

/**
 * Aufrufe von ini_set und define, die einen Sitzungswert setzen, gleich wo:
 * je ['name', 'i' (Index des Funktionsnamens), 'k' (Index der öffnenden Klammer)].
 */
function sitzungsaufrufe(array $t): array
{
    $erg = [];
    for ($i = 0, $n = count($t); $i < $n; $i++) {
        $x = $t[$i];
        if (!is_array($x) || !in_array($x[0], [T_STRING, T_NAME_FULLY_QUALIFIED], true)) continue;
        $fn = strtolower(ltrim($x[1], '\\'));
        if ($fn !== 'ini_set' && $fn !== 'define') continue;
        $k = naechster($t, $i + 1);
        if (($t[$k] ?? null) !== '(') continue;
        $a = naechster($t, $k + 1);
        if (!is_array($t[$a] ?? null) || $t[$a][0] !== T_CONSTANT_ENCAPSED_STRING) continue;
        $arg = substr($t[$a][1], 1, -1);
        if ($fn === 'ini_set' && $arg === SPEICHERORT) $erg[] = ['name' => SPEICHERORT, 'i' => $i, 'k' => $k];
        if ($fn === 'define' && in_array($arg, SITZUNG, true)) $erg[] = ['name' => $arg, 'i' => $i, 'k' => $k];
    }
    return $erg;
}

/** Welche Sitzungswerte eine Datei setzt (Aufrufe überall, dazu const NAME = …): Namen, nie Werte. */
function sitzung_gesetzt(array $t): array
{
    $namen = array_map(fn($a) => $a['name'], sitzungsaufrufe($t));
    for ($i = 0, $n = count($t); $i < $n; $i++) {
        if (!is_array($t[$i]) || $t[$i][0] !== T_CONST) continue;
        for ($j = $i + 1; $j < $n && $t[$j] !== ';'; $j++) {
            if (is_array($t[$j]) && $t[$j][0] === T_STRING && in_array($t[$j][1], SITZUNG, true)) $namen[] = $t[$j][1];
        }
    }
    return sitzung_ordnen($namen);
}

/** Der Speicherort zuerst, dann die Konstanten nach dem Alphabet – ohne Doppelte. */
function sitzung_ordnen(array $namen): array
{
    $namen = array_values(array_unique($namen));
    usort($namen, fn($a, $b) => [$a !== SPEICHERORT, $a] <=> [$b !== SPEICHERORT, $b]);
    return $namen;
}

/**
 * Die Sitzungsanweisungen, die „ableiten“ entfernt: Aufruf am Anfang einer
 * Anweisung auf oberster Ebene, bis zum Semikolon (Tokenindizes).
 * @return list<array{name:string, von:int, bis:int}>
 */
function sitzungsanweisungen(array $t): array
{
    $tiefe = [];
    $d = 0;
    foreach ($t as $i => $x) {
        if ($x === '{' || (is_array($x) && in_array($x[0], [T_CURLY_OPEN, T_DOLLAR_OPEN_CURLY_BRACES], true))) $d++;
        if ($x === '}') $d--;
        $tiefe[$i] = $d;
    }
    $erg = [];
    foreach (sitzungsaufrufe($t) as $a) {
        if ($tiefe[$a['i']] !== 0 || !anweisungsbeginn($t, $a['i'])) continue;
        $p = 0;
        for ($j = $a['k'], $n = count($t); $j < $n; $j++) {
            if ($t[$j] === '(') $p++;
            if ($t[$j] === ')') { $p--; if ($p === 0) break; }
        }
        $e = naechster($t, $j + 1);
        if (($t[$e] ?? null) !== ';') continue;   // kein eigener Satz: bleibt stehen, der HALT danach fängt es
        $erg[] = ['name' => $a['name'], 'von' => $a['i'], 'bis' => $e];
    }
    return $erg;
}

function fingerabdruck(array $t, int $von, int $bis): string
{
    $s = [];
    for ($i = $von; $i <= $bis; $i++) {
        if (is_array($t[$i]) && in_array($t[$i][0], [T_WHITESPACE, T_COMMENT, T_DOC_COMMENT], true)) continue;
        $s[] = text($t[$i]);
    }
    return substr(hash('sha256', implode(' ', $s)), 0, 16);
}

/**
 * Steht der Token $i am Anfang einer Anweisung? Sonst ist eine Variable mit
 * „=“ dahinter ein Parameter mit Vorgabewert, keine globale Zuweisung.
 */
function anweisungsbeginn(array $t, int $i): bool
{
    for ($j = $i - 1; $j >= 0; $j--) {
        $y = $t[$j];
        if (is_array($y) && in_array($y[0], [T_WHITESPACE, T_COMMENT, T_DOC_COMMENT], true)) continue;
        return $y === ';' || $y === '}' || (is_array($y) && $y[0] === T_OPEN_TAG);
    }
    return true;
}

/** Namen aus define('…') und globalen Zuweisungen auf oberster Ebene. */
function wertnamen(string $quelle): array
{
    $t = token_get_all($quelle);
    $namen = []; $tiefe = 0;
    for ($i = 0, $n = count($t); $i < $n; $i++) {
        $x = $t[$i];
        if ($x === '{') $tiefe++;
        if ($x === '}') $tiefe--;
        if (!is_array($x)) continue;
        if ($x[0] === T_STRING && strtolower($x[1]) === 'define') {
            for ($j = $i + 1; $j < $n; $j++) {
                if (is_array($t[$j]) && $t[$j][0] === T_CONSTANT_ENCAPSED_STRING) { $namen[] = trim($t[$j][1], "'\""); break; }
                if ($t[$j] === ')') break;
            }
        }
        if ($tiefe === 0 && $x[0] === T_VARIABLE && anweisungsbeginn($t, $i)) {
            for ($j = $i + 1; $j < $n && is_array($t[$j]) && $t[$j][0] === T_WHITESPACE; $j++);
            if (($t[$j] ?? null) === '=') $namen[] = $x[1];
        }
    }
    $namen = array_values(array_unique($namen));
    sort($namen);
    return $namen;
}

function lesen(string $pfad): string
{
    if (!is_file($pfad) || !is_readable($pfad)) halt("$pfad nicht lesbar");
    return (string)file_get_contents($pfad);
}

function liste(string $s): array
{
    $l = array_values(array_filter(array_map('trim', explode(',', $s)), fn($x) => $x !== ''));
    sort($l);
    return $l;
}

function lint(string $code): bool
{
    $p = proc_open([PHP_BINARY, '-l'], [0 => ['pipe', 'r'], 1 => ['pipe', 'w'], 2 => ['pipe', 'w']], $r);
    if (!is_resource($p)) return false;
    fwrite($r[0], $code); fclose($r[0]);
    stream_get_contents($r[1]); stream_get_contents($r[2]);   // Ausgabe kann Zeilen der Datei nennen – verworfen
    return proc_close($p) === 0;
}

$art = $argv[1] ?? '';

if ($art === 'namen' && isset($argv[2])) {
    echo implode(',', wertnamen(lesen($argv[2]))), "\n";
    exit(0);
}

if ($art === 'fingerabdruecke' && isset($argv[2])) {
    $t = token_get_all(lesen($argv[2]));
    $f = [];
    foreach (deklarationen($t) as $d) $f[] = $d['name'] . ':' . fingerabdruck($t, $d['von'], $d['bis']);
    sort($f);
    echo implode(',', $f), "\n";
    exit(0);
}

if ($art === 'pruefen' && isset($argv[2], $argv[3])) {
    $q = lesen($argv[2]);
    $fehlen = array_values(array_diff(liste($argv[3]), wertnamen($q)));
    $funk = array_map(fn($d) => $d['name'], deklarationen(token_get_all($q)));
    echo 'geprüft: ', basename($argv[2]), ', ', count(liste($argv[3])), " Namen der Vorlage\n";
    if ($funk !== []) halt('Funktionen in einer Wertedatei: ' . implode(', ', $funk));
    $sitz = sitzung_gesetzt(token_get_all($q));
    if ($sitz !== []) halt('setzt, was im Kern oder in sessions.ini steht (E68): ' . implode(', ', $sitz));
    if ($fehlen !== []) halt('es fehlen: ' . implode(', ', $fehlen));
    echo "in Ordnung: alle Namen da, keine Funktion\n";
    exit(0);
}

if ($art === 'ableiten' && isset($argv[2], $argv[3], $argv[4], $argv[5])) {
    [$quelle, $ziel, $namen, $finger] = [$argv[2], $argv[3], liste($argv[4]), liste($argv[5])];
    $schreiben = getenv('SCHREIBEN') === '1';
    if (file_exists($ziel)) halt("$ziel gibt es schon – es wird nie überschrieben");
    if ($namen === [] || $finger === []) halt('Namen oder Fingerabdrücke leer – die Vorprüfung fand ihre Voraussetzung nicht');

    $q = lesen($quelle);
    $t = token_get_all($q);
    $dekl = deklarationen($t);
    $erwartet = [];
    foreach ($finger as $f) { [$n, $h] = array_pad(explode(':', $f, 2), 2, ''); $erwartet[$n] = $h; }

    echo 'Quelle: ', basename($quelle), ', ', count($dekl), ' Funktionen, ', count(wertnamen($q)), " Namen\n";
    $halt = [];
    $gefunden = [];
    foreach ($dekl as $d) {
        $gefunden[$d['name']] = fingerabdruck($t, $d['von'], $d['bis']);
        if (!isset($erwartet[$d['name']])) $halt[] = "unbekannte Funktion {$d['name']}";
    }
    foreach ($erwartet as $n => $h) {
        $stand = !isset($gefunden[$n]) ? 'fehlt'
            : ($gefunden[$n] === $h ? 'gleich'
            : ((BETRIEBSFASSUNGEN[$n] ?? null) === $gefunden[$n] ? BETRIEBSFASSUNG : 'abweichend'));
        echo "  $n: $stand\n";
        if ($stand !== 'gleich' && $stand !== BETRIEBSFASSUNG) $halt[] = "$n: $stand";
    }
    if ($halt !== []) halt(implode('; ', $halt));

    // Die Sitzungsanweisungen (Paket 4): genannt beim Namen, nie mit Wert.
    $sitzung = sitzungsanweisungen($t);
    $entf = sitzung_ordnen(array_map(fn($s) => $s['name'], $sitzung));
    echo 'entfällt: ', $entf === [] ? 'nichts' : implode(', ', $entf),
         " – die Sitzung steht im Kern, der Speicherort in sessions.ini (E68)\n";

    // Ergebnis: die Deklarationen weg, ein Doc-Kommentar direkt davor mit,
    // ebenso der Zeilenumbruch danach. Ebenso die Sitzungsanweisungen. Alles
    // andere byte-gleich.
    $weg = [];
    foreach (array_merge($dekl, $sitzung) as $d) {
        $von = $d['von'];
        $j = $von - 1;
        while ($j >= 0 && is_array($t[$j]) && $t[$j][0] === T_WHITESPACE) $j--;
        // Der Doc-Kommentar gehört nur zu einer Funktion. Vor einer
        // Sitzungsanweisung ist er der Kopf der Datei und bleibt stehen.
        if (in_array($d, $dekl, true) && $j >= 0 && is_array($t[$j]) && $t[$j][0] === T_DOC_COMMENT) $von = $j;
        $bis = $d['bis'];
        if (isset($t[$bis + 1]) && is_array($t[$bis + 1]) && $t[$bis + 1][0] === T_WHITESPACE) $bis++;
        for ($i = $von; $i <= $bis; $i++) $weg[$i] = true;
    }
    $erg = '';
    foreach ($t as $i => $x) {
        if (isset($weg[$i])) continue;
        $erg .= text($x);
        if (is_array($x) && $x[0] === T_OPEN_TAG && !str_contains($erg, 'konfiguration-ableiten')) {
            $erg .= '// Abgeleitet am ' . date('d.m.Y') . " aus config.php durch bin/konfiguration-ableiten.php – nur Werte, der Code steht in backend/kern.php (E68).\n";
        }
    }

    $ergT = token_get_all($erg);
    if (deklarationen($ergT) !== []) halt('das Ergebnis enthält noch eine Funktion');
    $rest = sitzung_gesetzt($ergT);
    if ($rest !== []) halt('nicht als eigene Anweisung entfernbar, das Ergebnis setzt noch: ' . implode(', ', $rest));
    $verloren = array_values(array_diff(wertnamen($q), wertnamen($erg), SITZUNG));
    if ($verloren !== []) halt('im Ergebnis fehlen Namen der Quelle: ' . implode(', ', $verloren));
    $fehlen = array_values(array_diff($namen, wertnamen($erg)));
    if ($fehlen !== []) halt('im Ergebnis fehlen Namen der Vorlage: ' . implode(', ', $fehlen));
    if (!lint($erg)) halt('php -l meldet einen Fehler im Ergebnis');
    echo 'Ergebnis: keine Funktion, ', count(wertnamen($erg)), ' Namen, alle ', count($namen), " der Vorlage, php -l sauber\n";

    if (!$schreiben) {
        echo "trocken: nichts geschrieben (SCHREIBEN=1 schreibt " . basename($ziel) . ")\n";
        exit(0);
    }
    umask(077);
    $h = @fopen($ziel, 'x');
    if ($h === false) halt("$ziel nicht anlegbar");
    fwrite($h, $erg);
    fclose($h);
    chmod($ziel, 0600);
    echo 'geschrieben: ', basename($ziel), ", Rechte 0600\n";
    exit(0);
}

fwrite(STDERR, "Aufruf: namen VORLAGE | fingerabdruecke REFERENZ | ableiten QUELLE ZIEL NAMEN FINGER | pruefen DATEI NAMEN\n");
exit(2);
