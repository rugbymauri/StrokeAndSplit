# courses Specification

## Purpose

Lässt den Nutzer wiederverwendbare Strecken definieren: eine Länge in Metern oder Minuten, unterteilt in Segmente mit optionalen Zielbändern für Pace und Schlagzahl. Strecken sind die Grundlage für Vorlagen, Rundenvergleiche und den späteren Ghost.

## Requirements

### Requirement: Strecke mit einer Achse anlegen
Der Nutzer SHALL eine Strecke mit Namen anlegen können, die entweder distanzbasiert (Länge in Metern) oder zeitbasiert (Länge in Minuten und Sekunden) ist. Eine Strecke MUST genau eine dieser Achsen haben, und ihre Länge MUST grösser als null sein.

#### Scenario: Distanzstrecke anlegen
- **WHEN** der Nutzer die Strecke „Seerunde“ mit der Achse Distanz und 1000 m anlegt
- **THEN** erscheint „Seerunde, 1000 m“ in der Streckenliste

#### Scenario: Zeitstrecke anlegen
- **WHEN** der Nutzer die Strecke „Vier Minuten“ mit der Achse Zeit und 4:00 anlegt
- **THEN** erscheint „Vier Minuten, 4:00“ in der Streckenliste

#### Scenario: Länge null
- **WHEN** der Nutzer eine Strecke mit 0 m speichern will
- **THEN** wird sie nicht gespeichert und der Nutzer sieht, dass die Länge fehlt

### Requirement: Strecke in Segmente teilen
Eine Strecke SHALL sich aus ihren eingebauten Zonen und den freien Abschnitten dazwischen zusammensetzen, die zusammen genau die Länge der Strecke ergeben. Eine neue Strecke MUST ohne Zonen beginnen und ist dann ein einziger freier Abschnitt. Ändert der Nutzer die Länge der Strecke, MUST die App die Änderung ablehnen, wenn danach eine eingebaute Zone über das Streckenende ragen würde.

#### Scenario: Neue Strecke
- **WHEN** der Nutzer die Strecke „Locker 5 km“ mit 5000 m anlegt
- **THEN** besteht sie aus einem freien Abschnitt von 0 bis 5000 m

#### Scenario: Strecke zu kurz für ihre Zonen
- **WHEN** der Nutzer „2 km Intervall“ mit einer Zone von 1000 bis 1500 m auf 1200 m kürzen will
- **THEN** wird die Länge nicht gespeichert und der Editor nennt die Zone, die nicht mehr passt

### Requirement: Strecken auflisten und bearbeiten
Die App SHALL alle Strecken in einer Liste mit Name, Achse und Länge anzeigen. Der Nutzer SHALL Name, Länge, Segmente und Bänder einer Strecke bearbeiten können.

#### Scenario: Strecke umbenennen
- **WHEN** der Nutzer die Strecke „Seerunde“ in „Seerunde lang“ umbenennt
- **THEN** zeigt die Liste „Seerunde lang“

### Requirement: Geruderte Strecken versionieren
Ändert der Nutzer Länge, Segmente oder Bänder einer Strecke, die bereits in einer Session gerudert wurde, SHALL die Änderung als neue Version der Strecke gespeichert werden. Bestehende Sessions MUST mit der Version verknüpft bleiben, die gerudert wurde. Die Liste zeigt nur die neueste Version.

#### Scenario: Gerudert, dann geändert
- **WHEN** die Strecke „Seerunde“ mit 1000 m schon gerudert wurde und der Nutzer sie auf 1200 m ändert
- **THEN** zeigen alte Sessions weiterhin 1000 m und neue Sessions rudern 1200 m

#### Scenario: Nur umbenannt
- **WHEN** der Nutzer eine bereits geruderte Strecke nur umbenennt
- **THEN** entsteht keine neue Version und auch alte Sessions zeigen den neuen Namen

### Requirement: Strecke löschen
Der Nutzer SHALL eine Strecke nach Bestätigung löschen können. Eine gelöschte Strecke verschwindet aus der Streckenliste und aus der Auswahl für Vorlagen. Sessions, die auf ihr gerudert wurden, MUST mit ihren Runden erhalten bleiben.

#### Scenario: Geruderte Strecke löschen
- **WHEN** der Nutzer die bereits geruderte Strecke „Seerunde“ löscht und bestätigt
- **THEN** ist sie nicht mehr in der Streckenliste und die alten Sessions zeigen weiterhin ihre Rundenzeiten auf „Seerunde“

#### Scenario: Strecke einer Vorlage löschen
- **WHEN** der Nutzer eine Strecke löschen will, die eine Vorlage verwendet
- **THEN** weist die Bestätigung darauf hin, dass auch die Vorlage gelöscht wird

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
