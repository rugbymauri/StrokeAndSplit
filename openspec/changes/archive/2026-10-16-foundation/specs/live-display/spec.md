# Spec Delta

## Purpose

Zeigt dem Nutzer während des Ruderns die wichtigsten Messwerte gross und gut lesbar an, auf dem Handy am Erg ebenso wie auf dem Laptop.

## ADDED Requirements

### Requirement: Kernwerte anzeigen
Das Live-Display SHALL mindestens Pace pro 500 m, Schlagzahl, Watt, verstrichene Zeit und Distanz anzeigen. Die Herzfrequenz SHALL angezeigt werden, wenn sie vorhanden ist.

#### Scenario: Rudern mit Herzfrequenz
- **WHEN** der Nutzer rudert und ein Herzfrequenzgurt verbunden ist
- **THEN** zeigt das Display Pace, Schlagzahl, Watt, Zeit, Distanz und Herzfrequenz

#### Scenario: Rudern ohne Herzfrequenz
- **WHEN** keine Herzfrequenz vorhanden ist
- **THEN** wird kein Herzfrequenzfeld mit falschem Wert angezeigt

### Requirement: Werte in gewohnten Formaten anzeigen
Pace und Zeit SHALL im Format Minuten:Sekunden angezeigt werden (z.B. „2:05.3“ bzw. „12:34“), Distanz in ganzen Metern, Watt und Schlagzahl als ganze Zahlen, so wie es Ruderer vom PM5 kennen.

#### Scenario: Pace-Darstellung
- **WHEN** die aktuelle Pace 125,3 Sekunden pro 500 m beträgt
- **THEN** zeigt das Display „2:05.3“

### Requirement: Lesbar aus Ruderdistanz
Das Live-Display SHALL so gestaltet sein, dass die Pace als wichtigster Wert am grössten dargestellt wird, und SHALL sich an Hoch- und Querformat sowie an Handy- und Laptop-Bildschirme anpassen.

#### Scenario: Handy im Querformat
- **WHEN** das Handy im Querformat am Erg-Halter steckt
- **THEN** sind alle Kernwerte ohne Scrollen sichtbar und die Pace ist der grösste Wert

#### Scenario: Laptop-Fenster
- **WHEN** die App auf dem Laptop in einem Fenster läuft
- **THEN** passt sich das Display der Fenstergrösse an, ohne Werte abzuschneiden

### Requirement: Bildschirm aktiv halten
Solange das Live-Display offen und eine Datenquelle verbunden ist, SHALL die App verhindern, dass sich der Bildschirm automatisch ausschaltet.

#### Scenario: Lange Session
- **WHEN** der Nutzer 30 Minuten rudert, ohne den Bildschirm zu berühren
- **THEN** bleibt der Bildschirm eingeschaltet

### Requirement: Veraltete Daten kennzeichnen
Treffen länger als 3 Sekunden keine Daten von der Datenquelle ein, SHALL das Live-Display die Werte als veraltet kennzeichnen, statt den letzten Stand unkommentiert stehen zu lassen.

#### Scenario: Datenfluss stockt
- **WHEN** 3 Sekunden lang keine Daten eintreffen, die Verbindung aber nicht als getrennt gemeldet ist
- **THEN** werden die angezeigten Werte sichtbar als veraltet markiert
