## MODIFIED Requirements

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
