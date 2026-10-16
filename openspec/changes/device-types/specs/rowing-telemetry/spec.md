# Spec Delta

## MODIFIED Requirements

### Requirement: Laufende Messwerte bereitstellen
Die App SHALL aus den Statusdaten des Rudergeräts (PM5 oder FTMS) laufend folgende Messwerte bereitstellen: verstrichene Zeit, Distanz, aktuelle Pace pro 500 m, Leistung in Watt, Schlagzahl, Herzfrequenz (falls vorhanden) und Kalorien. Liefert ein Gerät einen Wert nicht, MUST er als „nicht vorhanden“ gekennzeichnet sein.

#### Scenario: Rudern mit verbundenem PM5
- **WHEN** der Nutzer rudert und der PM5 Statusdaten sendet
- **THEN** stehen die Messwerte innerhalb einer Sekunde nach Eintreffen der Daten zur Verfügung

#### Scenario: Rudern mit verbundenem FTMS-Rudergerät
- **WHEN** der Nutzer rudert und das FTMS-Rudergerät Rudern-Daten sendet
- **THEN** stehen die Messwerte innerhalb einer Sekunde nach Eintreffen der Daten zur Verfügung

#### Scenario: Kein Herzfrequenzgurt
- **WHEN** das Rudergerät keine Herzfrequenz liefert
- **THEN** ist die Herzfrequenz als „nicht vorhanden“ gekennzeichnet statt als 0 oder 255

#### Scenario: FTMS-Gerät ohne Kalorien
- **WHEN** ein FTMS-Rudergerät keinen Energieverbrauch meldet
- **THEN** sind die Kalorien als „nicht vorhanden“ gekennzeichnet und die übrigen Messwerte laufen weiter

### Requirement: Schlag-Ereignisse bereitstellen
Die App SHALL pro Ruderschlag ein Ereignis bereitstellen, das mindestens Schlagnummer, Zeit und Distanz enthält. Durchzugslänge, Durchzugszeit, Erholungszeit, Spitzenkraft und Durchschnittskraft SHALL enthalten sein, wenn das Gerät sie liefert. Fehlen sie, MUST sie als „nicht vorhanden“ gekennzeichnet sein und MUST NOT geschätzt werden.

#### Scenario: Ein Schlag wird ausgeführt
- **WHEN** der PM5 die Daten eines abgeschlossenen Schlags sendet
- **THEN** wird genau ein Schlag-Ereignis mit fortlaufender Schlagnummer und allen Schlagdetails erzeugt

#### Scenario: Ein Schlag am FTMS-Rudergerät
- **WHEN** der Schlagzähler eines FTMS-Rudergeräts um eins steigt
- **THEN** wird genau ein Schlag-Ereignis mit dieser Schlagnummer erzeugt, dessen Durchzugs- und Kraftwerte als „nicht vorhanden“ gekennzeichnet sind

#### Scenario: Verpasste Zählerstände
- **WHEN** der Schlagzähler eines FTMS-Rudergeräts zwischen zwei Paketen von 40 auf 42 springt
- **THEN** werden zwei Schlag-Ereignisse mit den Nummern 41 und 42 erzeugt

### Requirement: Workout-Zustand erkennen
Die App SHALL den vom PM5 gemeldeten Workout-Typ und Workout-Zustand (z.B. wartet, rudert, Pause, beendet) bereitstellen und Zustandswechsel als Ereignis melden. Bei FTMS-Rudergeräten MUST Workout-Typ und -Zustand als „unbekannt“ gekennzeichnet sein, weil der Standard sie nicht verlässlich liefert.

#### Scenario: Workout am PM5 gestartet
- **WHEN** der Nutzer am PM5 zu rudern beginnt
- **THEN** meldet die App einen Wechsel in den Zustand „rudert“

#### Scenario: Workout am PM5 zurückgesetzt
- **WHEN** der Nutzer am PM5 ein neues Workout startet und Zeit und Distanz auf null fallen
- **THEN** meldet die App einen Zustandswechsel, statt einen Rücksprung der Werte stillschweigend weiterzugeben

#### Scenario: FTMS-Rudergerät
- **WHEN** ein FTMS-Rudergerät die Datenquelle ist
- **THEN** sind Workout-Typ und Workout-Zustand „unbekannt“

