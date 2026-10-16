# rowing-telemetry Specification

## Purpose

Übersetzt die Rohdaten des PM5 in einheitliche Rudermesswerte und Ereignisse, auf denen Anzeige, Aufzeichnung und spätere Spielmechanik aufbauen, unabhängig davon, woher die Daten stammen.

## Requirements

### Requirement: Laufende Messwerte bereitstellen
Die App SHALL aus den Statusdaten des PM5 laufend folgende Messwerte bereitstellen: verstrichene Zeit, Distanz, aktuelle Pace pro 500 m, Leistung in Watt, Schlagzahl, Herzfrequenz (falls vorhanden) und Kalorien.

#### Scenario: Rudern mit verbundenem PM5
- **WHEN** der Nutzer rudert und der PM5 Statusdaten sendet
- **THEN** stehen die Messwerte innerhalb einer Sekunde nach Eintreffen der Daten zur Verfügung

#### Scenario: Kein Herzfrequenzgurt
- **WHEN** der PM5 keine Herzfrequenz liefert
- **THEN** ist die Herzfrequenz als „nicht vorhanden“ gekennzeichnet statt als 0 oder 255

### Requirement: Schlag-Ereignisse bereitstellen
Die App SHALL pro Ruderschlag ein Ereignis bereitstellen, das mindestens Schlagnummer, Durchzugslänge, Durchzugszeit, Erholungszeit, Spitzenkraft und Durchschnittskraft enthält.

#### Scenario: Ein Schlag wird ausgeführt
- **WHEN** der PM5 die Daten eines abgeschlossenen Schlags sendet
- **THEN** wird genau ein Schlag-Ereignis mit fortlaufender Schlagnummer erzeugt

### Requirement: Workout-Zustand erkennen
Die App SHALL den vom PM5 gemeldeten Workout-Typ und Workout-Zustand (z.B. wartet, rudert, Pause, beendet) bereitstellen und Zustandswechsel als Ereignis melden.

#### Scenario: Workout am PM5 gestartet
- **WHEN** der Nutzer am PM5 zu rudern beginnt
- **THEN** meldet die App einen Wechsel in den Zustand „rudert“

#### Scenario: Workout am PM5 zurückgesetzt
- **WHEN** der Nutzer am PM5 ein neues Workout startet und Zeit und Distanz auf null fallen
- **THEN** meldet die App einen Zustandswechsel, statt einen Rücksprung der Werte stillschweigend weiterzugeben

### Requirement: Einheitliche Daten über alle Quellen
Messwerte und Ereignisse SHALL für alle Datenquellen (echter PM5, Simulator, Replay) dieselbe Form und Bedeutung haben, sodass Anzeige und Aufzeichnung die Quelle nicht unterscheiden müssen.

#### Scenario: Replay einer aufgezeichneten Session
- **WHEN** eine aufgezeichnete Session abgespielt wird
- **THEN** entstehen dieselben Messwerte und Ereignisse wie bei der ursprünglichen Live-Session

### Requirement: Fehlerhafte Daten tolerieren
Unvollständige oder unbekannte Datenpakete vom PM5 MUST NOT zum Absturz führen. Sie SHALL verworfen und für die Fehlersuche protokolliert werden.

#### Scenario: Unbekanntes Paket
- **WHEN** ein Datenpaket mit unerwarteter Länge oder unbekanntem Typ eintrifft
- **THEN** wird es ignoriert, protokolliert, und die übrigen Messwerte laufen weiter
