<?php
/**
 * Projektstunden NRW – tests/anmeldebremse_test.php
 * Die Anmeldebremse: Wartezeit statt Sperre
 *
 * Auftrag aus koordination (AUFTRAG-anmeldebremse-reihe.md, 16.10.2026,
 * fortgesetzt am 21.10.): die Bauart der Reihe, wie in schulprozesse und
 * signage. Bis hier sperrte WebUntisAuth nach 5 Fehlversuchen 15 Minuten
 * lang – auch den Inhaber mit dem richtigen Passwort –, jeder abgewiesene
 * Versuch verlängerte die Sperre, ein nicht erreichbares WebUntis zählte
 * als Fehlversuch, und der lokale Login (E-Mail + Passwort) war gar nicht
 * gebremst.
 *
 * AUSGEFÜHRT gegen SQLite. Die Tabelle ist in MariaDB-Form angelegt
 * (sql/06_migration_webuntis_auth.sql); hier wird sie nach SQLite
 * übersetzt, und eine Prüfung hält fest, dass die Spalten dieselben sind.
 *
 * Aufruf: php tests/anmeldebremse_test.php   → Exit-Code 0 = alles grün
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

declare(strict_types=1);

// Warnungen der Prüfumgebung (Sitzung und Header im CLI, curl_close unter
// PHP 8.5) gehen nach stderr, nicht zwischen die Prüfzeilen.
ini_set('display_errors', 'stderr');

$fehler = 0;
function pruefe(string $name, bool $ok): void
{
    global $fehler;
    echo ($ok ? '  ✓ ' : '  ✗ ') . $name . PHP_EOL;
    if (!$ok) $fehler++;
}
set_exception_handler(function (Throwable $e): void {
    echo '  ✗ Suite abgebrochen: ' . get_class($e) . ': ' . $e->getMessage() . PHP_EOL;
    exit(1);
});

$W = dirname(__DIR__);
foreach (['backend/auth/Anmeldebremse.php', 'backend/auth/WebUntisAuth.php'] as $d) {
    if (is_file("$W/$d")) require_once "$W/$d";
}

$da = class_exists('Anmeldebremse');
pruefe('Voraussetzung: Anmeldebremse vorhanden (backend/auth/Anmeldebremse.php)', $da);

const SCHWELLE = 5;     // config.example.php, max_failed_logins
const FENSTER  = 15;    // config.example.php, lockout_minutes

// ---- das Urteil, rein ------------------------------------------------------
echo PHP_EOL . 'Das Urteil: ab der Schwelle 60 Sekunden, ohne Staffel' . PHP_EOL;
$u = fn(?array $lage): array => $da ? Anmeldebremse::urteil($lage, SCHWELLE) : ['durch' => null, 'status' => 0, 'meldung' => ''];
$l = fn(int $n, ?int $seit): array => ['fehlversuche' => $n, 'seit' => $seit];
pruefe('unter der Schwelle (4): durch', $u($l(4, 0))['durch'] === true);
pruefe('an der Schwelle (5), gerade eben: 429, „60 Sekunden“',
    $u($l(5, 0))['status'] === 429 && str_contains($u($l(5, 0))['meldung'], '60 Sekunden'));
pruefe('auf der Grenze: 59 s nach dem letzten noch „1 Sekunde“, nach 60 s durch',
    $u($l(5, 59))['status'] === 429 && str_contains($u($l(5, 59))['meldung'], '1 Sekunde.')
    && $u($l(5, 60))['durch'] === true);
pruefe('ohne Staffel: 30 Fehlversuche warten wie 5 – 60 Sekunden', str_contains($u($l(30, 0))['meldung'], '60 Sekunden'));
pruefe('Zählung gescheitert: 503 mit eigenem Satz, nicht „Ungültige Anmeldedaten“',
    $u(null)['status'] === 503 && $u(null)['durch'] === false
    && str_contains($u(null)['meldung'], 'Anmeldeversuche') && !str_contains($u(null)['meldung'], 'Anmeldedaten'));

// ---- die Tabelle aus der Migration ----------------------------------------
$ddl = (string)file_get_contents("$W/sql/06_migration_webuntis_auth.sql");
$block = preg_match('/CREATE TABLE IF NOT EXISTS webuntis_login_log \((.*?)\n\) ENGINE/s', $ddl, $m) === 1 ? $m[1] : '';
preg_match_all('/^\s+([a-z_]+)\s+(?:INT|TINYINT|VARCHAR|DATETIME)/m', $block, $sp);
$spalten = $sp[1];
pruefe('Voraussetzung: webuntis_login_log aus der Migration gelesen – genau diese Spalten',
    $spalten === ['id', 'benutzername', 'erfolgreich', 'grund', 'ip', 'zeitpunkt']);
const SQLITE_TABELLE = 'CREATE TABLE webuntis_login_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT, benutzername TEXT NOT NULL,
    erfolgreich INTEGER NOT NULL DEFAULT 0, grund TEXT NULL, ip TEXT NULL,
    zeitpunkt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP)';
function neue_db(): PDO
{
    $p = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
    $p->exec(SQLITE_TABELLE);
    // KENNUNGEN BEGINNEN NICHT BEI 0 – in lernzeiten war eine Prüfung blind,
    // weil sie bei 1 begannen.
    $p->exec("INSERT INTO sqlite_sequence (name, seq) VALUES ('webuntis_login_log', 4710)");
    return $p;
}
function fehl(PDO $p, string $wer, array $alter): void
{
    foreach ($alter as $a) {
        $p->prepare("INSERT INTO webuntis_login_log (benutzername, erfolgreich, grund, ip, zeitpunkt)
                     VALUES (?, 0, 'falsches_passwort', '', datetime('now', ?))")->execute([$wer, '-' . $a . ' seconds']);
    }
}
$zeilen = fn(PDO $p): int => (int)$p->query('SELECT COUNT(*) FROM webuntis_login_log')->fetchColumn();
$beginnen = function (PDO $p, string $wer) use ($da): array {
    if (!$da) return ['id' => 0, 'status' => 0, 'meldung' => ''];
    // Jede Ausnahme wird an der Prüfung rot, die sie auslöst – nicht als
    // Abbruch der Suite.
    try { $r = Anmeldebremse::beginnen($p, $wer, '', SCHWELLE, FENSTER); }
    catch (Throwable $e) { echo '    (Ausnahme: ' . get_class($e) . ' ' . $e->getMessage() . ')' . PHP_EOL;
                           return ['id' => 0, 'status' => -1, 'meldung' => '']; }
    return ['id' => $r['id'], 'status' => $r['urteil']['status'], 'meldung' => $r['urteil']['meldung']];
};
$anmelden = function (PDO $p, string $wer) use ($beginnen, $da): void {
    $r = $beginnen($p, $wer);
    if ($da && $r['status'] === 200) Anmeldebremse::abschliessen($p, $r['id'], true, null);
};

echo PHP_EOL . 'Zuerst eintragen, dann zählen' . PHP_EOL;
$p = neue_db();
$r = $beginnen($p, 'Hor');
$z = $r['status'] === 200 ? $p->query('SELECT * FROM webuntis_login_log WHERE id = ' . (int)$r['id'])->fetch() : false;
pruefe('ohne Vorgeschichte: durch, der Versuch steht schon da – laufend, Kennung ab 4711',
    $r['status'] === 200 && is_array($z) && $z['benutzername'] === 'Hor' && (int)$z['erfolgreich'] === 0
    && $z['grund'] === '(läuft)' && (int)$z['id'] >= 4711);
pruefe('der Grund „(läuft)“ passt in die Spalte (VARCHAR(50))',
    $da && mb_strlen(Anmeldebremse::LAEUFT) <= 50 && str_contains($block, 'grund        VARCHAR(50)'));
$p = neue_db();
fehl($p, 'Hor', [30, 30, 30, 30]);
$r1 = $beginnen($p, 'Hor');
$r2 = $beginnen($p, 'Hor');
pruefe('gleichzeitig: 4 Fehlversuche, zwei Anfragen – die erste läuft, die zweite sieht sie und wartet',
    $r1['status'] === 200 && $r2['status'] === 429);
pruefe('der abgewiesene Versuch zählt nicht: seine Zeile ist wieder fort', $zeilen($p) === 5);

echo PHP_EOL . 'Im Tempo einer Person' . PHP_EOL;
$p = neue_db();
fehl($p, 'Hor', [75, 60, 45, 30, 15]);
$r = $beginnen($p, 'Hor');
pruefe('fünf Fehlversuche im Abstand von 15 s, der letzte vor 15 s: der sechste wartet, 44–45 s, mit Satz',
    $r['status'] === 429 && preg_match('/noch (44|45) Sekunden\./', $r['meldung']) === 1);
$p = neue_db();
fehl($p, 'Hor', [600, 540, 480, 420, 61]);
pruefe('… der letzte vor 61 s: durch – keine Sperre über 15 Minuten', $beginnen($p, 'Hor')['status'] === 200);

echo PHP_EOL . 'Die Grenze, ausgeführt' . PHP_EOL;
$p = neue_db();
fehl($p, 'Hor', [300, 290, 280, 270, 58]);
pruefe('der letzte von 5 vor 58 s: abgewiesen, 1–2 s Rest',
    preg_match('/noch [12] Sekunden?\./', $beginnen($p, 'Hor')['meldung']) === 1);
$p = neue_db();
fehl($p, 'Hor', [300, 290, 280, 270, 60]);
pruefe('der letzte von 5 vor 60 s: durch', $beginnen($p, 'Hor')['status'] === 200);
$p = neue_db();
fehl($p, 'Hor', [17 * 60, 17 * 60, 17 * 60, 17 * 60, 1]);
pruefe('Fenster: 4 Fehlversuche vor 17 Minuten und einer vor 1 s – nur der eine zählt, durch',
    $beginnen($p, 'Hor')['status'] === 200);
$p = neue_db();
fehl($p, 'andere', [1, 1, 1, 1, 1, 1]);
pruefe('je Benutzer: 6 fremde Fehlversuche gerade eben zählen nicht', $beginnen($p, 'Hor')['status'] === 200);

echo PHP_EOL . 'Eine gelungene Anmeldung setzt zurück' . PHP_EOL;
$p = neue_db();
fehl($p, 'Hor', [400, 380, 360, 340, 320]);
$anmelden($p, 'Hor');
fehl($p, 'Hor', [1]);
pruefe('Rücksetzen: 5 Fehlversuche, dann angemeldet, dann einer vor 1 s – durch', $beginnen($p, 'Hor')['status'] === 200);
$p = neue_db();
fehl($p, 'Hor', [400, 380, 360, 340, 320, 1]);
pruefe('Gegenprobe: dieselben sechs ohne Anmeldung dazwischen – es wird gewartet', $beginnen($p, 'Hor')['status'] === 429);
$p = neue_db();
fehl($p, 'Hor', [400, 380, 360, 340]);
$anmelden($p, 'Hor');
$zp = $p->query('SELECT zeitpunkt FROM webuntis_login_log WHERE erfolgreich = 1')->fetchColumn();
for ($i = 0; $i < 5; $i++) {
    $p->prepare("INSERT INTO webuntis_login_log (benutzername, erfolgreich, grund, ip, zeitpunkt) VALUES ('Hor', 0, 'falsches_passwort', '', ?)")
      ->execute([(string)$zp]);
}
pruefe('nach der Nummer: fünf Fehlversuche in derselben Sekunde wie die Anmeldung, danach eingetragen – sie zählen',
    $zp !== false && $beginnen($p, 'Hor')['status'] === 429);
$p = neue_db();
fehl($p, 'andere', [400, 380, 360, 340, 320]);
$anmelden($p, 'Hor');
fehl($p, 'andere', [1]);
pruefe('je Benutzer: die Anmeldung eines anderen setzt nicht zurück', $beginnen($p, 'andere')['status'] === 429);

echo PHP_EOL . 'Die bekannte Grenze: ein Skript im Minutentakt' . PHP_EOL;
$p = neue_db();
fehl($p, 'Hor', [241, 181, 121, 61, 1]);
$r = $beginnen($p, 'Hor');
pruefe('Skript im Minutentakt, der letzte vor 1 s: der Inhaber muss warten (58–59 s)',
    $r['status'] === 429 && preg_match('/noch (58|59) Sekunden\./', $r['meldung']) === 1);
$p = neue_db();
fehl($p, 'Hor', [300, 240, 180, 120, 60]);
pruefe('… und der nächste Versuch des Skripts nach der Minute ist wieder durch', $beginnen($p, 'Hor')['status'] === 200);

echo PHP_EOL . 'Die Datenbank antwortet nicht' . PHP_EOL;
$p = neue_db();
$p->exec('DROP TABLE webuntis_login_log');
$r = $beginnen($p, 'Hor');
pruefe('ohne Tabelle: abgewiesen mit 503 und eigenem Satz, nicht „Ungültige Anmeldedaten“',
    $r['status'] === 503 && str_contains($r['meldung'], 'Anmeldeversuche') && !str_contains($r['meldung'], 'Anmeldedaten'));

echo PHP_EOL . 'Ohne Entscheid: WebUntis nicht erreichbar' . PHP_EOL;
$p = neue_db();
$r = $beginnen($p, 'Hor');
if ($da && $r['status'] === 200) Anmeldebremse::ohneEntscheid($p, $r['id']);
pruefe('ohne Entscheid: der laufende Eintrag verschwindet, nichts bleibt', $da && $zeilen($p) === 0);
// WebUntis zeigt auf einen Port, an dem niemand antwortet.
$WU_TOT = ['base_url' => 'https://127.0.0.1:9', 'school' => 'probe', 'client' => 'probe',
           'allowed_person_types' => [2, 16, 5], 'connect_timeout' => 2, 'timeout' => 2,
           'max_failed_logins' => SCHWELLE, 'lockout_minutes' => FENSTER];
$p = neue_db();
$wu = class_exists('WebUntisAuth') ? new WebUntisAuth($p, $WU_TOT) : null;
$erg = null;
try { $erg = $wu?->authenticateAndGetDetails('Hor', 'irgendwas'); }
catch (Throwable $e) { echo '    (Ausnahme: ' . get_class($e) . ' ' . $e->getMessage() . ')' . PHP_EOL; $erg = 'ausnahme'; }
pruefe('WebUntisAuth: WebUntis antwortet nicht – null, Grund „ohne_entscheid“, und es schreibt nichts mehr selbst',
    $wu !== null && $erg === null && method_exists($wu, 'grund') && $wu->grund() === 'ohne_entscheid' && $zeilen($p) === 0);

// ---- der ganze Weg: handle_auth ausgeführt ---------------------------------
// handle_auth steht im Router (backend/api/index.php), der beim Laden die
// Konfiguration einbindet und sofort verteilt. Deshalb wird nur die Funktion
// samt Helfer aus dem Quelltext gelöst und ausgeführt. Ersetzt sind nur die
// Ränder: json_response/json_error werfen die Antwort statt exit, get_db
// liefert die Prüf-Datenbank, session_start_secure tut nichts.
// Zwei Fassungen: einmal mit dem echten WebUntisAuth gegen einen toten Port
// (der Notfall), einmal mit einer Attrappe, die eine Antwort von WebUntis
// nachstellt. Für die zweite wird im gelösten Quelltext AUSSCHLIESSLICH der
// Klassenname bei `new` ausgetauscht – gekennzeichnet, kein Eingriff in den
// Ablauf.
echo PHP_EOL . 'Der ganze Weg: handle_auth' . PHP_EOL;
final class Antwort extends Exception
{
    public function __construct(public int $status, public mixed $daten) { parent::__construct('antwort'); }
}
function json_response(mixed $data, int $status = 200): never { throw new Antwort($status, $data); }
function json_error(string $msg, int $status = 400): never { throw new Antwort($status, ['error' => $msg]); }
function session_start_secure(): void {}
function get_db(): PDO { return $GLOBALS['PRUEF_DB']; }
const SCHULE_ID = 1;
const WEBUNTIS_ENABLED = true;

final class WebUntisAttrappe
{
    public static ?array $ergebnis = null;
    public static ?string $grundWert = null;
    public static int $aufrufe = 0;
    public function __construct(PDO $db, array $config) {}
    public function authenticateAndGetDetails(string $u, string $p): ?array { self::$aufrufe++; return self::$ergebnis; }
    public function grund(): ?string { return self::$grundWert; }
}

$router = (string)file_get_contents("$W/backend/api/index.php");
$quelle = '';
foreach (['handle_auth', 'bremse_beginnen'] as $fn) {
    if (preg_match('/^function ' . $fn . '\(.*?^\}/ms', $router, $m) === 1) $quelle .= $m[0] . "\n";
}
pruefe('Voraussetzung: handle_auth und bremse_beginnen im Router gefunden',
    str_contains($quelle, 'function handle_auth(') && str_contains($quelle, 'function bremse_beginnen('));
$quelle = str_replace('__DIR__', var_export("$W/backend/api", true), $quelle);
$attrappe = str_replace(['function handle_auth(', 'function bremse_beginnen(', 'bremse_beginnen(', 'new WebUntisAuth('],
                        ['function handle_auth_attrappe(', 'function bremse_beginnen_a(', 'bremse_beginnen_a(', 'new WebUntisAttrappe('],
                        $quelle);
$weg = str_contains($quelle, 'function bremse_beginnen(');
if ($weg) { eval($quelle); eval($attrappe); }

$benutzer = function (PDO $p): void {
    $p->exec("CREATE TABLE benutzer (id INTEGER PRIMARY KEY, schule_id INTEGER NOT NULL, vorname TEXT, nachname TEXT,
              email TEXT, passwort_hash TEXT, rolle TEXT, kuerzel TEXT, aktiv INTEGER NOT NULL DEFAULT 1)");
    $p->prepare("INSERT INTO benutzer (id, schule_id, vorname, nachname, email, passwort_hash, rolle, kuerzel)
                 VALUES (4711, 1, 'Ada', 'Lovelace', 'ada@schule.example', ?, 'admin', 'Lov')")
      ->execute([password_hash('Das lokale Passwort', PASSWORD_BCRYPT)]);
};
$login = function (PDO $p, string $wer, string $pw, bool $attr = false) use ($weg): array {
    if (!$weg) return ['status' => 0, 'daten' => null];
    $GLOBALS['PRUEF_DB'] = $p;
    $_SESSION = [];
    try { $attr ? handle_auth_attrappe('POST', 'login', ['username' => $wer, 'passwort' => $pw])
                : handle_auth('POST', 'login', ['username' => $wer, 'passwort' => $pw]);
          return ['status' => -1, 'daten' => null]; }
    catch (Antwort $a) { return ['status' => $a->status, 'daten' => $a->daten]; }
};
$alle = fn(PDO $p): array => $p->query('SELECT erfolgreich, grund FROM webuntis_login_log ORDER BY id')->fetchAll();
$WEBUNTIS_CONFIG = $WU_TOT;

$p = neue_db(); $benutzer($p);
$r = $login($p, 'ada@schule.example', 'Das lokale Passwort');
$a = $alle($p);
pruefe('lokal, richtiges Passwort: angemeldet, eine Zeile – erfolgreich, „lokal“',
    $r['status'] === 200 && count($a) === 1 && (int)$a[0]['erfolgreich'] === 1 && $a[0]['grund'] === 'lokal');
$p = neue_db(); $benutzer($p);
$r = $login($p, 'ada@schule.example', 'falsch');
$a = $alle($p);
pruefe('lokal falsch, WebUntis tot: 401 – und der Versuch zählt, denn das lokale Passwort hat entschieden',
    $r['status'] === 401 && count($a) === 1 && (int)$a[0]['erfolgreich'] === 0 && $a[0]['grund'] === 'falsches_lokales_passwort');
$p = neue_db(); $benutzer($p);
for ($i = 0; $i < SCHWELLE; $i++) $login($p, 'ada@schule.example', 'falsch-' . $i);
$r = $login($p, 'ada@schule.example', 'Das lokale Passwort');
pruefe('lokal, fünf Fehlversuche gerade eben: auch das richtige Passwort wartet – 429 mit Sekunden',
    $r['status'] === 429 && preg_match('/noch \d+ Sekunden?\./', (string)($r['daten']['error'] ?? '')) === 1);
$p = neue_db(); $benutzer($p);
$r = $login($p, 'Hor', 'irgendwas');
pruefe('kein lokales Konto, WebUntis tot: 401, und es bleibt keine Zeile – kein Passwort hat entschieden',
    $r['status'] === 401 && $zeilen($p) === 0);
$p = neue_db(); $benutzer($p);
$p->exec('DROP TABLE webuntis_login_log');
$r = $login($p, 'ada@schule.example', 'Das lokale Passwort');
pruefe('die Zählung scheitert: 503 mit eigenem Satz – auch vor dem lokalen Passwort',
    $r['status'] === 503 && str_contains((string)($r['daten']['error'] ?? ''), 'Anmeldeversuche'));

echo PHP_EOL . 'Der ganze Weg: handle_auth, WebUntis antwortet (Attrappe)' . PHP_EOL;
$p = neue_db(); $benutzer($p);
WebUntisAttrappe::$ergebnis = null; WebUntisAttrappe::$grundWert = 'falsches_passwort';
$r = $login($p, 'Hor', 'falsch', true);
$a = $alle($p);
pruefe('WebUntis: falsches Passwort – 401 „Ungültige Anmeldedaten.“, eine Zeile, sie zählt',
    $r['status'] === 401 && ($r['daten']['error'] ?? '') === 'Ungültige Anmeldedaten.'
    && count($a) === 1 && (int)$a[0]['erfolgreich'] === 0 && $a[0]['grund'] === 'falsches_passwort');
$p = neue_db(); $benutzer($p);
fehl($p, 'Hor', [50, 40, 30, 20, 10]);
WebUntisAttrappe::$aufrufe = 0;
$r = $login($p, 'Hor', 'richtig', true);
pruefe('WebUntis: fünf Fehlversuche gerade eben – 429, und WebUntis wird gar nicht erst gefragt',
    $r['status'] === 429 && WebUntisAttrappe::$aufrufe === 0);
$p = neue_db(); $benutzer($p);
WebUntisAttrappe::$ergebnis = ['personType' => 2, 'personId' => 99, 'kuerzel' => 'Hor', 'vorname' => 'S', 'nachname' => 'H'];
WebUntisAttrappe::$grundWert = null;
$r = $login($p, 'Hor', 'richtig', true);
$a = $alle($p);
pruefe('WebUntis: Lehrkraft angemeldet – 200, eine Zeile, erfolgreich (setzt zurück)',
    $r['status'] === 200 && count($a) === 1 && (int)$a[0]['erfolgreich'] === 1);
$p = neue_db(); $benutzer($p);
WebUntisAttrappe::$ergebnis = ['personType' => 5, 'personId' => 99, 'key' => ''];
$r = $login($p, 'max.muster', 'richtig', true);
$a = $alle($p);
pruefe('WebUntis: Schüler ohne Schild-ID – 401 wie ein falsches Passwort, EINE Zeile mit dem Grund, sie zählt',
    $r['status'] === 401 && ($r['daten']['error'] ?? '') === 'Ungültige Anmeldedaten.'
    && count($a) === 1 && (int)$a[0]['erfolgreich'] === 0 && $a[0]['grund'] === 'schueler_id_fehlt');
$p = neue_db(); $benutzer($p);
WebUntisAttrappe::$ergebnis = null; WebUntisAttrappe::$grundWert = 'falsche_rolle';
$r = $login($p, 'Hor', 'richtig', true);
$a = $alle($p);
pruefe('WebUntis: falsche Rolle – 401 wie ein falsches Passwort, die Zeile zählt',
    $r['status'] === 401 && count($a) === 1 && (int)$a[0]['erfolgreich'] === 0 && $a[0]['grund'] === 'falsche_rolle');

// ---- wer schreibt in die Tabelle -------------------------------------------
echo PHP_EOL . 'Wer in webuntis_login_log schreibt (Quelltext)' . PHP_EOL;
$auth = (string)file_get_contents("$W/backend/auth/WebUntisAuth.php");
pruefe('nur noch die Anmeldebremse – kein INSERT im Router und in WebUntisAuth.php',
    !str_contains($router, 'INSERT INTO webuntis_login_log') && !str_contains($auth, 'INSERT INTO webuntis_login_log'));

echo PHP_EOL . ($fehler === 0 ? 'ALLE TESTS GRÜN' : "$fehler ROT") . PHP_EOL;
exit($fehler === 0 ? 0 : 1);
