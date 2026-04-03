-- =============================================================================
-- Projektstunden NRW – Datenbankschema
-- Gymnasium G9 Nordrhein-Westfalen
-- =============================================================================
-- Dieses Schema verwaltet Schulen, Klassen, Lehrer, Schüler, Fächer,
-- Kompetenzen (fächerbezogen) und Projekte mit zugeordneten Stunden
-- und erworbenen Kompetenzen.
--
-- Empfohlene MariaDB-Version: 10.4+
-- Zeichensatz: utf8mb4 (volle Unicode-Unterstützung inkl. Emoji)
-- =============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -----------------------------------------------------------------------------
-- 1. SCHULE
-- Ermöglicht Mandantenfähigkeit: Mehrere Schulen können dieselbe Installation
-- nutzen. Jeder Datensatz gehört zu genau einer Schule.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS schulen (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name        VARCHAR(200) NOT NULL COMMENT 'Offizieller Schulname',
    kuerzel     VARCHAR(20)  NOT NULL COMMENT 'z. B. FRG, GYM-GE',
    adresse     VARCHAR(300) NULL,
    erstellt_am DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_kuerzel (kuerzel)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Mandant: Schule';

-- -----------------------------------------------------------------------------
-- 2. BENUTZER / LEHRKRÄFTE
-- Lehrkräfte melden sich an und können Projekte anlegen.
-- Rolle: 'admin' = Schulverwaltung, 'lehrer' = normaler Unterrichtsnutzer.
-- Das Passwort wird als bcrypt-Hash gespeichert (PHP password_hash()).
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS benutzer (
    id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    schule_id      INT UNSIGNED     NOT NULL,
    vorname        VARCHAR(100)     NOT NULL,
    nachname       VARCHAR(100)     NOT NULL,
    email          VARCHAR(200)     NOT NULL,
    passwort_hash  VARCHAR(255)     NOT NULL COMMENT 'bcrypt-Hash',
    rolle          ENUM('admin','lehrer') NOT NULL DEFAULT 'lehrer',
    kuerzel        VARCHAR(10)      NULL COMMENT 'Lehrerkürzel, z. B. MUS',
    aktiv          TINYINT(1)       NOT NULL DEFAULT 1,
    erstellt_am    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_email (schule_id, email),
    FOREIGN KEY (schule_id) REFERENCES schulen(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Lehrkräfte und Administratoren';

-- -----------------------------------------------------------------------------
-- 3. KLASSEN
-- Eine Klasse gehört zu einer Schule und hat ein Schuljahr (z. B. 2024/25).
-- Der Jahrgang (5–10) steuert das Stundensoll der Stundentafel.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS klassen (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    schule_id   INT UNSIGNED  NOT NULL,
    bezeichnung VARCHAR(20)   NOT NULL COMMENT 'z. B. 7b, 9a',
    jahrgang    TINYINT       NOT NULL COMMENT '5 bis 10 (G9 Sek I)',
    schuljahr   VARCHAR(10)   NOT NULL COMMENT 'z. B. 2024/25',
    aktiv       TINYINT(1)    NOT NULL DEFAULT 1,
    erstellt_am DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_klasse (schule_id, bezeichnung, schuljahr),
    FOREIGN KEY (schule_id) REFERENCES schulen(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Schulklassen';

-- Klassenleitung: Eine Lehrkraft kann Klassenleitung einer Klasse sein
CREATE TABLE IF NOT EXISTS klassenleitung (
    klasse_id   INT UNSIGNED NOT NULL,
    benutzer_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (klasse_id, benutzer_id),
    FOREIGN KEY (klasse_id)   REFERENCES klassen(id)  ON DELETE CASCADE,
    FOREIGN KEY (benutzer_id) REFERENCES benutzer(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Klassenleitung (n:m)';

-- -----------------------------------------------------------------------------
-- 4. SCHÜLER
-- Schüler gehören zu einer Klasse (und damit transitiv zu einer Schule).
-- Keine personenbezogenen Daten jenseits von Name und Klasse.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS schueler (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    klasse_id   INT UNSIGNED NOT NULL,
    vorname     VARCHAR(100) NOT NULL,
    nachname    VARCHAR(100) NOT NULL,
    aktiv       TINYINT(1)   NOT NULL DEFAULT 1 COMMENT '0 = abgegangen',
    erstellt_am DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_klasse (klasse_id),
    FOREIGN KEY (klasse_id) REFERENCES klassen(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Schülerinnen und Schüler';

-- -----------------------------------------------------------------------------
-- 5. UNTERRICHTSFÄCHER
-- Fächer inkl. des lehrplanbezogenen Wochenstundensolls je Jahrgang (5–10).
-- Das Soll dient dem Kontingent-Dashboard: Projektstunden werden auf das
-- Jahres-Wochenstundensoll angerechnet.
-- Fächerkürzel (kuerzel) wird als Fremdschlüssel in Kompetenz-Tabellen genutzt.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS faecher (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    schule_id   INT UNSIGNED NOT NULL,
    name        VARCHAR(100) NOT NULL COMMENT 'Vollständiger Fachname',
    kuerzel     VARCHAR(20)  NOT NULL COMMENT 'z. B. DE, MA, BIO',
    -- Wochenstunden-Soll je Jahrgang laut G9-Stundentafel NRW (Anlage 3a)
    soll_jg5    TINYINT      NOT NULL DEFAULT 0,
    soll_jg6    TINYINT      NOT NULL DEFAULT 0,
    soll_jg7    TINYINT      NOT NULL DEFAULT 0,
    soll_jg8    TINYINT      NOT NULL DEFAULT 0,
    soll_jg9    TINYINT      NOT NULL DEFAULT 0,
    soll_jg10   TINYINT      NOT NULL DEFAULT 0,
    aktiv       TINYINT(1)   NOT NULL DEFAULT 1,
    UNIQUE KEY uq_kuerzel (schule_id, kuerzel),
    FOREIGN KEY (schule_id) REFERENCES schulen(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Unterrichtsfächer mit Stundensoll';

-- Lehrkraft unterrichtet Fach in Klasse (Zuordnung für Berechtigungen)
CREATE TABLE IF NOT EXISTS fach_lehrer_klasse (
    fach_id     INT UNSIGNED NOT NULL,
    benutzer_id INT UNSIGNED NOT NULL,
    klasse_id   INT UNSIGNED NOT NULL,
    PRIMARY KEY (fach_id, benutzer_id, klasse_id),
    FOREIGN KEY (fach_id)     REFERENCES faecher(id)  ON DELETE CASCADE,
    FOREIGN KEY (benutzer_id) REFERENCES benutzer(id) ON DELETE CASCADE,
    FOREIGN KEY (klasse_id)   REFERENCES klassen(id)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Wer unterrichtet welches Fach in welcher Klasse';

-- -----------------------------------------------------------------------------
-- 6. KOMPETENZRAHMEN – HIERARCHISCHE STRUKTUR
--
-- Dreistufig: Rahmen → Bereich → Teilkompetenz
--
-- kompetenzrahmen: z. B. "Medienkompetenzrahmen NRW", "Mathematik KLP G9"
-- kompetenzbereiche: z. B. "1 Bedienen und Anwenden", "OPERIEREN"
-- kompetenzen: die eigentlichen Teilkompetenzen (Blattknoten)
--
-- Jede Kompetenz ist optional einem Fach zugeordnet (fach_id NULL = fachüber-
-- greifend, z. B. Medienkompetenzrahmen).
-- Ein Code (z. B. "1.1", "OPE1") erlaubt eindeutige Referenzierung.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS kompetenzrahmen (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    schule_id   INT UNSIGNED NOT NULL,
    name        VARCHAR(200) NOT NULL COMMENT 'z. B. Medienkompetenzrahmen NRW 2020',
    kuerzel     VARCHAR(30)  NOT NULL COMMENT 'z. B. MKR, MA_KLP',
    beschreibung TEXT         NULL,
    quelle_url  VARCHAR(500) NULL COMMENT 'Offizielle URL des Rahmens',
    fach_id     INT UNSIGNED NULL COMMENT 'NULL = fächerübergreifend',
    UNIQUE KEY uq_rahmen (schule_id, kuerzel),
    FOREIGN KEY (schule_id) REFERENCES schulen(id) ON DELETE CASCADE,
    FOREIGN KEY (fach_id)   REFERENCES faecher(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Kompetenzrahmen (z. B. MKR NRW, KLP Mathematik)';

CREATE TABLE IF NOT EXISTS kompetenzbereiche (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rahmen_id       INT UNSIGNED NOT NULL,
    code            VARCHAR(20)  NULL    COMMENT 'z. B. 1, P, E, S1',
    name            VARCHAR(200) NOT NULL,
    beschreibung    TEXT         NULL,
    reihenfolge     SMALLINT     NOT NULL DEFAULT 0,
    FOREIGN KEY (rahmen_id) REFERENCES kompetenzrahmen(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Kompetenzbereiche innerhalb eines Rahmens';

CREATE TABLE IF NOT EXISTS kompetenzen (
    id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    bereich_id      INT UNSIGNED NOT NULL,
    fach_id         INT UNSIGNED NULL     COMMENT 'Wenn NULL: fächerübergreifend',
    code            VARCHAR(30)  NULL     COMMENT 'z. B. 1.1, OPE1, MOD3',
    kurzname        VARCHAR(200) NOT NULL COMMENT 'Kurze Bezeichnung der Kompetenz',
    beschreibung    TEXT         NULL     COMMENT 'Vollständige Kompetenzbeschreibung',
    jahrgangsstufe  VARCHAR(20)  NULL     COMMENT 'z. B. 5/6, 7/8, 9/10 oder NULL = alle',
    aktiv           TINYINT(1)   NOT NULL DEFAULT 1,
    FOREIGN KEY (bereich_id) REFERENCES kompetenzbereiche(id) ON DELETE CASCADE,
    FOREIGN KEY (fach_id)    REFERENCES faecher(id) ON DELETE SET NULL,
    INDEX idx_fach (fach_id),
    INDEX idx_bereich (bereich_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Einzelne Teilkompetenzen';

-- -----------------------------------------------------------------------------
-- 7. PROJEKTE
-- Ein Projekt wird von einer verantwortlichen Lehrkraft angelegt,
-- hat ein Datum, gehört zu einer Klasse und dokumentiert:
-- - Projektstunden je Fach (projekt_stunden)
-- - erworbene Kompetenzen je Schüler (projekt_schueler_kompetenzen)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS projekte (
    id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    schule_id        INT UNSIGNED NOT NULL,
    klasse_id        INT UNSIGNED NOT NULL,
    lehrer_id        INT UNSIGNED NOT NULL COMMENT 'Verantwortliche Lehrkraft',
    name             VARCHAR(300) NOT NULL,
    beschreibung     TEXT         NULL,
    datum_von        DATE         NOT NULL COMMENT 'Projektbeginn',
    datum_bis        DATE         NULL     COMMENT 'Projektende (optional)',
    status           ENUM('geplant','laufend','abgeschlossen') NOT NULL DEFAULT 'abgeschlossen',
    erstellt_am      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    geaendert_am     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_klasse (klasse_id),
    INDEX idx_lehrer (lehrer_id),
    FOREIGN KEY (schule_id) REFERENCES schulen(id) ON DELETE CASCADE,
    FOREIGN KEY (klasse_id) REFERENCES klassen(id) ON DELETE RESTRICT,
    FOREIGN KEY (lehrer_id) REFERENCES benutzer(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Fächerübergreifende Projekte';

-- Welche Schüler nehmen an einem Projekt teil?
CREATE TABLE IF NOT EXISTS projekt_schueler (
    projekt_id  INT UNSIGNED NOT NULL,
    schueler_id INT UNSIGNED NOT NULL,
    PRIMARY KEY (projekt_id, schueler_id),
    FOREIGN KEY (projekt_id)  REFERENCES projekte(id)  ON DELETE CASCADE,
    FOREIGN KEY (schueler_id) REFERENCES schueler(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Projektteilnahme der Schüler';

-- Wie viele Stunden werden einem Fach angerechnet?
-- (gilt für alle beteiligten Schüler gleichermaßen)
CREATE TABLE IF NOT EXISTS projekt_stunden (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    projekt_id  INT UNSIGNED         NOT NULL,
    fach_id     INT UNSIGNED         NOT NULL,
    stunden     DECIMAL(5,1)         NOT NULL COMMENT 'Auf das Fachkontingent anzurechnende Stunden',
    notiz       VARCHAR(300)         NULL     COMMENT 'Optionale Begründung',
    UNIQUE KEY uq_proj_fach (projekt_id, fach_id),
    FOREIGN KEY (projekt_id) REFERENCES projekte(id)  ON DELETE CASCADE,
    FOREIGN KEY (fach_id)    REFERENCES faecher(id)   ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Angerechnete Projektstunden je Fach';

-- Welche Kompetenzen hat ein Schüler in einem Projekt erworben?
-- Granularität: pro Schüler und Kompetenz (nicht nur pro Projekt)
CREATE TABLE IF NOT EXISTS projekt_schueler_kompetenzen (
    id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    projekt_id    INT UNSIGNED NOT NULL,
    schueler_id   INT UNSIGNED NOT NULL,
    kompetenz_id  INT UNSIGNED NOT NULL,
    notiz         TEXT         NULL COMMENT 'Optionale Beurteilung / Beobachtung',
    erstellt_am   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_proj_schueler_komp (projekt_id, schueler_id, kompetenz_id),
    FOREIGN KEY (projekt_id)   REFERENCES projekte(id)   ON DELETE CASCADE,
    FOREIGN KEY (schueler_id)  REFERENCES schueler(id)  ON DELETE CASCADE,
    FOREIGN KEY (kompetenz_id) REFERENCES kompetenzen(id) ON DELETE CASCADE,
    INDEX idx_schueler_komp (schueler_id, kompetenz_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Erworbene Kompetenzen je Schüler und Projekt';

-- -----------------------------------------------------------------------------
-- 8. AUDIT-LOG (optional, aber empfohlen für Schulen mit Datenschutzpflichten)
-- Protokolliert kritische Datenänderungen mit Zeitstempel und Benutzer.
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_log (
    id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    benutzer_id INT UNSIGNED NULL COMMENT 'NULL wenn System',
    tabelle     VARCHAR(60)  NOT NULL,
    datensatz_id INT UNSIGNED NULL,
    aktion      ENUM('INSERT','UPDATE','DELETE') NOT NULL,
    alt_wert    JSON         NULL,
    neu_wert    JSON         NULL,
    ip_adresse  VARCHAR(45)  NULL,
    erstellt_am DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_tabelle (tabelle, datensatz_id),
    INDEX idx_benutzer (benutzer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Audit-Log für Datenschutz';

SET FOREIGN_KEY_CHECKS = 1;
