# Spec Delta

## MODIFIED Requirements

### Requirement: Session vollständig speichern
Die App SHALL zu jeder Session eine Zusammenfassung (Startzeitpunkt, Dauer, Distanz, Durchschnittspace, Durchschnittswatt, Durchschnittsschlagzahl, Anzahl Schläge, Durchschnitts- und Maximalpuls falls vorhanden, Datenquelle, Geräteart) sowie den zeitlichen Verlauf aller Messwerte, RR-Intervalle und Schlag-Ereignisse lokal speichern. Schlagdetails, die das Gerät nicht liefert, MUST als „nicht vorhanden“ gespeichert werden.

#### Scenario: Session nach App-Neustart
- **WHEN** der Nutzer eine Session beendet und die App neu startet
- **THEN** ist die Session mit Zusammenfassung und Verlauf weiterhin vorhanden

#### Scenario: Session mit FTMS-Rudergerät
- **WHEN** der Nutzer eine Session mit einem FTMS-Rudergerät mit 120 Schlägen beendet
- **THEN** zeigt die Zusammenfassung 120 Schläge und das Gerät als FTMS-Rudergerät, und die gespeicherten Schläge haben keine Durchzugs- und Kraftwerte

#### Scenario: Session mit Puls
- **WHEN** der Nutzer eine Session mit Puls beendet, ob vom Gurt oder vom Rudergerät
- **THEN** zeigt die Zusammenfassung Durchschnitts- und Maximalpuls als ganze Schläge pro Minute

#### Scenario: Session ohne Puls
- **WHEN** der Nutzer eine Session ohne Puls beendet
- **THEN** zeigt die Zusammenfassung keine Pulswerte statt 0

#### Scenario: Bestehende Sessions nach dem Update
- **WHEN** die App mit Sessions aus einer früheren Version auf diese Version aktualisiert wird
- **THEN** sind alle Sessions mit Zusammenfassung, Verlauf, vollständigen Schlagdetails und Replay weiterhin vorhanden, gelten als PM5-Sessions, sofern sie mit einem PM5 aufgezeichnet wurden, und haben keine Pulszusammenfassung

### Requirement: Rohdaten für Replay speichern
Für Sessions mit einem echten Rudergerät SHALL die App die empfangenen Rohdaten des Rudergeräts und eines direkt verbundenen Gurts mit Zeitstempel auf einer gemeinsamen Zeitachse und mit dem Protokoll des Rudergeräts (PM5 oder FTMS) speichern, sodass die Session später exakt wieder abgespielt werden kann.

#### Scenario: Replay einer echten Session
- **WHEN** eine mit einem echten PM5 aufgezeichnete Session abgespielt wird
- **THEN** ergeben sich dieselben Messwerte wie bei der Aufzeichnung

#### Scenario: Replay einer FTMS-Session
- **WHEN** eine mit einem FTMS-Rudergerät aufgezeichnete Session abgespielt wird
- **THEN** werden die Rohdaten als FTMS-Daten gelesen und ergeben dieselben Messwerte wie bei der Aufzeichnung

#### Scenario: Replay einer Session mit direkt verbundenem Gurt
- **WHEN** eine Session abgespielt wird, bei der ein Gurt direkt verbunden war, ob mit PM5 oder FTMS-Rudergerät
- **THEN** ergeben sich derselbe Puls und dieselben RR-Intervalle wie bei der Aufzeichnung

#### Scenario: Export und Import mit Gurt-Daten
- **WHEN** eine Session mit direkt verbundenem Gurt exportiert und auf einem anderen Gerät importiert wird
- **THEN** zeigt die importierte Session denselben Puls, dieselben RR-Intervalle und dieselbe Zusammenfassung

## ADDED Requirements

### Requirement: RR-Intervalle in der Zusammenfassung
Enthält eine Session RR-Intervalle, SHALL die Zusammenfassung ihren Verlauf über die Session als Kurve sowie die Herzratenvariabilität als RMSSD in ganzen Millisekunden zeigen. Ohne RR-Intervalle MUST NOT Kurve oder RMSSD erscheinen.

#### Scenario: Session mit RR-Intervallen
- **WHEN** der Nutzer eine Session beendet, bei der der Gurt RR-Intervalle gesendet hat
- **THEN** zeigt die Zusammenfassung die RR-Kurve und den RMSSD-Wert

#### Scenario: RMSSD-Berechnung
- **WHEN** eine Session die RR-Intervalle 800, 810 und 790 ms enthält
- **THEN** beträgt der RMSSD 16 ms (Wurzel aus dem Mittel von 10² und 20²)

#### Scenario: Puls nur über das Rudergerät
- **WHEN** der Nutzer eine Session beendet, bei der der Puls nur vom Rudergerät kam
- **THEN** zeigt die Zusammenfassung Durchschnitts- und Maximalpuls, aber weder RR-Kurve noch RMSSD
