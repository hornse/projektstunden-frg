<?php
/**
 * Projektstunden NRW – API Router
 * ============================================================
 * Datei: backend/api/index.php  (liegt im DocumentRoot unter /api/)
 *
 * Dieser Router nimmt alle HTTP-Anfragen entgegen, leitet sie
 * anhand von METHOD + PATH an die zuständige Handler-Funktion weiter
 * und sendet die JSON-Antwort zurück.
 *
 * URL-Struktur:
 *   POST   /api/auth/login
 *   POST   /api/auth/logout
 *   GET    /api/auth/me
 *
 *   GET    /api/schueler?klasse_id=3
 *   POST   /api/schueler
 *   DELETE /api/schueler/{id}
 *
 *   GET    /api/klassen
 *   POST   /api/klassen
 *   DELETE /api/klassen/{id}
 *
 *   GET    /api/faecher
 *   GET    /api/lehrer
 *
 *   GET    /api/kompetenzen?fach_id=4&rahmen_id=2
 *   GET    /api/kompetenzrahmen
 *
 *   GET    /api/projekte?klasse_id=3
 *   POST   /api/projekte
 *   GET    /api/projekte/{id}
 *   PUT    /api/projekte/{id}
 *   DELETE /api/projekte/{id}
 *
 *   GET    /api/dashboard?klasse_id=3&schueler_id=7
 *   GET    /api/export/csv?klasse_id=3
 *
 *   GET    /api/benutzer              Liste aller Benutzer (nur Admin)
 *   POST   /api/benutzer              Neuen Benutzer anlegen (nur Admin)
 *   PUT    /api/benutzer/{id}         Benutzer bearbeiten (nur Admin)
 *   DELETE /api/benutzer/{id}         Benutzer deaktivieren (nur Admin)
 *   PUT    /api/benutzer/{id}/passwort Passwort ändern (Admin oder eigener Account)
 * ============================================================
 */

// Konfiguration eine Ebene über dem DocumentRoot laden
require_once __DIR__ . '/../../backend/config.php';

// ----- CORS-Header -----
header('Access-Control-Allow-Origin: ' . ALLOWED_ORIGIN);
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Requested-With');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

// ----- Request parsen -----
$method = $_SERVER['REQUEST_METHOD'];
// PATH_INFO wird via .htaccess RewriteRule gesetzt
$path   = trim($_SERVER['PATH_INFO'] ?? '/', '/');
$parts  = explode('/', $path);          // z. B. ['projekte', '5']
$route  = $parts[0] ?? '';             // 'projekte'
$id     = isset($parts[1]) ? (int)$parts[1] : null;
$sub    = $parts[1] ?? '';             // für /auth/login etc.
// Für verschachtelte Routen: /schuljahre/{id}/aktivieren oder /import/vorschau
if ($route === 'schuljahre' && isset($parts[2])) {
    $sub = $parts[2];                  // z. B. 'aktivieren'
}
if ($route === 'import') {
    $sub = $parts[1] ?? '';            // z. B. 'vorschau', 'ausfuehren'
    $id  = null;
}
if ($route === 'werkstatt' && isset($parts[2])) {
    $sub = $parts[2];                  // z. B. 'abschluss', 'schueler', 'status'
}

// JSON-Body einlesen (für POST/PUT)
$body = [];
if (in_array($method, ['POST', 'PUT'])) {
    $raw = file_get_contents('php://input');
    $body = json_decode($raw, true) ?? [];
}

// ----- Routing -----
try {
    match ($route) {
        'auth'        => handle_auth($method, $sub, $body),
        'schueler'    => handle_schueler($method, $id, $body),
        'klassen'     => handle_klassen($method, $id, $body),
        'faecher'     => handle_faecher($method),
        'lehrer'      => handle_lehrer($method),
        'kompetenzen' => handle_kompetenzen($method),
        'kompetenzrahmen' => handle_kompetenzrahmen($method),
        'projekte'      => handle_projekte($method, $id, $body),
        'werkstatt'     => handle_werkstatt($method, $id, $sub, $body),
        'bewertung'           => handle_bewertung($method, $id, $body),
        'rueckmeldung'        => handle_rueckmeldung($method, $id, $body),
        'schueler-portal'     => handle_schueler_portal($method, $id, $body),
        'selbsteinschaetzung' => handle_selbsteinschaetzung($method, $id, $body),
        'einstellungen'       => handle_einstellungen($method, $sub ?? '', $body),
        'dashboard'   => handle_dashboard($method),
        'export'      => handle_export($method, $sub),
        'benutzer'    => handle_benutzer($method, $id, $sub, $body),
        'schuljahre'  => handle_schuljahre($method, $id, $sub, $body),
        'import'      => handle_import($method, $sub, $body),
        default       => json_error('Unbekannte Route.', 404),
    };
} catch (PDOException $e) {
    // SQL-Fehlertext nicht ans Frontend weitergeben
    error_log('DB-Fehler: ' . $e->getMessage());
    json_error('Datenbankfehler.', 500);
} catch (Throwable $e) {
    error_log('Fehler: ' . $e->getMessage());
    json_error('Interner Fehler.', 500);
}

// ============================================================
//  AUTH
// ============================================================
function handle_auth(string $method, string $sub, array $body): void {
    if ($method === 'POST' && $sub === 'login') {
        $username = trim($body['username'] ?? $body['email'] ?? '');
        $pass     = $body['passwort'] ?? '';
        if (!$username || !$pass) json_error('Zugangsdaten erforderlich.');

        $db = get_db();

        // ── Schritt 1: Lokaler Login (E-Mail + Passwort) ──
        if (filter_var($username, FILTER_VALIDATE_EMAIL)) {
            $stmt = $db->prepare(
                'SELECT id, vorname, nachname, email, passwort_hash, rolle, schule_id, aktiv
                 FROM benutzer WHERE email = ? AND schule_id = ? LIMIT 1'
            );
            $stmt->execute([$username, SCHULE_ID]);
            $user = $stmt->fetch();
            if ($user && $user['aktiv'] && password_verify($pass, $user['passwort_hash'])) {
                session_start_secure();
                session_regenerate_id(true);
                $_SESSION['benutzer_id'] = $user['id'];
                $_SESSION['rolle']       = $user['rolle'];
                $_SESSION['schule_id']   = $user['schule_id'];
                $_SESSION['typ']         = 'benutzer';
                json_response(['ok' => true, 'vorname' => $user['vorname'],
                               'nachname' => $user['nachname'], 'rolle' => $user['rolle'],
                               'typ' => 'benutzer', 'id' => $user['id']]);
            }
        }

        // ── Schritt 2: WebUntis-Login ──
        // Lehrer: Session on-the-fly, kein DB-Eintrag nötig
        // Schüler: Abgleich schild_id = WebUntis key (beide aus Schild-NRW)
        global $WEBUNTIS_CONFIG;
        if (defined('WEBUNTIS_ENABLED') && WEBUNTIS_ENABLED && !empty($WEBUNTIS_CONFIG)) {
            require_once __DIR__ . '/../auth/WebUntisAuth.php';
            $wu     = new WebUntisAuth($db, $WEBUNTIS_CONFIG);
            $ip     = $_SERVER['REMOTE_ADDR'] ?? 'unbekannt';
            $result = $wu->authenticateAndGetDetails($username, $pass, $ip);

            if ($result !== null) {
                $personType = $result['personType'];
                $personId   = $result['personId'];

                // ── Lehrer (personType = 2 oder 16) ──
                if ($personType === WebUntisAuth::TYPE_LEHRER ||
                    $personType === WebUntisAuth::TYPE_ADMIN) {
                    $kuerzel  = $result['kuerzel']  ?? '';
                    $vorname  = $result['vorname']  ?? '';
                    $nachname = $result['nachname'] ?? '';

                    // personType 16 = WebUntis-Admin → immer admin
                    // personType  2 = Lehrkraft → lernbegleiter (außer in admin_kuerzel)
                    $adminKuerzel = $WEBUNTIS_CONFIG['admin_kuerzel'] ?? [];
                    if ($personType === WebUntisAuth::TYPE_ADMIN) {
                        $rolle = 'admin';
                    } elseif (in_array($kuerzel, $adminKuerzel, true)) {
                        $rolle = 'admin';
                    } else {
                        $rolle = 'lernbegleiter';
                    }

                    // Lokalen DB-Eintrag per Kürzel prüfen (Rolle hat Vorrang)
                    if ($kuerzel) {
                        $chk = $db->prepare(
                            'SELECT id, rolle FROM benutzer
                             WHERE kuerzel = ? AND schule_id = ? AND aktiv = 1 LIMIT 1'
                        );
                        $chk->execute([$kuerzel, SCHULE_ID]);
                        $dbUser = $chk->fetch();
                        if ($dbUser) {
                            $rolle = $dbUser['rolle'];
                            // Lokaler Benutzer gefunden – dessen ID nutzen
                            $dbUserId = $dbUser['id'];
                        }
                    }

                    session_start_secure();
                    session_regenerate_id(true);
                    $_SESSION['benutzer_id']  = $dbUserId ?? 0;
                    $_SESSION['wu_person_id'] = $personId;
                    $_SESSION['wu_kuerzel']   = $kuerzel;
                    $_SESSION['wu_vorname']   = $vorname;
                    $_SESSION['wu_nachname']  = $nachname;
                    $_SESSION['rolle']        = $rolle;
                    $_SESSION['schule_id']    = SCHULE_ID;
                    $_SESSION['typ']          = 'benutzer';

                    json_response(['ok' => true, 'vorname' => $vorname,
                                   'nachname' => $nachname, 'rolle' => $rolle,
                                   'typ' => 'benutzer', 'id' => $dbUserId ?? 0]);
                }

                // ── Schüler (personType = 5) ──
                // key = Schild-ID (aus Schild-NRW → WebUntis → Projektstunden)
                if ($personType === WebUntisAuth::TYPE_SCHUELER) {
                    $schildId    = (int)($result['key']        ?? 0);
                    $wuKlasseId  = (int)($result['klasseId']   ?? 0);
                    $klasseName  = $result['klasse_name']       ?? '';
                    $vorname     = $result['vorname']           ?? '';
                    $nachname    = $result['nachname']          ?? '';

                    if (!$schildId) {
                        json_error('WebUntis-Login erfolgreich, aber Schüler-ID fehlt.', 403);
                    }

                    // Schüler in DB suchen
                    $stmt = $db->prepare(
                        'SELECT s.id, s.vorname, s.nachname
                         FROM schueler s
                         JOIN klassen k ON k.id = s.klasse_id
                         WHERE s.schild_id = ? AND k.schule_id = ? AND s.aktiv = 1 LIMIT 1'
                    );
                    $stmt->execute([$schildId, SCHULE_ID]);
                    $schueler = $stmt->fetch();

                    // Nicht gefunden → automatisch anlegen (on-the-fly Registration)
                    if (!$schueler && $klasseName && $vorname && $nachname) {
                        $db->beginTransaction();
                        try {
                            // Klasse anlegen falls nicht vorhanden
                            $kl = $db->prepare(
                                'SELECT id FROM klassen WHERE bezeichnung = ? AND schule_id = ? LIMIT 1'
                            );
                            $kl->execute([$klasseName, SCHULE_ID]);
                            $klasse = $kl->fetch();

                            if (!$klasse) {
                                // Jahrgang aus Klassenname extrahieren (z.B. "06A" → 6)
                                preg_match('/^(\d+)/', $klasseName, $m);
                                $jahrgang = isset($m[1]) ? (int)$m[1] : 0;
                                $db->prepare(
                                    'INSERT INTO klassen (schule_id, bezeichnung, schuljahr, jahrgang)
                                     VALUES (?, ?, ?, ?)'
                                )->execute([SCHULE_ID, $klasseName,
                                            date('Y') . '/' . (date('Y')+1), $jahrgang]);
                                $klasse_id = (int)$db->lastInsertId();
                            } else {
                                $klasse_id = (int)$klasse['id'];
                            }

                            // Schüler anlegen
                            $db->prepare(
                                'INSERT INTO schueler
                                 (schule_id, klasse_id, schild_id, vorname, nachname, aktiv)
                                 VALUES (?, ?, ?, ?, ?, 1)'
                            )->execute([SCHULE_ID, $klasse_id, $schildId, $vorname, $nachname]);
                            $schueler_id = (int)$db->lastInsertId();

                            $db->commit();
                            $schueler = ['id' => $schueler_id,
                                         'vorname' => $vorname, 'nachname' => $nachname];
                        } catch (Throwable $e) {
                            $db->rollBack();
                            json_error('Fehler beim automatischen Anlegen des Schülers.', 500);
                        }
                    }

                    if (!$schueler) {
                        json_error('Schüler nicht gefunden. Bitte Administrator informieren.', 403);
                    }

                    session_start_secure();
                    session_regenerate_id(true);
                    $_SESSION['benutzer_id'] = $schueler['id'];
                    $_SESSION['rolle']       = 'schueler';
                    $_SESSION['schule_id']   = SCHULE_ID;
                    $_SESSION['typ']         = 'schueler';

                    json_response(['ok' => true, 'vorname' => $schueler['vorname'],
                                   'nachname' => $schueler['nachname'], 'rolle' => 'schueler',
                                   'typ' => 'schueler', 'id' => $schueler['id']]);
                }
            }
        }

        json_error('Ungültige Anmeldedaten.', 401);
    }

    if ($method === 'POST' && $sub === 'logout') {
        session_start_secure();
        session_destroy();
        json_response(['ok' => true]);
    }

    if ($method === 'GET' && $sub === 'me') {
        $user = require_auth();
        $db   = get_db();

        if ($user['typ'] === 'schueler') {
            $stmt = $db->prepare('SELECT id, vorname, nachname FROM schueler WHERE id = ?');
            $stmt->execute([$user['id']]);
            $row = $stmt->fetch();
            json_response(array_merge($row, ['rolle' => 'schueler', 'typ' => 'schueler']));
        }

        // WebUntis-Lehrer ohne lokalen DB-Eintrag
        if (($user['id'] ?? 0) === 0) {
            json_response([
                'id'       => 0,
                'vorname'  => $_SESSION['wu_vorname']  ?? '',
                'nachname' => $_SESSION['wu_nachname'] ?? '',
                'rolle'    => $_SESSION['rolle'],
                'typ'      => 'benutzer',
            ]);
        }

        $stmt = $db->prepare('SELECT id, vorname, nachname, email, rolle FROM benutzer WHERE id = ?');
        $stmt->execute([$user['id']]);
        $row = $stmt->fetch();
        json_response(array_merge($row, ['typ' => 'benutzer']));
    }

    json_error('Unbekannte Auth-Aktion.', 404);
}


