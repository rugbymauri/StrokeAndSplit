# Design

## Context

Motivation und Umfang: siehe `proposal.md`, Anforderungen: siehe `specs/`.

Heutiger Stand (Foundation, archiviert):

- Alle Quellen (`Pm5BleSource`, `SimulatedSource`, `ReplaySource`) liefern `RawPacket`s mit PM5-Characteristic-IDs. `rowingEventsProvider` und `SessionAccumulator` erzeugen fest einen `Pm5Decoder`.
- `SessionOffset` erkennt einen Reset bereits allgemein am Zurückfallen von Zeit oder Distanz, nicht am Workout-Zustand. Der Accumulator ignoriert `WorkoutStateChanged`.
- `FlutterBluePlusTransport` sucht nur nach Namen mit `PM5` und verbindet sich nur mit dem Concept2-Rudern-Service `0x0030`. `FoundPm5`, `Pm5Link` und `Pm5ConnectException` sind PM5-spezifisch benannt.
- Die Tabelle `Strokes` hat Schlagdetails als `NOT NULL`. Die Anzahl Schläge in der Zusammenfassung zählt die Zeilen dieser Tabelle.
- Keine Anzeige liest Schlagdetails, Workout-Typ oder -Zustand. Die Schlagdetails sind also nur in der Datenschicht relevant.
- `ErgSourceKind` (`pm5`, `simulator`, `replay`) wird als Text gespeichert und steuert die Quellenanzeige (`connection_indicator.dart`, `session_summary_screen.dart`).

Der Change `courses` (Branch `feature/courses`, noch nicht gemergt) hebt das Schema auf Version 2: Er führt `wallMs` an den Samples, Strecken, Vorlagen und Runden ein und baut den `SessionAccumulator` aus. Er ändert nur ADDED-Requirements, es gibt also keinen Spec-Konflikt, wohl aber Code- und Schema-Überschneidungen.

FTMS-Rudergeräte (Bluetooth SIG, *Fitness Machine Service 1.0*):

| UUID | Inhalt |
|---|---|
| `0x1826` Service | Fitness Machine. Die Service Data im Advertisement enthält ein Flags-Byte und das Bitfeld Fitness Machine Type (Bit 4 = Rower). |
| `0x2ACC` | Fitness Machine Feature (lesbar): unterstützte Felder |
| `0x2AD1` | Rower Data (Notify): Flags (u16), danach nur die gesetzten Felder |
| `0x2AD9` | Fitness Machine Control Point (Write + Indicate) |
| `0x2ADA` | Fitness Machine Status (Notify, optional) |

Rower Data, in dieser Reihenfolge, jeweils Little-Endian:

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
| 8 | Total Energy, Energy/h, Energy/min | u16 kcal, u16 kcal, u8 kcal |
| 9 | Heart Rate | u8 1/min |
| 10 | Metabolic Equivalent | u8 0.1 |
| 11 | Elapsed Time | u16 s |
| 12 | Remaining Time | u16 s |

Bit 0 ist invertiert („More Data“): Ist es gesetzt, fehlen Stroke Rate und Count, und weitere Teile desselben Datensatzes folgen. Geräte mit kleiner MTU teilen einen Datensatz so auf mehrere Notifications auf.

## Goals / Non-Goals

**Goals:**
- Rohdaten bleiben die Wahrheit, auch bei FTMS. Replay und Import rechnen FTMS-Sessions genauso neu wie PM5-Sessions.
- Alles hinter dem Decoder (Live-Display, Aufzeichnung, Strecken) bleibt protokollblind.
- Der FTMS-Pfad ist ohne FTMS-Hardware bis einschliesslich echter Bluetooth-Übertragung testbar.

**Non-Goals:**
- Steuerung von FTMS-Geräten über Start/Fortsetzen hinaus (Widerstand, Zielwerte, Trainingsprogramme).
- Auswertung von Fitness Machine Status, Training Status oder Feature-Characteristic für die Anzeige.
- Ein Plugin-Mechanismus für beliebige Protokolle.

## Decisions

### D1: Auf `feature/courses` aufbauen

`device-types` wird vor der Umsetzung auf `feature/courses` rebased (oder auf `main`, sobald `courses` gemergt ist). Die Migration geht damit von Schema 2 auf 3.

*Alternative:* parallel auf dem Foundation-Stand bauen und später zusammenführen. Verworfen, weil beide Changes den `SessionAccumulator`, das Schema und das Rohformat ändern. Zwei unabhängige Migrationen auf Version 2 liessen sich nicht sauber zusammenführen.

### D2: Package `pm5_protocol` wird zu `erg_protocol`

Das Package wird umbenannt und gegliedert:

