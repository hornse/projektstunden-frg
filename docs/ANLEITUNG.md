# Inbetriebnahme-Anleitung: Projektstunden NRW auf Uberspace

## Inhaltsverzeichnis
1. Voraussetzungen
2. Uberspace vorbereiten
3. Datenbank einrichten
4. Dateien hochladen
5. Konfiguration anpassen
6. App starten und testen
7. Git + IntelliJ IDEA einrichten
8. Laufender Betrieb und Updates
9. Empfohlene zusätzliche Datenspeicher
10. Datenschutz-Hinweise

---

## 1. Voraussetzungen

| Was | Wo |
|---|---|
| Uberspace-Account | https://uberspace.de (ab 1 €/Monat) |
| SSH-Zugang | im Uberspace-Dashboard einrichten |
| PHP ≥ 8.1 | auf Uberspace vorinstalliert |
| MariaDB | auf Uberspace vorinstalliert |
| Git | lokal + auf Uberspace vorinstalliert |
| IntelliJ IDEA | lokal (Ultimate oder Community) |

---

## 2. Uberspace vorbereiten

### 2.1 SSH-Key hinterlegen
```bash
# Lokalen Public Key anzeigen (oder erzeugen)
cat ~/.ssh/id_rsa.pub

# Im Uberspace-Dashboard unter "SSH-Schlüssel" einfügen
```

### 2.2 Per SSH einloggen
```bash
ssh DEIN_BENUTZERNAME@DEIN_HOST.uberspace.de
```

### 2.3 PHP-Version prüfen und festlegen
```bash
# Aktuelle Version anzeigen
php --version

# Version auf 8.2 setzen (empfohlen)
uberspace tools version use php 8.2
```

### 2.4 DocumentRoot festlegen
Uberspace nutzt standardmäßig `~/html` als Web-Root.
```bash
# Prüfen welcher Ordner als Web-Root konfiguriert ist
ls ~/html
```

---

## 3. Datenbank einrichten

### 3.1 MySQL-Zugangsdaten ermitteln
```bash
# Standardmäßig hat dein Uberspace-User direkten MySQL-Zugang
# Die Zugangsdaten stehen in:
cat ~/.my.cnf

# Ausgabe sieht so aus:
# [client]
# host=localhost
# user=DEIN_BENUTZERNAME
# password=DEIN_ZUFALLSPASSWORT
```

### 3.2 Datenbank erstellen
```bash
mysql -e "CREATE DATABASE IF NOT EXISTS projektstunden CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
```

### 3.3 Schema und Seed-Daten einspielen
```bash
# Schema erstellen
mysql projektstunden < sql/01_schema.sql

# Beispieldaten (Fächer, MKR, Mathematik-Kompetenzen)
mysql projektstunden < sql/02_seed.sql

# Prüfen ob alles angelegt wurde
mysql projektstunden -e "SHOW TABLES;"
mysql projektstunden -e "SELECT COUNT(*) AS kompetenzen FROM kompetenzen;"
```

### 3.4 Admin-Passwort setzen
```bash
# Sicheres Passwort-Hash erzeugen (ersetze 'DeinPasswort123!' mit deinem Wunschpasswort)
php -r "echo password_hash('DeinPasswort123!', PASSWORD_DEFAULT);"

# Hash in Datenbank eintragen
mysql projektstunden -e "UPDATE benutzer SET passwort_hash='HASH_VON_OBEN' WHERE email='admin@schule.de';"

# E-Mail-Adresse anpassen
mysql projektstunden -e "UPDATE benutzer SET email='deine@email.de' WHERE id=1;"
```

---

## 4. Dateien hochladen

### Struktur auf dem Server
```
~/ (Home-Verzeichnis)
├── projektstunden/
│   └── backend/
│       ├── config.php          ← Konfiguration (NICHT im Web-Root!)
│       └── api/
│           └── index.php       ← API-Router
└── html/                       ← Web-Root (öffentlich erreichbar)
    ├── .htaccess               ← URL-Routing
    ├── index.html              ← Frontend
    └── backend/                ← Symlink oder Kopie
        └── api/
            └── index.php
```

### 4.1 Empfohlene Struktur (sicherste Variante)
```bash
# Auf dem Uberspace-Server:
mkdir -p ~/projektstunden/backend/api
mkdir -p ~/html/api  # Nur API-Einstiegspunkt im Web-Root
```

