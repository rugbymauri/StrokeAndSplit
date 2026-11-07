# Spec Delta

## ADDED Requirements

### Requirement: Geplante Dauer speichern
Eine Session mit Gesamtdauer SHALL die geplante Dauer speichern. Der Export als Datei MUST sie enthalten, und der Import MUST sie wiederherstellen. Eine Datei ohne geplante Dauer MUST weiterhin importierbar sein.

#### Scenario: Export und Import
- **WHEN** der Nutzer eine Session mit 30 min auf „Seerunde“ exportiert und wieder importiert
- **THEN** zeigt die importierte Session „Seerunde · 30 min“ und dieselben Runden

#### Scenario: Ältere Datei
- **WHEN** der Nutzer eine Datei importiert, die vor diesem Change exportiert wurde
- **THEN** wird sie wie bisher importiert, ohne geplante Dauer

### Requirement: Session ohne Vorlage in der Liste
Die Session-Liste SHALL eine Session ohne Vorlage auf einer Strecke mit dem Namen der Strecke und der geplanten Länge zeigen: Rundenzahl, Dauer oder „offen“.

#### Scenario: Dauer in der Liste
- **WHEN** der Nutzer 30 min auf „Seerunde“ ohne Vorlage gerudert hat und die Session-Liste öffnet
- **THEN** zeigt der Eintrag „Seerunde · 30 min“
