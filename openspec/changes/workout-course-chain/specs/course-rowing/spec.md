## ADDED Requirements

### Requirement: Strecken einer Kette nacheinander rudern
Hat ein Workout mehrere Strecken, SHALL die App sie in jeder Runde in ihrer Reihenfolge ohne Lücke nacheinander rudern lassen. Die Grenze zwischen zwei Strecken MUST wie eine Rundengrenze auf den exakten Punkt interpoliert werden. Abschnitte, Zonenstatus und Anteil in der Zone MUST über die Strecken hinweg so laufen, als wären ihre Abschnitte eine einzige Strecke.

#### Scenario: Übergang zur nächsten Strecke
- **WHEN** der Nutzer in „Intervalltraining“ die 500 m von „Einrudern“ erreicht
- **THEN** beginnt bei 500 m der erste Abschnitt von „2 km Intervall“, ohne dass eine neue Runde beginnt

#### Scenario: Grenze zwischen zwei Messpunkten
- **WHEN** ein Messpunkt bei 498 m nach 2:29.0 und der nächste bei 503 m nach 2:30.0 liegt und „Einrudern“ 500 m lang ist
- **THEN** endet „Einrudern“ bei 500 m nach 2:29.4 und „2 km Intervall“ beginnt bei 500 m

### Requirement: Ergebnis pro Strecke der Kette speichern
Die App SHALL für jede Strecke einer Runde Dauer, Distanz und Anteil in der Zone ableiten können, auch wenn das Workout nur eine Strecke hat. Eine Strecke gilt als vollständig, wenn ihr Ende erreicht wurde, auch wenn die Runde danach unvollständig bleibt.

#### Scenario: Abbruch in der letzten Strecke
- **WHEN** der Nutzer „Intervalltraining“ mitten in „Ausrudern“ beendet
- **THEN** sind „Einrudern“ und „2 km Intervall“ dieser Runde vollständig, „Ausrudern“ und die Runde unvollständig

## MODIFIED Requirements

### Requirement: Runden fortlaufend zählen
Die App SHALL eine Runde beenden, sobald die Länge der Runde erreicht ist, und die nächste Runde unmittelbar anschliessen. Die Länge einer Runde ist die Summe der Längen aller Strecken des Workouts bzw. die Länge der einen geruderten Strecke. Die Rundengrenze MUST zwischen zwei Messpunkten auf die exakte Länge interpoliert werden, und Überschuss MUST der nächsten Runde zugerechnet werden.

#### Scenario: Grenze zwischen zwei Messpunkten
- **WHEN** ein Messpunkt bei 998 m nach 3:59.0 und der nächste bei 1003 m nach 4:00.0 liegt
- **THEN** endet Runde 1 bei 1000 m nach 3:59.4 und Runde 2 beginnt bei 1000 m

#### Scenario: Offene Rundenzahl
- **WHEN** ein Workout mit offener Rundenzahl gerudert wird
- **THEN** folgt auf jede Runde eine weitere, bis der Nutzer die Session beendet

#### Scenario: Runde über mehrere Strecken
- **WHEN** der Nutzer „Intervalltraining“ mit 500 m, 2000 m und 500 m und 2 Runden rudert
- **THEN** endet Runde 1 bei 3000 m und Runde 2 beginnt dort wieder mit „Einrudern“

### Requirement: Runde und Segment live anzeigen
Beim Rudern eines Workouts SHALL das Live-Display die aktuelle Runde (bei fester Zahl als „Runde 2 / 3“), den aktuellen Abschnitt mit dem Namen seiner Zone bzw. „frei“, die Restdistanz bzw. Restzeit bis zum Abschnittsende und die Zielbänder der Zone anzeigen. Hat das Workout mehrere Strecken, MUST es zusätzlich den Namen der aktuellen Strecke zeigen.

#### Scenario: Mitten in der Zone Tempo
- **WHEN** der Nutzer in Runde 2 von 3 bei 520 m in der Zone „Tempo“ von 200 bis 800 m mit Band 2:05–2:10 rudert
- **THEN** zeigt das Display „Runde 2 / 3“, „Tempo“, „280 m“ bis zum Abschnittsende und „2:05–2:10“

#### Scenario: Freier Abschnitt
- **WHEN** der Nutzer bei 300 m einer Strecke rudert, in der die erste Zone bei 500 m beginnt
- **THEN** zeigt das Display „frei“ und „200 m“ bis zum Abschnittsende

