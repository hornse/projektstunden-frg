-- =============================================================================
-- Migration 17: inhaltsfeld, kompetenzbereich und teilbereich entfallen (E29b)
-- Stand: September 2026
-- =============================================================================
--
-- ZWECK
--   Nach der Umformung auf den Baum (Migration 15, die drei Seeds,
--   Migration 16) tragen die drei Spalten keine Information mehr, die nicht
--   im Baum steht:
--
--     inhaltsfeld       -> Name und `art` des Wurzelknotens
--     kompetenzbereich  -> Name und `art` des Blattes
--     teilbereich       -> war nie befuellt; sie war fuer die dritte Ebene
--                          der Fremdsprachen vorgesehen, die der Baum jetzt
--                          ohne eigene Spalte traegt
--
-- ART DER MIGRATION
--   **Die einzige nicht additive Aenderung dieses Auftrags.** Sie entfernt
--   Spalten; ein Rueckweg fuehrt nur ueber das Backup.
--
--   VOR DEM AUSFUEHREN AUF DEM SERVER:
--     mysqldump hornse_projektstunden > ~/backup_vor_17_$(date +%F).sql
--
--   Zweimal ausfuehrbar: DROP COLUMN IF EXISTS ist beim zweiten Lauf ein
--   No-Op.
--
-- VORAUSSETZUNG, die vorher zu pruefen war
--   Kein Code liest die Spalten mehr. `backend/api/index.php` las sie an
--   genau einer Stelle (Zeile 541) und liefert sie seither nicht mehr aus;
--   das Frontend hat sie nie verwendet. `phase` bleibt -- app.js filtert die
--   Katalogansicht darueber.
-- =============================================================================

SET NAMES utf8mb4;

ALTER TABLE kompetenzbereiche
    DROP COLUMN IF EXISTS inhaltsfeld,
    DROP COLUMN IF EXISTS kompetenzbereich,
    DROP COLUMN IF EXISTS teilbereich;

-- -----------------------------------------------------------------------------
-- Kontrolle (veraendert nichts)
-- -----------------------------------------------------------------------------
SHOW COLUMNS FROM kompetenzbereiche;

SELECT COUNT(*) AS bereiche    FROM kompetenzbereiche;
SELECT COUNT(*) AS kompetenzen FROM kompetenzen;
SELECT COUNT(*) AS zuweisungen FROM projekt_schueler_kompetenzen;
-- Erwartet: 177 / 649 / 228
