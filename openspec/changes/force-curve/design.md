# Design

## Context

Das Verhalten steht in den Specs. Die Gestaltung stammt aus dem Claude-Design-Canvas **AergRow Frontend** (privat, Freigabe über das Share-Menü). Die Kurve erscheint dort an vier Stellen:

| Screen im Canvas | Platz der Kurve |
|---|---|
| Live: freies Rudern | eigene Karte unter den Nebenwerten, Höhe etwa 96 px |
| Live: Vorlage mit Zonen | schmaler Streifen „Kraft“ unter den Kacheln, etwa 44 px |
| Live quer: freies Rudern | unter der Pace in derselben Karte |
| Live quer: Vorlage mit Zonen | in der Schlagzahl-Karte unter der Schlagzahl |
| Zustände: Kraftkurve & Puls | Zustände „Live“, „Warte auf ersten Schlag“ und „Gerät liefert keine Kraftkurve“ |

Dieser Change setzt auf `ui-design` auf, das die Flächen dafür baut.

## Decisions

### D1: Daten vom PM5

Der PM5 sendet die Kurve eines Schlags direkt nach dessen Durchzug in mehreren Notifications der Characteristic `0x003D`. Jedes Paket trägt die Zahl der Pakete der Kurve, einen Zähler und bis zu neun Kraftwerte in ganzen Pfund-Kraft. Der Decoder sammelt die Pakete eines Schlags, ordnet die Kurve der Schlagnummer aus dem vorangehenden `0x0035` zu und gibt die vollständige Kurve als ein Ereignis aus. Die Kraftwerte werden mit demselben Faktor wie die bestehenden Kräfte in Newton umgerechnet (1 lbf = 4.44822 N), aber ohne die Division durch 10.

Der Spike-Mitschnitt am echten PM5 hat Characteristic, Paketaufbau, Einheit und die Zahl der Werte pro Schlag bestätigt (siehe unten). Die Erwartung laut Spezifikation war: Characteristic `CE06003D-…` im Rowing-Service `0x0030`, Notify, bis 20 Bytes, Byte 0 im oberen Nibble die Zahl der Pakete, im unteren die Zahl der Kraftwerte im Paket, Byte 1 der Zähler, danach bis zu neun Kraftwerte als u16 Little-Endian in lbf. Das trifft zu; die offene Frage nach der Einheit beantwortet der Mitschnitt mit ganzen lbf.

Zusammensetzen im Decoder (für 1.2):

- Ein Paket mit Zähler 0 beginnt eine neue Kurve; eine noch offene, unvollständige Kurve wird dabei verworfen.
- Die Kurve ist vollständig, wenn die Zähler 0 bis Paketzahl − 1 lückenlos und in Reihenfolge eingetroffen sind und alle Pakete dieselbe Paketzahl im oberen Nibble tragen. Erst dann entsteht das Ereignis.
- Fehlt ein Zähler, passt die Paketzahl nicht, oder kommt das nächste `0x0035` mit neuer Schlagnummer, bevor die Kurve vollständig ist, wird sie verworfen.
- Die Paketlänge ist variabel; ein Paket ist nur gültig, wenn es mindestens 2 + 2 × Werteanzahl Bytes hat.
- Die Schlagnummer stammt aus dem letzten `0x0035` vor der Kurve. Das Schlag-Ereignis mit dieser Nummer gibt der bestehende Decoder erst am Ende der Erholung aus; die Kurve kommt also rund 1.5–2 s **vor** ihrem Schlag-Ereignis und muss die Schlagnummer selbst tragen.

#### Stand des Spikes (2026-10-16)

Neuer Mitschnitt am 2026-10-16 um 22:32 (PM5 430000001, RowErg, Just Row, etwa 70 s, Schläge 0–23 mit Spitzenkräften von 34 bis 149 lbf, also 150–660 N). Der Spike abonnierte `0031`–`0036` und `003d`. Ergebnis: 118 Pakete `003d`, 46 × `0035`, 24 × `0036`, 22 vollständige Kurven (Schläge 2–23), kein verlorenes Paket. Ein Ausschnitt (Schläge 0–18, 17 Kurven) liegt als `packages/erg_protocol/test/fixtures/force_curve.jsonl` vor.

**Paketaufbau** (bestätigt): Byte 0 oberes Nibble = Zahl der Pakete der Kurve, unteres Nibble = Zahl der Kraftwerte in diesem Paket; Byte 1 = Zähler 0 … Paketzahl − 1, beginnt bei jedem Schlag neu bei 0; danach die Werte als u16 Little-Endian. Alle Pakete ausser dem letzten tragen 9 Werte (20 Bytes), das letzte 1–9 Werte, die Paketlänge ist genau 2 + 2 × Werteanzahl (4–20 Bytes). Beispiel Schlag 4 (7 Pakete, 60 Werte):

