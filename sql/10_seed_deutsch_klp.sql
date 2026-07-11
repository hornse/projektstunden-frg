-- =============================================================================
-- Seed 10: Deutsch – Kernlehrplan Gymnasium Sek I (G9), NRW 2019 (Heft 3409)
-- Automatisch generiert aus gen_deutsch_klp.py – wörtliche Kompetenzerwartungen.
-- Voraussetzung: Migration 08 (Spalten phase/inhaltsfeld/kompetenzbereich,
--               eltern_kompetenz_id, schule_id) ist eingespielt.
-- Idempotent: löscht vorhandenen DEU_KLP-Rahmen und baut ihn neu auf.
-- =============================================================================

SET NAMES utf8mb4;
START TRANSACTION;

SET @schule := 1;
SET @fach := (SELECT id FROM faecher WHERE schule_id = @schule AND kuerzel = 'DE' LIMIT 1);

-- Alten (ggf. fehlerhaften) DEU_KLP-Rahmen entfernen (CASCADE räumt Bereiche/Kompetenzen).
DELETE FROM kompetenzrahmen WHERE schule_id = @schule AND kuerzel = 'DEU_KLP';

INSERT INTO kompetenzrahmen (schule_id, name, kuerzel, beschreibung, quelle_url, fach_id)
VALUES (@schule, 'Deutsch KLP NRW G9 Sek I (FRG)', 'DEU_KLP', 'Kernlehrplan Deutsch, Gymnasium Sekundarstufe I (G9), NRW 2019. Kompetenzbereiche Rezeption/Produktion, Inhaltsfelder Sprache/Texte/Kommunikation/Medien, gegliedert nach Erprobungs-, Erster und Zweiter Stufe.', 'https://lehrplannavigator.nrw.de/system/files/media/document/file/g9_d_klp_3409_2019_06_23.pdf', @fach);
SET @rahmen := LAST_INSERT_ID();

-- --------------------------------------------------------------------------
-- Kompetenzbereiche (phase · inhaltsfeld · kompetenzbereich)
-- --------------------------------------------------------------------------
INSERT INTO kompetenzbereiche (rahmen_id, code, name, reihenfolge, phase, inhaltsfeld, kompetenzbereich) VALUES
(@rahmen, 'DE_EP_UEB_REZ', 'Erprobungsstufe · Übergeordnet · Rezeption', 1, 'erprobungsstufe', 'Übergeordnet', 'Rezeption'),
(@rahmen, 'DE_EP_UEB_PRO', 'Erprobungsstufe · Übergeordnet · Produktion', 2, 'erprobungsstufe', 'Übergeordnet', 'Produktion'),
(@rahmen, 'DE_EP_SPR_REZ', 'Erprobungsstufe · Sprache · Rezeption', 3, 'erprobungsstufe', 'Sprache', 'Rezeption'),
(@rahmen, 'DE_EP_SPR_PRO', 'Erprobungsstufe · Sprache · Produktion', 4, 'erprobungsstufe', 'Sprache', 'Produktion'),
(@rahmen, 'DE_EP_TXT_REZ', 'Erprobungsstufe · Texte · Rezeption', 5, 'erprobungsstufe', 'Texte', 'Rezeption'),
(@rahmen, 'DE_EP_TXT_PRO', 'Erprobungsstufe · Texte · Produktion', 6, 'erprobungsstufe', 'Texte', 'Produktion'),
(@rahmen, 'DE_EP_KOM_REZ', 'Erprobungsstufe · Kommunikation · Rezeption', 7, 'erprobungsstufe', 'Kommunikation', 'Rezeption'),
(@rahmen, 'DE_EP_KOM_PRO', 'Erprobungsstufe · Kommunikation · Produktion', 8, 'erprobungsstufe', 'Kommunikation', 'Produktion'),
(@rahmen, 'DE_EP_MED_REZ', 'Erprobungsstufe · Medien · Rezeption', 9, 'erprobungsstufe', 'Medien', 'Rezeption'),
(@rahmen, 'DE_EP_MED_PRO', 'Erprobungsstufe · Medien · Produktion', 10, 'erprobungsstufe', 'Medien', 'Produktion'),
(@rahmen, 'DE_S2_UEB_REZ', 'Zweite Stufe · Übergeordnet · Rezeption', 11, 'zweite_stufe', 'Übergeordnet', 'Rezeption'),
(@rahmen, 'DE_S2_UEB_PRO', 'Zweite Stufe · Übergeordnet · Produktion', 12, 'zweite_stufe', 'Übergeordnet', 'Produktion'),
(@rahmen, 'DE_S1_SPR_REZ', 'Erste Stufe · Sprache · Rezeption', 13, 'erste_stufe', 'Sprache', 'Rezeption'),
(@rahmen, 'DE_S1_SPR_PRO', 'Erste Stufe · Sprache · Produktion', 14, 'erste_stufe', 'Sprache', 'Produktion'),
(@rahmen, 'DE_S1_TXT_REZ', 'Erste Stufe · Texte · Rezeption', 15, 'erste_stufe', 'Texte', 'Rezeption'),
(@rahmen, 'DE_S1_TXT_PRO', 'Erste Stufe · Texte · Produktion', 16, 'erste_stufe', 'Texte', 'Produktion'),
(@rahmen, 'DE_S1_KOM_REZ', 'Erste Stufe · Kommunikation · Rezeption', 17, 'erste_stufe', 'Kommunikation', 'Rezeption'),
(@rahmen, 'DE_S1_KOM_PRO', 'Erste Stufe · Kommunikation · Produktion', 18, 'erste_stufe', 'Kommunikation', 'Produktion'),
(@rahmen, 'DE_S1_MED_REZ', 'Erste Stufe · Medien · Rezeption', 19, 'erste_stufe', 'Medien', 'Rezeption'),
(@rahmen, 'DE_S1_MED_PRO', 'Erste Stufe · Medien · Produktion', 20, 'erste_stufe', 'Medien', 'Produktion'),
(@rahmen, 'DE_S2_SPR_REZ', 'Zweite Stufe · Sprache · Rezeption', 21, 'zweite_stufe', 'Sprache', 'Rezeption'),
(@rahmen, 'DE_S2_SPR_PRO', 'Zweite Stufe · Sprache · Produktion', 22, 'zweite_stufe', 'Sprache', 'Produktion'),
(@rahmen, 'DE_S2_TXT_REZ', 'Zweite Stufe · Texte · Rezeption', 23, 'zweite_stufe', 'Texte', 'Rezeption'),
(@rahmen, 'DE_S2_TXT_PRO', 'Zweite Stufe · Texte · Produktion', 24, 'zweite_stufe', 'Texte', 'Produktion'),
(@rahmen, 'DE_S2_KOM_REZ', 'Zweite Stufe · Kommunikation · Rezeption', 25, 'zweite_stufe', 'Kommunikation', 'Rezeption'),
(@rahmen, 'DE_S2_KOM_PRO', 'Zweite Stufe · Kommunikation · Produktion', 26, 'zweite_stufe', 'Kommunikation', 'Produktion'),
(@rahmen, 'DE_S2_MED_REZ', 'Zweite Stufe · Medien · Rezeption', 27, 'zweite_stufe', 'Medien', 'Rezeption'),
(@rahmen, 'DE_S2_MED_PRO', 'Zweite Stufe · Medien · Produktion', 28, 'zweite_stufe', 'Medien', 'Produktion');

-- --------------------------------------------------------------------------
-- Kompetenzerwartungen (flach: eltern_kompetenz_id = NULL)
-- --------------------------------------------------------------------------
-- Erprobungsstufe · Übergeordnet · Rezeption (8)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EP_UEB_REZ_01' AS code, 'sinnerfassend lesen und zuhören' AS kurzname, 'sinnerfassend lesen und zuhören' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_REZ_02' AS code, 'Lesestrategien zielführend einsetzen' AS kurzname, 'Lesestrategien zielführend einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_REZ_03' AS code, 'Texte mit elementaren analytischen Methoden untersuchen' AS kurzname, 'Texte mit elementaren analytischen Methoden untersuchen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_REZ_04' AS code, 'Gehörtes und Gelesenes zusammenfassen' AS kurzname, 'Gehörtes und Gelesenes zusammenfassen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_REZ_05' AS code, 'schreibproduktive Formen der Texterschließung für vertieftes Leseverstehen einsetzen' AS kurzname, 'schreibproduktive Formen der Texterschließung für vertieftes Leseverstehen einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_REZ_06' AS code, 'sprachliche Strukturen untersuchen' AS kurzname, 'sprachliche Strukturen untersuchen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_REZ_07' AS code, 'in Gesprächssituationen aktiv zuhören und Sprechabsichten identifizieren' AS kurzname, 'in Gesprächssituationen aktiv zuhören und Sprechabsichten identifizieren' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_REZ_08' AS code, 'zu fachlichen Gegenständen persönlich Stellung beziehen' AS kurzname, 'zu fachlichen Gegenständen persönlich Stellung beziehen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EP_UEB_REZ';

