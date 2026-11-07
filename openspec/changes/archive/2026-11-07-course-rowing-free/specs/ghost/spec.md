# Spec Delta

## ADDED Requirements

### Requirement: Ghost beim Rudern einer Strecke
Der Start-Screen einer Strecke SHALL denselben Ghost-Schalter zeigen wie der Screen einer Vorlage, beim Öffnen eingeschaltet und nicht gespeichert. Mit eingeschaltetem Ghost MUST auf Runden- und Abschnittsspur der Ghost laufen, auf der Streckenspur keiner und die Pace-Box keinen Abstand zeigen. Mit ausgeschaltetem Ghost MUST auf keiner Spur ein Ghost erscheinen.

#### Scenario: Mit Ghost
- **WHEN** es für „Seerunde“ eine beste Runde gibt und der Nutzer sie ohne Vorlage mit eingeschaltetem Ghost rudert
- **THEN** läuft auf der Rundenspur der Ghost der besten Runde, auf der Streckenspur keiner, und die Pace-Box zeigt keinen Abstand

#### Scenario: Ohne Ghost
- **WHEN** der Nutzer auf dem Start-Screen von „Seerunde“ den Ghost ausschaltet und startet
- **THEN** erscheint auf keiner Spur ein Ghost
