# Spec Delta

## ADDED Requirements

### Requirement: Ghost im Fortschrittsrahmen
Läuft eine Vorlage mit Ghost, SHALL der Fortschrittsrahmen auf jeder Spur, für die Ghost-Daten vorhanden sind, ein eigenes Ghost-Schiffchen an der Position zeigen, an der der Ghost zur gleichen Zeit war. Das Ghost-Schiffchen MUST sich in Farbe und Form vom eigenen Schiffchen unterscheiden. Fehlen für eine Spur Ghost-Daten, MUST dort kein Ghost-Schiffchen erscheinen.

#### Scenario: Ghost liegt vorne
- **WHEN** der Nutzer bei 460 m in Runde 2 ist und der Ghost zur gleichen Zeit bei 490 m war
- **THEN** steht das Ghost-Schiffchen auf der Rundenspur vor dem eigenen Schiffchen

#### Scenario: Nur Rundendaten
- **WHEN** für den Ghost nur Daten zur Runde vorhanden sind, nicht zum Segment
- **THEN** zeigt nur die Rundenspur ein Ghost-Schiffchen

### Requirement: Abstand zum Ghost anzeigen
Läuft auf der Streckenspur ein Ghost, SHALL die Pace-Box den Abstand zu diesem Ghost der Vorlage zeigen: auf einer Distanzachse in Sekunden, auf einer Zeitachse in Metern. Sie MUST kennzeichnen, ob der Nutzer vorne oder hinten liegt, nicht allein über Farbe. Läuft auf der Streckenspur kein Ghost, MUST die Box keinen Abstand zeigen.

#### Scenario: Rückstand auf einer Distanzachse
- **WHEN** der Ghost der Vorlage die aktuelle Distanz des Nutzers 7.6 s früher erreicht hat
- **THEN** zeigt die Box „7.6 s vor dir“ und markiert den Rückstand

#### Scenario: Vorsprung auf einer Zeitachse
- **WHEN** der Nutzer zur gleichen Zeit 12 m weiter ist als der Ghost der Vorlage
- **THEN** zeigt die Box „12 m hinter dir“ und markiert den Vorsprung

#### Scenario: Kein Ghost der Vorlage
- **WHEN** die Vorlage eine offene Rundenzahl hat
- **THEN** zeigt die Box keinen Abstand, und die Rundenspur zeigt trotzdem den Ghost der besten Runde

### Requirement: Platz 1 ist der Ghost
Der Ghost jeder Spur SHALL der Eintrag auf Platz 1 der Rangliste dieser Ebene sein: aussen die Rangliste der Vorlage, in der Mitte die der Strecke und innen die der Zone des aktuellen Abschnitts. Der Ghost der Runde MUST mit jeder Runde neu starten, der Ghost der Zone mit jeder Fahrt durch die Zone. Hat eine Ebene keine Rangliste oder noch keinen Eintrag, MUST auf ihrer Spur kein Ghost laufen.

#### Scenario: Runde 2
- **WHEN** der Nutzer Runde 2 von „Seerunde x3“ beginnt und die beste Runde auf „Seerunde“ 4:08 dauerte
- **THEN** startet der Ghost auf der Rundenspur am Rundenbeginn und erreicht das Rundenende nach 4:08

#### Scenario: Freier Abschnitt
- **WHEN** der Nutzer in einem freien Abschnitt rudert
- **THEN** läuft auf der Abschnittsspur kein Ghost

#### Scenario: Offene Rundenzahl
- **WHEN** der Nutzer eine Vorlage mit offener Rundenzahl rudert
- **THEN** läuft auf der Streckenspur kein Ghost, auf Runden- und Abschnittsspur schon, soweit es Einträge gibt