// ============================================================
//  SCHÜLER
// ============================================================
function handle_schueler(string $method, ?int $id, array $body): void {
    $user = require_auth();
    $db   = get_db();

    if ($method === 'GET') {
        $klasse_id  = (int)($_GET['klasse_id'] ?? 0);
        // Multi-Klassen: ?klassen=1,2,3
        $klassen_raw = $_GET['klassen'] ?? '';
        $klasse_ids  = array_filter(array_map('intval', explode(',', $klassen_raw)));

        $sql = 'SELECT s.id, s.vorname, s.nachname, s.aktiv,
                       k.bezeichnung AS klasse, k.id AS klasse_id, k.jahrgang
                FROM schueler s
                JOIN klassen k ON k.id = s.klasse_id
                WHERE k.schule_id = ? AND s.aktiv = 1';
        $params = [$user['schule_id']];

        if (!empty($klasse_ids)) {
            $plh = implode(',', array_fill(0, count($klasse_ids), '?'));
            $sql .= " AND s.klasse_id IN ($plh)";
            $params = array_merge($params, $klasse_ids);
        } elseif ($klasse_id) {
            $sql .= ' AND s.klasse_id = ?';
            $params[] = $klasse_id;
        }

        $sql .= ' ORDER BY k.bezeichnung, s.nachname, s.vorname';
        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        json_response($stmt->fetchAll());
    }

    if ($method === 'POST') {
        $vorname   = clean($body['vorname']   ?? '');
        $nachname  = clean($body['nachname']  ?? '');
        $klasse_id = (int)($body['klasse_id'] ?? 0);
        if (!$vorname || !$nachname || !$klasse_id) json_error('Pflichtfelder fehlen.');

        // Sicherstellen, dass die Klasse zur Schule gehört
        $chk = $db->prepare('SELECT id FROM klassen WHERE id = ? AND schule_id = ?');
        $chk->execute([$klasse_id, $user['schule_id']]);
        if (!$chk->fetch()) json_error('Klasse nicht gefunden.', 404);

        $stmt = $db->prepare('INSERT INTO schueler (klasse_id, vorname, nachname) VALUES (?, ?, ?)');
        $stmt->execute([$klasse_id, $vorname, $nachname]);
        $new_id = (int)$db->lastInsertId();
        audit($user['id'], 'schueler', $new_id, 'INSERT', null, $body);
        json_response(['ok' => true, 'id' => $new_id], 201);
    }

    if ($method === 'DELETE' && $id) {
        // Soft-Delete: aktiv = 0 statt physischem Löschen
        $stmt = $db->prepare(
            'UPDATE schueler s JOIN klassen k ON k.id = s.klasse_id
             SET s.aktiv = 0 WHERE s.id = ? AND k.schule_id = ?'
        );
        $stmt->execute([$id, $user['schule_id']]);
        audit($user['id'], 'schueler', $id, 'DELETE');
        json_response(['ok' => true]);
    }

    json_error('Methode nicht erlaubt.', 405);
}

// ============================================================
//  KLASSEN
// ============================================================
function handle_klassen(string $method, ?int $id, array $body): void {
    $user = require_auth();
    $db   = get_db();

    if ($method === 'GET') {
        $stmt = $db->prepare(
            'SELECT k.id, k.bezeichnung, k.jahrgang, k.schuljahr, k.aktiv,
                    COUNT(DISTINCT s.id) AS schueler_anzahl
             FROM klassen k
             LEFT JOIN schueler s ON s.klasse_id = k.id AND s.aktiv = 1
             WHERE k.schule_id = ? AND k.aktiv = 1
             GROUP BY k.id ORDER BY k.schuljahr DESC, k.jahrgang, k.bezeichnung'
        );
        $stmt->execute([$user['schule_id']]);
        json_response($stmt->fetchAll());
    }

    if ($method === 'POST') {
        require_admin(); // Klassen anlegen = Admin-Aktion
        $bez      = clean($body['bezeichnung'] ?? '');
        $jg       = (int)($body['jahrgang']    ?? 0);
        $sj       = clean($body['schuljahr']   ?? '');
        if (!$bez || !$jg || !$sj) json_error('Pflichtfelder fehlen.');
        if ($jg < 5 || $jg > 10)  json_error('Jahrgang muss zwischen 5 und 10 liegen.');

        $stmt = $db->prepare(
            'INSERT INTO klassen (schule_id, bezeichnung, jahrgang, schuljahr) VALUES (?, ?, ?, ?)'
        );
        $stmt->execute([$user['schule_id'], $bez, $jg, $sj]);
        json_response(['ok' => true, 'id' => (int)$db->lastInsertId()], 201);
    }

    if ($method === 'DELETE' && $id) {
        require_admin();
        $stmt = $db->prepare('UPDATE klassen SET aktiv = 0 WHERE id = ? AND schule_id = ?');
        $stmt->execute([$id, $user['schule_id']]);
        json_response(['ok' => true]);
    }

    json_error('Methode nicht erlaubt.', 405);
}

// ============================================================
//  FÄCHER (nur lesen – werden durch Seed angelegt)
// ============================================================
function handle_faecher(string $method): void {
    $user = require_auth();
    if ($method !== 'GET') json_error('Methode nicht erlaubt.', 405);
    $db   = get_db();
    $stmt = $db->prepare(
        'SELECT id, name, kuerzel, soll_jg5, soll_jg6, soll_jg7, soll_jg8, soll_jg9, soll_jg10
         FROM faecher WHERE schule_id = ? AND aktiv = 1 ORDER BY name'
    );
    $stmt->execute([$user['schule_id']]);
    json_response($stmt->fetchAll());
}

// ============================================================
//  LEHRER (für Dropdown im Projekt-Formular)
// ============================================================
function handle_lehrer(string $method): void {
    $user = require_auth();
    if ($method !== 'GET') json_error('Methode nicht erlaubt.', 405);
    $db   = get_db();
    $stmt = $db->prepare(
        'SELECT id, vorname, nachname, kuerzel, rolle FROM benutzer
         WHERE schule_id = ? AND aktiv = 1 ORDER BY nachname, vorname'
    );
    $stmt->execute([$user['schule_id']]);
    json_response($stmt->fetchAll());
}

// ============================================================
//  KOMPETENZRAHMEN
// ============================================================
function handle_kompetenzrahmen(string $method): void {
    $user = require_auth();
    if ($method !== 'GET') json_error('Methode nicht erlaubt.', 405);
    $db   = get_db();
    $stmt = $db->prepare(
        'SELECT kr.id, kr.name, kr.kuerzel, kr.beschreibung, kr.quelle_url,
                f.name AS fach_name, f.kuerzel AS fach_kuerzel
         FROM kompetenzrahmen kr
         LEFT JOIN faecher f ON f.id = kr.fach_id
         WHERE kr.schule_id = ? ORDER BY kr.name'
    );
    $stmt->execute([$user['schule_id']]);
    json_response($stmt->fetchAll());
}

// ============================================================
//  KOMPETENZEN (mit Filter nach Fach und/oder Rahmen)
// ============================================================
function handle_kompetenzen(string $method): void {
    $user     = require_auth();
    if ($method !== 'GET') json_error('Methode nicht erlaubt.', 405);
    $db       = get_db();
    $fach_id  = (int)($_GET['fach_id']  ?? 0);
    $rahmen   = (int)($_GET['rahmen_id'] ?? 0);
    $jg       = (int)($_GET['jahrgang'] ?? 0); // Optional: Jahrgangsstufe vorfiltern

    // Abfrage liefert Kompetenzen mit Bereich und Rahmen als Kontextinformation
    $sql = '
        SELECT k.id, k.code, k.kurzname, k.beschreibung, k.jahrgangsstufe,
               k.eltern_kompetenz_id,
               kb.name AS bereich_name, kb.code AS bereich_code,
               kb.phase, kb.inhaltsfeld, kb.kompetenzbereich,
               kr.name AS rahmen_name, kr.kuerzel AS rahmen_kuerzel,
               f.name  AS fach_name,   f.kuerzel  AS fach_kuerzel
        FROM kompetenzen k
        JOIN kompetenzbereiche kb ON kb.id = k.bereich_id
        JOIN kompetenzrahmen   kr ON kr.id = kb.rahmen_id
        LEFT JOIN faecher       f ON f.id  = k.fach_id
        WHERE kr.schule_id = ? AND k.aktiv = 1
    ';
    $params = [$user['schule_id']];

    // Fachspezifische ODER fächerübergreifende Kompetenzen
    if ($fach_id) {
        $sql .= ' AND (k.fach_id = ? OR k.fach_id IS NULL)';
        $params[] = $fach_id;
    }
    if ($rahmen)  { $sql .= ' AND kr.id = ?'; $params[] = $rahmen; }

    // Jahrgangsstufe: exakter Treffer oder NULL (= alle Jahrgänge)
    if ($jg) {
        // Aus Jahrgang Stufenbezeichnung ableiten: 5-6 → '5/6', 7-8 → '7/8', 9-10 → '9/10'
        $stufe = $jg <= 6 ? '5/6' : ($jg <= 8 ? '7/8' : '9/10');
        $sql  .= ' AND (k.jahrgangsstufe = ? OR k.jahrgangsstufe IS NULL)';
        $params[] = $stufe;
    }

    $sql .= ' ORDER BY kr.kuerzel, kb.reihenfolge, k.code, k.kurzname';
    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    json_response($stmt->fetchAll());
}

