-- =============================================================================
-- Migration 15: kompetenzbereiche bekommt parent_id (E29b, E31)
-- Stand: September 2026
-- =============================================================================
--
-- ZWECK
--   E29b hebt E18 auf: Die Gliederung der Kernlehrplaene wird wieder als Baum
--   abgebildet, nicht als feste Spalten. Grund war die Strukturerhebung ueber
--   alle 37 Plaene (docs/curricula/STRUKTUR.md): Die groesste belegte Tiefe
--   ist 3, bei 16 Plaenen ist die Gliederung aber gar nicht gelesen -- ein
--   Schema mit fester Tiefe setzt voraus, dass die groesste Tiefe bekannt ist.
--
--   Diese Migration legt nur die Spalte an. Das Umformen der vier vorhandenen
--   Rahmen erledigen die Seeds und ein UPDATE fuer den MKR; die alten Spalten
--   entfallen erst mit Migration 16, nachdem die Umformung belegt ist.
--
-- ART DER MIGRATION
--   Rein additiv. `parent_id` ist NULL-faehig, ohne Vorgabewert; jede
--   vorhandene Zeile bleibt unveraendert gueltig und wird zunaechst zum
--   Wurzelknoten. Die Datei enthaelt bewusst kein DROP, DELETE oder TRUNCATE.
--
--   Zweimal ausfuehrbar: ADD COLUMN IF NOT EXISTS ist beim zweiten Lauf ein
--   No-Op (FALLSTRICKE.md Abschnitt 4). Der Fremdschluessel wird ueber
--   information_schema abgesichert -- MariaDB kennt kein
--   "ADD FOREIGN KEY IF NOT EXISTS" (dasselbe Muster wie in Migration 08).
--
-- VOR DEM AUSFUEHREN AUF DEM SERVER
--   mysqldump hornse_projektstunden > ~/backup_vor_15_$(date +%F).sql
--   mysql hornse_projektstunden < ~/projektstunden/sql/15_migration_kompetenzbereiche_baum.sql
-- =============================================================================

SET NAMES utf8mb4;

-- -----------------------------------------------------------------------------
-- Selbstreferenz auf kompetenzbereiche
-- -----------------------------------------------------------------------------
ALTER TABLE kompetenzbereiche
    ADD COLUMN IF NOT EXISTS parent_id INT UNSIGNED NULL
        COMMENT 'Elternknoten in kompetenzbereiche; NULL = Wurzelknoten (E29b)'
        AFTER rahmen_id;

-- ON DELETE CASCADE: Wird ein Knoten geloescht, gehen seine Kinder mit. Das
-- ist gewollt -- ein Seed loescht seinen Rahmen und baut ihn neu auf; ein
-- verwaister Teilbaum waere schlimmer als ein geloeschter.
SET @fk := (
    SELECT COUNT(*) FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'kompetenzbereiche'
      AND COLUMN_NAME = 'parent_id'
      AND REFERENCED_TABLE_NAME = 'kompetenzbereiche'
);
SET @sql := IF(@fk = 0,
    'ALTER TABLE kompetenzbereiche ADD CONSTRAINT fk_kb_parent FOREIGN KEY (parent_id) REFERENCES kompetenzbereiche(id) ON DELETE CASCADE',
    'SELECT ''FK fk_kb_parent existiert bereits – uebersprungen'' AS hinweis');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

ALTER TABLE kompetenzbereiche
    ADD INDEX IF NOT EXISTS idx_kb_parent (parent_id);

-- -----------------------------------------------------------------------------
-- `art` gilt jetzt fuer jeden Knoten, nicht mehr nur fuer Blaetter
-- -----------------------------------------------------------------------------
-- Bedeutungsverschiebung gegenueber Migration 13: Dort sagte `art`, was in der
-- Spalte `inhaltsfeld` steht. Im Baum sagt sie, was der KNOTEN ist -- die
-- Spalte `inhaltsfeld` entfaellt mit Migration 16.
ALTER TABLE kompetenzbereiche
    MODIFY COLUMN art VARCHAR(30) NULL
        COMMENT 'Was der Knoten ist: inhaltsfeld | bewegungsfeld | kompetenzbereich | medienkompetenzbereich. Beim MKR ist ein Knoten Wurzel und Blatt zugleich (flacher Rahmen im Baummodell) – das ist kein Fehler.';

-- -----------------------------------------------------------------------------
-- Kontrolle (veraendert nichts)
-- -----------------------------------------------------------------------------
SHOW COLUMNS FROM kompetenzbereiche;

SELECT COUNT(*) AS bereiche          FROM kompetenzbereiche;
SELECT COUNT(*) AS kompetenzen       FROM kompetenzen;
SELECT COUNT(*) AS zuweisungen       FROM projekt_schueler_kompetenzen;
SELECT COUNT(*) AS mit_parent        FROM kompetenzbereiche WHERE parent_id IS NOT NULL;
-- Erwartung direkt nach dieser Migration: 118 / 649 / 228, mit_parent = 0.
