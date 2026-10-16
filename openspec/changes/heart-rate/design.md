# Design

## Context

Den Puls vom Rudergerät gibt es bereits für beide Protokolle in `packages/erg_protocol`:

- `Pm5Decoder` liest das HR-Byte aus 0x0032 (255 bedeutet „nicht vorhanden“).
- `FtmsDecoder` liest das Feld Heart Rate der Rower Data 0x2AD1 (Flag-Bit 9, uint8, `RowerData.heartRate`). Werte ausserhalb 1–250, also auch 0, werden zu `null`. Der Decoder behält den letzten gemeldeten Wert, solange ein Datensatz das Feld nicht enthält, weil FTMS-Geräte einen Datensatz auf mehrere Benachrichtigungen verteilen dürfen.

Beide füllen `StatusTick.heartRate`, `samples.heart_rate` speichert den Wert, und das Live-Display zeigt den Puls nur bei vorhandenem Wert (`live_free.dart` in der Zeile unter den Kacheln, `live_course.dart` als kleine Kachel, jeweils mit `HeartIcon`).

Alle Quellen implementieren `ErgSource` und liefern Rohpakete ihres Protokolls. `ErgDecoder.forProtocol` wählt den Decoder. Er wird an zwei Stellen erzeugt: in `rowingEventsProvider` für Live und Replay und in `SessionAccumulator` für Aufzeichnung und Import. `BleRowerSource` (PM5 und FTMS) stempelt jedes Paket mit `clock.now()` relativ zum eigenen Start, und der Recorder speichert die Pakete der aktiven Quelle unverändert in `raw_packets`. Unbekannte Characteristics verwerfen beide Decoder mit einer Warnung.

Bluetooth läuft über `BleTransport` (`FoundRower`, `RowerLink`) mit `FlutterBluePlusTransport` als Implementierung. Die plugin-abhängige Schicht ist `GattConnection` in `rower_connector.dart`, `setUpRower` richtet darauf PM5 oder FTMS ein. Das gewählte Rudergerät steht als `RowerChoice` in `shared_preferences` (`rower_choice.dart`, Key `rower`), die Sprache ebenso (`app_language.dart`, Key `language`). „Geräte wählen“ (`choose_devices_screen.dart`) hat einen Platzhalter für den Pulsgurt, der Startbildschirm (`start_screen.dart`, `_DeviceRow`) zeigt das Rudergerät, das Live-Display zeigt `ConnectionIndicator` in der Kopfzeile. Die Datenbank steht auf `schemaVersion` 5.

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
- Gurt-Pakete laufen durch denselben Rohpaket-Pfad wie die Pakete des Rudergeräts. Recorder, Export, Import und Replay brauchen dafür keinen eigenen Code.
- Die Vorrangregel für den Puls steckt an genau einer Stelle, unabhängig vom Protokoll des Rudergeräts. Live, Aufzeichnung, Import und Replay sind damit identisch.
- Ein Ausfall des Gurts kann die Verbindung zum Rudergerät nicht stören.

**Non-Goals:**
- Artefakt-Filterung der RR-Intervalle (Extrasystolen, verpasste Schläge). RMSSD wird aus den Rohintervallen berechnet.
- Mehrere Gurte gleichzeitig.
- Body Sensor Location, Energy Expended und der Sensor-Kontakt-Status.
- Ein Gurt mit Simulator oder Replay und ein simulierter Gurt.
- Änderungen am Puls-Verhalten von `Pm5Decoder` und `FtmsDecoder`.

## Decisions

### D1: Gurt-Pakete werden in den Paketstrom der Rudergerät-Quelle eingespeist

```
 HeartRateMonitor --(2a37 bytes)--> BleRowerSource.attachHeartRate(stream)
                                          |  stempelt mit eigener Uhr
 PM5 (0031..0036) / FTMS (2ad1..) ------> |
                                          v
                               source.packets (ein Strom, eine Zeitachse)
                                 |                    |
                         rowingEventsProvider    SessionRecorder -> raw_packets
```

`BleRowerSource` bekommt `attachHeartRate(Stream<(String, List<int>)>)` und `detachHeartRate()`. Die Quelle stempelt diese Pakete mit derselben Uhr wie die eigenen, als `RawPacket(characteristicId: '2a37')`. Das Abonnement des Gurts ist vom `RowerLink` getrennt, ein Wiederverbinden des Rudergeräts lässt es unberührt. Alles hinter `source.packets` bleibt unverändert, und `.aergrow` nimmt die Zeilen `{"c": "2a37", ...}` ohne Formatänderung auf, bei PM5- wie bei FTMS-Sessions. Ältere App-Versionen verwerfen sie beim Import mit einer Decoder-Warnung.

