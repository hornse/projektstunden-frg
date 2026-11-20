# konfiguration.php einrichten – Schritt für Schritt

Seit Auftrag A (E68) steht der **Code** der Konfiguration versioniert in
`backend/kern.php`, die **Werte** in `backend/konfiguration.php`. Die
Wertedatei liegt **nicht in git** (`.gitignore`) und wird beim Ausliefern
nicht überschrieben. Vorlage: `backend/konfiguration.example.php`.

Bis A hieß die Datei `backend/config.php` und trug Werte und Code. Der Code
lädt sie nicht mehr.

**Vor dem Anlegen** braucht jeder Rechner, auf dem eine Sitzung von Claude
Code läuft, die Leseregeln `Read(//**/konfiguration.php)` und
`Read(//**/konfiguration.php.*)` in `~/.claude/settings.json`. Die Datei
trägt das Datenbankpasswort.

---

## Aus einer alten config.php ableiten (Server, Rechner)

```bash
./bin/konfiguration-ableiten.sh server            # trocken
SCHREIBEN=1 ./bin/konfiguration-ableiten.sh server
./bin/konfiguration-ableiten.sh server-pruefen    # Namen gegen die Vorlage
```

Am Rechner dasselbe mit `lokal` und `lokal-pruefen`. Ausgegeben werden nur
Namen und Zahlen, nie ein Wert. Trocken ist der Standard; geschrieben wird
mit Rechten 0600, eine vorhandene Datei wird nie überschrieben.

Die Ableitung vergleicht jede Funktion der alten Datei gegen die Vorlage vom
Stand vor A (`tests/daten/config.example-0e80957.php`) und **hält an**, wenn
eine fehlt, abweicht oder unbekannt ist. Eine Ausnahme, an ihrer Prüfsumme:
die Betriebsfassung von `session_start_secure` (E68, Abschnitt 2). Nicht
übernommen werden `ini_set('session.save_path', …)`, `SESSION_NAME` und
`SESSION_LIFETIME` – die Sitzung steht im Kern, der Speicherort in
`~/etc/php.d/sessions.ini`. Die Reihenfolge am Server steht in
`docs/AUSROLLEN-auftrag-A.md`.

## Neu anlegen (Neuinstallation)

```bash
cp backend/konfiguration.example.php backend/konfiguration.php
chmod 600 backend/konfiguration.php
nano backend/konfiguration.php
```

Das Datenbankpasswort steht auf dem Server in `~/.my.cnf`. Einzutragen sind
`DB_PASS` und die WebUntis-Werte:

```php
define('WEBUNTIS_ENABLED', true);

$WEBUNTIS_CONFIG = [
    'base_url'             => 'https://SERVERNAME.webuntis.com',  // ohne / am Ende
    'school'               => 'SCHULKUERZEL',
    'client'               => 'ProjektstundenNRW',
    'allowed_person_types' => [2, 16, 5],  // 2 Lehrkraft, 16 WebUntis-Admin, 5 Schüler
    'connect_timeout'      => 5,
    'timeout'              => 10,
    'admin_kuerzel'        => ['Vzq'],      // erfunden
];
```

`base_url` und `school` stehen in der WebUntis-Adresse der Schule:

```
https://SERVERNAME.webuntis.com/WebUntis/?school=SCHULKUERZEL
```

**Nicht hier:** die Schwelle und Wartezeit der Anmeldebremse
(`Anmeldung::SCHWELLE = 8`, `WARTEZEIT_S = 60`, M56; das Zählfenster im
Modul), Name und Dauer der Sitzung (`backend/kern.php`), der Speicherort der
Sitzungen (`sessions.ini`). Einträge `lockout_minutes` oder
`max_failed_logins` aus einer älteren Datei werden nicht mehr gelesen.

`mkdir -p ~/tmp/sessions` – der Speicherort aus `sessions.ini` muss
existieren.

## Lehrkräfte und Schüler mit WebUntis verknüpfen

```bash
# Kürzel für ein Konto eintragen
mysql hornse_projektstunden -e "
UPDATE benutzer SET webuntis_user = 'Vzq'
WHERE email = 'vorname.nachname@frg-duesseldorf.de';"

# Schüler einzeln (optional)
mysql hornse_projektstunden -e "
UPDATE schueler SET webuntis_user = 'schueler.vorname'
WHERE schild_id = 12345;"
```

Kürzel und Namen hier sind erfunden.

---

## Troubleshooting

**Jede API-Anfrage antwortet mit 500:** `konfiguration.php` fehlt
(„Failed opening required …/backend/konfiguration.php“ im Fehlerprotokoll).
Es gibt keinen Rückfall auf `config.php` – absichtlich (E68).

**Warum kommt jemand nicht hinein:** Die Ablehnung ist nach außen
einheitlich (FALLSTRICKE 8); der Grund steht im Verlauf. Nur zählen oder die
eigene Kennung ansehen:

```bash
mysql hornse_projektstunden -e "
SELECT erfolgreich, grund, COUNT(*) FROM anmeldeverlauf GROUP BY erfolgreich, grund;"
```

Der Verlauf hält 30 Tage; `zeitpunkt` kommt aus der PHP-Uhr, nicht aus
`NOW()` der Datenbank (FALLSTRICKE 4). `webuntis_login_log` gibt es seit `sql/24` nicht
mehr.

**WebUntis nicht erreichbar:** `WEBUNTIS_ENABLED` auf `false` → nur noch
E-Mail und Passwort.

---

## Abgleich mit der Vorlage

`konfiguration.php` wird nie mit ausgeliefert, nie zurückgeholt und von
keinem `git diff` gesehen. Sie kann zwischen Rechner und Server
auseinanderlaufen, ohne dass etwas warnt – das war der Anlass von A: Die
lokale `config.php` hing drei Änderungen hinter dem Server (`secure`,
`SameSite`, `empty()` in `require_auth`). **Seit A steht kein Code mehr
darin**; was auseinanderlaufen kann, sind nur noch Werte.

**`tests-projektstunden.sh` prüft die Struktur:** jeder Name aus der
Vorlage kommt in `konfiguration.php` vor, und sie enthält keine Funktion.
Fehlt die Datei – an jedem Commit, in einem Klon oder `git worktree` –,
wird die Prüfung **sichtbar übersprungen und gezählt**:

```
  –  ÜBERSPRUNGEN: keine backend/konfiguration.php (Baum ohne Konfiguration) – Struktur gegen backend/konfiguration.example.php nicht verglichen
```

```
  ✓ konfiguration.php fuehrt alle 10 Namen aus konfiguration.example.php und keine Funktion
```

**Nur Namen, keine Werte.** Gemeldet werden ausschließlich Namen aus der
Vorlage, die fehlen. Abweichende **Werte** sieht die Prüfung nicht; eine
Wertänderung auf dem Server muss weiterhin hier oder in `CLAUDE.md` vermerkt
werden.
