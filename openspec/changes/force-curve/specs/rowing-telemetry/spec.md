# Spec Delta

## ADDED Requirements

### Requirement: Kraftkurve pro Schlag
Liefert die Quelle eine Kraftkurve, SHALL die App nach dem Durchzug jedes Schlags dessen vollständige Kurve als Folge von Kraftwerten in Newton bereitstellen, zugeordnet zur Schlagnummer. Unvollständige Kurven, etwa nach einem verlorenen Paket, MUST verworfen werden, statt eine verfälschte Kurve zu liefern.

#### Scenario: Vollständiger Schlag
- **WHEN** der PM5 nach dem Durchzug eines Schlags alle Kurvenpakete dieses Schlags sendet
- **THEN** stellt die App genau eine Kurve für diesen Schlag bereit, deren Maximum der Spitzenkraft des Schlags entspricht

#### Scenario: Schlaglänge zur Kurve
- **WHEN** der PM5 vor der Kurve eines Schlags dessen Durchzugslänge meldet
- **THEN** trägt die Kurve dieses Schlags dieselbe Durchzugslänge in Metern; fehlt sie oder ist sie 0, ist sie als nicht vorhanden gekennzeichnet

#### Scenario: Paket verloren
- **WHEN** ein Kurvenpaket eines Schlags fehlt
- **THEN** stellt die App für diesen Schlag keine Kurve bereit, und der nächste Schlag wird wieder normal ausgewertet
