<?php
/**
 * Projektstunden NRW – tests/kontotyp_test.php
 * Filter nach Kontotyp (Z1) und Wächter für Lehrkraft-Handler (Z2), ohne Datenbank
 *
 * Anlass: Befund Z1/Z2 (koordination docs/BEFUND-2026-11-04-personendaten.md
 * §10), belegt am 04.11.2026 in einer Probe mit erfundenen Daten: Eine
 * Schülersitzung erreichte jede Route der Lehrkräfte, und ein Schüler mit
 * derselben Nummer wie eine Lernbegleitung bekam deren Werkstätten.
 * Auftrag: koordination docs/AUFTRAG-projektstunden-kontotyp.md.
 *
 * Zwei Stufen, die sich UNTERSCHIEDLICH melden (REIHENREGELN 2):
 *   A  der Filter im Verteiler (backend/api/index.php, vor dem match):
 *      Eine Sitzung, deren typ nicht genau 'benutzer' ist, erreicht nur die
 *      Routen der Erlaubnisliste; sonst 403 mit KONTOTYP_SATZ_FILTER.
 *   B  der Wächter require_lehrkraft() am Kopf jedes Lehrkraft-Handlers:
 *      403 mit KONTOTYP_SATZ_WAECHTER.
 * Beide in backend/api/kontotyp.php.
 *
 * Die Datenbank fehlt hier absichtlich: Der Filter greift vor jedem
 * Datenbankzugriff. Ein Handler, der erreicht wird, antwortet mit
 * „Datenbankfehler.“ (500) oder seinem eigenen Satz – beides ist NICHT der
 * Satz des Filters. Was nur mit Daten zu sehen ist (Z2, die Lehrkraftseite
 * mit Inhalt, jede Stufe einzeln), misst tests/kontotyp_db_test.sh.
 *
 *   K1  Routen aus dem match des Verteilers ermittelt (Tokenizer); null = rot
 *   K2  je Route: Schülersitzung und Sitzung ohne typ, vier Methoden –
 *       außerhalb der Liste 403 mit dem Satz des Filters, auf der Liste nie
 *   K3  unbekannte Route als Schüler: 403 mit dem Satz des Filters
 *   K4  je Route: Lehrkraftsitzung, vier Methoden – nie Filter, nie Wächter
 *   K5  ohne Cookie: Logo erreicht den Handler, setzt kein Cookie; 401 bleibt
 *   K6  Liste im Code gleich der ERWARTUNG in tests/daten/kontotyp_erlaubt.json
 *   K7  die Schülerfunktionen in app.js rufen nur Routen der Erwartung
 *   K8  Aufrufstelle im Verteiler, vor dem match – RÜCKFALL, misst Quelltext
 *   K9  require_auth() nur in drei Handlern, sonst require_lehrkraft()
 *       – RÜCKFALL, misst Quelltext
 *   K10 die Sätze von Filter, Wächter und Handlern sind verschieden
 *
 * Die Sitzungen sind Dateien mit genau den Schlüsseln, die die Anmeldung
 * setzt (index.php, Schüler- und Lehrkraftzweig). ERFUNDEN: alle Nummern.
 * Gegenproben: tests/mutationen_kontotyp.sh.
 *
 * Aufruf: php tests/kontotyp_test.php   → Exit-Code 0 = alles grün
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

declare(strict_types=1);

ini_set('display_errors', 'stderr');

$fehler = 0;
function pruefe(string $name, bool $ok, array $details = []): void
{
    global $fehler;
    echo ($ok ? '  ✓ ' : '  ✗ ') . $name . PHP_EOL;
    if (!$ok) {
        $fehler++;
        foreach (array_slice($details, 0, 8) as $d) echo "      $d" . PHP_EOL;
        if (count($details) > 8) echo '      … und ' . (count($details) - 8) . ' weitere' . PHP_EOL;
    }
}
set_exception_handler(function (Throwable $e): void {
    echo '  ✗ Suite abgebrochen: ' . get_class($e) . ': ' . $e->getMessage() . PHP_EOL;
    exit(1);
});

$WURZEL   = dirname(__DIR__);
$INDEX    = $WURZEL . '/backend/api/index.php';
$KONTOTYP = $WURZEL . '/backend/api/kontotyp.php';
$ERWART   = __DIR__ . '/daten/kontotyp_erlaubt.json';

// ------------------------------------------------------------------
// Die Erwartung und die Sätze
// ------------------------------------------------------------------
$erwartung = json_decode((string)@file_get_contents($ERWART), true)['erlaubt'] ?? null;
if (!is_array($erwartung) || $erwartung === []) {
    pruefe('Erwartung tests/daten/kontotyp_erlaubt.json lesbar und nicht leer', false);
    exit(1);
}
function erwartet_erlaubt(array $erwartung, string $methode, string $route, string $sub): bool
{
    foreach ($erwartung as $e) {
        if ($e['route'] === $route
            && ($e['methode'] === '*' || $e['methode'] === $methode)
            && ($e['sub'] === '*' || $e['sub'] === $sub)) return true;
    }
    return false;
}

// Die Funktionen der Anwendung. Fehlt die Datei, sind die Sätze unbekannt –
// dann kann keine Prüfung, die den Satz des Filters verlangt, grün werden.
if (is_file($KONTOTYP)) require_once $KONTOTYP;
$SATZ_FILTER   = defined('KONTOTYP_SATZ_FILTER')   ? (string)constant('KONTOTYP_SATZ_FILTER')   : null;
$SATZ_WAECHTER = defined('KONTOTYP_SATZ_WAECHTER') ? (string)constant('KONTOTYP_SATZ_WAECHTER') : null;

// ------------------------------------------------------------------
// Quelltext: Tokens ohne Kommentare und Leerraum
// ------------------------------------------------------------------
/** @return list<array{0:int|string,1:string}> */
function code_tokens(string $datei): array
{
    $aus = [];
    foreach (token_get_all((string)file_get_contents($datei)) as $t) {
        if (is_array($t) && in_array($t[0], [T_COMMENT, T_DOC_COMMENT, T_WHITESPACE], true)) continue;
        $aus[] = is_array($t) ? [$t[0], $t[1]] : [0, $t];
    }
    return $aus;
}
$TOK = code_tokens($INDEX);

