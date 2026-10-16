# Design

## Context

Das Verhalten steht in den Specs, die Motivation in `proposal.md`. Die visuelle Vorlage ist der Claude-Design-Canvas **AergRow Frontend**:



Der Canvas ist privat. Wer ihn öffnen soll, braucht eine Freigabe über das Share-Menü des Canvas. Die Screens darin sind statische Mockups ohne echte Daten.

| Screen im Canvas | Reihe | Grösse | Umsetzung in diesem Change |
|---|---|---|---|
| Start | Hauptfluss | 390 × 844 | Startbildschirm |
| Live: freies Rudern | Hauptfluss | 390 × 844 | Live-Display ohne Vorlage, hoch |
| Live: Vorlage mit Zonen | Hauptfluss | 390 × 844 | Live-Display mit Vorlage, hoch |
| Zusammenfassung | Hauptfluss | 390 × 844 | Zusammenfassung |
| Zustände: Kraftkurve & Puls | Hauptfluss | 390 × 844 | nur Platzhalter, Inhalt kommt mit `force-curve` und `heart-rate` |
| Live quer: freies Rudern | Querformat am Erg | 844 × 390 | Live-Display ohne Vorlage, quer |
| Live quer: Vorlage mit Zonen | Querformat am Erg | 844 × 390 | Live-Display mit Vorlage, quer |
| Vorlage wählen | Vorlagen und Strecken | 390 × 844 | Tab „Vorlagen“ |
| Vorlagen-Editor | Vorlagen und Strecken | 390 × 844 | Vorlagen-Editor |
| Streckenliste | Vorlagen und Strecken | 390 × 844 | Tab „Strecken“ |
| Strecken-Editor | Vorlagen und Strecken | 390 × 844 | Strecken-Editor |
| Zone einbauen, Zonenliste, Zonen-Editor | Vorlagen, Strecken und Zonen | 390 × 844 | Funktion aus `zones`, Zahlenfelder als Ruderblatt-Tasten (D7) |
| Bedienelement: Ruderblatt-Tasten | Querformat am Erg | 844 × 390 | Widget für Ruderblatt-Tasten (D7) |

Die Kraftkurve, das Herz-Symbol beim Puls und die Ghost-Schiffchen sind in den Live-Screens schon eingezeichnet. Dieser Change baut die Flächen dafür, befüllt sie aber erst, wenn die jeweiligen Changes die Daten liefern. Ohne Daten bleiben sie ausgeblendet.

## Goals / Non-Goals

**Goals:**
- Die Screens entsprechen dem Canvas in Aufbau, Farben, Schriften und Grössenverhältnissen. Pixelgenauigkeit ist nicht das Ziel, die Hierarchie schon: Die Pace ist immer der grösste Wert.
- Alle Live-Screens funktionieren in Hoch- und Querformat ohne Scrollen und ohne Überlauf, auch auf kleinen Handys (360 × 640) und im Laptop-Fenster.
- Der Fortschrittsrahmen ist ein eigenständiges Widget, das sich ohne laufende Session testen lässt.

**Non-Goals:**
- Helles Thema. Die App bleibt vorerst dunkel.
- Animationen über das Nachführen der Spuren hinaus.
- Neue Daten. Alles, was gezeigt wird, liefern `foundation`, `courses`, `zones` und `device-types` bereits.

## Decisions

### D1: Tokens

Farben:

