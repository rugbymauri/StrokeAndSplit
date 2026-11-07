# Spec Delta

## MODIFIED Requirements

### Requirement: Runde und Segment live anzeigen
Beim Rudern einer Vorlage SHALL das Live-Display die aktuelle Runde (bei fester Zahl als „Runde 2 / 3“), den aktuellen Abschnitt mit dem Namen seiner Zone bzw. „frei“, die Restdistanz bzw. Restzeit bis zum Abschnittsende und die Zielbänder der Zone anzeigen.

#### Scenario: Mitten in der Zone Tempo
- **WHEN** der Nutzer in Runde 2 von 3 bei 520 m in der Zone „Tempo“ von 200 bis 800 m mit Band 2:05–2:10 rudert
- **THEN** zeigt das Display „Runde 2 / 3“, „Tempo“, „280 m“ bis zum Abschnittsende und „2:05–2:10“

#### Scenario: Freier Abschnitt
- **WHEN** der Nutzer bei 300 m einer Strecke rudert, in der die erste Zone bei 500 m beginnt
- **THEN** zeigt das Display „frei“ und „200 m“ bis zum Abschnittsende
