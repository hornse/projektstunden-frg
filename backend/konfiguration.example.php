<?php
/**
 * Projektstunden NRW – Konfiguration: NUR WERTE
 * ============================================================
 * Datei: backend/konfiguration.php
 *
 * Diese Datei NICHT in git versionieren (steht in .gitignore).
 * Für Neuinstallation: konfiguration.example.php → konfiguration.php
 * kopieren und die Werte anpassen. Aus einer alten backend/config.php
 * leitet bin/konfiguration-ableiten.sh sie ab (E68).
 *
 * Hier steht KEINE Funktion. Der Code steht versioniert in backend/kern.php,
 * der diese Datei lädt (tests/kern_test.php K2, K3). Bis Auftrag A hieß die
 * Datei config.php und trug auch den Code.
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
// personType-Werte: 2=Lehrkraft, 16=WebUntis-Admin, 5=Schüler
define('WEBUNTIS_ENABLED', true);

$WEBUNTIS_CONFIG = [
    'base_url'             => 'https://frg-dusseldorf.webuntis.com', // ohne / am Ende
    'school'               => 'frg-dusseldorf',
    'client'               => 'ProjektstundenNRW',
    // personType 2  = Lehrkraft      → Rolle 'lernbegleiter'
    // personType 16 = WebUntis-Admin → Rolle 'admin'
    // personType 5  = Schüler        → Schüler-Portal
    'allowed_person_types' => [2, 16, 5],
    'connect_timeout'      => 5,
    'timeout'              => 10,
    // Anmeldebremse (backend/auth/Anmeldebremse.php): ab acht Fehlversuchen
    // 60 Sekunden Wartezeit, nie eine Sperre. Die Schwelle steht im Code
    // (Anmeldebremse::SCHWELLE, M56 der Reihe), nicht hier. lockout_minutes
    // heisst aus Gewohnheit so und ist das ZAEHLFENSTER – gezaehlt werden
    // Fehlversuche der letzten 15 Minuten, seit der letzten gelungenen Anmeldung.
    'lockout_minutes'      => 15,

    // Zusätzlich: Lehrer-Kürzel (personType 2) die auch Admin werden sollen.
    // WebUntis-Admins (personType 16) werden automatisch Admin ohne diese Liste.
    'admin_kuerzel'        => ['Vzq'],
];
