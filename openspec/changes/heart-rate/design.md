# Design

## Context

Den Puls vom PM5 gibt es bereits: `Pm5Decoder` liest das HR-Byte aus 0x0032 (255 bedeutet „nicht vorhanden“), `StatusTick.heartRate` trägt den Wert, `samples.heart_rate` speichert ihn, und das Live-Display zeigt die Kachel „Puls“ nur bei vorhandenem Wert. Alle Quellen liefern Rohpakete in einen einzigen Decoder (foundation D2). `Pm5BleSource` stempelt jedes Paket mit `clock.now()` relativ zum eigenen Start, und der Recorder speichert die Pakete der aktiven Quelle unverändert in `raw_packets`.

Brustgurte sprechen den Bluetooth-Standard *Heart Rate Profile*:

| UUID | Inhalt |
|---|---|
| `0x180D` Service | Heart Rate |
| `0x2A37` | Heart Rate Measurement (Notify): Flags, Puls als uint8 oder uint16, optional Energy Expended (uint16), optional beliebig viele RR-Intervalle (uint16, Einheit 1/1024 s) |
| `0x2A38` | Body Sensor Location (nicht genutzt) |

Flags in Byte 0: Bit 0 Pulsformat (0 = uint8, 1 = uint16), Bit 3 Energy Expended vorhanden, Bit 4 RR-Intervalle vorhanden. Bits 1–2 (Sensor-Kontakt) werden ignoriert.

Motivation und Umfang: siehe `proposal.md`, Anforderungen: siehe `specs/`.

## Goals / Non-Goals

**Goals:**
- Gurt-Pakete laufen durch denselben Rohpaket-Pfad wie die PM5-Pakete. Recorder, Export, Import und Replay brauchen dafür keinen eigenen Code.
- Die Vorrangregel für den Puls steckt an genau einer Stelle, im Decoder. Live und Replay sind damit identisch.
- Ein Ausfall des Gurts kann die PM5-Verbindung nicht stören.

**Non-Goals:**
- Artefakt-Filterung der RR-Intervalle (Extrasystolen, verpasste Schläge). RMSSD wird aus den Rohintervallen berechnet.
- Mehrere Gurte gleichzeitig.
- Body Sensor Location, Energy Expended und der Sensor-Kontakt-Status.
- Umbenennen von `Pm5Decoder`, obwohl er nun auch Gurt-Pakete versteht.

## Decisions

### D1: Gurt-Pakete werden in den Paketstrom der PM5-Quelle eingespeist

```
 HeartRateMonitor --(2a37 bytes)--> Pm5BleSource.attachHeartRate(stream)
                                          |  stempelt mit eigener Uhr
 PM5 ------------(0031..0036)-----------> |
                                          v
                               source.packets (ein Strom, eine Zeitachse)
                                 |                    |
                         rowingEventsProvider    SessionRecorder -> raw_packets
```

`Pm5BleSource` bekommt eine Methode, mit der sich ein Strom von Gurt-Benachrichtigungen anhängen und wieder lösen lässt. Die Quelle stempelt diese Pakete mit derselben Uhr wie die eigenen, als `RawPacket(characteristicId: '2a37')`. Alles hinter `source.packets` bleibt unverändert, und `.aergrow` nimmt die Zeilen `{"c": "2a37", ...}` ohne Formatänderung auf. Ältere App-Versionen ignorieren sie beim Import mit einer Decoder-Warnung.

*Alternative:* Gurt- und PM5-Strom erst im Provider zusammenführen. Verworfen, weil dann zwei Zeitbasen abgeglichen werden müssten und der Recorder zwei Ströme abonnieren müsste.

### D2: Eigene Transport-Schnittstelle für Gurte

`HeartRateTransport` (Suche gefiltert auf Service `0x180D`, `connect` abonniert `0x2A37`, `HeartRateLink` mit `notifications`, `lost`, `disconnect`) steht neben `BleTransport`. `FlutterBluePlusTransport` implementiert beide. Die Readiness-Prüfung wird geteilt. Tests nutzen wie beim PM5 einen Fake-Transport.

*Alternative:* `BleTransport` um Gurt-Methoden erweitern. Verworfen, weil `FoundPm5` und `Pm5Link` PM5-spezifisch sind und sich die Schnittstelle sonst aufbläht.

### D3: Gurt-Messung im Protokoll-Package dekodieren, Vorrang im Decoder

`pm5_protocol` bekommt `src/heart_rate_measurement.dart` mit einem reinen Parser (Flags, uint8/uint16, Energy überspringen, RR-Liste in ms = `raw * 1000 / 1024`, gerundet). `Pm5Decoder` verarbeitet `2a37`:

- Er merkt sich den letzten Gurt-Puls mit der Paketzeit.
- Beim Ausgeben eines `StatusTick` gilt `heartRate = gurt` (falls `tickZeit - gurtZeit <= 3 s`), sonst der PM5-Wert, sonst `null`.
- Pro Messung mit RR-Intervallen gibt er ein neues `RowingEvent` `HeartBeatIntervals(time, intervalsMs)` aus.

Die 3 Sekunden beziehen sich auf die Paketzeit, nicht auf die Wanduhr. Replay und Import liefern deshalb dasselbe Ergebnis wie live.

*Alternative:* eigenes Package `hr_protocol`. Verworfen, weil es für einen Parser von 30 Zeilen zu viel Infrastruktur wäre.

### D4: Zeitpunkt jedes RR-Intervalls

Eine Messung kann mehrere Intervalle enthalten. Das letzte endet zur Paketzeit `t`, jedes frühere endet um die Summe der späteren Intervalle davor. Die Kurve in der Zusammenfassung nutzt diese Endzeiten als x-Achse. Damit ist die Zuordnung deterministisch und für alle Gurte gleich.

