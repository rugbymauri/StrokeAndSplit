## MODIFIED Requirements

### Requirement: Strecke löschen
Der Nutzer SHALL eine Strecke nach Bestätigung löschen können. Eine gelöschte Strecke verschwindet aus der Streckenliste und aus der Auswahl für Workouts. Sessions, die auf ihr gerudert wurden, MUST mit ihren Runden erhalten bleiben.

#### Scenario: Geruderte Strecke löschen
- **WHEN** der Nutzer die bereits geruderte Strecke „Seerunde“ löscht und bestätigt
- **THEN** ist sie nicht mehr in der Streckenliste und die alten Sessions zeigen weiterhin ihre Rundenzeiten auf „Seerunde“

#### Scenario: Strecke einer Vorlage löschen
- **WHEN** der Nutzer eine Strecke löschen will, die ein Workout verwendet
- **THEN** weist die Bestätigung darauf hin, dass auch das Workout gelöscht wird
