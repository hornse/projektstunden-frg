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
        $stand = !isset($gefunden[$n]) ? 'fehlt' : ($gefunden[$n] === $h ? 'gleich' : 'abweichend');
        echo "  $n: $stand\n";
        if ($stand !== 'gleich') $halt[] = "$n: $stand";
    }
    if ($halt !== []) halt(implode('; ', $halt));

    // Ergebnis: die Deklarationen weg, ein Doc-Kommentar direkt davor mit,
    // ebenso der Zeilenumbruch danach. Alles andere byte-gleich.
    $weg = [];
    foreach ($dekl as $d) {
        $von = $d['von'];
        $j = $von - 1;
        while ($j >= 0 && is_array($t[$j]) && $t[$j][0] === T_WHITESPACE) $j--;
        if ($j >= 0 && is_array($t[$j]) && $t[$j][0] === T_DOC_COMMENT) $von = $j;
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
    $verloren = array_values(array_diff(wertnamen($q), wertnamen($erg)));
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