| Token | Wert | Verwendung |
|---|---|---|
| `bg` | `#0E1114` | Hintergrund |
| `surface` | `#161B20` | Karten, Kacheln |
| `line` | `#2A3138` | Rahmen, Trennlinien, freie Abschnitte |
| `track` | `#242B32` | leere Fortschrittsspur |
| `trackInner` | `#1B3550` | leere innere Spur (Abschnitt), leicht blau getönt |
| `text` | `#E8ECEF` | Text, Zahlen |
| `textMuted` | `#9AA4AD` | Beschriftungen |
| `zoneIn` | `#5AB0FF` | in der Zone, Zone mit Band, Primärfarbe (Fokus, Schalter, Auswahl, gefüllter Button; entschieden 2026-10-16) |
| `zoneInSurface` / `zoneInText` | `#0F2438` / `#A9D3FF` | Karte bzw. Text in der Zone |
| `zoneOut` | `#FF9A3D` | ausserhalb der Zone, Fehler, Löschen |
| `zoneOutSurface` / `zoneOutText` | `#33200F` / `#FFC58F` | Karte bzw. Text ausserhalb |
| `ghost` | `#C9B6FF` | Ghost |
| `connected` | `#4CD07D` | Punkt „verbunden“ in der Kopfzeile des Live-Displays (vorläufig) |

Blau und Orange unterscheiden sich auch in der Helligkeit, damit der Zonenstatus bei Rot-Grün-Schwäche lesbar bleibt. Dazu kommen immer Pfeil oder Text (bestehende Spec „Zonenstatus ohne Farbe erkennbar“).

Schriften: Barlow Condensed 700 für alle Messwerte und 500 für Einheiten und Zeiten (entschieden 2026-10-16), IBM Plex Sans 400/500/600 für Text. Beschriftungen über Werten sind 12–13 px, Grossbuchstaben mit Sperrung 0.08 em.

Radien: Karten 14–16 px, Pace-Box 28 px, Buttons 12–16 px. Abstände in Schritten von 4 px, Seitenrand 20 px im Hochformat und 48 px im Querformat, damit Kamera-Notch und Gestenleiste nichts verdecken.

*Alternative*: Schriften über das Paket `google_fonts` laden. Verworfen, weil die App am Erg oft ohne Netz läuft und beim ersten Start sonst mit einer Ersatzschrift erscheint.

### D2: Layout nach Seitenverhältnis

Das Live-Display wählt das Layout nach dem Seitenverhältnis des verfügbaren Platzes, nicht nach der Geräteausrichtung. Breiter als hoch heisst Querformat. Damit funktioniert ein breites Laptop-Fenster wie ein Handy quer.

- **Hoch, frei**: Pace oben, darunter 2 × 2 Kacheln, eine Zeile mit Nebenwerten, die Kraftkurve und unten „Session beenden“.
- **Quer, frei**: links die Pace mit der Kraftkurve darunter, rechts 2 × 2 Kacheln und „Session beenden“.
- **Hoch, Vorlage**: Pace-Box über die volle Breite, darunter Schlagzahl-Karte, vier kleine Kacheln (Rundenzeit, Watt, Puls, Anteil in der Zone), Kraftkurve und „Session beenden“.
- **Quer, Vorlage**: links die Pace-Box fast über die volle Höhe, in der Mitte die Schlagzahl-Karte mit Kraftkurve, rechts eine schmale Spalte mit den vier Kacheln und „Beenden“.

Die Grössen skalieren mit dem Platz. Massgebend ist das Verhältnis aus dem Canvas, nicht der absolute Pixelwert.

Kopfzeile (entschieden 2026-10-16 vom Nutzer): Die App-Leiste des Live-Displays zeigt nur noch den Namen der gerudeten Vorlage, beim freien Rudern vorläufig „Frei rudern“. Die Verbindung steht als kleiner Punkt (12 px) vor dem Namen statt als Text, verbunden ist er grün ausgefüllt (`connected`). Vorläufig gilt für die übrigen Zustände:

- Suchen, Verbinden und Wiederverbinden: Punkt in `zoneOut`, ohne Animation.
- Getrennt: leerer Ring in `textMuted`.
- In allen Zuständen ausser „verbunden“ steht der Zustand zusätzlich als Text unter der App-Leiste (z. B. „Verbindung unterbrochen, verbinde neu …“), damit er wie in der Spec `erg-connection` verlangt auch ohne Farben erkennbar ist. Screenreader lesen den Zustand am Punkt vor, ein langer Druck zeigt ihn als Tooltip.
- Der Name des echten Rudergeräts entfällt. Simulator und Replay bleiben als Badge rechts in der App-Leiste markiert (Spec `erg-simulation`, „Datenquelle erkennbar machen“).
- „Trennen“ bleibt als Symbol-Button rechts in der App-Leiste erreichbar.

