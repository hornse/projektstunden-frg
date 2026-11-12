-- =============================================================================
-- Seed 21: Spanisch – Kernlehrplan Gymnasium Sek I (G9), NRW 2019 (Heft 3416)
--
-- Quelle: docs/curricula/g9_s_klp_3416_2019_06_23.pdf
-- SHA256: 119d7166a93d0c925fcb42ff4edf54ad37dd2aaf1041f571cb5dc60aed77f6d9
-- Erzeugt von: sql/gen/gen_spanisch_klp.py
--
-- NICHT VON HAND AENDERN: Korrekturen gehoeren in den Erzeuger, die Datei
-- wird daraus neu geschrieben (E19).
-- Voraussetzung: Migration 08, 13 und 15 (Baum, Spalte `art`).
-- Idempotent: loescht vorhandenen SPA_KLP-Rahmen und baut ihn neu auf.
--
-- Anlage wie Franzoesisch (E63): Der BILDUNGSGANG ist die Wurzel -- zweite
-- Fremdsprache in zwei Stufen und dritte Fremdsprache. Der Baum ist vier
-- Ebenen tief -- Bildungsgang, Kompetenzbereich, Teilbereich, Unterbereich.
--
-- Kapitel 2.3 (Spanisch ab Jahrgangsstufe 5) hat keinen Zweig: Es
-- verweist auf Kapitel 2.2 und fuehrt keine eigenen Erwartungen.
-- =============================================================================

SET NAMES utf8mb4;
START TRANSACTION;

SET @schule := 1;
SET @fach := (SELECT id FROM faecher WHERE schule_id = @schule AND kuerzel = 'SPA' LIMIT 1);

-- Nur der eigene Rahmen wird geloescht; CASCADE raeumt Bereiche und Kompetenzen.
DELETE FROM kompetenzrahmen WHERE schule_id = @schule AND kuerzel = 'SPA_KLP';

INSERT INTO kompetenzrahmen (schule_id, name, kuerzel, beschreibung, quelle_url, fach_id)
VALUES (@schule, 'Spanisch KLP NRW G9 Sek I (FRG)', 'SPA_KLP', 'Kernlehrplan Spanisch Gymnasium Sekundarstufe I (G9), NRW 2019, Heft 3416', 'docs/curricula/g9_s_klp_3416_2019_06_23.pdf', @fach);
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
(@rahmen, NULL, 'ES_2FS_S1', 'Zweite Fremdsprache (Erste Stufe)', 1, 'erste_stufe', 'bildungsgang'),
(@rahmen, NULL, 'ES_2FS_S2', 'Zweite Fremdsprache (Zweite Stufe)', 21, 'zweite_stufe', 'bildungsgang'),
(@rahmen, NULL, 'ES_3FS', 'Dritte Fremdsprache (Ende der Sekundarstufe I)', 41, 'sek1_uebergreifend', 'bildungsgang');

-- Ebene 2: parent_id ueber den Code des Elternknotens.
INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art)
SELECT @rahmen, p.id, t.code, t.name, t.reihenfolge, t.phase, t.art
FROM (
  SELECT 'ES_2FS_S1_FKK' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz' AS name, 2 AS reihenfolge, 'erste_stufe' AS phase, 'kompetenzbereich' AS art, 'ES_2FS_S1' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_IKK' AS code, 'Zweite Fremdsprache (Erste Stufe) · Interkulturelle kommunikative Kompetenz' AS name, 14 AS reihenfolge, 'erste_stufe' AS phase, 'kompetenzbereich' AS art, 'ES_2FS_S1' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_TMK' AS code, 'Zweite Fremdsprache (Erste Stufe) · Text- und Medienkompetenz' AS name, 18 AS reihenfolge, 'erste_stufe' AS phase, 'kompetenzbereich' AS art, 'ES_2FS_S1' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_SLK' AS code, 'Zweite Fremdsprache (Erste Stufe) · Sprachlernkompetenz' AS name, 19 AS reihenfolge, 'erste_stufe' AS phase, 'kompetenzbereich' AS art, 'ES_2FS_S1' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_SBW' AS code, 'Zweite Fremdsprache (Erste Stufe) · Sprachbewusstheit' AS name, 20 AS reihenfolge, 'erste_stufe' AS phase, 'kompetenzbereich' AS art, 'ES_2FS_S1' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_FKK' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz' AS name, 22 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'ES_2FS_S2' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_IKK' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Interkulturelle kommunikative Kompetenz' AS name, 34 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'ES_2FS_S2' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_TMK' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Text- und Medienkompetenz' AS name, 38 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'ES_2FS_S2' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_SLK' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Sprachlernkompetenz' AS name, 39 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'ES_2FS_S2' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_SBW' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Sprachbewusstheit' AS name, 40 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'ES_2FS_S2' AS pcode
  UNION ALL
  SELECT 'ES_3FS_FKK' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz' AS name, 42 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'kompetenzbereich' AS art, 'ES_3FS' AS pcode
  UNION ALL
  SELECT 'ES_3FS_IKK' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Interkulturelle kommunikative Kompetenz' AS name, 54 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'kompetenzbereich' AS art, 'ES_3FS' AS pcode
  UNION ALL
  SELECT 'ES_3FS_TMK' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Text- und Medienkompetenz' AS name, 58 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'kompetenzbereich' AS art, 'ES_3FS' AS pcode
  UNION ALL
  SELECT 'ES_3FS_SLK' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Sprachlernkompetenz' AS name, 59 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'kompetenzbereich' AS art, 'ES_3FS' AS pcode
  UNION ALL
  SELECT 'ES_3FS_SBW' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Sprachbewusstheit' AS name, 60 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'kompetenzbereich' AS art, 'ES_3FS' AS pcode
) t JOIN kompetenzbereiche p ON p.rahmen_id = @rahmen AND p.code = t.pcode;

