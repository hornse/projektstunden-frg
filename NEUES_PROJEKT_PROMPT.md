# Bootstrap-Prompt für neue Schulprojekte (Vorlage)

> Diesen Text an den **Anfang eines neuen Projekt-Chats** kopieren. Er beschreibt
> alle Rahmenbedingungen, die für meine (bestehenden) Projekte gelten, damit sofort
> klar ist, in welcher Umgebung, mit welchem Stack und welchen Konventionen gearbeitet
> wird. Die mit «…» markierten Stellen für das jeweilige neue Projekt ausfüllen.

---

## 0. Auftrag an Claude

Du unterstützt mich (Sebastian Horn, IT-Administrator und Lehrer am
Friedrich-Rückert-Gymnasium Düsseldorf) bei der Entwicklung einer Webanwendung.
Das neue Projekt orientiert sich **eng an meinen bestehenden Projekten** (z. B.
„Projektstunden NRW"). Halte dich an die unten beschriebenen Rahmenbedingungen,
Konventionen und Fallstricke, ohne dass ich sie erneut erklären muss. Frag nach,
wenn ein projektspezifischer Wert («…») fehlt.

## 1. Neues Projekt – auszufüllen

| Was | Wert |
|---|---|
| **App-Name** | «…» |
| **Zweck / Kurzbeschreibung** | «…» |
| **Lokaler Pfad** | `/Users/sebastianhorn/Projekte/«projektname»` |
| **Domain** | `«projektname».hornse.de` |
| **Port** (built-in PHP-Server) | `«80xx»` (eindeutig, nicht doppelt belegen) |
| **Datenbank** | `hornse_«projektname»` (MariaDB) |
| **GitHub-Repo** | `hornse/«projektname»` (privat) |
| **Braucht WebUntis-Login?** | ja / nein |

## 2. Infrastruktur (fix, für alle Projekte gleich)

- **Hosting:** Uberspace 7, Server `halimede.uberspace.de`, Account `hornse`.
- **Laufzeit:** PHP built-in Server via **supervisord**, nicht Apache direkt
  (wegen sauberem URL-Routing). Config: `~/etc/services.d/«projektname».ini`
  mit `command=php -S 0.0.0.0:«PORT» /home/hornse/«projektname»/backend/router.php`.
  Danach `supervisorctl reread && supervisorctl update`.
- **Web-Backend-Weiterleitung:**
  `uberspace web backend set «projektname».hornse.de/ --http --port «PORT»`.
- **SSL** wird von Uberspace **vor** PHP terminiert (wichtig, siehe Fallstricke).
- **DB-Zugang:** MariaDB-Passwort steht auf dem Server in `~/.my.cnf`.

## 3. Stack & Konventionen (fix)

- **Backend:** PHP 8.1+, **kein Framework**, eigener Router + eigener API-Router,
  Datenbankzugriff via **PDO**.
- **Frontend:** Vanilla JS / HTML / CSS, **kein Build-Schritt**.
- **Gesamtes JavaScript gehört in `frontend/app.js`** – nicht ins HTML einbetten
  (Uberspace-Proxy begrenzt HTML auf ~63 KB).
- **Datenbank:** MariaDB, nummerierte SQL-Dateien (siehe unten).

### Verzeichnisstruktur (Vorlage)
```
«projektname»/
├── backend/
│   ├── router.php          ← HTTPS + session_name GANZ OBEN (kritisch!)
│   ├── config.php          ← NICHT in git (.gitignore)
│   ├── config.example.php  ← Vorlage in git
│   └── api/index.php       ← API-Router + Handler
├── frontend/
│   ├── index.html          ← SPA-Gerüst (kein JS!)
│   └── app.js              ← gesamtes JavaScript
├── sql/
│   ├── 01_schema.sql
│   ├── 02_seed.sql
│   └── NN_migration_*.sql / NN_seed_*.sql   ← fortlaufend nummeriert
├── docs/
├── deploy.sh
└── .gitignore
```

## 4. Git- & Deploy-Workflow (fix)

- **Bare Repo auf dem Server:** `/home/hornse/repos/«projektname».git`,
  Work-Tree `/home/hornse/«projektname»` (Deploy per Post-Receive-Hook / checkout).
- **GitHub** zusätzlich als privates Remote.
- **Deploy-Skript:** `./deploy.sh "Commit-Nachricht"` – setzt Cache-Busting-Timestamp
  in `index.html`, macht `git add -A`, commit, dann `git push github main &&
  git push uberspace main`.
- **Wichtig:** `deploy.sh` überträgt nur **Dateien**. DB-Migrationen/Seeds werden
  **separat** auf dem Server eingespielt: `mysql hornse_«projektname» < sql/NN_*.sql`.
- **`config.php`** liegt nicht in git und muss nach frischem Deploy einmalig aus
  `config.example.php` erzeugt und mit DB-Passwort (aus `~/.my.cnf`) befüllt werden.

## 5. Kritische Fallstricke (immer beachten)

1. **`router.php` – zwei Zeilen ganz oben, vor jedem `require`:**
   ```php
   $_SERVER['HTTPS'] = 'on';        // Uberspace terminiert SSL vor PHP
   session_name('«proj»_session');  // sonst Session-Verlust nach Login
   ```
2. **Nie `empty()` für IDs, die 0 sein dürfen** (z. B. WebUntis-Lehrer mit id=0):
   `if (!isset($_SESSION['benutzer_id']) || $_SESSION['benutzer_id'] === null)`.
3. **`session.save_path` per `~/etc/php.d/sessions.ini`** setzen, nicht per
   `ini_set()` (greift bei PHP-FPM zu spät):
   `session.save_path = /home/hornse/tmp/sessions`.
4. **JavaScript nur in `app.js`** (63-KB-HTML-Limit des Proxys).
5. **SQL-Migrationen idempotent** schreiben (`ADD COLUMN IF NOT EXISTS`, …).
   In **MariaDB** gehört `COMMENT` in der Spaltendefinition **vor** `AFTER …`
   (nicht danach – sonst Syntaxfehler 1064). Seeds mit `INSERT IGNORE` bzw.
   idempotentem `DELETE … ; INSERT …` in einer Transaktion.
6. **Debug:** Server-Log via `supervisorctl tail «projektname» stderr | tail -20`
   (bei `<!DOCTYPE` statt JSON steckt meist ein PHP-500 dahinter).

## 6. WebUntis-Login (nur falls benötigt)

- Config-Werte: `base_url` (`https://«schule».webuntis.com`), `school`, `client`,
  `allowed_person_types`, `admin_kuerzel`.
- Rollen-Mapping: personType **2** → Lehrkraft/`lernbegleiter`, **16** → Admin
  (hat `personId = -1`, kein Eintrag in `getTeachers()` → Name aus DB per Kürzel),
  **5** → Schüler (`key` = Schild-ID, Abgleich mit `schueler.schild_id`).
- **`JSESSIONID`** aus der `authenticate`-Antwort speichern und bei allen
  Folgeaufrufen (`getTeachers`, `getStudents`, `logout`) mitschicken.
- `getStudents()` liefert (an dieser Instanz) **kein** `idOfClass`; die `klasseId`
  kommt nur beim Schüler-Login in der `authenticate`-Antwort → Bulk-Sync
  mit Klassenzuordnung nicht möglich.
- Wiederverwendbares Modul: `hornse/webuntis-auth-php`.

## 7. Erwartete Arbeitsweise von Claude

- **Recherche zuerst** (offizielle Quellen/PDFs), erst dann Deliverables bauen.
- Bei jeder Änderung eine **Zip mit Zeitstempel** bereitstellen
  (`«projektname»_«thema»_YYYYMMDD_HHMMSS.zip`, Dateien mit Pfadstruktur),
  zusätzlich Kopie in `bundles/` (aus git ausgeschlossen).
- **Deploy-Befehl** + separate **DB-Schritte** immer explizit angeben.
- Generierte Massendaten (SQL-Seeds) vor Auslieferung **verifizieren**
  (z. B. Testlauf gegen eine SQL-Engine, Zähl-/Konsistenzprüfungen).
- Vorlage-Repo für den Projektstart: `hornse/schulprojekt-template`.

---

*Rekonstruiert am «Datum» aus den Rahmenbedingungen von „Projektstunden NRW".*