// ============================================================
//  PROJEKTE / WERKSTÄTTEN
//  GET    /api/projekte              – Liste (Lernbegleiter sieht nur eigene)
//  POST   /api/projekte              – Neue Werkstatt anlegen
//  GET    /api/projekte/{id}         – Einzelne Werkstatt mit Details
//  PUT    /api/projekte/{id}         – Werkstatt bearbeiten
//  DELETE /api/projekte/{id}         – Löschen (nur Admin)
// ============================================================
function handle_projekte(string $method, ?int $id, array $body): void {
    $user     = require_auth();
    $db       = get_db();
    $istAdmin = $user['rolle'] === 'admin';

    // ----- GET /projekte oder GET /projekte/{id} -----
    if ($method === 'GET') {
        if ($id) {
            $stmt = $db->prepare(
                'SELECT p.*, k.bezeichnung AS klasse, sj.name AS schuljahr_name
                 FROM projekte p
                 JOIN klassen k ON k.id = p.klasse_id
                 LEFT JOIN schuljahre sj ON sj.id = p.schuljahr_id
                 WHERE p.id = ? AND p.schule_id = ?'
            );
            $stmt->execute([$id, $user['schule_id']]);
            $proj = $stmt->fetch();
            if (!$proj) json_error('Werkstatt nicht gefunden.', 404);

            // Zugangskontrolle: Lernbegleiter nur eigene Werkstätten
            if (!$istAdmin) {
                $chk = $db->prepare(
                    'SELECT 1 FROM projekt_lehrer WHERE projekt_id = ? AND benutzer_id = ?'
                );
                $chk->execute([$id, $user['id']]);
                if (!$chk->fetch()) json_error('Keine Berechtigung.', 403);
            }

            // Lernbegleiter
            $stmt = $db->prepare(
                'SELECT b.id, b.vorname, b.nachname, b.kuerzel, pl.rolle
                 FROM projekt_lehrer pl JOIN benutzer b ON b.id = pl.benutzer_id
                 WHERE pl.projekt_id = ? ORDER BY pl.rolle ASC'
            );
            $stmt->execute([$id]);
            $proj['lernbegleiter'] = $stmt->fetchAll();

            // Schüler
            $stmt = $db->prepare(
                'SELECT s.id, s.vorname, s.nachname FROM schueler s
                 JOIN projekt_schueler ps ON ps.schueler_id = s.id
                 WHERE ps.projekt_id = ?'
            );
            $stmt->execute([$id]);
            $proj['schueler'] = $stmt->fetchAll();

            // Stunden
            $stmt = $db->prepare(
                'SELECT ps.fach_id, f.name AS fach_name, f.kuerzel, ps.stunden, ps.notiz
                 FROM projekt_stunden ps JOIN faecher f ON f.id = ps.fach_id
                 WHERE ps.projekt_id = ?'
            );
            $stmt->execute([$id]);
            $proj['stunden'] = $stmt->fetchAll();

            // Kompetenzen
            $stmt = $db->prepare(
                'SELECT DISTINCT k.id, k.code, k.kurzname, kb.name AS bereich, kr.kuerzel AS rahmen
                 FROM projekt_schueler_kompetenzen psk
                 JOIN kompetenzen k        ON k.id  = psk.kompetenz_id
                 JOIN kompetenzbereiche kb ON kb.id = k.bereich_id
                 JOIN kompetenzrahmen kr   ON kr.id = kb.rahmen_id
                 WHERE psk.projekt_id = ?'
            );
            $stmt->execute([$id]);
            $proj['kompetenzen'] = $stmt->fetchAll();

            json_response($proj);
        }

        // Liste
        $schuljahr_id = (int)($_GET['schuljahr_id'] ?? 0);
        $sql = '
            SELECT p.id, p.name, p.datum_von, p.datum_bis, p.status,
                   p.laufzeit, p.max_schueler, p.praesentation_datum,
                   sj.name AS schuljahr_name,
                   COUNT(DISTINCT ps.schueler_id) AS schueler_anzahl,
                   COUNT(DISTINCT psk.kompetenz_id) AS kompetenzen_anzahl,
                   GROUP_CONCAT(DISTINCT CONCAT(bl.vorname, " ", bl.nachname)
                                ORDER BY pl.rolle ASC SEPARATOR ", ") AS lernbegleiter,
                   GROUP_CONCAT(DISTINCT k.bezeichnung
                                ORDER BY k.jahrgang, k.bezeichnung SEPARATOR ", ") AS klassen
            FROM projekte p
            LEFT JOIN schuljahre sj ON sj.id = p.schuljahr_id
            LEFT JOIN projekt_klassen pk ON pk.projekt_id = p.id
            LEFT JOIN klassen k ON k.id = pk.klasse_id
            LEFT JOIN projekt_lehrer pl ON pl.projekt_id = p.id
            LEFT JOIN benutzer bl ON bl.id = pl.benutzer_id
            LEFT JOIN projekt_schueler ps ON ps.projekt_id = p.id
            LEFT JOIN projekt_schueler_kompetenzen psk ON psk.projekt_id = p.id
            WHERE p.schule_id = ?
        ';
        $params = [$user['schule_id']];

        // Lernbegleiter sehen nur eigene Werkstätten
        if (!$istAdmin) {
            $sql .= ' AND EXISTS (
                SELECT 1 FROM projekt_lehrer pl2
                WHERE pl2.projekt_id = p.id AND pl2.benutzer_id = ?
            )';
            $params[] = $user['id'];
        }

        if ($schuljahr_id) { $sql .= ' AND p.schuljahr_id = ?'; $params[] = $schuljahr_id; }
        $sql .= ' GROUP BY p.id ORDER BY p.datum_von DESC';
        $stmt = $db->prepare($sql);
        $stmt->execute($params);
        json_response($stmt->fetchAll());
    }

    // ----- POST /projekte -----
    if ($method === 'POST') {
        $name                = clean($body['name']      ?? '');
        $klasse_id           = (int)($body['klasse_id'] ?? 0);
        $schuljahr_id        = (int)($body['schuljahr_id'] ?? 0) ?: null;
        $datum_von           = $body['datum_von'] ?? '';
        $datum_bis           = $body['datum_bis'] ?? null;
        $praesentation_datum = $body['praesentation_datum'] ?? null;
        $laufzeit            = in_array($body['laufzeit'] ?? '', ['halbjahr','jahr'])
                               ? $body['laufzeit'] : 'jahr';
        $max_schueler        = isset($body['max_schueler']) && $body['max_schueler'] !== ''
                               ? (int)$body['max_schueler'] : null;
        $beschreibung        = clean($body['beschreibung'] ?? '');
        $status              = in_array($body['status'] ?? '', ['geplant','aktiv','abgeschlossen','abgesagt'])
                               ? $body['status'] : 'geplant';
        $lehrer_ids          = array_map('intval', $body['lehrer_ids'] ?? []);

        if (!$name || !$klasse_id || !$datum_von) {
            json_error('Werkstattname, Klasse und Startdatum sind Pflichtfelder.');
        }

        // Max-Teilnehmer prüfen
        $schueler_ids = array_map('intval', $body['schueler_ids'] ?? []);
        if ($max_schueler !== null && count($schueler_ids) > $max_schueler) {
            json_error("Zu viele Teilnehmer: max. {$max_schueler} erlaubt, " . count($schueler_ids) . " ausgewählt.");
        }

        // Eigene ID immer als Lernbegleiter eintragen
        if (!in_array($user['id'], $lehrer_ids)) {
            array_unshift($lehrer_ids, $user['id']);
        }

        $db->beginTransaction();
        try {
            $stmt = $db->prepare(
                'INSERT INTO projekte
                 (schule_id, klasse_id, lehrer_id, schuljahr_id, name, beschreibung,
                  datum_von, datum_bis, laufzeit, max_schueler, praesentation_datum, status)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
            );
            $stmt->execute([
                $user['schule_id'], $klasse_id, $user['id'], $schuljahr_id,
                $name, $beschreibung, $datum_von,
                $datum_bis ?: null, $laufzeit, $max_schueler,
                $praesentation_datum ?: null, $status
            ]);
            $proj_id = (int)$db->lastInsertId();

            // Lernbegleiter eintragen (erster = Leitung)
            $ins_lb = $db->prepare(
                'INSERT IGNORE INTO projekt_lehrer (projekt_id, benutzer_id, rolle) VALUES (?, ?, ?)'
            );
            foreach ($lehrer_ids as $i => $lid) {
                $ins_lb->execute([$proj_id, $lid, $i === 0 ? 'leitung' : 'begleitung']);
            }

            // Klassen eintragen (Multi-Klassen)
            $klasse_ids = array_map('intval', $body['klasse_ids'] ?? [$klasse_id]);
            if (empty($klasse_ids) && $klasse_id) $klasse_ids = [$klasse_id];
            $ins_kl = $db->prepare(
                'INSERT IGNORE INTO projekt_klassen (projekt_id, klasse_id) VALUES (?, ?)'
            );
            foreach ($klasse_ids as $kid) {
                if ($kid) $ins_kl->execute([$proj_id, $kid]);
            }

            // Schüler
            if (!empty($schueler_ids)) {
                $ins = $db->prepare(
                    'INSERT IGNORE INTO projekt_schueler (projekt_id, schueler_id) VALUES (?, ?)'
                );
                foreach ($schueler_ids as $sid) $ins->execute([$proj_id, $sid]);
            }

            // Stunden
            $stunden = $body['stunden'] ?? [];
            if (!empty($stunden)) {
                $ins = $db->prepare(
                    'INSERT INTO projekt_stunden (projekt_id, fach_id, stunden, notiz) VALUES (?, ?, ?, ?)'
                );
                foreach ($stunden as $s) {
                    if (empty($s['fach_id']) || empty($s['stunden'])) continue;
                    $ins->execute([
                        $proj_id, (int)$s['fach_id'],
                        round((float)$s['stunden'], 1), clean($s['notiz'] ?? '')
                    ]);
                }
            }

            // Kompetenzen
            $kompetenzen = $body['kompetenzen'] ?? [];
            if (!empty($kompetenzen)) {
                $ins = $db->prepare(
                    'INSERT IGNORE INTO projekt_schueler_kompetenzen
                     (projekt_id, schueler_id, kompetenz_id, notiz) VALUES (?, ?, ?, ?)'
                );
                foreach ($kompetenzen as $kc) {
                    if (empty($kc['schueler_id']) || empty($kc['kompetenz_id'])) continue;
                    $ins->execute([
                        $proj_id, (int)$kc['schueler_id'],
                        (int)$kc['kompetenz_id'], clean($kc['notiz'] ?? '')
                    ]);
                }
            }

            $db->commit();
            audit($user['id'], 'projekte', $proj_id, 'INSERT', null, ['name' => $name]);
            json_response(['ok' => true, 'id' => $proj_id], 201);

        } catch (Throwable $e) {
            $db->rollBack();
            throw $e;
        }
    }

    // ----- PUT /projekte/{id} -----
    if ($method === 'PUT' && $id) {
        // Zugangskontrolle: nur Leitung oder Admin
        if (!$istAdmin) {
            $chk = $db->prepare(
                'SELECT rolle FROM projekt_lehrer WHERE projekt_id = ? AND benutzer_id = ?'
            );
            $chk->execute([$id, $user['id']]);
            $pl = $chk->fetch();
            if (!$pl || $pl['rolle'] !== 'leitung') {
                json_error('Nur die Leitungsperson darf die Werkstatt bearbeiten.', 403);
            }
        }

        $name                = clean($body['name']      ?? '');
        $klasse_ids_put      = array_map('intval', $body['klasse_ids'] ?? []);
        $klasse_id           = (int)($body['klasse_id'] ?? ($klasse_ids_put[0] ?? 0));
        $schuljahr_id        = (int)($body['schuljahr_id'] ?? 0) ?: null;
        $datum_von           = $body['datum_von'] ?? '';
        $datum_bis           = $body['datum_bis'] ?? null;
        $praesentation_datum = $body['praesentation_datum'] ?? null;
        $laufzeit            = in_array($body['laufzeit'] ?? '', ['halbjahr','jahr'])
                               ? $body['laufzeit'] : 'jahr';
        $max_schueler        = isset($body['max_schueler']) && $body['max_schueler'] !== ''
                               ? (int)$body['max_schueler'] : null;
        $beschreibung        = clean($body['beschreibung'] ?? '');
        $status              = in_array($body['status'] ?? '', ['geplant','aktiv','abgeschlossen','abgesagt'])
                               ? $body['status'] : 'geplant';
        $lehrer_ids          = array_map('intval', $body['lehrer_ids'] ?? []);

        if (!$name || !$datum_von) {
            json_error('Werkstattname und Startdatum sind Pflichtfelder.');
        }

        $db->beginTransaction();
        try {
            // klasse_id nur updaten wenn mitgeschickt (sonst bestehenden Wert behalten)
            if ($klasse_id) {
                $db->prepare(
                    'UPDATE projekte SET
                     klasse_id=?, schuljahr_id=?, name=?, beschreibung=?,
                     datum_von=?, datum_bis=?, laufzeit=?, max_schueler=?,
                     praesentation_datum=?, status=?
                     WHERE id=? AND schule_id=?'
                )->execute([
                    $klasse_id, $schuljahr_id, $name, $beschreibung,
                    $datum_von, $datum_bis ?: null, $laufzeit, $max_schueler,
                    $praesentation_datum ?: null, $status,
                    $id, $user['schule_id']
                ]);
            } else {
                $db->prepare(
                    'UPDATE projekte SET
                     schuljahr_id=?, name=?, beschreibung=?,
                     datum_von=?, datum_bis=?, laufzeit=?, max_schueler=?,
                     praesentation_datum=?, status=?
                     WHERE id=? AND schule_id=?'
                )->execute([
                    $schuljahr_id, $name, $beschreibung,
                    $datum_von, $datum_bis ?: null, $laufzeit, $max_schueler,
                    $praesentation_datum ?: null, $status,
                    $id, $user['schule_id']
                ]);
            }

            // Lernbegleiter neu setzen
            if (!empty($lehrer_ids)) {
                $db->prepare('DELETE FROM projekt_lehrer WHERE projekt_id = ?')->execute([$id]);
                $ins = $db->prepare(
                    'INSERT IGNORE INTO projekt_lehrer (projekt_id, benutzer_id, rolle) VALUES (?, ?, ?)'
                );
                foreach ($lehrer_ids as $i => $lid) {
                    $ins->execute([$id, $lid, $i === 0 ? 'leitung' : 'begleitung']);
                }
            }

            // Stunden aktualisieren (falls mitgeschickt)
            $stunden = $body['stunden'] ?? [];
            if (!empty($stunden)) {
                $db->prepare('DELETE FROM projekt_stunden WHERE projekt_id = ?')->execute([$id]);
                $ins = $db->prepare(
                    'INSERT INTO projekt_stunden (projekt_id, fach_id, stunden, notiz) VALUES (?, ?, ?, ?)'
                );
                foreach ($stunden as $s) {
                    if (empty($s['fach_id']) || empty($s['stunden'])) continue;
                    $ins->execute([
                        $id, (int)$s['fach_id'],
                        round((float)$s['stunden'], 1), clean($s['notiz'] ?? '')
                    ]);
                }
            }

            // Kompetenzen aktualisieren (falls mitgeschickt)
            // Alle Schüler der Werkstatt bekommen die neuen Kompetenzen
            $kompetenz_ids = array_map('intval', $body['kompetenz_ids'] ?? []);
            if (isset($body['kompetenz_ids'])) {
                // Alle bisherigen Kompetenzen dieser Werkstatt löschen
                $db->prepare('DELETE FROM projekt_schueler_kompetenzen WHERE projekt_id = ?')->execute([$id]);
                // Neue Kompetenzen für alle Teilnehmer eintragen
                if (!empty($kompetenz_ids)) {
                    $schueler_stmt = $db->prepare(
                        'SELECT schueler_id FROM projekt_schueler WHERE projekt_id = ?'
                    );
                    $schueler_stmt->execute([$id]);
                    $teilnehmer = $schueler_stmt->fetchAll(PDO::FETCH_COLUMN);
                    if (!empty($teilnehmer)) {
                        $ins_k = $db->prepare(
                            'INSERT IGNORE INTO projekt_schueler_kompetenzen
                             (projekt_id, schueler_id, kompetenz_id) VALUES (?, ?, ?)'
                        );
                        foreach ($teilnehmer as $sid) {
                            foreach ($kompetenz_ids as $kid) {
                                $ins_k->execute([$id, $sid, $kid]);
                            }
                        }
                    }
                }
            }

            $db->commit();
            audit($user['id'], 'projekte', $id, 'UPDATE', null, ['name' => $name]);
            json_response(['ok' => true]);

        } catch (Throwable $e) {
            $db->rollBack();
            throw $e;
        }
    }

    // ----- DELETE /projekte/{id} -----
    if ($method === 'DELETE' && $id) {
        require_admin();
        $stmt = $db->prepare('DELETE FROM projekte WHERE id = ? AND schule_id = ?');
        $stmt->execute([$id, $user['schule_id']]);
        audit($user['id'], 'projekte', $id, 'DELETE');
        json_response(['ok' => true]);
    }

    json_error('Methode nicht erlaubt.', 405);
}

