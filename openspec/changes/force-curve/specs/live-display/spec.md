# Spec Delta

## ADDED Requirements

### Requirement: Kraftkurve anzeigen
Unterstützt die Quelle Kraftkurven, SHALL das Live-Display die Kurve des letzten Schlags und zum Vergleich die des vorherigen Schlags zeigen, beide auf derselben Skala und klar unterscheidbar. Die Kurve MUST kleiner bleiben als die Pace.

#### Scenario: Während des Ruderns
- **WHEN** der Nutzer mit dem PM5 rudert und mindestens zwei Schläge gemacht hat
- **THEN** zeigt das Display die Kurven der letzten beiden Schläge, die neuere hervorgehoben

#### Scenario: Vor dem ersten Schlag
- **WHEN** die Session läuft, aber noch kein Schlag ausgewertet ist
- **THEN** zeigt die Karte den Hinweis „Warte auf ersten Schlag“

#### Scenario: Quelle ohne Kraftkurve
- **WHEN** die verbundene Quelle keine Kraftkurven liefert
- **THEN** zeigt das Display keine Kraftkurven-Karte, und die übrigen Werte nutzen den Platz
