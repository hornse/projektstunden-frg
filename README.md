# Projektstunden NRW

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Eine Web-App zur Verwaltung von Projektstunden an NRW-Schulen: Werkstätten
anlegen, Schüler zuordnen, Projektstunden auf Fächer anrechnen, Kompetenzen
aus KLPs und MKR dokumentieren, Bewertungen vergeben und Rückmeldungen schreiben.

Entwickelt von einem Lehrer und IT-Verantwortlichen am Friedrich-Rückert-Gymnasium
Düsseldorf, mit Unterstützung von [Claude](https://claude.ai) (Anthropic).

---

## Kernkonzept

Schülerinnen und Schüler in NRW absolvieren fächerübergreifende Projektstunden,
die auf das Stundenkontingent verschiedener Fächer angerechnet werden. Die App
bildet diesen Prozess vollständig ab:

| Schritt | Was die App macht |
|---|---|
| Schüler importieren | CSV-Import aus Schild-NRW, automatische Klassen-Anlage |
| Werkstatt anlegen | Name, Schuljahr, Laufzeit, Klassen, Lernbegleiter, Teilnehmer |
| Stunden anrechnen | Projektstunden auf Fächer verteilen |
| Kompetenzen vergeben | KLPs und MKR je Schüler dokumentieren |
| Bewerten | 4-stufige Fremdeinschätzung pro Schüler und Kompetenz |
| Rückmeldung | Strukturiert + Freitext, steuerbar wer es sieht |
| Übersicht | Dashboard zeigt Soll/Ist je Schüler und Fach |
| Export | CSV-Export für Stunden und Kompetenzen |

---

## Was die App kann

**Werkstätten:**
- Mehrere Werkstätten gleichzeitig, je mit Schuljahr, Laufzeit, Präsentationsdatum
- Mehrere Lernbegleiter pro Werkstatt (Leitung + Begleitung)
- Multi-Klassen-Auswahl – jahrgangs- und klassenübergreifende Werkstätten
- Max-Teilnehmerzahl als Limit setzbar
- Zugangskontrolle: Lernbegleiter sehen nur eigene Werkstätten
- Status: geplant / aktiv / abgeschlossen / abgesagt
- Teilnehmer einzeln oder alle als „absolviert" markieren

**Bewertungen & Rückmeldungen:**
- 4-stufige Fremdeinschätzung pro Schüler und Kompetenz (farbige Chips)
- Rückmeldungen persistent gespeichert: Bewertungsstufe + Freitext
- Empfänger wählbar: alle / einzelner Schüler / Teilmenge
- Sichtbarkeit für Schüler steuerbar

**Schüler und Klassen:**
- CSV-Import aus Schild-NRW mit Vorschau vor dem Import
- Automatische Klassen-Anlage beim Import
- Schüler inaktivieren wenn nicht mehr in CSV vorhanden
- Import-Log mit Statistik

**Kompetenzrahmen:**
- KLPs (fachspezifisch) und MKR (fächerübergreifend)
- Initial nur MKR; KLP-Tabs erscheinen nach Fachauswahl
- Kompetenzen mit aufklappbaren konkreten Erwartungen

**Dashboard und Export:**
- Stundenkontingent Soll/Ist je Schüler und Fach (nur abgeschlossene Werkstätten)
- CSV-Export für Stundenkontingent und Kompetenznachweis (Excel-kompatibel)

---

## Berechtigungsmodell

| Aktion | Admin | Lernbegleiter |
|---|---|---|
| Schuljahr anlegen/aktivieren | ✓ | – |
| Schüler importieren (CSV) | ✓ | – |
| Benutzer verwalten | ✓ | – |
| Werkstatt anlegen | ✓ | ✓ |
| Eigene Werkstatt bearbeiten | ✓ | ✓ (Leitung) |
| Alle Werkstätten sehen | ✓ | – (nur eigene) |
| Kompetenzen vergeben | ✓ | ✓ (eigene WS) |
| Bewertungen & Rückmeldungen | ✓ | ✓ (eigene WS) |
| Dashboard / Export | ✓ | ✓ |

---

## Navigation

- **Dashboard** – Stundenkontingent und Kompetenzen je Schüler
- **Werkstätten** – Liste, Anlegen, Bearbeiten, Detailansicht
- **Bewertungen** – Fremdeinschätzung und Rückmeldungen je Werkstatt
- **Schüler verwalten** – manuell anlegen oder per CSV importieren
- **Klassen** – Klassen anlegen (Admin)
- **Kompetenzkatalog** – KLPs und MKR einsehen
- **Export** – CSV-Exporte
- **Schuljahre** – verwalten und aktivieren (Admin)
- **Schüler importieren** – CSV aus Schild-NRW (Admin)
- **Benutzerverwaltung** – Konten anlegen und verwalten (Admin)

---

## Technischer Überblick

| Schicht | Technologie |
|---|---|
| Frontend | Vanilla JS/HTML/CSS, kein Build-Schritt |
| Backend | PHP ohne Framework, eigener Router |
| Datenbank | MariaDB 10.6 (PDO MySQL) |
| Authentifizierung | E-Mail + bcrypt-Passwort |
| Hosting | Uberspace 7 (empfohlen) |

---

## Sicherheitsmaßnahmen

- Prepared Statements für alle SQL-Abfragen
- Session-Hardening (HttpOnly, SameSite, session_regenerate_id)
- Soft-Delete statt physischem Löschen bei Schülern und Benutzern
- Audit-Log für alle schreibenden Operationen
- Zugangskontrolle auf Werkstatt-Ebene

---

## Datenbankschema

```
schulen                       – Mandant (eine Schule)
benutzer                      – Admin und Lernbegleiter (bcrypt)
schuljahre                    – Schuljahre mit Status
klassen                       – Klassen je Schuljahr
schueler                      – Schüler mit Schild-ID
schueler_schuljahr            – Schüler-Klassen-Zuordnung je Schuljahr
import_log                    – Protokoll der CSV-Importe
projekte                      – Werkstätten mit Schuljahr, Laufzeit, Status
projekt_lehrer                – Lernbegleiter je Werkstatt (Leitung/Begleitung)
projekt_klassen               – Mehrere Klassen pro Werkstatt
projekt_schueler              – Teilnehmer je Werkstatt (mit abgeschlossen-Flag)
projekt_stunden               – Stunden je Fach und Werkstatt
faecher                       – Fächer mit Stunden-Soll je Jahrgang
kompetenzrahmen               – KLPs und MKR
kompetenzbereiche             – Bereiche je Rahmen
kompetenzen                   – Einzelkompetenzen mit konkreten Erwartungen
projekt_schueler_kompetenzen  – Kompetenzen je Schüler+Werkstatt (fremd_stufe)
bewertungsstufen              – 4-stufige Skala
werkstatt_rueckmeldungen      – Rückmeldungen je Schüler pro Werkstatt
audit_log                     – Protokoll aller schreibenden Operationen
```

---

## Schnellstart (lokal)

```bash
DB=backend/datenbank.sqlite
mysql hornse_projektstunden < sql/01_schema.sql
mysql hornse_projektstunden < sql/02_seed.sql
mysql hornse_projektstunden < sql/03_migration_schuljahr_schueler_werkstatt.sql
mysql hornse_projektstunden < sql/04_migration_werkstatt_detail.sql
mysql hornse_projektstunden < sql/05_migration_rueckmeldungen.sql
mysql hornse_projektstunden < sql/09_seed_sport_konkrete_erwartungen.sql
php -S localhost:8082 backend/router.php
```

## Deployen (Uberspace)

```bash
./deploy.sh "Beschreibung der Änderung"
```

Das Script aktualisiert automatisch den Cache-Busting-Timestamp in `frontend/index.html`
und pusht auf GitHub und Uberspace. Details zur Uberspace-Konfiguration
in `deploy/uberspace.md`.

---

## Lizenz

Copyright (C) 2026 Sebastian Horn, Friedrich-Rückert-Gymnasium Düsseldorf
GNU General Public License v3.0 – Details siehe [LICENSE](LICENSE).

Entwickelt mit Unterstützung von [Claude](https://claude.ai) (Anthropic).