```
79 00 06 00 06 00 06 00 13 00 13 00 13 00 2a 00 2a 00 42 00   Paket 0, 9 Werte
79 01 42 00 42 00 58 00 58 00 6a 00 6a 00 71 00 71 00 76 00   Paket 1
…
76 06 13 00 04 00 04 00 03 00 00 00 00 00                     Paket 6, 6 Werte
```

Abweichend von der Erwartung „bis 20 Bytes, fest“ ist nur, dass das letzte Paket kürzer ist; ein Paket mit einem einzigen Wert (`61 05 00 00`, 4 Bytes) kam vor.

**Einheit** (bestätigt: ganze lbf): Das Maximum jeder der 22 Kurven ist genau die Spitzenkraft aus `0x0035` (0.1 lbf) ganzzahlig abgeschnitten, z. B. Maximum `0x7b` = 123 bei Spitzenkraft 1237 (123.7 lbf), 148 bei 148.7, 51 bei 51.0. Das Mittel der Kurve liegt innerhalb von 3 % bei der Durchschnittskraft aus `0x0035`. Umrechnung: Wert × 4.44822 = N.

**Punkte pro Kurve**: 34–68 Werte in 4–8 Paketen, etwa 62 Werte pro Sekunde Durchzugszeit (rund 16 ms Abstand). Die Zahl ändert sich also von Schlag zu Schlag; die Anzeige streckt sie nach D2 auf die Breite. Aufeinanderfolgende Werte wiederholen sich oft paarweise; sie sind unverändert zu übernehmen. Die Kurve beginnt mit einem Wert über 0 (4–28 lbf) und endet meist auf 0, manchmal auf einem kleinen Wert bis 19 lbf. Mit höchstens 15 Paketen zu 9 Werten fasst das Format 135 Werte, gut doppelt so viele wie gemessen.

**Zeitliche Lage** (bestätigt, Kurve um den Wechsel 2 → 4): Am Ende des Durchzugs (`0x0031` wechselt von Schlagzustand 2 auf 3, einmal direkt auf 4) folgen ohne andere Pakete dazwischen das erste `0x0035` (neue Schlagnummer, Kräfte), `0x0036` und alle `003d`-Pakete der Kurve; danach kommt wieder `0x0031`, bald mit Schlagzustand 4. Die Kurvenpakete kommen meist innerhalb von 20 ms nach `0x0035`, zweimal um 110 bzw. 190 ms verzögert, und verteilen sich über 4–80 ms. Das zweite `0x0035` am Ende der Erholung folgt etwa 2 s später ohne Kurve.

**Sonderfälle**:

- Schlag 0 (beim Start, alle Werte 0) und Schlag 1 (Spitzen- und Durchschnittskraft 0) liefern keine Kurve. Die erste Kurve kommt mit Schlag 2; bis dahin bleibt die Karte im Zustand „Warte auf ersten Schlag“.
- Abgeschnittene oder lückenhafte Kurven kamen im Mitschnitt nicht vor. Das Verwerfen nach der Spec wird deshalb mit künstlich entfernten Paketen getestet.
- BLE-Abbrüche oder verlorene Pakete traten trotz der zusätzlichen Notifications nicht auf (siehe Risiken).
- Der bestehende `Pm5Decoder` verwirft `003d` bisher als unbekannte Characteristic mit Warnung; das ändert 1.2.

### D2: Darstellung

- Die x-Achse ist der Index des Werts im Schlag, auf die Breite gestreckt. Die y-Achse reicht von 0 bis zum Maximum der beiden gezeigten Kurven, damit beide vergleichbar bleiben.
- Letzter Schlag: Linie 3 px in `zoneIn`, darunter Fläche in derselben Farbe mit 16 % Deckkraft. Im Querformat mit Vorlage steht die Kurve auf orangem Grund und ist deshalb in `text` gezeichnet.
- Vorheriger Schlag: Linie 2 px in `#5A646E`, ohne Fläche.
- Legende nur in der grossen Karte: „Letzter“ und „Vorheriger“.

### D3: Verfügbarkeit

Die Karte erscheint, sobald die Quelle Kraftkurven unterstützt. PM5 und Simulator tun das, FTMS-Ruderer nicht. Bis zum ersten Schlag zeigt sie eine gestrichelte Grundlinie mit „Warte auf ersten Schlag“.

## Risks / Trade-offs

- **Bandbreite**: Die zusätzlichen Notifications (4–8 pro Schlag) belasten die BLE-Verbindung. Im Mitschnitt vom 2026-10-16 (etwa 70 s) ging kein Paket verloren, das Abonnement bleibt deshalb fest. Zeigen längere Sessions Abbrüche, wird es optional und lässt sich abschalten.
- **Speicher**: Pro Schlag kommen einige hundert Bytes Rohdaten dazu, bei einer Stunde Rudern etwa 0.5 MB.