```
packages/erg_protocol/lib/
  erg_protocol.dart          Exporte
  src/
    raw_packet.dart          unverändert
    raw_recording.dart       + Protokoll im Header
    rowing_event.dart        Stroke-Details nullable
    session_offset.dart      unverändert, Parameter neutral benannt
    erg_protocol.dart        enum ErgProtocol { pm5, ftms }
    erg_decoder.dart         interface ErgDecoder + Factory je Protokoll
    pm5/                     Characteristics, Decoder, Encoder, Erg-Typ
    ftms/                    UUIDs, Rower-Data-Parser, Decoder, Encoder
```

`ErgDecoder` hat dieselbe Form wie heute `Pm5Decoder`: `decode(RawPacket)` und `flush()`. `ErgDecoder.forProtocol(protocol, onWarning:)` liefert den passenden Decoder. `wattsForPace` wandert auf die oberste Ebene, weil beide Decoder es nutzen.

*Alternative:* ein zweites Package `ftms_protocol` plus ein drittes für die gemeinsamen Typen. Verworfen: drei Packages für rund 1000 Zeilen, und jede Änderung an `RowingEvent` würde drei `pubspec.yaml` berühren.

### D3: Das Protokoll hängt an der Quelle und an der Session, nicht am Paket

- `ErgSource` bekommt `ErgProtocol get protocol`. Der PM5 meldet `pm5`, eine FTMS-Quelle `ftms`, der Simulator seinen Modus, Replay den Wert aus dem Aufnahme-Header.
- `rowingEventsProvider` und `SessionAccumulator` erzeugen den Decoder über `ErgDecoder.forProtocol(source.protocol)`.
- `Sessions` bekommt die Spalte `protocol` (Text-Enum, Default `pm5`). Export und Import schreiben und lesen sie als `"protocol"` im Header des Rohformats. Fehlt der Schlüssel, gilt `pm5`.

*Alternative:* das Protokoll an jedem `RawPacket` oder aus der Characteristic-ID ableiten (`0031` gegenüber `2ad1`). Verworfen: Eine Session hat genau ein Protokoll, und eine explizite Angabe ist robuster als Heuristiken über IDs. Die Format-Version im Header bleibt 1: Das Feld ist rein additiv, und ältere App-Versionen sind nicht im Umlauf.

### D4: `ErgSourceKind` bekommt `ftms`

`ErgSourceKind` wird zu `{ pm5, ftms, simulator, replay }`. Damit unterscheidet die Quellenanzeige echtes PM5, echtes FTMS-Gerät, Simulator und Replay, wie in `erg-simulation` verlangt. Die Werte werden über ihren Namen gespeichert, ein neuer Wert braucht also keine Datenmigration. `deviceName` wird für beide echten Arten gespeichert.

Der Simulator im FTMS-Modus bleibt `simulator` mit Protokoll `ftms`. Die Anzeige sagt dann „SIMULATOR (FTMS)“.

### D5: Transport für zwei Gerätearten

- `FoundPm5` wird zu `FoundRower { id, name, protocol }`, `Pm5Link` zu `RowerLink`, `Pm5ConnectException` zu `RowerConnectException`.
- **Scan:** Gesucht wird mit Keyword `PM5` und Service `0x1826`. Weil Linux die Filter ignoriert, filtert `add()` selbst:
  - Ein Name mit `PM5` ergibt `pm5`. Endet der Name auf ` Ski` oder ` Bike`, wird das Gerät verworfen. Ein PM5 mit FTMS erscheint deshalb immer als PM5.
  - Sonst wird das Gerät als `ftms` gelistet, wenn das Advertisement Service `0x1826` enthält. Liegt Service Data vor und ist darin Bit 4 (Rower) nicht gesetzt, wird es verworfen. Ohne Service Data wird es gelistet und erst beim Verbinden geprüft.
  - Unter Linux werden zusätzlich `systemDevices([0x0030-Guid, 0x1826])` abgefragt, wie heute für den BlueZ-Cache.
- **Connect PM5:** wie heute, plus eine Erg-Typ-Prüfung (D6).
- **Connect FTMS:** Fehlt die Characteristic `0x2AD1`, wird die Verbindung mit „kein Rudergerät“ getrennt. Sonst wird Notify auf `0x2AD1` aktiviert, danach folgt der Control Point (D7).
- Die bestehende `Pm5BleSource` wird zu `BleRowerSource` mit Protokoll aus `FoundRower`. Reconnect und bewusstes Trennen bleiben gleich, die Logik ist protokollunabhängig.

### D6: PM5 am SkiErg oder BikeErg abweisen

