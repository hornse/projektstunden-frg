#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Erzeuger: Deutsch, Kernlehrplan Gymnasiale Oberstufe (GOSt) NRW.

Liest das Quell-PDF, wandelt es mit `pdftotext -layout` in Text und schreibt
daraus sql/11_seed_deutsch_sii.sql.

Aufruf aus der Projektwurzel:
    python3 sql/gen/gen_deutsch_sii.py

Das Skript schreibt die Seed-Datei nur, wenn alle Zaehlwerte stimmen. Weicht
eine einzige Gliederungseinheit ab, bricht es ab und schreibt nichts --
eine Pruefung ohne ihre Voraussetzung gilt nicht als bestanden
(REIHENREGELN 2).

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
# Feste Angaben zur Quelle (E19: Quelle und Pruefsumme gehoeren in den Kopf)
# ---------------------------------------------------------------------------
WURZEL = Path(__file__).resolve().parents[2]
QUELLE = Path("docs/curricula/gost_klp_d_2026_08_24.pdf")
QUELLE_SHA = "00694903d6a16447989fd476d9ce91c8e0e7b8cb0e114fa3cfd3ed773d981c29"
ZIEL = Path("sql/11_seed_deutsch_sii.sql")
ERZEUGER = "sql/gen/gen_deutsch_sii.py"

RAHMEN_KUERZEL = "DEU_KLP_SII"
RAHMEN_NAME = "Deutsch KLP NRW SII/GOSt (2026)"
RAHMEN_BESCHREIBUNG = (
    "Kernlehrplan Deutsch für die gymnasiale Oberstufe (GOSt), NRW, "
    "verabschiedete Fassung vom 24.08.2026. Kompetenzbereiche "
    "Rezeption/Produktion, Inhaltsfelder Sprache/Texte/Kommunikation/Medien; "
    "Phasen Einführungsphase, Qualifikationsphase Grundkurs und Leistungskurs."
)

# Sollzahlen je (Phase, Inhaltsfeld) -> (Rezeption, Produktion).
# Ermittelt unabhaengig vom Erzeuger durch Auszaehlen der Aufzaehlungszeichen
# im PDF. Weicht der Lauf ab, ist zuerst zu klaeren, welche Zaehlung falsch
# ist -- nicht, welche recht hat.
SOLL = {
    ("einfuehrungsphase", "Übergeordnet"): (8, 11),
    ("einfuehrungsphase", "Sprache"): (6, 3),
    ("einfuehrungsphase", "Texte"): (8, 6),
    ("einfuehrungsphase", "Kommunikation"): (5, 3),
    ("einfuehrungsphase", "Medien"): (5, 3),
    ("qualifikationsphase_gk", "Übergeordnet"): (9, 11),
    ("qualifikationsphase_gk", "Sprache"): (6, 2),
    ("qualifikationsphase_gk", "Texte"): (14, 6),
    ("qualifikationsphase_gk", "Kommunikation"): (5, 3),
    ("qualifikationsphase_gk", "Medien"): (7, 3),
    ("qualifikationsphase_lk", "Übergeordnet"): (11, 11),
    ("qualifikationsphase_lk", "Sprache"): (7, 3),
    ("qualifikationsphase_lk", "Texte"): (14, 6),
    ("qualifikationsphase_lk", "Kommunikation"): (7, 3),
    ("qualifikationsphase_lk", "Medien"): (8, 3),
}

PHASEN_KUERZEL = {
    "einfuehrungsphase": "EF",
    "qualifikationsphase_gk": "QGK",
    "qualifikationsphase_lk": "QLK",
}
PHASEN_NAME = {
    "einfuehrungsphase": "Einführungsphase",
    "qualifikationsphase_gk": "Qualifikationsphase (Grundkurs)",
    "qualifikationsphase_lk": "Qualifikationsphase (Leistungskurs)",
}
FELD_KUERZEL = {
    "Übergeordnet": "UEB",
    "Sprache": "SPR",
    "Texte": "TXT",
    "Kommunikation": "KOM",
    "Medien": "MED",
}
FELD_REIHENFOLGE = ["Übergeordnet", "Sprache", "Texte", "Kommunikation", "Medien"]
BEREICH_KUERZEL = {"Rezeption": "REZ", "Produktion": "PRO"}

