-- =============================================================================
-- Migration 07: Schulanpassung – Einstellungen
-- =============================================================================
-- Einmalig ausführen:
--   mysql hornse_projektstunden < sql/07_migration_einstellungen.sql
-- =============================================================================

CREATE TABLE IF NOT EXISTS einstellungen (
    schluessel   VARCHAR(50)  NOT NULL,
    wert         TEXT         NOT NULL DEFAULT '',
    geaendert_am DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                              ON UPDATE CURRENT_TIMESTAMP,
    geaendert_von VARCHAR(100) NULL     COMMENT 'Kürzel des Admins',
    PRIMARY KEY (schluessel)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Schulspezifische Einstellungen (Logo, Name, Farben)';

-- Standardwerte
INSERT INTO einstellungen (schluessel, wert) VALUES
    ('schulname',       'Friedrich-Rückert-Gymnasium Düsseldorf'),
    ('app_titel',       'Projektstunden NRW'),
    ('app_untertitel',  'Gymnasium G9 – Kompetenz- und Stunden-Tracking'),
    ('farbe_akzent',    '#3d6b4f'),
    ('farbe_sekundaer', '#2c4f3a'),
    ('logo_pfad',       ''),
    ('logo_mime',       '')
ON DUPLICATE KEY UPDATE schluessel = schluessel; -- Keine Überschreibung bei Re-Run