### Requirement: Einheitliche Daten über alle Quellen
Messwerte und Ereignisse SHALL für alle Datenquellen (echter PM5, FTMS-Rudergerät, Simulator, Replay) dieselbe Form und Bedeutung haben, sodass Anzeige, Aufzeichnung und Strecken die Quelle nicht unterscheiden müssen.

#### Scenario: Replay einer aufgezeichneten Session
- **WHEN** eine aufgezeichnete Session abgespielt wird
- **THEN** entstehen dieselben Messwerte und Ereignisse wie bei der ursprünglichen Live-Session

#### Scenario: Gleiche Pace, gleiche Leistung
- **WHEN** ein PM5 und ein FTMS-Rudergerät dieselbe Pace von 2:00 pro 500 m melden
- **THEN** zeigt die App für beide dieselbe Leistung in Watt an

### Requirement: Fehlerhafte Daten tolerieren
Unvollständige oder unbekannte Datenpakete vom Rudergerät MUST NOT zum Absturz führen. Sie SHALL verworfen und für die Fehlersuche protokolliert werden.

#### Scenario: Unbekanntes Paket
- **WHEN** ein Datenpaket mit unerwarteter Länge oder unbekanntem Typ eintrifft
- **THEN** wird es ignoriert, protokolliert, und die übrigen Messwerte laufen weiter

#### Scenario: FTMS-Paket kürzer als angekündigt
- **WHEN** ein FTMS-Paket laut seinen Flags mehr Felder enthalten müsste, als Bytes vorhanden sind
- **THEN** wird es verworfen und protokolliert, und die übrigen Messwerte laufen weiter

## ADDED Requirements

### Requirement: Zeit bei FTMS selbst messen
Bei FTMS-Rudergeräten SHALL die App die verstrichene Zeit selbst aus dem Eintreffen der Daten messen, unabhängig davon, ob das Gerät eine Zeit meldet. Die Zeit MUST nur laufen, solange gerudert wird, und MUST stehen bleiben, wenn der Nutzer aufhört, so wie am PM5.

#### Scenario: Gerät ohne Zeitangabe
- **WHEN** ein FTMS-Rudergerät keine verstrichene Zeit meldet und der Nutzer 2 Minuten rudert
- **THEN** zeigt die App etwa 2:00 als verstrichene Zeit

#### Scenario: Pause am FTMS-Rudergerät
- **WHEN** der Nutzer aufhört zu rudern und weder Distanz noch Schlagzähler mehrere Sekunden lang steigen
- **THEN** bleibt die verstrichene Zeit stehen und läuft weiter, sobald wieder gerudert wird

### Requirement: Reset bei FTMS erkennen
Fällt bei einem FTMS-Rudergerät die Distanz oder der Schlagzähler zurück, SHALL die App das als Reset am Gerät melden, so wie den Reset eines Workouts am PM5.

#### Scenario: Gerät setzt die Distanz zurück
- **WHEN** ein FTMS-Rudergerät bei 1500 m steht und das nächste Paket 0 m meldet
- **THEN** meldet die App einen Reset, statt einen Rücksprung der Werte stillschweigend weiterzugeben

### Requirement: Unplausible FTMS-Werte verwerfen
Die App SHALL einzelne Werte eines FTMS-Rudergeräts als „nicht vorhanden“ behandeln, wenn sie ausserhalb plausibler Grenzen für das Rudern liegen oder 0 als Platzhalter für „kein Wert“ verwendet wird. Die übrigen Werte desselben Pakets MUST weiter verwendet werden.

#### Scenario: Pace 0
- **WHEN** ein FTMS-Rudergerät eine Pace von 0:00 pro 500 m meldet
- **THEN** ist die Pace „nicht vorhanden“ und Distanz und Schlagzahl werden weiter angezeigt

#### Scenario: Herzfrequenz 0
- **WHEN** ein FTMS-Rudergerät eine Herzfrequenz von 0 meldet
- **THEN** ist die Herzfrequenz „nicht vorhanden“

#### Scenario: Unmögliche Schlagzahl
- **WHEN** ein FTMS-Rudergerät eine Schlagzahl von 120 pro Minute meldet
- **THEN** ist die Schlagzahl „nicht vorhanden“