# Kuerzung des Anzeigenamens. Die Grenze 120 stammt aus dem Bestand: sie
# reproduziert alle 197 vorhandenen Kurznamen zeichengenau.
KURZNAME_GRENZE = 120

# Regel 1 aus E22: Ellipse, der Bindestrich bleibt stehen.
ELLIPSE = {"und", "oder", "bzw.", "bzw", "sowie"}


def fehler(text):
    print(f"FEHLER: {text}", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# 1 -- Quelle pruefen und umwandeln
# ---------------------------------------------------------------------------
def lies_pdf_als_text(pdf: Path) -> list:
    """Wandelt das PDF mit `pdftotext -layout` um und gibt die Zeilen zurueck.

    `-layout` ist Pflicht: ohne die Option verliert pdftotext bei dieser
    Datei rund 16 Prozent des Textes, und Saetze brechen mitten ab.
    """
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
        ["pdftotext", "-layout", str(pdf), "-"],
        capture_output=True, check=False,
    )
    if lauf.returncode != 0:
        fehler(f"pdftotext brach ab: {lauf.stderr.decode('utf-8', 'replace')}")
    return lauf.stdout.decode("utf-8").split("\n")


# ---------------------------------------------------------------------------
# 2 -- Wortschatz des Dokuments (E22, Regeln 2 und 3)
# ---------------------------------------------------------------------------
WORT = re.compile(r"[A-Za-zÄÖÜäöüß]+(?:-[A-Za-zÄÖÜäöüß]+)*")


def baue_wortschatz(zeilen) -> collections.Counter:
    """Zaehlt alle ungetrennt vorkommenden Woerter.

    Das Dokument dient sich damit selbst als Woerterbuch: ob `A-` / `B` eine
    Silbentrennung oder ein echter Bindestrich ist, entscheidet, welche der
    beiden Formen sonst noch im Text steht.
    """
    schatz = collections.Counter()
    for zeile in zeilen:
        for treffer in WORT.finditer(zeile):
            schatz[treffer.group()] += 1
    return schatz


# ---------------------------------------------------------------------------
# 3 -- Aufbau des Kompetenzteils
# ---------------------------------------------------------------------------
SEITENKOPF = re.compile(
    r"^\s*(Einführungsphase|Qualifikationsphase - (Grund|Leistungs)kurs)\s*$"
)
SEITENZAHL = re.compile(r"^\s*\d{1,3}\s*$")
PHASENMARKE = [
    (re.compile(r"^2\.2 Kompetenzerwartungen"), "einfuehrungsphase"),
    (re.compile(r"^\s*2\.3\.1\s+Grundkurs"), "qualifikationsphase_gk"),
    (re.compile(r"^\s*2\.3\.2\s+Leistungskurs"), "qualifikationsphase_lk"),
]
UEBERGEORDNET = re.compile(
    r"^\s*Übergeordnete Kompetenzerwartungen \((Rezeption|Produktion)\)\s*$"
)
INHALTSFELD = re.compile(r"^\s*Inhaltsfeld (Sprache|Texte|Kommunikation|Medien)\s*$")
KOMPETENZBEREICH = re.compile(r"^\s*(Rezeption|Produktion)\s*$")
# Kompetenzerwartung: Aufzaehlungszeichen mit GENAU drei Leerzeichen dahinter.
# Die inhaltlichen Schwerpunkte stehen mit genau einem Leerzeichen und fallen
# damit heraus -- das ist das einzige zuverlaessige Unterscheidungsmerkmal.
PUNKT = re.compile(r"^( *)•(   )(\S.*)$")
KAPITEL_DREI = re.compile(r"^3\s+[A-ZÄÖÜ]")


