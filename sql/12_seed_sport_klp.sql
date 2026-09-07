-- =============================================================================
-- Seed 12: Sport – Kernlehrplan Gymnasium Sek I (G9), NRW 2019 (Heft 3426)
-- Ersetzt das veraltete 09_seed_sport_konkrete_erwartungen.sql.
--
-- Quelle: docs/curricula/g9_sp_klp_3426_2019_06_23.pdf
-- SHA256: 815f985166f45bc136ae3fc28aff4b0214b29b9862aa0eb33df312e32e950351
-- Erzeugt von: sql/gen/gen_sport_klp.py
--
-- NICHT VON HAND AENDERN: Korrekturen gehoeren in den Erzeuger, die Datei
-- wird daraus neu geschrieben (E19).
-- Voraussetzung: Migration 08 und Migration 13 (Spalte `art`).
-- Idempotent: loescht vorhandenen SPO_KLP-Rahmen und baut ihn neu auf.
-- =============================================================================

SET NAMES utf8mb4;
START TRANSACTION;

SET @schule := 1;
SET @fach := (SELECT id FROM faecher WHERE schule_id = @schule AND kuerzel = 'SP' LIMIT 1);

-- Nur der eigene Rahmen wird geloescht; CASCADE raeumt Bereiche und Kompetenzen.
DELETE FROM kompetenzrahmen WHERE schule_id = @schule AND kuerzel = 'SPO_KLP';

INSERT INTO kompetenzrahmen (schule_id, name, kuerzel, beschreibung, quelle_url, fach_id)
VALUES (@schule, 'Sport KLP NRW G9 Sek I (FRG)', 'SPO_KLP', 'Kernlehrplan Sport, Gymnasium Sekundarstufe I (G9), NRW 2019. Kompetenzbereiche BWK/SK/MK/UK; sechs Inhaltsfelder (a-f) und neun Bewegungsfelder/Sportbereiche; gegliedert nach Erprobungsstufe und Ende Sek I.', 'docs/curricula/g9_sp_klp_3426_2019_06_23.pdf', @fach);
SET @rahmen := LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Kompetenzbereiche
--
-- Zwei Ebenen (E29b, E31): je Phase und Gegenstand ein Wurzelknoten,
-- darunter die Kompetenzbereiche als Blaetter. Kompetenzen haengen nur
-- an den Blaettern; die Phase steht als Spalte an jedem Knoten.
--
-- `art` sagt jetzt, was der KNOTEN ist -- nicht mehr, was in der Spalte
-- `inhaltsfeld` steht. Sport ist das einzige Fach mit zwei Achsen: sechs
-- Inhaltsfelder (a-f) und neun Bewegungsfelder (BF/SB 1-9) stehen
-- nebeneinander auf derselben Ebene. Die Wurzelknoten tragen deshalb
-- 'inhaltsfeld' bzw. 'bewegungsfeld', die Blaetter 'kompetenzbereich'.
-- --------------------------------------------------------------------------
INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art) VALUES
(@rahmen, NULL, 'SPO_EP_IFA', 'Erprobungsstufe · a: Bewegungsstruktur und Bewegungslernen', 1, 'erprobungsstufe', 'inhaltsfeld'),
(@rahmen, NULL, 'SPO_EP_IFB', 'Erprobungsstufe · b: Bewegungsgestaltung', 5, 'erprobungsstufe', 'inhaltsfeld'),
(@rahmen, NULL, 'SPO_EP_IFC', 'Erprobungsstufe · c: Wagnis und Verantwortung', 9, 'erprobungsstufe', 'inhaltsfeld'),
(@rahmen, NULL, 'SPO_EP_IFD', 'Erprobungsstufe · d: Leistung', 13, 'erprobungsstufe', 'inhaltsfeld'),
(@rahmen, NULL, 'SPO_EP_IFE', 'Erprobungsstufe · e: Kooperation und Konkurrenz', 17, 'erprobungsstufe', 'inhaltsfeld'),
(@rahmen, NULL, 'SPO_EP_IFF', 'Erprobungsstufe · f: Gesundheit', 21, 'erprobungsstufe', 'inhaltsfeld'),
(@rahmen, NULL, 'SPO_EP_BF1', 'Erprobungsstufe · BF/SB 1: Den Körper wahrnehmen und Bewegungsfähigkeiten ausprägen', 25, 'erprobungsstufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_EP_BF2', 'Erprobungsstufe · BF/SB 2: Das Spielen entdecken und Spielräume nutzen', 27, 'erprobungsstufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_EP_BF3', 'Erprobungsstufe · BF/SB 3: Laufen, Springen, Werfen – Leichtathletik', 29, 'erprobungsstufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_EP_BF4', 'Erprobungsstufe · BF/SB 4: Bewegen im Wasser – Schwimmen', 31, 'erprobungsstufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_EP_BF5', 'Erprobungsstufe · BF/SB 5: Bewegen an Geräten – Turnen', 33, 'erprobungsstufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_EP_BF6', 'Erprobungsstufe · BF/SB 6: Gestalten, Tanzen, Darstellen – Gymnastik/Tanz, Bewegungskünste', 35, 'erprobungsstufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_EP_BF7', 'Erprobungsstufe · BF/SB 7: Spielen in und mit Regelstrukturen – Sportspiele', 37, 'erprobungsstufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_EP_BF8', 'Erprobungsstufe · BF/SB 8: Gleiten, Fahren, Rollen – Rollsport, Bootssport, Wintersport', 39, 'erprobungsstufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_EP_BF9', 'Erprobungsstufe · BF/SB 9: Ringen und Kämpfen – Zweikampfsport', 41, 'erprobungsstufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_SI_IFA', 'Sekundarstufe I · a: Bewegungsstruktur und Bewegungslernen', 43, 'zweite_stufe', 'inhaltsfeld'),
(@rahmen, NULL, 'SPO_SI_IFB', 'Sekundarstufe I · b: Bewegungsgestaltung', 47, 'zweite_stufe', 'inhaltsfeld'),
(@rahmen, NULL, 'SPO_SI_IFC', 'Sekundarstufe I · c: Wagnis und Verantwortung', 51, 'zweite_stufe', 'inhaltsfeld'),
(@rahmen, NULL, 'SPO_SI_IFD', 'Sekundarstufe I · d: Leistung', 55, 'zweite_stufe', 'inhaltsfeld'),
(@rahmen, NULL, 'SPO_SI_IFE', 'Sekundarstufe I · e: Kooperation und Konkurrenz', 59, 'zweite_stufe', 'inhaltsfeld'),
(@rahmen, NULL, 'SPO_SI_IFF', 'Sekundarstufe I · f: Gesundheit', 63, 'zweite_stufe', 'inhaltsfeld'),
(@rahmen, NULL, 'SPO_SI_BF1', 'Sekundarstufe I · BF/SB 1: Den Körper wahrnehmen und Bewegungsfähigkeiten ausprägen', 67, 'zweite_stufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_SI_BF2', 'Sekundarstufe I · BF/SB 2: Das Spielen entdecken und Spielräume nutzen', 69, 'zweite_stufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_SI_BF3', 'Sekundarstufe I · BF/SB 3: Laufen, Springen, Werfen – Leichtathletik', 71, 'zweite_stufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_SI_BF4', 'Sekundarstufe I · BF/SB 4: Bewegen im Wasser – Schwimmen', 73, 'zweite_stufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_SI_BF5', 'Sekundarstufe I · BF/SB 5: Bewegen an Geräten – Turnen', 75, 'zweite_stufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_SI_BF6', 'Sekundarstufe I · BF/SB 6: Gestalten, Tanzen, Darstellen – Gymnastik/Tanz, Bewegungskünste', 77, 'zweite_stufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_SI_BF7', 'Sekundarstufe I · BF/SB 7: Spielen in und mit Regelstrukturen – Sportspiele', 79, 'zweite_stufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_SI_BF8', 'Sekundarstufe I · BF/SB 8: Gleiten, Fahren, Rollen – Rollsport, Bootssport, Wintersport', 81, 'zweite_stufe', 'bewegungsfeld'),
(@rahmen, NULL, 'SPO_SI_BF9', 'Sekundarstufe I · BF/SB 9: Ringen und Kämpfen – Zweikampfsport', 83, 'zweite_stufe', 'bewegungsfeld');

