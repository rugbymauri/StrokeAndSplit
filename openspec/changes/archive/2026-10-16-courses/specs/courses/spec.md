# Spec Delta

## Purpose

Lässt den Nutzer wiederverwendbare Strecken definieren: eine Länge in Metern oder Minuten, unterteilt in Segmente mit optionalen Zielbändern für Pace und Schlagzahl. Strecken sind die Grundlage für Vorlagen, Rundenvergleiche und den späteren Ghost.

## ADDED Requirements

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
Eine Strecke SHALL aus einem oder mehreren aufeinanderfolgenden Segmenten bestehen, die zusammen genau die Länge der Strecke ergeben. Segmentlängen werden in der Achse der Strecke angegeben. Eine neue Strecke MUST mit einem einzigen Segment über die ganze Länge beginnen.

#### Scenario: Strecke unterteilen
- **WHEN** der Nutzer die 1000-m-Strecke in Segmente von 200 m, 600 m und 200 m teilt
- **THEN** zeigt der Editor drei Segmente mit den Grenzen 200 m und 800 m

#### Scenario: Segmente passen nicht zur Länge
- **WHEN** die Segmente einer 1000-m-Strecke zusammen 900 m ergeben
- **THEN** kann die Strecke nicht gespeichert werden und der Editor zeigt die Abweichung von 100 m

### Requirement: Zielbänder pro Segment
Jedes Segment SHALL optional ein Pace-Band (schnellste und langsamste Pace pro 500 m) und optional ein Schlagzahl-Band (niedrigste und höchste Schlagzahl) haben können. Ein Band MUST eine Untergrenze haben, die nicht über der Obergrenze liegt. Ein Segment ohne Band ist ein freier Abschnitt.

#### Scenario: Segment mit beiden Bändern
- **WHEN** der Nutzer für das mittlere Segment das Pace-Band 2:05–2:10 und das Schlagzahl-Band 20–22 setzt
- **THEN** zeigt die Strecke für dieses Segment „2:05–2:10 · 20–22 spm“

#### Scenario: Freies Segment
- **WHEN** der Nutzer für ein Segment kein Band setzt
- **THEN** ist es als freier Abschnitt gekennzeichnet

#### Scenario: Vertauschte Grenzen
- **WHEN** der Nutzer als Pace-Band 2:10–2:05 eingibt, also die langsamere Pace als schnellste Grenze
- **THEN** wird das Band nicht gespeichert und der Nutzer sieht den Fehler

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
