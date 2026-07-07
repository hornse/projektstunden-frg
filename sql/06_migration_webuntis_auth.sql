-- =============================================================================
-- Migration 06: WebUntis-Auth – Login-Log, Schüler-Zugriff, Selbsteinschätzung
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Login-Log für WebUntis-Versuche (Brute-Force-Schutz)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS webuntis_login_log (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    benutzername VARCHAR(100) NOT NULL COMMENT 'WebUntis-Kürzel oder Schüler-Username',
    erfolgreich  TINYINT(1)   NOT NULL DEFAULT 0,
    grund        VARCHAR(50)  NULL     COMMENT 'z. B. falsches_passwort, nicht_freigegeben',
    ip           VARCHAR(45)  NULL,
    zeitpunkt    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_benutzername_zeitpunkt (benutzername, zeitpunkt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Protokoll aller WebUntis-Login-Versuche (Brute-Force-Schutz)';

-- -----------------------------------------------------------------------------
-- 2. WebUntis-Verknüpfung für Benutzer (Lehrer)
--    Ein Benutzer kann optional sein WebUntis-Kürzel hinterlegen.
--    Dann kann er sich zusätzlich per WebUntis einloggen.
-- -----------------------------------------------------------------------------
ALTER TABLE benutzer
    ADD COLUMN IF NOT EXISTS webuntis_user VARCHAR(100) NULL
        COMMENT 'WebUntis-Kürzel für optionalen WebUntis-Login' AFTER kuerzel,
    ADD UNIQUE KEY uq_webuntis_user (webuntis_user);

-- -----------------------------------------------------------------------------
-- 3. Schüler-Zugriff
--    Schüler bekommen einen eigenen Login (WebUntis oder Schüler-PIN).
--    schueler.webuntis_user: der WebUntis-Benutzername des Schülers
-- -----------------------------------------------------------------------------
ALTER TABLE schueler
    ADD COLUMN IF NOT EXISTS webuntis_user VARCHAR(100) NULL
        COMMENT 'WebUntis-Benutzername des Schülers für Login' AFTER zuletzt_importiert,
    ADD UNIQUE KEY IF NOT EXISTS uq_schueler_webuntis (webuntis_user);

-- -----------------------------------------------------------------------------
-- 4. Selbsteinschätzung: bereits in Migration 03 vorbereitet
--    (selbst_stufe, selbst_sichtbar in projekt_schueler_kompetenzen)
--    Keine weiteren Tabellenänderungen nötig.
-- -----------------------------------------------------------------------------