// ------------------------------------------------------------------
// K1 – Routen aus dem match des Verteilers
// ------------------------------------------------------------------
$routen = [];
$matchPos = null;
for ($i = 0; $i < count($TOK) - 4; $i++) {
    if ($TOK[$i][1] === 'match' && $TOK[$i + 1][1] === '(' && $TOK[$i + 2][1] === '$route'
        && $TOK[$i + 3][1] === ')' && $TOK[$i + 4][1] === '{') {
        $matchPos = $i;
        $tiefe = 0;
        for ($j = $i + 4; $j < count($TOK); $j++) {
            if ($TOK[$j][1] === '{') $tiefe++;
            if ($TOK[$j][1] === '}') { $tiefe--; if ($tiefe === 0) break; }
            // Nur Schlüssel der obersten Ebene: Zeichenkette, gefolgt von =>
            if ($tiefe === 1 && $TOK[$j][0] === T_CONSTANT_ENCAPSED_STRING
                && ($TOK[$j + 1][0] ?? null) === T_DOUBLE_ARROW) {
                $routen[] = trim($TOK[$j][1], "'\"");
            }
        }
        break;
    }
}
pruefe('Routen aus dem match des Verteilers ermittelt: ' . count($routen)
    . ' (null wäre ein Fehler)', $routen !== []);

