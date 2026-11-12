#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Abgleich: jede Erwartung eines Seeds gegen einen zweiten Schnitt aus dem PDF.

WOZU. Ein Fach ohne Bestand hat keinen Wortlautvergleich (REIHENREGELN 2:
"Das erste Exemplar einer Sorte hat keinen Vergleich"). Die Sollzahlen je
Blatt sehen keinen falschen SCHNITT: Bei Spanisch trafen im ersten Lauf alle
Zahlen, und trotzdem endete ES_2FS_S2_TMK_05 auf "... einsetzen,
produktionsorientierte oder kreative", waehrend TMK_06 erst mit "Texte zum
..." begann (E67). Die Endepruefung aus E64 war gruen, beide Texte endeten
auf einem Buchstaben. Gefunden hat es nur dieser Abgleich.

Er schneidet die Erwartungen ein zweites Mal aus, mit einem Verfahren, das
mit dem Erzeuger nichts teilt: `pdftotext -raw` (Reihenfolge des
Inhaltsstroms, keine Koordinaten), Marker am Zeilenanfang, Ende an der
naechsten Zeile, die etwas anderes beginnt. Kein Code aus einem Erzeuger.

AUFRUF aus der Projektwurzel, mit dem Seed als einzigem Argument:

    python3 sql/gen/abgleich.py sql/21_seed_spanisch_klp.sql

Quelle und Pruefsumme stehen im Kopf des Seeds (E19) und werden von dort
gelesen; weicht die Summe ab, bricht der Abgleich ab.

Exit 0 = kein harter Befund, 1 = harter Befund, 2 = Voraussetzung fehlt
(Quelle, Werkzeug, Kapitelmarke, null Erwartungen). Die letzte Zeile beginnt
mit "ABGLEICH:" und steht nur da, wenn der Lauf durchkam.

WIE VERGLICHEN WIRD. Ueber die Buchstabenfolge: Leerzeichen, Satzzeichen,
Bindestriche und Ziffern fallen auf beiden Seiten weg. Jede Erwartung aus dem
`-raw`-Schnitt wird genau einem Seedtext zugeordnet:

  gleich           Buchstabenfolge identisch.
  raw laeuft weiter  Der Seedtext ist Anfang des Schnitts; der Schnitt laeuft
                   in eine Ueberschrift, eine Fussnotenziffer oder die rechte
                   Spalte weiter. Der Ueberhang wird ausgegeben und MUSS mit
                   einem Satzzeichen beginnen, gefolgt vom ZEILENENDE (ggf.
                   mit Fussnotenziffer davor oder dahinter) -- eine Erwartung endet im
                   PDF am Zeilenende. Sonst endet der Seedtext mitten im Satz,
                   auch an einem Komma: HART.
  raw bricht ab    Der Schnitt ist Anfang des Seedtexts; er endete an einem
                   Seitenumbruch, hinter dem die rechte Spalte weiterlief. Der
                   Rest des Seedtexts muss zusammenhaengend im Dokument stehen,
                   dort von Satzzeichen und Zeilenende gefolgt sein (sonst ist
                   der Seedtext abgeschnitten), und darf NICHT der Anfang einer
                   anderen Erwartung sein -- so sah TMK_05 aus: HART.
                   Steht der Rest mehrfach im Dokument, genuegt EIN Vorkommen
                   mit Zeilenende; das ist eine benannte Schwaeche.
  ohne Gegenstueck HART, ebenso jeder Seedtext, der uebrig bleibt.

Zusaetzlich HART: eine Ziffer in einem Seedtext (Seitenzahl, E64), und eine
abweichende Zahl der Erwartungen.

