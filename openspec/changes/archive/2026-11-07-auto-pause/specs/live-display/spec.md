# Spec Delta

## ADDED Requirements

### Requirement: Pause anzeigen
Ist die laufende Session pausiert, SHALL das Live-Display das deutlich und aus Ruderdistanz lesbar mit „Pause“ zeigen (englisch „Paused“). Die Werte der Session MUST dabei auf dem Stand vor der Pause stehen bleiben. Der Hinweis MUST verschwinden, sobald die Session weiterläuft. In einer Pause MUST das Display die Werte nicht als veraltet kennzeichnen, solange weiter Daten eintreffen.

#### Scenario: Nutzer hört auf zu rudern
- **WHEN** die Session pausiert
- **THEN** zeigt das Display „Pause“, und die Zeit der Session steht still

#### Scenario: Weiterrudern
- **WHEN** der Nutzer in der Pause wieder rudert
- **THEN** verschwindet der Hinweis und die Zeit läuft weiter
