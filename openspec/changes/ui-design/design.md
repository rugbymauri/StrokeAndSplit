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
| Zone einbauen, Zonenliste, Zonen-Editor | Vorlagen, Strecken und Zonen | 390 × 844 | gehören zum Change `zones` |

Die Kraftkurve, das Herz-Symbol beim Puls und die Ghost-Schiffchen sind in den Live-Screens schon eingezeichnet. Dieser Change baut die Flächen dafür, befüllt sie aber erst, wenn die jeweiligen Changes die Daten liefern. Ohne Daten bleiben sie ausgeblendet.

## Goals / Non-Goals

**Goals:**
- Die Screens entsprechen dem Canvas in Aufbau, Farben, Schriften und Grössenverhältnissen. Pixelgenauigkeit ist nicht das Ziel, die Hierarchie schon: Die Pace ist immer der grösste Wert.
- Alle Live-Screens funktionieren in Hoch- und Querformat ohne Scrollen und ohne Überlauf, auch auf kleinen Handys (360 × 640) und im Laptop-Fenster.
- Der Fortschrittsrahmen ist ein eigenständiges Widget, das sich ohne laufende Session testen lässt.

**Non-Goals:**
- Helles Thema. Die App bleibt vorerst dunkel.
- Animationen über das Nachführen der Spuren hinaus.
- Neue Daten. Alles, was gezeigt wird, liefern `foundation` und `courses` bereits.

## Decisions

### D1: Tokens

Farben:

| Token | Wert | Verwendung |
|---|---|---|
| `bg` | `#0E1114` | Hintergrund |
| `surface` | `#161B20` | Karten, Kacheln |
| `line` | `#2A3138` | Rahmen, Trennlinien, freie Segmente |
| `track` | `#242B32` | leere Fortschrittsspur |
| `text` | `#E8ECEF` | Text, Zahlen, primärer Button |
| `textMuted` | `#9AA4AD` | Beschriftungen |
| `zoneIn` | `#5AB0FF` | in der Zone, Segment mit Band |
| `zoneInSurface` / `zoneInText` | `#0F2438` / `#A9D3FF` | Karte bzw. Text in der Zone |
| `zoneOut` | `#FF9A3D` | ausserhalb der Zone, Fehler, Löschen |
| `zoneOutSurface` / `zoneOutText` | `#33200F` / `#FFC58F` | Karte bzw. Text ausserhalb |
| `ghost` | `#C9B6FF` | Ghost |

Blau und Orange unterscheiden sich auch in der Helligkeit, damit der Zonenstatus bei Rot-Grün-Schwäche lesbar bleibt. Dazu kommen immer Pfeil oder Text (bestehende Spec „Zonenstatus ohne Farbe erkennbar“).

Schriften: Barlow Condensed 700 für alle Messwerte, IBM Plex Sans 400/500/600 für Text. Beschriftungen über Werten sind 12–13 px, Grossbuchstaben mit Sperrung 0.08 em.

Radien: Karten 14–16 px, Pace-Box 28 px, Buttons 12–16 px. Abstände in Schritten von 4 px, Seitenrand 20 px im Hochformat und 48 px im Querformat, damit Kamera-Notch und Gestenleiste nichts verdecken.

*Alternative*: Schriften über das Paket `google_fonts` laden. Verworfen, weil die App am Erg oft ohne Netz läuft und beim ersten Start sonst mit einer Ersatzschrift erscheint.

### D2: Layout nach Seitenverhältnis

Das Live-Display wählt das Layout nach dem Seitenverhältnis des verfügbaren Platzes, nicht nach der Geräteausrichtung. Breiter als hoch heisst Querformat. Damit funktioniert ein breites Laptop-Fenster wie ein Handy quer.

- **Hoch, frei**: Pace oben, darunter 2 × 2 Kacheln, eine Zeile mit Nebenwerten, die Kraftkurve und unten „Session beenden“.
- **Quer, frei**: links die Pace mit der Kraftkurve darunter, rechts 2 × 2 Kacheln und „Session beenden“.
- **Hoch, Vorlage**: Pace-Box über die volle Breite, darunter Schlagzahl-Karte, vier kleine Kacheln (Rundenzeit, Watt, Puls, Anteil in der Zone), Kraftkurve und „Session beenden“.
- **Quer, Vorlage**: links die Pace-Box fast über die volle Höhe, in der Mitte die Schlagzahl-Karte mit Kraftkurve, rechts eine schmale Spalte mit den vier Kacheln und „Beenden“.

Die Grössen skalieren mit dem Platz. Massgebend ist das Verhältnis aus dem Canvas, nicht der absolute Pixelwert.

### D3: Fortschrittsrahmen

Der Rahmen der Pace-Box besteht aus drei ineinanderliegenden Spuren in der Form der Box, also Rechtecke mit abgerundeten Ecken:

| Spur | Lage | Farbe | Fortschritt |
|---|---|---|---|
| Strecke | aussen | `text` | Achsenposition über alle Runden / (Streckenlänge × Rundenzahl) |
| Runde | Mitte | `textMuted` | Position in der aktuellen Runde / Streckenlänge |
| Segment | innen | `zoneIn` bzw. `zoneOut` | Position im aktuellen Segment / Segmentlänge |

