-- =============================================================================
-- Migration 24: Aufräumen nach der Abnahme von Auftrag A (E68)
-- =============================================================================
-- Einspielen:  mariadb hornse_projektstunden < sql/24_aufraeumen_nach_abnahme.sql
-- ERST NACH DER ABNAHME, wenn der neue Code läuft (Ausrollanleitung). Der Code
-- seit Auftrag A schreibt weder in webuntis_login_log noch ip_adresse; er
-- läuft vor und nach dieser Datei (tests/fristen_db_test.sh, vor24/nach24).
-- Zweimal einspielen ist unschädlich (IF EXISTS).
--
-- webuntis_login_log entfällt OHNE Übernahme: Nichts liest sie, ihre Frist
-- war 30 Tage, und sie hält IP-Adressen. Der Verlauf steht seit sql/23 in
-- anmeldeverlauf, ohne Adresse.
--
-- audit_log.ip_adresse entfällt: Hinter dem Proxy war REMOTE_ADDR der Proxy
-- (FALLSTRICKE 1), und das Protokoll braucht keine Adresse.
--
-- SPDX-License-Identifier: GPL-3.0-or-later
-- =============================================================================

DROP TABLE IF EXISTS webuntis_login_log;

ALTER TABLE audit_log DROP COLUMN IF EXISTS ip_adresse;