*Alternative:* Gurt- und Rudergerät-Strom erst im Provider zusammenführen. Verworfen, weil dann zwei Zeitbasen abgeglichen werden müssten und der Recorder zwei Ströme abonnieren müsste.

### D2: Eigene Transport-Schnittstelle für Gurte

`HeartRateTransport` steht neben `BleTransport` in `lib/data/sources/ble/`: `readiness()`, `scan` gefiltert auf Service `0x180D` mit `FoundHeartRateMonitor(id, name)`, `connect` liefert einen `HeartRateLink` mit `notifications`, `lost` und `disconnect`. `FlutterBluePlusTransport` implementiert beide Schnittstellen und teilt Readiness-Prüfung und `GattConnection`. Die Einrichtung des Gurts (`0x2A37` abonnieren, ohne Heart Rate Service `HeartRateConnectException`) steckt plugin-unabhängig neben `setUpRower`, sodass sie mit einer Fake-`GattConnection` testbar ist. Tests nutzen wie beim Rudergerät einen Fake-Transport.

*Alternative:* `BleTransport` um Gurt-Methoden erweitern. Verworfen, weil `FoundRower` und `RowerLink` auf Rudergeräte zugeschnitten sind (Protokoll, `RowerConnectError`) und sich die Schnittstelle sonst aufbläht.

### D3: Gurt-Messung im Protokoll-Package dekodieren, Vorrang in einem vorgeschalteten Decoder

`erg_protocol` bekommt `src/heart_rate/heart_rate_measurement.dart` mit einem reinen Parser (Flags, uint8/uint16, Energy überspringen, RR-Liste in ms = `raw * 1000 / 1024`, gerundet) und `src/heart_rate/heart_rate_decoder.dart` mit `HeartRateDecoder implements ErgDecoder`. Er umhüllt den Decoder des Rudergeräts:

- Pakete `2a37` fängt er ab, der innere Decoder sieht sie nie. Er merkt sich den letzten Gurt-Puls mit der Paketzeit.
- Alle anderen Pakete gibt er weiter. In jedem `StatusTick` des inneren Decoders setzt er `heartRate = gurt` (falls `tickZeit - gurtZeit <= 3 s`), sonst bleibt der Wert des Rudergeräts (PM5 oder FTMS), sonst `null`. Die Tickzeit ist die Paketzeit des auslösenden Pakets.
- Pro Messung mit RR-Intervallen gibt er ein neues `RowingEvent` `HeartBeatIntervals(time, intervalsMs)` aus.

`ErgDecoder.forProtocol` liefert den umhüllten Decoder, damit `rowingEventsProvider` und `SessionAccumulator` die Regel ohne eigene Änderung bekommen. `StatusTick` braucht dafür `copyWith(heartRate:)`. Die 3 Sekunden beziehen sich auf die Paketzeit, nicht auf die Wanduhr. Replay und Import liefern deshalb dasselbe Ergebnis wie live.

FTMS-Puls (F3, entschieden 2026-10-16): `FtmsDecoder` dekodiert das Feld Heart Rate bereits. Er bleibt unverändert und dient als Rückfall wie der PM5-Puls. Das Festhalten des letzten FTMS-Werts ändert die Regel nicht, weil der Gurt Vorrang hat. Ohne Gurt zeigt die App weiter, was das Gerät zuletzt gemeldet hat, wie heute.

*Alternativen:* die Regel in `Pm5Decoder` und `FtmsDecoder` je einzeln einbauen. Verworfen, weil sie dann doppelt stünde und für jedes weitere Protokoll erneut. Ein eigenes Package `hr_protocol`. Verworfen, weil es für einen Parser von 30 Zeilen zu viel Infrastruktur wäre.

### D4: Zeitpunkt jedes RR-Intervalls

Eine Messung kann mehrere Intervalle enthalten. Das letzte endet zur Paketzeit `t`, jedes frühere endet um die Summe der späteren Intervalle davor. Die Kurve in der Zusammenfassung nutzt diese Endzeiten als x-Achse. Damit ist die Zuordnung deterministisch und für alle Gurte gleich.

### D5: Schema-Erweiterung auf `schemaVersion` 6

```
 sessions      + averageHeartRate int?  + maxHeartRate int?  + rmssdMs int?
 rr_intervals  (sessionId -> sessions cascade, tMs, rrMs)   Index (sessionId, tMs)
 settings      (key text PK, value text)                     siehe D6 und F17
```

