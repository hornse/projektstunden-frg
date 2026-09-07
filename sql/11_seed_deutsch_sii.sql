-- =============================================================================
-- Seed 11: Deutsch – Kernlehrplan Gymnasiale Oberstufe (GOSt) NRW
-- Verabschiedete Fassung vom 24.08.2026.
--
-- Quelle: docs/curricula/gost_klp_d_2026_08_24.pdf
-- SHA256: 00694903d6a16447989fd476d9ce91c8e0e7b8cb0e114fa3cfd3ed773d981c29
-- Erzeugt von: sql/gen/gen_deutsch_sii.py
--
-- NICHT VON HAND AENDERN: Korrekturen gehoeren in den Erzeuger, die Datei
-- wird daraus neu geschrieben (E19).
-- Voraussetzung: Migration 08 (phase/inhaltsfeld/kompetenzbereich,
--               eltern_kompetenz_id, schule_id) ist eingespielt.
-- Idempotent: loescht vorhandenen DEU_KLP_SII-Rahmen und baut ihn neu auf.
-- =============================================================================

SET NAMES utf8mb4;
START TRANSACTION;

SET @schule := 1;
SET @fach := (SELECT id FROM faecher WHERE schule_id = @schule AND kuerzel = 'DE' LIMIT 1);

-- Nur der eigene Rahmen wird geloescht; CASCADE raeumt Bereiche und Kompetenzen.
DELETE FROM kompetenzrahmen WHERE schule_id = @schule AND kuerzel = 'DEU_KLP_SII';

INSERT INTO kompetenzrahmen (schule_id, name, kuerzel, beschreibung, quelle_url, fach_id)
VALUES (@schule, 'Deutsch KLP NRW SII/GOSt (2026)', 'DEU_KLP_SII', 'Kernlehrplan Deutsch für die gymnasiale Oberstufe (GOSt), NRW, verabschiedete Fassung vom 24.08.2026. Kompetenzbereiche Rezeption/Produktion, Inhaltsfelder Sprache/Texte/Kommunikation/Medien; Phasen Einführungsphase, Qualifikationsphase Grundkurs und Leistungskurs.', 'docs/curricula/gost_klp_d_2026_08_24.pdf', @fach);
SET @rahmen := LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Kompetenzbereiche als Baum (E29b, E31)
--
-- Zwei Ebenen: je Phase und Inhaltsfeld ein Wurzelknoten (art =
-- 'inhaltsfeld'), darunter Rezeption und Produktion als Blaetter
-- (art = 'kompetenzbereich'). Kompetenzen haengen nur an den Blaettern.
-- Die Phase steht als Spalte an jedem Knoten (E31).
-- --------------------------------------------------------------------------
INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art) VALUES
(@rahmen, NULL, 'DE_EF_UEB', 'Einführungsphase · Übergeordnet', 1, 'einfuehrungsphase', 'inhaltsfeld'),
(@rahmen, NULL, 'DE_EF_SPR', 'Einführungsphase · Sprache', 4, 'einfuehrungsphase', 'inhaltsfeld'),
(@rahmen, NULL, 'DE_EF_TXT', 'Einführungsphase · Texte', 7, 'einfuehrungsphase', 'inhaltsfeld'),
(@rahmen, NULL, 'DE_EF_KOM', 'Einführungsphase · Kommunikation', 10, 'einfuehrungsphase', 'inhaltsfeld'),
(@rahmen, NULL, 'DE_EF_MED', 'Einführungsphase · Medien', 13, 'einfuehrungsphase', 'inhaltsfeld'),
(@rahmen, NULL, 'DE_QGK_UEB', 'Qualifikationsphase (Grundkurs) · Übergeordnet', 16, 'qualifikationsphase_gk', 'inhaltsfeld'),
(@rahmen, NULL, 'DE_QGK_SPR', 'Qualifikationsphase (Grundkurs) · Sprache', 19, 'qualifikationsphase_gk', 'inhaltsfeld'),
(@rahmen, NULL, 'DE_QGK_TXT', 'Qualifikationsphase (Grundkurs) · Texte', 22, 'qualifikationsphase_gk', 'inhaltsfeld'),
(@rahmen, NULL, 'DE_QGK_KOM', 'Qualifikationsphase (Grundkurs) · Kommunikation', 25, 'qualifikationsphase_gk', 'inhaltsfeld'),
(@rahmen, NULL, 'DE_QGK_MED', 'Qualifikationsphase (Grundkurs) · Medien', 28, 'qualifikationsphase_gk', 'inhaltsfeld'),
(@rahmen, NULL, 'DE_QLK_UEB', 'Qualifikationsphase (Leistungskurs) · Übergeordnet', 31, 'qualifikationsphase_lk', 'inhaltsfeld'),
(@rahmen, NULL, 'DE_QLK_SPR', 'Qualifikationsphase (Leistungskurs) · Sprache', 34, 'qualifikationsphase_lk', 'inhaltsfeld'),
(@rahmen, NULL, 'DE_QLK_TXT', 'Qualifikationsphase (Leistungskurs) · Texte', 37, 'qualifikationsphase_lk', 'inhaltsfeld'),
(@rahmen, NULL, 'DE_QLK_KOM', 'Qualifikationsphase (Leistungskurs) · Kommunikation', 40, 'qualifikationsphase_lk', 'inhaltsfeld'),
(@rahmen, NULL, 'DE_QLK_MED', 'Qualifikationsphase (Leistungskurs) · Medien', 43, 'qualifikationsphase_lk', 'inhaltsfeld');

