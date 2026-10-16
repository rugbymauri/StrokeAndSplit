# Proposal

## Why

Die Screens aus `foundation` und `courses` sind funktional, folgen aber keiner gemeinsamen Gestaltung. Am Erg muss man die Werte aus etwa einem Meter Abstand und unter Belastung lesen. Dafür braucht es eine klare Designsprache mit grossen Zahlen, wenig Text und Farben, die eine feste Bedeutung haben. Ausserdem fehlt beim Rudern einer Vorlage ein Überblick auf einen Blick: Wo stehe ich in der Strecke, in der Runde und im aktuellen Abschnitt (Zone oder frei)? Das Design dafür ist im Claude-Design-Canvas „AergRow Frontend“ festgelegt (Link und Screens in `design.md`).

## What Changes

- **Designsprache**: dunkles Thema, Barlow Condensed für Zahlen, IBM Plex Sans für Text, feste Farbbedeutungen (Blau: in der Zone, Orange: ausserhalb, Violett: Ghost), Touch-Ziele ab 44 px. Die Werte stehen als Tokens in `design.md`.
- **Geräte zuerst**: Die App beginnt mit „Geräte wählen“: Rudergerät (PM5 oder FTMS-Rudergerät aus `device-types`, oder Simulator im PM5- bzw. FTMS-Modus) und optional der Pulsgurt aus `heart-rate`; danach geht es zum Startbildschirm.
- **Startbildschirm**: gewählte Geräte als kompakte Zeile, „Rudern“, „Frei rudern“, eine Kachel „Nochmal“ mit der zuletzt geruderten Vorlage und ein Link zu den Sessions. Schlanker als im Canvas, der Kacheln aller Vorlagen und eine Liste der letzten Sessions zeigt. Die Sprachwahl aus `translations` bleibt als Symbol in der App-Leiste des Startbildschirms und steht auch auf „Geräte wählen“, damit sie schon beim ersten Start erreichbar ist.
- **Live-Display frei**: grosse Pace, Kacheln für Schlagzahl, Watt, Zeit und Distanz, eine Zeile für Puls, Kalorien und Ø Pace. Eigene Layouts für Hoch- und Querformat.
- **Live-Display mit Vorlage**: Die Pace steht in einer Box mit abgerundeten Ecken. Der Rahmen der Box zeigt den Fortschritt als drei Spuren wie bei einer Uhr: aussen die Gesamtstrecke, in der Mitte die Runde, innen der aktuelle Abschnitt (Zone oder frei). Die Spitze jeder Spur ist ein Schiffchen. In der Box stehen Pace, Zonenstatus mit Band und die Restangaben zu Strecke, Runde und Abschnitt, beim Abschnitt mit dem Zonennamen bzw. „frei“. Die Angaben der bisherigen Streckenleiste (`course_bar.dart`) gehen darin auf. Die Schlagzahl hat eine eigene, kleinere Karte mit Zonenstatus.
- **Vorlagen, Strecken und Zonen**: Der gemeinsame Screen mit den Tabs „Vorlagen“, „Strecken“ und „Zonen“ besteht seit `zones` und wird neu gestaltet. Jede Vorlage und jede Strecke zeigt einen Ablaufbalken (Breite: Länge, Blau: Zone mit Band, Grau: frei, Helligkeit: Tempo). Dafür wird der bestehende `CourseStrip` aus `zones` ausgebaut. Neu gestaltete Editoren für Vorlage und Strecke. Zonen, ihr Editor und das Einbauen in Strecken kommen aus `zones` und bekommen hier nur die Gestaltung.
- **Zahlen über Ruderblatt-Tasten**: In allen Editoren werden Zahlen nicht mehr getippt, sondern mit einem Tastenpaar „mehr“ und „weniger“ in festen Schritten eingestellt. Die Tasten sehen aus wie ein eckiges Ruderblatt, dessen Pfeil die Stange bildet: nach oben für mehr, nach unten für weniger. Am Erg lässt sich so mit verschwitzten Fingern und ohne Bildschirmtastatur einstellen. Das gilt auch für den Zonen-Editor und „Zone einbauen“ aus `zones`.
- **Zusammenfassung**: Gesamtwerte, Rundenzeiten mit Balken für den Anteil in der Zone, Durchschnittswerte, „Abspielen“ und „Fertig“.
- **Texte**: Alle neuen und geänderten Texte stehen in den ARB-Dateien aus `translations`, auf Deutsch und Englisch.

Nicht Teil dieses Changes: das Lesen und Anzeigen der Kraftkurve (Change `force-curve`), die Daten und die Auswahl des Ghosts (Change `ghost`) sowie das Koppeln eines Brustgurts (Change `heart-rate`). Das Design reserviert für alle drei den Platz, und dieser Change baut die Anzeige so, dass sie die Werte aufnehmen kann, sobald sie vorhanden sind.

## Capabilities

### New Capabilities

- `number-steppers`: Zahlenwerte in den Editoren über Ruderblatt-Tasten mit festen Schritten einstellen.

### Modified Capabilities

- `live-display`: Fortschrittsrahmen um die Pace beim Rudern einer Vorlage, mit einer Spur für den aktuellen Abschnitt (Zone oder frei), eigene Layouts für Hoch- und Querformat.

## Impact

- `lib/app`: Theme mit Farb- und Schrift-Tokens. Die Schriften Barlow Condensed und IBM Plex Sans (SIL Open Font License) werden als Assets eingebunden, damit die App offline gleich aussieht.
- `lib/features/connection/`: neuer Screen „Geräte wählen“ (PM5, FTMS-Rudergerät, Simulator PM5 und FTMS, Platz für den Pulsgurt, Sprachwahl in der App-Leiste) vor dem Startbildschirm; `start_screen.dart` mit neuem Aufbau, Gerätezeile und Sprachwahl in der App-Leiste.
- `lib/features/live`: Layouts für Hoch- und Querformat, Pace-Box mit Fortschrittsrahmen als `CustomPainter`, Schlagzahl-Karte. `course_bar.dart` geht in der Pace-Box auf.
- `lib/features/templates`, `lib/features/courses`, `lib/features/zones`: Gestaltung des bestehenden Screens mit drei Tabs. `lib/features/courses/course_strip.dart` wird zum Ablaufbalken nach Design D4 ausgebaut.
- `lib/features/sessions/session_summary_screen.dart`: neuer Aufbau.
- `lib/features/templates`, `lib/features/courses`, `lib/features/zones`: Zahlenfelder in den Editoren werden durch das Widget für Ruderblatt-Tasten ersetzt.
- `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb`: neue Texte, generierter Code wird mit `make l10n` erzeugt.
- Keine Änderung an Datenbank, Protokoll oder Aufzeichnung.
- Voraussetzung: `courses`, `zones`, `device-types` und `translations` sind in `main`. Der Branch basiert auf `main`.
