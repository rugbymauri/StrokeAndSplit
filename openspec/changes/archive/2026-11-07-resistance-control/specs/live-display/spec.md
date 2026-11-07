# Spec Delta

## ADDED Requirements

### Requirement: Widerstandsstufe von Hand verstellen
Ist ein Rudergerät verbunden, dessen Stufe sich setzen lässt, SHALL die Live-Anzeige bei der Stufe unter den Watt eine Möglichkeit bieten, die Stufe um eine Stufe zu senken oder zu erhöhen, frei und mit Vorlage. Die Bedienelemente MUST aus Ruderdistanz treffbar sein und dürfen die Kernwerte nicht verdecken. An der Grenze des Bereichs MUST die jeweilige Richtung gesperrt sein. Lässt sich die Stufe nicht setzen, SHALL die Anzeige wie bisher nur die gemeldete Stufe zeigen.

#### Scenario: Stufe erhöhen
- **WHEN** das Gerät Stufe 6 meldet und der Nutzer auf + tippt
- **THEN** sendet die App Stufe 7 und die Anzeige zeigt „Stufe 7“, sobald das Gerät sie meldet

#### Scenario: Obere Grenze
- **WHEN** das Gerät Stufe 15 meldet und höchstens 15 erlaubt
- **THEN** ist + gesperrt

#### Scenario: Mehrmals schnell getippt
- **WHEN** der Nutzer bei Stufe 6 dreimal schnell auf + tippt
- **THEN** landet das Gerät auf Stufe 9

#### Scenario: Gerät ohne setzbare Stufe
- **WHEN** ein Gerät seine Stufe meldet, das Setzen aber nicht unterstützt
- **THEN** steht unter den Watt nur „Stufe 6“, ohne − und +
