# Spec Delta

## ADDED Requirements

### Requirement: Widerstandsstufe einer Zone
Der Nutzer SHALL einer Zone zusätzlich zu ihren Bändern eine Widerstandsstufe geben oder diese leer lassen können. Die Stufe MUST eine ganze Zahl ab 1 sein. Eine Stufe allein ersetzt kein Band. Die Liste und der Editor SHALL die Stufe zeigen, wenn sie gesetzt ist. Eine Änderung der Stufe SHALL wie eine Änderung der Bänder in allen Strecken gelten, die die Zone enthalten. Bereits geruderte Sessions SHALL die Stufe behalten, die beim Rudern galt.

#### Scenario: Sprint mit Stufe
- **WHEN** der Nutzer der Zone „Sprint“ mit Pace-Band 1:45–1:50 die Stufe 10 gibt
- **THEN** erscheint „Sprint, 100 m, 1:45–1:50 · Stufe 10“ in der Zonenliste

#### Scenario: Nur Stufe
- **WHEN** der Nutzer eine Zone ohne Pace- und Schlagzahl-Band, aber mit Stufe 8 speichern will
- **THEN** wird sie nicht gespeichert und der Nutzer sieht, dass ein Band fehlt

#### Scenario: Ohne Stufe
- **WHEN** der Nutzer eine Zone ohne Stufe speichert
- **THEN** zeigt die Liste keine Stufe, und beim Rudern gilt dort die Grundstufe
