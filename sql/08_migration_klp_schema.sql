-- =============================================================================
-- Migration 08: KLP-Schema für G9-Kernlehrpläne + Bereinigung falscher KLP-Daten
-- Stand: Juli 2026
-- =============================================================================
--
-- ZWECK
--   1. Additive Schema-Erweiterung der Tabelle `kompetenzbereiche` um die
--      Struktur der aktuellen G9-Kernlehrpläne:
--        - phase            (Erprobungsstufe … Qualifikationsphase LK)
--        - inhaltsfeld      (z. B. Sprache, Texte, Kommunikation, Medien)
--        - kompetenzbereich (z. B. Rezeption, Produktion; fachabhängig)
--   2. Defensive Absicherung der Spalten in `kompetenzen`, die das Frontend
--      bereits nutzt (eltern_kompetenz_id, schule_id) – falls sie in dieser
--      Umgebung noch fehlen (IF NOT EXISTS = No-Op, wenn bereits vorhanden).
--   3. Kontrolliertes Löschen der VERALTETEN/FALSCHEN KLP-Daten
--      (nur MKR bleibt erhalten) – bewusst getrennt und mit Impact-Check,
--      weil das Löschen per ON DELETE CASCADE auch Bewertungen
--      (projekt_schueler_kompetenzen) mitlöschen kann.
--
-- WICHTIG – VOR DEM AUSFÜHREN AUF DEM SERVER:
--   # 1) Backup ziehen:
--   #    mysqldump hornse_projektstunden > ~/backup_vor_08_$(date +%F).sql
--   # 2) Migration einspielen:
--   #    mysql hornse_projektstunden < ~/projektstunden/sql/08_migration_klp_schema.sql
--
-- Das Skript ist idempotent (IF NOT EXISTS überall) und in Transaktionen
-- gekapselt, wo sinnvoll.
-- =============================================================================

SET NAMES utf8mb4;

-- -----------------------------------------------------------------------------
-- TEIL 1: Additive Spalten auf kompetenzbereiche
-- -----------------------------------------------------------------------------
-- phase als ENUM deckt Sek I + Sek II vollständig ab. NULL = phasenunabhängig
-- (z. B. prozessbezogene Bereiche wie Mathematik OPE/MOD oder der MKR).
ALTER TABLE kompetenzbereiche
    ADD COLUMN IF NOT EXISTS phase
        ENUM(
            'erprobungsstufe',        -- Jg. 5/6
            'erste_stufe',            -- Jg. 7-8/9 (Sek I)
            'zweite_stufe',           -- Jg. 9/10 (Sek I)
            'einfuehrungsphase',      -- EF (Sek II)
            'qualifikationsphase_gk', -- Q1/Q2 Grundkurs
            'qualifikationsphase_lk'  -- Q1/Q2 Leistungskurs
        ) NULL
        COMMENT 'Schulische Phase laut G9-KLP; NULL = phasenübergreifend'
        AFTER reihenfolge,
    ADD COLUMN IF NOT EXISTS inhaltsfeld VARCHAR(120) NULL
        COMMENT 'Inhaltsfeld/Gegenstandsbereich, z. B. Sprache, Texte, Kommunikation, Medien'
        AFTER phase,
    ADD COLUMN IF NOT EXISTS kompetenzbereich VARCHAR(80) NULL
        COMMENT 'Kompetenzbereich, z. B. Rezeption/Produktion (Deutsch) oder UF/E/K/B (NaWi)'
        AFTER inhaltsfeld;

-- Index für phasenweises Rendern (Tabs/Farben) im Kompetenzkatalog-Screen.
ALTER TABLE kompetenzbereiche
    ADD INDEX IF NOT EXISTS idx_kb_phase (rahmen_id, phase);

-- -----------------------------------------------------------------------------
-- TEIL 2: Defensive Absicherung der kompetenzen-Spalten (No-Op, wenn vorhanden)
-- -----------------------------------------------------------------------------
-- Das Frontend (app.js) trennt bereits nach eltern_kompetenz_id
-- (allgemeine Kompetenz -> konkrete Erwartung) und 09_seed_sport nutzt
-- schule_id. In dieser DB sind die Spalten vermutlich schon vorhanden;
-- IF NOT EXISTS macht die Migration in beiden Fällen sicher.
ALTER TABLE kompetenzen
    ADD COLUMN IF NOT EXISTS eltern_kompetenz_id INT UNSIGNED NULL
        COMMENT 'Selbstreferenz: NULL = allgemeine Kompetenz, sonst konkrete Erwartung'
        AFTER bereich_id;

