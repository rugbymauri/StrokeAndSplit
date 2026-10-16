# Spec Delta

## ADDED Requirements

### Requirement: Fortschrittsrahmen um die Pace
Beim Rudern einer Vorlage SHALL die Pace in einer Box stehen, deren Rahmen den Fortschritt als drei Spuren zeigt: aussen die Gesamtstrecke über alle Runden, in der Mitte die aktuelle Runde und innen das aktuelle Segment. Jede Spur MUST oben in der Mitte beginnen und im Uhrzeigersinn wachsen. Die Spitze jeder Spur MUST als Schiffchen markiert sein. Die Box SHALL zusätzlich zur Pace den Zonenstatus mit Band und pro Spur die Restdistanz bzw. Restzeit als Text zeigen.

#### Scenario: Mitten in Runde 2
- **WHEN** der Nutzer die Vorlage „Seerunde x3“ (1000 m, Segmente 200/600/200 m) rudert und bei 460 m in Runde 2 steht
- **THEN** ist die Streckenspur zu 49 %, die Rundenspur zu 46 % und die Segmentspur zu 43 % gefüllt, und die Box zeigt „1 460 / 3 000 m“, „noch 540 m“ und „noch 340 m“

#### Scenario: Offene Rundenzahl
- **WHEN** der Nutzer eine Vorlage mit offener Rundenzahl rudert
- **THEN** zeigt der Rahmen nur die Spuren für Runde und Segment und die Box nennt die Runde ohne Gesamtzahl

#### Scenario: Grenzen sichtbar
- **WHEN** die Strecke aus drei Segmenten besteht und drei Runden geplant sind
- **THEN** markieren Kerben auf der Streckenspur die zwei Rundengrenzen und auf der Rundenspur die zwei Segmentgrenzen

### Requirement: Segmentspur zeigt den Zonenstatus
Die innere Spur des Fortschrittsrahmens SHALL in der Farbe des Pace-Zonenstatus erscheinen: in der Zone und ausserhalb unterscheidbar in Farbe und Helligkeit. In einem Segment ohne Pace-Band MUST sie neutral bleiben. Der Zonenstatus MUST zusätzlich als Text oder Symbol in der Box stehen.

#### Scenario: Pace zu langsam
- **WHEN** das Segment das Band 2:05–2:10 hat und die Pace 2:13.0 beträgt
- **THEN** ist die Segmentspur als ausserhalb eingefärbt und die Box zeigt den Hinweis „schneller“

#### Scenario: Freies Segment
- **WHEN** das aktuelle Segment kein Pace-Band hat
- **THEN** ist die Segmentspur neutral und die Box zeigt keinen Zonenstatus für die Pace

### Requirement: Layout nach Seitenverhältnis
Das Live-Display SHALL bei mehr Breite als Höhe ein eigenes Querformat-Layout verwenden, sonst das Hochformat-Layout. Das gilt mit und ohne Vorlage. In beiden Layouts MUST die Pace der grösste Wert sein und alle Werte ohne Scrollen sichtbar.

#### Scenario: Laptop-Fenster breiter als hoch
- **WHEN** die App auf dem Laptop in einem Fenster von 1200 × 700 läuft
- **THEN** zeigt das Live-Display das Querformat-Layout

#### Scenario: Handy quer mit Vorlage
- **WHEN** das Handy im Querformat steckt und eine Vorlage läuft
- **THEN** steht die Pace-Box mit Fortschrittsrahmen links fast über die volle Höhe, und Schlagzahl und weitere Werte stehen daneben