Nach dem Abonnieren wartet `connect` bis zu 3 s auf das erste `0x0032` und liest Byte 16 (Erg-Typ). Laut Concept2-Spezifikation gelten `128` (Static Ski) und `143` (Ski Simulator) als SkiErg, `192` bis `194` und `207` als BikeErg, `225` und `226` als Multi-Erg Ski bzw. Bike. Bei diesen Werten wird getrennt und `RowerConnectException('Nur Rudergeräte werden unterstützt …')` geworfen. Alle anderen Werte und ein Ausbleiben des Pakets werden zugelassen, damit neue RowErg-Varianten nicht blockiert werden. Die Werteliste wird bei der Umsetzung gegen die aktuelle Spezifikation geprüft und als `Pm5ErgType` im Package abgelegt.

*Alternative:* nur die Rudern-Werte zulassen. Verworfen, weil ein unbekannter neuer RowErg dann abgewiesen würde. Ein falsch zugelassener SkiErg ist das kleinere Übel.

### D7: FTMS Control Point defensiv

Nur wenn `0x2AD9` existiert: Indicate aktivieren, `Request Control (0x00)` schreiben und bis zu 2 s auf die Antwort `0x80 00 01` warten. Bei Erfolg folgt `Start or Resume (0x07)`. Fehler, Ablehnung oder Timeout werden protokolliert und ignoriert. `Reset (0x01)` und `Stop or Pause (0x08)` werden nie gesendet, auch nicht beim Trennen.

### D8: FTMS-Decoder

- **Zusammensetzen:** Der Decoder hält den letzten bekannten Wert jedes Felds. Jede Notification aktualisiert die enthaltenen Felder. Ein `StatusTick` entsteht bei jeder Notification mit More Data = 0, also am Ende eines Datensatzes. Pakete, die laut Flags länger sein müssten, werden verworfen (`onWarning`).
- **Zeit:** Die eigene Uhr summiert die Abstände der `RawPacket.time` zwischen zwei Datensätzen, aber nur, während gerudert wird. Die Gerätezeit (Bit 11) wird gelesen, aber nicht verwendet. So bleibt die Zeit bei 1-s-Auflösung flüssig und verhält sich bei Pausen wie am PM5. Weil die Zeit aus `RawPacket.time` kommt, liefert ein Replay exakt dieselben Werte.
- **Rudert:** gilt, solange Distanz oder Schlagzähler in den letzten 4 s gestiegen sind. Viele Geräte melden die letzte Schlagzahl nach dem Aufhören weiter, deshalb zählt die Schlagzahl allein nicht.
- **Pace und Watt:** Die Pace kommt aus Bit 3, ist aber `null`, wenn sie 0 ist, ausserhalb von 1:00 bis 10:00 pro 500 m liegt oder nicht gerudert wird. Watt werden immer mit `wattsForPace` aus der Pace berechnet, die Geräteleistung (Bit 5) wird ignoriert. Das ist dieselbe Bedeutung wie beim PM5 (Spec „Gleiche Pace, gleiche Leistung“), und Gerätewerte für die Leistung sind bei günstigen Rowern oft unzuverlässig.
- **Plausibilität:** Schlagzahl ausserhalb von 1 bis 60 ergibt `null`, Herzfrequenz 0 oder über 250 ebenfalls `null`. Kalorien kommen aus Total Energy, der Platzhalter `0xFFFF` ergibt `null`.
- **Schläge:** Steigt der Schlagzähler von n auf m, entsteht je ein `Stroke` für n+1 bis m mit derselben Zeit und Distanz. Die Details sind `null`, die Leistung ebenfalls. Bei mehr als 10 Schlägen Sprung (z.B. beim Verbinden mitten im Rudern) wird nur der Zählerstand übernommen, ohne Ereignisse.
- **Reset:** Fällt die Distanz oder der Schlagzähler zurück, wird `WorkoutStateChanged(isReset: true)` mit Zuständen `unknown` gemeldet. Die eigene Uhr läuft weiter. Für die Session reicht das, weil `SessionOffset` den Rückfall der Distanz ohnehin erkennt.
- **Workout:** `workoutType` und `workoutState` sind immer `unknown`. Das ist der einzige `WorkoutStateChanged`, den der FTMS-Decoder erzeugt.

### D9: Schlagdetails nullable, Schema 3

`Stroke.driveLengthMeters`, `driveTime`, `recoveryTime`, `peakForceNewtons` und `averageForceNewtons` werden nullable, ebenso die gleichnamigen Spalten in `Strokes`. Die Migration von 2 auf 3:

- `Strokes` über `TableMigration` neu aufbauen, weil SQLite `NOT NULL` nicht per `ALTER` lockern kann. Bestehende Zeilen bleiben erhalten.
- `Sessions.protocol` mit Default `pm5` hinzufügen.

Danach `make schema` ausführen, die Migrationstests aus `courses` um 2→3 und 1→3 erweitern.

### D10: Simulator mit FTMS-Modus

