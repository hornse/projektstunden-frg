-- =============================================================================
-- Seed-Daten: Beispielschule, Fächer (G9-Stundentafel), Kompetenzrahmen
-- =============================================================================
-- Ausführungsreihenfolge: nach 01_schema.sql
-- Alle INSERT IGNORE – können also wiederholt ausgeführt werden.
-- =============================================================================

SET NAMES utf8mb4;

-- -----------------------------------------------------------------------------
-- Beispielschule (ID 1) – bitte nach Installation anpassen
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO schulen (id, name, kuerzel, adresse) VALUES
(1, 'Muster-Gymnasium NRW', 'MGY', 'Musterstraße 1, 12345 Musterstadt');

-- Admin-Benutzer (Passwort: "Admin1234!" – BITTE SOFORT ÄNDERN)
-- Hash erzeugt mit: php -r "echo password_hash('Admin1234!', PASSWORD_DEFAULT);"
INSERT IGNORE INTO benutzer (id, schule_id, vorname, nachname, email, passwort_hash, rolle, kuerzel) VALUES
(1, 1, 'Admin', 'Mustermann', 'admin@schule.de',
 '$2y$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMaWdcGbFZDRYDK3j6/w4lEY4e',
 'admin', 'ADM');

-- -----------------------------------------------------------------------------
-- FÄCHER mit G9-Stundentafel NRW (Anlage 3a, gültig ab 01.08.2021)
-- Spalten: soll_jg5 … soll_jg10 = Wochenstunden je Jahrgangsstufe
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO faecher (schule_id, name, kuerzel, soll_jg5, soll_jg6, soll_jg7, soll_jg8, soll_jg9, soll_jg10) VALUES
-- Sprachen
(1, 'Deutsch',              'DE',  5, 4, 4, 3, 3, 3),
(1, 'Englisch',             'EN',  5, 4, 4, 3, 3, 3),
(1, '2. Fremdsprache',      'L2',  0, 0, 4, 4, 3, 3),
-- Mathematik & Naturwissenschaften
(1, 'Mathematik',           'MA',  5, 4, 3, 3, 4, 3),
(1, 'Biologie',             'BIO', 2, 2, 0, 2, 0, 2),
(1, 'Chemie',               'CH',  0, 0, 2, 2, 1, 2),
(1, 'Physik',               'PH',  0, 2, 0, 2, 2, 2),
(1, 'Informatik',           'IF',  0, 2, 0, 0, 0, 0),
-- Gesellschaftslehre
(1, 'Geschichte',           'GE',  0, 2, 2, 0, 2, 2),
(1, 'Erdkunde',             'EK',  2, 0, 2, 0, 2, 1),
(1, 'Wirtschaft-Politik',   'WP',  0, 2, 0, 2, 2, 2),
-- Künste
(1, 'Kunst',                'KU',  2, 1, 2, 2, 1, 1),
(1, 'Musik',                'MU',  2, 2, 0, 2, 1, 1),
-- Weitere Pflichtfächer
(1, 'Religion/Phil.',       'RE',  2, 2, 2, 2, 2, 2),
(1, 'Sport',                'SP',  4, 3, 4, 3, 2, 2);

-- -----------------------------------------------------------------------------
-- KOMPETENZRAHMEN 1: Medienkompetenzrahmen NRW (2020)
-- fach_id = NULL → fächerübergreifend
-- Quelle: https://medienkompetenzrahmen.nrw
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO kompetenzrahmen (id, schule_id, name, kuerzel, beschreibung, quelle_url, fach_id) VALUES
(1, 1,
 'Medienkompetenzrahmen NRW 2020',
 'MKR',
 '24 Teilkompetenzen in 6 Kompetenzbereichen. Grundlage für alle Fächer.',
 'https://medienkompetenzrahmen.nrw/medienkompetenzrahmen-nrw',
 NULL);

