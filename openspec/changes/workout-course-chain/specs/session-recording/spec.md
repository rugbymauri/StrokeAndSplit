## MODIFIED Requirements

### Requirement: Session eines Workouts zuordnen
Eine Session, die mit einem Workout gestartet wurde, SHALL mit dem Workout und den geruderten Versionen aller seiner Strecken in ihrer Reihenfolge verknüpft sein. Die Session-Liste MUST bei solchen Sessions den Namen des Workouts anzeigen. Bestehende Sessions MUST nach dem Update mit ihrer einen Strecke verknüpft bleiben.

#### Scenario: Liste mit Workout-Session
- **WHEN** der Nutzer die Session-Liste öffnet und eine Session mit dem Workout „Seerunde x3“ gerudert hat
- **THEN** zeigt der Eintrag „Seerunde x3“ zusätzlich zu Datum, Dauer, Distanz und Pace

#### Scenario: Workout später gelöscht
- **WHEN** das Workout einer Session gelöscht wurde
- **THEN** zeigt die Session weiterhin den Namen des Workouts und der Strecke, mit dem sie gerudert wurde

#### Scenario: Workout später geändert
- **WHEN** der Nutzer nach einer Session auf „Intervalltraining“ die Strecke „Ausrudern“ aus dem Workout entfernt
- **THEN** zeigt die alte Session weiterhin alle drei Strecken, mit denen sie gerudert wurde

#### Scenario: Session von vor dem Update
- **WHEN** der Nutzer nach dem Update eine Session öffnet, die vorher auf „Seerunde“ gerudert wurde
- **THEN** zeigt sie „Seerunde“ mit allen Runden wie vor dem Update
