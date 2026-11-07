## ADDED Requirements

### Requirement: Bereitschaft vor dem ersten Schlag anzeigen
Ist eine Session mit Vorlage bereit, aber noch nicht gestartet, SHALL das Live-Display deutlich zeigen, dass die Session mit dem ersten Schlag startet. Der Hinweis MUST verschwinden, sobald die Session gestartet ist.

#### Scenario: Vorlage gewählt
- **WHEN** der Nutzer eine Vorlage wählt und noch nicht rudert
- **THEN** zeigt das Display „Bereit – startet mit dem ersten Schlag“ (englisch „Ready – starts with your first stroke“)

#### Scenario: Erster Schlag
- **WHEN** der Nutzer den ersten Schlag rudert
- **THEN** verschwindet der Hinweis und die Zeit beginnt zu laufen