-- Bereiche MKR
INSERT IGNORE INTO kompetenzbereiche (id, rahmen_id, code, name, reihenfolge) VALUES
(1, 1, '1', 'Bedienen und Anwenden',        1),
(2, 1, '2', 'Informieren und Recherchieren', 2),
(3, 1, '3', 'Kommunizieren und Kooperieren', 3),
(4, 1, '4', 'Produzieren und Präsentieren',  4),
(5, 1, '5', 'Analysieren und Reflektieren',  5),
(6, 1, '6', 'Problemlösen und Modellieren',  6);

-- Teilkompetenzen MKR (24 Stück, alle fächerübergreifend)
INSERT IGNORE INTO kompetenzen (bereich_id, fach_id, code, kurzname, beschreibung) VALUES
-- Bereich 1
(1, NULL, '1.1', 'Medienausstattung (Hardware)',
 'Medienausstattung (Hardware) kennen, auswählen und reflektiert anwenden; mit dieser verantwortungsvoll umgehen.'),
(1, NULL, '1.2', 'Digitale Werkzeuge',
 'Verschiedene digitale Werkzeuge und deren Funktionsumfang kennen, auswählen sowie diese kreativ, reflektiert und zielgerichtet einsetzen.'),
(1, NULL, '1.3', 'Datenorganisation',
 'Informationen und Daten sicher speichern, wiederfinden und von verschiedenen Orten abrufen; Informationen und Daten zusammenfassen, organisieren und strukturiert aufbewahren.'),
(1, NULL, '1.4', 'Datenschutz und Informationssicherheit',
 'Verantwortungsvoll mit persönlichen und fremden Daten umgehen; Datenschutz, Privatsphäre und Informationssicherheit beachten.'),
-- Bereich 2
(2, NULL, '2.1', 'Informationsrecherche',
 'Informationsrecherchen zielgerichtet durchführen und dabei Suchstrategien anwenden.'),
(2, NULL, '2.2', 'Informationsauswertung',
 'Themenrelevante Informationen und Daten aus Medienangeboten filtern, strukturieren, umwandeln und aufbereiten.'),
(2, NULL, '2.3', 'Informationsbewertung',
 'Informationen, Daten und ihre Quellen sowie dahinterliegende Strategien und Absichten erkennen und kritisch bewerten.'),
(2, NULL, '2.4', 'Informationskritik',
 'Unangemessene und gefährdende Medieninhalte erkennen und hinsichtlich rechtlicher Grundlagen sowie gesellschaftlicher Normen und Werte einschätzen; Jugend- und Verbraucherschutz kennen und Hilfs- und Unterstützungsstrukturen nutzen.'),
-- Bereich 3
(3, NULL, '3.1', 'Kommunikations- und Kooperationsprozesse',
 'Kommunikations- und Kooperationsprozesse mit digitalen Werkzeugen zielgerichtet gestalten sowie mediale Produkte und Informationen teilen.'),
(3, NULL, '3.2', 'Kommunikations- und Kooperationsregeln',
 'Regeln für digitale Kommunikation und Kooperation kennen, formulieren und einhalten.'),
(3, NULL, '3.3', 'Kommunikation und Kooperation in der Gesellschaft',
 'Kommunikations- und Kooperationsprozesse im Sinne einer aktiven Teilhabe an der Gesellschaft gestalten und reflektieren; ethische Grundsätze sowie kulturell-gesellschaftliche Normen beachten.'),
(3, NULL, '3.4', 'Cybergewalt und -kriminalität',
 'Persönliche, gesellschaftliche und wirtschaftliche Risiken und Auswirkungen von Cybergewalt und -kriminalität erkennen sowie Ansprechpartner und Reaktionsmöglichkeiten kennen und nutzen.'),
-- Bereich 4
(4, NULL, '4.1', 'Medienproduktion und Präsentation',
 'Medienprodukte adressatengerecht planen, gestalten und präsentieren; Möglichkeiten des Veröffentlichens und Teilens kennen und nutzen.'),
(4, NULL, '4.2', 'Gestaltungsmittel',
 'Gestaltungsmittel von Medienprodukten kennen, reflektiert anwenden sowie hinsichtlich ihrer Qualität, Wirkung und Aussageabsicht beurteilen.'),
