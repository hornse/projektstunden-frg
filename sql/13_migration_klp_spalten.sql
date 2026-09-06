-- =============================================================================
-- Migration 13: teilbereich und art auf kompetenzbereiche (E18)
-- Stand: September 2026
-- =============================================================================
--
-- ZWECK
--   E18 hebt E11 auf: Die Gliederung der Kernlehrpläne wird nicht als Baum
--   über parent_id abgebildet, sondern über benannte Spalten. Dafür fehlen
--   zwei:
--
--     teilbereich  Dritte Gliederungsebene der Fremdsprachen. Unter der
--                  Funktionalen kommunikativen Kompetenz liegen dort sieben
--                  Teilbereiche (Hörverstehen, Sprachmittlung, ...). Bleibt
--                  bei allen anderen Fächern NULL und wird mit dem
--                  Englisch-Auftrag befüllt.
--
--     art          Was in `inhaltsfeld` steht. Sport führt als einziges Fach
--                  zwei Achsen im selben Feld: sechs Inhaltsfelder (a bis f)
--                  und neun Bewegungsfelder (BF/SB 1 bis 9). Heute sind sie
--                  nur an der Namenskonvention unterscheidbar -- `a:` gegen
--                  `BF/SB 1:`. Genau dafür wurde die Spalte beschlossen.
--                  Vorgesehene Werte: 'inhaltsfeld', 'bewegungsfeld'.
--
-- ART DER MIGRATION
--   Rein additiv. Beide Spalten sind NULL-fähig und haben keinen Vorgabewert,
--   damit jede vorhandene Zeile unverändert gültig bleibt. Es wird nichts
--   gelöscht, nichts umgeschrieben und nichts umbenannt -- die Datei enthält
--   bewusst kein DROP, DELETE oder TRUNCATE.
--
--   Zweimal ausführbar: ADD COLUMN IF NOT EXISTS ist beim zweiten Lauf ein
--   No-Op (FALLSTRICKE.md Abschnitt 4).
--
-- VOR DEM AUSFÜHREN AUF DEM SERVER
--   mysqldump hornse_projektstunden > ~/backup_vor_13_$(date +%F).sql
--   mysql hornse_projektstunden < ~/projektstunden/sql/13_migration_klp_spalten.sql
-- =============================================================================

SET NAMES utf8mb4;

-- -----------------------------------------------------------------------------
-- Additive Spalten auf kompetenzbereiche
-- -----------------------------------------------------------------------------
-- Kein ENUM für `art`: Die Werteliste wächst mit jedem Fach, das eine zweite
-- Inhaltsachse mitbringt. Ein ENUM zu erweitern ist eine Tabellenänderung,
-- ein VARCHAR nicht. Die Werte stehen im Kommentar, nicht im Typ.
ALTER TABLE kompetenzbereiche
    ADD COLUMN IF NOT EXISTS teilbereich VARCHAR(80) NULL
        COMMENT 'Dritte Gliederungsebene (Fremdsprachen: Hörverstehen, Sprachmittlung, ...); NULL wo das Fach keine hat'
        AFTER kompetenzbereich,
    ADD COLUMN IF NOT EXISTS art VARCHAR(30) NULL
        COMMENT 'Was in inhaltsfeld steht: inhaltsfeld | bewegungsfeld; NULL wo unerheblich'
        AFTER teilbereich;

-- -----------------------------------------------------------------------------
-- Kontrolle (verändert nichts)
-- -----------------------------------------------------------------------------
SHOW COLUMNS FROM kompetenzbereiche;

SELECT COUNT(*) AS bereiche_gesamt   FROM kompetenzbereiche;
SELECT COUNT(*) AS kompetenzen_gesamt FROM kompetenzen;
-- Erwartung: unverändert gegenüber dem Stand vor der Migration.
-- Weichen die Zahlen ab, hat die Migration mehr getan als angelegt.
