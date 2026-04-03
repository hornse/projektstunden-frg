-- =============================================================================
-- Migration 03: Schuljahre, Schüler-Import, Werkstätten, Bewertungsskala
-- =============================================================================
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -----------------------------------------------------------------------------
-- 1. SCHULJAHRE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS schuljahre (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    schule_id   INT UNSIGNED NOT NULL,
    name        VARCHAR(10)  NOT NULL COMMENT 'z. B. 2024/25',
    beginn      DATE         NOT NULL COMMENT 'Erster Schultag',
    ende        DATE         NOT NULL COMMENT 'Letzter Schultag',
    status      ENUM('zukuenftig','aktiv','abgeschlossen') NOT NULL DEFAULT 'zukuenftig',
    erstellt_am DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_schuljahr (schule_id, name),
    FOREIGN KEY (schule_id) REFERENCES schulen(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Schuljahre mit Status';

-- -----------------------------------------------------------------------------
-- 2. KLASSEN: neue Spalten
-- -----------------------------------------------------------------------------
ALTER TABLE klassen
    ADD COLUMN IF NOT EXISTS schuljahr_id       INT UNSIGNED NULL
        COMMENT 'FK auf schuljahre' AFTER schuljahr,
    ADD COLUMN IF NOT EXISTS klassenlehrer_name VARCHAR(200) NULL
        COMMENT 'Aus Schild-Import: Name des Klassenlehrers' AFTER schuljahr_id;

-- FK separat (ohne IF NOT EXISTS)
ALTER TABLE klassen
    ADD FOREIGN KEY (schuljahr_id) REFERENCES schuljahre(id) ON DELETE SET NULL;

-- -----------------------------------------------------------------------------
-- 3. SCHÜLER: neue Felder für Schild-Import
-- -----------------------------------------------------------------------------
ALTER TABLE schueler
    ADD COLUMN IF NOT EXISTS schild_id          INT UNSIGNED NULL
        COMMENT 'Interne ID-Nummer aus Schild-NRW' AFTER id,
    ADD COLUMN IF NOT EXISTS geschlecht         ENUM('m','w','d','x') NULL
        COMMENT 'm=männlich, w=weiblich, d=divers, x=unbekannt' AFTER nachname,
    ADD COLUMN IF NOT EXISTS geburtsdatum       DATE NULL
        COMMENT 'Geburtsdatum aus Schild-Import' AFTER geschlecht,
    ADD COLUMN IF NOT EXISTS zuletzt_importiert DATETIME NULL
        COMMENT 'Zeitstempel des letzten CSV-Imports' AFTER geburtsdatum;

-- Unique Key für schild_id separat
ALTER TABLE schueler
    ADD UNIQUE KEY uq_schild_id (schild_id);

-- -----------------------------------------------------------------------------
-- 4. SCHÜLER-SCHULJAHR-VERLAUF
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS schueler_schuljahr (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    schueler_id  INT UNSIGNED NOT NULL,
    klasse_id    INT UNSIGNED NOT NULL,
    schuljahr_id INT UNSIGNED NOT NULL,
    erstellt_am  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_schueler_schuljahr (schueler_id, schuljahr_id),
    FOREIGN KEY (schueler_id)  REFERENCES schueler(id)   ON DELETE CASCADE,
    FOREIGN KEY (klasse_id)    REFERENCES klassen(id)    ON DELETE RESTRICT,
    FOREIGN KEY (schuljahr_id) REFERENCES schuljahre(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Schuljahrgebundene Schüler-Klassen-Zuordnung';

-- -----------------------------------------------------------------------------
-- 5. IMPORT-LOG
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS import_log (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    schule_id       INT UNSIGNED NOT NULL,
    schuljahr_id    INT UNSIGNED NOT NULL,
    benutzer_id     INT UNSIGNED NOT NULL,
    dateiname       VARCHAR(300) NULL,
    neu             INT UNSIGNED NOT NULL DEFAULT 0,
    aktualisiert    INT UNSIGNED NOT NULL DEFAULT 0,
    unveraendert    INT UNSIGNED NOT NULL DEFAULT 0,
    inaktiviert     INT UNSIGNED NOT NULL DEFAULT 0,
    fehler          INT UNSIGNED NOT NULL DEFAULT 0,
    erstellt_am     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (schule_id)    REFERENCES schulen(id)    ON DELETE CASCADE,
    FOREIGN KEY (schuljahr_id) REFERENCES schuljahre(id) ON DELETE RESTRICT,
    FOREIGN KEY (benutzer_id)  REFERENCES benutzer(id)  ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Protokoll der CSV-Importe';

-- -----------------------------------------------------------------------------
-- 6. PROJEKTE: Erweiterungen
-- -----------------------------------------------------------------------------
ALTER TABLE projekte
    ADD COLUMN IF NOT EXISTS schuljahr_id       INT UNSIGNED NULL
        COMMENT 'Schuljahr dem das Projekt zugeordnet ist' AFTER schule_id,
    ADD COLUMN IF NOT EXISTS laufzeit           ENUM('halbjahr','jahr') NOT NULL DEFAULT 'jahr'
        COMMENT 'Mindestlaufzeit der Werkstatt' AFTER datum_bis,
    ADD COLUMN IF NOT EXISTS max_schueler       SMALLINT UNSIGNED NULL
        COMMENT 'Maximale Teilnehmerzahl (NULL = unbegrenzt)' AFTER laufzeit,
    ADD COLUMN IF NOT EXISTS praesentation_datum DATE NULL
        COMMENT 'Datum des Präsentationstags' AFTER max_schueler;

-- Status-Enum erweitern
ALTER TABLE projekte
    MODIFY COLUMN status
        ENUM('geplant','aktiv','abgeschlossen','abgesagt') NOT NULL DEFAULT 'geplant';

-- FK für schuljahr_id
ALTER TABLE projekte
    ADD FOREIGN KEY (schuljahr_id) REFERENCES schuljahre(id) ON DELETE SET NULL;

-- -----------------------------------------------------------------------------
-- 7. PROJEKT-LEHRER (mehrere Lernbegleiter pro Werkstatt)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS projekt_lehrer (
    projekt_id  INT UNSIGNED NOT NULL,
    benutzer_id INT UNSIGNED NOT NULL,
    rolle       ENUM('leitung','begleitung') NOT NULL DEFAULT 'begleitung',
    PRIMARY KEY (projekt_id, benutzer_id),
    FOREIGN KEY (projekt_id)  REFERENCES projekte(id)  ON DELETE CASCADE,
    FOREIGN KEY (benutzer_id) REFERENCES benutzer(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Mehrere Lernbegleiter pro Werkstatt';

-- -----------------------------------------------------------------------------
-- 8. BEWERTUNGSSTUFEN
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS bewertungsstufen (
    id           TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    stufe        TINYINT UNSIGNED NOT NULL,
    bezeichnung  VARCHAR(50)      NOT NULL,
    beschreibung VARCHAR(200)     NOT NULL,
    UNIQUE KEY uq_stufe (stufe)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='4-stufige Bewertungsskala';

INSERT IGNORE INTO bewertungsstufen (stufe, bezeichnung, beschreibung) VALUES
(1, 'Mit Unterstützung',       'mit intensiver Unterstützung'),
(2, 'Teilweise selbstständig', 'teilweise selbstständig'),
(3, 'Weitgehend sicher',       'weitgehend sicher'),
(4, 'Sicher und reflektiert',  'sicher, reflektiert und transferfähig');

-- -----------------------------------------------------------------------------
-- 9. KOMPETENZBEWERTUNG: Selbst- und Fremdeinschätzung
-- -----------------------------------------------------------------------------
ALTER TABLE projekt_schueler_kompetenzen
    ADD COLUMN IF NOT EXISTS fremd_stufe       TINYINT UNSIGNED NULL
        COMMENT 'Fremdeinschätzung durch Lernbegleiter (1-4)' AFTER notiz,
    ADD COLUMN IF NOT EXISTS selbst_stufe      TINYINT UNSIGNED NULL
        COMMENT 'Selbsteinschätzung des Schülers (1-4)' AFTER fremd_stufe,
    ADD COLUMN IF NOT EXISTS selbst_sichtbar   TINYINT(1) NOT NULL DEFAULT 0
        COMMENT '0 = Selbsteinschätzung für Lehrer noch nicht sichtbar' AFTER selbst_stufe,
    ADD COLUMN IF NOT EXISTS fremd_benutzer_id INT UNSIGNED NULL
        COMMENT 'Welcher Lernbegleiter hat die Fremdeinschätzung eingetragen' AFTER selbst_sichtbar,
    ADD COLUMN IF NOT EXISTS bewertet_am       DATETIME NULL
        COMMENT 'Zeitpunkt der Bewertung' AFTER fremd_benutzer_id;

ALTER TABLE projekt_schueler_kompetenzen
    ADD FOREIGN KEY (fremd_benutzer_id) REFERENCES benutzer(id) ON DELETE SET NULL;

-- -----------------------------------------------------------------------------
-- 10. KOMPETENZEN: Werkstattkategorie
-- -----------------------------------------------------------------------------
ALTER TABLE kompetenzen
    ADD COLUMN IF NOT EXISTS werkstatt_kategorie
        ENUM('fachlich','methodisch','sozial','persoenlich') NULL
        COMMENT 'Einordnung nach Werkstattkonzept' AFTER aktiv;

SET FOREIGN_KEY_CHECKS = 1;