(4, NULL, '4.3', 'Quellendokumentation',
 'Standards der Quellenangaben beim Produzieren und Präsentieren von eigenen und fremden Inhalten kennen und anwenden.'),
(4, NULL, '4.4', 'Rechtliche Grundlagen',
 'Rechtliche Grundlagen des Persönlichkeits- (u.a. des Bildrechts), Urheber- und Nutzungsrechts (u.a. Lizenzen) überprüfen, bewerten und beachten.'),
-- Bereich 5
(5, NULL, '5.1', 'Medienanalyse',
 'Die Vielfalt der Medien, ihre Entwicklung und Bedeutungen kennen, analysieren und reflektieren.'),
(5, NULL, '5.2', 'Meinungsbildung',
 'Die interessengeleitete Setzung und Verbreitung von Themen in Medien erkennen sowie in Bezug auf die Meinungsbildung beurteilen.'),
(5, NULL, '5.3', 'Identitätsbildung',
 'Chancen und Herausforderungen von Medien für die Realitätswahrnehmung erkennen und analysieren sowie für die eigene Identitätsbildung nutzen.'),
(5, NULL, '5.4', 'Selbstregulierte Mediennutzung',
 'Medien und ihre Wirkungen beschreiben, kritisch reflektieren und deren Nutzung selbstverantwortlich regulieren; andere bei ihrer Mediennutzung unterstützen.'),
-- Bereich 6
(6, NULL, '6.1', 'Prinzipien der digitalen Welt',
 'Grundlegende Prinzipien und Funktionsweisen der digitalen Welt identifizieren, kennen, verstehen und bewusst nutzen.'),
(6, NULL, '6.2', 'Algorithmen erkennen',
 'Algorithmische Muster und Strukturen in verschiedenen Kontexten erkennen, nachvollziehen und reflektieren.'),
(6, NULL, '6.3', 'Modellieren und Programmieren',
 'Probleme formalisiert beschreiben, Problemlösestrategien entwickeln und dazu eine strukturierte, algorithmische Sequenz planen; diese auch durch Programmieren umsetzen und die gefundene Lösungsstrategie beurteilen.'),
(6, NULL, '6.4', 'Bedeutung von Algorithmen',
 'Einflüsse von Algorithmen und Auswirkung der Automatisierung von Prozessen in der digitalen Welt beschreiben und reflektieren.');

-- -----------------------------------------------------------------------------
-- KOMPETENZRAHMEN 2: Mathematik G9 – KLP NRW (prozess- & inhaltsbezogen)
-- fach_id wird nach dem INSERT der Fächer per Subquery gesetzt
-- -----------------------------------------------------------------------------
INSERT IGNORE INTO kompetenzrahmen (id, schule_id, name, kuerzel, beschreibung, quelle_url, fach_id) VALUES
(2, 1,
 'Mathematik KLP NRW G9 (FRG)',
 'MA_KLP',
 'Prozess- und inhaltsbezogene Kompetenzen, Kernlehrplan NRW Mathematik 2019.',
 'https://www.schulentwicklung.nrw.de/lehrplaene/lehrplan/200/g9_ma_klp_3401_2019_06_23.pdf',
 (SELECT id FROM faecher WHERE schule_id = 1 AND kuerzel = 'MA' LIMIT 1));

-- Prozessbezogene Kompetenzbereiche (Oberkategorien)
INSERT IGNORE INTO kompetenzbereiche (id, rahmen_id, code, name, beschreibung, reihenfolge) VALUES
(10, 2, 'OPE', 'Operieren',
 'Mathematisches Operieren: hilfsmittelfreies Operieren sowie Arbeiten mit Medien und Werkzeugen.', 1),
(11, 2, 'MOD', 'Modellieren',
 'Strukturieren, Mathematisieren sowie Interpretieren und Validieren realer Situationen.', 2),
