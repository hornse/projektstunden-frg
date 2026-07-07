# Benutzerhandbuch – Projektstunden NRW

---

## Schnelleinstieg

1. URL aufrufen: `https://projektstunden.hornse.de`
2. E-Mail und Passwort eingeben → **Anmelden**
3. Dashboard zeigt Stundenkontingent aller Schüler
4. Erste Werkstatt anlegen: Navigation → **Werkstätten** → **+ Neue Werkstatt**

---

## Navigation

| Menüpunkt | Wer sieht es | Funktion |
|---|---|---|
| Dashboard | alle | Stunden und Kompetenzen je Schüler |
| Werkstätten | alle | Liste, Anlegen, Bearbeiten |
| Bewertungen | alle | Fremdeinschätzung + Rückmeldungen |
| Schüler verwalten | alle | Schüler anlegen/entfernen |
| Klassen | alle | Klassen einsehen |
| Kompetenzkatalog | alle | KLPs und MKR ansehen |
| Export | alle | CSV-Exporte |
| Schuljahre | nur Admin | Schuljahre verwalten |
| Schüler importieren | nur Admin | CSV aus Schild-NRW |
| Benutzerverwaltung | nur Admin | Konten verwalten |

---

## Dashboard

Zeigt für jeden Schüler:
- **Stundenkontingent** je Fach: Ist-Stunden / Soll-Stunden mit Fortschrittsbalken
- **Erworbene Kompetenzen** als farbige Pillen (MKR / KLP)

> Stunden und Kompetenzen werden nur angezeigt wenn die Werkstatt
> `status = abgeschlossen` hat oder der Schüler individuell als
> „absolviert" markiert wurde.

**Filter:** Klasse und Schüler über Dropdowns einschränken.

---

## Werkstätten

### Übersicht

Zeigt alle eigenen Werkstätten (Admins sehen alle). Filter nach Schuljahr
oben rechts. Jede Card zeigt: Name, Datum, Klassen, Schuljahr, Lernbegleiter,
Präsentationsdatum, Laufzeit, Kompetenzanzahl, Status.

### Neue Werkstatt anlegen

1. **+ Neue Werkstatt** klicken → Formular klappt auf
2. **Pflichtfelder:** Werkstattname, mind. eine Klasse, Startdatum,
   mind. ein Lernbegleiter
3. **Klassen** – Strg/Cmd für Mehrfachauswahl (jahrgangsübergreifend möglich)
4. **Lernbegleiter** – erster Eintrag wird automatisch als Leitung gesetzt
5. **Max. Teilnehmer** – optional; wird beim Speichern geprüft
6. **Stunden je Fach** – nur beteiligte Fächer ausfüllen
7. **Kompetenzen** – erst Fächer mit Stunden eintragen, dann erscheinen
   die passenden KLP-Tabs; MKR ist immer verfügbar
8. **Schüler** – erscheinen nach Klassen-Auswahl; Strg/Cmd für Mehrfachauswahl
9. **Werkstatt speichern** → Formular klappt zu, Werkstatt erscheint in Liste

### Details und Statusänderung

Klick auf **Details**-Button öffnet ein Modal:
- **Status** ändern und speichern
- **Teilnehmer** einzeln oder alle als „✓ absolviert" markieren
- **✏️ Bearbeiten** – öffnet vollständige Bearbeiten-Seite
- **Löschen** – nur für Admins

### Werkstatt bearbeiten

Öffnet die gleiche Ansicht wie beim Anlegen, vorausgefüllt:
- Alle Stammdaten änderbar
- Stunden je Fach aktualisierbar
- Kompetenzen hinzufügen/entfernen
- **Änderungen speichern** → zurück zur Werkstattliste

---

## Bewertungen & Rückmeldungen

### Werkstatt wählen

Dropdown oben: Werkstatt auswählen → Bewertungstabelle und Rückmeldungsbereich
erscheinen.

### Bewertungstabelle

- **Zeilen:** Schüler/innen (alphabetisch nach Nachname)
- **Spalten:** Kompetenzen der Werkstatt (Code oder Kurzname; Tooltip zeigt Volltext)
- **Chips:** 1–4 anklicken um Stufe zu setzen; nochmal klicken entfernt sie

| Stufe | Farbe | Bedeutung |
|---|---|---|
| 1 | rot | Mit Unterstützung |
| 2 | gelb | Teilweise selbstständig |
| 3 | grün | Weitgehend sicher |
| 4 | blau | Sicher und reflektiert |

Bewertungen werden sofort gespeichert (kein Speichern-Button nötig).

> Die Tabelle hat horizontalen Scroll wenn viele Kompetenzen vorhanden sind.
> Schülernamen bleiben links fixiert.

### Rückmeldungen

**Neue Rückmeldung erstellen:**
1. **Empfänger** auswählen (Checkboxen; „Alle auswählen" / „Alle abwählen")
2. **Bewertungsstufe** optional wählen (Gesamteinschätzung)
3. **Freitext** eingeben
4. **Für Schüler sichtbar** – direkt aktivieren oder später umschalten
5. **Rückmeldung speichern**