// ------------------------------------------------------------------
// Probebaum und php -S
// ------------------------------------------------------------------
function freier_port(): int
{
    $s = stream_socket_server('tcp://127.0.0.1:0', $en, $es);
    if ($s === false) throw new RuntimeException("kein freier Port: $es");
    $name = (string)stream_socket_get_name($s, false);
    fclose($s);
    return (int)substr($name, strrpos($name, ':') + 1);
}
/** @return array{0: resource, 1: int} */
function server_starten(string $wurzel): array
{
    $port = freier_port();
    $p = proc_open([PHP_BINARY, '-S', "127.0.0.1:$port", 'backend/router.php'],
        [0 => ['file', '/dev/null', 'r'], 1 => ['file', '/dev/null', 'w'],
         2 => ['file', '/dev/null', 'w']], $rohre, $wurzel);
    if (!is_resource($p)) throw new RuntimeException("php -S in $wurzel nicht gestartet");
    for ($i = 0; $i < 50; $i++) {
        $f = @fsockopen('127.0.0.1', $port, $en, $es, 0.2);
        if ($f !== false) { fclose($f); return [$p, $port]; }
        usleep(100000);
    }
    proc_terminate($p);
    throw new RuntimeException("php -S in $wurzel antwortet nicht auf Port $port");
}
/** @return array{code:int, kopf:string, fehler:?string} */
function abrufen(int $port, string $methode, string $uri, ?string $cookie): array
{
    $f = fsockopen('127.0.0.1', $port, $en, $es, 5);
    if ($f === false) throw new RuntimeException("Abruf $methode $uri: $es");
    $rumpf = in_array($methode, ['POST', 'PUT'], true) ? '{}' : '';
    fwrite($f, "$methode $uri HTTP/1.0\r\nHost: 127.0.0.1\r\nConnection: close\r\n"
        . ($cookie !== null ? "Cookie: $cookie\r\n" : '')
        . ($rumpf !== '' ? "Content-Type: application/json\r\nContent-Length: " . strlen($rumpf) . "\r\n" : '')
        . "\r\n" . $rumpf);
    $roh = (string)stream_get_contents($f);
    fclose($f);
    [$kopf, $inhalt] = array_pad(explode("\r\n\r\n", $roh, 2), 2, '');
    preg_match('#^HTTP/\S+ (\d{3})#', $kopf, $m);
    $j = json_decode($inhalt, true);
    return ['code' => (int)($m[1] ?? 0), 'kopf' => $kopf,
            'fehler' => is_array($j) && isset($j['error']) ? (string)$j['error'] : null];
}
function baum_loeschen(string $d): void
{
    if (!is_dir($d)) return;
    $it = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($d, FilesystemIterator::SKIP_DOTS),
        RecursiveIteratorIterator::CHILD_FIRST);
    foreach ($it as $x) { $x->isDir() ? rmdir((string)$x) : unlink((string)$x); }
    rmdir($d);
}

$T = sys_get_temp_dir() . '/ps-kontotyp-' . getmypid();
baum_loeschen($T);
mkdir("$T/sess", 0700, true);
// backend/ ohne die echte Konfiguration: config.php und ihre Sicherungen
// enthalten Zugangsdaten und gehören nicht in einen Probebaum.
$it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator("$WURZEL/backend", FilesystemIterator::SKIP_DOTS));
foreach ($it as $x) {
    $rel = substr((string)$x, strlen($WURZEL) + 1);
    if (str_starts_with(basename($rel), 'config.php')) continue;
    if (!is_dir(dirname("$T/$rel"))) mkdir(dirname("$T/$rel"), 0700, true);
    copy((string)$x, "$T/$rel");
}
// Konfiguration aus der Vorlage: die Funktionen wörtlich, drei Werte ersetzt.
// Die Datenbank zeigt auf einen Port, auf dem nichts lauscht.
$vorlage = (string)file_get_contents("$WURZEL/backend/config.example.php");
$ersetzt = 0;
$konfig = $vorlage;
foreach ([
    "ini_set('session.save_path', '/home/hornse/tmp/sessions');" => "ini_set('session.save_path', '$T/sess');",
    "define('DB_PORT',    3306);"                                  => "define('DB_PORT',    " . freier_port() . ");",
    "define('WEBUNTIS_ENABLED', true);"                            => "define('WEBUNTIS_ENABLED', false);",
] as $alt => $neu) {
    $konfig = str_replace($alt, $neu, $konfig, $n);
    $ersetzt += $n;
}
if ($ersetzt !== 3) {
    pruefe("Probekonfiguration: 3 Ersetzungen in config.example.php, gefunden $ersetzt", false);
    baum_loeschen($T);
    exit(1);
}
file_put_contents("$T/backend/config.php", $konfig);

// Sitzungen – dieselben Schlüssel wie die Anmeldung, Nummern erfunden.
$SITZUNG = [
    'schueler' => 'benutzer_id|i:157;rolle|s:8:"schueler";schule_id|i:1;typ|s:8:"schueler";',
    'ohne typ' => 'benutzer_id|i:157;rolle|s:6:"lehrer";schule_id|i:1;',
    'lehrkraft'=> 'benutzer_id|i:157;rolle|s:6:"lehrer";schule_id|i:1;typ|s:8:"benutzer";',
];
$COOKIE = [];
foreach ($SITZUNG as $wer => $inhalt) {
    $kennung = 'kt' . substr(md5($wer), 0, 20);
    file_put_contents("$T/sess/sess_$kennung", $inhalt);
    $COOKIE[$wer] = "proj_session=$kennung";
}

