# Proposal

## Why

Die RR-Intervalle eines direkt verbundenen Gurts (Wert beim Puls im Live-Display, Kurve und RMSSD in der Zusammenfassung) werden nicht genutzt. Sie binden den Puls an den direkt verbundenen Gurt, obwohl ein FTMS-Rudergerät mit eigenem Gurt den Puls auch liefert, und sie kosten eine eigene Tabelle, ein eigenes Ereignis und eigene Anzeigen. Ohne RR-Intervalle ist der Puls vom Gurt und vom Rudergerät gleichwertig; darauf baut `heart-rate-from-rower` auf.

## What Changes

- **Live-Display**: Beim Puls steht kein RR-Intervall mehr („812 ms“).
- **Zusammenfassung**: keine RR-Kurve und kein „HRV (RMSSD)“ mehr; Durchschnitts- und Maximalpuls bleiben.
- **Aufzeichnung**: RR-Intervalle und RMSSD werden nicht mehr berechnet oder gespeichert. Die Rohpakete des Gurts werden weiter aufgezeichnet und exportiert, der Puls daraus weiter ausgewertet.
- **Datenbank**: Schema 13 löscht die Tabelle der RR-Intervalle und die RMSSD-Spalte der Sessions. Bestehende Sessions behalten alles andere. **BREAKING** für die gespeicherten RR-Daten: sie sind danach nur noch in den Rohpaketen enthalten.
- **Export/Import**: Der Export schreibt kein `rmssdMs` mehr in den Header; der Import nimmt ältere Dateien mit `rmssdMs` weiterhin an und ignoriert das Feld.
- **Protokoll**: Die Gurt-Messung liefert nur noch den Puls; RR-Angaben werden gelesen, damit die Länge der Messung geprüft wird, aber nicht weitergegeben.

Nicht Teil dieses Changes:

- Das Verhalten der Gurt-Verbindung und ihrer Meldung; das regelt `heart-rate-from-rower`.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `rowing-telemetry`: „RR-Intervalle bereitstellen“ entfällt.
- `live-display`: „Letztes RR-Intervall anzeigen“ entfällt.
- `session-recording`: „Session vollständig speichern“ und „Rohdaten für Replay speichern“ ohne RR-Intervalle, „RR-Intervalle in der Zusammenfassung“ entfällt, neues Szenario für den Import alter Dateien.

## Impact

- **Code**:
  - `packages/erg_protocol`: `HeartBeatIntervals` aus `rowing_event.dart`, RR-Ausgabe in `heart_rate_decoder.dart`, `intervalsMs` in `heart_rate_measurement.dart` und `heart_rate_encoder.dart`, Fall in `pm5_to_ftms.dart`.
  - `lib/data/db/database.dart`: Tabelle `RrIntervals` und Spalte `rmssdMs` weg, `schemaVersion` 13 mit Migration; `make codegen schema`.
  - `lib/data/sessions`: Accumulator, Repository (`rmssd`, `rrIntervals`, Export-Header), `sessionRrIntervalsProvider`.
  - `lib/features/live`: `live_screen.dart`, `live_free.dart`, `live_course.dart`, `formatRrInterval`.
  - `lib/features/sessions/session_summary_screen.dart`: `_RrIntervals`.
  - Texte `summaryRrIntervals`, `summaryRrCurve`, `summaryRmssd` aus beiden ARB-Dateien, `make l10n`.
- **Tests**: Protokoll-Tests, `session_heart_rate_test.dart`, `live_screen_test.dart`, `session_summary_screen_test.dart`, Migrationstest 12 → 13.
- **Doku**: README, Abschnitte Pulsgurt und Exportformat; Zweck der Spec `heart-rate-monitor`.