`SimulatedSource` bekommt `protocol` (Default `pm5`). Das Rudermodell (Pace-Annäherung, Schwankung, Pause) bleibt gleich. Nur die Ausgabe wechselt: Im FTMS-Modus erzeugt ein `FtmsEncoder` einmal pro Sekunde ein Rower-Data-Paket mit Stroke Rate und Count, Total Distance, Instantaneous Pace, Instantaneous Power, Total Energy und Elapsed Time. Eine Sekunde entspricht dem typischen Takt realer Geräte, und so fällt auch die Auflösung auf, die die eigene Uhr glätten muss. In der Simulator-Bedienung gibt es eine Auswahl zwischen PM5 und FTMS.

### D11: Software-Rower unter `tool/ftms_rower/`

Zwei Teile, damit die Protokolllogik nur in Dart existiert:

1. **`dart run erg_protocol:pm5_to_ftms <in> <out>`**: Ein Dart-Skript im Package dekodiert eine PM5-Aufnahme (`.jsonl` oder `.aergrow`) und schreibt mit dem `FtmsEncoder` eine FTMS-Aufnahme im Rohformat mit `"protocol": "ftms"` und Paketen `2ad1` im Sekundentakt. Das Ergebnis dient auch als Test-Fixture.
2. **`tool/ftms_rower/ftms_rower.py`**: Ein Python-Skript mit `bless` (BlueZ-GATT-Server über D-Bus) meldet sich als `AergRow FTMS Rower` mit Service `0x1826`, Service Data „Rower“, Rower Data `0x2AD1` und einem Control Point, der Request Control und Start bestätigt. Es spielt die FTMS-Aufnahme zeitgetreu als Notifications ab. Gestartet wird es mit `make ftms-rower FILE=…`, die Abhängigkeiten sind inline deklariert und laufen über `uv run`.

Getestet wird vom Android-Handy aus. Unter Linux kann derselbe Adapter nicht gleichzeitig Peripheral und Central für die eigene App sein.

*Alternative:* der Software-Rower komplett in Dart. Verworfen, weil es kein gepflegtes Dart-Package für BlueZ-GATT-Server gibt. Die Bluetooth-Seite in Python ist klein und hat keine eigene Protokolllogik.

### D12: Spike schneidet FTMS mit

Der Spike sucht auch nach FTMS-Rowern und schreibt deren Notifications von `0x2AD1`, `0x2ADA` und den Control-Point-Antworten im selben Format mit `"protocol": "ftms"` im Header. Wer ein echtes Gerät hat, liefert so direkt importierbare Fixtures.

## Risks / Trade-offs

- [FTMS ist nur gegen die Spezifikation und den eigenen Software-Rower getestet. Echte Geräte weichen ab.] → Defensive Plausibilitätsgrenzen (D8), der Spike für spätere Fixtures (D12) und die Kennzeichnung im README als „ungetestet an echter Hardware“.
- [Ein Gerät sendet nur nach einem Control-Point-Befehl, der hier nicht vorgesehen ist, oder es interpretiert „Start“ als Reset.] → Nur Request Control und Start/Resume. Ein Reset wird vom Accumulator abgefangen. Falls nötig, folgt eine Verbesserung, sobald ein echter Mitschnitt vorliegt.
- [Die Zeit einer FTMS-Session weicht von der Geräteanzeige ab, weil die App selbst misst.] → So gewollt, weil die Zeit dadurch zwischen Geräten vergleichbar ist und im Replay reproduzierbar bleibt. Die Abweichung liegt im Bereich der 4-s-Pausenerkennung.
- [Die Erg-Typ-Werte stammen aus dem Gedächtnis und der Spezifikation, nicht aus einer Messung an Ski- oder BikeErg.] → Nur bekannte Ski- und Bike-Werte werden abgewiesen. Der Name-Suffix filtert zusätzlich in der Liste.
- [Die Umbenennung des Packages berührt viele Imports und kollidiert mit `courses`.] → Die Umbenennung kommt als eigener, rein mechanischer Commit direkt nach dem Rebase (D1).
- [Ein PM5 mit FTMS-Unterstützung wird als PM5 behandelt, auch wenn FTMS bei einem Bike Daten liefern würde.] → Gewollt, denn das PM5-Protokoll ist reicher, und Nicht-RowErgs werden über D6 abgewiesen.

## Migration Plan

1. Rebase auf `feature/courses` (Schema 2).
2. Schema 3: `Strokes` neu aufbauen, `Sessions.protocol` mit Default `pm5`. Bestehende Sessions bleiben vollständig und gelten als PM5.
3. Alte `.aergrow`-Dateien ohne `protocol` werden als PM5 importiert.

Einen Rollback gibt es nicht: Eine ältere App-Version kann eine Datenbank mit Schema 3 nicht öffnen. Bei einer lokalen Single-User-App ohne Verteilung ist das vertretbar.