$METHODEN = ['GET', 'POST', 'PUT', 'DELETE'];
/** Die Abrufe je Route: vier Methoden auf /api/<route>/73, beim Logo zusätzlich der Unterpfad. */
function abrufe_fuer(string $route, array $methoden): array
{
    $a = [];
    foreach ($methoden as $m) $a[] = [$m, $route, '73'];
    if ($route === 'einstellungen') $a[] = ['GET', $route, 'logo'];
    return $a;
}

$server = null;
try {
    [$server, $port] = server_starten($T);

    // ---- K2 – je Route: Schülersitzung und Sitzung ohne typ ----------
    foreach ($routen as $r) {
        $falsch = []; $gesperrt = 0; $zahl = 0;
        foreach (['schueler', 'ohne typ'] as $wer) {
            foreach (abrufe_fuer($r, $METHODEN) as [$m, $route, $sub]) {
                $zahl++;
                $a = abrufen($port, $m, "/api/$route/$sub", $COOKIE[$wer]);
                if (erwartet_erlaubt($erwartung, $m, $route, $sub)) {
                    if ($SATZ_FILTER === null || $a['fehler'] === $SATZ_FILTER) {
                        $falsch[] = "$m /api/$route/$sub ($wer): erwartet durchgelassen, bekam {$a['code']} „{$a['fehler']}“";
                    }
                } else {
                    $gesperrt++;
                    if ($SATZ_FILTER === null || $a['code'] !== 403 || $a['fehler'] !== $SATZ_FILTER) {
                        $falsch[] = "$m /api/$route/$sub ($wer): erwartet 403 Filter, bekam {$a['code']} „{$a['fehler']}“";
                    }
                }
            }
        }
        pruefe("Schüler und ohne typ: /api/$r – $zahl Abrufe, davon $gesperrt erwartet gesperrt (Satz des Filters)",
            $falsch === [], $falsch);
    }

    // ---- K3 – unbekannte Route --------------------------------------
    $a = abrufen($port, 'GET', '/api/gibtsnicht-kt/73', $COOKIE['schueler']);
    pruefe('Schüler: unbekannte Route → 403 mit dem Satz des Filters',
        $SATZ_FILTER !== null && $a['code'] === 403 && $a['fehler'] === $SATZ_FILTER,
        ["bekam {$a['code']} „{$a['fehler']}“"]);

    // ---- K4 – je Route: Lehrkraftsitzung ----------------------------
    foreach ($routen as $r) {
        $falsch = []; $zahl = 0;
        foreach (abrufe_fuer($r, $METHODEN) as [$m, $route, $sub]) {
            $zahl++;
            $a = abrufen($port, $m, "/api/$route/$sub", $COOKIE['lehrkraft']);
            if ($a['code'] === 0 || ($SATZ_FILTER !== null && $a['fehler'] === $SATZ_FILTER)
                || ($SATZ_WAECHTER !== null && $a['fehler'] === $SATZ_WAECHTER)) {
                $falsch[] = "$m /api/$route/$sub: {$a['code']} „{$a['fehler']}“";
            }
        }
        pruefe("Lehrkraft: /api/$r – $zahl Abrufe, keiner vom Filter oder Wächter abgewiesen",
            $falsch === [], $falsch);
    }

    // ---- K5 – ohne Cookie --------------------------------------------
    $a = abrufen($port, 'GET', '/api/einstellungen/logo', null);
    pruefe('Ohne Cookie: /api/einstellungen/logo erreicht den Handler und setzt kein Cookie',
        $a['code'] !== 0 && $a['fehler'] !== $SATZ_FILTER && stripos($a['kopf'], "\nSet-Cookie:") === false,
        ["{$a['code']} „{$a['fehler']}“, Set-Cookie: " . (stripos($a['kopf'], "\nSet-Cookie:") === false ? 'nein' : 'ja')]);
    $a = abrufen($port, 'GET', '/api/schueler', null);
    pruefe('Ohne Cookie: /api/schueler → 401 wie bisher',
        $a['code'] === 401, ["bekam {$a['code']} „{$a['fehler']}“"]);
} catch (RuntimeException $e) {
    pruefe('Probebaum unter php -S: ' . $e->getMessage(), false);
} finally {
    if (is_resource($server)) { proc_terminate($server); proc_close($server); }
    baum_loeschen($T);
}

