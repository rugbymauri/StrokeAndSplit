## ADDED Requirements

### Requirement: Statusleiste ausblenden
Solange das Live-Display offen ist, SHALL die App unter Android die Statusleiste mit Uhrzeit und Akkustand ausblenden; die Navigationsleiste MUST sichtbar bleiben. Verlässt der Nutzer das Live-Display, MUST die Statusleiste wieder erscheinen.

#### Scenario: Live-Display öffnen
- **WHEN** der Nutzer unter Android das Live-Display öffnet, ob verbunden oder nicht
- **THEN** ist oben keine Statusleiste mit Uhrzeit und Akkustand zu sehen, und die Navigationsleiste bleibt

#### Scenario: Live-Display verlassen
- **WHEN** der Nutzer das Live-Display zum Startbildschirm verlässt
- **THEN** zeigt der Startbildschirm die Statusleiste wieder
