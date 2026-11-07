# Proposal

## Why

„Vorlage“ klingt nach Büro und passt nicht zum Sport. Gemeint ist ein geplantes Training: eine Strecke mit einer festen oder offenen Rundenzahl, die man mit einem Tippen startet. Am Ergometer heisst das „Workout“, so auch im Menü des PM5 („Select Workout“). Der Begriff grenzt sich ausserdem klar von den Sessions ab. Ein Workout ist das, was man vorhat, eine Session das, was man gerudert hat.

## What Changes

- **Sichtbare Texte**: Aus „Vorlage“ wird in der App überall „Workout“ (das Workout, die Workouts), auf Englisch aus „Template“ ebenfalls „Workout“. Das betrifft Startbildschirm, Titel und Tabs, Editor, Löschdialoge, Bestenliste, Live-Display und Zusammenfassung.
- **Health Connect**: Die englischen Texte nennen die übertragenen Einträge bisher „workouts“. Das kollidiert mit dem neuen Begriff, sie heissen deshalb „exercise sessions“. Im Deutschen heissen sie schon „Trainingseinheiten“ und „Einheiten“ und bleiben so.
- **Code**: Ordner, Dateien, Klassen, Provider, Keys und Testnamen wechseln von `template` auf `workout`. Damit der neue Name frei ist, heisst die Health-Connect-Klasse `HealthWorkout` künftig `HealthExercise`.
- **Datenbank**: Die Tabellen `templates` und `template_blocks` sowie die Spalten `sessions.template_id` und `sessions.template_name` werden umbenannt. Das ist Schemaversion 11, gespeicherte Workouts und Sessions bleiben erhalten.
- **Session-Dateien**: Der Export schreibt den Namen und die Runden des Workouts unter `workout` statt unter `template`. Der Import liest beide, damit bestehende Exporte gültig bleiben.
- **Specs und Doku**: Die Capability `session-templates` heisst künftig `workouts`. Alle Anforderungen, die „Vorlage“ nennen, sowie README und Implementierungsplan sprechen von Workouts.

Nicht Teil dieses Changes: archivierte Changes und die alten Schema-Snapshots unter `drift_schemas/`. Sie dokumentieren den Stand von damals und bleiben, wie sie sind.

## Capabilities

### New Capabilities

- `workouts`: Workouts anlegen, auflisten, bearbeiten, löschen, auf ihrem eigenen Screen öffnen und starten. Übernimmt die Anforderungen von `session-templates` unter dem neuen Begriff.

### Modified Capabilities

- `session-templates`: Alle Anforderungen wandern nach `workouts`, die Capability entfällt.
- `course-rowing`: Neben dem Begriff kommt ein Szenario dazu: Eine Session, die eine frühere Version mit Vorlage exportiert hat, lässt sich weiter importieren.
- `app-language`, `course-session-setup`, `courses`, `erg-connection`, `erg-simulation`, `ghost`, `health-export`, `live-display`, `number-steppers`, `resistance-control`, `session-recording`, `statistics`: Die Anforderungen, die „Vorlage“ nennen, sprechen von „Workout“. Das Verhalten bleibt gleich.

## Impact

- `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb` und der daraus erzeugte Code: Texte und Keys (`templatesTitle`, `tabTemplates`, `templateCreate` …).
- `lib/data/templates/` und `lib/features/templates/` sowie die Tests unter `test/data/templates/`, `test/features/templates/` und `test/support/template_setup.dart`: Ordner, Dateien und Bezeichner.
- Alle Stellen, die Workouts nutzen: Startbildschirm, Live-Display, Ghost, Statistik, Session-Liste und Zusammenfassung, Health-Export.
- `lib/data/db/database.dart`, `database.g.dart`, `database.steps.dart`, `drift_schemas/` (neuer Snapshot v11) und die erzeugten Migrationstests.
- `lib/data/sessions/session_repository.dart`: Export und Import der Metadaten.
- `lib/data/health/`: `HealthWorkout` → `HealthExercise`.
- `README.md`, `docs/implementation-plan.md`, `openspec/specs/`.
- Zeitpunkt: Es gibt keine offenen Branches, Konflikte sind also nicht zu erwarten.
