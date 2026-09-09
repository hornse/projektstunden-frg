#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Erzeuger: Deutsch, Kernlehrplan Gymnasium Sekundarstufe I (G9) NRW.

Liest das Quell-PDF, wandelt es mit `pdftotext -layout` in Text und schreibt
daraus sql/10_seed_deutsch_klp.sql.

Aufruf aus der Projektwurzel:
    python3 sql/gen/gen_deutsch_klp.py

Das Skript schreibt die Seed-Datei nur, wenn alle Zaehlwerte stimmen. Weicht
eine einzige Gliederungseinheit ab, bricht es ab und schreibt nichts
(REIHENREGELN 2).

Eigenheiten dieses Plans, alle am Dokument belegt:

  * **Zwei Aufzaehlungszeichen.** `\\x83` leitet die 42 uebergeordneten
    Erwartungen ein, `à` die 184 konkretisierten -- zusammen 226. Beide sind
    falsch dekodierte Wingdings-Zeichen. Sport verwendet nur `à`, Deutsch GOSt
    nur `•`: Das Zeichen ist je Dokument neu zu ermitteln, nicht zu uebernehmen.
  * **`\\x83` ist ein C1-Steuerzeichen (U+0083), kein C0.** Die Bereinigung
    nach E25 fasst nur C0 und laesst den Marker deshalb stehen -- was hier
    noetig ist, weil er die Gliederung traegt. Wer den Ausdruck auf C1
    ausweitet, verliert 42 Erwartungen.
  * **`–` leitet inhaltliche Schwerpunkte ein**, 98 Vorkommen, und zaehlt nicht
    mit.
  * **Vier Abschnitte, nicht drei.** Zwischen `2.3` und `2.3.1` liegt der Block
    der uebergeordneten Erwartungen fuer die gesamte Sekundarstufe I. Er steht
    im Lehrplan vor der Ersten Stufe, weil er fuer beide Stufen gilt -- der
    Gegenstand von E12. Diese 21 Erwartungen bekommen `sek1_uebergreifend`
    und die Codes `DE_S1U_UEB_…` (E14).
  * Silbentrennung nach E22, Steuerzeichen nach E25.

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
QUELLE = Path("docs/curricula/g9_d_klp_3409_2019_06_23.pdf")
QUELLE_SHA = "844fdfe8c875433c2775c899b74a2d83d466a19a4d3cc5d88630d7b7d66cb94c"
ZIEL = Path("sql/10_seed_deutsch_klp.sql")
ERZEUGER = "sql/gen/gen_deutsch_klp.py"

RAHMEN_KUERZEL = "DEU_KLP"
RAHMEN_NAME = "Deutsch KLP NRW G9 Sek I (FRG)"
RAHMEN_BESCHREIBUNG = (
    "Kernlehrplan Deutsch, Gymnasium Sekundarstufe I (G9), NRW 2019. "
    "Kompetenzbereiche Rezeption/Produktion, Inhaltsfelder "
    "Sprache/Texte/Kommunikation/Medien, gegliedert nach Erprobungsstufe, "
    "Erster und Zweiter Stufe; dazu die für die gesamte Sekundarstufe I "
    "geltenden übergeordneten Erwartungen aus Kapitel 2.3."
)

# Sollzahlen je (Phase, Inhaltsfeld) -> (Rezeption, Produktion).
# Unabhaengig vom Erzeuger durch Auszaehlen der `\x83`- und `à`-Zeilen
# ermittelt. Weicht der Lauf ab, ist zuerst zu klaeren, welche Zaehlung
# falsch ist -- nicht, welche recht hat.
SOLL = {
    ("erprobungsstufe", "Übergeordnet"): (8, 13),
    ("erprobungsstufe", "Sprache"): (10, 6),
    ("erprobungsstufe", "Texte"): (10, 6),
    ("erprobungsstufe", "Kommunikation"): (7, 7),
    ("erprobungsstufe", "Medien"): (7, 8),
    ("sek1_uebergreifend", "Übergeordnet"): (8, 13),
    ("erste_stufe", "Sprache"): (9, 5),
    ("erste_stufe", "Texte"): (13, 9),
    ("erste_stufe", "Kommunikation"): (6, 4),
    ("erste_stufe", "Medien"): (10, 7),
    ("zweite_stufe", "Sprache"): (9, 6),
    ("zweite_stufe", "Texte"): (9, 10),
    ("zweite_stufe", "Kommunikation"): (4, 6),
    ("zweite_stufe", "Medien"): (9, 7),
}