-- Blaetter: parent_id wird ueber den Code des Wurzelknotens aufgeloest.
INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art)
SELECT @rahmen, p.id, t.code, t.name, t.reihenfolge, t.phase, t.art
FROM (
  SELECT 'SPO_EP_IFA_SK' AS code, 'Erprobungsstufe · a: Bewegungsstruktur und Bewegungslernen · Sachkompetenz' AS name, 2 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFA' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFA_MK' AS code, 'Erprobungsstufe · a: Bewegungsstruktur und Bewegungslernen · Methodenkompetenz' AS name, 3 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFA' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFA_UK' AS code, 'Erprobungsstufe · a: Bewegungsstruktur und Bewegungslernen · Urteilskompetenz' AS name, 4 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFA' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFB_SK' AS code, 'Erprobungsstufe · b: Bewegungsgestaltung · Sachkompetenz' AS name, 6 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFB' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFB_MK' AS code, 'Erprobungsstufe · b: Bewegungsgestaltung · Methodenkompetenz' AS name, 7 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFB' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFB_UK' AS code, 'Erprobungsstufe · b: Bewegungsgestaltung · Urteilskompetenz' AS name, 8 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFB' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFC_SK' AS code, 'Erprobungsstufe · c: Wagnis und Verantwortung · Sachkompetenz' AS name, 10 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFC' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFC_MK' AS code, 'Erprobungsstufe · c: Wagnis und Verantwortung · Methodenkompetenz' AS name, 11 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFC' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFC_UK' AS code, 'Erprobungsstufe · c: Wagnis und Verantwortung · Urteilskompetenz' AS name, 12 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFC' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFD_SK' AS code, 'Erprobungsstufe · d: Leistung · Sachkompetenz' AS name, 14 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFD' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFD_MK' AS code, 'Erprobungsstufe · d: Leistung · Methodenkompetenz' AS name, 15 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFD' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFD_UK' AS code, 'Erprobungsstufe · d: Leistung · Urteilskompetenz' AS name, 16 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFD' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFE_SK' AS code, 'Erprobungsstufe · e: Kooperation und Konkurrenz · Sachkompetenz' AS name, 18 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFE' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFE_MK' AS code, 'Erprobungsstufe · e: Kooperation und Konkurrenz · Methodenkompetenz' AS name, 19 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFE' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFE_UK' AS code, 'Erprobungsstufe · e: Kooperation und Konkurrenz · Urteilskompetenz' AS name, 20 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFE' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFF_SK' AS code, 'Erprobungsstufe · f: Gesundheit · Sachkompetenz' AS name, 22 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFF' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFF_MK' AS code, 'Erprobungsstufe · f: Gesundheit · Methodenkompetenz' AS name, 23 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFF' AS pcode
  UNION ALL
  SELECT 'SPO_EP_IFF_UK' AS code, 'Erprobungsstufe · f: Gesundheit · Urteilskompetenz' AS name, 24 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_IFF' AS pcode
  UNION ALL
  SELECT 'SPO_EP_BF1_BWK' AS code, 'Erprobungsstufe · BF/SB 1: Den Körper wahrnehmen und Bewegungsfähigkeiten ausprägen · Bewegungs- und Wahrnehmungskompetenz' AS name, 26 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_BF1' AS pcode
  UNION ALL
  SELECT 'SPO_EP_BF2_BWK' AS code, 'Erprobungsstufe · BF/SB 2: Das Spielen entdecken und Spielräume nutzen · Bewegungs- und Wahrnehmungskompetenz' AS name, 28 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_BF2' AS pcode
  UNION ALL
  SELECT 'SPO_EP_BF3_BWK' AS code, 'Erprobungsstufe · BF/SB 3: Laufen, Springen, Werfen – Leichtathletik · Bewegungs- und Wahrnehmungskompetenz' AS name, 30 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_BF3' AS pcode
  UNION ALL
  SELECT 'SPO_EP_BF4_BWK' AS code, 'Erprobungsstufe · BF/SB 4: Bewegen im Wasser – Schwimmen · Bewegungs- und Wahrnehmungskompetenz' AS name, 32 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_BF4' AS pcode
  UNION ALL
  SELECT 'SPO_EP_BF5_BWK' AS code, 'Erprobungsstufe · BF/SB 5: Bewegen an Geräten – Turnen · Bewegungs- und Wahrnehmungskompetenz' AS name, 34 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_BF5' AS pcode
  UNION ALL
  SELECT 'SPO_EP_BF6_BWK' AS code, 'Erprobungsstufe · BF/SB 6: Gestalten, Tanzen, Darstellen – Gymnastik/Tanz, Bewegungskünste · Bewegungs- und Wahrnehmungskompetenz' AS name, 36 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_BF6' AS pcode
  UNION ALL
  SELECT 'SPO_EP_BF7_BWK' AS code, 'Erprobungsstufe · BF/SB 7: Spielen in und mit Regelstrukturen – Sportspiele · Bewegungs- und Wahrnehmungskompetenz' AS name, 38 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_BF7' AS pcode
  UNION ALL
  SELECT 'SPO_EP_BF8_BWK' AS code, 'Erprobungsstufe · BF/SB 8: Gleiten, Fahren, Rollen – Rollsport, Bootssport, Wintersport · Bewegungs- und Wahrnehmungskompetenz' AS name, 40 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_BF8' AS pcode
  UNION ALL
  SELECT 'SPO_EP_BF9_BWK' AS code, 'Erprobungsstufe · BF/SB 9: Ringen und Kämpfen – Zweikampfsport · Bewegungs- und Wahrnehmungskompetenz' AS name, 42 AS reihenfolge, 'erprobungsstufe' AS phase, 'kompetenzbereich' AS art, 'SPO_EP_BF9' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFA_SK' AS code, 'Sekundarstufe I · a: Bewegungsstruktur und Bewegungslernen · Sachkompetenz' AS name, 44 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFA' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFA_MK' AS code, 'Sekundarstufe I · a: Bewegungsstruktur und Bewegungslernen · Methodenkompetenz' AS name, 45 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFA' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFA_UK' AS code, 'Sekundarstufe I · a: Bewegungsstruktur und Bewegungslernen · Urteilskompetenz' AS name, 46 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFA' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFB_SK' AS code, 'Sekundarstufe I · b: Bewegungsgestaltung · Sachkompetenz' AS name, 48 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFB' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFB_MK' AS code, 'Sekundarstufe I · b: Bewegungsgestaltung · Methodenkompetenz' AS name, 49 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFB' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFB_UK' AS code, 'Sekundarstufe I · b: Bewegungsgestaltung · Urteilskompetenz' AS name, 50 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFB' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFC_SK' AS code, 'Sekundarstufe I · c: Wagnis und Verantwortung · Sachkompetenz' AS name, 52 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFC' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFC_MK' AS code, 'Sekundarstufe I · c: Wagnis und Verantwortung · Methodenkompetenz' AS name, 53 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFC' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFC_UK' AS code, 'Sekundarstufe I · c: Wagnis und Verantwortung · Urteilskompetenz' AS name, 54 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFC' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFD_SK' AS code, 'Sekundarstufe I · d: Leistung · Sachkompetenz' AS name, 56 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFD' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFD_MK' AS code, 'Sekundarstufe I · d: Leistung · Methodenkompetenz' AS name, 57 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFD' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFD_UK' AS code, 'Sekundarstufe I · d: Leistung · Urteilskompetenz' AS name, 58 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFD' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFE_SK' AS code, 'Sekundarstufe I · e: Kooperation und Konkurrenz · Sachkompetenz' AS name, 60 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFE' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFE_MK' AS code, 'Sekundarstufe I · e: Kooperation und Konkurrenz · Methodenkompetenz' AS name, 61 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFE' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFE_UK' AS code, 'Sekundarstufe I · e: Kooperation und Konkurrenz · Urteilskompetenz' AS name, 62 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFE' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFF_SK' AS code, 'Sekundarstufe I · f: Gesundheit · Sachkompetenz' AS name, 64 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFF' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFF_MK' AS code, 'Sekundarstufe I · f: Gesundheit · Methodenkompetenz' AS name, 65 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFF' AS pcode
  UNION ALL
  SELECT 'SPO_SI_IFF_UK' AS code, 'Sekundarstufe I · f: Gesundheit · Urteilskompetenz' AS name, 66 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_IFF' AS pcode
  UNION ALL
  SELECT 'SPO_SI_BF1_BWK' AS code, 'Sekundarstufe I · BF/SB 1: Den Körper wahrnehmen und Bewegungsfähigkeiten ausprägen · Bewegungs- und Wahrnehmungskompetenz' AS name, 68 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_BF1' AS pcode
  UNION ALL
  SELECT 'SPO_SI_BF2_BWK' AS code, 'Sekundarstufe I · BF/SB 2: Das Spielen entdecken und Spielräume nutzen · Bewegungs- und Wahrnehmungskompetenz' AS name, 70 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_BF2' AS pcode
  UNION ALL
  SELECT 'SPO_SI_BF3_BWK' AS code, 'Sekundarstufe I · BF/SB 3: Laufen, Springen, Werfen – Leichtathletik · Bewegungs- und Wahrnehmungskompetenz' AS name, 72 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_BF3' AS pcode
  UNION ALL
  SELECT 'SPO_SI_BF4_BWK' AS code, 'Sekundarstufe I · BF/SB 4: Bewegen im Wasser – Schwimmen · Bewegungs- und Wahrnehmungskompetenz' AS name, 74 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_BF4' AS pcode
  UNION ALL
  SELECT 'SPO_SI_BF5_BWK' AS code, 'Sekundarstufe I · BF/SB 5: Bewegen an Geräten – Turnen · Bewegungs- und Wahrnehmungskompetenz' AS name, 76 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_BF5' AS pcode
  UNION ALL
  SELECT 'SPO_SI_BF6_BWK' AS code, 'Sekundarstufe I · BF/SB 6: Gestalten, Tanzen, Darstellen – Gymnastik/Tanz, Bewegungskünste · Bewegungs- und Wahrnehmungskompetenz' AS name, 78 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_BF6' AS pcode
  UNION ALL
  SELECT 'SPO_SI_BF7_BWK' AS code, 'Sekundarstufe I · BF/SB 7: Spielen in und mit Regelstrukturen – Sportspiele · Bewegungs- und Wahrnehmungskompetenz' AS name, 80 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_BF7' AS pcode
  UNION ALL
  SELECT 'SPO_SI_BF8_BWK' AS code, 'Sekundarstufe I · BF/SB 8: Gleiten, Fahren, Rollen – Rollsport, Bootssport, Wintersport · Bewegungs- und Wahrnehmungskompetenz' AS name, 82 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_BF8' AS pcode
  UNION ALL
  SELECT 'SPO_SI_BF9_BWK' AS code, 'Sekundarstufe I · BF/SB 9: Ringen und Kämpfen – Zweikampfsport · Bewegungs- und Wahrnehmungskompetenz' AS name, 84 AS reihenfolge, 'zweite_stufe' AS phase, 'kompetenzbereich' AS art, 'SPO_SI_BF9' AS pcode
) t JOIN kompetenzbereiche p ON p.rahmen_id = @rahmen AND p.code = t.pcode;

