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
 * PROJEKTEIGEN – NICHT VENDORED. Entstanden am 07.07.2026 aus der
 * Fassung in schulprozesse (dort seit 23.06.2026, der Ursprung). Diese
 * Datei ist ein VORFAHR des Moduls webuntis-auth-php (erster Stand
 * 09.07.2026), keine Kopie davon: Sie entspricht keiner Modulfassung und
 * wird nicht nachgezogen. Festgehalten am 21.10.2026 (Bericht
 * koordination 2026-10-16, Anmeldebremse).
 *
 * Unterschiede zu Schulprozesse:
 *   - MariaDB statt SQLite
 *   - personType 2 (Lehrkraft) und 5 (Schüler) werden separat behandelt
 *   - Kein eigener Namespace (Einzeldatei-Architektur)
 *
 * Seit 21.10.2026 bremst und protokolliert diese Klasse nicht mehr selbst.
 * Die Bremse steht in Anmeldebremse.php und gilt für jeden Weg, der ein
 * Passwort annimmt; diese Klasse meldet über grund(), WARUM eine Anmeldung
 * nicht gelang, und der Router schließt den Versuch damit ab.
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

    private string $sessionCookie = ''; // aktive Session-Cookie
    private ?string $grund = null;

    /**
     * Warum die letzte Anmeldung nicht gelang: 'leer', 'falsches_passwort'
     * (WebUntis hat abgelehnt), 'falsche_rolle' (Passwort stimmte, Kontotyp
     * nicht zugelassen) oder 'ohne_entscheid' (WebUntis antwortete nicht –
     * kein Passwort hat entschieden, der Versuch zählt nicht).
     */
    public function grund(): ?string
    {
        return $this->grund;
    }

    public function __construct(
        private readonly PDO   $db,
        private readonly array $config
    ) {}

    /**
     * Authentifiziert einen Benutzer und holt zusätzliche Details.
     * Für Lehrer: Kürzel, Vor- und Nachname
     * Für Schüler: key (= Schild-ID)
     *
     * @return array|null  null = Login fehlgeschlagen
     */
    public function authenticateAndGetDetails(string $username, string $password): ?array
    {
        $this->grund = null;
        $username = trim($username);
        if ($username === '' || $password === '') { $this->grund = 'leer'; return null; }

        // Einloggen – Cookie wird in $this->sessionCookie gespeichert
        $authResponse = $this->jsonRpc('authenticate', [
            'user'     => $username,
            'password' => $password,
            'client'   => $this->config['client'] ?? 'ProjektstundenNRW',
        ], true); // true = Cookie aus Response speichern

        if ($authResponse === null) {
            $this->grund = 'ohne_entscheid';
            return null;
        }
        if (isset($authResponse['error'])) {
            $this->grund = 'falsches_passwort';
            return null;
        }

        $result     = $authResponse['result'] ?? null;
        $personType = (int)($result['personType'] ?? 0);
        $personId   = (int)($result['personId']   ?? 0);

        $erlaubt = $this->config['allowed_person_types'] ?? [self::TYPE_LEHRER];
        if (!in_array($personType, $erlaubt, true)) {
            $this->jsonRpc('logout', []);
            $this->grund = 'falsche_rolle';
            return null;
        }

        // Zusatzdaten mit aktiver Session holen
        $details = ['personType' => $personType, 'personId' => $personId];

        if ($personType === self::TYPE_LEHRER || $personType === self::TYPE_ADMIN) {
            $details['kuerzel'] = $username; // Fallback

            // personId = -1 bei reinen WebUntis-Admins (kein Stundenplan-Eintrag)
            // In diesem Fall Kürzel = username, Name aus lokaler DB holen falls vorhanden
            if ($personId > 0) {
                $teachers = $this->jsonRpc('getTeachers', []);
                if ($teachers && isset($teachers['result'])) {
                    foreach ($teachers['result'] as $t) {
                        if ((int)$t['id'] === $personId) {
                            $details['kuerzel']  = $t['name']     ?? $username;
                            $details['vorname']  = $t['foreName'] ?? '';
                            $details['nachname'] = $t['longName'] ?? '';
                            break;
                        }
                    }
                }
            }
            // Wenn Name noch leer: aus DB per Kürzel nachschlagen
            if (empty($details['vorname'])) {
                try {
                    $stmt = $this->db->prepare(
                        'SELECT vorname, nachname FROM benutzer
                         WHERE kuerzel = ? AND schule_id = 1 AND aktiv = 1 LIMIT 1'
                    );
                    $stmt->execute([$details['kuerzel']]);
                    $row = $stmt->fetch();
                    if ($row) {
                        $details['vorname']  = $row['vorname'];
                        $details['nachname'] = $row['nachname'];
                    }
                } catch (Throwable) {}
            }
        }

        if ($personType === self::TYPE_SCHUELER) {
            $students = $this->jsonRpc('getStudents', []);
            if ($students && isset($students['result'])) {
                foreach ($students['result'] as $s) {
                    if ((int)$s['id'] === $personId) {
                        $details['key']      = $s['key']      ?? '';
                        $details['vorname']  = $s['foreName'] ?? '';
                        $details['nachname'] = $s['longName'] ?? '';
                        $details['gender']   = $s['gender']   ?? '';
                        break;
                    }
                }
            }
        }

        // Session freigeben
        $this->jsonRpc('logout', []);
        $this->sessionCookie = '';

        return $details;
    }

    /**
     * WebUntis-Session freigeben.
     */
    private function logoutSession(string $sessionId): void
    {
        $this->jsonRpc('logout', []);
    }

    /**
     * Alte authenticate-Methode – bleibt für Rückwärtskompatibilität.
     * @deprecated Nutze authenticateAndGetDetails()
     */
    public function authenticate(string $username, string $password): ?array
    {
        return $this->authenticateAndGetDetails($username, $password);
    }

    /**
     * JSON-RPC-Aufruf an WebUntis.
     * @param bool $saveCookie  true beim ersten Aufruf (authenticate) um Session-Cookie zu speichern
     */
    private function jsonRpc(string $method, array $params, bool $saveCookie = false): ?array
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

        $headers = ['Content-Type: application/json'];
        // Session-Cookie mitschicken wenn vorhanden
        if ($this->sessionCookie !== '') {
            $headers[] = 'Cookie: ' . $this->sessionCookie;
        }

        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST           => true,
            CURLOPT_POSTFIELDS     => $body,
            CURLOPT_HTTPHEADER     => $headers,
            CURLOPT_CONNECTTIMEOUT => $this->config['connect_timeout'] ?? 5,
            CURLOPT_TIMEOUT        => $this->config['timeout']         ?? 10,
            CURLOPT_HEADER         => $saveCookie, // Header in Response einschließen
        ]);

        $raw      = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $curlErr  = curl_error($ch);
        $headerSize = curl_getinfo($ch, CURLINFO_HEADER_SIZE);
        curl_close($ch);

        if ($raw === false) {
            error_log("WebUntisAuth: cURL-Fehler bei method={$method}: {$curlErr}");
            return null;
        }
        if ($httpCode !== 200) {
            error_log("WebUntisAuth: HTTP {$httpCode} bei method={$method}");
            return null;
        }

        // Cookie aus Response-Header speichern (nur beim ersten Aufruf)
        if ($saveCookie) {
            $responseHeaders = substr($raw, 0, $headerSize);
            $raw             = substr($raw, $headerSize);
            // JSESSIONID aus Set-Cookie Header extrahieren
            if (preg_match('/Set-Cookie:\s*(JSESSIONID=[^;]+)/i', $responseHeaders, $m)) {
                $this->sessionCookie = $m[1];
            }
        }

        $decoded = json_decode($raw, true);
        if (!is_array($decoded)) {
            error_log("WebUntisAuth: Ungültige JSON-Antwort bei method={$method}");
            return null;
        }

        return $decoded;
    }
}
