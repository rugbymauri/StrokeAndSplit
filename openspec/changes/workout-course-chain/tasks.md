# Tasks

Texte nur über `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb` mit `@`-Beschreibung ändern, danach `make l10n`; der generierte Code wird committet. Jede Gruppe endet mit grünem `make check` und `make check-generated`.

## 1. Datenbank

- [x] 1.1 Schema 12 nach D1, D3 und D10: `workouts.laps` und `workouts.duration_s`, `workout_blocks` ohne `laps`, neue Tabelle `session_courses`, `sessions` ohne `course_version_id`; Migrationsschritt `from11To12`; `make codegen` und `make schema` erst nach dem letzten Getter-Rename. Verifikation: Der erzeugte Migrationstest von 11 auf 12 ist grün. Ein zusätzlicher Test legt in Schema 11 Workouts mit 3 Runden und offen sowie Sessions mit und ohne Strecke an, migriert und findet Länge, Bausteine, `session_courses` (Position 0, `first_segment` 0) und die Kaskaden wieder; `PRAGMA foreign_key_check` ist leer.

## 2. Domäne und Rudern

- [x] 2.1 `Workout` mit `courses` und `PlanLength`, Repository liest und schreibt Bausteine und Länge (D1). Verifikation: Repository-Tests für Anlegen, Ändern (Strecke anhängen, verschieben, entfernen, Dauer setzen) und Löschen eines Workouts mit drei Strecken.
- [x] 2.2 `SessionPlan` mit `courses`, `definition` und `courseStarts` (D2); Recorder, `LapTracker`-Aufruf, Ghost-Fortschritt und `ProgressFrameModel` nutzen `definition`; `Workout.toPlan()` kennt alle drei Längen. Verifikation: Unit-Tests „Übergang zur nächsten Strecke“ (Segmentgrenze bei 500 m, keine neue Runde), „Runde über mehrere Strecken“ (Runde endet bei 3000 m) und „Workout mit Dauer“ (Ende nach 45 min Ruderzeit); bestehende Tests mit einer Strecke bleiben grün.
- [x] 2.3 Session speichert ihre Strecken in `session_courses` mit `first_segment` (D3); `course_version_id` kommt in `lib/` nicht mehr vor. Verifikation: Recorder-Test mit „Intervalltraining“ findet drei Zeilen in `session_courses` mit `first_segment` passend zu den Segmentzahlen; `grep -rn "courseVersionId\|course_version_id" lib --exclude=database.g.dart --exclude=database.steps.dart` findet nur noch alte Migrationsschritte.
- [ ] 2.4 Aktuelle Strecke in `ActiveRecording` und im Live-Display, nur bei mehreren Strecken (D6). Verifikation: Widget-Test zeigt bei 800 m in „Intervalltraining“ „2 km Intervall“ und bei „Seerunde x3“ keinen zusätzlichen Streckennamen.

## 3. Ranglisten und Ghost

- [ ] 3.1 Rangliste einer Strecke aus `laps` (eine Strecke) und aus `lap_segments` (Kette) nach D4. Verifikation: Tests „Strecke in einer Kette“ (Fahrt allein und in der Kette in derselben Rangliste), „Kette abgebrochen“ (gegen gespeicherte Daten einer mitten in „Ausrudern“ beendeten Session) und ein Vergleich, dass Sessions mit einer Strecke dieselben Werte wie vor dem Change liefern.
- [ ] 3.2 Rangliste einer Zone über `session_courses` und `first_segment` (D4). Verifikation: Test mit „Sprint“ in der zweiten Strecke einer Kette landet in der Rangliste von „Sprint“ mit richtiger Start- und Endzeit; bestehende Zonentests grün.
- [ ] 3.3 Rangliste eines Workouts nach Folge der Streckenlängen und Rundenzahl, keine bei Dauer oder offen (D4); `session_places.dart` angepasst. Verifikation: Tests „Strecke angehängt“ (eigene Rangliste) und „Workout mit Dauer“ (keine Plätze); bestehende Workout-Ranglisten-Tests grün.
- [ ] 3.4 Ghost der Rundenspur bei mehreren Strecken aus `workoutLaps` (D5). Verifikation: Tests „Runde über mehrere Strecken“ (Ghost erreicht das Rundenende nach der schnellsten früheren Runde) und „Kette erstmals gerudert“ (kein Ghost auf der Rundenspur); bei einer Strecke unverändert.

## 4. Export und Import

- [ ] 4.1 Export schreibt `courses` mit `firstSegment`, Import liest `courses` und als Rückfall `course` (D7). Verifikation: Repository-Tests: Export und Import einer Session auf „Intervalltraining“ in eine leere DB ergeben dieselben Runden und legen die drei Strecken an; eine Datei im bisherigen Format mit `course` (auch mit `template`) importiert wie vorher.

## 5. Oberfläche

- [ ] 5.1 Gemeinsames Widget für Runden/Dauer/offen aus dem Start-Screen der Strecke herauslösen (D8). Verifikation: bestehende Tests von `course-session-setup` grün.
- [ ] 5.2 Workout-Editor mit Streckenliste (anhängen, hoch/runter, entfernen, letzte nicht entfernbar), Auswahl nach Achse und Länge über das gemeinsame Widget (D8). Verifikation: Widget-Tests „Strecke anhängen“ (Runde 2500 m), „Nur gleiche Achse“, „Strecke verschieben“, „Letzte Strecke“, „Erste Strecke ersetzen“, „Dauer wählen“ und „Werte bleiben beim Wechseln“; der Editor passt in 400 × 400 ohne Überlauf, auch mit langen Zonennamen.
- [ ] 5.3 Workout-Liste, Workout-Screen, Session-Liste und Zusammenfassung zeigen die Strecken als „A + B + C“ und die Länge mit Runden, Dauer oder offen. Verifikation: Widget-Tests „Mehrere Strecken“ (Liste und Zusammenfassung), „Mehrere Strecken ansehen“ (Screen mit Strecken in Reihenfolge und Summe) und „Workout mit Dauer“ in der Liste („45:00“).
- [ ] 5.4 Strecke löschen nach D9: aus Ketten entfernen, Bausteine neu nummerieren, leere Workouts löschen; der Dialog nennt nur diese. Verifikation: Repository- und Widget-Tests „Strecke eines Workouts löschen“ und „Strecke aus einer Kette löschen“.

## 6. Doku und Prüfung

- [ ] 6.1 README (Abschnitt zu Zonen, Strecken und Workouts, Exportformat) und `docs/implementation-plan.md` beschreiben Workouts mit mehreren Strecken. Verifikation: Abschnitt gelesen; Plan nennt den Change als begonnen bzw. erledigt.
- [ ] 6.2 Gesamtprüfung in der Linux-App mit einer Scratch-DB in Schema 11: Migration läuft, alte Workouts und Sessions unverändert; ein Workout „Einrudern + 2 km Intervall + Ausrudern“ mit 1 Runde im Simulator rudern, Streckenname im Live-Display, Zusammenfassung und Ranglisten der Strecken prüfen. Verifikation: Screenshots der Schritte.
- [ ] 6.3 Am Handy (Nutzer): App aktualisieren, alte Workouts und Sessions sind da; ein Workout mit zwei Strecken und Dauer anlegen und rudern.

## Workflow follow-up

- Nach dem Archivieren den Purpose von `openspec/specs/workouts/spec.md` an mehrere Strecken und Runden/Dauer/offen anpassen.
