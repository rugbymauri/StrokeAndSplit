# Spec Delta

## ADDED Requirements

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
