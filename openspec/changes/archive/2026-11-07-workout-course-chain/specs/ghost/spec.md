## MODIFIED Requirements

### Requirement: Platz 1 ist der Ghost
Der Ghost jeder Spur SHALL der Eintrag auf Platz 1 der Rangliste dieser Ebene sein: aussen die Rangliste des Workouts, in der Mitte die der Strecke und innen die der Zone des aktuellen Abschnitts. Hat das Workout mehrere Strecken, MUST der Ghost der mittleren Spur stattdessen die schnellste vollständige Runde einer früheren Session dieses Workouts mit derselben Folge der Streckenlängen sein. Der Ghost der Runde MUST mit jeder Runde neu starten, der Ghost der Zone mit jeder Fahrt durch die Zone. Hat eine Ebene keinen Eintrag, MUST auf ihrer Spur kein Ghost laufen.

#### Scenario: Runde 2
- **WHEN** der Nutzer Runde 2 von „Seerunde x3“ beginnt und die beste Runde auf „Seerunde“ 4:08 dauerte
- **THEN** startet der Ghost auf der Rundenspur am Rundenbeginn und erreicht das Rundenende nach 4:08

#### Scenario: Freier Abschnitt
- **WHEN** der Nutzer in einem freien Abschnitt rudert
- **THEN** läuft auf der Abschnittsspur kein Ghost

#### Scenario: Offene Rundenzahl
- **WHEN** der Nutzer ein Workout mit offener Rundenzahl rudert
- **THEN** läuft auf der Streckenspur kein Ghost, auf Runden- und Abschnittsspur schon, soweit es Einträge gibt

#### Scenario: Runde über mehrere Strecken
- **WHEN** der Nutzer Runde 1 von „Intervalltraining“ beginnt und die schnellste vollständige Runde früherer Sessions dieses Workouts 11:40 dauerte
- **THEN** startet der Ghost auf der Rundenspur am Rundenbeginn und erreicht das Rundenende nach 11:40

#### Scenario: Kette erstmals gerudert
- **WHEN** der Nutzer „Intervalltraining“ zum ersten Mal rudert
- **THEN** läuft auf der Rundenspur kein Ghost, auf der Abschnittsspur der Ghost der Zone, soweit es Einträge gibt
