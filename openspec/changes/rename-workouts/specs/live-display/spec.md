## MODIFIED Requirements

### Requirement: Streckenangaben ohne Verlust der Lesbarkeit
Beim Rudern eines Workouts SHALL das Live-Display Runde, Segment, Restdistanz bzw. Restzeit, Zielbänder und Zonenstatus zusätzlich zu den Kernwerten zeigen. Die Pace MUST dabei der grösste Wert bleiben, und alle Angaben MUST in Hoch- und Querformat auf Handy und Laptop ohne Scrollen sichtbar sein.

#### Scenario: Handy im Querformat mit Vorlage
- **WHEN** der Nutzer ein Workout mit Pace- und Schlagzahl-Band auf dem Handy im Querformat rudert
- **THEN** sind Kernwerte, Runde, Segment, Restdistanz und Zonenstatus ohne Scrollen sichtbar und die Pace ist der grösste Wert

### Requirement: Fortschrittsrahmen um die Pace
Beim Rudern eines Workouts SHALL die Pace in einer Box stehen, deren Rahmen den Fortschritt als drei Spuren zeigt: aussen die Gesamtstrecke, in der Mitte die Runde, innen den Abschnitt (Zone oder frei). Jede Spur MUST oben in der Mitte beginnen, im Uhrzeigersinn wachsen und an der Spitze ein Schiffchen tragen. Die Box SHALL neben der Pace den Zonenstatus mit Band, den Zonennamen bzw. „frei“ und pro Spur die Restdistanz bzw. Restzeit zeigen.

#### Scenario: Mitten in Runde 2
- **WHEN** der Nutzer das Workout „Seerunde x3“ rudert, dessen Strecke 1000 m lang ist und die Zone „Tempo“ von 200 bis 800 m enthält, und bei 460 m in Runde 2 steht
- **THEN** ist die Streckenspur zu 49 %, die Rundenspur zu 46 % und die Abschnittsspur zu 43 % gefüllt, und die Box zeigt „1 460 / 3 000 m“, „noch 540 m“, „Tempo“ und „noch 340 m“

#### Scenario: Freier Abschnitt
- **WHEN** der Nutzer in demselben Workout bei 100 m einer Runde steht
- **THEN** zeigt die Box für den Abschnitt „frei“ und „noch 100 m“

#### Scenario: Offene Rundenzahl
- **WHEN** der Nutzer ein Workout mit offener Rundenzahl rudert
- **THEN** zeigt der Rahmen nur die Spuren für Runde und Abschnitt und die Box nennt die Runde ohne Gesamtzahl

#### Scenario: Grenzen sichtbar
- **WHEN** die Strecke aus drei Abschnitten besteht und drei Runden geplant sind
- **THEN** markieren Kerben auf der Streckenspur die zwei Rundengrenzen und auf der Rundenspur die zwei Abschnittsgrenzen

### Requirement: Layout nach Seitenverhältnis
Das Live-Display SHALL bei mehr Breite als Höhe ein eigenes Querformat-Layout verwenden, sonst das Hochformat-Layout. Das gilt mit und ohne Workout. In beiden Layouts MUST die Pace der grösste Wert sein und alle Werte ohne Scrollen sichtbar.

#### Scenario: Laptop-Fenster breiter als hoch
- **WHEN** die App auf dem Laptop in einem Fenster von 1200 × 700 läuft
- **THEN** zeigt das Live-Display das Querformat-Layout

#### Scenario: Handy quer mit Vorlage
- **WHEN** das Handy im Querformat steckt und ein Workout läuft
- **THEN** steht die Pace-Box mit Fortschrittsrahmen links fast über die volle Höhe, und Schlagzahl und weitere Werte stehen daneben

#### Scenario: Zeit und Distanz der Session mit Vorlage
- **WHEN** ein Workout seit 6:20 läuft und die Session 1520 m zurückgelegt hat
- **THEN** zeigt das Live-Display neben Rundenzeit, Watt und Puls die Kacheln „Zeit“ mit 6:20 und „Distanz“ mit 1 520 m, im Hochformat auch auf einem 360 px breiten Handy und im Querformat, ohne dass ein Wert abgeschnitten wird

