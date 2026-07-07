<?php
/**
 * Projektstunden NRW – Konfiguration
 * ============================================================
 * Datei: backend/config.php
 *
 * Diese Datei NICHT in git versionieren (steht in .gitignore).
 * Für Neuinstallation: config.example.php → config.php kopieren
 * und die Werte anpassen.
 *
 * Copyright (C) 2026 Sebastian Horn, Friedrich-Rückert-Gymnasium Düsseldorf
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

ini_set('session.save_path', '/home/hornse/tmp/sessions');
ini_set('display_errors', 0);
error_reporting(E_ALL);

// ----- Datenbank (MariaDB) -----
define('DB_HOST',    '127.0.0.1');
define('DB_PORT',    3306);
define('DB_NAME',    'hornse_projektstunden');
define('DB_USER',    'hornse');
define('DB_PASS',    'DEIN_DATENBANKPASSWORT');
define('DB_CHARSET', 'utf8mb4');

// ----- Schule (Mandant) -----
define('SCHULE_ID', 1);

// ----- Session -----
define('SESSION_NAME',     'proj_session');
define('SESSION_LIFETIME', 8 * 3600);

// ----- CORS -----
define('ALLOWED_ORIGIN', 'https://projektstunden.hornse.de');

// ----- WebUntis (optional) -----
// Wenn konfiguriert, können sich Lehrer zusätzlich per WebUntis-Kürzel
// und WebUntis-Passwort anmelden. E-Mail/Passwort bleibt weiterhin möglich.
//
// Eigenen personType herausfinden:
//   php -r "..." (siehe deploy/uberspace.md)
//
// personType-Werte: 2 = Lehrkraft, 5 = Schüler
define('WEBUNTIS_ENABLED', true);

$WEBUNTIS_CONFIG = [
    'base_url'             => 'https://neilo.webuntis.com',  // ohne / am Ende
    'school'               => 'frg-duesseldorf',              // Schulkürzel in WebUntis-URL
    'client'               => 'ProjektstundenNRW',
    'allowed_person_types' => [2],     // Lehrkräfte; [2, 5] für Lehrer + Schüler
    'connect_timeout'      => 5,
    'timeout'              => 10,
    'max_failed_logins'    => 5,       // Versuche bevor gesperrt
    'lockout_minutes'      => 15,      // Sperrzeit
];

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
function session_start_secure(): void {
    if (session_status() === PHP_SESSION_ACTIVE) return;
    session_name(SESSION_NAME);
    session_set_cookie_params([
        'lifetime' => SESSION_LIFETIME,
        'path'     => '/',
        'secure'   => true,
        'httponly' => true,
        'samesite' => 'Strict',
    ]);
    session_start();
}

function require_auth(): array {
    session_start_secure();
    if (empty($_SESSION['benutzer_id'])) {
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
function audit(int|null $benutzer_id, string $tabelle, int|null $datensatz_id,
               string $aktion, mixed $alt = null, mixed $neu = null): void {
    try {
        $db = get_db();
        $db->prepare(
            'INSERT INTO audit_log (benutzer_id, tabelle, datensatz_id, aktion, alt_wert, neu_wert, ip_adresse)
             VALUES (?, ?, ?, ?, ?, ?, ?)'
        )->execute([
            $benutzer_id, $tabelle, $datensatz_id, $aktion,
            $alt !== null ? json_encode($alt) : null,
            $neu !== null ? json_encode($neu) : null,
            $_SERVER['REMOTE_ADDR'] ?? null,
        ]);
    } catch (Throwable) {}
}
