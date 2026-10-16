# Spec Delta

## MODIFIED Requirements

### Requirement: Laufende Messwerte bereitstellen
Die App SHALL aus den Statusdaten des Rudergeräts (PM5 oder FTMS) laufend folgende Messwerte bereitstellen: verstrichene Zeit, Distanz, aktuelle Pace pro 500 m, Leistung in Watt, Schlagzahl, Herzfrequenz (falls vorhanden, vom direkt verbundenen Gurt oder vom Rudergerät) und Kalorien. Liefert ein Gerät einen Wert nicht, MUST er als „nicht vorhanden“ gekennzeichnet sein.

#### Scenario: Rudern mit verbundenem PM5
- **WHEN** der Nutzer rudert und der PM5 Statusdaten sendet
- **THEN** stehen die Messwerte innerhalb einer Sekunde nach Eintreffen der Daten zur Verfügung

#### Scenario: Rudern mit verbundenem FTMS-Rudergerät
- **WHEN** der Nutzer rudert und das FTMS-Rudergerät Rudern-Daten sendet
- **THEN** stehen die Messwerte innerhalb einer Sekunde nach Eintreffen der Daten zur Verfügung

#### Scenario: Kein Herzfrequenzgurt
- **WHEN** weder das Rudergerät noch ein direkt verbundener Gurt eine Herzfrequenz liefert
- **THEN** ist die Herzfrequenz als „nicht vorhanden“ gekennzeichnet statt als 0 oder 255

#### Scenario: FTMS-Gerät ohne Kalorien
- **WHEN** ein FTMS-Rudergerät keinen Energieverbrauch meldet
- **THEN** sind die Kalorien als „nicht vorhanden“ gekennzeichnet und die übrigen Messwerte laufen weiter

## ADDED Requirements

### Requirement: Herzfrequenz nach Vorrang wählen
Die App SHALL als Herzfrequenz den Wert des direkt verbundenen Gurts verwenden, solange dessen letzter Wert höchstens 3 Sekunden alt ist. Sonst MUST sie den vom Rudergerät (PM5 oder FTMS) gemeldeten Wert verwenden und ohne beides die Herzfrequenz als „nicht vorhanden“ kennzeichnen. Die Regel MUST für Live, Aufzeichnung, Import und Replay gleich gelten und sich auf die Empfangszeit der Daten beziehen.

#### Scenario: Gurt direkt und am PM5
- **WHEN** der direkt verbundene Gurt 142 meldet und der PM5 gleichzeitig 140
- **THEN** ist die Herzfrequenz 142

#### Scenario: Gurt direkt und FTMS-Rudergerät mit Puls
- **WHEN** der direkt verbundene Gurt 142 meldet und das FTMS-Rudergerät gleichzeitig 138
- **THEN** ist die Herzfrequenz 142

#### Scenario: Gurt fällt aus, Rudergerät liefert weiter
- **WHEN** der direkt verbundene Gurt seit mehr als 3 Sekunden nichts gesendet hat und das Rudergerät 140 meldet
- **THEN** ist die Herzfrequenz 140

#### Scenario: Gurt fällt aus, Rudergerät ohne Puls
- **WHEN** der direkt verbundene Gurt seit mehr als 3 Sekunden nichts gesendet hat und das Rudergerät keinen Puls meldet
- **THEN** ist die Herzfrequenz „nicht vorhanden“

### Requirement: RR-Intervalle bereitstellen
Sendet der direkt verbundene Gurt RR-Intervalle (Abstand zwischen zwei Herzschlägen), SHALL die App jedes Intervall in Millisekunden mit seinem Empfangszeitpunkt bereitstellen. Ohne RR-Intervalle vom Gurt MUST NOT ein Intervall erfunden oder aus dem Puls abgeleitet werden.

#### Scenario: Gurt mit RR-Intervallen
- **WHEN** der Gurt in einer Messung zwei RR-Intervalle von 812 ms und 790 ms sendet
- **THEN** stellt die App beide Intervalle in dieser Reihenfolge bereit

#### Scenario: Puls nur über das Rudergerät
- **WHEN** der Puls nur vom Rudergerät kommt, ob PM5 oder FTMS
- **THEN** stellt die App keine RR-Intervalle bereit

### Requirement: Gurt-Messungen tolerant lesen
Die App SHALL Puls-Messungen des Gurts in beiden Formaten des Standards (8 und 16 Bit) lesen, auch mit oder ohne Energie- und RR-Angaben. Unvollständige Messungen MUST verworfen und protokolliert werden, ohne die übrigen Messwerte zu beeinflussen.

#### Scenario: Abgeschnittene Messung
- **WHEN** eine Gurt-Messung kürzer ist, als ihre Flags angeben
- **THEN** wird sie ignoriert und protokolliert, und der Puls vom Rudergerät sowie alle Rudermesswerte laufen weiter
