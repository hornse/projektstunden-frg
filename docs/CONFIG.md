# config.php einrichten – Schritt-für-Schritt

Die Datei `backend/config.php` liegt **nicht in git** (steht in `.gitignore`).
Sie muss nach jedem frischen Deployment manuell angelegt werden.

---

## Schritt 1 – Datenbankpasswort herausfinden

Das MariaDB-Passwort steht auf dem Uberspace-Server in `~/.my.cnf`:

```bash
cat ~/.my.cnf
# [client]
# user = hornse
# password = DAS_IST_DEIN_PASSWORT
```

---

## Schritt 2 – config.php anlegen

```bash
cp /home/hornse/projektstunden/backend/config.example.php \
   /home/hornse/projektstunden/backend/config.php
```

---

## Schritt 3 – Datenbankpasswort eintragen

```bash
nano /home/hornse/projektstunden/backend/config.php
```

Zeile suchen und anpassen:
```php
define('DB_PASS', 'DEIN_DATENBANKPASSWORT');
//                 ↑ durch echtes Passwort aus ~/.my.cnf ersetzen
```

---

## Schritt 4 – WebUntis konfigurieren

Im selben Editor die WebUntis-Werte anpassen:

```php
define('WEBUNTIS_ENABLED', true);

$WEBUNTIS_CONFIG = [
    'base_url' => 'https://neilo.webuntis.com',  // ← Uberspace-Adresse deiner Schule
    'school'   => 'frg-duesseldorf',              // ← Schulkürzel aus der WebUntis-URL
    // z. B. https://neilo.webuntis.com/WebUntis/?school=frg-duesseldorf
    'client'               => 'ProjektstundenNRW',
    'allowed_person_types' => [2],    // 2 = Lehrkraft; [2, 5] wenn auch Schüler
    'connect_timeout'      => 5,
    'timeout'              => 10,
    'max_failed_logins'    => 5,
    'lockout_minutes'      => 15,
];
```

WebUntis-URL deiner Schule findest du indem du dich im Browser bei WebUntis
anmeldest und die URL anschaust:
```
https://SERVERNAME.webuntis.com/WebUntis/?school=SCHULKUERZEL
         ↑ base_url bis hier                    ↑ school
```

---

## Schritt 5 – session.save_path sicherstellen

```bash
mkdir -p ~/tmp/sessions
```

---

## Schritt 6 – Lehrer mit WebUntis-Kürzel verknüpfen

Damit ein Lehrer sich per WebUntis-Kürzel einloggen kann, muss das Kürzel
in der Datenbank hinterlegt sein:

```bash
# Kürzel für deinen Account eintragen
mysql hornse_projektstunden -e "
UPDATE benutzer SET webuntis_user = 'Hor'
WHERE email = 'sebastian.horn@frg-duesseldorf.de';"

# Prüfen
mysql hornse_projektstunden -e "
SELECT id, vorname, nachname, email, webuntis_user, rolle
FROM benutzer WHERE schule_id = 1;"
```

Das Kürzel entspricht dem WebUntis-Anmeldename (meist Nachname-Kürzel,
z. B. `Hor` für Horn).

---

## Schritt 7 – Schüler mit WebUntis-Username verknüpfen (optional)

Wenn Schüler sich per WebUntis einloggen sollen:

```bash
# Einzeln:
mysql hornse_projektstunden -e "
UPDATE schueler SET webuntis_user = 'schueler.vorname'
WHERE schild_id = 12345;"

# Bulk per Import: webuntis_user kann beim CSV-Import ergänzt werden
# (Spalte 'WebUntis-Benutzername' in der Schild-Exportdatei falls vorhanden)
```

---

## Vollständige config.php – Referenz

```php
<?php
/**
 * Projektstunden NRW – Konfiguration
 * NICHT in git versionieren!
 */

ini_set('session.save_path', '/home/hornse/tmp/sessions');
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Datenbank
define('DB_HOST',    '127.0.0.1');
define('DB_PORT',    3306);
define('DB_NAME',    'hornse_projektstunden');
define('DB_USER',    'hornse');
define('DB_PASS',    'PASSWORT_AUS_MY_CNF');  // ← anpassen!
define('DB_CHARSET', 'utf8mb4');

// Schule
define('SCHULE_ID', 1);

// Session
define('SESSION_NAME',     'proj_session');
define('SESSION_LIFETIME', 8 * 3600);

// CORS
define('ALLOWED_ORIGIN', 'https://projektstunden.hornse.de');

// WebUntis
define('WEBUNTIS_ENABLED', true);

$WEBUNTIS_CONFIG = [
    'base_url'             => 'https://neilo.webuntis.com',
    'school'               => 'frg-duesseldorf',
    'client'               => 'ProjektstundenNRW',
    'allowed_person_types' => [2],
    'connect_timeout'      => 5,
    'timeout'              => 10,
    'max_failed_logins'    => 5,
    'lockout_minutes'      => 15,
];
```

> Den Rest der Datei (Funktionen `get_db`, `session_start_secure`, etc.)
> aus `config.example.php` unverändert übernehmen.

---

## Troubleshooting

**WebUntis-Login schlägt fehl obwohl Passwort korrekt:**
```bash
# Login-Log prüfen
mysql hornse_projektstunden -e "
SELECT * FROM webuntis_login_log ORDER BY zeitpunkt DESC LIMIT 10;"
```

**Kein Konto gefunden nach erfolgreichem WebUntis-Login:**
Sicherstellen dass `webuntis_user` in der `benutzer`-Tabelle gesetzt ist
(Schritt 6).

**WebUntis nicht erreichbar:**
`WEBUNTIS_ENABLED` auf `false` setzen → nur noch E-Mail/Passwort-Login möglich.