WAS ES NICHT PRUEFT.
  * Trennentscheidungen. Die Buchstabenfolge ist fuer `Ebe-nen`/`Ebenen` und
    `kritisch-konstruktiv`/`kritischkonstruktiv` gleich. Dafuer gibt der
    Erzeuger die Liste der Regel-4-Faelle aus (E22).
  * Zeichensetzung und Wortabstaende innerhalb eines Textes.
  * Die Zuordnung zu Blaettern. Ein richtig geschnittener Text am falschen
    Blatt besteht den Abgleich; dagegen stehen die Sollzahlen je Blatt.
  * Den Ueberhang selbst. Ob er wirklich Ueberschrift oder rechte Spalte ist,
    sieht ein Mensch; das Werkzeug prueft nur, dass er mit einem Satzzeichen
    beginnt. Die Liste ist deshalb durchzusehen, nicht nur der Exit-Code.
  * Das Kapitel eines Befunds. Zugeordnet wird ueber den Text, und 2.2.2 und
    2.4 fuehren wortgleiche Erwartungen. Beim Fehler aus E67 erschien der
    uebrige `-raw`-Eintrag deshalb unter "3FS", obwohl er in 2.2.2 stand.
    Massgeblich ist der Code am harten Befund, nicht die Kapitelangabe.
  * Ob der `-raw`-Schnitt selbst richtig ist. Er ist ein zweites Verfahren,
    kein richtiges. Wo beide denselben Fehler machen, schweigt der Abgleich.

WORAN ES HAENGT -- gebaut und belegt fuer Spanisch Sek I (E67). Spanisch-
bzw. planspezifisch sind genau diese Stellen, alle unter "Planabhaengig":

  * KAPITEL: die Marken 2.2.1 / 2.2.2 / 2.3 / 2.4 / "3 Lernerfolg" und welche
    davon Erwartungen fuehren (2.3 nicht). Das ist die Anlage aus E63.
  * MARKER = "à" am Zeilenanfang.
  * STOP: woran eine Erwartung im `-raw`-Text endet -- `−` (fachliche
    Konkretisierung), `•`, "Fachliche Konkretisierungen", "Sie können",
    "Die Schülerinnen", eine reine Zahlzeile (Seitenzahl, Fussnote).
  * FORTSETZUNG: Nach einer Seitenzahl geht die Erwartung weiter, wenn die
    naechste Zeile klein beginnt. Bei Spanisch belegt, sonst nicht.

GEGENPROBEN (12.11.2026, an Kopien des Seeds, jede mit veraenderter
Pruefsumme; alle sechs schlagen mit Exit 1 und dem richtigen Code an):
  M1  der echte Fehler aus E67 (Zeilenbildung mit `zeile[0]`)
  M2  Text an einem Komma mitten im Satz abgeschnitten (Fall "raw laeuft weiter")
  M3  Text auf einem heilen Wort abgeschnitten, ueber einen Seitenumbruch
  M4  Seitenzahl am Ende angehaengt
  M5  letztes Wort weggelassen (Fall "gleich")
  M6  Satzteil verloren
Am unveraenderten Seed: 106 gleich, 32 Ueberhang, 6 ueber Seitenumbruch,
0 hart. Zwei eigene Fehlalarme gab es auf dem Weg: Die Fussnotenziffer steht
HINTER dem Satzzeichen (`realisieren.18`), das Muster erwartete sie davor.

Fuer ein anderes Fach sind diese Stellen neu zu bestimmen und gegen den Plan
zu belegen; das Werkzeug zu verallgemeinern ist ein eigener Schritt.

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
# Planabhaengig -- belegt fuer Spanisch Sek I (E67), siehe Kopf
# ---------------------------------------------------------------------------
# (Marke, Muster, fuehrt Erwartungen bis zur naechsten Marke)
KAPITEL = [
    ("2FS_S1", r"2\.2\.1\s", True),
    ("2FS_S2", r"2\.2\.2\s", True),
    ("2.3", r"2\.3\s", False),
    ("3FS", r"2\.4\s", True),
    ("ENDE", r"3\s+Lernerfolg", False),
]
MARKER = "à"
STOP = re.compile(
    r"^(à|−|•|Fachliche Konkretisierungen|Sie können|Die Schülerinnen|\d{1,3}$)"
)
ZAHLZEILE = re.compile(r"\d{1,3}")
# Ein Ueberhang darf so beginnen: Satzzeichen, dann Zeilenende. Eine
# Fussnotenziffer kann davor oder dahinter stehen -- bei Spanisch steht sie
# dahinter (`realisieren.18`, fuenfmal).
UEBERHANG_OK = re.compile(r"^\d{0,3}[.,;:]\d{0,3}[ \t\x0c]*(\n|$)")


def halt(text: str, code: int = 2):
    print(f"FEHLER: {text}", file=sys.stderr)
    sys.exit(code)


def nur_buchstaben(s: str) -> str:
    return "".join(z for z in s if z.isalpha())