`SessionAccumulator` schreibt aus `HeartBeatIntervals` die Zeilen in `rr_intervals`. `SessionRepository.finish` berechnet den Durchschnitt aus den Samples mit Puls, das Maximum und RMSSD (`sqrt(mean((rr[i+1]-rr[i])^2))`, gerundet, erst ab zwei Intervallen). Der Export schreibt die drei Werte in den `session`-Block des Headers. Der Import baut alles aus den Rohpaketen neu auf und braucht keine Sonderbehandlung. Die Migration von 5 auf 6 ergänzt Spalten und Tabellen, bestehende Sessions behalten `null`. Snapshot und Migrationstest kommen über `make schema`.

*Alternative:* RR-Intervalle nur in den Rohpaketen belassen und für die Zusammenfassung jedes Mal neu dekodieren. Verworfen, weil Liste und Zusammenfassung sonst die ganze Session parsen müssten.

### D6: Gemerkter Gurt in einer `settings`-Tabelle

Die App speichert den Gurt als `heart_rate_monitor.id` und `heart_rate_monitor.name` in einer schlichten Key-Value-Tabelle in derselben drift-Datenbank.

*Alternative:* `shared_preferences`. Verworfen, weil es eine neue Dependency mit eigenem Linux-Backend wäre. Die DB-Migration ist ohnehin fällig.

*Stand 2026-10-16, offen (F17):* Die Begründung trifft nicht mehr zu. `shared_preferences` ist seit `ui-design` eine Dependency und hält das gemerkte Rudergerät (`rower_choice.dart`) und die Sprache. Ob der Gurt ebenfalls dorthin gehört und die Tabelle `settings` entfällt, entscheidet der Nutzer, siehe Open Questions.

### D7: Lebenszyklus über einen eigenen Notifier

```
                 Rudergerät verbunden & Gurt gekoppelt
 [nicht gekoppelt]   [bereit] ----------------------> [verbindend] --ok--> [verbunden]
        ^               |  ^                              |                 |   ^
        | vergessen     |  | Rudergerät bewusst getrennt  | Fehler          |   | ok
        +---------------+  +------------------------------+--> [getrennt]   v   |
                                                               ^      [wiederverbindend]
                                                               +--- 30 s ----+
```

`heartRateMonitorProvider` beobachtet den gemerkten Gurt, `activeErgSourceProvider` und `ergConnectionStateProvider`. Ist die aktive Quelle eine `BleRowerSource` (PM5 oder FTMS, F4, entschieden 2026-10-16) im Zustand „verbunden“, verbindet er den gemerkten Gurt automatisch und hängt dessen Strom an die Quelle (D1). Simulator und Replay verbinden keinen Gurt. Wiederverbindet sich das Rudergerät, bleibt der Gurt verbunden. Wird das Rudergerät bewusst gestoppt oder die Quelle gewechselt, trennt er den Gurt. Das Wiederverbinden innerhalb von 30 s folgt derselben Logik wie in `BleRowerSource._reconnect`. Lässt sich diese Logik ohne Verrenkungen herauslösen, etwa als Funktion mit Zeitfenster, Wartezeit und `connect`, nutzen beide sie gemeinsam. Scheitert die Verbindung, hält der Zustand „getrennt“ den Grund fest, damit das Live-Display die Meldung zeigen und einen neuen Versuch anbieten kann.

### D8: Anzeige

