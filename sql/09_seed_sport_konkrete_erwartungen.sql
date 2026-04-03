-- SQL: Fehlende konkrete Kompetenzerwartungen für Sport KLP
-- Generiert aus SPO_KLP_LOGINEO_UTF8_BOM_mit_Kompetenzerwartungen.csv

START TRANSACTION;

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_001',
    'unterschiedliche Körperempfindungen und Körperwahrnehmungen in vielfältigen Bewegungssituationen beschreiben',
    'unterschiedliche Körperempfindungen und Körperwahrnehmungen in vielfältigen Bewegungssituationen beschreiben',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_A_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_001');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_002',
    'wesentliche Bewegungsmerkmale einfacher Bewegungsabläufe benennen',
    'wesentliche Bewegungsmerkmale einfacher Bewegungsabläufe benennen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_A_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_002');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_003',
    'mediengestützte Bewegungsbeobachtungen zur kriteriengeleiteten Rückmeldung auf grundlegendem Niveau nutzen',
    'mediengestützte Bewegungsbeobachtungen zur kriteriengeleiteten Rückmeldung auf grundlegendem Niveau nutzen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_A_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_003');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_004',
    'einfache Hilfen (Hilfestellungen, Geländehilfen, Visualisierungen, akustische Signale) beim Erlernen und Üben sportlicher Bewegungen verwenden',
    'einfache Hilfen (Hilfestellungen, Geländehilfen, Visualisierungen, akustische Signale) beim Erlernen und Üben sportlicher Bewegungen verwenden',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_A_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_004');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_005',
    'einfache Bewegungsabläufe hinsichtlich der Bewegungsqualität auf grundlegendem Niveau kriteriengeleitet beurteilen',
    'einfache Bewegungsabläufe hinsichtlich der Bewegungsqualität auf grundlegendem Niveau kriteriengeleitet beurteilen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_A_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_005');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_006',
    'Grundformen gestalterischen Bewegens (in zwei Bewegungsfeldern) benennen',
    'Grundformen gestalterischen Bewegens (in zwei Bewegungsfeldern) benennen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_B_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_006');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_007',
    'grundlegende Aufstellungsformen und Formationen benennen',
    'grundlegende Aufstellungsformen und Formationen benennen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_B_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_007');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_008',
    'Grundformen gestalterischen Bewegens nach- und umgestalten',
    'Grundformen gestalterischen Bewegens nach- und umgestalten',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_B_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_008');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_009',
    'einfache kreative Bewegungsgestaltungen entwickeln und zu einer Präsentation verbinden',
    'einfache kreative Bewegungsgestaltungen entwickeln und zu einer Präsentation verbinden',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_B_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_009');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_010',
    'kreative, gestalterische Präsentationen anhand grundlegender Kriterien beurteilen',
    'kreative, gestalterische Präsentationen anhand grundlegender Kriterien beurteilen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_B_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_010');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_011',
    'die Herausforderungen in einfachen sportlichen Handlungssituationen im Hinblick auf die Anforderung, das eigene Können und mögliche Gefahren beschreiben',
    'die Herausforderungen in einfachen sportlichen Handlungssituationen im Hinblick auf die Anforderung, das eigene Können und mögliche Gefahren beschreiben',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_C_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_011');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_012',
    'verlässlich verbale und nonverbale Unterstützung bei sportlichen Handlungssituationen geben und gezielt nutzen',
    'verlässlich verbale und nonverbale Unterstützung bei sportlichen Handlungssituationen geben und gezielt nutzen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_C_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_012');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_013',
    'einfache sportliche Wagnissituationen für sich situativ einschätzen und anhand ausgewählter Kriterien beurteilen',
    'einfache sportliche Wagnissituationen für sich situativ einschätzen und anhand ausgewählter Kriterien beurteilen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_C_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_013');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_014',
    'die motorischen Grundfähigkeiten (Kraft, Schnelligkeit, Ausdauer, Beweglichkeit) in unterschiedlichen Anforderungssituationen benennen',
    'die motorischen Grundfähigkeiten (Kraft, Schnelligkeit, Ausdauer, Beweglichkeit) in unterschiedlichen Anforderungssituationen benennen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_D_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_014');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_015',
    'psycho-physische Leistungsfaktoren (u.a. Anstrengungsbereitschaft, Konzentrationsfähigkeit) in unterschiedlichen Anforderungssituationen benennen',
    'psycho-physische Leistungsfaktoren (u.a. Anstrengungsbereitschaft, Konzentrationsfähigkeit) in unterschiedlichen Anforderungssituationen benennen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_D_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_015');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_016',
    'psycho-physische Reaktionen des Körpers in sportlichen Anforderungssituationen beschreiben',
    'psycho-physische Reaktionen des Körpers in sportlichen Anforderungssituationen beschreiben',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_D_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_016');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_017',
    'einfache Methoden zur Erfassung von körperlicher Leistungsfähigkeit anwenden',
    'einfache Methoden zur Erfassung von körperlicher Leistungsfähigkeit anwenden',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_D_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_017');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_018',
    'ihre individuelle Leistungsfähigkeit in unterschiedlichen sportbezogenen Situationen anhand ausgewählter Kriterien auf grundlegendem Niveau beurteilen',
    'ihre individuelle Leistungsfähigkeit in unterschiedlichen sportbezogenen Situationen anhand ausgewählter Kriterien auf grundlegendem Niveau beurteilen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_D_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_018');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_019',
    'Merkmale für faires, kooperatives und teamorientiertes sportliches Handeln benennen',
    'Merkmale für faires, kooperatives und teamorientiertes sportliches Handeln benennen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_E_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_019');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_020',
    'sportartspezifische Vereinbarungen, Regeln und Messverfahren in unterschiedlichen Bewegungsfeldern beschreiben',
    'sportartspezifische Vereinbarungen, Regeln und Messverfahren in unterschiedlichen Bewegungsfeldern beschreiben',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_E_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_020');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_021',
    'selbstständig und verantwortungsvoll Spielflächen und -geräte gemeinsam auf- und abbauen',
    'selbstständig und verantwortungsvoll Spielflächen und -geräte gemeinsam auf- und abbauen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_E_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_021');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_022',
    'in sportlichen Handlungssituationen grundlegende, bewegungsfeldspezifische Vereinbarungen und Regeln dokumentieren',
    'in sportlichen Handlungssituationen grundlegende, bewegungsfeldspezifische Vereinbarungen und Regeln dokumentieren',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_E_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_022');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_023',
    'sportliche Handlungs- und Spielsituationen hinsichtlich ausgewählter Aspekte (u.a. Einhaltung von Regeln und Vereinbarungen, Fairness im Mit- und Gegeneinander) auf grundlegendem Niveau bewerten',
    'sportliche Handlungs- und Spielsituationen hinsichtlich ausgewählter Aspekte (u.a. Einhaltung von Regeln und Vereinbarungen, Fairness im Mit- und Gegeneinander) auf grundlegendem Niveau bewerten',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_E_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_023');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_024',
    'grundlegende sportartspezifische Gefahrenmomente sowie Organisations- und Sicherheitsvereinbarungen für das sichere sportliche Handeln benennen',
    'grundlegende sportartspezifische Gefahrenmomente sowie Organisations- und Sicherheitsvereinbarungen für das sichere sportliche Handeln benennen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_F_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_024');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_025',
    'Merkmale einer sachgerechten Vorbereitung auf sportliches Bewegen (u.a. allgemeines Aufwärmen, Kleidung) benennen',
    'Merkmale einer sachgerechten Vorbereitung auf sportliches Bewegen (u.a. allgemeines Aufwärmen, Kleidung) benennen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_F_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_025');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_026',
    'Spiel-, Übungs- und Wettkampfstätten situationsangemessen und sicherheitsbewusst nutzen',
    'Spiel-, Übungs- und Wettkampfstätten situationsangemessen und sicherheitsbewusst nutzen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_F_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_026');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_EP_027',
    'körperliche Anstrengung anhand der Reaktionen des eigenen Körpers auf grundlegendem Niveau gesundheitsorientiert beurteilen',
    'körperliche Anstrengung anhand der Reaktionen des eigenen Körpers auf grundlegendem Niveau gesundheitsorientiert beurteilen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_EP_IF_F_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_EP_027');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_001',
    'die für das Lernen und Üben ausgewählter Bewegungsabläufe bedeutsamen Körperempfindungen und Körperwahrnehmungen beschreiben',
    'die für das Lernen und Üben ausgewählter Bewegungsabläufe bedeutsamen Körperempfindungen und Körperwahrnehmungen beschreiben',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_A_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_001');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_002',
    'für ausgewählte Bewegungstechniken die relevanten Bewegungsmerkmale benennen und einfache grundlegende Zusammenhänge von Aktionen und Effekten erläutern',
    'für ausgewählte Bewegungstechniken die relevanten Bewegungsmerkmale benennen und einfache grundlegende Zusammenhänge von Aktionen und Effekten erläutern',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_A_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_002');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_003',
    'grundlegende methodische Prinzipien auf das Lernen und Üben sportlicher Bewegungen anwenden',
    'grundlegende methodische Prinzipien auf das Lernen und Üben sportlicher Bewegungen anwenden',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_A_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_003');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_004',
    'analoge und digitale Medien zur Bewegungsanalyse und Unterstützung motorischer Lern- und Übungsprozesse zielorientiert einsetzen',
    'analoge und digitale Medien zur Bewegungsanalyse und Unterstützung motorischer Lern- und Übungsprozesse zielorientiert einsetzen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_A_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_004');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_005',
    'unterschiedliche Hilfen beim Erlernen und Verbessern sportlicher Bewegungen auswählen und verwenden',
    'unterschiedliche Hilfen beim Erlernen und Verbessern sportlicher Bewegungen auswählen und verwenden',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_A_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_005');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_006',
    'Bewegungsabläufe kriteriengeleitet beurteilen',
    'Bewegungsabläufe kriteriengeleitet beurteilen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_A_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_006');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_007',
    'den Nutzen analoger und digitaler Medien zur Analyse und Unterstützung motorischer Lern- und Übungsprozesse vergleichend beurteilen',
    'den Nutzen analoger und digitaler Medien zur Analyse und Unterstützung motorischer Lern- und Übungsprozesse vergleichend beurteilen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_A_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_007');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_008',
    'den Einsatz unterschiedlicher Hilfen beim Erlernen und Verbessern sportlicher Bewegungen kriteriengeleitet bewerten',
    'den Einsatz unterschiedlicher Hilfen beim Erlernen und Verbessern sportlicher Bewegungen kriteriengeleitet bewerten',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_A_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_008');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_009',
    'ausgewählte Ausführungskriterien (Bewegungsqualität, Synchronität, Ausdruck und Körperspannung) benennen',
    'ausgewählte Ausführungskriterien (Bewegungsqualität, Synchronität, Ausdruck und Körperspannung) benennen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_B_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_009');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_010',
    'das Gestaltungskriterium Raum beschreiben',
    'das Gestaltungskriterium Raum beschreiben',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_B_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_010');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_011',
    'unterschiedliche Ausgangspunkte als Anlass für Gestaltungen nutzen',
    'unterschiedliche Ausgangspunkte als Anlass für Gestaltungen nutzen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_B_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_011');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_012',
    'Bewegungsgestaltungen allein oder in der Gruppe auch mit Hilfe digitaler Medien nach-, um- und neugestalten',
    'Bewegungsgestaltungen allein oder in der Gruppe auch mit Hilfe digitaler Medien nach-, um- und neugestalten',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_B_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_012');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_013',
    'kreative Bewegungsgestaltungen entwickeln und zu einer Präsentation verbinden',
    'kreative Bewegungsgestaltungen entwickeln und zu einer Präsentation verbinden',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_B_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_013');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_014',
    'die Ausführungs- und Bewegungsqualität bei sich und anderen nach vorgegebenen Kriterien beurteilen',
    'die Ausführungs- und Bewegungsqualität bei sich und anderen nach vorgegebenen Kriterien beurteilen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_B_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_014');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_015',
    'gestalterische Präsentationen auch unter Verwendung digitaler Medien kriteriengeleitet beurteilen',
    'gestalterische Präsentationen auch unter Verwendung digitaler Medien kriteriengeleitet beurteilen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_B_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_015');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_016',
    'unterschiedliche Motive sportlichen Handelns in Wagnissituationen erläutern',
    'unterschiedliche Motive sportlichen Handelns in Wagnissituationen erläutern',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_C_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_016');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_017',
    'emotionale Signale in sportlichen Wagnissituationen beschreiben',
    'emotionale Signale in sportlichen Wagnissituationen beschreiben',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_C_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_017');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_018',
    'die Herausforderungen in sportlichen Handlungssituationen im Hinblick auf die Anforderung, das eigene Können und mögliche Gefahren erläutern',
    'die Herausforderungen in sportlichen Handlungssituationen im Hinblick auf die Anforderung, das eigene Können und mögliche Gefahren erläutern',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_C_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_018');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_019',
    'Strategien zum Umgang mit Emotionen in sportlichen Wagnissituationen anwenden',
    'Strategien zum Umgang mit Emotionen in sportlichen Wagnissituationen anwenden',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_C_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_019');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_020',
    'Herausforderungen in sportlichen Handlungssituationen angepasst an das individuelle motorische Können gezielt verändern',
    'Herausforderungen in sportlichen Handlungssituationen angepasst an das individuelle motorische Können gezielt verändern',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_C_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_020');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_021',
    'komplexe sportliche Wagnissituationen für sich und andere unter Berücksichtigung des eigenen Könnens und möglicher Gefahrenmomente situativ beurteilen und sich begründet für oder gegen deren Bewältigung entscheiden',
    'komplexe sportliche Wagnissituationen für sich und andere unter Berücksichtigung des eigenen Könnens und möglicher Gefahrenmomente situativ beurteilen und sich begründet für oder gegen deren Bewältigung entscheiden',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_C_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_021');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_022',
    'grundlegende Methoden und Prinzipien zur Verbesserung motorischer Grundfähigkeiten (Ausdauer und Kraft) beschreiben',
    'grundlegende Methoden und Prinzipien zur Verbesserung motorischer Grundfähigkeiten (Ausdauer und Kraft) beschreiben',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_D_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_022');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_023',
    'ausgewählte Belastungsgrößen zur Gestaltung eines Trainings auf grundlegendem Niveau erläutern',
    'ausgewählte Belastungsgrößen zur Gestaltung eines Trainings auf grundlegendem Niveau erläutern',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_D_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_023');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_024',
    'koordinative Anforderungen von Bewegungsaufgaben benennen',
    'koordinative Anforderungen von Bewegungsaufgaben benennen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_D_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_024');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_025',
    'einen individualisierten Trainingsplan aus vorgegebenen Einzelelementen zur Verbesserung einer ausgewählten motorischen Grundfähigkeit zusammenstellen',
    'einen individualisierten Trainingsplan aus vorgegebenen Einzelelementen zur Verbesserung einer ausgewählten motorischen Grundfähigkeit zusammenstellen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_D_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_025');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_026',
    'sportliche Leistungen analog oder digital erfassen und anhand von graphischen Darstellungen und/oder Diagrammen dokumentieren',
    'sportliche Leistungen analog oder digital erfassen und anhand von graphischen Darstellungen und/oder Diagrammen dokumentieren',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_D_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_026');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_027',
    'die eigene und die Leistungsfähigkeit anderer in unterschiedlichen Sport- und Wettkampfsituationen unter Berücksichtigung individueller Voraussetzungen kriteriengeleitet beurteilen',
    'die eigene und die Leistungsfähigkeit anderer in unterschiedlichen Sport- und Wettkampfsituationen unter Berücksichtigung individueller Voraussetzungen kriteriengeleitet beurteilen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_D_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_027');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_028',
    'den Leistungsbegriff in unterschiedlichen sportlichen Handlungssituationen kritisch reflektieren',
    'den Leistungsbegriff in unterschiedlichen sportlichen Handlungssituationen kritisch reflektieren',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_D_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_028');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_029',
    'Kennzeichen für ein grundlegendes Wettkampfverhalten erläutern',
    'Kennzeichen für ein grundlegendes Wettkampfverhalten erläutern',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_E_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_029');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_030',
    'Rahmenbedingungen, Strukturmerkmale, Vereinbarungen und Regeln unterschiedlicher Spiele oder Wettkampfsituationen kriteriengeleitet in ihrer Notwendigkeit und Funktion für das Gelingen sportlicher Handlungen erläutern',
    'Rahmenbedingungen, Strukturmerkmale, Vereinbarungen und Regeln unterschiedlicher Spiele oder Wettkampfsituationen kriteriengeleitet in ihrer Notwendigkeit und Funktion für das Gelingen sportlicher Handlungen erläutern',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_E_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_030');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_031',
    'Vereinbarungen und Regeln für ein faires und gelingendes sportliches Handeln analysieren und kriteriengeleitet modifizieren',
    'Vereinbarungen und Regeln für ein faires und gelingendes sportliches Handeln analysieren und kriteriengeleitet modifizieren',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_E_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_031');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_032',
    'einfache analoge und digitale Darstellungen zur Erläuterung von sportlichen Handlungssituationen verwenden',
    'einfache analoge und digitale Darstellungen zur Erläuterung von sportlichen Handlungssituationen verwenden',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_E_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_032');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_033',
    'in sportlichen Handlungssituationen unter Verwendung der vereinbarten Zeichen und Signale Schiedsrichterfunktionen übernehmen',
    'in sportlichen Handlungssituationen unter Verwendung der vereinbarten Zeichen und Signale Schiedsrichterfunktionen übernehmen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_E_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_033');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_034',
    'das eigene sportliche Handeln sowie das sportliche Handeln anderer kriteriengeleitet im Hinblick auf ausgewählte Aspekte beurteilen',
    'das eigene sportliche Handeln sowie das sportliche Handeln anderer kriteriengeleitet im Hinblick auf ausgewählte Aspekte beurteilen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_E_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_034');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_035',
    'Auswirkungen gezielten Sporttreibens auf die Gesundheit grundlegend beschreiben',
    'Auswirkungen gezielten Sporttreibens auf die Gesundheit grundlegend beschreiben',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_F_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_035');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_036',
    'Prinzipien einer sachgerechten allgemeinen und sportartspezifischen Vorbereitung auf sportliches Bewegen erläutern',
    'Prinzipien einer sachgerechten allgemeinen und sportartspezifischen Vorbereitung auf sportliches Bewegen erläutern',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_F_SK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_036');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_037',
    'die Rahmenbedingungen und Gegebenheiten von Spiel-, Übungs- und Wettkampfsituationen analysieren und diese sicherheitsbewusst gestalten',
    'die Rahmenbedingungen und Gegebenheiten von Spiel-, Übungs- und Wettkampfsituationen analysieren und diese sicherheitsbewusst gestalten',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_F_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_037');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_038',
    'Muster des eigenen Bewegungsverhaltens auch unter Nutzung digitaler Medien erfassen und im Hinblick auf den gesundheitlichen Nutzen und mögliche Risiken analysieren',
    'Muster des eigenen Bewegungsverhaltens auch unter Nutzung digitaler Medien erfassen und im Hinblick auf den gesundheitlichen Nutzen und mögliche Risiken analysieren',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_F_MK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_038');

INSERT IGNORE INTO kompetenzen (code, kurzname, beschreibung, bereich_id, eltern_kompetenz_id, fach_id, schule_id, aktiv)
SELECT 
    'SPO_SI_039',
    'gesundheitliche Auswirkungen sportlichen Handelns unter besonderer Berücksichtigung medial vermittelter Fitnesstrends und Körperideale auch unter Geschlechteraspekten kritisch beurteilen',
    'gesundheitliche Auswirkungen sportlichen Handelns unter besonderer Berücksichtigung medial vermittelter Fitnesstrends und Körperideale auch unter Geschlechteraspekten kritisch beurteilen',
    eltern.bereich_id,
    eltern.id,
    eltern.fach_id,
    eltern.schule_id,
    1
FROM kompetenzen eltern
WHERE eltern.code = 'SPO_SI_IF_F_UK'
  AND NOT EXISTS (SELECT 1 FROM kompetenzen WHERE code = 'SPO_SI_039');

COMMIT;

-- Prüfabfrage:
-- SELECT COUNT(*) FROM kompetenzen WHERE code LIKE 'SPO_EP_%' OR code LIKE 'SPO_SI_%';