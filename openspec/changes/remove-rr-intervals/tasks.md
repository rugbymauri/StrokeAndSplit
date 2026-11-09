# Tasks

Schema 12 → 13. Texte werden nur entfernt; nach dem Ändern der ARB-Dateien `make l10n`, nach dem Schema `make codegen schema`. Der generierte Code wird committet.

## 1. Protokoll

- [ ] 1.1 `HeartRateMeasurement` ohne `intervalsMs` nach D1, `HeartRateEncoder` ohne RR-Parameter nach D2. Verifikation: `heart_rate_measurement_test.dart` liest 8- und 16-Bit-Messungen mit und ohne Energie- und RR-Angaben mit dem richtigen Puls und verwirft eine Messung mit RR-Flag, die kürzer ist, als ihre Flags angeben.
- [ ] 1.2 `HeartBeatIntervals` aus `RowingEvent` entfernen, `HeartRateDecoder` und `pm5_to_ftms.dart` nach D2. Verifikation: `heart_rate_decoder_test.dart` prüft weiter Gurt vor Rudergerät, Rückfall nach 3 s und die abgeschnittene Messung, ohne RR-Ereignis; `cd packages/erg_protocol && dart test` grün.

## 2. Live-Display

- [ ] 2.1 `rrIntervalMs`, `_beats` und `formatRrInterval` aus `live_screen.dart`, `live_free.dart`, `live_course.dart` und `formatters.dart` entfernen. Verifikation: `live_screen_test.dart` zeigt mit Gurt den Puls ohne `metric-rr`; die Overflow-Tests bleiben grün.

## 3. Aufzeichnung und Datenbank

- [ ] 3.1 `SessionAccumulator` und `SessionRepository` ohne RR-Intervalle und RMSSD, `sessionRrIntervalsProvider` entfernen, Export-Header ohne `rmssdMs` nach D4. Verifikation: `session_heart_rate_test.dart` speichert mit Gurt Durchschnitts- und Maximalpuls; ein Test exportiert ohne `rmssdMs` und importiert eine Datei mit `rmssdMs` im Header ohne Fehler und mit demselben Puls.
- [ ] 3.2 Schema 13 nach D3: Tabelle `RrIntervals` und Spalte `rmssdMs` aus `database.dart`, `from12To13`, `make codegen schema`. Verifikation: `migration_test.dart` migriert eine Session aus Schema 12 mit RR-Intervallen und RMSSD auf 13, die Session behält Zusammenfassung, Puls, Samples und Schläge, und `rr_intervals` gibt es nicht mehr; die alten Tests mit `rrIntervals` und `rmssdMs` sind angepasst; `make check-generated` grün.

## 4. Zusammenfassung

- [ ] 4.1 `_RrIntervals` aus `session_summary_screen.dart`, Texte `summaryRrIntervals`, `summaryRrCurve` und `summaryRmssd` nach D5, `make l10n`. Verifikation: `session_summary_screen_test.dart` zeigt bei einer Session mit Gurt Ø und Max. Puls und weder `summary-rr-curve` noch „HRV“.

## 5. Doku und Abschluss

- [ ] 5.1 README (Abschnitte Pulsgurt und Exportformat) ohne RR-Intervalle und `rmssdMs`; Zweck der Spec `openspec/specs/heart-rate-monitor/spec.md` ohne RR-Intervalle. Verifikation: `grep -rn -i "rr-interv\|rmssd" README.md lib packages/erg_protocol/lib openspec/specs/heart-rate-monitor` findet nichts.
- [ ] 5.2 Gesamtprüfung in der Linux-App mit Scratch-DB: eine Session aus Schema 12 mit RR-Intervallen öffnen (Zusammenfassung mit Puls, ohne RR), im Simulator rudern, Session exportieren und wieder importieren. Verifikation: Screenshots; `make check` grün.