### D3: Fortschrittsrahmen

Begriffe wie in `zones`: Eine Strecke besteht aus Abschnitten. Ein Abschnitt ist eine eingebaute Zone oder frei. Im Code heisst ein Abschnitt weiterhin `CourseSegment`.

Der Rahmen der Pace-Box besteht aus drei ineinanderliegenden Spuren in der Form der Box, also Rechtecke mit abgerundeten Ecken:

| Spur | Lage | Farbe | Fortschritt |
|---|---|---|---|
| Strecke | aussen | `text` | Achsenposition über alle Runden / (Streckenlänge × Rundenzahl) |
| Runde | Mitte | `textMuted` | Position in der aktuellen Runde / Streckenlänge |
| Abschnitt | innen | `zoneIn` bzw. `zoneOut` | Position im aktuellen Abschnitt / Abschnittslänge |

- Jede Spur beginnt oben in der Mitte und läuft im Uhrzeigersinn. Die leere Spur ist in `track` sichtbar, die innere leere Spur in `trackInner`.
- Kerben in der Farbe der Box markieren auf der Streckenspur die Rundengrenzen und auf der Rundenspur die Abschnittsgrenzen. Strecken- und Rundenspur haben zusätzlich oben in der Mitte eine Kerbe am Start.
- Die gefüllte Spur endet gerade. An ihrer Spitze sitzt ein Schiffchen in der Farbe der Spur, eine Raute von etwa 22 × 14 px mit 2 px dunklem Rand. Es ist breiter als die Spur (10 px), damit es auf der gefüllten Spur sichtbar bleibt. Das Schiffchen folgt der Laufrichtung und dreht sich in den Ecken mit der Tangente.
- Die Farbe der Abschnittsspur folgt dem Zonenstatus der Pace. In einem freien Abschnitt und in einer Zone ohne Pace-Band ist sie `textMuted`.
- Bei offener Rundenzahl entfällt die Streckenspur, weil die Gesamtlänge unbekannt ist. Die Rundenspur rückt nach aussen.
- Die Position wird als Bogenlänge auf dem Pfad berechnet (`PathMetrics`), damit gleiche Anteile überall gleich lang sind, auch in den Ecken.

Inhalt der Box von oben nach unten: Beschriftung „Pace /500 m“, die Pace, Zonenstatus mit Band (z. B. „In der Zone · 2:05–2:10“), eine Trennlinie und die Legende. Die Legende hat eine Zeile pro Spur mit Farbpunkt, Bezeichnung und Restangabe, z. B. „Gesamt 1 460 / 3 000 m“, „Runde 2 / 3 · noch 540 m“, „Tempo · noch 340 m“ bzw. „frei · noch 340 m“. Bei Zeitstrecken stehen statt Metern Zeiten. Die Runde heisst knapp „Runde 2 / 3“ statt wie bisher „Runde 2 von 3“, bei offener Rundenzahl weiterhin „Runde 2“ (entschieden 2026-10-16). Die Spec `course-rowing` ändert sich entsprechend.

Was die bisherige Streckenleiste `course_bar.dart` zeigt, wandert in die Pace-Box und die Kacheln (Task 3.3):

| `course_bar.dart` | neu |
|---|---|
| Runde („Runde 2 / 3“) | Legende, Zeile der Rundenspur |
| Zonenname bzw. „frei“ (`segment.zoneName`, ohne Namen „Zone“) | Legende, Zeile der Abschnittsspur |
| Rest bis Abschnittsende | Legende, Zeile der Abschnittsspur |
| Pace-Band | Zonenstatus unter der Pace |
| Schlagzahl-Band | Schlagzahl-Karte |
| Anteil in der Zone | Kachel „in der Zone“ |
| Bereich des Abschnitts („200–800 m“) | entfällt, die Abschnittsspur zeigt die Lage |

