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
