# Spec Delta

## MODIFIED Requirements

### Requirement: Runde und Segment live anzeigen
Beim Rudern einer Vorlage SHALL das Live-Display die aktuelle Runde (bei fester Zahl als „Runde 2 von 3“), den aktuellen Abschnitt mit dem Namen seiner Zone bzw. „frei“, die Restdistanz bzw. Restzeit bis zum Abschnittsende und die Zielbänder der Zone anzeigen.

#### Scenario: Mitten in der Zone Tempo
- **WHEN** der Nutzer in Runde 2 von 3 bei 520 m in der Zone „Tempo“ von 200 bis 800 m mit Band 2:05–2:10 rudert
- **THEN** zeigt das Display „Runde 2 von 3“, „Tempo“, „280 m“ bis zum Abschnittsende und „2:05–2:10“

#### Scenario: Freier Abschnitt
- **WHEN** der Nutzer bei 300 m einer Strecke rudert, in der die erste Zone bei 500 m beginnt
- **THEN** zeigt das Display „frei“ und „200 m“ bis zum Abschnittsende

#### Scenario: Zone nur mit Stufe
- **WHEN** der Nutzer bei 700 m in der Zone „Kraft“ von 500 bis 1000 m rudert, die nur Stufe 12 und kein Band hat
- **THEN** zeigt das Display „Kraft“ statt „frei“ und „300 m“ bis zum Abschnittsende, aber kein Zielband

### Requirement: Anteil in der Zone zählen
Für jedes Segment mit mindestens einem Band SHALL die App den Anteil der Zeit messen, in dem alle gesetzten Bänder gleichzeitig eingehalten wurden. Zeit ohne gültigen Messwert, etwa in einer Pause, MUST als ausserhalb der Zone zählen. Das Live-Display SHALL den laufenden Anteil der aktuellen Runde anzeigen.

#### Scenario: Teilweise in der Zone
- **WHEN** der Nutzer ein 60-Sekunden-Segment 45 Sekunden lang in beiden Bändern rudert
- **THEN** beträgt der Anteil in der Zone für dieses Segment 75 %

#### Scenario: Pause im Segment
- **WHEN** der Nutzer in einem Segment mit Band 10 Sekunden pausiert
- **THEN** zählen diese 10 Sekunden als ausserhalb der Zone

#### Scenario: Zone nur mit Stufe
- **WHEN** der Nutzer eine Runde rudert, deren einzige Zone „Kraft“ nur Stufe 12 und kein Band hat
- **THEN** hat weder das Segment noch die Runde einen Anteil in der Zone