Pro Schüler wird eine Rückmeldung gespeichert (UPSERT: erneutes Speichern
überschreibt die vorherige).

**Sichtbarkeit** – Checkbox „sichtbar" neben jeder vorhandenen Rückmeldung
umschalten um zu steuern ob der Schüler es sehen kann.

---

## Schüler verwalten

### Manuell anlegen

Vorname, Nachname, Klasse ausfüllen → **Hinzufügen**.

### CSV-Import (nur Admin)

Navigation → **Schüler importieren**:
1. Schuljahr wählen (aktives Schuljahr vorausgewählt)
2. CSV-Datei aus Schild-NRW hochladen
3. **Vorschau** prüfen: neu / aktualisiert / unverändert / Fehler
4. **Import durchführen**

Schüler die nicht mehr in der CSV erscheinen werden automatisch inaktiviert.
Das Import-Log zeigt die letzten 20 Importe mit Statistik.

**Benötigte CSV-Felder:** Interne ID-Nummer, Vorname, Nachname, Klasse,
Jahrgang, Geschlecht, Geburtsdatum, Klassenlehrer: Name, Klassenlehrer: Vorname

---

## Schuljahre (nur Admin)

- **Anlegen** – Name (z. B. `2026/27`), Beginn, Ende, Status
- **Aktivieren** – nur ein Schuljahr kann aktiv sein; vorheriges wird
  automatisch abgeschlossen
- **Löschen** – nur wenn keine Werkstätten oder Schüler zugeordnet sind

---

## Benutzerverwaltung (nur Admin)

- **Anlegen** – Vorname, Nachname, E-Mail, Passwort, Rolle (Admin/Lernbegleiter)
- **Bearbeiten** – Stammdaten und Rolle ändern
- **Deaktivieren** – Soft-Delete; Daten bleiben erhalten
- **Passwort ändern** – Admin: alle Passwörter; Lernbegleiter: nur eigenes

Passwort-Anforderungen: mind. 8 Zeichen, 1 Großbuchstabe, 1 Zahl.

---

## Export

- **Stundenkontingent** – CSV mit allen Schülern, Stunden je Fach, Gesamtsumme
- **Kompetenzen** – CSV mit allen Schülern, erworbenen Kompetenzen je Werkstatt

Beide Exporte sind Excel-kompatibel (UTF-8 BOM, Semikolon-getrennt).
Optional nach Klasse filtern.

---

## Kompetenzkatalog

Zeigt alle verfügbaren Kompetenzrahmen (KLPs und MKR) mit Bereichen und
konkreten Erwartungen. Nur lesend – Änderungen über die Datenbank.

---

## Häufige Fragen (FAQ)

**Warum sehe ich keine Stunden im Dashboard?**
Die Werkstatt muss auf `abgeschlossen` gesetzt sein oder der Schüler
muss individuell als „absolviert" markiert sein.

**Warum erscheint kein KLP-Tab beim Anlegen?**
KLP-Tabs erscheinen erst wenn beim zugehörigen Fach Stunden eingetragen wurden.
MKR ist immer verfügbar.

**Warum kann ich die Werkstatt eines Kollegen nicht sehen?**
Lernbegleiter sehen nur Werkstätten bei denen sie als Lernbegleiter eingetragen
sind. Admins sehen alle Werkstätten.

**Wie ändere ich den Status einer Werkstatt?**
Details-Button auf der Werkstattkarte → Status-Dropdown → Speichern.

**Kann ich mehr Schüler zuweisen als das Maximum erlaubt?**
Nein – die App prüft beim Speichern ob die Anzahl das Limit überschreitet
und zeigt eine Fehlermeldung.

**Wie kann ich einer Werkstatt Schüler aus mehreren Klassen zuweisen?**
Im Klassen-Feld Strg/Cmd gedrückt halten und mehrere Klassen anklicken.
Die Schülerliste zeigt dann alle Schüler aus allen gewählten Klassen.

**Warum sieht ein Schüler seine Rückmeldung nicht?**
Die Rückmeldung muss als „sichtbar" markiert sein. Im Bewertungs-Screen
die Checkbox „sichtbar" neben der Rückmeldung aktivieren.

**Kann ich eine Rückmeldung ändern?**
Ja – einfach erneut speichern. Pro Schüler wird die Rückmeldung überschrieben.

**Wie importiere ich Schüler aus Schild-NRW?**
Navigation → Schüler importieren → CSV hochladen → Vorschau prüfen →
Import durchführen. Klassen werden automatisch angelegt.

**Was passiert wenn ich einen Schüler entferne?**
Soft-Delete: Der Schüler wird inaktiv gesetzt, alle Daten bleiben erhalten.

---

## Datenschutzhinweis

Gespeichert werden ausschließlich schulbezogene Koordinationsdaten:
Schülernamen, Klassen, Projektstunden, Kompetenzen, Bewertungen, Rückmeldungen.
Kein Tracking. Alle Daten verbleiben auf dem Schulserver (Uberspace).