-- Ebene 3: parent_id ueber den Code des Elternknotens.
INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art)
SELECT @rahmen, p.id, t.code, t.name, t.reihenfolge, t.phase, t.art
FROM (
  SELECT 'ES_2FS_S1_HOR' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen' AS name, 3 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'ES_2FS_S1_FKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_LES' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Leseverstehen' AS name, 4 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'ES_2FS_S1_FKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_SAG' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen' AS name, 5 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'ES_2FS_S1_FKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_ZUS' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen' AS name, 6 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'ES_2FS_S1_FKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_SCH' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Schreiben' AS name, 7 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'ES_2FS_S1_FKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_SPM' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Sprachmittlung' AS name, 8 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'ES_2FS_S1_FKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_VSM' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel' AS name, 9 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'ES_2FS_S1_FKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_IKK_SOW' AS code, 'Zweite Fremdsprache (Erste Stufe) · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen' AS name, 15 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'ES_2FS_S1_IKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_IKK_EIN' AS code, 'Zweite Fremdsprache (Erste Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit' AS name, 16 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'ES_2FS_S1_IKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_IKK_VER' AS code, 'Zweite Fremdsprache (Erste Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln' AS name, 17 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'ES_2FS_S1_IKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_HOR' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen' AS name, 23 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'ES_2FS_S2_FKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_LES' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Leseverstehen' AS name, 24 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'ES_2FS_S2_FKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_SAG' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen' AS name, 25 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'ES_2FS_S2_FKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_ZUS' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen' AS name, 26 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'ES_2FS_S2_FKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_SCH' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Schreiben' AS name, 27 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'ES_2FS_S2_FKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_SPM' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Sprachmittlung' AS name, 28 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'ES_2FS_S2_FKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_VSM' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel' AS name, 29 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'ES_2FS_S2_FKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_IKK_SOW' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen' AS name, 35 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'ES_2FS_S2_IKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_IKK_EIN' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit' AS name, 36 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'ES_2FS_S2_IKK' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_IKK_VER' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln' AS name, 37 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'ES_2FS_S2_IKK' AS pcode
  UNION ALL
  SELECT 'ES_3FS_HOR' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen' AS name, 43 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'teilbereich' AS art, 'ES_3FS_FKK' AS pcode
  UNION ALL
  SELECT 'ES_3FS_LES' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Leseverstehen' AS name, 44 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'teilbereich' AS art, 'ES_3FS_FKK' AS pcode
  UNION ALL
  SELECT 'ES_3FS_SAG' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen' AS name, 45 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'teilbereich' AS art, 'ES_3FS_FKK' AS pcode
  UNION ALL
  SELECT 'ES_3FS_ZUS' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen' AS name, 46 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'teilbereich' AS art, 'ES_3FS_FKK' AS pcode
  UNION ALL
  SELECT 'ES_3FS_SCH' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Schreiben' AS name, 47 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'teilbereich' AS art, 'ES_3FS_FKK' AS pcode
  UNION ALL
  SELECT 'ES_3FS_SPM' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Sprachmittlung' AS name, 48 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'teilbereich' AS art, 'ES_3FS_FKK' AS pcode
  UNION ALL
  SELECT 'ES_3FS_VSM' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel' AS name, 49 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'teilbereich' AS art, 'ES_3FS_FKK' AS pcode
  UNION ALL
  SELECT 'ES_3FS_IKK_SOW' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen' AS name, 55 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'unterbereich' AS art, 'ES_3FS_IKK' AS pcode
  UNION ALL
  SELECT 'ES_3FS_IKK_EIN' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit' AS name, 56 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'unterbereich' AS art, 'ES_3FS_IKK' AS pcode
  UNION ALL
  SELECT 'ES_3FS_IKK_VER' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln' AS name, 57 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'unterbereich' AS art, 'ES_3FS_IKK' AS pcode
) t JOIN kompetenzbereiche p ON p.rahmen_id = @rahmen AND p.code = t.pcode;

-- Ebene 4: parent_id ueber den Code des Elternknotens.
INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art)
SELECT @rahmen, p.id, t.code, t.name, t.reihenfolge, t.phase, t.art
FROM (
  SELECT 'ES_2FS_S1_VSM_WOR' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz' AS name, 10 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'ES_2FS_S1_VSM' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_VSM_GRA' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik' AS name, 11 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'ES_2FS_S1_VSM' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_VSM_AUS' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation' AS name, 12 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'ES_2FS_S1_VSM' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S1_VSM_ORT' AS code, 'Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie' AS name, 13 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'ES_2FS_S1_VSM' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_VSM_WOR' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz' AS name, 30 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'ES_2FS_S2_VSM' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_VSM_GRA' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik' AS name, 31 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'ES_2FS_S2_VSM' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_VSM_AUS' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation' AS name, 32 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'ES_2FS_S2_VSM' AS pcode
  UNION ALL
  SELECT 'ES_2FS_S2_VSM_ORT' AS code, 'Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie' AS name, 33 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'ES_2FS_S2_VSM' AS pcode
  UNION ALL
  SELECT 'ES_3FS_VSM_WOR' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz' AS name, 50 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'unterbereich' AS art, 'ES_3FS_VSM' AS pcode
  UNION ALL
  SELECT 'ES_3FS_VSM_GRA' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik' AS name, 51 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'unterbereich' AS art, 'ES_3FS_VSM' AS pcode
  UNION ALL
  SELECT 'ES_3FS_VSM_AUS' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation' AS name, 52 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'unterbereich' AS art, 'ES_3FS_VSM' AS pcode
  UNION ALL
  SELECT 'ES_3FS_VSM_ORT' AS code, 'Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie' AS name, 53 AS reihenfolge, 'sek1_uebergreifend' AS phase, 'unterbereich' AS art, 'ES_3FS_VSM' AS pcode
) t JOIN kompetenzbereiche p ON p.rahmen_id = @rahmen AND p.code = t.pcode;

-- --------------------------------------------------------------------------
-- Kompetenzerwartungen (flach, nur an Blaettern)
-- --------------------------------------------------------------------------
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_HOR_01' AS code, 'in unterrichtlicher Kommunikation wesentliche Informationen zum Unterrichtsablauf verstehen und den Beiträgen…' AS kurzname, 'in unterrichtlicher Kommunikation wesentliche Informationen zum Unterrichtsablauf verstehen und den Beiträgen sprachlich weitgehend folgen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_HOR_02' AS code, 'in unmittelbar im unterrichtlichen Kontext erlebter direkter Kommunikation die Sprechenden weitgehend in ihren…' AS kurzname, 'in unmittelbar im unterrichtlichen Kontext erlebter direkter Kommunikation die Sprechenden weitgehend in ihren Gesamtaussagen, Hauptaussagen und Einzelinformationen verstehen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_HOR_03' AS code, 'auditiv und audiovisuell vermittelten Texten die Gesamtaussage, Hauptaussagen und Einzelinformationen entnehmen' AS kurzname, 'auditiv und audiovisuell vermittelten Texten die Gesamtaussage, Hauptaussagen und Einzelinformationen entnehmen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_HOR_04' AS code, 'eindeutige Gefühle der Sprechenden erfassen' AS kurzname, 'eindeutige Gefühle der Sprechenden erfassen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_HOR';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Leseverstehen (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_LES_01' AS code, 'in unterrichtlicher Kommunikation die Arbeitsaufträge und die wesentlichen Informationen zur Unterrichtsorganisation…' AS kurzname, 'in unterrichtlicher Kommunikation die Arbeitsaufträge und die wesentlichen Informationen zur Unterrichtsorganisation verstehen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_LES_02' AS code, 'klar und einfach strukturierten Lesetexten Hauptaussagen sowie leicht zugängliche inhaltliche Details und thematische…' AS kurzname, 'klar und einfach strukturierten Lesetexten Hauptaussagen sowie leicht zugängliche inhaltliche Details und thematische Aspekte entnehmen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_LES';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_SAG_01' AS code, 'aktiv an der unterrichtlichen Kommunikation teilnehmen' AS kurzname, 'aktiv an der unterrichtlichen Kommunikation teilnehmen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_SAG_02' AS code, 'sich in klar definierten und vertrauten Rollen in informellen sowie in formalisierten Gesprächssituationen an…' AS kurzname, 'sich in klar definierten und vertrauten Rollen in informellen sowie in formalisierten Gesprächssituationen an Gesprächen beteiligen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_SAG_03' AS code, 'eigene Interessen benennen und durch einfache Begründungen stützen' AS kurzname, 'eigene Interessen benennen und durch einfache Begründungen stützen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_SAG';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_ZUS_01' AS code, 'konkrete Beschreibungen ihrer Lebenswelt vornehmen und Auskünfte über sich und andere geben' AS kurzname, 'konkrete Beschreibungen ihrer Lebenswelt vornehmen und Auskünfte über sich und andere geben' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_ZUS_02' AS code, 'kürzere Präsentationen, auch digital gestützt, darbieten' AS kurzname, 'kürzere Präsentationen, auch digital gestützt, darbieten' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_ZUS_03' AS code, 'von konkreten Ereignissen, Erlebnissen und Vorhaben berichten' AS kurzname, 'von konkreten Ereignissen, Erlebnissen und Vorhaben berichten' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_ZUS';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Schreiben (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_SCH_01' AS code, 'einfache formalisierte Texte und kurze Texte zum Lebens- und Erfahrungsbereich verfassen' AS kurzname, 'einfache formalisierte Texte und kurze Texte zum Lebens- und Erfahrungsbereich verfassen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_SCH_02' AS code, 'verschiedene, einfache Formen des produktionsorientierten, kreativen Schreibens realisieren' AS kurzname, 'verschiedene, einfache Formen des produktionsorientierten, kreativen Schreibens realisieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_SCH';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Sprachmittlung (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_SPM_01' AS code, 'die relevanten Aussagen situationsangemessen in die jeweilige Zielsprache mündlich und schriftlich sinngemäß übertragen' AS kurzname, 'die relevanten Aussagen situationsangemessen in die jeweilige Zielsprache mündlich und schriftlich sinngemäß übertragen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_SPM_02' AS code, 'auf der Grundlage ihrer bereits vorhandenen interkulturellen Kompetenz Textinformationen weitgehend adressatengerecht…' AS kurzname, 'auf der Grundlage ihrer bereits vorhandenen interkulturellen Kompetenz Textinformationen weitgehend adressatengerecht bündeln und bei Bedarf ergänzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_SPM';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_VSM_WOR_01' AS code, 'einen grundlegenden Wortschatz zur unterrichtlichen Kommunikation anwenden' AS kurzname, 'einen grundlegenden Wortschatz zur unterrichtlichen Kommunikation anwenden' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_VSM_WOR_02' AS code, 'einen grundlegenden allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz…' AS kurzname, 'einen grundlegenden allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz produktiv und rezeptiv anwenden' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_VSM_WOR_03' AS code, 'einen grundlegenden Wortschatz zur Produktion einfach strukturierter, auch digitaler Texte anwenden' AS kurzname, 'einen grundlegenden Wortschatz zur Produktion einfach strukturierter, auch digitaler Texte anwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_VSM_WOR';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_VSM_GRA_01' AS code, 'auf unterschiedlichen zeitlichen Ebenen Aussagen, Fragen, Bitten und Aufforderungen, Vergleiche, Vorschläge und…' AS kurzname, 'auf unterschiedlichen zeitlichen Ebenen Aussagen, Fragen, Bitten und Aufforderungen, Vergleiche, Vorschläge und Verpflichtungen einfach strukturiert formulieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_VSM_GRA';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_VSM_AUS_01' AS code, 'kurze, einfache Sprech- und Lesetexte sinngestaltend und adressatenbezogen vortragen' AS kurzname, 'kurze, einfache Sprech- und Lesetexte sinngestaltend und adressatenbezogen vortragen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_VSM_AUS_02' AS code, 'in sprachlich einfach strukturierten Gesprächssituationen und in kurzen Redebeiträgen Aussprache und Intonation…' AS kurzname, 'in sprachlich einfach strukturierten Gesprächssituationen und in kurzen Redebeiträgen Aussprache und Intonation weitgehend angemessen anwenden' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_VSM_AUS_03' AS code, 'erste Kenntnisse über Aussprache und Intonation beim Hör- und Hörsehverstehen einsetzen' AS kurzname, 'erste Kenntnisse über Aussprache und Intonation beim Hör- und Hörsehverstehen einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_VSM_AUS';
-- Zweite Fremdsprache (Erste Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_VSM_ORT_01' AS code, 'erste Kenntnisse von grundlegenden grammatischen Strukturen und Regeln für die normgerechte Schreibung nutzen' AS kurzname, 'erste Kenntnisse von grundlegenden grammatischen Strukturen und Regeln für die normgerechte Schreibung nutzen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_VSM_ORT_02' AS code, 'Grundregeln der spanischen Zeichensetzung weitgehend korrekt anwenden' AS kurzname, 'Grundregeln der spanischen Zeichensetzung weitgehend korrekt anwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_VSM_ORT';
-- Zweite Fremdsprache (Erste Stufe) · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_IKK_SOW_01' AS code, 'ein noch begrenztes soziokulturelles Orientierungswissen in interkulturell geprägten Kommunikationssituationen anwenden' AS kurzname, 'ein noch begrenztes soziokulturelles Orientierungswissen in interkulturell geprägten Kommunikationssituationen anwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_IKK_SOW';
-- Zweite Fremdsprache (Erste Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_IKK_EIN_01' AS code, 'die gewonnenen kulturspezifischen Einblicke in die spanischsprachige Lebenswelt mit der eigenen Lebenswirklichkeit…' AS kurzname, 'die gewonnenen kulturspezifischen Einblicke in die spanischsprachige Lebenswelt mit der eigenen Lebenswirklichkeit vergleichen, Gemeinsamkeiten und Unterschiede entdecken und ihr interkulturelles Verständnis erweitern' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_IKK_EIN';
-- Zweite Fremdsprache (Erste Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_IKK_VER_01' AS code, 'in einfachen, simulierten zielsprachigen Begegnungssituationen mit kulturspezifischen Konventionen und Besonderheiten…' AS kurzname, 'in einfachen, simulierten zielsprachigen Begegnungssituationen mit kulturspezifischen Konventionen und Besonderheiten weitgehend angemessen umgehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_IKK_VER';
-- Zweite Fremdsprache (Erste Stufe) · Text- und Medienkompetenz (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_TMK_01' AS code, 'aus einfach strukturierten Texten wesentliche Informationen zu Themen, Handlungen und Personen entnehmen und diese…' AS kurzname, 'aus einfach strukturierten Texten wesentliche Informationen zu Themen, Handlungen und Personen entnehmen und diese mündlich und schriftlich, auch digital unterstützt wiedergeben' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_TMK_02' AS code, 'zu Textaussagen eigene, sprachlich einfach strukturierte persönliche Stellungnahmen mündlich und schriftlich formulieren' AS kurzname, 'zu Textaussagen eigene, sprachlich einfach strukturierte persönliche Stellungnahmen mündlich und schriftlich formulieren' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_TMK_03' AS code, 'kurze, produktionsorientierte oder kreative Texte zum persönlichen Lebensumfeld, auch digital, erstellen, umformen und…' AS kurzname, 'kurze, produktionsorientierte oder kreative Texte zum persönlichen Lebensumfeld, auch digital, erstellen, umformen und ergänzen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_TMK_04' AS code, 'bei der Erstellung von Medienprodukten die zentralen rechtlichen Grundlagen des Persönlichkeits-, Urheber- und…' AS kurzname, 'bei der Erstellung von Medienprodukten die zentralen rechtlichen Grundlagen des Persönlichkeits-, Urheber- und Nutzungsrechts beachten' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_TMK_05' AS code, 'sozial verantwortungsvoll mit eigenen und fremden, auch digital erstellten Produkten umgehen' AS kurzname, 'sozial verantwortungsvoll mit eigenen und fremden, auch digital erstellten Produkten umgehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_TMK';
-- Zweite Fremdsprache (Erste Stufe) · Sprachlernkompetenz (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_SLK_01' AS code, 'bedarfsgerecht und weitgehend kritisch reflektierend unterschiedliche Arbeits- und Hilfsmittel in Printversion und als…' AS kurzname, 'bedarfsgerecht und weitgehend kritisch reflektierend unterschiedliche Arbeits- und Hilfsmittel in Printversion und als digitales Werkzeug zur Texterschließung, Texterstellung und Selbstkorrektur nutzen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_SLK_02' AS code, 'ihren Lernprozess beobachten und planen sowie den Grad ihrer eigenen Sprachbeherrschung, auch im Hinblick auf die…' AS kurzname, 'ihren Lernprozess beobachten und planen sowie den Grad ihrer eigenen Sprachbeherrschung, auch im Hinblick auf die Nutzung digitaler Hilfsmittel, weitgehend treffend einschätzen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_SLK_03' AS code, 'die Bearbeitung von Aufgaben weitgehend selbstständig und mittels individueller sowie kollaborativer Arbeitsformen des…' AS kurzname, 'die Bearbeitung von Aufgaben weitgehend selbstständig und mittels individueller sowie kollaborativer Arbeitsformen des Sprachenlernens planen, durchführen und dabei mit auftretenden Schwierigkeiten ergebnisorientiert umgehen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_SLK_04' AS code, 'kontinuierlich eigene Fehlerschwerpunkte bearbeiten, Anregungen von anderen kritisch aufnehmen und Schlussfolgerungen…' AS kurzname, 'kontinuierlich eigene Fehlerschwerpunkte bearbeiten, Anregungen von anderen kritisch aufnehmen und Schlussfolgerungen für ihr eigenes Sprachenlernen ziehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_SLK';
-- Zweite Fremdsprache (Erste Stufe) · Sprachbewusstheit (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S1_SBW_01' AS code, 'grundlegende sprachliche Regelmäßigkeiten des Sprachgebrauchs benennen' AS kurzname, 'grundlegende sprachliche Regelmäßigkeiten des Sprachgebrauchs benennen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_SBW_02' AS code, 'einfach strukturierte Beziehungen zwischen Sprach- und Kulturphänomenen aufzeigen' AS kurzname, 'einfach strukturierte Beziehungen zwischen Sprach- und Kulturphänomenen aufzeigen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_SBW_03' AS code, 'im Sprachvergleich der Zielsprache mit anderen Sprachen grundlegende Ähnlichkeiten und Verschiedenheiten aufzeigen' AS kurzname, 'im Sprachvergleich der Zielsprache mit anderen Sprachen grundlegende Ähnlichkeiten und Verschiedenheiten aufzeigen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S1_SBW_04' AS code, 'das eigene und fremde Kommunikationsverhalten im Hinblick auf Kommunikationserfolge und -probleme beobachten und…' AS kurzname, 'das eigene und fremde Kommunikationsverhalten im Hinblick auf Kommunikationserfolge und -probleme beobachten und ansatzweise kritisch-konstruktiv reflektieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S1_SBW';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_HOR_01' AS code, 'in unterrichtlicher Kommunikation die Informationen zum Unterrichtsablauf verstehen und den Beiträgen folgen' AS kurzname, 'in unterrichtlicher Kommunikation die Informationen zum Unterrichtsablauf verstehen und den Beiträgen folgen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_HOR_02' AS code, 'in unmittelbar im unterrichtlichen Kontext erlebter direkter Kommunikation die Sprechenden in der Regel in ihren…' AS kurzname, 'in unmittelbar im unterrichtlichen Kontext erlebter direkter Kommunikation die Sprechenden in der Regel in ihren Gesamtaussagen, Hauptaussagen und Einzelinformationen verstehen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_HOR_03' AS code, 'auditiv und audiovisuell vermittelten Texten die Gesamtaussage, Hauptaussagen und Einzelinformationen entnehmen' AS kurzname, 'auditiv und audiovisuell vermittelten Texten die Gesamtaussage, Hauptaussagen und Einzelinformationen entnehmen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_HOR';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Leseverstehen (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_LES_01' AS code, 'in unterrichtlicher Kommunikation die Arbeitsaufträge und die Informationen zur Unterrichtsorganisation verstehen' AS kurzname, 'in unterrichtlicher Kommunikation die Arbeitsaufträge und die Informationen zur Unterrichtsorganisation verstehen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_LES_02' AS code, 'längeren, klar strukturierten Lesetexten Hauptaussagen, leicht zugängliche inhaltliche Details und thematische Aspekte…' AS kurzname, 'längeren, klar strukturierten Lesetexten Hauptaussagen, leicht zugängliche inhaltliche Details und thematische Aspekte entnehmen und diese in den Kontext der Gesamtaussage einordnen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_LES_03' AS code, 'auch digitale und mehrfach kodierte Texte vor dem Hintergrund elementarer Gestaltungsmerkmale inhaltlich erfassen und…' AS kurzname, 'auch digitale und mehrfach kodierte Texte vor dem Hintergrund elementarer Gestaltungsmerkmale inhaltlich erfassen und diese in den Kontext der Gesamtaussage einordnen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_LES';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_SAG_01' AS code, 'aktiv an der unterrichtlichen Kommunikation teilnehmen' AS kurzname, 'aktiv an der unterrichtlichen Kommunikation teilnehmen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_SAG_02' AS code, 'sich in unterschiedlichen Rollen in informellen sowie in formalisierten, auch digital gestützten Gesprächssituationen…' AS kurzname, 'sich in unterschiedlichen Rollen in informellen sowie in formalisierten, auch digital gestützten Gesprächssituationen auch spontan an Gesprächen beteiligen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_SAG_03' AS code, 'eigene Interessen benennen und begründen' AS kurzname, 'eigene Interessen benennen und begründen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_SAG';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_ZUS_01' AS code, 'Beschreibungen ihrer Lebenswelt vornehmen und Auskünfte über sich und andere geben' AS kurzname, 'Beschreibungen ihrer Lebenswelt vornehmen und Auskünfte über sich und andere geben' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_ZUS_02' AS code, 'Präsentationen, auch digital gestützt, darbieten' AS kurzname, 'Präsentationen, auch digital gestützt, darbieten' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_ZUS_03' AS code, 'von Erfahrungen, Erlebnissen, Ereignissen und Vorhaben berichten' AS kurzname, 'von Erfahrungen, Erlebnissen, Ereignissen und Vorhaben berichten' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_ZUS_04' AS code, 'eigene und fremde Meinungen darlegen und konkret begründen' AS kurzname, 'eigene und fremde Meinungen darlegen und konkret begründen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_ZUS';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Schreiben (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_SCH_01' AS code, 'formalisierte Texte und Texte zum Lebens- und Erfahrungsbereich, auch in Form mehrfach kodierter Texte, verfassen' AS kurzname, 'formalisierte Texte und Texte zum Lebens- und Erfahrungsbereich, auch in Form mehrfach kodierter Texte, verfassen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_SCH_02' AS code, 'verschiedene Formen des produktionsorientierten, kreativen Schreibens realisieren' AS kurzname, 'verschiedene Formen des produktionsorientierten, kreativen Schreibens realisieren' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_SCH_03' AS code, 'in zusammenhängender Form wichtige Informationen aus Texten wiedergeben, bündeln und bewerten' AS kurzname, 'in zusammenhängender Form wichtige Informationen aus Texten wiedergeben, bündeln und bewerten' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_SCH_04' AS code, 'digitale Werkzeuge auch für das kollaborative Schreiben nutzen' AS kurzname, 'digitale Werkzeuge auch für das kollaborative Schreiben nutzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_SCH';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Sprachmittlung (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_SPM_01' AS code, 'die relevanten Aussagen situationsangemessen in die jeweilige Zielsprache mündlich und schriftlich sinngemäß übertragen' AS kurzname, 'die relevanten Aussagen situationsangemessen in die jeweilige Zielsprache mündlich und schriftlich sinngemäß übertragen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_SPM_02' AS code, 'auf der Grundlage ihrer bereits vorhandenen interkulturellen Kompetenz Textinformationen adressatengerecht bündeln und…' AS kurzname, 'auf der Grundlage ihrer bereits vorhandenen interkulturellen Kompetenz Textinformationen adressatengerecht bündeln und bei Bedarf ergänzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_SPM';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_VSM_WOR_01' AS code, 'einen breiteren Wortschatz zur unterrichtlichen Kommunikation anwenden' AS kurzname, 'einen breiteren Wortschatz zur unterrichtlichen Kommunikation anwenden' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_VSM_WOR_02' AS code, 'einen grundlegenden allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz…' AS kurzname, 'einen grundlegenden allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz produktiv anwenden' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_VSM_WOR_03' AS code, 'einen erweiterten allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz…' AS kurzname, 'einen erweiterten allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz rezeptiv anwenden' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_VSM_WOR_04' AS code, 'einen grundlegenden Wortschatz zur Textbesprechung anwenden' AS kurzname, 'einen grundlegenden Wortschatz zur Textbesprechung anwenden' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_VSM_WOR_05' AS code, 'einen grundlegenden Wortschatz zur Produktion längerer, zusammenhängender, auch digitaler Texte anwenden' AS kurzname, 'einen grundlegenden Wortschatz zur Produktion längerer, zusammenhängender, auch digitaler Texte anwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_VSM_WOR';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_VSM_GRA_01' AS code, 'auf unterschiedlichen zeitlichen Ebenen Aussagen, Fragen, Bitten und Aufforderungen, Vergleiche, Vorschläge und…' AS kurzname, 'auf unterschiedlichen zeitlichen Ebenen Aussagen, Fragen, Bitten und Aufforderungen, Vergleiche, Vorschläge und Verpflichtungen, Annahmen, Hypothesen oder Bedingungen, Gefühle, Wünsche sowie Erwartungen angemessen differenziert formulieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_VSM_GRA';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_VSM_AUS_01' AS code, 'auch umfangreichere Sprech- und Lesetexte sinngestaltend und adressatenbezogen vortragen' AS kurzname, 'auch umfangreichere Sprech- und Lesetexte sinngestaltend und adressatenbezogen vortragen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_VSM_AUS_02' AS code, 'auch in authentischen Gesprächssituationen und weitgehend freier Rede Aussprache und Intonation angemessen anwenden' AS kurzname, 'auch in authentischen Gesprächssituationen und weitgehend freier Rede Aussprache und Intonation angemessen anwenden' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_VSM_AUS_03' AS code, 'ihre Kenntnisse über Aussprache und Intonation beim Hör- und Hörsehverstehen einsetzen' AS kurzname, 'ihre Kenntnisse über Aussprache und Intonation beim Hör- und Hörsehverstehen einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_VSM_AUS';
-- Zweite Fremdsprache (Zweite Stufe) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_VSM_ORT_01' AS code, 'die Kenntnis von grammatischen Strukturen und Regeln für die normgerechte Schreibung nutzen' AS kurzname, 'die Kenntnis von grammatischen Strukturen und Regeln für die normgerechte Schreibung nutzen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_VSM_ORT_02' AS code, 'Grundregeln der spanischen Zeichensetzung, auch in Abgrenzung zur deutschen Sprache und im digitalen Schriftverkehr,…' AS kurzname, 'Grundregeln der spanischen Zeichensetzung, auch in Abgrenzung zur deutschen Sprache und im digitalen Schriftverkehr, in der Regel korrekt anwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_VSM_ORT';
-- Zweite Fremdsprache (Zweite Stufe) · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_IKK_SOW_01' AS code, 'ein grundlegendes soziokulturelles Orientierungswissen in interkulturell geprägten Kommunikationssituationen anwenden' AS kurzname, 'ein grundlegendes soziokulturelles Orientierungswissen in interkulturell geprägten Kommunikationssituationen anwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_IKK_SOW';
-- Zweite Fremdsprache (Zweite Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_IKK_EIN_01' AS code, 'die gewonnenen kulturspezifischen Einblicke in die spanischsprachige Lebenswelt mit der eigenen Lebenswirklichkeit…' AS kurzname, 'die gewonnenen kulturspezifischen Einblicke in die spanischsprachige Lebenswelt mit der eigenen Lebenswirklichkeit vergleichen, Gemeinsamkeiten entdecken, Stereotype und Unterschiede hinterfragen, einen Perspektivwechsel vollziehen und ein differenzierteres interkulturelles Verständnis entwickeln' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_IKK_EIN';
-- Zweite Fremdsprache (Zweite Stufe) · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_IKK_VER_01' AS code, 'in zielsprachigen Begegnungssituationen kulturspezifischen Konventionen und Besonderheiten respektvoll, tolerant und…' AS kurzname, 'in zielsprachigen Begegnungssituationen kulturspezifischen Konventionen und Besonderheiten respektvoll, tolerant und geschlechtersensibel begegnen, hierzu Stellung beziehen und ihr Handeln in der Regel angemessen darauf einstellen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_IKK_VER_02' AS code, 'in der passiven Sprachverwendung regionalismos und hispanoamerikanische Varietäten der Zielsprache verstehen' AS kurzname, 'in der passiven Sprachverwendung regionalismos und hispanoamerikanische Varietäten der Zielsprache verstehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_IKK_VER';
-- Zweite Fremdsprache (Zweite Stufe) · Text- und Medienkompetenz (8)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_TMK_01' AS code, 'aus Texten die Gesamtaussage, Hauptaussagen und relevante Details und leicht zugängliche implizite Informationen zu…' AS kurzname, 'aus Texten die Gesamtaussage, Hauptaussagen und relevante Details und leicht zugängliche implizite Informationen zu Themen, Handlungsverlauf, Personen und Figuren entnehmen und mündlich und schriftlich, auch digital unterstützt wiedergeben' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_TMK_02' AS code, 'auffällige sprachlich-stilistische Gestaltungsmittel und deren Wirkungsabsichten von Texten und Medienprodukten…' AS kurzname, 'auffällige sprachlich-stilistische Gestaltungsmittel und deren Wirkungsabsichten von Texten und Medienprodukten herausarbeiten und kritisch reflektieren' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_TMK_03' AS code, 'sich mit den Perspektiven und Handlungsmustern von Figuren auseinandersetzen und einen Perspektivwechsel vollziehen' AS kurzname, 'sich mit den Perspektiven und Handlungsmustern von Figuren auseinandersetzen und einen Perspektivwechsel vollziehen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_TMK_04' AS code, 'zu Textaussagen persönliche Eindrücke und Gefühle sowie eigene Perspektiven und persönliche Stellungnahmen mündlich…' AS kurzname, 'zu Textaussagen persönliche Eindrücke und Gefühle sowie eigene Perspektiven und persönliche Stellungnahmen mündlich und schriftlich formulieren' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_TMK_05' AS code, 'unterschiedliche mediale Quellen für eigene Informationsrecherchen nutzen sowie gewonnene Informationen kritisch und…' AS kurzname, 'unterschiedliche mediale Quellen für eigene Informationsrecherchen nutzen sowie gewonnene Informationen kritisch und zielentsprechend einsetzen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_TMK_06' AS code, 'produktionsorientierte oder kreative Texte zum persönlichen Lebensumfeld, auch digital, erstellen, umformen und ergänzen' AS kurzname, 'produktionsorientierte oder kreative Texte zum persönlichen Lebensumfeld, auch digital, erstellen, umformen und ergänzen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_TMK_07' AS code, 'bei der Erstellung von Medienprodukten die rechtlichen Grundlagen des Persönlichkeits-, Urheber- und Nutzungsrechts…' AS kurzname, 'bei der Erstellung von Medienprodukten die rechtlichen Grundlagen des Persönlichkeits-, Urheber- und Nutzungsrechts beachten' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_TMK_08' AS code, 'sozial verantwortungsvoll und kritisch reflektierend mit eigenen und fremden, auch digital erstellten Produkten umgehen' AS kurzname, 'sozial verantwortungsvoll und kritisch reflektierend mit eigenen und fremden, auch digital erstellten Produkten umgehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_TMK';
-- Zweite Fremdsprache (Zweite Stufe) · Sprachlernkompetenz (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_SLK_01' AS code, 'auf der Grundlage ihres individuellen Mehrsprachigkeitsprofils durch Erproben sprachlicher Mittel und kommunikativer…' AS kurzname, 'auf der Grundlage ihres individuellen Mehrsprachigkeitsprofils durch Erproben sprachlicher Mittel und kommunikativer Strategien die eigene Sprachkompetenz festigen und erweitern' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_SLK_02' AS code, 'bedarfsgerecht und kritisch reflektierend unterschiedliche Arbeits- und Hilfsmittel in Printversion und als digitales…' AS kurzname, 'bedarfsgerecht und kritisch reflektierend unterschiedliche Arbeits- und Hilfsmittel in Printversion und als digitales Werkzeug zur Texterschließung, Texterstellung und Selbstkorrektur nutzen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_SLK_03' AS code, 'ihren Lernprozess beobachten und planen sowie den Grad ihrer eigenen Sprachbeherrschung, auch im Hinblick auf den…' AS kurzname, 'ihren Lernprozess beobachten und planen sowie den Grad ihrer eigenen Sprachbeherrschung, auch im Hinblick auf den Einsatz von digitalen Hilfsmitteln, in der Regel treffend einschätzen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_SLK_04' AS code, 'die Bearbeitung von Aufgaben selbstständig und mittels individueller sowie kollaborativer Arbeitsformen des…' AS kurzname, 'die Bearbeitung von Aufgaben selbstständig und mittels individueller sowie kollaborativer Arbeitsformen des Sprachenlernens planen, durchführen und dabei mit auftretenden Schwierigkeiten ergebnisorientiert umgehen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_SLK_05' AS code, 'kontinuierlich eigene Fehlerschwerpunkte bearbeiten, Anregungen von anderen kritisch aufnehmen und Schlussfolgerungen…' AS kurzname, 'kontinuierlich eigene Fehlerschwerpunkte bearbeiten, Anregungen von anderen kritisch aufnehmen und Schlussfolgerungen für ihr eigenes Sprachenlernen ziehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_SLK';
-- Zweite Fremdsprache (Zweite Stufe) · Sprachbewusstheit (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_2FS_S2_SBW_01' AS code, 'sprachliche Regelmäßigkeiten, unterschiedliche Register und Normabweichungen des Sprachgebrauchs benennen' AS kurzname, 'sprachliche Regelmäßigkeiten, unterschiedliche Register und Normabweichungen des Sprachgebrauchs benennen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_SBW_02' AS code, 'Beziehungen zwischen Sprach- und Kulturphänomenen aufzeigen und reflektieren' AS kurzname, 'Beziehungen zwischen Sprach- und Kulturphänomenen aufzeigen und reflektieren' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_SBW_03' AS code, 'im Sprachvergleich der Zielsprache mit anderen Sprachen Ähnlichkeiten und Verschiedenheiten aufzeigen' AS kurzname, 'im Sprachvergleich der Zielsprache mit anderen Sprachen Ähnlichkeiten und Verschiedenheiten aufzeigen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_SBW_04' AS code, 'im Sprachvergleich der Zielsprache mit zielsprachigen Varietäten grundlegende Verschiedenheiten benennen' AS kurzname, 'im Sprachvergleich der Zielsprache mit zielsprachigen Varietäten grundlegende Verschiedenheiten benennen' AS beschreibung
  UNION ALL
  SELECT 'ES_2FS_S2_SBW_05' AS code, 'das eigene und fremde Kommunikationsverhalten im Hinblick auf Kommunikationserfolge und -probleme beobachten und deren…' AS kurzname, 'das eigene und fremde Kommunikationsverhalten im Hinblick auf Kommunikationserfolge und -probleme beobachten und deren Lösung kritisch-konstruktiv reflektieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_2FS_S2_SBW';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_HOR_01' AS code, 'in unterrichtlicher Kommunikation die Informationen zum Unterrichtsablauf verstehen und den Beiträgen folgen' AS kurzname, 'in unterrichtlicher Kommunikation die Informationen zum Unterrichtsablauf verstehen und den Beiträgen folgen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_HOR_02' AS code, 'in unmittelbar im unterrichtlichen Kontext erlebter direkter Kommunikation die Sprechenden in der Regel in ihren…' AS kurzname, 'in unmittelbar im unterrichtlichen Kontext erlebter direkter Kommunikation die Sprechenden in der Regel in ihren Gesamtaussagen, Hauptaussagen und Einzelinformationen verstehen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_HOR_03' AS code, 'auditiv und audiovisuell vermittelten Texten die Gesamtaussage, Hauptaussagen und Einzelinformationen entnehmen' AS kurzname, 'auditiv und audiovisuell vermittelten Texten die Gesamtaussage, Hauptaussagen und Einzelinformationen entnehmen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_HOR';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Leseverstehen (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_LES_01' AS code, 'in unterrichtlicher Kommunikation die Arbeitsaufträge und die Informationen zur Unterrichtsorganisation verstehen' AS kurzname, 'in unterrichtlicher Kommunikation die Arbeitsaufträge und die Informationen zur Unterrichtsorganisation verstehen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_LES_02' AS code, 'klar strukturierten Lesetexten Hauptaussagen, leicht zugängliche inhaltliche Details und thematische Aspekte entnehmen…' AS kurzname, 'klar strukturierten Lesetexten Hauptaussagen, leicht zugängliche inhaltliche Details und thematische Aspekte entnehmen und diese in den Kontext der Gesamtaussage einordnen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_LES_03' AS code, 'auch digitale und mehrfach kodierte Texte vor dem Hintergrund elementarer Gestaltungsmerkmale inhaltlich erfassen' AS kurzname, 'auch digitale und mehrfach kodierte Texte vor dem Hintergrund elementarer Gestaltungsmerkmale inhaltlich erfassen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_LES';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_SAG_01' AS code, 'aktiv an der unterrichtlichen Kommunikation teilnehmen' AS kurzname, 'aktiv an der unterrichtlichen Kommunikation teilnehmen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_SAG_02' AS code, 'sich in unterschiedlichen Rollen in informellen sowie in formalisierten, auch digital gestützten Gesprächssituationen…' AS kurzname, 'sich in unterschiedlichen Rollen in informellen sowie in formalisierten, auch digital gestützten Gesprächssituationen an Gesprächen beteiligen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_SAG_03' AS code, 'eigene Interessen benennen und begründen' AS kurzname, 'eigene Interessen benennen und begründen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_SAG';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_ZUS_01' AS code, 'Beschreibungen ihrer Lebenswelt vornehmen und Auskünfte über sich und andere geben' AS kurzname, 'Beschreibungen ihrer Lebenswelt vornehmen und Auskünfte über sich und andere geben' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_ZUS_02' AS code, 'kurze Präsentationen, auch digital gestützt, darbieten' AS kurzname, 'kurze Präsentationen, auch digital gestützt, darbieten' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_ZUS_03' AS code, 'von Erfahrungen, Erlebnissen, Ereignissen und Vorhaben berichten' AS kurzname, 'von Erfahrungen, Erlebnissen, Ereignissen und Vorhaben berichten' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_ZUS_04' AS code, 'eigene und fremde Meinungen darlegen und konkret begründen' AS kurzname, 'eigene und fremde Meinungen darlegen und konkret begründen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_ZUS';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Schreiben (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_SCH_01' AS code, 'formalisierte Texte und Texte zum Lebens- und Erfahrungsbereich, auch in Form mehrfach kodierter Texte, verfassen' AS kurzname, 'formalisierte Texte und Texte zum Lebens- und Erfahrungsbereich, auch in Form mehrfach kodierter Texte, verfassen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_SCH_02' AS code, 'verschiedene Formen des produktionsorientierten, kreativen Schreibens realisieren' AS kurzname, 'verschiedene Formen des produktionsorientierten, kreativen Schreibens realisieren' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_SCH_03' AS code, 'wichtige Informationen aus Texten wiedergeben und im Rahmen kurzer Stellungnahmen bewerten' AS kurzname, 'wichtige Informationen aus Texten wiedergeben und im Rahmen kurzer Stellungnahmen bewerten' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_SCH_04' AS code, 'digitale Werkzeuge auch für das kollaborative Schreiben nutzen' AS kurzname, 'digitale Werkzeuge auch für das kollaborative Schreiben nutzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_SCH';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Sprachmittlung (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_SPM_01' AS code, 'die relevanten Aussagen situationsangemessen in die jeweilige Zielsprache mündlich und schriftlich sinngemäß übertragen' AS kurzname, 'die relevanten Aussagen situationsangemessen in die jeweilige Zielsprache mündlich und schriftlich sinngemäß übertragen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_SPM_02' AS code, 'auf der Grundlage ihrer bereits vorhandenen interkulturellen Kompetenz Textinformationen adressatengerecht bündeln und…' AS kurzname, 'auf der Grundlage ihrer bereits vorhandenen interkulturellen Kompetenz Textinformationen adressatengerecht bündeln und bei Bedarf ergänzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_SPM';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_VSM_WOR_01' AS code, 'einen breiteren Wortschatz zur unterrichtlichen Kommunikation anwenden' AS kurzname, 'einen breiteren Wortschatz zur unterrichtlichen Kommunikation anwenden' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_VSM_WOR_02' AS code, 'einen grundlegenden allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz…' AS kurzname, 'einen grundlegenden allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz produktiv anwenden' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_VSM_WOR_03' AS code, 'einen erweiterten allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz…' AS kurzname, 'einen erweiterten allgemeinen und auf das soziokulturelle Orientierungswissen bezogenen thematischen Wortschatz rezeptiv anwenden' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_VSM_WOR_04' AS code, 'einen grundlegenden Wortschatz zur Textbesprechung anwenden' AS kurzname, 'einen grundlegenden Wortschatz zur Textbesprechung anwenden' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_VSM_WOR_05' AS code, 'einen grundlegenden Wortschatz zur Produktion längerer, zusammenhängender, auch digitaler Texte anwenden' AS kurzname, 'einen grundlegenden Wortschatz zur Produktion längerer, zusammenhängender, auch digitaler Texte anwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_VSM_WOR';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_VSM_GRA_01' AS code, 'auf unterschiedlichen zeitlichen Ebenen Aussagen, Fragen, Bitten und Aufforderungen, Vergleiche, Vorschläge und…' AS kurzname, 'auf unterschiedlichen zeitlichen Ebenen Aussagen, Fragen, Bitten und Aufforderungen, Vergleiche, Vorschläge und Verpflichtungen, Annahmen, Hypothesen oder Bedingungen, Gefühle, Wünsche sowie Erwartungen angemessen differenziert formulieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_VSM_GRA';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_VSM_AUS_01' AS code, 'Sprech- und Lesetexte sinngestaltend und adressatenbezogen vortragen' AS kurzname, 'Sprech- und Lesetexte sinngestaltend und adressatenbezogen vortragen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_VSM_AUS_02' AS code, 'in sprachlich klar strukturierten Gesprächssituationen und in Redebeiträgen Aussprache und Intonation angemessen…' AS kurzname, 'in sprachlich klar strukturierten Gesprächssituationen und in Redebeiträgen Aussprache und Intonation angemessen anwenden' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_VSM_AUS_03' AS code, 'ihre Kenntnisse über Aussprache und Intonation beim Hör- und Hörsehverstehen einsetzen' AS kurzname, 'ihre Kenntnisse über Aussprache und Intonation beim Hör- und Hörsehverstehen einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_VSM_AUS';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_VSM_ORT_01' AS code, 'die Kenntnis von grammatischen Strukturen und Regeln für die normgerechte Schreibung nutzen' AS kurzname, 'die Kenntnis von grammatischen Strukturen und Regeln für die normgerechte Schreibung nutzen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_VSM_ORT_02' AS code, 'Grundregeln der spanischen Zeichensetzung in der Regel korrekt anwenden' AS kurzname, 'Grundregeln der spanischen Zeichensetzung in der Regel korrekt anwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_VSM_ORT';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_IKK_SOW_01' AS code, 'ein grundlegendes soziokulturelles Orientierungswissen in interkulturell geprägten Kommunikationssituationen anwenden' AS kurzname, 'ein grundlegendes soziokulturelles Orientierungswissen in interkulturell geprägten Kommunikationssituationen anwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_IKK_SOW';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_IKK_EIN_01' AS code, 'die gewonnenen kulturspezifischen Einblicke in die spanischsprachige Lebenswelt mit der eigenen Lebenswirklichkeit…' AS kurzname, 'die gewonnenen kulturspezifischen Einblicke in die spanischsprachige Lebenswelt mit der eigenen Lebenswirklichkeit vergleichen, Gemeinsamkeiten entdecken, Stereotype und Unterschiede hinterfragen, einen Perspektivwechsel vollziehen und ein differenzierteres interkulturelles Verständnis entwickeln' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_IKK_EIN';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_IKK_VER_01' AS code, 'in zielsprachigen Begegnungssituationen kulturspezifischen Konventionen und Besonderheiten respektvoll, tolerant und…' AS kurzname, 'in zielsprachigen Begegnungssituationen kulturspezifischen Konventionen und Besonderheiten respektvoll, tolerant und geschlechtersensibel begegnen, hierzu Stellung beziehen und ihr Handeln in der Regel angemessen darauf einstellen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_IKK_VER_02' AS code, 'in der passiven Sprachverwendung regionalismos und hispanoamerikanische Varietäten der Zielsprache verstehen' AS kurzname, 'in der passiven Sprachverwendung regionalismos und hispanoamerikanische Varietäten der Zielsprache verstehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_IKK_VER';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Text- und Medienkompetenz (7)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_TMK_01' AS code, 'aus Texten die Gesamtaussage, Hauptaussagen und relevante Details zu Themen, Handlungsverlauf, Personen und Figuren…' AS kurzname, 'aus Texten die Gesamtaussage, Hauptaussagen und relevante Details zu Themen, Handlungsverlauf, Personen und Figuren entnehmen und mündlich und schriftlich, auch digital unterstützt wiedergeben' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_TMK_02' AS code, 'sich mit den Perspektiven und Handlungsmustern von Figuren auseinandersetzen' AS kurzname, 'sich mit den Perspektiven und Handlungsmustern von Figuren auseinandersetzen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_TMK_03' AS code, 'zu Textaussagen persönliche Eindrücke und Gefühle, sowie persönliche Stellungnahmen mündlich und schriftlich formulieren' AS kurzname, 'zu Textaussagen persönliche Eindrücke und Gefühle, sowie persönliche Stellungnahmen mündlich und schriftlich formulieren' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_TMK_04' AS code, 'unterschiedliche mediale Quellen für eigene Informationsrecherchen nutzen sowie gewonnene Informationen kritisch und…' AS kurzname, 'unterschiedliche mediale Quellen für eigene Informationsrecherchen nutzen sowie gewonnene Informationen kritisch und zielentsprechend einsetzen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_TMK_05' AS code, 'produktionsorientierte oder kreative Texte zum persönlichen Lebensumfeld, auch digital, erstellen, umformen und ergänzen' AS kurzname, 'produktionsorientierte oder kreative Texte zum persönlichen Lebensumfeld, auch digital, erstellen, umformen und ergänzen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_TMK_06' AS code, 'bei der Erstellung von Medienprodukten die rechtlichen Grundlagen des Persönlichkeits-, Urheber- und Nutzungsrechts…' AS kurzname, 'bei der Erstellung von Medienprodukten die rechtlichen Grundlagen des Persönlichkeits-, Urheber- und Nutzungsrechts beachten' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_TMK_07' AS code, 'sozial verantwortungsvoll und kritisch reflektierend mit eigenen und fremden, auch digital erstellten, Produkten umgehen' AS kurzname, 'sozial verantwortungsvoll und kritisch reflektierend mit eigenen und fremden, auch digital erstellten, Produkten umgehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_TMK';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Sprachlernkompetenz (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_SLK_01' AS code, 'auf der Grundlage ihres individuellen Mehrsprachigkeitsprofils durch Erproben sprachlicher Mittel und kommunikativer…' AS kurzname, 'auf der Grundlage ihres individuellen Mehrsprachigkeitsprofils durch Erproben sprachlicher Mittel und kommunikativer Strategien die eigene Sprachkompetenz festigen und erweitern' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_SLK_02' AS code, 'bedarfsgerecht und kritisch reflektierend unterschiedliche Arbeits- und Hilfsmittel in Print- und digitaler Version…' AS kurzname, 'bedarfsgerecht und kritisch reflektierend unterschiedliche Arbeits- und Hilfsmittel in Print- und digitaler Version zur Texterschließung, Texterstellung und Selbstkorrektur nutzen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_SLK_03' AS code, 'ihren Lernprozess beobachten und planen sowie den Grad ihrer eigenen Sprachbeherrschung, auch im Hinblick auf den…' AS kurzname, 'ihren Lernprozess beobachten und planen sowie den Grad ihrer eigenen Sprachbeherrschung, auch im Hinblick auf den Einsatz digitaler Hilfsmittel, in der Regel treffend einschätzen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_SLK_04' AS code, 'die Bearbeitung von Aufgaben selbstständig und mittels individueller, sowie kollaborativer Arbeitsformen des…' AS kurzname, 'die Bearbeitung von Aufgaben selbstständig und mittels individueller, sowie kollaborativer Arbeitsformen des Sprachenlernens planen, durchführen und dabei mit auftretenden Schwierigkeiten ergebnisorientiert umgehen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_SLK_05' AS code, 'kontinuierlich eigene Fehlerschwerpunkte bearbeiten, Anregungen von anderen kritisch aufnehmen und Schlussfolgerungen…' AS kurzname, 'kontinuierlich eigene Fehlerschwerpunkte bearbeiten, Anregungen von anderen kritisch aufnehmen und Schlussfolgerungen für ihr eigenes Sprachenlernen ziehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_SLK';
-- Dritte Fremdsprache (Ende der Sekundarstufe I) · Sprachbewusstheit (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'ES_3FS_SBW_01' AS code, 'grundlegende sprachliche Regelmäßigkeiten, unterschiedliche Register und Normabweichungen des Sprachgebrauchs benennen' AS kurzname, 'grundlegende sprachliche Regelmäßigkeiten, unterschiedliche Register und Normabweichungen des Sprachgebrauchs benennen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_SBW_02' AS code, 'Beziehungen zwischen Sprach- und Kulturphänomenen aufzeigen' AS kurzname, 'Beziehungen zwischen Sprach- und Kulturphänomenen aufzeigen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_SBW_03' AS code, 'im Sprachvergleich der Zielsprache mit anderen Sprachen Ähnlichkeiten und Verschiedenheiten aufzeigen' AS kurzname, 'im Sprachvergleich der Zielsprache mit anderen Sprachen Ähnlichkeiten und Verschiedenheiten aufzeigen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_SBW_04' AS code, 'im Sprachvergleich der Zielsprache mit zielsprachigen Varietäten Verschiedenheiten benennen' AS kurzname, 'im Sprachvergleich der Zielsprache mit zielsprachigen Varietäten Verschiedenheiten benennen' AS beschreibung
  UNION ALL
  SELECT 'ES_3FS_SBW_05' AS code, 'das eigene und fremde Kommunikationsverhalten im Hinblick auf Kommunikationserfolge und -probleme beobachten und…' AS kurzname, 'das eigene und fremde Kommunikationsverhalten im Hinblick auf Kommunikationserfolge und -probleme beobachten und ansatzweise kritisch-konstruktiv reflektieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'ES_3FS_SBW';

COMMIT;

-- Kontrolle: erwartet Knoten=60 (davon 48 Blaetter), Kompetenzen=144