(12, 2, 'PRO', 'Problemlösen',
 'Erkunden, Lösen und Reflektieren mathematischer Problemsituationen.', 3),
(13, 2, 'ARG', 'Argumentieren',
 'Vermuten, Begründen und Beurteilen mathematischer Zusammenhänge.', 4),
(14, 2, 'KOM', 'Kommunizieren',
 'Rezipieren, Produzieren und Diskutieren mathematischer Inhalte.', 5),
-- Inhaltsbezogene Bereiche: Erprobungsstufe
(20, 2, 'E_ARI', 'Arithmetik/Algebra (Jg. 5/6)',
 'Zahlverständnis, Grundrechenarten, Brüche, Dezimalzahlen, ganze Zahlen, Größen.', 6),
(21, 2, 'E_FKT', 'Funktionen (Jg. 5/6)',
 'Zusammenhänge, Tabellen, Diagramme, Maßstab und Dreisatz.', 7),
(22, 2, 'E_GEO', 'Geometrie (Jg. 5/6)',
 'Ebene Figuren, Körper, Lagebeziehungen, Symmetrie, Flächeninhalt und Volumen.', 8),
(23, 2, 'E_STO', 'Stochastik (Jg. 5/6)',
 'Datenerhebung, Diagramme, Häufigkeiten und Kenngrößen.', 9),
-- Erste Stufe
(30, 2, 'S1_ARI', 'Arithmetik/Algebra (Jg. 7/8)',
 'Rationale Zahlen, Terme, Gleichungen, Gleichungssysteme.', 10),
(31, 2, 'S1_FKT', 'Funktionen (Jg. 7/8)',
 'Zuordnungen, lineare Funktionen, Prozent- und Zinsrechnung.', 11),
(32, 2, 'S1_GEO', 'Geometrie (Jg. 7/8)',
 'Winkel, Dreiecke, Konstruktionen, geometrische Sätze.', 12),
(33, 2, 'S1_STO', 'Stochastik (Jg. 7/8)',
 'Zufallsversuche, Baumdiagramme, Laplace-Wahrscheinlichkeit.', 13),
-- Zweite Stufe
(40, 2, 'S2_ARI', 'Arithmetik/Algebra (Jg. 9/10)',
 'Reelle Zahlen, Potenzen, Wurzeln, Logarithmen, quadratische Gleichungen.', 14),
(41, 2, 'S2_FKT', 'Funktionen (Jg. 9/10)',
 'Quadratische, exponentielle und trigonometrische Funktionen.', 15),
(42, 2, 'S2_GEO', 'Geometrie (Jg. 9/10)',
 'Ähnlichkeit, Kreis, Körper, Pythagoras, Trigonometrie.', 16),
(43, 2, 'S2_STO', 'Stochastik (Jg. 9/10)',
 'Bedingte Wahrscheinlichkeit, Unabhängigkeit, Vierfeldertafeln.', 17);

-- Teilkompetenzen Mathematik – prozessbezogen (alle Jahrgänge, fach_id MA)
-- Hilfsvariable: MA-Fach-ID via Subquery
SET @ma_id = (SELECT id FROM faecher WHERE schule_id = 1 AND kuerzel = 'MA' LIMIT 1);

