-- =============================================================================
-- Seed 19: Englisch – Kernlehrplan Gymnasium Sek I (G9), NRW 2019 (Heft 3417)
--
-- Quelle: docs/curricula/g9_e_klp_3417_2019_06_23.pdf
-- SHA256: 96a12dca0a6b7d81d75367d1c870aa48013db9bae84671d7add9e7bb55329ead
-- Erzeugt von: sql/gen/gen_englisch_klp.py
--
-- NICHT VON HAND AENDERN: Korrekturen gehoeren in den Erzeuger, die Datei
-- wird daraus neu geschrieben (E19).
-- Voraussetzung: Migration 08, 13 und 15 (Baum, Spalte `art`).
-- Idempotent: loescht vorhandenen ENG_KLP-Rahmen und baut ihn neu auf.
--
-- Erstes Fach mit DREI Gliederungsebenen (E46). Deshalb drei INSERTs auf
-- `kompetenzbereiche` statt der bisherigen zwei: Wurzeln, Mittelknoten,
-- Blaetter -- jeder loest seinen Elternknoten ueber dessen Code auf.
-- =============================================================================

SET NAMES utf8mb4;
START TRANSACTION;

SET @schule := 1;
SET @fach := (SELECT id FROM faecher WHERE schule_id = @schule AND kuerzel = 'EN' LIMIT 1);

-- Nur der eigene Rahmen wird geloescht; CASCADE raeumt Bereiche und Kompetenzen.
DELETE FROM kompetenzrahmen WHERE schule_id = @schule AND kuerzel = 'ENG_KLP';

INSERT INTO kompetenzrahmen (schule_id, name, kuerzel, beschreibung, quelle_url, fach_id)
VALUES (@schule, 'Englisch KLP NRW G9 Sek I (FRG)', 'ENG_KLP', 'Kernlehrplan Englisch Gymnasium Sekundarstufe I (G9), NRW 2019, Heft 3417', 'docs/curricula/g9_e_klp_3417_2019_06_23.pdf', @fach);
SET @rahmen := LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Kompetenzbereiche: drei Ebenen (E29b, E31, E46)
--
-- Die Tiefe schwankt innerhalb des Plans: Text- und Medienkompetenz,
-- Sprachlernkompetenz und Sprachbewusstheit tragen ihre Erwartungen
-- direkt; unter der Funktionalen kommunikativen Kompetenz liegen sieben
-- Teilbereiche, unter einem davon vier Unterbereiche.
-- Kompetenzen haengen nur an Blaettern; die Phase steht als Spalte an
-- jedem Knoten.
-- --------------------------------------------------------------------------
INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art) VALUES
(@rahmen, NULL, 'EN_EP_FKK', 'Erprobungsstufe · Funktionale kommunikative Kompetenz', 1, 'erprobungsstufe', 'kompetenzbereich'),
(@rahmen, NULL, 'EN_EP_IKK', 'Erprobungsstufe · Interkulturelle kommunikative Kompetenz', 13, 'erprobungsstufe', 'kompetenzbereich'),
(@rahmen, NULL, 'EN_EP_TMK', 'Erprobungsstufe · Text- und Medienkompetenz', 17, 'erprobungsstufe', 'kompetenzbereich'),
(@rahmen, NULL, 'EN_EP_SLK', 'Erprobungsstufe · Sprachlernkompetenz', 18, 'erprobungsstufe', 'kompetenzbereich'),
(@rahmen, NULL, 'EN_EP_SBW', 'Erprobungsstufe · Sprachbewusstheit', 19, 'erprobungsstufe', 'kompetenzbereich'),
(@rahmen, NULL, 'EN_S1_FKK', 'Erste Stufe · Funktionale kommunikative Kompetenz', 20, 'erste_stufe', 'kompetenzbereich'),
(@rahmen, NULL, 'EN_S1_IKK', 'Erste Stufe · Interkulturelle kommunikative Kompetenz', 32, 'erste_stufe', 'kompetenzbereich'),
(@rahmen, NULL, 'EN_S1_TMK', 'Erste Stufe · Text- und Medienkompetenz', 36, 'erste_stufe', 'kompetenzbereich'),
(@rahmen, NULL, 'EN_S1_SLK', 'Erste Stufe · Sprachlernkompetenz', 37, 'erste_stufe', 'kompetenzbereich'),
(@rahmen, NULL, 'EN_S1_SBW', 'Erste Stufe · Sprachbewusstheit', 38, 'erste_stufe', 'kompetenzbereich'),
(@rahmen, NULL, 'EN_S2_FKK', 'Zweite Stufe · Funktionale kommunikative Kompetenz', 39, 'zweite_stufe', 'kompetenzbereich'),
(@rahmen, NULL, 'EN_S2_IKK', 'Zweite Stufe · Interkulturelle kommunikative Kompetenz', 51, 'zweite_stufe', 'kompetenzbereich'),
(@rahmen, NULL, 'EN_S2_TMK', 'Zweite Stufe · Text- und Medienkompetenz', 55, 'zweite_stufe', 'kompetenzbereich'),
(@rahmen, NULL, 'EN_S2_SLK', 'Zweite Stufe · Sprachlernkompetenz', 56, 'zweite_stufe', 'kompetenzbereich'),
(@rahmen, NULL, 'EN_S2_SBW', 'Zweite Stufe · Sprachbewusstheit', 57, 'zweite_stufe', 'kompetenzbereich');