-- --------------------------------------------------------------------------
-- Kompetenzerwartungen (flach)
-- --------------------------------------------------------------------------
-- Erprobungsstufe · a: Bewegungsstruktur und Bewegungslernen · Sachkompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFA_SK_01' AS code, 'unterschiedliche Körperempfindungen und Körperwahrnehmungen in vielfältigen Bewegungssituationen beschreiben' AS kurzname, 'unterschiedliche Körperempfindungen und Körperwahrnehmungen in vielfältigen Bewegungssituationen beschreiben' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_IFA_SK_02' AS code, 'wesentliche Bewegungsmerkmale einfacher Bewegungsabläufe benennen' AS kurzname, 'wesentliche Bewegungsmerkmale einfacher Bewegungsabläufe benennen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFA_SK';
-- Erprobungsstufe · a: Bewegungsstruktur und Bewegungslernen · Methodenkompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFA_MK_01' AS code, 'mediengestützte Bewegungsbeobachtungen zur kriteriengeleiteten Rückmeldung auf grundlegendem Niveau nutzen' AS kurzname, 'mediengestützte Bewegungsbeobachtungen zur kriteriengeleiteten Rückmeldung auf grundlegendem Niveau nutzen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_IFA_MK_02' AS code, 'einfache Hilfen (Hilfestellungen, Geländehilfen, Visualisierungen, akustische Signale) beim Erlernen und Üben …' AS kurzname, 'einfache Hilfen (Hilfestellungen, Geländehilfen, Visualisierungen, akustische Signale) beim Erlernen und Üben sportlicher Bewegungen verwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFA_MK';
-- Erprobungsstufe · a: Bewegungsstruktur und Bewegungslernen · Urteilskompetenz (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFA_UK_01' AS code, 'einfache Bewegungsabläufe hinsichtlich der Bewegungsqualität auf grundlegendem Niveau kriteriengeleitet beurteilen' AS kurzname, 'einfache Bewegungsabläufe hinsichtlich der Bewegungsqualität auf grundlegendem Niveau kriteriengeleitet beurteilen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFA_UK';
-- Erprobungsstufe · b: Bewegungsgestaltung · Sachkompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFB_SK_01' AS code, 'Grundformen gestalterischen Bewegens (in zwei Bewegungsfeldern) benennen' AS kurzname, 'Grundformen gestalterischen Bewegens (in zwei Bewegungsfeldern) benennen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_IFB_SK_02' AS code, 'grundlegende Aufstellungsformen und Formationen benennen' AS kurzname, 'grundlegende Aufstellungsformen und Formationen benennen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFB_SK';
-- Erprobungsstufe · b: Bewegungsgestaltung · Methodenkompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFB_MK_01' AS code, 'Grundformen gestalterischen Bewegens nach- und umgestalten' AS kurzname, 'Grundformen gestalterischen Bewegens nach- und umgestalten' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_IFB_MK_02' AS code, 'einfache kreative Bewegungsgestaltungen entwickeln und zu einer Präsentation verbinden' AS kurzname, 'einfache kreative Bewegungsgestaltungen entwickeln und zu einer Präsentation verbinden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFB_MK';
-- Erprobungsstufe · b: Bewegungsgestaltung · Urteilskompetenz (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFB_UK_01' AS code, 'kreative, gestalterische Präsentationen anhand grundlegender Kriterien beurteilen' AS kurzname, 'kreative, gestalterische Präsentationen anhand grundlegender Kriterien beurteilen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFB_UK';
-- Erprobungsstufe · c: Wagnis und Verantwortung · Sachkompetenz (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFC_SK_01' AS code, 'die Herausforderungen in einfachen sportlichen Handlungssituationen im Hinblick auf die Anforderung, das eigene Können …' AS kurzname, 'die Herausforderungen in einfachen sportlichen Handlungssituationen im Hinblick auf die Anforderung, das eigene Können und mögliche Gefahren beschreiben' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFC_SK';
-- Erprobungsstufe · c: Wagnis und Verantwortung · Methodenkompetenz (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFC_MK_01' AS code, 'verlässlich verbale und nonverbale Unterstützung bei sportlichen Handlungssituationen geben und gezielt nutzen' AS kurzname, 'verlässlich verbale und nonverbale Unterstützung bei sportlichen Handlungssituationen geben und gezielt nutzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFC_MK';
-- Erprobungsstufe · c: Wagnis und Verantwortung · Urteilskompetenz (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFC_UK_01' AS code, 'einfache sportliche Wagnissituationen für sich situativ einschätzen und anhand ausgewählter Kriterien beurteilen' AS kurzname, 'einfache sportliche Wagnissituationen für sich situativ einschätzen und anhand ausgewählter Kriterien beurteilen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFC_UK';
-- Erprobungsstufe · d: Leistung · Sachkompetenz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFD_SK_01' AS code, 'die motorischen Grundfähigkeiten (Kraft, Schnelligkeit, Ausdauer, Beweglichkeit) in unterschiedlichen …' AS kurzname, 'die motorischen Grundfähigkeiten (Kraft, Schnelligkeit, Ausdauer, Beweglichkeit) in unterschiedlichen Anforderungssituationen benennen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_IFD_SK_02' AS code, 'psycho-physische Leistungsfaktoren (u.a. Anstrengungsbereitschaft, Konzentrationsfähigkeit) in unterschiedlichen …' AS kurzname, 'psycho-physische Leistungsfaktoren (u.a. Anstrengungsbereitschaft, Konzentrationsfähigkeit) in unterschiedlichen Anforderungssituationen benennen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_IFD_SK_03' AS code, 'psycho-physische Reaktionen des Körpers in sportlichen Anforderungssituationen beschreiben' AS kurzname, 'psycho-physische Reaktionen des Körpers in sportlichen Anforderungssituationen beschreiben' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFD_SK';
-- Erprobungsstufe · d: Leistung · Methodenkompetenz (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFD_MK_01' AS code, 'einfache Methoden zur Erfassung von körperlicher Leistungsfähigkeit anwenden' AS kurzname, 'einfache Methoden zur Erfassung von körperlicher Leistungsfähigkeit anwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFD_MK';
-- Erprobungsstufe · d: Leistung · Urteilskompetenz (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFD_UK_01' AS code, 'ihre individuelle Leistungsfähigkeit in unterschiedlichen sportbezogenen Situationen anhand ausgewählter Kriterien auf …' AS kurzname, 'ihre individuelle Leistungsfähigkeit in unterschiedlichen sportbezogenen Situationen anhand ausgewählter Kriterien auf grundlegendem Niveau beurteilen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFD_UK';
-- Erprobungsstufe · e: Kooperation und Konkurrenz · Sachkompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFE_SK_01' AS code, 'Merkmale für faires, kooperatives und teamorientiertes sportliches Handeln benennen' AS kurzname, 'Merkmale für faires, kooperatives und teamorientiertes sportliches Handeln benennen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_IFE_SK_02' AS code, 'sportartspezifische Vereinbarungen, Regeln und Messverfahren in unterschiedlichen Bewegungsfeldern beschreiben' AS kurzname, 'sportartspezifische Vereinbarungen, Regeln und Messverfahren in unterschiedlichen Bewegungsfeldern beschreiben' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFE_SK';
-- Erprobungsstufe · e: Kooperation und Konkurrenz · Methodenkompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFE_MK_01' AS code, 'selbstständig und verantwortungsvoll Spielflächen und -geräte gemeinsam auf- und abbauen' AS kurzname, 'selbstständig und verantwortungsvoll Spielflächen und -geräte gemeinsam auf- und abbauen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_IFE_MK_02' AS code, 'in sportlichen Handlungssituationen grundlegende, bewegungsfeldspezifische Vereinbarungen und Regeln dokumentieren' AS kurzname, 'in sportlichen Handlungssituationen grundlegende, bewegungsfeldspezifische Vereinbarungen und Regeln dokumentieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFE_MK';
-- Erprobungsstufe · e: Kooperation und Konkurrenz · Urteilskompetenz (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFE_UK_01' AS code, 'sportliche Handlungs- und Spielsituationen hinsichtlich ausgewählter Aspekte (u.a. Einhaltung von Regeln und …' AS kurzname, 'sportliche Handlungs- und Spielsituationen hinsichtlich ausgewählter Aspekte (u.a. Einhaltung von Regeln und Vereinbarungen, Fairness im Mit- und Gegeneinander) auf grundlegendem Niveau bewerten' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFE_UK';
-- Erprobungsstufe · f: Gesundheit · Sachkompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFF_SK_01' AS code, 'grundlegende sportartspezifische Gefahrenmomente sowie Organisations- und Sicherheitsvereinbarungen für das sichere …' AS kurzname, 'grundlegende sportartspezifische Gefahrenmomente sowie Organisations- und Sicherheitsvereinbarungen für das sichere sportliche Handeln benennen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_IFF_SK_02' AS code, 'Merkmale einer sachgerechten Vorbereitung auf sportliches Bewegen (u.a. allgemeines Aufwärmen, Kleidung) benennen' AS kurzname, 'Merkmale einer sachgerechten Vorbereitung auf sportliches Bewegen (u.a. allgemeines Aufwärmen, Kleidung) benennen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFF_SK';
-- Erprobungsstufe · f: Gesundheit · Methodenkompetenz (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFF_MK_01' AS code, 'Spiel-, Übungs- und Wettkampfstätten situationsangemessen und sicherheitsbewusst nutzen' AS kurzname, 'Spiel-, Übungs- und Wettkampfstätten situationsangemessen und sicherheitsbewusst nutzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFF_MK';
-- Erprobungsstufe · f: Gesundheit · Urteilskompetenz (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_IFF_UK_01' AS code, 'körperliche Anstrengung anhand der Reaktionen des eigenen Körpers auf grundlegendem Niveau gesundheitsorientiert …' AS kurzname, 'körperliche Anstrengung anhand der Reaktionen des eigenen Körpers auf grundlegendem Niveau gesundheitsorientiert beurteilen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_IFF_UK';
-- Erprobungsstufe · BF/SB 1: Den Körper wahrnehmen und Bewegungsfähigkeiten ausprägen · Bewegungs- und Wahrnehmungskompetenz (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_BF1_BWK_01' AS code, 'sich altersgerecht aufwärmen und die Intensität des Aufwärmprozesses an der eigenen Körperreaktion wahrnehmen' AS kurzname, 'sich altersgerecht aufwärmen und die Intensität des Aufwärmprozesses an der eigenen Körperreaktion wahrnehmen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF1_BWK_02' AS code, 'eine grundlegende Muskel- und Körperspannung aufbauen, aufrechterhalten und in unterschiedlichen …' AS kurzname, 'eine grundlegende Muskel- und Körperspannung aufbauen, aufrechterhalten und in unterschiedlichen Anforderungssituationen nutzen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF1_BWK_03' AS code, 'grundlegende motorische Basisqualifikationen (u.a. Hangeln, Stützen, Klettern, Balancieren) in unterschiedlichen …' AS kurzname, 'grundlegende motorische Basisqualifikationen (u.a. Hangeln, Stützen, Klettern, Balancieren) in unterschiedlichen sportlichen Anforderungssituationen anwenden' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF1_BWK_04' AS code, 'eine aerobe Ausdauerleistung ohne Unterbrechung im Schwimmen (15 min, beliebige Schwimmart, mind. 200m) und in einem …' AS kurzname, 'eine aerobe Ausdauerleistung ohne Unterbrechung im Schwimmen (15 min, beliebige Schwimmart, mind. 200m) und in einem weiteren Bewegungsfeld über einen je nach Sportart angemessenen Zeitraum (z.B. Laufen 15 min, Aerobic 15 min, Radfahren 30 min) erbringen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_BF1_BWK';
-- Erprobungsstufe · BF/SB 2: Das Spielen entdecken und Spielräume nutzen · Bewegungs- und Wahrnehmungskompetenz (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_BF2_BWK_01' AS code, 'Bewegungsspiele eigenverantwortlich, kreativ und kooperativ spielen' AS kurzname, 'Bewegungsspiele eigenverantwortlich, kreativ und kooperativ spielen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF2_BWK_02' AS code, 'Kleine Spiele und Pausenspiele eigenverantwortlich (nach-)spielen und situations- und kriterienorientiert gestalten' AS kurzname, 'Kleine Spiele und Pausenspiele eigenverantwortlich (nach-)spielen und situations- und kriterienorientiert gestalten' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF2_BWK_03' AS code, 'lernförderliche Spiele und Spielformen unter Berücksichtigung ausgewählter Zielsetzungen (u.a. Verbesserung der …' AS kurzname, 'lernförderliche Spiele und Spielformen unter Berücksichtigung ausgewählter Zielsetzungen (u.a. Verbesserung der Konzentrationsfähigkeit) spielen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF2_BWK_04' AS code, 'unterschiedliche Voraussetzungen und Rahmenbedingungen (Spielidee, Personen, Materialien, Raum- und Geländeangebote) …' AS kurzname, 'unterschiedliche Voraussetzungen und Rahmenbedingungen (Spielidee, Personen, Materialien, Raum- und Geländeangebote) nutzen, um eigene Spiele zu finden, situations- und kriterienorientiert zu gestalten und zu spielen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_BF2_BWK';
-- Erprobungsstufe · BF/SB 3: Laufen, Springen, Werfen – Leichtathletik · Bewegungs- und Wahrnehmungskompetenz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_BF3_BWK_01' AS code, 'grundlegendes leichtathletisches Bewegen (schnelles Laufen, weites/hohes Springen, weites/zielgenaues Werfen) …' AS kurzname, 'grundlegendes leichtathletisches Bewegen (schnelles Laufen, weites/hohes Springen, weites/zielgenaues Werfen) vielseitig und spielbezogen ausführen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF3_BWK_02' AS code, 'leichtathletische Disziplinen (u.a. Sprint, Weitsprung, Ballwurf) auf grundlegendem Fertigkeitsniveau ausführen' AS kurzname, 'leichtathletische Disziplinen (u.a. Sprint, Weitsprung, Ballwurf) auf grundlegendem Fertigkeitsniveau ausführen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF3_BWK_03' AS code, 'einen leichtathletischen Wettbewerb unter Berücksichtigung grundlegenden Wettkampfverhaltens durchführen' AS kurzname, 'einen leichtathletischen Wettbewerb unter Berücksichtigung grundlegenden Wettkampfverhaltens durchführen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_BF3_BWK';
-- Erprobungsstufe · BF/SB 4: Bewegen im Wasser – Schwimmen · Bewegungs- und Wahrnehmungskompetenz (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_BF4_BWK_01' AS code, 'das unterschiedliche Verhalten des Körpers bei Auftrieb, Absinken, Vortrieb und Rotationen (um die Längs-, Quer- und …' AS kurzname, 'das unterschiedliche Verhalten des Körpers bei Auftrieb, Absinken, Vortrieb und Rotationen (um die Längs-, Quer- und Tiefenachse) im und unter Wasser wahrnehmen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF4_BWK_02' AS code, 'grundlegende Fertigkeiten (Atmen, Tauchen, Gleiten, Springen) ohne Hilfsmittel im Tiefwasser zum sicheren und …' AS kurzname, 'grundlegende Fertigkeiten (Atmen, Tauchen, Gleiten, Springen) ohne Hilfsmittel im Tiefwasser zum sicheren und zielgerichteten Bewegen nutzen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF4_BWK_03' AS code, 'eine Wechselzug- oder eine Gleichzugtechnik einschließlich Atemtechnik, Start und Wende auf technisch-koordinativ …' AS kurzname, 'eine Wechselzug- oder eine Gleichzugtechnik einschließlich Atemtechnik, Start und Wende auf technisch-koordinativ grundlegendem Niveau sicher und ausdauernd ausführen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF4_BWK_04' AS code, 'in unterschiedlichen Situationen sicherheitsbewusst springen und tauchen' AS kurzname, 'in unterschiedlichen Situationen sicherheitsbewusst springen und tauchen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_BF4_BWK';
-- Erprobungsstufe · BF/SB 5: Bewegen an Geräten – Turnen · Bewegungs- und Wahrnehmungskompetenz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_BF5_BWK_01' AS code, 'vielfältiges turnerisches Bewegen (Stützen, Balancieren, Rollen, Klettern, Springen, Hangeln, Schaukeln und Schwingen) …' AS kurzname, 'vielfältiges turnerisches Bewegen (Stützen, Balancieren, Rollen, Klettern, Springen, Hangeln, Schaukeln und Schwingen) an unterschiedlichen Geräten und Gerätekombinationen (z.B. Boden, Trampolin, Klettertaue, Reck/Barren, Bank/Balken/Slackline, Kasten/Bock, Sprossenwand, Boulder-/Kletterwand) demonstrieren' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF5_BWK_02' AS code, 'eine Bewegungsverbindung aus turnerischen Grundelementen an einem ausgewählten Gerät (Boden, Barren, Reck oder …' AS kurzname, 'eine Bewegungsverbindung aus turnerischen Grundelementen an einem ausgewählten Gerät (Boden, Barren, Reck oder Schwebebalken) demonstrieren' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF5_BWK_03' AS code, 'grundlegende turnerische Sicherheits- und Hilfestellungen situationsbezogen wahrnehmen und sachgerecht ausführen' AS kurzname, 'grundlegende turnerische Sicherheits- und Hilfestellungen situationsbezogen wahrnehmen und sachgerecht ausführen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_BF5_BWK';
-- Erprobungsstufe · BF/SB 6: Gestalten, Tanzen, Darstellen – Gymnastik/Tanz, Bewegungskünste · Bewegungs- und Wahrnehmungskompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_BF6_BWK_01' AS code, 'Grundformen ästhetisch-gestalterischen Bewegens (Laufen, Hüpfen, Springen) mit ausgewählten Handgeräten (Reifen, Seil …' AS kurzname, 'Grundformen ästhetisch-gestalterischen Bewegens (Laufen, Hüpfen, Springen) mit ausgewählten Handgeräten (Reifen, Seil oder Ball) oder Alltagsmaterialien für eine einfache gymnastische Bewegungsgestaltung nutzen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF6_BWK_02' AS code, 'eine einfache traditionelle (Volkstanz) oder aktuelle (Modetanz) tänzerische Komposition präsentieren' AS kurzname, 'eine einfache traditionelle (Volkstanz) oder aktuelle (Modetanz) tänzerische Komposition präsentieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_BF6_BWK';
-- Erprobungsstufe · BF/SB 7: Spielen in und mit Regelstrukturen – Sportspiele · Bewegungs- und Wahrnehmungskompetenz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_BF7_BWK_01' AS code, 'sportspielübergreifende taktische, koordinative und technische Fähigkeiten und Fertigkeiten (u.a. Heidelberger …' AS kurzname, 'sportspielübergreifende taktische, koordinative und technische Fähigkeiten und Fertigkeiten (u.a. Heidelberger Ballschule) in vielfältigen Spielformen anwenden' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF7_BWK_02' AS code, 'sich in einfachen spielorientierten Handlungssituationen durch Wahrnehmung von Raum, Spielgerät und Spielerinnen und …' AS kurzname, 'sich in einfachen spielorientierten Handlungssituationen durch Wahrnehmung von Raum, Spielgerät und Spielerinnen und Spielern taktisch angemessen und den Regelvereinbarungen entsprechend verhalten' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF7_BWK_03' AS code, 'in dem ausgewählten Mannschafts- oder Partnerspiel grundlegende taktisch-kognitive Fähigkeiten und …' AS kurzname, 'in dem ausgewählten Mannschafts- oder Partnerspiel grundlegende taktisch-kognitive Fähigkeiten und technisch-koordinative Fertigkeiten in spielerisch-situationsorientierten Handlungen anwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_BF7_BWK';
-- Erprobungsstufe · BF/SB 8: Gleiten, Fahren, Rollen – Rollsport, Bootssport, Wintersport · Bewegungs- und Wahrnehmungskompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_BF8_BWK_01' AS code, 'sich mit einem Gleit- oder Fahr- oder Rollgerät kontrolliert fortbewegen, gezielt die Richtung ändern sowie situations- …' AS kurzname, 'sich mit einem Gleit- oder Fahr- oder Rollgerät kontrolliert fortbewegen, gezielt die Richtung ändern sowie situations- und sicherheitsbewusst beschleunigen und bremsen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF8_BWK_02' AS code, 'grundlegende, gerätspezifische Anforderungssituationen beim Gleiten oder Fahren oder Rollen unter bewegungsökonomischen …' AS kurzname, 'grundlegende, gerätspezifische Anforderungssituationen beim Gleiten oder Fahren oder Rollen unter bewegungsökonomischen oder gestalterischen Aspekten sicherheitsbewusst bewältigen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_BF8_BWK';
-- Erprobungsstufe · BF/SB 9: Ringen und Kämpfen – Zweikampfsport · Bewegungs- und Wahrnehmungskompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_EP_BF9_BWK_01' AS code, 'unter Berücksichtigung der individuellen Voraussetzungen von Partnerin oder Partner, Gegnerin oder Gegner, …' AS kurzname, 'unter Berücksichtigung der individuellen Voraussetzungen von Partnerin oder Partner, Gegnerin oder Gegner, normungebunden mit- und gegeneinander um Raum und Gegenstände im Stand und am Boden kämpfen' AS beschreibung
  UNION ALL
  SELECT 'SPO_EP_BF9_BWK_02' AS code, 'in einfachen Gruppen- und Zweikampfsituationen fair und regelgerecht kämpfen' AS kurzname, 'in einfachen Gruppen- und Zweikampfsituationen fair und regelgerecht kämpfen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_EP_BF9_BWK';
-- Sekundarstufe I · a: Bewegungsstruktur und Bewegungslernen · Sachkompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFA_SK_01' AS code, 'die für das Lernen und Üben ausgewählter Bewegungsabläufe bedeutsamen Körperempfindungen und Körperwahrnehmungen …' AS kurzname, 'die für das Lernen und Üben ausgewählter Bewegungsabläufe bedeutsamen Körperempfindungen und Körperwahrnehmungen beschreiben' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFA_SK_02' AS code, 'für ausgewählte Bewegungstechniken die relevanten Bewegungsmerkmale benennen und einfache grundlegende Zusammenhänge …' AS kurzname, 'für ausgewählte Bewegungstechniken die relevanten Bewegungsmerkmale benennen und einfache grundlegende Zusammenhänge von Aktionen und Effekten erläutern' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFA_SK';
-- Sekundarstufe I · a: Bewegungsstruktur und Bewegungslernen · Methodenkompetenz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFA_MK_01' AS code, 'grundlegende methodische Prinzipien auf das Lernen und Üben sportlicher Bewegungen anwenden' AS kurzname, 'grundlegende methodische Prinzipien auf das Lernen und Üben sportlicher Bewegungen anwenden' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFA_MK_02' AS code, 'analoge und digitale Medien zur Bewegungsanalyse und Unterstützung motorischer Lern- und Übungsprozesse zielorientiert …' AS kurzname, 'analoge und digitale Medien zur Bewegungsanalyse und Unterstützung motorischer Lern- und Übungsprozesse zielorientiert einsetzen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFA_MK_03' AS code, 'unterschiedliche Hilfen (Feedback, Hilfestellungen, Geländehilfen, Visualisierungen, akustische Signale) beim Erlernen …' AS kurzname, 'unterschiedliche Hilfen (Feedback, Hilfestellungen, Geländehilfen, Visualisierungen, akustische Signale) beim Erlernen und Verbessern sportlicher Bewegungen auswählen und verwenden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFA_MK';
-- Sekundarstufe I · a: Bewegungsstruktur und Bewegungslernen · Urteilskompetenz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFA_UK_01' AS code, 'Bewegungsabläufe kriteriengeleitet beurteilen' AS kurzname, 'Bewegungsabläufe kriteriengeleitet beurteilen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFA_UK_02' AS code, 'den Nutzen analoger und digitaler Medien zur Analyse und Unterstützung motorischer Lern- und Übungsprozesse …' AS kurzname, 'den Nutzen analoger und digitaler Medien zur Analyse und Unterstützung motorischer Lern- und Übungsprozesse vergleichend beurteilen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFA_UK_03' AS code, 'den Einsatz unterschiedlicher Hilfen (Feedback, Hilfestellungen, Geländehilfen, Visualisierungen, akustische Signale) …' AS kurzname, 'den Einsatz unterschiedlicher Hilfen (Feedback, Hilfestellungen, Geländehilfen, Visualisierungen, akustische Signale) beim Erlernen und Verbessern sportlicher Bewegungen kriteriengeleitet bewerten' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFA_UK';
-- Sekundarstufe I · b: Bewegungsgestaltung · Sachkompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFB_SK_01' AS code, 'ausgewählte Ausführungskriterien (Bewegungsqualität, Synchronität, Ausdruck und Körperspannung) benennen' AS kurzname, 'ausgewählte Ausführungskriterien (Bewegungsqualität, Synchronität, Ausdruck und Körperspannung) benennen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFB_SK_02' AS code, 'das Gestaltungskriterium Raum (Aufstellungsformen, Raumwege, Raumebenen und Bewegungsrichtungen) beschreiben' AS kurzname, 'das Gestaltungskriterium Raum (Aufstellungsformen, Raumwege, Raumebenen und Bewegungsrichtungen) beschreiben' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFB_SK';
-- Sekundarstufe I · b: Bewegungsgestaltung · Methodenkompetenz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFB_MK_01' AS code, 'unterschiedliche Ausgangspunkte (Texte, Musik oder Themen) als Anlass für Gestaltungen – allein oder in der Gruppe – …' AS kurzname, 'unterschiedliche Ausgangspunkte (Texte, Musik oder Themen) als Anlass für Gestaltungen – allein oder in der Gruppe – nutzen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFB_MK_02' AS code, 'Bewegungsgestaltungen allein oder in der Gruppe auch mit Hilfe digitaler Medien nach-, um- und neugestalten' AS kurzname, 'Bewegungsgestaltungen allein oder in der Gruppe auch mit Hilfe digitaler Medien nach-, um- und neugestalten' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFB_MK_03' AS code, 'kreative Bewegungsgestaltungen entwickeln und zu einer Präsentation verbinden' AS kurzname, 'kreative Bewegungsgestaltungen entwickeln und zu einer Präsentation verbinden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFB_MK';
-- Sekundarstufe I · b: Bewegungsgestaltung · Urteilskompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFB_UK_01' AS code, 'die Ausführungs- und Bewegungsqualität bei sich und anderen nach vorgegebenen Kriterien beurteilen' AS kurzname, 'die Ausführungs- und Bewegungsqualität bei sich und anderen nach vorgegebenen Kriterien beurteilen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFB_UK_02' AS code, 'gestalterische Präsentationen auch unter Verwendung digitaler Medien kriteriengeleitet (u.a. Schwierigkeit, …' AS kurzname, 'gestalterische Präsentationen auch unter Verwendung digitaler Medien kriteriengeleitet (u.a. Schwierigkeit, Kreativität, Nutzung des Raums, Wirkung auf den Zuschauer) beurteilen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFB_UK';
-- Sekundarstufe I · c: Wagnis und Verantwortung · Sachkompetenz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFC_SK_01' AS code, 'unterschiedliche Motive (u.a. Risiko erleben) sportlichen Handelns in Wagnissituationen erläutern' AS kurzname, 'unterschiedliche Motive (u.a. Risiko erleben) sportlichen Handelns in Wagnissituationen erläutern' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFC_SK_02' AS code, 'emotionale Signale in sportlichen Wagnissituationen beschreiben' AS kurzname, 'emotionale Signale in sportlichen Wagnissituationen beschreiben' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFC_SK_03' AS code, 'die Herausforderungen in sportlichen Handlungssituationen im Hinblick auf die Anforderung, das eigene Können und …' AS kurzname, 'die Herausforderungen in sportlichen Handlungssituationen im Hinblick auf die Anforderung, das eigene Können und mögliche Gefahren erläutern' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFC_SK';
-- Sekundarstufe I · c: Wagnis und Verantwortung · Methodenkompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFC_MK_01' AS code, 'Strategien zum Umgang mit Emotionen in sportlichen Wagnissituationen (u.a. zur Bewältigung von Angstsituationen) …' AS kurzname, 'Strategien zum Umgang mit Emotionen in sportlichen Wagnissituationen (u.a. zur Bewältigung von Angstsituationen) anwenden' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFC_MK_02' AS code, 'Herausforderungen in sportlichen Handlungssituationen angepasst an das individuelle motorische Können gezielt verändern' AS kurzname, 'Herausforderungen in sportlichen Handlungssituationen angepasst an das individuelle motorische Können gezielt verändern' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFC_MK';
-- Sekundarstufe I · c: Wagnis und Verantwortung · Urteilskompetenz (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFC_UK_01' AS code, 'komplexe sportliche Wagnissituationen für sich und andere unter Berücksichtigung des eigenen Könnens und möglicher …' AS kurzname, 'komplexe sportliche Wagnissituationen für sich und andere unter Berücksichtigung des eigenen Könnens und möglicher Gefahrenmomente situativ beurteilen und sich begründet für oder gegen deren Bewältigung entscheiden' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFC_UK';
-- Sekundarstufe I · d: Leistung · Sachkompetenz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFD_SK_01' AS code, 'grundlegende Methoden und Prinzipien zur Verbesserung motorischer Grundfähigkeiten (Ausdauer und Kraft) beschreiben' AS kurzname, 'grundlegende Methoden und Prinzipien zur Verbesserung motorischer Grundfähigkeiten (Ausdauer und Kraft) beschreiben' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFD_SK_02' AS code, 'ausgewählte Belastungsgrößen (u.a. Intensität, Umfang, Dichte, Dauer) zur Gestaltung eines Trainings auf grundlegendem …' AS kurzname, 'ausgewählte Belastungsgrößen (u.a. Intensität, Umfang, Dichte, Dauer) zur Gestaltung eines Trainings auf grundlegendem Niveau erläutern' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFD_SK_03' AS code, 'koordinative Anforderungen von Bewegungsaufgaben benennen' AS kurzname, 'koordinative Anforderungen von Bewegungsaufgaben benennen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFD_SK';
-- Sekundarstufe I · d: Leistung · Methodenkompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFD_MK_01' AS code, 'einen individualisierten Trainingsplan aus vorgegebenen Einzelelementen zur Verbesserung einer ausgewählten motorischen …' AS kurzname, 'einen individualisierten Trainingsplan aus vorgegebenen Einzelelementen zur Verbesserung einer ausgewählten motorischen Grundfähigkeit zusammenstellen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFD_MK_02' AS code, 'sportliche Leistungen analog oder digital erfassen und anhand von graphischen Darstellungen und/oder Diagrammen …' AS kurzname, 'sportliche Leistungen analog oder digital erfassen und anhand von graphischen Darstellungen und/oder Diagrammen dokumentieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFD_MK';
-- Sekundarstufe I · d: Leistung · Urteilskompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFD_UK_01' AS code, 'die eigene und die Leistungsfähigkeit anderer in unterschiedlichen Sport- und Wettkampfsituationen unter …' AS kurzname, 'die eigene und die Leistungsfähigkeit anderer in unterschiedlichen Sport- und Wettkampfsituationen unter Berücksichtigung individueller Voraussetzungen kriteriengeleitet beurteilen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFD_UK_02' AS code, 'den Leistungsbegriff in unterschiedlichen sportlichen Handlungssituationen unter Berücksichtigung unterschiedlicher …' AS kurzname, 'den Leistungsbegriff in unterschiedlichen sportlichen Handlungssituationen unter Berücksichtigung unterschiedlicher Bezugsgrößen (u.a. soziale, personale, kriteriale Bezugsnormen und Geschlechteraspekte) kritisch reflektieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFD_UK';
-- Sekundarstufe I · e: Kooperation und Konkurrenz · Sachkompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFE_SK_01' AS code, 'Kennzeichen für ein grundlegendes Wettkampfverhalten (u.a. wettkampfspezifische Regeln kennen, taktisch angemessen …' AS kurzname, 'Kennzeichen für ein grundlegendes Wettkampfverhalten (u.a. wettkampfspezifische Regeln kennen, taktisch angemessen agieren) erläutern' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFE_SK_02' AS code, 'Rahmenbedingungen, Strukturmerkmale, Vereinbarungen und Regeln unterschiedlicher Spiele oder Wettkampfsituationen …' AS kurzname, 'Rahmenbedingungen, Strukturmerkmale, Vereinbarungen und Regeln unterschiedlicher Spiele oder Wettkampfsituationen kriteriengeleitet in ihrer Notwendigkeit und Funktion für das Gelingen sportlicher Handlungen erläutern' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFE_SK';
-- Sekundarstufe I · e: Kooperation und Konkurrenz · Methodenkompetenz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFE_MK_01' AS code, 'Vereinbarungen und Regeln für ein faires und gelingendes sportliches Handeln analysieren und kriteriengeleitet …' AS kurzname, 'Vereinbarungen und Regeln für ein faires und gelingendes sportliches Handeln analysieren und kriteriengeleitet modifizieren' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFE_MK_02' AS code, 'einfache analoge und digitale Darstellungen zur Erläuterung von sportlichen Handlungssituationen (u.a. Spielzüge, …' AS kurzname, 'einfache analoge und digitale Darstellungen zur Erläuterung von sportlichen Handlungssituationen (u.a. Spielzüge, Aufstellungsformen) verwenden' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFE_MK_03' AS code, 'in sportlichen Handlungssituationen unter Verwendung der vereinbarten Zeichen und Signale Schiedsrichterfunktionen …' AS kurzname, 'in sportlichen Handlungssituationen unter Verwendung der vereinbarten Zeichen und Signale Schiedsrichterfunktionen übernehmen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFE_MK';
-- Sekundarstufe I · e: Kooperation und Konkurrenz · Urteilskompetenz (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFE_UK_01' AS code, 'das eigene sportliche Handeln sowie das sportliche Handeln anderer kriteriengeleitet im Hinblick auf ausgewählte …' AS kurzname, 'das eigene sportliche Handeln sowie das sportliche Handeln anderer kriteriengeleitet im Hinblick auf ausgewählte Aspekte (u.a. Fairness, Mit- und Gegeneinander, Partizipation, Geschlechteraspekte) beurteilen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFE_UK';
-- Sekundarstufe I · f: Gesundheit · Sachkompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFF_SK_01' AS code, 'Auswirkungen gezielten Sporttreibens auf die Gesundheit grundlegend beschreiben' AS kurzname, 'Auswirkungen gezielten Sporttreibens auf die Gesundheit grundlegend beschreiben' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFF_SK_02' AS code, 'Prinzipien einer sachgerechten allgemeinen und sportartspezifischen Vorbereitung auf sportliches Bewegen im Hinblick …' AS kurzname, 'Prinzipien einer sachgerechten allgemeinen und sportartspezifischen Vorbereitung auf sportliches Bewegen im Hinblick auf die damit verbundenen unterschiedlichen psycho-physischen Belastungen erläutern' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFF_SK';
-- Sekundarstufe I · f: Gesundheit · Methodenkompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFF_MK_01' AS code, 'die Rahmenbedingungen und Gegebenheiten von Spiel-, Übungs- und Wettkampfsituationen analysieren und diese …' AS kurzname, 'die Rahmenbedingungen und Gegebenheiten von Spiel-, Übungs- und Wettkampfsituationen analysieren und diese sicherheitsbewusst gestalten' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_IFF_MK_02' AS code, 'Muster des eigenen Bewegungsverhaltens (im Alltag und in sportlichen Handlungssituationen) auch unter Nutzung digitaler …' AS kurzname, 'Muster des eigenen Bewegungsverhaltens (im Alltag und in sportlichen Handlungssituationen) auch unter Nutzung digitaler Medien erfassen und im Hinblick auf den gesundheitlichen Nutzen und mögliche Risiken analysieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFF_MK';
-- Sekundarstufe I · f: Gesundheit · Urteilskompetenz (1)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_IFF_UK_01' AS code, 'gesundheitliche Auswirkungen sportlichen Handelns unter besonderer Berücksichtigung medial vermittelter Fitnesstrends …' AS kurzname, 'gesundheitliche Auswirkungen sportlichen Handelns unter besonderer Berücksichtigung medial vermittelter Fitnesstrends und Körperideale auch unter Geschlechteraspekten kritisch beurteilen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_IFF_UK';
-- Sekundarstufe I · BF/SB 1: Den Körper wahrnehmen und Bewegungsfähigkeiten ausprägen · Bewegungs- und Wahrnehmungskompetenz (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_BF1_BWK_01' AS code, 'sich funktional und wahrnehmungsorientiert – allgemein und sportartspezifisch – aufwärmen' AS kurzname, 'sich funktional und wahrnehmungsorientiert – allgemein und sportartspezifisch – aufwärmen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF1_BWK_02' AS code, 'ein Koordinationstraining unter Berücksichtigung unterschiedlicher Anforderungssituationen sachgemäß durchführen' AS kurzname, 'ein Koordinationstraining unter Berücksichtigung unterschiedlicher Anforderungssituationen sachgemäß durchführen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF1_BWK_03' AS code, 'ein gesund-funktionales Muskeltraining (z.B. als Zirkeltraining) unter Berücksichtigung der individuellen …' AS kurzname, 'ein gesund-funktionales Muskeltraining (z.B. als Zirkeltraining) unter Berücksichtigung der individuellen Belastungswahrnehmung sachgemäß durchführen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF1_BWK_04' AS code, 'eine aerobe Ausdauerleistung ohne Unterbrechung über einen je nach Sportart angemessenen Zeitraum (z.B. Laufen 30 min, …' AS kurzname, 'eine aerobe Ausdauerleistung ohne Unterbrechung über einen je nach Sportart angemessenen Zeitraum (z.B. Laufen 30 min, Schwimmen 20 min, Aerobic 30 min, Radfahren 60 min) in zwei ausgewählten Bewegungsfeldern erbringen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_BF1_BWK';
-- Sekundarstufe I · BF/SB 2: Das Spielen entdecken und Spielräume nutzen · Bewegungs- und Wahrnehmungskompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_BF2_BWK_01' AS code, 'lernförderliche Spiele und Spielformen unter Berücksichtigung ausgewählter Zielsetzungen (u.a. Verbesserung der …' AS kurzname, 'lernförderliche Spiele und Spielformen unter Berücksichtigung ausgewählter Zielsetzungen (u.a. Verbesserung der Konzentrationsfähigkeit) kriterienorientiert entwickeln und spielen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF2_BWK_02' AS code, 'eigene Spiele und Spiele aus anderen Kulturen unter Berücksichtigung ausgewählter Strukturmerkmale (z.B. Glück, …' AS kurzname, 'eigene Spiele und Spiele aus anderen Kulturen unter Berücksichtigung ausgewählter Strukturmerkmale (z.B. Glück, Strategie und Geschicklichkeit) kriterienorientiert entwickeln und spielen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_BF2_BWK';
-- Sekundarstufe I · BF/SB 3: Laufen, Springen, Werfen – Leichtathletik · Bewegungs- und Wahrnehmungskompetenz (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_BF3_BWK_01' AS code, 'bereits erlernte leichtathletische Disziplinen auf erweitertem technisch-koordinativen Fertigkeitsniveau ausführen' AS kurzname, 'bereits erlernte leichtathletische Disziplinen auf erweitertem technisch-koordinativen Fertigkeitsniveau ausführen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF3_BWK_02' AS code, 'eine neu erlernte leichtathletische Disziplin (z.B. Kugelstoßen, Hochsprung) in der Grobform ausführen' AS kurzname, 'eine neu erlernte leichtathletische Disziplin (z.B. Kugelstoßen, Hochsprung) in der Grobform ausführen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF3_BWK_03' AS code, 'einen leichtathletischen Wettkampf einzeln oder in der Gruppe unter Berücksichtigung angemessenen Wettkampfverhaltens …' AS kurzname, 'einen leichtathletischen Wettkampf einzeln oder in der Gruppe unter Berücksichtigung angemessenen Wettkampfverhaltens durchführen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF3_BWK_04' AS code, 'alternative leichtathletische Wettbewerbe (z.B. Orientierungslauf, Geocashing, Relativwettkämpfe, historische …' AS kurzname, 'alternative leichtathletische Wettbewerbe (z.B. Orientierungslauf, Geocashing, Relativwettkämpfe, historische Disziplinen) unter Berücksichtigung unterschiedlicher Zielrichtungen durchführen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_BF3_BWK';
-- Sekundarstufe I · BF/SB 4: Bewegen im Wasser – Schwimmen · Bewegungs- und Wahrnehmungskompetenz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_BF4_BWK_01' AS code, 'eine Wechselzug- und eine Gleichzugtechnik einschließlich Atemtechnik, Start und Wende auf technisch-koordinativ …' AS kurzname, 'eine Wechselzug- und eine Gleichzugtechnik einschließlich Atemtechnik, Start und Wende auf technisch-koordinativ höherem Niveau sicher ausführen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF4_BWK_02' AS code, 'Maßnahmen und Möglichkeiten zur Selbst- und Fremdrettung sachgerecht nutzen' AS kurzname, 'Maßnahmen und Möglichkeiten zur Selbst- und Fremdrettung sachgerecht nutzen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF4_BWK_03' AS code, 'grundlegende Techniken und Fertigkeiten im Wasser (Schwimmen, Tauchen oder Springen) spielerisch oder ästhetisch oder …' AS kurzname, 'grundlegende Techniken und Fertigkeiten im Wasser (Schwimmen, Tauchen oder Springen) spielerisch oder ästhetisch oder kreativ zur Bewältigung unterschiedlicher Anforderungssituationen im Wasser nutzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_BF4_BWK';
-- Sekundarstufe I · BF/SB 5: Bewegen an Geräten – Turnen · Bewegungs- und Wahrnehmungskompetenz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_BF5_BWK_01' AS code, 'turnerische Grundelemente auf technisch-koordinativ grundlegendem Niveau unter Berücksichtigung eines weiteren …' AS kurzname, 'turnerische Grundelemente auf technisch-koordinativ grundlegendem Niveau unter Berücksichtigung eines weiteren Turngeräts demonstrieren' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF5_BWK_02' AS code, 'eine selbst entwickelte akrobatische Gruppengestaltung präsentieren' AS kurzname, 'eine selbst entwickelte akrobatische Gruppengestaltung präsentieren' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF5_BWK_03' AS code, 'turnerische Sicherheits- und Hilfestellungen situationsbezogen wahrnehmen und sachgerecht ausführen' AS kurzname, 'turnerische Sicherheits- und Hilfestellungen situationsbezogen wahrnehmen und sachgerecht ausführen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_BF5_BWK';
-- Sekundarstufe I · BF/SB 6: Gestalten, Tanzen, Darstellen – Gymnastik/Tanz, Bewegungskünste · Bewegungs- und Wahrnehmungskompetenz (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_BF6_BWK_01' AS code, 'eine selbstständig um- und neugestaltete gymnastische Bewegungsgestaltung ohne oder mit ausgewählten Handgeräten (Ball, …' AS kurzname, 'eine selbstständig um- und neugestaltete gymnastische Bewegungsgestaltung ohne oder mit ausgewählten Handgeräten (Ball, Reifen, Seil, Keule oder Band) oder Alltagsmaterialien allein oder in der Gruppe präsentieren' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF6_BWK_02' AS code, 'eine selbstständig um- und neugestaltete tänzerische Komposition einer ausgewählten Tanzrichtung (z.B. Hip-Hop, …' AS kurzname, 'eine selbstständig um- und neugestaltete tänzerische Komposition einer ausgewählten Tanzrichtung (z.B. Hip-Hop, Jumpstyle) allein oder in der Gruppe präsentieren' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF6_BWK_03' AS code, 'eine selbstständig um- und neugestaltete künstlerische Bewegungskomposition aus einem ausgewählten Bereich (Pantomime, …' AS kurzname, 'eine selbstständig um- und neugestaltete künstlerische Bewegungskomposition aus einem ausgewählten Bereich (Pantomime, Bewegungstheater oder Jonglage) allein oder in der Gruppe präsentieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_BF6_BWK';
-- Sekundarstufe I · BF/SB 7: Spielen in und mit Regelstrukturen – Sportspiele · Bewegungs- und Wahrnehmungskompetenz (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_BF7_BWK_01' AS code, 'sportspielspezifische Handlungssituationen in unterschiedlichen Sportspielen differenziert wahrnehmen, …' AS kurzname, 'sportspielspezifische Handlungssituationen in unterschiedlichen Sportspielen differenziert wahrnehmen, taktisch-kognitiv angemessen agieren und fair und mannschaftsdienlich spielen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF7_BWK_02' AS code, 'in dem ausgewählten Mannschafts- oder Partnerspiel auf fortgeschrittenem Spielniveau taktisch-kognitive Fähigkeiten und …' AS kurzname, 'in dem ausgewählten Mannschafts- oder Partnerspiel auf fortgeschrittenem Spielniveau taktisch-kognitive Fähigkeiten und technisch-koordinative Fertigkeiten in spielerisch-situationsorientierten Handlungen anwenden' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF7_BWK_03' AS code, 'ein Endzonenspiel (z.B. Ultimate Frisbee, Rugby, Flag-Football) unter Berücksichtigung der taktisch-kognitiven und …' AS kurzname, 'ein Endzonenspiel (z.B. Ultimate Frisbee, Rugby, Flag-Football) unter Berücksichtigung der taktisch-kognitiven und technisch-koordinativen Herausforderungen regelgerecht und situativ angemessen spielen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF7_BWK_04' AS code, 'eine Sportspielvariante (z.B. Beachvolleyball, Streetball, Floorball) oder ein alternatives Mannschafts- oder …' AS kurzname, 'eine Sportspielvariante (z.B. Beachvolleyball, Streetball, Floorball) oder ein alternatives Mannschafts- oder Partnerspiel (z.B. Korfball, Tchoukball, Baseball) unter Berücksichtigung der taktisch-kognitiven und technisch-koordinativen Herausforderungen regelgerecht und situativ angemessen spielen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_BF7_BWK';
-- Sekundarstufe I · BF/SB 8: Gleiten, Fahren, Rollen – Rollsport, Bootssport, Wintersport · Bewegungs- und Wahrnehmungskompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_BF8_BWK_01' AS code, 'sich in komplexen Anforderungssituationen unter Wahrnehmung von Material, Geschwindigkeit und Umwelt mit einem …' AS kurzname, 'sich in komplexen Anforderungssituationen unter Wahrnehmung von Material, Geschwindigkeit und Umwelt mit einem fahrenden oder rollenden oder gleitenden Sportgerät dynamisch und situationsangemessen fortbewegen' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF8_BWK_02' AS code, 'gerätspezifische, technisch-koordinative Fertigkeiten unter Berücksichtigung unterschiedlicher Zielsetzungen …' AS kurzname, 'gerätspezifische, technisch-koordinative Fertigkeiten unter Berücksichtigung unterschiedlicher Zielsetzungen (ästhetisch, gestalterisch, spielerisch oder wettkampfbezogen) sicher und kontrolliert demonstrieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_BF8_BWK';
-- Sekundarstufe I · BF/SB 9: Ringen und Kämpfen – Zweikampfsport · Bewegungs- und Wahrnehmungskompetenz (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'SPO_SI_BF9_BWK_01' AS code, 'grundlegende, normgebundene, technisch-koordinative Fertigkeiten (z. B. Haltegriffe und Befreiungen, Falltechniken und …' AS kurzname, 'grundlegende, normgebundene, technisch-koordinative Fertigkeiten (z. B. Haltegriffe und Befreiungen, Falltechniken und kontrolliertes Werfen) und taktisch-kognitive Fähigkeiten (z. B. Kontern, Kombinieren, Fintieren) beim Ringen und Kämpfen im Stand und am Boden anwenden' AS beschreibung
  UNION ALL
  SELECT 'SPO_SI_BF9_BWK_02' AS code, 'in unterschiedlichen Zweikampfhandlungen situationsangepasst, regelgerecht und fair miteinander kämpfen' AS kurzname, 'in unterschiedlichen Zweikampfhandlungen situationsangepasst, regelgerecht und fair miteinander kämpfen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'SPO_SI_BF9_BWK';

COMMIT;

-- Kontrolle: erwartet Knoten=84 (30 Wurzeln + 54 Blaetter), Kompetenzen=120
-- Erwartet an den Wurzeln: art='inhaltsfeld' 12, art='bewegungsfeld' 18;
-- an den Blaettern durchweg art='kompetenzbereich'.
