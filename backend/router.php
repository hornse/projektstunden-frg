<?php
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
