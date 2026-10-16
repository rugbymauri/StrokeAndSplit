# Proposal

## Why

Die Screens aus `foundation` und `courses` sind funktional, folgen aber keiner gemeinsamen Gestaltung. Am Erg muss man die Werte aus etwa einem Meter Abstand und unter Belastung lesen. Dafür braucht es eine klare Designsprache mit grossen Zahlen, wenig Text und Farben, die eine feste Bedeutung haben. Ausserdem fehlt beim Rudern einer Vorlage ein Überblick auf einen Blick: Wo stehe ich in der Strecke, in der Runde und im Segment? Das Design dafür ist im Claude-Design-Canvas „AergRow Frontend“ festgelegt (Link und Screens in `design.md`).

## What Changes

- **Designsprache**: dunkles Thema, Barlow Condensed für Zahlen, IBM Plex Sans für Text, feste Farbbedeutungen (Blau: in der Zone, Orange: ausserhalb, Violett: Ghost), Touch-Ziele ab 44 px. Die Werte stehen als Tokens in `design.md`.
- **Startbildschirm**: Quelle wählen (PM5 oder Simulator), Kurzwahl der Vorlagen, „Frei rudern“ und die letzten Sessions.
- **Live-Display frei**: grosse Pace, Kacheln für Schlagzahl, Watt, Zeit und Distanz, eine Zeile für Puls, Kalorien und Ø Pace. Eigene Layouts für Hoch- und Querformat.
- **Live-Display mit Vorlage**: Die Pace steht in einer Box mit abgerundeten Ecken. Der Rahmen der Box zeigt den Fortschritt als drei Spuren wie bei einer Uhr: aussen die Gesamtstrecke, in der Mitte die Runde, innen der aktuelle Abschnitt (Zone oder frei). Die Spitze jeder Spur ist ein Schiffchen. In der Box stehen Pace, Zonenstatus mit Band und die Restangaben zu Strecke, Runde und Segment. Die Schlagzahl hat eine eigene, kleinere Karte mit Zonenstatus.
- **Vorlagen und Strecken**: ein gemeinsamer Screen mit Tabs „Vorlagen“ und „Strecken“. Jede Vorlage und jede Strecke zeigt einen Segmentbalken (Breite: Länge, Blau: mit Band, Grau: frei, Helligkeit: Tempo). Neu gestaltete Editoren für Vorlage und Strecke. Zonen als wiederverwendbare Bausteine, ein dritter Tab „Zonen“ und das Einbauen in Strecken regelt der Change `zones`.
- **Zusammenfassung**: Gesamtwerte, Rundenzeiten mit Balken für den Anteil in der Zone, Durchschnittswerte, „Abspielen“ und „Fertig“.

Nicht Teil dieses Changes: das Lesen und Anzeigen der Kraftkurve (Change `force-curve`), die Daten und die Auswahl des Ghosts (Change `ghost`) sowie das Koppeln eines Brustgurts (Change `heart-rate`). Das Design reserviert für alle drei den Platz, und dieser Change baut die Anzeige so, dass sie die Werte aufnehmen kann, sobald sie vorhanden sind.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `live-display`: Fortschrittsrahmen um die Pace beim Rudern einer Vorlage, eigene Layouts für Hoch- und Querformat.

## Impact

- `lib/app`: Theme mit Farb- und Schrift-Tokens. Die Schriften Barlow Condensed und IBM Plex Sans (SIL Open Font License) werden als Assets eingebunden, damit die App offline gleich aussieht.
- `lib/features/connection/start_screen.dart`: neuer Aufbau des Startbildschirms.
- `lib/features/live`: Layouts für Hoch- und Querformat, Pace-Box mit Fortschrittsrahmen als `CustomPainter`, Schlagzahl-Karte. `course_bar.dart` geht im Fortschrittsrahmen auf.
- `lib/features/templates`, `lib/features/courses`: gemeinsamer Screen mit Tabs, Segmentbalken als Widget.
- `lib/features/sessions/session_summary_screen.dart`: neuer Aufbau.
- Keine Änderung an Datenbank, Protokoll oder Aufzeichnung.
- Voraussetzung: `courses` ist abgeschlossen. Der Branch basiert auf `feature/courses`.