INSERT IGNORE INTO kompetenzen (bereich_id, fach_id, code, kurzname, beschreibung, jahrgangsstufe) VALUES
-- OPERIEREN
(10, @ma_id, 'OPE1',  'Kopfrechnen sicher anwenden', 'wenden grundlegende Kopfrechenfertigkeiten sicher an', NULL),
(10, @ma_id, 'OPE2',  'Geometrisch-räumliches Vorstellen', 'stellen sich geometrische Situationen räumlich vor und wechseln zwischen Perspektiven', NULL),
(10, @ma_id, 'OPE3',  'Formale und natürliche Sprache übersetzen', 'übersetzen symbolische und formale Sprache in natürliche Sprache und umgekehrt', NULL),
(10, @ma_id, 'OPE4',  'Rechenoperationen inhaltlich verstehen', 'führen Rechenoperationen auf der Grundlage eines inhaltlichen Verständnisses durch', NULL),
(10, @ma_id, 'OPE5',  'Mit Variablen und Termen arbeiten', 'arbeiten unter Berücksichtigung mathematischer Regeln mit Variablen, Termen, Gleichungen und Funktionen', NULL),
(10, @ma_id, 'OPE6',  'Darstellungswechsel ausführen', 'führen Darstellungswechsel sicher aus', NULL),
(10, @ma_id, 'OPE7',  'Lösungsverfahren effizient nutzen', 'führen Lösungs- und Kontrollverfahren sicher und effizient durch', NULL),
(10, @ma_id, 'OPE8',  'Algorithmen und Regeln nutzen', 'nutzen schematisierte und strategiegeleitete Verfahren, Algorithmen und Regeln', NULL),
(10, @ma_id, 'OPE9',  'Hilfsmittel zum Messen nutzen', 'nutzen mathematische Hilfsmittel (Lineal, Geodreieck, Zirkel) zum Messen und Konstruieren', NULL),
(10, @ma_id, 'OPE10', 'Informationen aus Medien recherchieren', 'nutzen Informationen aus Medienangeboten zur Informationsrecherche', NULL),
(10, @ma_id, 'OPE11', 'Digitale Mathematikwerkzeuge nutzen', 'nutzen digitale Mathematikwerkzeuge (DGS, CAS, Taschenrechner, Tabellenkalkulation)', NULL),
(10, @ma_id, 'OPE12', 'Hilfsmittel begründet auswählen', 'entscheiden situationsangemessen über den Einsatz mathematischer Hilfsmittel', NULL),
(10, @ma_id, 'OPE13', 'Analoge und digitale Medien nutzen', 'nutzen analoge und digitale Medien zur Unterstützung mathematischer Prozesse', NULL),
-- MODELLIEREN
(11, @ma_id, 'MOD1', 'Reale Situationen beschreiben', 'erfassen reale Situationen und beschreiben diese mit Worten und Skizzen', NULL),
(11, @ma_id, 'MOD2', 'Eigene Fragen zu Situationen stellen', 'stellen eigene Fragen zu realen Situationen, die mathematisch beantwortet werden können', NULL),
(11, @ma_id, 'MOD3', 'Annahmen treffen und vereinfachen', 'treffen begründet Annahmen und nehmen Vereinfachungen realer Situationen vor', NULL),
(11, @ma_id, 'MOD4', 'In mathematische Modelle übersetzen', 'übersetzen reale Situationen in mathematische Modelle bzw. wählen geeignete Modelle aus', NULL),
(11, @ma_id, 'MOD5', 'Situationen Modellen zuordnen', 'ordnen einem mathematischen Modell passende reale Situationen zu', NULL),
(11, @ma_id, 'MOD6', 'Lösungen im Modell erarbeiten', 'erarbeiten mithilfe mathematischer Kenntnisse Lösungen innerhalb des Modells', NULL),
(11, @ma_id, 'MOD7', 'Lösungen auf reale Situationen beziehen', 'beziehen erarbeitete Lösungen auf die reale Situation und interpretieren diese', NULL),
(11, @ma_id, 'MOD8', 'Plausibilität prüfen', 'überprüfen Lösungen auf ihre Plausibilität in realen Situationen', NULL),
(11, @ma_id, 'MOD9', 'Grenzen von Modellen benennen', 'benennen Grenzen aufgestellter mathematischer Modelle und verbessern diese', NULL),
-- PROBLEMLÖSEN
(12, @ma_id, 'PRO1',  'Problemsituation wiedergeben', 'geben Problemsituationen in eigenen Worten wieder und stellen Fragen', NULL),
(12, @ma_id, 'PRO2',  'Heuristische Hilfsmittel wählen', 'wählen geeignete heuristische Hilfsmittel aus (Skizze, Tabelle, experiment. Verfahren)', NULL),
(12, @ma_id, 'PRO3',  'Muster und Vermutungen', 'setzen Muster fort und stellen begründete Vermutungen über Zusammenhänge auf', NULL),
(12, @ma_id, 'PRO4',  'Geeignete Verfahren wählen', 'wählen geeignete Begriffe, Verfahren, Medien und Werkzeuge zur Problemlösung', NULL),
(12, @ma_id, 'PRO5',  'Heuristische Strategien nutzen', 'nutzen heuristische Strategien (Spezialfall, Analogie, Schätzen, Zerlegen, …)', NULL),
(12, @ma_id, 'PRO6',  'Lösungswege planen und umsetzen', 'entwickeln Ideen für Lösungswege, planen und führen diese zielgerichtet aus', NULL),
(12, @ma_id, 'PRO7',  'Plausibilität überprüfen', 'überprüfen die Plausibilität von Ergebnissen', NULL),
(12, @ma_id, 'PRO8',  'Lösungswege vergleichen', 'vergleichen Lösungswege und beurteilen deren Effizienz', NULL),
(12, @ma_id, 'PRO9',  'Fehlerursachen reflektieren', 'analysieren und reflektieren Ursachen von Fehlern', NULL),
(12, @ma_id, 'PRO10', 'Strategien übertragen', 'benennen heuristische Strategien und übertragen diese auf andere Problemstellungen', NULL),
-- ARGUMENTIEREN
(13, @ma_id, 'ARG1',  'Fragen stellen und vermuten', 'stellen für die Mathematik charakteristische Fragen und begründete Vermutungen auf', NULL),
(13, @ma_id, 'ARG2',  'Beispiele benennen', 'benennen Beispiele für vermutete Zusammenhänge', NULL),
(13, @ma_id, 'ARG3',  'Vermutungen präzisieren', 'präzisieren Vermutungen mithilfe von Fachbegriffen', NULL),
(13, @ma_id, 'ARG4',  'Relationen herstellen', 'stellen Relationen zwischen Fachbegriffen her (Ober-/Unterbegriff)', NULL),
(13, @ma_id, 'ARG5',  'Lösungswege begründen', 'begründen Lösungswege und nutzen dabei mathematische Regeln und sachlogische Argumente', NULL),
(13, @ma_id, 'ARG6',  'Argumente verknüpfen', 'verknüpfen Argumente zu Argumentationsketten', NULL),
(13, @ma_id, 'ARG7',  'Argumentationsstrategien nutzen', 'nutzen verschiedene Argumentationsstrategien (Gegenbeispiel, direktes Schlussfolgern, Widerspruch)', NULL),
(13, @ma_id, 'ARG8',  'Beweisstruktur erläutern', 'erläutern Argumentationen und Beweise hinsichtlich ihrer logischen Struktur', NULL),
(13, @ma_id, 'ARG9',  'Argumentationsketten beurteilen', 'beurteilen, ob Argumentationsketten vollständig und fehlerfrei sind', NULL),
(13, @ma_id, 'ARG10', 'Argumentationen verbessern', 'ergänzen lückenhafte und korrigieren fehlerhafte Argumentationsketten', NULL),
-- KOMMUNIZIEREN
(14, @ma_id, 'KOM1',  'Informationen entnehmen', 'entnehmen und strukturieren Informationen aus mathematikhaltigen Texten und Darstellungen', NULL),
(14, @ma_id, 'KOM2',  'Informationen recherchieren', 'recherchieren und bewerten fachbezogene Informationen', NULL),
(14, @ma_id, 'KOM3',  'Begriffsinhalte erläutern', 'erläutern Begriffsinhalte anhand von Anwendungssituationen', NULL),
(14, @ma_id, 'KOM4',  'Lösungswege wiedergeben', 'geben Lösungswege und Verfahren mit eigenen Worten und Fachbegriffen wieder', NULL),
(14, @ma_id, 'KOM5',  'Denkprozesse verbalisieren', 'verbalisieren eigene Denkprozesse und beschreiben Lösungswege', NULL),
(14, @ma_id, 'KOM6',  'Fachsprache verwenden', 'verwenden in angemessenem Umfang die fachgebundene Sprache', NULL),
(14, @ma_id, 'KOM7',  'Darstellungsformen wählen', 'wählen je nach Situation und Zweck geeignete Darstellungsformen', NULL),
(14, @ma_id, 'KOM8',  'Arbeitsschritte dokumentieren', 'dokumentieren Arbeitsschritte nachvollziehbar und präsentieren diese', NULL),
(14, @ma_id, 'KOM9',  'Beiträge aufgreifen', 'greifen Beiträge auf und entwickeln sie weiter', NULL),
(14, @ma_id, 'KOM10', 'Ausarbeitungen beurteilen', 'vergleichen und beurteilen Ausarbeitungen hinsichtlich fachlicher Richtigkeit', NULL),
(14, @ma_id, 'KOM11', 'Entscheidungen herbeiführen', 'führen Entscheidungen auf der Grundlage fachbezogener Diskussionen herbei', NULL),

