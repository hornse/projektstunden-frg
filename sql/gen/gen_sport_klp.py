#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Erzeuger: Sport, Kernlehrplan Gymnasium Sekundarstufe I (G9) NRW.

Liest das Quell-PDF, wandelt es mit `pdftotext -layout` in Text und schreibt
daraus sql/12_seed_sport_klp.sql.

Aufruf aus der Projektwurzel:
    python3 sql/gen/gen_sport_klp.py

Das Skript schreibt die Seed-Datei nur, wenn alle Zaehlwerte stimmen. Weicht
eine einzige Gliederungseinheit ab, bricht es ab und schreibt nichts
(REIHENREGELN 2).

Eigenheiten des Sport-Plans, alle am Dokument belegt:

  * **Das Aufzaehlungszeichen ist `à`**, nicht `•` -- ein falsch dekodierter
    Wingdings-Pfeil. Es kommt 120-mal vor, ausschliesslich am Zeilenanfang.
    `•` steht 20-mal im Dokument, aber an anderer Stelle.
  * **`–` leitet inhaltliche Schwerpunkte und Kerne ein**, keine
    Kompetenzerwartungen. 108 Vorkommen, die nicht mitgezaehlt werden duerfen.
  * **Drei `à`-Zeilen beginnen mit einem Seitenumbruch (\x0c)**, nicht mit
    einem Leerzeichen. Wer nur `^ *à` sucht, verliert diese drei.
  * **Zwei Achsen, ein Feld.** Unter 2.4.1/2.5.1 stehen die Inhaltsfelder a-f
    mit Sach-, Methoden- und Urteilskompetenz; unter 2.4.2/2.5.2 die
    Bewegungsfelder 1-9 mit der Bewegungs- und Wahrnehmungskompetenz. Die
    Ueberschriften "Bewegungsfeld uebergreifend" und "spezifisch" benennen
    diese beiden Achsen und sind keine weitere Ebene (E18). Genau dafuer
    fuehrt dieser Seed die Spalte `art`.