def kopfwert(seed: str, name: str) -> str:
    m = re.search(rf"^-- {name}: *(.+?)\s*$", seed, re.M)
    if not m:
        halt(f"Seed fuehrt keine Zeile '-- {name}:' (E19)")
    return m.group(1)


def raw_text(pdf: Path, sha_soll: str) -> str:
    if not pdf.is_file():
        halt(f"Quelle fehlt: {pdf}")
    ist = hashlib.sha256(pdf.read_bytes()).hexdigest()
    if ist != sha_soll:
        halt(f"Pruefsumme weicht ab: Seed nennt {sha_soll}, Datei hat {ist}")
    if shutil.which("pdftotext") is None:
        halt("pdftotext fehlt (brew install poppler)")
    lauf = subprocess.run(["pdftotext", "-raw", str(pdf), "-"],
                          capture_output=True, check=False)
    if lauf.returncode != 0:
        halt("pdftotext brach ab: " + lauf.stderr.decode("utf-8", "replace"))
    text = lauf.stdout.decode("utf-8")
    # E25: C0 ausser Zeilen- und Seitenumbruch zu Leerzeichen, C1 bleibt.
    return "".join(" " if (ord(z) < 32 and z not in "\n\x0c") else z for z in text)


def schneide(raw: str):
    """Erwartungen aus dem `-raw`-Text: (Kapitel, Text)."""
    zeilen = [z.replace("\x0c", "").strip() for z in raw.split("\n")]
    grenzen = {}
    for marke, muster, _ in KAPITEL:
        treffer = [i for i, z in enumerate(zeilen) if re.match(muster, z)]
        if not treffer:
            halt(f"Kapitelmarke fehlt: {marke}")
        grenzen[marke] = treffer[-1]   # die erste steht im Inhaltsverzeichnis
    folge = [m for m, _, _ in KAPITEL]
    aus = []
    for k, (marke, _, fuehrt) in enumerate(KAPITEL[:-1]):
        if not fuehrt:
            continue
        i, bis = grenzen[marke], grenzen[folge[k + 1]]
        while i < bis:
            if not zeilen[i].startswith(MARKER):
                i += 1
                continue
            teile = [zeilen[i][len(MARKER):].strip()]
            i += 1
            while i < bis and zeilen[i] and not STOP.match(zeilen[i]):
                teile.append(zeilen[i])
                i += 1
            # Seitenzahl mitten in der Erwartung: weiter, wenn klein fortgesetzt
            while (i + 1 < bis and ZAHLZEILE.fullmatch(zeilen[i] or "x")
                   and zeilen[i + 1] and not STOP.match(zeilen[i + 1])
                   and zeilen[i + 1][:1].islower()):
                i += 1
                while i < bis and zeilen[i] and not STOP.match(zeilen[i]):
                    teile.append(zeilen[i])
                    i += 1
            aus.append((marke, "\n".join(teile)))
    return aus


def ueberhang(r: str, anzahl_buchstaben: int) -> str:
    """Der Rest von r hinter den ersten `anzahl_buchstaben` Buchstaben."""
    n = 0
    for pos, z in enumerate(r):
        if n == anzahl_buchstaben:
            return r[pos:].lstrip(" ")
        if z.isalpha():
            n += 1
    return ""


