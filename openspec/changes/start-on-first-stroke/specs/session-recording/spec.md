## MODIFIED Requirements

### Requirement: Session starten und beenden
Der Nutzer SHALL eine Session in der App starten und beenden können, solange eine Datenquelle verbunden ist. Distanz und Zeit der Session MUST ab dem Start der Session zählen, unabhängig vom Stand der PM5-Anzeige. Bei freiem Rudern startet die Session mit „Session starten“, mit einer Vorlage erst mit dem ersten Ruderschlag.

#### Scenario: Session starten
- **WHEN** der Nutzer mit verbundenem PM5 „Session starten“ wählt, während der PM5 bereits 500 m anzeigt
- **THEN** beginnt die Session bei 0 m und 0:00

#### Scenario: Session beenden
- **WHEN** der Nutzer „Session beenden“ wählt
- **THEN** wird die Session gespeichert und ihre Zusammenfassung angezeigt

#### Scenario: Vorlage gewählt
- **WHEN** der Nutzer eine Vorlage wählt und die Datenquelle verbunden ist
- **THEN** ist die Session bereit, aber noch nicht gestartet

## ADDED Requirements

### Requirement: Session mit Vorlage startet mit dem ersten Schlag
Eine bereite Session mit Vorlage SHALL mit der ersten Bewegung starten: wenn die Distanz steigt oder ein Ruderschlag gemeldet wird, je nachdem, was zuerst kommt. Bis dahin MUST keine Zeit laufen. Nullpunkt von Zeit, Distanz und Wanduhr MUST der letzte Messwert vor der ersten Bewegung sein, damit vom ersten Schlag nichts verloren geht. Eine Schlagzahl, die der Monitor aus einer früheren Fahrt noch anzeigt, ist keine Bewegung.

#### Scenario: Warten vor dem ersten Schlag
- **WHEN** der Nutzer „Seerunde x3“ wählt und eine Minute lang nicht rudert
- **THEN** zeigt die Session 0:00 und 0 m, Runde 1 und der Ghost stehen am Start

#### Scenario: Erster Schlag
- **WHEN** der PM5 nach der Wahl der Vorlage 0 m zeigt und der Nutzer den ersten Schlag rudert
- **THEN** startet die Session, und ihre Distanz und Zeit enthalten den ganzen ersten Schlag

#### Scenario: Zeitstrecke
- **WHEN** der Nutzer eine Vorlage mit einem Abschnitt von 4 Minuten wählt und 30 Sekunden nach der Wahl zu rudern beginnt
- **THEN** endet der Abschnitt 4 Minuten nach dem ersten Schlag

#### Scenario: Monitor zeigt noch eine frühere Fahrt
- **WHEN** der PM5 nach einer Pause noch 288 m und 28 Schläge pro Minute anzeigt und der Nutzer eine Vorlage wählt
- **THEN** bleibt die Session bereit, bis die Distanz steigt oder ein neuer Schlag gemeldet wird, und beginnt dann bei 0 m und 0:00

#### Scenario: Replay
- **WHEN** eine Session mit Vorlage, die mit dem ersten Schlag gestartet wurde, abgespielt oder importiert wird
- **THEN** ergeben sich dieselben Messwerte, Runden und Abschnitte wie bei der Aufzeichnung

### Requirement: Bereite Session abbrechen
Trennt der Nutzer die Verbindung oder beendet er die Session, bevor sie mit dem ersten Schlag gestartet ist, SHALL keine Session gespeichert werden.

#### Scenario: Trennen vor dem ersten Schlag
- **WHEN** der Nutzer eine Vorlage wählt und vor dem ersten Schlag trennt
- **THEN** erscheint keine neue Session in der Liste
