# Design

## Context

- `WorkoutEditorScreen` (`lib/features/workouts/workout_editor_screen.dart`) hält `_courses` und `_length` im State. `_save` prüft Name und Strecken, schreibt über `WorkoutRepository` und schliesst den Editor. Unten steht ein `FilledButton` „Speichern“.
- `SessionPlan(courses:, length:, workout:)` kennt schon Pläne ohne Workout mit mehreren Strecken; die Aufzeichnung schreibt die Strecken nach `session_courses`.
- `startRowing(context, ref, plan:, ghost:)` (`lib/features/connection/rower_connection.dart`) verbindet das gewählte Rudergerät, öffnet sonst die Geräteauswahl, und legt den `LiveScreen` auf den Navigator. Der Strecken-Startscreen nutzt ihn genauso.
- Liste und Zusammenfassung benennen eine Session ohne Workout über `sessionName` mit dem Namen der Kette (`Course.chain(courses).name`, „A + B + C“) und der geplanten Länge.
- Der Ghost wählt bei einer Kette ohne Workout keinen Rundenghost und ohne Workout keinen äusseren Ghost; bei einer einzelnen Strecke den Ghost der Strecke.

## Goals / Non-Goals

**Goals:**
- Eine Kette einmal rudern, ohne ein Workout anzulegen.
- Keine Änderung an Aufzeichnung, Ranglisten oder Datenbank.

**Non-Goals:**
- Ghost-Schalter im Editor, eigener Einstieg in der Workout-Liste, Name für die Session.

## Decisions

**D1: Zweiter Knopf im Editor.** Unter „Speichern“ ein `OutlinedButton` „Starten ohne Speichern“ (Key `workout-start-unsaved`). Er prüft nur, ob Strecken gewählt sind (Fehler wie bisher `workoutCourseMissing` in `_errors`), baut `SessionPlan(courses: _courses, length: _length)` ohne `workout` und ruft `startRowing(context, ref, plan: plan)` mit eingeschaltetem Ghost.

Alternative: der Knopf in der App-Leiste. Verworfen, weil „Speichern“ dort schon als Symbol steht und zwei Symbole schwer zu unterscheiden sind.

**D2: Der Editor bleibt offen.** `startRowing` legt den Live-Screen über den Editor. „Fertig“ in der Zusammenfassung und Zurück im Live-Screen führen sonst zum Startbildschirm (`popUntil(isFirst)`) und würden den Editor schliessen; deshalb gibt `startRowing(returnHere: true)` dem `LiveScreen` die Route des Editors als `backTo` mit, und beide kehren dorthin zurück. Der State mit Strecken und Länge ist danach unverändert. Nichts wird gespeichert, bis der Nutzer „Speichern“ tippt. Workout- und Strecken-Startscreen führen weiter zum Startbildschirm.

**D3: Aktuelle Version der Strecken.** `_courses` hält die Strecken so, wie sie beim Öffnen bzw. Wählen geladen wurden. Vor dem Start werden sie über `CourseRepository.get` neu gelesen, damit eine inzwischen bearbeitete Strecke in ihrer aktuellen Version gerudert wird; eine gelöschte Strecke fällt dabei weg, und ohne Strecken startet nichts.

## Risks / Trade-offs

- Wer nach dem Rudern „Speichern“ vergisst, hat kein Workout → beabsichtigt; der Editor zeigt den Stand weiter an, bis er verlassen wird.
- Ein eingegebener Name geht für die Session verloren → bewusst einfach gehalten; die Kette benennt die Session eindeutig genug.