-- Erprobungsstufe · Übergeordnet · Produktion (13)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EP_UEB_PRO_01' AS code, 'Texte flüssig vorlesen sowie sprechgestaltende Mittel beim Vortragen verständnisfördernd einsetzen' AS kurzname, 'Texte flüssig vorlesen sowie sprechgestaltende Mittel beim Vortragen verständnisfördernd einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_PRO_02' AS code, 'Texte in handschriftlicher und digitaler Form leserfreundlich aufbereiten' AS kurzname, 'Texte in handschriftlicher und digitaler Form leserfreundlich aufbereiten' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_PRO_03' AS code, 'eigene Texte angeleitet planen und nach vorgegebenen Kriterien überarbeiten' AS kurzname, 'eigene Texte angeleitet planen und nach vorgegebenen Kriterien überarbeiten' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_PRO_04' AS code, 'Arbeitsergebnisse in schriftlicher Form sachgerecht sichern und dokumentieren' AS kurzname, 'Arbeitsergebnisse in schriftlicher Form sachgerecht sichern und dokumentieren' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_PRO_05' AS code, 'die inhaltliche und sprachliche Gestaltung von Texten als Modell für eigenes Schreiben verwenden' AS kurzname, 'die inhaltliche und sprachliche Gestaltung von Texten als Modell für eigenes Schreiben verwenden' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_PRO_06' AS code, 'mündliche und schriftliche Texte funktional gestalten' AS kurzname, 'mündliche und schriftliche Texte funktional gestalten' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_PRO_07' AS code, 'Quellen sinngetreu wiedergeben' AS kurzname, 'Quellen sinngetreu wiedergeben' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_PRO_08' AS code, 'orthografisch und grammatisch normgerecht schreiben' AS kurzname, 'orthografisch und grammatisch normgerecht schreiben' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_PRO_09' AS code, 'mündliche Beiträge artikuliert, verständlich und sprachlich korrekt gestalten' AS kurzname, 'mündliche Beiträge artikuliert, verständlich und sprachlich korrekt gestalten' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_PRO_10' AS code, 'einen zunehmend differenzierten Wortschatz funktional einsetzen' AS kurzname, 'einen zunehmend differenzierten Wortschatz funktional einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_PRO_11' AS code, 'auf Gesprächsbeiträge anderer eingehen und diese weiterführen' AS kurzname, 'auf Gesprächsbeiträge anderer eingehen und diese weiterführen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_PRO_12' AS code, 'eigene Urteile in mündlicher und schriftlicher Form sachbezogen begründen' AS kurzname, 'eigene Urteile in mündlicher und schriftlicher Form sachbezogen begründen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_UEB_PRO_13' AS code, 'Feedback geben und annehmen' AS kurzname, 'Feedback geben und annehmen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EP_UEB_PRO';

-- Erprobungsstufe · Sprache · Rezeption (10)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EP_SPR_REZ_01' AS code, 'Wortarten (Verb, Nomen, Artikel, Pronomen, Adjektiv, Konjunktion, Adverb) unterscheiden' AS kurzname, 'Wortarten (Verb, Nomen, Artikel, Pronomen, Adjektiv, Konjunktion, Adverb) unterscheiden' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_SPR_REZ_02' AS code, 'unterschiedliche Flexionsformen (Konjugation – Tempus, Deklination – Genus, Numerus, Kasus; Komparation) unterscheiden' AS kurzname, 'unterschiedliche Flexionsformen (Konjugation – Tempus, Deklination – Genus, Numerus, Kasus; Komparation) unterscheiden' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_SPR_REZ_03' AS code, 'Verfahren der Wortbildung unterscheiden (Komposition, Derivation)' AS kurzname, 'Verfahren der Wortbildung unterscheiden (Komposition, Derivation)' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_SPR_REZ_04' AS code, 'grundlegende Strukturen von Sätzen (Prädikat; Satzglieder: Subjekt, Objekt, Adverbial; Satzgliedteil: Attribut; …' AS kurzname, 'grundlegende Strukturen von Sätzen (Prädikat; Satzglieder: Subjekt, Objekt, Adverbial; Satzgliedteil: Attribut; Satzarten: Aussage-, Frage-, Aufforderungssatz; zusammengesetzte Sätze: Satzreihe, Satzgefüge, Hauptsatz, Nebensatz) untersuchen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_SPR_REZ_05' AS code, 'Sprachstrukturen mithilfe von Ersatz-, Umstell-, Erweiterungs- und Weglassprobe untersuchen' AS kurzname, 'Sprachstrukturen mithilfe von Ersatz-, Umstell-, Erweiterungs- und Weglassprobe untersuchen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_SPR_REZ_06' AS code, 'einfache sprachliche Mittel (Metapher, Personifikation, Vergleich, klangliche Gestaltungsmittel) in ihrer Wirkung …' AS kurzname, 'einfache sprachliche Mittel (Metapher, Personifikation, Vergleich, klangliche Gestaltungsmittel) in ihrer Wirkung beschreiben' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_SPR_REZ_07' AS code, 'Wortbedeutungen aus dem Kontext erschließen und unter Zuhilfenahme von digitalen sowie analogen Wörterbüchern klären' AS kurzname, 'Wortbedeutungen aus dem Kontext erschließen und unter Zuhilfenahme von digitalen sowie analogen Wörterbüchern klären' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_SPR_REZ_08' AS code, 'an einfachen Beispielen Alltagssprache und Bildungssprache unterscheiden' AS kurzname, 'an einfachen Beispielen Alltagssprache und Bildungssprache unterscheiden' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_SPR_REZ_09' AS code, 'an einfachen Beispielen Abweichungen von der Standardsprache beschreiben' AS kurzname, 'an einfachen Beispielen Abweichungen von der Standardsprache beschreiben' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_SPR_REZ_10' AS code, 'angeleitet Gemeinsamkeiten und Unterschiede (Satzstrukturen, Wörter und Wortgebrauch) verschiedener Sprachen (der …' AS kurzname, 'angeleitet Gemeinsamkeiten und Unterschiede (Satzstrukturen, Wörter und Wortgebrauch) verschiedener Sprachen (der Lerngruppe) untersuchen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EP_SPR_REZ';