// ============================================================
//  DASHBOARD – Kontingentübersicht je Schüler
// ============================================================
function handle_dashboard(string $method): void {
    $user      = require_auth();
    if ($method !== 'GET') json_error('Methode nicht erlaubt.', 405);
    $db        = get_db();
    $klasse_id = (int)($_GET['klasse_id']  ?? 0);
    $schueler_id = (int)($_GET['schueler_id'] ?? 0);

    // Schüler mit Projektstunden-Summe je Fach laden
    // Stunden werden nur angerechnet wenn:
    // - Werkstatt status = 'abgeschlossen' ODER Schüler individuell abgeschlossen
    $sql = '
        SELECT s.id, s.vorname, s.nachname,
               k.bezeichnung AS klasse, k.jahrgang, k.id AS klasse_id,
               f.id AS fach_id, f.name AS fach_name, f.kuerzel AS fach_kuerzel,
               f.soll_jg5, f.soll_jg6, f.soll_jg7, f.soll_jg8, f.soll_jg9, f.soll_jg10,
               COALESCE(SUM(
                   CASE WHEN (p.status = "abgeschlossen" OR ps_s.abgeschlossen = 1)
                        THEN ps_st.stunden ELSE 0 END
               ), 0) AS projekt_stunden
        FROM schueler s
        JOIN klassen k ON k.id = s.klasse_id
        CROSS JOIN faecher f ON f.schule_id = k.schule_id AND f.aktiv = 1
        LEFT JOIN projekt_schueler ps_s ON ps_s.schueler_id = s.id
        LEFT JOIN projekte p ON p.id = ps_s.projekt_id
        LEFT JOIN projekt_stunden  ps_st ON ps_st.projekt_id = ps_s.projekt_id
                                         AND ps_st.fach_id = f.id
        WHERE k.schule_id = ? AND s.aktiv = 1
    ';
    $params = [$user['schule_id']];
    if ($klasse_id)   { $sql .= ' AND k.id = ?';   $params[] = $klasse_id; }
    if ($schueler_id) { $sql .= ' AND s.id = ?';   $params[] = $schueler_id; }
    $sql .= ' GROUP BY s.id, f.id ORDER BY k.bezeichnung, s.nachname, f.name';

    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $rows = $stmt->fetchAll();

    // Kompetenzen je Schüler (nur aus abgeschlossenen Werkstätten)
    $komp_sql = '
        SELECT psk.schueler_id, k.id, k.code, k.kurzname, kb.name AS bereich, kr.kuerzel AS rahmen
        FROM projekt_schueler_kompetenzen psk
        JOIN schueler s       ON s.id  = psk.schueler_id
        JOIN klassen kl       ON kl.id = s.klasse_id
        JOIN projekt_schueler ps ON ps.projekt_id = psk.projekt_id AND ps.schueler_id = psk.schueler_id
        JOIN projekte p       ON p.id  = psk.projekt_id
        JOIN kompetenzen k    ON k.id  = psk.kompetenz_id
        JOIN kompetenzbereiche kb ON kb.id = k.bereich_id
        JOIN kompetenzrahmen kr   ON kr.id = kb.rahmen_id
        WHERE kl.schule_id = ? AND s.aktiv = 1
          AND (p.status = "abgeschlossen" OR ps.abgeschlossen = 1)
    ';
    $kparams = [$user['schule_id']];
    if ($klasse_id)   { $komp_sql .= ' AND kl.id = ?'; $kparams[] = $klasse_id; }
    if ($schueler_id) { $komp_sql .= ' AND s.id = ?';  $kparams[] = $schueler_id; }
    $komp_sql .= ' GROUP BY psk.schueler_id, k.id';

    $kstmt = $db->prepare($komp_sql);
    $kstmt->execute($kparams);
    $komps = $kstmt->fetchAll();

    // Kompetenzen nach Schüler-ID indexieren
    $komp_by_s = [];
    foreach ($komps as $kc) {
        $komp_by_s[$kc['schueler_id']][] = $kc;
    }

    // Zeilen nach Schüler gruppieren, Soll pro Jahrgang auflösen
    $result = [];
    foreach ($rows as $row) {
        $sid = $row['id'];
        if (!isset($result[$sid])) {
            $result[$sid] = [
                'id'       => $sid,
                'vorname'  => $row['vorname'],
                'nachname' => $row['nachname'],
                'klasse'   => $row['klasse'],
                'klasse_id'=> $row['klasse_id'],
                'jahrgang' => (int)$row['jahrgang'],
                'faecher'  => [],
                'kompetenzen' => $komp_by_s[$sid] ?? [],
            ];
        }
        $jg   = (int)$row['jahrgang'];
        $soll = (int)$row['soll_jg' . $jg];
        $result[$sid]['faecher'][] = [
            'fach_id'         => $row['fach_id'],
            'fach_name'       => $row['fach_name'],
            'fach_kuerzel'    => $row['fach_kuerzel'],
            'soll'            => $soll,
            'projekt_stunden' => round((float)$row['projekt_stunden'], 1),
        ];
    }

    json_response(array_values($result));
}

// ============================================================
//  EXPORT CSV
// ============================================================
function handle_export(string $method, string $sub): void {
    $user = require_auth();
    if ($method !== 'GET') json_error('Methode nicht erlaubt.', 405);
    $db        = get_db();
    $klasse_id = (int)($_GET['klasse_id'] ?? 0);

    if ($sub === 'stunden') {
        // Stundenkontingent je Schüler und Fach
        header('Content-Type: text/csv; charset=utf-8');
        header('Content-Disposition: attachment; filename="projektstunden.csv"');
        echo "\xEF\xBB\xBF"; // UTF-8 BOM für Excel

        // Fächer in korrekter Reihenfolge laden
        $fstmt = $db->prepare('SELECT id, name FROM faecher WHERE schule_id = ? AND aktiv = 1 ORDER BY name');
        $fstmt->execute([$user['schule_id']]);
        $faecher = $fstmt->fetchAll();

        // Header-Zeile
        $header = ['Klasse','Nachname','Vorname'];
        foreach ($faecher as $f) $header[] = $f['name'];
        $header[] = 'Gesamt Projektstunden';
        echo implode(';', $header) . "\r\n";

        // Daten
        $sql = '
            SELECT s.id, s.vorname, s.nachname, k.bezeichnung AS klasse
            FROM schueler s JOIN klassen k ON k.id = s.klasse_id
            WHERE k.schule_id = ? AND s.aktiv = 1
        ';
        $params = [$user['schule_id']];
        if ($klasse_id) { $sql .= ' AND k.id = ?'; $params[] = $klasse_id; }
        $sql .= ' ORDER BY k.bezeichnung, s.nachname, s.vorname';
        $sstmt = $db->prepare($sql);
        $sstmt->execute($params);

        while ($s = $sstmt->fetch()) {
            // Projektstunden je Fach für diesen Schüler
            $hstmt = $db->prepare(
                'SELECT ps.fach_id, SUM(ps.stunden) AS summe
                 FROM projekt_stunden ps
                 JOIN projekt_schueler pss ON pss.projekt_id = ps.projekt_id
                 WHERE pss.schueler_id = ?
                 GROUP BY ps.fach_id'
            );
            $hstmt->execute([$s['id']]);
            $h_map = [];
            $gesamt = 0;
            foreach ($hstmt->fetchAll() as $h) {
                $h_map[$h['fach_id']] = (float)$h['summe'];
                $gesamt += (float)$h['summe'];
            }
            $row = [$s['klasse'], $s['nachname'], $s['vorname']];
            foreach ($faecher as $f) {
                $row[] = number_format($h_map[$f['id']] ?? 0, 1, ',', '');
            }
            $row[] = number_format($gesamt, 1, ',', '');
            echo implode(';', $row) . "\r\n";
        }
        exit;
    }

    if ($sub === 'kompetenzen') {
        header('Content-Type: text/csv; charset=utf-8');
        header('Content-Disposition: attachment; filename="kompetenzen.csv"');
        echo "\xEF\xBB\xBF";

        echo implode(';', ['Klasse','Nachname','Vorname','Rahmen','Bereich','Code','Kompetenz','Projekt','Datum']) . "\r\n";

        $stmt = $db->prepare('
            SELECT k.bezeichnung AS klasse, s.nachname, s.vorname,
                   kr.kuerzel AS rahmen, kb.name AS bereich,
                   km.code, km.kurzname,
                   p.name AS projekt, p.datum_von,
                   psk.notiz
            FROM projekt_schueler_kompetenzen psk
            JOIN schueler s       ON s.id  = psk.schueler_id
            JOIN klassen  k       ON k.id  = s.klasse_id
            JOIN projekte p       ON p.id  = psk.projekt_id
            JOIN kompetenzen km   ON km.id = psk.kompetenz_id
            JOIN kompetenzbereiche kb ON kb.id = km.bereich_id
            JOIN kompetenzrahmen  kr ON kr.id  = kb.rahmen_id
            WHERE k.schule_id = ? AND s.aktiv = 1
            ORDER BY k.bezeichnung, s.nachname, kr.kuerzel, kb.reihenfolge
        ');
        $params = [$user['schule_id']];
        $stmt->execute($params);
        while ($r = $stmt->fetch()) {
            echo implode(';', [
                $r['klasse'], $r['nachname'], $r['vorname'],
                $r['rahmen'], $r['bereich'], $r['code'] ?? '',
                $r['kurzname'], $r['projekt'], $r['datum_von'],
            ]) . "\r\n";
        }
        exit;
    }

    json_error('Unbekannter Export-Typ.', 404);
}

// ============================================================
//  BENUTZERVERWALTUNG
//  Alle schreibenden Operationen sind auf Admins beschränkt.
//  Eine Lehrkraft darf nur ihr eigenes Passwort ändern.
// ============================================================
function handle_benutzer(string $method, ?int $id, string $sub, array $body): void {
    $user = require_auth();
    $db   = get_db();

    // ----- GET /benutzer  –  Liste aller Benutzer (nur Admin) -----
    if ($method === 'GET' && !$id) {
        require_admin();
        $stmt = $db->prepare(
            'SELECT id, vorname, nachname, email, rolle, kuerzel, aktiv, erstellt_am
             FROM benutzer WHERE schule_id = ? ORDER BY nachname, vorname'
        );
        $stmt->execute([$user['schule_id']]);
        json_response($stmt->fetchAll());
    }

    // ----- GET /benutzer/{id}  –  Einzelnen Benutzer anzeigen (Admin) -----
    if ($method === 'GET' && $id) {
        require_admin();
        $stmt = $db->prepare(
            'SELECT id, vorname, nachname, email, rolle, kuerzel, aktiv, erstellt_am
             FROM benutzer WHERE id = ? AND schule_id = ?'
        );
        $stmt->execute([$id, $user['schule_id']]);
        $row = $stmt->fetch();
        if (!$row) json_error('Benutzer nicht gefunden.', 404);
        json_response($row);
    }

    // ----- POST /benutzer  –  Neuen Benutzer anlegen (nur Admin) -----
    if ($method === 'POST') {
        require_admin();

        // Pflichtfelder prüfen
        $vorname  = clean($body['vorname']  ?? '');
        $nachname = clean($body['nachname'] ?? '');
        $email    = trim(strtolower($body['email'] ?? ''));
        $passwort = $body['passwort'] ?? '';
        $rolle    = in_array($body['rolle'] ?? '', ['admin', 'lehrer']) ? $body['rolle'] : 'lehrer';
        $kuerzel  = clean($body['kuerzel'] ?? '');

        if (!$vorname || !$nachname || !$email || !$passwort) {
            json_error('Vorname, Nachname, E-Mail und Passwort sind Pflichtfelder.');
        }
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            json_error('Ungültige E-Mail-Adresse.');
        }
        // Passwort-Mindestanforderungen: min. 8 Zeichen, 1 Großbuchstabe, 1 Zahl
        if (strlen($passwort) < 8 || !preg_match('/[A-Z]/', $passwort) || !preg_match('/[0-9]/', $passwort)) {
            json_error('Passwort muss mindestens 8 Zeichen, einen Großbuchstaben und eine Zahl enthalten.');
        }

        // E-Mail darf nicht doppelt vorkommen (innerhalb derselben Schule)
        $chk = $db->prepare('SELECT id FROM benutzer WHERE email = ? AND schule_id = ?');
        $chk->execute([$email, $user['schule_id']]);
        if ($chk->fetch()) json_error('Diese E-Mail-Adresse ist bereits vergeben.');

        // Passwort hashen (bcrypt, Kosten 12)
        $hash = password_hash($passwort, PASSWORD_BCRYPT, ['cost' => 12]);

        $stmt = $db->prepare(
            'INSERT INTO benutzer (schule_id, vorname, nachname, email, passwort_hash, rolle, kuerzel)
             VALUES (?, ?, ?, ?, ?, ?, ?)'
        );
        $stmt->execute([$user['schule_id'], $vorname, $nachname, $email, $hash, $rolle, $kuerzel ?: null]);
        $new_id = (int)$db->lastInsertId();

        audit($user['id'], 'benutzer', $new_id, 'INSERT', null,
              ['vorname' => $vorname, 'nachname' => $nachname, 'rolle' => $rolle]);

        json_response(['ok' => true, 'id' => $new_id], 201);
    }

    // ----- PUT /benutzer/{id}  –  Stammdaten ändern (nur Admin) -----
    if ($method === 'PUT' && $id && $sub !== 'passwort') {
        require_admin();

        // Prüfen ob Benutzer zur Schule gehört
        $chk = $db->prepare('SELECT id FROM benutzer WHERE id = ? AND schule_id = ?');
        $chk->execute([$id, $user['schule_id']]);
        if (!$chk->fetch()) json_error('Benutzer nicht gefunden.', 404);

        $vorname  = clean($body['vorname']  ?? '');
        $nachname = clean($body['nachname'] ?? '');
        $email    = trim(strtolower($body['email'] ?? ''));
        $rolle    = in_array($body['rolle'] ?? '', ['admin', 'lehrer']) ? $body['rolle'] : null;
        $kuerzel  = clean($body['kuerzel']  ?? '');
        $aktiv    = isset($body['aktiv']) ? (int)(bool)$body['aktiv'] : null;

        if (!$vorname || !$nachname || !$email) json_error('Vorname, Nachname und E-Mail sind Pflichtfelder.');
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) json_error('Ungültige E-Mail-Adresse.');

        // Doppelte E-Mail prüfen (andere Benutzer, gleiche Schule)
        $chk2 = $db->prepare('SELECT id FROM benutzer WHERE email = ? AND schule_id = ? AND id != ?');
        $chk2->execute([$email, $user['schule_id'], $id]);
        if ($chk2->fetch()) json_error('Diese E-Mail-Adresse ist bereits vergeben.');

        // Sicherheit: letzten Admin nicht degradieren
        if ($rolle === 'lehrer') {
            $adminCount = $db->prepare(
                'SELECT COUNT(*) FROM benutzer WHERE schule_id = ? AND rolle = "admin" AND aktiv = 1 AND id != ?'
            );
            $adminCount->execute([$user['schule_id'], $id]);
            if ((int)$adminCount->fetchColumn() === 0) {
                json_error('Es muss mindestens ein Administrator verbleiben.');
            }
        }

        $sql    = 'UPDATE benutzer SET vorname=?, nachname=?, email=?, kuerzel=?';
        $params = [$vorname, $nachname, $email, $kuerzel ?: null];
        if ($rolle  !== null) { $sql .= ', rolle=?';  $params[] = $rolle; }
        if ($aktiv  !== null) { $sql .= ', aktiv=?';  $params[] = $aktiv; }
        $sql .= ' WHERE id=? AND schule_id=?';
        $params[] = $id;
        $params[] = $user['schule_id'];

        $stmt = $db->prepare($sql);
        $stmt->execute($params);

        audit($user['id'], 'benutzer', $id, 'UPDATE',
              null, ['vorname' => $vorname, 'rolle' => $rolle]);

        json_response(['ok' => true]);
    }

    // ----- PUT /benutzer/{id}/passwort  –  Passwort ändern -----
    // Admin darf jedes Passwort ändern; Lehrer nur das eigene.
    if ($method === 'PUT' && $id && $sub === 'passwort') {
        $istAdmin = $user['rolle'] === 'admin';
        $istEigen = $user['id']   === $id;

        if (!$istAdmin && !$istEigen) {
            json_error('Keine Berechtigung.', 403);
        }

        // Lehrer muss altes Passwort bestätigen
        if (!$istAdmin) {
            $altPass = $body['altes_passwort'] ?? '';
            $row = $db->prepare('SELECT passwort_hash FROM benutzer WHERE id = ?');
            $row->execute([$id]);
            $row = $row->fetch();
            if (!$row || !password_verify($altPass, $row['passwort_hash'])) {
                json_error('Altes Passwort ist falsch.', 403);
            }
        }

        $neuesPass = $body['neues_passwort'] ?? '';
        if (strlen($neuesPass) < 8 || !preg_match('/[A-Z]/', $neuesPass) || !preg_match('/[0-9]/', $neuesPass)) {
            json_error('Passwort muss mindestens 8 Zeichen, einen Großbuchstaben und eine Zahl enthalten.');
        }

        $hash = password_hash($neuesPass, PASSWORD_BCRYPT, ['cost' => 12]);
        $stmt = $db->prepare('UPDATE benutzer SET passwort_hash=? WHERE id=? AND schule_id=?');
        $stmt->execute([$hash, $id, $user['schule_id']]);

        audit($user['id'], 'benutzer', $id, 'UPDATE', null, ['aktion' => 'passwort_geaendert']);

        json_response(['ok' => true]);
    }

    // ----- DELETE /benutzer/{id}  –  Benutzer deaktivieren (nur Admin) -----
    if ($method === 'DELETE' && $id) {
        require_admin();

        // Eigenen Account nicht deaktivieren
        if ($id === $user['id']) json_error('Eigenen Account nicht deaktivierbar.');

        // Letzten Admin nicht deaktivieren
        $chk = $db->prepare(
            'SELECT rolle FROM benutzer WHERE id = ? AND schule_id = ?'
        );
        $chk->execute([$id, $user['schule_id']]);
        $target = $chk->fetch();
        if (!$target) json_error('Benutzer nicht gefunden.', 404);

        if ($target['rolle'] === 'admin') {
            $cnt = $db->prepare(
                'SELECT COUNT(*) FROM benutzer WHERE schule_id=? AND rolle="admin" AND aktiv=1 AND id!=?'
            );
            $cnt->execute([$user['schule_id'], $id]);
            if ((int)$cnt->fetchColumn() === 0) {
                json_error('Letzten Administrator nicht deaktivierbar.');
            }
        }

        // Soft-Delete: Benutzer wird auf aktiv=0 gesetzt, Daten bleiben erhalten
        $stmt = $db->prepare('UPDATE benutzer SET aktiv=0 WHERE id=? AND schule_id=?');
        $stmt->execute([$id, $user['schule_id']]);

        audit($user['id'], 'benutzer', $id, 'DELETE');
        json_response(['ok' => true]);
    }

    json_error('Methode nicht erlaubt.', 405);
}