Copyright (C) 2026 Sebastian Horn, Friedrich-Rueckert-Gymnasium Duesseldorf
SPDX-License-Identifier: GPL-3.0-or-later
"""

import collections
import hashlib
import re
import shutil
import subprocess
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Feste Angaben zur Quelle (E19)
# ---------------------------------------------------------------------------
WURZEL = Path(__file__).resolve().parents[2]
QUELLE = Path("docs/curricula/g9_sp_klp_3426_2019_06_23.pdf")
QUELLE_SHA = "815f985166f45bc136ae3fc28aff4b0214b29b9862aa0eb33df312e32e950351"
ZIEL = Path("sql/12_seed_sport_klp.sql")
ERZEUGER = "sql/gen/gen_sport_klp.py"

RAHMEN_KUERZEL = "SPO_KLP"
RAHMEN_NAME = "Sport KLP NRW G9 Sek I (FRG)"
RAHMEN_BESCHREIBUNG = (
    "Kernlehrplan Sport, Gymnasium Sekundarstufe I (G9), NRW 2019. "
    "Kompetenzbereiche BWK/SK/MK/UK; sechs Inhaltsfelder (a-f) und neun "
    "Bewegungsfelder/Sportbereiche; gegliedert nach Erprobungsstufe und "
    "Ende Sek I."
)

# Sollzahlen je (Phase, Gegenstand, Kompetenzbereich).
# Unabhaengig vom Erzeuger durch Auszaehlen der `à`-Zeilen ermittelt. Weicht
# der Lauf ab, ist zuerst zu klaeren, welche Zaehlung falsch ist.
SOLL = {
    # Erprobungsstufe, Inhaltsfelder
    ("erprobungsstufe", "a", "SK"): 2, ("erprobungsstufe", "a", "MK"): 2, ("erprobungsstufe", "a", "UK"): 1,
    ("erprobungsstufe", "b", "SK"): 2, ("erprobungsstufe", "b", "MK"): 2, ("erprobungsstufe", "b", "UK"): 1,
    ("erprobungsstufe", "c", "SK"): 1, ("erprobungsstufe", "c", "MK"): 1, ("erprobungsstufe", "c", "UK"): 1,
    ("erprobungsstufe", "d", "SK"): 3, ("erprobungsstufe", "d", "MK"): 1, ("erprobungsstufe", "d", "UK"): 1,
    ("erprobungsstufe", "e", "SK"): 2, ("erprobungsstufe", "e", "MK"): 2, ("erprobungsstufe", "e", "UK"): 1,
    ("erprobungsstufe", "f", "SK"): 2, ("erprobungsstufe", "f", "MK"): 1, ("erprobungsstufe", "f", "UK"): 1,
    # Erprobungsstufe, Bewegungsfelder
    ("erprobungsstufe", "BF1", "BWK"): 4, ("erprobungsstufe", "BF2", "BWK"): 4,
    ("erprobungsstufe", "BF3", "BWK"): 3, ("erprobungsstufe", "BF4", "BWK"): 4,
    ("erprobungsstufe", "BF5", "BWK"): 3, ("erprobungsstufe", "BF6", "BWK"): 2,
    ("erprobungsstufe", "BF7", "BWK"): 3, ("erprobungsstufe", "BF8", "BWK"): 2,
    ("erprobungsstufe", "BF9", "BWK"): 2,
    # Sekundarstufe I, Inhaltsfelder
    ("zweite_stufe", "a", "SK"): 2, ("zweite_stufe", "a", "MK"): 3, ("zweite_stufe", "a", "UK"): 3,
    ("zweite_stufe", "b", "SK"): 2, ("zweite_stufe", "b", "MK"): 3, ("zweite_stufe", "b", "UK"): 2,
    ("zweite_stufe", "c", "SK"): 3, ("zweite_stufe", "c", "MK"): 2, ("zweite_stufe", "c", "UK"): 1,
    ("zweite_stufe", "d", "SK"): 3, ("zweite_stufe", "d", "MK"): 2, ("zweite_stufe", "d", "UK"): 2,
    ("zweite_stufe", "e", "SK"): 2, ("zweite_stufe", "e", "MK"): 3, ("zweite_stufe", "e", "UK"): 1,
    ("zweite_stufe", "f", "SK"): 2, ("zweite_stufe", "f", "MK"): 2, ("zweite_stufe", "f", "UK"): 1,
    # Sekundarstufe I, Bewegungsfelder
    ("zweite_stufe", "BF1", "BWK"): 4, ("zweite_stufe", "BF2", "BWK"): 2,
    ("zweite_stufe", "BF3", "BWK"): 4, ("zweite_stufe", "BF4", "BWK"): 3,
    ("zweite_stufe", "BF5", "BWK"): 3, ("zweite_stufe", "BF6", "BWK"): 3,
    ("zweite_stufe", "BF7", "BWK"): 4, ("zweite_stufe", "BF8", "BWK"): 2,
    ("zweite_stufe", "BF9", "BWK"): 2,
}

PHASEN_KUERZEL = {"erprobungsstufe": "EP", "zweite_stufe": "SI"}
PHASEN_NAME = {"erprobungsstufe": "Erprobungsstufe", "zweite_stufe": "Sekundarstufe I"}
BEREICH_KUERZEL = {
    "Sachkompetenz": "SK",
    "Methodenkompetenz": "MK",
    "Urteilskompetenz": "UK",
    "Bewegungs- und Wahrnehmungskompetenz": "BWK",
}
# Was in `inhaltsfeld` steht -- der Grund fuer die Spalte `art` (E18).
ART_INHALTSFELD = "inhaltsfeld"
ART_BEWEGUNGSFELD = "bewegungsfeld"

KURZNAME_GRENZE = 120          # reproduziert alle 120 Kurznamen des Bestands
ELLIPSE = {"und", "oder", "bzw.", "bzw", "sowie"}   # E22, Regel 1

# E25: alle C0-Steuerzeichen ausser Tabulator (\x09) und Zeilenumbruch (\x0a).
# Der Seitenumbruch (\x0c) wird vorher gesondert entfernt, weil er getilgt und
# nicht durch ein Leerzeichen ersetzt werden muss.
STEUERZEICHEN = re.compile(r"[\x00-\x08\x0b\x0d-\x1f\x7f]")


def fehler(text):
    print(f"FEHLER: {text}", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# 1 -- Quelle pruefen und umwandeln
# ---------------------------------------------------------------------------
def lies_pdf_als_text(pdf: Path) -> list:
    if not pdf.is_file():
        fehler(f"Quelle fehlt: {pdf}")
    ist = hashlib.sha256(pdf.read_bytes()).hexdigest()
    if ist != QUELLE_SHA:
        fehler(
            f"Pruefsumme weicht ab.\n  erwartet: {QUELLE_SHA}\n  gefunden: {ist}\n"
            "Das ist eine andere Datei als die, aus der die Sollzahlen stammen."
        )
    if shutil.which("pdftotext") is None:
        fehler(
            "pdftotext fehlt. Es wird ausdruecklich dieses Werkzeug verlangt: "
            "ein anderer Extraktor liefert andere Umbrueche als die, gegen die "
            "die Sollzahlen ermittelt wurden. Behebung: brew install poppler"
        )
    lauf = subprocess.run(
        ["pdftotext", "-layout", str(pdf), "-"], capture_output=True, check=False
    )
    if lauf.returncode != 0:
        fehler(f"pdftotext brach ab: {lauf.stderr.decode('utf-8', 'replace')}")
    text = lauf.stdout.decode("utf-8")

    # E25: Steuerzeichen vor allem anderen wegraeumen. Beide Formen sind
    # unsichtbar und wandern sonst stillschweigend in die Daten.
    #
    #  * Seitenumbruch \x0c: drei der 120 Aufzaehlungszeilen beginnen damit
    #    statt mit einem Leerzeichen. Ein Ausdruck `^ *à` verliert sie.
    #  * Uebrige C0-Steuerzeichen: an einer Stelle liefert pdftotext ein
    #    U+0003 statt eines Leerzeichens ("auf<U+0003>grundlegendem"). In
    #    Python ist das kein `\s`, die Normalisierung fasst es also nicht.
    #    Sie werden zu Leerzeichen, nicht geloescht -- sonst verschmelzen
    #    zwei Woerter zu einem.
    text = text.replace("\x0c", "")
    text = STEUERZEICHEN.sub(" ", text)
    return text.split("\n")


# ---------------------------------------------------------------------------
# 2 -- Wortschatz des Dokuments (E22, Regeln 2 und 3)
# ---------------------------------------------------------------------------
WORT = re.compile(r"[A-Za-zÄÖÜäöüß]+(?:-[A-Za-zÄÖÜäöüß]+)*")


def baue_wortschatz(zeilen) -> collections.Counter:
    schatz = collections.Counter()
    for zeile in zeilen:
        for treffer in WORT.finditer(zeile):
            schatz[treffer.group()] += 1
    return schatz


def linke_kompositumshaelften(schatz) -> frozenset:
    """E45: linke Haelften der im Dokument ungetrennt belegten
    Bindestrich-Komposita. `kritisch-konstruktiv` belegt `kritisch`.

    Am Zeilenende getrennte Woerter geraten nicht hinein: Dort steht der
    Bindestrich am Schluss, und WORT verlangt hinter ihm einen Buchstaben.

    NUR Belege mit KLEIN geschriebener rechter Haelfte zaehlen. Ein
    grossgeschriebener rechter Teil gehoert zu einer anderen Bauform: Bei
    Deutsch GOSt belegt `Autor-Rezipienten` sonst `Autor-`, und aus dem
    belegten `Autorschaft` wuerde `Autor-schaft`. Regel 5 entscheidet
    grossgeschriebene Fortsetzungen ohnehin schon -- Regel 6 braucht deshalb
    nur Belege ihrer eigenen Bauform.
    """
    aus = set()
    for wort in schatz:
        if "-" not in wort:
            continue
        links_, rechts_ = wort.split("-", 1)
        if rechts_[:1].islower():
            aus.add(links_)
    return frozenset(aus)


# ---------------------------------------------------------------------------
# 3 -- Aufbau des Kompetenzteils
# ---------------------------------------------------------------------------
SEITENZAHL = re.compile(r"^\s*\d{1,3}\s*$")
PHASENMARKE = [
    (re.compile(r"^2\.4 Kompetenzerwartungen"), "erprobungsstufe"),
    (re.compile(r"^2\.5 Kompetenzerwartungen"), "zweite_stufe"),
]
ACHSENMARKE = [
    (re.compile(r"^\s*2\.[45]\.1\s+Bewegungsfeld übergreifende"), ART_INHALTSFELD),
    (re.compile(r"^\s*2\.[45]\.2\s+Bewegungsfeld spezifische"), ART_BEWEGUNGSFELD),
]
INHALTSFELD = re.compile(r"^Inhaltsfeld ([a-f]): (.+?)\s*$")
BEWEGUNGSFELD = re.compile(r"^(BF/SB (\d)): (.+?)\s*$")
KOMPETENZART = re.compile(
    r"^(Sachkompetenz|Methodenkompetenz|Urteilskompetenz|"
    r"Bewegungs- und Wahrnehmungskompetenz)\s*$"
)
PUNKT = re.compile(r"^( *)à( +)(\S.*)$")
KAPITEL_DREI = re.compile(r"^3 Lernerfolgsüberprüfung")


def sammle_eintraege(zeilen):
    ohne_zahl = [
        (nr, z) for nr, z in enumerate(zeilen, start=1) if not SEITENZAHL.match(z)
    ]
    try:
        start = next(nr for nr, z in ohne_zahl if PHASENMARKE[0][0].match(z))
        ende = next(nr for nr, z in ohne_zahl if nr > start and KAPITEL_DREI.match(z))
    except StopIteration:
        fehler("Kapitelgrenzen 2.4 / 3 nicht gefunden -- Aufbau des PDFs geaendert?")

    phase = art = gegenstand = gegenstand_kurz = bereich = None
    eintraege = []
    offen = None

    for nr, zeile in ohne_zahl:
        if not start <= nr < ende:
            continue

        for muster, name in PHASENMARKE:
            if muster.match(zeile):
                phase, gegenstand, bereich, offen = name, None, None, None
        for muster, name in ACHSENMARKE:
            if muster.match(zeile):
                art, gegenstand, bereich, offen = name, None, None, None

        treffer = INHALTSFELD.match(zeile)
        if treffer:
            gegenstand = f"{treffer.group(1)}: {treffer.group(2)}"
            gegenstand_kurz = treffer.group(1)
            bereich, offen = None, None
            continue

        treffer = BEWEGUNGSFELD.match(zeile)
        if treffer:
            gegenstand = f"{treffer.group(1)}: {treffer.group(3)}"
            gegenstand_kurz = f"BF{treffer.group(2)}"
            bereich, offen = None, None
            continue

        treffer = KOMPETENZART.match(zeile)
        if treffer and gegenstand:
            bereich, offen = treffer.group(1), None
            continue

        treffer = PUNKT.match(zeile)
        if treffer:
            if not (phase and art and gegenstand and bereich):
                fehler(f"Aufzaehlungspunkt ohne Einordnung in Zeile {nr}")
            spalte = len(treffer.group(1)) + 1 + len(treffer.group(2))
            offen = {
                "phase": phase, "art": art, "gegenstand": gegenstand,
                "kurz": gegenstand_kurz, "bereich": bereich,
                "zeilen": [treffer.group(3)], "spalte": spalte, "zeilennr": nr,
            }
            eintraege.append(offen)
            continue

        # Fortsetzungszeile ueber die Einrueckung, nicht ueber Satzzeichen.
        if offen is not None and zeile.strip():
            einzug = len(zeile) - len(zeile.lstrip())
            if einzug == offen["spalte"]:
                offen["zeilen"].append(zeile.strip())
                continue
            offen = None

    return eintraege


# ---------------------------------------------------------------------------
# 4 -- Zeilen zusammenfuegen, Silbentrennung nach E22
# ---------------------------------------------------------------------------
def fuege_zusammen(rohzeilen, schatz, zeilennr, protokoll, linke_haelften=frozenset()):
    text = ""
    for stelle, zeile in enumerate(rohzeilen):
        if stelle == 0:
            text = zeile
            continue
        folge = re.match(r"[A-Za-zÄÖÜäöüß]+", zeile)
        folge = folge.group() if folge else ""
        vorn = re.search(r"([A-Za-zÄÖÜäöüß]+)-$", text)
        if not vorn:
            text += " " + zeile
            continue
        anfang = vorn.group(1)
        verschmolzen = schatz.get(anfang + folge, 0)
        mit_strich = schatz.get(anfang + "-" + folge, 0)
        if folge in ELLIPSE:                                    # Regel 1
            text += " " + zeile
            grund = "Ellipse"
        elif verschmolzen > 0 and mit_strich == 0:              # Regel 2
            text = text[:-1] + zeile
            grund = "Trennung (verschmolzene Form belegt)"
        elif mit_strich > 0 and verschmolzen == 0:              # Regel 3
            text += zeile
            grund = "echter Bindestrich (belegt)"
        elif mit_strich > 0 and verschmolzen > 0:
            text = text[:-1] + zeile
            grund = "beide Formen belegt -- aufgeloest"
        elif anfang in linke_haelften:                          # Regel 6 (E45)
            # Die linke Haelfte ist im Dokument als linke Haelfte eines
            # ungetrennt belegten Bindestrich-Kompositums belegt -- etwa
            # `kritisch-` durch `kritisch-konstruktiv`. Dann ist der
            # Bindestrich hier echt.
            #
            # Die Regel steht HINTER 2 und 3, weil sie sich wie diese auf
            # einen Beleg im Dokument stuetzt, und VOR 5, weil ein Beleg mehr
            # wiegt als eine orthografische Faustregel (E45).
            text += zeile
            grund = "Regel 6 (belegte linke Kompositumshaelfte)"
        elif folge[:1].isupper():                               # Regel 5 (E28)
            # Eine Silbentrennung fuehrt nie zu einem Grossbuchstaben; ein
            # Bindestrich davor ist ein Kompositum-Bindestrich. Die Regel steht
            # HINTER 2 und 3: wo das Dokument einen Beleg liefert, gilt der
            # Beleg, die Faustregel greift nur ohne einen solchen.
            text += zeile
            grund = "Regel 5 (Grossbuchstabe, echter Bindestrich)"
        else:                                                   # Regel 4
            text = text[:-1] + zeile
            grund = "Regel 4 (unbelegt, aufgeloest)"
        protokoll.append((zeilennr, anfang, folge, grund))

    text = re.sub(r"\s+", " ", text).strip()
    # E28: Ellipsenregel auch innerhalb der Zeile. `Satz-und` ist keine
    # moegliche deutsche Wortform, gleich woher die Luecke stammt.
    text = re.sub(r"(?<=-)(?=(?:und|oder|bzw\.|sowie)\b)", " ", text)
    return text


# ---------------------------------------------------------------------------
# 5 -- SQL schreiben
# ---------------------------------------------------------------------------
def sql_text(wert: str) -> str:
    return wert.replace("'", "''")


def kurzname(beschreibung: str) -> str:
    if len(beschreibung) <= KURZNAME_GRENZE:
        return beschreibung
    return beschreibung[:KURZNAME_GRENZE].rsplit(" ", 1)[0] + " …"


def schreibe_seed(eintraege, ziel: Path):
    # Reihenfolge des Bestands: je Phase erst die Inhaltsfelder a-f mit
    # SK/MK/UK, dann die Bewegungsfelder 1-9 mit BWK.
    ordnung = []
    for phase in ("erprobungsstufe", "zweite_stufe"):
        for buchstabe in "abcdef":
            for bereich in ("Sachkompetenz", "Methodenkompetenz", "Urteilskompetenz"):
                ordnung.append((phase, ART_INHALTSFELD, buchstabe, bereich))
        for zahl in range(1, 10):
            ordnung.append((phase, ART_BEWEGUNGSFELD, f"BF{zahl}",
                            "Bewegungs- und Wahrnehmungskompetenz"))

    nach_bereich = collections.defaultdict(list)
    gegenstand_von = {}
    for eintrag in eintraege:
        schluessel = (eintrag["phase"], eintrag["art"], eintrag["kurz"], eintrag["bereich"])
        nach_bereich[schluessel].append(eintrag)
        gegenstand_von[(eintrag["phase"], eintrag["kurz"])] = eintrag["gegenstand"]

    zeilen = []
    a = zeilen.append
    a("-- =============================================================================")
    a("-- Seed 12: Sport – Kernlehrplan Gymnasium Sek I (G9), NRW 2019 (Heft 3426)")
    a("-- Ersetzt das veraltete 09_seed_sport_konkrete_erwartungen.sql.")
    a("--")
    a(f"-- Quelle: {QUELLE}")
    a(f"-- SHA256: {QUELLE_SHA}")
    a(f"-- Erzeugt von: {ERZEUGER}")
    a("--")
    a("-- NICHT VON HAND AENDERN: Korrekturen gehoeren in den Erzeuger, die Datei")
    a("-- wird daraus neu geschrieben (E19).")
    a("-- Voraussetzung: Migration 08 und Migration 13 (Spalte `art`).")
    a("-- Idempotent: loescht vorhandenen SPO_KLP-Rahmen und baut ihn neu auf.")
    a("-- =============================================================================")
    a("")
    a("SET NAMES utf8mb4;")
    a("START TRANSACTION;")
    a("")
    a("SET @schule := 1;")
    a("SET @fach := (SELECT id FROM faecher WHERE schule_id = @schule AND kuerzel = 'SP' LIMIT 1);")
    a("")
    a("-- Nur der eigene Rahmen wird geloescht; CASCADE raeumt Bereiche und Kompetenzen.")
    a(f"DELETE FROM kompetenzrahmen WHERE schule_id = @schule AND kuerzel = '{RAHMEN_KUERZEL}';")
    a("")
    a("INSERT INTO kompetenzrahmen (schule_id, name, kuerzel, beschreibung, quelle_url, fach_id)")
    a(f"VALUES (@schule, '{sql_text(RAHMEN_NAME)}', '{RAHMEN_KUERZEL}', "
      f"'{sql_text(RAHMEN_BESCHREIBUNG)}', '{sql_text(str(QUELLE))}', @fach);")
    a("SET @rahmen := LAST_INSERT_ID();")
    a("")
    a("-- --------------------------------------------------------------------------")
    a("-- Kompetenzbereiche")
    a("--")
    a("-- Zwei Ebenen (E29b, E31): je Phase und Gegenstand ein Wurzelknoten,")
    a("-- darunter die Kompetenzbereiche als Blaetter. Kompetenzen haengen nur")
    a("-- an den Blaettern; die Phase steht als Spalte an jedem Knoten.")
    a("--")
    a("-- `art` sagt jetzt, was der KNOTEN ist -- nicht mehr, was in der Spalte")
    a("-- `inhaltsfeld` steht. Sport ist das einzige Fach mit zwei Achsen: sechs")
    a("-- Inhaltsfelder (a-f) und neun Bewegungsfelder (BF/SB 1-9) stehen")
    a("-- nebeneinander auf derselben Ebene. Die Wurzelknoten tragen deshalb")
    a("-- 'inhaltsfeld' bzw. 'bewegungsfeld', die Blaetter 'kompetenzbereich'.")
    a("-- --------------------------------------------------------------------------")

    # Wurzelknoten: je (Phase, Gegenstand) einer, in der Reihenfolge des
    # ersten zugehoerigen Blattes. Der Wurzelcode ist der gemeinsame Praefix
    # der Blattcodes; die Blattcodes bleiben unveraendert, weil die
    # Kompetenzcodes darauf aufbauen (SPO_EP_IFA_SK_01).
    wurzeln = []
    blaetter = []
    bereichsplan = []
    gesehen = {}
    lauf = 0
    for phase, art, kurz, bereich in ordnung:
        gegenstand = gegenstand_von.get((phase, kurz))
        if gegenstand is None:
            fehler(f"Kein Gegenstand fuer {phase}/{kurz} gefunden")
        feld_kuerzel = f"IF{kurz.upper()}" if art == ART_INHALTSFELD else kurz
        wcode = f"SPO_{PHASEN_KUERZEL[phase]}_{feld_kuerzel}"
        if wcode not in gesehen:
            lauf += 1
            gesehen[wcode] = True
            wname = f"{PHASEN_NAME[phase]} · {gegenstand}"
            wurzeln.append(
                f"(@rahmen, NULL, '{wcode}', '{sql_text(wname)}', {lauf}, "
                f"'{phase}', '{art}')"
            )
        lauf += 1
        code = f"{wcode}_{BEREICH_KUERZEL[bereich]}"
        name = f"{PHASEN_NAME[phase]} · {gegenstand} · {bereich}"
        bereichsplan.append((code, name, phase, art, kurz, bereich, gegenstand))
        blaetter.append(
            f"  SELECT '{code}' AS code, '{sql_text(name)}' AS name, "
            f"{lauf} AS reihenfolge, '{phase}' AS phase, "
            f"'kompetenzbereich' AS art, '{wcode}' AS pcode"
        )

    a("INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art) VALUES")
    a(",\n".join(wurzeln) + ";")
    a("")
    a("-- Blaetter: parent_id wird ueber den Code des Wurzelknotens aufgeloest.")
    a("INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art)")
    a("SELECT @rahmen, p.id, t.code, t.name, t.reihenfolge, t.phase, t.art")
    a("FROM (")
    a("\n  UNION ALL\n".join(blaetter))
    a(") t JOIN kompetenzbereiche p ON p.rahmen_id = @rahmen AND p.code = t.pcode;")
    a("")

    a("-- --------------------------------------------------------------------------")
    a("-- Kompetenzerwartungen (flach)")
    a("-- --------------------------------------------------------------------------")
    for code, name, phase, art, kurz, bereich, gegenstand in bereichsplan:
        posten = nach_bereich[(phase, art, kurz, bereich)]
        a(f"-- {name} ({len(posten)})")
        a("INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)")
        a("SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL")
        a("FROM kompetenzbereiche kb JOIN (")
        stuecke = []
        for lauf, eintrag in enumerate(posten, start=1):
            beschreibung = eintrag["text"]
            stuecke.append(
                f"  SELECT '{code}_{lauf:02d}' AS code, "
                f"'{sql_text(kurzname(beschreibung))}' AS kurzname, "
                f"'{sql_text(beschreibung)}' AS beschreibung"
            )
        a("\n  UNION ALL\n".join(stuecke))
        a(f") t ON kb.rahmen_id = @rahmen AND kb.code = '{code}';")
    a("")
    a("COMMIT;")
    a("")
    a(f"-- Kontrolle: erwartet Knoten={len(bereichsplan) + len(wurzeln)} "
      f"({len(wurzeln)} Wurzeln + {len(bereichsplan)} Blaetter), "
      f"Kompetenzen={len(eintraege)}")
    a("-- Erwartet an den Wurzeln: art='inhaltsfeld' 12, art='bewegungsfeld' 18;")
    a("-- an den Blaettern durchweg art='kompetenzbereich'.")
    ziel.write_text("\n".join(zeilen) + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
def main():
    pdf = WURZEL / QUELLE
    zeilen = lies_pdf_als_text(pdf)
    schatz = baue_wortschatz(zeilen)
    linke_haelften = linke_kompositumshaelften(schatz)
    eintraege = sammle_eintraege(zeilen)

    protokoll = []
    for eintrag in eintraege:
        roh = fuege_zusammen(eintrag["zeilen"], schatz, eintrag["zeilennr"],
                               protokoll, linke_haelften)
        # Der Bestand fuehrt weder Schlusskomma noch Schlusspunkt -- alle 120
        # Eintraege enden auf einen Buchstaben. Anders als bei Deutsch GOSt,
        # wo der Punkt stehen bleibt.
        eintrag["text"] = roh.rstrip(" ,.")

    # -- Zaehlwerte gegen die Sollzahlen ---------------------------------
    gezaehlt = collections.Counter(
        (e["phase"], e["kurz"], BEREICH_KUERZEL[e["bereich"]]) for e in eintraege
    )
    abweichungen = []
    for schluessel, soll in SOLL.items():
        ist = gezaehlt.get(schluessel, 0)
        if ist != soll:
            abweichungen.append(f"  {schluessel[0]} / {schluessel[1]} / {schluessel[2]}: "
                                f"{ist} (soll {soll})")
    for schluessel in gezaehlt:
        if schluessel not in SOLL:
            abweichungen.append(f"  unerwartete Einheit: {schluessel} ({gezaehlt[schluessel]})")
    if abweichungen:
        fehler("Zaehlwerte weichen ab -- es wird nichts geschrieben.\n"
               + "\n".join(abweichungen))
    if len(eintraege) != sum(SOLL.values()):
        fehler(f"Gesamtzahl {len(eintraege)} weicht von der Summe der Sollzahlen ab")
    if len(gezaehlt) != len(SOLL):
        fehler(f"{len(gezaehlt)} befuellte Einheiten, erwartet {len(SOLL)}")

    schreibe_seed(eintraege, WURZEL / ZIEL)

    print(f"{ZIEL} geschrieben: {len(eintraege)} Kompetenzen in {len(SOLL)} Bereichen.")
    nach_regel4 = [p for p in protokoll if p[3].startswith("Regel 4")]
    sonder = [p for p in protokoll if not p[3].startswith(("Regel 4", "Trennung"))]
    print(f"Silbentrennung: {len(protokoll)} Entscheidungen, "
          f"davon {len(nach_regel4)} nach Regel 4 (unbelegt).")
    if sonder:
        print("Nicht aufgeloest (Regel 1 und 3):")
        for nr, anfang, folge, grund in sonder:
            print(f"  Zeile {nr}: {anfang}- + {folge}  → {grund}")
    if nach_regel4:
        print("Nach Regel 4 entschieden (bitte durchsehen):")
        for nr, anfang, folge, grund in nach_regel4:
            print(f"  Zeile {nr}: {anfang}- + {folge}  → {anfang + folge}")


if __name__ == "__main__":
    main()
