# Tasks

Neue Texte nur über `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb` mit `@`-Beschreibung, danach `make l10n`; der generierte Code wird committet.

## 1. Pausen erkennen

- [ ] 1.1 Detektor `AutoPause` in `lib/data/sessions/auto_pause.dart` nach D1: Pakete mit Wanduhr-Zeit und Ereignissen, zählende Schläge ohne nachgereichten Schlag, Rhythmus bis 6 s, Beginn bei Rhythmus + 3 s, Ende mit Schlag oder Wechsel auf „rudert“ ab dem Anstieg der Distanz, Sessionzeit, abgeschlossene Pausen. Verifikation: Unit-Tests für Pause nach 3 s über dem Rhythmus, keine Pause bei 16 Schlägen pro Minute, Fortsetzen beim Schlag, Fortsetzen beim Wechsel auf „rudert“, nachgereichter Schlag beendet keine Pause, Pause vor dem ersten Schlag, Sessionzeit läuft nie rückwärts; mit `pause.jsonl` (eine Pause, Ende beim Anstieg der Distanz), `just_row`, `force_curve` und `ftms_just_row` (keine Pause beim Rudern)

## 2. Schema und Speicherung

- [ ] 2.1 Schema 7 nach D2/D3: `samples.active_ms`, `sessions.pause_count`, `sessions.paused_ms`, Tabelle `pauses`; Migration `from6To7`, `make schema`, `make codegen`, Schema-Kommentar zu `laps.*_wall_ms`. Verifikation: generierter Migrationstest 6 → 7 und `test/data/db` grün
- [ ] 2.2 `SessionAccumulator` mit `AutoPause`: `progress` mit Sessionzeit, `paused`, `active_ms` pro Sample, `LapTracker` auf der Sessionzeit, abgeschlossene Pausen im Batch, laufende Pause beim `finish` verworfen. Verifikation: Unit-Tests für Samples mit Sessionzeit, Zeitstrecke und Distanzrunde ohne Pause, Zonenanteil ohne Pause, Pausen im Batch
- [ ] 2.3 `SessionRepository`: Pausen schreiben und löschen, `finish` mit Dauer aus `active_ms` und Pausen-Summen, Wiederherstellung und Ghost über `COALESCE(active_ms, wall_ms)`, Export-Kopf mit `pauseCount`/`pausedMs`. Verifikation: Unit-Tests für Zusammenfassung mit Pausen, Export/Import mit gleichen Pausen, Import von `just_row` und `reset` mit denselben Werten wie zuvor und ohne Pausen, Wiederherstellung einer Session vor Schema 7
- [ ] 2.4 Bestehende Tests an Sessionzeit und Pausen anpassen (Runden mit Pause, Zeitstrecke, Ghost, Ranglisten, End-to-End mit Simulator). Verifikation: `make test`

## 3. Recorder und Live-Display

- [ ] 3.1 `ActiveRecording.paused`, Recorder aktualisiert den Zustand bei Wechsel von Pause oder Fortschritt (D4). Verifikation: Unit-Test mit Simulator in Fake-Zeit: Pause nach dem Anhalten, Zeit steht, weiter mit dem nächsten Schlag
- [ ] 3.2 Text `livePaused` („Pause“ / „Paused“) mit `@`-Beschreibung, `make l10n`; Widget `PauseHint` in `lib/features/live/pause_hint.dart`, in `LiveScreen` mit einer Zeile eingebunden. Verifikation: Widget-Test, Hinweis sichtbar in der Pause und weg nach dem nächsten Schlag; `test/l10n/arb_keys_test.dart`

## 4. Zusammenfassung und Ranglisten

- [ ] 4.1 Kachel mit Anzahl und Dauer der Pausen in der Zusammenfassung, nur bei Pausen (Text `summaryPauses` mit Plural). Verifikation: Widget-Test mit und ohne Pausen
- [ ] 4.2 Hinweis unter den Ranglisten (`rankingPausesHint`) und Beschreibungen der Pace-Texte an D5 anpassen. Verifikation: bestehende Widget-Tests der Ranglisten grün

## 5. Abschluss

- [ ] 5.1 `make check` grün und `openspec validate --all --strict` grün
- [ ] 5.2 Manueller Gerätetest mit PM5 und einem FTMS-Rudergerät: frei und mit Vorlage rudern, anhalten (Pause nach etwa 3 s über dem Rhythmus, „Pause“ sichtbar, Zeit, Restzeit und Ghost stehen), weiterrudern (weiter ab dem Stand vor der Pause), langsam mit 16–18 Schlägen pro Minute rudern ohne Pause, Zusammenfassung mit Pausen, Export und Import