ALTER TABLE kompetenzen
    ADD COLUMN IF NOT EXISTS schule_id INT UNSIGNED NULL
        COMMENT 'Mandant; NULL bei fächer-/schulübergreifenden Einträgen'
        AFTER fach_id;

-- FK für die Selbstreferenz nur anlegen, wenn noch keiner existiert.
-- (MariaDB kennt kein "ADD FOREIGN KEY IF NOT EXISTS", daher via information_schema.)
SET @fk_exists := (
    SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'kompetenzen'
      AND COLUMN_NAME = 'eltern_kompetenz_id'
      AND REFERENCED_TABLE_NAME = 'kompetenzen'
);
SET @sql := IF(@fk_exists = 0,
    'ALTER TABLE kompetenzen ADD CONSTRAINT fk_komp_eltern FOREIGN KEY (eltern_kompetenz_id) REFERENCES kompetenzen(id) ON DELETE CASCADE',
    'SELECT ''FK fk_komp_eltern existiert bereits – übersprungen'' AS hinweis');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Index auf die Selbstreferenz (idempotent).
ALTER TABLE kompetenzen
    ADD INDEX IF NOT EXISTS idx_komp_eltern (eltern_kompetenz_id);

-- -----------------------------------------------------------------------------
-- TEIL 3: IMPACT-CHECK vor dem Löschen (NICHTS wird hier gelöscht)
-- -----------------------------------------------------------------------------
-- Zeigt, wie viele Bewertungen (projekt_schueler_kompetenzen) an den zu
-- löschenden KLP-Rahmen hängen. Ist das Ergebnis > 0, VOR dem Löschen prüfen,
-- ob diese Bewertungen erhalten bleiben müssen!
SELECT
    kr.kuerzel,
    kr.name,
    COUNT(DISTINCT kb.id) AS bereiche,
    COUNT(DISTINCT k.id)  AS kompetenzen,
    COUNT(psk.id)         AS betroffene_bewertungen
FROM kompetenzrahmen kr
LEFT JOIN kompetenzbereiche kb ON kb.rahmen_id = kr.id
LEFT JOIN kompetenzen k        ON k.bereich_id = kb.id
LEFT JOIN projekt_schueler_kompetenzen psk ON psk.kompetenz_id = k.id
WHERE kr.schule_id = 1
  AND kr.kuerzel <> 'MKR'
GROUP BY kr.id
ORDER BY kr.kuerzel;

-- -----------------------------------------------------------------------------
-- TEIL 4: LÖSCHEN der falschen KLP-Daten (MKR bleibt erhalten)
-- -----------------------------------------------------------------------------
-- Standardmäßig AKTIV. Wenn der Impact-Check oben betroffene Bewertungen
-- meldet, die erhalten bleiben sollen, diesen Block auskommentieren und
-- zuerst manuell klären.
--
-- ON DELETE CASCADE räumt automatisch kompetenzbereiche, kompetenzen und
-- projekt_schueler_kompetenzen der gelöschten Rahmen ab.
START TRANSACTION;

DELETE FROM kompetenzrahmen
WHERE schule_id = 1
  AND kuerzel <> 'MKR';

COMMIT;

-- -----------------------------------------------------------------------------
-- TEIL 5: Kontroll-Query (Sollzustand nach der Migration)
-- -----------------------------------------------------------------------------
SELECT kr.kuerzel,
       COUNT(DISTINCT kb.id) AS bereiche,
       COUNT(DISTINCT k.id)  AS kompetenzen
FROM kompetenzrahmen kr
LEFT JOIN kompetenzbereiche kb ON kb.rahmen_id = kr.id
LEFT JOIN kompetenzen k        ON k.bereich_id = kb.id
WHERE kr.schule_id = 1
GROUP BY kr.id
ORDER BY kr.kuerzel;
-- Erwartung direkt nach Migration 08: nur noch MKR (6 Bereiche, 24 Kompetenzen).
-- Anschließend werden die Fächer per Seeds (09_… ff.) neu befüllt.
