# Proposal

## Why

Die App zeigt den Puls bisher nur, wenn der Brustgurt am PM5 gekoppelt ist. Diese Kopplung läuft über das PM5-Menü und ist umständlich, und der PM5 gibt nur einen gerundeten Pulswert weiter, keine RR-Intervalle. Wer einen BLE-Brustgurt direkt mit der App verbindet, bekommt den Puls zuverlässiger, ohne Umweg über den PM5, und dazu die Abstände von Herzschlag zu Herzschlag. Puls und RR-Intervalle sind ausserdem die Grundlage für spätere Puls-Zonen und Erholungsauswertungen.

## What Changes

- **Brustgurt direkt koppeln**: Die App sucht BLE-Brustgurte (Heart Rate Service), der Nutzer koppelt einen Gurt einmal auf dem Startbildschirm. Die App merkt sich den Gurt. Er lässt sich wechseln oder vergessen.
- **Gurt automatisch verbinden**: Sobald ein echter PM5 verbunden ist, verbindet sich die App mit dem gemerkten Gurt. Bricht die Verbindung zum Gurt ab, versucht sie wie beim PM5 30 Sekunden lang, sie wiederherzustellen. Der Zustand des Gurts ist im Live-Display neben dem des PM5 sichtbar. Ein Ausfall des Gurts beeinflusst die Verbindung zum PM5 nicht.
- **Puls-Regel**: Liefert der direkt verbundene Gurt einen frischen Wert, gilt dieser. Sonst gilt der Puls, den der PM5 meldet, und ohne beides ist der Puls „nicht vorhanden“. Die Regel gilt für Live, Aufzeichnung und Replay gleich.
- **RR-Intervalle**: Sendet der direkt verbundene Gurt RR-Intervalle, zeigt das Live-Display das letzte Intervall unter dem Puls. Über den PM5 gibt es keine RR-Intervalle.
- **Aufzeichnung**: Die Pakete des Gurts werden als Rohdaten mit der Session gespeichert, exportiert und importiert. Ein Replay zeigt Puls und RR-Intervalle wie bei der Aufnahme.
- **Zusammenfassung**: Die Zusammenfassung zeigt Durchschnitts- und Maximalpuls. Bei vorhandenen RR-Intervallen zeigt sie zusätzlich deren Verlauf als Kurve und die Herzratenvariabilität als RMSSD.
- **Spike**: Der BLE-Spike schneidet zusätzlich die Pakete eines Brustgurts mit, damit echte Aufnahmen als Test-Fixtures dienen können.

Nicht Teil dieses Changes: ein simulierter Gurt (der Simulator liefert weiterhin keinen Puls), ein Gurt ohne verbundenen PM5, die Anzeige der Puls-Herkunft im Live-Display, Puls-Zonen sowie weitere HRV-Auswertungen über RMSSD hinaus.

## Capabilities

### New Capabilities
- `heart-rate-monitor`: Einen BLE-Brustgurt suchen, koppeln, merken, automatisch verbinden und wiederverbinden sowie seinen Verbindungszustand anzeigen.

### Modified Capabilities
- `rowing-telemetry`: Puls aus dem Gurt oder dem PM5 nach fester Vorrangregel, RR-Intervalle als zusätzliche Messwerte.
- `session-recording`: Gurt-Rohdaten mitspeichern, exportieren und abspielen. Die Zusammenfassung enthält Durchschnitts- und Maximalpuls sowie RR-Verlauf und RMSSD.
- `live-display`: Zustand des Gurts neben dem PM5 und letztes RR-Intervall unter dem Puls anzeigen.

## Impact

- `packages/pm5_protocol`: Decoder für die Heart Rate Measurement (0x2A37), Vorrangregel im Decoder, neues Ereignis für RR-Intervalle.
- `lib/data/sources/ble`: Suche und Verbindung für Brustgurte neben dem PM5, Einspeisung der Gurt-Pakete in den Paketstrom der PM5-Quelle.
- `lib/data/db`: Schema-Erweiterung für Puls-Zusammenfassung und RR-Intervalle, mit Migration. Auf `main` steht das Schema auf 3, `device-types` hebt es auf 4. Kommt `heart-rate` danach, wird es Version 5.
- `lib/features`: Startbildschirm (Gurt koppeln), Live-Display (Gurt-Indikator, RR), Zusammenfassung (Puls, RR-Kurve, RMSSD).
- `lib/spike`: zusätzlicher Mitschnitt eines Brustgurts.
- Gespeicherte Einstellung für den gemerkten Gurt. Bisher speichert die App keine Einstellungen.
