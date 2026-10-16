# erg-simulation Specification

## Purpose

Bietet einen simulierten Ruderer und das Abspielen aufgezeichneter Sessions als Datenquellen an, damit die App ohne physischen Erg entwickelt, getestet und vorgeführt werden kann.

## Requirements

### Requirement: Simulierten Erg als Datenquelle wählen
Die App SHALL neben echten PM5 einen simulierten Erg als Datenquelle anbieten, der wie ein verbundener PM5 laufend Messwerte und Schlag-Ereignisse liefert.

#### Scenario: Simulator starten
- **WHEN** der Nutzer den simulierten Erg auswählt
- **THEN** verhält sich die App wie mit einem verbundenen PM5 und zeigt Live-Daten an

### Requirement: Simulator steuerbar machen
Der simulierte Erg SHALL über Ziel-Pace und Ziel-Schlagzahl steuerbar sein und daraus plausible, leicht schwankende Werte für Distanz, Watt und Schlagdaten erzeugen. Er MUST pausiert und fortgesetzt werden können.

#### Scenario: Ziel-Pace ändern
- **WHEN** der Nutzer die Ziel-Pace des Simulators von 2:10 auf 1:50 ändert
- **THEN** nähert sich die angezeigte Pace innerhalb weniger Schläge 1:50 an

#### Scenario: Simulator pausieren
- **WHEN** der Nutzer den Simulator pausiert
- **THEN** wächst die Distanz nicht weiter und es entstehen keine Schlag-Ereignisse

### Requirement: Aufgezeichnete Session abspielen
Die App SHALL eine aufgezeichnete Session als Datenquelle abspielen können, in Originalgeschwindigkeit oder beschleunigt.

#### Scenario: Replay in Originalgeschwindigkeit
- **WHEN** der Nutzer eine aufgezeichnete Session abspielt
- **THEN** treffen die Daten im ursprünglichen zeitlichen Abstand ein

#### Scenario: Beschleunigtes Replay
- **WHEN** der Nutzer eine Wiedergabe mit Faktor 10 wählt
- **THEN** läuft die Session zehnmal so schnell ab, mit denselben Werten

### Requirement: Datenquelle erkennbar machen
Die App SHALL jederzeit erkennbar anzeigen, ob die Daten von einem echten PM5, vom Simulator oder aus einem Replay stammen.

#### Scenario: Simulator aktiv
- **WHEN** der Simulator die aktive Datenquelle ist
- **THEN** zeigt das Live-Display deutlich an, dass es sich um simulierte Daten handelt
