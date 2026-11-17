<?php
/**
 * Projektstunden NRW – tests/kern_test.php
 * Der Kern des Backends ist versioniert, die Konfiguration hält nur Werte
 *
 * Anlass: Auftrag A (koordination AUFTRAG-projektstunden-A-anmeldung-modul.md,
 * Paket 1), Befund Z. 5 vom 06.11.2026: Die acht Funktionen des Backends
 * standen in der unversionierten backend/config.php. Im September lag die
 * lokale Fassung drei Generationen hinter der des Servers, und nichts hat es
 * bemerkt. Seit Auftrag A (E68): backend/kern.php (versioniert) und
 * backend/konfiguration.php (unversioniert, nur Werte).
 *
 * Vier Teile:
 *   K1–K2  Aufbau der beiden Dateien (Tokenizer – Kommentar und Zeichenkette
 *          zählen nicht als Code, REIHENREGELN 2)
 *   K3     Einbindung: wer welche Datei lädt (Aufrufstellen, Tokenizer)
 *   K4     bin/konfiguration-ableiten.php AUSGEFÜHRT gegen die beigelegte
 *          Vorlage vom Stand vor Auftrag A (tests/daten/config.example-0e80957.php,
 *          byte-gleich aus git show 0e80957:backend/config.example.php)
 *   K5     die Probebäume anderer Prüfungen kopieren keine konfiguration.php
 *          (Quelltext – die Bäume entstehen in fremden Skripten)
 *
 * Werte, die hier stehen, sind ERFUNDEN.
 *
 * Aufruf: php tests/kern_test.php   → Exit-Code 0 = alles grün
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

declare(strict_types=1);

ini_set('display_errors', 'stderr');

$fehler = 0;
function pruefe(string $name, bool $ok, string $detail = ''): void
{
    global $fehler;
    echo ($ok ? '  ✓ ' : '  ✗ ') . $name . PHP_EOL;
    if (!$ok && $detail !== '') echo '      ' . $detail . PHP_EOL;
    if (!$ok) $fehler++;
}
set_exception_handler(function (Throwable $e): void {
    echo '  ✗ Suite abgebrochen: ' . get_class($e) . ': ' . $e->getMessage() . PHP_EOL;
    exit(1);
});

$W      = dirname(__DIR__);
$KERN   = "$W/backend/kern.php";
$VORL   = "$W/backend/konfiguration.example.php";
$INDEX  = "$W/backend/api/index.php";
$ABL    = "$W/bin/konfiguration-ableiten.php";
$BEILAGE = __DIR__ . '/daten/config.example-0e80957.php';
const BEILAGE_SHA256 = '1f1e8e484e4332e173135eb2530b831ff2894b43632d391a398c810311ec6aea';
// Die acht aus config.php (Paket 1) und audit_grenze: Frist des audit_log,
// gehört zu audit(), Paket 3 (E68). Die Festlegung „acht Funktionen“ aus
// Schritt 2 ist damit bewusst auf neun geändert. K4 zählt weiter acht – dort
// ist der Maßstab die Vorlage vor Auftrag A, in der es audit_grenze nicht gab.
const KERNFUNKTIONEN = ['audit', 'audit_grenze', 'clean', 'get_db', 'json_error', 'json_response',
                        'require_admin', 'require_auth', 'session_start_secure'];

/** Namen der Funktionsdeklarationen (keine Closures), über den Tokenizer. */
function funktionen(string $quelle): array
{
    $t = token_get_all($quelle);
    $namen = [];
    for ($i = 0, $n = count($t); $i < $n; $i++) {
        if (!is_array($t[$i]) || $t[$i][0] !== T_FUNCTION) continue;
        for ($j = $i + 1; $j < $n; $j++) {
            if (is_array($t[$j]) && in_array($t[$j][0], [T_WHITESPACE, T_COMMENT, T_DOC_COMMENT], true)) continue;
            if ($t[$j] === '&') continue;
            if (is_array($t[$j]) && $t[$j][0] === T_STRING) $namen[] = $t[$j][1];
            break;
        }
    }
    sort($namen);
    return $namen;
}

