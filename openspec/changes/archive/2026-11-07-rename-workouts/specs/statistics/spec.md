## RENAMED Requirements

- FROM: `### Requirement: Rangliste einer Vorlage`
- TO: `### Requirement: Rangliste eines Workouts`

- FROM: `### Requirement: Plätze in der Vorlagenwahl`
- TO: `### Requirement: Plätze in der Workout-Wahl`

## MODIFIED Requirements

### Requirement: Rangliste eines Workouts
Die App SHALL pro Workout eine Rangliste führen, deren Einträge Sessions sind, in denen alle geplanten Runden vollständig gerudert wurden. Gewertet wird die Summe der Rundenzeiten bzw. Rundendistanzen. Nur Sessions mit gleicher Streckenlänge und gleicher Rundenzahl MUST in derselben Rangliste stehen. Ein Workout mit offener Rundenzahl hat keine Rangliste.

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

### Requirement: Rangliste einer Strecke
Die App SHALL pro Strecke eine Rangliste führen, deren Einträge vollständige Runden auf dieser Strecke sind, unabhängig vom Workout. Runden auf Versionen gleicher Länge MUST in derselben Rangliste stehen. Hatte die Strecke verschiedene Längen, SHALL es eine Rangliste pro Länge geben. Unvollständige Runden MUST NOT zählen.

#### Scenario: Über Vorlagen hinweg
- **WHEN** „Seerunde“ mit „Seerunde x3“ und mit „Seerunde offen“ gerudert wurde
- **THEN** stehen die Runden beider Workouts in derselben Rangliste von „Seerunde“

#### Scenario: Länge geändert
- **WHEN** „Seerunde“ mit 1000 m gerudert, auf 1200 m geändert und wieder gerudert wurde
- **THEN** hat „Seerunde“ eine Rangliste für 1000 m und eine für 1200 m

#### Scenario: Nur Zonen geändert
- **WHEN** in „Seerunde“ eine Zone eingebaut wurde und die Länge gleich blieb
- **THEN** stehen die Runden vor und nach der Änderung in derselben Rangliste

### Requirement: Rangliste einer Zone
Die App SHALL pro Zone eine Rangliste führen, deren Einträge die Abschnitte vollständiger Runden sind, auf denen diese Zone lag, unabhängig von Strecke und Workout. Jede Fahrt durch die Zone ist ein eigener Eintrag, auch mehrere aus derselben Session. Nur Fahrten mit gleicher Zonenlänge zum Zeitpunkt des Ruderns MUST in derselben Rangliste stehen. Freie Abschnitte haben keine Rangliste.

#### Scenario: Über Strecken hinweg
- **WHEN** „Sprint“ in „2 km Intervall“ und in „Seerunde“ eingebaut ist und beide gerudert wurden
- **THEN** stehen die Sprints beider Strecken in derselben Rangliste von „Sprint“

#### Scenario: Mehrfach in einer Session
- **WHEN** „Sprint“ zweimal in einer Strecke steckt und diese dreimal vollständig gerudert wurde
- **THEN** ergibt die Session sechs Einträge, und alle drei Plätze dürfen aus ihr stammen

#### Scenario: Zone verlängert
- **WHEN** „Sprint“ mit 100 m gerudert, auf 150 m verlängert und wieder gerudert wurde
- **THEN** hat „Sprint“ eine Rangliste für 100 m und eine für 150 m

### Requirement: Nur echte Sessions zählen
Die Ranglisten SHALL nur Sessions enthalten, die an einem Rudergerät aufgezeichnet wurden. Simulierte und importierte Sessions MUST NOT zählen, auch wenn eine importierte Session an einem Rudergerät entstanden ist.

#### Scenario: Simulator
- **WHEN** der Nutzer „Seerunde x3“ mit dem Simulator rudert
- **THEN** erscheint die Session in keiner Rangliste

#### Scenario: Import
- **WHEN** der Nutzer eine am PM5 geruderte Session auf dem Laptop importiert
- **THEN** erscheint die Session dort in keiner Rangliste ihres Workouts, Strecke und Zonen und bekommt keine Platzmarken

### Requirement: Gelöschtes verlässt die Ranglisten
Wird eine Strecke, eine Zone oder ein Workout gelöscht, SHALL deren Rangliste nicht mehr angezeigt werden. Wird eine Session gelöscht, MUST sie aus allen Ranglisten verschwinden. Die Sessions selbst MUST beim Löschen einer Strecke, einer Zone oder eines Workouts erhalten bleiben.

#### Scenario: Zone gelöscht
- **WHEN** der Nutzer die Zone „Sprint“ löscht
- **THEN** gibt es keine Rangliste von „Sprint“ mehr, und die Sessions zeigen weiterhin ihre Sprints

#### Scenario: Vorlage gelöscht
- **WHEN** der Nutzer das Workout „Seerunde x3“ löscht
- **THEN** zählen ihre Runden weiter für die Strecke „Seerunde“

#### Scenario: Session gelöscht
- **WHEN** der Nutzer die Session auf Platz 1 von „Seerunde“ löscht
- **THEN** rücken die übrigen Einträge einen Platz vor

### Requirement: Plätze in der Workout-Wahl
Der Screen eines Workouts SHALL die Plätze 1–3 seiner Rangliste mit Wert, Pace und Datum zeigen, für die aktuelle Streckenlänge und Rundenzahl. Gibt es noch keinen Eintrag oder ist die Rundenzahl offen, MUST stattdessen ein Hinweis stehen und kein Platz.

#### Scenario: Zwei Einträge
- **WHEN** „Seerunde x3“ zweimal vollständig gerudert wurde und der Nutzer in der Workout-Liste seinen Screen öffnet
- **THEN** sieht er Platz 1 und 2 mit Zeit, Pace und Datum

#### Scenario: Noch nie gerudert
- **WHEN** der Nutzer den Screen eines neuen Workouts öffnet
- **THEN** steht dort, dass es noch keine Bestzeit gibt

### Requirement: Plätze in der Zusammenfassung
Die Zusammenfassung einer Session auf einem Workout SHALL jede Runde und jede Zonenfahrt markieren, die in ihrer Rangliste auf Platz 1–3 steht, und ebenso die Session, wenn sie in der Rangliste ihres Workouts auf Platz 1–3 steht. Die Marke MUST den Platz nennen und den aktuellen Stand der Rangliste wiedergeben.

#### Scenario: Neue zweitbeste Runde
- **WHEN** der Nutzer auf „Seerunde“ eine Runde in 4:08 rudert und nur eine Runde schneller war
- **THEN** zeigt die Zusammenfassung bei dieser Runde „Platz 2“

#### Scenario: Später überholt
- **WHEN** die Runde später von drei schnelleren Runden überholt wurde und der Nutzer die alte Zusammenfassung öffnet
- **THEN** trägt die Runde keine Marke mehr