### 4.2 Dateien per SCP übertragen
```bash
# Vom lokalen Rechner aus:
scp sql/01_schema.sql BENUTZERNAME@HOST.uberspace.de:~/projektstunden/sql/
scp sql/02_seed.sql   BENUTZERNAME@HOST.uberspace.de:~/projektstunden/sql/
scp backend/config.php BENUTZERNAME@HOST.uberspace.de:~/projektstunden/backend/
scp backend/api/index.php BENUTZERNAME@HOST.uberspace.de:~/projektstunden/backend/api/
scp frontend/index.html  BENUTZERNAME@HOST.uberspace.de:~/html/
scp frontend/.htaccess   BENUTZERNAME@HOST.uberspace.de:~/html/
```

### 4.3 API-Einstiegspunkt im Web-Root
```bash
# Auf dem Uberspace-Server:
# Einfachste Variante: Wrapper-Datei im html-Verzeichnis
mkdir -p ~/html/backend/api
cat > ~/html/backend/api/index.php << 'EOF'
<?php
// Weiterleitung an den API-Router außerhalb des Web-Roots
// PATH_INFO via RewriteRule übergeben (siehe .htaccess)
require_once __DIR__ . '/../../../projektstunden/backend/api/index.php';
EOF
```

---

## 5. Konfiguration anpassen

### 5.1 config.php bearbeiten
```bash
nano ~/projektstunden/backend/config.php
```

Folgende Werte anpassen:
```php
define('DB_NAME', 'projektstunden');          // Datenbankname
define('DB_USER', 'DEIN_UBERSPACE_USER');     // aus ~/.my.cnf
define('DB_PASS', 'DEIN_DB_PASSWORT');        // aus ~/.my.cnf
define('ALLOWED_ORIGIN', 'https://DEIN_UBERSPACE_USER.uber.space');
```

### 5.2 Frontend-API-URL anpassen
In `frontend/index.html`:
```javascript
const API_BASE = '';  // Leer lassen wenn Frontend und API auf gleicher Domain
```

### 5.3 HTTPS sicherstellen
Uberspace stellt automatisch Let's-Encrypt-Zertifikate bereit:
```bash
# Uberspace macht das automatisch – kein Handlungsbedarf
# Deine App ist erreichbar unter:
# https://BENUTZERNAME.uber.space
```

---

## 6. App starten und testen

### 6.1 Erste Anmeldung testen
```
URL: https://BENUTZERNAME.uber.space
E-Mail: deine@email.de
Passwort: DeinPasswort123! (aus Schritt 3.4)
```

### 6.2 API direkt testen
```bash
# Auf dem Server oder mit curl:
curl -X POST https://BENUTZERNAME.uber.space/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"deine@email.de","passwort":"DeinPasswort123!"}' \
  -c cookies.txt

curl https://BENUTZERNAME.uber.space/api/faecher -b cookies.txt
```

### 6.3 Häufige Fehler
| Fehler | Ursache | Lösung |
|---|---|---|
| 500 Internal Server Error | Falsche DB-Zugangsdaten | config.php prüfen |
| 404 auf /api/... | .htaccess fehlt oder mod_rewrite nicht aktiv | .htaccess prüfen |
| Zeichensalat | Charset falsch | utf8mb4 in DB und config.php sicherstellen |
| 401 nach Reload | Session abgelaufen | SESSION_LIFETIME erhöhen |

```bash
# PHP-Fehlerlog anzeigen
tail -f ~/logs/error.log
# oder
tail -f /var/www/virtual/BENUTZERNAME/logs/error_log
```

---

## 7. Git + IntelliJ IDEA einrichten

**Ja, es ist sehr sinnvoll, den Quellcode mit IntelliJ und GitHub zu verwalten.**
Konkrete Vorteile für dein Projekt:
- Versionsverlauf: du siehst wann welche Änderung gemacht wurde
- Rollback: fehlerhafte Deployments sofort rückgängig machen
- Zusammenarbeit: mehrere Lehrkräfte/Admins können am Code mitarbeiten
- Deployment: git pull auf dem Server = Update in Sekunden

### 7.1 GitHub-Repository anlegen
1. https://github.com → New Repository
2. Name: `projektstunden-nrw`
3. Privat setzen (Schuldaten!)
4. README nicht automatisch erstellen

### 7.2 Projekt lokal initialisieren
```bash
# Im Projektverzeichnis (dort wo sql/, backend/, frontend/ liegen):
git init
git add .
git commit -m "Initiales Commit: Schema, API, Frontend"
git branch -M main
git remote add origin https://github.com/DEIN_GITHUB_NAME/projektstunden-nrw.git
git push -u origin main
```