-- Blaetter: parent_id wird ueber den Code des Wurzelknotens aufgeloest.
INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art)
SELECT @rahmen, p.id, t.code, t.name, t.reihenfolge, t.phase, t.art
FROM (
  SELECT 'DE_EF_UEB_REZ' AS code, 'Einführungsphase · Übergeordnet · Rezeption' AS name, 2 AS reihenfolge, 'einfuehrungsphase' AS phase, 'kompetenzbereich' AS art, 'DE_EF_UEB' AS pcode
  UNION ALL
  SELECT 'DE_EF_UEB_PRO' AS code, 'Einführungsphase · Übergeordnet · Produktion' AS name, 3 AS reihenfolge, 'einfuehrungsphase' AS phase, 'kompetenzbereich' AS art, 'DE_EF_UEB' AS pcode
  UNION ALL
  SELECT 'DE_EF_SPR_REZ' AS code, 'Einführungsphase · Sprache · Rezeption' AS name, 5 AS reihenfolge, 'einfuehrungsphase' AS phase, 'kompetenzbereich' AS art, 'DE_EF_SPR' AS pcode
  UNION ALL
  SELECT 'DE_EF_SPR_PRO' AS code, 'Einführungsphase · Sprache · Produktion' AS name, 6 AS reihenfolge, 'einfuehrungsphase' AS phase, 'kompetenzbereich' AS art, 'DE_EF_SPR' AS pcode
  UNION ALL
  SELECT 'DE_EF_TXT_REZ' AS code, 'Einführungsphase · Texte · Rezeption' AS name, 8 AS reihenfolge, 'einfuehrungsphase' AS phase, 'kompetenzbereich' AS art, 'DE_EF_TXT' AS pcode
  UNION ALL
  SELECT 'DE_EF_TXT_PRO' AS code, 'Einführungsphase · Texte · Produktion' AS name, 9 AS reihenfolge, 'einfuehrungsphase' AS phase, 'kompetenzbereich' AS art, 'DE_EF_TXT' AS pcode
  UNION ALL
  SELECT 'DE_EF_KOM_REZ' AS code, 'Einführungsphase · Kommunikation · Rezeption' AS name, 11 AS reihenfolge, 'einfuehrungsphase' AS phase, 'kompetenzbereich' AS art, 'DE_EF_KOM' AS pcode
  UNION ALL
  SELECT 'DE_EF_KOM_PRO' AS code, 'Einführungsphase · Kommunikation · Produktion' AS name, 12 AS reihenfolge, 'einfuehrungsphase' AS phase, 'kompetenzbereich' AS art, 'DE_EF_KOM' AS pcode
  UNION ALL
  SELECT 'DE_EF_MED_REZ' AS code, 'Einführungsphase · Medien · Rezeption' AS name, 14 AS reihenfolge, 'einfuehrungsphase' AS phase, 'kompetenzbereich' AS art, 'DE_EF_MED' AS pcode
  UNION ALL
  SELECT 'DE_EF_MED_PRO' AS code, 'Einführungsphase · Medien · Produktion' AS name, 15 AS reihenfolge, 'einfuehrungsphase' AS phase, 'kompetenzbereich' AS art, 'DE_EF_MED' AS pcode
  UNION ALL
  SELECT 'DE_QGK_UEB_REZ' AS code, 'Qualifikationsphase (Grundkurs) · Übergeordnet · Rezeption' AS name, 17 AS reihenfolge, 'qualifikationsphase_gk' AS phase, 'kompetenzbereich' AS art, 'DE_QGK_UEB' AS pcode
  UNION ALL
  SELECT 'DE_QGK_UEB_PRO' AS code, 'Qualifikationsphase (Grundkurs) · Übergeordnet · Produktion' AS name, 18 AS reihenfolge, 'qualifikationsphase_gk' AS phase, 'kompetenzbereich' AS art, 'DE_QGK_UEB' AS pcode
  UNION ALL
  SELECT 'DE_QGK_SPR_REZ' AS code, 'Qualifikationsphase (Grundkurs) · Sprache · Rezeption' AS name, 20 AS reihenfolge, 'qualifikationsphase_gk' AS phase, 'kompetenzbereich' AS art, 'DE_QGK_SPR' AS pcode
  UNION ALL
  SELECT 'DE_QGK_SPR_PRO' AS code, 'Qualifikationsphase (Grundkurs) · Sprache · Produktion' AS name, 21 AS reihenfolge, 'qualifikationsphase_gk' AS phase, 'kompetenzbereich' AS art, 'DE_QGK_SPR' AS pcode
  UNION ALL
  SELECT 'DE_QGK_TXT_REZ' AS code, 'Qualifikationsphase (Grundkurs) · Texte · Rezeption' AS name, 23 AS reihenfolge, 'qualifikationsphase_gk' AS phase, 'kompetenzbereich' AS art, 'DE_QGK_TXT' AS pcode
  UNION ALL
  SELECT 'DE_QGK_TXT_PRO' AS code, 'Qualifikationsphase (Grundkurs) · Texte · Produktion' AS name, 24 AS reihenfolge, 'qualifikationsphase_gk' AS phase, 'kompetenzbereich' AS art, 'DE_QGK_TXT' AS pcode
  UNION ALL
  SELECT 'DE_QGK_KOM_REZ' AS code, 'Qualifikationsphase (Grundkurs) · Kommunikation · Rezeption' AS name, 26 AS reihenfolge, 'qualifikationsphase_gk' AS phase, 'kompetenzbereich' AS art, 'DE_QGK_KOM' AS pcode
  UNION ALL
  SELECT 'DE_QGK_KOM_PRO' AS code, 'Qualifikationsphase (Grundkurs) · Kommunikation · Produktion' AS name, 27 AS reihenfolge, 'qualifikationsphase_gk' AS phase, 'kompetenzbereich' AS art, 'DE_QGK_KOM' AS pcode
  UNION ALL
  SELECT 'DE_QGK_MED_REZ' AS code, 'Qualifikationsphase (Grundkurs) · Medien · Rezeption' AS name, 29 AS reihenfolge, 'qualifikationsphase_gk' AS phase, 'kompetenzbereich' AS art, 'DE_QGK_MED' AS pcode
  UNION ALL
  SELECT 'DE_QGK_MED_PRO' AS code, 'Qualifikationsphase (Grundkurs) · Medien · Produktion' AS name, 30 AS reihenfolge, 'qualifikationsphase_gk' AS phase, 'kompetenzbereich' AS art, 'DE_QGK_MED' AS pcode
  UNION ALL
  SELECT 'DE_QLK_UEB_REZ' AS code, 'Qualifikationsphase (Leistungskurs) · Übergeordnet · Rezeption' AS name, 32 AS reihenfolge, 'qualifikationsphase_lk' AS phase, 'kompetenzbereich' AS art, 'DE_QLK_UEB' AS pcode
  UNION ALL
  SELECT 'DE_QLK_UEB_PRO' AS code, 'Qualifikationsphase (Leistungskurs) · Übergeordnet · Produktion' AS name, 33 AS reihenfolge, 'qualifikationsphase_lk' AS phase, 'kompetenzbereich' AS art, 'DE_QLK_UEB' AS pcode
  UNION ALL
  SELECT 'DE_QLK_SPR_REZ' AS code, 'Qualifikationsphase (Leistungskurs) · Sprache · Rezeption' AS name, 35 AS reihenfolge, 'qualifikationsphase_lk' AS phase, 'kompetenzbereich' AS art, 'DE_QLK_SPR' AS pcode
  UNION ALL
  SELECT 'DE_QLK_SPR_PRO' AS code, 'Qualifikationsphase (Leistungskurs) · Sprache · Produktion' AS name, 36 AS reihenfolge, 'qualifikationsphase_lk' AS phase, 'kompetenzbereich' AS art, 'DE_QLK_SPR' AS pcode
  UNION ALL
  SELECT 'DE_QLK_TXT_REZ' AS code, 'Qualifikationsphase (Leistungskurs) · Texte · Rezeption' AS name, 38 AS reihenfolge, 'qualifikationsphase_lk' AS phase, 'kompetenzbereich' AS art, 'DE_QLK_TXT' AS pcode
  UNION ALL
  SELECT 'DE_QLK_TXT_PRO' AS code, 'Qualifikationsphase (Leistungskurs) · Texte · Produktion' AS name, 39 AS reihenfolge, 'qualifikationsphase_lk' AS phase, 'kompetenzbereich' AS art, 'DE_QLK_TXT' AS pcode
  UNION ALL
  SELECT 'DE_QLK_KOM_REZ' AS code, 'Qualifikationsphase (Leistungskurs) · Kommunikation · Rezeption' AS name, 41 AS reihenfolge, 'qualifikationsphase_lk' AS phase, 'kompetenzbereich' AS art, 'DE_QLK_KOM' AS pcode
  UNION ALL
  SELECT 'DE_QLK_KOM_PRO' AS code, 'Qualifikationsphase (Leistungskurs) · Kommunikation · Produktion' AS name, 42 AS reihenfolge, 'qualifikationsphase_lk' AS phase, 'kompetenzbereich' AS art, 'DE_QLK_KOM' AS pcode
  UNION ALL
  SELECT 'DE_QLK_MED_REZ' AS code, 'Qualifikationsphase (Leistungskurs) · Medien · Rezeption' AS name, 44 AS reihenfolge, 'qualifikationsphase_lk' AS phase, 'kompetenzbereich' AS art, 'DE_QLK_MED' AS pcode
  UNION ALL
  SELECT 'DE_QLK_MED_PRO' AS code, 'Qualifikationsphase (Leistungskurs) · Medien · Produktion' AS name, 45 AS reihenfolge, 'qualifikationsphase_lk' AS phase, 'kompetenzbereich' AS art, 'DE_QLK_MED' AS pcode
) t JOIN kompetenzbereiche p ON p.rahmen_id = @rahmen AND p.code = t.pcode;

-- --------------------------------------------------------------------------
-- Kompetenzerwartungen (flach)
-- --------------------------------------------------------------------------
-- Einführungsphase · Übergeordnet · Rezeption (8)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EF_UEB_REZ_01' AS code, 'wählen fachlich angemessene Lesestrategien und analytische Zugänge zu fachlichen Gegenständen' AS kurzname, 'wählen fachlich angemessene Lesestrategien und analytische Zugänge zu fachlichen Gegenständen' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_REZ_02' AS code, 'erläutern die Zusammenhänge und Wirkungsweisen verschiedener Gestaltungselemente literarischer und pragmatischer Texte …' AS kurzname, 'erläutern die Zusammenhänge und Wirkungsweisen verschiedener Gestaltungselemente literarischer und pragmatischer Texte sowie medialer Gestaltungen' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_REZ_03' AS code, 'führen Ergebnisse der Untersuchung eines Textes oder einer medialen Gestaltung zu einer Deutung zusammen' AS kurzname, 'führen Ergebnisse der Untersuchung eines Textes oder einer medialen Gestaltung zu einer Deutung zusammen' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_REZ_04' AS code, 'beurteilen sprachliche Gestaltungsmittel, Texte, kommunikatives Handeln und mediale Gestaltung in Abhängigkeit von …' AS kurzname, 'beurteilen sprachliche Gestaltungsmittel, Texte, kommunikatives Handeln und mediale Gestaltung in Abhängigkeit von ihrem jeweiligen Kontext' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_REZ_05' AS code, 'vergleichen Texte und mediale Gestaltungen unter vorgegebenen Aspekten' AS kurzname, 'vergleichen Texte und mediale Gestaltungen unter vorgegebenen Aspekten' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_REZ_06' AS code, 'beurteilen auf der Grundlage von Fachwissen kriteriengeleitet Standpunkte und Aussagen' AS kurzname, 'beurteilen auf der Grundlage von Fachwissen kriteriengeleitet Standpunkte und Aussagen' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_REZ_07' AS code, 'prüfen KI-generierte Textvorschläge kritisch in Bezug auf inhaltliche und sprachlich-stilistische Angemessenheit' AS kurzname, 'prüfen KI-generierte Textvorschläge kritisch in Bezug auf inhaltliche und sprachlich-stilistische Angemessenheit' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_REZ_08' AS code, 'prüfen die funktionsgerechte Verwendung grammatischer Formen und Verknüpfungsmittel.' AS kurzname, 'prüfen die funktionsgerechte Verwendung grammatischer Formen und Verknüpfungsmittel.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EF_UEB_REZ';

-- Einführungsphase · Übergeordnet · Produktion (11)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EF_UEB_PRO_01' AS code, 'planen und gestalten begründet Schreibprozesse aufgaben- und anlassbezogen' AS kurzname, 'planen und gestalten begründet Schreibprozesse aufgaben- und anlassbezogen' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_PRO_02' AS code, 'verwenden verschiedene Schreibformate zur Reorganisation von Vorwissen und Aneignung von Fachwissen' AS kurzname, 'verwenden verschiedene Schreibformate zur Reorganisation von Vorwissen und Aneignung von Fachwissen' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_PRO_03' AS code, 'formulieren mit Blick auf die Kommunikationssituation formal sicher und stilistisch angemessen mit zielführender …' AS kurzname, 'formulieren mit Blick auf die Kommunikationssituation formal sicher und stilistisch angemessen mit zielführender Verwendung von Fachbegriffen' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_PRO_04' AS code, 'unterscheiden in ihren Texten und medialen Gestaltungen beschreibende, deutende und wertende Aussagen' AS kurzname, 'unterscheiden in ihren Texten und medialen Gestaltungen beschreibende, deutende und wertende Aussagen' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_PRO_05' AS code, 'integrieren Formen der impliziten und expliziten Bezugnahme auf fremde Texte (Zitate, Verweise, Paraphrasen) …' AS kurzname, 'integrieren Formen der impliziten und expliziten Bezugnahme auf fremde Texte (Zitate, Verweise, Paraphrasen) funktionsgerecht in eigene Texte und mediale Produkte' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_PRO_06' AS code, 'gestalten mündliche und schriftliche Beiträge adressatenbezogen und zielgerichtet' AS kurzname, 'gestalten mündliche und schriftliche Beiträge adressatenbezogen und zielgerichtet' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_PRO_07' AS code, 'entwickeln argumentativ eigene Positionen zu fachspezifischen Sachverhalten' AS kurzname, 'entwickeln argumentativ eigene Positionen zu fachspezifischen Sachverhalten' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_PRO_08' AS code, 'nutzen verbale, paraverbale und nonverbale Mittel zielorientiert und situationsangemessen' AS kurzname, 'nutzen verbale, paraverbale und nonverbale Mittel zielorientiert und situationsangemessen' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_PRO_09' AS code, 'präsentieren mithilfe geeigneter digitaler Werkzeuge selbstständig fachliche Zusammenhänge unter Beachtung des …' AS kurzname, 'präsentieren mithilfe geeigneter digitaler Werkzeuge selbstständig fachliche Zusammenhänge unter Beachtung des Urheberrechts' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_PRO_10' AS code, 'überarbeiten Texte im Hinblick auf eine normgerechte Verwendung der Sprache (Rechtschreibung, Grammatik und …' AS kurzname, 'überarbeiten Texte im Hinblick auf eine normgerechte Verwendung der Sprache (Rechtschreibung, Grammatik und Zeichensetzung) und nach weiteren vorgegebenen Kriterien, auch unter Verwendung von KI-Werkzeugen' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_UEB_PRO_11' AS code, 'gestalten auch bei einer kritisch-produktiven Verwendung von KI-Werkzeugen Texte eigenständig und verantwortlich.' AS kurzname, 'gestalten auch bei einer kritisch-produktiven Verwendung von KI-Werkzeugen Texte eigenständig und verantwortlich.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EF_UEB_PRO';

