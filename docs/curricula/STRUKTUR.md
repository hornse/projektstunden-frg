# Strukturerhebung über alle Kernlehrpläne

Befundtabelle zu den 37 Plänen unter `docs/curricula/`. **Dies ist eine
Erhebung, keine Entscheidung.** Sie ist die Grundlage für die Festlegung des
Datenmodells, nicht ihr Ersatz, und enthält bewusst keine Empfehlung dazu.

Anlass: Das Datenmodell wurde zweimal auf Grundlage einer Stichprobe der
Gliederungsüberschriften festgelegt und beide Male widerlegt — E11 (Sport habe
zwei sich kreuzende Inhaltsachsen: hat es nicht) und E18 (unterhalb der Phase
lägen nie mehr als zwei Ebenen: bei Englisch sind es drei).

Zweiter Zweck: Jedes bisher importierte Fach hat eine Eigenheit der
Textextraktion mitgebracht, die niemand vermutet hatte. Was hier steht, gehört
in den jeweiligen Fachauftrag, **bevor** der Lauf beginnt.

---

## Wie erhoben wurde

Drei Stufen. Die erste misst, die zweite liest, die dritte prüft.

**Stufe 1 — messen.** Deutungsfrei. `\x0c` und Seitenzahlzeilen werden vor
jeder Auswertung getilgt; ohne das gehen Zeilen verloren, die mit einem
Seitenumbruch beginnen. Erhoben werden: Marker am Zeilenanfang **mit dem
Abstand dahinter**, Steuerzeichen mit Codepoint, die Spaltigkeit aus den
Koordinaten von `pdftotext -bbox-layout`, und die Kapitelnummerierung, die das
Dokument selbst führt.

**Stufe 2 — lesen.** Der Kompetenzteil wird gelesen, die Gliederungsebenen
werden im Wortlaut benannt. Ein Verfahren, das Überschriften an Formmerkmalen
erkennt, ist nicht belastbar; die Reduktion der Leseliste ist ein
Lesehilfsmittel, keine Erkennung.

**Stufe 3 — prüfen.** Drei Wege:

* **(a)** Summe je Gliederungseinheit gegen die Zahl der Marker im
  Kompetenzteil.
* **(b)** Aufteilung je Marker, nicht nur die Summe (E28).
* **(c)** Strukturvergleich zwischen den Phasen desselben Plans. Eine Einheit,
  die in einer Phase keine Erwartungen hat, in einer anderen aber welche, ist
  ein Befund.

Dazu ein **zweiter, unabhängiger Zählweg**: Erwartungen folgen auf die Formel
„Die Schülerinnen und Schüler (können)" bzw. „Sie können". Das ist ein
inhaltliches Merkmal und unabhängig vom Marker. Wo beide Wege stark
auseinanderlaufen, ist der Plan hier als **unsicher** gekennzeichnet.

### Warum Weg (c) nötig ist

Bei Englisch Sek I ergab die erste Zählung „170 je Einheit = 170 direkt = 170
im Dokument" — dreimal dieselbe Zahl, dreimal richtig gerechnet, und trotzdem
sieben Erwartungen zu wenig: Alle drei Wege zählten denselben Marker. Auffällig
wurde es erst daran, dass `TEXT- UND MEDIENKOMPETENZ` in der Zweiten Stufe mit
**null** Erwartungen dastand, während dieselbe Einheit in den anderen Phasen 4
und 6 hat. Dort steht der Marker `•` statt `à`.

---

## Übersicht

`Tiefe` zählt die Gliederungsebenen **unterhalb der Phase**, bis zur Erwartung.
`✓` = gelesen und durch beide Zählwege gestützt. `?` = unsicher, siehe den
Abschnitt zum Plan.

