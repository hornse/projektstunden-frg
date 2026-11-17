<?php
/**
 * Projektstunden NRW – tests/anmeldebremse_test.php
 * Die Anmeldebremse aus dem Modul, und der Weg durch handle_auth
 *
 * Seit Auftrag A (koordination AUFTRAG-projektstunden-A-anmeldung-modul.md,
 * Paket 2; E68) kommt die Bremse aus hornse/webuntis-auth-php v2.0.2
 * (vendort, backend/auth/Anmeldebremse.php): gezählt nach Kennung UND ZIEL,
 * in einer eigenen Tabelle anmeldebremse, ohne Adresse. Der Verlauf steht
 * getrennt in anmeldeverlauf (sql/23), ebenfalls ohne Adresse. Sätze,
 * Schwelle und Ziel stehen projekteigen in backend/auth/anmeldung.php.
 *
 * Die 42 Prüfungen der früheren, projekteigenen Bremse (bis 0e80957) sind
 * EINZELN übertragen; ihre Nummer steht vorn im Namen (#1 … #42). Wo eine
 * nicht mehr zutraf, steht an ihrer Nummer, was an ihre Stelle trat (#1,
 * #7, #8, #10, #40). Neu sind V2, V3 und N1–N6.
 *
 * AUSGEFÜHRT gegen SQLite: die Bremse mit gestellter Uhr (JETZT liegt fest
 * und weit vom Schreibtag, REIHENREGELN 2), der Weg durch handle_auth mit
 * der echten Uhr. Die Tabellen kommen aus der vendorten SQLite-Fassung bzw.
 * aus der MariaDB-Migration, übersetzt, mit Prüfung der Spalten.
 *
 * Aufruf: php tests/anmeldebremse_test.php   → Exit-Code 0 = alles grün
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

declare(strict_types=1);

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
foreach (['backend/auth/anmeldung.php', 'backend/auth/WebUntisAuth.php'] as $d) {
    if (is_file("$W/$d")) require_once "$W/$d";
}
$da = class_exists('Anmeldebremse') && class_exists('Anmeldung');

// ---- vendort: byte-gleich mit dem Modul, bis auf den Kopfvermerk ---------
echo PHP_EOL . 'Vendort aus hornse/webuntis-auth-php v2.0.2' . PHP_EOL;
// Prüfsummen der Modulfassung, gemessen am 12.11.2026:
//   git -C webuntis-auth-php show v2.0.2:<datei> | shasum -a 256
const MODUL = [
    'backend/auth/Anmeldebremse.php'        => ['e3bd265a93bb03d037f76ec67b46c33a295bce687e5582980afe19c09009b8b4', 2],
    'sql/22_anmeldebremse.sql'              => ['4e381a856927f51d77805ec473a06e949889b774728096d05320972a23f91336', 1],
    'tests/daten/anmeldebremse.sqlite.sql'  => ['ce3defb3dc2aa6c5f65d9b0171c47334d680ff5ff21385972378cdac7c091239', 1],
];
const VERMERK = 'VENDORED aus hornse/webuntis-auth-php v2.0.2 – dort ändern, hierher kopieren!';
$vendort = function (string $datei) use ($W): bool {
    [$sha, $zeile] = MODUL[$datei];
    if (!is_file("$W/$datei")) return false;
    $z = explode("\n", (string)file_get_contents("$W/$datei"));
    $vermerk = $z[$zeile - 1] ?? '';
    unset($z[$zeile - 1]);
    return str_contains($vermerk, VERMERK) && hash('sha256', implode("\n", $z)) === $sha;
};
pruefe('#1 backend/auth/Anmeldebremse.php ist Modul v2.0.2: Kopfvermerk in Zeile 2, sonst byte-gleich (SHA-256)',
    $vendort('backend/auth/Anmeldebremse.php'));
pruefe('V2 sql/22_anmeldebremse.sql ist anmeldebremse.mariadb.sql aus v2.0.2: Kopfvermerk in Zeile 1, sonst byte-gleich',
    $vendort('sql/22_anmeldebremse.sql'));
pruefe('V3 tests/daten/anmeldebremse.sqlite.sql ist anmeldebremse.sqlite.sql aus v2.0.2: Kopfvermerk in Zeile 1, sonst byte-gleich',
    $vendort('tests/daten/anmeldebremse.sqlite.sql'));

// ---- die Tabellen ------------------------------------------------------------
$verlaufDdl = (string)@file_get_contents("$W/sql/23_migration_anmeldeverlauf.sql");
$block = preg_match('/CREATE TABLE IF NOT EXISTS anmeldeverlauf \((.*?)\n\) ENGINE/s', $verlaufDdl, $m) === 1 ? $m[1] : '';
preg_match_all('/^\s+([a-z_]+)\s+(?:INT|TINYINT|VARCHAR|DATETIME|BIGINT)/m', $block, $sp);
const SQLITE_VERLAUF = 'CREATE TABLE anmeldeverlauf (
    id INTEGER PRIMARY KEY AUTOINCREMENT, benutzername TEXT NOT NULL, ziel TEXT NOT NULL DEFAULT \'\',
    erfolgreich INTEGER NOT NULL DEFAULT 0, grund TEXT NULL, zeitpunkt DATETIME NOT NULL)';
$bremseSqlite = (string)@file_get_contents("$W/tests/daten/anmeldebremse.sqlite.sql");
function neue_db(): PDO
{
    global $bremseSqlite;
    $p = new PDO('sqlite::memory:', null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
    if ($bremseSqlite !== '') $p->exec($bremseSqlite);
    $p->exec(SQLITE_VERLAUF);
    // KENNUNGEN BEGINNEN NICHT BEI 0 (REIHENREGELN 2).
    $p->exec("INSERT INTO sqlite_sequence (name, seq) VALUES ('anmeldebremse', 4710)");
    $p->exec("INSERT INTO sqlite_sequence (name, seq) VALUES ('anmeldeverlauf', 8150)");
    return $p;
}
$p0 = neue_db();
$bremseSpalten = array_column($p0->query('PRAGMA table_info(anmeldebremse)')->fetchAll(), 'name');
pruefe('#8 Voraussetzung: anmeldebremse aus der vendorten SQLite-Datei (id, kennung, ziel, zeitpunkt, erfolg) und '
    . 'anmeldeverlauf aus sql/23 (id, benutzername, ziel, erfolgreich, grund, zeitpunkt) – keine Adressspalte',
    $bremseSpalten === ['id', 'kennung', 'ziel', 'zeitpunkt', 'erfolg']
    && $sp[1] === ['id', 'benutzername', 'ziel', 'erfolgreich', 'grund', 'zeitpunkt']);

// ---- die Bremse mit gestellter Uhr -------------------------------------------
const JETZT = 2000000000;          // 18.05.2033, fest
const ZIEL  = 'webuntis:schule.example';
$uhr = fn(): int => JETZT;
$bremse = fn(PDO $p) => $da ? Anmeldung::bremse($p, $uhr) : null;
// $n Fehlversuche, der jüngste vor $letzter Sekunden, je $abstand Sekunden auseinander.
$reihe = fn(int $n, int $letzter, int $abstand): array => array_map(fn($i) => $letzter + $abstand * ($n - 1 - $i), range(0, $n - 1));
function fehl(PDO $p, string $wer, array $alter, string $ziel = ZIEL, int $jetzt = JETZT): void
{
    foreach ($alter as $a) {
        $p->prepare('INSERT INTO anmeldebremse (kennung, ziel, zeitpunkt, erfolg) VALUES (?, ?, ?, 0)')
          ->execute([strtolower($wer), $ziel, $jetzt - $a]);
    }
}
$zeilen = fn(PDO $p): int => (int)$p->query('SELECT COUNT(*) FROM anmeldebremse')->fetchColumn();
$beginnen = function (PDO $p, string $wer, string $ziel = ZIEL) use ($bremse, $da): array {
    if (!$da) return ['ergebnis' => '', 'versuch' => null, 'sekunden' => null];
    try { return $bremse($p)->beginnen($wer, $ziel); }
    catch (Throwable $e) { echo '    (Ausnahme: ' . get_class($e) . ' ' . $e->getMessage() . ')' . PHP_EOL;
                           return ['ergebnis' => 'ausnahme', 'versuch' => null, 'sekunden' => null]; }
};
$durch  = fn(array $r): bool => $r['ergebnis'] === 'erlaubt';
$wartet = fn(array $r, ?int $s = null): bool => $r['ergebnis'] === 'warten' && ($s === null || $r['sekunden'] === $s);
$anmelden = function (PDO $p, string $wer) use ($beginnen, $bremse): void {
    $r = $beginnen($p, $wer);
    if ($r['ergebnis'] === 'erlaubt') $bremse($p)->abschliessen((int)$r['versuch'], Anmeldebremse::ERFOLG);
};

echo PHP_EOL . 'Das Urteil: ab der Schwelle 60 Sekunden, ohne Staffel' . PHP_EOL;
$S = $da ? Anmeldung::SCHWELLE : 5;
pruefe('#2 Schwelle: acht Fehlversuche (M56), Wartezeit 60 s – Konstanten von Anmeldung, an einer Stelle',
    $da && Anmeldung::SCHWELLE === 8 && Anmeldung::WARTEZEIT_S === 60);
$p = neue_db(); fehl($p, 'Vzq', array_fill(0, $S - 1, 0));
pruefe('#3 unter der Schwelle (' . ($S - 1) . ', gerade eben): durch', $durch($beginnen($p, 'Vzq')));
$p = neue_db(); fehl($p, 'Vzq', array_fill(0, $S, 0));
$r = $beginnen($p, 'Vzq');
pruefe('#4 an der Schwelle (' . $S . '), gerade eben: warten, 60 Sekunden, der Satz nennt sie',
    $wartet($r, 60) && $da && str_contains(Anmeldung::satzWarten(60), '60 Sekunden'));
$p = neue_db(); fehl($p, 'Vzq', array_fill(0, $S, 59)); $r59 = $beginnen($p, 'Vzq');
$p = neue_db(); fehl($p, 'Vzq', array_fill(0, $S, 60)); $r60 = $beginnen($p, 'Vzq');
pruefe('#5 auf der Grenze: 59 s nach dem letzten noch 1 Sekunde („1 Sekunde.“), nach 60 s durch',
    $wartet($r59, 1) && $da && str_ends_with(Anmeldung::satzWarten(1), ' 1 Sekunde.') && $durch($r60));
$p = neue_db(); fehl($p, 'Vzq', array_fill(0, 30, 0));
pruefe('#6 ohne Staffel: 30 Fehlversuche warten wie die Schwelle – 60 Sekunden', $wartet($beginnen($p, 'Vzq'), 60));
pruefe('#7 Zählung gescheitert hat einen eigenen Satz, nicht „Ungültige Anmeldedaten“',
    $da && str_contains(Anmeldung::SATZ_BREMSE_FEHLER, 'Anmeldeversuche') && !str_contains(Anmeldung::SATZ_BREMSE_FEHLER, 'Anmeldedaten'));

echo PHP_EOL . 'Zuerst eintragen, dann zählen' . PHP_EOL;
$p = neue_db();
$r = $beginnen($p, 'Vzq');
$z = $durch($r) ? $p->query('SELECT * FROM anmeldebremse WHERE id = ' . (int)$r['versuch'])->fetch() : false;
pruefe('#9 ohne Vorgeschichte: durch, der Versuch steht schon da – erfolg 0, Zeit der Uhr, Kennung ab 4711',
    is_array($z) && $z['kennung'] === 'vzq' && (int)$z['erfolg'] === 0 && (int)$z['zeitpunkt'] === JETZT && (int)$z['id'] >= 4711);
$p = neue_db(); fehl($p, 'Vzq', array_fill(0, $S - 1, 30));
$r1 = $beginnen($p, 'Vzq'); $r2 = $beginnen($p, 'Vzq');
pruefe('#11 gleichzeitig: einer unter der Schwelle, zwei Anfragen – die erste läuft, die zweite sieht sie und wartet',
    $durch($r1) && $wartet($r2));
pruefe('#12 der abgewiesene Versuch zählt nicht: seine Zeile ist wieder fort', $zeilen($p) === $S);

echo PHP_EOL . 'Im Tempo einer Person' . PHP_EOL;
$p = neue_db(); fehl($p, 'Vzq', $reihe($S, 15, 15));
pruefe('#13 Schwelle erreicht im Abstand von 15 s, der letzte vor 15 s: der nächste wartet 45 s', $wartet($beginnen($p, 'Vzq'), 45));
$p = neue_db(); fehl($p, 'Vzq', $reihe($S, 61, 60));
pruefe('#14 … der letzte vor 61 s: durch – keine Sperre über 15 Minuten', $durch($beginnen($p, 'Vzq')));

echo PHP_EOL . 'Die Grenze, ausgeführt' . PHP_EOL;
$p = neue_db(); fehl($p, 'Vzq', $reihe($S, 58, 5));
pruefe('#15 der letzte an der Schwelle vor 58 s: abgewiesen, 2 s Rest', $wartet($beginnen($p, 'Vzq'), 2));
$p = neue_db(); fehl($p, 'Vzq', $reihe($S, 60, 5));
pruefe('#16 der letzte an der Schwelle vor 60 s: durch', $durch($beginnen($p, 'Vzq')));
$p = neue_db(); fehl($p, 'Vzq', [...array_fill(0, $S - 1, 17 * 60), 1]);
pruefe('#17 Fenster: einer unter der Schwelle vor 17 Minuten und einer vor 1 s – nur der eine zählt, durch', $durch($beginnen($p, 'Vzq')));
$p = neue_db(); fehl($p, 'andere', array_fill(0, $S + 1, 1));
pruefe('#18 je Kennung: fremde Fehlversuche über der Schwelle, gerade eben, zählen nicht', $durch($beginnen($p, 'Vzq')));

echo PHP_EOL . 'Eine gelungene Anmeldung setzt zurück' . PHP_EOL;
$p = neue_db(); fehl($p, 'Vzq', $reihe($S, 320, 20)); $anmelden($p, 'Vzq'); fehl($p, 'Vzq', [1]);
pruefe('#19 Rücksetzen: Schwelle erreicht, dann angemeldet, dann einer vor 1 s – durch', $durch($beginnen($p, 'Vzq')));
$p = neue_db(); fehl($p, 'Vzq', [...$reihe($S, 320, 20), 1]);
pruefe('#20 Gegenprobe: dieselben ohne Anmeldung dazwischen – es wird gewartet', $wartet($beginnen($p, 'Vzq')));
$p = neue_db(); fehl($p, 'Vzq', $reihe($S - 1, 340, 20)); $anmelden($p, 'Vzq'); fehl($p, 'Vzq', array_fill(0, $S, 0));
pruefe('#21 nach der Nummer: Schwelle erreicht in derselben Sekunde wie die Anmeldung, danach eingetragen – sie zählen',
    $wartet($beginnen($p, 'Vzq')));
$p = neue_db(); fehl($p, 'andere', $reihe($S, 320, 20)); $anmelden($p, 'Vzq'); fehl($p, 'andere', [1]);
pruefe('#22 je Kennung: die Anmeldung eines anderen setzt nicht zurück', $wartet($beginnen($p, 'andere')));

echo PHP_EOL . 'Die bekannte Grenze: ein Skript im Minutentakt' . PHP_EOL;
$p = neue_db(); fehl($p, 'Vzq', $reihe($S, 1, 60));
pruefe('#23 Skript im Minutentakt, der letzte vor 1 s: der Inhaber muss warten (59 s)', $wartet($beginnen($p, 'Vzq'), 59));
$p = neue_db(); fehl($p, 'Vzq', $reihe($S, 60, 60));
pruefe('#24 … und der nächste Versuch des Skripts nach der Minute ist wieder durch', $durch($beginnen($p, 'Vzq')));

echo PHP_EOL . 'Die Datenbank antwortet nicht; ohne Entscheid' . PHP_EOL;
$p = neue_db(); $p->exec('DROP TABLE anmeldebremse');
pruefe('#25 ohne Tabelle: Ergebnis FEHLER – abgewiesen, unterscheidbar von WARTEN', $beginnen($p, 'Vzq')['ergebnis'] === 'fehler');
$p = neue_db(); $r = $beginnen($p, 'Vzq');
if ($durch($r)) $bremse($p)->abschliessen((int)$r['versuch'], Anmeldebremse::OHNE_ENTSCHEID);
pruefe('#26 ohne Entscheid: der laufende Eintrag verschwindet, nichts bleibt', $durch($r) && $zeilen($p) === 0);
$WU_TOT = ['base_url' => 'https://127.0.0.1:9', 'school' => 'probe', 'client' => 'probe',
           'allowed_person_types' => [2, 16, 5], 'connect_timeout' => 2, 'timeout' => 2,
           'max_failed_logins' => $S, 'lockout_minutes' => 15];
$p = neue_db();
$wu = class_exists('WebUntisAuth') ? new WebUntisAuth($p, $WU_TOT) : null;
$erg = null;
try { $erg = $wu?->authenticateAndGetDetails('Vzq', 'irgendwas'); }
catch (Throwable $e) { echo '    (Ausnahme: ' . get_class($e) . ' ' . $e->getMessage() . ')' . PHP_EOL; $erg = 'ausnahme'; }
pruefe('#27 WebUntisAuth: WebUntis antwortet nicht – null, Grund „ohne_entscheid“, und es schreibt nichts selbst',
    $wu !== null && $erg === null && $wu->grund() === 'ohne_entscheid' && $zeilen($p) === 0
    && (int)$p->query('SELECT COUNT(*) FROM anmeldeverlauf')->fetchColumn() === 0);

echo PHP_EOL . 'Das Ziel' . PHP_EOL;
$wuB = ['base_url' => 'https://Schule.Example/'];
pruefe('N5 Ziel: E-Mail-Kennung → „lokal“, Kürzel → „webuntis:<Host, kleingeschrieben>“',
    $da && Anmeldung::ziel('ada@probe.invalid', $wuB) === 'lokal' && Anmeldung::ziel('Vzq', $wuB) === 'webuntis:schule.example');
$p = neue_db(); fehl($p, 'Vzq', array_fill(0, $S, 0), 'webuntis:spielwiese.example');
pruefe('N4 Ziel trennt: acht Fehlversuche gegen die Spielwiese bremsen den Betrieb nicht – dort warten sie',
    $durch($beginnen($p, 'Vzq', 'webuntis:schule.example')) && $wartet($beginnen($p, 'Vzq', 'webuntis:spielwiese.example')));
$p = neue_db();
if ($da) Anmeldung::verlauf($p, 'Vzq', ZIEL, false, 'probe', $uhr);
$v = $p->query('SELECT benutzername, ziel, erfolgreich, grund, zeitpunkt FROM anmeldeverlauf')->fetchAll();
pruefe('N6 Verlauf: eine Zeile mit Kennung, Ziel, Ausgang, Grund und der Zeit der übergebenen Uhr, ab 8151',
    count($v) === 1 && $v[0]['benutzername'] === 'Vzq' && $v[0]['ziel'] === ZIEL && (int)$v[0]['erfolgreich'] === 0
    && $v[0]['grund'] === 'probe' && $v[0]['zeitpunkt'] === date('Y-m-d H:i:s', JETZT)
    && (int)$p->query('SELECT MAX(id) FROM anmeldeverlauf')->fetchColumn() === 8151);

// ---- der ganze Weg: handle_auth ausgeführt ---------------------------------
// handle_auth steht im Router (backend/api/index.php), der beim Laden den
// Kern einbindet und sofort verteilt. Deshalb wird nur die Funktion aus dem
// Quelltext gelöst und ausgeführt. Ersetzt sind nur die Ränder:
// json_response/json_error werfen die Antwort statt exit, get_db liefert die
// Prüf-Datenbank, session_start_secure tut nichts. Zwei Fassungen: einmal mit
// dem echten WebUntisAuth gegen einen toten Port, einmal mit einer Attrappe;
// für die zweite wird AUSSCHLIESSLICH der Klassenname bei `new` getauscht.
// Hier läuft die echte Uhr; Fehlversuche „vor n Sekunden“ beziehen sich auf sie.
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
$quelle = preg_match('/^function handle_auth\(.*?^\}/ms', $router, $m) === 1 ? $m[0] : '';
pruefe('#28 Voraussetzung: handle_auth im Router gefunden', str_contains($quelle, 'function handle_auth('));
$quelle = str_replace('__DIR__', var_export("$W/backend/api", true), $quelle);
$attrappe = str_replace(['function handle_auth(', 'new WebUntisAuth('], ['function handle_auth_attrappe(', 'new WebUntisAttrappe('], $quelle);
$weg = $quelle !== '';
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
$b = fn(PDO $p): array => $p->query('SELECT kennung, ziel, erfolg FROM anmeldebremse ORDER BY id')->fetchAll();
$v = fn(PDO $p): array => $p->query('SELECT benutzername, erfolgreich, grund FROM anmeldeverlauf ORDER BY id')->fetchAll();
$jetztFehl = fn(PDO $p, string $wer, array $alter, string $ziel) => fehl($p, $wer, $alter, $ziel, time());
$WEBUNTIS_CONFIG = $WU_TOT;
$ZIEL_WU = 'webuntis:127.0.0.1';
$fehler_satz = fn(array $r): string => (string)($r['daten']['error'] ?? '');
$alleGruende = [];
$gruende = function (PDO $p) use (&$alleGruende, $v): void { foreach ($v($p) as $z) $alleGruende[] = (string)$z['grund']; };

$p = neue_db(); $benutzer($p);
$r = $login($p, 'ada@schule.example', 'Das lokale Passwort');
pruefe('#29 lokal, richtiges Passwort: angemeldet; Bremse eine Zeile erfolg 1 unter „lokal“, Verlauf „lokal“',
    $r['status'] === 200 && $b($p) === [['kennung' => 'ada@schule.example', 'ziel' => 'lokal', 'erfolg' => 1]]
    && $v($p) === [['benutzername' => 'ada@schule.example', 'erfolgreich' => 1, 'grund' => 'lokal']]);
$gruende($p);
$p = neue_db(); $benutzer($p);
$r = $login($p, 'ada@schule.example', 'falsch');
pruefe('#30 lokal falsch, WebUntis tot: 401 – und der Versuch zählt, denn das lokale Passwort hat entschieden',
    $r['status'] === 401 && $b($p) === [['kennung' => 'ada@schule.example', 'ziel' => 'lokal', 'erfolg' => 0]]
    && ($v($p)[0]['grund'] ?? '') === 'falsches_lokales_passwort');
$gruende($p);
$p = neue_db(); $benutzer($p);
for ($i = 0; $i < $S; $i++) $login($p, 'ada@schule.example', 'falsch-' . $i);
$r = $login($p, 'ada@schule.example', 'Das lokale Passwort');
pruefe('#31 lokal, Schwelle erreicht gerade eben: auch das richtige Passwort wartet – 429 mit Sekunden, Verlauf „wartezeit“',
    $r['status'] === 429 && preg_match('/ \d+ Sekunden?\.$/', $fehler_satz($r)) === 1 && (end($v($p))['grund'] ?? '') === 'wartezeit');
$gruende($p);
$p = neue_db(); $benutzer($p);
$r = $login($p, 'Vzq', 'irgendwas');
// Satz und Status wie in der Reihe (FALLSTRICKE 8). Erwartungswert, keine Abschrift aus dem Code.
pruefe('#32 kein lokales Konto, WebUntis tot: 503 „WebUntis ist gerade nicht erreichbar. …“, keine Zeile in der Bremse, Verlauf „webuntis_nicht_erreichbar“',
    $r['status'] === 503
    && $fehler_satz($r) === 'WebUntis ist gerade nicht erreichbar. Bitte in ein paar Minuten erneut versuchen.'
    && $zeilen($p) === 0 && ($v($p)[0]['grund'] ?? '') === 'webuntis_nicht_erreichbar');
$gruende($p);
$p = neue_db(); $benutzer($p);
$WEBUNTIS_CONFIG = ['max_failed_logins' => 5, 'lockout_minutes' => 1] + $WU_TOT;
for ($i = 0; $i < 5; $i++) $login($p, 'ada@schule.example', 'falsch-' . $i);
$r = $login($p, 'ada@schule.example', 'Das lokale Passwort');
$WEBUNTIS_CONFIG = $WU_TOT;
pruefe('#33 Konfiguration sagt max_failed_logins 5: nach fünf Fehlversuchen trotzdem angemeldet – die Schwelle kommt nicht von dort',
    $r['status'] === 200);
$p = neue_db(); $benutzer($p);
$p->exec('DROP TABLE anmeldebremse');
$r = $login($p, 'ada@schule.example', 'Das lokale Passwort');
pruefe('#34 die Zählung scheitert: 503 mit eigenem Satz – auch vor dem richtigen lokalen Passwort, Verlauf „bremse_fehler“',
    $r['status'] === 503 && $fehler_satz($r) === 'Die Anmeldung ist gerade nicht möglich – die Prüfung der '
    . 'Anmeldeversuche antwortet nicht. Bitte in ein paar Minuten noch einmal.' && ($v($p)[0]['grund'] ?? '') === 'bremse_fehler');
$gruende($p);

echo PHP_EOL . 'Der ganze Weg: handle_auth, WebUntis antwortet (Attrappe)' . PHP_EOL;
$p = neue_db(); $benutzer($p);
WebUntisAttrappe::$ergebnis = null; WebUntisAttrappe::$grundWert = 'falsches_passwort';
$r = $login($p, 'Vzq', 'falsch', true);
pruefe('#35 WebUntis: falsches Passwort – 401 „Ungültige Anmeldedaten.“, eine Zeile unter webuntis:<Host>, sie zählt',
    $r['status'] === 401 && $fehler_satz($r) === 'Ungültige Anmeldedaten.'
    && $b($p) === [['kennung' => 'vzq', 'ziel' => $ZIEL_WU, 'erfolg' => 0]] && ($v($p)[0]['grund'] ?? '') === 'falsches_passwort');
$gruende($p);
$p = neue_db(); $benutzer($p);
$jetztFehl($p, 'Vzq', $reihe($S, 10, 5), $ZIEL_WU);
WebUntisAttrappe::$aufrufe = 0;
$r = $login($p, 'Vzq', 'richtig', true);
pruefe('#36 WebUntis: Schwelle erreicht gerade eben – 429, und WebUntis wird gar nicht erst gefragt',
    $r['status'] === 429 && WebUntisAttrappe::$aufrufe === 0);
$p = neue_db(); $benutzer($p);
WebUntisAttrappe::$ergebnis = ['personType' => 2, 'personId' => 99, 'kuerzel' => 'Vzq', 'vorname' => 'S', 'nachname' => 'H'];
WebUntisAttrappe::$grundWert = null;
$r = $login($p, 'Vzq', 'richtig', true);
pruefe('#37 WebUntis: Lehrkraft angemeldet – 200, eine Zeile, erfolg 1 (setzt zurück)',
    $r['status'] === 200 && $b($p) === [['kennung' => 'vzq', 'ziel' => $ZIEL_WU, 'erfolg' => 1]]);
$gruende($p);
$p = neue_db(); $benutzer($p);
WebUntisAttrappe::$ergebnis = ['personType' => 5, 'personId' => 99, 'key' => ''];
$r = $login($p, 'max.muster', 'richtig', true);
pruefe('#38 WebUntis: Schüler ohne Schild-ID – 401 wie ein falsches Passwort, die Zeile zählt (E66), Verlauf „schueler_id_fehlt“',
    $r['status'] === 401 && $fehler_satz($r) === 'Ungültige Anmeldedaten.'
    && $b($p) === [['kennung' => 'max.muster', 'ziel' => $ZIEL_WU, 'erfolg' => 0]] && ($v($p)[0]['grund'] ?? '') === 'schueler_id_fehlt');
$gruende($p);
$p = neue_db(); $benutzer($p);
WebUntisAttrappe::$ergebnis = null; WebUntisAttrappe::$grundWert = 'falsche_rolle';
$r = $login($p, 'Vzq', 'richtig', true);
pruefe('#39 WebUntis: falsche Rolle – 401 wie ein falsches Passwort, die Zeile zählt',
    $r['status'] === 401 && $b($p) === [['kennung' => 'vzq', 'ziel' => $ZIEL_WU, 'erfolg' => 0]]);
$gruende($p);
$p = neue_db(); $benutzer($p);
WebUntisAttrappe::$ergebnis = null; WebUntisAttrappe::$grundWert = 'schule_unbekannt';
$r = $login($p, 'Vzq', 'egal', true);
pruefe('N1 WebUntis -8500: 503 „Die Anmeldung ist gerade nicht möglich. Bitte der Schule Bescheid geben.“, zählt nicht, Verlauf „schule_unbekannt“',
    $r['status'] === 503 && $fehler_satz($r) === 'Die Anmeldung ist gerade nicht möglich. Bitte der Schule Bescheid geben.'
    && $zeilen($p) === 0 && ($v($p)[0]['grund'] ?? '') === 'schule_unbekannt');
$gruende($p);
$p = neue_db(); $benutzer($p);
$r = $login($p, 'ada@schule.example', 'falsch', true);
pruefe('N2 WebUntis -8500 nach falschem lokalem Passwort: 401, der Versuch zählt – das lokale Passwort hat entschieden',
    $r['status'] === 401 && $b($p) === [['kennung' => 'ada@schule.example', 'ziel' => 'lokal', 'erfolg' => 0]]);
$gruende($p);
$p = neue_db(); $benutzer($p);
WebUntisAttrappe::$grundWert = 'http_abgelehnt';
$r = $login($p, 'Vzq', 'egal', true);
pruefe('N3 WebUntis antwortet mit HTTP 4xx: 401 wie ein falsches Passwort, der Versuch zählt (M55: nur Transportfehler sind ohne Entscheid)',
    $r['status'] === 401 && $b($p) === [['kennung' => 'vzq', 'ziel' => $ZIEL_WU, 'erfolg' => 0]] && ($v($p)[0]['grund'] ?? '') === 'http_abgelehnt');
$gruende($p);
$lang = array_filter($alleGruende, fn($g) => strlen($g) > 50);
pruefe('#10 alle ' . count(array_unique($alleGruende)) . ' Gründe, die handle_auth oben in den Verlauf schrieb, passen in grund VARCHAR(50)',
    count(array_unique($alleGruende)) >= 8 && $lang === [] && str_contains($block, 'grund        VARCHAR(50)'));

// ---- wer schreibt wohin -----------------------------------------------------
echo PHP_EOL . 'Wer in welche Tabelle schreibt (Quelltext)' . PHP_EOL;
$alle = '';
foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator("$W/backend", FilesystemIterator::SKIP_DOTS)) as $x) {
    $n = basename((string)$x);
    if (str_ends_with($n, '.php') && !str_starts_with($n, 'config.php') && !str_starts_with($n, 'konfiguration.php')) {
        $alle .= (string)file_get_contents((string)$x);
    }
}
$anm = (string)@file_get_contents("$W/backend/auth/anmeldung.php");
pruefe('#40 niemand unter backend/ nennt webuntis_login_log mehr, und in anmeldeverlauf schreibt nur Anmeldung::verlauf',
    !str_contains($alle, 'webuntis_login_log') && substr_count($alle, 'INSERT INTO anmeldeverlauf') === 1
    && str_contains($anm, 'INSERT INTO anmeldeverlauf'));

echo PHP_EOL . 'Eine Stelle je Satz und je Schwelle (Quelltext, Tokenizer)' . PHP_EOL;
$literale = function (string $code): array {
    $l = [];
    foreach (token_get_all($code) as $t) {
        if (is_array($t) && $t[0] === T_CONSTANT_ENCAPSED_STRING) $l[] = substr($t[1], 1, -1);
    }
    return $l;
};
pruefe('#41 „Ungültige Anmeldedaten.“ ist eine Konstante von Anmeldung und steht im Router nicht als Zeichenkette',
    $da && Anmeldung::SATZ_ABGELEHNT === 'Ungültige Anmeldedaten.' && !in_array('Ungültige Anmeldedaten.', $literale($router), true));
$vorlage = (string)@file_get_contents("$W/backend/konfiguration.example.php");
pruefe('#42 die Vorlage nennt weder Schwelle noch Zählfenster (kein max_failed_logins, kein lockout_minutes) – sie würden nicht gelesen',
    $vorlage !== '' && !in_array('max_failed_logins', $literale($vorlage), true) && !in_array('lockout_minutes', $literale($vorlage), true));

echo PHP_EOL . ($fehler === 0 ? 'ALLE TESTS GRÜN' : "$fehler ROT") . PHP_EOL;
exit($fehler === 0 ? 0 : 1);
