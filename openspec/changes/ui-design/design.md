# Design

## Context

Das Verhalten steht in den Specs, die Motivation in `proposal.md`. Die visuelle Vorlage ist der Claude-Design-Canvas **Stroke & Split Frontend**.

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

Werte im Live-Display (entschieden 2026-10-18 vom Nutzer): Pace, Schlagzahl und die Kacheln (Zeit, Distanz, Runde, Watt, Puls) sowie die Werte beim freien Rudern stehen in Barlow 700, Einheiten in 500 (Token `AppFonts.liveValue`). Die Werte füllen meist die Breite ihrer Karte; Barlow ist bei gleicher Breite rund 12 % niedriger als Barlow Condensed („0:00.0“ bei 100 px: 281 statt 249 px breit), so bleibt Höhe für Pace-Box und Kraftkurve. Zusammenfassung, Statistik, Editoren und Titel bleiben bei Barlow Condensed.

*Alternative*: Barlow Semi Condensed. Verworfen, weil sie nur rund 6 % breiter ist als Barlow Condensed (265 px) und im Screenshot kaum niedriger wirkt. IBM Plex Sans wäre noch breiter (302 px), verliert aber den Zusammenhang mit den Zahlen der übrigen Screens.

Radien: Karten 14–16 px, Pace-Box 28 px, Buttons 12–16 px. Abstände in Schritten von 4 px, Seitenrand 20 px im Hochformat und 48 px im Querformat, damit Kamera-Notch und Gestenleiste nichts verdecken.

*Alternative*: Schriften über das Paket `google_fonts` laden. Verworfen, weil die App am Erg oft ohne Netz läuft und beim ersten Start sonst mit einer Ersatzschrift erscheint.

### D2: Layout nach Seitenverhältnis

Das Live-Display wählt das Layout nach dem Seitenverhältnis des verfügbaren Platzes, nicht nach der Geräteausrichtung. Breiter als hoch heisst Querformat. Damit funktioniert ein breites Laptop-Fenster wie ein Handy quer.

- **Hoch, frei**: Pace oben, darunter 2 × 2 Kacheln, eine Zeile mit Nebenwerten, die Kraftkurve und unten „Session beenden“. Die Pace nimmt höchstens 22 % der Höhe und nicht mehr, als sie bei der Breite braucht; der Rest geht an die Kacheln.
- **Quer, frei**: links die Pace mit der Kraftkurve darunter, rechts 2 × 2 Kacheln und „Session beenden“.
- **Hoch, Vorlage**: Pace-Box über die volle Breite, darunter Schlagzahl-Karte, zwei Reihen kleiner Kacheln, oben die Session (Zeit, Distanz und, wenn das Rudergerät sie liefert, Kalorien), darunter die Runde (Rundenzeit, Watt, Puls; die Kachel „in der Zone“ entfiel nach dem Gerätetest, der Anteil steht in der Zusammenfassung), Kraftkurve und „Session beenden“. Fünf Kacheln nebeneinander wären auf einem 360 px breiten Handy zu schmal für „1 520 m“; die Kraftkurve weicht dafür auf kleinen Handys zuerst, sobald die Pace-Box mit ihr unter 336 px Höhe fiele. Masse mit Barlow (2026-10-18): Schlagzahl-Karte 80 px (vorher 88), Kacheln 64 px (vorher 76), Kraftkurve 72 px, Abstand 10 px; Werte der Kacheln höchstens 42 px (vorher 48), Schlagzahl höchstens 64 px (vorher 80). Damit hat die Kraftkurve ab 718 px Innenhöhe Platz (vorher 806), also auch auf 360 × 740, und auf 390 × 844 ist die Pace-Box mit Kraftkurve 444 statt 412 px hoch.
- **Quer, Vorlage**: links die Pace-Box fast über die volle Höhe, in der Mitte die Schlagzahl-Karte mit Kraftkurve und darunter Zeit, Distanz und Kalorien der Session nebeneinander, rechts eine schmale Spalte mit den drei Kacheln der Runde und „Beenden“. Fünf Kacheln passen auf einem Handy quer nicht in die Seitenspalte.

