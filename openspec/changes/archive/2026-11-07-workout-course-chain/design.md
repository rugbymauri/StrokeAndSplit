# Design

## Context

- `Workout` (`lib/data/workouts/workout.dart`) hat genau eine `Course` und `laps` (null = offen). Gespeichert ist das in `workouts` und `workout_blocks` (`workout_id`, `position`, `course_id`, `laps`); die App schreibt und liest heute nur `position = 0`.
- `SessionPlan` (`lib/data/sessions/session_plan.dart`) trägt eine `course` und eine `PlanLength` (`LapCount`, `TimeLimit`, `OpenLength`). `Workout.toPlan()` kennt nur `LapCount` und `OpenLength`; `TimeLimit` gibt es nur beim direkten Rudern einer Strecke (`course-rowing-free`).
- Der `LapTracker` (`lib/data/courses/lap_tracker.dart`) folgt einer `CourseDefinition` (Achse, Länge, Segmente). Er kennt keine Strecke, nur Segmentgrenzen. Runden und Segmente landen in `laps` und `lap_segments` (`position` = Index des Segments in der Runde).
- `sessions.course_version_id` verknüpft eine Session mit genau einer Streckenversion. Davon hängen ab: die Ranglisten in `ranking_repository.dart` (Strecke über `laps`, Zone über `lap_segments` + `course_segments.position`, Workout über `workout_blocks` + `planned_laps`), `session_places.dart`, Session-Liste, Zusammenfassung (`plan_label.dart`), Export/Import in `session_repository.dart` (Schlüssel `course`).
- Der Workout-Editor wählt die Strecke über ein Dropdown, die Rundenzahl über einen Stepper mit Schalter „offen“. Der Start-Screen einer Strecke (`course-session-setup`) hat schon die Auswahl Runden/Dauer/offen.

## Goals / Non-Goals

**Goals:**
- Der `LapTracker`, die Zonenauswertung und der Fortschrittsrahmen bleiben unverändert und laufen über eine zusammengesetzte `CourseDefinition`.
- Sessions und Workouts mit einer Strecke rechnen nach der Migration genau dieselben Werte und Ranglisten wie vorher.

**Non-Goals:**
- Kein neuer Ring im Fortschrittsrahmen für die aktuelle Strecke. Streckengrenzen sind Abschnittsgrenzen und erscheinen als Kerben auf der Rundenspur.
- Keine Rangliste für Workouts mit Dauer.

## Decisions

### D1: Länge ins Workout, Bausteine nur noch Strecken

`workouts` bekommt `laps` (int, nullable) und `duration_s` (int, nullable). Beide null heisst offen; beide gesetzt kommt nicht vor. `workout_blocks` behält `workout_id`, `position`, `course_id` und verliert `laps`. `Workout` wird zu `{id, name, courses: List<Course>, length: PlanLength}` und nutzt dieselbe `PlanLength` wie `SessionPlan`.

Alternative: `laps` pro Baustein behalten und nur den ersten lesen. Verworfen, weil die Länge laut Entscheidung des Nutzers für das ganze Workout gilt und ein toter Wert pro Baustein irreführt.

### D2: `SessionPlan` mit einer Liste von Strecken

`SessionPlan.course` wird zu `courses: List<Course>` (mindestens eine, alle mit derselben Achse). Neu ist `SessionPlan.definition`: die Segmente aller Strecken hintereinander, Länge als Summe. Dazu `courseStarts`, der Index des ersten Segments jeder Strecke. Recorder, `LapTracker`, Ghost-Fortschritt und `ProgressFrameModel` arbeiten mit `definition`. Das direkte Rudern einer Strecke ist ein Plan mit einer Strecke.

Alternative: der Tracker wechselt die Strecke an der Grenze. Verworfen, weil dann Rundengrenze, Interpolation und Zonenanteil doppelt gelöst würden. Mit einer zusammengesetzten Definition ist die Streckengrenze eine gewöhnliche Segmentgrenze und wird schon exakt interpoliert.

### D3: Tabelle `session_courses` ersetzt `sessions.course_version_id`

Neue Tabelle `session_courses(session_id, position, course_version_id, first_segment)`, Primärschlüssel `(session_id, position)`, Löschung kaskadiert mit der Session. `first_segment` ist der Index des ersten Segments dieser Strecke innerhalb der Runde und wird beim Start gespeichert, damit SQL ein `lap_segments.position` ohne Rechnung einer Streckenversion und ihrem `course_segments.position` zuordnen kann (`cs.position = ls.position - sc.first_segment`). Die Migration kopiert jede vorhandene `course_version_id` als `position 0, first_segment 0` und entfernt danach die Spalte.

Alternative: `course_version_id` für die erste Strecke behalten und nur weitere in der neuen Tabelle. Verworfen: zwei Quellen für dieselbe Frage und jede Abfrage bräuchte beide Wege.

### D4: Ranglisten