-- INHALTSBEZOGEN: Erprobungsstufe Jg. 5/6
(20, @ma_id, 'E_ARI1',  'Primzahlen und Primfaktorzerlegung', 'erläutern Eigenschaften von Primzahlen, zerlegen natürliche Zahlen in Primfaktoren', '5/6'),
(20, @ma_id, 'E_ARI2',  'Teiler und Teilbarkeitsregeln', 'bestimmen Teiler, wenden Teilbarkeitsregeln an', '5/6'),
(20, @ma_id, 'E_ARI3',  'Vorteilhaft rechnen mit Rechengesetzen', 'begründen Strategien zum vorteilhaften Rechnen', '5/6'),
(20, @ma_id, 'E_ARI4',  'Rechenterme verbalisieren', 'verbalisieren Rechenterme und übersetzen Sachsituationen', '5/6'),
(20, @ma_id, 'E_ARI8',  'Zahlen unterschiedlich darstellen', 'stellen Zahlen auf unterschiedlichen Weisen dar und vergleichen sie', '5/6'),
(20, @ma_id, 'E_ARI11', 'Brüche deuten', 'deuten Brüche als Anteile, Operatoren, Quotienten, Zahlen und Verhältnisse', '5/6'),
(20, @ma_id, 'E_ARI14', 'Grundrechenarten ausführen', 'führen Grundrechenarten schriftlich und im Kopf durch', '5/6'),
(21, @ma_id, 'E_FKT1',  'Zusammenhänge beschreiben', 'beschreiben den Zusammenhang zwischen zwei Größen mit Worten, Diagrammen und Tabellen', '5/6'),
(21, @ma_id, 'E_FKT2',  'Dreisatz anwenden', 'wenden das Dreisatzverfahren zur Lösung von Sachproblemen an', '5/6'),
(22, @ma_id, 'E_GEO1',  'Grundbegriffe für Figuren und Körper', 'erläutern Grundbegriffe und beschreiben ebene Figuren und Körper', '5/6'),
(22, @ma_id, 'E_GEO5',  'Symmetrische Figuren erzeugen', 'erzeugen symmetrische Figuren und ermitteln Symmetrieachsen', '5/6'),
(22, @ma_id, 'E_GEO12', 'Umfang und Flächeninhalt berechnen', 'berechnen Umfang, Flächeninhalt und Volumen einfacher Figuren und Körper', '5/6'),
(23, @ma_id, 'E_STO1',  'Daten erheben und zusammenfassen', 'erheben Daten und fassen sie in Listen zusammen', '5/6'),
(23, @ma_id, 'E_STO2',  'Häufigkeiten darstellen', 'stellen Häufigkeiten in Tabellen und Diagrammen dar', '5/6'),