/** Steht der Token $i am Anfang einer Anweisung? (Parameter mit Vorgabewert sind keine Globalen.) */
function anweisungsbeginn(array $t, int $i): bool
{
    for ($j = $i - 1; $j >= 0; $j--) {
        $y = $t[$j];
        if (is_array($y) && in_array($y[0], [T_WHITESPACE, T_COMMENT, T_DOC_COMMENT], true)) continue;
        return $y === ';' || $y === '}' || (is_array($y) && $y[0] === T_OPEN_TAG);
    }
    return true;
}

/** Namen der Konstanten aus define('…') und der globalen Variablen auf oberster Ebene. */
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
                if ($t[$j] === ')' ) break;
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

/** Ziele der require/include-Anweisungen einer Datei: die Zeichenketten im Ausdruck. */
function einbindungen(string $quelle): array
{
    $t = token_get_all($quelle);
    $ziele = [];
    for ($i = 0, $n = count($t); $i < $n; $i++) {
        if (!is_array($t[$i]) || !in_array($t[$i][0], [T_REQUIRE, T_REQUIRE_ONCE, T_INCLUDE, T_INCLUDE_ONCE], true)) continue;
        $s = '';
        for ($j = $i + 1; $j < $n && $t[$j] !== ';'; $j++) {
            if (is_array($t[$j]) && $t[$j][0] === T_CONSTANT_ENCAPSED_STRING) $s .= trim($t[$j][1], "'\"");
        }
        $ziele[] = $s;
    }
    return $ziele;
}

// ------------------------------------------------------------------
// K1–K2 Aufbau
// ------------------------------------------------------------------
echo "Aufbau" . PHP_EOL;
$kern = is_file($KERN) ? (string)file_get_contents($KERN) : '';
pruefe('K1 backend/kern.php definiert genau die neun Funktionen des Kerns',
    funktionen($kern) === KERNFUNKTIONEN,
    'gefunden: ' . (is_file($KERN) ? implode(', ', funktionen($kern)) : 'Datei fehlt'));
$vorl = is_file($VORL) ? (string)file_get_contents($VORL) : '';
$vorlNamen = wertnamen($vorl);
pruefe('K2 backend/konfiguration.example.php hält nur Werte: keine Funktion, '
    . count($vorlNamen) . ' Namen (null wäre ein Fehler)',
    is_file($VORL) && funktionen($vorl) === [] && count($vorlNamen) > 0,
    is_file($VORL) ? 'Funktionen: ' . implode(', ', funktionen($vorl)) : 'Datei fehlt');

// ------------------------------------------------------------------
// K3 Einbindung
// ------------------------------------------------------------------
echo PHP_EOL . "Einbindung" . PHP_EOL;
$fremd = [];
$it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator("$W/backend", FilesystemIterator::SKIP_DOTS));
foreach ($it as $x) {
    $rel = substr((string)$x, strlen($W) + 1);
    if (!str_ends_with($rel, '.php')) continue;
    $b = basename($rel);
    if (str_starts_with($b, 'config.php') || str_starts_with($b, 'konfiguration.php')) continue;   // Werte, nie gelesen
    if ($rel === 'backend/kern.php') continue;
    foreach (einbindungen((string)file_get_contents((string)$x)) as $z) {
        if (str_contains($z, 'config.php') || str_contains($z, 'konfiguration.php')) $fremd[] = "$rel → $z";
    }
}
pruefe('K3 keine Datei unter backend/ außer kern.php bindet config.php oder konfiguration.php ein',
    $fremd === [], implode('; ', $fremd));
$kernZiele = einbindungen($kern);
$konfZiele = array_values(array_filter($kernZiele, fn($z) => str_ends_with($z, '/konfiguration.php')));
$altZiele  = array_values(array_filter($kernZiele, fn($z) => str_contains($z, 'config.php')));
pruefe('K3 kern.php bindet konfiguration.php genau einmal ein, config.php nie',
    count($konfZiele) === 1 && $altZiele === [], 'Ziele: ' . implode(', ', $kernZiele));
