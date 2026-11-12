# Design

## Context

- `HeartRateMeasurement.parse` (`packages/erg_protocol/lib/src/heart_rate/`) liest Puls, Energie und RR-Angaben einer Gurt-Messung. `HeartRateDecoder` setzt den Puls in jeden `StatusTick` und macht aus den RR-Angaben ein `HeartBeatIntervals`-Ereignis. `HeartRateEncoder` erzeugt Messungen mit RR-Angaben für Tests; `pm5_to_ftms.dart` reicht `HeartBeatIntervals` beim Umschreiben von Mitschnitten durch.
- `LiveScreen` merkt sich das letzte `HeartBeatIntervals` (`_beats`) und gibt das letzte Intervall als `rrIntervalMs` an `LiveFree` und `LiveCourse`; `formatRrInterval` formatiert es.
- `SessionAccumulator` sammelt die Intervalle als `RrIntervalsCompanion`, `SessionRepository` schreibt sie in `rr_intervals`, berechnet beim Abschluss `rmssd` und legt es in `sessions.rmssd_ms` ab, liefert sie über `rrIntervals(id)` an `sessionRrIntervalsProvider` und schreibt `rmssdMs` in den Export-Header.
- `SessionSummaryScreen` zeigt `_RrIntervals` (Kurve und RMSSD).
- Tabelle und Spalte kamen mit Schema 6 (`from5To6`); das aktuelle Schema ist 12.

## Goals / Non-Goals

**Goals:**
- Jede Spur der RR-Intervalle in App, Datenbank und Protokoll-Paket entfernen, ohne Puls, Replay, Export oder Import zu verändern.

**Non-Goals:**
- Die Rohpakete des Gurts aus Aufzeichnung oder Export entfernen; sie tragen den Puls.
- Alte Mitschnitte oder Fixtures umschreiben.

## Decisions

**D1: Die Messung liest RR-Angaben weiter, gibt sie aber nicht heraus.** `HeartRateMeasurement` behält die Prüfung, dass die Messung so lang ist, wie ihre Flags angeben, einschliesslich der RR-Angaben; das Feld `intervalsMs` entfällt. So bleibt „Gurt-Messungen tolerant lesen“ unverändert: eine abgeschnittene Messung mit RR-Flag wird weiter verworfen.

Alternative: RR-Bytes gar nicht mehr ansehen. Verworfen, weil eine abgeschnittene Messung dann als gültig durchginge.

**D2: `HeartBeatIntervals` verschwindet aus `RowingEvent`.** Das Ereignis hat ohne RR keinen Inhalt mehr. `HeartRateDecoder` liefert nur noch die `StatusTick`s mit dem Puls; das Merken von `_lastElapsed` für die Intervalle entfällt. `HeartRateEncoder` verliert den RR-Parameter und schreibt nur noch den Puls. Die Fälle in `pm5_to_ftms.dart`, `SessionAccumulator` und `LiveScreen` fallen weg; der Compiler findet jede Stelle über den `switch` auf dem versiegelten `RowingEvent`.

**D3: Schema 13 löscht Tabelle und Spalte.** `from12To13` löscht `rr_intervals` mit ihrem Index (`m.deleteTable`) und baut `sessions` per `m.alterTable(TableMigration(schema.sessions))` ohne `rmssd_ms` neu auf, wie schon `from11To12` beim Löschen einer Spalte. `make codegen schema` erzeugt Snapshot `drift_schema_v13.json` und Migrationstest-Gerüst; der Test prüft, dass eine Session mit RR-Intervallen und RMSSD aus Schema 12 mit allen übrigen Werten erhalten bleibt.

Alternative: Tabelle und Spalte stehen lassen und nur nicht mehr nutzen. Verworfen (Entscheid des Nutzers): tote Daten und Code, der mit der Spec auseinanderläuft.

**D4: Export ohne `rmssdMs`, Import ignoriert es.** Der Export-Header verliert das Feld. Der Import liest den Header schon heute nur für Metadaten und rechnet die Zusammenfassung aus den Rohpaketen neu; ein vorhandenes `rmssdMs` wird nicht mehr gelesen. Ein Test importiert eine Datei mit `rmssdMs` im Header.

**D5: Texte entfernen.** `summaryRrIntervals`, `summaryRrCurve` und `summaryRmssd` werden aus `app_de.arb` und `app_en.arb` gelöscht, danach `make l10n`.

## Risks / Trade-offs

- [Gespeicherte RR-Intervalle gehen verloren] → Sie stehen weiter in den Rohpaketen (`2a37`) jeder Session mit direkt verbundenem Gurt und im Export; eine spätere Auswertung könnte sie daraus neu berechnen.
- [Neubau von `sessions` bei der Migration] → Gleiches Vorgehen wie `from11To12`, abgesichert durch den generierten Migrationstest mit Daten.

## Migration Plan

Die Migration läuft beim ersten Start nach dem Update. Ein Zurück auf eine ältere Version ist wie bei jedem Schema-Sprung nicht vorgesehen.
