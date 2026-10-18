# Spec Delta

## ADDED Requirements

### Requirement: Fortschrittsrahmen um die Pace
Beim Rudern einer Vorlage SHALL die Pace in einer Box stehen, deren Rahmen den Fortschritt als drei Spuren zeigt: aussen die Gesamtstrecke, in der Mitte die Runde, innen den Abschnitt (Zone oder frei). Jede Spur MUST oben in der Mitte beginnen, im Uhrzeigersinn wachsen und an der Spitze ein Schiffchen tragen. Die Box SHALL neben der Pace den Zonenstatus mit Band, den Zonennamen bzw. „frei“ und pro Spur die Restdistanz bzw. Restzeit zeigen.

#### Scenario: Mitten in Runde 2
- **WHEN** der Nutzer die Vorlage „Seerunde x3“ rudert, deren Strecke 1000 m lang ist und die Zone „Tempo“ von 200 bis 800 m enthält, und bei 460 m in Runde 2 steht
- **THEN** ist die Streckenspur zu 49 %, die Rundenspur zu 46 % und die Abschnittsspur zu 43 % gefüllt, und die Box zeigt „1 460 / 3 000 m“, „noch 540 m“, „Tempo“ und „noch 340 m“

#### Scenario: Freier Abschnitt
- **WHEN** der Nutzer in derselben Vorlage bei 100 m einer Runde steht
- **THEN** zeigt die Box für den Abschnitt „frei“ und „noch 100 m“

#### Scenario: Offene Rundenzahl
- **WHEN** der Nutzer eine Vorlage mit offener Rundenzahl rudert
- **THEN** zeigt der Rahmen nur die Spuren für Runde und Abschnitt und die Box nennt die Runde ohne Gesamtzahl

#### Scenario: Grenzen sichtbar
- **WHEN** die Strecke aus drei Abschnitten besteht und drei Runden geplant sind
- **THEN** markieren Kerben auf der Streckenspur die zwei Rundengrenzen und auf der Rundenspur die zwei Abschnittsgrenzen

### Requirement: Abschnittsspur zeigt den Zonenstatus
Die innere Spur des Fortschrittsrahmens SHALL in der Farbe des Pace-Zonenstatus erscheinen: in der Zone und ausserhalb unterscheidbar in Farbe und Helligkeit. In einem freien Abschnitt und in einer Zone ohne Pace-Band MUST sie neutral bleiben. Der Zonenstatus MUST zusätzlich als Text oder Symbol in der Box stehen.

#### Scenario: Pace zu langsam
- **WHEN** die aktuelle Zone das Band 2:05–2:10 hat und die Pace 2:13.0 beträgt
- **THEN** ist die Abschnittsspur als ausserhalb eingefärbt und die Box zeigt den Hinweis „schneller“

#### Scenario: Abschnitt ohne Pace-Band
- **WHEN** der aktuelle Abschnitt frei ist oder seine Zone kein Pace-Band hat
- **THEN** ist die Abschnittsspur neutral und die Box zeigt keinen Zonenstatus für die Pace

### Requirement: Layout nach Seitenverhältnis
Das Live-Display SHALL bei mehr Breite als Höhe ein eigenes Querformat-Layout verwenden, sonst das Hochformat-Layout. Das gilt mit und ohne Vorlage. In beiden Layouts MUST die Pace der grösste Wert sein und alle Werte ohne Scrollen sichtbar.

#### Scenario: Laptop-Fenster breiter als hoch
- **WHEN** die App auf dem Laptop in einem Fenster von 1200 × 700 läuft
- **THEN** zeigt das Live-Display das Querformat-Layout

#### Scenario: Handy quer mit Vorlage
- **WHEN** das Handy im Querformat steckt und eine Vorlage läuft
- **THEN** steht die Pace-Box mit Fortschrittsrahmen links fast über die volle Höhe, und Schlagzahl und weitere Werte stehen daneben

#### Scenario: Zeit und Distanz der Session mit Vorlage
- **WHEN** eine Vorlage seit 6:20 läuft und die Session 1520 m zurückgelegt hat
- **THEN** zeigt das Live-Display neben Rundenzeit, Watt und Puls die Kacheln „Zeit“ mit 6:20 und „Distanz“ mit 1 520 m, im Hochformat auch auf einem 360 px breiten Handy und im Querformat, ohne dass ein Wert abgeschnitten wird

