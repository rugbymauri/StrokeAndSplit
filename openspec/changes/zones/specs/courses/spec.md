# Spec Delta

## ADDED Requirements

### Requirement: Zonen in eine Strecke einbauen
Der Nutzer SHALL vordefinierte Zonen in eine Strecke einbauen können, jede mit einer Startposition in der Achse der Strecke. Eine Zone MUST dieselbe Achse wie die Strecke haben, ganz innerhalb der Strecke liegen und darf keine andere eingebaute Zone überschneiden. Dieselbe Zone darf mehrfach eingebaut werden. Abschnitte ohne Zone sind frei.

#### Scenario: Intervallstrecke aufbauen
- **WHEN** der Nutzer in die 2000-m-Strecke „2 km Intervall“ die Zone „Sprint“ (100 m) ab 500 m und die Zone „Ausdauer 2:30“ (500 m) ab 1000 m einbaut
- **THEN** zeigt der Editor den Ablauf 0–500 m frei, 500–600 m Sprint, 600–1000 m frei, 1000–1500 m Ausdauer 2:30 und 1500–2000 m frei

#### Scenario: Überschneidung
- **WHEN** der Nutzer „Ausdauer 2:30“ ab 1300 m einbauen will und dort schon eine Zone von 1000 bis 1500 m liegt
- **THEN** wird die Zone nicht eingebaut und der Editor zeigt die Überschneidung

#### Scenario: Über das Ende hinaus
- **WHEN** der Nutzer eine 500-m-Zone ab 1800 m in eine 2000-m-Strecke einbauen will
- **THEN** wird sie nicht eingebaut und der Editor zeigt, dass sie über das Streckenende ragt

#### Scenario: Falsche Achse
- **WHEN** der Nutzer in eine Distanzstrecke eine Zone mit der Achse Zeit einbauen will
- **THEN** ist diese Zone in der Auswahl nicht wählbar

### Requirement: Zonenänderungen versionieren geruderte Strecken
Ändert sich eine eingebaute Zone oder wird sie gelöscht, SHALL jede betroffene Strecke wie bei einer eigenen Definitionsänderung behandelt werden: Wurde die aktuelle Version schon gerudert, entsteht eine neue Version, sonst wird sie angepasst. Bestehende Sessions MUST mit der Version verknüpft bleiben, die gerudert wurde.

#### Scenario: Zone einer geruderten Strecke ändern
- **WHEN** „2 km Intervall“ schon gerudert wurde und der Nutzer das Pace-Band von „Ausdauer 2:30“ auf 2:25–2:30 ändert
- **THEN** zeigen alte Sessions weiterhin 2:28–2:32 und neue Sessions rudern mit 2:25–2:30

## MODIFIED Requirements

### Requirement: Strecke in Segmente teilen
Eine Strecke SHALL sich aus ihren eingebauten Zonen und den freien Abschnitten dazwischen zusammensetzen, die zusammen genau die Länge der Strecke ergeben. Eine neue Strecke MUST ohne Zonen beginnen und ist dann ein einziger freier Abschnitt. Ändert der Nutzer die Länge der Strecke, MUST die App die Änderung ablehnen, wenn danach eine eingebaute Zone über das Streckenende ragen würde.

#### Scenario: Neue Strecke
- **WHEN** der Nutzer die Strecke „Locker 5 km“ mit 5000 m anlegt
- **THEN** besteht sie aus einem freien Abschnitt von 0 bis 5000 m

#### Scenario: Strecke zu kurz für ihre Zonen
- **WHEN** der Nutzer „2 km Intervall“ mit einer Zone von 1000 bis 1500 m auf 1200 m kürzen will
- **THEN** wird die Länge nicht gespeichert und der Editor nennt die Zone, die nicht mehr passt

## REMOVED Requirements

### Requirement: Zielbänder pro Segment
**Reason**: Bänder gehören jetzt zu Zonen, die als eigene Bausteine definiert und in Strecken eingebaut werden.
**Migration**: Bestehende Segmente mit Band werden beim Update zu Zonen und an ihrer Position eingebaut (siehe `design.md`, D5). Bänder legt der Nutzer künftig im Zonen-Editor fest.
