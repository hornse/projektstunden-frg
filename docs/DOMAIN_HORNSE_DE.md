# Domain hornse.de auf Uberspace einrichten
## Schritt-für-Schritt-Anleitung

---

## Überblick: Was passiert hier?

```
Browser                    DNS                      Uberspace
hornse.de       →    A-Record → Uberspace-IP  →   Apache
projektstunden.hornse.de → gleiche IP          →   eigener vHost
```

Uberspace hostet die App; dein Domain-Registrar (z. B. IONOS, Strato, Hetzner)
zeigt die Domain per DNS-Eintrag auf den Uberspace-Server.

---

## Schritt 1 – Uberspace-IP-Adresse ermitteln

```bash
# Per SSH einloggen
ssh DEIN_USER@DEIN_HOST.uberspace.de

# IPv4-Adresse des Servers herausfinden
dig +short DEIN_USER.uber.space A
# oder
host DEIN_USER.uber.space | grep "has address"
```

Notiere dir die angezeigte IP-Adresse, z. B. `185.26.156.XXX`.

---

## Schritt 2 – DNS beim Domain-Registrar einrichten

Logge dich beim Registrar ein, bei dem `hornse.de` registriert ist,
und lege folgende DNS-Einträge an:

### Option A: Hauptdomain (hornse.de direkt)

| Typ    | Name  | Wert                   | TTL  |
|--------|-------|------------------------|------|
| A      | @     | `185.26.156.XXX`       | 3600 |
| A      | www   | `185.26.156.XXX`       | 3600 |
| AAAA   | @     | (IPv6 von Uberspace)   | 3600 |
| AAAA   | www   | (IPv6 von Uberspace)   | 3600 |

### Option B: Subdomain (projektstunden.hornse.de) – empfohlen

Falls hornse.de bereits anderweitig genutzt wird:

| Typ    | Name               | Wert              | TTL  |
|--------|--------------------|-------------------|------|
| A      | projektstunden     | `185.26.156.XXX`  | 3600 |
| AAAA   | projektstunden     | (IPv6 Uberspace)  | 3600 |

```bash
# IPv6 des Servers:
dig +short DEIN_USER.uber.space AAAA
```

**Hinweis:** DNS-Änderungen benötigen je nach Registrar 15 Minuten bis 24 Stunden,
bis sie weltweit aktiv sind (TTL-abhängig).

---

## Schritt 3 – Domain bei Uberspace registrieren

Uberspace muss wissen, dass Anfragen für `hornse.de` zu deinem Account gehören.

```bash
# Per SSH auf dem Uberspace:

# Hauptdomain einrichten
uberspace web domain add hornse.de
uberspace web domain add www.hornse.de

# ODER Subdomain:
uberspace web domain add projektstunden.hornse.de
```

Uberspace zeigt dann an, welche IP-Adresse du im DNS eintragen musst
(zur Bestätigung).

```bash
# Prüfen welche Domains registriert sind:
uberspace web domain list
```

---

## Schritt 4 – HTTPS / SSL-Zertifikat

Uberspace stellt automatisch ein Let's-Encrypt-Zertifikat aus,
**sobald die DNS-Einträge aktiv sind und der Domain-Check erfolgreich war**.

```bash
# Status prüfen (kann einige Minuten dauern nach DNS-Aktivierung):
uberspace web domain list
# Zeigt an: hornse.de  ✓ SSL aktiv

# Manuell anstoßen falls nötig:
uberspace web certificate renew
```

Nach erfolgreicher Zertifikatsausstellung ist die App erreichbar unter:
```
https://hornse.de
https://www.hornse.de
# oder
https://projektstunden.hornse.de
```

---

## Schritt 5 – DocumentRoot konfigurieren

Standardmäßig liegt das Web-Root bei Uberspace unter `~/html`.
Für die Projektstunden-App gibt es zwei Varianten:

### Variante A: App direkt unter hornse.de

```bash
# Dateien direkt ins Web-Root kopieren
cp ~/projektstunden/frontend/index.html ~/html/index.html
cp ~/projektstunden/frontend/.htaccess  ~/html/.htaccess

# Backend-Wrapper anlegen
mkdir -p ~/html/backend/api
cat > ~/html/backend/api/index.php << 'EOF'
<?php
// Weiterleitung an den API-Router außerhalb des Web-Roots
require_once __DIR__ . '/../../../projektstunden/backend/api/index.php';
EOF
```

### Variante B: App in einem Unterverzeichnis (hornse.de/projektstunden)

```bash
mkdir -p ~/html/projektstunden
cp ~/projektstunden/frontend/index.html ~/html/projektstunden/index.html
cp ~/projektstunden/frontend/.htaccess  ~/html/projektstunden/.htaccess

mkdir -p ~/html/projektstunden/backend/api
cat > ~/html/projektstunden/backend/api/index.php << 'EOF'
<?php
require_once __DIR__ . '/../../../../projektstunden/backend/api/index.php';
EOF
```

