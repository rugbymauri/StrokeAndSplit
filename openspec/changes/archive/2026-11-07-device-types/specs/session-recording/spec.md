# Spec Delta

## RENAMED Requirements

- FROM: `### Requirement: PM5-Reset während einer Session überstehen`
- TO: `### Requirement: Geräte-Reset während einer Session überstehen`

## MODIFIED Requirements

### Requirement: Session starten und beenden
Der Nutzer SHALL eine Session in der App starten und beenden können, solange eine Datenquelle verbunden ist. Distanz und Zeit der Session MUST ab dem Start der Session zählen, unabhängig vom Stand der Anzeige am Rudergerät.

#### Scenario: Session starten
- **WHEN** der Nutzer mit verbundenem PM5 „Session starten“ wählt, während der PM5 bereits 500 m anzeigt
- **THEN** beginnt die Session bei 0 m und 0:00

#### Scenario: Session mit FTMS-Rudergerät starten
- **WHEN** der Nutzer mit verbundenem FTMS-Rudergerät „Session starten“ wählt, während das Gerät bereits 800 m meldet
- **THEN** beginnt die Session bei 0 m und 0:00

#### Scenario: Session beenden
- **WHEN** der Nutzer „Session beenden“ wählt
- **THEN** wird die Session gespeichert und ihre Zusammenfassung angezeigt

### Requirement: Geräte-Reset während einer Session überstehen
Setzt das Rudergerät während einer laufenden Session Zeit oder Distanz zurück, SHALL die Session ohne Rücksprung weiterzählen. Das gilt für den PM5 und für FTMS-Rudergeräte.

#### Scenario: Neues Workout am PM5 mitten in der Session
- **WHEN** die Session bei 1200 m steht und der Nutzer am PM5 ein neues Workout startet
- **THEN** zählt die Session ab 1200 m weiter, sobald wieder gerudert wird

#### Scenario: FTMS-Rudergerät setzt die Distanz zurück
- **WHEN** die Session bei 1200 m steht und das FTMS-Rudergerät plötzlich 0 m meldet
- **THEN** zählt die Session ab 1200 m weiter, sobald wieder gerudert wird

### Requirement: Session vollständig speichern
Die App SHALL zu jeder Session eine Zusammenfassung (Startzeitpunkt, Dauer, Distanz, Durchschnittspace, Durchschnittswatt, Durchschnittsschlagzahl, Anzahl Schläge, Datenquelle, Geräteart) sowie den zeitlichen Verlauf aller Messwerte und Schlag-Ereignisse lokal speichern. Schlagdetails, die das Gerät nicht liefert, MUST als „nicht vorhanden“ gespeichert werden.

#### Scenario: Session nach App-Neustart
- **WHEN** der Nutzer eine Session beendet und die App neu startet
- **THEN** ist die Session mit Zusammenfassung und Verlauf weiterhin vorhanden

#### Scenario: Session mit FTMS-Rudergerät
- **WHEN** der Nutzer eine Session mit einem FTMS-Rudergerät mit 120 Schlägen beendet
- **THEN** zeigt die Zusammenfassung 120 Schläge und das Gerät als FTMS-Rudergerät, und die gespeicherten Schläge haben keine Durchzugs- und Kraftwerte

#### Scenario: Bestehende Sessions nach dem Update
- **WHEN** die App mit Sessions aus einer früheren Version auf diese Version aktualisiert wird
- **THEN** sind alle Sessions mit vollständigen Schlagdetails weiterhin vorhanden und gelten als PM5-Sessions, sofern sie mit einem PM5 aufgezeichnet wurden

### Requirement: Rohdaten für Replay speichern
Für Sessions mit einem echten Rudergerät SHALL die App die empfangenen Rohdaten mit Zeitstempel und dem Protokoll des Geräts (PM5 oder FTMS) speichern, sodass die Session später exakt wieder abgespielt werden kann.

#### Scenario: Replay einer echten Session
- **WHEN** eine mit einem echten PM5 aufgezeichnete Session abgespielt wird
- **THEN** ergeben sich dieselben Messwerte wie bei der Aufzeichnung

#### Scenario: Replay einer FTMS-Session
- **WHEN** eine mit einem FTMS-Rudergerät aufgezeichnete Session abgespielt wird
- **THEN** werden die Rohdaten als FTMS-Daten gelesen und ergeben dieselben Messwerte wie bei der Aufzeichnung

### Requirement: Session als Datei exportieren
Die App SHALL eine Session inklusive Rohdaten und Protokoll als Datei exportieren und eine solche Datei wieder importieren können, damit Aufnahmen zwischen Geräten und als Testdaten weitergegeben werden können. Dateien ohne Protokollangabe MUST als PM5-Aufnahmen gelesen werden.

#### Scenario: Export und Import
- **WHEN** der Nutzer eine Session auf dem Handy exportiert und auf dem Laptop importiert
- **THEN** ist sie auf dem Laptop in der Liste und kann abgespielt werden

#### Scenario: Import einer FTMS-Session
- **WHEN** der Nutzer eine exportierte FTMS-Session importiert
- **THEN** werden Messwerte und Zusammenfassung aus den FTMS-Rohdaten neu berechnet und stimmen mit dem Original überein

#### Scenario: Import einer älteren Datei
- **WHEN** der Nutzer eine Datei importiert, die vor dieser Version exportiert wurde und kein Protokoll angibt
- **THEN** wird sie als PM5-Aufnahme gelesen und wie bisher importiert
