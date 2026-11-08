# Proposal

## Why

Wer eine Kombination von Strecken nur einmal rudern will, muss sie heute als Workout speichern und danach wieder löschen. Eine einzelne Strecke lässt sich schon ohne Workout rudern, eine Kette aus mehreren Strecken nicht. Der Workout-Editor soll deshalb das Zusammengestellte auch direkt starten können, ohne es zu speichern.

## What Changes

- **„Starten ohne Speichern“ im Workout-Editor**: neben „Speichern“ ein zweiter Knopf. Er startet die zusammengestellten Strecken mit der gewählten Länge (Runden, Dauer oder offen) sofort, ohne ein Workout anzulegen oder zu ändern.
- **Name nicht nötig**: Für „Starten ohne Speichern“ braucht es nur mindestens eine Strecke. Ein eingegebener Name wird nicht verwendet.
- **Auch beim Bearbeiten**: Im Editor eines bestehenden Workouts startet der Knopf den geänderten Stand, das gespeicherte Workout bleibt unverändert.
- **Zurück im Editor**: Nach der Session kommt der Nutzer in den Editor zurück, mit allem, was er eingestellt hatte; er kann es dann noch speichern.
- **Session wie eine Strecke ohne Workout**: Die Session gehört zu keinem Workout. Liste und Zusammenfassung nennen die Strecken und die Länge, z. B. „Einrudern + 2 km Intervall + Ausrudern · 1 Runde“. Sie zählt in den Ranglisten der Strecken und Zonen, aber in keiner Workout-Rangliste. Der Ghost läuft wie beim Rudern einer Strecke ohne Workout.

Nicht Teil dieses Changes:

- Ein Schalter für den Ghost im Editor; er ist eingeschaltet wie beim Start eines Workouts.
- Ein eigener Einstieg „Adhoc rudern“ in der Workout-Liste.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `workouts`: neue Requirement „Workout ohne Speichern rudern“.

## Impact

- **Code**:
  - `lib/features/workouts/workout_editor_screen.dart`: Knopf „Starten ohne Speichern“, Prüfung nur auf Strecken, Start über `startRowing` mit einem `SessionPlan` ohne Workout.
  - Neuer Text für den Knopf in `lib/l10n/app_de.arb` und `app_en.arb`.
  - Aufzeichnung, Ranglisten, Ghost, Liste und Zusammenfassung brauchen keine Änderung: sie kennen Sessions ohne Workout mit mehreren Strecken schon.
- **Tests**: `workout_editor_screen_test.dart`, eine Aufzeichnung ohne Workout mit drei Strecken.
- **Doku**: README, Abschnitt Workouts.
- **Daten**: keine Schema-Änderung.
