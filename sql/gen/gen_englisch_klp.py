#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Erzeuger: Englisch, Kernlehrplan Gymnasium Sekundarstufe I (G9) NRW.

Liest das Quell-PDF und schreibt sql/19_seed_englisch_klp.sql.

Aufruf aus der Projektwurzel:
    python3 sql/gen/gen_englisch_klp.py

Das Skript schreibt die Seed-Datei nur, wenn alle Zaehlwerte stimmen. Weicht
eine einzige Gliederungseinheit ab, bricht es ab und schreibt nichts
(REIHENREGELN 2).

Vier Eigenheiten dieses Plans, alle am Dokument belegt:

  * **Zweispaltiger Satz** (E47). Links die Kompetenzerwartungen, rechts die
    fachlichen Konkretisierungen. `pdftotext -layout` zieht beide in dieselbe
    Textzeile, und weil der linke Block im Blocksatz steht, beginnt die rechte
    Spalte je nach Zeile bei Zeichen 41, 45 oder 51. Deshalb wird hier ueber
    `-bbox-layout` mit Koordinaten gearbeitet.

  * **Zwei Marker mit derselben Bedeutung.** `à` traegt 170 Erwartungen, `•`
    sieben -- letztere ausschliesslich in der Text- und Medienkompetenz der
    Zweiten Stufe. Ein Erzeuger, der nur `à` kennt, liefert 170, und die Summe
    saehe stimmig aus. Nach E28 wird die Aufteilung je Marker geprueft.
    `•` kommt im Dokument 33-mal vor; die uebrigen 26 sind Aufzaehlungen
    ausserhalb des Kompetenzteils.

  * **Dritte Gliederungsebene** (E46). Unter "Verfuegen ueber sprachliche
    Mittel" liegen Wortschatz, Grammatik, Aussprache und Intonation,
    Orthografie; unter der Interkulturellen kommunikativen Kompetenz liegen
    drei weitere. Die uebrigen Kompetenzbereiche tragen ihre Erwartungen
    direkt. Die Tiefe schwankt also innerhalb des Plans.

  * **Kapitaelchen kommen zerlegt an** (E47). `pdftotext` setzt hinter jeden
    grossen Anfangsbuchstaben ein Leerzeichen:
    `I NTERKULTURELLE KOMMUNIKATIVE K OMPETENZ`.

