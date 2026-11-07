## MODIFIED Requirements

### Requirement: Strecke löschen
Der Nutzer SHALL eine Strecke nach Bestätigung löschen können. Eine gelöschte Strecke verschwindet aus der Streckenliste, aus der Auswahl für Workouts und aus allen Workouts, die sie enthalten. Ein Workout, das danach keine Strecke mehr hätte, MUST mitgelöscht werden. Sessions, die auf ihr gerudert wurden, MUST mit ihren Runden erhalten bleiben.

#### Scenario: Geruderte Strecke löschen
- **WHEN** der Nutzer die bereits geruderte Strecke „Seerunde“ löscht und bestätigt
- **THEN** ist sie nicht mehr in der Streckenliste und die alten Sessions zeigen weiterhin ihre Rundenzeiten auf „Seerunde“

#### Scenario: Strecke eines Workouts löschen
- **WHEN** der Nutzer eine Strecke löschen will, die die einzige Strecke eines Workouts ist
- **THEN** weist die Bestätigung darauf hin, dass auch das Workout gelöscht wird

#### Scenario: Strecke aus einer Kette löschen
- **WHEN** der Nutzer „Ausrudern“ löscht, das in „Intervalltraining“ neben zwei anderen Strecken steckt, und bestätigt
- **THEN** bleibt „Intervalltraining“ mit „Einrudern“ und „2 km Intervall“ erhalten, und die Bestätigung nannte es nicht als gelöscht