-- Ebene 2: parent_id ueber den Code des Elternknotens.
INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art)
SELECT @rahmen, p.id, t.code, t.name, t.reihenfolge, t.phase, t.art
FROM (
  SELECT 'EN_EP_HOR' AS code, 'Erprobungsstufe · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen' AS name, 2 AS reihenfolge, 'erprobungsstufe' AS phase, 'teilbereich' AS art, 'EN_EP_FKK' AS pcode
  UNION ALL
  SELECT 'EN_EP_LES' AS code, 'Erprobungsstufe · Funktionale kommunikative Kompetenz · Leseverstehen' AS name, 3 AS reihenfolge, 'erprobungsstufe' AS phase, 'teilbereich' AS art, 'EN_EP_FKK' AS pcode
  UNION ALL
  SELECT 'EN_EP_SAG' AS code, 'Erprobungsstufe · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen' AS name, 4 AS reihenfolge, 'erprobungsstufe' AS phase, 'teilbereich' AS art, 'EN_EP_FKK' AS pcode
  UNION ALL
  SELECT 'EN_EP_ZUS' AS code, 'Erprobungsstufe · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen' AS name, 5 AS reihenfolge, 'erprobungsstufe' AS phase, 'teilbereich' AS art, 'EN_EP_FKK' AS pcode
  UNION ALL
  SELECT 'EN_EP_SCH' AS code, 'Erprobungsstufe · Funktionale kommunikative Kompetenz · Schreiben' AS name, 6 AS reihenfolge, 'erprobungsstufe' AS phase, 'teilbereich' AS art, 'EN_EP_FKK' AS pcode
  UNION ALL
  SELECT 'EN_EP_SPM' AS code, 'Erprobungsstufe · Funktionale kommunikative Kompetenz · Sprachmittlung' AS name, 7 AS reihenfolge, 'erprobungsstufe' AS phase, 'teilbereich' AS art, 'EN_EP_FKK' AS pcode
  UNION ALL
  SELECT 'EN_EP_VSM' AS code, 'Erprobungsstufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel' AS name, 8 AS reihenfolge, 'erprobungsstufe' AS phase, 'teilbereich' AS art, 'EN_EP_FKK' AS pcode
  UNION ALL
  SELECT 'EN_EP_IKK_SOW' AS code, 'Erprobungsstufe · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen' AS name, 14 AS reihenfolge, 'erprobungsstufe' AS phase, 'unterbereich' AS art, 'EN_EP_IKK' AS pcode
  UNION ALL
  SELECT 'EN_EP_IKK_EIN' AS code, 'Erprobungsstufe · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit' AS name, 15 AS reihenfolge, 'erprobungsstufe' AS phase, 'unterbereich' AS art, 'EN_EP_IKK' AS pcode
  UNION ALL
  SELECT 'EN_EP_IKK_VER' AS code, 'Erprobungsstufe · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln' AS name, 16 AS reihenfolge, 'erprobungsstufe' AS phase, 'unterbereich' AS art, 'EN_EP_IKK' AS pcode
  UNION ALL
  SELECT 'EN_S1_HOR' AS code, 'Erste Stufe · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen' AS name, 21 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'EN_S1_FKK' AS pcode
  UNION ALL
  SELECT 'EN_S1_LES' AS code, 'Erste Stufe · Funktionale kommunikative Kompetenz · Leseverstehen' AS name, 22 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'EN_S1_FKK' AS pcode
  UNION ALL
  SELECT 'EN_S1_SAG' AS code, 'Erste Stufe · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen' AS name, 23 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'EN_S1_FKK' AS pcode
  UNION ALL
  SELECT 'EN_S1_ZUS' AS code, 'Erste Stufe · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen' AS name, 24 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'EN_S1_FKK' AS pcode
  UNION ALL
  SELECT 'EN_S1_SCH' AS code, 'Erste Stufe · Funktionale kommunikative Kompetenz · Schreiben' AS name, 25 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'EN_S1_FKK' AS pcode
  UNION ALL
  SELECT 'EN_S1_SPM' AS code, 'Erste Stufe · Funktionale kommunikative Kompetenz · Sprachmittlung' AS name, 26 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'EN_S1_FKK' AS pcode
  UNION ALL
  SELECT 'EN_S1_VSM' AS code, 'Erste Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel' AS name, 27 AS reihenfolge, 'erste_stufe' AS phase, 'teilbereich' AS art, 'EN_S1_FKK' AS pcode
  UNION ALL
  SELECT 'EN_S1_IKK_SOW' AS code, 'Erste Stufe · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen' AS name, 33 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'EN_S1_IKK' AS pcode
  UNION ALL
  SELECT 'EN_S1_IKK_EIN' AS code, 'Erste Stufe · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit' AS name, 34 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'EN_S1_IKK' AS pcode
  UNION ALL
  SELECT 'EN_S1_IKK_VER' AS code, 'Erste Stufe · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln' AS name, 35 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'EN_S1_IKK' AS pcode
  UNION ALL
  SELECT 'EN_S2_HOR' AS code, 'Zweite Stufe · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen' AS name, 40 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'EN_S2_FKK' AS pcode
  UNION ALL
  SELECT 'EN_S2_LES' AS code, 'Zweite Stufe · Funktionale kommunikative Kompetenz · Leseverstehen' AS name, 41 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'EN_S2_FKK' AS pcode
  UNION ALL
  SELECT 'EN_S2_SAG' AS code, 'Zweite Stufe · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen' AS name, 42 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'EN_S2_FKK' AS pcode
  UNION ALL
  SELECT 'EN_S2_ZUS' AS code, 'Zweite Stufe · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen' AS name, 43 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'EN_S2_FKK' AS pcode
  UNION ALL
  SELECT 'EN_S2_SCH' AS code, 'Zweite Stufe · Funktionale kommunikative Kompetenz · Schreiben' AS name, 44 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'EN_S2_FKK' AS pcode
  UNION ALL
  SELECT 'EN_S2_SPM' AS code, 'Zweite Stufe · Funktionale kommunikative Kompetenz · Sprachmittlung' AS name, 45 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'EN_S2_FKK' AS pcode
  UNION ALL
  SELECT 'EN_S2_VSM' AS code, 'Zweite Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel' AS name, 46 AS reihenfolge, 'zweite_stufe' AS phase, 'teilbereich' AS art, 'EN_S2_FKK' AS pcode
  UNION ALL
  SELECT 'EN_S2_IKK_SOW' AS code, 'Zweite Stufe · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen' AS name, 52 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'EN_S2_IKK' AS pcode
  UNION ALL
  SELECT 'EN_S2_IKK_EIN' AS code, 'Zweite Stufe · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit' AS name, 53 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'EN_S2_IKK' AS pcode
  UNION ALL
  SELECT 'EN_S2_IKK_VER' AS code, 'Zweite Stufe · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln' AS name, 54 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'EN_S2_IKK' AS pcode
) t JOIN kompetenzbereiche p ON p.rahmen_id = @rahmen AND p.code = t.pcode;

-- Ebene 3: parent_id ueber den Code des Elternknotens.
INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art)
SELECT @rahmen, p.id, t.code, t.name, t.reihenfolge, t.phase, t.art
FROM (
  SELECT 'EN_EP_VSM_WOR' AS code, 'Erprobungsstufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz' AS name, 9 AS reihenfolge, 'erprobungsstufe' AS phase, 'unterbereich' AS art, 'EN_EP_VSM' AS pcode
  UNION ALL
  SELECT 'EN_EP_VSM_GRA' AS code, 'Erprobungsstufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik' AS name, 10 AS reihenfolge, 'erprobungsstufe' AS phase, 'unterbereich' AS art, 'EN_EP_VSM' AS pcode
  UNION ALL
  SELECT 'EN_EP_VSM_AUS' AS code, 'Erprobungsstufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation' AS name, 11 AS reihenfolge, 'erprobungsstufe' AS phase, 'unterbereich' AS art, 'EN_EP_VSM' AS pcode
  UNION ALL
  SELECT 'EN_EP_VSM_ORT' AS code, 'Erprobungsstufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie' AS name, 12 AS reihenfolge, 'erprobungsstufe' AS phase, 'unterbereich' AS art, 'EN_EP_VSM' AS pcode
  UNION ALL
  SELECT 'EN_S1_VSM_WOR' AS code, 'Erste Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz' AS name, 28 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'EN_S1_VSM' AS pcode
  UNION ALL
  SELECT 'EN_S1_VSM_GRA' AS code, 'Erste Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik' AS name, 29 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'EN_S1_VSM' AS pcode
  UNION ALL
  SELECT 'EN_S1_VSM_AUS' AS code, 'Erste Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation' AS name, 30 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'EN_S1_VSM' AS pcode
  UNION ALL
  SELECT 'EN_S1_VSM_ORT' AS code, 'Erste Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie' AS name, 31 AS reihenfolge, 'erste_stufe' AS phase, 'unterbereich' AS art, 'EN_S1_VSM' AS pcode
  UNION ALL
  SELECT 'EN_S2_VSM_WOR' AS code, 'Zweite Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz' AS name, 47 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'EN_S2_VSM' AS pcode
  UNION ALL
  SELECT 'EN_S2_VSM_GRA' AS code, 'Zweite Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik' AS name, 48 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'EN_S2_VSM' AS pcode
  UNION ALL
  SELECT 'EN_S2_VSM_AUS' AS code, 'Zweite Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation' AS name, 49 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'EN_S2_VSM' AS pcode
  UNION ALL
  SELECT 'EN_S2_VSM_ORT' AS code, 'Zweite Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie' AS name, 50 AS reihenfolge, 'zweite_stufe' AS phase, 'unterbereich' AS art, 'EN_S2_VSM' AS pcode
) t JOIN kompetenzbereiche p ON p.rahmen_id = @rahmen AND p.code = t.pcode;