### 7.3 .gitignore anlegen (WICHTIG – keine Passwörter committen!)
```bash
cat > .gitignore << 'EOF'
# Konfiguration mit Datenbankzugangsdaten NIEMALS committen
backend/config.php

# Beispiel-Config committen (ohne echte Daten)
# backend/config.example.php → ja committen

# Logdateien
*.log
logs/

# IDE
.idea/
*.iml
.vscode/

# Betriebssystem
.DS_Store
Thumbs.db
EOF
```

### 7.4 config.example.php anlegen
```bash
cp backend/config.php backend/config.example.php
# In config.example.php Platzhalter statt echter Werte eintragen
# Dann: git add backend/config.example.php && git commit
```

### 7.5 IntelliJ IDEA einrichten
1. **Projekt öffnen**: File → Open → Projektverzeichnis wählen
2. **Git-Plugin**: ist eingebaut, kein zusätzliches Plugin nötig
3. **PHP-Support**: Settings → Plugins → PHP (bei Ultimate Edition vorhanden, Community: PHP-Plugin installieren)
4. **Remote-Deployment**: Tools → Deployment → Configuration
   - Type: SFTP
   - Host: DEIN_HOST.uberspace.de
   - User: DEIN_BENUTZERNAME
   - Authentication: Key pair
   - Root path: /home/BENUTZERNAME
   - Web server URL: https://BENUTZERNAME.uber.space
5. **Auto-Upload**: Tools → Deployment → Automatic Upload (on save)

### 7.6 Deployment-Workflow
```bash
# Auf dem Uberspace-Server (einmalig):
cd ~/projektstunden
git clone https://github.com/DEIN_GITHUB_NAME/projektstunden-nrw.git .

# Bei Updates (auf dem Server):
cd ~/projektstunden
git pull

# config.php liegt NICHT im Repo → muss separat gepflegt werden
```

---

## 8. Laufender Betrieb

### 8.1 Backup einrichten
```bash
# Automatisches Datenbank-Backup täglich um 3 Uhr
# Uberspace Cron (crontab -e):
0 3 * * * mysqldump projektstunden | gzip > ~/backups/projektstunden_$(date +\%Y\%m\%d).sql.gz

# Alte Backups aufräumen (älter als 30 Tage)
0 4 * * * find ~/backups -name "*.sql.gz" -mtime +30 -delete
```

### 8.2 Schüler-Datenschutz
Gemäß DSGVO und Schulgesetz NRW:
- Schülerdaten nur auf deutschen/EU-Servern (Uberspace: ✓ Deutschland)
- Uberspace-AGB + eigene Schulvereinbarung mit Datenschutzbeauftragten abstimmen
- Audit-Log (Tabelle `audit_log`) regelmäßig prüfen
- Schüler dürfen nur aktiven Klassen zugeordnet sein (`aktiv = 1`)

### 8.3 Weitere Lehrkräfte hinzufügen
```bash
# Hash für neues Passwort erzeugen
php -r "echo password_hash('LehrerPasswort!', PASSWORD_DEFAULT);"

# Lehrkraft anlegen
mysql projektstunden -e "
  INSERT INTO benutzer (schule_id, vorname, nachname, email, passwort_hash, rolle, kuerzel)
  VALUES (1, 'Erika', 'Mustermann', 'e.mustermann@schule.de', 'HASH_VON_OBEN', 'lehrer', 'MUS');
"
```

---

## 9. Empfohlene zusätzliche Datenspeicher

Folgende Informationen wären sinnvoll, aber noch nicht im Schema:

| Datum | Beschreibung | Tabelle |
|---|---|---|
| Elternkontakt | Für Benachrichtigungen | `schueler_kontakte` |
| Jahrgangswechsel | Schüler wandert in nächste Klasse | Historisierung in `klassen` |
| Lernstandsberichte | PDF-Berichte je Schüler | `berichte` (mit Dateipfad) |
| Schuljahresabschluss | Kontingent für Abschlusszeugnis | View über `projekt_stunden` |
| Projektevaluation | Feedback von Schülern und Lehrern | `projekt_evaluationen` |

---

## 10. Zusammenfassung der Projektstruktur

```
projektstunden-nrw/
├── sql/
│   ├── 01_schema.sql          Datenbankstruktur (alle Tabellen)
│   └── 02_seed.sql            Grunddaten: Fächer, MKR NRW, Mathematik KLP
├── backend/
│   ├── config.php             ← NICHT ins Git! (Passwörter)
│   ├── config.example.php     ← Ins Git (Platzhalter)
│   └── api/
│       └── index.php          REST-API (PHP, kein Framework)
├── frontend/
│   ├── index.html             Single-Page-App (Vanilla JS)
│   └── .htaccess              Apache URL-Routing
├── docs/
│   └── ANLEITUNG.md           Diese Datei
└── .gitignore
```
