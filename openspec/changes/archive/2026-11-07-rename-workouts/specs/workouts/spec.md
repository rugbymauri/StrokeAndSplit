## Purpose

Lässt den Nutzer festlegen, was er rudern will: eine Strecke mit einer festen oder offenen Anzahl Runden. Workouts sind gespeicherte Startparameter, die sich mit einem Tippen starten lassen.

## ADDED Requirements

### Requirement: Workout anlegen
Der Nutzer SHALL ein Workout mit Namen anlegen können, das genau eine Strecke und eine Rundenzahl festlegt. Die Rundenzahl MUST entweder eine feste Zahl von mindestens 1 oder „offen“ sein. Bei „offen“ wird gerudert, bis der Nutzer die Session beendet.

#### Scenario: Feste Rundenzahl
- **WHEN** der Nutzer das Workout „Seerunde x3“ mit der Strecke „Seerunde“ und 3 Runden anlegt
- **THEN** erscheint „Seerunde x3 · Seerunde · 3 Runden“ in der Workout-Liste

#### Scenario: Offene Rundenzahl
- **WHEN** der Nutzer das Workout „Seerunde offen“ mit der Rundenzahl „offen“ anlegt
- **THEN** erscheint sie mit „offen“ statt einer Rundenzahl in der Liste

#### Scenario: Keine Strecke vorhanden
- **WHEN** der Nutzer ein Workout anlegen will und es gibt noch keine Strecke
- **THEN** bietet die App an, zuerst eine Strecke anzulegen

### Requirement: Workouts auflisten, bearbeiten und löschen
Die App SHALL alle Workouts mit Name, Strecke und Rundenzahl auflisten. Der Nutzer SHALL Name, Strecke und Rundenzahl eines Workouts ändern und ein Workout nach Bestätigung löschen können. Sessions, die mit einem gelöschten Workout gerudert wurden, MUST erhalten bleiben.

#### Scenario: Rundenzahl ändern
- **WHEN** der Nutzer bei „Seerunde x3“ die Rundenzahl auf 4 ändert
- **THEN** startet das Workout künftig mit 4 Runden und bereits geruderte Sessions zeigen weiterhin ihre 3 Runden

#### Scenario: Workout löschen
- **WHEN** der Nutzer das Workout „Seerunde x3“ löscht und bestätigt
- **THEN** verschwindet sie aus der Liste und die damit geruderten Sessions bleiben in der Session-Liste

### Requirement: Workout starten
Der Nutzer SHALL ein Workout auswählen und mit einer verbundenen Datenquelle (PM5, Simulator) starten können. Mit dem Start beginnt sofort eine aufgezeichnete Session, die mit dem Workout und der aktuellen Version ihrer Strecke verknüpft ist.

#### Scenario: Workout mit dem PM5 starten
- **WHEN** der Nutzer mit verbundenem PM5 das Workout „Seerunde x3“ startet
- **THEN** läuft eine Session auf der Strecke „Seerunde“ mit Runde 1 von 3

#### Scenario: Workout mit dem Simulator starten
- **WHEN** der Nutzer den Simulator als Quelle wählt und ein Workout startet
- **THEN** läuft die Session wie mit dem PM5 und ist als simuliert gekennzeichnet

### Requirement: Frei rudern bleibt möglich
Das Rudern ohne Workout SHALL unverändert möglich bleiben. Eine Session ohne Workout hat keine Runden und keine Zonen.

#### Scenario: Ohne Workout
- **WHEN** der Nutzer im Live-Display ohne Workout „Session starten“ wählt
- **THEN** läuft eine Session wie bisher, ohne Runden- und Zonenanzeige

### Requirement: Workout auf eigenem Screen
Ein Tipp auf ein Workout in der Workout-Liste SHALL einen eigenen Screen dieses Workouts öffnen. Er MUST Name, Strecke, Rundenzahl und Zonen des Workouts zeigen und „Starten“ sowie Bearbeiten anbieten. Die Karten der Liste MUST NOT aufklappen. „Zurück“ führt zur Liste.

#### Scenario: Workout öffnen
- **WHEN** der Nutzer in der Workout-Liste „Seerunde x3“ antippt
- **THEN** öffnet sich der Screen „Seerunde x3“ mit Strecke „Seerunde“, 3 Runden, den Zonen der Strecke und dem Button „Starten“

#### Scenario: Zurück zur Liste
- **WHEN** der Nutzer auf dem Screen von „Seerunde x3“ zurück geht
- **THEN** zeigt die App die Workout-Liste, keine Karte ist aufgeklappt

#### Scenario: Starten vom Screen
- **WHEN** der Nutzer auf dem Screen von „Seerunde x3“ „Starten“ wählt
- **THEN** startet das Workout wie unter „Workout starten“ beschrieben

### Requirement: Workout auf dem Screen bearbeiten
Vom Screen eines Workouts aus SHALL der Nutzer das Workout bearbeiten können. Nach dem Speichern MUST der Screen das geänderte Workout zeigen. Wird das Workout im Editor gelöscht, MUST die App zur Workout-Liste zurückkehren.

#### Scenario: Name ändern
- **WHEN** der Nutzer auf dem Screen von „Seerunde x3“ das Workout bearbeitet und es in „Seerunde dreimal“ umbenennt
- **THEN** zeigt der Screen danach „Seerunde dreimal“

#### Scenario: Workout gelöscht
- **WHEN** der Nutzer das Workout vom Screen aus bearbeitet und im Editor löscht
- **THEN** zeigt die App die Workout-Liste ohne dieses Workout