| # | Datei | Fach | Stufe | Marker (Zeichen+Abstand) | Spalten | Tiefe | Erwartungen | |
|---|---|---|---|---|---|---|---|---|
| 1 | `g9_bi_klp_-3413_…` | Biologie | Sek I | `à`+3 · Tabelle | ein | 2 | 146 | ✓ |
| 2 | `g9_ch_klp_3415_…` | Chemie | Sek I | `à`+3/+4 · Tabelle | ein | 2 | 117 | ✓ |
| 3 | `g9_d_klp_3409_…` | Deutsch | Sek I | `à`+3 · `\x83`+3 | ein | 2 | **226** | ✓ |
| 4 | `g9_e_klp_3417_…` | Englisch | Sek I | `à`+3/+4/+1 · `•`+3 | **zwei** | **3** | 177 | ✓ |
| 5 | `g9_ek_klp_3408_…` | Erdkunde | Sek I | `à`+3 · `\x83`+3 | ein | 2 | 103 | ✓ |
| 6 | `g9_er_klp_3414_…` | Ev. Religionslehre | Sek I | `à`+3 · `\x83`+3 | ein | 2 | 177 | ✓ |
| 7 | `g9_f_klp_3410_…` | Französisch | Sek I | `à`+3/+4/+1 · `•`+4 | **zwei** | **3** | 204 | ✓ |
| 8 | `g9_ge_klp_3407_…` | Geschichte | Sek I | `à`+3 · `\x83`+3 | ein | 2 | 137 | ✓ |
| 9 | `g9_kr_klp_3403_…` | Kath. Religionslehre | Sek I | `à`+3/+4/+5 · `\x83`+3 | ein | 2 | 166 | ✓ |
| 10 | `g9_ku_klp_3405_…` | Kunst | Sek I | `à`+3 · `\x83`+3 | ein | 2 | 99 | ✓ |
| 11 | `g9_l_klp_3402_…` | Latein | Sek I | `à`+3/+4 · `\x83`+3 | ein | 2 | 94 | ? |
| 12 | `g9_m_klp_3401_…` | Mathematik | Sek I | **`(n)`** | ein | 2 | 181 | ? |
| 13 | `g9_mu_klp_3406_…` | Musik | Sek I | `à`+3 · `\x83`+3/+4 | ? | ? | 126 | **?** |
| 14 | `g9_ph_klp_3411_…` | Physik | Sek I | `à`+3 · Tabelle | ein | 2 | 178 | ✓ |
| 15 | `g9_s_klp_3416_…` | Spanisch | Sek I | `à`+4/+3/+1 · `•`+3 | **zwei** | **3** | 144 | ? |
| 16 | `g9_sp_klp_3426_…` | Sport | Sek I | `à`+4/+3 | ein | 2 | **120** | ✓ |
| 17 | `g9_wipo_klp_3429_…` | Wirtschaft-Politik | Sek I | `à`+3/+4/+5 · `\x83`+3 | ein | 2 | 148 | ✓ |
| 18 | `g9_wpif_klp_2023_…` | Informatik (WP) | Sek I | `•`+3 | ein | 2 | 54 | ✓ |
| 19 | `g9_wpwi_klp_34231_…` | Wirtschaft (WP) | Sek I | **`U+F0FA`**+3 · `U+F0A7`+3 | ein | 2 | 68 | ? |
| 20 | `si_kl5u6_if_klp_…` | Informatik | Kl. 5/6 | `•`+4/+3 | ein | 2 | 59 | ✓ |
| 21 | `klp_si_pp_2024_…` | Prakt. Philosophie | Sek I | **`U+F0FA`**+3 · **`U+F0A7`**+3 | ein | 2 | 172 | ✓ |
| 22 | `gost_klp_bi_…` | Biologie | GOSt | **`U+25CF`**+1 · Tabelle | ein | ? | 104 + 101 | ? |
| 23 | `gost_klp_ch_…` | Chemie | GOSt | `•`+3 · Tabelle | ein | ? | 145 + 72 | ? |
| 24 | `gost_klp_d_…` | Deutsch | GOSt | `•`+3 | ein | 2 | **197** | ✓ |
| 25 | `gost_klp_e_…` | Englisch | GOSt | `U+F0FA`+1/+3 | **zwei** | ? | 160 | ? |
| 26 | `gost_klp_f_…` | Französisch | GOSt | `U+F0FA`+3 · `•`+3 | **zwei** | ? | 323 | ? |
| 27 | `gost_klp_ge_…` | Geschichte | GOSt | `•`+3 · `•`+1 | ein | ? | 151 / 211 | **?** |
| 28 | `gost_klp_geo_…` | Geographie | GOSt | `•`+3 | ein | ? | 231 | ? |
| 29 | `gost_klp_if_…` | Informatik | GOSt | `•`+3/+4 | ein | ? | 154 | ? |
| 30 | `gost_klp_ku_…` | Kunst | GOSt | `•`+3 | ein | ? | 205 | ? |
| 31 | `gost_klp_m_…` | Mathematik | GOSt | **`(n)`** | ein | ? | 133 / 197 | **?** |
| 32 | `gost_klp_mu_…` | Musik | GOSt | `•`+1 | ein | ? | 163 | ? |
| 33 | `gost_klp_ph_…` | Physik | GOSt | `•`+3 · Tabelle | ein | ? | 190 + 72 | ? |
| 34 | `gost_klp_pl_…` | Philosophie | GOSt | `•`+3 | ein | ? | 168 | ? |
| 35 | `gost_klp_s_…` | Spanisch | GOSt | `U+F0FA`+3 · `•`+3 | **zwei** | ? | 278 | ? |
| 36 | `gost_klp_sp_…` | Sport | GOSt | **`−`**+1 | ein | ? | 234 | **?** |
| 37 | `gost_klp_sw_…` | Sozialwiss./Wirtschaft | GOSt | `•`+3 | ein | ? | 596 / 435 | **?** |

