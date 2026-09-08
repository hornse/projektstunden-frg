-- =============================================================================
-- Migration 18: Verwaiste Rückmeldungen entfernen (E37)
-- Stand: September 2026
-- =============================================================================
--
-- ZWECK
--   `werkstatt_rueckmeldungen` enthält Zeilen zu Personen, die keine
--   Teilnehmer der jeweiligen Werkstatt sind. Im Bestand sind es zwei, beide
--   zu Werkstatt 2, beide mit `bewertung_stufe = 3`, ohne Freitext, in
--   derselben Sekunde am 07.07.2026 entstanden.
--
--   Auf `projekt_schueler` zeigt kein Fremdschlüssel; solche Zeilen entstehen
--   nicht durch eine Kaskade, sondern durch einen Schreibweg, der die
--   Teilnahme nicht geprüft hat. Dieser Weg ist mit E36 geschlossen -- diese
--   Migration räumt auf, was vorher entstanden ist.
--
-- REIHENFOLGE
--   **Erst E36 ausliefern, dann diese Migration.** Läuft sie vorher, kann
--   dieselbe Lücke die Zeilen sofort wieder erzeugen.
--
-- WARUM ÜBER DIE BEDINGUNG, NICHT ÜBER IDs
--   `DELETE ... WHERE id IN (3,4)` träfe nach einem Neuaufbau der Tabelle
--   andere Zeilen. Die Bedingung „hat keinen Teilnehmerbeitrag" beschreibt,
--   was gemeint ist, und trifft deshalb auch dann das Richtige, wenn die
--   Nummern andere sind.
--
-- ART DER MIGRATION
--   **Nicht additiv.** Sie löscht Daten, und das ist nicht rückgängig zu
--   machen. Deshalb ist der `mysqldump` unten keine Empfehlung, sondern
--   Voraussetzung.
--
--   Zweimal ausführbar: Der zweite Lauf findet nichts mehr und löscht nichts.
--
-- VOR DEM AUSFÜHREN AUF DEM SERVER
--   mysqldump hornse_projektstunden > ~/backup_vor_18_$(date +%F).sql
--   mysql hornse_projektstunden < ~/projektstunden/sql/18_migration_verwaiste_rueckmeldungen.sql
-- =============================================================================

SET NAMES utf8mb4;

-- -----------------------------------------------------------------------------
-- Vorher zählen (verändert nichts)
-- -----------------------------------------------------------------------------
SELECT COUNT(*) AS rueckmeldungen_gesamt_vorher FROM werkstatt_rueckmeldungen;

SELECT COUNT(*) AS verwaist_vorher
FROM werkstatt_rueckmeldungen r
WHERE NOT EXISTS (
    SELECT 1 FROM projekt_schueler ps
    WHERE ps.projekt_id = r.projekt_id AND ps.schueler_id = r.schueler_id
);

-- Was verschwindet -- ohne Personendaten, nur Kennzahlen.
SELECT r.projekt_id, r.bewertung_stufe,
       CHAR_LENGTH(COALESCE(r.freitext,'')) AS freitext_zeichen,
       r.sichtbar, r.erstellt_am
FROM werkstatt_rueckmeldungen r
WHERE NOT EXISTS (
    SELECT 1 FROM projekt_schueler ps
    WHERE ps.projekt_id = r.projekt_id AND ps.schueler_id = r.schueler_id
);

-- -----------------------------------------------------------------------------
-- Löschen
-- -----------------------------------------------------------------------------
-- MariaDB erlaubt in der Unterabfrage eines DELETE keinen Bezug auf die
-- Zieltabelle selbst; über `projekt_schueler` läuft die Abfrage aber auf eine
-- ANDERE Tabelle, das ist zulässig.
DELETE r FROM werkstatt_rueckmeldungen r
WHERE NOT EXISTS (
    SELECT 1 FROM projekt_schueler ps
    WHERE ps.projekt_id = r.projekt_id AND ps.schueler_id = r.schueler_id
);

-- -----------------------------------------------------------------------------
-- Kontrolle
-- -----------------------------------------------------------------------------
SELECT COUNT(*) AS verwaist_nachher
FROM werkstatt_rueckmeldungen r
WHERE NOT EXISTS (
    SELECT 1 FROM projekt_schueler ps
    WHERE ps.projekt_id = r.projekt_id AND ps.schueler_id = r.schueler_id
);
-- Erwartet: 0

SELECT COUNT(*) AS rueckmeldungen_gesamt_nachher FROM werkstatt_rueckmeldungen;
-- Erwartet: vorher minus die oben gezählten Waisen.

SELECT projekt_id, COUNT(*) AS rueckmeldungen
FROM werkstatt_rueckmeldungen GROUP BY projekt_id ORDER BY projekt_id;
