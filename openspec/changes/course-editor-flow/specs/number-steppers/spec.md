## MODIFIED Requirements

### Requirement: Zahlen über Ruderblatt-Tasten einstellen
Jeder Zahlenwert in den Editoren SHALL über ein Tastenpaar „mehr“ und „weniger“ eingestellt werden, ohne Tastatur: die Rundenzahl im Vorlagen-Editor, die Länge im Strecken-Editor, Länge, Pace-Band und Schlagzahl-Band im Zonen-Editor sowie die Startposition beim Einbauen und beim Verschieben einer Zone. Gedrückt halten MUST den Schritt wiederholen. Kann der Wert nicht weiter sinken oder steigen, MUST die betroffene Taste gesperrt sein.

#### Scenario: Pace-Band anpassen
- **WHEN** im Zonen-Editor die schnellste Pace 1:45 beträgt und der Nutzer einmal auf „mehr“ tippt
- **THEN** zeigt das Feld 1:50

#### Scenario: Zone verschieben
- **WHEN** beim Einbauen einer Zone die Startposition 1600 m beträgt und der Nutzer einmal auf „weniger“ tippt
- **THEN** beginnt die Zone bei 1550 m

#### Scenario: Minimum erreicht
- **WHEN** im Vorlagen-Editor die feste Rundenzahl 1 beträgt
- **THEN** ist die Taste „weniger“ gesperrt und die Rundenzahl bleibt 1

#### Scenario: Gedrückt halten
- **WHEN** der Nutzer im Strecken-Editor die Taste „mehr“ bei 2000 m gedrückt hält
- **THEN** steigt die Länge fortlaufend in Schritten von 100 m, bis er loslässt

#### Scenario: Eingebaute Zone verschieben
- **WHEN** im Strecken-Editor die markierte Zone bei 1000 m beginnt und der Nutzer einmal auf „weniger“ tippt
- **THEN** beginnt die Zone bei 950 m
