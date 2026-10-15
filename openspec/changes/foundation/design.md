# Design

## Context

Greenfield: Im Repo gibt es bisher nur OpenSpec. Flutter ist auf dem Entwicklungsrechner (Fedora Linux) noch nicht installiert. Zielplattformen sind Android, iOS und Desktop. Der Laptop des Entwicklers läuft unter Linux, deshalb ist Linux die primäre Desktop-Plattform. Motivation und Umfang: siehe `proposal.md`, Anforderungen: siehe `specs/`.

Der PM5 spricht BLE nach dem öffentlichen Dokument *Concept2 PM5 Bluetooth Smart Interface Definition*. Relevante Teile (Base-UUID `CE06xxxx-43E5-11E4-916C-0800200C9A66`):

| UUID | Inhalt |
|---|---|
| `0x0010` Service | Device Information (Seriennummer, Firmware) |
| `0x0030` Service | Rowing |
| `0x0031` | General Status: Zeit, Distanz, Workout-Typ/-Zustand, Stroke State |
| `0x0032` | Additional Status: Speed, Schlagzahl, HR, aktuelle/Durchschnitts-Pace |
| `0x0033` | Additional Status 2: Kalorien, Watt (Durchschnitt), Intervall-Infos |
| `0x0034` | Sample Rate (beschreibbar: 1 s / 500 ms / 250 ms / 100 ms) |
| `0x0035` | Stroke Data: Durchzugslänge/-zeit, Erholung, Kräfte |
| `0x0036` | Additional Stroke Data: Watt, Kalorien pro Schlag, Schlagzahl |
| `0x0080` | Multiplexed: alle obigen über eine Characteristic, mit ID-Präfix-Byte |

Werte sind Little-Endian, viele als 24-Bit-Integer mit Einheit 0.01 (Zeit in 1/100 s, Distanz in 1/10 m).

## Goals / Non-Goals

**Goals:**
- Die Protokollschicht ist reines Dart ohne Flutter- oder BLE-Abhängigkeit und vollständig unit-testbar.
- PM5, Simulator und Replay laufen durch **denselben** Decoder-Pfad.
- Die App startet ohne Erg vollständig nutzbar (Simulator), damit spätere Changes (Strecken, Ghost) am Schreibtisch entwickelt werden können.
- Das Datenmodell der Session trägt spätere Features (Ghost braucht dichten (t, d)-Verlauf), ohne Migration der Rohdaten.

**Non-Goals:**
- CSAFE-Kommandos und Workout-Programmierung am PM5.
- Kraftkurve (`0x003D`). Sie wird nicht dekodiert, die Rohdaten werden aber mitgespeichert, falls abonniert.
- Mehrere gleichzeitige Ergs.
- Windows als getestete Plattform (best effort).
- Sync, Accounts, Concept2-Logbook.

## Decisions

### D1: Flutter mit lokalem Dart-Package für das Protokoll

```
aergrow/                      (Repo-Root = Flutter-App)
  lib/
    app/                      Routing, Theme, Provider-Setup
    features/
      connection/             Geräte-Suche, Verbindungs-UI
      live/                   Live-Display
      sessions/               Recorder, Liste, Detail, Export/Import
      simulator/              Simulator-Steuerung (UI)
    data/
      sources/                ErgSource-Implementierungen
      db/                     drift-Datenbank
  packages/
    pm5_protocol/             reines Dart: Decoder, Encoder, Modelle
      test/fixtures/          aufgezeichnete Byte-Dumps
```

`pm5_protocol` ist per `path:`-Dependency eingebunden und mit `dart test` testbar, also ohne Gerät und ohne Flutter-Engine.
*Alternative:* alles in `lib/`. Verworfen, weil dabei die Grenze zwischen Protokoll und App leicht verwischt und Tests eine Flutter-Testumgebung brauchen.

### D2: Alle Datenquellen liefern Rohpakete, ein einziger Decoder

