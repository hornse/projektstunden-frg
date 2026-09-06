-- =============================================================================
-- Migration 14: Phase `sek1_uebergreifend` (E12, E14)
-- Stand: September 2026
-- =============================================================================
--
-- ZWECK
--   Der Kernlehrplan Deutsch Sek I führt in Kapitel 2.3 einundzwanzig
--   übergeordnete Kompetenzerwartungen, die für die **gesamte**
--   Sekundarstufe I gelten -- nicht nur für die Zweite Stufe, als die sie
--   bisher eingetragen sind. E12 hat den Befund festgehalten, E14 die
--   Codeumbenennung beschlossen; beide stehen seit dem 02.09.2026 offen.
--
--   Diese Migration schafft die Voraussetzung: den ENUM-Wert. Das Umsetzen
--   der 21 Erwartungen erledigt der Seed 10, der daraufhin neu erzeugt wird.
--
-- REIHENFOLGE DER ENUM-WERTE
--   Der neue Wert steht zwischen `erprobungsstufe` und `erste_stufe`, nicht
--   am Ende. Die Reihenfolge eines ENUM ist in MariaDB die Sortierreihenfolge
--   (ORDER BY phase sortiert nach Position, nicht alphabetisch). Stünde
--   `sek1_uebergreifend` hinten, sortierte eine Übersicht die übergreifenden
--   Erwartungen hinter die Qualifikationsphase -- also an eine Stelle, an der
--   sie sachlich nichts zu suchen haben.
--
-- ART DER MIGRATION
--   Additiv im Wortsinn: Es kommt ein Wert hinzu, keiner fällt weg. Alle
--   sechs bisherigen Werte bleiben im neuen ENUM enthalten, in unveränderter
--   relativer Ordnung. MariaDB bildet die vorhandenen Zeilen beim MODIFY über
--   ihren **Zeichenwert** ab, nicht über den internen Index -- deshalb
--   überlebt jede Zeile die geänderte Position. Belegt wird das nicht durch
--   diese Aussage, sondern durch die Kontrollabfrage unten: Die Verteilung
--   je Phase muss vor und nach der Migration dieselbe sein.
--
--   Die Datei enthält bewusst kein DROP, DELETE oder TRUNCATE.
--
--   Zweimal ausführbar: Ein zweiter Lauf setzt denselben Typ noch einmal und
--   ist damit ein No-Op. `MODIFY COLUMN` kennt kein `IF NOT EXISTS`; die
--   Idempotenz kommt hier daher, dass die Anweisung einen Zielzustand
--   beschreibt und keine Veränderung.
--
--   COMMENT und NULL-Fähigkeit werden wiederholt. Ein `MODIFY COLUMN` ohne
--   sie würde beides stillschweigend verwerfen.
--
-- VOR DEM AUSFÜHREN AUF DEM SERVER
--   mysqldump hornse_projektstunden > ~/backup_vor_14_$(date +%F).sql
--   mysql hornse_projektstunden < ~/projektstunden/sql/14_migration_phase_sek1uebergreifend.sql
-- =============================================================================

SET NAMES utf8mb4;

-- -----------------------------------------------------------------------------
-- ENUM um `sek1_uebergreifend` erweitern
-- -----------------------------------------------------------------------------
ALTER TABLE kompetenzbereiche
    MODIFY COLUMN phase
        ENUM(
            'erprobungsstufe',        -- Jg. 5/6
            'sek1_uebergreifend',     -- gilt für die gesamte Sek I (E12)
            'erste_stufe',            -- Jg. 7-8/9 (Sek I)
            'zweite_stufe',           -- Jg. 9/10 (Sek I)
            'einfuehrungsphase',      -- EF (Sek II)
            'qualifikationsphase_gk', -- Q1/Q2 Grundkurs
            'qualifikationsphase_lk'  -- Q1/Q2 Leistungskurs
        ) NULL
        COMMENT 'Schulische Phase laut G9-KLP; NULL = phasenübergreifend';

-- -----------------------------------------------------------------------------
-- Kontrolle (verändert nichts)
-- -----------------------------------------------------------------------------
SHOW COLUMNS FROM kompetenzbereiche LIKE 'phase';

SELECT COUNT(*) AS bereiche_gesamt    FROM kompetenzbereiche;
SELECT COUNT(*) AS kompetenzen_gesamt FROM kompetenzen;

-- Kein Bereich darf seine Phase verloren haben. Die Verteilung muss der vor
-- der Migration entsprechen; `sek1_uebergreifend` ist hier noch leer und
-- taucht deshalb noch nicht auf.
SELECT phase, COUNT(*) AS bereiche FROM kompetenzbereiche GROUP BY phase ORDER BY phase;