def sammle_eintraege(zeilen):
    """Liest die Kompetenzerwartungen als Rohzeilen mit ihrer Einordnung."""
    ohne_kopf = [
        (nr, z) for nr, z in enumerate(zeilen, start=1)
        if not SEITENKOPF.match(z) and not SEITENZAHL.match(z)
    ]
    try:
        start = next(nr for nr, z in ohne_kopf if PHASENMARKE[0][0].match(z))
        ende = next(nr for nr, z in ohne_kopf if nr > start and KAPITEL_DREI.match(z))
    except StopIteration:
        fehler("Kapitelgrenzen 2.2 / 3 nicht gefunden -- Aufbau des PDFs geaendert?")

    phase = inhaltsfeld = bereich = None
    eintraege = []
    offen = None

    for nr, zeile in ohne_kopf:
        if not start <= nr < ende:
            continue

        for muster, name in PHASENMARKE:
            if muster.match(zeile):
                phase, inhaltsfeld, bereich, offen = name, None, None, None

        treffer = UEBERGEORDNET.match(zeile)
        if treffer:
            inhaltsfeld, bereich, offen = "Übergeordnet", treffer.group(1), None
            continue

        treffer = INHALTSFELD.match(zeile)
        if treffer:
            inhaltsfeld, bereich, offen = treffer.group(1), None, None
            continue

        treffer = KOMPETENZBEREICH.match(zeile)
        if treffer and inhaltsfeld and inhaltsfeld != "Übergeordnet":
            bereich, offen = treffer.group(1), None
            continue

        treffer = PUNKT.match(zeile)
        if treffer:
            if not (phase and inhaltsfeld and bereich):
                fehler(f"Aufzaehlungspunkt ohne Einordnung in Zeile {nr}")
            spalte = len(treffer.group(1)) + 1 + len(treffer.group(2))
            offen = {
                "phase": phase, "inhaltsfeld": inhaltsfeld, "bereich": bereich,
                "zeilen": [treffer.group(3)], "spalte": spalte, "zeilennr": nr,
            }
            eintraege.append(offen)
            continue

        # Fortsetzungszeile: gleiche Texteinrueckung wie der offene Punkt.
        # Ueber die Einrueckung, nicht ueber Satzzeichen -- die Regel "bis zum
        # naechsten Komma" ist falsch, Eintraege enthalten Kommata im Satz.
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
def fuege_zusammen(rohzeilen, schatz, zeilennr, protokoll):
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
        elif mit_strich > 0 and verschmolzen > 0:               # beides belegt
            text = text[:-1] + zeile
            grund = "beide Formen belegt -- aufgeloest"
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
    """Hochkommata fuer MariaDB verdoppeln."""
    return wert.replace("'", "''")


def kurzname(beschreibung: str) -> str:
    if len(beschreibung) <= KURZNAME_GRENZE:
        return beschreibung
    return beschreibung[:KURZNAME_GRENZE].rsplit(" ", 1)[0] + " …"