// ============================================================
//  SCHULJAHRE
//  GET    /api/schuljahre          – Liste aller Schuljahre
//  POST   /api/schuljahre          – Neues Schuljahr anlegen (Admin)
//  PUT    /api/schuljahre/{id}     – Schuljahr bearbeiten (Admin)
//  DELETE /api/schuljahre/{id}     – Schuljahr löschen (Admin, nur wenn leer)
//  POST   /api/schuljahre/{id}/aktivieren – Schuljahr aktivieren (Admin)
// ============================================================
function handle_schuljahre(string $method, ?int $id, string $sub, array $body): void {
    $user = require_auth();
    $db   = get_db();

    // GET /schuljahre – alle Schuljahre mit Statistik
    if ($method === 'GET' && !$id) {
        $stmt = $db->prepare(
            'SELECT sj.id, sj.name, sj.beginn, sj.ende, sj.status, sj.erstellt_am,
                    COUNT(DISTINCT k.id) AS klassen_anzahl,
                    COUNT(DISTINCT s.id) AS schueler_anzahl,
                    COUNT(DISTINCT p.id) AS projekte_anzahl
             FROM schuljahre sj
             LEFT JOIN klassen k  ON k.schuljahr_id  = sj.id
             LEFT JOIN schueler_schuljahr ss ON ss.schuljahr_id = sj.id
             LEFT JOIN schueler s  ON s.id = ss.schueler_id AND s.aktiv = 1
             LEFT JOIN projekte p  ON p.schuljahr_id  = sj.id
             WHERE sj.schule_id = ?
             GROUP BY sj.id
             ORDER BY sj.beginn DESC'
        );
        $stmt->execute([$user['schule_id']]);
        json_response($stmt->fetchAll());
    }

    // GET /schuljahre/{id} – Einzelnes Schuljahr
    if ($method === 'GET' && $id) {
        $stmt = $db->prepare(
            'SELECT id, name, beginn, ende, status, erstellt_am
             FROM schuljahre WHERE id = ? AND schule_id = ?'
        );
        $stmt->execute([$id, $user['schule_id']]);
        $row = $stmt->fetch();
        if (!$row) json_error('Schuljahr nicht gefunden.', 404);
        json_response($row);
    }

    // POST /schuljahre – Neues Schuljahr anlegen
    if ($method === 'POST' && !$id) {
        require_admin();
        $name   = clean($body['name']   ?? '');
        $beginn = $body['beginn'] ?? '';
        $ende   = $body['ende']   ?? '';
        $status = in_array($body['status'] ?? '', ['zukuenftig','aktiv','abgeschlossen'])
                  ? $body['status'] : 'zukuenftig';

        if (!$name || !$beginn || !$ende) {
            json_error('Name, Beginn und Ende sind Pflichtfelder.');
        }

        // Nur ein aktives Schuljahr erlaubt
        if ($status === 'aktiv') {
            $chk = $db->prepare(
                'SELECT id FROM schuljahre WHERE schule_id = ? AND status = "aktiv"'
            );
            $chk->execute([$user['schule_id']]);
            if ($chk->fetch()) {
                json_error('Es gibt bereits ein aktives Schuljahr. Bitte zuerst das aktuelle abschließen.');
            }
        }

        $stmt = $db->prepare(
            'INSERT INTO schuljahre (schule_id, name, beginn, ende, status)
             VALUES (?, ?, ?, ?, ?)'
        );
        $stmt->execute([$user['schule_id'], $name, $beginn, $ende, $status]);
        $new_id = (int)$db->lastInsertId();
        audit($user['id'], 'schuljahre', $new_id, 'INSERT', null, $body);
        json_response(['ok' => true, 'id' => $new_id], 201);
    }

    // PUT /schuljahre/{id} – Schuljahr bearbeiten
    if ($method === 'PUT' && $id && $sub !== 'aktivieren') {
        require_admin();
        $name   = clean($body['name']   ?? '');
        $beginn = $body['beginn'] ?? '';
        $ende   = $body['ende']   ?? '';

        if (!$name || !$beginn || !$ende) {
            json_error('Name, Beginn und Ende sind Pflichtfelder.');
        }

        // Abgeschlossene Schuljahre nicht mehr bearbeiten
        $chk = $db->prepare('SELECT status FROM schuljahre WHERE id = ? AND schule_id = ?');
        $chk->execute([$id, $user['schule_id']]);
        $sj = $chk->fetch();
        if (!$sj) json_error('Schuljahr nicht gefunden.', 404);
        if ($sj['status'] === 'abgeschlossen') {
            json_error('Abgeschlossene Schuljahre können nicht bearbeitet werden.');
        }

        $stmt = $db->prepare(
            'UPDATE schuljahre SET name = ?, beginn = ?, ende = ?
             WHERE id = ? AND schule_id = ?'
        );
        $stmt->execute([$name, $beginn, $ende, $id, $user['schule_id']]);
        audit($user['id'], 'schuljahre', $id, 'UPDATE', null, $body);
        json_response(['ok' => true]);
    }

    // POST /schuljahre/{id}/aktivieren – Schuljahr aktivieren
    if ($method === 'POST' && $id && $sub === 'aktivieren') {
        require_admin();

        // Prüfen ob das Schuljahr existiert
        $chk = $db->prepare('SELECT id, status FROM schuljahre WHERE id = ? AND schule_id = ?');
        $chk->execute([$id, $user['schule_id']]);
        $sj = $chk->fetch();
        if (!$sj) json_error('Schuljahr nicht gefunden.', 404);
        if ($sj['status'] === 'abgeschlossen') {
            json_error('Abgeschlossene Schuljahre können nicht aktiviert werden.');
        }

        $db->beginTransaction();
        try {
            // Aktuell aktives Schuljahr abschließen
            $db->prepare(
                'UPDATE schuljahre SET status = "abgeschlossen"
                 WHERE schule_id = ? AND status = "aktiv"'
            )->execute([$user['schule_id']]);

            // Neues Schuljahr aktivieren
            $db->prepare(
                'UPDATE schuljahre SET status = "aktiv" WHERE id = ?'
            )->execute([$id]);

            $db->commit();
            audit($user['id'], 'schuljahre', $id, 'UPDATE', null, ['aktion' => 'aktiviert']);
            json_response(['ok' => true]);
        } catch (Throwable $e) {
            $db->rollBack();
            throw $e;
        }
    }

    // DELETE /schuljahre/{id} – Schuljahr löschen (nur wenn leer)
    if ($method === 'DELETE' && $id) {
        require_admin();

        // Aktives Schuljahr nicht löschbar
        $chk = $db->prepare('SELECT status FROM schuljahre WHERE id = ? AND schule_id = ?');
        $chk->execute([$id, $user['schule_id']]);
        $sj = $chk->fetch();
        if (!$sj) json_error('Schuljahr nicht gefunden.', 404);
        if ($sj['status'] === 'aktiv') {
            json_error('Das aktive Schuljahr kann nicht gelöscht werden.');
        }

        // Prüfen ob Projekte oder Schüler vorhanden
        $chk2 = $db->prepare(
            'SELECT COUNT(*) FROM projekte WHERE schuljahr_id = ?'
        );
        $chk2->execute([$id]);
        if ((int)$chk2->fetchColumn() > 0) {
            json_error('Schuljahr kann nicht gelöscht werden – es sind noch Projekte zugeordnet.');
        }

        $chk3 = $db->prepare(
            'SELECT COUNT(*) FROM schueler_schuljahr WHERE schuljahr_id = ?'
        );
        $chk3->execute([$id]);
        if ((int)$chk3->fetchColumn() > 0) {
            json_error('Schuljahr kann nicht gelöscht werden – es sind noch Schüler zugeordnet.');
        }

        $db->prepare('DELETE FROM schuljahre WHERE id = ?')->execute([$id]);
        audit($user['id'], 'schuljahre', $id, 'DELETE');
        json_response(['ok' => true]);
    }

    json_error('Methode nicht erlaubt.', 405);
}

