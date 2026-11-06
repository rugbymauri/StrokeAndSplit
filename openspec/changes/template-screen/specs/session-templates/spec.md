# Spec Delta

## ADDED Requirements

### Requirement: Vorlage auf eigenem Screen
Ein Tipp auf eine Vorlage in der Vorlagenliste SHALL einen eigenen Screen dieser Vorlage öffnen. Er MUST Name, Strecke, Rundenzahl und Zonen der Vorlage zeigen und „Starten“ sowie Bearbeiten anbieten. Die Karten der Liste MUST NOT aufklappen. „Zurück“ führt zur Liste.

#### Scenario: Vorlage öffnen
- **WHEN** der Nutzer in der Vorlagenliste „Seerunde x3“ antippt
- **THEN** öffnet sich der Screen „Seerunde x3“ mit Strecke „Seerunde“, 3 Runden, den Zonen der Strecke und dem Button „Starten“

#### Scenario: Zurück zur Liste
- **WHEN** der Nutzer auf dem Screen von „Seerunde x3“ zurück geht
- **THEN** zeigt die App die Vorlagenliste, keine Karte ist aufgeklappt

#### Scenario: Starten vom Screen
- **WHEN** der Nutzer auf dem Screen von „Seerunde x3“ „Starten“ wählt
- **THEN** startet die Vorlage wie unter „Vorlage starten“ beschrieben

### Requirement: Vorlage auf dem Screen bearbeiten
Vom Screen einer Vorlage aus SHALL der Nutzer die Vorlage bearbeiten können. Nach dem Speichern MUST der Screen die geänderte Vorlage zeigen. Wird die Vorlage im Editor gelöscht, MUST die App zur Vorlagenliste zurückkehren.

#### Scenario: Name ändern
- **WHEN** der Nutzer auf dem Screen von „Seerunde x3“ die Vorlage bearbeitet und sie in „Seerunde dreimal“ umbenennt
- **THEN** zeigt der Screen danach „Seerunde dreimal“

#### Scenario: Vorlage gelöscht
- **WHEN** der Nutzer die Vorlage vom Screen aus bearbeitet und im Editor löscht
- **THEN** zeigt die App die Vorlagenliste ohne diese Vorlage

### Requirement: Nochmal öffnet die Vorlage
Die Kachel „Nochmal“ auf dem Startbildschirm SHALL die Vorlagenliste und darüber sofort den Screen der Vorlage öffnen, die sie zeigt. „Zurück“ vom Screen MUST zur Vorlagenliste führen.

#### Scenario: Nochmal antippen
- **WHEN** der Nutzer auf dem Startbildschirm die Kachel „Nochmal“ mit „Seerunde x3“ antippt
- **THEN** zeigt die App den Screen von „Seerunde x3“

#### Scenario: Zurück nach Nochmal
- **WHEN** der Nutzer nach „Nochmal“ auf dem Screen von „Seerunde x3“ zurück geht
- **THEN** zeigt die App die Vorlagenliste, ein weiteres Zurück den Startbildschirm
