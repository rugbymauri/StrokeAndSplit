# pm5_protocol

Reines Dart-Package ohne Flutter- und BLE-Abhängigkeit: übersetzt die Bluetooth-Rohdaten eines Concept2 PM5 in Rudermesswerte und Ereignisse und erzeugt umgekehrt PM5-Pakete für den Simulator.

```
dart test
```

## Byte-Layouts

Grundlage ist die *Concept2 PM5 Bluetooth Smart Interface Definition*, gegengeprüft mit den Aufnahmen in `test/fixtures/` (PM5 430000001, RowErg, Just Row, Sample Rate 250 ms). Alle Werte sind Little-Endian und vorzeichenlos. Die Paketlängen waren in allen Aufnahmen konstant.

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
| 16 | Erg-Typ | 0 = RowErg (Modell D) |

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

## Beobachtungen aus den Aufnahmen

- **`0x0035` kommt zweimal pro Schlag.** Das erste Paket kommt am Ende des Durchzugs mit neuer Schlagnummer, aber noch der Erholungszeit des *vorigen* Schlags. Das zweite kommt am Ende der Erholung mit derselben Schlagnummer und der aktuellen Erholungszeit. `0x0036` kommt nur einmal pro Schlag, zusammen mit dem ersten `0x0035`. Ein Schlag ist also erst mit dem zweiten `0x0035` vollständig.
- **Pause im Just Row (`pause.jsonl`):** Hört man auf zu rudern, **bleiben Elapsed Time und Distanz stehen**. Der Workout-Zustand bleibt 1 (WorkoutRow), nur der Ruderzustand fällt auf 0. Nach ca. 80 s Pause zählte der PM5 einfach weiter, ohne Reset und ohne Workout-Ende. Für zeitbasierte Strecken mit Pausen braucht die App deshalb eine eigene Uhr.
- **Neues Workout am PM5 (`reset.jsonl`):** Der Workout-Zustand läuft 1 → 11 (Terminate) → 0 (WaitToBegin), danach fallen Zeit und Distanz auf 0, und mit dem ersten Schlag wird der Zustand wieder 1.
- **Startwerte:** Wird während eines laufenden Just Row verbunden, beginnen Zeit und Distanz beim aktuellen PM5-Stand, nicht bei 0.
- **Sample Rate:** Der Schreibzugriff auf `0x0034` mit Wert 2 ergibt wie dokumentiert ein Paket pro 250 ms auf `0x0031`–`0x0033`.

## Plattformen

- **Linux (BlueZ), Fedora 44:** Verbinden, Sample Rate setzen und alle fünf Notifications funktionieren mit `flutter_blue_plus` 2.x. Allerdings meldet der Scan nur Geräte, die BlueZ *neu* entdeckt. Ein PM5, der schon im BlueZ-Cache ist, erscheint nur über `FlutterBluePlus.systemDevices`. Ausserdem ignoriert das Linux-Backend Namensfilter beim Scan, deshalb filtert die App selbst nach `PM5`.
- **Android:** noch nicht am PM5 getestet.

## Fixtures

`test/fixtures/*.jsonl`: Zeile 1 enthält die Metadaten, danach folgt pro Zeile ein Paket `{"t": ms, "c": "0031", "b": base64}` oder ein Marker `{"t": ms, "m": "Text"}`.

| Datei | Inhalt |
|---|---|
| `just_row.jsonl` | ca. 2 min Just Row, ca. 44 Schläge |
| `pause.jsonl` | Rudern, ca. 80 s Pause, weiterrudern |
| `reset.jsonl` | mehrere neue Workouts am PM5 während des Ruderns |
