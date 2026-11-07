# resistance-control Specification

## Purpose
TBD - created by archiving change resistance-control. Update Purpose after archive.

## Requirements

### Requirement: Setzbare Stufe erkennen
Die App SHALL beim Verbinden mit einem FTMS-Rudergerät erkennen, ob es das Setzen der Widerstandsstufe unterstützt und in welchem Bereich und mit welcher Schrittweite. Nur dann SHALL die App die Stufe setzen und das Verstellen anbieten. Bei einem PM5, im Replay und bei FTMS-Geräten ohne diese Funktion MUST die App keine Stufe senden.

#### Scenario: Woodrower
- **WHEN** die App sich mit einem Domyos Woodrower verbindet, der das Setzen der Stufe meldet und den Bereich 1 bis 15 in ganzen Stufen
- **THEN** bietet die App das Verstellen der Stufe zwischen 1 und 15 an

#### Scenario: Gerät ohne setzbare Stufe
- **WHEN** ein FTMS-Rudergerät seine Stufe meldet, das Setzen aber nicht unterstützt
- **THEN** zeigt die App die Stufe wie bisher an, bietet aber kein Verstellen an und sendet nichts

#### Scenario: PM5
- **WHEN** die App mit einem PM5 verbunden ist
- **THEN** gibt es weder eine Stufe noch ein Verstellen

### Requirement: Stufe senden
Die App SHALL eine Stufe nur innerhalb des vom Gerät gemeldeten Bereichs und auf dessen Schrittweite gerundet senden. Lehnt das Gerät eine Stufe ab oder antwortet es nicht, MUST die App die Verbindung und die Session unverändert lassen und dem Nutzer zeigen, dass die Stufe nicht gesetzt wurde. Massgebend für die Anzeige SHALL die Stufe sein, die das Gerät meldet, nicht die gesendete.

#### Scenario: Stufe angenommen
- **WHEN** die App Stufe 6 sendet und der Woodrower sie annimmt
- **THEN** meldet das Gerät kurz darauf Stufe 6 und die App zeigt „Stufe 6“

#### Scenario: Stufe ausserhalb des Bereichs
- **WHEN** eine Zone Stufe 20 verlangt und das Gerät höchstens 15 erlaubt
- **THEN** sendet die App Stufe 15

#### Scenario: Gerät lehnt ab
- **WHEN** das Gerät das Setzen der Stufe ablehnt, zum Beispiel weil ein anderer Client die Kontrolle hat
- **THEN** läuft die Session weiter, die Anzeige zeigt die gemeldete Stufe und der Nutzer sieht kurz, dass die Stufe nicht gesetzt werden konnte

### Requirement: Stufe pro Segment
Beim Rudern eines Workouts SHALL die App zu Beginn jedes Segments, das eine Stufe trägt, diese Stufe setzen. Segmente ohne Stufe SHALL die App auf der Grundstufe rudern lassen. Die Grundstufe SHALL die Stufe sein, die das Gerät beim Start der Session meldet, bis der Nutzer sie in einem Segment ohne Stufe von Hand ändert. Folgen zwei Segmente mit derselben Stufe aufeinander, MUST die App nichts senden.

#### Scenario: Intervall mit Stufen
- **WHEN** der Nutzer auf Stufe 4 ein Workout startet, dessen Strecke aus „Einrudern“ ohne Stufe, „Sprint“ mit Stufe 10 und „Erholung“ mit Stufe 3 besteht
- **THEN** bleibt beim Einrudern Stufe 4, mit dem Sprint setzt die App Stufe 10 und mit der Erholung Stufe 3

#### Scenario: Zurück auf die Grundstufe
- **WHEN** nach dem Sprint mit Stufe 10 ein freier Abschnitt folgt und die Grundstufe 4 ist
- **THEN** setzt die App zu Beginn des freien Abschnitts Stufe 4

#### Scenario: Neue Runde
- **WHEN** eine Runde mit dem Sprint mit Stufe 10 endet und die nächste Runde mit „Einrudern“ ohne Stufe beginnt
- **THEN** setzt die App die Grundstufe

#### Scenario: Freies Rudern
- **WHEN** der Nutzer frei rudert
- **THEN** setzt die App die Stufe nie von selbst

### Requirement: Handänderung gilt bis zum nächsten Segment
Ändert der Nutzer die Stufe während eines Segments, über die App oder am Gerät, SHALL die App diese Stufe bis zum Ende des Segments gelten lassen und nicht zurücksetzen. Mit dem nächsten Segment SHALL wieder dessen Stufe oder die Grundstufe gelten. Eine Handänderung in einem Segment ohne Stufe SHALL die neue Grundstufe sein.

#### Scenario: Am Gerät hochgedreht
- **WHEN** der Nutzer im Sprint mit Stufe 10 am Gerät auf Stufe 12 dreht
- **THEN** bleibt Stufe 12 bis zum Ende des Sprints und die Erholung beginnt mit Stufe 3

#### Scenario: Grundstufe von Hand geändert
- **WHEN** der Nutzer beim Einrudern ohne Stufe von 4 auf 5 erhöht
- **THEN** setzt die App nach dem Sprint im nächsten freien Abschnitt Stufe 5

### Requirement: Pause ändert die Stufe nicht
Eine Pause der Session SHALL die geltende Stufe nicht ändern, und die App MUST beim Weiterrudern nichts von selbst senden. Meldet das Gerät nach der Pause eine andere Stufe, SHALL das als Handänderung gelten.

#### Scenario: In der Pause von Hand gedreht
- **WHEN** der Nutzer im Sprint mit Stufe 10 pausiert, am Gerät auf Stufe 3 dreht und weiterrudert
- **THEN** bleibt Stufe 3 bis zum Ende des Sprints, und die Erholung beginnt mit ihrer eigenen Stufe

### Requirement: Stufe nach dem Wiederverbinden
Verbindet sich die App nach einem Abbruch wieder mit dem Gerät, SHALL sie die geltende Stufe erneut senden.

#### Scenario: Verbindung kurz weg
- **WHEN** die Verbindung im Sprint mit Stufe 10 abbricht und die App sich wieder verbindet
- **THEN** sendet die App Stufe 10
