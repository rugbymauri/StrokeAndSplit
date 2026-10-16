# Spec Delta

## ADDED Requirements

### Requirement: Kraftkurve pro Schlag
Liefert die Quelle eine Kraftkurve, SHALL die App nach dem Durchzug jedes Schlags dessen vollständige Kurve als Folge von Kraftwerten in Newton bereitstellen, zugeordnet zur Schlagnummer. Unvollständige Kurven, etwa nach einem verlorenen Paket, MUST verworfen werden, statt eine verfälschte Kurve zu liefern.

#### Scenario: Vollständiger Schlag
- **WHEN** der PM5 nach dem Durchzug eines Schlags alle Kurvenpakete dieses Schlags sendet
- **THEN** stellt die App genau eine Kurve für diesen Schlag bereit, deren Maximum der Spitzenkraft des Schlags entspricht

#### Scenario: Paket verloren
- **WHEN** ein Kurvenpaket eines Schlags fehlt
- **THEN** stellt die App für diesen Schlag keine Kurve bereit, und der nächste Schlag wird wieder normal ausgewertet
