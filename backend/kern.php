<?php
/**
 * Projektstunden NRW – Kern des Backends
 * ============================================================
 * Datei: backend/kern.php  (versioniert)
 *
 * Datenbank, Sitzung, Rechte, JSON-Antworten, Eingabe, Protokoll – die acht
 * Funktionen, die bis Auftrag A in der unversionierten backend/config.php
 * standen (Befund Z. 5, koordination 06.11.2026; E68). Dort liefen sie
 * zwischen Rechner und Server auseinander, ohne dass etwas warnte: Im
 * September hing die lokale Fassung drei Generationen hinter der des Servers.
 * Dazu kam in Paket 3 eine neunte: audit_grenze(), die Frist des audit_log,
 * die zu audit() gehört (tests/kern_test.php K1 zählt die neun).
 *
 * Die WERTE stehen in backend/konfiguration.php (nicht versioniert, Vorlage
 * backend/konfiguration.example.php). Diese Datei lädt sie, genau hier und
 * nirgends sonst – tests/kern_test.php K3 zählt die Aufrufstellen.
 *
 * Copyright (C) 2026 Sebastian Horn, Friedrich-Rückert-Gymnasium Düsseldorf
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

require_once __DIR__ . '/konfiguration.php';

// ============================================================
// Datenbankverbindung (PDO)
// ============================================================
function get_db(): PDO {
    static $pdo = null;
    if ($pdo !== null) return $pdo;
    $dsn = sprintf('mysql:host=%s;port=%d;dbname=%s;charset=%s',
                   DB_HOST, DB_PORT, DB_NAME, DB_CHARSET);
    $pdo = new PDO($dsn, DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
    return $pdo;
}

// ============================================================
// Session
// ============================================================
// Name und Dauer der Sitzung stehen hier und nirgends sonst (E68, Paket 4;
// tests/kern_test.php K6) – bis dahin in der unversionierten Konfiguration,
// der Name zusätzlich im Router. Der Name ist der des Betriebs: ein anderer
// meldete beim Ausliefern alle ab (tests/anmeldung_db_test.sh S5). Der
// Speicherort steht in keiner Datei des Projekts; maßgeblich ist die
// PHP-Konfiguration des Servers, ~/etc/php.d/sessions.ini (FALLSTRICKE 1).
const SESSION_NAME     = 'proj_session';
const SESSION_LIFETIME = 8 * 3600;

// Hier und nur hier wird die Sitzung eingerichtet: Name und Cookie vor dem
// ersten Zugriff, secure/httponly/samesite ausdrücklich (FALLSTRICKE 1).
// $_SERVER['HTTPS'] hat darauf keinen Einfluss.
function session_start_secure(): void {
    if (session_status() === PHP_SESSION_ACTIVE) return;
    session_name(SESSION_NAME);
    session_set_cookie_params([
        'lifetime' => SESSION_LIFETIME,
        'path'     => '/',
        'secure'   => true,
        'httponly' => true,
        // Lax, nicht Strict: Strict schickt das Cookie bei einem Link von
        // außen (Mail, WebUntis) nicht mit, und der Benutzer landet trotz
        // gültiger Sitzung auf der Anmeldemaske. Der Betrieb liefert Lax.
        'samesite' => 'Lax',
    ]);
    session_start();
}

function require_auth(): array {
    session_start_secure();
    if (!isset($_SESSION['benutzer_id']) || $_SESSION['benutzer_id'] === null) {
        http_response_code(401);
        die(json_encode(['error' => 'Nicht eingeloggt.']));
    }
    return [
        'id'        => (int)$_SESSION['benutzer_id'],
        'rolle'     => $_SESSION['rolle'],
        'schule_id' => (int)$_SESSION['schule_id'],
        'typ'       => $_SESSION['typ'] ?? 'benutzer', // 'benutzer' oder 'schueler'
    ];
}

function require_admin(): array {
    $user = require_auth();
    if ($user['rolle'] !== 'admin') {
        http_response_code(403);
        die(json_encode(['error' => 'Nur Administratoren.']));
    }
    return $user;
}

// ============================================================
// JSON-Antworten
// ============================================================
function json_response(mixed $data, int $status = 200): void {
    header('Content-Type: application/json; charset=utf-8');
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function json_error(string $msg, int $status = 400): void {
    json_response(['error' => $msg], $status);
}

// ============================================================
// Eingabe bereinigen
// ============================================================
function clean(string $s): string {
    return htmlspecialchars(trim($s), ENT_QUOTES, 'UTF-8');
}

// ============================================================
// Audit-Log
// ============================================================
// Frist „Schuljahr + 1“ (E68): Ein Eintrag bleibt das laufende und das
// vorige Schuljahr. Die Grenze ist der 01.08. des vorletzten
// Schuljahresbeginns – vom 01.08. an gerechnet, nicht vom Kalenderjahr:
// Stichtag 15.01.2031 → 01.08.2029, Stichtag 15.11.2031 → 01.08.2030.
function audit_grenze(DateTimeImmutable $jetzt): DateTimeImmutable {
    $jahr   = (int)$jetzt->format('Y');
    $beginn = (int)$jetzt->format('n') >= 8 ? $jahr : $jahr - 1;   // letzter Schuljahresbeginn
    return $jetzt->setDate($beginn - 1, 8, 1)->setTime(0, 0, 0);
}

// Ohne Adresse (E68): Hinter dem Proxy war REMOTE_ADDR der Proxy, und eine
// Adresse braucht das Protokoll nicht. Der Zeitpunkt kommt aus der PHP-Uhr,
// wie die Grenze (FALLSTRICKE 4). Aufgeräumt wird bei jedem Eintrag.
// Ein Fehler hält die Anwendung nicht an, aber er schweigt nicht: Gefangen
// wird nur der Betriebsfehler (Exception, nicht Throwable), mit Grund im
// Protokoll (FALLSTRICKE 3).
function audit(int|null $benutzer_id, string $tabelle, int|null $datensatz_id,
               string $aktion, mixed $alt = null, mixed $neu = null,
               ?DateTimeImmutable $jetzt = null): void {
    $jetzt ??= new DateTimeImmutable('now');
    try {
        $db = get_db();
        $db->prepare(
            'INSERT INTO audit_log (benutzer_id, tabelle, datensatz_id, aktion, alt_wert, neu_wert, erstellt_am)
             VALUES (?, ?, ?, ?, ?, ?, ?)'
        )->execute([
            $benutzer_id, $tabelle, $datensatz_id, $aktion,
            $alt !== null ? json_encode($alt) : null,
            $neu !== null ? json_encode($neu) : null,
            $jetzt->format('Y-m-d H:i:s'),
        ]);
        $db->prepare('DELETE FROM audit_log WHERE erstellt_am < ?')
           ->execute([audit_grenze($jetzt)->format('Y-m-d H:i:s')]);
    } catch (Exception $e) {
        error_log('projektstunden: audit_log nicht geschrieben oder nicht aufgeräumt ('
                  . get_class($e) . ' ' . $e->getCode() . ', Tabelle ' . $tabelle . ')');
    }
}
