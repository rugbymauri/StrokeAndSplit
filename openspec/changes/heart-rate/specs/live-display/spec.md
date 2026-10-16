# Spec Delta

## ADDED Requirements

### Requirement: Gurt-Zustand im Live-Display
Ist ein Gurt gekoppelt und die Quelle ein echter PM5, SHALL das Live-Display den Verbindungszustand des Gurts neben dem des PM5 anzeigen. Ohne gekoppelten Gurt oder mit Simulator oder Replay als Quelle MUST NOT ein Gurt-Zustand erscheinen.

#### Scenario: Gurt verbunden
- **WHEN** der Nutzer mit PM5 und verbundenem Gurt rudert
- **THEN** zeigt das Live-Display beide Verbindungen als verbunden

#### Scenario: Gurt wiederverbindend
- **WHEN** der Gurt die Verbindung verliert, der PM5 aber verbunden bleibt
- **THEN** zeigt das Live-Display den Gurt als wiederverbindend und den PM5 weiter als verbunden

### Requirement: Letztes RR-Intervall anzeigen
Liegen RR-Intervalle vor, SHALL das Live-Display das zuletzt empfangene Intervall in ganzen Millisekunden klein unter dem Puls anzeigen. Ist das letzte Intervall älter als 3 Sekunden oder gibt es keine RR-Intervalle, MUST NOT ein RR-Wert erscheinen.

#### Scenario: Gurt sendet RR-Intervalle
- **WHEN** der Gurt zuletzt ein RR-Intervall von 812 ms gesendet hat
- **THEN** steht unter dem Puls „812 ms“

#### Scenario: Puls nur über den PM5
- **WHEN** der Puls nur vom PM5 kommt
- **THEN** zeigt die Puls-Kachel nur den Puls, ohne RR-Wert

#### Scenario: Replay mit RR-Intervallen
- **WHEN** eine Session mit RR-Intervallen abgespielt wird
- **THEN** zeigt das Live-Display das RR-Intervall wie bei der Aufzeichnung
