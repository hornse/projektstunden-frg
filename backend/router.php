<?php
/**
 * Projektstunden NRW – PHP built-in Server Router
 *
 * Wird von supervisord gestartet, ersetzt Apache mod_rewrite.
 * Start: php -S 0.0.0.0:8082 backend/router.php
 *
 * WICHTIG: session_name() und $_SERVER['HTTPS'] müssen hier ganz oben
 * stehen – vor jedem require – damit PHP den Session-Cookie korrekt
 * liest und den Secure-Cookie-Flag setzt (Uberspace terminiert SSL
 * vor diesem PHP-Prozess).
 */

$_SERVER['HTTPS'] = 'on';
session_name('proj_session');

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

if (strpos($uri, '/api/') === 0) {
    $_SERVER['PATH_INFO'] = substr($uri, 4);
    require __DIR__ . '/api/index.php';
} else {
    $file = __DIR__ . '/../frontend' . $uri;
    if ($uri !== '/' && file_exists($file)) {
        return false;
    }
    readfile(__DIR__ . '/../frontend/index.html');
}
