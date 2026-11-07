# Tasks

Neue Texte nur über `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb` mit `@`-Beschreibung, danach `make l10n`.

## 1. Erste Bewegung erkennen

- [x] 1.1 Detektor in `lib/data/sessions/first_stroke.dart` nach D2: dekodiert Pakete, hält die Pakete des letzten Messwerts als Basis und liefert bei der ersten Bewegung die Pakete ab der Basis. Verifikation: Unit-Tests mit `just_row`, `force_curve`, `ftms_just_row` (Start beim ersten Schlag bzw. ersten Meter, Basis ist der letzte Leerlauf-Messwert), `pause` (alte Schlagzahl startet nicht) und `reset` (Reset macht den neuen Messwert zur Basis)

## 2. Recorder

- [x] 2.1 `SessionRecorder.start(template:)` geht in den Bereit-Zustand (D1): `ActiveRecording` ohne `sessionId`, Fortschritt 0, Stand eines frischen `LapTracker`. Bei der ersten Bewegung legt er die Session an und speist die Pakete ab der Basis in den Accumulator, Pakete während des Anlegens gepuffert. Freies Rudern startet unverändert sofort. Verifikation: Unit-Tests „bereit → Start bei erster Bewegung“, Nullpunkt (erster Sample 0:00 und 0 m, Distanz der Session gleich Distanz des Fixtures), Rohpakete beginnen mit der Basis
- [x] 2.2 `stop()` im Bereit-Zustand liefert `null` und speichert nichts. Verifikation: Unit-Test, keine Zeile in `sessions`
- [x] 2.3 Zeitabschnitt und Ghost-Zeit laufen erst ab dem Start. Verifikation: Unit-Test mit Zeitstrecke und Simulator in Fake-Zeit, Pause vor dem ersten Schlag
- [x] 2.4 Replay und Import: eine so aufgezeichnete Session ergibt beim Import dieselben Samples und Runden, und eine `ReplaySource` startet eine Vorlage beim ersten Schlag. Verifikation: Unit-Tests
- [x] 2.5 Bestehende Tests an den Bereit-Zustand anpassen (Recorder mit Vorlage, Ghost, Rangliste, End-to-End mit Simulator). Verifikation: `make check`

## 3. Live-Display

- [x] 3.1 Text `liveReadyForFirstStroke` („Bereit – startet mit dem ersten Schlag“ / „Ready – starts with your first stroke“) in beiden ARB-Dateien mit `@`-Beschreibung, `make l10n`. Verifikation: `test/l10n/arb_keys_test.dart`
- [x] 3.2 Widget `ReadyHint` in `lib/features/live/ready_hint.dart`, in `LiveScreen` mit wenigen Zeilen eingebunden, solange die Session bereit ist (D5). Verifikation: Widget-Test, Hinweis sichtbar nach der Wahl der Vorlage und verschwunden nach dem ersten Schlag
- [x] 3.3 Trennen im Bereit-Zustand speichert nichts. Verifikation: Widget-Test (Zurück, das wie der Trennen-Button trennt)

## 4. Abschluss

- [x] 4.1 `make check` grün und `openspec validate start-on-first-stroke --strict` grün
- [ ] 4.2 Manueller Gerätetest mit PM5: Vorlage wählen, warten (Hinweis, 0:00, Ghost am Start), erster Schlag startet Zeit und Distanz ab 0; Trennen vor dem ersten Schlag hinterlässt keine Session