### D5: Schema-Erweiterung (schemaVersion + 1)

```
 sessions      + averageHeartRate int?  + maxHeartRate int?  + rmssdMs int?
 rr_intervals  (sessionId -> sessions cascade, tMs, rrMs)   Index (sessionId, tMs)
 settings      (key text PK, value text)
```

`SessionAccumulator` schreibt aus `HeartBeatIntervals` die Zeilen in `rr_intervals`. `SessionRepository.finish` berechnet den Durchschnitt aus den Samples mit Puls, das Maximum und RMSSD (`sqrt(mean((rr[i+1]-rr[i])^2))`, gerundet, erst ab zwei Intervallen). Der Import baut alles aus den Rohpaketen neu auf und braucht keine Sonderbehandlung. Die Migration ergänzt Spalten und Tabellen, bestehende Sessions behalten `null`. Snapshot und Migrationstest kommen über `make schema`.

*Alternative:* RR-Intervalle nur in den Rohpaketen belassen und für die Zusammenfassung jedes Mal neu dekodieren. Verworfen, weil Liste und Zusammenfassung sonst die ganze Session parsen müssten.

### D6: Gemerkter Gurt in einer `settings`-Tabelle

Die App speichert den Gurt als `heart_rate_monitor.id` und `heart_rate_monitor.name` in einer schlichten Key-Value-Tabelle in derselben drift-Datenbank.

*Alternative:* `shared_preferences`. Verworfen, weil es eine neue Dependency mit eigenem Linux-Backend wäre. Die DB-Migration ist ohnehin fällig.

### D7: Lebenszyklus über einen eigenen Notifier

```
                 PM5 verbunden & Gurt gekoppelt
 [nicht gekoppelt]   [bereit] ----------------------> [verbindend] --ok--> [verbunden]
        ^               |  ^                              |                 |   ^
        | vergessen     |  | PM5 bewusst getrennt         | Fehler          |   | ok
        +---------------+  +------------------------------+--> [getrennt]   v   |
                                                               ^      [wiederverbindend]
                                                               +--- 30 s ----+
```

`heartRateMonitorProvider` beobachtet `activeErgSourceProvider` und `ergConnectionStateProvider`. Nur bei einer `Pm5BleSource` im Zustand „verbunden“ verbindet er den Gurt und hängt dessen Strom an die Quelle (D1). Wiederverbindet sich der PM5, bleibt der Gurt verbunden. Wird der PM5 bewusst gestoppt oder die Quelle gewechselt, trennt er den Gurt. Das Wiederverbinden innerhalb von 30 s folgt derselben Logik wie in `Pm5BleSource`. Lässt sich diese Logik ohne Verrenkungen herauslösen, nutzen beide sie gemeinsam.

### D8: Anzeige

- **Startbildschirm**: ein Bereich „Pulsgurt“ mit dem gekoppelten Gurt oder „Kein Gurt“ sowie den Aktionen Koppeln/Wechseln (öffnet die Gurt-Suche) und Vergessen.
- **Live-Display**: Ein zweiter Indikator steht neben dem bestehenden `ConnectionIndicator`. Die Puls-Kachel zeigt unter dem Wert klein das letzte RR-Intervall. Den letzten `HeartBeatIntervals` merkt sich das Display und blendet ihn aus, wenn der jüngste `StatusTick` mehr als 3 s später liegt. Das funktioniert so auch im Replay.
- **Zusammenfassung**: Ø/Max-Puls als weitere Kennzahlen. Bei RR-Daten kommt eine Kurve mit `CustomPainter` dazu (keine Chart-Dependency, eine einzige Linie) sowie „HRV (RMSSD) xx ms“.

### D9: Spike schneidet Gurt mit

Der Spike sucht zusätzlich nach `0x180D`, verbindet optional einen Gurt und schreibt dessen `2a37`-Pakete in dieselbe `.jsonl`-Datei. Aus einem solchen Mitschnitt entsteht die Fixture `heart_rate.jsonl` in `packages/pm5_protocol/test/fixtures/`.

## Risks / Trade-offs

- [Gurt erlaubt nur eine oder zwei BLE-Verbindungen und hängt schon an Uhr oder PM5] → klare Fehlermeldung (Spec heart-rate-monitor), der Rückfall auf den PM5-Puls greift.
- [Zwei BLE-Verbindungen gleichzeitig belasten schwache Adapter, z.B. unter Linux/BlueZ] → Gurt erst nach stabiler PM5-Verbindung verbinden, am echten Gerät auf Linux und Android verifizieren.
- [RR-Artefakte durch Bewegung beim Rudern verfälschen RMSSD] → als Non-Goal akzeptiert. Die Rohdaten bleiben erhalten, eine spätere Filterung kann alle Sessions neu berechnen.
- [`feature/courses` erhöht `schemaVersion` ebenfalls auf 2] → wer zuletzt merged, rebased, hebt auf die nächste Version und erzeugt Snapshot und Migrationstest neu.
- [Alte App-Version importiert eine Datei mit `2a37`] → Pakete werden mit Warnung verworfen, der PM5-Teil bleibt korrekt.

## Migration Plan

Die Migration auf die nächste `schemaVersion` fügt nur hinzu. Bestehende Sessions bekommen keine Pulszusammenfassung nachträglich. Ein erneuter Import ihrer `.aergrow`-Datei würde sie erzeugen, die App macht das aber nicht automatisch. Rollback heisst: die ältere App-Version installieren und die Datenbank neu anlegen, denn drift-Downgrades werden nicht unterstützt.