-- Erprobungsstufe · Sprache · Produktion (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EP_SPR_PRO_01' AS code, 'Wörter in Wortfeldern und -familien einordnen und gemäß ihren Bedeutungen einsetzen' AS kurzname, 'Wörter in Wortfeldern und -familien einordnen und gemäß ihren Bedeutungen einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_SPR_PRO_02' AS code, 'relevantes sprachliches Wissen (u.a. auf Wort- und Satzebene) beim Verfassen eigener Texte einsetzen' AS kurzname, 'relevantes sprachliches Wissen (u.a. auf Wort- und Satzebene) beim Verfassen eigener Texte einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_SPR_PRO_03' AS code, 'mittels geeigneter Rechtschreibstrategien (auf Laut-Buchstaben-Ebene, Wortebene, Satzebene) und unter Rückgriff auf …' AS kurzname, 'mittels geeigneter Rechtschreibstrategien (auf Laut-Buchstaben-Ebene, Wortebene, Satzebene) und unter Rückgriff auf grammatisches Wissen Texte angeleitet überprüfen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_SPR_PRO_04' AS code, 'eine normgerechte Zeichensetzung für einfache Satzstrukturen (Haupt- und Nebensatzverknüpfung, Apposition, Aufzählung, …' AS kurzname, 'eine normgerechte Zeichensetzung für einfache Satzstrukturen (Haupt- und Nebensatzverknüpfung, Apposition, Aufzählung, wörtliche Rede) realisieren' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_SPR_PRO_05' AS code, 'im Hinblick auf Orthografie, Grammatik und Kohärenz Texte angeleitet überarbeiten' AS kurzname, 'im Hinblick auf Orthografie, Grammatik und Kohärenz Texte angeleitet überarbeiten' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_SPR_PRO_06' AS code, 'angeleitet zu Fehlerschwerpunkten passende Rechtschreibstrategien (u.a. silbierendes Sprechen, Verlängern, Ableiten, …' AS kurzname, 'angeleitet zu Fehlerschwerpunkten passende Rechtschreibstrategien (u.a. silbierendes Sprechen, Verlängern, Ableiten, Wörter zerlegen, Nachschlagen, Ausnahmeschreibung merken) zur Textüberarbeitung einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EP_SPR_PRO';

-- Erprobungsstufe · Texte · Rezeption (10)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EP_TXT_REZ_01' AS code, 'angeleitet zentrale Aussagen mündlicher und schriftlicher Texte identifizieren und daran ihr Gesamtverständnis des …' AS kurzname, 'angeleitet zentrale Aussagen mündlicher und schriftlicher Texte identifizieren und daran ihr Gesamtverständnis des Textes erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_TXT_REZ_02' AS code, 'in literarischen Texten Figuren untersuchen und Figurenbeziehungen textbezogen erläutern' AS kurzname, 'in literarischen Texten Figuren untersuchen und Figurenbeziehungen textbezogen erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_TXT_REZ_03' AS code, 'erzählende Texte unter Berücksichtigung grundlegender Dimensionen der Handlung (Ort, Zeit, Konflikt, Handlungsschritte) …' AS kurzname, 'erzählende Texte unter Berücksichtigung grundlegender Dimensionen der Handlung (Ort, Zeit, Konflikt, Handlungsschritte) und der erzählerischen Vermittlung (u.a. Erzählerfigur) untersuchen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_TXT_REZ_04' AS code, 'lyrische Texte untersuchen – auch unter Berücksichtigung formaler und sprachlicher Gestaltungsmittel (Reim, Metrum, …' AS kurzname, 'lyrische Texte untersuchen – auch unter Berücksichtigung formaler und sprachlicher Gestaltungsmittel (Reim, Metrum, Klang, strophische Gliederung; einfache Formen der Bildlichkeit)' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_TXT_REZ_05' AS code, 'dialogische Texte im Hinblick auf explizit dargestellte Absichten und Verhaltensweisen von Figuren sowie einfache …' AS kurzname, 'dialogische Texte im Hinblick auf explizit dargestellte Absichten und Verhaltensweisen von Figuren sowie einfache Dialogverläufe untersuchen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_TXT_REZ_06' AS code, 'eine persönliche Stellungnahme zu den Ereignissen und zum Verhalten von literarischen Figuren textgebunden formulieren' AS kurzname, 'eine persönliche Stellungnahme zu den Ereignissen und zum Verhalten von literarischen Figuren textgebunden formulieren' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_TXT_REZ_07' AS code, 'eigene Texte zu literarischen Texten verfassen (u.a. Ausgestaltung, Fortsetzung, Paralleltexte) und im Hinblick auf den …' AS kurzname, 'eigene Texte zu literarischen Texten verfassen (u.a. Ausgestaltung, Fortsetzung, Paralleltexte) und im Hinblick auf den Ausgangstext erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_TXT_REZ_08' AS code, 'grundlegende Textfunktionen innerhalb von Sachtexten (appellieren, argumentieren, berichten, beschreiben, erklären) …' AS kurzname, 'grundlegende Textfunktionen innerhalb von Sachtexten (appellieren, argumentieren, berichten, beschreiben, erklären) unterscheiden' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_TXT_REZ_09' AS code, 'in einfachen diskontinuierlichen und kontinuierlichen Sachtexten – auch in digitaler Form – Aufbau und Funktion …' AS kurzname, 'in einfachen diskontinuierlichen und kontinuierlichen Sachtexten – auch in digitaler Form – Aufbau und Funktion beschreiben' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_TXT_REZ_10' AS code, 'Informationen aus Sachtexten aufeinander beziehen und miteinander vergleichen' AS kurzname, 'Informationen aus Sachtexten aufeinander beziehen und miteinander vergleichen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EP_TXT_REZ';

-- Erprobungsstufe · Texte · Produktion (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EP_TXT_PRO_01' AS code, 'ein Schreibziel benennen und mittels geeigneter Hilfen zur Planung und Formulierung (u.a. typische grammatische …' AS kurzname, 'ein Schreibziel benennen und mittels geeigneter Hilfen zur Planung und Formulierung (u.a. typische grammatische Konstruktionen, lexikalische Wendungen, satzübergreifende Muster der Textorganisation, Modelltexte) eigene Texte planen, verfassen und überarbeiten' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_TXT_PRO_02' AS code, 'Geschichten in mündlicher und schriftlicher Form frei oder an Vorgaben orientiert unter Nutzung von Gestaltungsmitteln …' AS kurzname, 'Geschichten in mündlicher und schriftlicher Form frei oder an Vorgaben orientiert unter Nutzung von Gestaltungsmitteln (u.a. Steigerung, Vorausdeutungen, Pointierung) erzählen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_TXT_PRO_03' AS code, 'angeleitet mögliche Erwartungen und Interessen einer Adressatin bzw. eines Adressaten einschätzen und im Zielprodukt …' AS kurzname, 'angeleitet mögliche Erwartungen und Interessen einer Adressatin bzw. eines Adressaten einschätzen und im Zielprodukt berücksichtigen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_TXT_PRO_04' AS code, 'ihr eigenes Urteil über einen Text begründen und in kommunikativen Zusammenhängen (Buchkritik, Leseempfehlung) erläutern' AS kurzname, 'ihr eigenes Urteil über einen Text begründen und in kommunikativen Zusammenhängen (Buchkritik, Leseempfehlung) erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_TXT_PRO_05' AS code, 'Sachtexte – auch in digitaler Form – zur Erweiterung der eigenen Wissensbestände, für den Austausch mit anderen und für …' AS kurzname, 'Sachtexte – auch in digitaler Form – zur Erweiterung der eigenen Wissensbestände, für den Austausch mit anderen und für das Verfassen eigener Texte gezielt einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_TXT_PRO_06' AS code, 'beim Verfassen eines eigenen Textes verschiedene Textfunktionen (appellieren, argumentieren, berichten, beschreiben, …' AS kurzname, 'beim Verfassen eines eigenen Textes verschiedene Textfunktionen (appellieren, argumentieren, berichten, beschreiben, erklären, informieren) unterscheiden und situationsangemessen einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EP_TXT_PRO';

-- Erprobungsstufe · Kommunikation · Rezeption (7)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EP_KOM_REZ_01' AS code, 'gelingende und misslingende Kommunikation in Gesprächen unterscheiden' AS kurzname, 'gelingende und misslingende Kommunikation in Gesprächen unterscheiden' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_KOM_REZ_02' AS code, 'in Gesprächen Absichten und Interessen anderer Gesprächsteilnehmender identifizieren' AS kurzname, 'in Gesprächen Absichten und Interessen anderer Gesprächsteilnehmender identifizieren' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_KOM_REZ_03' AS code, 'Gesprächsregeln mit dem Ziel einer funktionalen Gesprächsführung entwickeln' AS kurzname, 'Gesprächsregeln mit dem Ziel einer funktionalen Gesprächsführung entwickeln' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_KOM_REZ_04' AS code, 'Verletzungen von Gesprächsregeln identifizieren und einen Lösungsansatz entwickeln' AS kurzname, 'Verletzungen von Gesprächsregeln identifizieren und einen Lösungsansatz entwickeln' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_KOM_REZ_05' AS code, 'die Wirkung ihres kommunikativen Handelns – auch in digitaler Kommunikation – abschätzen und Konsequenzen reflektieren' AS kurzname, 'die Wirkung ihres kommunikativen Handelns – auch in digitaler Kommunikation – abschätzen und Konsequenzen reflektieren' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_KOM_REZ_06' AS code, 'Merkmale aktiven Zuhörens nennen' AS kurzname, 'Merkmale aktiven Zuhörens nennen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_KOM_REZ_07' AS code, 'aktiv zuhören, gezielt nachfragen und Gehörtes zutreffend wiedergeben – auch unter Nutzung eigener Notizen' AS kurzname, 'aktiv zuhören, gezielt nachfragen und Gehörtes zutreffend wiedergeben – auch unter Nutzung eigener Notizen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EP_KOM_REZ';

-- Erprobungsstufe · Kommunikation · Produktion (7)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EP_KOM_PRO_01' AS code, 'artikuliert sprechen und Tempo, Lautstärke und Sprechweise situationsangemessen einsetzen' AS kurzname, 'artikuliert sprechen und Tempo, Lautstärke und Sprechweise situationsangemessen einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_KOM_PRO_02' AS code, 'das eigene Kommunikationsverhalten nach Kommunikationskonventionen ausrichten' AS kurzname, 'das eigene Kommunikationsverhalten nach Kommunikationskonventionen ausrichten' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_KOM_PRO_03' AS code, 'Merkmale gesprochener und geschriebener Sprache unterscheiden und situationsangemessen einsetzen' AS kurzname, 'Merkmale gesprochener und geschriebener Sprache unterscheiden und situationsangemessen einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_KOM_PRO_04' AS code, 'Anliegen angemessen vortragen und begründen' AS kurzname, 'Anliegen angemessen vortragen und begründen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_KOM_PRO_05' AS code, 'eigene Beobachtungen und Erfahrungen anderen gegenüber sprachlich angemessen und verständlich darstellen' AS kurzname, 'eigene Beobachtungen und Erfahrungen anderen gegenüber sprachlich angemessen und verständlich darstellen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_KOM_PRO_06' AS code, 'zu strittigen Fragen aus dem eigenen Erfahrungsbereich eigene Standpunkte begründen und in Kommunikationssituationen …' AS kurzname, 'zu strittigen Fragen aus dem eigenen Erfahrungsbereich eigene Standpunkte begründen und in Kommunikationssituationen lösungsorientiert vertreten' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_KOM_PRO_07' AS code, 'nonverbale Mittel (u.a. Gestik, Mimik, Körperhaltung) und paraverbale Mittel (u.a. Intonation) unterscheiden und …' AS kurzname, 'nonverbale Mittel (u.a. Gestik, Mimik, Körperhaltung) und paraverbale Mittel (u.a. Intonation) unterscheiden und situationsangemessen einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EP_KOM_PRO';

-- Erprobungsstufe · Medien · Rezeption (7)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EP_MED_REZ_01' AS code, 'dem Leseziel und dem Medium angepasste einfache Lesestrategien des orientierenden, selektiven, intensiven und …' AS kurzname, 'dem Leseziel und dem Medium angepasste einfache Lesestrategien des orientierenden, selektiven, intensiven und vergleichenden Lesens einsetzen (u.a. bei Hypertexten) und die Lektüreergebnisse darstellen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_MED_REZ_02' AS code, 'Medien bezüglich ihrer Präsentationsform (Printmedien, Hörmedien, audiovisuelle Medien: Websites, interaktive Medien) …' AS kurzname, 'Medien bezüglich ihrer Präsentationsform (Printmedien, Hörmedien, audiovisuelle Medien: Websites, interaktive Medien) und ihrer Funktion beschreiben (informative, kommunikative, unterhaltende Schwerpunkte)' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_MED_REZ_03' AS code, 'Informationen und Daten aus Printmedien und digitalen Medien gezielt auswerten' AS kurzname, 'Informationen und Daten aus Printmedien und digitalen Medien gezielt auswerten' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_MED_REZ_04' AS code, 'Internet-Kommunikation als potenziell öffentliche Kommunikation identifizieren und grundlegende Konsequenzen für sich …' AS kurzname, 'Internet-Kommunikation als potenziell öffentliche Kommunikation identifizieren und grundlegende Konsequenzen für sich und andere einschätzen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_MED_REZ_05' AS code, 'in literalen und audiovisuellen Texten Merkmale virtueller Welten identifizieren' AS kurzname, 'in literalen und audiovisuellen Texten Merkmale virtueller Welten identifizieren' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_MED_REZ_06' AS code, 'einfache Gestaltungsmittel in Präsentationsformen verschiedener literarischer Texte benennen und deren Wirkung …' AS kurzname, 'einfache Gestaltungsmittel in Präsentationsformen verschiedener literarischer Texte benennen und deren Wirkung beschreiben (u.a. Hörfassungen, Graphic Novels)' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_MED_REZ_07' AS code, 'angeleitet die Qualität verschiedener altersgemäßer Quellen prüfen und bewerten (Autor/in, Ausgewogenheit, …' AS kurzname, 'angeleitet die Qualität verschiedener altersgemäßer Quellen prüfen und bewerten (Autor/in, Ausgewogenheit, Informationsgehalt, Belege)' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EP_MED_REZ';

-- Erprobungsstufe · Medien · Produktion (8)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_EP_MED_PRO_01' AS code, 'grundlegende Recherchestrategien in Printmedien und digitalen Medien (u.a. Suchmaschinen für Kinder) funktional …' AS kurzname, 'grundlegende Recherchestrategien in Printmedien und digitalen Medien (u.a. Suchmaschinen für Kinder) funktional einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_MED_PRO_02' AS code, 'Regeln für die digitale Kommunikation nennen und die Einhaltung beurteilen' AS kurzname, 'Regeln für die digitale Kommunikation nennen und die Einhaltung beurteilen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_MED_PRO_03' AS code, 'in digitaler und nicht-digitaler Kommunikation Elemente konzeptioneller Mündlichkeit bzw. Schriftlichkeit …' AS kurzname, 'in digitaler und nicht-digitaler Kommunikation Elemente konzeptioneller Mündlichkeit bzw. Schriftlichkeit identifizieren, die Wirkungen vergleichen und in eigenen Produkten (persönlicher Brief, digitale Nachricht) adressatenangemessen verwenden' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_MED_PRO_04' AS code, 'digitale und nicht-digitale Medien zur Organisation von Lernprozessen und zur Dokumentation von Arbeitsergebnissen …' AS kurzname, 'digitale und nicht-digitale Medien zur Organisation von Lernprozessen und zur Dokumentation von Arbeitsergebnissen einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_MED_PRO_05' AS code, 'Texte medial umformen (Vertonung/Verfilmung bzw. szenisches Spiel) und verwendete Gestaltungsmittel beschreiben' AS kurzname, 'Texte medial umformen (Vertonung/Verfilmung bzw. szenisches Spiel) und verwendete Gestaltungsmittel beschreiben' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_MED_PRO_06' AS code, 'Inhalt und Gestaltung von Medienprodukten angeleitet beschreiben' AS kurzname, 'Inhalt und Gestaltung von Medienprodukten angeleitet beschreiben' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_MED_PRO_07' AS code, 'grundlegende Funktionen der Textverarbeitung unterscheiden und einsetzen' AS kurzname, 'grundlegende Funktionen der Textverarbeitung unterscheiden und einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_EP_MED_PRO_08' AS code, 'Möglichkeiten und Grenzen digitaler Unterstützungsmöglichkeiten bei der Textproduktion beurteilen …' AS kurzname, 'Möglichkeiten und Grenzen digitaler Unterstützungsmöglichkeiten bei der Textproduktion beurteilen (Rechtschreibprogramme, Thesaurus)' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_EP_MED_PRO';

-- Zweite Stufe · Übergeordnet · Rezeption (8)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S2_UEB_REZ_01' AS code, 'verschiedene Lesestrategien sowie Techniken der Informationsrecherche funktional einsetzen' AS kurzname, 'verschiedene Lesestrategien sowie Techniken der Informationsrecherche funktional einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_REZ_02' AS code, 'Verfahren der Textuntersuchung zielgerichtet einsetzen' AS kurzname, 'Verfahren der Textuntersuchung zielgerichtet einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_REZ_03' AS code, 'schriftliche und mündliche Texte zusammenfassen' AS kurzname, 'schriftliche und mündliche Texte zusammenfassen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_REZ_04' AS code, 'schreibproduktive Formen der Texterschließung für vertieftes Leseverstehen einsetzen' AS kurzname, 'schreibproduktive Formen der Texterschließung für vertieftes Leseverstehen einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_REZ_05' AS code, 'sprachliche Darstellungsstrategien in Texten untersuchen' AS kurzname, 'sprachliche Darstellungsstrategien in Texten untersuchen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_REZ_06' AS code, 'in Gesprächssituationen aktiv zuhören und Sprechabsichten identifizieren' AS kurzname, 'in Gesprächssituationen aktiv zuhören und Sprechabsichten identifizieren' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_REZ_07' AS code, 'Printmedien und digitale Medien gezielt auswerten und die Informationen aus verschiedenen Quellen bezüglich ihrer …' AS kurzname, 'Printmedien und digitale Medien gezielt auswerten und die Informationen aus verschiedenen Quellen bezüglich ihrer Qualität und Relevanz bewerten' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_REZ_08' AS code, 'fachliche Gegenstände aus persönlicher und gesellschaftlicher Perspektive beurteilen' AS kurzname, 'fachliche Gegenstände aus persönlicher und gesellschaftlicher Perspektive beurteilen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S2_UEB_REZ';

-- Zweite Stufe · Übergeordnet · Produktion (13)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S2_UEB_PRO_01' AS code, 'Verfahren zur Planung, Gestaltung und Überarbeitung eigener Texte unterscheiden und einsetzen' AS kurzname, 'Verfahren zur Planung, Gestaltung und Überarbeitung eigener Texte unterscheiden und einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_PRO_02' AS code, 'die Möglichkeiten digitaler Textverarbeitung in Schreibprozessen zielgerichtet einsetzen' AS kurzname, 'die Möglichkeiten digitaler Textverarbeitung in Schreibprozessen zielgerichtet einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_PRO_03' AS code, 'Gehörtes und Gelesenes zusammenfassen und sachgerecht dokumentieren' AS kurzname, 'Gehörtes und Gelesenes zusammenfassen und sachgerecht dokumentieren' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_PRO_04' AS code, 'die inhaltliche und sprachliche Gestaltung von Texten als Modell für eigenes Schreiben verwenden' AS kurzname, 'die inhaltliche und sprachliche Gestaltung von Texten als Modell für eigenes Schreiben verwenden' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_PRO_05' AS code, 'schriftliche sowie mündliche Texte adressatengerecht und funktional gestalten' AS kurzname, 'schriftliche sowie mündliche Texte adressatengerecht und funktional gestalten' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_PRO_06' AS code, 'Texte orthografisch sowie grammatisch korrekt und stilistisch angemessen verfassen' AS kurzname, 'Texte orthografisch sowie grammatisch korrekt und stilistisch angemessen verfassen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_PRO_07' AS code, 'Quellen sinngetreu wiedergeben und korrekt zitieren' AS kurzname, 'Quellen sinngetreu wiedergeben und korrekt zitieren' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_PRO_08' AS code, 'fachbezogene Sachverhalte schriftlich und mündlich mit einer zunehmend differenzierten Fachsprache erläutern' AS kurzname, 'fachbezogene Sachverhalte schriftlich und mündlich mit einer zunehmend differenzierten Fachsprache erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_PRO_09' AS code, 'eigene Positionen schriftlich sowie mündlich adressaten- und situationsangemessen begründen' AS kurzname, 'eigene Positionen schriftlich sowie mündlich adressaten- und situationsangemessen begründen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_PRO_10' AS code, 'sich in eigenen Gesprächsbeiträgen auf andere beziehen' AS kurzname, 'sich in eigenen Gesprächsbeiträgen auf andere beziehen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_PRO_11' AS code, 'kommunikative Anforderungen verschiedener Gesprächssituationen identifizieren und eigene Beiträge situationsgerecht …' AS kurzname, 'kommunikative Anforderungen verschiedener Gesprächssituationen identifizieren und eigene Beiträge situationsgerecht gestalten' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_PRO_12' AS code, 'Präsentationsmedien funktional einsetzen' AS kurzname, 'Präsentationsmedien funktional einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_UEB_PRO_13' AS code, 'Feedback an Kriterien ausrichten und konstruktiv gestalten' AS kurzname, 'Feedback an Kriterien ausrichten und konstruktiv gestalten' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S2_UEB_PRO';

-- Erste Stufe · Sprache · Rezeption (9)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S1_SPR_REZ_01' AS code, 'Wortarten (Verb, Nomen, Artikel, Pronomen, Adjektiv, Konjunktion, Adverb, Präposition, Interjektion) unterscheiden' AS kurzname, 'Wortarten (Verb, Nomen, Artikel, Pronomen, Adjektiv, Konjunktion, Adverb, Präposition, Interjektion) unterscheiden' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_SPR_REZ_02' AS code, 'unterschiedliche Formen der Verbflexion unterscheiden und deren funktionalen Wert beschreiben (Aktiv / Passiv, Modi, …' AS kurzname, 'unterschiedliche Formen der Verbflexion unterscheiden und deren funktionalen Wert beschreiben (Aktiv / Passiv, Modi, stilistische Varianten)' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_SPR_REZ_03' AS code, 'Verfahren der Wortbildungen unterscheiden (Komposition, Derivation, Lehnwörter, Fremdwörter)' AS kurzname, 'Verfahren der Wortbildungen unterscheiden (Komposition, Derivation, Lehnwörter, Fremdwörter)' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_SPR_REZ_04' AS code, 'komplexe Strukturen von Sätzen (Nebensatz mit Satzgliedwert: Subjektsatz, Objektsatz, Adverbialsatz; Gliedsatz: …' AS kurzname, 'komplexe Strukturen von Sätzen (Nebensatz mit Satzgliedwert: Subjektsatz, Objektsatz, Adverbialsatz; Gliedsatz: Attributsatz; verschiedene Formen zusammengesetzter Sätze: Infinitivgruppe, uneingeleiteter Nebensatz) untersuchen und Wirkungen von Satzbau-Varianten beschreiben' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_SPR_REZ_05' AS code, 'sprachliche Gestaltungsmittel unterscheiden (u.a. Kohäsionsmittel) und ihre Wirkung erklären (u.a. sprachliche Signale …' AS kurzname, 'sprachliche Gestaltungsmittel unterscheiden (u.a. Kohäsionsmittel) und ihre Wirkung erklären (u.a. sprachliche Signale der Rezipientensteuerung)' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_SPR_REZ_06' AS code, 'Sprachvarietäten unterscheiden sowie Funktionen und Wirkung erläutern (Alltagssprache, Standardsprache, …' AS kurzname, 'Sprachvarietäten unterscheiden sowie Funktionen und Wirkung erläutern (Alltagssprache, Standardsprache, Bildungssprache, Jugendsprache, Sprache in Medien)' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_SPR_REZ_07' AS code, 'an Beispielen sprachliche Abweichungen von der Standardsprache erläutern' AS kurzname, 'an Beispielen sprachliche Abweichungen von der Standardsprache erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_SPR_REZ_08' AS code, 'anhand einfacher Beispiele Gemeinsamkeiten und Unterschiede verschiedener Sprachen (der Lerngruppe) im Hinblick auf …' AS kurzname, 'anhand einfacher Beispiele Gemeinsamkeiten und Unterschiede verschiedener Sprachen (der Lerngruppe) im Hinblick auf grammatische Strukturen und Semantik untersuchen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_SPR_REZ_09' AS code, 'die gesellschaftliche Bedeutung von Sprache beschreiben' AS kurzname, 'die gesellschaftliche Bedeutung von Sprache beschreiben' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S1_SPR_REZ';

-- Erste Stufe · Sprache · Produktion (5)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S1_SPR_PRO_01' AS code, 'Synonyme, Antonyme, Homonyme und Polyseme in semantisch-funktionalen Zusammenhängen einsetzen' AS kurzname, 'Synonyme, Antonyme, Homonyme und Polyseme in semantisch-funktionalen Zusammenhängen einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_SPR_PRO_02' AS code, 'relevantes sprachliches Wissen (u.a. semantische Beziehungen, direkte und indirekte Rede, Aktiv/Passiv, Mittel zur …' AS kurzname, 'relevantes sprachliches Wissen (u.a. semantische Beziehungen, direkte und indirekte Rede, Aktiv/Passiv, Mittel zur Textstrukturierung) für das Schreiben eigener Texte einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_SPR_PRO_03' AS code, 'geeignete Rechtschreibstrategien unterscheiden und orthografische Korrektheit (auf Laut-Buchstaben-Ebene, Wortebene, …' AS kurzname, 'geeignete Rechtschreibstrategien unterscheiden und orthografische Korrektheit (auf Laut-Buchstaben-Ebene, Wortebene, Satzebene) weitgehend selbstständig überprüfen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_SPR_PRO_04' AS code, 'Satzstrukturen unterscheiden und die Zeichensetzung normgerecht einsetzen (Satzreihe, Satzgefüge, Parenthesen, …' AS kurzname, 'Satzstrukturen unterscheiden und die Zeichensetzung normgerecht einsetzen (Satzreihe, Satzgefüge, Parenthesen, Infinitiv- und Partizipialgruppen)' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_SPR_PRO_05' AS code, 'eigene und fremde Texte anhand von vorgegebenen Kriterien überarbeiten (u.a. Textkohärenz)' AS kurzname, 'eigene und fremde Texte anhand von vorgegebenen Kriterien überarbeiten (u.a. Textkohärenz)' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S1_SPR_PRO';

-- Erste Stufe · Texte · Rezeption (13)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S1_TXT_REZ_01' AS code, 'zentrale Aussagen mündlicher und schriftlicher Texte identifizieren und daran ein kohärentes Textverständnis erläutern' AS kurzname, 'zentrale Aussagen mündlicher und schriftlicher Texte identifizieren und daran ein kohärentes Textverständnis erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_REZ_02' AS code, 'Texte im Hinblick auf das Verhältnis von Inhalt, Form und Wirkung erläutern' AS kurzname, 'Texte im Hinblick auf das Verhältnis von Inhalt, Form und Wirkung erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_REZ_03' AS code, 'Merkmale epischer, lyrischer und dramatischer Gestaltungsweisen unterscheiden und erläutern' AS kurzname, 'Merkmale epischer, lyrischer und dramatischer Gestaltungsweisen unterscheiden und erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_REZ_04' AS code, 'in literarischen Texten zentrale Figurenbeziehungen und -merkmale sowie Handlungsverläufe beschreiben und unter …' AS kurzname, 'in literarischen Texten zentrale Figurenbeziehungen und -merkmale sowie Handlungsverläufe beschreiben und unter Berücksichtigung gattungsspezifischer Darstellungsmittel (u.a. erzählerisch und dramatisch vermittelte Darstellung, Erzähltechniken der Perspektivierung) textbezogen erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_REZ_05' AS code, 'bildliche Gestaltungsmittel in literarischen Texten (u.a. lyrische und epische Texte) unterscheiden sowie ihre Funktion …' AS kurzname, 'bildliche Gestaltungsmittel in literarischen Texten (u.a. lyrische und epische Texte) unterscheiden sowie ihre Funktion im Hinblick auf Textaussage und Wirkung erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_REZ_06' AS code, 'literarische Texte (u.a. Gedichte, Kurzgeschichten) unter vorgegebenen Aspekten miteinander vergleichen' AS kurzname, 'literarische Texte (u.a. Gedichte, Kurzgeschichten) unter vorgegebenen Aspekten miteinander vergleichen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_REZ_07' AS code, 'eine persönliche Stellungnahme zur Handlung und zum Verhalten literarischer Figuren textgebunden formulieren' AS kurzname, 'eine persönliche Stellungnahme zur Handlung und zum Verhalten literarischer Figuren textgebunden formulieren' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_REZ_08' AS code, 'ihre eigene Leseart eines literarischen Textes begründen und mit Lesarten anderer vergleichen' AS kurzname, 'ihre eigene Leseart eines literarischen Textes begründen und mit Lesarten anderer vergleichen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_REZ_09' AS code, 'eigene Texte zu literarischen Texten verfassen (u.a. Leerstellen füllen, Paralleltexte konzipieren) und deren Beitrag …' AS kurzname, 'eigene Texte zu literarischen Texten verfassen (u.a. Leerstellen füllen, Paralleltexte konzipieren) und deren Beitrag zur Deutung des Ausgangstextes erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_REZ_10' AS code, 'den Aufbau kontinuierlicher und diskontinuierlicher Sachtexte erläutern' AS kurzname, 'den Aufbau kontinuierlicher und diskontinuierlicher Sachtexte erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_REZ_11' AS code, 'Sachtexte zur Erweiterung der eigenen Wissensbestände und zur Problemlösung auswerten' AS kurzname, 'Sachtexte zur Erweiterung der eigenen Wissensbestände und zur Problemlösung auswerten' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_REZ_12' AS code, 'in Sachtexten (u.a. journalistische Textformen) verschiedene Textfunktionen (appellieren, argumentieren, berichten, …' AS kurzname, 'in Sachtexten (u.a. journalistische Textformen) verschiedene Textfunktionen (appellieren, argumentieren, berichten, beschreiben, erklären, informieren) unterscheiden und in ihrem Zusammenwirken erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_REZ_13' AS code, 'Sachtexte – auch in digitaler Form – unter vorgegebenen Aspekten vergleichen' AS kurzname, 'Sachtexte – auch in digitaler Form – unter vorgegebenen Aspekten vergleichen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S1_TXT_REZ';

-- Erste Stufe · Texte · Produktion (9)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S1_TXT_PRO_01' AS code, 'aus Aufgabenstellungen konkrete Schreibziele ableiten, Texte planen und zunehmend selbstständig eigene Texte …' AS kurzname, 'aus Aufgabenstellungen konkrete Schreibziele ableiten, Texte planen und zunehmend selbstständig eigene Texte adressaten- und situationsgerecht formulieren' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_PRO_02' AS code, 'Texte kriteriengeleitet prüfen und Überarbeitungsvorschläge für die Textrevision nutzen' AS kurzname, 'Texte kriteriengeleitet prüfen und Überarbeitungsvorschläge für die Textrevision nutzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_PRO_03' AS code, 'bei der Textplanung, -formulierung und -überarbeitung die Möglichkeiten digitalen Schreibens (Gliederung und …' AS kurzname, 'bei der Textplanung, -formulierung und -überarbeitung die Möglichkeiten digitalen Schreibens (Gliederung und Inhaltsverzeichnis, Anordnen und Umstellen von Textpassagen, Weiterschreiben an verschiedenen Stellen) einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_PRO_04' AS code, 'die Ergebnisse der Textanalyse strukturiert darstellen' AS kurzname, 'die Ergebnisse der Textanalyse strukturiert darstellen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_PRO_05' AS code, 'ihr Verständnis eines literarischen Textes mit Textstellen belegen und im Dialog mit anderen Schülerinnen und Schülern …' AS kurzname, 'ihr Verständnis eines literarischen Textes mit Textstellen belegen und im Dialog mit anderen Schülerinnen und Schülern weiterentwickeln' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_PRO_06' AS code, 'Texte sinngestaltend unter Nutzung verschiedener Ausdrucksmittel (Artikulation, Modulation, Tempo, Intonation, Mimik …' AS kurzname, 'Texte sinngestaltend unter Nutzung verschiedener Ausdrucksmittel (Artikulation, Modulation, Tempo, Intonation, Mimik und Gestik) vortragen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_PRO_07' AS code, 'verschiedene Textfunktionen (appellieren, argumentieren, berichten, beschreiben, erklären, informieren) in eigenen …' AS kurzname, 'verschiedene Textfunktionen (appellieren, argumentieren, berichten, beschreiben, erklären, informieren) in eigenen mündlichen und schriftlichen Texten sachgerecht einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_PRO_08' AS code, 'mögliches Vorwissen, Haltungen und Interessen eines Adressaten identifizieren und eigene Schreibprodukte darauf …' AS kurzname, 'mögliches Vorwissen, Haltungen und Interessen eines Adressaten identifizieren und eigene Schreibprodukte darauf abstimmen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_TXT_PRO_09' AS code, 'Informationen aus verschiedenen Quellen (u.a. kontinuierliche, diskontinuierliche Sachtexte – auch in digitaler Form) …' AS kurzname, 'Informationen aus verschiedenen Quellen (u.a. kontinuierliche, diskontinuierliche Sachtexte – auch in digitaler Form) ermitteln und dem eigenen Schreibziel entsprechend nutzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S1_TXT_PRO';

-- Erste Stufe · Kommunikation · Rezeption (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S1_KOM_REZ_01' AS code, 'gelingende und misslingende Kommunikation identifizieren und Korrekturmöglichkeiten benennen' AS kurzname, 'gelingende und misslingende Kommunikation identifizieren und Korrekturmöglichkeiten benennen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_KOM_REZ_02' AS code, 'Absichten und Interessen anderer Gesprächsteilnehmender identifizieren und erläutern' AS kurzname, 'Absichten und Interessen anderer Gesprächsteilnehmender identifizieren und erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_KOM_REZ_03' AS code, 'para- und nonverbales Verhalten deuten' AS kurzname, 'para- und nonverbales Verhalten deuten' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_KOM_REZ_04' AS code, 'beabsichtigte und unbeabsichtigte Wirkungen des eigenen und fremden kommunikativen Handelns – auch in digitaler …' AS kurzname, 'beabsichtigte und unbeabsichtigte Wirkungen des eigenen und fremden kommunikativen Handelns – auch in digitaler Kommunikation – reflektieren und Konsequenzen daraus ableiten' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_KOM_REZ_05' AS code, 'in Gesprächen und Diskussionen aktiv zuhören und zugleich eigene Gesprächsbeiträge planen' AS kurzname, 'in Gesprächen und Diskussionen aktiv zuhören und zugleich eigene Gesprächsbeiträge planen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_KOM_REZ_06' AS code, 'längeren Beiträgen aufmerksam zuhören, gezielt nachfragen und zentrale Aussagen des Gehörten wiedergeben – auch unter …' AS kurzname, 'längeren Beiträgen aufmerksam zuhören, gezielt nachfragen und zentrale Aussagen des Gehörten wiedergeben – auch unter Nutzung eigener Notizen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S1_KOM_REZ';

-- Erste Stufe · Kommunikation · Produktion (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S1_KOM_PRO_01' AS code, 'in Gesprächssituationen die kommunikativen Anforderungen identifizieren und eigene Beiträge darauf abstimmen' AS kurzname, 'in Gesprächssituationen die kommunikativen Anforderungen identifizieren und eigene Beiträge darauf abstimmen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_KOM_PRO_02' AS code, 'eigene Standpunkte begründen und dabei auch die Beiträge anderer einbeziehen' AS kurzname, 'eigene Standpunkte begründen und dabei auch die Beiträge anderer einbeziehen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_KOM_PRO_03' AS code, 'bei strittigen Fragen Lösungsvarianten entwickeln und erörtern' AS kurzname, 'bei strittigen Fragen Lösungsvarianten entwickeln und erörtern' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_KOM_PRO_04' AS code, 'sich an unterschiedlichen Gesprächsformen (u.a. Diskussion, Informationsgespräch, kooperative Arbeitsformen) …' AS kurzname, 'sich an unterschiedlichen Gesprächsformen (u.a. Diskussion, Informationsgespräch, kooperative Arbeitsformen) ergebnisorientiert beteiligen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S1_KOM_PRO';

-- Erste Stufe · Medien · Rezeption (10)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S1_MED_REZ_01' AS code, 'dem Leseziel und dem Medium angepasste Lesestrategien des orientierenden, selektiven, vergleichenden, intensiven Lesens …' AS kurzname, 'dem Leseziel und dem Medium angepasste Lesestrategien des orientierenden, selektiven, vergleichenden, intensiven Lesens einsetzen (u.a. bei Hypertexten) und die Lektüreergebnisse grafisch darstellen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_MED_REZ_02' AS code, 'in Suchmaschinen und auf Websites dargestellte Informationen als abhängig von Spezifika der Internetformate beschreiben …' AS kurzname, 'in Suchmaschinen und auf Websites dargestellte Informationen als abhängig von Spezifika der Internetformate beschreiben und das eigene Wahrnehmungsverhalten reflektieren' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_MED_REZ_03' AS code, 'Medien (Printmedien, Hörmedien, audiovisuelle Medien, Website-Formate, Mischformen) bezüglich ihrer Präsentationsform …' AS kurzname, 'Medien (Printmedien, Hörmedien, audiovisuelle Medien, Website-Formate, Mischformen) bezüglich ihrer Präsentationsform beschreiben und Funktionen (Information, Beeinflussung, Kommunikation, Unterhaltung, Verkauf) vergleichen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_MED_REZ_04' AS code, 'den Grad der Öffentlichkeit in Formen der Internet-Kommunikation abschätzen und Handlungskonsequenzen aufzeigen …' AS kurzname, 'den Grad der Öffentlichkeit in Formen der Internet-Kommunikation abschätzen und Handlungskonsequenzen aufzeigen (Persönlichkeitsrechte, Datenschutz, Altersbeschränkungen)' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_MED_REZ_05' AS code, 'in Medien Realitätsdarstellungen und Darstellung virtueller Welten unterscheiden' AS kurzname, 'in Medien Realitätsdarstellungen und Darstellung virtueller Welten unterscheiden' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_MED_REZ_06' AS code, 'den Aufbau von Printmedien und verwandten digitalen Medien (Zeitung, Online-Zeitung) beschreiben, Unterschiede der …' AS kurzname, 'den Aufbau von Printmedien und verwandten digitalen Medien (Zeitung, Online-Zeitung) beschreiben, Unterschiede der Text- und Layoutgestaltung zu einem Thema benennen und deren Wirkung vergleichen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_MED_REZ_07' AS code, 'ihren Gesamteindruck von (Kurz-)Filmen bzw. anderen Bewegtbildern beschreiben und anhand inhaltlicher und ästhetischer …' AS kurzname, 'ihren Gesamteindruck von (Kurz-)Filmen bzw. anderen Bewegtbildern beschreiben und anhand inhaltlicher und ästhetischer Merkmale begründen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_MED_REZ_08' AS code, 'Handlungsstrukturen in audiovisuellen Texten (u.a. (Kurz-)Film) mit film- und erzähltechnischen Fachbegriffen …' AS kurzname, 'Handlungsstrukturen in audiovisuellen Texten (u.a. (Kurz-)Film) mit film- und erzähltechnischen Fachbegriffen identifizieren sowie Gestaltungsmittel (u.a. Bildgestaltung, Kameratechnik, Tongestaltung) benennen und deren Wirkung erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_MED_REZ_09' AS code, 'mediale Gestaltungen von Werbung beschreiben und hinsichtlich der Wirkungen (u.a. Rollenbilder) analysieren' AS kurzname, 'mediale Gestaltungen von Werbung beschreiben und hinsichtlich der Wirkungen (u.a. Rollenbilder) analysieren' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_MED_REZ_10' AS code, 'die Qualität verschiedener Quellen an Kriterien (Autor/in, Ausgewogenheit, Informationsgehalt, Belege) prüfen und …' AS kurzname, 'die Qualität verschiedener Quellen an Kriterien (Autor/in, Ausgewogenheit, Informationsgehalt, Belege) prüfen und bewerten' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S1_MED_REZ';

-- Erste Stufe · Medien · Produktion (7)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S1_MED_PRO_01' AS code, 'angeleitet komplexe Recherchestrategien für Printmedien und digitale Medien unterscheiden und einsetzen' AS kurzname, 'angeleitet komplexe Recherchestrategien für Printmedien und digitale Medien unterscheiden und einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_MED_PRO_02' AS code, 'digitale Kommunikation adressaten- und situationsangemessen gestalten und dabei Kommunikations- und Kooperationsregeln …' AS kurzname, 'digitale Kommunikation adressaten- und situationsangemessen gestalten und dabei Kommunikations- und Kooperationsregeln (Netiquette) einhalten' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_MED_PRO_03' AS code, 'Elemente konzeptioneller Mündlichkeit bzw. Schriftlichkeit in digitaler und nicht-digitaler Kommunikation …' AS kurzname, 'Elemente konzeptioneller Mündlichkeit bzw. Schriftlichkeit in digitaler und nicht-digitaler Kommunikation identifizieren, die Wirkungen vergleichen und eigene Produkte (offizieller Brief, Online-Beitrag) situations- und adressatenangemessen gestalten' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_MED_PRO_04' AS code, 'unter Nutzung digitaler und nicht-digitaler Medien Arbeits- und Lernergebnisse adressaten-, sachgerecht und …' AS kurzname, 'unter Nutzung digitaler und nicht-digitaler Medien Arbeits- und Lernergebnisse adressaten-, sachgerecht und bildungssprachlich angemessen vorstellen' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_MED_PRO_05' AS code, 'eine Textvorlage (u.a. Zeitungsartikel) medial umformen und die intendierte Wirkung von Gestaltungsmitteln beschreiben' AS kurzname, 'eine Textvorlage (u.a. Zeitungsartikel) medial umformen und die intendierte Wirkung von Gestaltungsmitteln beschreiben' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_MED_PRO_06' AS code, 'Inhalt, Gestaltung und Präsentation von Medienprodukten beschreiben' AS kurzname, 'Inhalt, Gestaltung und Präsentation von Medienprodukten beschreiben' AS beschreibung
  UNION ALL
  SELECT 'DE_S1_MED_PRO_07' AS code, 'digitale Möglichkeiten für die individuelle und kooperative Textproduktion einsetzen' AS kurzname, 'digitale Möglichkeiten für die individuelle und kooperative Textproduktion einsetzen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S1_MED_PRO';

-- Zweite Stufe · Sprache · Rezeption (9)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S2_SPR_REZ_01' AS code, 'Verfahren der Wortbildung (u.a. fachsprachliche Begriffsbildung, Integration von Fremdwörtern) unterscheiden' AS kurzname, 'Verfahren der Wortbildung (u.a. fachsprachliche Begriffsbildung, Integration von Fremdwörtern) unterscheiden' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_SPR_REZ_02' AS code, 'komplexe sprachliche Gestaltungsmittel (u.a. rhetorische Figuren) identifizieren, ihre Bedeutung für die Textaussage …' AS kurzname, 'komplexe sprachliche Gestaltungsmittel (u.a. rhetorische Figuren) identifizieren, ihre Bedeutung für die Textaussage und ihre Wirkung erläutern (u.a. sprachliche Signale von Beeinflussung)' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_SPR_REZ_03' AS code, 'Sprachvarietäten und stilistische Merkmale von Texten auf Wort-, Satz- und Textebene in ihrer Wirkung beurteilen' AS kurzname, 'Sprachvarietäten und stilistische Merkmale von Texten auf Wort-, Satz- und Textebene in ihrer Wirkung beurteilen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_SPR_REZ_04' AS code, 'anhand von Beispielen historische und aktuelle Erscheinungen des Sprachwandels erläutern (Bedeutungsveränderungen, …' AS kurzname, 'anhand von Beispielen historische und aktuelle Erscheinungen des Sprachwandels erläutern (Bedeutungsveränderungen, Einfluss von Kontakt- und Regionalsprachen wie Niederdeutsch, mediale Einflüsse, geschlechtergerechte Sprache)' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_SPR_REZ_05' AS code, 'konzeptionelle Mündlichkeit und Schriftlichkeit unterscheiden sowie deren Funktion und Angemessenheit erläutern' AS kurzname, 'konzeptionelle Mündlichkeit und Schriftlichkeit unterscheiden sowie deren Funktion und Angemessenheit erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_SPR_REZ_06' AS code, 'Abweichungen von der Standardsprache im Kontext von Sprachwandel erläutern' AS kurzname, 'Abweichungen von der Standardsprache im Kontext von Sprachwandel erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_SPR_REZ_07' AS code, 'sprachliche Zuschreibungen und Diskriminierungen (kulturell, geschlechterbezogen) beurteilen' AS kurzname, 'sprachliche Zuschreibungen und Diskriminierungen (kulturell, geschlechterbezogen) beurteilen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_SPR_REZ_08' AS code, 'semantische Unterschiede zwischen Sprachen aufzeigen (Übersetzungsvergleich, Denotationen, Konnotationen)' AS kurzname, 'semantische Unterschiede zwischen Sprachen aufzeigen (Übersetzungsvergleich, Denotationen, Konnotationen)' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_SPR_REZ_09' AS code, 'Mehrsprachigkeit in ihrer individuellen und gesellschaftlichen Bedeutung erläutern' AS kurzname, 'Mehrsprachigkeit in ihrer individuellen und gesellschaftlichen Bedeutung erläutern' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S2_SPR_REZ';

-- Zweite Stufe · Sprache · Produktion (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S2_SPR_PRO_01' AS code, 'relevantes sprachliches Wissen zur Herstellung von Textkohärenz beim Schreiben eigener Texte einsetzen' AS kurzname, 'relevantes sprachliches Wissen zur Herstellung von Textkohärenz beim Schreiben eigener Texte einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_SPR_PRO_02' AS code, 'selbstständig Texte mittels geeigneter Rechtschreibstrategien (auf Laut-Buchstaben-Ebene, Wortebene, Satzebene) …' AS kurzname, 'selbstständig Texte mittels geeigneter Rechtschreibstrategien (auf Laut-Buchstaben-Ebene, Wortebene, Satzebene) überarbeiten' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_SPR_PRO_03' AS code, 'eine normgerechte Zeichensetzung realisieren (u.a. beim Zitieren)' AS kurzname, 'eine normgerechte Zeichensetzung realisieren (u.a. beim Zitieren)' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_SPR_PRO_04' AS code, 'adressaten-, situationsangemessen, bildungssprachlich und fachsprachlich angemessen formulieren (paraphrasieren, …' AS kurzname, 'adressaten-, situationsangemessen, bildungssprachlich und fachsprachlich angemessen formulieren (paraphrasieren, referieren, erklären, schlussfolgern, vergleichen, argumentieren, beurteilen)' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_SPR_PRO_05' AS code, 'Formulierungsalternativen begründet auswählen' AS kurzname, 'Formulierungsalternativen begründet auswählen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_SPR_PRO_06' AS code, 'selbstständig eigene und fremde Texte kriterienorientiert überarbeiten (u.a. stilistische Angemessenheit, …' AS kurzname, 'selbstständig eigene und fremde Texte kriterienorientiert überarbeiten (u.a. stilistische Angemessenheit, Verständlichkeit)' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S2_SPR_PRO';

-- Zweite Stufe · Texte · Rezeption (9)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S2_TXT_REZ_01' AS code, 'in Texten das Thema bestimmen, Texte aspektgeleitet analysieren und – auch unter Berücksichtigung von …' AS kurzname, 'in Texten das Thema bestimmen, Texte aspektgeleitet analysieren und – auch unter Berücksichtigung von Kontextinformationen (u.a. Epochenbezug, historisch-gesellschaftlicher Kontext, biografischer Bezug, Textgenrespezifika) – zunehmend selbstständig schlüssige Deutungen entwickeln' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_REZ_02' AS code, 'Zusammenhänge zwischen Form und Inhalt bei der Analyse von epischen, lyrischen und dramatischen Texten sachgerecht …' AS kurzname, 'Zusammenhänge zwischen Form und Inhalt bei der Analyse von epischen, lyrischen und dramatischen Texten sachgerecht erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_REZ_03' AS code, 'in literarischen Texten komplexe Handlungsstrukturen, die Entwicklung zentraler Konflikte, die Figurenkonstellationen …' AS kurzname, 'in literarischen Texten komplexe Handlungsstrukturen, die Entwicklung zentraler Konflikte, die Figurenkonstellationen sowie relevante Figurenmerkmale und Handlungsmotive identifizieren und zunehmend selbstständig erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_REZ_04' AS code, 'zunehmend selbstständig literarische Texte aspektgeleitet miteinander vergleichen (u.a. Motiv- und …' AS kurzname, 'zunehmend selbstständig literarische Texte aspektgeleitet miteinander vergleichen (u.a. Motiv- und Themenverwandtschaft, Kontextbezüge)' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_REZ_05' AS code, 'unterschiedliche Deutungen eines literarischen Textes miteinander vergleichen und Deutungsspielräume erläutern' AS kurzname, 'unterschiedliche Deutungen eines literarischen Textes miteinander vergleichen und Deutungsspielräume erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_REZ_06' AS code, 'die eigene Perspektive auf durch literarische Texte vermittelte Weltdeutungen textbezogen erläutern' AS kurzname, 'die eigene Perspektive auf durch literarische Texte vermittelte Weltdeutungen textbezogen erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_REZ_07' AS code, 'ihr Verständnis eines literarischen Textes in verschiedenen Formen produktiver Gestaltung darstellen und die eigenen …' AS kurzname, 'ihr Verständnis eines literarischen Textes in verschiedenen Formen produktiver Gestaltung darstellen und die eigenen Entscheidungen zu Inhalt, Gestaltungsweise und medialer Form im Hinblick auf den Ausgangstext begründen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_REZ_08' AS code, 'diskontinuierliche und kontinuierliche Sachtexte weitgehend selbstständig unter Berücksichtigung von Form, Inhalt und …' AS kurzname, 'diskontinuierliche und kontinuierliche Sachtexte weitgehend selbstständig unter Berücksichtigung von Form, Inhalt und Funktion analysieren' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_REZ_09' AS code, 'Sachtexte – auch in digitaler Form – im Hinblick auf Form, Inhalt und Funktion miteinander vergleichen und bewerten' AS kurzname, 'Sachtexte – auch in digitaler Form – im Hinblick auf Form, Inhalt und Funktion miteinander vergleichen und bewerten' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S2_TXT_REZ';

-- Zweite Stufe · Texte · Produktion (10)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S2_TXT_PRO_01' AS code, 'eigene Schreibziele benennen, Texte selbstständig in Bezug auf Inhalt und sprachliche Gestaltung (u.a. Mittel der …' AS kurzname, 'eigene Schreibziele benennen, Texte selbstständig in Bezug auf Inhalt und sprachliche Gestaltung (u.a. Mittel der Leserführung) planen und verfassen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_PRO_02' AS code, 'Methoden der Textüberarbeitung selbstständig anwenden und Textveränderungen begründen' AS kurzname, 'Methoden der Textüberarbeitung selbstständig anwenden und Textveränderungen begründen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_PRO_03' AS code, 'Texte unter Nutzung der spezifischen Möglichkeiten digitalen Schreibens verfassen und überarbeiten' AS kurzname, 'Texte unter Nutzung der spezifischen Möglichkeiten digitalen Schreibens verfassen und überarbeiten' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_PRO_04' AS code, 'sich im literarischen Gespräch über unterschiedliche Sichtweisen zu einem literarischen Text verständigen und ein …' AS kurzname, 'sich im literarischen Gespräch über unterschiedliche Sichtweisen zu einem literarischen Text verständigen und ein Textverständnis unter Einbezug von eigenen und fremden Lesarten formulieren' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_PRO_05' AS code, 'Fremdheitserfahrungen beim Lesen literarischer Texte identifizieren und mögliche Gründe (kulturell-, sozial-, gender-, …' AS kurzname, 'Fremdheitserfahrungen beim Lesen literarischer Texte identifizieren und mögliche Gründe (kulturell-, sozial-, gender-, historisch-bedingt) erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_PRO_06' AS code, 'in heuristischen Schreibformen unterschiedliche Positionen zu einer fachlichen Fragestellung – auch unter Nutzung von …' AS kurzname, 'in heuristischen Schreibformen unterschiedliche Positionen zu einer fachlichen Fragestellung – auch unter Nutzung von sach- und fachspezifischen Informationen aus Texten – abwägen und ein eigenes Urteil begründen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_PRO_07' AS code, 'Vorwissen, Haltungen und Interessen eines heterogenen Adressatenkreises einschätzen und eigene Schreibprodukte darauf …' AS kurzname, 'Vorwissen, Haltungen und Interessen eines heterogenen Adressatenkreises einschätzen und eigene Schreibprodukte darauf abstimmen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_PRO_08' AS code, 'weitgehend selbstständig die Relevanz des Informationsgehalts von Sachtexten für eigene Schreibziele beurteilen sowie …' AS kurzname, 'weitgehend selbstständig die Relevanz des Informationsgehalts von Sachtexten für eigene Schreibziele beurteilen sowie informierende, argumentierende und appellative Textfunktionen für eigene Darstellungsabsichten sach-, adressaten- und situationsgerecht einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_PRO_09' AS code, 'Informationen auch aus selbst recherchierten Texten ermitteln und für das Schreiben eigener Texte einsetzen' AS kurzname, 'Informationen auch aus selbst recherchierten Texten ermitteln und für das Schreiben eigener Texte einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_TXT_PRO_10' AS code, 'Bewerbungen – auch digital – verfassen (u.a. Bewerbungsschreiben, Lebenslauf)' AS kurzname, 'Bewerbungen – auch digital – verfassen (u.a. Bewerbungsschreiben, Lebenslauf)' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S2_TXT_PRO';

-- Zweite Stufe · Kommunikation · Rezeption (4)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S2_KOM_REZ_01' AS code, 'in Sprechsituationen Sach- und Beziehungsebene unterscheiden und für misslingende Kommunikation Korrekturmöglichkeiten …' AS kurzname, 'in Sprechsituationen Sach- und Beziehungsebene unterscheiden und für misslingende Kommunikation Korrekturmöglichkeiten erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_KOM_REZ_02' AS code, 'beabsichtigte und unbeabsichtigte Wirkungen des eigenen und fremden kommunikativen Handelns – in privaten und …' AS kurzname, 'beabsichtigte und unbeabsichtigte Wirkungen des eigenen und fremden kommunikativen Handelns – in privaten und beruflichen Kommunikationssituationen – reflektieren und das eigene Kommunikationsverhalten der Intention anpassen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_KOM_REZ_03' AS code, 'Gesprächsverläufe beschreiben und Gesprächsstrategien identifizieren' AS kurzname, 'Gesprächsverläufe beschreiben und Gesprächsstrategien identifizieren' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_KOM_REZ_04' AS code, 'zentrale Informationen aus Präsentationen (u.a. Text-Bild-Relation) zu fachspezifischen Themen erschließen und …' AS kurzname, 'zentrale Informationen aus Präsentationen (u.a. Text-Bild-Relation) zu fachspezifischen Themen erschließen und weiterführende Fragestellungen formulieren' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S2_KOM_REZ';

-- Zweite Stufe · Kommunikation · Produktion (6)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S2_KOM_PRO_01' AS code, 'für Kommunikationssituationen passende Sprachregister auswählen und eigene Beiträge situations- und adressatengerecht …' AS kurzname, 'für Kommunikationssituationen passende Sprachregister auswählen und eigene Beiträge situations- und adressatengerecht vortragen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_KOM_PRO_02' AS code, 'dem Diskussionsstand angemessene eigene Redebeiträge formulieren' AS kurzname, 'dem Diskussionsstand angemessene eigene Redebeiträge formulieren' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_KOM_PRO_03' AS code, 'eigene Positionen situations- und adressatengerecht in Auseinandersetzung mit anderen Positionen begründen' AS kurzname, 'eigene Positionen situations- und adressatengerecht in Auseinandersetzung mit anderen Positionen begründen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_KOM_PRO_04' AS code, 'die Rollenanforderungen in Gesprächsformen (u.a. Debatte, kooperative Arbeitsformen, Gruppendiskussion) untersuchen und …' AS kurzname, 'die Rollenanforderungen in Gesprächsformen (u.a. Debatte, kooperative Arbeitsformen, Gruppendiskussion) untersuchen und verschiedene Rollen (teilnehmend, beobachtend, moderierend) übernehmen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_KOM_PRO_05' AS code, 'Gesprächs- und Arbeitsergebnisse in eigenen Worten zusammenfassen und bildungssprachlich angemessen präsentieren' AS kurzname, 'Gesprächs- und Arbeitsergebnisse in eigenen Worten zusammenfassen und bildungssprachlich angemessen präsentieren' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_KOM_PRO_06' AS code, 'Anforderungen in Bewerbungssituationen identifizieren und das eigene Kommunikationsverhalten daran anpassen' AS kurzname, 'Anforderungen in Bewerbungssituationen identifizieren und das eigene Kommunikationsverhalten daran anpassen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S2_KOM_PRO';

-- Zweite Stufe · Medien · Rezeption (9)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S2_MED_REZ_01' AS code, 'dem Leseziel und dem Medium angepasste Lesestrategien insbesondere des selektiven und des vergleichenden Lesens …' AS kurzname, 'dem Leseziel und dem Medium angepasste Lesestrategien insbesondere des selektiven und des vergleichenden Lesens einsetzen (u.a. bei Hypertexten) und Leseergebnisse synoptisch darstellen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_MED_REZ_02' AS code, 'die Funktionsweisen gängiger Internetformate (Suchmaschinen, soziale Medien) im Hinblick auf das präsentierte …' AS kurzname, 'die Funktionsweisen gängiger Internetformate (Suchmaschinen, soziale Medien) im Hinblick auf das präsentierte Informationsspektrum analysieren' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_MED_REZ_03' AS code, 'Inhalte aus digitalen und nicht-digitalen Medien beschreiben und hinsichtlich ihrer Funktionen (Information, …' AS kurzname, 'Inhalte aus digitalen und nicht-digitalen Medien beschreiben und hinsichtlich ihrer Funktionen (Information, Beeinflussung, Kommunikation, Unterhaltung, Verkauf) untersuchen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_MED_REZ_04' AS code, 'Medien gezielt auswählen und die Art der Mediennutzung im Hinblick auf Funktion, Möglichkeiten und Risiken begründen' AS kurzname, 'Medien gezielt auswählen und die Art der Mediennutzung im Hinblick auf Funktion, Möglichkeiten und Risiken begründen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_MED_REZ_05' AS code, 'Chancen und Risiken des interaktiven Internets benennen und Konsequenzen aufzeigen (öffentliche Meinungsbildung, …' AS kurzname, 'Chancen und Risiken des interaktiven Internets benennen und Konsequenzen aufzeigen (öffentliche Meinungsbildung, Mechanismen der Themensetzung, Datenschutz, Altersbeschränkungen, Persönlichkeits-, Urheber- und Nutzungsrechte)' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_MED_REZ_06' AS code, 'ihren Gesamteindruck der ästhetischen Gestaltung eines medialen Produktes beschreiben und an Form-Inhalt-Bezügen …' AS kurzname, 'ihren Gesamteindruck der ästhetischen Gestaltung eines medialen Produktes beschreiben und an Form-Inhalt-Bezügen begründen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_MED_REZ_07' AS code, 'mediale Darstellungen als Konstrukt identifizieren, die Darstellung von Realität und virtuellen Welten beschreiben und …' AS kurzname, 'mediale Darstellungen als Konstrukt identifizieren, die Darstellung von Realität und virtuellen Welten beschreiben und hinsichtlich der Potenziale zur Beeinflussung von Rezipientinnen und Rezipienten (u.a. Fake News, Geschlechterzuschreibungen) bewerten' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_MED_REZ_08' AS code, 'audiovisuelle Texte analysieren (u.a. Videoclip) und genretypische Gestaltungsmittel erläutern' AS kurzname, 'audiovisuelle Texte analysieren (u.a. Videoclip) und genretypische Gestaltungsmittel erläutern' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_MED_REZ_09' AS code, 'die Qualität verschiedener Quellen an Kriterien (Autor/in, Ausgewogenheit, Informationsgehalt, Belege) prüfen und eine …' AS kurzname, 'die Qualität verschiedener Quellen an Kriterien (Autor/in, Ausgewogenheit, Informationsgehalt, Belege) prüfen und eine Bewertung schlüssig begründen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S2_MED_REZ';

-- Zweite Stufe · Medien · Produktion (7)
INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)
SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL
FROM kompetenzbereiche kb JOIN (
  SELECT 'DE_S2_MED_PRO_01' AS code, 'selbstständig unterschiedliche mediale Quellen für eigene Recherchen einsetzen und Informationen quellenkritisch …' AS kurzname, 'selbstständig unterschiedliche mediale Quellen für eigene Recherchen einsetzen und Informationen quellenkritisch auswählen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_MED_PRO_02' AS code, 'in der digitalen Kommunikation verwendete Sprachregister unterscheiden und reflektiert einsetzen' AS kurzname, 'in der digitalen Kommunikation verwendete Sprachregister unterscheiden und reflektiert einsetzen' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_MED_PRO_03' AS code, 'zur Organisation von komplexen Lernprozessen und zur Dokumentation von Arbeitsergebnissen geeignete analoge und …' AS kurzname, 'zur Organisation von komplexen Lernprozessen und zur Dokumentation von Arbeitsergebnissen geeignete analoge und digitale Medien sowie Werkzeuge verwenden' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_MED_PRO_04' AS code, 'Grundregeln von korrekter Zitation und Varianten der Belegführung erläutern sowie verwendete Quellen konventionskonform …' AS kurzname, 'Grundregeln von korrekter Zitation und Varianten der Belegführung erläutern sowie verwendete Quellen konventionskonform dokumentieren' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_MED_PRO_05' AS code, 'auf der Grundlage von Texten mediale Produkte planen und umsetzen sowie intendierte Wirkungen verwendeter …' AS kurzname, 'auf der Grundlage von Texten mediale Produkte planen und umsetzen sowie intendierte Wirkungen verwendeter Gestaltungsmittel beschreiben' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_MED_PRO_06' AS code, 'Inhalt, Gestaltung und Präsentation von Medienprodukten analysieren' AS kurzname, 'Inhalt, Gestaltung und Präsentation von Medienprodukten analysieren' AS beschreibung
  UNION ALL
  SELECT 'DE_S2_MED_PRO_07' AS code, 'rechtliche Regelungen zur Veröffentlichung und zum Teilen von Medienprodukten benennen und bei eigenen Produkten …' AS kurzname, 'rechtliche Regelungen zur Veröffentlichung und zum Teilen von Medienprodukten benennen und bei eigenen Produkten berücksichtigen' AS beschreibung
) t ON kb.rahmen_id = @rahmen AND kb.code = 'DE_S2_MED_PRO';

COMMIT;

-- Kontrolle:
-- SELECT COUNT(*) FROM kompetenzbereiche WHERE rahmen_id=@rahmen;  -- erwartet: 28
-- SELECT COUNT(*) FROM kompetenzen k JOIN kompetenzbereiche kb ON kb.id=k.bereich_id WHERE kb.rahmen_id=@rahmen;  -- erwartet: 226
