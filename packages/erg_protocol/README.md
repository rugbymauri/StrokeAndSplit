# erg_protocol

Reines Dart-Package ohne Flutter- und BLE-Abhängigkeit: übersetzt die Bluetooth-Rohdaten von Rudergeräten in Rudermesswerte und Ereignisse und erzeugt umgekehrt Pakete für den Simulator. Es kennt zwei Protokolle (`ErgProtocol`): den Concept2 PM5 und den Bluetooth-Standard FTMS. `ErgDecoder.forProtocol` liefert den passenden Decoder, beide erzeugen Ereignisse derselben Form und Bedeutung.

```
dart test
```

## Byte-Layouts PM5

Grundlage ist die *Concept2 PM5 Bluetooth Smart Interface Definition*, gegengeprüft mit den Aufnahmen in `test/fixtures/` (PM5 430000001, RowErg, Just Row, Sample Rate 250 ms). Alle Werte sind Little-Endian und vorzeichenlos. Die Paketlängen waren in allen Aufnahmen konstant, ausser bei der Kraftkurve `0x003D`.

UUID-Schema: `CE06xxxx-43E5-11E4-916C-0800200C9A66`, Rowing-Service `0x0030`.

### `0x0031` General Status (19 Bytes)

| Bytes | Feld | Einheit |
|---|---|---|
| 0–2 | Elapsed Time | 0.01 s |
| 3–5 | Distanz | 0.1 m |
| 6 | Workout-Typ | Enum (1 = Just Row mit Splits) |
| 7 | Intervall-Typ | Enum |
| 8 | Workout-Zustand | Enum (0 = WaitToBegin, 1 = WorkoutRow, 11 = Terminate) |
| 9 | Ruderzustand | 0 = inaktiv, 1 = aktiv |
| 10 | Schlagzustand | 0–4 (2 = Durchzug, 4 = Erholung) |
| 11–13 | Total Work Distance | 0.1 m |
| 14–16 | Workout Duration | 0.01 s bzw. m, je nach Byte 17 |
| 17 | Workout Duration Type | 0x80 bei Just Row |
| 18 | Drag Factor | – |

### `0x0032` Additional Status (17 Bytes)

