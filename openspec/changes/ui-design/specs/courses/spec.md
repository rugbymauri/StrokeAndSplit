# Spec Delta

## MODIFIED Requirements

### Requirement: Strecke in Segmente teilen
Eine Strecke SHALL aus einem oder mehreren aufeinanderfolgenden Segmenten bestehen, die zusammen genau die Länge der Strecke ergeben. Segmentlängen werden in der Achse der Strecke angegeben. Eine neue Strecke MUST mit einem einzigen Segment über die ganze Länge beginnen. Ändert der Nutzer die Länge eines Segments, SHALL das folgende Segment die Differenz tragen, beim letzten Segment das vorherige. Ändert er die Länge der Strecke, SHALL das letzte Segment die Differenz tragen. Kein Segment MUST dabei kürzer als 50 m bzw. 10 s werden.

#### Scenario: Strecke unterteilen
- **WHEN** der Nutzer die 1000-m-Strecke in Segmente von 200 m, 600 m und 200 m teilt
- **THEN** zeigt der Editor drei Segmente mit den Grenzen 200 m und 800 m

#### Scenario: Segment verlängern
- **WHEN** der Nutzer bei den Segmenten 200/600/200 m das mittlere Segment auf 650 m verlängert
- **THEN** sind die Segmente 200/650/150 m lang und ergeben weiterhin 1000 m

#### Scenario: Nachbar zu kurz
- **WHEN** der Nutzer bei 200/600/200 m das mittlere Segment auf 800 m verlängern will
- **THEN** begrenzt der Editor es auf 750 m, das letzte Segment bleibt 50 m lang, und der Editor zeigt den Grund

#### Scenario: Strecke verlängern
- **WHEN** der Nutzer die Strecke mit 200/600/200 m auf 1200 m verlängert
- **THEN** sind die Segmente 200/600/400 m lang

#### Scenario: Segment entfernen
- **WHEN** der Nutzer bei 200/600/200 m das mittlere Segment entfernt
- **THEN** sind die Segmente 800/200 m lang