Die Grössen skalieren mit dem Platz. Massgebend ist das Verhältnis aus dem Canvas, nicht der absolute Pixelwert.

Kopfzeile (entschieden 2026-10-16 vom Nutzer): Die App-Leiste des Live-Displays zeigt nur noch den Namen der gerudeten Vorlage, beim freien Rudern vorläufig „Frei rudern“. Die Verbindung steht als kleiner Punkt (12 px) vor dem Namen statt als Text, verbunden ist er grün ausgefüllt (`connected`). Vorläufig gilt für die übrigen Zustände:

- Suchen, Verbinden und Wiederverbinden: Punkt in `zoneOut`, ohne Animation.
- Getrennt: leerer Ring in `textMuted`.
- In allen Zuständen ausser „verbunden“ steht der Zustand zusätzlich als Text unter der App-Leiste (z. B. „Verbindung unterbrochen, verbinde neu …“), damit er wie in der Spec `erg-connection` verlangt auch ohne Farben erkennbar ist. Screenreader lesen den Zustand am Punkt vor, ein langer Druck zeigt ihn als Tooltip.
- Der Name des echten Rudergeräts entfällt. Simulator und Replay bleiben als Badge rechts in der App-Leiste markiert (Spec `erg-simulation`, „Datenquelle erkennbar machen“).
- ~~„Trennen“ bleibt als Symbol-Button rechts in der App-Leiste erreichbar.~~ Entfällt (entschieden 2026-10-18 vom Nutzer): Das Live-Display hat kein Trennen-Symbol mehr. Zurück (Android-Geste bzw. Zurück-Taste) und auf dem Desktop Esc führen zum Startbildschirm, ebenso „Fertig“ in der Zusammenfassung; die Verbindung bleibt dabei bestehen. Läuft eine Session, endet sie beim Zurück wie mit „Session beenden“, aber ohne Zusammenfassung; eine bereite Vorlagen-Session (`start-on-first-stroke`) wird verworfen. Ein Replay ist keine Verbindung: Zurück beendet es und führt zur Sessionliste, „Fertig“ beendet es und führt zum Startbildschirm. Getrennt wird auf dem Startbildschirm (D6).

### D3: Fortschrittsrahmen

Begriffe wie in `zones`: Eine Strecke besteht aus Abschnitten. Ein Abschnitt ist eine eingebaute Zone oder frei. Im Code heisst ein Abschnitt weiterhin `CourseSegment`.

Der Rahmen der Pace-Box besteht aus drei ineinanderliegenden Spuren in der Form der Box, also Rechtecke mit abgerundeten Ecken:

| Spur | Lage | Farbe | Fortschritt |
|---|---|---|---|
| Strecke | aussen | `text` | Achsenposition über alle Runden / (Streckenlänge × Rundenzahl) |
| Runde | Mitte | `textMuted` | Position in der aktuellen Runde / Streckenlänge |
| Abschnitt | innen | `zoneIn` bzw. `zoneOut` | Position im aktuellen Abschnitt / Abschnittslänge |

- Jede Spur beginnt oben in der Mitte und läuft im Uhrzeigersinn. Die leere Spur ist in `track` sichtbar, die innere leere Spur in `trackInner`.
- Kerben in der Farbe der Box markieren auf der Streckenspur die Rundengrenzen und auf der Rundenspur die Abschnittsgrenzen. Auf der Rundenspur heben sich die Zonen heller ab als die freien Abschnitte: leer in `trackZone`, gefüllt in `text` statt `textMuted` (Nutzer nach dem Gerätetest, 2026-10-17). Strecken- und Rundenspur haben zusätzlich oben in der Mitte eine Kerbe am Start. Das Ende einer Runde markiert eine helle Linie (`text`, 3 px, in einer Kerbe der Boxfarbe) quer über die Spur: auf der Rundenspur oben in der Mitte, auf der Streckenspur am Start und an jeder Rundengrenze (Nutzer nach dem Gerätetest, 2026-10-17).
- Die gefüllte Spur endet gerade. An ihrer Spitze sitzt ein Schiffchen in der Farbe der Spur, eine Raute von etwa 22 × 14 px mit 2 px dunklem Rand. Es ist breiter als die Spur (10 px), damit es auf der gefüllten Spur sichtbar bleibt. Das Schiffchen folgt der Laufrichtung und dreht sich in den Ecken mit der Tangente.
- Die Farbe der Abschnittsspur folgt dem Zonenstatus der Pace. In einem freien Abschnitt und in einer Zone ohne Pace-Band ist sie `textMuted`.
- Bei offener Rundenzahl entfällt die Streckenspur, weil die Gesamtlänge unbekannt ist. Die Rundenspur rückt nach aussen.
- Die Position wird als Bogenlänge auf dem Pfad berechnet (`PathMetrics`), damit gleiche Anteile überall gleich lang sind, auch in den Ecken.

