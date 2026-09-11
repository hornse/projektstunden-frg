-- =============================================================================
-- Seed 20: Franzoesisch – Kernlehrplan Gymnasium Sek I (G9), NRW 2019 (Heft 3410)
--
-- Quelle: docs/curricula/g9_f_klp_3410_2019_06_23.pdf
-- SHA256: dbcaea789b7b7f3a937c14c3b17989ba6a0523e187371638271c7795f1925d57
-- Erzeugt von: sql/gen/gen_franzoesisch_klp.py
--
-- NICHT VON HAND AENDERN: Korrekturen gehoeren in den Erzeuger, die Datei
-- wird daraus neu geschrieben (E19).
-- Voraussetzung: Migration 08, 13 und 15 (Baum, Spalte `art`).
-- Idempotent: loescht vorhandenen FRA_KLP-Rahmen und baut ihn neu auf.
--
-- Erstes Fach mit einem BILDUNGSGANG als Wurzel (E63): zweite Fremdsprache
-- in zwei Stufen und dritte Fremdsprache. Der Baum ist deshalb vier Ebenen
-- tief -- Bildungsgang, Kompetenzbereich, Teilbereich, Unterbereich --, und
-- es gibt vier INSERTs auf `kompetenzbereiche` statt der drei bei Englisch.
--
-- Kapitel 2.3 (Franzoesisch ab Jahrgangsstufe 5) hat keinen Zweig: Es
-- verweist auf Kapitel 2.2 und fuehrt keine eigenen Erwartungen.
-- =============================================================================

SET NAMES utf8mb4;
START TRANSACTION;

SET @schule := 1;
SET @fach := (SELECT id FROM faecher WHERE schule_id = @schule AND kuerzel = 'FRA' LIMIT 1);

-- Nur der eigene Rahmen wird geloescht; CASCADE raeumt Bereiche und Kompetenzen.
DELETE FROM kompetenzrahmen WHERE schule_id = @schule AND kuerzel = 'FRA_KLP';

INSERT INTO kompetenzrahmen (schule_id, name, kuerzel, beschreibung, quelle_url, fach_id)
VALUES (@schule, 'Französisch KLP NRW G9 Sek I (FRG)', 'FRA_KLP', 'Kernlehrplan Französisch Gymnasium Sekundarstufe I (G9), NRW 2019, Heft 3410', 'docs/curricula/g9_f_klp_3410_2019_06_23.pdf', @fach);
SET @rahmen := LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Kompetenzbereiche: vier Ebenen (E29b, E31, E63)
--
-- Ebene 1 ist der Bildungsgang, Ebene 2 der Kompetenzbereich. Die Tiefe
-- darunter schwankt: Text- und Medienkompetenz, Sprachlernkompetenz und
-- Sprachbewusstheit tragen ihre Erwartungen direkt; unter der Funktionalen
-- kommunikativen Kompetenz liegen sieben Teilbereiche, unter einem davon
-- vier Unterbereiche, und unter der Interkulturellen drei.
-- Kompetenzen haengen nur an Blaettern; die Phase steht als Spalte an
-- jedem Knoten und wiederholt, was der Bildungsgang sagt.
-- --------------------------------------------------------------------------
INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art) VALUES
(@rahmen, NULL, 'FR_2FS_S1', 'Zweite Fremdsprache (Erste Stufe)', 1, 'erste_stufe', 'bildungsgang'),
(@rahmen, NULL, 'FR_2FS_S2', 'Zweite Fremdsprache (Zweite Stufe)', 21, 'zweite_stufe', 'bildungsgang'),
(@rahmen, NULL, 'FR_3FS', 'Dritte Fremdsprache (Ende der Sekundarstufe I)', 41, 'sek1_uebergreifend', 'bildungsgang');

-- Ebene 2: parent_id ueber den Code des Elternknotens.
INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art)
SELECT @rahmen, p.id, t.code, t.name, t.reihenfolge, t.phase, t.art
FROM (
  SELECT 'FR_2FS_S1_FKK' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz' AS name, 2 AS reihenfolge, 'erste_stufe' AS phase, 'kompetenzbereich' AS art, 'FR_2FS_S1' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_IKK' AS code, 'Zweite Fremdsprache (Erste Stufe) · Interkulturelle kommunikative Kompetenz' AS name, 14 AS reihenfolge, 'erste_stufe' AS phase, 'kompetenzbereich' AS art, 'FR_2FS_S1' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_TMK' AS code, 'Zweite Fremdsprache (Erste Stufe) · Text- und Medienkompetenz' AS name, 18 AS reihenfolge, 'erste_stufe' AS phase, 'kompetenzbereich' AS art, 'FR_2FS_S1' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_SLK' AS code, 'Zweite Fremdsprache (Erste Stufe) · Sprachlernkompetenz' AS name, 19 AS reihenfolge, 'erste_stufe' AS phase, 'kompetenzbereich' AS art, 'FR_2FS_S1' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_SBW' AS code, 'Zweite Fremdsprache (Erste Stufe) · Sprachbewusstheit' AS name, 20 AS reihenfolge, 'erste_stufe' AS phase, 'kompetenzbereich' AS art, 'FR_2FS_S1' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_FKK' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz' AS name, 22 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'FR_2FS_S2' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_IKK' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Interkulturelle kommunikative Kompetenz' AS name, 34 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'FR_2FS_S2' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_TMK' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Text- und Medienkompetenz' AS name, 38 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'FR_2FS_S2' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_SLK' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Sprachlernkompetenz' AS name, 39 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'FR_2FS_S2' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_SBW' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Sprachbewusstheit' AS name, 40 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'FR_2FS_S2' AS pcode
  UNION ALL
  SELECT 'FR_3FS_FKK' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz' AS name, 42 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'kompetenzbereich' AS art, 'FR_3FS' AS pcode
  UNION ALL
  SELECT 'FR_3FS_IKK' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Interkulturelle kommunikative Kompetenz' AS name, 54 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'kompetenzbereich' AS art, 'FR_3FS' AS pcode
  UNION ALL
  SELECT 'FR_3FS_TMK' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Text- und Medienkompetenz' AS name, 58 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'kompetenzbereich' AS art, 'FR_3FS' AS pcode
  UNION ALL
  SELECT 'FR_3FS_SLK' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Sprachlernkompetenz' AS name, 59 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'kompetenzbereich' AS art, 'FR_3FS' AS pcode
  UNION ALL
  SELECT 'FR_3FS_SBW' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Sprachbewusstheit' AS name, 60 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'kompetenzbereich' AS art, 'FR_3FS' AS pcode
) t JOIN kompetenzbereiche p ON p.rahmen_id = @rahmen AND p.code = t.pcode;

