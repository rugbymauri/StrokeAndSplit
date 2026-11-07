## RENAMED Requirements

- FROM: `### Requirement: Starten ohne Vorlage`
- TO: `### Requirement: Starten ohne Workout`

## MODIFIED Requirements

### Requirement: Starten ohne Workout
„Starten“ SHALL eine Session auf der Strecke mit der gewählten Option beginnen, mit derselben Verbindung wie beim Start eines Workouts. Dabei MUST NOT ein Workout angelegt werden. Die Wahl auf dem Start-Screen MUST NOT gespeichert werden; jedes Öffnen beginnt mit den Vorgaben.

#### Scenario: 30 min auf der Seerunde
- **WHEN** der Nutzer auf dem Start-Screen von „Seerunde“ „Dauer“ mit 30 min wählt und „Starten“ antippt
- **THEN** läuft eine Session auf „Seerunde“, die nach 30 min Ruderzeit endet, und die Workout-Liste bleibt unverändert

#### Scenario: Erneut öffnen
- **WHEN** der Nutzer nach einer Session mit 45 min den Start-Screen wieder öffnet
- **THEN** ist „Runden“ mit 3 gewählt
