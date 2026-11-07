## MODIFIED Requirements

### Requirement: Simulierter Widerstand
Im FTMS-Modus SHALL der Simulator melden, dass sich seine Stufe im Bereich 1 bis 15 setzen lässt, eine gesetzte Stufe annehmen und ab dann melden. Im PM5-Modus SHALL er keine Stufe melden.

#### Scenario: Stufe im Simulator setzen
- **WHEN** der Simulator im FTMS-Modus läuft und die App Stufe 9 setzt
- **THEN** meldet der Simulator ab dem nächsten Messwert Stufe 9

#### Scenario: Vorlage im Simulator
- **WHEN** der Nutzer im Simulator (FTMS) ein Workout mit einem Sprint auf Stufe 10 rudert
- **THEN** zeigt die Live-Anzeige im Sprint „Stufe 10“
