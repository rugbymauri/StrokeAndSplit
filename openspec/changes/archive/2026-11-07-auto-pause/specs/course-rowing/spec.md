# Spec Delta

## RENAMED Requirements

- FROM: `### Requirement: Fortschritt nach Wanduhr messen`
- TO: `### Requirement: Fortschritt nach Sessionzeit messen`

## MODIFIED Requirements

### Requirement: Fortschritt nach Sessionzeit messen
Beim Rudern einer Vorlage SHALL der Fortschritt einer Zeitstrecke nach der Sessionzeit gemessen werden, also nach Wanduhr ohne die Pausen der Session, unabhängig davon, ob der PM5 seine Uhr anhält. Rundenzeiten und Abschnittszeiten MUST ebenfalls nach der Sessionzeit gemessen werden und die Pausen damit nicht enthalten.

#### Scenario: Pause in einer Distanzrunde
- **WHEN** der Nutzer in einer 1000-m-Runde rudert und dabei 30 Sekunden stillsitzt
- **THEN** enthält die Rundenzeit die Zeit bis zum Beginn der Pause, aber nicht die Pause

#### Scenario: Pause in einer Zeitrunde
- **WHEN** der Nutzer in einer 4-min-Runde nach 3 Minuten aufhört, 30 Sekunden stillsitzt und weiterrudert
- **THEN** steht die Restzeit der Runde in der Pause still, und die Runde endet nach 4 Minuten Sessionzeit

#### Scenario: Ältere Session in der Rangliste
- **WHEN** eine Session aus einer früheren Version mit einer Pause in der Rangliste steht
- **THEN** zählt ihre Runde weiter mit der gespeicherten Zeit einschliesslich der Pause

### Requirement: Anteil in der Zone zählen
Für jedes Segment mit mindestens einem Band SHALL die App den Anteil der Sessionzeit messen, in dem alle gesetzten Bänder gleichzeitig eingehalten wurden. Zeit ohne gültigen Messwert ausserhalb einer Pause MUST als ausserhalb der Zone zählen. Die Pausen der Session MUST weder als innerhalb noch als ausserhalb zählen. Das Live-Display SHALL den laufenden Anteil der aktuellen Runde anzeigen.

#### Scenario: Teilweise in der Zone
- **WHEN** der Nutzer ein 60-Sekunden-Segment 45 Sekunden lang in beiden Bändern rudert
- **THEN** beträgt der Anteil in der Zone für dieses Segment 75 %

#### Scenario: Pause im Segment
- **WHEN** der Nutzer in einem Segment mit Band 30 Sekunden stillsitzt
- **THEN** zählt die Pause nicht zum Anteil in der Zone, nur die Zeit bis zum Beginn der Pause
