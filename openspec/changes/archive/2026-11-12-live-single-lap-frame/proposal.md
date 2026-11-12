# Proposal

## Why

Bei einem Workout mit genau einer Runde zeigt der Fortschrittsrahmen um die Pace aussen die Gesamtstrecke und in der Mitte die Runde, die gleich lang und gleich weit gefüllt sind. Die äussere Spur und die Legendenzeile „Gesamt“ wiederholen nur die Runde und nehmen Platz und Aufmerksamkeit weg.

## What Changes

- Bei genau einer geplanten Runde zeigt der Rahmen nur die Spuren für Runde und Abschnitt, wie bei offener Rundenzahl.
- Die Legende der Pace-Box zeigt dann keine Zeile „Gesamt“; die Rundenzeile heisst nur „Runde“ (englisch „Lap“) ohne Zahl und zeigt weiter die Restdistanz bzw. Restzeit der Runde.
- Ein Ghost läuft dann nur auf Runde und Abschnitt.
- Unverändert: mehrere Runden, offene Rundenzahl und Workouts mit Gesamtdauer (dort bleibt die äussere Spur die Zeit).

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `live-display`: Die Anforderung „Fortschrittsrahmen um die Pace“ bekommt das Szenario „Eine Runde“.

## Impact

- Live-Display: Modell und Legende des Fortschrittsrahmens, eine neue Übersetzung für „Runde“ ohne Zahl. README-Abschnitt zum Fortschrittsrahmen. Keine Änderung an Daten, Schema oder Aufzeichnung.