-- Einführungsphase · Sprache · Rezeption (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EF_SPR_REZ_01' AS code, 'beschreiben verschiedene Ebenen des Systems Sprache (phonologische, morphologische, syntaktische, semantische und …' AS kurzname, 'beschreiben verschiedene Ebenen des Systems Sprache (phonologische, morphologische, syntaktische, semantische und pragmatische Aspekte)' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_SPR_REZ_02' AS code, 'beurteilen anhand von Beispielen Strukturen und Funktionen verschiedener Sprachvarietäten (Sprache als …' AS kurzname, 'beurteilen anhand von Beispielen Strukturen und Funktionen verschiedener Sprachvarietäten (Sprache als Distinktionsmerkmal, Identifikation über Sprache)' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_SPR_REZ_03' AS code, 'beurteilen die gesellschaftliche Bedeutung sprachlicher Zuschreibungen (u. a. Diskriminierung durch Sprache, …' AS kurzname, 'beurteilen die gesellschaftliche Bedeutung sprachlicher Zuschreibungen (u. a. Diskriminierung durch Sprache, Geschlechterstereotype in der Sprache)' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_SPR_REZ_04' AS code, 'erläutern das Verhältnis von Mündlichkeit und Schriftlichkeit unter Berücksichtigung aktueller Veränderungen von Sprache' AS kurzname, 'erläutern das Verhältnis von Mündlichkeit und Schriftlichkeit unter Berücksichtigung aktueller Veränderungen von Sprache' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_SPR_REZ_05' AS code, 'beurteilen die situative Angemessenheit konzeptioneller Schriftlichkeit und konzeptioneller Mündlichkeit' AS kurzname, 'beurteilen die situative Angemessenheit konzeptioneller Schriftlichkeit und konzeptioneller Mündlichkeit' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_SPR_REZ_06' AS code, 'erläutern die Wirkung sprachlicher Gestaltungsmittel und ihre Bedeutung für die Textaussage.' AS kurzname, 'erläutern die Wirkung sprachlicher Gestaltungsmittel und ihre Bedeutung für die Textaussage.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EF_SPR_REZ';

-- Einführungsphase · Sprache · Produktion (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EF_SPR_PRO_01' AS code, 'stellen Sachverhalte im Hinblick auf die Kommunikationssituation, die Adressaten und die Funktion sprachlich angemessen …' AS kurzname, 'stellen Sachverhalte im Hinblick auf die Kommunikationssituation, die Adressaten und die Funktion sprachlich angemessen dar' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_SPR_PRO_02' AS code, 'verfassen Texte unter Berücksichtigung ihres Wissens über sprachliche Zuschreibungen' AS kurzname, 'verfassen Texte unter Berücksichtigung ihres Wissens über sprachliche Zuschreibungen' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_SPR_PRO_03' AS code, 'überarbeiten mithilfe von vorgegebenen Kriterien (u. a. stilistische Angemessenheit, Verständlichkeit) die sprachliche …' AS kurzname, 'überarbeiten mithilfe von vorgegebenen Kriterien (u. a. stilistische Angemessenheit, Verständlichkeit) die sprachliche Darstellung in Texten.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EF_SPR_PRO';

-- Einführungsphase · Texte · Rezeption (8)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EF_TXT_REZ_01' AS code, 'planen und steuern begründet ihren Leseprozess unter Berücksichtigung von Leseziel, Aufgabenstellung, Umfang und …' AS kurzname, 'planen und steuern begründet ihren Leseprozess unter Berücksichtigung von Leseziel, Aufgabenstellung, Umfang und Komplexität der Texte' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_TXT_REZ_02' AS code, 'setzen Textteile mit dem Textganzen in Beziehung (lokale und globale Kohärenz)' AS kurzname, 'setzen Textteile mit dem Textganzen in Beziehung (lokale und globale Kohärenz)' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_TXT_REZ_03' AS code, 'interpretieren textimmanent und textübergreifend dramatische, erzählende sowie lyrische Texte, auch unter …' AS kurzname, 'interpretieren textimmanent und textübergreifend dramatische, erzählende sowie lyrische Texte, auch unter Berücksichtigung grundlegender Strukturmerkmale der jeweiligen literarischen Gattung' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_TXT_REZ_04' AS code, 'beschreiben ihre individuelle Wahrnehmung der ästhetischen Gestaltung literarischer Texte' AS kurzname, 'beschreiben ihre individuelle Wahrnehmung der ästhetischen Gestaltung literarischer Texte' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_TXT_REZ_05' AS code, 'erschließen in Kooperation (auch) mit digitalen Werkzeugen die Mehrdeutigkeit literarischer Texte in der eigenen …' AS kurzname, 'erschließen in Kooperation (auch) mit digitalen Werkzeugen die Mehrdeutigkeit literarischer Texte in der eigenen Interpretation und in der Auseinandersetzung mit verschiedenen Lesarten' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_TXT_REZ_06' AS code, 'analysieren pragmatische Texte textimmanent und mithilfe textübergreifender Informationen' AS kurzname, 'analysieren pragmatische Texte textimmanent und mithilfe textübergreifender Informationen' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_TXT_REZ_07' AS code, 'entnehmen Texten und Materialdossiers zielgerichtet relevante Informationen und Argumente (Identifizieren, Ordnen, …' AS kurzname, 'entnehmen Texten und Materialdossiers zielgerichtet relevante Informationen und Argumente (Identifizieren, Ordnen, Auswählen)' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_TXT_REZ_08' AS code, 'setzen Texte (u. a. in einem Materialdossier) in Beziehung zueinander und leiten unter Berücksichtigung des Leseziels …' AS kurzname, 'setzen Texte (u. a. in einem Materialdossier) in Beziehung zueinander und leiten unter Berücksichtigung des Leseziels und der Aufgabenstellung Teilaspekte eines Themas ab.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EF_TXT_REZ';

-- Einführungsphase · Texte · Produktion (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EF_TXT_PRO_01' AS code, 'planen und steuern begründet ihren Schreibprozess unter Berücksichtigung von Schreibziel und Aufgabenstellung' AS kurzname, 'planen und steuern begründet ihren Schreibprozess unter Berücksichtigung von Schreibziel und Aufgabenstellung' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_TXT_PRO_02' AS code, 'verfassen informierende und argumentierende Texte sach-, adressaten- und situationsgerecht' AS kurzname, 'verfassen informierende und argumentierende Texte sach-, adressaten- und situationsgerecht' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_TXT_PRO_03' AS code, 'setzen zielgerichtet verschiedene Textmuster (typische grammatische Konstruktionen und satzübergreifende Muster der …' AS kurzname, 'setzen zielgerichtet verschiedene Textmuster (typische grammatische Konstruktionen und satzübergreifende Muster der Textorganisation) bei der Erstellung von analysierenden, informierenden, argumentierenden Texten und beim produktionsorientierten Schreiben ein' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_TXT_PRO_04' AS code, 'unterscheiden in ihren Texten zwischen Ergebnissen textimmanenter Untersuchungsverfahren und dem Einbezug …' AS kurzname, 'unterscheiden in ihren Texten zwischen Ergebnissen textimmanenter Untersuchungsverfahren und dem Einbezug textübergreifender Informationen' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_TXT_PRO_05' AS code, 'stellen ihr Textverständnis durch Formen produktionsorientierten Schreibens dar' AS kurzname, 'stellen ihr Textverständnis durch Formen produktionsorientierten Schreibens dar' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_TXT_PRO_06' AS code, 'interpretieren literarische Texte gestaltend.' AS kurzname, 'interpretieren literarische Texte gestaltend.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EF_TXT_PRO';

-- Einführungsphase · Kommunikation · Rezeption (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EF_KOM_REZ_01' AS code, 'untersuchen Kommunikationssituationen und -verläufe im Alltag mithilfe ausgewählter Kommunikationsmodelle' AS kurzname, 'untersuchen Kommunikationssituationen und -verläufe im Alltag mithilfe ausgewählter Kommunikationsmodelle' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_KOM_REZ_02' AS code, 'unterscheiden zwischen Alltagskommunikation und literarisch gestalteter Kommunikation' AS kurzname, 'unterscheiden zwischen Alltagskommunikation und literarisch gestalteter Kommunikation' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_KOM_REZ_03' AS code, 'beurteilen den Wert von Kommunikationsmodellen für das Verstehen literarischer Texte' AS kurzname, 'beurteilen den Wert von Kommunikationsmodellen für das Verstehen literarischer Texte' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_KOM_REZ_04' AS code, 'benennen die jeweils geltenden Konventionen monologischer und dialogischer Kommunikation in unterschiedlichen …' AS kurzname, 'benennen die jeweils geltenden Konventionen monologischer und dialogischer Kommunikation in unterschiedlichen (medialen) Kontexten' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_KOM_REZ_05' AS code, 'untersuchen monologische und dialogische Kommunikation im Hinblick auf ihre Funktion (u. a. Appell, Ausdruck, …' AS kurzname, 'untersuchen monologische und dialogische Kommunikation im Hinblick auf ihre Funktion (u. a. Appell, Ausdruck, Darstellung).' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EF_KOM_REZ';

-- Einführungsphase · Kommunikation · Produktion (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EF_KOM_PRO_01' AS code, 'gestalten ihr eigenes Kommunikationsverhalten in verschiedenen Kontexten unter Berücksichtigung der jeweils geltenden …' AS kurzname, 'gestalten ihr eigenes Kommunikationsverhalten in verschiedenen Kontexten unter Berücksichtigung der jeweils geltenden Konventionen' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_KOM_PRO_02' AS code, 'formulieren mündliche Beiträge im Hinblick auf die Funktion ziel- und adressatenorientiert' AS kurzname, 'formulieren mündliche Beiträge im Hinblick auf die Funktion ziel- und adressatenorientiert' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_KOM_PRO_03' AS code, 'formulieren unter Berücksichtigung ihres Wissens über Formen und Regeln angemessener Kommunikation Rückmeldungen zu …' AS kurzname, 'formulieren unter Berücksichtigung ihres Wissens über Formen und Regeln angemessener Kommunikation Rückmeldungen zu Beiträgen anderer.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EF_KOM_PRO';

-- Einführungsphase · Medien · Rezeption (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EF_MED_REZ_01' AS code, 'prüfen den Geltungsanspruch von (selbst recherchierten) Informationen in verschiedenen Darbietungsformen unter …' AS kurzname, 'prüfen den Geltungsanspruch von (selbst recherchierten) Informationen in verschiedenen Darbietungsformen unter Berücksichtigung der Verlässlichkeit von Quellen und der Objektivität der Darstellung' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_MED_REZ_02' AS code, 'erläutern Möglichkeiten und Risiken beim Generieren, Teilen und Kommentieren von Inhalten' AS kurzname, 'erläutern Möglichkeiten und Risiken beim Generieren, Teilen und Kommentieren von Inhalten' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_MED_REZ_03' AS code, 'beurteilen an Beispielen die individuelle und gesellschaftliche Verantwortung bei der Teilhabe an Meinungsbildungs- und …' AS kurzname, 'beurteilen an Beispielen die individuelle und gesellschaftliche Verantwortung bei der Teilhabe an Meinungsbildungs- und Entscheidungsprozessen' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_MED_REZ_04' AS code, 'vergleichen den Leseprozess bei linearen und nichtlinearen Texten' AS kurzname, 'vergleichen den Leseprozess bei linearen und nichtlinearen Texten' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_MED_REZ_05' AS code, 'erläutern an Beispielen Wirkungsweisen multimodaler Texte (u. a. multimodale Umsetzung lyrischer Texte).' AS kurzname, 'erläutern an Beispielen Wirkungsweisen multimodaler Texte (u. a. multimodale Umsetzung lyrischer Texte).' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EF_MED_REZ';

-- Einführungsphase · Medien · Produktion (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EF_MED_PRO_01' AS code, 'überarbeiten Texte kriteriengeleitet mithilfe digitaler Werkzeuge (auch in kollaborativen Verfahren)' AS kurzname, 'überarbeiten Texte kriteriengeleitet mithilfe digitaler Werkzeuge (auch in kollaborativen Verfahren)' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_MED_PRO_02' AS code, 'erstellen Beiträge in medialen Kommunikationssituationen unter Berücksichtigung von Urheber- und Persönlichkeitsrechten' AS kurzname, 'erstellen Beiträge in medialen Kommunikationssituationen unter Berücksichtigung von Urheber- und Persönlichkeitsrechten' AS beschreibung
  UNION ALL
  SELECT 'DE_EF_MED_PRO_03' AS code, 'gestalten Texte mithilfe digitaler Werkzeuge multimodal.' AS kurzname, 'gestalten Texte mithilfe digitaler Werkzeuge multimodal.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EF_MED_PRO';

-- Qualifikationsphase (Grundkurs) · Übergeordnet · Rezeption (9)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QGK_UEB_REZ_01' AS code, 'ermitteln durch Anwendung differenzierter Recherchestrategien in verschiedenen Medien Informationen zu fachbezogenen …' AS kurzname, 'ermitteln durch Anwendung differenzierter Recherchestrategien in verschiedenen Medien Informationen zu fachbezogenen Aufgabenstellungen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_REZ_02' AS code, 'wenden Strategien und Techniken des Textverstehens unter Nutzung von Fachwissen selbstständig an' AS kurzname, 'wenden Strategien und Techniken des Textverstehens unter Nutzung von Fachwissen selbstständig an' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_REZ_03' AS code, 'beurteilen auf der Grundlage von Fachwissen selbstständig Standpunkte und Argumentationen' AS kurzname, 'beurteilen auf der Grundlage von Fachwissen selbstständig Standpunkte und Argumentationen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_REZ_04' AS code, 'erläutern den Einfluss des jeweiligen historischen und gesellschaftlichen Kontextes auf Sprache, Texte, kommunikatives …' AS kurzname, 'erläutern den Einfluss des jeweiligen historischen und gesellschaftlichen Kontextes auf Sprache, Texte, kommunikatives Handeln und mediale Gestaltungen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_REZ_05' AS code, 'vergleichen Texte und mediale Gestaltungen unter vorgegebenen und selbst gewählten Aspekten' AS kurzname, 'vergleichen Texte und mediale Gestaltungen unter vorgegebenen und selbst gewählten Aspekten' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_REZ_06' AS code, 'erschließen Texte und mediale Gestaltungen im Verbund (motivische und thematische, diachrone und synchrone …' AS kurzname, 'erschließen Texte und mediale Gestaltungen im Verbund (motivische und thematische, diachrone und synchrone Zusammenhänge)' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_REZ_07' AS code, 'beurteilen die Zusammenhänge und Wirkungsweisen verschiedener Gestaltungselemente literarischer und pragmatischer Texte …' AS kurzname, 'beurteilen die Zusammenhänge und Wirkungsweisen verschiedener Gestaltungselemente literarischer und pragmatischer Texte sowie medialer Gestaltungen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_REZ_08' AS code, 'beurteilen KI-generierte Textvorschläge kritisch in Bezug auf inhaltliche und sprachlich-stilistische Angemessenheit …' AS kurzname, 'beurteilen KI-generierte Textvorschläge kritisch in Bezug auf inhaltliche und sprachlich-stilistische Angemessenheit und im Hinblick auf Fragen der Autorschaft' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_REZ_09' AS code, 'prüfen die funktionsgerechte Verwendung von grammatischen Formen und Verknüpfungsmitteln im Hinblick auf Textkohärenz.' AS kurzname, 'prüfen die funktionsgerechte Verwendung von grammatischen Formen und Verknüpfungsmitteln im Hinblick auf Textkohärenz.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QGK_UEB_REZ';

-- Qualifikationsphase (Grundkurs) · Übergeordnet · Produktion (11)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QGK_UEB_PRO_01' AS code, 'planen, gestalten und reflektieren aufgaben- und anlassbezogen Schreibprozesse' AS kurzname, 'planen, gestalten und reflektieren aufgaben- und anlassbezogen Schreibprozesse' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_PRO_02' AS code, 'verwenden zielgerichtet verschiedene Schreibformate zur Reorganisation von Vorwissen und Aneignung von Fachwissen' AS kurzname, 'verwenden zielgerichtet verschiedene Schreibformate zur Reorganisation von Vorwissen und Aneignung von Fachwissen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_PRO_03' AS code, 'formulieren mündlich und schriftlich dem kommunikativen Ziel entsprechend formal sicher, (fach-)sprachlich …' AS kurzname, 'formulieren mündlich und schriftlich dem kommunikativen Ziel entsprechend formal sicher, (fach-)sprachlich differenziert und stilistisch angemessen eigene Texte' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_PRO_04' AS code, 'formulieren argumentativ eigene Positionen zu fachspezifischen Sachverhalten vor dem Hintergrund ihres Fachwissens' AS kurzname, 'formulieren argumentativ eigene Positionen zu fachspezifischen Sachverhalten vor dem Hintergrund ihres Fachwissens' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_PRO_05' AS code, 'gestalten monologische und dialogische Beiträge adressatenbezogen und zielgerichtet' AS kurzname, 'gestalten monologische und dialogische Beiträge adressatenbezogen und zielgerichtet' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_PRO_06' AS code, 'unterscheiden in ihren Texten und medialen Gestaltungen beschreibende, deutende und wertende Aussagen' AS kurzname, 'unterscheiden in ihren Texten und medialen Gestaltungen beschreibende, deutende und wertende Aussagen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_PRO_07' AS code, 'integrieren Formen der impliziten und expliziten Bezugnahme auf kontinuierliche und diskontinuierliche Texte (Zitate, …' AS kurzname, 'integrieren Formen der impliziten und expliziten Bezugnahme auf kontinuierliche und diskontinuierliche Texte (Zitate, Verweise, Paraphrasen) funktionsgerecht in eigene Texte und mediale Produkte' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_PRO_08' AS code, 'nutzen verbale, paraverbale und nonverbale Mittel zielorientiert und situationsangemessen' AS kurzname, 'nutzen verbale, paraverbale und nonverbale Mittel zielorientiert und situationsangemessen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_PRO_09' AS code, 'präsentieren mithilfe geeigneter digitaler Werkzeuge selbstständig fachlich komplexe Zusammenhänge unter Beachtung des …' AS kurzname, 'präsentieren mithilfe geeigneter digitaler Werkzeuge selbstständig fachlich komplexe Zusammenhänge unter Beachtung des Urheberrechts' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_PRO_10' AS code, 'überarbeiten Texte im Hinblick auf eine normgerechte Verwendung der Sprache (Rechtschreibung, Grammatik und …' AS kurzname, 'überarbeiten Texte im Hinblick auf eine normgerechte Verwendung der Sprache (Rechtschreibung, Grammatik und Zeichensetzung) und nach weiteren Kriterien, auch unter Verwendung von KI-Werkzeugen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_UEB_PRO_11' AS code, 'gestalten auch bei einer kritisch-produktiven Verwendung von KI-Werkzeugen Texte eigenständig und verantwortlich.' AS kurzname, 'gestalten auch bei einer kritisch-produktiven Verwendung von KI-Werkzeugen Texte eigenständig und verantwortlich.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QGK_UEB_PRO';

-- Qualifikationsphase (Grundkurs) · Sprache · Rezeption (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QGK_SPR_REZ_01' AS code, 'vergleichen die Grundzüge unterschiedlicher Theorien zum Verhältnis von Sprache, Denken und Wirklichkeit (Zeichen, …' AS kurzname, 'vergleichen die Grundzüge unterschiedlicher Theorien zum Verhältnis von Sprache, Denken und Wirklichkeit (Zeichen, Vorstellung und Gegenstand)' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_SPR_REZ_02' AS code, 'vergleichen Sprachvarietäten in verschiedenen Erscheinungsformen (u. a. Soziolekt, Dialekt, Regionalsprache wie …' AS kurzname, 'vergleichen Sprachvarietäten in verschiedenen Erscheinungsformen (u. a. Soziolekt, Dialekt, Regionalsprache wie Niederdeutsch) und deren gesellschaftliche Bedeutsamkeit' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_SPR_REZ_03' AS code, 'erklären Veränderungstendenzen der Gegenwartssprache und ihre Ursachen (Mehrsprachigkeit, Einfluss von Medien, …' AS kurzname, 'erklären Veränderungstendenzen der Gegenwartssprache und ihre Ursachen (Mehrsprachigkeit, Einfluss von Medien, sprachliche Kreativität)' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_SPR_REZ_04' AS code, 'erläutern Phänomene innerer und äußerer Mehrsprachigkeit und ihre Auswirkungen' AS kurzname, 'erläutern Phänomene innerer und äußerer Mehrsprachigkeit und ihre Auswirkungen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_SPR_REZ_05' AS code, 'erklären Formen gesteuerten und ungesteuerten Sprachwandels (u. a. gendergerechte Sprache)' AS kurzname, 'erklären Formen gesteuerten und ungesteuerten Sprachwandels (u. a. gendergerechte Sprache)' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_SPR_REZ_06' AS code, 'erläutern sprachlich-stilistische Mittel in schriftlichen und mündlichen Texten im Hinblick auf deren Bedeutung für die …' AS kurzname, 'erläutern sprachlich-stilistische Mittel in schriftlichen und mündlichen Texten im Hinblick auf deren Bedeutung für die Textaussage und Wirkung.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QGK_SPR_REZ';

-- Qualifikationsphase (Grundkurs) · Sprache · Produktion (2)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QGK_SPR_PRO_01' AS code, 'stellen Sachverhalte unter Berücksichtigung der Kommunikationssituation, der Adressaten und der Funktion sprachlich …' AS kurzname, 'stellen Sachverhalte unter Berücksichtigung der Kommunikationssituation, der Adressaten und der Funktion sprachlich differenziert dar' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_SPR_PRO_02' AS code, 'überarbeiten selbstständig die sprachliche Darstellung in Texten mithilfe von Kriterien (u. a. stilistische …' AS kurzname, 'überarbeiten selbstständig die sprachliche Darstellung in Texten mithilfe von Kriterien (u. a. stilistische Angemessenheit, Verständlichkeit).' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QGK_SPR_PRO';

-- Qualifikationsphase (Grundkurs) · Texte · Rezeption (14)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QGK_TXT_REZ_01' AS code, 'planen und steuern begründet ihren Leseprozess unter Berücksichtigung von Leseziel, Aufgabenstellung, Umfang und …' AS kurzname, 'planen und steuern begründet ihren Leseprozess unter Berücksichtigung von Leseziel, Aufgabenstellung, Umfang und Komplexität der Texte' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_REZ_02' AS code, 'interpretieren strukturell unterschiedliche dramatische und erzählende Texte, auch unter Berücksichtigung der …' AS kurzname, 'interpretieren strukturell unterschiedliche dramatische und erzählende Texte, auch unter Berücksichtigung der Entwicklung der gattungstypischen Gestaltungsformen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_REZ_03' AS code, 'interpretieren lyrische Texte aus unterschiedlichen Epochen, auch unter Berücksichtigung der Formen des lyrischen …' AS kurzname, 'interpretieren lyrische Texte aus unterschiedlichen Epochen, auch unter Berücksichtigung der Formen des lyrischen Sprechens' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_REZ_04' AS code, 'untersuchen selbstständig Texte mithilfe von textimmanenten und textübergreifenden Verfahren und führen ihre Ergebnisse …' AS kurzname, 'untersuchen selbstständig Texte mithilfe von textimmanenten und textübergreifenden Verfahren und führen ihre Ergebnisse in einer schlüssigen Deutung zusammen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_REZ_05' AS code, 'erschließen synchrone Zusammenhänge aus der Zusammenschau literarischer Texte unter Einbezug weiterer Kontexte (u. a. …' AS kurzname, 'erschließen synchrone Zusammenhänge aus der Zusammenschau literarischer Texte unter Einbezug weiterer Kontexte (u. a. gesellschaftspolitische Hintergründe)' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_REZ_06' AS code, 'ordnen literarische Texte in grundlegende literaturhistorische und historisch-gesellschaftliche Entwicklungen ein (von …' AS kurzname, 'ordnen literarische Texte in grundlegende literaturhistorische und historisch-gesellschaftliche Entwicklungen ein (von der Aufklärung bis zur Gegenwart)' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_REZ_07' AS code, 'erläutern die Möglichkeiten und die Grenzen der Zuordnung literarischer Werke zu Epochen' AS kurzname, 'erläutern die Möglichkeiten und die Grenzen der Zuordnung literarischer Werke zu Epochen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_REZ_08' AS code, 'setzen einen literarischen Text zu anderen Texten (Aussagen von Autorinnen und Autoren, literaturwissenschaftliche …' AS kurzname, 'setzen einen literarischen Text zu anderen Texten (Aussagen von Autorinnen und Autoren, literaturwissenschaftliche Texte) in Beziehung' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_REZ_09' AS code, 'vergleichen ihre individuelle Wahrnehmung der ästhetischen Gestaltung literarischer Texte' AS kurzname, 'vergleichen ihre individuelle Wahrnehmung der ästhetischen Gestaltung literarischer Texte' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_REZ_10' AS code, 'erläutern an ausgewählten Beispielen die Mehrdeutigkeit von Texten' AS kurzname, 'erläutern an ausgewählten Beispielen die Mehrdeutigkeit von Texten' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_REZ_11' AS code, 'erläutern die Unterschiede zwischen fiktionalen und nicht-fiktionalen Texten' AS kurzname, 'erläutern die Unterschiede zwischen fiktionalen und nicht-fiktionalen Texten' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_REZ_12' AS code, 'analysieren komplexe pragmatische Texte und mediale Produkte, auch unter Berücksichtigung der Textfunktion (Ausdruck, …' AS kurzname, 'analysieren komplexe pragmatische Texte und mediale Produkte, auch unter Berücksichtigung der Textfunktion (Ausdruck, Darstellung, Appell) und des Modus (narrativ, deskriptiv, argumentativ)' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_REZ_13' AS code, 'entnehmen Texten und Materialdossiers zielgerichtet relevante Informationen und Argumente (Identifizieren, Ordnen, …' AS kurzname, 'entnehmen Texten und Materialdossiers zielgerichtet relevante Informationen und Argumente (Identifizieren, Ordnen, Auswählen)' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_REZ_14' AS code, 'setzen Texte (u. a. in einem Materialdossier) in Beziehung zueinander und leiten unter Berücksichtigung der …' AS kurzname, 'setzen Texte (u. a. in einem Materialdossier) in Beziehung zueinander und leiten unter Berücksichtigung der Aufgabenstellung selbstständig Teilaspekte eines Themas oder Vergleichsaspekte ab.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QGK_TXT_REZ';

-- Qualifikationsphase (Grundkurs) · Texte · Produktion (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QGK_TXT_PRO_01' AS code, 'planen und steuern begründet ihren Schreibprozess unter Berücksichtigung von Aufgabenstellung und Schreibziel' AS kurzname, 'planen und steuern begründet ihren Schreibprozess unter Berücksichtigung von Aufgabenstellung und Schreibziel' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_PRO_02' AS code, 'entwerfen auf der Grundlage der Textrezeption eine inhaltliche Gliederung für ihre eigenen Texte' AS kurzname, 'entwerfen auf der Grundlage der Textrezeption eine inhaltliche Gliederung für ihre eigenen Texte' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_PRO_03' AS code, 'formulieren unter Anwendung von Textmustern (typische grammatische Konstruktionen und satzübergreifende Muster der …' AS kurzname, 'formulieren unter Anwendung von Textmustern (typische grammatische Konstruktionen und satzübergreifende Muster der Textorganisation) Texte sach-, adressaten- und situationsgerecht' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_PRO_04' AS code, 'stellen in ihren Texten Ergebnisse textimmanenter und textübergreifender Untersuchungsverfahren dar und führen sie in …' AS kurzname, 'stellen in ihren Texten Ergebnisse textimmanenter und textübergreifender Untersuchungsverfahren dar und führen sie in einer eigenständigen Deutung zusammen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_PRO_05' AS code, 'stellen ihr Textverständnis durch Formen produktionsorientierten Schreibens dar' AS kurzname, 'stellen ihr Textverständnis durch Formen produktionsorientierten Schreibens dar' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_TXT_PRO_06' AS code, 'interpretieren literarische Texte durch einen gestaltenden Vortrag.' AS kurzname, 'interpretieren literarische Texte durch einen gestaltenden Vortrag.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QGK_TXT_PRO';

-- Qualifikationsphase (Grundkurs) · Kommunikation · Rezeption (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QGK_KOM_REZ_01' AS code, 'analysieren sprachliches Handeln in rhetorisch gestalteter Kommunikation unter Einbezug einzelner Kommunikationsmodelle' AS kurzname, 'analysieren sprachliches Handeln in rhetorisch gestalteter Kommunikation unter Einbezug einzelner Kommunikationsmodelle' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_KOM_REZ_02' AS code, 'setzen in der Analyse rhetorisch gestalteter Kommunikation verbale, nonverbale und paraverbale Aspekte miteinander in …' AS kurzname, 'setzen in der Analyse rhetorisch gestalteter Kommunikation verbale, nonverbale und paraverbale Aspekte miteinander in Beziehung' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_KOM_REZ_03' AS code, 'untersuchen die Kommunikation in literarischen Texten (symmetrische und asymmetrische Kommunikation, auch unter …' AS kurzname, 'untersuchen die Kommunikation in literarischen Texten (symmetrische und asymmetrische Kommunikation, auch unter Berücksichtigung gesellschaftlicher Rollen und Positionen sowie Genderaspekten)' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_KOM_REZ_04' AS code, 'erklären Merkmale verständigungsorientierter und manipulativer Kommunikation (u. a. im politischen Kontext)' AS kurzname, 'erklären Merkmale verständigungsorientierter und manipulativer Kommunikation (u. a. im politischen Kontext)' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_KOM_REZ_05' AS code, 'erläutern anhand ausgewählter Beispiele das Verhältnis von Öffentlichkeit und Privatheit in medialen Kontexten.' AS kurzname, 'erläutern anhand ausgewählter Beispiele das Verhältnis von Öffentlichkeit und Privatheit in medialen Kontexten.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QGK_KOM_REZ';

-- Qualifikationsphase (Grundkurs) · Kommunikation · Produktion (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QGK_KOM_PRO_01' AS code, 'erläutern Fachinhalte in monologischen Gesprächsformen Verständnis fördernd unter Nutzung von Visualisierungen' AS kurzname, 'erläutern Fachinhalte in monologischen Gesprächsformen Verständnis fördernd unter Nutzung von Visualisierungen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_KOM_PRO_02' AS code, 'begründen ihre Position in dialogischen Gesprächsformen sach- und adressatengerecht sowie dem kommunikativen Kontext …' AS kurzname, 'begründen ihre Position in dialogischen Gesprächsformen sach- und adressatengerecht sowie dem kommunikativen Kontext angemessen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_KOM_PRO_03' AS code, 'verfassen Beiträge in digitalen Kontexten im Hinblick auf die Wirkungsabsicht und die potenzielle Reichweite.' AS kurzname, 'verfassen Beiträge in digitalen Kontexten im Hinblick auf die Wirkungsabsicht und die potenzielle Reichweite.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QGK_KOM_PRO';

-- Qualifikationsphase (Grundkurs) · Medien · Rezeption (7)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QGK_MED_REZ_01' AS code, 'beurteilen die Qualität von Informationen aus verschiedenartigen Quellen (u. a. Grad an Fiktionalität, Seriosität, …' AS kurzname, 'beurteilen die Qualität von Informationen aus verschiedenartigen Quellen (u. a. Grad an Fiktionalität, Seriosität, fachliche Differenziertheit)' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_MED_REZ_02' AS code, 'ordnen die Möglichkeiten verschiedener digitaler Werkzeuge zur Verarbeitung von Wissen und zum Erkenntnisgewinn ein' AS kurzname, 'ordnen die Möglichkeiten verschiedener digitaler Werkzeuge zur Verarbeitung von Wissen und zum Erkenntnisgewinn ein' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_MED_REZ_03' AS code, 'erläutern an Beispielen Zusammenhänge zwischen medialem Kontext, Verbreitungsweisen und der Darbietungsform von …' AS kurzname, 'erläutern an Beispielen Zusammenhänge zwischen medialem Kontext, Verbreitungsweisen und der Darbietungsform von Informationen' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_MED_REZ_04' AS code, 'erläutern an Beispielen Möglichkeiten und Gefahren der Einflussnahme in Medien (u. a. Teilhabe an öffentlichen …' AS kurzname, 'erläutern an Beispielen Möglichkeiten und Gefahren der Einflussnahme in Medien (u. a. Teilhabe an öffentlichen Diskursen, Verbreitung von Falschmeldungen, Hate Speech)' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_MED_REZ_05' AS code, 'erläutern Gestaltungsmöglichkeiten multimodalen Erzählens auf der Figuren- und Handlungsebene' AS kurzname, 'erläutern Gestaltungsmöglichkeiten multimodalen Erzählens auf der Figuren- und Handlungsebene' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_MED_REZ_06' AS code, 'analysieren Ausschnitte der filmischen Umsetzung einer Textvorlage in ihrer ästhetischen Gestaltung und ihrer Wirkung' AS kurzname, 'analysieren Ausschnitte der filmischen Umsetzung einer Textvorlage in ihrer ästhetischen Gestaltung und ihrer Wirkung' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_MED_REZ_07' AS code, 'analysieren Auszüge der Bühneninszenierung eines dramatischen Textes in ihrer ästhetischen Gestaltung und ihrer Wirkung.' AS kurzname, 'analysieren Auszüge der Bühneninszenierung eines dramatischen Textes in ihrer ästhetischen Gestaltung und ihrer Wirkung.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QGK_MED_REZ';

-- Qualifikationsphase (Grundkurs) · Medien · Produktion (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QGK_MED_PRO_01' AS code, 'verfassen und überarbeiten Texte mithilfe digitaler Werkzeuge, auch in kollaborativen Verfahren' AS kurzname, 'verfassen und überarbeiten Texte mithilfe digitaler Werkzeuge, auch in kollaborativen Verfahren' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_MED_PRO_02' AS code, 'verfassen Beiträge in medialen Kommunikationssituationen unter Berücksichtigung von Persönlichkeitsrechten' AS kurzname, 'verfassen Beiträge in medialen Kommunikationssituationen unter Berücksichtigung von Persönlichkeitsrechten' AS beschreibung
  UNION ALL
  SELECT 'DE_QGK_MED_PRO_03' AS code, 'gestalten Beiträge in unterschiedlichen medialen Formaten situations- und adressatengerecht unter Berücksichtigung von …' AS kurzname, 'gestalten Beiträge in unterschiedlichen medialen Formaten situations- und adressatengerecht unter Berücksichtigung von Urheberrechten.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QGK_MED_PRO';

-- Qualifikationsphase (Leistungskurs) · Übergeordnet · Rezeption (11)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QLK_UEB_REZ_01' AS code, 'ermitteln durch Anwendung differenzierter Recherchestrategien in verschiedenen Medien Informationen zu komplexen …' AS kurzname, 'ermitteln durch Anwendung differenzierter Recherchestrategien in verschiedenen Medien Informationen zu komplexen fachbezogenen Aufgabenstellungen' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_REZ_02' AS code, 'wenden Strategien und Techniken des Textverstehens unter Nutzung von Fachwissen in Bezug auf Texte reflektiert an' AS kurzname, 'wenden Strategien und Techniken des Textverstehens unter Nutzung von Fachwissen in Bezug auf Texte reflektiert an' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_REZ_03' AS code, 'ordnen sprachliche Gestaltungsmittel, Texte, kommunikatives Handeln und mediale Gestaltungen in …' AS kurzname, 'ordnen sprachliche Gestaltungsmittel, Texte, kommunikatives Handeln und mediale Gestaltungen in historisch-gesellschaftliche Entwicklungslinien ein' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_REZ_04' AS code, 'erläutern die Bedingtheit von Verstehensprozessen' AS kurzname, 'erläutern die Bedingtheit von Verstehensprozessen' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_REZ_05' AS code, 'analysieren selbstständig Texte mithilfe von textimmanenten und textübergreifenden Verfahren, überprüfen die …' AS kurzname, 'analysieren selbstständig Texte mithilfe von textimmanenten und textübergreifenden Verfahren, überprüfen die Analyseergebnisse und führen sie in einer schlüssigen differenzierten Deutung zusammen' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_REZ_06' AS code, 'beurteilen auf der Grundlage von Fachwissen selbstständig und differenziert Standpunkte und Argumentationen' AS kurzname, 'beurteilen auf der Grundlage von Fachwissen selbstständig und differenziert Standpunkte und Argumentationen' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_REZ_07' AS code, 'erläutern differenziert die Zusammenhänge und Wirkungsweisen verschiedener Gestaltungselemente in literarischen Texten, …' AS kurzname, 'erläutern differenziert die Zusammenhänge und Wirkungsweisen verschiedener Gestaltungselemente in literarischen Texten, pragmatischen Texten und medialen Gestaltungen' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_REZ_08' AS code, 'vergleichen Texte und mediale Gestaltungen unter vorgegebenen und selbst gewählten Aspekten' AS kurzname, 'vergleichen Texte und mediale Gestaltungen unter vorgegebenen und selbst gewählten Aspekten' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_REZ_09' AS code, 'erschließen Texte und mediale Gestaltungen im Verbund (motivische und thematische, diachrone und synchrone …' AS kurzname, 'erschließen Texte und mediale Gestaltungen im Verbund (motivische und thematische, diachrone und synchrone Zusammenhänge)' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_REZ_10' AS code, 'beurteilen KI-generierte Textvorschläge kritisch in Bezug auf inhaltliche und sprachlich-stilistische Angemessenheit …' AS kurzname, 'beurteilen KI-generierte Textvorschläge kritisch in Bezug auf inhaltliche und sprachlich-stilistische Angemessenheit und im Hinblick auf Fragen der Autorschaft' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_REZ_11' AS code, 'prüfen die funktionsgerechte Verwendung von grammatischen Formen und Verknüpfungsmitteln im Hinblick auf Textkohärenz.' AS kurzname, 'prüfen die funktionsgerechte Verwendung von grammatischen Formen und Verknüpfungsmitteln im Hinblick auf Textkohärenz.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QLK_UEB_REZ';

-- Qualifikationsphase (Leistungskurs) · Übergeordnet · Produktion (11)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QLK_UEB_PRO_01' AS code, 'planen, gestalten und reflektieren aufgaben- und anlassbezogen komplexe Schreibprozesse' AS kurzname, 'planen, gestalten und reflektieren aufgaben- und anlassbezogen komplexe Schreibprozesse' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_PRO_02' AS code, 'vergleichen verschiedene Schreibformate zur Reorganisation von Vorwissen und Aneignung von Fachwissen' AS kurzname, 'vergleichen verschiedene Schreibformate zur Reorganisation von Vorwissen und Aneignung von Fachwissen' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_PRO_03' AS code, 'formulieren mündlich und schriftlich dem kommunikativen Ziel entsprechend formal sicher, (fach-)sprachlich …' AS kurzname, 'formulieren mündlich und schriftlich dem kommunikativen Ziel entsprechend formal sicher, (fach-)sprachlich differenziert und stilistisch angemessen eigene Texte' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_PRO_04' AS code, 'formulieren argumentativ eigene Positionen zu fachspezifischen Sachverhalten vor dem Hintergrund ihres Fachwissens und …' AS kurzname, 'formulieren argumentativ eigene Positionen zu fachspezifischen Sachverhalten vor dem Hintergrund ihres Fachwissens und theoretischer Bezüge' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_PRO_05' AS code, 'gestalten komplexe monologische und dialogische Beiträge adressatenbezogen und zielgerichtet' AS kurzname, 'gestalten komplexe monologische und dialogische Beiträge adressatenbezogen und zielgerichtet' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_PRO_06' AS code, 'unterscheiden in ihren Texten und medialen Gestaltungen beschreibende, deutende und wertende Aussagen' AS kurzname, 'unterscheiden in ihren Texten und medialen Gestaltungen beschreibende, deutende und wertende Aussagen' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_PRO_07' AS code, 'integrieren Formen der impliziten und expliziten Bezugnahme auf kontinuierliche und diskontinuierliche Texte (Zitate, …' AS kurzname, 'integrieren Formen der impliziten und expliziten Bezugnahme auf kontinuierliche und diskontinuierliche Texte (Zitate, Verweise, Paraphrasen) funktionsgerecht in eigene Texte und mediale Produkte' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_PRO_08' AS code, 'nutzen verbale, paraverbale und nonverbale Mittel zielorientiert und situationsangemessen' AS kurzname, 'nutzen verbale, paraverbale und nonverbale Mittel zielorientiert und situationsangemessen' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_PRO_09' AS code, 'präsentieren mithilfe geeigneter digitaler Werkzeuge selbstständig fachlich komplexe Zusammenhänge unter Beachtung des …' AS kurzname, 'präsentieren mithilfe geeigneter digitaler Werkzeuge selbstständig fachlich komplexe Zusammenhänge unter Beachtung des Urheberrechts' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_PRO_10' AS code, 'überarbeiten eigenständig Texte im Hinblick auf eine normgerechte Verwendung der Sprache (Rechtschreibung, Grammatik …' AS kurzname, 'überarbeiten eigenständig Texte im Hinblick auf eine normgerechte Verwendung der Sprache (Rechtschreibung, Grammatik und Zeichensetzung) und nach weiteren Kriterien, auch unter Verwendung von KI-Werkzeugen' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_UEB_PRO_11' AS code, 'gestalten auch bei einer kritisch-produktiven Verwendung von KI-Werkzeugen Texte eigenständig und verantwortlich.' AS kurzname, 'gestalten auch bei einer kritisch-produktiven Verwendung von KI-Werkzeugen Texte eigenständig und verantwortlich.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QLK_UEB_PRO';

-- Qualifikationsphase (Leistungskurs) · Sprache · Rezeption (7)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QLK_SPR_REZ_01' AS code, 'vergleichen unterschiedliche Theorien zum Verhältnis von Sprache, Denken und Wirklichkeit (Zeichen, Vorstellung und …' AS kurzname, 'vergleichen unterschiedliche Theorien zum Verhältnis von Sprache, Denken und Wirklichkeit (Zeichen, Vorstellung und Gegenstand, Sprachskepsis)' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_SPR_REZ_02' AS code, 'vergleichen Sprachvarietäten in verschiedenen Erscheinungsformen (u. a. Soziolekt, Dialekt, Regionalsprache wie …' AS kurzname, 'vergleichen Sprachvarietäten in verschiedenen Erscheinungsformen (u. a. Soziolekt, Dialekt, Regionalsprache wie Niederdeutsch) und deren gesellschaftliche Bedeutsamkeit, auch unter historischer Perspektive' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_SPR_REZ_03' AS code, 'erklären theoriegestützt Veränderungstendenzen der Gegenwartssprache und ihre Ursachen (Mehrsprachigkeit, Einfluss von …' AS kurzname, 'erklären theoriegestützt Veränderungstendenzen der Gegenwartssprache und ihre Ursachen (Mehrsprachigkeit, Einfluss von Medien, sprachliche Kreativität)' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_SPR_REZ_04' AS code, 'erläutern den Erwerb mehrerer Sprachen sowie Phänomene innerer und äußerer Mehrsprachigkeit und ihre Auswirkungen' AS kurzname, 'erläutern den Erwerb mehrerer Sprachen sowie Phänomene innerer und äußerer Mehrsprachigkeit und ihre Auswirkungen' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_SPR_REZ_05' AS code, 'beurteilen Formen gesteuerten und ungesteuerten Sprachwandels (u. a. gendergerechte Sprache)' AS kurzname, 'beurteilen Formen gesteuerten und ungesteuerten Sprachwandels (u. a. gendergerechte Sprache)' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_SPR_REZ_06' AS code, 'vergleichen die Grundannahmen von unterschiedlichen wissenschaftlichen Ansätzen der Spracherwerbstheorie' AS kurzname, 'vergleichen die Grundannahmen von unterschiedlichen wissenschaftlichen Ansätzen der Spracherwerbstheorie' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_SPR_REZ_07' AS code, 'erläutern sprachlich-stilistische Mittel in schriftlichen und mündlichen Texten im Hinblick auf deren Bedeutung für die …' AS kurzname, 'erläutern sprachlich-stilistische Mittel in schriftlichen und mündlichen Texten im Hinblick auf deren Bedeutung für die Textaussage und Wirkung, auch unter Berücksichtigung des jeweiligen gesellschaftlichen und historischen Kontextes.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QLK_SPR_REZ';

-- Qualifikationsphase (Leistungskurs) · Sprache · Produktion (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QLK_SPR_PRO_01' AS code, 'stellen komplexe Sachverhalte unter Berücksichtigung der Kommunikationssituation, der Adressaten und der Funktion …' AS kurzname, 'stellen komplexe Sachverhalte unter Berücksichtigung der Kommunikationssituation, der Adressaten und der Funktion sprachlich differenziert dar' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_SPR_PRO_02' AS code, 'formulieren mündlich und schriftlich unter Verwendung einer angemessenen Fachterminologie' AS kurzname, 'formulieren mündlich und schriftlich unter Verwendung einer angemessenen Fachterminologie' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_SPR_PRO_03' AS code, 'überarbeiten selbstständig die sprachliche Darstellung in Texten mithilfe von Kriterien (u. a. stilistische …' AS kurzname, 'überarbeiten selbstständig die sprachliche Darstellung in Texten mithilfe von Kriterien (u. a. stilistische Angemessenheit, Verständlichkeit, syntaktische und semantische Variationsbreite).' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QLK_SPR_PRO';

-- Qualifikationsphase (Leistungskurs) · Texte · Rezeption (14)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QLK_TXT_REZ_01' AS code, 'planen und steuern begründet ihren Leseprozess selbstständig unter Berücksichtigung von Leseziel, Aufgabenstellung, …' AS kurzname, 'planen und steuern begründet ihren Leseprozess selbstständig unter Berücksichtigung von Leseziel, Aufgabenstellung, Umfang und Komplexität der Texte' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_REZ_02' AS code, 'interpretieren strukturell unterschiedliche dramatische und erzählende Texte, auch unter Berücksichtigung der …' AS kurzname, 'interpretieren strukturell unterschiedliche dramatische und erzählende Texte, auch unter Berücksichtigung der Entwicklung der gattungstypischen Gestaltungsformen und poetologischer Konzepte' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_REZ_03' AS code, 'interpretieren lyrische Texte im historischen Längsschnitt, auch unter Berücksichtigung der Formen des lyrischen …' AS kurzname, 'interpretieren lyrische Texte im historischen Längsschnitt, auch unter Berücksichtigung der Formen des lyrischen Sprechens und poetologischer Konzepte' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_REZ_04' AS code, 'erschließen synchrone Zusammenhänge aus der Zusammenschau literarischer Texte unter Einbezug weiterer Kontexte (u. a. …' AS kurzname, 'erschließen synchrone Zusammenhänge aus der Zusammenschau literarischer Texte unter Einbezug weiterer Kontexte (u. a. gesellschaftspolitische Hintergründe, poetologische Konzepte, literaturwissenschaftliche Ansätze)' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_REZ_05' AS code, 'ordnen literarische Texte in grundlegende literaturhistorische und historisch-gesellschaftliche Entwicklungen ein (vom …' AS kurzname, 'ordnen literarische Texte in grundlegende literaturhistorische und historisch-gesellschaftliche Entwicklungen ein (vom Barock bis zur Gegenwart)' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_REZ_06' AS code, 'erläutern die Problematik literaturwissenschaftlicher Kategorisierungen (Epochen, Gattungen)' AS kurzname, 'erläutern die Problematik literaturwissenschaftlicher Kategorisierungen (Epochen, Gattungen)' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_REZ_07' AS code, 'vergleichen die Ausgestaltung von Motiven und Themen sowie die Strukturen literarischer Texte' AS kurzname, 'vergleichen die Ausgestaltung von Motiven und Themen sowie die Strukturen literarischer Texte' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_REZ_08' AS code, 'setzen einen literarischen Text zu anderen Texten in Beziehung (u. a. Aussagen von Autorinnen und Autoren, …' AS kurzname, 'setzen einen literarischen Text zu anderen Texten in Beziehung (u. a. Aussagen von Autorinnen und Autoren, literaturwissenschaftliche Texte)' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_REZ_09' AS code, 'vergleichen ihre individuelle Wahrnehmung der ästhetischen Gestaltung literarischer Texte' AS kurzname, 'vergleichen ihre individuelle Wahrnehmung der ästhetischen Gestaltung literarischer Texte' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_REZ_10' AS code, 'erläutern die Mehrdeutigkeit von Texten sowie die Zeitbedingtheit von Rezeption und Interpretation' AS kurzname, 'erläutern die Mehrdeutigkeit von Texten sowie die Zeitbedingtheit von Rezeption und Interpretation' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_REZ_11' AS code, 'erläutern die Problematik der Unterscheidung zwischen fiktionalen und nicht-fiktionalen Texten an Beispielen' AS kurzname, 'erläutern die Problematik der Unterscheidung zwischen fiktionalen und nicht-fiktionalen Texten an Beispielen' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_REZ_12' AS code, 'analysieren komplexe pragmatische Texte (in unterschiedlichen medialen Formaten), auch unter Berücksichtigung der …' AS kurzname, 'analysieren komplexe pragmatische Texte (in unterschiedlichen medialen Formaten), auch unter Berücksichtigung der unterschiedlichen Textfunktionen (Ausdruck, Darstellung, Appell) und des Modus (narrativ, deskriptiv, argumentativ), vor dem Hintergrund ihres jeweiligen gesellschaftlich-historischen Kontextes' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_REZ_13' AS code, 'entnehmen Texten und Materialdossiers zielgerichtet relevante Informationen und Argumente (Identifizieren, Ordnen, …' AS kurzname, 'entnehmen Texten und Materialdossiers zielgerichtet relevante Informationen und Argumente (Identifizieren, Ordnen, Auswählen)' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_REZ_14' AS code, 'setzen komplexe Texte (u. a. in einem Materialdossier) in Beziehung zueinander und leiten unter Berücksichtigung der …' AS kurzname, 'setzen komplexe Texte (u. a. in einem Materialdossier) in Beziehung zueinander und leiten unter Berücksichtigung der Aufgabenstellung selbstständig Teilaspekte eines Themas oder Vergleichsaspekte ab.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QLK_TXT_REZ';

-- Qualifikationsphase (Leistungskurs) · Texte · Produktion (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QLK_TXT_PRO_01' AS code, 'planen und steuern begründet ihren Schreibprozess selbstständig unter Berücksichtigung von Aufgabenstellung und …' AS kurzname, 'planen und steuern begründet ihren Schreibprozess selbstständig unter Berücksichtigung von Aufgabenstellung und Schreibziel' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_PRO_02' AS code, 'entwerfen auf der Grundlage der Textrezeption eigenständig eine inhaltliche Gliederung für ihre eigenen Texte' AS kurzname, 'entwerfen auf der Grundlage der Textrezeption eigenständig eine inhaltliche Gliederung für ihre eigenen Texte' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_PRO_03' AS code, 'formulieren unter Anwendung von Textmustern (typische grammatische Konstruktionen und satzübergreifende Muster der …' AS kurzname, 'formulieren unter Anwendung von Textmustern (typische grammatische Konstruktionen und satzübergreifende Muster der Textorganisation) komplexe Texte sach-, adressaten- und situationsgerecht' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_PRO_04' AS code, 'stellen in ihren Texten die Ergebnisse textimmanenter und textübergreifender Untersuchungsverfahren dar und integrieren …' AS kurzname, 'stellen in ihren Texten die Ergebnisse textimmanenter und textübergreifender Untersuchungsverfahren dar und integrieren sie in eine eigenständige Deutung' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_PRO_05' AS code, 'stellen ihr Textverständnis durch verschiedene Formen produktionsorientierten Schreibens dar' AS kurzname, 'stellen ihr Textverständnis durch verschiedene Formen produktionsorientierten Schreibens dar' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_TXT_PRO_06' AS code, 'interpretieren literarische Texte durch einen gestaltenden Vortrag.' AS kurzname, 'interpretieren literarische Texte durch einen gestaltenden Vortrag.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QLK_TXT_PRO';

-- Qualifikationsphase (Leistungskurs) · Kommunikation · Rezeption (7)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QLK_KOM_REZ_01' AS code, 'analysieren sprachliches Handeln in rhetorisch gestalteter Kommunikation unter Einbezug von Kommunikationsmodellen' AS kurzname, 'analysieren sprachliches Handeln in rhetorisch gestalteter Kommunikation unter Einbezug von Kommunikationsmodellen' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_KOM_REZ_02' AS code, 'deuten in der Analyse rhetorisch gestalteter Kommunikation verbale, nonverbale und paraverbale Aspekte in Beziehung …' AS kurzname, 'deuten in der Analyse rhetorisch gestalteter Kommunikation verbale, nonverbale und paraverbale Aspekte in Beziehung zueinander' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_KOM_REZ_03' AS code, 'untersuchen symmetrische und asymmetrische Kommunikation in Gesprächssituationen und literarischen Texten, auch unter …' AS kurzname, 'untersuchen symmetrische und asymmetrische Kommunikation in Gesprächssituationen und literarischen Texten, auch unter Berücksichtigung gesellschaftlicher Rollen und Positionen sowie Genderaspekten' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_KOM_REZ_04' AS code, 'erläutern Merkmale verständigungsorientierter und manipulativer Kommunikation (u. a. im politischen Kontext)' AS kurzname, 'erläutern Merkmale verständigungsorientierter und manipulativer Kommunikation (u. a. im politischen Kontext)' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_KOM_REZ_05' AS code, 'stellen Möglichkeiten und Grenzen gesellschaftlicher Mitgestaltung in linearer und vernetzter Kommunikation dar' AS kurzname, 'stellen Möglichkeiten und Grenzen gesellschaftlicher Mitgestaltung in linearer und vernetzter Kommunikation dar' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_KOM_REZ_06' AS code, 'erläutern das Verhältnis von Öffentlichkeit und Privatheit in verschiedenen medialen Kontexten' AS kurzname, 'erläutern das Verhältnis von Öffentlichkeit und Privatheit in verschiedenen medialen Kontexten' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_KOM_REZ_07' AS code, 'erläutern die Besonderheiten der Autor-Rezipienten-Kommunikation.' AS kurzname, 'erläutern die Besonderheiten der Autor-Rezipienten-Kommunikation.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QLK_KOM_REZ';

-- Qualifikationsphase (Leistungskurs) · Kommunikation · Produktion (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QLK_KOM_PRO_01' AS code, 'erläutern komplexe Fachinhalte in monologischen Gesprächsformen Verständnis fördernd (u. a. Zuhöreraktivierung, Nutzung …' AS kurzname, 'erläutern komplexe Fachinhalte in monologischen Gesprächsformen Verständnis fördernd (u. a. Zuhöreraktivierung, Nutzung von Visualisierung)' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_KOM_PRO_02' AS code, 'begründen ihre Position in dialogischen Gesprächsformen sach- und adressatengerecht sowie dem kommunikativen Kontext …' AS kurzname, 'begründen ihre Position in dialogischen Gesprächsformen sach- und adressatengerecht sowie dem kommunikativen Kontext angemessen' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_KOM_PRO_03' AS code, 'verfassen Beiträge in digitalen Kontexten im Hinblick auf die Wirkungsabsicht und die potenzielle Reichweite.' AS kurzname, 'verfassen Beiträge in digitalen Kontexten im Hinblick auf die Wirkungsabsicht und die potenzielle Reichweite.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QLK_KOM_PRO';

-- Qualifikationsphase (Leistungskurs) · Medien · Rezeption (8)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QLK_MED_REZ_01' AS code, 'beurteilen die Qualität von Informationen aus verschiedenartigen Quellen (u. a. Grad an Fiktionalität, Seriosität, …' AS kurzname, 'beurteilen die Qualität von Informationen aus verschiedenartigen Quellen (u. a. Grad an Fiktionalität, Seriosität, fachliche Differenziertheit)' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_MED_REZ_02' AS code, 'beurteilen die Möglichkeiten verschiedener digitaler Werkzeuge zur Verarbeitung von Wissen und zum Erkenntnisgewinn' AS kurzname, 'beurteilen die Möglichkeiten verschiedener digitaler Werkzeuge zur Verarbeitung von Wissen und zum Erkenntnisgewinn' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_MED_REZ_03' AS code, 'erläutern differenziert Zusammenhänge zwischen medialem Kontext und der Darbietungsform von Informationen' AS kurzname, 'erläutern differenziert Zusammenhänge zwischen medialem Kontext und der Darbietungsform von Informationen' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_MED_REZ_04' AS code, 'beurteilen Möglichkeiten und Gefahren der politischen Willensbildung und der gesellschaftlichen Einflussnahme in …' AS kurzname, 'beurteilen Möglichkeiten und Gefahren der politischen Willensbildung und der gesellschaftlichen Einflussnahme in verschiedenen medialen Zusammenhängen (u. a. Teilhabe an öffentlichen Diskursen, Verbreitung von Falschmeldungen, Hate Speech)' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_MED_REZ_05' AS code, 'analysieren die narrative Struktur und ästhetische Gestaltung eines Films, auch mit Blick auf ihre Wirkung und …' AS kurzname, 'analysieren die narrative Struktur und ästhetische Gestaltung eines Films, auch mit Blick auf ihre Wirkung und reflektieren diese kritisch' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_MED_REZ_06' AS code, 'erläutern Gestaltungsmöglichkeiten multimodalen Erzählens auf der Figuren- und Handlungsebene und reflektieren diese …' AS kurzname, 'erläutern Gestaltungsmöglichkeiten multimodalen Erzählens auf der Figuren- und Handlungsebene und reflektieren diese kritisch' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_MED_REZ_07' AS code, 'vergleichen ausgewählte Aspekte verschiedener Bühneninszenierungen eines dramatischen Textes in ihrer ästhetischen …' AS kurzname, 'vergleichen ausgewählte Aspekte verschiedener Bühneninszenierungen eines dramatischen Textes in ihrer ästhetischen Gestaltung und Wirkung' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_MED_REZ_08' AS code, 'erläutern zentrale Folgen medialer Umbrüche theoriegestützt (Buchdruck, Fernsehen, Internet).' AS kurzname, 'erläutern zentrale Folgen medialer Umbrüche theoriegestützt (Buchdruck, Fernsehen, Internet).' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QLK_MED_REZ';

-- Qualifikationsphase (Leistungskurs) · Medien · Produktion (3)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_QLK_MED_PRO_01' AS code, 'verfassen und überarbeiten verschiedenartige Texte mithilfe digitaler Werkzeuge, auch in kollaborativen Verfahren' AS kurzname, 'verfassen und überarbeiten verschiedenartige Texte mithilfe digitaler Werkzeuge, auch in kollaborativen Verfahren' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_MED_PRO_02' AS code, 'gestalten Beiträge in verschiedenen medialen Kommunikationssituationen unter Berücksichtigung von Persönlichkeitsrechten' AS kurzname, 'gestalten Beiträge in verschiedenen medialen Kommunikationssituationen unter Berücksichtigung von Persönlichkeitsrechten' AS beschreibung
  UNION ALL
  SELECT 'DE_QLK_MED_PRO_03' AS code, 'gestalten Beiträge in unterschiedlichen medialen Kontexten auch unter ästhetischen Gesichtspunkten situations- und …' AS kurzname, 'gestalten Beiträge in unterschiedlichen medialen Kontexten auch unter ästhetischen Gesichtspunkten situations- und adressatengerecht unter Berücksichtigung von Urheberrechten.' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_QLK_MED_PRO';

COMMIT;

-- Kontrolle: erwartet Knoten=45 (15 Wurzeln + 30 Blaetter), Kompetenzen=197
