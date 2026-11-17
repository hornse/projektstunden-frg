<?php
/**
 * Projektstunden NRW – tests/daten/webuntis_ersatz.php
 * Ein WebUntis-Ersatz über HTTPS, nur 127.0.0.1, für tests/anmeldung_db_test.sh
 *
 * Herkunft: das Messskript aus Schritt 1 von Auftrag A (12.11.2026, Python,
 * im Scratchpad der Sitzung), hier in PHP, damit die Prüfung nur php braucht
 * und auch in der kargen Umgebung läuft. WebUntisAuth verlangt https://,
 * deshalb TLS mit einer Wegwerf-CA. Belegt am 12.11.2026 (PHP 8.4, OpenSSL
 * 4.0.3): curl.cainfo greift dort NICHT, openssl.cafile schon – die Anwendung
 * läuft deshalb unter php -d openssl.cafile=<ca.pem>.
 *
 *   php webuntis_ersatz.php zertifikate VERZEICHNIS   → ca.pem, srv.pem, srv.key
 *   php webuntis_ersatz.php dienen PORT VERZEICHNIS    → bedient, bis er beendet wird
 *
 * Verhalten je Benutzername (alle ERFUNDEN):
 *   probe.falsch   JSON-RPC-Fehler -8504, HTTP 200
 *   probe.schule   JSON-RPC-Fehler -8500 (invalid schoolname), HTTP 200
 *   probe.vier     HTTP 404, HTML
 *   probe.fuenf    HTTP 503, HTML
 *   probe.langsam  antwortet erst nach 4 s (die Anwendung wartet 2 s)
 *   probe.gut      Erfolg, personType 2, personId 4711
 *   …@…            HTTP 503 (eine E-Mail-Adresse trifft auf ein ausgefallenes WebUntis)
 *   sonst          -8504
 * Die übrigen Methoden (getTeachers, logout) antworten leer.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

declare(strict_types=1);

$art = $argv[1] ?? '';

if ($art === 'zertifikate') {
    $d = $argv[2];
    $cfg = ['digest_alg' => 'sha256', 'private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA];
    $caKey = openssl_pkey_new($cfg);
    $caCsr = openssl_csr_new(['commonName' => 'Pruef-CA projektstunden'], $caKey, $cfg);
    $caCfg = tempnam($d, 'ca') ?: exit(1);
    file_put_contents($caCfg, "[req]\ndistinguished_name=dn\n[dn]\n[v3_ca]\nbasicConstraints=critical,CA:TRUE\nkeyUsage=critical,keyCertSign\n");
    $ca = openssl_csr_sign($caCsr, null, $caKey, 1, ['config' => $caCfg, 'x509_extensions' => 'v3_ca'] + $cfg, 4711);
    $srvKey = openssl_pkey_new($cfg);
    $srvCsr = openssl_csr_new(['commonName' => '127.0.0.1'], $srvKey, $cfg);
    $srvCfg = tempnam($d, 'srv') ?: exit(1);
    file_put_contents($srvCfg, "[req]\ndistinguished_name=dn\n[dn]\n[v3_srv]\nbasicConstraints=CA:FALSE\nsubjectAltName=IP:127.0.0.1\nextendedKeyUsage=serverAuth\n");
    $srv = openssl_csr_sign($srvCsr, $ca, $caKey, 1, ['config' => $srvCfg, 'x509_extensions' => 'v3_srv'] + $cfg, 4712);
    openssl_x509_export_to_file($ca, "$d/ca.pem");
    openssl_x509_export_to_file($srv, "$d/srv.pem");
    openssl_pkey_export_to_file($srvKey, "$d/srv.key");
    unlink($caCfg); unlink($srvCfg);
    exit(is_file("$d/ca.pem") && is_file("$d/srv.pem") && is_file("$d/srv.key") ? 0 : 1);
}

if ($art !== 'dienen') { fwrite(STDERR, "Aufruf: zertifikate DIR | dienen PORT DIR\n"); exit(2); }

[$port, $d] = [(int)$argv[2], $argv[3]];
$ctx = stream_context_create(['ssl' => ['local_cert' => "$d/srv.pem", 'local_pk' => "$d/srv.key"]]);
$s = stream_socket_server("tls://127.0.0.1:$port", $en, $es, STREAM_SERVER_BIND | STREAM_SERVER_LISTEN, $ctx);
if ($s === false) { fwrite(STDERR, "kein Server: $es\n"); exit(1); }
file_put_contents("$d/bereit", 'ja');

function antworten($c, int $status, string $rumpf, string $typ = 'application/json', bool $cookie = false): void
{
    $kopf = "HTTP/1.1 $status " . ($status === 200 ? 'OK' : 'Fehler') . "\r\nContent-Type: $typ\r\n"
          . ($cookie ? "Set-Cookie: JSESSIONID=ERFUNDEN0000; Path=/WebUntis\r\n" : '')
          . 'Content-Length: ' . strlen($rumpf) . "\r\nConnection: close\r\n\r\n";
    @fwrite($c, $kopf . $rumpf);
}

while (true) {
    $c = @stream_socket_accept($s, -1);
    if ($c === false) continue;
    stream_set_timeout($c, 5);
    $kopf = '';
    while (!str_contains($kopf, "\r\n\r\n") && ($z = fgets($c)) !== false) $kopf .= $z;
    $laenge = preg_match('/Content-Length:\s*(\d+)/i', $kopf, $m) === 1 ? (int)$m[1] : 0;
    $rumpf = '';
    while (strlen($rumpf) < $laenge && ($b = fread($c, $laenge - strlen($rumpf))) !== false && $b !== '') $rumpf .= $b;
    $rpc = json_decode($rumpf, true) ?: [];
    $id = $rpc['id'] ?? null;
    $ok = fn(mixed $r) => json_encode(['jsonrpc' => '2.0', 'id' => $id, 'result' => $r]);
    $err = fn(int $code, string $msg) => json_encode(['jsonrpc' => '2.0', 'id' => $id, 'error' => ['code' => $code, 'message' => $msg]]);
    if (($rpc['method'] ?? '') !== 'authenticate') {
        antworten($c, 200, $ok(($rpc['method'] ?? '') === 'logout' ? null : []));
    } else {
        $u = (string)($rpc['params']['user'] ?? '');
        match (true) {
            $u === 'probe.schule'  => antworten($c, 200, $err(-8500, 'invalid schoolname')),
            $u === 'probe.vier'    => antworten($c, 404, '<html><body>Not Found</body></html>', 'text/html'),
            $u === 'probe.fuenf', str_contains($u, '@')
                                   => antworten($c, 503, '<html><body>Service Unavailable</body></html>', 'text/html'),
            $u === 'probe.langsam' => (function () use ($c, $err) { sleep(4); antworten($c, 200, $err(-8504, 'bad credentials')); })(),
            $u === 'probe.gut'     => antworten($c, 200, $ok(['sessionId' => 'ERFUNDEN', 'personType' => 2, 'personId' => 4711, 'klasseId' => 0]), 'application/json', true),
            default                => antworten($c, 200, $err(-8504, 'bad credentials')),
        };
    }
    @fclose($c);
}
