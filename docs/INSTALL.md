# Installation

---

## Teil 1: Lokales Projekt einrichten

### Schritt 1 – Repository klonen

```bash
git clone https://github.com/hornse/projektstunden.git
cd projektstunden
```

### Schritt 2 – Git-Remotes prüfen

```bash
git remote -v
# Erwartet:
# github    abc@schule.example:hornse/projektstunden.git
# uberspace hornse@halimede.uberspace.de:repos/projektstunden.git
```

Falls Uberspace-Remote fehlt:
```bash
git remote add uberspace hornse@halimede.uberspace.de:repos/projektstunden.git
```

### Schritt 3 – deploy.sh ausführbar machen (einmalig)

```bash
chmod +x /Users/sebastianhorn/Projekte/projektstunden/deploy.sh
```

---

## Teil 2: Uberspace einrichten

### Schritt 4 – Bare Repository anlegen

```bash
mkdir -p ~/repos/projektstunden.git
cd ~/repos/projektstunden.git && git init --bare

cat > hooks/post-receive << 'EOF'
#!/bin/bash
GIT_WORK_TREE=/home/hornse/projektstunden \
GIT_DIR=/home/hornse/repos/projektstunden.git \
git checkout -f main
echo "✓ Deploy erfolgreich auf Uberspace"
EOF
chmod +x hooks/post-receive
```

### Schritt 5 – Ersten Push

```bash
mkdir -p /home/hornse/projektstunden
```

Lokal:
```bash
git push uberspace main
```

### Schritt 6 – Domain

```bash
uberspace web domain add projektstunden.hornse.de
```

Ein Symlink im vhost-Verzeichnis wird nicht gebraucht: Der Dienst liefert
alles über `backend/router.php` aus (Schritt 7, 8).

### Schritt 7 – PHP Backend-Server (supervisord)

```bash
cat > ~/etc/services.d/projektstunden.ini << 'EOF'
[program:projektstunden]
command=php -S 0.0.0.0:8082 /home/hornse/projektstunden/backend/router.php
directory=/home/hornse/projektstunden
autostart=yes
autorestart=yes
startsecs=30
EOF

supervisorctl reread
supervisorctl update
supervisorctl status projektstunden
```

### Schritt 8 – Web Backend registrieren

```bash
uberspace web backend set projektstunden.hornse.de/ --http --port 8082
uberspace web backend list | grep projektstunden
# Erwartet: projektstunden.hornse.de/ http:8082 => OK, listening: ...
```

### Schritt 9 – Datenbank anlegen (MariaDB)

```bash
# Datenbank erstellen
mysql -e "CREATE DATABASE IF NOT EXISTS hornse_projektstunden
          CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

# Migrationen in der Reihenfolge ihrer Nummern einspielen
# (Liste und Inhalt: Abschnitt „Migrationen“ unten):
DB=hornse_projektstunden
for f in /home/hornse/projektstunden/sql/[0-9][0-9]_*.sql; do
  echo "== $f"; mysql $DB < "$f" || break
done
```

> Die Reihenfolge ist die der Nummern. Eine 09 gibt es nicht mehr (entfernt
> mit `f4b1338`, ersetzt durch Seed 12). Die Schleife ist am 03.11.2026
> nicht ausgeführt worden – sie ersetzt eine Liste, die bei 05 stehen blieb.

### Schritt 10 – config.php prüfen

Die Datei `backend/config.php` enthält die Datenbankzugangsdaten.
Auf Uberspace sind die MariaDB-Zugangsdaten in `~/.my.cnf` hinterlegt:

```bash
cat ~/.my.cnf
# [client]
# user=hornse
# password=DEIN_PASSWORT
```

In `backend/config.php` eintragen:
```php
define('DB_HOST', '127.0.0.1');
define('DB_NAME', 'hornse_projektstunden');
define('DB_USER', 'hornse');
define('DB_PASS', 'DEIN_PASSWORT');
```

### Schritt 11 – Ersten Admin anlegen

```bash
# Hash erzeugen
HASH=$(php -r "echo password_hash('DEIN_PASSWORT', PASSWORD_BCRYPT);")

# Admin eintragen
mysql hornse_projektstunden -e "
INSERT INTO benutzer (schule_id, vorname, nachname, email, passwort_hash, rolle)
VALUES (1, 'Vorname', 'Nachname', 'deine@email.de', '$HASH', 'admin');"
```

---

## Migrationen

