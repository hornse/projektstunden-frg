-- =============================================================================
-- Migration 16: Medienkompetenzrahmen im Baummodell (E29b, E31)
-- Stand: September 2026
-- =============================================================================
--
-- ZWECK
--   Der MKR ist der einzige Rahmen ohne Erzeuger und ohne Quelldatei: Er
--   stammt aus einer eigenen Vorlage und ist nach E8 der einzige von Anfang
--   an korrekte Rahmen. Seine sechs Bereiche sind flach -- im Baummodell
--   werden sie zu sechs Wurzelknoten, die zugleich Blaetter sind.
--
--   Strukturell ist also nichts umzuformen. Zu setzen ist nur `art`.
--
-- WARUM UPDATE UND NICHT NEUAUFBAU
--   An den 106 Kompetenzen des MKR haengen ALLE 228 Zuweisungen aus
--   `projekt_schueler_kompetenzen`. Ein Neuaufbau wuerde den Rahmen loeschen,
--   `ON DELETE CASCADE` naehme die Kompetenzen mit und damit die Zuweisungen.
--   Fuer ein Feld, das gesetzt werden muss, steht das in keinem Verhaeltnis.
--
--   Das UPDATE ruehrt weder `kompetenzen` noch `projekt_schueler_kompetenzen`
--   an. Die Zaehlung unten belegt das.
--
-- WARUM EINE EIGENE DATEI
--   Migration 15 legt Schema an und ist bereits eingespielt; sie soll nicht
--   rueckwirkend auch Daten aendern. Der Auftrag sah die Nummer 16 fuer das
--   Entfernen der alten Spalten vor -- das ist jetzt Migration 17.
--
-- ART DER MIGRATION
--   Datenaendernd, aber eng begrenzt: ein UPDATE auf genau einen Rahmen, das
--   nur `art` setzt. Kein DROP, kein TRUNCATE, kein Loeschen von Zeilen.
--   Zweimal ausfuehrbar -- das UPDATE beschreibt einen Zielzustand.
-- =============================================================================

SET NAMES utf8mb4;
START TRANSACTION;

SET @schule := 1;
SET @rahmen := (SELECT id FROM kompetenzrahmen
                WHERE schule_id = @schule AND kuerzel = 'MKR' LIMIT 1);

-- Sechs Wurzelknoten, die zugleich Blaetter sind: parent_id bleibt NULL,
-- die Kompetenzen haengen unmittelbar daran. `medienkompetenzbereich` ist
-- eine eigene Sorte, weil ein MKR-Bereich ("Bedienen und Anwenden")
-- inhaltlich gliedert, waehrend ein `kompetenzbereich` bei Deutsch
-- ("Rezeption") Rezeption von Produktion unterscheidet (E31).
UPDATE kompetenzbereiche
   SET art = 'medienkompetenzbereich'
 WHERE rahmen_id = @rahmen;

COMMIT;

-- -----------------------------------------------------------------------------
-- Kontrolle (veraendert nichts)
-- -----------------------------------------------------------------------------
SELECT COUNT(*) AS mkr_knoten,
       SUM(parent_id IS NULL) AS wurzeln,
       SUM(art = 'medienkompetenzbereich') AS mit_art
  FROM kompetenzbereiche WHERE rahmen_id = @rahmen;
-- Erwartet: 6 / 6 / 6

SELECT COUNT(*) AS mkr_kompetenzen FROM kompetenzen k
  JOIN kompetenzbereiche kb ON kb.id = k.bereich_id WHERE kb.rahmen_id = @rahmen;
-- Erwartet: 106 -- unveraendert

SELECT COUNT(*) AS zuweisungen_gesamt FROM projekt_schueler_kompetenzen;
-- Erwartet: 228 -- unveraendert
