# session-recording Specification

## Purpose

Zeichnet Rudersessions lokal auf dem Gerät auf, mit Zusammenfassung und vollständigem Datenverlauf. Darauf bauen Historie, Replay und später Ghost und Progression auf.

## Requirements

### Requirement: Session starten und beenden
Der Nutzer SHALL eine Session in der App starten und beenden können, solange eine Datenquelle verbunden ist. Distanz und Zeit der Session MUST ab dem Start der Session zählen, unabhängig vom Stand der PM5-Anzeige.

#### Scenario: Session starten
- **WHEN** der Nutzer mit verbundenem PM5 „Session starten“ wählt, während der PM5 bereits 500 m anzeigt
- **THEN** beginnt die Session bei 0 m und 0:00

#### Scenario: Session beenden
- **WHEN** der Nutzer „Session beenden“ wählt
- **THEN** wird die Session gespeichert und ihre Zusammenfassung angezeigt

### Requirement: PM5-Reset während einer Session überstehen
Setzt der PM5 während einer laufenden Session Zeit und Distanz zurück, SHALL die Session ohne Rücksprung weiterzählen.

#### Scenario: Neues Workout am PM5 mitten in der Session
- **WHEN** die Session bei 1200 m steht und der Nutzer am PM5 ein neues Workout startet
- **THEN** zählt die Session ab 1200 m weiter, sobald wieder gerudert wird

### Requirement: Session vollständig speichern
Die App SHALL zu jeder Session eine Zusammenfassung (Startzeitpunkt, Dauer, Distanz, Durchschnittspace, Durchschnittswatt, Durchschnittsschlagzahl, Anzahl Schläge, Datenquelle) sowie den zeitlichen Verlauf aller Messwerte und Schlag-Ereignisse lokal speichern.

#### Scenario: Session nach App-Neustart
- **WHEN** der Nutzer eine Session beendet und die App neu startet
- **THEN** ist die Session mit Zusammenfassung und Verlauf weiterhin vorhanden

### Requirement: Session bei Abbruch nicht verlieren
Bricht die Verbindung ab oder wird die App unerwartet beendet, SHALL die bis dahin aufgezeichnete Session erhalten bleiben.

#### Scenario: App stürzt während der Session ab
- **WHEN** die App nach 10 Minuten Session unerwartet beendet wird
- **THEN** ist nach dem Neustart eine Session mit den Daten bis kurz vor dem Abbruch vorhanden und als unvollständig gekennzeichnet

### Requirement: Rohdaten für Replay speichern
Für Sessions mit einem echten PM5 SHALL die App die empfangenen Rohdaten mit Zeitstempel speichern, sodass die Session später exakt wieder abgespielt werden kann.

#### Scenario: Replay einer echten Session
- **WHEN** eine mit einem echten PM5 aufgezeichnete Session abgespielt wird
- **THEN** ergeben sich dieselben Messwerte wie bei der Aufzeichnung

### Requirement: Sessions auflisten
Die App SHALL eine Liste aller gespeicherten Sessions anzeigen, neueste zuerst, mit Datum, Dauer, Distanz und Durchschnittspace.

#### Scenario: Mehrere Sessions vorhanden
- **WHEN** der Nutzer die Session-Liste öffnet
- **THEN** sieht er alle Sessions, die neueste oben

### Requirement: Session löschen
Der Nutzer SHALL eine gespeicherte Session nach einer Bestätigung löschen können.

#### Scenario: Session löschen
- **WHEN** der Nutzer eine Session löschen will und bestätigt
- **THEN** ist die Session samt Verlauf und Rohdaten entfernt

### Requirement: Session als Datei exportieren
Die App SHALL eine Session inklusive Rohdaten als Datei exportieren und eine solche Datei wieder importieren können, damit Aufnahmen zwischen Geräten und als Testdaten weitergegeben werden können.

#### Scenario: Export und Import
- **WHEN** der Nutzer eine Session auf dem Handy exportiert und auf dem Laptop importiert
- **THEN** ist sie auf dem Laptop in der Liste und kann abgespielt werden
