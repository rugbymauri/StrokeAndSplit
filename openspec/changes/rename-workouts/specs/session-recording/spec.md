## RENAMED Requirements

- FROM: `### Requirement: Session einer Vorlage zuordnen`
- TO: `### Requirement: Session eines Workouts zuordnen`

- FROM: `### Requirement: Session mit Vorlage startet mit dem ersten Schlag`
- TO: `### Requirement: Session mit Workout startet mit dem ersten Schlag`

- FROM: `### Requirement: Session ohne Vorlage in der Liste`
- TO: `### Requirement: Session ohne Workout in der Liste`

## MODIFIED Requirements

### Requirement: Session starten und beenden
Der Nutzer SHALL eine Session in der App starten und beenden können, solange eine Datenquelle verbunden ist. Distanz und Zeit der Session MUST ab dem Start der Session zählen, unabhängig vom Stand der Anzeige am Rudergerät. Bei freiem Rudern startet die Session mit „Session starten“, mit einem Workout erst mit dem ersten Ruderschlag.

#### Scenario: Session starten
- **WHEN** der Nutzer mit verbundenem PM5 „Session starten“ wählt, während der PM5 bereits 500 m anzeigt
- **THEN** beginnt die Session bei 0 m und 0:00

#### Scenario: Session mit FTMS-Rudergerät starten
- **WHEN** der Nutzer mit verbundenem FTMS-Rudergerät „Session starten“ wählt, während das Gerät bereits 800 m meldet
- **THEN** beginnt die Session bei 0 m und 0:00

#### Scenario: Session beenden
- **WHEN** der Nutzer „Session beenden“ wählt
- **THEN** wird die Session gespeichert und ihre Zusammenfassung angezeigt

#### Scenario: Vorlage gewählt
- **WHEN** der Nutzer ein Workout wählt und die Datenquelle verbunden ist
- **THEN** ist die Session bereit, aber noch nicht gestartet

### Requirement: Session eines Workouts zuordnen
Eine Session, die mit einem Workout gestartet wurde, SHALL mit dem Workout und der geruderten Version ihrer Strecke verknüpft sein. Die Session-Liste MUST bei solchen Sessions den Namen des Workouts anzeigen.

#### Scenario: Liste mit Vorlagen-Session
- **WHEN** der Nutzer die Session-Liste öffnet und eine Session mit dem Workout „Seerunde x3“ gerudert hat
- **THEN** zeigt der Eintrag „Seerunde x3“ zusätzlich zu Datum, Dauer, Distanz und Pace

#### Scenario: Vorlage später gelöscht
- **WHEN** das Workout einer Session gelöscht wurde
- **THEN** zeigt die Session weiterhin den Namen des Workouts und der Strecke, mit dem sie gerudert wurde

### Requirement: Lokale Daten nach der Umbenennung
Findet die App beim Start keine Datenbank unter dem neuen Namen, aber eine unter dem alten am selben Ort, SHALL sie diese übernehmen, sodass alle Sessions, Strecken und Workouts erhalten bleiben.

#### Scenario: Update auf dem Linux-Desktop
- **WHEN** der Nutzer auf dem Linux-Desktop die umbenannte Version zum ersten Mal startet
- **THEN** zeigt sie alle Sessions, Strecken und Workouts der bisherigen Version

### Requirement: Session mit Workout startet mit dem ersten Schlag
Eine bereite Session mit Workout SHALL mit der ersten Bewegung starten: wenn die Distanz steigt oder ein Ruderschlag gemeldet wird, je nachdem, was zuerst kommt. Bis dahin MUST keine Zeit laufen. Nullpunkt von Zeit, Distanz und Wanduhr MUST der letzte Messwert vor der ersten Bewegung sein, damit vom ersten Schlag nichts verloren geht. Eine Schlagzahl, die der Monitor aus einer früheren Fahrt noch anzeigt, ist keine Bewegung.

