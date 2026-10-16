# Tasks

## 1. Spike und Fixture

- [ ] 1.1 Spike um Gurt erweitern (Design D9): zusätzlich nach Service `0x180D` suchen, optional einen Gurt verbinden, `0x2A37` abonnieren und die Pakete als `"c": "2a37"` in dieselbe `.jsonl` schreiben. Verifikation: auf Android oder Linux entsteht ein Mitschnitt mit PM5- und `2a37`-Zeilen
- [ ] 1.2 Mitschnitt von ca. 2 min Rudern mit Gurt direkt und gleichzeitig am PM5 als `packages/pm5_protocol/test/fixtures/heart_rate.jsonl` ablegen und die Beobachtungen (Flags, RR vorhanden, Taktung) in `packages/pm5_protocol/README.md` festhalten. Verifikation: Fixture committed, README-Abschnitt „Heart Rate Measurement“ vorhanden

## 2. Protokoll (Capability rowing-telemetry)

- [ ] 2.1 Parser für Heart Rate Measurement (Design D3): uint8/uint16, Energy Expended überspringen, RR-Intervalle in ms, zu kurze Pakete ergeben `null` mit Warnung. Verifikation: Unit-Tests mit selbst gebauten Paketen für alle Flag-Kombinationen und abgeschnittene Pakete
- [ ] 2.2 `Pm5Decoder` verarbeitet `2a37`: Vorrangregel Gurt (≤ 3 s Paketzeit) vor PM5 vor `null` beim Ausgeben von `StatusTick`. Verifikation: Unit-Tests für die drei Szenarien der Spec „Herzfrequenz nach Vorrang wählen“ sowie für die Grenze bei genau 3 s
- [ ] 2.3 Neues `RowingEvent` `HeartBeatIntervals(time, intervalsMs)` pro Messung mit RR-Intervallen. Ohne RR entsteht kein Ereignis. Verifikation: Unit-Tests, dazu ein Test gegen `heart_rate.jsonl` mit konkreten Puls- und RR-Werten
- [ ] 2.4 `Pm5Encoder` kann Gurt-Messungen erzeugen, damit Tests Gurt-Pakete bauen können. Der Simulator bleibt ohne Puls. Verifikation: Roundtrip-Test encode→decode für Puls und RR

## 3. Datenbank (Capability session-recording)

- [ ] 3.1 Schema erweitern (Design D5/D6): Spalten `averageHeartRate`, `maxHeartRate`, `rmssdMs` in `sessions`, Tabellen `rr_intervals` und `settings`, `schemaVersion` erhöhen, Migration schreiben, `make codegen` und `make schema` ausführen. Verifikation: Migrationstest von der vorherigen Version ist grün, bestehende Sessions bleiben erhalten
- [ ] 3.2 `SessionAccumulator` schreibt `HeartBeatIntervals` mit Endzeit nach Design D4 in `rr_intervals`. Verifikation: Unit-Test mit einer Messung aus zwei Intervallen prüft beide Zeilen und ihre Zeiten
- [ ] 3.3 `SessionRepository.finish` berechnet Ø-Puls, Max-Puls und RMSSD. Ohne Puls bzw. mit weniger als zwei RR-Intervallen bleibt der jeweilige Wert `null`. Verifikation: Unit-Tests inklusive des Spec-Beispiels 800/810/790 ms ergibt 16 ms
- [ ] 3.4 Export/Import: Die Zusammenfassung im Header enthält die neuen Werte, und ein Import baut `rr_intervals` aus den Rohpaketen neu auf. Verifikation: Test exportiert und importiert eine Session mit Gurt-Paketen und vergleicht Puls, RR und Zusammenfassung

## 4. Gurt-Verbindung (Capability heart-rate-monitor)

- [ ] 4.1 `HeartRateTransport` mit `FoundHeartRateMonitor`, `HeartRateLink` und einem Fake für Tests definieren und in `FlutterBluePlusTransport` implementieren (Design D2): Suche nur mit Service `0x180D`, 15-s-Timeout, `connect` abonniert `0x2A37`. Verifikation: `flutter analyze` sauber, manuell erscheint ein Gurt in der Suche, ein PM5 nicht
- [ ] 4.2 Gemerkten Gurt in `settings` speichern, lesen und löschen. Verifikation: Unit-Test mit In-Memory-Datenbank übersteht ein erneutes Öffnen
- [ ] 4.3 `Pm5BleSource` kann einen Gurt-Strom anhängen und lösen und stempelt dessen Pakete mit der eigenen Uhr (Design D1). Verifikation: Unit-Test mit Fake-Transport zeigt `2a37`-Pakete in `source.packets` auf derselben Zeitachse
- [ ] 4.4 `heartRateMonitorProvider` mit Zustandsautomat nach Design D7: Verbinden nur bei verbundener `Pm5BleSource`, Trennen bei bewusstem Stopp oder Quellenwechsel, 30-s-Wiederverbinden. Den Reconnect-Teil mit `Pm5BleSource` teilen, wenn das sauber geht. Verifikation: Unit-Tests mit Fake-Transports für alle Übergänge, inklusive „Simulator verbindet keinen Gurt“ und „Gurt-Ausfall lässt PM5 unberührt“
- [ ] 4.5 Fehlermeldung bei gescheiterter Gurt-Verbindung mit Hinweis auf begrenzte Verbindungen. Verifikation: Widget-Test mit Fake-Transport, der beim Verbinden wirft, plus manueller Test mit einem an Uhr oder PM5 gebundenen Gurt

## 5. Oberfläche (Capabilities heart-rate-monitor, live-display, session-recording)

- [ ] 5.1 Startbildschirm: Bereich „Pulsgurt“ mit gekoppeltem Gurt bzw. „Kein Gurt“, Gurt-Suche mit Liste und Hinweis nach 15 s, Aktionen Koppeln/Wechseln/Vergessen. Verifikation: Widget-Tests für Koppeln, Vergessen und „kein Gurt gefunden“
- [ ] 5.2 Live-Display: Gurt-Indikator neben dem PM5-Indikator, nur bei gekoppeltem Gurt und PM5-Quelle. Verifikation: Widget-Tests für verbunden, wiederverbindend und Simulator ohne Indikator
- [ ] 5.3 Live-Display: letztes RR-Intervall klein unter dem Puls, ausgeblendet ab 3 s Abstand zum jüngsten Tick. Verifikation: Widget-Tests für „812 ms“, Puls nur vom PM5 und veraltetes RR. Die bestehenden Layout-Tests für Hoch- und Querformat bleiben grün
- [ ] 5.4 Zusammenfassung: Ø/Max-Puls, RR-Kurve per `CustomPainter` und „HRV (RMSSD) xx ms“, alles nur bei vorhandenen Daten. Verifikation: Widget-Tests für Session mit RR, nur PM5-Puls und ohne Puls
- [ ] 5.5 README ergänzen: Gurt koppeln, Vorrangregel, RR/RMSSD, Fixture. Verifikation: README-Abschnitt vorhanden und mit dem Verhalten der App abgeglichen

## 6. Integration am echten Gerät

- [ ] 6.1 `make check` grün. Verifikation: Analyse und alle Tests von App und `pm5_protocol` ohne Fehler
- [ ] 6.2 Manuell auf Android und Linux mit PM5 und Gurt: Koppeln, automatisch verbinden, Gurt kurz ausser Reichweite (Wiederverbinden), Gurt ablegen (Rückfall auf PM5-Puls), Session aufzeichnen, Zusammenfassung prüfen, Replay und Export/Import. Verifikation: Ergebnis im Plattform-Status des README festgehalten
