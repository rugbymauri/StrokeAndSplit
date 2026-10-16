# Spec Delta

## Purpose

Bestimmt aus den geruderten Sessions die besten Leistungen pro Vorlage, Strecke und Zone und zeigt die Plätze 1–3. Platz 1 jeder Ebene ist der Ghost, gegen den gerudert wird.

## ADDED Requirements

### Requirement: Leistung nach Achse werten
Ein Eintrag einer Rangliste SHALL auf einer Distanzachse nach der benötigten Zeit und auf einer Zeitachse nach den erreichten Metern gewertet werden, beides nach Wanduhr inklusive Pausen. Kürzere Zeit bzw. mehr Meter MUST besser platziert sein. Bei Gleichstand MUST der frühere Eintrag vorne liegen. Zu jedem Eintrag SHALL die App das Datum der Session und die Pace pro 500 m zeigen.

#### Scenario: Distanzzone
- **WHEN** die 100-m-Zone „Sprint“ einmal in 18.9 s und einmal in 18.2 s gerudert wurde
- **THEN** steht 18.2 s auf Platz 1 und 18.9 s auf Platz 2, jeweils mit Datum und Pace

#### Scenario: Zeitstrecke
- **WHEN** auf der 4-min-Strecke „Vier Minuten“ Runden mit 1012 m und 1030 m gerudert wurden
- **THEN** steht 1030 m auf Platz 1

#### Scenario: Pause zählt mit
- **WHEN** eine 1000-m-Runde in 4:00 Ruderzeit mit 30 Sekunden Pause gerudert wurde
- **THEN** zählt sie mit 4:30

#### Scenario: Gleichstand
- **WHEN** zwei Runden mit 4:08.0 gerudert wurden, am 1. und am 5. Oktober
- **THEN** steht die Runde vom 1. Oktober vorne

### Requirement: Rangliste einer Vorlage
Die App SHALL pro Vorlage eine Rangliste führen, deren Einträge Sessions sind, in denen alle geplanten Runden vollständig gerudert wurden. Gewertet wird die Summe der Rundenzeiten bzw. Rundendistanzen. Nur Sessions mit gleicher Streckenlänge und gleicher Rundenzahl MUST in derselben Rangliste stehen. Eine Vorlage mit offener Rundenzahl hat keine Rangliste.

#### Scenario: Drei Runden
- **WHEN** „Seerunde x3“ zweimal vollständig gerudert wurde, in 12:31.8 und 12:24.1
- **THEN** steht 12:24.1 auf Platz 1 der Rangliste von „Seerunde x3“

#### Scenario: Abgebrochene Session
- **WHEN** eine Session auf „Seerunde x3“ nach Runde 2 beendet wurde
- **THEN** steht sie nicht in der Rangliste der Vorlage

#### Scenario: Rundenzahl geändert
- **WHEN** „Seerunde x3“ auf 4 Runden geändert und danach gerudert wurde
- **THEN** stehen die 4-Runden-Sessions in einer eigenen Rangliste und die 3-Runden-Sessions bleiben in ihrer

#### Scenario: Offene Rundenzahl
- **WHEN** die Vorlage „Seerunde offen“ gerudert wurde
- **THEN** zeigt die Vorlage keine Plätze, ihre Runden zählen aber für die Strecke

### Requirement: Rangliste einer Strecke
Die App SHALL pro Strecke eine Rangliste führen, deren Einträge vollständige Runden auf dieser Strecke sind, unabhängig von der Vorlage. Runden auf Versionen gleicher Länge MUST in derselben Rangliste stehen. Hatte die Strecke verschiedene Längen, SHALL es eine Rangliste pro Länge geben. Unvollständige Runden MUST NOT zählen.

#### Scenario: Über Vorlagen hinweg
- **WHEN** „Seerunde“ mit „Seerunde x3“ und mit „Seerunde offen“ gerudert wurde
- **THEN** stehen die Runden beider Vorlagen in derselben Rangliste von „Seerunde“

#### Scenario: Länge geändert
- **WHEN** „Seerunde“ mit 1000 m gerudert, auf 1200 m geändert und wieder gerudert wurde
- **THEN** hat „Seerunde“ eine Rangliste für 1000 m und eine für 1200 m

#### Scenario: Nur Zonen geändert
- **WHEN** in „Seerunde“ eine Zone eingebaut wurde und die Länge gleich blieb
- **THEN** stehen die Runden vor und nach der Änderung in derselben Rangliste

