# Proposal

## Why

Die App zeigt den Puls bisher nur, wenn das Rudergerät selbst einen liefert: beim PM5 nur mit einem im PM5-Menü gekoppelten Brustgurt, bei FTMS-Rudergeräten nur, wenn das Gerät das Feld Heart Rate sendet. Die Kopplung am PM5 ist umständlich, und Rudergeräte geben nur einen gerundeten Pulswert weiter, keine RR-Intervalle. Wer einen BLE-Brustgurt direkt mit der App verbindet, bekommt den Puls zuverlässiger, ohne Umweg über das Rudergerät, und dazu die Abstände von Herzschlag zu Herzschlag. Puls und RR-Intervalle sind ausserdem die Grundlage für spätere Puls-Zonen und Erholungsauswertungen.

## What Changes

- **Brustgurt direkt koppeln**: Die App sucht BLE-Brustgurte (Heart Rate Service). Der Nutzer koppelt einen Gurt in „Geräte wählen“ vor dem Startbildschirm, optional neben dem Rudergerät. Die App merkt sich den Gurt. Er lässt sich dort wechseln oder vergessen. Der Startbildschirm zeigt den gekoppelten Gurt in der Gerätezeile.
- **Gurt automatisch verbinden**: Sobald ein echtes Rudergerät über Bluetooth verbunden ist, ein PM5 oder ein FTMS-Rudergerät, verbindet sich die App mit dem gemerkten Gurt. Mit Simulator oder Replay verbindet sie keinen Gurt. Bricht die Verbindung zum Gurt ab, versucht sie wie beim Rudergerät 30 Sekunden lang, sie wiederherzustellen. Der Zustand des Gurts ist im Live-Display neben dem des Rudergeräts sichtbar. Ein Ausfall des Gurts beeinflusst die Verbindung zum Rudergerät nicht.
- **Puls-Regel**: Liefert der direkt verbundene Gurt einen frischen Wert, gilt dieser. Sonst gilt der Puls, den das Rudergerät meldet (PM5 oder FTMS), und ohne beides ist der Puls „nicht vorhanden“. Die Herkunft wird nicht angezeigt. Die Regel gilt für Live, Aufzeichnung und Replay gleich.
- **RR-Intervalle**: Sendet der direkt verbundene Gurt RR-Intervalle, zeigt das Live-Display das letzte Intervall klein beim Puls. Über das Rudergerät gibt es keine RR-Intervalle.
- **Aufzeichnung**: Die Pakete des Gurts werden als Rohdaten mit der Session gespeichert, exportiert und importiert. Ein Replay zeigt Puls und RR-Intervalle wie bei der Aufnahme.
- **Zusammenfassung**: Die Zusammenfassung zeigt Durchschnitts- und Maximalpuls. Bei vorhandenen RR-Intervallen zeigt sie zusätzlich deren Verlauf als Kurve und die Herzratenvariabilität als RMSSD.
- **Spike**: Der BLE-Spike schneidet zusätzlich die Pakete eines Brustgurts mit, damit echte Aufnahmen als Test-Fixtures dienen können.

Nicht Teil dieses Changes: ein simulierter Gurt (die Simulatoren liefern weiterhin keinen Puls), ein Gurt ohne verbundenes Rudergerät, die Anzeige der Puls-Herkunft im Live-Display, Puls-Zonen sowie weitere HRV-Auswertungen über RMSSD hinaus.

## Capabilities

### New Capabilities
- `heart-rate-monitor`: Einen BLE-Brustgurt suchen, in „Geräte wählen“ koppeln, merken, mit dem Rudergerät automatisch verbinden und wiederverbinden sowie seinen Verbindungszustand anzeigen.

### Modified Capabilities
- `rowing-telemetry`: Puls aus dem Gurt oder dem Rudergerät (PM5 oder FTMS) nach fester Vorrangregel, RR-Intervalle als zusätzliche Messwerte.
- `session-recording`: Gurt-Rohdaten mitspeichern, exportieren und abspielen. Die Zusammenfassung enthält Durchschnitts- und Maximalpuls sowie RR-Verlauf und RMSSD.
- `live-display`: Zustand des Gurts neben dem Rudergerät und letztes RR-Intervall beim Puls anzeigen.

## Impact

- `packages/erg_protocol`: Parser für die Heart Rate Measurement (0x2A37), ein Decoder, der die Gurt-Pakete vor dem Decoder des Rudergeräts abfängt und die Vorrangregel für PM5 und FTMS gleich anwendet, neues Ereignis für RR-Intervalle, Encoder für Gurt-Pakete in Tests.
- `lib/data/sources/ble`: Suche und Verbindung für Brustgurte neben den Rudergeräten (`HeartRateTransport` neben `BleTransport`, Einrichtung über die bestehende `GattConnection`), Einspeisung der Gurt-Pakete in den Paketstrom von `BleRowerSource`.
- `lib/data/sources`: gemerkter Gurt neben dem gemerkten Rudergerät (`rower_choice.dart`), Notifier für den Lebenszyklus des Gurts.
- `lib/data/db`: Schema-Erweiterung für Puls-Zusammenfassung und RR-Intervalle, mit Migration. `statistics` hat `schemaVersion` auf 5 gehoben, `heart-rate` hebt auf 6.
- `lib/features/connection`: „Geräte wählen“ (Bereich „Pulsgurt“), Startbildschirm (Gurt in der Gerätezeile), Gurt-Indikator neben `ConnectionIndicator`.
- `lib/features/live` und `lib/features/sessions`: RR-Intervall beim Puls, Zusammenfassung mit Puls, RR-Kurve und RMSSD.
- `lib/l10n`: neue Texte auf Deutsch und Englisch.
- `lib/spike`: zusätzlicher Mitschnitt eines Brustgurts.