-- --------------------------------------------------------------------------
-- Kompetenzerwartungen (flach, nur an Blaettern)
-- --------------------------------------------------------------------------
-- Erprobungsstufe · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_HOR_01' AS code, 'kürzeren Unterrichtsbeiträgen die wesentlichen Informationen entnehmen' AS kurzname, 'kürzeren Unterrichtsbeiträgen die wesentlichen Informationen entnehmen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_HOR_02' AS code, 'einfachen Gesprächen in vertrauten Situationen des Alltags wesentliche Informationen entnehmen' AS kurzname, 'einfachen Gesprächen in vertrauten Situationen des Alltags wesentliche Informationen entnehmen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_HOR_03' AS code, 'Hör-/Hörsehtexten wesentliche Informationen entnehmen' AS kurzname, 'Hör-/Hörsehtexten wesentliche Informationen entnehmen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_HOR';
-- Erprobungsstufe · Funktionale kommunikative Kompetenz · Leseverstehen (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_LES_01' AS code, 'kürzere Arbeitsanweisungen, Anleitungen und Erklärungen für ihren Lern- und Arbeitsprozess nutzen' AS kurzname, 'kürzere Arbeitsanweisungen, Anleitungen und Erklärungen für ihren Lern- und Arbeitsprozess nutzen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_LES_02' AS code, 'Sach- und Gebrauchstexten sowie literarischen Texten wesentliche Informationen und wichtige Details entnehmen. 15' AS kurzname, 'Sach- und Gebrauchstexten sowie literarischen Texten wesentliche Informationen und wichtige Details entnehmen. 15' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_LES';
-- Erprobungsstufe · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_SAG_01' AS code, 'am classroom discourse und an einfachen Gesprächen in vertrauten Situationen des Alltags aktiv teilnehmen' AS kurzname, 'am classroom discourse und an einfachen Gesprächen in vertrauten Situationen des Alltags aktiv teilnehmen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_SAG_02' AS code, 'Gespräche beginnen und beenden' AS kurzname, 'Gespräche beginnen und beenden' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_SAG_03' AS code, 'sich auch in unterschiedlichen Rollen an Gesprächen beteiligen' AS kurzname, 'sich auch in unterschiedlichen Rollen an Gesprächen beteiligen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_SAG';
-- Erprobungsstufe · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_ZUS_01' AS code, 'Arbeitsergebnisse in elementarer Form vorstellen' AS kurzname, 'Arbeitsergebnisse in elementarer Form vorstellen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_ZUS_02' AS code, 'Inhalte einfacher Texte und Medien nacherzählend und zusammenfassend wiedergeben' AS kurzname, 'Inhalte einfacher Texte und Medien nacherzählend und zusammenfassend wiedergeben' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_ZUS_03' AS code, 'notizengestützt eine einfache Präsentation strukturiert vortragen' AS kurzname, 'notizengestützt eine einfache Präsentation strukturiert vortragen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_ZUS_04' AS code, 'einfache Texte sinnstiftend vorlesen' AS kurzname, 'einfache Texte sinnstiftend vorlesen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_ZUS';
-- Erprobungsstufe · Funktionale kommunikative Kompetenz · Schreiben (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_SCH_01' AS code, 'kurze Alltagstexte verfassen' AS kurzname, 'kurze Alltagstexte verfassen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_SCH_02' AS code, 'Modelltexte kreativ gestaltend in einfache eigene Texte umformen' AS kurzname, 'Modelltexte kreativ gestaltend in einfache eigene Texte umformen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_SCH_03' AS code, 'Arbeits-/Lernprozesse schriftlich begleiten und Arbeitsergebnisse festhalten' AS kurzname, 'Arbeits-/Lernprozesse schriftlich begleiten und Arbeitsergebnisse festhalten' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_SCH';
-- Erprobungsstufe · Funktionale kommunikative Kompetenz · Sprachmittlung (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_SPM_01' AS code, 'in Begegnungssituationen des Alltags einfache schriftliche und mündliche Informationen mündlich sinngemäß übertragen' AS kurzname, 'in Begegnungssituationen des Alltags einfache schriftliche und mündliche Informationen mündlich sinngemäß übertragen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_SPM_02' AS code, 'in schriftlichen Kommunikationssituationen die relevanten Informationen kurzer privater und öffentlicher Alltagstexte …' AS kurzname, 'in schriftlichen Kommunikationssituationen die relevanten Informationen kurzer privater und öffentlicher Alltagstexte sinngemäß übertragen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_SPM_03' AS code, 'gegebene Informationen weitgehend situationsangemessen und adressatengerecht bündeln' AS kurzname, 'gegebene Informationen weitgehend situationsangemessen und adressatengerecht bündeln' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_SPM';
-- Erprobungsstufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_VSM_WOR_01' AS code, 'classroom phrases verstehen und situationsangemessen anwenden' AS kurzname, 'classroom phrases verstehen und situationsangemessen anwenden' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_VSM_WOR_02' AS code, 'einen allgemeinen sowie thematischen Wortschatz verstehen und situationsangemessen anwenden' AS kurzname, 'einen allgemeinen sowie thematischen Wortschatz verstehen und situationsangemessen anwenden' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_VSM_WOR_03' AS code, 'Vokabular zur einfachen Beschreibung sprachlicher Elemente und Strukturen sowie zu einfachen Formen der Textbesprechung …' AS kurzname, 'Vokabular zur einfachen Beschreibung sprachlicher Elemente und Strukturen sowie zu einfachen Formen der Textbesprechung und Textproduktion verstehen und anwenden. 17' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_VSM_WOR';
-- Erprobungsstufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik (7)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_VSM_GRA_01' AS code, 'Personen, Sachen, Sachverhalte, Tätigkeiten und Geschehnisse bezeichnen und beschreiben' AS kurzname, 'Personen, Sachen, Sachverhalte, Tätigkeiten und Geschehnisse bezeichnen und beschreiben' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_VSM_GRA_02' AS code, 'bejahte und verneinte Aussagen, Fragen und Aufforderungen formulieren' AS kurzname, 'bejahte und verneinte Aussagen, Fragen und Aufforderungen formulieren' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_VSM_GRA_03' AS code, 'Verbote, Erlaubnis und Bitten ausdrücken' AS kurzname, 'Verbote, Erlaubnis und Bitten ausdrücken' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_VSM_GRA_04' AS code, 'in einfacher Form Wünsche, Interessen und Verpflichtungen ausdrücken' AS kurzname, 'in einfacher Form Wünsche, Interessen und Verpflichtungen ausdrücken' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_VSM_GRA_05' AS code, 'räumliche, zeitliche und logische Bezüge zwischen Sätzen herstellen, Bedingungen ausdrücken' AS kurzname, 'räumliche, zeitliche und logische Bezüge zwischen Sätzen herstellen, Bedingungen ausdrücken' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_VSM_GRA_06' AS code, 'über gegenwärtige, vergangene und zukünftige Ereignisse aus dem eigenen Erfahrungsbereich berichten und erzählen' AS kurzname, 'über gegenwärtige, vergangene und zukünftige Ereignisse aus dem eigenen Erfahrungsbereich berichten und erzählen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_VSM_GRA_07' AS code, 'Aussagen wörtlich wiedergeben' AS kurzname, 'Aussagen wörtlich wiedergeben' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_VSM_GRA';
-- Erprobungsstufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_VSM_AUS_01' AS code, 'einfache Aussprache- und Intonationsmuster beachten und auf neue Wörter und Sätze übertragen' AS kurzname, 'einfache Aussprache- und Intonationsmuster beachten und auf neue Wörter und Sätze übertragen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_VSM_AUS_02' AS code, 'die Wörter ihres Grundwortschatzes aussprechen' AS kurzname, 'die Wörter ihres Grundwortschatzes aussprechen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_VSM_AUS_03' AS code, 'die Intonation einfacher Aussagesätze, Fragen und Aufforderungen angemessen realisieren' AS kurzname, 'die Intonation einfacher Aussagesätze, Fragen und Aufforderungen angemessen realisieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_VSM_AUS';
-- Erprobungsstufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_VSM_ORT_01' AS code, 'typische Laut-Buchstaben-Verbindungen beachten' AS kurzname, 'typische Laut-Buchstaben-Verbindungen beachten' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_VSM_ORT_02' AS code, 'einfache Regeln der Rechtschreibung und Zeichensetzung anwenden, auch in Abgrenzung zur deutschen Sprache' AS kurzname, 'einfache Regeln der Rechtschreibung und Zeichensetzung anwenden, auch in Abgrenzung zur deutschen Sprache' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_VSM_ORT_03' AS code, 'die Wörter ihres Grundwortschatzes schreiben' AS kurzname, 'die Wörter ihres Grundwortschatzes schreiben' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_VSM_ORT';
-- Erprobungsstufe · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_IKK_SOW_01' AS code, 'auf ein elementares soziokulturelles Orientierungswissen zu anglophonen Lebenswirklichkeiten in Großbritannien …' AS kurzname, 'auf ein elementares soziokulturelles Orientierungswissen zu anglophonen Lebenswirklichkeiten in Großbritannien zurückgreifen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_IKK_SOW';
-- Erprobungsstufe · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_IKK_EIN_01' AS code, 'neuen Erfahrungen mit anderen Kulturen offen und lernbereit begegnen' AS kurzname, 'neuen Erfahrungen mit anderen Kulturen offen und lernbereit begegnen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_IKK_EIN_02' AS code, 'einfache fremdkulturelle Werte, Normen und Verhaltensweisen mit durch die eigene Kultur geprägten Wahrnehmungen und …' AS kurzname, 'einfache fremdkulturelle Werte, Normen und Verhaltensweisen mit durch die eigene Kultur geprägten Wahrnehmungen und Einstellungen auch aus Gender-Perspektive vergleichen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_IKK_EIN';
-- Erprobungsstufe · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_IKK_VER_01' AS code, 'sich in elementare Denk- und Verhaltensweisen von Menschen der Zielkultur hineinversetzen' AS kurzname, 'sich in elementare Denk- und Verhaltensweisen von Menschen der Zielkultur hineinversetzen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_IKK_VER_02' AS code, 'in einfachen interkulturellen Kommunikationssituationen elementare kulturspezifische Konventionen und Besonderheiten …' AS kurzname, 'in einfachen interkulturellen Kommunikationssituationen elementare kulturspezifische Konventionen und Besonderheiten des Kommunikationsverhaltens respektvoll beachten' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_IKK_VER_03' AS code, 'sich mit englischsprachigen Kommunikationspartnern über einfache kulturelle Gemeinsamkeiten, Unterschiede und …' AS kurzname, 'sich mit englischsprachigen Kommunikationspartnern über einfache kulturelle Gemeinsamkeiten, Unterschiede und Stereotype austauschen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_IKK_VER';
-- Erprobungsstufe · Text- und Medienkompetenz (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_TMK_01' AS code, 'didaktisierte und einfache authentische Texte und Medien bezogen auf Thema, Inhalt, Aussage und typische …' AS kurzname, 'didaktisierte und einfache authentische Texte und Medien bezogen auf Thema, Inhalt, Aussage und typische Textsortenmerkmale untersuchen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_TMK_02' AS code, 'eigene und fremde Texte nach Einleitung, Hauptteil und Schluss gliedern' AS kurzname, 'eigene und fremde Texte nach Einleitung, Hauptteil und Schluss gliedern' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_TMK_03' AS code, 'einfache Informationsrecherchen zu einem Thema durchführen und die themenrelevanten Informationen und Daten filtern und …' AS kurzname, 'einfache Informationsrecherchen zu einem Thema durchführen und die themenrelevanten Informationen und Daten filtern und strukturieren' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_TMK_04' AS code, 'unter Einsatz einfacher produktionsorientierter Verfahren kurze analoge und digitale Texte sowie Medienprodukte …' AS kurzname, 'unter Einsatz einfacher produktionsorientierter Verfahren kurze analoge und digitale Texte sowie Medienprodukte erstellen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_TMK';
-- Erprobungsstufe · Sprachlernkompetenz (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_SLK_01' AS code, 'einfache anwendungsorientierte Formen der Wortschatzarbeit einsetzen' AS kurzname, 'einfache anwendungsorientierte Formen der Wortschatzarbeit einsetzen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_SLK_02' AS code, 'Übungs- und Testaufgaben zum systematischen Sprachtraining auch unter Verwendung digitaler Angebote nutzen' AS kurzname, 'Übungs- und Testaufgaben zum systematischen Sprachtraining auch unter Verwendung digitaler Angebote nutzen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_SLK_03' AS code, 'einfache Regeln des Sprachgebrauchs erschließen, verstehen, erprobend anwenden und ihren Gebrauch festigen' AS kurzname, 'einfache Regeln des Sprachgebrauchs erschließen, verstehen, erprobend anwenden und ihren Gebrauch festigen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_SLK_04' AS code, 'einfache Hilfsmittel nutzen und erstellen, um analoge und digitale Texte und Arbeitsprodukte zu verstehen, zu erstellen …' AS kurzname, 'einfache Hilfsmittel nutzen und erstellen, um analoge und digitale Texte und Arbeitsprodukte zu verstehen, zu erstellen und zu überarbeiten' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_SLK_05' AS code, 'den eigenen Lernfortschritt anhand einfacher, auch digitaler Evaluationsinstrumente einschätzen sowie eigene …' AS kurzname, 'den eigenen Lernfortschritt anhand einfacher, auch digitaler Evaluationsinstrumente einschätzen sowie eigene Fehlerschwerpunkte bearbeiten' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_SLK';
-- Erprobungsstufe · Sprachbewusstheit (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_EP_SBW_01' AS code, 'offenkundige Regelmäßigkeiten und Normabweichungen in den Bereichen Rechtschreibung, Aussprache, Intonation und …' AS kurzname, 'offenkundige Regelmäßigkeiten und Normabweichungen in den Bereichen Rechtschreibung, Aussprache, Intonation und Grammatik erkennen und benennen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_SBW_02' AS code, 'im Vergleich des Englischen mit der deutschen Sprache oder anderen vertrauten Sprachen Ähnlichkeiten und Unterschiede …' AS kurzname, 'im Vergleich des Englischen mit der deutschen Sprache oder anderen vertrauten Sprachen Ähnlichkeiten und Unterschiede erkennen und benennen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_SBW_03' AS code, 'offenkundige Beziehungen zwischen Sprach- und Kulturphänomenen erkennen' AS kurzname, 'offenkundige Beziehungen zwischen Sprach- und Kulturphänomenen erkennen' AS beschreibung
  UNION ALL
  SELECT 'EN_EP_SBW_04' AS code, 'ihren Sprachgebrauch an die Erfordernisse einfacher Kommunikationssituationen anpassen' AS kurzname, 'ihren Sprachgebrauch an die Erfordernisse einfacher Kommunikationssituationen anpassen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_EP_SBW';
-- Erste Stufe · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_HOR_01' AS code, 'Unterrichtsbeiträgen die wesentlichen Informationen entnehmen' AS kurzname, 'Unterrichtsbeiträgen die wesentlichen Informationen entnehmen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_HOR_02' AS code, 'dem Verlauf einfacher Gespräche folgen und ihnen Hauptpunkte und wichtige Details entnehmen' AS kurzname, 'dem Verlauf einfacher Gespräche folgen und ihnen Hauptpunkte und wichtige Details entnehmen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_HOR_03' AS code, 'Hör-/Hörsehtexten Hauptpunkte und wichtige Details entnehmen' AS kurzname, 'Hör-/Hörsehtexten Hauptpunkte und wichtige Details entnehmen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_HOR_04' AS code, 'wesentliche implizite Gefühle der Sprechenden identifizieren' AS kurzname, 'wesentliche implizite Gefühle der Sprechenden identifizieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_HOR';
-- Erste Stufe · Funktionale kommunikative Kompetenz · Leseverstehen (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_LES_01' AS code, 'Arbeitsanweisungen, Anleitungen und Erklärungen für ihren Lern- und Arbeitsprozess nutzen, 23' AS kurzname, 'Arbeitsanweisungen, Anleitungen und Erklärungen für ihren Lern- und Arbeitsprozess nutzen, 23' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_LES_02' AS code, 'Sach- und Gebrauchstexten sowie literarischen Texten die Gesamtaussage sowie Hauptpunkte und wichtige Details entnehmen' AS kurzname, 'Sach- und Gebrauchstexten sowie literarischen Texten die Gesamtaussage sowie Hauptpunkte und wichtige Details entnehmen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_LES_03' AS code, 'literarischen Texten wesentliche implizite Informationen entnehmen' AS kurzname, 'literarischen Texten wesentliche implizite Informationen entnehmen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_LES';
-- Erste Stufe · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_SAG_01' AS code, 'am classroom discourse und an Gesprächen in vertrauten privaten und öffentlichen Situationen in der Form des freien …' AS kurzname, 'am classroom discourse und an Gesprächen in vertrauten privaten und öffentlichen Situationen in der Form des freien Gesprächs aktiv teilnehmen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SAG_02' AS code, 'Gespräche eröffnen, fortführen und beenden sowie auch bei sprachlichen Schwierigkeiten weitgehend aufrechterhalten' AS kurzname, 'Gespräche eröffnen, fortführen und beenden sowie auch bei sprachlichen Schwierigkeiten weitgehend aufrechterhalten' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SAG_03' AS code, 'auf Beiträge des Gesprächspartners weitgehend flexibel eingehen und elementare Verständnisprobleme ausräumen' AS kurzname, 'auf Beiträge des Gesprächspartners weitgehend flexibel eingehen und elementare Verständnisprobleme ausräumen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SAG_04' AS code, 'sich in unterschiedlichen Rollen an einfachen formalisierten Gesprächen beteiligen' AS kurzname, 'sich in unterschiedlichen Rollen an einfachen formalisierten Gesprächen beteiligen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_SAG';
-- Erste Stufe · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_ZUS_01' AS code, 'Arbeitsergebnisse weitgehend strukturiert vorstellen' AS kurzname, 'Arbeitsergebnisse weitgehend strukturiert vorstellen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_ZUS_02' AS code, 'Inhalte von Texten und Medien zusammenfassend wiedergeben' AS kurzname, 'Inhalte von Texten und Medien zusammenfassend wiedergeben' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_ZUS_03' AS code, 'notizengestützt eine Präsentation strukturiert vortragen und dabei auf Materialien zur Veranschaulichung eingehen' AS kurzname, 'notizengestützt eine Präsentation strukturiert vortragen und dabei auf Materialien zur Veranschaulichung eingehen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_ZUS_04' AS code, 'Texte sinnstiftend und darstellerisch-gestaltend vorlesen' AS kurzname, 'Texte sinnstiftend und darstellerisch-gestaltend vorlesen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_ZUS';
-- Erste Stufe · Funktionale kommunikative Kompetenz · Schreiben (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_SCH_01' AS code, 'Texte in beschreibender, berichtender, zusammenfassender, erzählender, erklärender und argumentierender Absicht …' AS kurzname, 'Texte in beschreibender, berichtender, zusammenfassender, erzählender, erklärender und argumentierender Absicht verfassen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SCH_02' AS code, 'kreativ gestaltend eigene Texte verfassen' AS kurzname, 'kreativ gestaltend eigene Texte verfassen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SCH_03' AS code, 'Arbeits-/Lernprozesse schriftlich begleiten und Arbeitsergebnisse detailliert festhalten' AS kurzname, 'Arbeits-/Lernprozesse schriftlich begleiten und Arbeitsergebnisse detailliert festhalten' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_SCH';
-- Erste Stufe · Funktionale kommunikative Kompetenz · Sprachmittlung (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_SPM_01' AS code, 'in Begegnungssituationen relevante schriftliche und mündliche Informationen mündlich sinngemäß übertragen' AS kurzname, 'in Begegnungssituationen relevante schriftliche und mündliche Informationen mündlich sinngemäß übertragen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SPM_02' AS code, 'in schriftlichen Kommunikationssituationen die relevanten Informationen aus Sach- und Gebrauchstexten sinngemäß …' AS kurzname, 'in schriftlichen Kommunikationssituationen die relevanten Informationen aus Sach- und Gebrauchstexten sinngemäß übertragen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SPM_03' AS code, 'gegebene Informationen auf der Grundlage ihrer interkulturellen kommunikativen Kompetenz weitgehend …' AS kurzname, 'gegebene Informationen auf der Grundlage ihrer interkulturellen kommunikativen Kompetenz weitgehend situationsangemessen und adressatengerecht bündeln sowie bei Bedarf ergänzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_SPM';
-- Erste Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_VSM_WOR_01' AS code, 'classroom phrases verstehen und situationsangemessen anwenden' AS kurzname, 'classroom phrases verstehen und situationsangemessen anwenden' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_WOR_02' AS code, 'einen allgemeinen sowie thematischen Wortschatz verstehen und situationsangemessen anwenden' AS kurzname, 'einen allgemeinen sowie thematischen Wortschatz verstehen und situationsangemessen anwenden' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_WOR_03' AS code, 'grundlegende lexikalische Unterschiede zwischen amerikanischem und britischem Englisch beachten' AS kurzname, 'grundlegende lexikalische Unterschiede zwischen amerikanischem und britischem Englisch beachten' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_WOR_04' AS code, 'Vokabular zur Beschreibung sprachlicher Elemente und Strukturen sowie zur 25 Textbesprechung und Textproduktion …' AS kurzname, 'Vokabular zur Beschreibung sprachlicher Elemente und Strukturen sowie zur 25 Textbesprechung und Textproduktion verstehen und anwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_VSM_WOR';
-- Erste Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik (9)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_VSM_GRA_01' AS code, 'Sachverhalte sowie Dauer, Zeitpunkt, Wiederholung, Abfolge von Handlungen ausdrücken' AS kurzname, 'Sachverhalte sowie Dauer, Zeitpunkt, Wiederholung, Abfolge von Handlungen ausdrücken' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_GRA_02' AS code, 'Verbote, Erlaubnis, Aufforderungen, Bitten, Wünsche, Erwartungen und Verpflichtungen ausdrücken' AS kurzname, 'Verbote, Erlaubnis, Aufforderungen, Bitten, Wünsche, Erwartungen und Verpflichtungen ausdrücken' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_GRA_03' AS code, 'weitere Möglichkeiten einsetzen, um Zukünftiges auszudrücken' AS kurzname, 'weitere Möglichkeiten einsetzen, um Zukünftiges auszudrücken' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_GRA_04' AS code, 'Handlungen und Ereignisse aktivisch und passivisch darstellen' AS kurzname, 'Handlungen und Ereignisse aktivisch und passivisch darstellen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_GRA_05' AS code, 'Beziehungen innerhalb eines Satzes ausdrücken und Zusatzinformationen geben' AS kurzname, 'Beziehungen innerhalb eines Satzes ausdrücken und Zusatzinformationen geben' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_GRA_06' AS code, 'Handlungen vergleichen und näher beschreiben' AS kurzname, 'Handlungen vergleichen und näher beschreiben' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_GRA_07' AS code, 'Bedingungen und Bezüge darstellen' AS kurzname, 'Bedingungen und Bezüge darstellen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_GRA_08' AS code, 'Aussagen vermittelt wiedergeben' AS kurzname, 'Aussagen vermittelt wiedergeben' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_GRA_09' AS code, 'grundlegende Unterschiede des amerikanischen gegenüber dem britischen Englisch beachten' AS kurzname, 'grundlegende Unterschiede des amerikanischen gegenüber dem britischen Englisch beachten' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_VSM_GRA';
-- Erste Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_VSM_AUS_01' AS code, 'grundlegende Aussprache- und Intonationsmuster beachten und auf neue Wörter und Sätze übertragen' AS kurzname, 'grundlegende Aussprache- und Intonationsmuster beachten und auf neue Wörter und Sätze übertragen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_AUS_02' AS code, 'die Wörter ihres erweiterten Grundwortschatzes aussprechen' AS kurzname, 'die Wörter ihres erweiterten Grundwortschatzes aussprechen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_AUS_03' AS code, 'in Fragen, Aufforderungen und Ausrufen Intonationsmuster mit Bedeutungsimplikationen weitgehend angemessen realisieren' AS kurzname, 'in Fragen, Aufforderungen und Ausrufen Intonationsmuster mit Bedeutungsimplikationen weitgehend angemessen realisieren' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_AUS_04' AS code, 'gängige Aussprachevarianten des britischen und amerikanischen Englisch erkennen und verstehen' AS kurzname, 'gängige Aussprachevarianten des britischen und amerikanischen Englisch erkennen und verstehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_VSM_AUS';
-- Erste Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_VSM_ORT_01' AS code, 'grundlegende Laut-Buchstaben-Verbindungen beachten' AS kurzname, 'grundlegende Laut-Buchstaben-Verbindungen beachten' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_ORT_02' AS code, 'ein Repertoire grundlegender Regeln der Rechtschreibung und Zeichensetzung anwenden, auch in Abgrenzung zur deutschen …' AS kurzname, 'ein Repertoire grundlegender Regeln der Rechtschreibung und Zeichensetzung anwenden, auch in Abgrenzung zur deutschen Sprache' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_ORT_03' AS code, 'die Wörter ihres erweiterten Grundwortschatzes schreiben' AS kurzname, 'die Wörter ihres erweiterten Grundwortschatzes schreiben' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_VSM_ORT_04' AS code, 'grundlegende orthografische Unterschiede des britischen und amerikanischen Englisch erkennen und beachten' AS kurzname, 'grundlegende orthografische Unterschiede des britischen und amerikanischen Englisch erkennen und beachten' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_VSM_ORT';
-- Erste Stufe · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_IKK_SOW_01' AS code, 'auf ein grundlegendes soziokulturelles Orientierungswissen zu anglophonen Lebenswirklichkeiten im Vereinigten …' AS kurzname, 'auf ein grundlegendes soziokulturelles Orientierungswissen zu anglophonen Lebenswirklichkeiten im Vereinigten Königreich und in den USA zurückgreifen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_IKK_SOW';
-- Erste Stufe · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_IKK_EIN_01' AS code, 'sich der Chancen und Herausforderungen kultureller Vielfalt bewusst sein und neuen Erfahrungen mit anderen Kulturen …' AS kurzname, 'sich der Chancen und Herausforderungen kultureller Vielfalt bewusst sein und neuen Erfahrungen mit anderen Kulturen offen und lernbereit begegnen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_IKK_EIN_02' AS code, 'grundlegende eigen- und fremdkulturelle Wertvorstellungen, Einstellungen und Lebensstile vergleichen und sie – auch …' AS kurzname, 'grundlegende eigen- und fremdkulturelle Wertvorstellungen, Einstellungen und Lebensstile vergleichen und sie – auch selbstkritisch sowie aus Gender-Perspektive – in Frage stellen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_IKK_EIN';
-- Erste Stufe · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_IKK_VER_01' AS code, 'typische (inter-)kulturelle Stereotype/Klischees und Vorurteile erläutern und kritisch hinterfragen' AS kurzname, 'typische (inter-)kulturelle Stereotype/Klischees und Vorurteile erläutern und kritisch hinterfragen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_IKK_VER_02' AS code, 'sich in Denk- und Verhaltensweisen von Menschen anderer Kulturen hineinversetzen und dadurch Verständnis für den …' AS kurzname, 'sich in Denk- und Verhaltensweisen von Menschen anderer Kulturen hineinversetzen und dadurch Verständnis für den anderen bzw. kritische Distanz entwickeln' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_IKK_VER_03' AS code, 'in interkulturellen Kommunikationssituationen grundlegende kulturspezifische Konventionen und Besonderheiten des …' AS kurzname, 'in interkulturellen Kommunikationssituationen grundlegende kulturspezifische Konventionen und Besonderheiten des Kommunikationsverhaltens respektvoll beachten sowie einfache sprachlich-kulturell bedingte Missverständnisse erkennen und weitgehend aufklären' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_IKK_VER_04' AS code, 'sich mit englischsprachigen Kommunikationspartnern über kulturelle Gemeinsamkeiten und Unterschiede …' AS kurzname, 'sich mit englischsprachigen Kommunikationspartnern über kulturelle Gemeinsamkeiten und Unterschiede tolerant-wertschätzend, erforderlichenfalls aber auch kritisch austauschen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_IKK_VER';
-- Erste Stufe · Text- und Medienkompetenz (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_TMK_01' AS code, 'unter Einsatz von Texterschließungsverfahren didaktisierte und einfache authentische Texte bezogen auf Thema, Inhalt, …' AS kurzname, 'unter Einsatz von Texterschließungsverfahren didaktisierte und einfache authentische Texte bezogen auf Thema, Inhalt, Textaufbau, Aussage und typische Textsortenmerkmale untersuchen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_TMK_02' AS code, 'eigene und fremde Texte weitgehend funktional gliedern' AS kurzname, 'eigene und fremde Texte weitgehend funktional gliedern' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_TMK_03' AS code, 'Informationsrecherchen zu einem Thema durchführen und die themenrelevanten Informationen und Daten filtern, …' AS kurzname, 'Informationsrecherchen zu einem Thema durchführen und die themenrelevanten Informationen und Daten filtern, strukturieren und aufbereiten' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_TMK_04' AS code, 'Arbeitsergebnisse mithilfe von digitalen Werkzeugen adressatengerecht gestalten und präsentieren' AS kurzname, 'Arbeitsergebnisse mithilfe von digitalen Werkzeugen adressatengerecht gestalten und präsentieren' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_TMK_05' AS code, 'unter Einsatz produktionsorientierter Verfahren analoge und kurze digitale Texte und Medienprodukte erstellen' AS kurzname, 'unter Einsatz produktionsorientierter Verfahren analoge und kurze digitale Texte und Medienprodukte erstellen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_TMK_06' AS code, 'unter Einsatz produktionsorientierter Verfahren die Wirkung von Texten und Medien erkunden' AS kurzname, 'unter Einsatz produktionsorientierter Verfahren die Wirkung von Texten und Medien erkunden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_TMK';
-- Erste Stufe · Sprachlernkompetenz (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_SLK_01' AS code, 'unterschiedliche anwendungsorientierte Formen der Wortschatzarbeit einsetzen' AS kurzname, 'unterschiedliche anwendungsorientierte Formen der Wortschatzarbeit einsetzen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SLK_02' AS code, 'in Texten grammatische Elemente und Strukturen identifizieren, klassifizieren und einfache Hypothesen zur Regelbildung …' AS kurzname, 'in Texten grammatische Elemente und Strukturen identifizieren, klassifizieren und einfache Hypothesen zur Regelbildung aufstellen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SLK_03' AS code, 'durch Erproben sprachlicher Mittel und kommunikativer Strategien die eigene Sprachkompetenz festigen und erweitern' AS kurzname, 'durch Erproben sprachlicher Mittel und kommunikativer Strategien die eigene Sprachkompetenz festigen und erweitern' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SLK_04' AS code, 'Übungs- und Testaufgaben zum systematischen Sprachentraining weitgehend selbstständig bearbeiten' AS kurzname, 'Übungs- und Testaufgaben zum systematischen Sprachentraining weitgehend selbstständig bearbeiten' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SLK_05' AS code, 'Hilfsmittel nutzen und erstellen, um analoge und digitale Texte und Arbeitsprodukte zu verstehen, erstellen und …' AS kurzname, 'Hilfsmittel nutzen und erstellen, um analoge und digitale Texte und Arbeitsprodukte zu verstehen, erstellen und überarbeiten sowie das eigene Sprachenlernen zu unterstützen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SLK_06' AS code, 'den eigenen Lernfortschritt auch anhand digitaler Evaluationsinstrumente' AS kurzname, 'den eigenen Lernfortschritt auch anhand digitaler Evaluationsinstrumente' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_SLK';
-- Erste Stufe · Sprachbewusstheit (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S1_SBW_01' AS code, 'grundlegende sprachliche Regelmäßigkeiten und Normabweichungen erkennen und beschreiben' AS kurzname, 'grundlegende sprachliche Regelmäßigkeiten und Normabweichungen erkennen und beschreiben' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SBW_02' AS code, 'grundlegende Unterschiede zwischen britischem und amerikanischem Englisch erkennen und beschreiben' AS kurzname, 'grundlegende Unterschiede zwischen britischem und amerikanischem Englisch erkennen und beschreiben' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SBW_03' AS code, 'im Vergleich des Englischen mit anderen Sprachen Ähnlichkeiten und Unterschiede erkennen und benennen' AS kurzname, 'im Vergleich des Englischen mit anderen Sprachen Ähnlichkeiten und Unterschiede erkennen und benennen' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SBW_04' AS code, 'grundlegende Beziehungen zwischen Sprach- und Kulturphänomenen erkennen und beschreiben' AS kurzname, 'grundlegende Beziehungen zwischen Sprach- und Kulturphänomenen erkennen und beschreiben' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SBW_05' AS code, 'das eigene und fremde Kommunikationsverhalten im Hinblick auf Kommunikationserfolge und -probleme ansatzweise …' AS kurzname, 'das eigene und fremde Kommunikationsverhalten im Hinblick auf Kommunikationserfolge und -probleme ansatzweise kritisch-konstruktiv reflektieren' AS beschreibung
  UNION ALL
  SELECT 'EN_S1_SBW_06' AS code, 'ihren mündlichen und schriftlichen Sprachgebrauch den Erfordernissen vertrauter Kommunikationssituationen entsprechend …' AS kurzname, 'ihren mündlichen und schriftlichen Sprachgebrauch den Erfordernissen vertrauter Kommunikationssituationen entsprechend steuern. 31' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S1_SBW';
-- Zweite Stufe · Funktionale kommunikative Kompetenz · Hör-/Hörsehverstehen (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_HOR_01' AS code, 'dem Verlauf von Gesprächen folgen und ihnen die Hauptpunkte und wichtige Details entnehmen' AS kurzname, 'dem Verlauf von Gesprächen folgen und ihnen die Hauptpunkte und wichtige Details entnehmen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_HOR_02' AS code, 'längeren Hör-/Hörsehtexten die Hauptpunkte und wichtige Details entnehmen' AS kurzname, 'längeren Hör-/Hörsehtexten die Hauptpunkte und wichtige Details entnehmen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_HOR_03' AS code, 'wesentliche Einstellungen der Sprechenden identifizieren' AS kurzname, 'wesentliche Einstellungen der Sprechenden identifizieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_HOR';
-- Zweite Stufe · Funktionale kommunikative Kompetenz · Leseverstehen (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_LES_01' AS code, 'komplexere Arbeitsanweisungen, Anleitungen und Erklärungen für ihren Lern- und Arbeitsprozess nutzen' AS kurzname, 'komplexere Arbeitsanweisungen, Anleitungen und Erklärungen für ihren Lern- und Arbeitsprozess nutzen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_LES_02' AS code, 'Sach- und Gebrauchstexten sowie literarischen Texten die Gesamtaussage, die Hauptpunkte und wichtige Details entnehmen' AS kurzname, 'Sach- und Gebrauchstexten sowie literarischen Texten die Gesamtaussage, die Hauptpunkte und wichtige Details entnehmen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_LES_03' AS code, 'Texten wesentliche implizite Informationen entnehmen' AS kurzname, 'Texten wesentliche implizite Informationen entnehmen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_LES';
-- Zweite Stufe · Funktionale kommunikative Kompetenz · Sprechen: an Gesprächen teilnehmen (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_SAG_01' AS code, 'an informellen, auch digital gestützten Gesprächen spontan aktiv teilnehmen' AS kurzname, 'an informellen, auch digital gestützten Gesprächen spontan aktiv teilnehmen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SAG_02' AS code, 'in unterschiedlichen Rollen an einfachen formellen Gesprächen aktiv teilnehmen' AS kurzname, 'in unterschiedlichen Rollen an einfachen formellen Gesprächen aktiv teilnehmen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SAG_03' AS code, 'Gespräche eröffnen, fortführen und beenden sowie bei sprachlichen Schwierigkeiten in der Regel aufrechterhalten' AS kurzname, 'Gespräche eröffnen, fortführen und beenden sowie bei sprachlichen Schwierigkeiten in der Regel aufrechterhalten' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SAG_04' AS code, 'auf Beiträge des Gesprächspartners in der Regel flexibel eingehen und wesentliche Verständnisprobleme ausräumen' AS kurzname, 'auf Beiträge des Gesprächspartners in der Regel flexibel eingehen und wesentliche Verständnisprobleme ausräumen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_SAG';
-- Zweite Stufe · Funktionale kommunikative Kompetenz · Sprechen: zusammenhängendes Sprechen (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_ZUS_01' AS code, 'Arbeitsergebnisse strukturiert vorstellen' AS kurzname, 'Arbeitsergebnisse strukturiert vorstellen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_ZUS_02' AS code, 'Inhalte von umfangreicheren Texten und Medien notizengestützt zusammenfassend wiedergeben' AS kurzname, 'Inhalte von umfangreicheren Texten und Medien notizengestützt zusammenfassend wiedergeben' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_ZUS_03' AS code, 'notizengestützt eine Präsentation strukturiert vortragen und dabei weitgehend funktional auf Materialien zur …' AS kurzname, 'notizengestützt eine Präsentation strukturiert vortragen und dabei weitgehend funktional auf Materialien zur Veranschaulichung eingehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_ZUS';
-- Zweite Stufe · Funktionale kommunikative Kompetenz · Schreiben (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_SCH_01' AS code, 'ein grundlegendes Spektrum von Texten in beschreibender, berichtender, erzählender, zusammenfassender, erklärender und …' AS kurzname, 'ein grundlegendes Spektrum von Texten in beschreibender, berichtender, erzählender, zusammenfassender, erklärender und argumentierender Absicht verfassen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SCH_02' AS code, 'kreativ gestaltend auch mehrfach kodierte Texte verfassen' AS kurzname, 'kreativ gestaltend auch mehrfach kodierte Texte verfassen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SCH_03' AS code, 'Texte mit Blick auf die Mitteilungsabsicht und den Adressaten auch kollaborativ überarbeiten' AS kurzname, 'Texte mit Blick auf die Mitteilungsabsicht und den Adressaten auch kollaborativ überarbeiten' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SCH_04' AS code, 'Arbeits-/Lernprozesse schriftlich planen und begleiten sowie Arbeitsergebnisse detailliert festhalten' AS kurzname, 'Arbeits-/Lernprozesse schriftlich planen und begleiten sowie Arbeitsergebnisse detailliert festhalten' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_SCH';
-- Zweite Stufe · Funktionale kommunikative Kompetenz · Sprachmittlung (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_SPM_01' AS code, 'auch in komplexeren Begegnungssituationen relevante schriftliche und mündliche Informationen mündlich sinngemäß …' AS kurzname, 'auch in komplexeren Begegnungssituationen relevante schriftliche und mündliche Informationen mündlich sinngemäß übertragen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SPM_02' AS code, 'in schriftlichen Kommunikationssituationen die relevanten Informationen aus Sach- und Gebrauchstexten, auch aus medial …' AS kurzname, 'in schriftlichen Kommunikationssituationen die relevanten Informationen aus Sach- und Gebrauchstexten, auch aus medial vermittelten, sinngemäß übertragen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SPM_03' AS code, 'gegebene Informationen auf der Grundlage ihrer interkulturellen kommunikativen Kompetenz weitgehend …' AS kurzname, 'gegebene Informationen auf der Grundlage ihrer interkulturellen kommunikativen Kompetenz weitgehend situationsangemessen und adressatengerecht bündeln sowie bei Bedarf ergänzen und erläutern' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_SPM';
-- Zweite Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Wortschatz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_VSM_WOR_01' AS code, 'einen allgemeinen sowie thematischen Wortschatz verstehen und situationsangemessen anwenden' AS kurzname, 'einen allgemeinen sowie thematischen Wortschatz verstehen und situationsangemessen anwenden' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_VSM_WOR_02' AS code, 'Vokabular zur Beschreibung und Erläuterung sprachlicher Elemente und Strukturen sowie zur Textbesprechung und …' AS kurzname, 'Vokabular zur Beschreibung und Erläuterung sprachlicher Elemente und Strukturen sowie zur Textbesprechung und Textproduktion verstehen und anwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_VSM_WOR';
-- Zweite Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Grammatik (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_VSM_GRA_01' AS code, 'komplexe Sachverhalte in Satzgefügen formulieren sowie räumliche, zeitliche und logische Bezüge herstellen' AS kurzname, 'komplexe Sachverhalte in Satzgefügen formulieren sowie räumliche, zeitliche und logische Bezüge herstellen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_VSM_GRA_02' AS code, 'weitere Aspekte des Zukünftigen ausdrücken' AS kurzname, 'weitere Aspekte des Zukünftigen ausdrücken' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_VSM_GRA_03' AS code, 'weitere Modalitäten ausdrücken' AS kurzname, 'weitere Modalitäten ausdrücken' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_VSM_GRA_04' AS code, 'Formen der Emphase sowie Gefühle und Meinungen äußern' AS kurzname, 'Formen der Emphase sowie Gefühle und Meinungen äußern' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_VSM_GRA_05' AS code, 'Zeit und Aspekt in ihren unterschiedlichen Bedeutungsnuancen verstehen' AS kurzname, 'Zeit und Aspekt in ihren unterschiedlichen Bedeutungsnuancen verstehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_VSM_GRA';
-- Zweite Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Aussprache und Intonation (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_VSM_AUS_01' AS code, 'ihr erweitertes Repertoire an Aussprache- und Intonationsmustern beachten und auf neue Wörter und Sätze übertragen' AS kurzname, 'ihr erweitertes Repertoire an Aussprache- und Intonationsmustern beachten und auf neue Wörter und Sätze übertragen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_VSM_AUS_02' AS code, 'die Wörter ihres erweiterten Wortschatzes aussprechen' AS kurzname, 'die Wörter ihres erweiterten Wortschatzes aussprechen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_VSM_AUS_03' AS code, 'in Aussagen Intonationsmuster mit Bedeutungsimplikationen weitgehend angemessen realisieren' AS kurzname, 'in Aussagen Intonationsmuster mit Bedeutungsimplikationen weitgehend angemessen realisieren' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_VSM_AUS_04' AS code, 'weitere gängige Aussprachevarietäten erkennen und weitgehend verstehen' AS kurzname, 'weitere gängige Aussprachevarietäten erkennen und weitgehend verstehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_VSM_AUS';
-- Zweite Stufe · Funktionale kommunikative Kompetenz · Verfügen über sprachliche Mittel · Orthografie (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_VSM_ORT_01' AS code, 'ein erweitertes Repertoire grundlegender Regeln der Rechtschreibung und Zeichensetzung anwenden, auch in Abgrenzung zur …' AS kurzname, 'ein erweitertes Repertoire grundlegender Regeln der Rechtschreibung und Zeichensetzung anwenden, auch in Abgrenzung zur deutschen Sprache' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_VSM_ORT_02' AS code, 'die Wörter ihres erweiterten Wortschatzes schreiben' AS kurzname, 'die Wörter ihres erweiterten Wortschatzes schreiben' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_VSM_ORT';
-- Zweite Stufe · Interkulturelle kommunikative Kompetenz · Soziokulturelles Orientierungswissen (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_IKK_SOW_01' AS code, 'auf ein erweitertes soziokulturelles Orientierungswissen zu anglophonen Lebenswirklichkeiten im Vereinigten Königreich, …' AS kurzname, 'auf ein erweitertes soziokulturelles Orientierungswissen zu anglophonen Lebenswirklichkeiten im Vereinigten Königreich, in den USA und einem weiteren anglophonen Land zurückgreifen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_IKK_SOW';
-- Zweite Stufe · Interkulturelle kommunikative Kompetenz · Interkulturelle Einstellungen und Bewusstheit (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_IKK_EIN_01' AS code, 'sich der Chancen und Herausforderungen kultureller Vielfalt kritisch-reflektiert bewusst sein und neuen Erfahrungen mit …' AS kurzname, 'sich der Chancen und Herausforderungen kultureller Vielfalt kritisch-reflektiert bewusst sein und neuen Erfahrungen mit anderen Kulturen grundsätzlich offen und lernbereit begegnen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_IKK_EIN_02' AS code, 'eigen- und fremdkulturelle Wertvorstellungen, Einstellungen und Lebensstile differenziert vergleichen und sie – auch …' AS kurzname, 'eigen- und fremdkulturelle Wertvorstellungen, Einstellungen und Lebensstile differenziert vergleichen und sie – auch selbstkritisch und aus Gender-Perspektive – in Frage stellen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_IKK_EIN';
-- Zweite Stufe · Interkulturelle kommunikative Kompetenz · Interkulturelles Verstehen und Handeln (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_IKK_VER_01' AS code, '(inter-)kulturelle Stereotype/Klischees und Vorurteile differenziert erläutern' AS kurzname, '(inter-)kulturelle Stereotype/Klischees und Vorurteile differenziert erläutern' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_IKK_VER_02' AS code, 'sich aktiv in Denk- und Verhaltensweisen von Menschen anderer Kulturen hineinversetzen und dadurch Verständnis für den …' AS kurzname, 'sich aktiv in Denk- und Verhaltensweisen von Menschen anderer Kulturen hineinversetzen und dadurch Verständnis für den anderen bzw. kritische Distanz entwickeln' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_IKK_VER_03' AS code, 'in interkulturellen Kommunikationssituationen kulturspezifische Konventionen und Besonderheiten des …' AS kurzname, 'in interkulturellen Kommunikationssituationen kulturspezifische Konventionen und Besonderheiten des Kommunikationsverhaltens respektvoll beachten sowie sprachlich-kulturell bedingte Missverständnisse und Konflikte weitgehend überwinden' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_IKK_VER_04' AS code, 'sich mit englischsprachigen Kommunikationspartnern über kulturelle Gemeinsamkeiten und Unterschiede …' AS kurzname, 'sich mit englischsprachigen Kommunikationspartnern über kulturelle Gemeinsamkeiten und Unterschiede tolerant-wertschätzend austauschen, erforderlichenfalls aber auch kritisch-distanzierend diskutieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_IKK_VER';
-- Zweite Stufe · Text- und Medienkompetenz (7)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_TMK_01' AS code, 'unter Einsatz von Texterschließungsverfahren authentische Texte vertrauter Thematik bezogen auf Thema, Inhalt, …' AS kurzname, 'unter Einsatz von Texterschließungsverfahren authentische Texte vertrauter Thematik bezogen auf Thema, Inhalt, Textaufbau, Aussage und wesentliche Textsortenmerkmale untersuchen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_TMK_02' AS code, 'themenrelevante Informationen und Daten aus Texten und Medien identifizieren, filtern, strukturieren und aufbereiten' AS kurzname, 'themenrelevante Informationen und Daten aus Texten und Medien identifizieren, filtern, strukturieren und aufbereiten' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_TMK_03' AS code, 'in Texten und Medien vermittelte Absichten untersuchen und kritisch bewerten' AS kurzname, 'in Texten und Medien vermittelte Absichten untersuchen und kritisch bewerten' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_TMK_04' AS code, 'grundlegende Gestaltungsmittel von Texten und Medien beschreiben, analysieren sowie hinsichtlich ihrer Wirkung …' AS kurzname, 'grundlegende Gestaltungsmittel von Texten und Medien beschreiben, analysieren sowie hinsichtlich ihrer Wirkung beurteilen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_TMK_05' AS code, 'Arbeitsergebnisse mithilfe von digitalen Werkzeugen adressatengerecht gestalten und präsentieren' AS kurzname, 'Arbeitsergebnisse mithilfe von digitalen Werkzeugen adressatengerecht gestalten und präsentieren' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_TMK_06' AS code, 'unter Einsatz produktionsorientierter Verfahren digitale Texte und Medienprodukte erstellen' AS kurzname, 'unter Einsatz produktionsorientierter Verfahren digitale Texte und Medienprodukte erstellen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_TMK_07' AS code, 'unter Einsatz produktionsorientierter Verfahren die Wirkung von Texten und Medien erkunden' AS kurzname, 'unter Einsatz produktionsorientierter Verfahren die Wirkung von Texten und Medien erkunden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_TMK';
-- Zweite Stufe · Sprachlernkompetenz (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_SLK_01' AS code, 'auch komplexere anwendungsorientierte Formen der Wortschatzarbeit einsetzen' AS kurzname, 'auch komplexere anwendungsorientierte Formen der Wortschatzarbeit einsetzen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SLK_02' AS code, 'in Texten grammatische Elemente und Strukturen identifizieren, klassifizieren und Hypothesen zur Regelbildung aufstellen' AS kurzname, 'in Texten grammatische Elemente und Strukturen identifizieren, klassifizieren und Hypothesen zur Regelbildung aufstellen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SLK_03' AS code, 'durch Erproben sprachlicher Mittel und kommunikativer Strategien die eigene Sprachkompetenz gezielt festigen und …' AS kurzname, 'durch Erproben sprachlicher Mittel und kommunikativer Strategien die eigene Sprachkompetenz gezielt festigen und erweitern' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SLK_04' AS code, 'auch digitale Hilfsmittel nutzen und erstellen, um analoge und digitale Texte und Arbeitsprodukte zu verstehen, zu …' AS kurzname, 'auch digitale Hilfsmittel nutzen und erstellen, um analoge und digitale Texte und Arbeitsprodukte zu verstehen, zu erstellen und zu überarbeiten sowie das eigene Sprachenlernen zu unterstützen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SLK_05' AS code, 'den eigenen Lernfortschritt auch an-' AS kurzname, 'den eigenen Lernfortschritt auch an-' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_SLK';
-- Zweite Stufe · Sprachbewusstheit (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'EN_S2_SBW_01' AS code, 'grundlegende sprachliche Regelmäßigkeiten, Normabweichungen und Varietäten erkennen und beschreiben' AS kurzname, 'grundlegende sprachliche Regelmäßigkeiten, Normabweichungen und Varietäten erkennen und beschreiben' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SBW_02' AS code, 'grundlegende Beziehungen zwischen Sprach- und Kulturphänomenen erkennen und beschreiben' AS kurzname, 'grundlegende Beziehungen zwischen Sprach- und Kulturphänomenen erkennen und beschreiben' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SBW_03' AS code, 'ihr Sprachhandeln weitgehend bedarfsgerecht planen' AS kurzname, 'ihr Sprachhandeln weitgehend bedarfsgerecht planen' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SBW_04' AS code, 'das eigene und fremde Kommunikationsverhalten im Hinblick auf Kommunikationserfolge und -probleme kritisch-konstruktiv …' AS kurzname, 'das eigene und fremde Kommunikationsverhalten im Hinblick auf Kommunikationserfolge und -probleme kritisch-konstruktiv reflektieren' AS beschreibung
  UNION ALL
  SELECT 'EN_S2_SBW_05' AS code, 'ihren mündlichen und schriftlichen Sprachgebrauch den Erfordernissen der jeweiligen Kommunikationssituation …' AS kurzname, 'ihren mündlichen und schriftlichen Sprachgebrauch den Erfordernissen der jeweiligen Kommunikationssituation entsprechend steuern. 39' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'EN_S2_SBW';

COMMIT;

-- Kontrolle: erwartet Knoten=57 (davon 48 Blaetter), Kompetenzen=177