### Requirement: Live-Display ohne Trennen verlassen
Das Live-Display SHALL kein Bedienelement zum Trennen zeigen. Zurück (Geste oder Taste) und auf dem Desktop die Esc-Taste MUST zum Startbildschirm führen, ohne die Verbindung zu trennen. Eine laufende Session MUST dabei wie mit „Session beenden“ gespeichert werden, eine bereite Session, die noch auf den ersten Schlag wartet, MUST verworfen werden. Der Bildschirm MUST nach dem Verlassen wieder ausgehen dürfen.

#### Scenario: Kein Trennen-Symbol
- **WHEN** der Nutzer frei oder mit einer Vorlage rudert, im Hoch- oder Querformat
- **THEN** zeigt das Live-Display Verbindungspunkt, Pulsgurt und Quelle, aber kein Symbol zum Trennen

#### Scenario: Esc auf dem Desktop
- **WHEN** der Nutzer auf dem Linux-Desktop im Live-Display Esc drückt
- **THEN** zeigt die App den Startbildschirm, das Rudergerät bleibt verbunden und der Bildschirm darf wieder ausgehen

#### Scenario: Zurück während einer Session
- **WHEN** der Nutzer während einer laufenden Session zurück geht
- **THEN** wird die Session gespeichert und die App zeigt den Startbildschirm

#### Scenario: Zurück vor dem ersten Schlag
- **WHEN** der Nutzer eine Vorlage startet und vor dem ersten Schlag zurück geht
- **THEN** wird keine Session gespeichert, und das Rudergerät bleibt verbunden

## MODIFIED Requirements

### Requirement: Werte in gewohnten Formaten anzeigen
Pace und Zeit SHALL im Format Minuten:Sekunden angezeigt werden (z.B. „2:05“ bzw. „12:34“), die Pace in ganzen Sekunden ohne Zehntel, Distanz in ganzen Metern, Watt und Schlagzahl als ganze Zahlen, so wie es Ruderer vom PM5 kennen.

#### Scenario: Pace-Darstellung
- **WHEN** die aktuelle Pace 125,3 Sekunden pro 500 m beträgt
- **THEN** zeigt das Display „2:05“

#### Scenario: Pace wird auf ganze Sekunden gerundet
- **WHEN** die aktuelle Pace 125,6 Sekunden pro 500 m beträgt
- **THEN** zeigt das Display „2:06“

### Requirement: Zonenstatus ohne Farbe erkennbar
Der Zonenstatus SHALL nicht allein über Farbe vermittelt werden. Ausserhalb der Zone MUST ein Richtungssymbol oder Text die Abweichung zeigen. Liegt die Schlagzahl ausserhalb ihres Bands, MUST die Schlagzahl-Karte in Hoch- und Querformat eine deutliche Anweisung zeigen: Pfeil nach oben und „Mehr Schläge“ bzw. Pfeil nach unten und „Weniger Schläge“, zusammen mit dem Band, in der Farbe für ausserhalb der Zone, vollständig lesbar und mindestens so auffällig wie der Zonenstatus der Pace. In der Zone SHALL der Status dezent bleiben, und ohne Schlagzahl-Band MUST die Anweisung entfallen.

#### Scenario: Ausserhalb der Zone
- **WHEN** die Pace langsamer als das Band ist
- **THEN** zeigt das Display neben der Farbe einen Pfeil bzw. den Hinweis „schneller“

#### Scenario: Schlagzahl zu niedrig
- **WHEN** die aktuelle Zone das Schlagzahl-Band 20–22 spm hat und die Schlagzahl 18 spm beträgt
- **THEN** zeigt die Schlagzahl-Karte gut sichtbar einen Pfeil nach oben, „Mehr Schläge“ und das Band 20–22 spm

#### Scenario: Schlagzahl zu hoch
- **WHEN** die aktuelle Zone das Schlagzahl-Band 20–22 spm hat und die Schlagzahl 24 spm beträgt
- **THEN** zeigt die Schlagzahl-Karte gut sichtbar einen Pfeil nach unten, „Weniger Schläge“ und das Band 20–22 spm

#### Scenario: Schlagzahl in der Zone
- **WHEN** die Schlagzahl im Band liegt
- **THEN** zeigt die Schlagzahl-Karte dezent „In der Zone“ und keine Anweisung

#### Scenario: Abschnitt ohne Schlagzahl-Band
- **WHEN** der aktuelle Abschnitt frei ist oder seine Zone kein Schlagzahl-Band hat
- **THEN** zeigt die Schlagzahl-Karte keine Anweisung