PHASEN_KUERZEL = {
    "erprobungsstufe": "EP",
    "sek1_uebergreifend": "S1U",
    "erste_stufe": "S1",
    "zweite_stufe": "S2",
}
PHASEN_NAME = {
    "erprobungsstufe": "Erprobungsstufe",
    "sek1_uebergreifend": "Sekundarstufe I übergreifend",
    "erste_stufe": "Erste Stufe",
    "zweite_stufe": "Zweite Stufe",
}
FELD_KUERZEL = {
    "Übergeordnet": "UEB",
    "Sprache": "SPR",
    "Texte": "TXT",
    "Kommunikation": "KOM",
    "Medien": "MED",
}
BEREICH_KUERZEL = {"Rezeption": "REZ", "Produktion": "PRO"}

# Reihenfolge der 28 Bereiche wie im Bestand: Erprobungsstufe vollstaendig,
# dann die uebergreifenden Erwartungen, dann Erste und Zweite Stufe. Die
# uebergreifenden stehen vor der Ersten Stufe, weil sie im Lehrplan dort
# stehen und fuer beide Stufen gelten.
ORDNUNG = (
    [("erprobungsstufe", f) for f in
     ("Übergeordnet", "Sprache", "Texte", "Kommunikation", "Medien")]
    + [("sek1_uebergreifend", "Übergeordnet")]
    + [("erste_stufe", f) for f in ("Sprache", "Texte", "Kommunikation", "Medien")]
    + [("zweite_stufe", f) for f in ("Sprache", "Texte", "Kommunikation", "Medien")]
)

KURZNAME_GRENZE = 120          # reproduziert alle 226 Kurznamen des Bestands
ELLIPSE = {"und", "oder", "bzw.", "bzw", "sowie"}   # E22, Regel 1

# E25: alle C0-Steuerzeichen ausser Tabulator (\x09) und Zeilenumbruch (\x0a).
# Der Seitenumbruch (\x0c) wird vorher gesondert getilgt. C1 bleibt
# unberuehrt -- `\x83` traegt hier die Gliederung.
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
# Reihenfolge wichtig: 2.3.1 und 2.3.2 muessen vor 2.3 geprueft werden.
PHASENMARKE = [
    (re.compile(r"^\s*2\.3\.1\s+Erste Stufe\s*$"), "erste_stufe"),
    (re.compile(r"^\s*2\.3\.2\s+Zweite Stufe\s*$"), "zweite_stufe"),
    (re.compile(r"^\s*2\.2 Kompetenzerwartungen"), "erprobungsstufe"),
    (re.compile(r"^\s*2\.3 Kompetenzerwartungen"), "sek1_uebergreifend"),
]
INHALTSFELD = re.compile(r"^\s*Inhaltsfeld \d+: (Sprache|Texte|Kommunikation|Medien)\s*$")
KOMPETENZBEREICH = re.compile(r"^\s*(Rezeption|Produktion)\s*$")
PUNKT = re.compile(r"^( *)([\x83à])( +)(\S.*)$")
KAPITEL_DREI = re.compile(r"^\s*3 Lernerfolgsüberprüfung")