`ZoneHint` zieht aus `course_bar.dart` in eine eigene Datei, die Datei selbst entfällt.

Berechnung: Eine reine Funktion bildet aus `LapProgress` und der Streckendefinition ein Modell mit den Anteilen der Spuren (0–1), den Grenzen als Anteile (Rundengrenzen auf der Streckenspur, Abschnittsgrenzen auf der Rundenspur) und den Restangaben als Zahlen in der Einheit der Strecke. Die Position in der Runde ist das Abschnittsende minus der Rest. Bei offener Rundenzahl fehlt die Streckenspur im Modell. Formatieren und Übersetzen macht das Widget, damit das Modell ohne `BuildContext` testbar bleibt.

Platz für den Ghost: Der Change `ghost` setzt auf jede Spur ein zweites, kleineres Schiffchen in `ghost` (etwa 18 × 7 px) und eine vierte Zeile in der Legende. Liegen beide Schiffchen übereinander, liegt das des Ghosts oben. Das Widget nimmt dafür optionale Ghost-Positionen pro Spur entgegen.

*Alternative*: drei konzentrische Kreise um die Pace. Im Canvas ausprobiert und verworfen. Die Pace wird im Kreis kleiner, und die Restangaben finden keinen Platz.

### D4: Ablaufbalken

Der bestehende `CourseStrip` aus `zones` (`lib/features/courses/course_strip.dart`) wird ausgebaut, statt ein zweites Widget `SegmentBar` zu bauen. Er zeigt die Abschnitte einer Strecke als Balken. Breite heisst Länge, Grau heisst frei, Blau heisst mit Band. Haben mehrere Zonen ein Pace-Band, werden schnellere Bänder heller dargestellt. Die Abstufung reicht von `#2F5577` (langsamstes Band) bis `#A9D3FF` (schnellstes) und folgt der Mitte des Bands proportional zum Tempo (entschieden 2026-10-16). Verschiedene Bänder liegen mindestens 15 % der Spanne auseinander, damit ähnlich schnelle Zonen unterscheidbar bleiben. In freien Lücken steht kein Text. Haben die Zonen nur ein Schlagzahl-Band, sind sie einheitlich `zoneIn`. Höhe: 8–10 px in Listen, 28 px mit Zonennamen im Strecken-Editor. Die gewählte Zone hat einen Umriss in `text`. Die Abschnitte mit Band sind die eingebauten Zonen, die grauen (`line`) die freien Lücken. Die bestehenden Aufrufe in Streckenliste und Strecken-Editor bleiben und bekommen die neue Darstellung.

### D5: Segmentlänge ändern (entfällt)

Die manuelle Segmentlänge ersetzt der Change `zones`: Strecken bestehen dort aus eingebauten Zonen mit fester Länge und freien Lücken. Die Nummer D5 bleibt frei, damit Verweise stabil bleiben.

### D6: Navigation