- Jede Spur beginnt oben in der Mitte und läuft im Uhrzeigersinn. Die leere Spur ist in `track` sichtbar, die innere leere Spur leicht blau getönt.
- Kerben in der Farbe der Box markieren auf der Streckenspur die Rundengrenzen und auf der Rundenspur die Segmentgrenzen.
- Die gefüllte Spur endet gerade. An ihrer Spitze sitzt ein Schiffchen in der Farbe der Spur, eine Raute von etwa 22 × 14 px mit 2 px dunklem Rand. Es ist breiter als die Spur (10 px), damit es auf der gefüllten Spur sichtbar bleibt. Das Schiffchen folgt der Laufrichtung und dreht sich in den Ecken mit der Tangente.
- Die Farbe der Segmentspur folgt dem Zonenstatus der Pace. In einem freien Segment ist sie `textMuted`.
- Bei offener Rundenzahl entfällt die Streckenspur, weil die Gesamtlänge unbekannt ist. Die Rundenspur rückt nach aussen.
- Die Position wird als Bogenlänge auf dem Pfad berechnet (`PathMetrics`), damit gleiche Anteile überall gleich lang sind, auch in den Ecken.

Inhalt der Box von oben nach unten: Beschriftung „Pace /500 m“, die Pace, Zonenstatus mit Band (z. B. „In der Zone · 2:05–2:10“), eine Trennlinie und die Legende. Die Legende hat eine Zeile pro Spur mit Farbpunkt, Bezeichnung und Restangabe, z. B. „Gesamt 1 460 / 3 000 m“, „Runde 2 / 3 noch 540 m“, „Zone Tempo noch 206 m“ bzw. „frei noch 206 m“ (Zonenname aus `zones`). Bei Zeitstrecken stehen statt Metern Zeiten.

Platz für den Ghost: Der Change `ghost` setzt auf jede Spur ein zweites, kleineres Schiffchen in `ghost` (etwa 18 × 7 px) und eine vierte Zeile in der Legende. Liegen beide Schiffchen übereinander, liegt das des Ghosts oben. Das Widget nimmt dafür optionale Ghost-Positionen pro Spur entgegen.

*Alternative*: drei konzentrische Kreise um die Pace. Im Canvas ausprobiert und verworfen. Die Pace wird im Kreis kleiner, und die Restangaben finden keinen Platz.

### D4: Segmentbalken

Ein wiederverwendbares Widget zeigt die Segmente einer Strecke als Balken. Breite heisst Länge, Grau heisst frei, Blau heisst mit Band. Haben mehrere Segmente ein Pace-Band, werden schnellere Bänder heller dargestellt. Die Abstufung reicht von `#2F5577` (langsamstes Band) bis `#A9D3FF` (schnellstes). Haben die Segmente nur ein Schlagzahl-Band, sind sie einheitlich `zoneIn`. Höhe: 8–10 px in Listen, 28 px mit Zonennamen im Strecken-Editor. Die gewählte Zone hat einen Umriss in `text`. Mit `zones` sind die Abschnitte mit Band die eingebauten Zonen, die grauen die freien Lücken.

### D5: Segmentlänge ändern (entfällt)

Die manuelle Segmentlänge ersetzt der Change `zones`: Strecken bestehen dort aus eingebauten Zonen mit fester Länge und freien Lücken. Die Nummer D5 bleibt frei, damit Verweise stabil bleiben.

### D6: Navigation

- Startbildschirm (entschieden 2026-10-16, Mittelweg statt Canvas): oben die Quelle, darunter „Rudern“ und „Frei rudern“, dann die Kachel „Nochmal“ und der Link „Sessions“.
  - „Rudern“ öffnet „Vorlage wählen“. „Frei rudern“ startet direkt.
  - „Nochmal“ zeigt die Vorlage der jüngsten Session, deren Vorlage noch existiert, mit Name und Datum der Session („gestern“). Antippen öffnet „Vorlage wählen“ mit dieser Vorlage vorausgewählt. Gibt es keine solche Session, fehlt die Kachel.
  - Keine Kacheln für alle Vorlagen und keine Liste der letzten Sessions: Der Bildschirm bleibt ruhig, und der häufigste Fall, dieselbe Vorlage noch einmal zu rudern, braucht trotzdem nur zwei Tipps.
  - *Alternativen:* wie im Canvas (alle Vorlagen als Kacheln, letzte Sessions) oder ganz schlank (nur Quelle, „Rudern“, „Frei rudern“). Verworfen, weil der Canvas am Erg zu voll ist und die schlanke Variante für die Lieblingsvorlage einen Schritt mehr braucht.
- „Vorlage wählen“ klappt die gewählte Vorlage auf, mit Bändern, Ghost-Bestzeit (sobald `ghost` da ist) und „Starten“. Der Stift öffnet den Vorlagen-Editor.
- Der Tab „Strecken“ zeigt die Streckenliste. Eine Strecke öffnet den Strecken-Editor. Der dritte Tab „Zonen“ und „Zone einbauen“ kommen mit `zones`.

## Risks / Trade-offs

- **Platz im Hochformat mit Vorlage**: Pace-Box, Schlagzahl, Kacheln und Kraftkurve sind auf 390 × 844 knapp. Auf kleineren Geräten fällt zuerst die Kraftkurve weg, danach werden die Kacheln einzeilig. Die bestehenden Layout-Tests in allen vier Grössen sichern das ab.
- **Schiffchen überlappen**: Liegen eigener Wert und Ghost sehr nah beieinander, verdeckt ein Schiffchen das andere teilweise. Vorerst liegt der Ghost oben. Erweist sich das am Erg als unlesbar, wird der Ghost nach aussen versetzt.
- **Schriften als Assets** vergrössern die App um etwa 400 kB.

## Open Questions

- Puls-Herkunft: Der Canvas zeigt im Screen „Zustände“ einen Zustand „Über PM5“. Der Change `heart-rate` schliesst die Anzeige der Puls-Herkunft im Live-Display aber ausdrücklich aus. Das ist vor der Umsetzung von `heart-rate` zu klären.
