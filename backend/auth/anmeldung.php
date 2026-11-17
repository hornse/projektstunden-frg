<?php
/**
 * Projektstunden NRW – Anmeldung: Bremse, Ziel, Sätze, Verlauf
 * ============================================================
 * Datei: backend/auth/anmeldung.php  (projekteigen)
 *
 * Seit Auftrag A (E68) kommt die Bremse aus dem Modul hornse/webuntis-auth-php
 * (backend/auth/Anmeldebremse.php, vendort). Was die Klasse des Moduls dem
 * Projekt überlässt, steht hier, je an EINER Stelle:
 *   - Schwelle und Wartezeit (M56: acht Fehlversuche, 60 Sekunden);
 *   - das Ziel, nach dem neben der Kennung gezählt wird;
 *   - die Sätze an den Benutzer (FALLSTRICKE 8) – der Router benutzt sie,
 *     Hilfe und Handbuch zitieren sie, die Suite vergleicht beides;
 *   - der Verlauf (anmeldeverlauf, sql/23), ohne Adresse.
 *
 * DAS ZIEL. Eine Kennung in E-Mail-Form wird lokal geprüft (benutzer.email)
 * und zählt unter „lokal“, auch wenn danach noch WebUntis gefragt wird – so
 * zählt ein falsches lokales Passwort auch dann, wenn WebUntis ausfällt (E66).
 * Jede andere Kennung zählt unter „webuntis:<Host>“: Ein Fehlversuch gegen
 * die Spielwiese bremst den Betrieb nicht (koordination M55, kurse E83).
 *
 * Copyright (C) 2026 Sebastian Horn, Friedrich-Rückert-Gymnasium Düsseldorf
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

declare(strict_types=1);

require_once __DIR__ . '/Anmeldebremse.php';

final class Anmeldung
{
    /** Ab so vielen Fehlversuchen wird gewartet (M56). */
    public const SCHWELLE = 8;
    /** Sekunden zwischen zwei Versuchen ab der Schwelle. */
    public const WARTEZEIT_S = 60;

    /** Jede Ablehnung, bei der ein Passwort entschieden hat. Immer 401 (FALLSTRICKE 8). */
    public const SATZ_ABGELEHNT = 'Ungültige Anmeldedaten.';
    /** WebUntis antwortete nicht (Transportfehler). 503, zählt nicht. */
    public const SATZ_AUSFALL = 'WebUntis ist gerade nicht erreichbar. Bitte in ein paar Minuten erneut versuchen.';
    /** Die Tabelle der Bremse antwortet nicht. 503, abgewiesen (geschlossen scheitern). */
    public const SATZ_BREMSE_FEHLER = 'Die Anmeldung ist gerade nicht möglich – die Prüfung der '
        . 'Anmeldeversuche antwortet nicht. Bitte in ein paar Minuten noch einmal.';
    /** WebUntis meldet -8500: Schule unbekannt oder Instanz gewechselt. 503, zählt nicht; Warten behebt es nicht (FALLSTRICKE 6). */
    public const SATZ_SCHULE_UNBEKANNT = 'Die Anmeldung ist gerade nicht möglich. Bitte der Schule Bescheid geben.';

    /** Der Satz bei Wartezeit, mit den Sekunden aus der Bremse. */
    public static function satzWarten(int $sekunden): string
    {
        return 'Zu viele Fehlversuche. Erneut versuchen in noch ' . $sekunden
            . ($sekunden === 1 ? ' Sekunde.' : ' Sekunden.');
    }

    /** Die Bremse – die eine Stelle, an der sie entsteht. Die Uhr ist für die Prüfungen übergebbar. */
    public static function bremse(PDO $db, ?Closure $uhr = null): Anmeldebremse
    {
        return new Anmeldebremse($db, ['schwelle' => self::SCHWELLE, 'wartezeit_s' => self::WARTEZEIT_S], $uhr);
    }

    /** „lokal“ für eine E-Mail-Kennung, sonst „webuntis:<Host>“ aus base_url, kleingeschrieben. */
    public static function ziel(string $kennung, array $webuntis): string
    {
        if (filter_var(trim($kennung), FILTER_VALIDATE_EMAIL)) return 'lokal';
        $host = parse_url((string)($webuntis['base_url'] ?? ''), PHP_URL_HOST);
        return 'webuntis:' . strtolower(is_string($host) ? $host : '');
    }

    /**
     * Ein Eintrag im Verlauf. Er entscheidet über nichts: Scheitert er, geht
     * die Anmeldung ihren Gang, und das Fehlerprotokoll nennt Art und Code –
     * nie die Kennung (FALLSTRICKE 3: nur Betriebsfehler, mit Grund).
     */
    public static function verlauf(PDO $db, string $kennung, string $ziel, bool $erfolgreich,
                                   ?string $grund, ?Closure $uhr = null): void
    {
        $jetzt = $uhr !== null ? $uhr() : time();
        try {
            $db->prepare('INSERT INTO anmeldeverlauf (benutzername, ziel, erfolgreich, grund, zeitpunkt)
                          VALUES (?, ?, ?, ?, ?)')
               ->execute([$kennung, $ziel, $erfolgreich ? 1 : 0, $grund, date('Y-m-d H:i:s', $jetzt)]);
        } catch (Exception $e) {
            error_log('projektstunden: Verlauf nicht geschrieben (' . get_class($e) . ' ' . $e->getCode() . ')');
        }
    }
}