Inhalt der Box von oben nach unten: Beschriftung „Pace /500 m“, die Pace, Zonenstatus mit Band (z. B. „In der Zone · 2:05–2:10“), eine Trennlinie und die Legende. Die Legende hat eine Zeile pro Spur mit Farbpunkt, Bezeichnung und Restangabe, z. B. „Gesamt 1 460 / 3 000 m“, „Runde 2 / 3 · noch 540 m“, „Tempo · noch 340 m“ bzw. „frei · noch 340 m“. Bei Zeitstrecken stehen statt Metern Zeiten. Die Runde heisst knapp „Runde 2 / 3“ statt wie bisher „Runde 2 von 3“, bei offener Rundenzahl weiterhin „Runde 2“ (entschieden 2026-10-16). Die Spec `course-rowing` ändert sich entsprechend.

Ø Pace in der Box (entschieden 2026-10-19 vom Nutzer): Die erste Zeile der Legende, ohne Markierung, weil sie zu keiner Spur gehört, zeigt die Ø Pace der ganzen Session aus Zeit und Distanz wie beim freien Rudern, z. B. „Ø Pace 2:05“, vor dem ersten Meter „–:––“. Als vierte Kachel neben Zeit, Distanz und Kalorien wären die Werte auf einem 360 px breiten Handy zu klein geworden (unter 30 px hoch, quer unter 16 px).

Was die bisherige Streckenleiste `course_bar.dart` zeigt, wandert in die Pace-Box und die Kacheln (Task 3.3):

| `course_bar.dart` | neu |
|---|---|
| Runde („Runde 2 / 3“) | Legende, Zeile der Rundenspur |
| Zonenname bzw. „frei“ (`segment.zoneName`, ohne Namen „Zone“) | Legende, Zeile der Abschnittsspur |
| Rest bis Abschnittsende | Legende, Zeile der Abschnittsspur |
| Pace-Band | Zonenstatus unter der Pace |
| Schlagzahl-Band | Schlagzahl-Karte |
| Anteil in der Zone | entfällt im Live-Display (Nutzer, 2026-10-17), nur in der Zusammenfassung |
| Bereich des Abschnitts („200–800 m“) | entfällt, die Abschnittsspur zeigt die Lage |

`ZoneHint` zieht aus `course_bar.dart` in eine eigene Datei, die Datei selbst entfällt.

Schlagzahl-Karte (entschieden 2026-10-17 nach dem Test am Gerät): Die Karte zeigt unter „Schlagzahl“ den Zonenstatus der Schlagzahl. In der Zone bleibt er dezent, eine Zeile in der Farbe der Karte, z. B. „✓ In der Zone · 20–22 spm“. Ausserhalb des Bands steht eine Anweisung als Pille wie in der Pace-Box: Pfeil nach oben und „Mehr Schläge“ bzw. Pfeil nach unten und „Weniger Schläge“, ohne Schläge „Keine Schläge“. Weil die Karte dann schon in `zoneOutSurface` getönt ist, ist die Pille voll in `zoneOut` mit dunkler Schrift (`bg`). Sie steht auf einer eigenen Zeile unter der Beschriftung, in der Schrift der Pace-Pille (16 px), und wird nie abgeschnitten: im Hochformat schrumpft sie notfalls, im schmalen Querformat bricht sie auf zwei Zeilen um. Das Band steht im Hochformat als eigene Zeile unter der Pille, im Querformat wie bisher neben dem Wert, z. B. „24 20–22 spm“. In einem freien Abschnitt und in einer Zone ohne Schlagzahl-Band zeigt die Karte keinen Status. Pace-Box und Karte nutzen dasselbe Widget für die Pille.

