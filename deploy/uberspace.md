# Uberspace-Konfiguration – Projektstunden NRW

Diese Datei dokumentiert alles was auf dem Uberspace-Server konfiguriert ist
aber **nicht** durch `git push` deployed wird. Bei einer Neuinstallation müssen
diese Schritte manuell ausgeführt werden.

Server: `halimede.uberspace.de`
Account: `hornse`
Domain: `projektstunden.hornse.de`

---

## PHP Built-in Server (supervisord)

Die App läuft über einen PHP built-in server statt direkt über Apache.
Das ist nötig damit URL-Routing korrekt funktioniert.

**Config-Datei:** `~/etc/services.d/projektstunden.ini`

```ini
[program:projektstunden]
command=php -S 0.0.0.0:8082 /var/www/virtual/hornse/router.php
directory=/home/hornse/projektstunden
autostart=yes
autorestart=yes
startsecs=30
```

**Service starten:**
```bash
supervisorctl reread
supervisorctl update
supervisorctl status projektstunden
```

**Service neu starten** (nach Deploy falls nötig):
```bash
supervisorctl restart projektstunden
```

> Normalerweise nicht nötig – PHP-Dateien werden bei jedem Request neu geladen.

---

## Web Backend

Uberspace leitet `projektstunden.hornse.de` an Port 8082 weiter:

```bash
uberspace web backend set projektstunden.hornse.de/ --http --port 8082
```

Prüfen:
```bash
uberspace web backend list | grep projektstunden
# Erwartet: projektstunden.hornse.de/ http:8082 => OK, listening: ...
```

---

## Domain-Symlink

```bash
# Symlink im vhost-Verzeichnis anlegen
ln -s /home/hornse/projektstunden \
  /var/www/virtual/hornse/projektstunden
```

> Hinweis: Der router.php im supervisord-Command liegt unter
> `/var/www/virtual/hornse/router.php` – dieser leitet `/api/`-Anfragen
> an `backend/api/index.php` weiter und alle anderen an `frontend/index.html`.

---

## Git Bare Repository + post-receive Hook

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

Lokal als Remote hinzufügen:
```bash
git remote add uberspace hornse@halimede.uberspace.de:repos/projektstunden.git
```

---

## Datenbank-Migrationen

Einmalig bei Erstinstallation – in dieser Reihenfolge:

```bash
DB=/home/hornse/projektstunden/backend/datenbank.sqlite

sqlite3 $DB < sql/01_schema.sql
sqlite3 $DB < sql/02_seed.sql
sqlite3 $DB < sql/03_migration_schuljahr_schueler_werkstatt.sql
sqlite3 $DB < sql/09_seed_sport_konkrete_erwartungen.sql
```

> Die Datenbankdatei (`datenbank.sqlite`) liegt nicht im Git-Repo
> und wird nicht durch `git push` überschrieben.

---

## Logs aktivieren (Debugging)

```bash
uberspace web log apache_error enable
uberspace web log php_error enable
uberspace web log access enable

# Logs lesen
tail -f ~/logs/webserver/error_log_apache
tail -f ~/logs/error_log_php
tail -f ~/logs/webserver/access_log

# Supervisord-Log für projektstunden
tail -f ~/logs/supervisord.log | grep projektstunden
```

Logs deaktivieren wenn nicht mehr gebraucht:
```bash
uberspace web log apache_error disable
uberspace web log php_error disable
uberspace web log access disable
```

---

## Verzeichnisstruktur auf dem Server

```
/home/hornse/projektstunden/          ← Work-Tree (deploy-Ziel)
├── backend/
│   ├── api/
│   │   └── index.php                 ← API-Router (alle Endpunkte)
│   ├── config.php                    ← DB-Pfad, Session-Config, Konstanten
│   └── router.php                    ← PHP built-in server Router
├── frontend/
│   ├── index.html                    ← Single Page App
│   └── app.js                        ← Gesamte Frontend-Logik
├── sql/
│   ├── 01_schema.sql
│   ├── 02_seed.sql
│   ├── 03_migration_schuljahr_schueler_werkstatt.sql
│   └── 09_seed_sport_konkrete_erwartungen.sql
├── backups/                          ← SQLite-Backups (nicht in git)
├── docs/                             ← Dokumentation
└── .gitignore

/var/www/virtual/hornse/
├── projektstunden/                   ← Symlink → /home/hornse/projektstunden
└── router.php                        ← Haupt-Router (leitet an backend/router.php)

~/etc/services.d/
└── projektstunden.ini                ← nicht in git – siehe oben

~/repos/
└── projektstunden.git/               ← bare repo für git push
```

---

## Deployment-Workflow

```bash
# Lokal – mit dem deploy.sh Script:
./deploy.sh "feat: Werkstätten Multi-Lernbegleiter"

# Oder manuell:
git add -A
git commit -m "Beschreibung"
git push github main && git push uberspace main
```

Der post-receive Hook deployt automatisch nach `git push uberspace main`.

---

## Bekannte Eigenheiten

**Interface-Problem (behoben Juni 2026):**
Supervisord lief ursprünglich auf `100.64.47.2:8082` statt `0.0.0.0:8082`.
Fix: In `~/etc/services.d/projektstunden.ini` den command-Wert korrigieren
und `supervisorctl reread && supervisorctl update && supervisorctl restart projektstunden` ausführen.

**Work-Tree ist kein Git-Repo:**
`/home/hornse/projektstunden` hat kein `.git`-Verzeichnis – das ist Absicht.
Das bare repo liegt in `~/repos/projektstunden.git`.
Deshalb funktioniert `git status` im Work-Tree nicht direkt; stattdessen:
```bash
git --git-dir=/home/hornse/repos/projektstunden.git \
    --work-tree=/home/hornse/projektstunden \
    status
```