// ------------------------------------------------------------------
// K6 – die Liste im Code gegen die Erwartung
// ------------------------------------------------------------------
$falsch = []; $faelle = 0;
if (!function_exists('schueler_route_erlaubt')) {
    $falsch[] = 'schueler_route_erlaubt() fehlt (backend/api/kontotyp.php)';
} else {
    foreach (array_merge($routen, ['gibtsnicht-kt']) as $r) {
        foreach (['GET', 'POST', 'PUT', 'DELETE', 'PATCH'] as $m) {
            foreach (['', '73', 'logo', 'login'] as $sub) {
                $faelle++;
                $soll = erwartet_erlaubt($erwartung, $m, $r, $sub);
                $ist  = schueler_route_erlaubt($m, $r, $sub);
                if ($soll !== $ist) $falsch[] = "$m $r/$sub: Code " . ($ist ? 'frei' : 'zu') . ', erwartet ' . ($soll ? 'frei' : 'zu');
            }
        }
    }
}
pruefe("Erlaubnisliste im Code gleich der Erwartung (tests/daten/kontotyp_erlaubt.json): $faelle Fälle",
    $faelle > 0 && $falsch === [], $falsch);

// ------------------------------------------------------------------
// K7 – die Schüleransicht im Frontend ruft nur Routen der Erwartung
// ------------------------------------------------------------------
// Nur ROUTEN, nicht Methoden: Die Methode steht im Frontend mal im
// Funktionsnamen (GET/POST), mal im fetch-Objekt. Die Methoden misst der
// Browser (tests/browser_test.mjs).
$app = (string)file_get_contents("$WURZEL/frontend/app.js");
$fe = []; $fehlend = [];
foreach (['checkAuth', 'doLogin', 'doLogout', 'showSchuelerPortal', 'ladeSchuelerPortal',
          'schuelerWerkstattDetail', 'selbstEinschaetzung'] as $fn) {
    if (!preg_match('/\nasync function ' . $fn . '\(|\nfunction ' . $fn . '\(/', $app, $m, PREG_OFFSET_CAPTURE)) {
        $fehlend[] = $fn; continue;
    }
    $anfang = $m[0][1];
    $ende = strpos($app, "\n}\n", $anfang);
    $rumpf = substr($app, $anfang, $ende === false ? null : $ende - $anfang);
    preg_match_all('#/api/([a-z-]+)#', $rumpf, $t1);
    preg_match_all('#\b(?:GET|POST|DELETE)\(\s*[`\'"]([a-z-]+)#', $rumpf, $t2);
    foreach (array_merge($t1[1], $t2[1]) as $r) $fe[$r] = true;
}
preg_match_all('#src="/api/([a-z-]+)#', (string)file_get_contents("$WURZEL/frontend/index.html"), $t3);
foreach ($t3[1] as $r) $fe[$r] = true;
$feRouten = array_keys($fe); sort($feRouten);
$soll = array_values(array_unique(array_column($erwartung, 'route'))); sort($soll);
pruefe('Schüleransicht (app.js, index.html) ruft genau die Routen der Erwartung: '
    . implode(', ', $feRouten), $fehlend === [] && $feRouten === $soll,
    array_merge(array_map(fn($f) => "Funktion $f nicht gefunden", $fehlend),
        ['Frontend: ' . implode(', ', $feRouten), 'Erwartung: ' . implode(', ', $soll)]));

// ------------------------------------------------------------------
// K8 – Aufrufstelle im Verteiler (RÜCKFALL: Quelltext, die Wirkung misst K2)
// ------------------------------------------------------------------
$aufruf = ['kontotyp_gefiltert' => [], 'schueler_route_erlaubt' => []];
foreach ($TOK as $i => $t) {
    if (isset($aufruf[$t[1]]) && $t[0] === T_STRING && ($TOK[$i + 1][1] ?? '') === '(') $aufruf[$t[1]][] = $i;
}
pruefe('Verteiler ruft kontotyp_gefiltert() und schueler_route_erlaubt() je genau einmal, vor dem match'
    . ' (Rückfall, misst Quelltext)',
    $matchPos !== null && count($aufruf['kontotyp_gefiltert']) === 1 && count($aufruf['schueler_route_erlaubt']) === 1
    && $aufruf['kontotyp_gefiltert'][0] < $matchPos && $aufruf['schueler_route_erlaubt'][0] < $matchPos,
    ['kontotyp_gefiltert: ' . count($aufruf['kontotyp_gefiltert']) . '×, schueler_route_erlaubt: '
     . count($aufruf['schueler_route_erlaubt']) . '×, match ' . ($matchPos === null ? 'nicht gefunden' : 'gefunden')]);

