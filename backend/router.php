<?php
/**
 * Projektstunden NRW – Einstiegspunkt für den PHP built-in Server
 *
 * Start über supervisord:
 *   [program:projektstunden]
 *   directory=/home/hornse/projektstunden
 *   command=php -S 0.0.0.0:8082 /home/hornse/projektstunden/backend/router.php
 *
 * KRITISCH (NEUES_PROJEKT_PROMPT.md, Abschnitt 5): Die beiden Zeilen
 * unten müssen VOR jedem require stehen. Uberspace terminiert SSL vor
 * PHP – ohne $_SERVER['HTTPS'] = 'on' fehlt das Secure-Flag am
 * Session-Cookie, ohne session_name() geht die Sitzung nach dem Login
 * verloren. In der bis August 2026 laufenden Fassung fehlten beide.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

$_SERVER['HTTPS'] = 'on';
session_name('proj_session');

$uri  = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$root = dirname(__DIR__);                 // /home/hornse/projektstunden
$frontend = $root . '/frontend';

// ---- API ----------------------------------------------------
if (str_starts_with($uri, '/api/') || $uri === '/api') {
    $_SERVER['PATH_INFO'] = substr($uri, 4);

    // Der frühere Block, der den Anfragekörper nach tempnam() schrieb,
    // ist ersatzlos entfallen. Er war wirkungslos – php://input lässt
    // sich seit PHP 5.6 mehrfach lesen – und legte bei JEDEM POST eine
    // Datei in /tmp ab, die niemand löschte. Beim Login stand dort der
    // Klartext von Benutzername und Passwort.
    require __DIR__ . '/api/index.php';
    return true;
}

// ---- Statische Frontend-Dateien -----------------------------
//
// SICHERHEIT: Der eingebaute PHP-Server normalisiert „..“ NICHT,
// bevor er die Anfrage an diesen Router gibt. Eine Prüfung mit
// file_exists() allein liefert deshalb jede Datei unterhalb des
// Projektordners aus – auch backend/config.php mit dem
// Datenbankpasswort. Nachgestellt und bestätigt am 10.08.2026.
//
// realpath() löst „..“ auf; danach wird geprüft, ob das Ergebnis
// tatsächlich unterhalb von frontend/ liegt. Der Schrägstrich im
// Vergleich ist wichtig: Ohne ihn wäre auch ein Nachbarordner
// „frontend-alt“ erreichbar.
$mime = [
    'html'  => 'text/html; charset=utf-8',
    'js'    => 'application/javascript; charset=utf-8',
    'css'   => 'text/css; charset=utf-8',
    'svg'   => 'image/svg+xml',
    'png'   => 'image/png',
    'jpg'   => 'image/jpeg',
    'jpeg'  => 'image/jpeg',
    'webp'  => 'image/webp',
    'ico'   => 'image/x-icon',
    'woff2' => 'font/woff2',
    'json'  => 'application/json; charset=utf-8',
];

$frontendReal = realpath($frontend);
$datei        = realpath($frontend . $uri);

if ($uri !== '/' && $frontendReal !== false && $datei !== false
    && str_starts_with($datei, $frontendReal . DIRECTORY_SEPARATOR)
    && is_file($datei)) {

    $ext = strtolower(pathinfo($datei, PATHINFO_EXTENSION));
    header('Content-Type: ' . ($mime[$ext] ?? 'application/octet-stream'));
    header('X-Content-Type-Options: nosniff');
    header('Cache-Control: no-cache');
    readfile($datei);
    return true;
}

// ---- Fallback: alles andere bekommt die index.html ----------
// Pfade mit Punkt sind vermutlich eine fehlende Datei; sie bekommen
// 404 statt HTML, damit ein falscher Dateiname sofort auffällt und
// nicht als „unerwarteter MIME-Typ“ in der Browserkonsole endet.
if (str_contains(basename($uri), '.')) {
    http_response_code(404);
    header('Content-Type: text/plain; charset=utf-8');
    echo 'Nicht gefunden';
    return true;
}

header('Content-Type: text/html; charset=utf-8');
header('Cache-Control: no-cache');
readfile($frontend . '/index.html');
return true;
