# Tasks

Setzt `template-screen` in `main` voraus (Ghost-Wahl in der Aufnahme, Ghost-Zeile). Neue Texte nur über `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb` mit `@`-Beschreibung, danach `make l10n`; der generierte Code wird committet.

## 1. Plan statt Vorlage

- [x] 1.1 `SessionPlan` und `PlanLength` (`LapCount`, `TimeLimit`, `OpenLength`) nach D1, `SessionTemplate.toPlan()`; Recorder `start(plan:, ghost:)`, `ActiveRecording.plan`, `SessionRepository.create(plan:)`, `startRowing(..., plan:)`, `LiveScreen`, Ghost-Keys mit nullable `templateId` (D5). Noch ohne Dauer und ohne neuen Screen. Verifikation: alle bestehenden Tests grün ohne inhaltliche Änderung; neuer Recorder-Test: Plan ohne Vorlage legt eine Session mit `course_version_id`, `planned_laps` und ohne `template_id` an

## 2. Daten

- [x] 2.1 Schema 10 nach D3: `sessions.planned_duration_ms`, `from9To10`, `make schema`, `make codegen`; `create(plan:)` speichert die Dauer. Verifikation: generierter Migrationstest 9 → 10, Repository-Test mit `TimeLimit(30 min)`
- [x] 2.2 Export und Import mit `durationMs` im Block `template` (D3). Verifikation: Export/Import-Test mit Dauer und ohne Vorlage ergibt dieselbe Dauer, dieselben Runden und keinen Vorlagennamen; ein Header ohne `durationMs` (Stand Schema 9) importiert unverändert, in `session_export_test.dart`

## 3. Ende nach Dauer

- [x] 3.1 `SessionAccumulator.plannedDuration`, `planFinished`, Recorder beendet über `_finishAfterPlan` (D2). Verifikation: Unit-Tests: Ende beim ersten Datenpunkt mit Ruderzeit ≥ Dauer; 2 min Pause verschieben das Ende um 2 min; Ende mitten in der Runde speichert sie unvollständig; Zeitstrecke 4 min × 30 min ergibt 7 vollständige Runden und eine unvollständige; mit `Laps` und `OpenLength` endet alles wie bisher
- [x] 3.2 Ranglisten mit Sessions ohne Vorlage. Verifikation: Ranking-Test: vollständige Runden und Zonenfahrten einer Session ohne Vorlage stehen in den Ranglisten von Strecke und Zone, die unvollständige letzte Runde nicht

## 4. Live-Display

- [x] 4.1 Äusserer Ring und verbleibende Zeit bei Dauer, Runde ohne Gesamtzahl (D4). Verifikation: Unit-Tests von `ProgressFrameModel` (halbe Dauer = halber Ring, keine Rundengrenzen); Golden des Rahmens mit Dauer; Widget-Test: „15:00“ verbleibend und „Runde 3“; Overflow-Test bei 390 px hoch und quer
- [x] 4.2 Ghost ohne Vorlage (D5). Verifikation: Test in `live_screen_test.dart` („with ghosts“): ohne Vorlage mit Ghost läuft der Runden-Ghost, kein Ghost auf der Streckenspur, keine Abstandszeile; mit ausgeschaltetem Ghost keiner

## 5. Start-Screen

- [ ] 5.1 Button „Rudern“ in `CourseDetailScreen` und `CourseStartScreen` nach D6: Segmentbalken, Länge, drei Optionen, Rundenzahl, Dauer, offen, Ghost-Zeile, „Starten“. Verifikation: neue `test/features/courses/course_start_screen_test.dart`: „Rudern“ öffnet den Screen, Zurück zur Detailansicht; beim Öffnen „Runden“ mit 3; nur die gewählte Eingabe sichtbar; Werte bleiben beim Wechseln; Grenzen 1 Runde, 1 min und 180 min gesperrt; 90 min als „1:30:00“; „Starten“ mit 30 min startet eine Session mit `TimeLimit` und legt keine Vorlage an; erneutes Öffnen zeigt wieder die Vorgaben; Ghost aus startet ohne Ghost; deutsche und englische Texte; Overflow-Test bei 390 px und quer

## 6. Titel

- [ ] 6.1 `planLabel` und Titel ohne Vorlage in Session-Liste, Zusammenfassung und Health Connect (D7). Verifikation: Widget-Tests: Liste und Zusammenfassung zeigen „Seerunde · 30 min“, „Seerunde · 3 Runden“, „Seerunde · offen“, keine Platzmarke für eine Vorlage; Health-Export-Test nimmt den Streckennamen

## 7. Doku und Abschluss

- [ ] 7.1 README: Abschnitt zu Strecken um „Rudern“, den Start-Screen und die Gesamtdauer ergänzen. Verifikation: Abschnitt beschreibt Einstieg, drei Optionen, Pausen und Ende mitten in der Runde
- [ ] 7.2 Gesamtprüfung: `make check` grün; App unter Linux mit Simulator: „Seerunde“ 3 min mit Dauer rudern, eine Pause einlegen, Ende nach 3 min Ruderzeit, Zusammenfassung und Liste mit „· 3 min“, keine neue Vorlage
- [ ] 7.3 Test am Gerät (Nutzer): eine Strecke mit Dauer am Rudergerät rudern, Ende und Titel prüfen

## Workflow follow-up

- Erst nach `ghost` und `template-screen` archivieren.
