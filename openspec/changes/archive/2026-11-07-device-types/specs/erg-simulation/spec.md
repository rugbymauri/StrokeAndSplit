# Spec Delta

## MODIFIED Requirements

### Requirement: Simulierten Erg als Datenquelle wählen
Die App SHALL neben echten Rudergeräten einen simulierten Erg als Datenquelle anbieten, der wie ein verbundenes Rudergerät laufend Messwerte und Schlag-Ereignisse liefert. Der Nutzer SHALL wählen können, ob der Simulator Daten wie ein PM5 oder wie ein FTMS-Rudergerät liefert.

#### Scenario: Simulator starten
- **WHEN** der Nutzer den simulierten Erg auswählt
- **THEN** verhält sich die App wie mit einem verbundenen PM5 und zeigt Live-Daten an

#### Scenario: Simulator als FTMS-Rudergerät
- **WHEN** der Nutzer den simulierten Erg im FTMS-Modus startet
- **THEN** verhält sich die App wie mit einem verbundenen FTMS-Rudergerät: Live-Daten erscheinen, Schläge werden gezählt und die Schlagdetails sind „nicht vorhanden“

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