def main():
    if len(sys.argv) != 2:
        halt("Aufruf: python3 sql/gen/abgleich.py sql/<nr>_seed_<fach>.sql")
    seed_pfad = Path(sys.argv[1])
    if not seed_pfad.is_file():
        halt(f"Seed fehlt: {seed_pfad}")
    seed = seed_pfad.read_text(encoding="utf-8")
    raw = raw_text(Path(kopfwert(seed, "Quelle")), kopfwert(seed, "SHA256"))

    erw = schneide(raw)
    texte = [(c, t.replace("''", "'")) for c, t in re.findall(
        r"SELECT '([A-Z0-9_]+)' AS code, '(?:[^']|'')*' AS kurzname, "
        r"'((?:[^']|'')*)' AS beschreibung", seed)]
    if not erw or not texte:
        # Null Funde sind ein Fehler, kein Ergebnis (REIHENREGELN 2).
        halt(f"nichts zu vergleichen: {len(erw)} im -raw-Schnitt, {len(texte)} im Seed")

    hart = []
    je_kapitel = collections.Counter(m for m, _ in erw)
    print("-raw-Schnitt je Kapitel: " + ", ".join(f"{m} {n}" for m, n in je_kapitel.items()))
    print(f"Erwartungen: -raw {len(erw)}, Seed {len(texte)}")
    if len(erw) != len(texte):
        hart.append(f"Zahl weicht ab: -raw {len(erw)}, Seed {len(texte)}")

    ganz = nur_buchstaben(raw)
    # Stelle jedes Buchstabens im raw-Text, fuer das Ende eines Fundes
    lage = [i for i, z in enumerate(raw) if z.isalpha()]

    def endet_an_zeilenende(rest: str) -> bool:
        for m in re.finditer(re.escape(rest), ganz):
            hinter = raw[lage[m.end() - 1] + 1:]
            if UEBERHANG_OK.match(hinter):
                return True
        return False
    raw_anfaenge = [nur_buchstaben(t) for _, t in erw]
    rest_seed = list(texte)
    kat = collections.Counter()
    print("\n=== Einordnung (nur, was nicht gleich ist)")
    for marke, r in erw:
        rb = nur_buchstaben(r)
        treffer = [x for x in rest_seed if nur_buchstaben(x[1]) == rb]
        if treffer:
            rest_seed.remove(treffer[0])
            kat["gleich"] += 1
            continue
        laenger = sorted((x for x in rest_seed if rb.startswith(nur_buchstaben(x[1]))),
                         key=lambda x: -len(nur_buchstaben(x[1])))
        if laenger:
            code, t = laenger[0]
            rest_seed.remove(laenger[0])
            kat["raw laeuft weiter"] += 1
            ueber = ueberhang(r, len(nur_buchstaben(t)))
            ok = bool(UEBERHANG_OK.match(ueber))
            print(f"  RAW+ {code}: …{t[-30:]!r} || {ueber[:70].replace(chr(10), ' ⏎ ')!r}"
                  + ("" if ok else "   <-- HART"))
            if not ok:
                hart.append(f"{code}: endet vor dem Satzzeichen, im PDF folgt {ueber[:40]!r}")
            continue
        kuerzer = [x for x in rest_seed if nur_buchstaben(x[1]).startswith(rb)]
        if kuerzer:
            code, t = kuerzer[0]
            rest_seed.remove(kuerzer[0])
            kat["raw bricht ab"] += 1
            rest = nur_buchstaben(t)[len(rb):]
            im_dokument = rest in ganz
            fremd = [a for a in raw_anfaenge if a and a != rb and rest.startswith(a[:30])]
            befund = []
            if not im_dokument:
                befund.append("Rest steht nicht im Dokument")
            elif not endet_an_zeilenende(rest):
                befund.append("Rest endet im Dokument nicht am Satzende")
            if fremd:
                befund.append("Rest beginnt eine andere Erwartung")
            print(f"  RAW- {code}: -raw endet …{r[-30:].replace(chr(10), ' ⏎ ')!r}; Rest {len(rest)} Buchstaben"
                  + (f"   <-- HART: {', '.join(befund)}" if befund else ", im Dokument zusammenhaengend"))
            if befund:
                hart.append(f"{code}: {', '.join(befund)}")
            continue
        kat["ohne Gegenstueck"] += 1
        print(f"  OHNE {marke}: {r[:90].replace(chr(10), ' ')!r}   <-- HART")
        hart.append(f"-raw ohne Gegenstueck ({marke}): {r[:50].replace(chr(10), ' ')!r}")
    for code, t in rest_seed:
        print(f"  SEED {code}: {t[:90]!r}   <-- HART")
        hart.append(f"{code}: Seedtext ohne Gegenstueck")

    for code, t in texte:
        if re.search(r"\d", t):
            hart.append(f"{code}: Ziffer im Text (Seitenzahl? E64)")

    print("\n" + ", ".join(f"{k} {v}" for k, v in kat.items()))
    if hart:
        print(f"\n{len(hart)} harte(r) Befund(e):")
        for h in hart:
            print("  " + h)
    print(f"ABGLEICH: {len(texte)} Seedtexte, {kat['gleich']} gleich, "
          f"{kat['raw laeuft weiter']} mit Ueberhang (durchsehen), "
          f"{kat['raw bricht ab']} ueber Seitenumbruch, {len(hart)} hart")
    sys.exit(1 if hart else 0)


if __name__ == "__main__":
    main()
