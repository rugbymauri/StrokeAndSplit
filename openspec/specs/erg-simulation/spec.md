# erg-simulation Specification

## Purpose

Bietet einen simulierten Ruderer und das Abspielen aufgezeichneter Sessions als Datenquellen an, damit die App ohne physischen Erg entwickelt, getestet und vorgeführt werden kann.

## Requirements

### Requirement: Simulierten Erg als Datenquelle wählen
Die App SHALL neben echten Rudergeräten einen simulierten Erg als Datenquelle anbieten, der wie ein verbundenes Rudergerät laufend Messwerte und Schlag-Ereignisse liefert. Der Nutzer SHALL wählen können, ob der Simulator Daten wie ein PM5 oder wie ein FTMS-Rudergerät liefert.

#### Scenario: Simulator starten
- **WHEN** der Nutzer den simulierten Erg auswählt
- **THEN** verhält sich die App wie mit einem verbundenen PM5 und zeigt Live-Daten an

#### Scenario: Simulator als FTMS-Rudergerät
- **WHEN** der Nutzer den simulierten Erg im FTMS-Modus startet
- **THEN** verhält sich die App wie mit einem verbundenen FTMS-Rudergerät: Live-Daten erscheinen, Schläge werden gezählt und die Schlagdetails sind „nicht vorhanden“

### Requirement: Simulator steuerbar machen
Der simulierte Erg SHALL über Ziel-Pace und Ziel-Schlagzahl steuerbar sein und daraus plausible, leicht schwankende Werte für Distanz, Watt und Schlagdaten erzeugen. Er MUST pausiert und fortgesetzt werden können.

#### Scenario: Ziel-Pace ändern
- **WHEN** der Nutzer die Ziel-Pace des Simulators von 2:10 auf 1:50 ändert
- **THEN** nähert sich die angezeigte Pace innerhalb weniger Schläge 1:50 an

#### Scenario: Simulator pausieren
- **WHEN** der Nutzer den Simulator pausiert
- **THEN** wächst die Distanz nicht weiter und es entstehen keine Schlag-Ereignisse

### Requirement: Aufgezeichnete Session abspielen
Die App SHALL eine aufgezeichnete Session als Datenquelle abspielen können, in Originalgeschwindigkeit oder beschleunigt, unabhängig davon, ob sie mit einem PM5 oder einem FTMS-Rudergerät aufgezeichnet wurde.

#### Scenario: Replay in Originalgeschwindigkeit
- **WHEN** der Nutzer eine aufgezeichnete Session abspielt
- **THEN** treffen die Daten im ursprünglichen zeitlichen Abstand ein

#### Scenario: Beschleunigtes Replay
- **WHEN** der Nutzer eine Wiedergabe mit Faktor 10 wählt
- **THEN** läuft die Session zehnmal so schnell ab, mit denselben Werten

#### Scenario: Replay einer FTMS-Session
- **WHEN** der Nutzer eine mit einem FTMS-Rudergerät aufgezeichnete Session abspielt
- **THEN** zeigt die App dieselben Werte wie bei der Aufzeichnung

### Requirement: Datenquelle erkennbar machen
Die App SHALL jederzeit erkennbar anzeigen, ob die Daten von einem echten PM5, einem echten FTMS-Rudergerät, vom Simulator oder aus einem Replay stammen.

#### Scenario: Simulator aktiv
- **WHEN** der Simulator die aktive Datenquelle ist
- **THEN** zeigt das Live-Display deutlich an, dass es sich um simulierte Daten handelt

#### Scenario: FTMS-Rudergerät aktiv
- **WHEN** ein FTMS-Rudergerät die aktive Datenquelle ist
- **THEN** zeigt das Live-Display den Namen des Geräts und dass es über FTMS verbunden ist

### Requirement: Simulierte Kraftkurve
Der Simulator SHALL nach jedem simulierten Schlag eine plausible Kraftkurve liefern, deren Höhe zur eingestellten Leistung passt und die von Schlag zu Schlag leicht variiert.

#### Scenario: Höhere Leistung
- **WHEN** der Nutzer im Simulator die Leistung erhöht
- **THEN** werden die folgenden Kraftkurven höher

### Requirement: Simulierter Widerstand
Im FTMS-Modus SHALL der Simulator melden, dass sich seine Stufe im Bereich 1 bis 15 setzen lässt, eine gesetzte Stufe annehmen und ab dann melden. Im PM5-Modus SHALL er keine Stufe melden.

#### Scenario: Stufe im Simulator setzen
- **WHEN** der Simulator im FTMS-Modus läuft und die App Stufe 9 setzt
- **THEN** meldet der Simulator ab dem nächsten Messwert Stufe 9

#### Scenario: Vorlage im Simulator
- **WHEN** der Nutzer im Simulator (FTMS) eine Vorlage mit einem Sprint auf Stufe 10 rudert
- **THEN** zeigt die Live-Anzeige im Sprint „Stufe 10“