Passe dann in `config.php` den `ALLOWED_ORIGIN` an:
```php
define('ALLOWED_ORIGIN', 'https://hornse.de');
// oder
define('ALLOWED_ORIGIN', 'https://projektstunden.hornse.de');
```

---

## Schritt 6 – .htaccess für die Domain anpassen

Die mitgelieferte `.htaccess` funktioniert ohne Änderung, wenn die App
im DocumentRoot liegt. Bei Unterverzeichnis `RewriteBase` anpassen:

```apache
# Variante B (Unterverzeichnis):
RewriteBase /projektstunden/

RewriteRule ^api/(.*)$ backend/api/index.php/$1 [QSA,L]

RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^(?!api/)(.*)$ index.html [QSA,L]
```

---

## Schritt 7 – Vollständige Verzeichnisstruktur auf dem Server

Nach Abschluss aller Schritte sieht die Struktur so aus:

```
/home/DEIN_USER/
├── projektstunden/              ← NICHT öffentlich (außerhalb ~/html)
│   ├── backend/
│   │   ├── config.php           ← DB-Zugangsdaten (nie ins Git!)
│   │   └── api/
│   │       └── index.php        ← API-Logik
│   ├── sql/
│   │   ├── 01_schema.sql
│   │   └── 02_seed.sql
│   └── docs/
│       └── ANLEITUNG.md
└── html/                        ← Öffentlich erreichbar (Web-Root)
    ├── .htaccess
    ├── index.html               ← Frontend SPA
    └── backend/
        └── api/
            └── index.php        ← Wrapper → leitet weiter an ~/projektstunden/backend/api/
```

---

## Schritt 8 – Alles testen

```bash
# DNS-Propagation prüfen (von extern):
dig hornse.de A
# oder online: https://www.whatsmydns.net/#A/hornse.de

# HTTP → HTTPS Weiterleitung testen:
curl -I http://hornse.de
# Erwartete Antwort: 301 Moved Permanently → https://hornse.de

# API testen:
curl -s https://hornse.de/api/auth/me
# Erwartete Antwort: {"error":"Nicht eingeloggt."} (401)
# Das ist korrekt! Bedeutet: API antwortet.

# Login testen:
curl -X POST https://hornse.de/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"deine@email.de","passwort":"DeinPasswort123!"}' \
  -c /tmp/cookies.txt -b /tmp/cookies.txt
# Erwartete Antwort: {"ok":true,"vorname":"...","rolle":"admin"}
```

---

## Schritt 9 – config.php final anpassen

```php
// ~/projektstunden/backend/config.php

define('DB_HOST', '127.0.0.1');
define('DB_NAME', 'DEIN_USER');           // Uberspace: DB-Name = Benutzername
define('DB_USER', 'DEIN_USER');           // aus ~/.my.cnf
define('DB_PASS', 'DEIN_DB_PASSWORT');    // aus ~/.my.cnf

// Domain anpassen:
define('ALLOWED_ORIGIN', 'https://hornse.de');
```

---

## Schritt 10 – Automatische Deployments mit Git (optional)

```bash
# Auf dem Uberspace: Git-Remote einrichten
cd ~/projektstunden
git remote add origin https://github.com/DEIN_GITHUB/projektstunden-nrw.git
git pull origin main

# Update-Skript anlegen
cat > ~/update-projektstunden.sh << 'EOF'
#!/bin/bash
cd ~/projektstunden
git pull origin main
# Frontend ins Web-Root kopieren (config.php wird NICHT überschrieben, da in .gitignore)
cp frontend/index.html ~/html/index.html
cp frontend/.htaccess  ~/html/.htaccess
echo "Update abgeschlossen: $(date)"
EOF
chmod +x ~/update-projektstunden.sh

# Ausführen bei jedem Update:
~/update-projektstunden.sh
```

---

## Zusammenfassung der wichtigsten Befehle

```bash
# Domain registrieren
uberspace web domain add hornse.de

# Zertifikat-Status
uberspace web domain list

# Datenbank-Backup
mysqldump projektstunden | gzip > ~/backups/backup_$(date +%Y%m%d).sql.gz

# PHP-Fehlerlog
tail -f ~/logs/error.log

# App-Update aus Git
~/update-projektstunden.sh
```

---

## Häufige Probleme

| Problem | Ursache | Lösung |
|---|---|---|
| Seite lädt nicht | DNS noch nicht propagiert | Bis zu 24h warten; `dig hornse.de` prüfen |
| Kein SSL-Zertifikat | DNS noch nicht aktiv | DNS abwarten, dann `uberspace web certificate renew` |
| API antwortet mit 500 | config.php falsch | `tail ~/logs/error.log` |
| API antwortet mit 404 | .htaccess fehlt | .htaccess ins Web-Root kopieren |
| Login schlägt fehl | Falsches Passwort-Hash | Neuen Hash mit `php -r "echo password_hash(...);"` erzeugen |
| Zeichensalat | Falsche DB-Encoding | `ALTER DATABASE projektstunden CHARACTER SET utf8mb4;` |
