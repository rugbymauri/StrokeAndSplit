# Spec Delta

## ADDED Requirements

### Requirement: Kraftkurve aufzeichnen
Die App SHALL die Kurvenpakete einer Session als Rohdaten mitspeichern, exportieren und importieren. Ein Replay MUST die Kraftkurve so zeigen wie während der Aufnahme.

#### Scenario: Replay mit Kraftkurve
- **WHEN** der Nutzer eine mit dem PM5 aufgezeichnete Session abspielt
- **THEN** zeigt das Live-Display die Kraftkurven der Schläge wie bei der Aufnahme

#### Scenario: Export und Import
- **WHEN** der Nutzer eine Session mit Kraftkurven exportiert und wieder importiert
- **THEN** zeigt das Replay der importierten Session dieselben Kurven
