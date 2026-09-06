# Kernlehrpläne NRW — Quellenverzeichnis

Die Quelldateien der Kompetenzrahmen. Jeder Seed unter `sql/` nennt in seinem
Kopf die Datei, aus der er erzeugt wurde, samt ihrer SHA256-Summe (E19). Dieses
Verzeichnis führt die Zuordnung an einer Stelle zusammen.

**Dateinamen bleiben unverändert**, wie sie vom Ministerium kommen. Sie tragen
Fach, Heftnummer und Ausgabedatum; ein lesbarerer Name würde die Verbindung zur
Quelle kappen.

Prüfen, ob eine vorliegende Datei dieselbe ist:

```bash
shasum -a 256 docs/curricula/*.pdf
```

Fachbezeichnung und Stufe stammen aus der Titelseite der jeweiligen Datei, nicht
aus dem Dateikürzel — `g9_s_klp` ist Spanisch, `g9_sp_klp` ist Sport.

**Aufbau und Extraktionseigenheiten stehen in [`STRUKTUR.md`](STRUKTUR.md).**
Dort ist je Plan erhoben, welche Aufzählungsmarker die Kompetenzerwartungen
tragen, ob der Kompetenzteil zweispaltig gesetzt ist, wie tief die Gliederung
reicht und welche Steuerzeichen im Text stehen. Wer einen Fachimport vorbereitet,
liest das vor dem Bauen — jedes bisher importierte Fach hat eine Eigenheit
mitgebracht, die niemand vermutet hatte.

⚠ = Inhalt bisher nicht ausgewertet.

Bestand: 37 Dateien, rund 16 MB.

---

## Sekundarstufe I (21)

| Datei | Fach | Stand | SHA256 |
|---|---|---|---|
| `g9_bi_klp_-3413_2019_06_23_0.pdf` | Biologie | 23.06.2019 | `536d51639cab388fc2966540fc9f9538327ea024e9d906a76792cee335b354a5` |
| `g9_ch_klp_3415_2019_06_23.pdf` | Chemie | 23.06.2019 | `e87c474a50de25311aa9875ed14a301deccb8fcb91c6e710adb6c742cf6a9d24` |
| `g9_d_klp_3409_2019_06_23.pdf` | Deutsch | 23.06.2019 | `844fdfe8c875433c2775c899b74a2d83d466a19a4d3cc5d88630d7b7d66cb94c` |
| `g9_e_klp_3417_2019_06_23.pdf` | Englisch | 23.06.2019 | `96a12dca0a6b7d81d75367d1c870aa48013db9bae84671d7add9e7bb55329ead` |
| `g9_ek_klp_3408_2019_06_23.pdf` | Erdkunde | 23.06.2019 | `95d39c55083bf9ee893d5c3ffc3c35a094f2cef41895d9569e72fb31adba8436` |
| `g9_er_klp_3414_2019_06_23.pdf` | Evangelische Religionslehre | 23.06.2019 | `d7fdabab4579415655389474fa13fe8f960d2aa22bf8fbbbb4894add4798c401` |
| `g9_f_klp_3410_2019_06_23.pdf` | Französisch | 23.06.2019 | `dbcaea789b7b7f3a937c14c3b17989ba6a0523e187371638271c7795f1925d57` |
| `g9_ge_klp_3407_2019_06_23.pdf` | Geschichte | 23.06.2019 | `465afdc231e551c2e4edfc28a637cdd057f74f3926647d840680ca756ffd6bac` |
| `si_kl5u6_if_klp_2021_07_01.pdf` | Informatik (Kl. 5/6) | 01.07.2021 | `941bd69cd1be8630b95213b4593b753fbf63777330ef18cb55bfc1f09264df57` |
| `g9_wpif_klp_2023_06_01.pdf` | Informatik (Wahlpflicht) | 01.06.2023 | `de4f229f2342edcbbca34a36809ca01fc09fe69c600d47eee4b82a9f1c2be386` |
| `g9_kr_klp_3403_2019_06_23.pdf` | Katholische Religionslehre | 23.06.2019 | `5fcd8fc99280804bef316b83a301d9626b647a4a05df2c53332bd6d93813b576` |
| `g9_ku_klp_3405_2019_06_23.pdf` | Kunst | 23.06.2019 | `37a569d0f32541548432e86cd90c9758ff685c283b8e7bcecd6aca8d7176dcf8` |
| `g9_l_klp_3402_2019_06_23_0.pdf` | Latein | 23.06.2019 | `0d1209cf798c12abebe17b3586c457455f3127381ada504b31fc670e95a0b1dc` |
| `g9_m_klp_3401_2019_06_23_0.pdf` | Mathematik | 23.06.2019 | `e58c85336c2aa4112923ae3b0c9fb3bdf38adadc1947110d62d9266c7e14f477` |
| `g9_mu_klp_3406_2019_06_23_0.pdf` | Musik | 23.06.2019 | `4f7246c391611d43d345f706414b606ec17448b57d6d25124eae20ba0cea4739` |
| `g9_ph_klp_3411_2019_06_23.pdf` | Physik | 23.06.2019 | `e5f930ef65337b4aeced8e709f64610a211f58efaeea209d5f1c01c0904aeb4a` |
| `klp_si_pp_2024_10_02_0.pdf` | Praktische Philosophie | 02.10.2024 | `777fe87002eddbd8fe39c8ff0e7f1f6e3539b37600314a4f07b5aac2ea202cde` |
| `g9_s_klp_3416_2019_06_23.pdf` | Spanisch | 23.06.2019 | `119d7166a93d0c925fcb42ff4edf54ad37dd2aaf1041f571cb5dc60aed77f6d9` |
| `g9_sp_klp_3426_2019_06_23.pdf` | Sport | 23.06.2019 | `815f985166f45bc136ae3fc28aff4b0214b29b9862aa0eb33df312e32e950351` |
| `g9_wpwi_klp_34231_2022_06_24.pdf` | Wirtschaft (Wahlpflicht) ⚠ | 24.06.2022 | `09de28af41583a0dbbe123c7bda27560fe7b97d357634c5b1b89ff4d1aa66f49` |
| `g9_wipo_klp_3429_2019_06_23.pdf` | Wirtschaft-Politik | 23.06.2019 | `26fb6738e26a3a8484fd3a7236c8ab484baf7f554cb50a5887ab282d90846f02` |