| Datei | Inhalt |
|---|---|
| `01_schema.sql` | Vollständiges Datenbankschema |
| `02_seed.sql` | Grunddaten: Schule, Fächer, Kompetenzrahmen |
| `03_migration_schuljahr_schueler_werkstatt.sql` | Schuljahre, Import, Werkstatt-Erweiterungen, Bewertungsstufen |
| `04_migration_werkstatt_detail.sql` | Abschluss je Schüler, Multi-Klassen |
| `05_migration_rueckmeldungen.sql` | Rückmeldungen-Tabelle |
| `06_migration_webuntis_auth.sql` | WebUntis-Anmeldung: Login-Log (Anmeldebremse), Schüler-Zugriff, Selbsteinschätzung |
| `07_migration_einstellungen.sql` | Schulanpassung: Einstellungen |
| `08_migration_klp_schema.sql` | KLP-Schema für G9-Kernlehrpläne, Bereinigung falscher KLP-Daten |
| `10_seed_deutsch_klp.sql` | Deutsch, Kernlehrplan Sek I (G9) |
| `11_seed_deutsch_sii.sql` | Deutsch, Kernlehrplan Oberstufe |
| `12_seed_sport_klp.sql` | Sport, Kernlehrplan Sek I (G9) |
| `13_migration_klp_spalten.sql` | teilbereich und art auf kompetenzbereiche (E18) |
| `14_migration_phase_sek1uebergreifend.sql` | Phase `sek1_uebergreifend` (E12, E14) |
| `15_migration_kompetenzbereiche_baum.sql` | kompetenzbereiche bekommt parent_id (E29b, E31) |
| `16_migration_mkr_baum.sql` | Medienkompetenzrahmen im Baummodell (E29b, E31) |
| `17_migration_klp_spalten_entfernen.sql` | inhaltsfeld, kompetenzbereich und teilbereich entfallen (E29b) |
| `18_migration_verwaiste_rueckmeldungen.sql` | verwaiste Rückmeldungen entfernen (E37) |
| `19_seed_englisch_klp.sql` | Englisch, Kernlehrplan Sek I (G9) |
| `20_seed_franzoesisch_klp.sql` | Französisch, Kernlehrplan Sek I (G9) |

Die Inhalte stammen aus dem Kopf der jeweiligen Datei. Die Tabelle ist von
Hand gepflegt: Kommt eine Migration dazu, gehört sie hierher.

---

## Laufender Betrieb

### Deployen

```bash
cd /Users/sebastianhorn/Projekte/projektstunden
./deploy.sh "Beschreibung der Änderung"
```

### Server-Status prüfen

```bash
ssh hornse@halimede.uberspace.de
supervisorctl status projektstunden
uberspace web backend list | grep projektstunden
```

### Logs

```bash
uberspace web log apache_error enable
uberspace web log php_error enable

tail -f ~/logs/webserver/error_log_apache
tail -f ~/logs/error_log_php
supervisorctl tail projektstunden stderr

# Danach wieder deaktivieren:
uberspace web log apache_error disable
uberspace web log php_error disable
```

### Neue Migration einspielen

```bash
mysql hornse_projektstunden < /home/hornse/projektstunden/sql/NEUE_MIGRATION.sql
```

### Git-Stand auf dem Server prüfen

```bash
git --git-dir=/home/hornse/repos/projektstunden.git \
    --work-tree=/home/hornse/projektstunden \
    status

git --git-dir=/home/hornse/repos/projektstunden.git log --oneline -5
```

---

### Sicherung

Uberspace sichert die Datenbank täglich. Eine eigene Sicherung per cron gibt
es nicht (gezählt am 03.11.2026: `crontab -l` ist leer).

### Datenschutz

Übernommen aus der früheren `docs/ANLEITUNG.md` (8.2), am Code geprüft am
03.11.2026: Die Tabelle `audit_log` gibt es (`sql/01_schema.sql`), und das
Backend schreibt hinein.

Gemäß DSGVO und Schulgesetz NRW:
- Schülerdaten nur auf deutschen/EU-Servern (Uberspace: Deutschland)
- Uberspace-AGB und eigene Schulvereinbarung mit der oder dem
  Datenschutzbeauftragten abstimmen
- Audit-Log (Tabelle `audit_log`) regelmäßig prüfen
- Schüler dürfen nur aktiven Klassen zugeordnet sein (`aktiv = 1`)

## Uberspace-spezifische Konfiguration

Alles was nur auf dem Server konfiguriert ist (supervisord, web backend,
Symlinks, Logs) ist dokumentiert in `deploy/uberspace.md`.