- Puls-Herkunft (F1, entschieden 2026-10-16): Gurt vor Rudergerät vor keinem Puls nach der Vorrangregel (D3). Die Herkunft wird im Live-Display nicht angezeigt, ohne Puls fehlt die Kachel bzw. der Wert.
- FTMS-Rudergerät und Gurt (F3, entschieden 2026-10-16): Liefern beide einen Puls, gilt der Gurt, wie beim PM5. Der Puls des FTMS-Geräts dient nur als Rückfall, wenn kein Gurt verbunden ist oder er keine Werte liefert.
- **Geräte wählen** (vor dem Startbildschirm, `ui-design` D6, entschieden 2026-10-16): Der Bereich „Pulsgurt“ ersetzt den Platzhalter in `choose_devices_screen.dart` unter den Rudergeräten und Simulatoren. Er zeigt den gekoppelten Gurt oder „Kein Gurt“ sowie die Aktionen Koppeln/Wechseln (öffnet die Gurt-Suche mit Liste, 15-s-Timeout und Tipps) und Vergessen. Der Pulsgurt ist optional, „Weiter“ hängt nur vom Rudergerät ab. Die Gurt-Suche läuft getrennt von der Suche nach Rudergeräten, damit sich die Listen nicht vermischen.
- **Startbildschirm**: `_DeviceRow` zeigt neben dem Rudergerät den gekoppelten Gurt, ohne Gurt nur das Rudergerät. Antippen führt wie heute zu „Geräte wählen“.
- **Live-Display**: Ein Gurt-Indikator (Punkt wie `ConnectionIndicator`, mit `HeartIcon` unterscheidbar) steht in der Kopfzeile neben `ConnectionIndicator`, nur bei gekoppeltem Gurt und einer `BleRowerSource`. Der Puls zeigt klein das letzte RR-Intervall, in der Kachel von `live_course.dart` unter dem Wert, in der Zeile von `live_free.dart` hinter dem Wert. Den letzten `HeartBeatIntervals` merkt sich das Display und blendet ihn aus, wenn der jüngste `StatusTick` mehr als 3 s später liegt. Das funktioniert so auch im Replay.
- **Zusammenfassung**: Ø/Max-Puls als weitere Kennzahlen. Bei RR-Daten kommt eine Kurve mit `CustomPainter` dazu (keine Chart-Dependency, eine einzige Linie) sowie „HRV (RMSSD) xx ms“.
- Alle neuen Texte kommen über die ARB-Dateien in Deutsch und Englisch.

### D9: Spike schneidet Gurt mit

Der Spike sucht zusätzlich nach `0x180D`, verbindet optional einen Gurt neben dem PM5 oder FTMS-Rudergerät und schreibt dessen `2a37`-Pakete in dieselbe `.jsonl`-Datei. Aus einem solchen Mitschnitt entsteht die Fixture `heart_rate.jsonl` in `packages/erg_protocol/test/fixtures/`.

## Risks / Trade-offs

- [Gurt erlaubt nur eine oder zwei BLE-Verbindungen und hängt schon an Uhr, PM5 oder FTMS-Gerät] → klare Fehlermeldung (Spec heart-rate-monitor), der Rückfall auf den Puls des Rudergeräts greift.
- [Zwei BLE-Verbindungen gleichzeitig belasten schwache Adapter, z.B. unter Linux/BlueZ] → Gurt erst nach stabiler Verbindung zum Rudergerät verbinden, am echten Gerät auf Linux und Android verifizieren.
- [RR-Artefakte durch Bewegung beim Rudern verfälschen RMSSD] → als Non-Goal akzeptiert. Die Rohdaten bleiben erhalten, eine spätere Filterung kann alle Sessions neu berechnen.
- [FTMS-Gerät meldet nach Abnehmen seines eigenen Gurts weiter den letzten Wert, weil `FtmsDecoder` ihn festhält] → bestehendes Verhalten, nicht Teil dieses Changes. Mit direkt verbundenem Gurt ohne Wirkung, weil der Gurt Vorrang hat.
- [`statistics` hat `schemaVersion` auf 5 gehoben] → `heart-rate` hebt auf 6 und erzeugt Snapshot und Migrationstest auf dem Stand von `statistics`. Kommt ein anderer Change mit Schema-Änderung vorher nach `main`, verschiebt sich die Nummer.
- [Die MODIFIED-Anforderungen in `rowing-telemetry` und `session-recording` bauen auf dem Text von `device-types` auf, der noch nicht archiviert ist] → `device-types` vor `heart-rate` archivieren.
- [Alte App-Version importiert eine Datei mit `2a37`] → Pakete werden mit Warnung verworfen, der Teil des Rudergeräts bleibt korrekt.

## Migration Plan

Die Migration von `schemaVersion` 5 auf 6 fügt nur hinzu. Bestehende Sessions bekommen keine Pulszusammenfassung nachträglich. Ein erneuter Import ihrer `.aergrow`-Datei würde sie erzeugen, die App macht das aber nicht automatisch. Rollback heisst: die ältere App-Version installieren und die Datenbank neu anlegen, denn drift-Downgrades werden nicht unterstützt.

## Open Questions

- **F17: Gemerkter Gurt in `settings` oder `shared_preferences`?** D6 plant eine Tabelle `settings`, das gemerkte Rudergerät und die Sprache liegen aber in `shared_preferences`. Mit `shared_preferences` entfällt die Tabelle `settings` in D5, der Gurt folgt dem Muster von `RowerChoiceStore` (Store-Schnittstelle, Implementierung mit `SharedPreferencesWithCache`, Speicher-Variante für Tests, Öffnen in `main`), und die Tasks 3.1 und 4.3 werden entsprechend angepasst.
