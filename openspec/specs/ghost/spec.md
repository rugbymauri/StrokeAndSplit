# ghost Specification

## Purpose
TBD - created by archiving change ghost. Update Purpose after archive.

## Requirements

### Requirement: Ghost im Fortschrittsrahmen
Läuft eine Vorlage mit Ghost, SHALL der Fortschrittsrahmen auf jeder Spur, für die Ghost-Daten vorhanden sind, ein eigenes Ghost-Schiffchen an der Position zeigen, an der der Ghost zur gleichen Zeit war. Das Ghost-Schiffchen MUST sich in Farbe und Form vom eigenen Schiffchen unterscheiden. Fehlen für eine Spur Ghost-Daten, MUST dort kein Ghost-Schiffchen erscheinen.

#### Scenario: Ghost liegt vorne
- **WHEN** der Nutzer bei 460 m in Runde 2 ist und der Ghost zur gleichen Zeit bei 490 m war
- **THEN** steht das Ghost-Schiffchen auf der Rundenspur vor dem eigenen Schiffchen

#### Scenario: Nur Rundendaten
- **WHEN** für den Ghost nur Daten zur Runde vorhanden sind, nicht zum Segment
- **THEN** zeigt nur die Rundenspur ein Ghost-Schiffchen

### Requirement: Kein Ghost-Schiffchen auf Zeitstrecken
Auf einer Zeitstrecke SHALL der Fortschrittsrahmen kein Ghost-Schiffchen zeigen, weil der Ghost dort immer an derselben Stelle stünde wie der Nutzer. Vorsprung oder Rückstand MUST dann allein die Pace-Box in Metern zeigen.

#### Scenario: Zeitstrecke
- **WHEN** der Nutzer eine Vorlage auf „Vier Minuten“ rudert und es dafür schon einen Ghost gibt
- **THEN** zeigt der Rahmen auf keiner Spur ein Ghost-Schiffchen, und die Box zeigt den Abstand in Metern

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

### Requirement: Ghost vor dem Start abschalten
Der Screen einer Vorlage SHALL einen Schalter „Ghost“ zeigen, der bei jedem Öffnen des Screens eingeschaltet ist. Startet der Nutzer mit ausgeschaltetem Ghost, MUST in dieser Session auf keiner Spur ein Ghost-Schiffchen erscheinen und die Pace-Box keinen Abstand zum Ghost zeigen. Die Wahl MUST NOT gespeichert werden und gilt nur für die Session, die vom Screen aus startet.

#### Scenario: Ohne Ghost starten
- **WHEN** es für „Seerunde x3“ Bestleistungen gibt und der Nutzer auf ihrem Screen den Ghost ausschaltet und „Starten“ wählt
- **THEN** zeigt der Fortschrittsrahmen auf keiner Spur ein Ghost-Schiffchen, und die Pace-Box zeigt keine Abstandszeile

#### Scenario: Mit Ghost starten
- **WHEN** der Nutzer den Screen von „Seerunde x3“ öffnet und ohne den Schalter zu berühren „Starten“ wählt
- **THEN** laufen die Ghosts wie unter „Platz 1 ist der Ghost“ beschrieben

#### Scenario: Wahl gilt nur einmal
- **WHEN** der Nutzer ohne Ghost gerudert hat und den Screen von „Seerunde x3“ wieder öffnet
- **THEN** ist der Schalter wieder eingeschaltet

#### Scenario: Vorlage ohne Bestleistung
- **WHEN** der Nutzer den Screen einer Vorlage öffnet, die noch nie gerudert wurde
- **THEN** zeigt der Screen den Schalter trotzdem, und mit eingeschaltetem Ghost läuft auf keiner Spur ein Ghost, solange es keinen Eintrag gibt

### Requirement: Ghost während der Fahrt unveränderlich
Ob in einer Session ein Ghost läuft, SHALL mit dem Start feststehen. Das Live-Display MUST NOT anbieten, den Ghost während der Session ein- oder auszuschalten.

#### Scenario: Während der Fahrt
- **WHEN** der Nutzer eine Vorlage ohne Ghost rudert
- **THEN** bietet das Live-Display keinen Schalter für den Ghost, und bis zum Ende der Session erscheint kein Ghost

### Requirement: Ghost beim Rudern einer Strecke
Der Start-Screen einer Strecke SHALL denselben Ghost-Schalter zeigen wie der Screen einer Vorlage, beim Öffnen eingeschaltet und nicht gespeichert. Mit eingeschaltetem Ghost MUST auf Runden- und Abschnittsspur der Ghost laufen, auf der Streckenspur keiner und die Pace-Box keinen Abstand zeigen. Mit ausgeschaltetem Ghost MUST auf keiner Spur ein Ghost erscheinen.

#### Scenario: Mit Ghost
- **WHEN** es für „Seerunde“ eine beste Runde gibt und der Nutzer sie ohne Vorlage mit eingeschaltetem Ghost rudert
- **THEN** läuft auf der Rundenspur der Ghost der besten Runde, auf der Streckenspur keiner, und die Pace-Box zeigt keinen Abstand

#### Scenario: Ohne Ghost
- **WHEN** der Nutzer auf dem Start-Screen von „Seerunde“ den Ghost ausschaltet und startet
- **THEN** erscheint auf keiner Spur ein Ghost
