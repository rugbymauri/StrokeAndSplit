# number-steppers Specification

## Purpose
TBD - created by archiving change ui-design. Update Purpose after archive.

## Requirements

### Requirement: Zahlen über Ruderblatt-Tasten einstellen
Jeder Zahlenwert in den Editoren SHALL über ein Tastenpaar „mehr“ und „weniger“ eingestellt werden, ohne Tastatur: die Rundenzahl im Workout-Editor, die Länge im Strecken-Editor, Länge, Pace-Band und Schlagzahl-Band im Zonen-Editor sowie die Startposition beim Einbauen und beim Verschieben einer Zone. Gedrückt halten MUST den Schritt wiederholen. Kann der Wert nicht weiter sinken oder steigen, MUST die betroffene Taste gesperrt sein.

#### Scenario: Pace-Band anpassen
- **WHEN** im Zonen-Editor die schnellste Pace 1:45 beträgt und der Nutzer einmal auf „mehr“ tippt
- **THEN** zeigt das Feld 1:50

#### Scenario: Zone verschieben
- **WHEN** beim Einbauen einer Zone die Startposition 1600 m beträgt und der Nutzer einmal auf „weniger“ tippt
- **THEN** beginnt die Zone bei 1550 m

#### Scenario: Minimum erreicht
- **WHEN** im Workout-Editor die feste Rundenzahl 1 beträgt
- **THEN** ist die Taste „weniger“ gesperrt und die Rundenzahl bleibt 1

#### Scenario: Gedrückt halten
- **WHEN** der Nutzer im Strecken-Editor die Taste „mehr“ bei 2000 m gedrückt hält
- **THEN** steigt die Länge fortlaufend in Schritten von 100 m, bis er loslässt

#### Scenario: Eingebaute Zone verschieben
- **WHEN** im Strecken-Editor die markierte Zone bei 1000 m beginnt und der Nutzer einmal auf „weniger“ tippt
- **THEN** beginnt die Zone bei 950 m

### Requirement: Feste Schritte pro Feld
Jeder Tipp auf eine Taste SHALL den Wert um einen festen Schritt ändern: Pace 5 s, Schlagzahl 1 spm, Runden 1, Streckenlänge 100 m, Zonenlänge 10 m, Startposition einer Zone 50 m. Auf der Zeitachse MUST der Schritt für die Streckenlänge 30 s und für Zonenlänge und Startposition 10 s betragen.

#### Scenario: Zonenlänge
- **WHEN** im Zonen-Editor die Länge 100 m beträgt und der Nutzer einmal auf „mehr“ tippt
- **THEN** ist die Zone 110 m lang

#### Scenario: Zeitstrecke verlängern
- **WHEN** eine Strecke mit Zeitachse 4:00 lang ist und der Nutzer einmal auf „mehr“ tippt
- **THEN** ist die Strecke 4:30 lang

### Requirement: Pace-Band als Ganzes verschieben
Eine neue Zone SHALL mit einem Pace-Band beginnen, dessen Grenzen 10 s pro 500 m auseinanderliegen. Ändert der Nutzer die schnellste Pace, MUST die langsamste um denselben Schritt mitwandern. Ändert er die langsamste, MUST nur sie sich ändern. Die Pace MUST zwischen 1:00 und 5:00 bleiben, die schnellste MUST NOT langsamer als die langsamste sein. Das Schlagzahl-Band ist nicht betroffen.

#### Scenario: Neue Zone
- **WHEN** der Nutzer eine neue Zone anlegt
- **THEN** beträgt das Pace-Band 2:45–2:55

#### Scenario: Schnellste Pace verschieben
- **WHEN** das Pace-Band 2:00–2:10 beträgt und der Nutzer bei der schnellsten Pace einmal auf „weniger“ tippt
- **THEN** beträgt das Pace-Band 1:55–2:05

#### Scenario: Abstand ändern
- **WHEN** das Pace-Band 2:00–2:10 beträgt und der Nutzer bei der langsamsten Pace einmal auf „mehr“ tippt
- **THEN** beträgt das Pace-Band 2:00–2:15, und weitere Schritte an der schnellsten Pace behalten den Abstand von 15 s

#### Scenario: Obergrenze erreicht
- **WHEN** das Pace-Band 4:50–5:00 beträgt
- **THEN** ist die Taste „mehr“ der schnellsten Pace gesperrt und das Band bleibt 4:50–5:00

### Requirement: Richtung der Taste erkennbar
Die Tasten SHALL die Form eines Ruderblatts haben, dessen Pfeil zugleich die Stange bildet. Bei „mehr“ MUST Blatt und Pfeil nach oben zeigen, bei „weniger“ nach unten. Jede Taste MUST für Screenreader mit Richtung und Schritt beschriftet sein, z. B. „5 Sekunden mehr“.

#### Scenario: Screenreader
- **WHEN** ein Screenreader die Taste „weniger“ beim Schlagzahl-Band vorliest
- **THEN** nennt er „1 Schlag weniger“
