-- =============================================================================
-- Migration 23: Verlauf der Anmeldungen – ohne Adresse (Auftrag A, E68)
-- =============================================================================
-- Einspielen:  mariadb hornse_projektstunden < sql/23_migration_anmeldeverlauf.sql
-- Zweimal einspielen ist unschädlich (IF NOT EXISTS).
--
-- Projekteigen, nach dem Vorbild von kurse (sql/05_anmeldeverlauf.sql, E82
-- dort). Der Verlauf ist PROTOKOLL und entscheidet über nichts – die Bremse
-- zählt in ihrer eigenen Tabelle (sql/22_anmeldebremse.sql, aus dem Modul).
-- Er beantwortet „warum komme ich nicht hinein“: Die Ablehnung ist nach außen
-- einheitlich (FALLSTRICKE 8), der Grund steht nur hier.
--
-- KEINE SPALTE FÜR EINE ADRESSE. Hinter dem Proxy stand in webuntis_login_log.ip
-- immer derselbe Wert (FALLSTRICKE 1, koordination M53); die Bremse braucht
-- keine (Personendaten L3). webuntis_login_log entfällt nach der Abnahme von
-- Auftrag A (sql/24).
--
-- zeitpunkt setzt die Anwendung aus ihrer Uhr, nicht die Datenbank: Die Frist
-- (Paket 3) vergleicht mit derselben Uhr (FALLSTRICKE 4).
--
-- Passwörter und Sitzungskennungen stehen hier nicht und dürfen es nie.
-- =============================================================================

CREATE TABLE IF NOT EXISTS anmeldeverlauf (
    id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    benutzername VARCHAR(190) NOT NULL COMMENT 'wie eingegeben: Kürzel oder E-Mail',
    ziel         VARCHAR(100) NOT NULL DEFAULT '' COMMENT 'lokal oder webuntis:<Host>',
    erfolgreich  TINYINT(1)   NOT NULL DEFAULT 0,
    grund        VARCHAR(50)  NULL     COMMENT 'siehe handle_auth; NULL bei Erfolg über WebUntis',
    zeitpunkt    DATETIME     NOT NULL,
    INDEX idx_anmeldeverlauf_zeitpunkt (zeitpunkt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Anmeldeversuche – Protokoll, keine Entscheidung (E68)';