#### Scenario: Zone nur mit Stufe
- **WHEN** der Nutzer bei 700 m in der Zone „Kraft“ von 500 bis 1000 m rudert, die nur Stufe 12 und kein Band hat
- **THEN** zeigt das Display „Kraft“ statt „frei“ und „300 m“ bis zum Abschnittsende, aber kein Zielband

#### Scenario: Aktuelle Strecke
- **WHEN** der Nutzer in „Intervalltraining“ bei 800 m ist, also in „2 km Intervall“
- **THEN** zeigt das Display „2 km Intervall“ neben Runde und Abschnitt

#### Scenario: Nur eine Strecke
- **WHEN** der Nutzer „Seerunde x3“ rudert
- **THEN** zeigt das Display keinen zusätzlichen Streckennamen

### Requirement: Zusammenfassung mit Runden
Die Zusammenfassung einer Session auf einem Workout SHALL Workout, Strecken und alle Runden mit ihrer Zeit (Distanzstrecke) bzw. Distanz (Zeitstrecke) und ihrem Anteil in der Zone zeigen. Die beste vollständige Runde MUST hervorgehoben sein.

#### Scenario: Drei Runden auf Distanz
- **WHEN** die Runden 4:12, 4:08 und 4:15 dauerten
- **THEN** zeigt die Zusammenfassung alle drei Zeiten und hebt 4:08 hervor

#### Scenario: Zeitstrecke
- **WHEN** auf einer 4-min-Strecke 1012 m, 1030 m und 998 m gerudert wurden
- **THEN** zeigt die Zusammenfassung die drei Distanzen und hebt 1030 m hervor

#### Scenario: Mehrere Strecken
- **WHEN** der Nutzer die Zusammenfassung einer Session auf „Intervalltraining“ öffnet
- **THEN** nennt sie „Einrudern + 2 km Intervall + Ausrudern“ und zeigt die Runden über die ganze Kette

### Requirement: Export und Import einer Workout-Session
Wird eine Session auf einem Workout exportiert und wieder importiert, SHALL sie dieselben Runden- und Segmentergebnisse und dieselben Strecken in derselben Reihenfolge ergeben wie bei der Aufzeichnung. Fehlt beim Import eine Strecke, MUST sie in der gespeicherten Version aus der Datei angelegt werden.

#### Scenario: Export und Import
- **WHEN** eine Session „Seerunde x3“ auf dem Handy exportiert und auf dem Laptop importiert wird, wo es die Strecke nicht gibt
- **THEN** zeigt die importierte Session dieselben drei Rundenzeiten und die Strecke „Seerunde“ ist auf dem Laptop vorhanden

#### Scenario: Datei aus der Zeit vor den Workouts
- **WHEN** der Nutzer eine Session importiert, die eine frühere Version der App mit der Vorlage „Seerunde x3“ exportiert hat
- **THEN** zeigt die importierte Session „Seerunde x3“ als Workout mit ihren drei Rundenzeiten

#### Scenario: Mehrere Strecken
- **WHEN** eine Session auf „Intervalltraining“ exportiert und auf einem Gerät ohne diese Strecken importiert wird
- **THEN** zeigt die importierte Session „Einrudern + 2 km Intervall + Ausrudern“ mit denselben Runden, und die drei Strecken sind angelegt

### Requirement: Nach der Gesamtdauer beenden
Bei einer Session mit Gesamtdauer, ob von einem Workout oder direkt auf einer Strecke, SHALL die App die Session automatisch beenden, sobald die Ruderzeit ohne Pausen die Dauer erreicht, und die Zusammenfassung zeigen. Liegt das Ende mitten in einer Runde, MUST diese Runde als unvollständig gespeichert werden.

#### Scenario: Ende mitten in der Runde
- **WHEN** der Nutzer 30 min auf „Seerunde“ rudert und nach 30 min Ruderzeit in Runde 8 bei 1.3 km von 2.4 km ist
- **THEN** endet die Session, Runde 8 ist unvollständig, und die Zusammenfassung erscheint

#### Scenario: Pause zählt nicht
- **WHEN** der Nutzer bei 30 min Dauer nach 20 min Ruderzeit 2 min pausiert
- **THEN** endet die Session erst nach weiteren 10 min Ruderzeit

#### Scenario: Zeitstrecke mit Gesamtdauer
- **WHEN** der Nutzer die Zeitstrecke „Vier Minuten“ 30 min lang rudert
- **THEN** sind 7 Runden vollständig und Runde 8 nach 2 min unvollständig

#### Scenario: Workout mit Dauer
- **WHEN** der Nutzer das Workout „Intervalltraining“ mit 45 min Dauer rudert
- **THEN** endet die Session nach 45 min Ruderzeit, auch mitten in einer Strecke
