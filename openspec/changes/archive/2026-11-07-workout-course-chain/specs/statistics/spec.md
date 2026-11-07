## MODIFIED Requirements

### Requirement: Rangliste eines Workouts
Die App SHALL pro Workout eine Rangliste führen, deren Einträge Sessions sind, in denen alle geplanten Runden vollständig gerudert wurden. Gewertet wird die Summe der Rundenzeiten bzw. Rundendistanzen. Nur Sessions mit gleicher Folge der Streckenlängen und gleicher Rundenzahl MUST in derselben Rangliste stehen. Ein Workout mit offener Rundenzahl oder mit Dauer hat keine Rangliste.

#### Scenario: Drei Runden
- **WHEN** „Seerunde x3“ zweimal vollständig gerudert wurde, in 12:31.8 und 12:24.1
- **THEN** steht 12:24.1 auf Platz 1 der Rangliste von „Seerunde x3“

#### Scenario: Abgebrochene Session
- **WHEN** eine Session auf „Seerunde x3“ nach Runde 2 beendet wurde
- **THEN** steht sie nicht in der Rangliste des Workouts

#### Scenario: Rundenzahl geändert
- **WHEN** „Seerunde x3“ auf 4 Runden geändert und danach gerudert wurde
- **THEN** stehen die 4-Runden-Sessions in einer eigenen Rangliste und die 3-Runden-Sessions bleiben in ihrer

#### Scenario: Offene Rundenzahl
- **WHEN** das Workout „Seerunde offen“ gerudert wurde
- **THEN** zeigt das Workout keine Plätze, seine Runden zählen aber für die Strecke

#### Scenario: Strecke angehängt
- **WHEN** an „Seerunde x3“ nach einigen Sessions „Ausrudern“ angehängt und das Workout wieder gerudert wurde
- **THEN** stehen die Sessions mit beiden Strecken in einer eigenen Rangliste und die älteren bleiben in ihrer

#### Scenario: Workout mit Dauer
- **WHEN** das Workout „Intervalltraining“ mit 45 min Dauer gerudert wurde
- **THEN** zeigt das Workout keine Plätze, seine vollständigen Strecken und Zonenfahrten zählen aber in deren Ranglisten

### Requirement: Rangliste einer Strecke
Die App SHALL pro Strecke eine Rangliste führen, deren Einträge vollständige Fahrten über diese Strecke sind, unabhängig vom Workout und davon, ob die Strecke allein oder in einer Kette gerudert wurde. Jede Fahrt ist ein eigener Eintrag, auch mehrere aus derselben Session. Fahrten auf Versionen gleicher Länge MUST in derselben Rangliste stehen. Hatte die Strecke verschiedene Längen, SHALL es eine Rangliste pro Länge geben. Unvollständige Fahrten MUST NOT zählen.

#### Scenario: Über Workouts hinweg
- **WHEN** „Seerunde“ mit „Seerunde x3“ und mit „Seerunde offen“ gerudert wurde
- **THEN** stehen die Runden beider Workouts in derselben Rangliste von „Seerunde“

#### Scenario: Länge geändert
- **WHEN** „Seerunde“ mit 1000 m gerudert, auf 1200 m geändert und wieder gerudert wurde
- **THEN** hat „Seerunde“ eine Rangliste für 1000 m und eine für 1200 m

#### Scenario: Nur Zonen geändert
- **WHEN** in „Seerunde“ eine Zone eingebaut wurde und die Länge gleich blieb
- **THEN** stehen die Runden vor und nach der Änderung in derselben Rangliste

#### Scenario: Strecke in einer Kette
- **WHEN** „2 km Intervall“ allein und als Teil von „Intervalltraining“ gerudert wurde
- **THEN** stehen beide Fahrten in derselben Rangliste von „2 km Intervall“

#### Scenario: Kette abgebrochen
- **WHEN** der Nutzer „Intervalltraining“ mitten in „Ausrudern“ beendet
- **THEN** zählt die Fahrt über „2 km Intervall“ in dessen Rangliste, die über „Ausrudern“ nicht

### Requirement: Plätze in der Workout-Wahl
Der Screen eines Workouts SHALL die Plätze 1–3 seiner Rangliste mit Wert, Pace und Datum zeigen, für die aktuelle Folge der Streckenlängen und Rundenzahl. Gibt es noch keinen Eintrag oder ist die Länge offen oder eine Dauer, MUST stattdessen ein Hinweis stehen und kein Platz.

#### Scenario: Zwei Einträge
- **WHEN** „Seerunde x3“ zweimal vollständig gerudert wurde und der Nutzer in der Workout-Liste seinen Screen öffnet
- **THEN** sieht er Platz 1 und 2 mit Zeit, Pace und Datum

#### Scenario: Noch nie gerudert
- **WHEN** der Nutzer den Screen eines neuen Workouts öffnet
- **THEN** steht dort, dass es noch keine Bestzeit gibt

#### Scenario: Workout mit Dauer
- **WHEN** der Nutzer den Screen eines Workouts mit 45 min Dauer öffnet
- **THEN** steht dort ein Hinweis statt der Plätze
