-- =============================================================================
-- Migration 04: Werkstatt-Detail – Abschluss je Schüler, Multi-Klassen
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. projekt_schueler: Abschluss-Flag je Teilnehmer
-- -----------------------------------------------------------------------------
ALTER TABLE projekt_schueler
    ADD COLUMN IF NOT EXISTS abgeschlossen TINYINT(1) NOT NULL DEFAULT 0
        COMMENT '1 = Werkstatt erfolgreich absolviert',
    ADD COLUMN IF NOT EXISTS abgeschlossen_am DATETIME NULL
        COMMENT 'Zeitstempel der Abschluss-Markierung';

-- -----------------------------------------------------------------------------
-- 2. projekt_klassen: Mehrere Klassen pro Werkstatt
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS projekt_klassen (
    projekt_id INT UNSIGNED NOT NULL,
    klasse_id  INT UNSIGNED NOT NULL,
    PRIMARY KEY (projekt_id, klasse_id),
    FOREIGN KEY (projekt_id) REFERENCES projekte(id) ON DELETE CASCADE,
    FOREIGN KEY (klasse_id)  REFERENCES klassen(id)  ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Mehrere Klassen pro Werkstatt (jahrgangsübergreifend)';

-- Bestehende Projekte: klasse_id in projekt_klassen übernehmen
INSERT IGNORE INTO projekt_klassen (projekt_id, klasse_id)
SELECT id, klasse_id FROM projekte WHERE klasse_id IS NOT NULL;