Die vier fett gesetzten Zahlen sind gegen die Datenbank belegt: Deutsch Sek I
226, Deutsch GOSt 197, Sport Sek I 120 — und die Bereichszahlen 28, 30, 54.

---

## Alle Marker im Bestand

| Codepoint | Zeichen | Bedeutung | kommt vor in |
|---|---|---|---|
| U+00E0 | `à` | Kompetenzerwartung | 13 Plänen (Sek I 2019) |
| U+2022 | `•` | Kompetenzerwartung **oder** inhaltlicher Schwerpunkt — der **Abstand** entscheidet | 15 Plänen |
| U+0083 | `\x83` | Kompetenzerwartung, übergeordnet | 10 Plänen (Sek I 2019) |
| U+F0FA | — | Kompetenzerwartung (Private Use Area) | 5 Plänen |
| U+F0A7 | — | Kompetenzerwartung, zweite Sorte (Private Use Area) | 2 Plänen |
| U+25CF | `●` | Kompetenzerwartung | 1 Plan (Biologie GOSt) |
| U+2212 | `−` | Konkretisierung/Schwerpunkt — **außer Sport GOSt**, dort Erwartung | 12 Plänen |
| U+2013 | `–` | inhaltlicher Schwerpunkt / Kern — nie Erwartung | 23 Plänen |
| `(1)` `(2)` … | — | Kompetenzerwartung, durchnummeriert | 2 Plänen (Mathematik) |
| — | Tabellenzeile mit Code (`UF1`, `E1`, `S1`, `K1`, `B1`) | Kompetenzerwartung, übergeordnet, **ohne Marker** | 5 Plänen (NaWi) |

**Dasselbe Zeichen bedeutet nicht überall dasselbe.** `•` markiert bei Deutsch
GOSt mit Abstand 3 eine Erwartung und mit Abstand 1 einen Schwerpunkt; `−` ist
in elf Plänen ein Konkretisierungszeichen und in Sport GOSt der einzige
Erwartungsmarker. Der Marker ist deshalb je Plan neu zu bestimmen und niemals
aus einem anderen Plan zu übernehmen.

---

## Steuerzeichen

| Codepoint | Vorkommen | Bedeutung |
|---|---|---|
| U+000C | **alle 37**, 22–78× | Seitenumbruch. Steht mehrfach unmittelbar **vor** einem Aufzählungsmarker und bricht dort jeden Ausdruck der Form `^ *X`. Muss vor jeder Auswertung getilgt werden. |
| U+0003 | 17 Pläne (Sek I 2019), 13–26× | Ersetzt vereinzelt ein Leerzeichen mitten im Satz. In Python kein `\s`. Wird zu einem Leerzeichen (E25). |
| U+0083 | 10 Pläne | **Kein zu tilgendes Steuerzeichen, sondern ein Aufzählungsmarker.** C1, nicht C0 — die Bereinigung nach E25 lässt ihn deshalb stehen. Eine Ausweitung auf C1 löscht bei Deutsch Sek I 42 von 226 Erwartungen spurlos. |