$indexZiele = einbindungen(is_file($INDEX) ? (string)file_get_contents($INDEX) : '');
pruefe('K3 backend/api/index.php bindet kern.php ein',
    count(array_filter($indexZiele, fn($z) => str_ends_with($z, '/kern.php'))) === 1,
    'Ziele: ' . implode(', ', $indexZiele));

// ------------------------------------------------------------------
// K4 Ableitung, ausgeführt
// ------------------------------------------------------------------
echo PHP_EOL . "Ableitung der Werte (bin/konfiguration-ableiten.php, ausgeführt)" . PHP_EOL;
$beilage = is_file($BEILAGE) ? (string)file_get_contents($BEILAGE) : '';
pruefe('K4 Beilage tests/daten/config.example-0e80957.php unverändert (SHA-256 wie git show 0e80957:backend/config.example.php)',
    hash('sha256', $beilage) === BEILAGE_SHA256);

$T = sys_get_temp_dir() . '/ps-kern-' . getmypid();
@mkdir($T, 0700, true);
function lauf(array $argumente, bool $schreiben): array
{
    global $ABL;
    $env = ['PATH' => (string)getenv('PATH'), 'LC_ALL' => 'C'];
    if ($schreiben) $env['SCHREIBEN'] = '1';
    $p = proc_open(array_merge([PHP_BINARY, $ABL], $argumente),
        [0 => ['file', '/dev/null', 'r'], 1 => ['pipe', 'w'], 2 => ['pipe', 'w']], $r, null, $env);
    $aus = stream_get_contents($r[1]) . stream_get_contents($r[2]);
    return [proc_close($p), $aus];
}
$ausgeben = function (string $art, string $datei): string {
    [$code, $aus] = lauf([$art, $datei], false);
    return $code === 0 ? trim($aus) : '';
};