```
  Pm5BleSource ---+
  SimulatedSource-+--> Stream<RawPacket{charId, bytes, t}> --> Pm5Decoder
  ReplaySource ---+                                              |
                                                                 v
                                           Stream<RowingEvent> (StatusTick,
                                           Stroke, WorkoutStateChanged)
```

Der Simulator erzeugt mit einem `Pm5Encoder` echte PM5-Bytes. Daraus folgt:
- Die Spec-Anforderung „einheitliche Daten über alle Quellen“ ist strukturell erfüllt.
- Encoder und Decoder testen sich gegenseitig (Roundtrip-Tests).
- *Jede* Session, auch eine simulierte, hat Rohpakete und ist identisch abspielbar.

*Alternative:* Der Simulator erzeugt direkt `RowingEvent`s. Verworfen, weil sonst zwei Pfade auseinanderlaufen können und simulierte Sessions nicht replay-fähig wären.

### D3: Einzelne Characteristics statt Multiplexed

Wir abonnieren `0x0031`, `0x0032`, `0x0033`, `0x0035`, `0x0036` einzeln und setzen die Sample Rate über `0x0034` auf 250 ms. Das ist ein einfacher Characteristic-Write, kein CSAFE.
*Alternative:* `0x0080` Multiplexed. Damit braucht es nur eine Subscription, was auf manchen Plattformen robuster ist. Das Format ist intern dasselbe plus Präfix-Byte. Der Decoder unterstützt deshalb beide Varianten, sodass ein Wechsel nur die BLE-Schicht betrifft, falls der Spike Probleme zeigt.

### D4: BLE mit `flutter_blue_plus`

Es unterstützt Android, iOS, macOS und Linux (BlueZ) mit einer API. Die Suche filtert auf den Rowing-Service bzw. das Namenspräfix `PM5`. Die Wiederverbindung (30 s) liegt in `Pm5BleSource` als Zustandsautomat:

```
 disconnected --scan--> scanning --select--> connecting --ok--> connected
      ^                                          |                  |
      |                                        fail           link lost
      |                                          v                  v
      +-------------------- 30 s Timeout ---- reconnecting <--------+
      +<-------- user disconnect (kein Reconnect) -------- connected
```

Berechtigungen für Android 12+ (`BLUETOOTH_SCAN` mit `neverForLocation`, `BLUETOOTH_CONNECT`) und `NSBluetoothAlwaysUsageDescription` auf iOS.

### D5: State-Management mit Riverpod

Die Streams (`RowingEvent`, Verbindungszustand) lassen sich mit `StreamProvider` direkt anbinden. Die aktive `ErgSource` ist ein austauschbarer Provider, was den Quellwechsel (PM5, Simulator, Replay) trivial macht.
*Alternativen:* Bloc (mehr Boilerplate), Provider (zu schwach für Stream-Komposition).

### D6: Session-Zählung mit Offset-Akkumulator

Die Session-Werte werden aus PM5-Werten abgeleitet:

```
 sessionDistance = carried + (pm5Distance - baseline)
 Start:  baseline = pm5Distance aktuell, carried = 0
 Reset erkannt (pm5Distance < letzter Wert oder Workout-Zustand neu):
         carried += letzter Wert - baseline;  baseline = 0
```

Das Gleiche gilt für die Zeit. Damit sind die Anforderungen „ab Session-Start zählen“ und „PM5-Reset überstehen“ erfüllt. Die Logik steckt in einer reinen Funktion und ist unit-getestet.

### D7: Lokale Persistenz mit drift (SQLite)

```
 sessions   (id, startedAt, endedAt?, status: recording|complete|incomplete,
             source: pm5|simulator|replay, deviceName?, summary-Felder)
 samples    (sessionId, t_ms, distance_dm, pace_cs, watts, spm, hr?, calories)
 strokes    (sessionId, t_ms, strokeNo, driveLength, driveTime, recoveryTime,
             peakForce, avgForce)
 raw_packets(sessionId, t_ms, charId, bytes BLOB)
```

