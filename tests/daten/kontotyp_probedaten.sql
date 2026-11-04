-- Probebestand für tests/kontotyp_db_test.sh
-- ERFUNDEN: alle Namen, Nummern, Adressen. Keine echte Person. Kennungen
-- bewusst nicht bei 0/1 (REIHENREGELN 2). Dieselbe Form wie im Beleg vom
-- 04.11.2026 (koordination docs/berichte/2026-11-04-bericht-projektstunden-kontotyp.md).
--
-- Der Kern: Schüler 57 und Lehrkraft 57 teilen die Nummer (Z2). Schüler 57
-- nimmt an keiner Werkstatt teil; Werkstatt 71 gehört Lehrkraft 57.
-- @@HASH@@ ersetzt das Testskript durch password_hash() eines Probepassworts.

INSERT INTO schuljahre (id, schule_id, name, beginn, ende, status) VALUES (13, 1, 'Probejahr', '2031-08-01', '2032-07-31', 'aktiv');
INSERT INTO klassen (id, schule_id, bezeichnung, jahrgang, schuljahr, schuljahr_id) VALUES
 (41, 1, 'P5A', 5, '2031/2032', 13), (42, 1, 'P6B', 6, '2031/2032', 13);
INSERT INTO schueler (id, schild_id, klasse_id, vorname, nachname, aktiv) VALUES
 (57, 9057, 41, 'Probe', 'Gleichnummer', 1),
 (101, 9101, 41, 'Probe', 'EinsA', 1), (102, 9102, 41, 'Probe', 'ZweiA', 1),
 (103, 9103, 42, 'Probe', 'DreiB', 1), (104, 9104, 42, 'Probe', 'VierB', 1),
 (105, 9105, 42, 'Probe', 'FuenfB', 1);
INSERT INTO benutzer (id, schule_id, vorname, nachname, email, passwort_hash, rolle, kuerzel, aktiv) VALUES
 (57, 1, 'Probe', 'Lernbegleitung', 'lb57@probe.invalid', '@@HASH@@', 'lehrer', 'PLB', 1),
 (58, 1, 'Probe', 'Andere', 'lb58@probe.invalid', '@@HASH@@', 'lehrer', 'PAN', 1);
INSERT INTO projekte (id, schule_id, schuljahr_id, klasse_id, lehrer_id, name, datum_von, status) VALUES
 (71, 1, 13, 41, 57, 'Probewerkstatt LB57', '2031-09-01', 'aktiv'),
 (72, 1, 13, 42, 58, 'Probewerkstatt LB58', '2031-09-01', 'aktiv');
INSERT INTO projekt_klassen (projekt_id, klasse_id) VALUES (71, 41), (72, 42);
INSERT INTO projekt_lehrer (projekt_id, benutzer_id, rolle) VALUES (71, 57, 'leitung'), (72, 58, 'leitung');
INSERT INTO projekt_schueler (projekt_id, schueler_id) VALUES (71, 101), (71, 102), (72, 103);
INSERT INTO projekt_schueler_kompetenzen (projekt_id, schueler_id, kompetenz_id)
 SELECT 71, 101, MIN(id) FROM kompetenzen;
INSERT INTO werkstatt_rueckmeldungen (projekt_id, schueler_id, erstellt_von, bewertung_stufe, freitext, sichtbar) VALUES
 (71, 101, 57, 3, 'Probetext eins', 0), (71, 102, 57, 2, 'Probetext zwei', 0);
