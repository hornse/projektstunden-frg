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

Gemessen am 03.11.2026 (`uberspace web backend list`, `grep` auf die
ini-Datei): Der Router ist `backend/router.php` im Arbeitsbaum.

```ini
[program:projektstunden]
command=php -S 0.0.0.0:8082 /home/hornse/projektstunden/backend/router.php
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

## Router

Der Router ist `backend/router.php` im Arbeitsbaum. Er leitet `/api/`-Anfragen
an `backend/api/index.php` weiter, liefert Dateien aus `frontend/` aus und
sperrt, was nicht ausgeliefert werden darf (Sperrliste wie die Apache-Vorlage,
S61). Ein Symlink im vhost-Verzeichnis wird dafür **nicht** gebraucht.

**Offen (03.11.2026):** Unter `/var/www/virtual/hornse/` liegen noch
`projektstunden` (ein Verzeichnis, kein Symlink) und `router.php`. Der Dienst
benutzt keines von beiden. Was sie enthalten und ob sie weg können, ist nicht
geprüft.

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

## Datenbank

MariaDB, Datenbank `hornse_projektstunden`. Die Migrationen und ihre
Reihenfolge stehen **nur** in `docs/INSTALL.md` (Abschnitt „Migrationen“) –
eine Liste, nicht zwei.

**Sicherung:** Uberspace sichert die Datenbank täglich. Eine eigene Sicherung
per cron gibt es nicht (gezählt am 03.11.2026: `crontab -l` ist leer).

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
│   ├── config.php                    ← DB-Zugang, Session, WebUntis (nicht in git)
│   └── router.php                    ← Router des PHP built-in server
├── frontend/
│   ├── index.html                    ← Single Page App
│   └── app.js                        ← Gesamte Frontend-Logik
├── sql/                              ← Migrationen, Liste in docs/INSTALL.md
├── docs/                             ← Dokumentation
└── .gitignore

~/etc/services.d/
└── projektstunden.ini                ← nicht in git – siehe oben

~/repos/
└── projektstunden.git/               ← bare repo für git push
```

---

## Deployment-Workflow

```bash
./deploy.sh "<Beschreibung>"
```

**Nur über `deploy.sh`.** Es hält an, solange etwas unverfolgt oder nicht
committet ist, lässt `./tests-projektstunden.sh` laufen (rot: kein Deploy),
setzt den Cache-Stempel `?v=` in `frontend/index.html`, committet nur diese
Datei und pusht nach `github` und `uberspace`. Ein Push von Hand liefert
neuen Servercode mit altem Browsercode aus (REIHENREGELN 6). Der
post-receive Hook checkt nach dem Push auf `uberspace` aus.

**Achtung:** Der Upstream von `main` ist `uberspace/main`. Ein `git push`
ohne Argument ist eine Auslieferung.

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
