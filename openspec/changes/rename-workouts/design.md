# Design

## Context

Der Begriff steckt an vier Arten von Stellen: in den sichtbaren Texten (DE und EN), in Bezeichnern des Codes (Ordner `templates`, Klassen wie `SessionTemplate`, `TemplateRepository`, Provider, l10n-Keys, Widget-Keys), in gespeicherten Daten (Tabellen und Spalten der Datenbank, Schlüssel `template` in exportierten Session-Dateien) und in Doku und Specs. Nur die gespeicherten Daten betreffen bestehende Installationen.

Für Health Connect gibt es schon die Klasse `HealthWorkout`. Die englischen Texte zu Health Connect sprechen von „workouts“.

## Goals / Non-Goals

**Goals:**

- Der Nutzer liest überall „Workout“, nirgends mehr „Vorlage“ oder „Template“.
- Code, Datenbank und Specs verwenden denselben Begriff, damit kein Übersetzen zwischen Oberfläche und Code nötig ist.
- Bestehende Workouts, Sessions und exportierte Dateien bleiben nutzbar.

**Non-Goals:**

- Verhalten ändern. Es wird nur umbenannt.
- Archivierte Changes, alte Schema-Snapshots unter `drift_schemas/` und Test-Fixtures mit altem Format anpassen. Sie halten den Stand von damals fest; die Fixtures belegen zudem, dass alte Dateien weiter importiert werden.

## Decisions

### D1: Begriffe in der Oberfläche

| Bisher | Neu (DE) | Neu (EN) |
|---|---|---|
| Vorlage / Vorlagen | das Workout / die Workouts | Workout / Workouts |
| „Vorlage rudern“ (Titel) | „Workout rudern“ | „Row a workout“ |
| Tab „Vorlagen“ | „Workouts“ | „Workouts“ |
| „Vorlage anlegen“, „Neue Vorlage“, „Vorlage bearbeiten“, „Vorlage löschen?“ | „Workout anlegen“, „Neues Workout“, „Workout bearbeiten“, „Workout löschen?“ | „Create workout“, „New workout“, „Edit workout“, „Delete workout?“ |
| „Platz {place} der Vorlage“ | „Platz {place} des Workouts“ | „Place {place} in the workout“ |
| zusammengesetzte Wörter („Vorlagenliste“) | mit Bindestrich („Workout-Liste“) | – |

„Workout“ ist im Deutschen sächlich, Artikel und Pronomen ändern sich mit. Die englischen Texte richten sich nach der Wortwahl, die die bestehenden englischen Texte schon haben; die Tabelle gibt nur die Richtung vor.

### D2: Health Connect

Die englischen Health-Connect-Texte nennen die übertragenen Einträge „exercise sessions“, wie Health Connect selbst sie nennt. Sonst stünden in derselben App „Workouts“, die man plant, neben „workouts“, die nach Health Connect gehen. Im Deutschen heissen sie schon „Trainingseinheiten“ bzw. „Einheiten“ und bleiben so.

Im Code wird `HealthWorkout` zu `HealthExercise` und `healthWorkoutOf` zu `healthExerciseOf`, Datei `health_workout.dart` zu `health_exercise.dart`. Das Feld `templateName` darin heisst `workoutName`.

*Alternative*: `HealthWorkout` behalten und nur das Feld umbenennen. Verworfen, weil dann `HealthWorkout.workoutName` zwei verschiedene Bedeutungen von „Workout“ in einer Zeile vereint.

### D3: Bezeichner im Code

`template` wird zu `workout` in jeder Schreibweise: `templates` → `workouts`, `Template` → `Workout`, `TEMPLATE` → `WORKOUT`, Ordner `lib/data/templates` → `lib/data/workouts`, `lib/features/templates` → `lib/features/workouts`, ebenso unter `test/`. `SessionTemplate` heisst nur noch `Workout`, die Datei `session_template.dart` wird `workout.dart`. l10n-Keys (`templatesTitle` → `workoutsTitle` …) und Widget-Keys (`Key('template-…')` → `Key('workout-…')`) folgen derselben Regel.

Ausnahmen: Flutter- und Drift-APIs, die selbst „template“ heissen, falls vorhanden, und Kommentare, die auf archivierte Changes verweisen.

Die Umbenennung läuft als ein mechanischer Commit (`git mv` plus Ersetzen), getrennt von den Text-, Datenbank- und Exportänderungen, damit der Diff überprüfbar bleibt.

### D4: Datenbank

Schemaversion 11 benennt um, ohne Daten zu kopieren:

- Tabelle `templates` → `workouts`, `template_blocks` → `workout_blocks`
- Spalte `template_blocks.template_id` → `workout_blocks.workout_id`
- Spalten `sessions.template_id` → `workout_id`, `sessions.template_name` → `workout_name`

Die Migration nutzt `renameTable` und `renameColumn` von Drift (`ALTER TABLE … RENAME`). SQLite passt dabei die Fremdschlüssel anderer Tabellen auf die umbenannte Tabelle an. Ein neuer Snapshot `drift_schema_v11.json` und der erzeugte Migrationstest (`make schema`) belegen den Schritt von 10 auf 11 mit Daten.

*Alternative*: Tabellen behalten und nur die Dart-Namen über `tableName`/`named` umbiegen. Verworfen: Der Nutzer will alles umbenannt, und eine Abweichung zwischen Dart-Namen und Tabellennamen fällt beim Debuggen der Datenbank immer wieder auf.

### D5: Session-Dateien

Der Export schreibt Name, Runden und Dauer des Workouts unter dem Schlüssel `workout`. Der Import liest `workout` und, wenn das fehlt, `template`. Der Formatname `strokesplit-raw` bleibt, das Format ändert sich nur um diesen Schlüssel, und ältere App-Versionen lesen eine neue Datei weiterhin, nur ohne Workout-Namen.

### D6: Specs

OpenSpec kann eine Capability nicht umbenennen. Die sechs Anforderungen von `session-templates` stehen deshalb als ADDED in der neuen Capability `workouts` und als REMOVED in `session-templates`. Beim Archivieren entfällt `session-templates`.

Die übrigen Specs bekommen MODIFIED-Blöcke, umbenannte Anforderungen zusätzlich einen RENAMED-Eintrag. Szenarien lassen sich in einem MODIFIED-Block nicht umbenennen. Deren Titel behalten in den Deltas „Vorlage“ und werden nach dem Archivieren direkt in den Haupt-Specs umbenannt (siehe „Workflow follow-up“ in `tasks.md`).

### D7: Reihenfolge

1. Datenbank (Schema 11) mit Migrationstest.
2. Mechanischer Rename im Code, inklusive Tests.
3. Texte DE/EN, inklusive Health Connect.
4. Export und Import.
5. README, Implementierungsplan.

## Risks / Trade-offs

- **Migration auf dem Handy**: Schlägt die Umbenennung fehl, startet die App nicht. Der erzeugte Migrationstest prüft den Schritt mit Daten; zusätzlich prüft der Nutzer die Migration auf dem Handy mit seinen echten Daten.
- **Grösse des Diffs**: Der mechanische Commit berührt rund 50 Dateien. Er enthält nur Umbenennungen, die Verhaltensänderungen liegen in eigenen Commits.
- **Ältere App-Versionen**: Eine Datenbank mit Schema 11 lässt sich nicht mehr mit einer älteren Version öffnen. Das gilt für jede Schemaänderung und betrifft nur ein Downgrade.
