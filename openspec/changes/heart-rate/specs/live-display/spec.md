# Spec Delta

## ADDED Requirements

### Requirement: Gurt-Zustand im Live-Display
Ist ein Gurt gekoppelt und die Quelle ein echtes Rudergerät (PM5 oder FTMS), SHALL das Live-Display den Verbindungszustand des Gurts in der Kopfzeile neben dem des Rudergeräts anzeigen. Ohne gekoppelten Gurt oder mit einem Simulator oder Replay als Quelle MUST NOT ein Gurt-Zustand erscheinen.

#### Scenario: Gurt verbunden
- **WHEN** der Nutzer mit Rudergerät und verbundenem Gurt rudert
- **THEN** zeigt das Live-Display beide Verbindungen als verbunden

#### Scenario: Gurt wiederverbindend
- **WHEN** der Gurt die Verbindung verliert, das Rudergerät aber verbunden bleibt
- **THEN** zeigt das Live-Display den Gurt als wiederverbindend und das Rudergerät weiter als verbunden

#### Scenario: Simulator mit gekoppeltem Gurt
- **WHEN** der Nutzer mit einem Simulator rudert und einen Gurt gekoppelt hat
- **THEN** zeigt das Live-Display keinen Gurt-Zustand

### Requirement: Letztes RR-Intervall anzeigen
Liegen RR-Intervalle vor, SHALL das Live-Display das zuletzt empfangene Intervall in ganzen Millisekunden klein beim Puls anzeigen. Ist das letzte Intervall älter als 3 Sekunden oder gibt es keine RR-Intervalle, MUST NOT ein RR-Wert erscheinen. Die Herkunft des Pulses MUST NOT angezeigt werden.

#### Scenario: Gurt sendet RR-Intervalle
- **WHEN** der Gurt zuletzt ein RR-Intervall von 812 ms gesendet hat
- **THEN** steht beim Puls „812 ms“

#### Scenario: Puls nur über das Rudergerät
- **WHEN** der Puls nur vom Rudergerät kommt
- **THEN** zeigt das Live-Display nur den Puls, ohne RR-Wert und ohne Hinweis auf die Herkunft

#### Scenario: Replay mit RR-Intervallen
- **WHEN** eine Session mit RR-Intervallen abgespielt wird
- **THEN** zeigt das Live-Display das RR-Intervall wie bei der Aufzeichnung
