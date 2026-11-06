# Spec Delta

## Purpose

Lässt den Nutzer eine Strecke direkt rudern, ohne eine Vorlage anzulegen: Er wählt die Strecke, legt Runden, eine Gesamtdauer oder offen fest und startet.

## ADDED Requirements

### Requirement: Strecke aus der Detailansicht rudern
Die Detailansicht einer Strecke SHALL einen Button „Rudern“ anbieten. Er MUST einen Start-Screen für diese Strecke öffnen, der Name, Segmentbalken und Länge der Strecke zeigt. „Zurück“ vom Start-Screen führt zur Detailansicht.

#### Scenario: Rudern antippen
- **WHEN** der Nutzer in der Detailansicht von „Seerunde“ „Rudern“ antippt
- **THEN** öffnet sich der Start-Screen von „Seerunde“ mit ihrem Segmentbalken und ihrer Länge

#### Scenario: Zurück zur Detailansicht
- **WHEN** der Nutzer auf dem Start-Screen von „Seerunde“ zurück geht
- **THEN** zeigt die App wieder die Detailansicht von „Seerunde“

### Requirement: Runden, Dauer oder offen wählen
Der Start-Screen SHALL drei Optionen anbieten, von denen genau eine gewählt ist: Runden, Dauer und offen. Er MUST nur die Eingabe der gewählten Option zeigen. Beim Öffnen ist „Runden“ gewählt.

#### Scenario: Auf Dauer wechseln
- **WHEN** der Nutzer auf dem Start-Screen von „Runden“ auf „Dauer“ wechselt
- **THEN** verschwindet die Rundenzahl, und die Dauer erscheint

#### Scenario: Offen wählen
- **WHEN** der Nutzer „offen“ wählt
- **THEN** zeigt der Screen keine Eingabe, nur den Hinweis, dass bis zum Beenden der Session gerudert wird

#### Scenario: Werte bleiben beim Wechseln
- **WHEN** der Nutzer 5 Runden einstellt, auf „Dauer“ und wieder auf „Runden“ wechselt
- **THEN** zeigt die Rundenzahl wieder 5

### Requirement: Rundenzahl einstellen
Bei „Runden“ SHALL der Nutzer die Rundenzahl mit − und + in Schritten von 1 einstellen können. Sie MUST mindestens 1 sein. Beim Öffnen steht sie auf 3.

#### Scenario: Untergrenze
- **WHEN** die Rundenzahl 1 ist
- **THEN** ist − gesperrt

### Requirement: Dauer einstellen
Bei „Dauer“ SHALL der Nutzer die Gesamtdauer mit − und + in Schritten von 1 min einstellen können, von 1 bis 180 min. Beim Öffnen steht sie auf 30 min. Die Dauer MUST als Minuten und Sekunden, ab einer Stunde mit Stunden angezeigt werden.

#### Scenario: Grenzen
- **WHEN** die Dauer 1 min oder 180 min ist
- **THEN** ist − bzw. + gesperrt

#### Scenario: Über eine Stunde
- **WHEN** der Nutzer die Dauer auf 90 min stellt
- **THEN** zeigt der Screen „1:30:00“

### Requirement: Starten ohne Vorlage
„Starten“ SHALL eine Session auf der Strecke mit der gewählten Option beginnen, mit derselben Verbindung wie beim Start einer Vorlage. Dabei MUST NOT eine Vorlage angelegt werden. Die Wahl auf dem Start-Screen MUST NOT gespeichert werden; jedes Öffnen beginnt mit den Vorgaben.

#### Scenario: 30 min auf der Seerunde
- **WHEN** der Nutzer auf dem Start-Screen von „Seerunde“ „Dauer“ mit 30 min wählt und „Starten“ antippt
- **THEN** läuft eine Session auf „Seerunde“, die nach 30 min Ruderzeit endet, und die Vorlagenliste bleibt unverändert

#### Scenario: Erneut öffnen
- **WHEN** der Nutzer nach einer Session mit 45 min den Start-Screen wieder öffnet
- **THEN** ist „Runden“ mit 3 gewählt