def sammle_eintraege(zeilen):
    ohne_zahl = [
        (nr, z) for nr, z in enumerate(zeilen, start=1) if not SEITENZAHL.match(z)
    ]
    try:
        start = next(nr for nr, z in ohne_zahl
                     if re.match(r"^\s*2\.2 Kompetenzerwartungen", z))
        ende = next(nr for nr, z in ohne_zahl if nr > start and KAPITEL_DREI.match(z))
    except StopIteration:
        fehler("Kapitelgrenzen 2.2 / 3 nicht gefunden -- Aufbau des PDFs geaendert?")

    phase = inhaltsfeld = bereich = None
    eintraege = []
    offen = None

    for nr, zeile in ohne_zahl:
        if not start <= nr < ende:
            continue

        neue_phase = None
        for muster, name in PHASENMARKE:
            if muster.match(zeile):
                neue_phase = name
                break
        if neue_phase:
            phase = neue_phase
            # Nach einer Phasenmarke folgen zuerst die uebergeordneten
            # Erwartungen -- sie tragen keine eigene "Inhaltsfeld"-Zeile.
            # Erste und Zweite Stufe haben keine; dort setzt die erste
            # Inhaltsfeld-Zeile den Wert, bevor ein Punkt kommt.
            inhaltsfeld, bereich, offen = "Übergeordnet", None, None
            continue

        treffer = INHALTSFELD.match(zeile)
        if treffer:
            inhaltsfeld, bereich, offen = treffer.group(1), None, None
            continue

        treffer = KOMPETENZBEREICH.match(zeile)
        if treffer and phase:
            bereich, offen = treffer.group(1), None
            continue

        treffer = PUNKT.match(zeile)
        if treffer:
            if not (phase and inhaltsfeld and bereich):
                fehler(f"Aufzaehlungspunkt ohne Einordnung in Zeile {nr}")
            spalte = len(treffer.group(1)) + 1 + len(treffer.group(3))
            offen = {
                "phase": phase, "inhaltsfeld": inhaltsfeld, "bereich": bereich,
                "marke": treffer.group(2),
                "zeilen": [treffer.group(4)], "spalte": spalte, "zeilennr": nr,
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
    # moegliche deutsche Wortform, gleich woher die Luecke stammt -- hier
    # verschluckt pdftotext den Wortabstand, weil er im PDF zu eng gesetzt ist.
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
    nach_bereich = collections.defaultdict(list)
    for eintrag in eintraege:
        nach_bereich[(eintrag["phase"], eintrag["inhaltsfeld"],
                      eintrag["bereich"])].append(eintrag)

    zeilen = []
    a = zeilen.append
    a("-- =============================================================================")
    a("-- Seed 10: Deutsch – Kernlehrplan Gymnasium Sek I (G9), NRW 2019 (Heft 3409)")
    a("--")
    a(f"-- Quelle: {QUELLE}")
    a(f"-- SHA256: {QUELLE_SHA}")
    a(f"-- Erzeugt von: {ERZEUGER}")
    a("--")
    a("-- NICHT VON HAND AENDERN: Korrekturen gehoeren in den Erzeuger, die Datei")
    a("-- wird daraus neu geschrieben (E19).")
    a("-- Voraussetzung: Migration 08 und Migration 14 (Phase sek1_uebergreifend).")
    a("-- Idempotent: loescht vorhandenen DEU_KLP-Rahmen und baut ihn neu auf.")
    a("-- =============================================================================")
    a("")
    a("SET NAMES utf8mb4;")
    a("START TRANSACTION;")
    a("")
    a("SET @schule := 1;")
    a("SET @fach := (SELECT id FROM faecher WHERE schule_id = @schule AND kuerzel = 'DE' LIMIT 1);")
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
    a("-- Kompetenzbereiche als Baum (E29b, E31)")
    a("--")
    a("-- Zwei Ebenen: je Phase und Inhaltsfeld ein Wurzelknoten (art =")
    a("-- 'inhaltsfeld'), darunter Rezeption und Produktion als Blaetter")
    a("-- (art = 'kompetenzbereich'). Die Kompetenzen haengen nur an den")
    a("-- Blaettern -- ein Knoten mit Kindern traegt keine (E31).")
    a("--")
    a("-- Die Phase bleibt eine Spalte und steht an JEDEM Knoten, auch am Blatt:")
    a("-- sie liegt quer zur Schachtelung, und das Frontend filtert ueber sie")
    a("-- (E31). Die uebergeordneten Erwartungen aus Kapitel 2.3 tragen")
    a("-- `sek1_uebergreifend` (E12) und die Codes DE_S1U_… (E14).")
    a("-- --------------------------------------------------------------------------")

    # Wurzelknoten: je (Phase, Inhaltsfeld) einer. Der Code ist der gemeinsame
    # Praefix der Blaetter darunter; die Blattcodes bleiben unveraendert, weil
    # die Kompetenzcodes darauf aufbauen (DE_EP_SPR_REZ_01).
    wurzeln = []
    blaetter = []
    bereichsplan = []
    lauf = 0
    for phase, feld in ORDNUNG:
        lauf += 1
        wcode = f"DE_{PHASEN_KUERZEL[phase]}_{FELD_KUERZEL[feld]}"
        wname = f"{PHASEN_NAME[phase]} · {feld}"
        wurzeln.append(
            f"(@rahmen, NULL, '{wcode}', '{sql_text(wname)}', {lauf}, "
            f"'{phase}', 'inhaltsfeld')"
        )
        for bereich in ("Rezeption", "Produktion"):
            lauf += 1
            code = f"{wcode}_{BEREICH_KUERZEL[bereich]}"
            name = f"{PHASEN_NAME[phase]} · {feld} · {bereich}"
            bereichsplan.append((code, name, phase, feld, bereich))
            blaetter.append(
                f"  SELECT '{code}' AS code, '{sql_text(name)}' AS name, {lauf} AS reihenfolge, "
                f"'{phase}' AS phase, 'kompetenzbereich' AS art, '{wcode}' AS pcode"
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
    for code, name, phase, feld, bereich in bereichsplan:
        posten = nach_bereich[(phase, feld, bereich)]
        a(f"-- {name} ({len(posten)})")
        a("INSERT INTO kompetenzen (bereich_id, fach_id, schule_id, code, kurzname, beschreibung, eltern_kompetenz_id)")
        a("SELECT kb.id, @fach, @schule, t.code, t.kurzname, t.beschreibung, NULL")
        a("FROM kompetenzbereiche kb JOIN (")
        stuecke = []
        for i, eintrag in enumerate(posten, start=1):
            b = eintrag["text"]
            stuecke.append(
                f"  SELECT '{code}_{i:02d}' AS code, "
                f"'{sql_text(kurzname(b))}' AS kurzname, "
                f"'{sql_text(b)}' AS beschreibung"
            )
        a("\n  UNION ALL\n".join(stuecke))
        a(f") t ON kb.rahmen_id = @rahmen AND kb.code = '{code}';")
    a("")
    a("COMMIT;")
    a("")
    a(f"-- Kontrolle: erwartet Knoten={len(bereichsplan) + len(ORDNUNG)} "
      f"({len(ORDNUNG)} Wurzeln + {len(bereichsplan)} Blaetter), "
      f"Kompetenzen={len(eintraege)}")
    a("-- Erwartet je Phase: erprobungsstufe 10/82, sek1_uebergreifend 2/21,")
    a("--                   erste_stufe 8/63, zweite_stufe 8/60.")
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
        # Der Bestand fuehrt weder Schlusskomma noch Schlusspunkt.
        eintrag["text"] = roh.rstrip(" ,.")

    gezaehlt = collections.Counter(
        (e["phase"], e["inhaltsfeld"], e["bereich"]) for e in eintraege
    )
    abweichungen = []
    for (phase, feld), (soll_rez, soll_pro) in SOLL.items():
        ist_rez = gezaehlt.get((phase, feld, "Rezeption"), 0)
        ist_pro = gezaehlt.get((phase, feld, "Produktion"), 0)
        if (ist_rez, ist_pro) != (soll_rez, soll_pro):
            abweichungen.append(
                f"  {phase} / {feld}: Rezeption {ist_rez} (soll {soll_rez}), "
                f"Produktion {ist_pro} (soll {soll_pro})"
            )
    for schluessel in gezaehlt:
        if (schluessel[0], schluessel[1]) not in SOLL:
            abweichungen.append(f"  unerwartete Einheit: {schluessel} ({gezaehlt[schluessel]})")
    if abweichungen:
        fehler("Zaehlwerte weichen ab -- es wird nichts geschrieben.\n"
               + "\n".join(abweichungen))
    if len(eintraege) != sum(r + p for r, p in SOLL.values()):
        fehler(f"Gesamtzahl {len(eintraege)} weicht von der Summe der Sollzahlen ab")
    if len(gezaehlt) != 2 * len(SOLL):
        fehler(f"{len(gezaehlt)} befuellte Bereiche, erwartet {2 * len(SOLL)}")

    # Die beiden Aufzaehlungszeichen trennen uebergeordnete von konkretisierten
    # Erwartungen. Stimmt diese Aufteilung nicht, ist die Gliederung falsch
    # erkannt worden, auch wenn die Summe zufaellig aufgeht.
    marken = collections.Counter(e["marke"] for e in eintraege)
    if marken.get("\x83", 0) != 42 or marken.get("à", 0) != 184:
        fehler(f"Aufzaehlungszeichen unerwartet verteilt: "
               f"\\x83={marken.get(chr(0x83), 0)} (soll 42), "
               f"à={marken.get('à', 0)} (soll 184)")

    schreibe_seed(eintraege, WURZEL / ZIEL)

    print(f"{ZIEL} geschrieben: {len(eintraege)} Kompetenzen in {len(gezaehlt)} Bereichen.")
    print(f"Aufzaehlungszeichen: \\x83={marken['\x83']} uebergeordnet, à={marken['à']} konkretisiert.")
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