| Bytes | Feld | Einheit |
|---|---|---|
| 0–2 | Elapsed Time | 0.01 s |
| 3–4 | Geschwindigkeit | 0.001 m/s |
| 5 | Schlagzahl | 1/min |
| 6 | Herzfrequenz | 1/min, **255 = kein Gurt** |
| 7–8 | Aktuelle Pace | 0.01 s / 500 m |
| 9–10 | Durchschnittspace | 0.01 s / 500 m |
| 11–12 | Rest Distance | m |
| 13–15 | Rest Time | 0.01 s |
| 16 | Erg-Typ | siehe [Erg-Typ](#erg-typ-des-pm5), 0 = RowErg (Modell D) |

### `0x0033` Additional Status 2 (20 Bytes)

| Bytes | Feld | Einheit |
|---|---|---|
| 0–2 | Elapsed Time | 0.01 s |
| 3 | Intervall-Zähler | – |
| 4–5 | Durchschnittsleistung | W |
| 6–7 | Kalorien total | kcal |
| 8–9 | Split-Durchschnittspace | 0.01 s / 500 m |
| 10–11 | Split-Durchschnittsleistung | W |
| 12–13 | Split-Durchschnittskalorien | kcal/h |
| 14–16 | Letzte Split-Zeit | 0.1 s |
| 17–19 | Letzte Split-Distanz | m |

### `0x0035` Stroke Data (20 Bytes)

| Bytes | Feld | Einheit |
|---|---|---|
| 0–2 | Elapsed Time | 0.01 s |
| 3–5 | Distanz | 0.1 m |
| 6 | Durchzugslänge | 0.01 m |
| 7 | Durchzugszeit | 0.01 s |
| 8–9 | Erholungszeit | 0.01 s |
| 10–11 | Schlagdistanz | 0.01 m |
| 12–13 | Spitzenkraft | 0.1 lbf |
| 14–15 | Durchschnittskraft | 0.1 lbf |
| 16–17 | Arbeit pro Schlag | 0.1 J |
| 18–19 | Schlagnummer | – |

Kräfte kommen in Pound-force, 1 lbf = 4.44822 N.

### `0x0036` Additional Stroke Data (15 Bytes)

| Bytes | Feld | Einheit |
|---|---|---|
| 0–2 | Elapsed Time | 0.01 s |
| 3–4 | Schlagleistung | W |
| 5–6 | Kalorienrate | kcal/h |
| 7–8 | Schlagnummer | – |
| 9–11 | Projected Work Time | 0.01 s |
| 12–14 | Projected Work Distance | m |

### `0x003D` Force Curve (4–20 Bytes)

Gemessen am 2026-10-16 (Fixture `force_curve.jsonl`). Die Kurve eines Schlags kommt direkt nach dem Durchzug in mehreren Paketen, unmittelbar nach dem ersten `0x0035` und `0x0036` dieses Schlags; sie gehört zur Schlagnummer dieses `0x0035`.

| Bytes | Feld | Einheit |
|---|---|---|
| 0, Bits 4–7 | Zahl der Pakete der Kurve | – |
| 0, Bits 0–3 | Zahl der Kraftwerte in diesem Paket (1–9) | – |
| 1 | Zähler, 0 bis Paketzahl − 1, pro Schlag neu ab 0 | – |
| 2 … | Kraftwerte, je 2 Bytes | lbf (ganze) |

- Alle Pakete ausser dem letzten tragen 9 Werte, die Länge ist 2 + 2 × Werteanzahl.
- 4–8 Pakete, 34–68 Werte pro Schlag, etwa 62 Werte pro Sekunde Durchzug.
- Das Maximum der Kurve ist die Spitzenkraft aus `0x0035` ganzzahlig abgeschnitten (`0x0035` liefert 0.1 lbf, die Kurve ganze lbf).
- Die Schläge 0 und 1 nach dem Start liefern keine Kurve.

Beispiel, erstes und letztes Paket eines Schlags mit 7 Paketen: `79 00 06 00 06 00 06 00 13 00 …` (7 Pakete, 9 Werte, Zähler 0, 6 lbf, 6 lbf, …) und `76 06 13 00 04 00 04 00 03 00 00 00 00 00` (6 Werte, Zähler 6).

## Erg-Typ des PM5

Byte 16 von `0x0032` meldet, an welchem Erg der PM5 sitzt (`ERGMACHINE_TYPE` der Concept2-Spezifikation). Die App weist SkiErg und BikeErg nach dem Verbinden ab (`Pm5ErgType`). Unbekannte Werte werden zugelassen, damit neue RowErg-Varianten nicht blockiert werden.

| Werte | Gerät | Folge |
|---|---|---|
| 0, 1, 2, 3, 5, 7, 8 | RowErg (Modelle D, C, A, B, E, Simulator, Dynamic) | zugelassen |
| 16–20 | RowErg auf Slides | zugelassen |
| 32, 64 | Linked Dynamic, Dyno | zugelassen |
| 224 | Multi-Erg als Rudergerät | zugelassen |
| 128, 143, 225 | SkiErg (Static, Simulator, Multi-Erg) | abgewiesen |
| 192, 193, 194, 207, 226 | BikeErg (mit/ohne Arme, Simulator, Multi-Erg) | abgewiesen |
| alle anderen | unbekannt | zugelassen |

Am echten Gerät bestätigt ist nur der Wert 0 (RowErg Modell D, alle Fixtures). Die übrigen Werte stammen aus der Spezifikation und sind nicht gemessen.

## Byte-Layouts FTMS

Grundlage ist die *Fitness Machine Service 1.0* der Bluetooth SIG. Alle Werte sind Little-Endian. Gemessen an echter FTMS-Hardware ist noch nichts, getestet wird gegen die Spezifikation und den Software-Rower unter `tool/ftms_rower/`.

| UUID | Inhalt | Verwendung |
|---|---|---|
| `0x1826` Service | Fitness Machine; Service Data im Advertisement mit Flags-Byte und Fitness Machine Type, Bit 4 = Rower | Suche |
| `0x2ACC` | Fitness Machine Feature | nicht ausgewertet |
| `0x2AD1` | Rower Data (Notify) | Messwerte |
| `0x2AD9` | Fitness Machine Control Point (Write + Indicate) | Steuerung anfordern, Start |
| `0x2ADA` | Fitness Machine Status (Notify) | nur mitgeschnitten |

### `0x2AD1` Rower Data

Zuerst ein u16 mit Flags, danach nur die Felder, deren Flag gesetzt ist, in dieser Reihenfolge:

| Flag-Bit | Feld | Typ, Einheit |
|---|---|---|
| 0 = **0** | Stroke Rate, Stroke Count | u8 0.5/min, u16 |
| 1 | Average Stroke Rate | u8 0.5/min |
| 2 | Total Distance | u24 m |
| 3 | Instantaneous Pace | u16 s/500 m |
| 4 | Average Pace | u16 s/500 m |
| 5 | Instantaneous Power | s16 W |
| 6 | Average Power | s16 W |
| 7 | Resistance Level | s16 |
| 8 | Total Energy, Energy/h, Energy/min | u16 kcal, u16 kcal, u8 kcal; `0xFFFF` bzw. `0xFF` = kein Wert |
| 9 | Heart Rate | u8 1/min |
| 10 | Metabolic Equivalent | u8 0.1 |
| 11 | Elapsed Time | u16 s |
| 12 | Remaining Time | u16 s |

Bit 0 ist invertiert („More Data“): Ist es gesetzt, fehlen Stroke Rate und Count, und weitere Teile desselben Datensatzes folgen. Der Decoder merkt sich den letzten Wert jedes Felds und erzeugt am Ende jedes Datensatzes (Bit 0 = 0) einen `StatusTick`. Ein Paket, das kürzer ist, als seine Flags ankündigen, wird verworfen und gemeldet.

### `0x2AD9` Control Point

Nach dem Verbinden: Indicate aktivieren, `0x00` (Request Control) schreiben und bis zu 2 s auf die Antwort `0x80 0x00 0x01` warten. Bei Erfolg folgt `0x07` (Start or Resume). Ablehnung, Fehler oder Timeout werden ignoriert. `0x01` (Reset) und `0x08` (Stop or Pause) sendet die App nie, auch nicht beim Trennen.

### Eigene Uhr und Rudern-Erkennung

- **Zeit:** Der Decoder summiert die Abstände der Empfangszeiten (`RawPacket.time`) zwischen zwei Datensätzen, aber nur, solange gerudert wird. Die Gerätezeit (Bit 11) wird gelesen, aber nicht verwendet. So bleibt die Zeit bei 1-s-Takt flüssig, steht in Pausen still wie am PM5, und ein Replay liefert exakt dieselben Werte.
- **Rudert:** solange Distanz oder Schlagzähler in den letzten 4 s gestiegen sind. Die Schlagzahl allein zählt nicht, weil viele Geräte sie nach dem Aufhören weiter melden.
- **Schläge:** Steigt der Zähler von n auf m, entsteht je ein `Stroke` für n+1 bis m, ohne Durchzugs- und Kraftwerte. Bei mehr als 10 Schlägen Sprung (z.B. Verbinden mitten im Rudern) wird nur der Zählerstand übernommen.
- **Reset:** Fällt Distanz oder Schlagzähler zurück, meldet der Decoder `WorkoutStateChanged(isReset: true)` und beginnt die eigene Uhr bei 0, wie der PM5 bei einem neuen Workout. Die Session zählt über `SessionOffset` weiter.
- **Workout:** Typ und Zustand sind immer `unknown`.

### Plausibilitätsgrenzen

| Wert | gilt als „nicht vorhanden“ |
|---|---|
| Pace | 0, ausserhalb von 1:00 bis 10:00 pro 500 m oder während nicht gerudert wird |
| Watt | immer aus der Pace mit `wattsForPace` berechnet, die Geräteleistung (Bit 5) wird ignoriert |
| Schlagzahl | ausserhalb von 1 bis 60 pro Minute |
| Herzfrequenz | 0 oder über 250 |
| Kalorien | Platzhalter `0xFFFF` |

## Beobachtungen aus den PM5-Aufnahmen

- **`0x0035` kommt zweimal pro Schlag.** Das erste Paket kommt am Ende des Durchzugs mit neuer Schlagnummer, aber noch der Erholungszeit des *vorigen* Schlags. Das zweite kommt am Ende der Erholung mit derselben Schlagnummer und der aktuellen Erholungszeit. `0x0036` kommt nur einmal pro Schlag, zusammen mit dem ersten `0x0035`. Ein Schlag ist also erst mit dem zweiten `0x0035` vollständig.
- **Pause im Just Row (`pause.jsonl`):** Hört man auf zu rudern, **bleiben Elapsed Time und Distanz stehen**. Der Workout-Zustand bleibt 1 (WorkoutRow), nur der Ruderzustand fällt auf 0. Nach ca. 80 s Pause zählte der PM5 einfach weiter, ohne Reset und ohne Workout-Ende. Für zeitbasierte Strecken mit Pausen braucht die App deshalb eine eigene Uhr.
- **Neues Workout am PM5 (`reset.jsonl`):** Der Workout-Zustand läuft 1 → 11 (Terminate) → 0 (WaitToBegin), danach fallen Zeit und Distanz auf 0, und mit dem ersten Schlag wird der Zustand wieder 1.
- **Startwerte:** Wird während eines laufenden Just Row verbunden, beginnen Zeit und Distanz beim aktuellen PM5-Stand, nicht bei 0.
- **Sample Rate:** Der Schreibzugriff auf `0x0034` mit Wert 2 ergibt wie dokumentiert ein Paket pro 250 ms auf `0x0031`–`0x0033`.

## Plattformen

- **Linux (BlueZ), Fedora 44:** Verbinden, Sample Rate setzen und alle fünf Notifications funktionieren mit `flutter_blue_plus` 2.x. Allerdings meldet der Scan nur Geräte, die BlueZ *neu* entdeckt. Ein PM5, der schon im BlueZ-Cache ist, erscheint nur über `FlutterBluePlus.systemDevices`. Ausserdem ignoriert das Linux-Backend Namensfilter beim Scan, deshalb filtert die App selbst nach `PM5`.
- **Android:** am PM5 verifiziert (Pixel 8 Pro, Android 17), gleiches Verhalten wie unter Linux: Status-Pakete alle 250 ms, `0035` zweimal pro Schlag.

## Fixtures

`test/fixtures/*.jsonl`: Zeile 1 enthält die Metadaten, danach folgt pro Zeile ein Paket `{"t": ms, "c": "0031", "b": base64}` oder ein Marker `{"t": ms, "m": "Text"}`.

| Datei | Inhalt |
|---|---|
| `just_row.jsonl` | ca. 2 min Just Row, ca. 44 Schläge |
| `pause.jsonl` | Rudern, ca. 80 s Pause, weiterrudern |
| `reset.jsonl` | mehrere neue Workouts am PM5 während des Ruderns |
| `force_curve.jsonl` | ca. 55 s Just Row mit Kraftkurve `003d`, Schläge 0–18, 17 Kurven mit Spitzenkräften von 34 bis 149 lbf, Ausschnitt aus dem Mitschnitt vom 2026-10-16 |
| `ftms_just_row.jsonl` | `just_row.jsonl` als FTMS-Rower: ein Rower-Data-Datensatz pro Sekunde, erzeugt mit `dart run erg_protocol:pm5_to_ftms test/fixtures/just_row.jsonl test/fixtures/ftms_just_row.jsonl` |

`pm5_to_ftms` liest `.jsonl` und `.aergrow` und übernimmt Schlagzähler, Distanz, Pace, Leistung, Energie und Zeit des PM5. Die Fixture ist keine Aufnahme eines echten FTMS-Geräts; die bleibt für den Spike offen.