// ============================================================
//  SCHÜLER-IMPORT (CSV/TXT aus Schild-NRW)
//  POST /api/import/vorschau   – Datei hochladen, Vorschau liefern
//  POST /api/import/ausfuehren – Import bestätigen und ausführen
// ============================================================
function handle_import(string $method, string $sub, array $body): void {
    $user = require_auth();
    require_admin();
    $db = get_db();

    // Aktives Schuljahr holen (oder aus Body falls angegeben)
    $schuljahr_id = (int)($body['schuljahr_id'] ?? 0);
    if (!$schuljahr_id) {
        $sj = $db->prepare(
            'SELECT id FROM schuljahre WHERE schule_id = ? AND status = "aktiv" LIMIT 1'
        );
        $sj->execute([$user['schule_id']]);
        $row = $sj->fetch();
        if (!$row) json_error('Kein aktives Schuljahr gefunden. Bitte zuerst ein Schuljahr aktivieren.');
        $schuljahr_id = $row['id'];
    }

    // GET /api/import/log – letzte Importe
    if ($method === 'GET' && $sub === 'log') {
        $stmt = $db->prepare(
            'SELECT il.id, il.dateiname, il.neu, il.aktualisiert, il.unveraendert,
                    il.inaktiviert, il.fehler, il.erstellt_am,
                    sj.name AS schuljahr_name,
                    b.vorname, b.nachname
             FROM import_log il
             LEFT JOIN schuljahre sj ON sj.id = il.schuljahr_id
             LEFT JOIN benutzer   b  ON b.id  = il.benutzer_id
             WHERE il.schule_id = ?
             ORDER BY il.erstellt_am DESC
             LIMIT 20'
        );
        $stmt->execute([$user['schule_id']]);
        json_response($stmt->fetchAll());
    }

    // POST /api/import/vorschau
    if ($method === 'POST' && $sub === 'vorschau') {
        if (empty($_FILES['datei'])) json_error('Keine Datei hochgeladen.');
        $tmp  = $_FILES['datei']['tmp_name'];
        $name = $_FILES['datei']['name'];

        $rows = parse_schild_csv($tmp);
        if (empty($rows)) json_error('Datei konnte nicht gelesen werden oder ist leer.');

        $vorschau = analyse_import($db, $rows, $user['schule_id'], $schuljahr_id);
        $vorschau['schuljahr_id'] = $schuljahr_id;
        $vorschau['dateiname']    = $name;
        json_response($vorschau);
    }

    // POST /api/import/ausfuehren
    if ($method === 'POST' && $sub === 'ausfuehren') {
        if (empty($_FILES['datei'])) json_error('Keine Datei hochgeladen.');
        $tmp  = $_FILES['datei']['tmp_name'];
        $name = $_FILES['datei']['name'];

        $rows = parse_schild_csv($tmp);
        if (empty($rows)) json_error('Datei konnte nicht gelesen werden oder ist leer.');

        $ergebnis = fuehre_import_aus($db, $rows, $user['schule_id'], $schuljahr_id, $user['id'], $name);
        json_response($ergebnis);
    }

    json_error('Unbekannte Import-Aktion.', 404);
}

// ============================================================
//  HILFSFUNKTIONEN FÜR DEN IMPORT
// ============================================================

/**
 * Schild-CSV/TXT parsen (Semikolon-getrennt, UTF-8)
 * Gibt Array von assoziativen Arrays zurück
 */
function parse_schild_csv(string $filepath): array {
    $rows = [];
    $handle = fopen($filepath, 'r');
    if (!$handle) return [];

    // Encoding-Erkennung (UTF-8 mit oder ohne BOM, Latin-1)
    $bom = fread($handle, 3);
    if ($bom !== "\xEF\xBB\xBF") {
        // Kein UTF-8 BOM – zurückspulen
        rewind($handle);
    }

    $header = null;
    while (($line = fgets($handle)) !== false) {
        $line = rtrim($line, "\r\n");
        if (empty($line)) continue;

        // Encoding konvertieren falls nötig
        if (!mb_detect_encoding($line, 'UTF-8', true)) {
            $line = mb_convert_encoding($line, 'UTF-8', 'ISO-8859-1');
        }

        $cols = str_getcsv($line, ';', '"');

        if ($header === null) {
            // Header-Zeile: Anführungszeichen aus Spaltennamen entfernen
            $header = array_map(fn($h) => trim($h, '"'), $cols);
            continue;
        }

        if (count($cols) < count($header)) {
            // Zu wenige Spalten – überspringen
            continue;
        }

        $row = [];
        foreach ($header as $i => $h) {
            $row[$h] = trim($cols[$i] ?? '', '"');
        }
        $rows[] = $row;
    }

    fclose($handle);
    return $rows;
}

/**
 * Analysiert die CSV-Zeilen ohne zu schreiben
 * Liefert Vorschau: neu/aktualisiert/unverändert
 */
function analyse_import(PDO $db, array $rows, int $schule_id, int $schuljahr_id): array {
    $neu          = [];
    $aktualisiert = [];
    $unveraendert = [];
    $fehler       = [];

    foreach ($rows as $i => $row) {
        $schild_id = (int)($row['Interne ID-Nummer'] ?? 0);
        $vorname   = trim($row['Vorname']   ?? '');
        $nachname  = trim($row['Nachname']  ?? '');
        $klasse    = trim($row['Klasse']    ?? '');
        $jahrgang  = (int)($row['Jahrgang'] ?? 0);
        $geschlecht_raw = strtolower(trim($row['Geschlecht'] ?? ''));
        $klassenlehrer  = trim(($row['Klassenlehrer: Name'] ?? '') . ' ' .
                               ($row['Klassenlehrer: Vorname'] ?? ''));

        // Pflichtfelder prüfen
        if (!$schild_id || !$vorname || !$nachname || !$klasse || !$jahrgang) {
            $fehler[] = [
                'zeile'  => $i + 2,
                'grund'  => 'Pflichtfelder fehlen (ID, Name, Klasse oder Jahrgang)',
                'daten'  => "$vorname $nachname"
            ];
            continue;
        }

        // Geschlecht normalisieren
        $geschlecht = match(true) {
            str_starts_with($geschlecht_raw, 'm') => 'm',
            str_starts_with($geschlecht_raw, 'w') => 'w',
            str_starts_with($geschlecht_raw, 'd') => 'd',
            default => 'x'
        };

        // Schüler in DB suchen
        $stmt = $db->prepare(
            'SELECT s.id, s.vorname, s.nachname, s.geschlecht,
                    k.bezeichnung AS klasse
             FROM schueler s
             LEFT JOIN klassen k ON k.id = s.klasse_id
             WHERE s.schild_id = ?'
        );
        $stmt->execute([$schild_id]);
        $existing = $stmt->fetch();

        $eintrag = [
            'schild_id'      => $schild_id,
            'vorname'        => $vorname,
            'nachname'       => $nachname,
            'klasse'         => $klasse,
            'jahrgang'       => $jahrgang,
            'geschlecht'     => $geschlecht,
            'klassenlehrer'  => trim($klassenlehrer),
        ];

        if (!$existing) {
            $neu[] = $eintrag;
        } elseif (
            $existing['vorname']    !== $vorname   ||
            $existing['nachname']   !== $nachname  ||
            $existing['klasse']     !== $klasse    ||
            ($existing['geschlecht'] ?? '') !== $geschlecht
        ) {
            $eintrag['id'] = $existing['id'];
            $aktualisiert[] = $eintrag;
        } else {
            $eintrag['id'] = $existing['id'];
            $unveraendert[] = $eintrag;
        }
    }

    return [
        'neu'          => $neu,
        'aktualisiert' => $aktualisiert,
        'unveraendert' => $unveraendert,
        'fehler'       => $fehler,
        'statistik'    => [
            'neu'          => count($neu),
            'aktualisiert' => count($aktualisiert),
            'unveraendert' => count($unveraendert),
            'fehler'       => count($fehler),
            'gesamt'       => count($rows),
        ]
    ];
}

/**
 * Führt den Import tatsächlich aus
 */
function fuehre_import_aus(
    PDO $db, array $rows, int $schule_id, int $schuljahr_id,
    int $benutzer_id, string $dateiname
): array {
    $zaehler = ['neu' => 0, 'aktualisiert' => 0, 'unveraendert' => 0,
                'inaktiviert' => 0, 'fehler' => 0];
    $importierte_schild_ids = [];

    $db->beginTransaction();
    try {
        $now = date('Y-m-d H:i:s');

        foreach ($rows as $row) {
            $schild_id = (int)($row['Interne ID-Nummer'] ?? 0);
            $vorname   = trim($row['Vorname']   ?? '');
            $nachname  = trim($row['Nachname']  ?? '');
            $klasse_bez = trim($row['Klasse']   ?? '');
            $jahrgang  = (int)($row['Jahrgang'] ?? 0);
            $gebdat    = trim($row['Geburtsdatum'] ?? '');
            $klassenlehrer = trim(($row['Klassenlehrer: Name'] ?? '') . ' ' .
                                  ($row['Klassenlehrer: Vorname'] ?? ''));
            $geschlecht_raw = strtolower(trim($row['Geschlecht'] ?? ''));

            if (!$schild_id || !$vorname || !$nachname || !$klasse_bez || !$jahrgang) {
                $zaehler['fehler']++;
                continue;
            }

            $geschlecht = match(true) {
                str_starts_with($geschlecht_raw, 'm') => 'm',
                str_starts_with($geschlecht_raw, 'w') => 'w',
                str_starts_with($geschlecht_raw, 'd') => 'd',
                default => 'x'
            };

            // Geburtsdatum parsen (Schild: DD.MM.YYYY → YYYY-MM-DD)
            $geburtsdatum = null;
            if ($gebdat && preg_match('/^(\d{2})\.(\d{2})\.(\d{4})$/', $gebdat, $m)) {
                $geburtsdatum = "{$m[3]}-{$m[2]}-{$m[1]}";
            }

            // Klasse anlegen falls nicht vorhanden
            $kl_stmt = $db->prepare(
                'SELECT id FROM klassen
                 WHERE schule_id = ? AND bezeichnung = ? AND schuljahr_id = ?'
            );
            $kl_stmt->execute([$schule_id, $klasse_bez, $schuljahr_id]);
            $klasse = $kl_stmt->fetch();

            if (!$klasse) {
                $ins_kl = $db->prepare(
                    'INSERT INTO klassen
                     (schule_id, bezeichnung, jahrgang, schuljahr, schuljahr_id, klassenlehrer_name)
                     VALUES (?, ?, ?, (SELECT name FROM schuljahre WHERE id = ?), ?, ?)'
                );
                $ins_kl->execute([
                    $schule_id, $klasse_bez, $jahrgang,
                    $schuljahr_id, $schuljahr_id,
                    trim($klassenlehrer) ?: null
                ]);
                $klasse_id = (int)$db->lastInsertId();
            } else {
                $klasse_id = $klasse['id'];
                // Klassenlehrer aktualisieren
                if (trim($klassenlehrer)) {
                    $db->prepare(
                        'UPDATE klassen SET klassenlehrer_name = ? WHERE id = ?'
                    )->execute([trim($klassenlehrer), $klasse_id]);
                }
            }

            // Schüler suchen
            $s_stmt = $db->prepare(
                'SELECT id, vorname, nachname, geschlecht, klasse_id FROM schueler WHERE schild_id = ?'
            );
            $s_stmt->execute([$schild_id]);
            $existing = $s_stmt->fetch();

            if (!$existing) {
                // Neuen Schüler anlegen
                $db->prepare(
                    'INSERT INTO schueler
                     (schild_id, klasse_id, vorname, nachname, geschlecht, geburtsdatum,
                      aktiv, zuletzt_importiert)
                     VALUES (?, ?, ?, ?, ?, ?, 1, ?)'
                )->execute([
                    $schild_id, $klasse_id, $vorname, $nachname,
                    $geschlecht, $geburtsdatum, $now
                ]);
                $schueler_id = (int)$db->lastInsertId();
                $zaehler['neu']++;
            } else {
                // Bestehenden Schüler aktualisieren
                $db->prepare(
                    'UPDATE schueler SET
                     klasse_id = ?, vorname = ?, nachname = ?,
                     geschlecht = ?, geburtsdatum = ?,
                     aktiv = 1, zuletzt_importiert = ?
                     WHERE id = ?'
                )->execute([
                    $klasse_id, $vorname, $nachname,
                    $geschlecht, $geburtsdatum, $now,
                    $existing['id']
                ]);
                $schueler_id = $existing['id'];

                if ($existing['vorname'] !== $vorname ||
                    $existing['nachname'] !== $nachname ||
                    $existing['klasse_id'] != $klasse_id) {
                    $zaehler['aktualisiert']++;
                } else {
                    $zaehler['unveraendert']++;
                }
            }

            // Schuljahr-Zuordnung anlegen/aktualisieren
            $db->prepare(
                'INSERT INTO schueler_schuljahr (schueler_id, klasse_id, schuljahr_id)
                 VALUES (?, ?, ?)
                 ON DUPLICATE KEY UPDATE klasse_id = VALUES(klasse_id)'
            )->execute([$schueler_id, $klasse_id, $schuljahr_id]);

            $importierte_schild_ids[] = $schild_id;
        }

        // Schüler die im Schuljahr waren aber NICHT in der neuen Datei → inaktivieren
        if (!empty($importierte_schild_ids)) {
            $platzhalter = implode(',', array_fill(0, count($importierte_schild_ids), '?'));
            $inakt_stmt = $db->prepare(
                "UPDATE schueler s
                 INNER JOIN schueler_schuljahr ss ON ss.schueler_id = s.id
                 SET s.aktiv = 0
                 WHERE ss.schuljahr_id = ?
                   AND s.schild_id NOT IN ($platzhalter)"
            );
            $inakt_stmt->execute(array_merge(
                [$schuljahr_id],
                $importierte_schild_ids
            ));
            $zaehler['inaktiviert'] = $inakt_stmt->rowCount();
        }

        // Import-Log schreiben
        $db->prepare(
            'INSERT INTO import_log
             (schule_id, schuljahr_id, benutzer_id, dateiname, neu, aktualisiert,
              unveraendert, inaktiviert, fehler)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)'
        )->execute([
            $schule_id, $schuljahr_id, $benutzer_id, $dateiname,
            $zaehler['neu'], $zaehler['aktualisiert'],
            $zaehler['unveraendert'], $zaehler['inaktiviert'], $zaehler['fehler']
        ]);

        $db->commit();
        return ['ok' => true, 'statistik' => $zaehler];

    } catch (Throwable $e) {
        $db->rollBack();
        throw $e;
    }
}