Pace-Box in der Zonenfarbe (entschieden 2026-10-19 vom Nutzer): Wie die Schlagzahl-Karte ist die ganze Pace-Box getönt, sobald der Abschnitt ein Pace-Band hat, im Band in `zoneInSurface`, ausserhalb in `zoneOutSurface`. Die Beschriftung „Pace“ steht dann in `zoneInText` bzw. `zoneOutText`, die Pille ist voll in `zoneIn` bzw. `zoneOut` mit dunkler Schrift, damit sie sich von der getönten Box abhebt. Die Kerben der Spuren und der Rand der Schiffchen nehmen die Farbe der Box an. In einem freien Abschnitt und in einer Zone ohne Pace-Band bleibt die Box in `surface` wie bisher.

Grenzen des Pace-Bands (entschieden 2026-10-26 nach dem Test am Gerät): Der Zonenstatus vergleicht die Pace gerundet auf ganze Sekunden, so wie sie angezeigt wird. Vorher galt bei einem Band von 2:45–2:50 eine angezeigte „2:45“ (tatsächlich 2:44,6) bzw. „2:50“ (2:50,4) als ausserhalb. Das gilt auch für den Anteil in der Zone.

Nächste Zone ankündigen (entschieden 2026-10-26 vom Nutzer): 10 s bevor eine Zone beginnt, blinken ihre Bänder als gelbe Pille (`upcoming`, dunkle Schrift) an Stelle des Zonenstatus: das Pace-Band unter der Pace, z. B. „» Gleich 1:55–2:00“, das Schlagzahl-Band auf der Karte, z. B. „» Gleich 26–30 spm“. Hat die nächste Zone nur eines der Bänder, bleibt am anderen Wert der Status. Bei Distanzstrecken ergibt sich die Zeit aus dem Rest und der aktuellen Pace, ohne Pace kündigt nichts an; bei Zeitstrecken ist es der Rest. Angekündigt wird auch die erste Zone der nächsten Runde, nicht aber ein freier Abschnitt oder eine Zone mit denselben Bändern. Die Pille wird zum Blinken gedimmt statt ausgeblendet, damit sie jederzeit lesbar ist, und bleibt ruhig, wenn das System weniger Bewegung verlangt.

Widerstandsstufe (entschieden 2026-11-05 vom Nutzer): Meldet ein FTMS-Rudergerät seine Widerstandsstufe, z. B. der Domyos Woodrower mit 15 Stufen, steht sie klein unter dem Watt-Wert („Stufe 7“), wie das RR-Intervall unter dem Puls. Eine eigene Kachel wäre auf dem Handy zu klein geworden. Die App zeigt den gemeldeten Wert unverändert, 0 und fehlende Werte zeigen nichts; der PM5 meldet keine Stufe. Den Widerstand verstellt die App nicht.

