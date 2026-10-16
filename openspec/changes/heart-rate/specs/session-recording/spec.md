# Spec Delta

## MODIFIED Requirements

### Requirement: Session vollständig speichern
Die App SHALL zu jeder Session eine Zusammenfassung (Startzeitpunkt, Dauer, Distanz, Durchschnittspace, Durchschnittswatt, Durchschnittsschlagzahl, Anzahl Schläge, Durchschnitts- und Maximalpuls falls vorhanden, Datenquelle) sowie den zeitlichen Verlauf aller Messwerte, RR-Intervalle und Schlag-Ereignisse lokal speichern.

#### Scenario: Session nach App-Neustart
- **WHEN** der Nutzer eine Session beendet und die App neu startet
- **THEN** ist die Session mit Zusammenfassung und Verlauf weiterhin vorhanden

#### Scenario: Session mit Puls
- **WHEN** der Nutzer eine Session mit Puls beendet
- **THEN** zeigt die Zusammenfassung Durchschnitts- und Maximalpuls als ganze Schläge pro Minute

#### Scenario: Session ohne Puls
- **WHEN** der Nutzer eine Session ohne Puls beendet
- **THEN** zeigt die Zusammenfassung keine Pulswerte statt 0

#### Scenario: Bestehende Sessions nach dem Update
- **WHEN** die App mit Sessions aus einer früheren Version aktualisiert wird
- **THEN** bleiben diese Sessions mit Zusammenfassung, Verlauf und Replay erhalten

### Requirement: Rohdaten für Replay speichern
Für Sessions mit einem echten PM5 SHALL die App die empfangenen Rohdaten des PM5 und eines direkt verbundenen Gurts mit Zeitstempel auf einer gemeinsamen Zeitachse speichern, sodass die Session später exakt wieder abgespielt werden kann.

#### Scenario: Replay einer echten Session
- **WHEN** eine mit einem echten PM5 aufgezeichnete Session abgespielt wird
- **THEN** ergeben sich dieselben Messwerte wie bei der Aufzeichnung

#### Scenario: Replay einer Session mit direkt verbundenem Gurt
- **WHEN** eine Session abgespielt wird, bei der ein Gurt direkt verbunden war
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

#### Scenario: Puls nur über den PM5
- **WHEN** der Nutzer eine Session beendet, bei der der Puls nur vom PM5 kam
- **THEN** zeigt die Zusammenfassung Durchschnitts- und Maximalpuls, aber weder RR-Kurve noch RMSSD
