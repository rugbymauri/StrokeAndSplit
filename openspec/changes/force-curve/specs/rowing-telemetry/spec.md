# Spec Delta

## ADDED Requirements

### Requirement: Kraftkurve pro Schlag
Liefert die Quelle eine Kraftkurve, SHALL die App nach jedem Schlag dessen vollständige Kurve als Folge von Kraftwerten in Newton bereitstellen. Unvollständige Kurven, etwa nach einem verlorenen Paket, MUST verworfen werden, statt eine verfälschte Kurve zu liefern.

#### Scenario: Vollständiger Schlag
- **WHEN** der PM5 nach einem Schlag alle Kurvenpakete dieses Schlags sendet
- **THEN** stellt die App genau eine Kurve für diesen Schlag bereit

#### Scenario: Paket verloren
- **WHEN** ein Kurvenpaket eines Schlags fehlt
- **THEN** stellt die App für diesen Schlag keine Kurve bereit, und der nächste Schlag wird wieder normal ausgewertet
