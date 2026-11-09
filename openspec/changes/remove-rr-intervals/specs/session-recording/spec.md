## MODIFIED Requirements

### Requirement: Session vollständig speichern
Die App SHALL zu jeder Session eine Zusammenfassung (Startzeitpunkt, Dauer, Distanz, Durchschnittspace, Durchschnittswatt, Durchschnittsschlagzahl, Anzahl Schläge, Anzahl und Gesamtdauer der Pausen, Durchschnitts- und Maximalpuls falls vorhanden, Datenquelle, Geräteart) sowie den zeitlichen Verlauf aller Messwerte und Schlag-Ereignisse lokal speichern. Schlagdetails, die das Gerät nicht liefert, MUST als „nicht vorhanden“ gespeichert werden. Dauer, Durchschnittspace und Durchschnittsschlagzahl MUST auf der Sessionzeit ohne Pausen beruhen.

#### Scenario: Session nach App-Neustart
- **WHEN** der Nutzer eine Session beendet und die App neu startet
- **THEN** ist die Session mit Zusammenfassung und Verlauf weiterhin vorhanden

#### Scenario: Session mit FTMS-Rudergerät
- **WHEN** der Nutzer eine Session mit einem FTMS-Rudergerät mit 120 Schlägen beendet
- **THEN** zeigt die Zusammenfassung 120 Schläge und das Gerät als FTMS-Rudergerät, und die gespeicherten Schläge haben keine Durchzugs- und Kraftwerte

#### Scenario: Session mit Puls
- **WHEN** der Nutzer eine Session mit Puls beendet, ob vom Gurt oder vom Rudergerät
- **THEN** zeigt die Zusammenfassung Durchschnitts- und Maximalpuls als ganze Schläge pro Minute und keine weiteren Pulswerte

#### Scenario: Session ohne Puls
- **WHEN** der Nutzer eine Session ohne Puls beendet
- **THEN** zeigt die Zusammenfassung keine Pulswerte statt 0

#### Scenario: Bestehende Sessions nach dem Update
- **WHEN** die App mit Sessions aus einer früheren Version auf diese Version aktualisiert wird
- **THEN** sind alle Sessions mit Zusammenfassung, Verlauf, vollständigen Schlagdetails und Replay weiterhin vorhanden, gelten als PM5-Sessions, sofern sie mit einem PM5 aufgezeichnet wurden, und haben keine Pulszusammenfassung

#### Scenario: Sessions mit RR-Intervallen nach dem Update
- **WHEN** die App mit Sessions, zu denen RR-Intervalle und RMSSD gespeichert sind, auf diese Version aktualisiert wird
- **THEN** sind diese Sessions mit Zusammenfassung, Durchschnitts- und Maximalpuls, Verlauf und Replay weiterhin vorhanden, und RR-Intervalle und RMSSD sind nicht mehr gespeichert

#### Scenario: Zusammenfassung mit Pausen
- **WHEN** der Nutzer 10 Minuten rudert und dazwischen zweimal je etwa eine Minute stillsitzt
- **THEN** zeigt die Zusammenfassung eine Dauer von etwa 10 Minuten und 2 Pausen mit ihrer Gesamtdauer

#### Scenario: Session ohne Pause
- **WHEN** der Nutzer ohne Unterbrechung rudert
- **THEN** zeigt die Zusammenfassung keine Pausen

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
- **THEN** ergibt sich derselbe Puls wie bei der Aufzeichnung

#### Scenario: Export und Import mit Gurt-Daten
- **WHEN** eine Session mit direkt verbundenem Gurt exportiert und auf einem anderen Gerät importiert wird
- **THEN** zeigt die importierte Session denselben Puls und dieselbe Zusammenfassung

#### Scenario: Import einer Datei mit RMSSD
- **WHEN** der Nutzer eine Datei importiert, die mit einer früheren Version exportiert wurde und im Header einen RMSSD-Wert enthält
- **THEN** importiert die App die Session ohne Fehler, mit Puls und Zusammenfassung aus den Rohpaketen und ohne RMSSD

## REMOVED Requirements

### Requirement: RR-Intervalle in der Zusammenfassung
**Reason**: Die RR-Intervalle entfallen (siehe `rowing-telemetry`); die Zusammenfassung zeigt nur noch Durchschnitts- und Maximalpuls.
**Migration**: Keine. Die RR-Angaben bleiben in den Rohpaketen exportierter Sessions erhalten.
