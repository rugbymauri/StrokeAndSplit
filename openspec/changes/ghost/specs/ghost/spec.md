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
Läuft eine Vorlage mit Ghost, SHALL die Pace-Box den Abstand zum Ghost in Metern und Sekunden zeigen und kennzeichnen, ob der Nutzer vorne oder hinten liegt, nicht allein über Farbe.

#### Scenario: Rückstand
- **WHEN** der Ghost 30 m vor dem Nutzer liegt
- **THEN** zeigt die Box „30 m vor dir“ mit dem Zeitabstand und markiert den Rückstand

#### Scenario: Vorsprung
- **WHEN** der Nutzer 12 m vor dem Ghost liegt
- **THEN** zeigt die Box „12 m hinter dir“ mit dem Zeitabstand und markiert den Vorsprung