### Requirement: Live-Display ohne Trennen verlassen
Das Live-Display SHALL kein Bedienelement zum Trennen zeigen. Zurück (Geste oder Taste) und auf dem Desktop die Esc-Taste MUST zum Startbildschirm führen, ohne die Verbindung zu trennen. Eine laufende Session MUST dabei wie mit „Session beenden“ gespeichert werden, eine bereite Session, die noch auf den ersten Schlag wartet, MUST verworfen werden. Der Bildschirm MUST nach dem Verlassen wieder ausgehen dürfen.

#### Scenario: Kein Trennen-Symbol
- **WHEN** der Nutzer frei oder mit einem Workout rudert, im Hoch- oder Querformat
- **THEN** zeigt das Live-Display Verbindungspunkt, Pulsgurt und Quelle, aber kein Symbol zum Trennen

#### Scenario: Esc auf dem Desktop
- **WHEN** der Nutzer auf dem Linux-Desktop im Live-Display Esc drückt
- **THEN** zeigt die App den Startbildschirm, das Rudergerät bleibt verbunden und der Bildschirm darf wieder ausgehen

#### Scenario: Zurück während einer Session
- **WHEN** der Nutzer während einer laufenden Session zurück geht
- **THEN** wird die Session gespeichert und die App zeigt den Startbildschirm

#### Scenario: Zurück vor dem ersten Schlag
- **WHEN** der Nutzer ein Workout startet und vor dem ersten Schlag zurück geht
- **THEN** wird keine Session gespeichert, und das Rudergerät bleibt verbunden

### Requirement: Bereitschaft vor dem ersten Schlag anzeigen
Ist eine Session mit Workout bereit, aber noch nicht gestartet, SHALL das Live-Display deutlich zeigen, dass die Session mit dem ersten Schlag startet. Der Hinweis MUST verschwinden, sobald die Session gestartet ist.

#### Scenario: Vorlage gewählt
- **WHEN** der Nutzer ein Workout wählt und noch nicht rudert
- **THEN** zeigt das Display „Bereit – startet mit dem ersten Schlag“ (englisch „Ready – starts with your first stroke“)

#### Scenario: Erster Schlag
- **WHEN** der Nutzer den ersten Schlag rudert
- **THEN** verschwindet der Hinweis und die Zeit beginnt zu laufen

### Requirement: Widerstandsstufe von Hand verstellen
Ist ein Rudergerät verbunden, dessen Stufe sich setzen lässt, SHALL die Live-Anzeige bei der Stufe unter den Watt eine Möglichkeit bieten, die Stufe um eine Stufe zu senken oder zu erhöhen, frei und mit Workout. Die Bedienelemente MUST aus Ruderdistanz treffbar sein und dürfen die Kernwerte nicht verdecken. An der Grenze des Bereichs MUST die jeweilige Richtung gesperrt sein. Lässt sich die Stufe nicht setzen, SHALL die Anzeige wie bisher nur die gemeldete Stufe zeigen.

#### Scenario: Stufe erhöhen
- **WHEN** das Gerät Stufe 6 meldet und der Nutzer auf + tippt
- **THEN** sendet die App Stufe 7 und die Anzeige zeigt „Stufe 7“, sobald das Gerät sie meldet

#### Scenario: Obere Grenze
- **WHEN** das Gerät Stufe 15 meldet und höchstens 15 erlaubt
- **THEN** ist + gesperrt

#### Scenario: Mehrmals schnell getippt
- **WHEN** der Nutzer bei Stufe 6 dreimal schnell auf + tippt
- **THEN** landet das Gerät auf Stufe 9

#### Scenario: Gerät ohne setzbare Stufe
- **WHEN** ein Gerät seine Stufe meldet, das Setzen aber nicht unterstützt
- **THEN** steht unter den Watt nur „Stufe 6“, ohne − und +
