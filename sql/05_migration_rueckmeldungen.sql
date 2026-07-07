-- =============================================================================
-- Migration 05: Werkstatt-Rückmeldungen
-- =============================================================================

CREATE TABLE IF NOT EXISTS werkstatt_rueckmeldungen (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    projekt_id      INT UNSIGNED NOT NULL,
    schueler_id     INT UNSIGNED NOT NULL,
    erstellt_von    INT UNSIGNED NOT NULL COMMENT 'Lernbegleiter-ID',
    bewertung_stufe TINYINT UNSIGNED NULL COMMENT '1-4, optional',
    freitext        TEXT NULL COMMENT 'Freie Rückmeldung',
    sichtbar        TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 = für Schüler sichtbar',
    erstellt_am     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    geaendert_am    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_rueckmeldung (projekt_id, schueler_id),
    FOREIGN KEY (projekt_id)   REFERENCES projekte(id)  ON DELETE CASCADE,
    FOREIGN KEY (schueler_id)  REFERENCES schueler(id)  ON DELETE CASCADE,
    FOREIGN KEY (erstellt_von) REFERENCES benutzer(id)  ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Rückmeldungen je Schüler pro Werkstatt';