Vorher stand die Anweisung in 13 px in derselben Zeile wie die Beschriftung bzw. hinter ihr und wurde abgeschnitten, im Querformat z. B. zu „Weniger S…“, im kleinen Fenster zu „Me…“, im Hochformat fehlte das Ende des Bands. Am Gerät war sie deshalb nicht zu lesen.

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
  - Verbindung halten (entschieden 2026-10-18 vom Nutzer): Nach dem Rudern bleibt das Rudergerät bzw. der Simulator verbunden, bis der Nutzer trennt, ein anderes Gerät wählt oder die App beendet. Solange die Verbindung besteht, zeigt die Gerätezeile den Gerätenamen und darunter den Zustand („Verbunden“ in `connected`, beim Wiederverbinden „Verbindung unterbrochen, verbinde neu …“ in `zoneOut`) sowie vor dem Pfeil den Button „Trennen“ mit Symbol `link_off` (Touch-Ziel ab 48 px). „Trennen“ beendet die Verbindung, danach zeigt die Zeile wieder „Verbindet beim Start“ bzw. den Hinweis zum Simulator. „Rudern“, „Frei rudern“ und „Nochmal“ nutzen eine bestehende Verbindung, ohne neu zu verbinden; ohne Verbindung verbinden sie wie bisher. Wird in „Geräte wählen“ ein anderes Gerät gewählt, trennt „Weiter“ zuerst das bisherige. Nach einem Neustart der App ist nichts verbunden, es gilt das Überspringen von oben. *Alternative*: Trennen weiter im Live-Display. Verworfen, weil das Symbol dort Platz neben dem Session-Button braucht und ein versehentliches Antippen während des Ruderns die Verbindung beendet.
  - „Sessions“ (entschieden 2026-10-18 vom Nutzer): ein Button über die volle Breite mit Symbol `history`, als `OutlinedButton` unter der Kachel „Nochmal“, statt eines Links. „Rudern“ bleibt primär (gefüllt), „Frei rudern“ und „Sessions“ sind sekundär (umrandet), „Sessions“ etwas niedriger als „Frei rudern“ (48 statt 52 px).
  - „Rudern“ öffnet „Vorlage wählen“. „Frei rudern“ startet direkt.
  - „Nochmal“ zeigt die Vorlage der jüngsten Session, deren Vorlage noch existiert, mit Name und Datum der Session („gestern“). Antippen öffnet „Vorlage wählen“ mit dieser Vorlage vorausgewählt. Gibt es keine solche Session, fehlt die Kachel.
    *Abgelöst (2026-11-06)*: Change `template-screen` entfernt die Kachel „Nochmal“ (dort D3).
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
- **Pace-Band mit 10 s Abstand** (entschieden 2026-10-17): Eine neue Zone beginnt mit einem Pace-Band, dessen Grenzen 10 s auseinanderliegen (2:45–2:55). Die schnellste Pace verschiebt das ganze Band: Die langsamste wandert mit, der Abstand bleibt, wie er ist. Die langsamste Pace ändert nur sich selbst und damit den Abstand. „Mehr“ an der schnellsten Pace ist gesperrt, sobald die langsamste 5:00 erreichen würde; die Grenzen 1:00 und 5:00 und „schnellste nicht langsamer als langsamste“ gelten weiter. Das Schlagzahl-Band bleibt unverändert, dort stellt jede Grenze nur sich selbst ein.
- **Gedrückt halten** wiederholt den Schritt, nach etwa einer Sekunde schneller, damit auch 10 000 m schnell erreicht sind.
- Die Grenzen kommen aus der bestehenden Validierung der Felder. Eine Taste, deren Schritt die Grenze überschreiten würde, ist gesperrt.
- Blau bleibt für „in der Zone“ reserviert. Darum sind beide Richtungen gleich gefärbt und unterscheiden sich nur durch die Richtung.

*Alternativen*: Textfelder mit Zahlentastatur wie bisher, oder ein Rad zum Drehen. Verworfen: Die Tastatur verdeckt am Handy den halben Editor, und ein Rad ist mit nassen Fingern ungenau.

*Alternativen zum Pace-Band*: Einen festen Abstand von 10 s erzwingen, oder die langsamste Pace an der Obergrenze stehen lassen und den Abstand verkleinern. Verworfen: Ein fester Abstand verhindert engere oder weitere Bänder, und ein Abstand, der sich am Rand still verkleinert, überrascht beim Zurückschieben.

### D8: Sprachwahl

