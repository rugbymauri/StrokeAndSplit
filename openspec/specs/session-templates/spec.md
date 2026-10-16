# session-templates Specification

## Purpose

Lässt den Nutzer festlegen, was er rudern will: eine Strecke mit einer festen oder offenen Anzahl Runden. Vorlagen sind gespeicherte Startparameter, die sich mit einem Tippen starten lassen.

## Requirements

### Requirement: Vorlage anlegen
Der Nutzer SHALL eine Vorlage mit Namen anlegen können, die genau eine Strecke und eine Rundenzahl festlegt. Die Rundenzahl MUST entweder eine feste Zahl von mindestens 1 oder „offen“ sein. Bei „offen“ wird gerudert, bis der Nutzer die Session beendet.

#### Scenario: Feste Rundenzahl
- **WHEN** der Nutzer die Vorlage „Seerunde x3“ mit der Strecke „Seerunde“ und 3 Runden anlegt
- **THEN** erscheint „Seerunde x3 · Seerunde · 3 Runden“ in der Vorlagenliste

#### Scenario: Offene Rundenzahl
- **WHEN** der Nutzer die Vorlage „Seerunde offen“ mit der Rundenzahl „offen“ anlegt
- **THEN** erscheint sie mit „offen“ statt einer Rundenzahl in der Liste

#### Scenario: Keine Strecke vorhanden
- **WHEN** der Nutzer eine Vorlage anlegen will und es gibt noch keine Strecke
- **THEN** bietet die App an, zuerst eine Strecke anzulegen

### Requirement: Vorlagen auflisten, bearbeiten und löschen
Die App SHALL alle Vorlagen mit Name, Strecke und Rundenzahl auflisten. Der Nutzer SHALL Name, Strecke und Rundenzahl einer Vorlage ändern und eine Vorlage nach Bestätigung löschen können. Sessions, die mit einer gelöschten Vorlage gerudert wurden, MUST erhalten bleiben.

#### Scenario: Rundenzahl ändern
- **WHEN** der Nutzer bei „Seerunde x3“ die Rundenzahl auf 4 ändert
- **THEN** startet die Vorlage künftig mit 4 Runden und bereits geruderte Sessions zeigen weiterhin ihre 3 Runden

#### Scenario: Vorlage löschen
- **WHEN** der Nutzer die Vorlage „Seerunde x3“ löscht und bestätigt
- **THEN** verschwindet sie aus der Liste und die damit geruderten Sessions bleiben in der Session-Liste

### Requirement: Vorlage starten
Der Nutzer SHALL eine Vorlage auswählen und mit einer verbundenen Datenquelle (PM5, Simulator) starten können. Mit dem Start beginnt sofort eine aufgezeichnete Session, die mit der Vorlage und der aktuellen Version ihrer Strecke verknüpft ist.

#### Scenario: Vorlage mit dem PM5 starten
- **WHEN** der Nutzer mit verbundenem PM5 die Vorlage „Seerunde x3“ startet
- **THEN** läuft eine Session auf der Strecke „Seerunde“ mit Runde 1 von 3

#### Scenario: Vorlage mit dem Simulator starten
- **WHEN** der Nutzer den Simulator als Quelle wählt und eine Vorlage startet
- **THEN** läuft die Session wie mit dem PM5 und ist als simuliert gekennzeichnet

### Requirement: Frei rudern bleibt möglich
Das Rudern ohne Vorlage SHALL unverändert möglich bleiben. Eine Session ohne Vorlage hat keine Runden und keine Zonen.

#### Scenario: Ohne Vorlage
- **WHEN** der Nutzer im Live-Display ohne Vorlage „Session starten“ wählt
- **THEN** läuft eine Session wie bisher, ohne Runden- und Zonenanzeige
