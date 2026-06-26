# Installation

---

## Teil 1: Lokales Projekt einrichten

### Schritt 1 – Repository klonen oder ZIP entpacken

```bash
git clone https://github.com/hornse/projektstunden.git
# oder ZIP entpacken nach ~/Projekte/projektstunden/
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

### Schritt 5 – Projektverzeichnis anlegen und ersten Push

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

### Schritt 7 – PHP Backend-Server einrichten (supervisord)

```bash
mkdir -p ~/etc/services.d
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

### Schritt 9 – Datenbank anlegen

```bash
DB=/home/hornse/projektstunden/backend/datenbank.sqlite
SRC=/home/hornse/projektstunden/sql

sqlite3 $DB < $SRC/01_schema.sql
sqlite3 $DB < $SRC/02_seed.sql
sqlite3 $DB < $SRC/03_migration_schuljahr_schueler_werkstatt.sql
sqlite3 $DB < $SRC/09_seed_sport_konkrete_erwartungen.sql
```

**Wichtig:** Alle Migrationen in dieser Reihenfolge einspielen.

### Schritt 10 – Ersten Admin anlegen

```bash
sqlite3 /home/hornse/projektstunden/backend/datenbank.sqlite \
  "INSERT INTO benutzer (schule_id, vorname, nachname, email, passwort_hash, rolle)
   VALUES (1, 'Sebastian', 'Horn', 'deine@email.de',
   '\$(php -r \"echo password_hash(\'PASSWORT\', PASSWORD_BCRYPT);\")','admin');"
```

Oder komfortabler – Hash separat erzeugen:
```bash
# Auf dem Server:
php -r "echo password_hash('DEIN_PASSWORT', PASSWORD_BCRYPT) . PHP_EOL;"

# Hash dann eintragen:
sqlite3 /home/hornse/projektstunden/backend/datenbank.sqlite \
  "INSERT INTO benutzer (schule_id, vorname, nachname, email, passwort_hash, rolle)
   VALUES (1, 'Sebastian', 'Horn', 'deine@email.de', 'HASH_HIER', 'admin');"
```

---

## Migrationen

| Datei | Inhalt |
|---|---|
| `01_schema.sql` | Vollständiges Datenbankschema |
| `02_seed.sql` | Grunddaten: Schule, Fächer, Kompetenzrahmen |
| `03_migration_schuljahr_schueler_werkstatt.sql` | Schuljahre, Import, Werkstatt-Erweiterungen, Bewertungsstufen |
| `09_seed_sport_konkrete_erwartungen.sql` | Konkrete Erwartungen für Sport-KLP |

---

## Laufender Betrieb

### Deployen

```bash
cd /Users/sebastianhorn/Projekte/projektstunden
./deploy.sh "Beschreibung der Änderung"
```

Das Script macht automatisch:
1. Cache-Busting-Timestamp in `frontend/index.html` aktualisieren (`?v=YYYYMMDDHHMM`)
2. `git add -A && git commit`
3. `git push github main && git push uberspace main`

Der post-receive Hook auf dem Server deployt automatisch.
Ein `supervisorctl restart` ist normalerweise nicht nötig da PHP-Dateien
bei jedem Request neu geladen werden.

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
tail -f ~/logs/supervisord.log | grep projektstunden

# Danach wieder deaktivieren:
uberspace web log apache_error disable
uberspace web log php_error disable
```

### Datenbank-Backup (manuell)

```bash
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
sqlite3 /home/hornse/projektstunden/backend/datenbank.sqlite .dump \
  > /home/hornse/projektstunden/backups/backup_${TIMESTAMP}.sql
```

### Git-Stand auf dem Server prüfen

```bash
# Weicht der Work-Tree vom letzten Commit ab?
git --git-dir=/home/hornse/repos/projektstunden.git \
    --work-tree=/home/hornse/projektstunden \
    status

# Letzter eingespielter Commit:
git --git-dir=/home/hornse/repos/projektstunden.git log --oneline -5
```

---

## Uberspace-spezifische Konfiguration

Alles was nur auf dem Server konfiguriert ist (supervisord, web backend,
Symlinks, Logs) ist dokumentiert in `deploy/uberspace.md`.
