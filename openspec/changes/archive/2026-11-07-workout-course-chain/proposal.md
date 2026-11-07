# Proposal

## Why

Ein Workout besteht heute aus genau einer Strecke. Ein typisches Training hat aber mehrere Teile, etwa „Einrudern → 2 km Intervall → Ausrudern“. Dafür muss man heute entweder eine einzige grosse Strecke bauen, die die Strecken nicht wiederverwendet und in deren Ranglisten nicht zählt, oder drei Sessions nacheinander starten. Ausserdem kann ein Workout nur Runden oder offen, keine Gesamtdauer, obwohl eine Strecke ohne Workout das seit `course-rowing-free` kann.

## What Changes

- **Mehrere Strecken pro Workout**: Ein Workout reiht eine oder mehrere Strecken lückenlos aneinander, ähnlich wie eine Strecke Zonen aneinanderreiht, nur ohne freie Abschnitte dazwischen. Die erste Strecke legt die Achse fest; danach lassen sich nur Strecken derselben Achse (Meter oder Sekunden) anhängen. Dieselbe Strecke darf mehrfach vorkommen.
- **Workout-Editor**: Strecken anhängen, entfernen und in der Reihenfolge verschieben. Die Gesamtlänge einer Runde ist die Summe der Streckenlängen.
- **Runden, Dauer oder offen für das ganze Workout**: Wie auf dem Start-Screen einer Strecke wählt der Nutzer im Workout genau eine Option. Eine Runde ist die ganze Kette der Strecken. Neu ist die Dauer im Workout: Die Session endet nach der Ruderzeit ohne Pausen, auch mitten in einer Runde.
- **Rudern einer Kette**: Runden, Abschnitte, Zonenstatus und Ergebnisse laufen über die ganze Kette wie heute über eine Strecke. Das Live-Display nennt zusätzlich die aktuelle Strecke, wenn das Workout mehr als eine hat. Die Rundenspur zeigt weiter die ganze Runde; ihr Ghost ist bei mehreren Strecken die schnellste Runde früherer Sessions dieses Workouts mit derselben Streckenfolge.
- **Session merkt sich alle Strecken**: Eine Session speichert die geruderten Versionen aller Strecken in ihrer Reihenfolge, auch im Export. Ältere Dateien mit einer Strecke bleiben lesbar.
- **Ranglisten**: Jede vollständig geruderte Strecke einer Kette zählt in der Rangliste dieser Strecke, jede Zonenfahrt in der der Zone. Die Rangliste eines Workouts trennt nach Folge der Streckenlängen und Rundenzahl. Ein Workout mit Dauer hat wie eines mit offener Rundenzahl keine Rangliste.
- **Strecke löschen**: Eine gelöschte Strecke verschwindet aus allen Workouts. Ein Workout, das dadurch keine Strecke mehr hat, wird mitgelöscht; die Bestätigung nennt es.
- **Datenbank Schema 12**: Rundenzahl und Dauer wandern von den Bausteinen ins Workout, die Strecken einer Session in eine eigene Tabelle. Bestehende Workouts und Sessions werden übernommen und verhalten sich unverändert.

Nicht Teil dieses Changes:

- Achsen mischen (Zeit- und Distanzstrecken in einem Workout).
- Runden oder Dauer pro Strecke in der Kette.
- Eine Rangliste „beste Distanz in 30 min“ für Workouts mit Dauer.
- Pausen oder freie Abschnitte zwischen den Strecken.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `workouts`: Ein Workout hat eine oder mehrere Strecken derselben Achse und Runden, Dauer oder offen; Editor, Liste und Workout-Screen zeigen die Kette.
- `course-rowing`: Runden, Abschnitte und Ergebnisse laufen über die Kette; Live-Display und Zusammenfassung nennen die Strecken; ein Workout kann nach seiner Dauer enden; Export und Import tragen alle Strecken.
- `session-recording`: Eine Session ist mit den geruderten Versionen aller Strecken ihres Workouts verknüpft.
- `statistics`: Strecken einer Kette zählen in ihren Ranglisten; die Rangliste eines Workouts trennt nach Streckenfolge; Workouts mit Dauer haben keine.
- `ghost`: Bei mehreren Strecken ist der Ghost der Rundenspur die schnellste Runde früherer Sessions dieses Workouts mit derselben Streckenfolge.
- `courses`: Das Löschen einer Strecke entfernt sie aus Workouts und löscht nur Workouts, die keine Strecke mehr hätten.

## Impact

- Datenbank: Schema 12 mit Migration (`workouts` bekommt Runden und Dauer, `workout_blocks` verliert `laps`, neue Tabelle für die Strecken einer Session, `sessions.course_version_id` wird übernommen).
- `lib/data/workouts/`, `lib/data/sessions/` (Plan, Recorder, Export/Import), `lib/data/statistics/` (Ranglisten-SQL), Ghost, Live-Display, Zusammenfassung.
- `lib/features/workouts/` (Editor, Screen, Liste), Löschdialog der Strecken, l10n DE/EN.
- Exportformat `.strokesplit`: neue Liste der Strecken; der Import liest weiter Dateien mit einer Strecke.