-- Ebene 3: parent_id ueber den Code des Elternknotens.
INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art)
SELECT @rahmen, p.id, t.code, t.name, t.reihenfolge, t.phase, t.art
FROM (
  SELECT 'FR_2FS_S1_HOR' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen' AS name, 3 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'FR_2FS_S1_FKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_LES' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Leseverstehen' AS name, 4 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'FR_2FS_S1_FKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_SAG' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen' AS name, 5 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'FR_2FS_S1_FKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_ZUS' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen' AS name, 6 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'FR_2FS_S1_FKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_SCH' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Schreiben' AS name, 7 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'FR_2FS_S1_FKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_SPM' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Sprachmittlung' AS name, 8 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'FR_2FS_S1_FKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_VSM' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel' AS name, 9 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'FR_2FS_S1_FKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_IKK_SOW' AS code, 'Zweite Fremdsprache (Erste Stufe) · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen' AS name, 15 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'FR_2FS_S1_IKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_IKK_EIN' AS code, 'Zweite Fremdsprache (Erste Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit' AS name, 16 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'FR_2FS_S1_IKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_IKK_VER' AS code, 'Zweite Fremdsprache (Erste Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln' AS name, 17 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'FR_2FS_S1_IKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_HOR' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen' AS name, 23 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'FR_2FS_S2_FKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_LES' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Leseverstehen' AS name, 24 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'FR_2FS_S2_FKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_SAG' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen' AS name, 25 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'FR_2FS_S2_FKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_ZUS' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen' AS name, 26 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'FR_2FS_S2_FKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_SCH' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Schreiben' AS name, 27 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'FR_2FS_S2_FKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_SPM' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Sprachmittlung' AS name, 28 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'FR_2FS_S2_FKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_VSM' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel' AS name, 29 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'FR_2FS_S2_FKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_IKK_SOW' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen' AS name, 35 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'FR_2FS_S2_IKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_IKK_EIN' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit' AS name, 36 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'FR_2FS_S2_IKK' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_IKK_VER' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln' AS name, 37 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'FR_2FS_S2_IKK' AS pcode
  UNION ALL
  SELECT 'FR_3FS_HOR' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen' AS name, 43 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'teilbereich' AS art, 'FR_3FS_FKK' AS pcode
  UNION ALL
  SELECT 'FR_3FS_LES' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Leseverstehen' AS name, 44 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'teilbereich' AS art, 'FR_3FS_FKK' AS pcode
  UNION ALL
  SELECT 'FR_3FS_SAG' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen' AS name, 45 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'teilbereich' AS art, 'FR_3FS_FKK' AS pcode
  UNION ALL
  SELECT 'FR_3FS_ZUS' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen' AS name, 46 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'teilbereich' AS art, 'FR_3FS_FKK' AS pcode
  UNION ALL
  SELECT 'FR_3FS_SCH' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Schreiben' AS name, 47 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'teilbereich' AS art, 'FR_3FS_FKK' AS pcode
  UNION ALL
  SELECT 'FR_3FS_SPM' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Sprachmittlung' AS name, 48 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'teilbereich' AS art, 'FR_3FS_FKK' AS pcode
  UNION ALL
  SELECT 'FR_3FS_VSM' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel' AS name, 49 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'teilbereich' AS art, 'FR_3FS_FKK' AS pcode
  UNION ALL
  SELECT 'FR_3FS_IKK_SOW' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen' AS name, 55 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'unterbereich' AS art, 'FR_3FS_IKK' AS pcode
  UNION ALL
  SELECT 'FR_3FS_IKK_EIN' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit' AS name, 56 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'unterbereich' AS art, 'FR_3FS_IKK' AS pcode
  UNION ALL
  SELECT 'FR_3FS_IKK_VER' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln' AS name, 57 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'unterbereich' AS art, 'FR_3FS_IKK' AS pcode
) t JOIN kompetenzbereiche p ON p.rahmen_id = @rahmen AND p.code = t.pcode;

-- Ebene 4: parent_id ueber den Code des Elternknotens.
INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art)
SELECT @rahmen, p.id, t.code, t.name, t.reihenfolge, t.phase, t.art
FROM (
  SELECT 'FR_2FS_S1_VSM_WOR' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz' AS name, 10 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'FR_2FS_S1_VSM' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_VSM_GRA' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik' AS name, 11 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'FR_2FS_S1_VSM' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_VSM_AUS' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation' AS name, 12 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'FR_2FS_S1_VSM' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S1_VSM_ORT' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie' AS name, 13 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'FR_2FS_S1_VSM' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_WOR' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz' AS name, 30 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'FR_2FS_S2_VSM' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_GRA' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik' AS name, 31 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'FR_2FS_S2_VSM' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_AUS' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation' AS name, 32 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'FR_2FS_S2_VSM' AS pcode
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_ORT' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie' AS name, 33 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'FR_2FS_S2_VSM' AS pcode
  UNION ALL
  SELECT 'FR_3FS_VSM_WOR' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz' AS name, 50 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'unterbereich' AS art, 'FR_3FS_VSM' AS pcode
  UNION ALL
  SELECT 'FR_3FS_VSM_GRA' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik' AS name, 51 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'unterbereich' AS art, 'FR_3FS_VSM' AS pcode
  UNION ALL
  SELECT 'FR_3FS_VSM_AUS' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation' AS name, 52 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'unterbereich' AS art, 'FR_3FS_VSM' AS pcode
  UNION ALL
  SELECT 'FR_3FS_VSM_ORT' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie' AS name, 53 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'unterbereich' AS art, 'FR_3FS_VSM' AS pcode
) t JOIN kompetenzbereiche p ON p.rahmen_id = @rahmen AND p.code = t.pcode;

-- --------------------------------------------------------------------------
-- Kompetenzerwartungen (flach, nur an Blaettern)
-- --------------------------------------------------------------------------
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_HOR_01' AS code, 'der mündlichen Kommunikation im Unterricht folgen' AS kurzname, 'der mündlichen Kommunikation im Unterricht folgen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_HOR_02' AS code, 'einfachen, klar artikulierten auditiv und audiovisuell vermittelten Texten die Gesamtaussage, Hauptaussagen und…' AS kurzname, 'einfachen, klar artikulierten auditiv und audiovisuell vermittelten Texten die Gesamtaussage, Hauptaussagen und wichtige Einzelinformationen entnehmen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_HOR_03' AS code, 'einfachen Gesprächen zu alltäglichen oder vertrauten Sachverhalten und Themen die Gesamtaussage, Hauptaussagen und…' AS kurzname, 'einfachen Gesprächen zu alltäglichen oder vertrauten Sachverhalten und Themen die Gesamtaussage, Hauptaussagen und wichtige Einzelinformationen entnehmen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_HOR_04' AS code, 'eindeutige Gefühle der Sprechenden erfassen' AS kurzname, 'eindeutige Gefühle der Sprechenden erfassen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_HOR';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Leseverstehen (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_LES_01' AS code, 'der schriftlichen Kommunikation im Unterricht folgen' AS kurzname, 'der schriftlichen Kommunikation im Unterricht folgen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_LES_02' AS code, 'einfachen, klar strukturierten Sach- und Gebrauchstexten sowie einfachen literarischen Texten die Gesamtaussage,…' AS kurzname, 'einfachen, klar strukturierten Sach- und Gebrauchstexten sowie einfachen literarischen Texten die Gesamtaussage, Hauptaussagen und wichtige Einzelinformationen entnehmen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_LES';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_SAG_01' AS code, 'am Unterrichtsgeschehen mündlich teilnehmen' AS kurzname, 'am Unterrichtsgeschehen mündlich teilnehmen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SAG_02' AS code, 'in alltäglichen Gesprächssituationen ihre Redeabsichten verwirklichen und in einfacher Form interagieren' AS kurzname, 'in alltäglichen Gesprächssituationen ihre Redeabsichten verwirklichen und in einfacher Form interagieren' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SAG_03' AS code, 'sich auch in unterschiedlichen Rollen an Gesprächen beteiligen' AS kurzname, 'sich auch in unterschiedlichen Rollen an Gesprächen beteiligen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SAG_04' AS code, 'auch einfache non- und paraverbale Signale setzen' AS kurzname, 'auch einfache non- und paraverbale Signale setzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_SAG';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_ZUS_01' AS code, 'Arbeits- und Unterrichtsergebnisse, auch digital gestützt, in einfacher Form präsentieren' AS kurzname, 'Arbeits- und Unterrichtsergebnisse, auch digital gestützt, in einfacher Form präsentieren' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_ZUS_02' AS code, 'ihre Lebenswelt beschreiben, von Ereignissen berichten und Interessen darstellen' AS kurzname, 'ihre Lebenswelt beschreiben, von Ereignissen berichten und Interessen darstellen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_ZUS_03' AS code, 'mündliche Äußerungen und Inhalte von Texten in einfacher Form wiedergeben' AS kurzname, 'mündliche Äußerungen und Inhalte von Texten in einfacher Form wiedergeben' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_ZUS_04' AS code, 'sich zu Inhalten von im Unterricht behandelten Texten und Themen in einfacher Form äußern' AS kurzname, 'sich zu Inhalten von im Unterricht behandelten Texten und Themen in einfacher Form äußern' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_ZUS';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Schreiben (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_SCH_01' AS code, 'wesentliche Textinhalte in einfacher Form wiedergeben' AS kurzname, 'wesentliche Textinhalte in einfacher Form wiedergeben' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SCH_02' AS code, 'in Alltagssituationen zielführend schriftlich kommunizieren' AS kurzname, 'in Alltagssituationen zielführend schriftlich kommunizieren' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SCH_03' AS code, 'ihre Lebenswelt beschreiben, von Ereignissen berichten und Interessen darstellen' AS kurzname, 'ihre Lebenswelt beschreiben, von Ereignissen berichten und Interessen darstellen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SCH_04' AS code, 'einfache Formen des produktionsorientierten und kreativen Schreibens realisieren' AS kurzname, 'einfache Formen des produktionsorientierten und kreativen Schreibens realisieren' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SCH_05' AS code, 'digitale Werkzeuge auch für einfache Formen des kollaborativen Schreibens einsetzen' AS kurzname, 'digitale Werkzeuge auch für einfache Formen des kollaborativen Schreibens einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_SCH';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Sprachmittlung (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_SPM_01' AS code, 'als Sprachmittelnde in informellen und einfach strukturierten formalisierten Kommunikationssituationen relevante…' AS kurzname, 'als Sprachmittelnde in informellen und einfach strukturierten formalisierten Kommunikationssituationen relevante Aussagen in der jeweiligen Zielsprache, auch unter Nutzung von geeigneten Kompensationsstrategien, situations- und adressatengerecht wiedergeben' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SPM_02' AS code, 'Kernaussagen kürzerer mündlicher und schriftlicher Informationsmaterialien adressatengerecht wiedergeben' AS kurzname, 'Kernaussagen kürzerer mündlicher und schriftlicher Informationsmaterialien adressatengerecht wiedergeben' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SPM_03' AS code, 'für die Sprachmittlung notwendige Erläuterungen hinzufügen' AS kurzname, 'für die Sprachmittlung notwendige Erläuterungen hinzufügen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_SPM';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_VSM_WOR_01' AS code, 'einen grundlegenden Wortschatz des discours en classe verwenden' AS kurzname, 'einen grundlegenden Wortschatz des discours en classe verwenden' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_VSM_WOR_02' AS code, 'einen grundlegenden allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz…' AS kurzname, 'einen grundlegenden allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_VSM_WOR_03' AS code, 'einen grundlegenden Wortschatz zur Textproduktion verwenden' AS kurzname, 'einen grundlegenden Wortschatz zur Textproduktion verwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_VSM_WOR';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_VSM_GRA_01' AS code, 'Sachverhalte schildern und von Ereignissen berichten und erzählen' AS kurzname, 'Sachverhalte schildern und von Ereignissen berichten und erzählen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_VSM_GRA_02' AS code, 'Ge- und Verbote, Aufforderungen und Bitten, Fragen, Wünsche und Erwartungen sowie Verpflichtungen in einfacher Form…' AS kurzname, 'Ge- und Verbote, Aufforderungen und Bitten, Fragen, Wünsche und Erwartungen sowie Verpflichtungen in einfacher Form ausdrücken' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_VSM_GRA_03' AS code, 'Texte und mündliche Äußerungen strukturieren und räumliche, zeitliche und logische Bezüge in einfacher Form darstellen' AS kurzname, 'Texte und mündliche Äußerungen strukturieren und räumliche, zeitliche und logische Bezüge in einfacher Form darstellen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_VSM_GRA';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_VSM_AUS_01' AS code, 'kürzere Sprech- und Lesetexte sinngestaltend und adressatenbezogen vortragen' AS kurzname, 'kürzere Sprech- und Lesetexte sinngestaltend und adressatenbezogen vortragen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_VSM_AUS_02' AS code, 'in klar strukturierten Gesprächssituationen und kurzen Redebeiträgen Aussprache und Intonation weitgehend angemessen…' AS kurzname, 'in klar strukturierten Gesprächssituationen und kurzen Redebeiträgen Aussprache und Intonation weitgehend angemessen realisieren' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_VSM_AUS_03' AS code, 'erste Kenntnisse der Aussprache und Intonation für ihre Hör- und Sprechabsichten einsetzen' AS kurzname, 'erste Kenntnisse der Aussprache und Intonation für ihre Hör- und Sprechabsichten einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_VSM_AUS';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_VSM_ORT_01' AS code, 'grundlegende orthografische Muster weitgehend korrekt verwenden' AS kurzname, 'grundlegende orthografische Muster weitgehend korrekt verwenden' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_VSM_ORT_02' AS code, 'Kenntnisse grundlegender grammatischer Strukturen und Regeln, diakritischer Zeichen und typografischer Besonderheiten…' AS kurzname, 'Kenntnisse grundlegender grammatischer Strukturen und Regeln, diakritischer Zeichen und typografischer Besonderheiten für die weitgehend normgerechte Schreibung einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_VSM_ORT';
-- Zweite Fremdsprache (Erste Stufe) · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_IKK_SOW_01' AS code, 'ein erstes soziokulturelles Orientierungswissen einsetzen' AS kurzname, 'ein erstes soziokulturelles Orientierungswissen einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_IKK_SOW';
-- Zweite Fremdsprache (Erste Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_IKK_EIN_01' AS code, 'Phänomene kultureller Vielfalt benennen und neuen Erfahrungen mit anderen Kulturen grundsätzlich offen begegnen' AS kurzname, 'Phänomene kultureller Vielfalt benennen und neuen Erfahrungen mit anderen Kulturen grundsätzlich offen begegnen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_IKK_EIN_02' AS code, 'repräsentative Verhaltensweisen und Konventionen anderer Kulturen in Ansätzen mit eigenen Anschauungen vergleichen und…' AS kurzname, 'repräsentative Verhaltensweisen und Konventionen anderer Kulturen in Ansätzen mit eigenen Anschauungen vergleichen und dabei Toleranz entwickeln, sofern Grundprinzipien friedlichen und respektvollen Zusammenlebens nicht verletzt werden' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_IKK_EIN_03' AS code, 'zu ihren eigenen Wahrnehmungen und Einstellungen begründet Stellung beziehen' AS kurzname, 'zu ihren eigenen Wahrnehmungen und Einstellungen begründet Stellung beziehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_IKK_EIN';
-- Zweite Fremdsprache (Erste Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_IKK_VER_01' AS code, 'in elementaren formellen wie informellen Begegnungssituationen unter Beachtung kulturspezifischer Konventionen und…' AS kurzname, 'in elementaren formellen wie informellen Begegnungssituationen unter Beachtung kulturspezifischer Konventionen und Besonderheiten kommunikativ angemessen handeln' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_IKK_VER_02' AS code, 'in elementaren interkulturellen Handlungssituationen grundlegende Informationen und Meinungen zu Themen des…' AS kurzname, 'in elementaren interkulturellen Handlungssituationen grundlegende Informationen und Meinungen zu Themen des soziokulturellen Orientierungswissens austauschen und daraus Handlungsoptionen ableiten' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_IKK_VER_03' AS code, 'sich durch Perspektivwechsel mit elementaren, kulturell bedingten Denk- und Verhaltensweisen kritisch auseinandersetzen' AS kurzname, 'sich durch Perspektivwechsel mit elementaren, kulturell bedingten Denk- und Verhaltensweisen kritisch auseinandersetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_IKK_VER';
-- Zweite Fremdsprache (Erste Stufe) · Text- und Medienkompetenz (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_TMK_01' AS code, 'im Rahmen des besprechenden Umgangs mit Texten und Medien einfachen Texten und Medienprodukten wesentliche…' AS kurzname, 'im Rahmen des besprechenden Umgangs mit Texten und Medien einfachen Texten und Medienprodukten wesentliche Informationen zu Personen, Handlungen, Ort und Zeit entnehmen, diese mündlich und schriftlich wiedergeben und zusammenfassen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_TMK_02' AS code, 'einfache Texte und Medienprodukte grundlegenden Gattungen zuordnen und wesentliche Strukturelemente an ihnen belegen' AS kurzname, 'einfache Texte und Medienprodukte grundlegenden Gattungen zuordnen und wesentliche Strukturelemente an ihnen belegen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_TMK_03' AS code, 'im Rahmen des gestaltenden Umgangs mit Texten und Medien kurze Texte oder Medienprodukte erstellen, in andere…' AS kurzname, 'im Rahmen des gestaltenden Umgangs mit Texten und Medien kurze Texte oder Medienprodukte erstellen, in andere vertraute Texte oder Medienprodukte umwandeln sowie Texte und Medienprodukte in einfacher Form kreativ bearbeiten' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_TMK_04' AS code, 'im Rahmen des reflektierenden Umgangs mit Texten und Medien unter Berücksichtigung der rechtlichen Grundlagen das…' AS kurzname, 'im Rahmen des reflektierenden Umgangs mit Texten und Medien unter Berücksichtigung der rechtlichen Grundlagen das Internet aufgabenbezogen für Informationsrecherchen zu spezifischen frankophonen Themen nutzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_TMK';
-- Zweite Fremdsprache (Erste Stufe) · Sprachlernkompetenz (7)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_SLK_01' AS code, 'im Vergleich des Französischen mit anderen Sprachen Ähnlichkeiten und Verschiedenheiten entdecken und für das eigene…' AS kurzname, 'im Vergleich des Französischen mit anderen Sprachen Ähnlichkeiten und Verschiedenheiten entdecken und für das eigene Sprachenlernen in Ansätzen nutzen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SLK_02' AS code, 'elementare Formen der Wortschatzarbeit einsetzen' AS kurzname, 'elementare Formen der Wortschatzarbeit einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SLK_03' AS code, 'Arbeitsprodukte in Wort und Schrift in Ansätzen selbstständig überarbeiten und dabei eigene Fehlerschwerpunkte erkennen' AS kurzname, 'Arbeitsprodukte in Wort und Schrift in Ansätzen selbstständig überarbeiten und dabei eigene Fehlerschwerpunkte erkennen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SLK_04' AS code, 'in Texten elementare grammatische Elemente und Strukturen identifizieren und daraus Regeln ableiten' AS kurzname, 'in Texten elementare grammatische Elemente und Strukturen identifizieren und daraus Regeln ableiten' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SLK_05' AS code, 'einfache, auch digitale Werkzeuge für das eigene Sprachenlernen reflektiert einsetzen' AS kurzname, 'einfache, auch digitale Werkzeuge für das eigene Sprachenlernen reflektiert einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SLK_06' AS code, 'auch digitale Übungs- und Testaufgaben zum selbstgesteuerten systematischen Sprachtraining einsetzen' AS kurzname, 'auch digitale Übungs- und Testaufgaben zum selbstgesteuerten systematischen Sprachtraining einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SLK_07' AS code, 'den eigenen Lernfortschritt anhand einfacher, auch digitaler Evaluationsinstrumente einschätzen und dokumentieren' AS kurzname, 'den eigenen Lernfortschritt anhand einfacher, auch digitaler Evaluationsinstrumente einschätzen und dokumentieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_SLK';
-- Zweite Fremdsprache (Erste Stufe) · Sprachbewusstheit (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S1_SBW_01' AS code, 'einfache semantische und strukturelle Zusammenhänge, elementare sprachliche Regelmäßigkeiten sowie einzelne Varietäten…' AS kurzname, 'einfache semantische und strukturelle Zusammenhänge, elementare sprachliche Regelmäßigkeiten sowie einzelne Varietäten des alltäglichen Sprachgebrauchs erkennen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SBW_02' AS code, 'einfache Sprachphänomene und sprachliche Entwicklungen vergleichen' AS kurzname, 'einfache Sprachphänomene und sprachliche Entwicklungen vergleichen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SBW_03' AS code, 'die Angemessenheit und Effektivität ihres sprachlichen Ausdrucks abwägen' AS kurzname, 'die Angemessenheit und Effektivität ihres sprachlichen Ausdrucks abwägen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S1_SBW_04' AS code, 'ihren Sprachgebrauch entsprechend den Erfordernissen der Kommunikationssituation reflektieren' AS kurzname, 'ihren Sprachgebrauch entsprechend den Erfordernissen der Kommunikationssituation reflektieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S1_SBW';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_HOR_01' AS code, 'der mündlichen Kommunikation im Unterricht folgen' AS kurzname, 'der mündlichen Kommunikation im Unterricht folgen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_HOR_02' AS code, 'klar artikulierten auditiv und audiovisuell vermittelten Texten die Gesamtaussage, Hauptaussagen und wichtige…' AS kurzname, 'klar artikulierten auditiv und audiovisuell vermittelten Texten die Gesamtaussage, Hauptaussagen und wichtige Einzelinformationen entnehmen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_HOR_03' AS code, 'Gesprächen zu alltäglichen oder vertrauten Sachverhalten und Themen die Gesamtaussage, Hauptaussagen und wichtige…' AS kurzname, 'Gesprächen zu alltäglichen oder vertrauten Sachverhalten und Themen die Gesamtaussage, Hauptaussagen und wichtige Einzelinformationen entnehmen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_HOR_04' AS code, 'eindeutige Stimmungen und Gefühle der Sprechenden erfassen' AS kurzname, 'eindeutige Stimmungen und Gefühle der Sprechenden erfassen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_HOR';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Leseverstehen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_LES_01' AS code, 'der schriftlichen Kommunikation im Unterricht folgen' AS kurzname, 'der schriftlichen Kommunikation im Unterricht folgen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_LES_02' AS code, 'klar strukturierten, auch mehrfach kodierten Sach- und Gebrauchstexten sowie einfacheren literarischen Texten die…' AS kurzname, 'klar strukturierten, auch mehrfach kodierten Sach- und Gebrauchstexten sowie einfacheren literarischen Texten die Gesamtaussage, Hauptaussagen und wichtige Einzelinformationen entnehmen und diese Informationen in den Kontext der Gesamtaussage einordnen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_LES_03' AS code, 'Texte vor dem Hintergrund grundlegender Gattungs- und Gestaltungsmerkmale inhaltlich erfassen' AS kurzname, 'Texte vor dem Hintergrund grundlegender Gattungs- und Gestaltungsmerkmale inhaltlich erfassen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_LES_04' AS code, 'explizite und leicht zugängliche implizite Informationen im Wesentlichen erfassen und in den Kontext der Gesamtaussage…' AS kurzname, 'explizite und leicht zugängliche implizite Informationen im Wesentlichen erfassen und in den Kontext der Gesamtaussage einordnen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_LES';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_SAG_01' AS code, 'im Unterricht Inhalte beschreiben und Abläufe vereinbaren' AS kurzname, 'im Unterricht Inhalte beschreiben und Abläufe vereinbaren' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SAG_02' AS code, 'Ergebnisse von Arbeitsprozessen diskutieren' AS kurzname, 'Ergebnisse von Arbeitsprozessen diskutieren' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SAG_03' AS code, 'in alltäglichen, auch digital gestützten Gesprächssituationen ihre Redeabsichten verwirklichen und angemessen…' AS kurzname, 'in alltäglichen, auch digital gestützten Gesprächssituationen ihre Redeabsichten verwirklichen und angemessen interagieren' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SAG_04' AS code, 'sich in unterschiedlichen Rollen an formalisierten, thematisch vertrauten Gesprächen beteiligen' AS kurzname, 'sich in unterschiedlichen Rollen an formalisierten, thematisch vertrauten Gesprächen beteiligen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SAG_05' AS code, 'auch non- und paraverbale Signale setzen' AS kurzname, 'auch non- und paraverbale Signale setzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_SAG';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_ZUS_01' AS code, 'sich und ihre Lebenswelt beschreiben, Persönlichkeiten vorstellen, von Ereignissen berichten, ihre Mediennutzung sowie…' AS kurzname, 'sich und ihre Lebenswelt beschreiben, Persönlichkeiten vorstellen, von Ereignissen berichten, ihre Mediennutzung sowie ihr Konsumverhalten erklären, Interessen und Standpunkte darstellen und erläutern' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_ZUS_02' AS code, 'mündliche Äußerungen und Inhalte von Texten zusammenfassend vortragen' AS kurzname, 'mündliche Äußerungen und Inhalte von Texten zusammenfassend vortragen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_ZUS_03' AS code, 'sich zu Inhalten von im Unterricht behandelten Texten und Themen zusammenhängend äußern sowie in einfacher Form ihre…' AS kurzname, 'sich zu Inhalten von im Unterricht behandelten Texten und Themen zusammenhängend äußern sowie in einfacher Form ihre Einstellungen und Meinungen dazu begründen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_ZUS_04' AS code, 'Arbeits- und Unterrichtsergebnisse, auch digital gestützt, präsentieren' AS kurzname, 'Arbeits- und Unterrichtsergebnisse, auch digital gestützt, präsentieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_ZUS';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Schreiben (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_SCH_01' AS code, 'Arbeitsergebnisse dokumentieren' AS kurzname, 'Arbeitsergebnisse dokumentieren' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SCH_02' AS code, 'wesentliche Inhalte von klar strukturierten einfacheren fiktionalen Texten sowie von Sach- und Gebrauchstexten…' AS kurzname, 'wesentliche Inhalte von klar strukturierten einfacheren fiktionalen Texten sowie von Sach- und Gebrauchstexten zusammenfassen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SCH_03' AS code, 'unterschiedliche Typen von stärker formalisierten, auch mehrfach kodierten Sach- und Gebrauchstexten in einfacher Form…' AS kurzname, 'unterschiedliche Typen von stärker formalisierten, auch mehrfach kodierten Sach- und Gebrauchstexten in einfacher Form verfassen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SCH_04' AS code, 'in persönlichen Texten ihre Meinungen, Hoffnungen und Einstellungen äußern und Handlungsvorschläge machen' AS kurzname, 'in persönlichen Texten ihre Meinungen, Hoffnungen und Einstellungen äußern und Handlungsvorschläge machen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SCH_05' AS code, 'unter Beachtung grundlegender textsortenspezifischer Merkmale einfache Formen des produktionsorientierten und…' AS kurzname, 'unter Beachtung grundlegender textsortenspezifischer Merkmale einfache Formen des produktionsorientierten und kreativen Schreibens realisieren' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SCH_06' AS code, 'digitale Werkzeuge auch für das kollaborative Schreiben einsetzen' AS kurzname, 'digitale Werkzeuge auch für das kollaborative Schreiben einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_SCH';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Sprachmittlung (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_SPM_01' AS code, 'als Sprachmittelnde in informellen und einfach strukturierten formalisierten Kommunikationssituationen relevante…' AS kurzname, 'als Sprachmittelnde in informellen und einfach strukturierten formalisierten Kommunikationssituationen relevante Aussagen in der jeweiligen Zielsprache, auch unter Nutzung von geeigneten Kompensationsstrategien, situations- und adressatengerecht wiedergeben' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SPM_02' AS code, 'zentrale Informationen aus klar strukturierten mündlichen und schriftlichen Texten situations- und adressatengerecht…' AS kurzname, 'zentrale Informationen aus klar strukturierten mündlichen und schriftlichen Texten situations- und adressatengerecht zusammenfassen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SPM_03' AS code, 'für die Sprachmittlung notwendige Erläuterungen hinzufügen' AS kurzname, 'für die Sprachmittlung notwendige Erläuterungen hinzufügen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SPM_04' AS code, 'bei der Sprachmittlung von Informationen auf eventuelle einfache Nachfragen eingehen' AS kurzname, 'bei der Sprachmittlung von Informationen auf eventuelle einfache Nachfragen eingehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_SPM';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_VSM_WOR_01' AS code, 'einen grundlegenden Wortschatz zur unterrichtlichen Kommunikation produktiv und einen erweiterten Wortschatz rezeptiv…' AS kurzname, 'einen grundlegenden Wortschatz zur unterrichtlichen Kommunikation produktiv und einen erweiterten Wortschatz rezeptiv verwenden' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_WOR_02' AS code, 'einen grundlegenden allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz…' AS kurzname, 'einen grundlegenden allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz produktiv einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_WOR_03' AS code, 'einen erweiterten allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz…' AS kurzname, 'einen erweiterten allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz rezeptiv einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_WOR_04' AS code, 'einen grundlegenden Wortschatz zur Textbesprechung einsetzen' AS kurzname, 'einen grundlegenden Wortschatz zur Textbesprechung einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_WOR_05' AS code, 'einen grundlegenden Wortschatz zur Textproduktion einsetzen' AS kurzname, 'einen grundlegenden Wortschatz zur Textproduktion einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_VSM_WOR';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_VSM_GRA_01' AS code, 'Handlungen, Vorgänge und Äußerungen zeitlich positionieren' AS kurzname, 'Handlungen, Vorgänge und Äußerungen zeitlich positionieren' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_GRA_02' AS code, 'Annahmen, Hypothesen oder Bedingungen formulieren' AS kurzname, 'Annahmen, Hypothesen oder Bedingungen formulieren' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_GRA_03' AS code, 'Gefühle, Meinungen, Bitten, Wünsche und Erwartungen äußern' AS kurzname, 'Gefühle, Meinungen, Bitten, Wünsche und Erwartungen äußern' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_GRA_04' AS code, 'Vergleiche zur Darstellung von Gemeinsamkeiten und Unterschieden anstellen' AS kurzname, 'Vergleiche zur Darstellung von Gemeinsamkeiten und Unterschieden anstellen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_GRA_05' AS code, 'Handlungen und Ereignisse aktivisch und passivisch darstellen' AS kurzname, 'Handlungen und Ereignisse aktivisch und passivisch darstellen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_GRA_06' AS code, 'komplexere Sachverhalte mit temporalen, kausalen, konsekutiven und konditionalen Zusammenhängen formulieren' AS kurzname, 'komplexere Sachverhalte mit temporalen, kausalen, konsekutiven und konditionalen Zusammenhängen formulieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_VSM_GRA';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_VSM_AUS_01' AS code, 'auch umfangreichere Texte phonetisch und intonatorisch korrekt vortragen' AS kurzname, 'auch umfangreichere Texte phonetisch und intonatorisch korrekt vortragen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_AUS_02' AS code, 'beim monologischen und dialogischen Sprechen ein grundlegendes Repertoire typischer Aussprache- und Intonationsmuster…' AS kurzname, 'beim monologischen und dialogischen Sprechen ein grundlegendes Repertoire typischer Aussprache- und Intonationsmuster einsetzen und dabei eine zumeist klare Aussprache und Intonation realisieren' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_AUS_03' AS code, 'Kenntnisse der Aussprache und Intonation für ihre Hör- und Sprechabsichten einsetzen' AS kurzname, 'Kenntnisse der Aussprache und Intonation für ihre Hör- und Sprechabsichten einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_VSM_AUS';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_VSM_ORT_01' AS code, 'typische orthografische Muster in der Regel korrekt verwenden' AS kurzname, 'typische orthografische Muster in der Regel korrekt verwenden' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_ORT_02' AS code, 'Kenntnisse grammatischer Strukturen und Regeln für die normgerechte Schreibung einsetzen' AS kurzname, 'Kenntnisse grammatischer Strukturen und Regeln für die normgerechte Schreibung einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_VSM_ORT_03' AS code, 'Grundregeln der französischen Zeichensetzung, die von der deutschen Sprache abweichen, im Wesentlichen korrekt anwenden' AS kurzname, 'Grundregeln der französischen Zeichensetzung, die von der deutschen Sprache abweichen, im Wesentlichen korrekt anwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_VSM_ORT';
-- Zweite Fremdsprache (Zweite Stufe) · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_IKK_SOW_01' AS code, 'ein grundlegendes soziokulturelles Orientierungswissen einsetzen' AS kurzname, 'ein grundlegendes soziokulturelles Orientierungswissen einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_IKK_SOW';
-- Zweite Fremdsprache (Zweite Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_IKK_EIN_01' AS code, 'Phänomene kultureller Vielfalt einordnen und neuen Erfahrungen mit anderen Kulturen grundsätzlich offen begegnen' AS kurzname, 'Phänomene kultureller Vielfalt einordnen und neuen Erfahrungen mit anderen Kulturen grundsätzlich offen begegnen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_IKK_EIN_02' AS code, 'repräsentative Wertvorstellungen und Verhaltensweisen anderer Kulturen mit eigenen Anschauungen vergleichen und dabei…' AS kurzname, 'repräsentative Wertvorstellungen und Verhaltensweisen anderer Kulturen mit eigenen Anschauungen vergleichen und dabei Toleranz entwickeln, sofern Grundprinzipien friedlichen und respektvollen Zusammenlebens nicht verletzt werden' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_IKK_EIN_03' AS code, 'zu ihren eigenen Wahrnehmungen und Einstellungen auch aus Gender-Perspektive kritisch Stellung beziehen' AS kurzname, 'zu ihren eigenen Wahrnehmungen und Einstellungen auch aus Gender-Perspektive kritisch Stellung beziehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_IKK_EIN';
-- Zweite Fremdsprache (Zweite Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_IKK_VER_01' AS code, 'in formellen wie informellen Begegnungssituationen unter Beachtung kulturspezifischer Konventionen und Besonderheiten…' AS kurzname, 'in formellen wie informellen Begegnungssituationen unter Beachtung kulturspezifischer Konventionen und Besonderheiten kommunikativ angemessen handeln' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_IKK_VER_02' AS code, 'in interkulturellen Handlungssituationen Informationen und Meinungen zu Themen des soziokulturellen…' AS kurzname, 'in interkulturellen Handlungssituationen Informationen und Meinungen zu Themen des soziokulturellen Orientierungswissens austauschen und daraus Handlungsoptionen ableiten' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_IKK_VER_03' AS code, 'sich durch Perspektivwechsel mit kulturell bedingten Denk- und Verhaltensweisen auseinandersetzen und diese auf…' AS kurzname, 'sich durch Perspektivwechsel mit kulturell bedingten Denk- und Verhaltensweisen auseinandersetzen und diese auf Grundlage spezifischer Differenzerfahrungen kritisch prüfen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_IKK_VER';
-- Zweite Fremdsprache (Zweite Stufe) · Text- und Medienkompetenz (11)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_TMK_01' AS code, 'im Rahmen des besprechenden Umgangs mit Texten und Medien Texte und Medienprodukte vor dem Hintergrund des…' AS kurzname, 'im Rahmen des besprechenden Umgangs mit Texten und Medien Texte und Medienprodukte vor dem Hintergrund des kommunikativen und kulturellen Kontextes erschließen, ihnen die Gesamtaussage, Hauptaussagen sowie wichtige Details zu Personen, Handlungen, Ort und Zeit entnehmen, diese mündlich und schriftlich wiedergeben und zusammenfassen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_TMK_02' AS code, 'Texte und Medienprodukte grundlegenden Gattungen zuordnen und wesentliche Strukturelemente an ihnen belegen' AS kurzname, 'Texte und Medienprodukte grundlegenden Gattungen zuordnen und wesentliche Strukturelemente an ihnen belegen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_TMK_03' AS code, 'Aussagen und Wirkungsabsichten bei geläufigen Textsorten und Medienprodukten erläutern' AS kurzname, 'Aussagen und Wirkungsabsichten bei geläufigen Textsorten und Medienprodukten erläutern' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_TMK_04' AS code, 'unter Berücksichtigung des soziokulturellen Orientierungswissens zu den Aussagen der jeweiligen Texte oder…' AS kurzname, 'unter Berücksichtigung des soziokulturellen Orientierungswissens zu den Aussagen der jeweiligen Texte oder Medienprodukte mündlich und schriftlich Stellung beziehen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_TMK_05' AS code, 'im Rahmen des gestaltenden Umgangs mit Texten und Medien in Anlehnung an unterschiedliche Ausgangsformate Texte und…' AS kurzname, 'im Rahmen des gestaltenden Umgangs mit Texten und Medien in Anlehnung an unterschiedliche Ausgangsformate Texte und Medienprodukte des täglichen Gebrauchs erstellen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_TMK_06' AS code, 'Texte oder Medienprodukte in andere vertraute Texte oder Medienprodukte umwandeln' AS kurzname, 'Texte oder Medienprodukte in andere vertraute Texte oder Medienprodukte umwandeln' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_TMK_07' AS code, 'Texte und Medienprodukte kreativ bearbeiten' AS kurzname, 'Texte und Medienprodukte kreativ bearbeiten' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_TMK_08' AS code, 'einfache audiovisuelle Medienprodukte unter Verwendung digitaler Werkzeuge erstellen' AS kurzname, 'einfache audiovisuelle Medienprodukte unter Verwendung digitaler Werkzeuge erstellen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_TMK_09' AS code, 'im Rahmen des reflektierenden Umgangs mit Texten und Medien unter Berücksichtigung der rechtlichen Grundlagen…' AS kurzname, 'im Rahmen des reflektierenden Umgangs mit Texten und Medien unter Berücksichtigung der rechtlichen Grundlagen vornehmlich vorgegebene Texte und Medienprodukte aufgabenbezogen mündlich, schriftlich und medial auswerten' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_TMK_10' AS code, 'Arbeitsergebnisse und Mitteilungsabsichten sach- und adressatengerecht mündlich, schriftlich und medial darstellen' AS kurzname, 'Arbeitsergebnisse und Mitteilungsabsichten sach- und adressatengerecht mündlich, schriftlich und medial darstellen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_TMK_11' AS code, 'verschiedene digitale Werkzeuge zur Text- und Medienproduktion, Recherche und Kommunikation reflektiert und…' AS kurzname, 'verschiedene digitale Werkzeuge zur Text- und Medienproduktion, Recherche und Kommunikation reflektiert und zielgerichtet einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_TMK';
-- Zweite Fremdsprache (Zweite Stufe) · Sprachlernkompetenz (7)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_SLK_01' AS code, 'im Vergleich des Französischen mit anderen Sprachen Ähnlichkeiten und Verschiedenheiten entdecken und für das eigene…' AS kurzname, 'im Vergleich des Französischen mit anderen Sprachen Ähnlichkeiten und Verschiedenheiten entdecken und für das eigene Sprachenlernen nutzen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SLK_02' AS code, 'auch komplexere Formen der Wortschatzarbeit einsetzen' AS kurzname, 'auch komplexere Formen der Wortschatzarbeit einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SLK_03' AS code, 'Arbeitsprodukte in Wort und Schrift weitgehend selbstständig überarbeiten und dabei eigene Fehlerschwerpunkte erkennen' AS kurzname, 'Arbeitsprodukte in Wort und Schrift weitgehend selbstständig überarbeiten und dabei eigene Fehlerschwerpunkte erkennen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SLK_04' AS code, 'in Texten auch komplexere grammatische Elemente und Strukturen identifizieren und daraus Regeln ableiten' AS kurzname, 'in Texten auch komplexere grammatische Elemente und Strukturen identifizieren und daraus Regeln ableiten' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SLK_05' AS code, 'unterschiedliche, auch digitale Werkzeuge für das eigene Sprachenlernen reflektiert einsetzen' AS kurzname, 'unterschiedliche, auch digitale Werkzeuge für das eigene Sprachenlernen reflektiert einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SLK_06' AS code, 'Übungs- und Testaufgaben zum selbstgesteuerten systematischen Sprachtraining auch unter Verwendung digitaler Angebote…' AS kurzname, 'Übungs- und Testaufgaben zum selbstgesteuerten systematischen Sprachtraining auch unter Verwendung digitaler Angebote einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SLK_07' AS code, 'den eigenen Lernfortschritt anhand geeigneter, auch digitaler Evaluationsinstrumente einschätzen und dokumentieren' AS kurzname, 'den eigenen Lernfortschritt anhand geeigneter, auch digitaler Evaluationsinstrumente einschätzen und dokumentieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_SLK';
-- Zweite Fremdsprache (Zweite Stufe) · Sprachbewusstheit (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_2FS_S2_SBW_01' AS code, 'semantische und strukturelle Zusammenhänge, sprachliche Regelmäßigkeiten, Normabweichungen und einzelne Varietäten des…' AS kurzname, 'semantische und strukturelle Zusammenhänge, sprachliche Regelmäßigkeiten, Normabweichungen und einzelne Varietäten des Sprachgebrauchs erkennen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SBW_02' AS code, 'Sprachphänomene und sprachliche Entwicklungen vergleichen' AS kurzname, 'Sprachphänomene und sprachliche Entwicklungen vergleichen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SBW_03' AS code, 'Beziehungen zwischen Sprach- und Kulturphänomenen reflektieren' AS kurzname, 'Beziehungen zwischen Sprach- und Kulturphänomenen reflektieren' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SBW_04' AS code, 'die Angemessenheit und Effektivität ihres sprachlichen Ausdrucks beurteilen' AS kurzname, 'die Angemessenheit und Effektivität ihres sprachlichen Ausdrucks beurteilen' AS beschreibung
  UNION ALL
  SELECT 'FR_2FS_S2_SBW_05' AS code, 'ihren Sprachgebrauch entsprechend den Erfordernissen der Kommunikationssituation reflektieren' AS kurzname, 'ihren Sprachgebrauch entsprechend den Erfordernissen der Kommunikationssituation reflektieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_2FS_S2_SBW';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_HOR_01' AS code, 'der mündlichen Kommunikation im Unterricht folgen' AS kurzname, 'der mündlichen Kommunikation im Unterricht folgen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_HOR_02' AS code, 'klar artikulierten auditiv und audiovisuell vermittelten Texten die Gesamtaussage, Hauptaussagen und wichtige…' AS kurzname, 'klar artikulierten auditiv und audiovisuell vermittelten Texten die Gesamtaussage, Hauptaussagen und wichtige Einzelinformationen entnehmen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_HOR_03' AS code, 'Gesprächen zu alltäglichen oder vertrauten Sachverhalten und Themen die Gesamtaussage, Hauptaussagen und wichtige…' AS kurzname, 'Gesprächen zu alltäglichen oder vertrauten Sachverhalten und Themen die Gesamtaussage, Hauptaussagen und wichtige Einzelinformationen entnehmen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_HOR_04' AS code, 'eindeutige Stimmungen und Gefühle der Sprechenden erfassen' AS kurzname, 'eindeutige Stimmungen und Gefühle der Sprechenden erfassen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_HOR';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Leseverstehen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_LES_01' AS code, 'der schriftlichen Kommunikation im Unterricht folgen' AS kurzname, 'der schriftlichen Kommunikation im Unterricht folgen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_LES_02' AS code, 'klar strukturierten Sach- und Gebrauchstexten sowie einfacheren literarischen Texten die Gesamtaussage, Hauptaussagen…' AS kurzname, 'klar strukturierten Sach- und Gebrauchstexten sowie einfacheren literarischen Texten die Gesamtaussage, Hauptaussagen und wichtige Einzelinformationen entnehmen und diese Informationen in den Kontext der Gesamtaussage einordnen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_LES_03' AS code, 'Texte vor dem Hintergrund grundlegender Gattungs- und Gestaltungsmerkmale inhaltlich erfassen' AS kurzname, 'Texte vor dem Hintergrund grundlegender Gattungs- und Gestaltungsmerkmale inhaltlich erfassen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_LES_04' AS code, 'explizite und leicht zugängliche implizite Informationen im Wesentlichen erfassen und in den Kontext der Gesamtaussage…' AS kurzname, 'explizite und leicht zugängliche implizite Informationen im Wesentlichen erfassen und in den Kontext der Gesamtaussage einordnen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_LES';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_SAG_01' AS code, 'im Unterricht Inhalte beschreiben und Abläufe vereinbaren' AS kurzname, 'im Unterricht Inhalte beschreiben und Abläufe vereinbaren' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SAG_02' AS code, 'Ergebnisse von Arbeitsprozessen diskutieren' AS kurzname, 'Ergebnisse von Arbeitsprozessen diskutieren' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SAG_03' AS code, 'in alltäglichen, auch digital gestützten Gesprächssituationen ihre Redeabsichten verwirklichen und angemessen…' AS kurzname, 'in alltäglichen, auch digital gestützten Gesprächssituationen ihre Redeabsichten verwirklichen und angemessen interagieren' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SAG_04' AS code, 'sich in unterschiedlichen Rollen an formalisierten, thematisch vertrauten Gesprächen beteiligen' AS kurzname, 'sich in unterschiedlichen Rollen an formalisierten, thematisch vertrauten Gesprächen beteiligen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SAG_05' AS code, 'auch non- und paraverbale Signale setzen' AS kurzname, 'auch non- und paraverbale Signale setzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_SAG';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_ZUS_01' AS code, 'sich und ihre Lebenswelt beschreiben, Persönlichkeiten vorstellen, von Ereignissen berichten, ihre Mediennutzung sowie…' AS kurzname, 'sich und ihre Lebenswelt beschreiben, Persönlichkeiten vorstellen, von Ereignissen berichten, ihre Mediennutzung sowie ihr Konsumverhalten erklären, Interessen und Standpunkte darstellen und erläutern' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_ZUS_02' AS code, 'mündliche Äußerungen und Inhalte von Texten zusammenfassend vortragen' AS kurzname, 'mündliche Äußerungen und Inhalte von Texten zusammenfassend vortragen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_ZUS_03' AS code, 'sich zu Inhalten von im Unterricht behandelten Texten und Themen zusammenhängend äußern sowie in einfacher Form ihre…' AS kurzname, 'sich zu Inhalten von im Unterricht behandelten Texten und Themen zusammenhängend äußern sowie in einfacher Form ihre Einstellungen und Meinungen dazu begründen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_ZUS_04' AS code, 'Arbeits- und Unterrichtsergebnisse, auch digital gestützt, präsentieren' AS kurzname, 'Arbeits- und Unterrichtsergebnisse, auch digital gestützt, präsentieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_ZUS';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Schreiben (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_SCH_01' AS code, 'Arbeitsergebnisse dokumentieren' AS kurzname, 'Arbeitsergebnisse dokumentieren' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SCH_02' AS code, 'wesentliche Inhalte von klar strukturierten einfacheren fiktionalen Texten sowie von Sach- und Gebrauchstexten…' AS kurzname, 'wesentliche Inhalte von klar strukturierten einfacheren fiktionalen Texten sowie von Sach- und Gebrauchstexten zusammenfassen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SCH_03' AS code, 'unterschiedliche Typen von stärker formalisierten, auch mehrfach kodierten Sach- und Gebrauchstexten in einfacher Form…' AS kurzname, 'unterschiedliche Typen von stärker formalisierten, auch mehrfach kodierten Sach- und Gebrauchstexten in einfacher Form verfassen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SCH_04' AS code, 'in persönlichen Texten ihre Meinungen, Hoffnungen und Einstellungen äußern und Handlungsvorschläge machen' AS kurzname, 'in persönlichen Texten ihre Meinungen, Hoffnungen und Einstellungen äußern und Handlungsvorschläge machen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SCH_05' AS code, 'unter Beachtung grundlegender textsortenspezifischer Merkmale einfache Formen des produktionsorientierten und…' AS kurzname, 'unter Beachtung grundlegender textsortenspezifischer Merkmale einfache Formen des produktionsorientierten und kreativen Schreibens realisieren' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SCH_06' AS code, 'digitale Werkzeuge auch für das kollaborative Schreiben einsetzen' AS kurzname, 'digitale Werkzeuge auch für das kollaborative Schreiben einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_SCH';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Sprachmittlung (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_SPM_01' AS code, 'als Sprachmittelnde in informellen und einfach strukturierten formalisierten Kommunikationssituationen relevante…' AS kurzname, 'als Sprachmittelnde in informellen und einfach strukturierten formalisierten Kommunikationssituationen relevante Aussagen in der jeweiligen Zielsprache, auch unter Nutzung von geeigneten Kompensationsstrategien, situations- und adressatengerecht wiedergeben' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SPM_02' AS code, 'zentrale Informationen aus klar strukturierten mündlichen und schriftlichen Texten situations- und adressatengerecht…' AS kurzname, 'zentrale Informationen aus klar strukturierten mündlichen und schriftlichen Texten situations- und adressatengerecht zusammenfassen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SPM_03' AS code, 'für die Sprachmittlung notwendige Erläuterungen hinzufügen' AS kurzname, 'für die Sprachmittlung notwendige Erläuterungen hinzufügen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SPM_04' AS code, 'bei der Sprachmittlung von Informationen auf eventuelle einfache Nachfragen eingehen' AS kurzname, 'bei der Sprachmittlung von Informationen auf eventuelle einfache Nachfragen eingehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_SPM';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_VSM_WOR_01' AS code, 'einen grundlegenden allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz…' AS kurzname, 'einen grundlegenden allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz produktiv einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_VSM_WOR_02' AS code, 'einen erweiterten allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz…' AS kurzname, 'einen erweiterten allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz rezeptiv einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_VSM_WOR_03' AS code, 'einen grundlegenden Wortschatz zur Textbesprechung einsetzen' AS kurzname, 'einen grundlegenden Wortschatz zur Textbesprechung einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_VSM_WOR_04' AS code, 'einen grundlegenden Wortschatz zur Textproduktion einsetzen' AS kurzname, 'einen grundlegenden Wortschatz zur Textproduktion einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_VSM_WOR';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_VSM_GRA_01' AS code, 'Handlungen, Vorgänge und Äußerungen zeitlich positionieren' AS kurzname, 'Handlungen, Vorgänge und Äußerungen zeitlich positionieren' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_VSM_GRA_02' AS code, 'Annahmen, Hypothesen oder Bedingungen formulieren' AS kurzname, 'Annahmen, Hypothesen oder Bedingungen formulieren' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_VSM_GRA_03' AS code, 'Ge- und Verbote formulieren sowie Gefühle und Meinungen, Aufforderungen und Bitten, Wünsche und Erwartungen äußern' AS kurzname, 'Ge- und Verbote formulieren sowie Gefühle und Meinungen, Aufforderungen und Bitten, Wünsche und Erwartungen äußern' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_VSM_GRA_04' AS code, 'Vergleiche zur Darstellung von Gemeinsamkeiten und Unterschieden anstellen' AS kurzname, 'Vergleiche zur Darstellung von Gemeinsamkeiten und Unterschieden anstellen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_VSM_GRA_05' AS code, 'Texte und mündliche Äußerungen strukturieren' AS kurzname, 'Texte und mündliche Äußerungen strukturieren' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_VSM_GRA_06' AS code, 'Sachverhalte mit temporalen, kausalen, konsekutiven und konditionalen Zusammenhängen formulieren' AS kurzname, 'Sachverhalte mit temporalen, kausalen, konsekutiven und konditionalen Zusammenhängen formulieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_VSM_GRA';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_VSM_AUS_01' AS code, 'auch umfangreichere Texte phonetisch und intonatorisch korrekt vortragen' AS kurzname, 'auch umfangreichere Texte phonetisch und intonatorisch korrekt vortragen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_VSM_AUS_02' AS code, 'beim monologischen und dialogischen Sprechen ein grundlegendes Repertoire typischer Aussprache- und Intonationsmuster…' AS kurzname, 'beim monologischen und dialogischen Sprechen ein grundlegendes Repertoire typischer Aussprache- und Intonationsmuster einsetzen und dabei eine zumeist klare Aussprache und Intonation realisieren' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_VSM_AUS_03' AS code, 'Kenntnisse der Aussprache und Intonation für ihre Hör- und Sprechabsichten einsetzen' AS kurzname, 'Kenntnisse der Aussprache und Intonation für ihre Hör- und Sprechabsichten einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_VSM_AUS';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_VSM_ORT_01' AS code, 'typische orthografische Muster weitgehend korrekt verwenden' AS kurzname, 'typische orthografische Muster weitgehend korrekt verwenden' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_VSM_ORT_02' AS code, 'Kenntnisse grammatischer Strukturen und Regeln für die normgerechte Schreibung einsetzen' AS kurzname, 'Kenntnisse grammatischer Strukturen und Regeln für die normgerechte Schreibung einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_VSM_ORT_03' AS code, 'Grundregeln der französischen Zeichensetzung, die von der deutschen Sprache abweichen, im Wesentlichen korrekt anwenden' AS kurzname, 'Grundregeln der französischen Zeichensetzung, die von der deutschen Sprache abweichen, im Wesentlichen korrekt anwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_VSM_ORT';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_IKK_SOW_01' AS code, 'ein grundlegendes soziokulturelles Orientierungswissen einsetzen' AS kurzname, 'ein grundlegendes soziokulturelles Orientierungswissen einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_IKK_SOW';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_IKK_EIN_01' AS code, 'Phänomene kultureller Vielfalt einordnen und neuen Erfahrungen mit anderen Kulturen grundsätzlich offen begegnen' AS kurzname, 'Phänomene kultureller Vielfalt einordnen und neuen Erfahrungen mit anderen Kulturen grundsätzlich offen begegnen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_IKK_EIN_02' AS code, 'repräsentative Wertvorstellungen und Verhaltensweisen anderer Kulturen mit eigenen Anschauungen vergleichen und dabei…' AS kurzname, 'repräsentative Wertvorstellungen und Verhaltensweisen anderer Kulturen mit eigenen Anschauungen vergleichen und dabei Toleranz entwickeln, sofern Grundprinzipien friedlichen und respektvollen Zusammenlebens nicht verletzt werden' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_IKK_EIN_03' AS code, 'zu ihren eigenen Wahrnehmungen und Einstellungen auch aus Gender-Perspektive kritisch Stellung beziehen' AS kurzname, 'zu ihren eigenen Wahrnehmungen und Einstellungen auch aus Gender-Perspektive kritisch Stellung beziehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_IKK_EIN';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_IKK_VER_01' AS code, 'in formellen wie informellen Begegnungssituationen unter Beachtung kulturspezifischer Konventionen und Besonderheiten…' AS kurzname, 'in formellen wie informellen Begegnungssituationen unter Beachtung kulturspezifischer Konventionen und Besonderheiten kommunikativ angemessen handeln' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_IKK_VER_02' AS code, 'in interkulturellen Handlungssituationen Informationen und Meinungen zu Themen des soziokulturellen…' AS kurzname, 'in interkulturellen Handlungssituationen Informationen und Meinungen zu Themen des soziokulturellen Orientierungswissens austauschen und daraus Handlungsoptionen ableiten' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_IKK_VER_03' AS code, 'sich durch Perspektivwechsel mit kulturell bedingten Denk- und Verhaltensweisen auseinandersetzen und diese auf…' AS kurzname, 'sich durch Perspektivwechsel mit kulturell bedingten Denk- und Verhaltensweisen auseinandersetzen und diese auf Grundlage spezifischer Differenzerfahrungen kritisch prüfen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_IKK_VER';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Text- und Medienkompetenz (11)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_TMK_01' AS code, 'im Rahmen des besprechenden Umgangs mit Texten und Medien Texte und Medienprodukte vor dem Hintergrund des…' AS kurzname, 'im Rahmen des besprechenden Umgangs mit Texten und Medien Texte und Medienprodukte vor dem Hintergrund des kommunikativen und kulturellen Kontextes erschließen, ihnen die Gesamtaussage, Hauptaussagen sowie wichtige Details zu Personen, Handlungen, Ort und Zeit entnehmen, diese mündlich und schriftlich wiedergeben und zusammenfassen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_TMK_02' AS code, 'Texte und Medienprodukte grundlegenden Gattungen zuordnen und wesentliche Strukturelemente an ihnen belegen' AS kurzname, 'Texte und Medienprodukte grundlegenden Gattungen zuordnen und wesentliche Strukturelemente an ihnen belegen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_TMK_03' AS code, 'Aussagen und Wirkungsabsichten bei geläufigen Textsorten und Medienprodukten erläutern' AS kurzname, 'Aussagen und Wirkungsabsichten bei geläufigen Textsorten und Medienprodukten erläutern' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_TMK_04' AS code, 'unter Berücksichtigung des soziokulturellen Orientierungswissens zu den Aussagen der jeweiligen Texte oder…' AS kurzname, 'unter Berücksichtigung des soziokulturellen Orientierungswissens zu den Aussagen der jeweiligen Texte oder Medienprodukte mündlich und schriftlich Stellung beziehen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_TMK_05' AS code, 'im Rahmen des gestaltenden Umgangs mit Texten und Medien in Anlehnung an unterschiedliche Ausgangsformate Texte und…' AS kurzname, 'im Rahmen des gestaltenden Umgangs mit Texten und Medien in Anlehnung an unterschiedliche Ausgangsformate Texte und Medienprodukte des täglichen Gebrauchs erstellen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_TMK_06' AS code, 'Texte und Medienprodukte in andere vertraute Texte oder Medienprodukte umwandeln' AS kurzname, 'Texte und Medienprodukte in andere vertraute Texte oder Medienprodukte umwandeln' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_TMK_07' AS code, 'Texte und Medienprodukte kreativ bearbeiten' AS kurzname, 'Texte und Medienprodukte kreativ bearbeiten' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_TMK_08' AS code, 'einfache audiovisuelle Medienprodukte unter Verwendung digitaler Werkzeuge erstellen' AS kurzname, 'einfache audiovisuelle Medienprodukte unter Verwendung digitaler Werkzeuge erstellen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_TMK_09' AS code, 'im Rahmen des reflektierenden Umgangs mit Texten und Medien unter Berücksichtigung der rechtlichen Grundlagen…' AS kurzname, 'im Rahmen des reflektierenden Umgangs mit Texten und Medien unter Berücksichtigung der rechtlichen Grundlagen vornehmlich vorgegebene Texte und Medienprodukte aufgabenbezogen mündlich, schriftlich und medial auswerten' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_TMK_10' AS code, 'Arbeitsergebnisse und Mitteilungsabsichten sach- und adressatengerecht mündlich, schriftlich und medial darstellen' AS kurzname, 'Arbeitsergebnisse und Mitteilungsabsichten sach- und adressatengerecht mündlich, schriftlich und medial darstellen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_TMK_11' AS code, 'verschiedene digitale Werkzeuge zur Text- und Medienproduktion, Recherche und Kommunikation reflektiert und…' AS kurzname, 'verschiedene digitale Werkzeuge zur Text- und Medienproduktion, Recherche und Kommunikation reflektiert und zielgerichtet einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_TMK';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Sprachlernkompetenz (7)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_SLK_01' AS code, 'im Vergleich des Französischen mit anderen Sprachen Ähnlichkeiten und Verschiedenheiten entdecken und für das eigene…' AS kurzname, 'im Vergleich des Französischen mit anderen Sprachen Ähnlichkeiten und Verschiedenheiten entdecken und für das eigene Sprachenlernen nutzen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SLK_02' AS code, 'auch komplexere Formen der Wortschatzarbeit einsetzen' AS kurzname, 'auch komplexere Formen der Wortschatzarbeit einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SLK_03' AS code, 'Arbeitsprodukte in Wort und Schrift weitgehend selbstständig überarbeiten und dabei eigene Fehlerschwerpunkte erkennen' AS kurzname, 'Arbeitsprodukte in Wort und Schrift weitgehend selbstständig überarbeiten und dabei eigene Fehlerschwerpunkte erkennen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SLK_04' AS code, 'in Texten auch komplexere grammatische Elemente und Strukturen identifizieren und daraus Regeln ableiten' AS kurzname, 'in Texten auch komplexere grammatische Elemente und Strukturen identifizieren und daraus Regeln ableiten' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SLK_05' AS code, 'unterschiedliche, auch digitale Werkzeuge für das eigene Sprachenlernen reflektiert einsetzen' AS kurzname, 'unterschiedliche, auch digitale Werkzeuge für das eigene Sprachenlernen reflektiert einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SLK_06' AS code, 'auch digitale Übungs- und Testaufgaben zum selbstgesteuerten systematischen Sprachtraining einsetzen' AS kurzname, 'auch digitale Übungs- und Testaufgaben zum selbstgesteuerten systematischen Sprachtraining einsetzen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SLK_07' AS code, 'den eigenen Lernfortschritt anhand geeigneter, auch digitaler Evaluationsinstrumente einschätzen und dokumentieren' AS kurzname, 'den eigenen Lernfortschritt anhand geeigneter, auch digitaler Evaluationsinstrumente einschätzen und dokumentieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_SLK';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Sprachbewusstheit (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'FR_3FS_SBW_01' AS code, 'semantische und strukturelle Zusammenhänge, sprachliche Regelmäßigkeiten, Normabweichungen und einzelne Varietäten des…' AS kurzname, 'semantische und strukturelle Zusammenhänge, sprachliche Regelmäßigkeiten, Normabweichungen und einzelne Varietäten des Sprachgebrauchs erkennen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SBW_02' AS code, 'Sprachphänomene und sprachliche Entwicklungen vergleichen' AS kurzname, 'Sprachphänomene und sprachliche Entwicklungen vergleichen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SBW_03' AS code, 'Beziehungen zwischen Sprach- und Kulturphänomenen reflektieren' AS kurzname, 'Beziehungen zwischen Sprach- und Kulturphänomenen reflektieren' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SBW_04' AS code, 'die Angemessenheit und Effektivität ihres sprachlichen Ausdrucks beurteilen' AS kurzname, 'die Angemessenheit und Effektivität ihres sprachlichen Ausdrucks beurteilen' AS beschreibung
  UNION ALL
  SELECT 'FR_3FS_SBW_05' AS code, 'ihren Sprachgebrauch entsprechend den Erfordernissen der Kommunikationssituation reflektieren' AS kurzname, 'ihren Sprachgebrauch entsprechend den Erfordernissen der Kommunikationssituation reflektieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'FR_3FS_SBW';

COMMIT;

-- Kontrolle: erwartet Knoten=60 (davon 48 Blaetter), Kompetenzen=202