def schreibe_seed(eintraege, ziel: Path):
    zeilen = []
    a = zeilen.append
    a("-- =============================================================================")
    a("-- Seed 11: Deutsch – Kernlehrplan Gymnasiale Oberstufe (GOSt) NRW")
    a("-- Verabschiedete Fassung vom 24.08.2026.")
    a("--")
    a(f"-- Quelle: {QUELLE}")
    a(f"-- SHA256: {QUELLE_SHA}")
    a(f"-- Erzeugt von: {ERZEUGER}")
    a("--")
    a("-- NICHT VON HAND AENDERN: Korrekturen gehoeren in den Erzeuger, die Datei")
    a("-- wird daraus neu geschrieben (E19).")
    a("-- Voraussetzung: Migration 08 (phase/inhaltsfeld/kompetenzbereich,")
    a("--               eltern_kompetenz_id, schule_id) ist eingespielt.")
    a("-- Idempotent: loescht vorhandenen DEU_KLP_SII-Rahmen und baut ihn neu auf.")
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

    # -- Bereiche --------------------------------------------------------
    a("-- --------------------------------------------------------------------------")
    a("-- Kompetenzbereiche als Baum (E29b, E31)")
    a("--")
    a("-- Zwei Ebenen: je Phase und Inhaltsfeld ein Wurzelknoten (art =")
    a("-- 'inhaltsfeld'), darunter Rezeption und Produktion als Blaetter")
    a("-- (art = 'kompetenzbereich'). Kompetenzen haengen nur an den Blaettern.")
    a("-- Die Phase steht als Spalte an jedem Knoten (E31).")
    a("-- --------------------------------------------------------------------------")
    wurzeln = []
    blaetter = []
    reihenfolge = 0
    bereichscodes = []
    for phase in PHASEN_KUERZEL:
        for feld in FELD_REIHENFOLGE:
            reihenfolge += 1
            wcode = f"DE_{PHASEN_KUERZEL[phase]}_{FELD_KUERZEL[feld]}"
            wname = f"{PHASEN_NAME[phase]} · {feld}"
            wurzeln.append(
                f"(@rahmen, NULL, '{wcode}', '{sql_text(wname)}', {reihenfolge}, "
                f"'{phase}', 'inhaltsfeld')"
            )
            for bereich in ("Rezeption", "Produktion"):
                reihenfolge += 1
                code = f"{wcode}_{BEREICH_KUERZEL[bereich]}"
                name = f"{PHASEN_NAME[phase]} · {feld} · {bereich}"
                bereichscodes.append((code, phase, feld, bereich, name))
                blaetter.append(
                    f"  SELECT '{code}' AS code, '{sql_text(name)}' AS name, "
                    f"{reihenfolge} AS reihenfolge, '{phase}' AS phase, "
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

    # -- Kompetenzen -----------------------------------------------------
    a("-- --------------------------------------------------------------------------")
    a("-- Kompetenzerwartungen (flach)")
    a("-- --------------------------------------------------------------------------")
    nach_bereich = collections.defaultdict(list)
    for eintrag in eintraege:
        schluessel = (eintrag["phase"], eintrag["inhaltsfeld"], eintrag["bereich"])
        nach_bereich[schluessel].append(eintrag)

    for code, phase, feld, bereich, name in bereichscodes:
        posten = nach_bereich[(phase, feld, bereich)]
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
    a(f"-- Kontrolle: erwartet Knoten={len(bereichscodes) + len(wurzeln)} "
      f"({len(wurzeln)} Wurzeln + {len(bereichscodes)} Blaetter), "
      f"Kompetenzen={len(eintraege)}")
    ziel.write_text("\n".join(zeilen) + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
def main():
    pdf = WURZEL / QUELLE
    zeilen = lies_pdf_als_text(pdf)
    schatz = baue_wortschatz(zeilen)
    eintraege = sammle_eintraege(zeilen)

    protokoll = []
    for eintrag in eintraege:
        roh = fuege_zusammen(eintrag["zeilen"], schatz, eintrag["zeilennr"], protokoll)
        # Schlusskomma entfaellt, ein Schlusspunkt bleibt stehen -- so haelt es
        # der Bestand, und so bleiben Sek I und Sek II gleich.
        eintrag["text"] = roh[:-1] if roh.endswith(",") else roh

    # -- Zaehlwerte gegen die Sollzahlen ---------------------------------
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
    if abweichungen:
        fehler(
            "Zaehlwerte weichen ab -- es wird nichts geschrieben.\n"
            + "\n".join(abweichungen)
        )
    if len(eintraege) != sum(r + p for r, p in SOLL.values()):
        fehler(f"Gesamtzahl {len(eintraege)} weicht von der Summe der Sollzahlen ab")
    if len(gezaehlt) != 2 * len(SOLL):
        fehler(f"{len(gezaehlt)} befuellte Bereiche, erwartet {2 * len(SOLL)}")

    schreibe_seed(eintraege, WURZEL / ZIEL)

    print(f"{ZIEL} geschrieben: {len(eintraege)} Kompetenzen in {len(gezaehlt)} Bereichen.")
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