- `samples` sind bereits session-relativ (D6) und bilden das dichte (t, d)-Raster für den späteren Ghost.
- Schreiben erfolgt gepuffert, alle 2 s als Batch-Transaktion. Bei einem Absturz gehen also höchstens ca. 2 s verloren.
- Beim App-Start werden Sessions mit `status = recording` auf `incomplete` gesetzt und ihre Zusammenfassung aus den gespeicherten Samples berechnet.
- Grössenordnung: bei 250 ms rund 14k Samples pro Stunde plus rund 5 Rohpakete pro Tick. Das ist für SQLite unkritisch.

*Alternativen:* Isar/Hive. Verworfen, weil Zeitreihen-Abfragen (Ghost-Lookup per Distanz) in SQL natürlicher sind und drift typsichere Migrationen mitbringt.

### D8: Exportformat `.aergrow`

gzip-komprimiertes JSON Lines. Zeile 1 enthält Metadaten (Formatversion, Session-Zusammenfassung, Quelle), danach eine Zeile pro Rohpaket `{t, c, b}` (Bytes in Base64). Beim Import werden `samples` und `strokes` durch Replay des Decoders neu erzeugt. So bleibt das Format minimal, und Decoder-Fixes wirken sich auch rückwirkend aus. Dieselben Dateien dienen als Test-Fixtures in `pm5_protocol/test/fixtures/`.

### D9: Simulator-Modell

Ein einfaches Physik-light-Modell: Aus der Ziel-Pace folgt die Geschwindigkeit, aus der Ziel-Schlagzahl das Schlagintervall. Pro Schlag gibt es eine Pace-Schwankung von ±2 % und eine Annäherung an Ziel-Werte über ca. 3 Schläge. Watt werden nach der Concept2-Formel `P = 2.80 / (pace_s_per_m)³` berechnet. Ein deterministischer Seed ist für Tests möglich.

### D10: Bildschirm aktiv halten mit `wakelock_plus`

Der Wakelock wird aktiviert, solange das Live-Display sichtbar ist und eine Quelle verbunden ist.

## Risks / Trade-offs

- **Byte-Layout weicht von Erinnerung oder Dokument ab** → Spike am echten PM5 als einer der ersten Schritte. Die Rohpakete werden mitgeschnitten, und alle Decoder-Tests basieren auf echten Dumps statt auf Annahmen.
- **Linux-BLE (BlueZ) zickt mit `flutter_blue_plus`** → Der Simulator macht den Laptop auch ohne BLE nutzbar. Die BLE-Verifikation erfolgt primär auf Android. Bei Problemen fällt die Wahl auf Multiplexed (D3).
- **iOS-Build erfordert einen Mac** → iOS wird konfiguriert (Info.plist, Permissions). Die Verifikation auf einem iOS-Gerät hängt von der Verfügbarkeit eines Macs ab und wird in den Tasks separat ausgewiesen.
- **PM5 erlaubt nur eine BLE-Verbindung** → klare Fehlermeldung (Spec erg-connection). Nicht technisch lösbar.
- **Pace-Glättung am PM5 verzögert Werte** → Das ist für die Anzeige akzeptabel. Für spätere Gamification ist es bekannt und wird dort behandelt.
- **Speicherbedarf der Rohpakete** → Die Rohdaten machen den grössten Teil einer Session aus (Schätzung: wenige MB pro Stunde). Das ist akzeptabel. Eine spätere Bereinigung (z.B. Rohdaten nach X Monaten löschen) bleibt möglich, ohne `samples` zu verlieren.

## Open Questions

- Unterstützt der PM5 die Sample Rate 100 ms stabil über BLE auf allen Plattformen? Start mit 250 ms. Eine Erhöhung ist ein reiner Konfigurationswert.
- Genaues Verhalten von Elapsed Time im „Just Row“-Modus bei längeren Pausen. Für diesen Change unkritisch (D6 behandelt Rücksprünge), wichtig erst für zeitbasierte Strecken im Change `courses`. Wird im Spike mitgeloggt.
