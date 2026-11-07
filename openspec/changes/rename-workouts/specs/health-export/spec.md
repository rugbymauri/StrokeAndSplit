## MODIFIED Requirements

### Requirement: Trainingseinheit übertragen
Eine übertragene Session SHALL in Health Connect eine Trainingseinheit vom Typ Rudergerät sein: mit Beginn und Ende der Session, als Titel dem Namen des Workouts bzw. einem Titel für freies Rudern, mit der geruderten Distanz und mit den Kalorien des Rudergeräts, sofern es welche gemeldet hat. Schlagzahl, Kraftkurve und Rohdaten MUST NOT übertragen werden.

#### Scenario: Freie Session
- **WHEN** der Nutzer eine freie Session über 2 000 m überträgt
- **THEN** zeigt Health Connect eine Rudergerät-Einheit mit dem Titel für freies Rudern, ihrem Zeitraum und 2 000 m

### Requirement: Verläufe, Runden und Pausen übertragen
Zur Trainingseinheit SHALL die App die Verläufe von Puls, Leistung und Geschwindigkeit aus den gespeicherten Messwerten übertragen, soweit vorhanden, dazu die Runden eines Workouts mit ihrer Distanz und die Pausen der Session. Messwerte ohne Wert und ein Puls von 0 MUST ausgelassen werden.

#### Scenario: Vorlage mit Puls
- **WHEN** der Nutzer eine Session „Seerunde x3“ mit Brustgurt überträgt
- **THEN** zeigt Health Connect eine Rudergerät-Einheit „Seerunde x3“ mit Distanz, Kalorien, Pulsverlauf, Leistungs- und Geschwindigkeitsverlauf und drei Runden

#### Scenario: Freies Rudern ohne Puls
- **WHEN** der Nutzer eine freie Session ohne Puls an einem FTMS-Rudergerät ohne Kalorien überträgt
- **THEN** enthält die Einheit Zeitraum, Titel, Distanz, Leistung und Geschwindigkeit, aber weder Puls noch Kalorien

#### Scenario: Session mit Pause
- **WHEN** der Nutzer eine Session mit einer Pause von einer Minute überträgt
- **THEN** enthält die Einheit die Pause mit Beginn und Ende