- Geräte zuerst (entschieden 2026-10-16 vom Nutzer): Die App beginnt mit dem Screen „Geräte wählen“. Dort wählt der Nutzer das Rudergerät, also ein PM5 oder FTMS-Rudergerät aus der Geräteliste von `device-types` oder „Simulator“ bzw. „Simulator (FTMS)“, und optional den Pulsgurt (sobald `heart-rate` umgesetzt ist; bis dahin fehlt der Bereich). „Weiter“ führt zum Startbildschirm, erst wenn ein Rudergerät gewählt ist. Die gewählten Geräte gelten für „Rudern“, „Frei rudern“ und „Nochmal“. Der Quellen-Dialog beim Start einer Vorlage (heute in `templates_screen.dart`) entfällt. *Alternative*: Quelle oben auf dem Startbildschirm oder als Dialog beim Start. Verworfen, weil am Erg zuerst die Geräte stehen müssen und die Wahl danach gleich bleibt.
  - Überspringen (entschieden 2026-10-16 vom Nutzer): Die App merkt sich das zuletzt gewählte Rudergerät. Beim nächsten Start sucht sie es; wird es gefunden, verbindet sie und zeigt direkt den Startbildschirm. Wird es nicht gefunden (vorläufig: nach 10 s), erscheint „Geräte wählen“ mit diesem Gerät vorausgewählt. Vorläufig: War es ein Simulator, geht es ohne Suche direkt zum Startbildschirm. Über die Gerätezeile kommt der Nutzer jederzeit zurück zu „Geräte wählen“.
- Startbildschirm (entschieden 2026-10-16, Mittelweg statt Canvas): oben eine kompakte Zeile mit dem gewählten Rudergerät (und Pulsgurt), Antippen führt zurück zu „Geräte wählen“; darunter „Rudern“ und „Frei rudern“, dann die Kachel „Nochmal“ und der Link „Sessions“.
  - „Rudern“ öffnet „Vorlage wählen“. „Frei rudern“ startet direkt.
  - „Nochmal“ zeigt die Vorlage der jüngsten Session, deren Vorlage noch existiert, mit Name und Datum der Session („gestern“). Antippen öffnet „Vorlage wählen“ mit dieser Vorlage vorausgewählt. Gibt es keine solche Session, fehlt die Kachel.
  - Keine Kacheln für alle Vorlagen und keine Liste der letzten Sessions: Der Bildschirm bleibt ruhig, und der häufigste Fall, dieselbe Vorlage noch einmal zu rudern, braucht trotzdem nur zwei Tipps.
  - *Alternativen:* wie im Canvas (alle Vorlagen als Kacheln, letzte Sessions) oder ganz schlank (nur Quelle, „Rudern“, „Frei rudern“). Verworfen, weil der Canvas am Erg zu voll ist und die schlanke Variante für die Lieblingsvorlage einen Schritt mehr braucht.
- „Vorlage wählen“ klappt die gewählte Vorlage auf, mit Bändern, Ghost-Bestzeit (sobald `ghost` da ist) und „Starten“. Der Stift öffnet den Vorlagen-Editor.
- Die drei Tabs „Vorlagen“, „Strecken“ und „Zonen“ bestehen seit `zones` (`templates_screen.dart`). Dieser Change gestaltet sie nur neu, Aufbau und Navigation bleiben. Eine Strecke öffnet den Strecken-Editor, eine Zone den Zonen-Editor.

### D7: Ruderblatt-Tasten für Zahlen

Zahlen werden in allen Editoren mit einem Tastenpaar eingestellt, nicht getippt (entschieden 2026-10-16, Board „Bedienelement: Ruderblatt-Tasten“ im Canvas).

- **Form**: ein eckiges, schmales Ruderblatt mit gerader Kante an der Spitze und abgeschrägten Kanten zum Hals. Ein heller Pfeil in `text` bildet zugleich die kurze Stange, seine Spitze reicht an die Blattkante, die Schenkel bis an die Seiten, so dass er wie das Muster des Blatts wirkt. Blatt `line` mit Rand `#4A545E`. „Mehr“ zeigt nach oben, „weniger“ ist um 180° gedreht.
- **Grössen**: gross 56 × 60 px für einzelne Werte in voller Breite (Runden, Startposition einer Zone), kompakt 44 × 47 px in Feldern nebeneinander (Länge, Pace- und Schlagzahl-Band). Der Wert steht zwischen den Tasten, die Einheit darunter bzw. daneben.
- **Zustände**: bereit; gedrückt mit Blatt `#1D3A55`, Rand und Pfeil in `zoneIn`; gesperrt am Minimum oder Maximum mit 35 % Deckkraft.
- **Schritte**: Pace 5 s, Schlagzahl 1 spm, Runden 1, Streckenlänge 100 m, Zonenlänge 10 m, Startposition einer Zone 50 m. Auf der Zeitachse (entschieden 2026-10-16): Streckenlänge 30 s, Zonenlänge und Startposition 10 s.
- **Gedrückt halten** wiederholt den Schritt, nach etwa einer Sekunde schneller, damit auch 10 000 m schnell erreicht sind.
- Die Grenzen kommen aus der bestehenden Validierung der Felder. Eine Taste, deren Schritt die Grenze überschreiten würde, ist gesperrt.
- Blau bleibt für „in der Zone“ reserviert. Darum sind beide Richtungen gleich gefärbt und unterscheiden sich nur durch die Richtung.

