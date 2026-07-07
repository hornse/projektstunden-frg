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
# github    git@github.com:hornse/projektstunden.git
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

### Schritt 6 – Domain und Symlink

```bash
uberspace web domain add projektstunden.hornse.de
cd /var/www/virtual/hornse
ln -s /home/hornse/projektstunden projektstunden
```

### Schritt 7 – PHP Backend-Server (supervisord)

```bash
cat > ~/etc/services.d/projektstunden.ini << 'EOF'
[program:projektstunden]
command=php -S 0.0.0.0:8082 /var/www/virtual/hornse/router.php
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

# Migrationen in dieser Reihenfolge einspielen:
DB=hornse_projektstunden
mysql $DB < /home/hornse/projektstunden/sql/01_schema.sql
mysql $DB < /home/hornse/projektstunden/sql/02_seed.sql
mysql $DB < /home/hornse/projektstunden/sql/03_migration_schuljahr_schueler_werkstatt.sql
mysql $DB < /home/hornse/projektstunden/sql/04_migration_werkstatt_detail.sql
mysql $DB < /home/hornse/projektstunden/sql/05_migration_rueckmeldungen.sql
mysql $DB < /home/hornse/projektstunden/sql/09_seed_sport_konkrete_erwartungen.sql
```

> Alle Migrationen müssen in dieser Reihenfolge eingespielt werden.

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
VALUES (1, 'Sebastian', 'Horn', 'deine@email.de', '$HASH', 'admin');"
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
| `09_seed_sport_konkrete_erwartungen.sql` | Konkrete Erwartungen für Sport-KLP |

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

## Uberspace-spezifische Konfiguration

Alles was nur auf dem Server konfiguriert ist (supervisord, web backend,
Symlinks, Logs) ist dokumentiert in `deploy/uberspace.md`.