### Requirement: Rangliste einer Zone
Die App SHALL pro Zone eine Rangliste führen, deren Einträge die Abschnitte vollständiger Runden sind, auf denen diese Zone lag, unabhängig von Strecke und Vorlage. Jede Fahrt durch die Zone ist ein eigener Eintrag, auch mehrere aus derselben Session. Nur Fahrten mit gleicher Zonenlänge zum Zeitpunkt des Ruderns MUST in derselben Rangliste stehen. Freie Abschnitte haben keine Rangliste.

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
- **THEN** erscheint die Session dort in keiner Rangliste ihrer Vorlage, Strecke und Zonen und bekommt keine Platzmarken

### Requirement: Gelöschtes verlässt die Ranglisten
Wird eine Strecke, Zone oder Vorlage gelöscht, SHALL ihre Rangliste nicht mehr angezeigt werden. Wird eine Session gelöscht, MUST sie aus allen Ranglisten verschwinden. Die Sessions selbst MUST beim Löschen einer Strecke, Zone oder Vorlage erhalten bleiben.

#### Scenario: Zone gelöscht
- **WHEN** der Nutzer die Zone „Sprint“ löscht
- **THEN** gibt es keine Rangliste von „Sprint“ mehr, und die Sessions zeigen weiterhin ihre Sprints

#### Scenario: Vorlage gelöscht
- **WHEN** der Nutzer die Vorlage „Seerunde x3“ löscht
- **THEN** zählen ihre Runden weiter für die Strecke „Seerunde“

#### Scenario: Session gelöscht
- **WHEN** der Nutzer die Session auf Platz 1 von „Seerunde“ löscht
- **THEN** rücken die übrigen Einträge einen Platz vor

### Requirement: Plätze in der Vorlagenwahl
Die Vorlagenwahl SHALL bei einer aufgeklappten Vorlage die Plätze 1–3 ihrer Rangliste mit Wert, Pace und Datum zeigen, für die aktuelle Streckenlänge und Rundenzahl. Gibt es noch keinen Eintrag oder ist die Rundenzahl offen, MUST stattdessen ein Hinweis stehen und kein Platz.

#### Scenario: Zwei Einträge
- **WHEN** „Seerunde x3“ zweimal vollständig gerudert wurde und der Nutzer sie in der Vorlagenwahl aufklappt
- **THEN** sieht er Platz 1 und 2 mit Zeit, Pace und Datum

#### Scenario: Noch nie gerudert
- **WHEN** der Nutzer eine neue Vorlage aufklappt
- **THEN** steht dort, dass es noch keine Bestzeit gibt

### Requirement: Detailansicht von Strecke und Zone
Aus der Strecken- und der Zonenliste SHALL der Nutzer eine Detailansicht öffnen können, die die Plätze 1–3 jeder Rangliste mit Wert, Pace und Datum zeigt. Hat eine Strecke oder Zone mehrere Längen, MUST die Rangliste der aktuellen Länge zuerst stehen. Von der Detailansicht aus SHALL der Nutzer die Strecke bzw. Zone bearbeiten können.

#### Scenario: Zone ansehen
- **WHEN** der Nutzer in der Zonenliste „Sprint“ antippt
- **THEN** sieht er die drei schnellsten Sprints mit Zeit, Pace und Datum

#### Scenario: Mehrere Längen
- **WHEN** die Strecke „Seerunde“ mit 1000 m und mit 1200 m gerudert wurde und heute 1200 m lang ist
- **THEN** zeigt die Detailansicht zuerst die Rangliste für 1200 m und darunter die für 1000 m

### Requirement: Plätze in der Zusammenfassung
Die Zusammenfassung einer Session auf einer Vorlage SHALL jede Runde und jede Zonenfahrt markieren, die in ihrer Rangliste auf Platz 1–3 steht, und ebenso die Session, wenn sie in der Rangliste ihrer Vorlage auf Platz 1–3 steht. Die Marke MUST den Platz nennen und den aktuellen Stand der Rangliste wiedergeben.

#### Scenario: Neue zweitbeste Runde
- **WHEN** der Nutzer auf „Seerunde“ eine Runde in 4:08 rudert und nur eine Runde schneller war
- **THEN** zeigt die Zusammenfassung bei dieser Runde „Platz 2“

#### Scenario: Später überholt
- **WHEN** die Runde später von drei schnelleren Runden überholt wurde und der Nutzer die alte Zusammenfassung öffnet
- **THEN** trägt die Runde keine Marke mehr
