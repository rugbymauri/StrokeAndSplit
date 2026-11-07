## RENAMED Requirements

- FROM: `### Requirement: Export und Import einer Vorlagen-Session`
- TO: `### Requirement: Export und Import einer Workout-Session`

- FROM: `### Requirement: Strecke ohne Vorlage rudern`
- TO: `### Requirement: Strecke ohne Workout rudern`

- FROM: `### Requirement: Zusammenfassung ohne Vorlage`
- TO: `### Requirement: Zusammenfassung ohne Workout`

## MODIFIED Requirements

### Requirement: Fortschritt nach Sessionzeit messen
Beim Rudern eines Workouts SHALL der Fortschritt einer Zeitstrecke nach der Sessionzeit gemessen werden, also nach Wanduhr ohne die Pausen der Session, unabhängig davon, ob der PM5 seine Uhr anhält. Rundenzeiten und Abschnittszeiten MUST ebenfalls nach der Sessionzeit gemessen werden und die Pausen damit nicht enthalten.

#### Scenario: Pause in einer Distanzrunde
- **WHEN** der Nutzer in einer 1000-m-Runde rudert und dabei 30 Sekunden stillsitzt
- **THEN** enthält die Rundenzeit die Zeit bis zum Beginn der Pause, aber nicht die Pause

#### Scenario: Pause in einer Zeitrunde
- **WHEN** der Nutzer in einer 4-min-Runde nach 3 Minuten aufhört, 30 Sekunden stillsitzt und weiterrudert
- **THEN** steht die Restzeit der Runde in der Pause still, und die Runde endet nach 4 Minuten Sessionzeit

#### Scenario: Ältere Session in der Rangliste
- **WHEN** eine Session aus einer früheren Version mit einer Pause in der Rangliste steht
- **THEN** zählt ihre Runde weiter mit der gespeicherten Zeit einschliesslich der Pause

### Requirement: Runden fortlaufend zählen
Die App SHALL eine Runde beenden, sobald die Länge der Strecke erreicht ist, und die nächste Runde unmittelbar anschliessen. Die Rundengrenze MUST zwischen zwei Messpunkten auf die exakte Streckenlänge interpoliert werden, und Überschuss MUST der nächsten Runde zugerechnet werden.

#### Scenario: Grenze zwischen zwei Messpunkten
- **WHEN** ein Messpunkt bei 998 m nach 3:59.0 und der nächste bei 1003 m nach 4:00.0 liegt
- **THEN** endet Runde 1 bei 1000 m nach 3:59.4 und Runde 2 beginnt bei 1000 m

#### Scenario: Offene Rundenzahl
- **WHEN** ein Workout mit offener Rundenzahl gerudert wird
- **THEN** folgt auf jede Runde eine weitere, bis der Nutzer die Session beendet

### Requirement: Runde und Segment live anzeigen
Beim Rudern eines Workouts SHALL das Live-Display die aktuelle Runde (bei fester Zahl als „Runde 2 / 3“), den aktuellen Abschnitt mit dem Namen seiner Zone bzw. „frei“, die Restdistanz bzw. Restzeit bis zum Abschnittsende und die Zielbänder der Zone anzeigen.

#### Scenario: Mitten in der Zone Tempo
- **WHEN** der Nutzer in Runde 2 von 3 bei 520 m in der Zone „Tempo“ von 200 bis 800 m mit Band 2:05–2:10 rudert
- **THEN** zeigt das Display „Runde 2 / 3“, „Tempo“, „280 m“ bis zum Abschnittsende und „2:05–2:10“

#### Scenario: Freier Abschnitt
- **WHEN** der Nutzer bei 300 m einer Strecke rudert, in der die erste Zone bei 500 m beginnt
- **THEN** zeigt das Display „frei“ und „200 m“ bis zum Abschnittsende

#### Scenario: Zone nur mit Stufe
- **WHEN** der Nutzer bei 700 m in der Zone „Kraft“ von 500 bis 1000 m rudert, die nur Stufe 12 und kein Band hat
- **THEN** zeigt das Display „Kraft“ statt „frei“ und „300 m“ bis zum Abschnittsende, aber kein Zielband

### Requirement: Zusammenfassung mit Runden
Die Zusammenfassung einer Session auf einem Workout SHALL Workout, Strecke und alle Runden mit ihrer Zeit (Distanzstrecke) bzw. Distanz (Zeitstrecke) und ihrem Anteil in der Zone zeigen. Die beste vollständige Runde MUST hervorgehoben sein.

#### Scenario: Drei Runden auf Distanz
- **WHEN** die Runden 4:12, 4:08 und 4:15 dauerten
- **THEN** zeigt die Zusammenfassung alle drei Zeiten und hebt 4:08 hervor

#### Scenario: Zeitstrecke
- **WHEN** auf einer 4-min-Strecke 1012 m, 1030 m und 998 m gerudert wurden
- **THEN** zeigt die Zusammenfassung die drei Distanzen und hebt 1030 m hervor

### Requirement: Export und Import einer Workout-Session
Wird eine Session auf einem Workout exportiert und wieder importiert, SHALL sie dieselben Runden- und Segmentergebnisse ergeben wie bei der Aufzeichnung. Fehlt beim Import die passende Strecke, MUST die Strecke in der gespeicherten Version aus der Datei angelegt werden.

#### Scenario: Export und Import
- **WHEN** eine Session „Seerunde x3“ auf dem Handy exportiert und auf dem Laptop importiert wird, wo es die Strecke nicht gibt
- **THEN** zeigt die importierte Session dieselben drei Rundenzeiten und die Strecke „Seerunde“ ist auf dem Laptop vorhanden

#### Scenario: Datei aus der Zeit vor den Workouts
- **WHEN** der Nutzer eine Session importiert, die eine frühere Version der App mit der Vorlage „Seerunde x3“ exportiert hat
- **THEN** zeigt die importierte Session „Seerunde x3“ als Workout mit ihren drei Rundenzeiten

### Requirement: Strecke ohne Workout rudern
Eine Session, die ohne Workout auf einer Strecke läuft, SHALL Runden, Abschnitte, Zonenstatus, Anteil in der Zone und Ergebnisse genauso messen, anzeigen und speichern wie eine Session auf einem Workout mit dieser Strecke. Ihre vollständigen Runden und Zonenfahrten MUST in den Ranglisten von Strecke und Zone zählen.

#### Scenario: Drei Runden ohne Vorlage
- **WHEN** der Nutzer „Seerunde“ ohne Workout mit 3 Runden rudert
- **THEN** zeigt das Live-Display „Runde 2 von 3“ und den aktuellen Abschnitt, und die Session endet nach der dritten Runde

#### Scenario: Rangliste der Strecke
- **WHEN** der Nutzer „Seerunde“ ohne Workout rudert und eine Runde in 4:05 schafft, schneller als alle bisherigen
- **THEN** steht diese Runde auf Platz 1 der Rangliste von „Seerunde“

### Requirement: Zusammenfassung ohne Workout
Die Zusammenfassung einer Session ohne Workout auf einer Strecke SHALL statt des Workouts die Strecke und die geplante Länge nennen: die Rundenzahl, die Dauer oder „offen“. Sie MUST alle Runden wie bei einem Workout zeigen und keine Platzmarke für ein Workout.

#### Scenario: 30 min auf der Seerunde
- **WHEN** der Nutzer die Zusammenfassung einer Session mit 30 min auf „Seerunde“ öffnet
- **THEN** steht dort „Seerunde · 30 min“ mit allen Runden, die letzte als unvollständig markiert
