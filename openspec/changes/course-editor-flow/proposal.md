# Proposal

## Why

Eine Strecke zusammenzustellen ist umständlich. Der Dialog „Zone einbauen“ zeigt zuerst alle Zonen ungeordnet, auch die der anderen Achse, und den Start erst darunter. Ob eine Zone passt, sieht man erst, nachdem man sie gewählt und den Start eingestellt hat. Zum Verschieben öffnet sich derselbe Dialog, und man stellt den Start dort neu ein. Der Ablauf soll vom Ort ausgehen: erst den Start wählen, dann aus den passenden Zonen eine antippen. Verschieben soll direkt im Strecken-Editor gehen.

## What Changes

- **Eigener Screen „Zone einbauen“** statt Dialog:
  - Oben der Start mit den Ruderblatt-Tasten und eine Vorschau der Strecke mit einer Marke am Start.
  - Darunter die Zonen der Achse der Strecke, gruppiert nach Härte: leicht, mittel, hart, mit Farbmarke.
  - Zonen, die am gewählten Start nicht passen, sind ausgegraut und nennen den Grund, etwa „überschneidet Tempo 2:30“ oder „ragt über das Streckenende“.
  - Zonen der anderen Achse erscheinen nicht.
  - Ein Tipp auf eine passende Zone baut sie ein und führt zurück zum Editor; ein Knopf „Einbauen“ entfällt.
  - **Zone anlegen** öffnet den Zonen-Editor mit der Achse der Strecke. Passt die neue Zone am Start, wird sie gleich eingebaut.
- **Verschieben im Strecken-Editor**:
  - Langdruck oder Tipp auf eine Zone im Balken oder in der Abschnittsliste markiert sie.
  - Unter dem Balken erscheinen Name, Start mit den Ruderblatt-Tasten und „Fertig“.
  - Die Tasten verschieben die Zone sofort. Die Grenzen sind die Nachbarzonen bzw. Anfang und Ende der Strecke, dort ist die Taste gesperrt.
  - „Fertig“ oder ein erneuter Tipp auf die markierte Zone beendet das Verschieben; ein Langdruck oder Tipp auf eine andere Zone markiert diese.
  - Gespeichert wird wie bisher mit „Speichern“ der Strecke.
- **Tipp auf einen freien Abschnitt** öffnet den Screen „Zone einbauen“ mit dem Anfang des Abschnitts als Start, wie heute den Dialog.
- **Fehleransicht des Editors**: Passt die Länge nicht mehr zu den Zonen, zeigen die Abschnitte ihre Härte-Farbe statt Blau (Rest aus `zone-intensity-colors`).

Nicht Teil dieses Changes:

- Ziehen einer Zone mit dem Finger.
- Über eine andere Zone hinweg verschieben. Dafür entfernt man die Zone und baut sie neu ein.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `courses`:
  - „Zonen in eine Strecke einbauen“: eigener Screen, Start zuerst, Zonen nach Härte gruppiert, unpassende Zonen ausgegraut mit Grund, andere Achse nicht sichtbar, ein Tipp baut ein.
  - Neu „Zone in einer Strecke verschieben“: markieren per Langdruck oder Tipp, Ruderblatt-Tasten mit den Nachbarn als Grenzen.
- `number-steppers`: „Zahlen über Ruderblatt-Tasten einstellen“ nennt auch das Verschieben einer eingebauten Zone.

## Impact

- **Code**:
  - Neu `lib/features/courses/place_zone_screen.dart`; `_PlaceZoneDialog` und `_ZoneOption` in `course_editor_screen.dart` fallen weg.
  - `course_editor_screen.dart`: Markieren und Verschieben, Bedienfeld unter dem Balken, Farbe in der Fehleransicht.
  - `course_strip.dart`: Rückruf für Langdruck.
- **Texte**: neue Texte für die Gruppen, das Bedienfeld und den Grund „passt hier nicht“; `coursePlace`, `courseMove`, `courseMoveZone`, `coursePlacedAt` und `courseOtherAxis` werden geprüft und fallen weg, wo sie nicht mehr gebraucht werden.
- **Tests**: `test/features/courses/courses_screen_test.dart` und `test/features/templates/templates_screen_test.dart` bauen Zonen heute über den Dialog ein und müssen auf den Screen umgestellt werden.
- **Doku**: README, Abschnitt „Zonen, Strecken und Vorlagen“ Schritt 2.
- **Daten**: keine Schema-Änderung.