---

## Sekundarstufe II (16)

Verabschiedete Fassungen vom 24.08.2026. Ein früher verwendeter Entwurf vom
31.07.2025 ist überholt und liegt hier nicht (E13).

| Datei | Fach | Stand | SHA256 |
|---|---|---|---|
| `gost_klp_bi_2026_08_24.pdf` | Biologie | 24.08.2026 | `98a5b5ee1fae8a4c419bf5d920d1f830e4ec8c871602e420ec315e67a3111246` |
| `gost_klp_ch_2026_08_24.pdf` | Chemie | 24.08.2026 | `e868a0de15741ab59e1578446cb66254f55707eb991cbd006992880458b10b32` |
| `gost_klp_d_2026_08_24.pdf` | Deutsch | 24.08.2026 | `00694903d6a16447989fd476d9ce91c8e0e7b8cb0e114fa3cfd3ed773d981c29` |
| `gost_klp_e_2026_08_24.pdf` | Englisch | 24.08.2026 | `f8c06ca1ecc429be9eb7cbb58263c70c4e531bd7bac189b89ae70c4a3e953598` |
| `gost_klp_f_2026_08_24.pdf` | Französisch | 24.08.2026 | `58e762570e93013b021ab78627dbfd8df4e7e85c345392bc711e263f11f5cd4b` |
| `gost_klp_geo_2026_08_24.pdf` | Geographie | 24.08.2026 | `793c363f4467f8e28b393cc5542a8142e11ff5fd70cc87a3bd610385026e48f4` |
| `gost_klp_ge_2026_08_24.pdf` | Geschichte | 24.08.2026 | `481171f18171d8460c121a8148d2b1db40636d08d72aa3a99378ac59f3a22b77` |
| `gost_klp_if_2026_08_24.pdf` | Informatik | 24.08.2026 | `41bee53e29007fdf8326be644e65b23dbbed0faa324c4a59eab49d00a5c2d12b` |
| `gost_klp_ku_2026_08_24.pdf` | Kunst | 24.08.2026 | `1006cf18e5a1b64d07ebcf66f25e7d410864ca2276ad751e503309a3265788d0` |
| `gost_klp_m_2026_08_24.pdf` | Mathematik | 24.08.2026 | `e515789eed183730abea51203613197bb93ca639ee4be1d5b3297e1b8f392ae4` |
| `gost_klp_mu_2026_08_24.pdf` | Musik | 24.08.2026 | `dcacc33309e90d427124917953b92b07ad1423e79aeaee86ddc7da9b6423c0d3` |
| `gost_klp_pl_2026_08_24_0.pdf` | Philosophie | 24.08.2026 | `fcc9ed0b92626738195f6284fa460fcec93ca6ce64d70dd3b465c82f65d2cfd6` |
| `gost_klp_ph_2026_08_24.pdf` | Physik | 24.08.2026 | `a752671269b8508b667e20995df08c71097f1c7d4f0717a91035360eb43d127e` |
| `gost_klp_sw_2026_08_24.pdf` | Sozialwissenschaften / Wirtschaft | 24.08.2026 | `46e44e3e6dc8561c51c27d19fc6d807aeea8892803567fa7c3defe8b316cb012` |
| `gost_klp_s_2026_08_24.pdf` | Spanisch | 24.08.2026 | `3c4ab4faef74e2535fbce126fca8827e1f0e196ca4632037f1f14bd5074c4b24` |
| `gost_klp_sp_2026_08_24.pdf` | Sport | 24.08.2026 | `231559e210b2991244fc465162882800dff5eb33012c8f733a5aefab4fdc4fce` |

---

## Nicht enthalten

- **Latein Sekundarstufe II** — wird an der Schule nicht unterrichtet, kein
  Kompetenzrahmen vorgesehen (E13).
- **Medienkompetenzrahmen NRW** — kein Kernlehrplan. Der Rahmen `MKR` in der
  Datenbank stammt aus einer eigenen Vorlage und ist geprüft.
