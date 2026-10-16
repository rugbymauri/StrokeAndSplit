# Tasks

Voraussetzungen: `device-types`, `ui-design` und `statistics` (Schema 5) sind in `main`. `device-types` wird vor `heart-rate` archiviert, weil die MODIFIED-Anforderungen auf seinem Text aufbauen. Die Frage F17 (gemerkter Gurt in `settings` oder `shared_preferences`, Design D6) ist vor den Tasks 3.1 und 4.3 entschieden.

Parallel arbeiten: Die Gruppen 1, 2 und 4 hängen an keinem anderen Task dieses Changes und können gleichzeitig starten. Innerhalb der Gruppen und für die übrigen Gruppen gilt:
- Gruppe 2: 2.1 zuerst (Ereignis und `copyWith` als Vertrag für die Gruppen 3 und 5), danach 2.2 und 2.3 parallel, 2.4 nach 2.2 und 2.3, 2.5 nach 2.4, 2.6 nach 2.4 und 1.2.
- Gruppe 3 startet nach 2.1. 3.1 zuerst, danach 3.2 und 3.3 parallel, 3.4 nach 2.4, 3.2 und 3.3.
- Gruppe 4: 4.1 zuerst, danach 4.2, 4.3 und 4.4 parallel, 4.5 nach 4.3 und 4.4.
- Gruppe 5: 5.1 und 5.2 nach 4.1 und 4.3, 5.3 nach 4.5, 5.4 nach 2.1, 5.5 nach 3.3. Jeder UI-Task ergänzt seine Texte selbst in `app_de.arb` und `app_en.arb` und führt `make l10n` aus; Konflikte in den ARB-Dateien beim Zusammenführen sind zu erwarten und einfach.
- Gruppe 6 zum Schluss.

## 1. Spike und Fixture (Hardware)

- [ ] 1.1 Spike um Gurt erweitern (Design D9): zusätzlich nach Service `0x180D` suchen, optional einen Gurt neben dem PM5 oder FTMS-Rudergerät verbinden, `0x2A37` abonnieren und die Pakete als `"c": "2a37"` in dieselbe `.jsonl` schreiben. Verifikation: auf Android oder Linux entsteht ein Mitschnitt mit Zeilen des Rudergeräts und `2a37`-Zeilen, `flutter analyze` sauber
- [ ] 1.2 Mitschnitt von ca. 2 min Rudern am PM5 mit Gurt direkt und gleichzeitig am PM5 als `packages/erg_protocol/test/fixtures/heart_rate.jsonl` ablegen und die Beobachtungen (Flags, RR vorhanden, Taktung) in `packages/erg_protocol/README.md` im Abschnitt „Heart Rate Measurement“ festhalten. Verifikation: Fixture committed, README-Abschnitt vorhanden

## 2. Protokoll in `packages/erg_protocol` (Capability rowing-telemetry)

- [x] 2.1 Neues `RowingEvent` `HeartBeatIntervals(time, intervalsMs)` und `StatusTick.copyWith(heartRate:)` (Design D3). Verifikation: Unit-Tests für `copyWith` (übrige Felder unverändert, `heartRate` auf Wert und auf `null`), `dart analyze --fatal-infos` sauber
- [ ] 2.2 Parser `src/heart_rate/heart_rate_measurement.dart` (Design D3): uint8/uint16, Energy Expended überspringen, RR-Intervalle in ms (`raw * 1000 / 1024`, gerundet), zu kurze Pakete ergeben `null`. Verifikation: Unit-Tests mit selbst gebauten Paketen für alle Flag-Kombinationen und abgeschnittene Pakete
- [ ] 2.3 `HeartRateEncoder` in `src/heart_rate/` erzeugt Gurt-Messungen mit Puls (uint8 und uint16) und RR-Intervallen, damit Tests Gurt-Pakete bauen können. Die Simulatoren bleiben ohne Puls. Verifikation: Roundtrip-Test encode→parse für Puls und RR
- [ ] 2.4 `HeartRateDecoder` umhüllt den Decoder des Rudergeräts (Design D3): fängt `2a37` ab, Vorrangregel Gurt (≤ 3 s Paketzeit) vor Rudergerät vor `null` in jedem `StatusTick`, ein `HeartBeatIntervals` pro Messung mit RR-Intervallen (ohne RR kein Ereignis), abgeschnittene Messungen mit Warnung verwerfen. `ErgDecoder.forProtocol` liefert für PM5 und FTMS den umhüllten Decoder. Verifikation: Unit-Tests mit `Pm5Encoder` bzw. `FtmsEncoder` und `HeartRateEncoder` für die vier Szenarien der Spec „Herzfrequenz nach Vorrang wählen“, die Grenze bei genau 3 s und „Abgeschnittene Messung“; die bestehenden Decoder-Tests bleiben grün
- [ ] 2.5 FTMS-Rückfall absichern (Design D3, F3): Test, dass ein FTMS-Puls ohne Gurt durchkommt, mit frischem Gurt überstimmt wird und nach 3 s ohne Gurt wieder gilt; ein FTMS-Puls 0 bleibt „nicht vorhanden“. `FtmsDecoder` selbst bleibt unverändert. Verifikation: die genannten Unit-Tests sind grün
- [ ] 2.6 Test gegen `heart_rate.jsonl` mit konkreten Puls- und RR-Werten an festen Zeitpunkten. Verifikation: Test grün, Werte stimmen mit den Beobachtungen im README überein