// ============================================================
//  WERKSTATT-DETAIL
//  GET  /api/werkstatt/{id}/schueler   – Schüler aus mehreren Klassen laden
//  PUT  /api/werkstatt/{id}/abschluss  – Abschluss je Schüler markieren
//  GET  /api/schueler?klassen=1,2,3    – wird in handle_schueler ergänzt
// ============================================================
function handle_werkstatt(string $method, ?int $id, string $sub, array $body): void {
    $user     = require_auth();
    $db       = get_db();
    $istAdmin = $user['rolle'] === 'admin';

    if (!$id) json_error('Werkstatt-ID fehlt.', 400);

    // Zugangskontrolle
    if (!$istAdmin) {
        $chk = $db->prepare(
            'SELECT 1 FROM projekt_lehrer WHERE projekt_id = ? AND benutzer_id = ?'
        );
        $chk->execute([$id, $user['id']]);
        if (!$chk->fetch()) json_error('Keine Berechtigung.', 403);
    }

    // ----- PUT /api/werkstatt/{id}/status -----
    if ($method === 'PUT' && $sub === 'status') {
        $status = in_array($body['status'] ?? '', ['geplant','aktiv','abgeschlossen','abgesagt'])
                  ? $body['status'] : null;
        if (!$status) json_error('Ungültiger Status.', 400);
        $db->prepare('UPDATE projekte SET status = ? WHERE id = ? AND schule_id = ?')
           ->execute([$status, $id, $user['schule_id']]);
        audit($user['id'], 'projekte', $id, 'UPDATE', null, ['status' => $status]);
        json_response(['ok' => true]);
    }

    // ----- GET /api/werkstatt/{id}/schueler -----
    // Alle Schüler der zugeordneten Klassen laden (für Teilnehmer-Auswahl)
    if ($method === 'GET' && $sub === 'schueler') {
        $stmt = $db->prepare(
            'SELECT DISTINCT s.id, s.vorname, s.nachname,
                    k.bezeichnung AS klasse, k.jahrgang,
                    ps.abgeschlossen
             FROM projekt_klassen pk
             JOIN klassen k ON k.id = pk.klasse_id
             JOIN schueler s ON s.klasse_id = k.id AND s.aktiv = 1
             LEFT JOIN projekt_schueler ps ON ps.projekt_id = ? AND ps.schueler_id = s.id
             WHERE pk.projekt_id = ?
             ORDER BY k.jahrgang, k.bezeichnung, s.nachname, s.vorname'
        );
        $stmt->execute([$id, $id]);
        json_response($stmt->fetchAll());
    }

    // ----- PUT /api/werkstatt/{id}/abschluss -----
    // Body: { schueler_id: 7, abgeschlossen: true }
    //   oder { alle: true, abgeschlossen: true }
    if ($method === 'PUT' && $sub === 'abschluss') {
        $abgeschlossen = (bool)($body['abgeschlossen'] ?? false);
        $now = $abgeschlossen ? date('Y-m-d H:i:s') : null;

        // Alle Teilnehmer auf einmal?
        if (!empty($body['alle'])) {
            $stmt = $db->prepare(
                'UPDATE projekt_schueler
                 SET abgeschlossen = ?, abgeschlossen_am = ?
                 WHERE projekt_id = ?'
            );
            $stmt->execute([(int)$abgeschlossen, $now, $id]);
            audit($user['id'], 'projekt_schueler', $id, 'UPDATE', null,
                  ['alle_abgeschlossen' => $abgeschlossen]);
            json_response(['ok' => true, 'aktualisiert' => $stmt->rowCount()]);
        }

        // Einzelner Schüler
        $schueler_id = (int)($body['schueler_id'] ?? 0);
        if (!$schueler_id) json_error('schueler_id fehlt.', 400);

        $stmt = $db->prepare(
            'UPDATE projekt_schueler
             SET abgeschlossen = ?, abgeschlossen_am = ?
             WHERE projekt_id = ? AND schueler_id = ?'
        );
        $stmt->execute([(int)$abgeschlossen, $now, $id, $schueler_id]);
        audit($user['id'], 'projekt_schueler', $schueler_id, 'UPDATE', null,
              ['abgeschlossen' => $abgeschlossen]);
        json_response(['ok' => true]);
    }

    json_error('Unbekannte Werkstatt-Aktion.', 404);
}

// ============================================================
//  BEWERTUNGEN (Fremd-/Selbsteinschätzung pro Schüler+Kompetenz)
//  GET  /api/bewertung?projekt_id=1       – alle Bewertungen der Werkstatt
//  PUT  /api/bewertung/{projekt_id}       – Bewertung setzen/aktualisieren
// ============================================================
function handle_bewertung(string $method, ?int $id, array $body): void {
    $user     = require_auth();
    $db       = get_db();
    $istAdmin = $user['rolle'] === 'admin';

    // GET /api/bewertung?projekt_id=1
    if ($method === 'GET') {
        $projekt_id = (int)($_GET['projekt_id'] ?? 0);
        if (!$projekt_id) json_error('projekt_id fehlt.', 400);

        // Zugangskontrolle
        if (!$istAdmin) {
            $chk = $db->prepare('SELECT 1 FROM projekt_lehrer WHERE projekt_id=? AND benutzer_id=?');
            $chk->execute([$projekt_id, $user['id']]);
            if (!$chk->fetch()) json_error('Keine Berechtigung.', 403);
        }

        $stmt = $db->prepare(
            'SELECT psk.schueler_id, psk.kompetenz_id,
                    psk.fremd_stufe, psk.selbst_stufe, psk.selbst_sichtbar,
                    psk.notiz, psk.bewertet_am,
                    k.kurzname AS kompetenz_name, k.code,
                    kb.name AS bereich_name,
                    s.vorname, s.nachname
             FROM projekt_schueler_kompetenzen psk
             JOIN kompetenzen k ON k.id = psk.kompetenz_id
             JOIN kompetenzbereiche kb ON kb.id = k.bereich_id
             JOIN schueler s ON s.id = psk.schueler_id
             WHERE psk.projekt_id = ?
             ORDER BY s.nachname, s.vorname, kb.reihenfolge, k.code'
        );
        $stmt->execute([$projekt_id]);
        json_response($stmt->fetchAll());
    }

    // PUT /api/bewertung/{projekt_id} – Fremdeinschätzung setzen
    if ($method === 'PUT' && $id) {
        $schueler_id  = (int)($body['schueler_id']  ?? 0);
        $kompetenz_id = (int)($body['kompetenz_id'] ?? 0);
        $fremd_stufe  = isset($body['fremd_stufe']) && $body['fremd_stufe'] !== ''
                        ? (int)$body['fremd_stufe'] : null;

        if (!$schueler_id || !$kompetenz_id) json_error('schueler_id und kompetenz_id erforderlich.');
        if ($fremd_stufe !== null && ($fremd_stufe < 1 || $fremd_stufe > 4)) {
            json_error('Bewertungsstufe muss zwischen 1 und 4 liegen.');
        }

        $db->prepare(
            'UPDATE projekt_schueler_kompetenzen
             SET fremd_stufe = ?, fremd_benutzer_id = ?, bewertet_am = NOW()
             WHERE projekt_id = ? AND schueler_id = ? AND kompetenz_id = ?'
        )->execute([$fremd_stufe, $user['id'], $id, $schueler_id, $kompetenz_id]);

        json_response(['ok' => true]);
    }

    json_error('Methode nicht erlaubt.', 405);
}

// ============================================================
//  RÜCKMELDUNGEN (pro Schüler, persistent)
//  GET  /api/rueckmeldung?projekt_id=1    – alle Rückmeldungen der Werkstatt
//  POST /api/rueckmeldung/{projekt_id}    – Rückmeldung anlegen/aktualisieren
//  PUT  /api/rueckmeldung/{projekt_id}    – Sichtbarkeit umschalten
// ============================================================
function handle_rueckmeldung(string $method, ?int $id, array $body): void {
    $user     = require_auth();
    $db       = get_db();
    $istAdmin = $user['rolle'] === 'admin';

    $projekt_id = $id ?? (int)($_GET['projekt_id'] ?? 0);
    if (!$projekt_id) json_error('projekt_id fehlt.', 400);

    // Zugangskontrolle
    if (!$istAdmin) {
        $chk = $db->prepare('SELECT 1 FROM projekt_lehrer WHERE projekt_id=? AND benutzer_id=?');
        $chk->execute([$projekt_id, $user['id']]);
        if (!$chk->fetch()) json_error('Keine Berechtigung.', 403);
    }

    // GET – alle Rückmeldungen laden
    if ($method === 'GET') {
        $stmt = $db->prepare(
            'SELECT r.id, r.schueler_id, r.bewertung_stufe, r.freitext,
                    r.sichtbar, r.erstellt_am, r.geaendert_am,
                    s.vorname, s.nachname,
                    b.vorname AS lb_vorname, b.nachname AS lb_nachname
             FROM werkstatt_rueckmeldungen r
             JOIN schueler s ON s.id = r.schueler_id
             JOIN benutzer b ON b.id = r.erstellt_von
             WHERE r.projekt_id = ?
             ORDER BY s.nachname, s.vorname'
        );
        $stmt->execute([$projekt_id]);
        json_response($stmt->fetchAll());
    }

    // POST – Rückmeldung anlegen oder aktualisieren (UPSERT)
    if ($method === 'POST') {
        $schueler_ids   = array_map('intval', $body['schueler_ids'] ?? []);
        $bewertung_stufe = isset($body['bewertung_stufe']) && $body['bewertung_stufe'] !== ''
                          ? (int)$body['bewertung_stufe'] : null;
        $freitext       = $body['freitext'] ?? '';
        $sichtbar       = (int)($body['sichtbar'] ?? 0);

        if (empty($schueler_ids)) json_error('Mindestens einen Schüler angeben.');

        $stmt = $db->prepare(
            'INSERT INTO werkstatt_rueckmeldungen
             (projekt_id, schueler_id, erstellt_von, bewertung_stufe, freitext, sichtbar)
             VALUES (?, ?, ?, ?, ?, ?)
             ON DUPLICATE KEY UPDATE
             bewertung_stufe = VALUES(bewertung_stufe),
             freitext        = VALUES(freitext),
             sichtbar        = VALUES(sichtbar),
             erstellt_von    = VALUES(erstellt_von),
             geaendert_am    = NOW()'
        );

        foreach ($schueler_ids as $sid) {
            $stmt->execute([
                $projekt_id, $sid, $user['id'],
                $bewertung_stufe, $freitext ?: null, $sichtbar
            ]);
        }

        json_response(['ok' => true, 'anzahl' => count($schueler_ids)]);
    }

    // PUT – Sichtbarkeit für einzelnen Schüler umschalten
    if ($method === 'PUT') {
        $schueler_id = (int)($body['schueler_id'] ?? 0);
        $sichtbar    = (int)(bool)($body['sichtbar'] ?? 0);
        if (!$schueler_id) json_error('schueler_id fehlt.');

        $db->prepare(
            'UPDATE werkstatt_rueckmeldungen SET sichtbar=?
             WHERE projekt_id=? AND schueler_id=?'
        )->execute([$sichtbar, $projekt_id, $schueler_id]);

        json_response(['ok' => true]);
    }

    json_error('Methode nicht erlaubt.', 405);
}