*Alternativen*: Textfelder mit Zahlentastatur wie bisher, oder ein Rad zum Drehen. Verworfen: Die Tastatur verdeckt am Handy den halben Editor, und ein Rad ist mit nassen Fingern ungenau.

### D8: Sprachwahl

Entschieden am 2026-10-16 vom Nutzer: Die Sprachwahl aus `translations` (dort Design D3) bleibt ein Symbol in der App-Leiste und öffnet wie heute den Dialog mit den Sprachen. Das Symbol steht auf dem Startbildschirm und auf „Geräte wählen“, damit sich die Sprache schon beim ersten Start wählen lässt, bevor ein Rudergerät gewählt ist. Beide Screens nutzen dasselbe Widget. Das Symbol bekommt nur die Gestaltung aus D1 (Symbol in `textMuted`, Touch-Ziel ab 44 px). Der Canvas zeigt keinen Platz dafür.

*Alternativen*: ein eigener Einstellungs-Screen oder ein Eintrag unter dem Link „Sessions“. Verworfen, solange die Sprache die einzige Einstellung ist. Kommen weitere Einstellungen dazu, etwa der Brustgurt aus `heart-rate`, kann die Sprachwahl in einen Einstellungs-Screen umziehen; der Pulsgurt sitzt aber in „Geräte wählen“ (D6).

### D9: Texte

Neue und geänderte Texte stehen nur in `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb`, jeder mit `@`-Beschreibung. `make l10n` erzeugt den Code, der eingecheckt wird. Bestehende Schlüssel werden weiterverwendet, wo der Text gleich bleibt. Fest im Code bleiben nur Einheiten, Formate und Eigennamen wie in `translations`.

## Risks / Trade-offs

- **Platz im Hochformat mit Vorlage**: Pace-Box, Schlagzahl, Kacheln und Kraftkurve sind auf 390 × 844 knapp. Auf kleineren Geräten fällt zuerst die Kraftkurve weg, danach werden die Kacheln einzeilig. Die bestehenden Layout-Tests in allen vier Grössen sichern das ab.
- **Schiffchen überlappen**: Liegen eigener Wert und Ghost sehr nah beieinander, verdeckt ein Schiffchen das andere teilweise. Vorerst liegt der Ghost oben. Erweist sich das am Erg als unlesbar, wird der Ghost nach aussen versetzt.
- **Schriften als Assets** vergrössern die App um etwa 800 kB. Ihre Lizenzen (OFL) stehen auf der Lizenzseite der App.

## Open Questions


- ~~Puls-Herkunft~~ (F1, entschieden 2026-10-16 vom Nutzer): Der Pulsgurt wird in „Geräte wählen“ gewählt (D6). Der Puls kommt vom gewählten BLE-Gurt, wenn er gefunden ist und Werte liefert, sonst vom Rudergerät (PM5), wenn es Puls liefert, sonst wird kein Puls angezeigt (Vorrangregel aus `heart-rate`). Das Live-Display zeigt die Herkunft nicht an; der Zustand „Über PM5“ aus dem Canvas entfällt.