if (!is_file($ABL)) {
    pruefe('K4 bin/konfiguration-ableiten.php vorhanden – die Ableitung lief nicht', false);
} else {
    // Die Quelle: die Beilage mit einem erfundenen Probewert. Er muss im
    // Ergebnis stehen und darf in keiner Ausgabe erscheinen.
    $PROBEWERT = 'PROBEWERT-k4-7f3a91';
    $quelle = str_replace("'DEIN_DATENBANKPASSWORT'", "'$PROBEWERT'", $beilage, $n);
    file_put_contents("$T/config.php", $quelle);
    $namen = $ausgeben('namen', $VORL);
    $finger = $ausgeben('fingerabdruecke', $BEILAGE);
    pruefe('K4 Vorbereitung: Probewert eingesetzt (1×), Namen und Fingerabdrücke ausgegeben',
        $n === 1 && $namen !== '' && substr_count($finger, ':') === 8, "Ersetzungen $n, Fingerabdrücke '$finger'");

    [$c, $aus] = lauf(['ableiten', "$T/config.php", "$T/konfiguration.php", $namen, $finger], false);
    pruefe('K4 trocken: Exit 0, keine Datei, alle acht Funktionen „gleich“',
        $c === 0 && !file_exists("$T/konfiguration.php") && substr_count($aus, ': gleich') === 8,
        "Exit $c; " . str_replace("\n", ' | ', trim($aus)));

    [$c, $aus] = lauf(['ableiten', "$T/config.php", "$T/konfiguration.php", $namen, $finger], true);
    $erg = is_file("$T/konfiguration.php") ? (string)file_get_contents("$T/konfiguration.php") : '';
    $rechte = is_file("$T/konfiguration.php") ? (fileperms("$T/konfiguration.php") & 0777) : 0;
    exec(escapeshellarg(PHP_BINARY) . ' -l ' . escapeshellarg("$T/konfiguration.php") . ' 2>&1', $_l, $lint);
    pruefe('K4 schreibend: Datei mit Rechten 0600, ohne Funktion, mit allen Namen der Vorlage, php -l sauber',
        $c === 0 && $rechte === 0600 && funktionen($erg) === [] && $lint === 0
        && array_diff($vorlNamen, wertnamen($erg)) === [],
        sprintf('Exit %d, Rechte %o, Funktionen %s, lint %d, fehlende Namen %s', $c, $rechte,
            implode(',', funktionen($erg)), $lint, implode(',', array_diff($vorlNamen, wertnamen($erg)))));
    pruefe('K4 der Wert steht im Ergebnis und in keiner Ausgabe',
        str_contains($erg, $PROBEWERT) && !str_contains($aus, $PROBEWERT));

    // Voraussetzung: Es gibt eine Datei, die überschrieben werden könnte.
    $da = is_file("$T/konfiguration.php");
    $vorher = $da ? hash_file('sha256', "$T/konfiguration.php") : '';
    [$c, $aus] = lauf(['ableiten', "$T/config.php", "$T/konfiguration.php", $namen, $finger], true);
    pruefe('K4 überschreibt nicht: zweiter Lauf hält an, Datei unverändert',
        $da && $c !== 0 && hash_file('sha256', "$T/konfiguration.php") === $vorher,
        $da ? "Exit $c" : 'Voraussetzung fehlt: keine Datei aus dem ersten Lauf');

    [$c, $aus] = lauf(['pruefen', "$T/konfiguration.php", $namen], false);
    pruefe('K4 pruefen: die abgeleitete Datei führt alle Namen der Vorlage', $c === 0, trim($aus));
    file_put_contents("$T/unvollstaendig.php", str_replace("define('SCHULE_ID', 1);", '', $erg, $n3));
    [$c, $aus] = lauf(['pruefen', "$T/unvollstaendig.php", $namen], false);
    pruefe('K4 pruefen: fehlt SCHULE_ID, hält es an und nennt den Namen, ohne Wert',
        $n3 === 1 && $c !== 0 && str_contains($aus, 'SCHULE_ID') && !str_contains($aus, $PROBEWERT),
        "Entfernt {$n3}×, Exit $c");

    if (is_file("$T/konfiguration.php")) unlink("$T/konfiguration.php");
    file_put_contents("$T/config.php", $quelle . "\nfunction probe_fremd(): void {}\n");
    [$c, $aus] = lauf(['ableiten', "$T/config.php", "$T/konfiguration.php", $namen, $finger], true);
    pruefe('K4 unbekannte Funktion in der Quelle: hält an, keine Datei, nennt sie',
        $c !== 0 && !file_exists("$T/konfiguration.php") && str_contains($aus, 'probe_fremd'), "Exit $c");

    $abw = str_replace('return htmlspecialchars(trim($s), ENT_QUOTES, \'UTF-8\');',
                       'return htmlspecialchars($s, ENT_QUOTES, \'UTF-8\');', $quelle, $n2);
    file_put_contents("$T/config.php", $abw);
    [$c, $aus] = lauf(['ableiten', "$T/config.php", "$T/konfiguration.php", $namen, $finger], true);
    pruefe('K4 abweichende Funktion (clean): hält an, keine Datei, nennt „clean: abweichend“',
        $n2 === 1 && $c !== 0 && !file_exists("$T/konfiguration.php") && str_contains($aus, 'clean: abweichend'),
        "Ersetzung $n2, Exit $c");
}
foreach (glob("$T/*") ?: [] as $f) unlink($f);
@rmdir($T);

// ------------------------------------------------------------------
// K5 Probebäume anderer Prüfungen
// ------------------------------------------------------------------
echo PHP_EOL . "Probebäume (Quelltext)" . PHP_EOL;
$kt   = (string)@file_get_contents("$W/tests/kontotyp_test.php");
$ktdb = (string)@file_get_contents("$W/tests/kontotyp_db_test.sh");
pruefe("K5 tests/kontotyp_test.php lässt konfiguration.php* und config.php* aus dem Probebaum (Quelltext)",
    str_contains($kt, "str_starts_with(basename(\$rel), 'konfiguration.php')")
    && str_contains($kt, "str_starts_with(basename(\$rel), 'config.php')"));
pruefe("K5 tests/kontotyp_db_test.sh lässt konfiguration.php* und config.php* aus dem Probebaum (Quelltext)",
    str_contains($ktdb, "! -name 'konfiguration.php*'") && str_contains($ktdb, "! -name 'config.php*'"));

exit($fehler === 0 ? 0 : 1);