#### Scenario: Warten vor dem ersten Schlag
- **WHEN** der Nutzer „Seerunde x3“ wählt und eine Minute lang nicht rudert
- **THEN** zeigt die Session 0:00 und 0 m, Runde 1 und der Ghost stehen am Start

#### Scenario: Erster Schlag
- **WHEN** der PM5 nach der Wahl des Workouts 0 m zeigt und der Nutzer den ersten Schlag rudert
- **THEN** startet die Session, und ihre Distanz und Zeit enthalten den ganzen ersten Schlag

#### Scenario: Zeitstrecke
- **WHEN** der Nutzer ein Workout mit einem Abschnitt von 4 Minuten wählt und 30 Sekunden nach der Wahl zu rudern beginnt
- **THEN** endet der Abschnitt 4 Minuten nach dem ersten Schlag

#### Scenario: Monitor zeigt noch eine frühere Fahrt
- **WHEN** der PM5 nach einer Pause noch 288 m und 28 Schläge pro Minute anzeigt und der Nutzer ein Workout wählt
- **THEN** bleibt die Session bereit, bis die Distanz steigt oder ein neuer Schlag gemeldet wird, und beginnt dann bei 0 m und 0:00

#### Scenario: Replay
- **WHEN** eine Session mit Workout, die mit dem ersten Schlag gestartet wurde, abgespielt oder importiert wird
- **THEN** ergeben sich dieselben Messwerte, Runden und Abschnitte wie bei der Aufzeichnung

### Requirement: Bereite Session abbrechen
Trennt der Nutzer die Verbindung oder beendet er die Session, bevor sie mit dem ersten Schlag gestartet ist, SHALL keine Session gespeichert werden.

#### Scenario: Trennen vor dem ersten Schlag
- **WHEN** der Nutzer ein Workout wählt und vor dem ersten Schlag trennt
- **THEN** erscheint keine neue Session in der Liste

### Requirement: Session pausiert, wenn nicht gerudert wird
Bleibt während einer laufenden Session der nächste Ruderschlag aus, SHALL die Session pausieren, sobald 3 s seit dem Zeitpunkt vergangen sind, an dem er im Rhythmus der letzten Schläge fällig gewesen wäre. Ein langsamer Rhythmus allein MUST keine Pause auslösen. In der Pause MUST die Sessionzeit stillstehen; die Zeit bis zum Beginn der Pause zählt zur Session. Das gilt für freies Rudern und Workouts, für PM5 und FTMS-Rudergeräte.

#### Scenario: Aufhören zu rudern
- **WHEN** der Nutzer mit 24 Schlägen pro Minute rudert und dann aufhört
- **THEN** pausiert die Session 3 s nach dem Zeitpunkt, an dem der nächste Schlag fällig gewesen wäre, und die Sessionzeit steht still

#### Scenario: Langsam rudern
- **WHEN** der Nutzer gleichmässig mit 16 Schlägen pro Minute rudert
- **THEN** pausiert die Session nicht

#### Scenario: Monitor lässt seine Uhr weiterlaufen
- **WHEN** der Nutzer stillsitzt und der Monitor seine eigene Zeit weiterzählt oder anhält
- **THEN** steht die Sessionzeit in beiden Fällen ab dem Beginn der Pause still

#### Scenario: Freie Session vor dem ersten Schlag
- **WHEN** der Nutzer bei freiem Rudern „Session starten“ wählt und erst 20 Sekunden später zu rudern beginnt
- **THEN** pausiert die Session nach 3 Sekunden und läuft mit dem ersten Schlag weiter

### Requirement: Session ohne Workout in der Liste
Die Session-Liste SHALL eine Session ohne Workout auf einer Strecke mit dem Namen der Strecke und der geplanten Länge zeigen: Rundenzahl, Dauer oder „offen“.

#### Scenario: Dauer in der Liste
- **WHEN** der Nutzer 30 min auf „Seerunde“ ohne Workout gerudert hat und die Session-Liste öffnet
- **THEN** zeigt der Eintrag „Seerunde · 30 min“