- **Strecke**: Einträge aus zwei Quellen, vereint. Sessions mit genau einer Strecke liefern wie heute ihre vollständigen Runden aus `laps`, damit alte Werte bitgenau gleich bleiben. Sessions mit mehreren Strecken liefern pro Runde und Strecke eine Fahrt aus `lap_segments`: Summe von Dauer und Distanz der Segmente `[first_segment, first_segment + n)`, Beginn aus Rundenbeginn plus vorherige Segmente (wie heute bei der Zone, dort D5). Eine Fahrt ist vollständig, wenn die Runde vollständig ist oder die Runde ein späteres Segment hat.
- **Zone**: Der Join auf `course_segments` läuft über `session_courses` mit der Verschiebung aus D3. Sonst unverändert.
- **Workout**: Gruppiert nach der Folge der Streckenlängen (in SQL als `group_concat` der Versionslängen nach `position`) und `planned_laps`. Die aktuelle Gruppe ergibt sich aus den neuesten Versionen der Strecken in `workout_blocks`. Workouts ohne `laps` haben keine Rangliste.
- `session_places.dart` folgt denselben Joins.

### D5: Ghost der Rundenspur bei mehreren Strecken

Bei einer Strecke bleibt der Ghost der Rundenspur Platz 1 der Strecke. Bei mehreren Strecken liefert eine neue Abfrage `RankingRepository.workoutLaps(workoutId)` die vollständigen Runden früherer gezählter Sessions dieses Workouts mit derselben Folge der Streckenlängen, die schnellste wird Ghost. Die Ghost-Wahl (`liveGhostsKey` und Umgebung) entscheidet anhand von `plan.courses.length`.

Alternative: den Ghost aus den besten Fahrten jeder Strecke zusammensetzen. Verworfen: ergibt eine Runde, die nie jemand gerudert hat, und braucht eine eigene Zeitachse pro Teilstück.

### D6: Aktuelle Strecke im Live-Display

`ActiveRecording` meldet zusätzlich den Index der aktuellen Strecke, abgeleitet aus dem aktuellen Segment und `courseStarts`. Das Live-Display zeigt den Namen nur, wenn `plan.courses.length > 1`.

### D7: Export und Import

Der Export schreibt `courses: [ … ]` mit je einer Strecke im heutigen Format, ergänzt um `firstSegment`. Der Import liest `courses` und fällt auf `course` (eine Strecke, `firstSegment 0`) zurück. Fehlende Strecken legt er wie heute in der gespeicherten Version an.

### D8: Editor

Der Workout-Editor ersetzt das Dropdown durch eine Liste der Strecken mit Karten (Name, Länge, Zonenstreifen aus `course_strip.dart`), Knöpfen hoch/runter und Entfernen sowie „Strecke anhängen“. Das Anhängen öffnet eine Auswahl, die nur Strecken der Achse der ersten zeigt; bei einer einzigen Strecke alle. Die Länge nutzt die Auswahl Runden/Dauer/offen des Start-Screens, die dafür in ein gemeinsames Widget wandert. Das bisherige Dropdown mit dem Überlauf bei langen Zonennamen fällt damit weg.

### D9: Strecke löschen

`CourseRepository.delete` entfernt die Bausteine der Strecke, nummeriert die übrigen Bausteine jedes betroffenen Workouts lückenlos neu und löscht Workouts ohne Baustein. Der Bestätigungsdialog nennt nur Workouts, die keine Strecke mehr hätten.

### D10: Schema 12

Ein Migrationsschritt `from11To12`:
1. `workouts.laps` und `workouts.duration_s` anlegen, `laps` aus dem Baustein `position 0` übernehmen.
2. `workout_blocks.laps` entfernen (`alterTable` mit `TableMigration`).
3. `session_courses` anlegen und aus `sessions.course_version_id` füllen.
4. `sessions.course_version_id` entfernen (`alterTable`).

Der Migrationstest legt in v11 Workouts mit offener und fester Rundenzahl sowie Sessions mit und ohne Strecke an und prüft Werte, Kaskaden und Ranglisten danach.

## Risks / Trade-offs

- [Drift `alterTable` baut Tabellen mit Fremdschlüsseln neu auf] → Im Migrationstest Fremdschlüssel prüfen (`PRAGMA foreign_key_check`) und die Kaskade Workout → Bausteine sowie Session → Strecken testen.
- [Fahrten aus `lap_segments` weichen um Rundungen von `laps` ab] → Für Sessions mit einer Strecke bleibt `laps` die Quelle (D4); ein Test vergleicht beide Wege an einer Kette mit einer Strecke.
- [Ob die angefangene Runde ihre letzten Segmente speichert, entscheidet über die Vollständigkeit einer Fahrt] → Test „Abbruch in der letzten Strecke“ gegen gespeicherte Daten, nicht nur gegen den Tracker.
- [Schema-Snapshot passt nicht zum finalen Stand, wie bei Schema 11] → `make check-generated` vor jedem Push laufen lassen, Snapshot erst nach dem letzten Getter-Rename erzeugen.
- [Viele SQL-Stellen hängen an `course_version_id`] → Nach der Migration darf `course_version_id` nirgends mehr vorkommen; `grep` als Teil der Aufgaben.

## Migration Plan

Die Migration läuft beim ersten Start nach dem Update. Ein Rückweg auf Schema 11 ist nicht vorgesehen (wie bei früheren Schemaänderungen). Exportdateien älterer Versionen bleiben über den Rückfall auf `course` importierbar; neue Exportdateien kann eine ältere App nicht lesen.

Nach dem Archivieren den Purpose von `openspec/specs/workouts/spec.md` an mehrere Strecken und Runden/Dauer/offen anpassen.