## 3. Datenbank (Capability session-recording)

- [ ] 3.1 Schema auf `schemaVersion` 6 (Design D5, D6 nach F17): Spalten `averageHeartRate`, `maxHeartRate`, `rmssdMs` in `sessions`, Tabelle `rr_intervals` mit Index, Tabelle `settings` nur, wenn F17 bei D6 bleibt. Migrationsschritt `from5To6`, `make codegen` und `make schema` ausführen. Verifikation: Migrationstests 5→6 und 1→6 sind grün, bestehende Sessions bleiben erhalten und haben `null` in den neuen Spalten
- [ ] 3.2 `SessionAccumulator` schreibt `HeartBeatIntervals` mit Endzeit nach Design D4 in `rr_intervals`, auf der Session-Zeitachse wie die übrigen Zeilen. Verifikation: Unit-Test mit einer Messung aus zwei Intervallen prüft beide Zeilen und ihre Zeiten
- [ ] 3.3 `SessionRepository.finish` berechnet Ø-Puls, Max-Puls und RMSSD. Ohne Puls bzw. mit weniger als zwei RR-Intervallen bleibt der jeweilige Wert `null`. Verifikation: Unit-Tests inklusive des Spec-Beispiels 800/810/790 ms ergibt 16 ms und einer Session nur mit PM5-Puls
- [ ] 3.4 Export/Import: Der `session`-Block im Header enthält die neuen Werte, und ein Import baut `rr_intervals` aus den Rohpaketen neu auf. Verifikation: Test exportiert und importiert je eine PM5- und eine FTMS-Session mit Gurt-Paketen und vergleicht Puls, RR und Zusammenfassung

## 4. Gurt-Verbindung (Capability heart-rate-monitor)

- [ ] 4.1 `HeartRateTransport` mit `FoundHeartRateMonitor`, `HeartRateLink`, `HeartRateConnectException` und einem Fake für Tests in `lib/data/sources/ble/` definieren (Design D2), dazu `heartRateTransportProvider` in `platform_providers.dart`. Verifikation: `flutter analyze` sauber, der Fake wird von einem ersten Unit-Test genutzt
- [ ] 4.2 Gurt-Einrichtung neben `setUpRower` auf `GattConnection` (ohne Heart Rate Service `HeartRateConnectException`, sonst `0x2A37` abonnieren) und Implementierung in `FlutterBluePlusTransport`: Suche nur mit Service `0x180D`, 15-s-Timeout, geteilte Readiness-Prüfung. Verifikation: Unit-Tests der Einrichtung mit Fake-`GattConnection`; manuell erscheint ein Gurt in der Suche, ein PM5 oder FTMS-Rudergerät nicht
- [ ] 4.3 Gemerkten Gurt speichern, lesen und löschen nach D6 bzw. F17, mit `chosenHeartRateMonitorProvider` (koppeln, wechseln, vergessen) neben `chosenRowerProvider`. Verifikation: Unit-Test übersteht ein erneutes Öffnen des Speichers (In-Memory-Datenbank bei `settings`, Speicher-Store bei `shared_preferences`) und vergisst den Gurt
- [ ] 4.4 `BleRowerSource.attachHeartRate` und `detachHeartRate` stempeln Gurt-Pakete mit der eigenen Uhr (Design D1); ein Wiederverbinden des Rudergeräts lässt das Gurt-Abonnement bestehen. Verifikation: Unit-Tests mit Fake-Transport zeigen `2a37`-Pakete in `source.packets` auf derselben Zeitachse, für PM5 und FTMS, und auch nach einem Wiederverbinden des Rudergeräts
- [ ] 4.5 `heartRateMonitorProvider` mit Zustandsautomat nach Design D7: Verbinden nur bei verbundener `BleRowerSource` (PM5 oder FTMS), Trennen bei bewusstem Stopp, Quellenwechsel oder Vergessen, 30-s-Wiederverbinden, Grund des Fehlschlags im Zustand „getrennt“, erneuter Versuch auf Anfrage. Den Reconnect-Teil mit `BleRowerSource` teilen, wenn das sauber geht. Verifikation: Unit-Tests mit Fake-Transports für alle Übergänge, inklusive „FTMS verbindet den Gurt“, „Simulator und Replay verbinden keinen Gurt“ und „Gurt-Ausfall lässt das Rudergerät unberührt“

