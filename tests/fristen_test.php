<?php
/**
 * tests/fristen_test.php – Fristen von audit_log und anmeldeverlauf, ausgeführt
 *
 * Auftrag A, Paket 3 (E68). Wird von tests/fristen_db_test.sh gerufen, gegen
 * eine Wegwerf-MariaDB und einen Probebaum mit konfiguration.php aus der
 * Vorlage. Allein aufgerufen prüft es nichts.
 *
 *   php tests/fristen_test.php BAUM vor24|nach24 FEHLERPROTOKOLL
 *
 * vor24:  Schema bis sql/23 – audit_log hat noch ip_adresse.
 * nach24: sql/24 ist eingespielt – die Spalte ist weg. audit() muss dann
 *         weiter schreiben; es fängt Ausnahmen ab, ein Fehler ginge sonst
 *         STILL verloren (Auftrag, Paket 3 b).
 *
 * Frist audit_log: Schuljahr + 1. Die Grenze ist der 01.08. des vorletzten
 * Schuljahresbeginns: Stichtag im Januar 2031 → letzter Beginn 01.08.2030,
 * Grenze 01.08.2029; Stichtag im November 2031 → Grenze 01.08.2030.
 * Frist Verlauf: 30 Tage, über Datumsarithmetik (FALLSTRICKE 4) – der
 * Stichtag liegt nach der Sommerzeitumstellung, damit 30 × 86 400 s eine
 * andere Grenze ergäbe.
 *
 * Alle Zeitpunkte liegen fest und weit vom Schreibtag (REIHENREGELN 2), die
 * Kennungen beginnen nicht bei 0. Kennungen und Namen sind ERFUNDEN.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
declare(strict_types=1);

[$_, $baum, $phase, $protokoll] = $argv + [null, null, null, null];
if ($baum === null || !in_array($phase, ['vor24', 'nach24'], true) || $protokoll === null) {
    fwrite(STDERR, "Aufruf: php tests/fristen_test.php BAUM vor24|nach24 FEHLERPROTOKOLL\n");
    exit(2);
}
ini_set('error_log', $protokoll);
date_default_timezone_set('Europe/Berlin');
require $baum . '/backend/kern.php';
require $baum . '/backend/auth/anmeldung.php';

$rot = 0;
function pruefe(bool $ok, string $text, string $warum = ''): void {
    global $rot;
    if ($ok) { echo "  ✓ $text\n"; return; }
    $rot++; echo "  ✗ $text\n"; if ($warum !== '') echo "      $warum\n";
}
$db = get_db();
$t = fn(string $s) => new DateTimeImmutable($s);
$zahl = fn(string $sql, array $p = []) => (function () use ($db, $sql, $p) {
    $s = $db->prepare($sql); $s->execute($p); return (int)$s->fetchColumn();
})();
$probe = function (string $tabelle, string ...$zeitpunkte) use ($db): void {
    $s = $db->prepare("INSERT INTO audit_log (benutzer_id, tabelle, datensatz_id, aktion, erstellt_am)
                       VALUES (4711, ?, 8150, 'UPDATE', ?)");
    foreach ($zeitpunkte as $z) $s->execute([$tabelle, $z]);
};
$gibt = fn(string $tabelle, string $zeit) =>
    $zahl('SELECT COUNT(*) FROM audit_log WHERE tabelle = ? AND erstellt_am = ?', [$tabelle, $zeit]);

if ($phase === 'vor24') {
    // ---- Grenze des audit_log, als Funktion -----------------------------
    $grenze = function (string $stichtag): string {
        if (!function_exists('audit_grenze')) return 'audit_grenze() fehlt';
        return audit_grenze(new DateTimeImmutable($stichtag))->format('Y-m-d H:i:s');
    };
    foreach ([
        ['2031-01-15 10:00:00', '2029-08-01 00:00:00', 'Stichtag im Januar'],
        ['2031-11-15 10:00:00', '2030-08-01 00:00:00', 'Stichtag im November'],
        ['2031-07-31 23:59:59', '2029-08-01 00:00:00', 'Stichtag 31.07., letzte Sekunde des Schuljahrs'],
        ['2031-08-01 00:00:00', '2030-08-01 00:00:00', 'Stichtag 01.08., erste Sekunde des neuen Schuljahrs'],
    ] as [$stichtag, $soll, $art]) {
        $ist = $grenze($stichtag);
        pruefe($ist === $soll, "audit_grenze: $art ($stichtag) → $soll", "bekam $ist");
    }

    // ---- Frist ausgeführt: audit() räumt beim Schreiben auf -------------
    foreach ([
        ['probe_jan', '2031-01-15 10:00:00', '2029'],
        ['probe_nov', '2031-11-15 10:00:00', '2030'],
    ] as [$tab, $stichtag, $jahr]) {
        $probe($tab, "$jahr-07-31 23:59:59", "$jahr-08-01 00:00:00");
        audit(4711, $tab, 8151, 'UPDATE', null, ['probe' => 1], $t($stichtag));
        pruefe($gibt($tab, "$jahr-07-31 23:59:59") === 0, "audit, Stichtag $stichtag: Eintrag vom 31.07.$jahr gelöscht");
        pruefe($gibt($tab, "$jahr-08-01 00:00:00") === 1, "audit, Stichtag $stichtag: Eintrag vom 01.08.$jahr bleibt");
    }
    pruefe($gibt('probe_nov', '2031-11-15 10:00:00') === 1,
        'audit: erstellt_am kommt aus der PHP-Uhr (übergebener Stichtag), nicht aus der Datenbank');

    // ---- Schreiben vor sql/24: die Spalte ip_adresse gibt es noch -------
    $vor = $zahl('SELECT COUNT(*) FROM audit_log');
    audit(4711, 'probe_vor24', 8152, 'INSERT', null, ['probe' => 2], $t('2031-11-15 10:00:01'));
    $nach = $zahl('SELECT COUNT(*) FROM audit_log');
    pruefe($nach === $vor + 1, 'audit vor sql/24 (mit Spalte ip_adresse): Zeilenzahl steigt um eins', "vorher $vor, nachher $nach");

    // ---- Kein stilles Schlucken: Fehler mit Grund im Protokoll ----------
    @unlink($protokoll);
    $db->exec('RENAME TABLE audit_log TO audit_log_weg');
    $warf = null;
    try { audit(4711, 'probe_kaputt', 8153, 'INSERT', null, null, $t('2031-11-15 10:00:02')); }
    catch (Throwable $e) { $warf = get_class($e); }
    $db->exec('RENAME TABLE audit_log_weg TO audit_log');
    $log = is_file($protokoll) ? (string)file_get_contents($protokoll) : '';
    pruefe($warf === null, 'audit ohne Tabelle: wirft nicht (ein Betriebsfehler hält die Anwendung nicht an)', "warf $warf");
    pruefe(str_contains($log, 'audit_log') && str_contains($log, 'PDOException'),
        'audit ohne Tabelle: Fehlerprotokoll nennt audit_log und die Art (PDOException), schweigt nicht',
        'Protokoll: ' . ($log === '' ? 'leer' : 'ohne beide Angaben'));

    // ---- Am Quelltext: catch (Exception), kein catch (Throwable) --------
    // Der Tokenizer trennt Code von Kommentar und Zeichenkette.
    $tok = token_get_all((string)file_get_contents($baum . '/backend/kern.php'));
    $rumpf = []; $in = false; $tiefe = 0; $vorher = null;
    foreach ($tok as $x) {
        $text = is_array($x) ? $x[1] : $x;
        if (is_array($x) && in_array($x[0], [T_WHITESPACE, T_COMMENT, T_DOC_COMMENT], true)) continue;
        if (!$in && $vorher === 'function' && $text === 'audit') { $in = true; $tiefe = 0; }
        elseif ($in) {
            $rumpf[] = $text;
            if ($text === '{') $tiefe++;
            if ($text === '}' && --$tiefe === 0) break;
        }
        $vorher = $text;
    }
    $code = implode(' ', $rumpf);
    pruefe($code !== '' && str_contains($code, 'catch ( Exception') && !str_contains($code, 'Throwable'),
        'audit(), Quelltext: fängt Exception, nicht Throwable (FALLSTRICKE 3)',
        $code === '' ? 'Rumpf von audit() nicht gefunden' : 'catch im Rumpf: ' . (preg_match_all('/catch \( (\w+)/', $code, $m) ? implode(', ', $m[1]) : 'keins'));

    // ---- Verlauf: 30 Tage, Datumsarithmetik, bei jedem Eintrag ---------
    // Stichtag 10.04.2031 12:00 (Sommerzeit seit 30.03.2031). Grenze über
    // modify('-30 days'): 11.03.2031 12:00:00. 30 × 86 400 s ergäbe 11:00.
    $jetzt = (new DateTimeImmutable('2031-04-10 12:00:00'))->getTimestamp();
    $s = $db->prepare("INSERT INTO anmeldeverlauf (benutzername, ziel, erfolgreich, grund, zeitpunkt)
                       VALUES ('probe.frist', 'lokal', 0, 'probe', ?)");
    foreach (['2031-03-11 11:59:59', '2031-03-11 12:00:00', '2031-03-11 11:00:00'] as $z) $s->execute([$z]);
    Anmeldung::verlauf($db, 'probe.frist', 'lokal', true, 'lokal', fn() => $jetzt);
    $vz = fn(string $z) => $zahl("SELECT COUNT(*) FROM anmeldeverlauf WHERE benutzername = 'probe.frist' AND zeitpunkt = ?", [$z]);
    pruefe($vz('2031-03-11 11:59:59') === 0, 'Verlauf: Eintrag eine Sekunde vor der Grenze (30 Tage) gelöscht');
    pruefe($vz('2031-03-11 12:00:00') === 1, 'Verlauf: Eintrag genau auf der Grenze bleibt');
    pruefe($vz('2031-03-11 11:00:00') === 0,
        'Verlauf: Grenze über das Datum, nicht 30 × 86 400 s (Sommerzeit) – 11:00 ist gelöscht');
    pruefe($vz('2031-04-10 12:00:00') === 1, 'Verlauf: der neue Eintrag steht da, aufgeräumt wird nach dem Schreiben');
} else {
    // ---- nach sql/24 -----------------------------------------------------
    $spalten = $zahl("SELECT COUNT(*) FROM information_schema.COLUMNS
                      WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'audit_log' AND COLUMN_NAME = 'ip_adresse'");
    $alt = $zahl("SELECT COUNT(*) FROM information_schema.TABLES
                  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'webuntis_login_log'");
    pruefe($spalten === 0, 'sql/24: audit_log ohne Spalte ip_adresse', "Spalte noch da: $spalten");
    pruefe($alt === 0, 'sql/24: Tabelle webuntis_login_log entfernt', "Tabelle noch da: $alt");
    $vor = $zahl('SELECT COUNT(*) FROM audit_log');
    audit(4711, 'probe_nach24', 8154, 'INSERT', null, ['probe' => 3], $t('2031-11-15 10:00:03'));
    $nach = $zahl('SELECT COUNT(*) FROM audit_log');
    pruefe($nach === $vor + 1, 'audit nach sql/24 (ohne Spalte ip_adresse): Zeilenzahl steigt um eins', "vorher $vor, nachher $nach");
}
exit($rot === 0 ? 0 : 1);
