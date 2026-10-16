# Proposal

## Why

In `courses` hat jede Strecke ihre Segmente mit Bändern selbst. Wer dieselbe Belastung in mehreren Strecken nutzt, etwa einen 100-m-Sprint oder 500 m bei 2:30, muss sie in jeder Strecke neu anlegen. Ändert er sie, muss er jede Strecke einzeln anpassen, und die Strecken laufen auseinander. Ruderer denken in benannten Belastungen: „nach 500 m ein Sprint, ab 1000 m 500 m Ausdauer bei 2:30“. Zonen als eigene, wiederverwendbare Bausteine bilden das direkt ab.

## What Changes

- **Zonen definieren**: Eine Zone hat einen Namen, eine Achse (Distanz oder Zeit), eine feste Länge und optional ein Pace-Band und ein Schlagzahl-Band, mindestens eines davon. Zonen lassen sich in einer eigenen Liste anlegen, bearbeiten und löschen.
- **Zonen in Strecken einbauen**: Eine Strecke besteht aus ihrer Länge und eingebauten Zonen, jede mit einer Startposition. Was zwischen den Zonen liegt, ist frei. Eine Zone passt nur in eine Strecke mit derselben Achse, muss ganz in der Strecke liegen und darf sich mit keiner anderen Zone überschneiden. Dieselbe Zone darf mehrfach in einer Strecke stecken.
- **Änderungen wirken überall**: Eine Strecke verweist auf ihre Zonen. Ändert der Nutzer eine Zone, gilt das für alle Strecken, die sie enthalten. Wurde eine dieser Strecken schon gerudert, entsteht wie bei jeder Definitionsänderung eine neue Version, damit alte Rundenzeiten vergleichbar bleiben.
- **Bänder nur noch in Zonen**: Die manuelle Einteilung in Segmente mit Bändern aus `courses` entfällt. Intern bleibt die Strecke eine Folge von Abschnitten, die Runden-Logik ändert sich nicht.
- **Anzeige**: Live-Display und Zusammenfassung nennen den Namen der aktuellen Zone bzw. „frei“ statt „Segment 2 von 3“.
- **Migration**: Bestehende Segmente mit Band werden zu Zonen, benannt nach Strecke und Position. Freie Segmente gehen in den Lücken auf. Geruderte Sessions bleiben unverändert.

Nicht Teil dieses Changes: Zonen mit einer anderen Achse als die Strecke, Zonen mit variabler Länge pro Strecke, benannte Intensitäten mit persönlichen Pace-Werten und Puls-Zonen.

## Capabilities

### New Capabilities

- `zones`: Zonen mit Name, Achse, Länge und Bändern anlegen, bearbeiten und löschen.

### Modified Capabilities

- `courses`: Eine Strecke besteht aus Länge und eingebauten Zonen statt aus Segmenten mit eigenen Bändern. Änderungen an Zonen führen zu neuen Versionen geruderter Strecken.
- `course-rowing`: Das Live-Display nennt die aktuelle Zone bzw. „frei“.

Die Deltas beziehen sich auf den Stand von `courses` nach der Archivierung.

## Impact

- Datenbank: neue Tabelle `zones`, `course_segments` bekommt einen Verweis auf die Zone und deren Namen zum Zeitpunkt der Version. Migration der bestehenden Segmente mit Band zu Zonen.
- `lib/data/courses`: Repository für Zonen, Auflösen einer Strecke aus Länge und Zonen in Abschnitte, neue Versionen bei Zonenänderungen.
- `lib/features`: Zonenliste und Zonen-Editor, Strecken-Editor mit „Zone einbauen“ statt Segment-Editor, dritter Tab „Zonen“.
- Export `.aergrow`: Der Header führt pro Abschnitt den Zonennamen mit. Beim Import werden fehlende Zonen angelegt.
- `LapTracker` und Zonenbewertung bleiben unverändert, sie arbeiten weiter auf aufgelösten Abschnitten.
- Design: Canvas „AergRow Frontend“, Reihe „Vorlagen, Strecken und Zonen“: „Zonenliste“, „Zonen-Editor“, „Strecken-Editor“, „Zone einbauen“, „Streckenliste“.
- Ersetzt im Change `ui-design` die Regel zum Ändern von Segmentlängen.