-- INHALTSBEZOGEN: Erste Stufe Jg. 7/8
(30, @ma_id, 'S1_ARI1',  'Rationale Zahlen darstellen', 'stellen rationale Zahlen auf der Zahlengeraden dar und ordnen sie', '7/8'),
(30, @ma_id, 'S1_ARI4',  'Variablen in verschiedenen Rollen', 'deuten Variablen als Veränderliche, Platzhalter und Unbekannte', '7/8'),
(30, @ma_id, 'S1_ARI7',  'Terme und Bruchterme umformen', 'formen Terme, auch Bruchterme, zielgerichtet um', '7/8'),
(30, @ma_id, 'S1_ARI9',  'Lineare Gleichungen lösen', 'ermitteln Lösungsmengen linearer Gleichungen und Gleichungssysteme', '7/8'),
(31, @ma_id, 'S1_FKT3',  'Funktionen charakterisieren', 'charakterisieren Funktionen als Klasse eindeutiger Zuordnungen', '7/8'),
(31, @ma_id, 'S1_FKT4',  'Funktionen in Darstellungen', 'stellen Funktionen in verschiedenen Darstellungen dar und nutzen sie', '7/8'),
(31, @ma_id, 'S1_FKT8',  'Prozent- und Zinsrechnung', 'wenden Prozent- und Zinsrechnung auf Konsumsituationen an', '7/8'),
(32, @ma_id, 'S1_GEO1',  'Geometrische Sätze zur Winkelbestimmung', 'nutzen geometrische Sätze zur Winkelbestimmung', '7/8'),
(32, @ma_id, 'S1_GEO3',  'Konstruktionen durchführen', 'führen Konstruktionen mit Zirkel und Lineal durch', '7/8'),
(33, @ma_id, 'S1_STO2',  'Zufallsexperimente mit Baumdiagrammen', 'stellen Zufallsexperimente mit Baumdiagrammen dar', '7/8'),

