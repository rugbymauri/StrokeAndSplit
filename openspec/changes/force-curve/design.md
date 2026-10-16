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

Erwartung laut Spezifikation, noch nicht gemessen: Characteristic `CE06003D-…` im Rowing-Service `0x0030`, Notify, bis 20 Bytes. Byte 0 trägt im oberen Nibble die Zahl der Pakete des Schlags und im unteren die Zahl der Kraftwerte in diesem Paket, Byte 1 ist der Zähler, danach folgen bis zu neun Kraftwerte als u16 Little-Endian in lbf. Ob die Werte wie bei `0x0035` in 0.1 lbf oder in ganzen lbf kommen, klärt erst der Mitschnitt.

#### Stand des Spikes (2026-10-16)

Der Mitschnitt vom 2026-10-16 (PM5 430000001, RowErg, Just Row, 13 Schläge) enthält **keine** Kraftkurve: Der Spike abonnierte nur `0031`–`0036`; dasselbe gilt für die Aufnahmen vom 2026-10-15. Bestätigt sind damit nur die Schlag-Ereignisse, an denen sich der Decoder ausrichten kann:

- `0x0035` kommt zweimal pro Schlag: am Ende des Durchzugs (Schlagzustand 2 → 3/4) mit neuer Schlagnummer und Kräften, und am Ende der Erholung noch einmal mit derselben Schlagnummer und nachgeführter Erholungszeit. `0x0036` kommt einmal pro Schlag, zusammen mit dem ersten `0x0035`. Die Kurve ist um den Wechsel 2 → 4 zu erwarten.
- Der erste Schlag nach dem Start meldet Spitzen- und Durchschnittskraft 0; für ihn ist keine Kurve zu erwarten.
- Spitzenkraft 420–550 N, Durchschnittskraft 280–350 N, Verhältnis 0.63–0.68 bei etwa 95 W und 0.9 m Durchzug. Daran lässt sich die Kurve später prüfen: ihr Maximum muss der Spitzenkraft aus `0x0035` entsprechen, ihr Mittel ungefähr der Durchschnittskraft. Das legt auch die Einheit fest.

Der Spike abonniert `003d` jetzt zusätzlich. Ein neuer Mitschnitt von einigen Minuten ist nötig, bevor der Decoder entsteht.

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
