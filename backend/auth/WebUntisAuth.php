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
    const TYPE_LEHRER   = 2;
    const TYPE_ADMIN    = 16; // WebUntis-Administrator
    const TYPE_SCHUELER = 5;

    public function __construct(
        private readonly PDO   $db,
        private readonly array $config  // aus config.php: $config['webuntis']
    ) {}

    /**
     * Authentifiziert einen Benutzer und holt zusätzliche Details.
     * Für Lehrer: Kürzel, Vor- und Nachname
     * Für Schüler: key (= Schild-ID)
     *
     * @return array|null  null = Login fehlgeschlagen
     */
    public function authenticateAndGetDetails(string $username, string $password, string $ip): ?array
    {
        $username = trim($username);
        if ($username === '' || $password === '') return null;

        if ($this->tooManyAttempts($username)) {
            $this->log($username, false, 'zu_viele_versuche', $ip);
            return null;
        }

        // Einloggen
        $authResponse = $this->jsonRpc('authenticate', [
            'user'     => $username,
            'password' => $password,
            'client'   => $this->config['client'] ?? 'ProjektstundenNRW',
        ]);

        if ($authResponse === null || isset($authResponse['error'])) {
            $this->log($username, false, 'falsches_passwort_oder_netzwerk', $ip);
            return null;
        }

        $result     = $authResponse['result'] ?? null;
        $personType = (int)($result['personType'] ?? 0);
        $personId   = (int)($result['personId']   ?? 0);
        $sessionId  = $result['sessionId']         ?? '';

        $erlaubt = $this->config['allowed_person_types'] ?? [self::TYPE_LEHRER];
        if (!in_array($personType, $erlaubt, true)) {
            $this->logoutSession($sessionId);
            $this->log($username, false, 'falsche_rolle', $ip);
            return null;
        }

        // Zusatzdaten holen (mit aktiver Session)
        $details = ['personType' => $personType, 'personId' => $personId];

        if ($personType === self::TYPE_LEHRER) {
            // Lehrerliste holen und passenden Eintrag finden
            $teachers = $this->jsonRpc('getTeachers', []);
            if ($teachers && isset($teachers['result'])) {
                foreach ($teachers['result'] as $t) {
                    if ((int)$t['id'] === $personId) {
                        $details['kuerzel']  = $t['name']     ?? '';
                        $details['vorname']  = $t['foreName'] ?? '';
                        $details['nachname'] = $t['longName'] ?? '';
                        break;
                    }
                }
            }
            // Fallback: Kürzel aus username
            if (empty($details['kuerzel'])) {
                $details['kuerzel'] = $username;
            }
        }

        if ($personType === self::TYPE_SCHUELER) {
            // Schülerliste holen und passenden Eintrag finden
            $students = $this->jsonRpc('getStudents', []);
            if ($students && isset($students['result'])) {
                foreach ($students['result'] as $s) {
                    if ((int)$s['id'] === $personId) {
                        $details['key']      = $s['key']      ?? ''; // = Schild-ID
                        $details['vorname']  = $s['foreName'] ?? '';
                        $details['nachname'] = $s['longName'] ?? '';
                        $details['gender']   = $s['gender']   ?? '';
                        break;
                    }
                }
            }
        }

        // Session freigeben
        $this->logoutSession($sessionId);
        $this->log($username, true, null, $ip);

        return $details;
    }

    /**
     * WebUntis-Session freigeben.
     */
    private function logoutSession(string $sessionId): void
    {
        // Session-Cookie setzen und logout aufrufen
        $this->jsonRpc('logout', []);
    }

    /**
     * Alte authenticate-Methode – bleibt für Rückwärtskompatibilität.
     * @deprecated Nutze authenticateAndGetDetails()
     */
    public function authenticate(string $username, string $password, string $ip): ?array
    {
        return $this->authenticateAndGetDetails($username, $password, $ip);
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