-- INHALTSBEZOGEN: Zweite Stufe Jg. 9/10
(40, @ma_id, 'S2_ARI1',  'Zehnerpotenzschreibweise', 'stellen Zahlen in Zehnerpotenzschreibweise dar', '9/10'),
(40, @ma_id, 'S2_ARI5',  'Wurzel- und Potenzschreibweise', 'wechseln zwischen Wurzel- und Potenzschreibweise', '9/10'),
(40, @ma_id, 'S2_ARI8',  'Quadratische Gleichungen lösen', 'wählen Verfahren zum Lösen quadratischer Gleichungen und bestimmen die Lösungsmenge', '9/10'),
(40, @ma_id, 'S2_ARI10', 'Exponentialgleichungen lösen', 'lösen Exponentialgleichungen durch Probieren, Logarithmieren und digitale Werkzeuge', '9/10'),
(41, @ma_id, 'S2_FKT3',  'Funktionsklassen charakterisieren', 'charakterisieren Funktionsklassen und grenzen diese ab', '9/10'),
(41, @ma_id, 'S2_FKT10', 'Modelle für Wachstumsprozesse', 'wählen begründet Modelle zur Beschreibung von Wachstumsprozessen', '9/10'),
(41, @ma_id, 'S2_FKT13', 'Sinus- und Kosinusfunktion', 'erläutern Sinus- und Kosinusfunktion am Einheitskreis', '9/10'),
(42, @ma_id, 'S2_GEO1',  'Satz des Pythagoras beweisen', 'beweisen den Satz des Pythagoras', '9/10'),
(42, @ma_id, 'S2_GEO5',  'Oberflächen und Volumen berechnen', 'berechnen Oberfläche und Volumen von Körpern und Teilkörpern', '9/10'),
(42, @ma_id, 'S2_GEO9',  'Größen mit Trigonometrie berechnen', 'berechnen Größen mithilfe von Ähnlichkeit und trigonometrischen Beziehungen', '9/10'),
(43, @ma_id, 'S2_STO2',  'Grafiken kritisch analysieren', 'analysieren grafische Darstellungen kritisch und erkennen Manipulationen', '9/10'),
(43, @ma_id, 'S2_STO5',  'Wahrscheinlichkeiten berechnen', 'berechnen Wahrscheinlichkeiten mit Baumdiagramm und Vierfeldertafel', '9/10');
