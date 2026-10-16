# Spec Delta

## ADDED Requirements

### Requirement: Wanduhr-Zeitachse aufzeichnen
Die App SHALL zu jedem gespeicherten Messwert einer Session zusätzlich zur Zeit des PM5 die seit Session-Beginn vergangene Wanduhr-Zeit speichern. Die Wanduhr-Zeit MUST auch dann weiterlaufen, wenn der PM5 seine Uhr in einer Pause anhält.

#### Scenario: Pause in einer Session
- **WHEN** der Nutzer nach 2 Minuten Rudern 30 Sekunden pausiert und dann weiterrudert
- **THEN** zeigt der nächste Messwert eine PM5-Zeit von etwa 2:00 und eine Wanduhr-Zeit von etwa 2:30

#### Scenario: Bestehende Sessions nach dem Update
- **WHEN** die App mit Sessions aus einer früheren Version aktualisiert wird
- **THEN** bleiben diese Sessions mit Zusammenfassung, Verlauf und Replay erhalten

### Requirement: Session einer Vorlage zuordnen
Eine Session, die mit einer Vorlage gestartet wurde, SHALL mit der Vorlage und der geruderten Version ihrer Strecke verknüpft sein. Die Session-Liste MUST bei solchen Sessions den Namen der Vorlage anzeigen.

#### Scenario: Liste mit Vorlagen-Session
- **WHEN** der Nutzer die Session-Liste öffnet und eine Session mit der Vorlage „Seerunde x3“ gerudert hat
- **THEN** zeigt der Eintrag „Seerunde x3“ zusätzlich zu Datum, Dauer, Distanz und Pace

#### Scenario: Vorlage später gelöscht
- **WHEN** die Vorlage einer Session gelöscht wurde
- **THEN** zeigt die Session weiterhin den Namen der Vorlage und der Strecke, mit dem sie gerudert wurde