Entschieden am 2026-10-16 vom Nutzer: Die Sprachwahl aus `translations` (dort Design D3) bleibt ein Symbol in der App-Leiste und öffnet wie heute den Dialog mit den Sprachen. Das Symbol steht auf dem Startbildschirm und auf „Geräte wählen“, damit sich die Sprache schon beim ersten Start wählen lässt, bevor ein Rudergerät gewählt ist. Beide Screens nutzen dasselbe Widget. Das Symbol bekommt nur die Gestaltung aus D1 (Symbol in `textMuted`, Touch-Ziel ab 44 px). Der Canvas zeigt keinen Platz dafür.

*Alternativen*: ein eigener Einstellungs-Screen oder ein Eintrag unter dem Link „Sessions“. Verworfen, solange die Sprache die einzige Einstellung ist. Kommen weitere Einstellungen dazu, etwa der Brustgurt aus `heart-rate`, kann die Sprachwahl in einen Einstellungs-Screen umziehen; der Pulsgurt sitzt aber in „Geräte wählen“ (D6).

### D9: Texte

Neue und geänderte Texte stehen nur in `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb`, jeder mit `@`-Beschreibung. `make l10n` erzeugt den Code, der eingecheckt wird. Bestehende Schlüssel werden weiterverwendet, wo der Text gleich bleibt. Fest im Code bleiben nur Einheiten, Formate und Eigennamen wie in `translations`.

### D10: Pace und Puls in der Zusammenfassung

Pace (entschieden 2026-10-19 vom Nutzer): Unter den Durchschnitten steht ein Abschnitt „Pace /500 m“ mit der schnellsten, der durchschnittlichen und der langsamsten Pace und darunter ihrem Verlauf über die Session als Kurve wie bei den RR-Intervallen, schneller oben, der Durchschnitt als gestrichelte Linie. Die Kurve besteht aus Schritten gleicher geruderter Zeit, mindestens 10 s, höchstens rund 60 pro Session; jeder Schritt rechnet seine Pace aus der in ihm geruderten Distanz. So zählen Pausen nicht (die geruderte Zeit steht dann still), einzelne Schläge schlagen nicht aus, und die Schritte passen zur Ø Pace aus Zeit und Distanz. Schnellste und langsamste Pace sind die eines Schritts, nicht eines einzelnen Schlags. Ein letzter Schritt unter einem halben fällt weg. Ohne gespeicherte Samples (Import) fehlt der Abschnitt. Berechnet wird beim Anzeigen, ohne neue Spalte, damit auch ältere Sessions die Kurve zeigen.

Puls (entschieden 2026-10-19 vom Nutzer): Neben Ø und Max. Puls steht der niedrigste Puls, ebenfalls beim Anzeigen aus den Samples gelesen; 0 (Kontakt verloren) zählt nicht.

## Risks / Trade-offs

- **Platz im Hochformat mit Vorlage**: Pace-Box, Schlagzahl, Kacheln und Kraftkurve sind auf 360 × 740 knapp; dort ist die Pace-Box mit Kraftkurve 340 px hoch und ihr Inhalt schrumpft leicht. Auf kleineren Geräten fällt zuerst die Kraftkurve weg, danach werden die Kacheln einzeilig. Die bestehenden Layout-Tests in allen vier Grössen sichern das ab.
- **Schiffchen überlappen**: Liegen eigener Wert und Ghost sehr nah beieinander, verdeckt ein Schiffchen das andere teilweise. Vorerst liegt der Ghost oben. Erweist sich das am Erg als unlesbar, wird der Ghost nach aussen versetzt.
- **Schriften als Assets** vergrössern die App um etwa 1 MB (Barlow für das Live-Display kam mit rund 210 kB dazu). Ihre Lizenzen (OFL) stehen auf der Lizenzseite der App.

## Open Questions


- ~~Puls-Herkunft~~ (F1, entschieden 2026-10-16 vom Nutzer): Der Pulsgurt wird in „Geräte wählen“ gewählt (D6). Der Puls kommt vom gewählten BLE-Gurt, wenn er gefunden ist und Werte liefert, sonst vom Rudergerät (PM5), wenn es Puls liefert, sonst wird kein Puls angezeigt (Vorrangregel aus `heart-rate`). Das Live-Display zeigt die Herkunft nicht an; der Zustand „Über PM5“ aus dem Canvas entfällt.