// ------------------------------------------------------------------
// K9 – Wächter in jedem Lehrkraft-Handler (RÜCKFALL: Quelltext, die Wirkung
//      misst tests/kontotyp_db_test.sh D7)
// ------------------------------------------------------------------
// Ausgenommen sind die Handler, die selbst nach dem Kontotyp verzweigen
// (Anmeldung) oder ihn verlangen (Schülerportal, Selbsteinschätzung).
$OHNE_WAECHTER = ['handle_auth', 'handle_schueler_portal', 'handle_selbsteinschaetzung'];
$funktionen = [];          // Name => [Tokens des Rumpfs]
for ($i = 0; $i < count($TOK); $i++) {
    if ($TOK[$i][0] !== T_FUNCTION || ($TOK[$i + 1][0] ?? null) !== T_STRING) continue;
    $name = $TOK[$i + 1][1];
    $j = $i; while ($j < count($TOK) && $TOK[$j][1] !== '{') $j++;
    $tiefe = 0; $rumpf = [];
    for (; $j < count($TOK); $j++) {
        if ($TOK[$j][1] === '{') $tiefe++;
        if ($TOK[$j][1] === '}') { $tiefe--; if ($tiefe === 0) break; }
        $rumpf[] = $TOK[$j];
    }
    $funktionen[$name] = $rumpf;
    $i = $j;
}
$ruft = function (array $rumpf, string $fn): bool {
    foreach ($rumpf as $k => $t) if ($t[0] === T_STRING && $t[1] === $fn && ($rumpf[$k + 1][1] ?? '') === '(') return true;
    return false;
};
$falsch = []; $handler = 0;
$authGesamt = 0;
foreach ($TOK as $k => $t) if ($t[0] === T_STRING && $t[1] === 'require_auth' && ($TOK[$k + 1][1] ?? '') === '(') $authGesamt++;
$authInAusnahmen = 0;
foreach ($funktionen as $name => $rumpf) {
    if (!str_starts_with($name, 'handle_')) continue;
    $handler++;
    foreach ($rumpf as $k => $t) if ($t[0] === T_STRING && $t[1] === 'require_auth' && ($rumpf[$k + 1][1] ?? '') === '(') {
        if (in_array($name, $OHNE_WAECHTER, true)) $authInAusnahmen++;
        else $falsch[] = "$name ruft require_auth() statt require_lehrkraft()";
    }
    if (!in_array($name, $OHNE_WAECHTER, true) && !$ruft($rumpf, 'require_lehrkraft')) {
        $falsch[] = "$name ruft require_lehrkraft() nicht";
    }
}
if ($authGesamt !== $authInAusnahmen && $falsch === []) $falsch[] = 'require_auth() außerhalb eines Handlers: ' . ($authGesamt - $authInAusnahmen) . '×';
pruefe("Wächter: jeder der $handler Handler außer " . implode(', ', $OHNE_WAECHTER)
    . ' ruft require_lehrkraft(), require_auth() nur dort (Rückfall, misst Quelltext)',
    $handler > 0 && $falsch === [], $falsch);

// ------------------------------------------------------------------
// K10 – die Sätze sind unterscheidbar (Voraussetzung der Gegenproben)
// ------------------------------------------------------------------
$handlerSaetze = [];
for ($i = 0; $i < count($TOK) - 5; $i++) {
    if ($TOK[$i][1] === 'json_error' && $TOK[$i + 1][1] === '(' && $TOK[$i + 2][0] === T_CONSTANT_ENCAPSED_STRING
        && $TOK[$i + 3][1] === ',' && $TOK[$i + 4][1] === '403') {
        $handlerSaetze[] = trim($TOK[$i + 2][1], "'\"");
    }
}
$handlerSaetze = array_values(array_unique($handlerSaetze));
pruefe('Sätze von Filter, Wächter und den ' . count($handlerSaetze) . ' Handler-403 sind paarweise verschieden',
    $SATZ_FILTER !== null && $SATZ_WAECHTER !== null && $SATZ_FILTER !== '' && $SATZ_WAECHTER !== ''
    && $SATZ_FILTER !== $SATZ_WAECHTER && $handlerSaetze !== []
    && !in_array($SATZ_FILTER, $handlerSaetze, true) && !in_array($SATZ_WAECHTER, $handlerSaetze, true),
    ['Filter: ' . var_export($SATZ_FILTER, true), 'Wächter: ' . var_export($SATZ_WAECHTER, true)]);

exit($fehler === 0 ? 0 : 1);