## 5. Oberfläche (Capabilities heart-rate-monitor, live-display, session-recording)

- [ ] 5.1 „Geräte wählen“: Bereich „Pulsgurt“ anstelle des Platzhalters in `choose_devices_screen.dart` mit gekoppeltem Gurt bzw. „Kein Gurt“, Gurt-Suche mit Liste und Tipps nach 15 s, Aktionen Koppeln/Wechseln/Vergessen; „Weiter“ hängt weiter nur vom Rudergerät ab (Design D8). Verifikation: Widget-Tests für Koppeln, Wechseln, Vergessen, „kein Gurt gefunden“ und „Weiter ohne Gurt“; die bestehenden Tests von „Geräte wählen“ bleiben grün
- [ ] 5.2 Startbildschirm: `_DeviceRow` zeigt den gekoppelten Gurt neben dem Rudergerät (Design D8). Verifikation: Widget-Tests für Gerätezeile mit und ohne Gurt, Antippen führt weiter zu „Geräte wählen“
- [ ] 5.3 Live-Display: Gurt-Indikator neben `ConnectionIndicator` in der Kopfzeile, nur bei gekoppeltem Gurt und `BleRowerSource`; bei gescheiterter Verbindung die Meldung mit Hinweis auf begrenzte Verbindungen und „Erneut versuchen“. Verifikation: Widget-Tests für verbunden, wiederverbindend, Fehlschlag mit Meldung (Fake-Transport, der beim Verbinden wirft) und Simulator ohne Indikator
- [ ] 5.4 Live-Display: letztes RR-Intervall klein beim Puls in `live_free.dart` und `live_course.dart`, ausgeblendet ab 3 s Abstand zum jüngsten Tick, ohne Hinweis auf die Puls-Herkunft. Verifikation: Widget-Tests für „812 ms“, Puls nur vom Rudergerät und veraltetes RR; die bestehenden Layout-Tests für Hoch- und Querformat bleiben grün
- [ ] 5.5 Zusammenfassung: Ø/Max-Puls, RR-Kurve per `CustomPainter` und „HRV (RMSSD) xx ms“, alles nur bei vorhandenen Daten. Verifikation: Widget-Tests für Session mit RR, nur mit Puls vom Rudergerät und ohne Puls

## 6. Abschluss und Integration am echten Gerät

- [ ] 6.1 README ergänzen: Gurt in „Geräte wählen“ koppeln, Vorrangregel für PM5 und FTMS, RR/RMSSD, Fixture. Verifikation: README-Abschnitt vorhanden und mit dem Verhalten der App abgeglichen
- [ ] 6.2 `make check` grün. Verifikation: Analyse und alle Tests von App und `erg_protocol` ohne Fehler
- [ ] 6.3 Manuell auf Android und Linux mit Gurt, je einmal mit PM5 und mit FTMS-Rudergerät (oder `make ftms-rower`): Koppeln, automatisch verbinden, Gurt kurz ausser Reichweite (Wiederverbinden), Gurt ablegen (Rückfall auf den Puls des Rudergeräts), Session aufzeichnen, Zusammenfassung prüfen, Replay und Export/Import. Verifikation: Ergebnis im Plattform-Status des README festgehalten
