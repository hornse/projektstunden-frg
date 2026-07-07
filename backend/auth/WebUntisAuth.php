<?php
/**
 * Projektstunden NRW – WebUntis-Authentifizierung
 * ============================================================
 * Datei: backend/auth/WebUntisAuth.php
 *
 * Authentifiziert Benutzer (Lehrer und Schüler) gegen die
 * WebUntis JSON-RPC-API. Adaptiert von Schulprozesse/WebUntisAuth.php
 * für MariaDB und die Projektstunden-Datenbankstruktur.
 *
 * Unterschiede zu Schulprozesse:
 *   - MariaDB statt SQLite (NOW() statt datetime('now'))
 *   - personType 2 (Lehrkraft) und 5 (Schüler) werden separat behandelt
 *   - Login-Log in audit_log statt login_log
 *   - Kein eigener Namespace (Einzeldatei-Architektur)
 *
 * Copyright (C) 2026 Sebastian Horn, Friedrich-Rückert-Gymnasium Düsseldorf
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

class WebUntisAuth
{
    // personType-Konstanten laut WebUntis JSON-RPC
    const TYPE_LEHRER  = 2;
    const TYPE_SCHUELER = 5;

    public function __construct(
        private readonly PDO   $db,
        private readonly array $config  // aus config.php: $config['webuntis']
    ) {}

    /**
     * Authentifiziert einen Benutzer gegen WebUntis.
     *
     * @return array{username: string, personType: int, personId: int}|null
     *         null = Login fehlgeschlagen (falsches Passwort, gesperrt, Netzwerkfehler)
     */
    public function authenticate(string $username, string $password, string $ip): ?array
    {
        $username = trim($username);
        if ($username === '' || $password === '') return null;

        // Brute-Force-Schutz
        if ($this->tooManyAttempts($username)) {
            $this->log($username, false, 'zu_viele_versuche', $ip);
            return null;
        }

        // WebUntis-Anfrage
        $response = $this->jsonRpc('authenticate', [
            'user'     => $username,
            'password' => $password,
            'client'   => $this->config['client'] ?? 'ProjektstundenNRW',
        ]);

        if ($response === null || isset($response['error'])) {
            $this->log($username, false, 'falsches_passwort_oder_netzwerk', $ip);
            return null;
        }

        $result     = $response['result'] ?? null;
        $personType = (int)($result['personType'] ?? 0);
        $personId   = (int)($result['personId']   ?? 0);

        // WebUntis-Session sofort freigeben (Best effort)
        $this->jsonRpc('logout', []);

        // Erlaubte Typen prüfen
        $erlaubt = $this->config['allowed_person_types'] ?? [self::TYPE_LEHRER];
        if (!in_array($personType, $erlaubt, true)) {
            $this->log($username, false, 'falsche_rolle', $ip);
            return null;
        }

        $this->log($username, true, null, $ip);

        return [
            'username'   => $username,
            'personType' => $personType,
            'personId'   => $personId,
        ];
    }

    /**
     * JSON-RPC-Aufruf an WebUntis.
     * KEIN Logging von Requests die Passwörter enthalten.
     */
    private function jsonRpc(string $method, array $params): ?array
    {
        $baseUrl = rtrim($this->config['base_url'], '/');

        if (!str_starts_with($baseUrl, 'https://')) {
            throw new RuntimeException('webuntis.base_url muss mit https:// beginnen.');
        }

        $url  = $baseUrl . '/WebUntis/jsonrpc.do?school=' . urlencode($this->config['school']);
        $body = json_encode([
            'id'      => 'proj-' . bin2hex(random_bytes(4)),
            'method'  => $method,
            'params'  => $params,
            'jsonrpc' => '2.0',
        ]);

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $body,
            CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
            CURLOPT_CONNECTTIMEOUT => $this->config['connect_timeout'] ?? 5,
            CURLOPT_TIMEOUT        => $this->config['timeout']         ?? 10,
        ]);

        $raw      = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlErr  = curl_error($ch);
        curl_close($ch);

        if ($raw === false) {
            error_log("WebUntisAuth: cURL-Fehler bei method={$method}: {$curlErr}");
            return null;
        }
        if ($httpCode !== 200) {
            error_log("WebUntisAuth: HTTP {$httpCode} bei method={$method}");
            return null;
        }

        $decoded = json_decode($raw, true);
        if (!is_array($decoded)) {
            error_log("WebUntisAuth: Ungültige JSON-Antwort bei method={$method}");
            return null;
        }

        return $decoded;
    }

    /**
     * Brute-Force-Bremse: blockiert nach zu vielen Fehlversuchen.
     */
    private function tooManyAttempts(string $username): bool
    {
        $max     = $this->config['max_failed_logins'] ?? 5;
        $minutes = $this->config['lockout_minutes']   ?? 15;

        $stmt = $this->db->prepare(
            'SELECT COUNT(*) FROM webuntis_login_log
             WHERE benutzername = ? AND erfolgreich = 0
               AND zeitpunkt >= DATE_SUB(NOW(), INTERVAL ? MINUTE)'
        );
        $stmt->execute([$username, $minutes]);
        return (int)$stmt->fetchColumn() >= $max;
    }

    /**
     * Login-Versuch protokollieren.
     */
    private function log(string $username, bool $ok, ?string $grund, string $ip): void
    {
        try {
            $this->db->prepare(
                'INSERT INTO webuntis_login_log (benutzername, erfolgreich, grund, ip)
                 VALUES (?, ?, ?, ?)'
            )->execute([$username, $ok ? 1 : 0, $grund, $ip]);
        } catch (Throwable $e) {
            error_log('WebUntisAuth log: ' . $e->getMessage());
        }
    }
}