Copyright (C) 2026 Sebastian Horn, Friedrich-Rueckert-Gymnasium Duesseldorf
SPDX-License-Identifier: GPL-3.0-or-later
"""

import collections
import hashlib
import html
import re
import shutil
import subprocess
import sys
from pathlib import Path

WURZEL = Path(__file__).resolve().parents[2]
QUELLE = Path("docs/curricula/g9_e_klp_3417_2019_06_23.pdf")
QUELLE_SHA = "96a12dca0a6b7d81d75367d1c870aa48013db9bae84671d7add9e7bb55329ead"
ERZEUGER = "sql/gen/gen_englisch_klp.py"
ZIEL = Path("sql/19_seed_englisch_klp.sql")

RAHMEN_KUERZEL = "ENG_KLP"
RAHMEN_NAME = "Englisch KLP NRW G9 Sek I (FRG)"
RAHMEN_BESCHREIBUNG = (
    "Kernlehrplan Englisch Gymnasium Sekundarstufe I (G9), NRW 2019, Heft 3417"
)
FACH_KUERZEL = "EN"
KURZNAME_GRENZE = 120

MARKER = ("à", "•")
ELLIPSE = {"und", "oder", "bzw.", "bzw", "sowie"}          # E22, Regel 1

# Spaltengeometrie, an diesem Dokument gemessen (E47).
RINNE = (293.0, 300.0)      # Band, das ein zweispaltiger Block frei laesst
SPALTE_RECHTS = 300.0       # ab hier beginnt die rechte Spalte
MINDESTLUECKE = 8.0         # groesser als ein gedehnter Wortzwischenraum

PHASEN_KUERZEL = {"erprobungsstufe": "EP", "erste_stufe": "S1", "zweite_stufe": "S2"}
PHASEN_NAME = {
    "erprobungsstufe": "Erprobungsstufe",
    "erste_stufe": "Erste Stufe",
    "zweite_stufe": "Zweite Stufe",
}

ART_BEREICH = "kompetenzbereich"
ART_TEIL = "teilbereich"
ART_UNTER = "unterbereich"

# Gliederung: Kompetenzbereich -> Teilbereiche -> Unterbereiche.
# Kuerzel und Reihenfolge stehen hier und nirgends sonst; sie bilden das
# Codeschema aus E46.
BEREICHE = [
    ("FKK", "Funktionale kommunikative Kompetenz", [
        ("HOR", "Hör-/Hörsehverstehen", []),
        ("LES", "Leseverstehen", []),
        ("SAG", "Sprechen: an Gesprächen teilnehmen", []),
        ("ZUS", "Sprechen: zusammenhängendes Sprechen", []),
        ("SCH", "Schreiben", []),
        ("SPM", "Sprachmittlung", []),
        ("VSM", "Verfügen über sprachliche Mittel", [
            ("WOR", "Wortschatz"),
            ("GRA", "Grammatik"),
            ("AUS", "Aussprache und Intonation"),
            ("ORT", "Orthografie"),
        ]),
    ]),
    ("IKK", "Interkulturelle kommunikative Kompetenz", [
        ("SOW", "Soziokulturelles Orientierungswissen", []),
        ("EIN", "Interkulturelle Einstellungen und Bewusstheit", []),
        ("VER", "Interkulturelles Verstehen und Handeln", []),
    ]),
    ("TMK", "Text- und Medienkompetenz", []),
    ("SLK", "Sprachlernkompetenz", []),
    ("SBW", "Sprachbewusstheit", []),
]

# Sollzahlen je Blatt und Phase, unabhaengig vom Erzeuger ausgezaehlt.
SOLL = {
    "erprobungsstufe": {"HOR": 3, "LES": 2, "SAG": 3, "ZUS": 4, "SCH": 3, "SPM": 3,
                        "WOR": 3, "GRA": 7, "AUS": 3, "ORT": 3,
                        "SOW": 1, "EIN": 2, "VER": 3,
                        "TMK": 4, "SLK": 5, "SBW": 4},
    "erste_stufe":     {"HOR": 4, "LES": 3, "SAG": 4, "ZUS": 4, "SCH": 3, "SPM": 3,
                        "WOR": 4, "GRA": 9, "AUS": 4, "ORT": 4,
                        "SOW": 1, "EIN": 2, "VER": 4,
                        "TMK": 6, "SLK": 6, "SBW": 6},
    "zweite_stufe":    {"HOR": 3, "LES": 3, "SAG": 4, "ZUS": 3, "SCH": 4, "SPM": 3,
                        "WOR": 2, "GRA": 5, "AUS": 4, "ORT": 2,
                        "SOW": 1, "EIN": 2, "VER": 4,
                        "TMK": 7, "SLK": 5, "SBW": 5},
}
SOLL_MARKER = {"à": 170, "•": 7}


def fehler(text):
    print(f"FEHLER: {text}", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# 1 -- Quelle pruefen und in Woerter mit Koordinaten umwandeln
# ---------------------------------------------------------------------------
WORT_XML = re.compile(
    r'<word xMin="([\d.]+)" yMin="([\d.]+)" xMax="([\d.]+)" yMax="([\d.]+)">([^<]*)</word>'
)
SEITE_XML = re.compile(r'<page width="[\d.]+" height="[\d.]+">(.*?)</page>', re.S)


def c0_zu_leerzeichen(text: str) -> str:
    """E25: C0-Steuerzeichen zu Leerzeichen, C1 bleibt.

    Dieser Plan traegt 17-mal U+0003 und kein einziges C1-Zeichen -- geprueft,
    nicht angenommen. Bei Deutsch Sek I traegt `\\x83` (C1) dagegen 42
    Erwartungen; wer die Bereinigung dorthin ausweitet, loescht sie spurlos.
    """
    return "".join(" " if (ord(z) < 32 and z not in "\t\n\x0c") else z for z in text)


def lies_pdf(pdf: Path) -> list:
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
        ["pdftotext", "-bbox-layout", str(pdf), "-"], capture_output=True, check=False
    )
    if lauf.returncode != 0:
        fehler(f"pdftotext brach ab: {lauf.stderr.decode('utf-8', 'replace')}")
    xml = lauf.stdout.decode("utf-8")
    seiten = []
    for inhalt in SEITE_XML.findall(xml):
        seiten.append([
            (float(a), float(b), float(c), float(d),
             c0_zu_leerzeichen(html.unescape(e)).strip())
            for a, b, c, d, e in WORT_XML.findall(inhalt)
        ])
    if not seiten:
        fehler("pdftotext lieferte keine Seiten -- anderes Ausgabeformat?")
    return seiten


# ---------------------------------------------------------------------------
# 2 -- Zeilen, Bloecke, Spaltentrennung (E47)
# ---------------------------------------------------------------------------
def zu_zeilen(woerter, y_toleranz=3.0):
    """Woerter nach Grundlinie zu sichtbaren Zeilen gruppieren.

    Die <line>-Gruppierung von `-bbox-layout` ist dafuer unbrauchbar: Sie folgt
    den Textlaeufen des PDF, nicht den Zeilen -- der Aufzaehlungsmarker landet
    dort in einer eigenen "Zeile".
    """
    zeilen = []
    for wort in sorted(woerter, key=lambda w: (w[1], w[0])):
        for zeile in zeilen:
            if abs(zeile[0][1] - wort[1]) <= y_toleranz:
                zeile.append(wort)
                break
        else:
            zeilen.append([wort])
    for zeile in zeilen:
        zeile.sort(key=lambda w: w[0])
    zeilen.sort(key=lambda z: z[0][1])
    return zeilen


def deckt_rinne(zeile) -> bool:
    return any(w[0] < RINNE[1] and w[2] > RINNE[0] for w in zeile)


def bloecke(zeilen):
    """Markerzeile samt Fortsetzungen. Der Block endet, sobald eine Zeile am
    linken Rand beginnt, die kein Marker ist -- eine Ueberschrift oder ein
    neuer Absatz.

    Das ist nicht Formsache: Liefe der Block weiter, geriete der einspaltige
    Einleitungsabsatz des naechsten Abschnitts hinein. Der deckt die Rinne ab,
    die Spaltenentscheidung fiele fuer den ganzen Block auf "einspaltig", und
    die letzte Erwartung bekaeme die rechte Spalte angehaengt. Genau so ist es
    beim ersten Entwurf geschehen (E47).
    """
    aus, akt, rand = [], [], None
    for zeile in zeilen:
        if not zeile:
            continue
        if zeile[0][4][:1] in MARKER:
            if akt:
                aus.append(akt)
            akt, rand = [zeile], zeile[0][0]
            continue
        if akt:
            if zeile[0][0] > rand + 4.0 or zeile[0][0] >= SPALTE_RECHTS:
                akt.append(zeile)
                continue
            aus.append(akt)
            akt, rand = [], None
        aus.append([zeile])
    if akt:
        aus.append(akt)
    return aus


def linke_spalte(seiten):
    """(Seitennummer, x der Zeile, Text) -- nur die linke Spalte.

    Die Spaltenfrage wird am BLOCK entschieden, nicht an der Zeile: Deckt auch
    nur eine Zeile des Blocks die Rinne ab, ist der Block einspaltig und bleibt
    unangetastet. Ein einspaltiger Absatz schuetzt sich damit selbst, und ein
    Wortzwischenraum, der zufaellig auf die Rinne faellt, schneidet keine
    Erwartung ab.
    """
    aus = []
    for nummer, woerter in enumerate(seiten, start=1):
        for block in bloecke(zu_zeilen(woerter)):
            einspaltig = any(deckt_rinne(z) for z in block)
            for zeile in block:
                if einspaltig:
                    links = zeile
                elif zeile[0][0] >= SPALTE_RECHTS:
                    continue                      # ganze Zeile rechte Spalte
                else:
                    links = zeile
                    for i in range(1, len(zeile)):
                        if (zeile[i][0] >= SPALTE_RECHTS
                                and zeile[i][0] - zeile[i - 1][2] >= MINDESTLUECKE):
                            links = zeile[:i]
                            break
                if links:
                    aus.append((nummer, links[0][0],
                                " ".join(w[4] for w in links).strip()))
    return aus


# ---------------------------------------------------------------------------
# 3 -- Wortschatz und Silbentrennung (E22, E28, E45, E48)
# ---------------------------------------------------------------------------
WORT = re.compile(r"[A-Za-zÄÖÜäöüß]+(?:-[A-Za-zÄÖÜäöüß]+)*")


def baue_wortschatz(zeilen) -> collections.Counter:
    schatz = collections.Counter()
    for _seite, _x, text in zeilen:
        for treffer in WORT.finditer(text):
            schatz[treffer.group()] += 1
    return schatz


def linke_kompositumshaelften(schatz) -> frozenset:
    """E45/E48: linke Haelften der ungetrennt belegten Bindestrich-Komposita,
    aber NUR mit kleingeschriebener rechter Haelfte.

    `kritisch-konstruktiv` belegt `kritisch`. `Autor-Rezipienten` belegt
    `Autor` NICHT -- das ist eine andere Bauform, und aus dem belegten
    `Autorschaft` wuerde sonst `Autor-schaft` (E48). Grossgeschriebene
    Fortsetzungen entscheidet Regel 5 ohnehin schon.
    """
    aus = set()
    for wort in schatz:
        if "-" not in wort:
            continue
        links_, rechts_ = wort.split("-", 1)
        if rechts_[:1].islower():
            aus.add(links_)
    return frozenset(aus)


def fuege_zusammen(rohzeilen, schatz, linke_haelften, kennung, protokoll):
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
        elif anfang in linke_haelften:                          # Regel 6 (E45/E48)
            text += zeile
            grund = "Regel 6 (belegte linke Kompositumshaelfte)"
        elif folge[:1].isupper():                               # Regel 5 (E28)
            text += zeile
            grund = "Regel 5 (Grossbuchstabe, echter Bindestrich)"
        else:                                                   # Regel 4
            text = text[:-1] + zeile
            grund = "Regel 4 (unbelegt, aufgeloest)"
        protokoll.append((kennung, anfang, folge, grund))

    text = re.sub(r"\s+", " ", text).strip()
    # E28: Ellipsenregel auch innerhalb der Zeile.
    text = re.sub(r"-(" + "|".join(re.escape(w) for w in ELLIPSE) + r")\b", r"- \1", text)
    return text


# ---------------------------------------------------------------------------
# 4 -- Gliederung lesen
# ---------------------------------------------------------------------------
def kapitaelchen(text: str) -> str:
    """E47: `I NTERKULTURELLE KOMMUNIKATIVE K OMPETENZ` zurueckbauen."""
    text = re.sub(r"\b([A-ZÄÖÜ]) ([A-ZÄÖÜ]{2,})", r"\1\2", text)
    text = re.sub(r"\s+([-/:])", r"\1", text)
    return re.sub(r"\s+", " ", text).strip()


def ist_ueberschrift(text: str) -> bool:
    ohne = re.sub(r"\s+", "", text)
    buchstaben = [z for z in ohne if z.isalpha()]
    if not buchstaben or len(ohne) <= 6:
        return False
    return sum(1 for z in buchstaben if z.isupper()) / len(buchstaben) > 0.9


KAPITEL = [
    (re.compile(r"^2\.2\s"), "erprobungsstufe"),
    (re.compile(r"^2\.3\.1\s"), "erste_stufe"),
    (re.compile(r"^2\.3\.2\s"), "zweite_stufe"),
    (re.compile(r"^3\s+Lernerfolg"), None),
]

# Name -> (Bereichskuerzel, Blattkuerzel). Blatt None heisst: der Knoten hat
# Kinder und traegt selbst keine Erwartungen.
def baue_verzeichnis():
    nach_name = {}
    for bkz, bname, teile in BEREICHE:
        nach_name[re.sub(r"\s+", "", bname).upper()] = (bkz, None if teile else bkz)
        for tkz, tname, unter in teile:
            nach_name[re.sub(r"\s+", "", tname).upper()] = (bkz, None if unter else tkz)
            for ukz, uname in unter:
                nach_name[re.sub(r"\s+", "", uname).upper()] = (bkz, ukz)
    return nach_name


def sammle_eintraege(zeilen):
    """Erwartungen mit Phase, Kompetenzbereich und Blatt."""
    verzeichnis = baue_verzeichnis()
    # Kapitelgrenzen: die LETZTE Fundstelle zaehlt. Die erste steht im
    # Inhaltsverzeichnis, und wer sie nimmt, zaehlt die Aufzaehlungen der
    # Einleitungskapitel als Erwartungen der Zweiten Stufe.
    grenzen = {}
    for i, (_s, _x, text) in enumerate(zeilen):
        for muster, phase in KAPITEL:
            if muster.match(text.strip()):
                grenzen[phase] = i
    for schluessel in ("erprobungsstufe", "erste_stufe", "zweite_stufe", None):
        if schluessel not in grenzen:
            fehler(f"Kapitelmarke fehlt: {schluessel}")

    abschnitte = [
        ("erprobungsstufe", grenzen["erprobungsstufe"], grenzen["erste_stufe"]),
        ("erste_stufe", grenzen["erste_stufe"], grenzen["zweite_stufe"]),
        ("zweite_stufe", grenzen["zweite_stufe"], grenzen[None]),
    ]

    eintraege = []
    for phase, von, bis in abschnitte:
        bereich = blatt = None
        akt = None
        i = von
        while i < bis:
            seite, x, roh = zeilen[i]
            text = roh.strip()
            schluessel = re.sub(r"\s+", "", kapitaelchen(text)).upper().rstrip(":")
            neu = None
            # Ueberschriften sind an drei Formen erkennbar, und alle drei
            # kommen vor: Kapitaelchen in Grossbuchstaben (Kompetenzbereiche),
            # eine kurze Zeile mit Doppelpunkt am linken Rand (die drei
            # Unterbereiche der Interkulturellen Kompetenz) und eine kurze
            # Zeile OHNE Doppelpunkt (Wortschatz, Grammatik, Aussprache und
            # Intonation, Orthografie). Entschieden wird deshalb nicht ueber
            # die Form, sondern ueber das Verzeichnis: Steht der Text dort,
            # ist es eine Ueberschrift.
            if ist_ueberschrift(text) or (x < 80 and len(text) <= 60):
                neu = verzeichnis.get(schluessel)
            # "Interkulturelle Einstellungen und Be-" / "wusstheit:" ist ueber
            # den Zeilenumbruch getrennt.
            if neu is None and x < 80 and text.endswith("-") and i + 1 < bis:
                zusammen = re.sub(r"\s+", "", text[:-1] + zeilen[i + 1][2].strip()).upper().rstrip(":")
                if zusammen in verzeichnis:
                    neu = verzeichnis[zusammen]
                    i += 1
            if neu is not None:
                if akt:
                    eintraege.append(akt)
                    akt = None
                bereich, blatt = neu
                i += 1
                continue

            if text[:1] in MARKER:
                if akt:
                    eintraege.append(akt)
                if blatt is None:
                    fehler(f"Erwartung ohne Blatt auf Seite {seite}: {text[:60]!r}")
                akt = {"phase": phase, "bereich": bereich, "blatt": blatt,
                       "marker": text[0], "seite": seite,
                       "zeilen": [text[1:].strip()]}
                rand = x
            elif akt is not None:
                if x > rand + 4.0 and text:
                    akt["zeilen"].append(text)
                else:
                    eintraege.append(akt)
                    akt = None
            i += 1
        if akt:
            eintraege.append(akt)
    return eintraege


# ---------------------------------------------------------------------------
# 5 -- Seed schreiben
# ---------------------------------------------------------------------------
def sql_text(wert: str) -> str:
    return wert.replace("'", "''")


def kurzname(beschreibung: str) -> str:
    if len(beschreibung) <= KURZNAME_GRENZE:
        return beschreibung
    return beschreibung[:KURZNAME_GRENZE].rsplit(" ", 1)[0] + " …"


def knotenplan():
    """(code, name_teile, phase, art, parent_code, blatt_kuerzel) je Knoten.

    Codeschema nach E46: `EN_<Phase>_<Kompetenzbereich>[_<Unterbereich>]`.
    Die Funktionale kommunikative Kompetenz faellt im Code aus -- sie ist die
    Klammer ueber die sieben Teilbereiche, und `EN_EP_FKK_HOR_01` truege eine
    Ebene mit, die zur Unterscheidung nichts beitraegt. Alle uebrigen Ebenen
    stehen im Code.
    """
    plan = []
    for phase in ("erprobungsstufe", "erste_stufe", "zweite_stufe"):
        pk = PHASEN_KUERZEL[phase]
        for bkz, bname, teile in BEREICHE:
            bcode = f"EN_{pk}_{bkz}"
            bpfad = [PHASEN_NAME[phase], bname]
            plan.append((bcode, bpfad, phase, ART_BEREICH, None,
                         bkz if not teile else None))
            for tkz, tname, unter in teile:
                # Unter FKK faellt der Bereich im Code weg, unter IKK nicht.
                tcode = f"EN_{pk}_{tkz}" if bkz == "FKK" else f"EN_{pk}_{bkz}_{tkz}"
                tpfad = bpfad + [tname]
                art = ART_TEIL if bkz == "FKK" else ART_UNTER
                plan.append((tcode, tpfad, phase, art, bcode,
                             tkz if not unter else None))
                for ukz, uname in unter:
                    plan.append((f"{tcode}_{ukz}", tpfad + [uname], phase,
                                 ART_UNTER, tcode, ukz))
    return plan


def schreibe_seed(eintraege, ziel: Path):
    plan = knotenplan()
    nach_blatt = collections.defaultdict(list)
    for eintrag in eintraege:
        nach_blatt[(eintrag["phase"], eintrag["blatt"])].append(eintrag)

    zeilen = []
    a = zeilen.append
    a("-- =============================================================================")
    a("-- Seed 19: Englisch – Kernlehrplan Gymnasium Sek I (G9), NRW 2019 (Heft 3417)")
    a("--")
    a(f"-- Quelle: {QUELLE}")
    a(f"-- SHA256: {QUELLE_SHA}")
    a(f"-- Erzeugt von: {ERZEUGER}")
    a("--")
    a("-- NICHT VON HAND AENDERN: Korrekturen gehoeren in den Erzeuger, die Datei")
    a("-- wird daraus neu geschrieben (E19).")
    a("-- Voraussetzung: Migration 08, 13 und 15 (Baum, Spalte `art`).")
    a("-- Idempotent: loescht vorhandenen ENG_KLP-Rahmen und baut ihn neu auf.")
    a("--")
    a("-- Erstes Fach mit DREI Gliederungsebenen (E46). Deshalb drei INSERTs auf")
    a("-- `kompetenzbereiche` statt der bisherigen zwei: Wurzeln, Mittelknoten,")
    a("-- Blaetter -- jeder loest seinen Elternknoten ueber dessen Code auf.")
    a("-- =============================================================================")
    a("")
    a("SET NAMES utf8mb4;")
    a("START TRANSACTION;")
    a("")
    a("SET @schule := 1;")
    a(f"SET @fach := (SELECT id FROM faecher WHERE schule_id = @schule "
      f"AND kuerzel = '{FACH_KUERZEL}' LIMIT 1);")
    a("")
    a("-- Nur der eigene Rahmen wird geloescht; CASCADE raeumt Bereiche und Kompetenzen.")
    a(f"DELETE FROM kompetenzrahmen WHERE schule_id = @schule AND kuerzel = '{RAHMEN_KUERZEL}';")
    a("")
    a("INSERT INTO kompetenzrahmen (schule_id, name, kuerzel, beschreibung, quelle_url, fach_id)")
    a(f"VALUES (@schule, '{sql_text(RAHMEN_NAME)}', '{RAHMEN_KUERZEL}', "
      f"'{sql_text(RAHMEN_BESCHREIBUNG)}', '{sql_text(str(QUELLE))}', @fach);")
    a("SET @rahmen := LAST_INSERT_ID();")
    a("")

    ebenen = {0: [], 1: [], 2: []}
    tiefe_von = {}
    for lauf, (code, pfad, phase, art, pcode, blatt) in enumerate(plan, start=1):
        tiefe = 0 if pcode is None else tiefe_von[pcode] + 1
        tiefe_von[code] = tiefe
        name = " · ".join(pfad)
        if tiefe == 0:
            ebenen[0].append(
                f"(@rahmen, NULL, '{code}', '{sql_text(name)}', {lauf}, '{phase}', '{art}')"
            )
        else:
            ebenen[tiefe].append(
                f"  SELECT '{code}' AS code, '{sql_text(name)}' AS name, "
                f"{lauf} AS reihenfolge, '{phase}' AS phase, '{art}' AS art, "
                f"'{pcode}' AS pcode"
            )

    a("-- --------------------------------------------------------------------------")
    a("-- Kompetenzbereiche: drei Ebenen (E29b, E31, E46)")
    a("--")
    a("-- Die Tiefe schwankt innerhalb des Plans: Text- und Medienkompetenz,")
    a("-- Sprachlernkompetenz und Sprachbewusstheit tragen ihre Erwartungen")
    a("-- direkt; unter der Funktionalen kommunikativen Kompetenz liegen sieben")
    a("-- Teilbereiche, unter einem davon vier Unterbereiche.")
    a("-- Kompetenzen haengen nur an Blaettern; die Phase steht als Spalte an")
    a("-- jedem Knoten.")
    a("-- --------------------------------------------------------------------------")
    a("INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art) VALUES")
    a(",\n".join(ebenen[0]) + ";")
    a("")
    for tiefe in (1, 2):
        a(f"-- Ebene {tiefe + 1}: parent_id ueber den Code des Elternknotens.")
        a("INSERT INTO kompetenzbereiche (rahmen_id, parent_id, code, name, reihenfolge, phase, art)")
        a("SELECT @rahmen, p.id, t.code, t.name, t.reihenfolge, t.phase, t.art")
        a("FROM (")
        a("\n  UNION ALL\n".join(ebenen[tiefe]))
        a(") t JOIN kompetenzbereiche p ON p.rahmen_id = @rahmen AND p.code = t.pcode;")
        a("")

    a("-- --------------------------------------------------------------------------")
    a("-- Kompetenzerwartungen (flach, nur an Blaettern)")
    a("-- --------------------------------------------------------------------------")
    for code, pfad, phase, art, pcode, blatt in plan:
        if blatt is None:
            continue
        posten = nach_blatt[(phase, blatt)]
        if not posten:
            fehler(f"Blatt ohne Erwartungen: {code}")
        a(f"-- {' · '.join(pfad)} ({len(posten)})")
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
    blaetter = sum(1 for _c, _p, _ph, _a, _pc, b in plan if b is not None)
    a(f"-- Kontrolle: erwartet Knoten={len(plan)} (davon {blaetter} Blaetter), "
      f"Kompetenzen={len(eintraege)}")
    ziel.write_text("\n".join(zeilen) + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
def main():
    seiten = lies_pdf(WURZEL / QUELLE)
    zeilen = linke_spalte(seiten)
    schatz = baue_wortschatz(zeilen)
    linke_haelften = linke_kompositumshaelften(schatz)
    eintraege = sammle_eintraege(zeilen)

    protokoll = []
    for eintrag in eintraege:
        kennung = f"S{eintrag['seite']}/{eintrag['blatt']}"
        roh = fuege_zusammen(eintrag["zeilen"], schatz, linke_haelften,
                             kennung, protokoll)
        # Wie Deutsch Sek I und Sport: kein Schlusskomma, kein Schlusspunkt.
        # Es gibt hier keinen Bestand, an dem man sich ausrichten koennte --
        # die Wahl folgt den beiden Sek-I-Faechern, nicht Deutsch GOSt.
        eintrag["text"] = roh.rstrip(" ,.")

    # -- Zaehlwerte ------------------------------------------------------
    gezaehlt = collections.Counter((e["phase"], e["blatt"]) for e in eintraege)
    abweichungen = []
    for phase, blaetter in SOLL.items():
        for blatt, soll in blaetter.items():
            ist = gezaehlt.get((phase, blatt), 0)
            if ist != soll:
                abweichungen.append(f"{PHASEN_KUERZEL[phase]}/{blatt}: {ist} statt {soll}")
    for schluessel in gezaehlt:
        if schluessel[1] not in SOLL[schluessel[0]]:
            abweichungen.append(f"unbekanntes Blatt: {schluessel}")

    # E28: Aufteilung je Marker, nicht nur die Summe.
    marker = collections.Counter(e["marker"] for e in eintraege)
    for zeichen, soll in SOLL_MARKER.items():
        if marker.get(zeichen, 0) != soll:
            abweichungen.append(
                f"Marker {zeichen!r}: {marker.get(zeichen, 0)} statt {soll}"
            )

    if abweichungen:
        print("Zaehlwerte weichen ab -- es wird nichts geschrieben:", file=sys.stderr)
        for zeile in abweichungen:
            print("  " + zeile, file=sys.stderr)
        sys.exit(1)

    schreibe_seed(eintraege, WURZEL / ZIEL)

    plan = knotenplan()
    blaetter = sum(1 for _c, _p, _ph, _a, _pc, b in plan if b is not None)
    print(f"{ZIEL} geschrieben.")
    print(f"  Erwartungen: {len(eintraege)}  "
          f"(EP {sum(v for k, v in gezaehlt.items() if k[0] == 'erprobungsstufe')}, "
          f"S1 {sum(v for k, v in gezaehlt.items() if k[0] == 'erste_stufe')}, "
          f"S2 {sum(v for k, v in gezaehlt.items() if k[0] == 'zweite_stufe')})")
    print(f"  Marker: " + ", ".join(f"{z} {n}" for z, n in sorted(marker.items())))
    print(f"  Knoten: {len(plan)}, davon Blaetter {blaetter}")

    nach_regel4 = [p for p in protokoll if p[3].startswith("Regel 4")]
    nach_regel6 = [p for p in protokoll if p[3].startswith("Regel 6")]
    print(f"  Trennstellen: {len(protokoll)}, davon {len(nach_regel4)} nach Regel 4 "
          f"(unbelegt) und {len(nach_regel6)} nach Regel 6 (E48).")
    if nach_regel6:
        print("  Nach Regel 6 entschieden (Bindestrich bleibt):")
        for _k, anfang, folge, _g in sorted(set((p[0], p[1], p[2], p[3]) for p in nach_regel6),
                                            key=lambda p: (p[1], p[2])):
            print(f"    {anfang}-{folge}")
    if nach_regel4:
        print("  Nach Regel 4 entschieden (bitte durchsehen):")
        for anfang, folge in sorted(set((p[1], p[2]) for p in nach_regel4)):
            print(f"    {anfang}- + {folge}  →  {anfang}{folge}")


if __name__ == "__main__":
    main()
