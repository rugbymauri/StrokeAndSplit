# Design

## Context

Das Verhalten steht in den Specs. Die Gestaltung stammt aus dem Claude-Design-Canvas **AergRow Frontend** (privat, Freigabe über das Share-Menü). Die Kurve erscheint dort an vier Stellen:

| Screen im Canvas | Platz der Kurve |
|---|---|
| Live: freies Rudern | eigene Karte unter den Nebenwerten, Höhe etwa 96 px |
| Live: Vorlage mit Zonen | schmaler Streifen „Kraft“ unter den Kacheln, etwa 44 px |
| Live quer: freies Rudern | unter der Pace in derselben Karte |
| Live quer: Vorlage mit Zonen | in der Schlagzahl-Karte unter der Schlagzahl |
| Zustände: Kraftkurve & Puls | Zustände „Live“, „Warte auf ersten Schlag“ und „Gerät liefert keine Kraftkurve“ |

Dieser Change setzt auf `ui-design` auf, das die Flächen dafür baut.

## Decisions

### D1: Daten vom PM5

Laut Concept2-BLE-Spezifikation sendet der PM5 die Kurve eines Schlags nach dessen Ende in mehreren Notifications. Jedes Paket enthält einen Zähler und eine Reihe von Kraftwerten in Pfund-Kraft. Der Decoder sammelt die Pakete eines Schlags und gibt die vollständige Kurve als ein Ereignis aus. Die Kraftwerte werden wie die bestehenden Kraftwerte in Newton umgerechnet.

Erster Schritt der Umsetzung ist ein Spike-Mitschnitt am echten PM5. Er bestätigt UUID, Paketaufbau und die Zahl der Werte pro Schlag, bevor der Decoder entsteht. Weicht der Aufbau von der Spezifikation ab, gilt der Mitschnitt.

### D2: Darstellung

- Die x-Achse ist der Index des Werts im Schlag, auf die Breite gestreckt. Die y-Achse reicht von 0 bis zum Maximum der beiden gezeigten Kurven, damit beide vergleichbar bleiben.
- Letzter Schlag: Linie 3 px in `zoneIn`, darunter Fläche in derselben Farbe mit 16 % Deckkraft. Im Querformat mit Vorlage steht die Kurve auf orangem Grund und ist deshalb in `text` gezeichnet.
- Vorheriger Schlag: Linie 2 px in `#5A646E`, ohne Fläche.
- Legende nur in der grossen Karte: „Letzter“ und „Vorheriger“.

### D3: Verfügbarkeit

Die Karte erscheint, sobald die Quelle Kraftkurven unterstützt. PM5 und Simulator tun das, FTMS-Ruderer nicht. Bis zum ersten Schlag zeigt sie eine gestrichelte Grundlinie mit „Warte auf ersten Schlag“.

## Risks / Trade-offs

- **Bandbreite**: Die zusätzlichen Notifications belasten die BLE-Verbindung. Bei Abbrüchen im Mitschnitt wird das Abonnement optional und lässt sich abschalten.
- **Speicher**: Pro Schlag kommen einige hundert Bytes Rohdaten dazu, bei einer Stunde Rudern etwa 0.5 MB.