// ============================================================
//  SCHÜLER-PORTAL
//  GET /api/schueler-portal          – alle Werkstätten des Schülers
//  GET /api/schueler-portal/{id}     – Detail einer Werkstatt
// ============================================================
function handle_schueler_portal(string $method, ?int $id, array $body): void {
    $user = require_auth();
    $db   = get_db();

    // Nur Schüler dürfen diesen Endpunkt nutzen
    if ($user['typ'] !== 'schueler') {
        json_error('Nur für Schüler-Logins.', 403);
    }

    $schueler_id = $user['id'];

    // GET /api/schueler-portal – Übersicht aller Werkstätten
    if ($method === 'GET' && !$id) {
        $stmt = $db->prepare(
            'SELECT p.id, p.name, p.datum_von, p.datum_bis, p.status,
                    sj.name AS schuljahr_name,
                    ps.abgeschlossen,
                    COUNT(DISTINCT psk.kompetenz_id) AS kompetenzen_anzahl,
                    GROUP_CONCAT(DISTINCT CONCAT(b.vorname, " ", b.nachname)
                                 ORDER BY pl.rolle ASC SEPARATOR ", ") AS lernbegleiter
             FROM projekt_schueler ps
             JOIN projekte p ON p.id = ps.projekt_id
             LEFT JOIN schuljahre sj ON sj.id = p.schuljahr_id
             LEFT JOIN projekt_lehrer pl ON pl.projekt_id = p.id
             LEFT JOIN benutzer b ON b.id = pl.benutzer_id
             LEFT JOIN projekt_schueler_kompetenzen psk
                    ON psk.projekt_id = p.id AND psk.schueler_id = ps.schueler_id
             WHERE ps.schueler_id = ?
             GROUP BY p.id
             ORDER BY p.datum_von DESC'
        );
        $stmt->execute([$schueler_id]);
        $werkstaetten = $stmt->fetchAll();
        json_response(['werkstaetten' => $werkstaetten]);
    }

    // GET /api/schueler-portal/{id} – Detail einer Werkstatt
    if ($method === 'GET' && $id) {
        // Zugangsprüfung: Schüler muss Teilnehmer sein
        $chk = $db->prepare(
            'SELECT 1 FROM projekt_schueler WHERE projekt_id = ? AND schueler_id = ?'
        );
        $chk->execute([$id, $schueler_id]);
        if (!$chk->fetch()) json_error('Keine Berechtigung.', 403);

        // Werkstatt-Grunddaten
        $stmt = $db->prepare(
            'SELECT p.id, p.name, p.datum_von, p.datum_bis, p.status,
                    sj.name AS schuljahr_name
             FROM projekte p
             LEFT JOIN schuljahre sj ON sj.id = p.schuljahr_id
             WHERE p.id = ?'
        );
        $stmt->execute([$id]);
        $proj = $stmt->fetch();
        if (!$proj) json_error('Werkstatt nicht gefunden.', 404);

        // Kompetenzen mit Fremd- und Selbsteinschätzung
        $stmt = $db->prepare(
            'SELECT psk.kompetenz_id, psk.fremd_stufe, psk.selbst_stufe,
                    k.code, k.kurzname AS kompetenz_name,
                    kb.name AS bereich_name, kr.kuerzel AS rahmen
             FROM projekt_schueler_kompetenzen psk
             JOIN kompetenzen k ON k.id = psk.kompetenz_id
             JOIN kompetenzbereiche kb ON kb.id = k.bereich_id
             JOIN kompetenzrahmen kr ON kr.id = kb.rahmen_id
             WHERE psk.projekt_id = ? AND psk.schueler_id = ?
             ORDER BY kb.reihenfolge, k.code'
        );
        $stmt->execute([$id, $schueler_id]);
        $proj['kompetenzen'] = $stmt->fetchAll();

        // Nur sichtbare Rückmeldungen
        $stmt = $db->prepare(
            'SELECT r.bewertung_stufe, r.freitext, r.erstellt_am, r.geaendert_am,
                    b.vorname AS lb_vorname, b.nachname AS lb_nachname
             FROM werkstatt_rueckmeldungen r
             JOIN benutzer b ON b.id = r.erstellt_von
             WHERE r.projekt_id = ? AND r.schueler_id = ? AND r.sichtbar = 1'
        );
        $stmt->execute([$id, $schueler_id]);
        $proj['rueckmeldungen'] = $stmt->fetchAll();

        json_response($proj);
    }

    json_error('Methode nicht erlaubt.', 405);
}

// ============================================================
//  SELBSTEINSCHÄTZUNG (Schüler bewertet sich selbst)
//  PUT /api/selbsteinschaetzung/{projekt_id}
// ============================================================
function handle_selbsteinschaetzung(string $method, ?int $id, array $body): void {
    $user = require_auth();
    $db   = get_db();

    if ($user['typ'] !== 'schueler') json_error('Nur für Schüler.', 403);
    if (!$id) json_error('projekt_id fehlt.', 400);

    $schueler_id  = $user['id'];
    $kompetenz_id = (int)($body['kompetenz_id'] ?? 0);
    $selbst_stufe = isset($body['selbst_stufe']) && $body['selbst_stufe'] !== ''
                    ? (int)$body['selbst_stufe'] : null;

    if (!$kompetenz_id) json_error('kompetenz_id fehlt.', 400);
    if ($selbst_stufe !== null && ($selbst_stufe < 1 || $selbst_stufe > 4)) {
        json_error('Stufe muss zwischen 1 und 4 liegen.', 400);
    }

    // Zugangsprüfung
    $chk = $db->prepare(
        'SELECT 1 FROM projekt_schueler WHERE projekt_id = ? AND schueler_id = ?'
    );
    $chk->execute([$id, $schueler_id]);
    if (!$chk->fetch()) json_error('Keine Berechtigung.', 403);

    $db->prepare(
        'UPDATE projekt_schueler_kompetenzen
         SET selbst_stufe = ?
         WHERE projekt_id = ? AND schueler_id = ? AND kompetenz_id = ?'
    )->execute([$selbst_stufe, $id, $schueler_id, $kompetenz_id]);

    json_response(['ok' => true]);
}

// ============================================================
//  EINSTELLUNGEN (Schulanpassung)
//  GET  /api/einstellungen          – alle lesen (admin)
//  POST /api/einstellungen          – speichern (admin)
//  POST /api/einstellungen/logo     – Logo hochladen (admin)
//  GET  /api/einstellungen/logo     – Logo ausliefern (öffentlich)
//  POST /api/einstellungen/logo/loeschen – Logo löschen (admin)
//  POST /api/einstellungen/zuruecksetzen – Auf Standard (admin)
// ============================================================
function handle_einstellungen(string $method, string $sub, array $body): void {
    $db = get_db();

    // Logo ausliefern – öffentlich, kein Login nötig
    if ($method === 'GET' && $sub === 'logo') {
        $pfad = $db->query("SELECT wert FROM einstellungen WHERE schluessel='logo_pfad'")->fetchColumn();
        if (!$pfad || !is_file($pfad)) { http_response_code(404); exit; }
        $mime = $db->query("SELECT wert FROM einstellungen WHERE schluessel='logo_mime'")->fetchColumn() ?: 'image/png';
        header('Content-Type: ' . $mime);
        header('Cache-Control: public, max-age=3600');
        header('Content-Length: ' . filesize($pfad));
        readfile($pfad);
        exit;
    }

    // Ab hier: nur Admin
    $user = require_admin();
    $kuerzel = $_SESSION['wu_kuerzel'] ?? ($_SESSION['benutzer_id'] ? 'lokal' : 'unbekannt');

    // GET – alle Einstellungen lesen
    if ($method === 'GET' && $sub === '') {
        $rows = $db->query(
            "SELECT schluessel, wert FROM einstellungen WHERE schluessel != 'logo_pfad'"
        )->fetchAll(PDO::FETCH_KEY_PAIR);

        $defaults = [
            'schulname'      => 'Friedrich-Rückert-Gymnasium Düsseldorf',
            'app_titel'      => 'Projektstunden NRW',
            'app_untertitel' => 'Gymnasium G9 – Kompetenz- und Stunden-Tracking',
            'farbe_akzent'   => '#3d6b4f',
            'farbe_sekundaer'=> '#2c4f3a',
            'logo_mime'      => '',
        ];
        $result = array_merge($defaults, $rows);

        $hatLogo = (bool)$db->query(
            "SELECT wert FROM einstellungen WHERE schluessel='logo_pfad'"
        )->fetchColumn();
        $result['hat_logo'] = $hatLogo;

        json_response($result);
    }

    // POST – Einstellungen speichern
    if ($method === 'POST' && $sub === '') {
        $felder = [
            'schulname'      => ['typ' => 'text', 'max' => 80],
            'app_titel'      => ['typ' => 'text', 'max' => 60],
            'app_untertitel' => ['typ' => 'text', 'max' => 100],
            'farbe_akzent'   => ['typ' => 'farbe'],
            'farbe_sekundaer'=> ['typ' => 'farbe'],
        ];

        $stmt = $db->prepare(
            'INSERT INTO einstellungen (schluessel, wert, geaendert_von)
             VALUES (?, ?, ?)
             ON DUPLICATE KEY UPDATE wert=VALUES(wert), geaendert_von=VALUES(geaendert_von)'
        );

        $gespeichert = [];
        foreach ($felder as $key => $regel) {
            if (!array_key_exists($key, $body)) continue;
            $wert = (string)$body[$key];

            if ($regel['typ'] === 'farbe') {
                if (!preg_match('/^#[0-9A-Fa-f]{6}$/', $wert)) {
                    json_error("Ungültiger Farbwert für '{$key}'. Erwartet: #RRGGBB", 400);
                }
            } else {
                $wert = mb_substr(strip_tags(trim($wert)), 0, $regel['max']);
                if ($wert === '') json_error("'{$key}' darf nicht leer sein.", 400);
            }

            $stmt->execute([$key, $wert, $kuerzel]);
            $gespeichert[] = $key;
        }

        json_response(['ok' => true, 'gespeichert' => $gespeichert]);
    }

    // POST /logo – Logo hochladen (Base64)
    if ($method === 'POST' && $sub === 'logo') {
        $base64 = $body['daten'] ?? null;
        if (!$base64) json_error('Keine Bilddaten übermittelt.', 400);

        $binaer = base64_decode($base64, strict: true);
        if ($binaer === false) json_error('Ungültige Base64-Daten.', 400);
        if (strlen($binaer) > 500 * 1024) json_error('Logo darf max. 500 KB groß sein.', 400);

        // MIME via finfo prüfen
        $tmp = tempnam(sys_get_temp_dir(), 'logo_');
        file_put_contents($tmp, $binaer);
        $mime = (new finfo(FILEINFO_MIME_TYPE))->file($tmp);

        $erlaubt = ['image/png' => 'png', 'image/jpeg' => 'jpg', 'image/svg+xml' => 'svg'];
        if (!isset($erlaubt[$mime])) {
            unlink($tmp);
            json_error('Nur PNG, JPG und SVG erlaubt. Erkannt: ' . htmlspecialchars($mime), 400);
        }

        // SVG auf gefährliche Inhalte prüfen
        if ($mime === 'image/svg+xml') {
            $muster = ['/<script/i', '/javascript:/i', '/on\w+\s*=/i', '/<iframe/i', '/<object/i'];
            foreach ($muster as $m) {
                if (preg_match($m, $binaer)) {
                    unlink($tmp);
                    json_error('SVG enthält potenziell gefährliche Inhalte.', 400);
                }
            }
        }

        // Zielverzeichnis außerhalb Webroot
        $logoDir = dirname(__DIR__, 2) . '/data/logos/';
        if (!is_dir($logoDir)) mkdir($logoDir, 0750, true);

        // Altes Logo löschen
        $alt = $db->query("SELECT wert FROM einstellungen WHERE schluessel='logo_pfad'")->fetchColumn();
        if ($alt && is_file($alt)) unlink($alt);

        // Speichern
        $ziel = $logoDir . bin2hex(random_bytes(16)) . '.' . $erlaubt[$mime];
        rename($tmp, $ziel);
        chmod($ziel, 0640);

        $stmt = $db->prepare(
            'INSERT INTO einstellungen (schluessel, wert, geaendert_von)
             VALUES (?, ?, ?)
             ON DUPLICATE KEY UPDATE wert=VALUES(wert), geaendert_von=VALUES(geaendert_von)'
        );
        $stmt->execute(['logo_pfad', $ziel, $kuerzel]);
        $stmt->execute(['logo_mime', $mime, $kuerzel]);

        json_response(['ok' => true, 'mime' => $mime]);
    }

    // POST /logo/loeschen
    if ($method === 'POST' && $sub === 'logo/loeschen') {
        $pfad = $db->query("SELECT wert FROM einstellungen WHERE schluessel='logo_pfad'")->fetchColumn();
        if ($pfad && is_file($pfad)) unlink($pfad);

        $stmt = $db->prepare(
            'INSERT INTO einstellungen (schluessel, wert, geaendert_von)
             VALUES (?, ?, ?)
             ON DUPLICATE KEY UPDATE wert=VALUES(wert), geaendert_von=VALUES(geaendert_von)'
        );
        $stmt->execute(['logo_pfad', '', $kuerzel]);
        $stmt->execute(['logo_mime', '', $kuerzel]);

        json_response(['ok' => true]);
    }

    // POST /zuruecksetzen
    if ($method === 'POST' && $sub === 'zuruecksetzen') {
        $pfad = $db->query("SELECT wert FROM einstellungen WHERE schluessel='logo_pfad'")->fetchColumn();
        if ($pfad && is_file($pfad)) unlink($pfad);

        $defaults = [
            'schulname'      => 'Friedrich-Rückert-Gymnasium Düsseldorf',
            'app_titel'      => 'Projektstunden NRW',
            'app_untertitel' => 'Gymnasium G9 – Kompetenz- und Stunden-Tracking',
            'farbe_akzent'   => '#3d6b4f',
            'farbe_sekundaer'=> '#2c4f3a',
            'logo_pfad'      => '',
            'logo_mime'      => '',
        ];
        $stmt = $db->prepare(
            'INSERT INTO einstellungen (schluessel, wert, geaendert_von)
             VALUES (?, ?, ?)
             ON DUPLICATE KEY UPDATE wert=VALUES(wert), geaendert_von=VALUES(geaendert_von)'
        );
        foreach ($defaults as $k => $v) $stmt->execute([$k, $v, $kuerzel]);

        json_response(['ok' => true]);
    }

    json_error('Unbekannte Einstellungs-Aktion.', 404);
}