Keine der 37 Dateien enthält einen Soft Hyphen (U+00AD) oder ein geschütztes
Leerzeichen (U+00A0).

---

## Zweispaltige Pläne

Fünf Pläne setzen den Kompetenzteil zweispaltig — links die Erwartungen,
rechts die fachlichen Konkretisierungen. Gemessen als Anteil der
Fließtextzeilen, die rechts von x≈260 pt beginnen, **auf den Seiten mit
Kompetenzmarkern**:

| Plan | Anteil | rechts steht | Spaltengrenze |
|---|---|---|---|
| Spanisch Sek I | 27 % | Fachliche Konkretisierungen (`−`) | x ≈ 300 pt |
| Englisch GOSt | 28 % | Fachliche Konkretisierungen (`−`) | x ≈ 300 pt |
| Englisch Sek I | 23 % | Fachliche Konkretisierungen (`−`) | x ≈ 300 pt |
| Französisch Sek I | 18 % | Fachliche Konkretisierungen (`−`) | x ≈ 300 pt |
| Französisch GOSt | 17 % | Fachliche Konkretisierungen (`−`) | x ≈ 300 pt |
| Spanisch GOSt | 18 % | Fachliche Konkretisierungen (`−`) | x ≈ 300 pt |

**`pdftotext -layout` zieht beide Spalten in dieselbe Textzeile:**

```
à    Personen, Sachen, Sachverhalte, Tä- − nouns: singular vs. plural, s-genitive,
     tigkeiten und Geschehnisse bezeich-    of-construction
```

Wer das übersieht, liest den Anfang einer Konkretisierung als Teil einer
Erwartung. Bei den sechs Sprachplänen ist die Extraktion deshalb anders
anzusetzen als bei den übrigen 31.

**Zwei Pläne sind nur außerhalb des Kompetenzteils zweispaltig** und dürfen
nicht als zweispaltig geführt werden: Sport Sek I (Seiten 18–19, Kapitel 2.3
mit der Übersicht der Bewegungsfelder) und Kunst Sek I (6 %). Deshalb wird die
Spaltigkeit auf die Seiten mit Kompetenzmarkern bezogen, nicht auf das
Dokument.

---

## Pläne mit Tiefe 3

Drei Pläne — alle drei modernen Fremdsprachen der Sekundarstufe I:

**Englisch Sek I**, größte gefundene Tiefe, vollständiger Pfad im Wortlaut:

```
2.3.1 Erste Stufe                                    (Phase)
  › FUNKTIONALE KOMMUNIKATIVE KOMPETENZ              (Kompetenzbereich)
    › VERFÜGEN ÜBER SPRACHLICHE MITTEL               (Teilbereich)
      › Grammatik                                    (Unterbereich)
        → 9 Kompetenzerwartungen
```

Fundstelle: `g9_e_klp_3417_2019_06_23.pdf`, Zeile 949 im Text von
`pdftotext -layout`.

**Die Tiefe schwankt innerhalb desselben Plans.** Bei Englisch führen nur zwei
der fünf Kompetenzbereiche eine dritte Ebene:

| Kompetenzbereich | dritte Ebene | Tiefe |
|---|---|---|
| Funktionale kommunikative Kompetenz | Wortschatz, Grammatik, Aussprache und Intonation, Orthografie (nur unter „Verfügen über sprachliche Mittel") | 3 |
| Interkulturelle kommunikative Kompetenz | Soziokulturelles Orientierungswissen | 3 |
| Text- und Medienkompetenz | — | 1 |
| Sprachlernkompetenz | — | 1 |
| Sprachbewusstheit | — | 1 |

**Französisch Sek I** und **Spanisch Sek I** führen dieselben Überschriften in
derselben Anordnung; Französisch ist gelesen und bestätigt, Spanisch nur an den
Überschriften abgeglichen und deshalb als unsicher geführt.

Ob die drei Fremdsprachen der **GOSt** ebenfalls Tiefe 3 haben, ist offen —
ihre Marker (`U+F0FA`) und ihre Spaltigkeit stimmen mit den Sek-I-Plänen
überein, die Gliederung ist aber nicht gelesen.

---

## Unsichere Pläne

Ein als unsicher gekennzeichneter Plan ist ein brauchbares Ergebnis; ein falsch
als sicher ausgewiesener nicht. Bei diesen Plänen liegt entweder die Gliederung
nicht eindeutig vor, oder die beiden Zählwege gehen auseinander.

### Musik Sek I — Gliederung nicht lesbar

Beide Lesarten:

* **(A)** Tiefe 2 wie die übrigen Sek-I-Pläne: Phase › Inhaltsfeld ›
  Kompetenzbereich.
* **(B)** Der Kompetenzteil ist in Wahrheit eine Tabelle, und was wie eine
  Gliederungsebene aussieht (`Rhythmik`, `Melodik`, `Harmonik`, `Tempo`), steht
  in einer rechten Spalte und gehört zu den Ordnungssystemen musikalischer
  Strukturen.

Für (B) spricht, dass im extrahierten Text Fragmente wie
`formulieren Analyseergebnisse unter Verwendung Harmonik` stehen — ein
Zeilenende, das aus zwei Spalten zusammengesetzt ist. Gegen (B) spricht, dass
die Koordinatenmessung auf den Seiten 18–30 **keine** Zeile rechts von x = 240
findet. Die beiden Befunde widersprechen sich; welcher trägt, ist ohne ein
Ansehen der Seiten nicht zu entscheiden.
Zählwege: 126 gegen 114.

### Mathematik Sek I und GOSt — anderer Marker, Zählung offen

Beide Mathematikpläne nummerieren die Erwartungen durch: `(1)`, `(2)`, `(3)` …
statt ein Aufzählungszeichen zu setzen. Die Nummerierung läuft fortlaufend über
die Teilbereiche eines Kompetenzbereichs.

Gelesen ist die Gliederung von Mathematik Sek I:

```
2.2 Prozessbezogene Kompetenzerwartungen bis zum Ende der Sekundarstufe I
  › Operieren                                   (Kompetenzbereich)
    › Hilfsmittelfreies Operieren               (Teilbereich)     → (1)–(8)
    › Arbeiten mit Medien und Werkzeugen        (Teilbereich)     → (9)–(13)
```

Mathematik führt damit **zwei Achsen**: prozessbezogene Erwartungen (Kapitel
2.2) und inhaltsfeldbezogene (Kapitel 2.3/2.4). Das ist genau die Anordnung,
die E11 für Sport angenommen und E18 dort widerlegt hat — bei Mathematik trifft
sie zu.

Unsicher ist die **Zahl**: Der Marker `(` steht auch in Literaturverweisen und
Klammerzusätzen. Zählwege: 181 gegen 179 (Sek I), 133 gegen 197 (GOSt). Die
Zählung braucht einen Ausdruck, der `(n)` am Zeilenanfang von `(vgl. …)` im
Satz trennt.

### Sport GOSt — Erwartung und Schwerpunkt tragen dasselbe Zeichen

Der einzige Plan, in dem `−` (U+2212) die Kompetenzerwartungen markiert. In
elf anderen Plänen ist dasselbe Zeichen der Marker für Konkretisierungen. Hier
tragen **beide** dieses Zeichen:

```
Inhaltlicher Schwerpunkt:
− Trainingsplanung und -organisation: Belastungskomponenten; …

Sachkompetenz
Die Schülerinnen und Schüler
− erläutern allgemeine Gesetzmäßigkeiten von Ausdauertraining …
```

Am Marker sind sie nicht unterscheidbar, nur am Vorspann. Der markerbasierte
Zählweg liefert deshalb 0, der vorspannbasierte 234. Die Extraktion muss hier
über den Vorspann laufen; ohne diesen Befund hätte ein Erzeuger entweder
nichts oder alles gefunden.

### Geschichte GOSt und Sozialwissenschaften GOSt — Zählwege weit auseinander

* Geschichte: `•`+3 ergibt 151, `•`+1 weitere 60; der vorspannbasierte Weg
  zählt 211. Ob die 60 Einträge mit Abstand 1 Erwartungen oder Schwerpunkte
  sind, ist nicht entschieden.
* Sozialwissenschaften: 596 gegen 435. Der Plan ist mit 68 Seiten der
  umfangreichste; er führt Sozialwissenschaften **und** Wirtschaft und hat
  dadurch vermutlich mehr Phasen als die übrigen.

### Weitere unsichere Pläne

| Plan | offene Frage |
|---|---|
| Latein Sek I | Die Inhaltsfelder tragen inhaltliche Schwerpunkte, unter denen unmittelbar Erwartungen stehen — ob der Schwerpunkt eine Gliederungsebene ist oder nur eine Aufzählung, ist nicht entschieden. Zählwege 94/94. |
| Spanisch Sek I | Struktur nur an den Überschriften mit Englisch abgeglichen, nicht gelesen. Zählwege 144/86 (zweispaltig). |
| Wirtschaft (WP) | Zwei PUA-Marker, `U+F0FA` (42) und `U+F0A7` (26). Ob beide Erwartungen markieren oder einer die Schwerpunkte, ist nicht entschieden. In E13 ohnehin als „Lehrplan liegt nicht vor" geführt — er liegt vor, ist aber nicht ausgewertet. |
| alle GOSt außer Deutsch | Marker, Spaltigkeit, Steuerzeichen und Zählwerte sind erhoben; die Gliederung ist **nicht gelesen**. Die Kapitelstruktur (`2.x` Einführungsphase, `2.3.1` Grundkurs, `2.3.2` Leistungskurs) stimmt bei allen mit Deutsch GOSt überein, die Ebenen darunter sind offen. |

---

## Was die Erhebung an Fallen zutage gefördert hat

Fünf Punkte, die in jeden künftigen Fachauftrag gehören:

1. **`\x0c` vor dem Marker.** Dreimal belegt (Sport, Deutsch Sek I, Englisch).
   Tilgen, bevor irgendein Ausdruck greift.
2. **Der Abstand hinter dem Marker entscheidet mit.** Ohne ihn ergab Deutsch
   GOSt 244 statt 197.
3. **Ein Plan kann mehrere Marker führen** — mit gleicher Bedeutung (Sport:
   `à`+3 und `à`+4) oder mit verschiedener (Deutsch Sek I: `\x83` übergeordnet,
   `à` konkretisiert; Englisch: `à` und `•` für dasselbe).
4. **Spaltigkeit ist eine Eigenschaft von Seiten, nicht von Dokumenten.**
5. **Übergeordnete Erwartungen können ganz ohne Marker auskommen** — bei den
   fünf naturwissenschaftlichen Plänen stehen sie in einer Tabelle, erkennbar
   nur am Code in der linken Spalte (`UF1`, `E1`, `K1`, `B1`, `S1`).

Und zwei Fehler, die nur durch eine Zahl auffielen, nicht durch Hinsehen: die
sieben `•`-Erwartungen bei Englisch, und ein Ausdruck `t[:1] in marker`, der
jede **Leerzeile** als Erwartung zählte, weil der leere String in jedem String
enthalten ist.

---

## Was diese Erhebung nicht leistet

* **Keine Empfehlung zum Datenmodell.** Die Tabelle ist die Grundlage dafür.
* **Keine gelesene Gliederung für 16 der 37 Pläne.** Sie sind als unsicher
  gekennzeichnet, mit der jeweils offenen Frage.
* **Keine Prüfung der Inhalte.** Ob die Erwartungen wörtlich übernommen werden
  können, entscheidet sich erst beim Import, im Wortlautvergleich.
* **Die vier gegen die Datenbank belegten Zahlen** (Deutsch Sek I, Deutsch
  GOSt, Sport Sek I) stützen das Verfahren, nicht die 33 übrigen Zeilen. Für
  einen Plan ohne Vorgänger gibt es keinen solchen Vergleich — das ist der
  Normalfall, nicht die Ausnahme.
