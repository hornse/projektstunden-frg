<?php
/**
 * Projektstunden NRW – Filter nach Kontotyp
 * ============================================================
 * Datei: backend/api/kontotyp.php, eingebunden von backend/api/index.php
 *
 * Anlass: Befund Z1 (koordination docs/BEFUND-2026-11-04-personendaten.md
 * §10), am 04.11.2026 in einer Probe belegt: Eine Schülersitzung erreichte
 * jede Route der Lehrkräfte – Schülerliste aller Klassen, Konten der
 * Lehrkräfte, Dashboard, Export, Anlegen und Inaktivieren von Schülern.
 * require_auth() prüfte nur, dass benutzer_id gesetzt ist.
 *
 * Eine ENGSTELLE statt einer Prüfung je Handler (REIHENREGELN 1): Der
 * Verteiler fragt vor dem match, und alles, was nicht auf der Liste steht,
 * ist für eine Sitzung, die nicht nachweislich eine Lehrkraft ist, zu.
 * Eine ERLAUBNISLISTE, keine Sperrliste: Eine neue Route ist für Schüler
 * gesperrt, bis jemand sie hier freigibt.
 *
 * Warum hier und nicht in require_auth(): require_auth() steht in
 * backend/config.php. Die ist nicht versioniert und wird beim Deploy nicht
 * überschrieben – eine Änderung dort käme nie auf den Server.
 *
 * Die Liste wird gegen eine eigene ERWARTUNG gemessen
 * (tests/daten/kontotyp_erlaubt.json, tests/kontotyp_test.php K6). Wer hier
 * etwas freigibt, trägt es dort mit Beleg aus dem Frontend ein.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

// Eigener Satz: Die Gegenproben müssen den Filter von den 403 der Handler
// unterscheiden können (REIHENREGELN 2, „Stufen melden sich unterschiedlich“).
const KONTOTYP_SATZ_FILTER = 'Für Schülerkonten nicht freigegeben.';

/**
 * Darf eine Sitzung, die keine Lehrkraft ist, diese Route erreichen?
 * Belegt aus der Schüleransicht (frontend/app.js, index.html):
 *   auth                 alle Methoden – Anmelden, Abmelden, auth/me
 *   schueler-portal      GET           – eigene Werkstätten, Detail
 *   selbsteinschaetzung  PUT           – Selbsteinschätzung
 *   einstellungen        GET logo      – Logo der Anmeldemaske (öffentlich)
 */
function schueler_route_erlaubt(string $method, string $route, string $sub): bool
{
    return match ($route) {
        'auth'                => true,
        'schueler-portal'     => $method === 'GET',
        'selbsteinschaetzung' => $method === 'PUT',
        'einstellungen'       => $method === 'GET' && $sub === 'logo',
        default               => false,
    };
}

/**
 * Wird diese Anfrage gefiltert? Ja, wenn eine Sitzung mit benutzer_id
 * besteht und ihr typ nicht GENAU 'benutzer' ist – auch ein fehlender typ.
 * Das ist dieselbe Erlaubnislogik eine Ebene höher: Ein Kontotyp, den es
 * künftig gibt oder der fehlt, ist zu, bis jemand ihn freigibt.
 * require_auth() ergänzt einen fehlenden typ zu 'benutzer'; diese
 * Großzügigkeit erbt der Filter nicht.
 *
 * Eine Sitzung wird nur gestartet, wenn das Cookie da ist: Sonst bekäme jeder
 * anonyme Abruf des Anmeldelogos eine Sitzung samt Cookie.
 */
function kontotyp_gefiltert(): bool
{
    if (!isset($_COOKIE[SESSION_NAME])) return false;
    session_start_secure();
    if (!isset($_SESSION['benutzer_id'])) return false;
    return ($_SESSION['typ'] ?? null) !== 'benutzer';
}
