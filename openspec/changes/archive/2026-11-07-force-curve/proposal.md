# Proposal

## Why

Pace und Watt sagen, wie schnell man rudert, aber nicht, wie der Schlag aussieht. Die Kraftkurve zeigt den Kraftverlauf über einen Schlag und macht Technikfehler sichtbar, etwa einen späten Kraftaufbau oder einen Einbruch in der Mitte. Der PM5 liefert die Kurve pro Schlag über Bluetooth. Die App liest bisher nur Spitzen- und Durchschnittskraft aus den Schlagdaten.

## What Changes

- **Kraftkurve lesen**: Die App abonniert beim PM5 die Kraftkurven-Daten (laut Concept2-BLE-Spezifikation die Characteristic 0x003D, vor der Umsetzung per Spike-Mitschnitt zu bestätigen) und setzt die Teilpakete eines Schlags zu einer Kurve zusammen.
- **Kraftkurve anzeigen**: Das Live-Display zeigt die Kurve des letzten Schlags als Linie mit Fläche und dahinter die des vorherigen Schlags in Grau. Vor dem ersten Schlag zeigt die Karte „Warte auf ersten Schlag“. Liefert die Quelle keine Kurve, entfällt die Karte und die übrigen Werte rücken nach.
- **Schlaglänge**: Neben der Kurve des letzten Schlags steht dessen Durchzugslänge in Zentimetern, etwa „102 cm“. Fehlt die Länge, etwa bei FTMS-Ruderern, entfällt die Angabe.
- **Aufzeichnen und abspielen**: Die Kurvenpakete werden als Rohdaten mit der Session gespeichert, exportiert und importiert. Ein Replay zeigt die Kurve wie live.
- **Simulator**: Der Simulator liefert eine plausible Kurve pro Schlag, damit sich die Anzeige ohne Erg testen lässt.

Nicht Teil dieses Changes: Auswertungen der Kurve (Kurvenform-Kennzahlen, Vergleich über die Session), die Kurve in der Zusammenfassung und eine Kraftkurve für FTMS-Ruderer (Change `device-types`), die diese Daten nicht liefern.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `rowing-telemetry`: Kraftkurve pro Schlag als zusätzlicher Messwert.
- `live-display`: Karte mit der Kraftkurve des letzten und des vorherigen Schlags und der Schlaglänge.
- `session-recording`: Kurvenpakete aufzeichnen, exportieren und abspielen.
- `erg-simulation`: Der Simulator liefert eine Kraftkurve.

## Impact

- `packages/erg_protocol`: Characteristic, Decoder für die Kraftkurve mit Zusammensetzen der Teilpakete, neues Ereignis pro Schlag.
- `lib/data/sources`: Abonnement der zusätzlichen Characteristic, Kurve im Simulator.
- `lib/features/live`: Karte mit der Kurve. Ihr Platz ist im Change `ui-design` vorgesehen.
- `lib/spike`: abonniert die Kurvenpakete; ein Ausschnitt des Mitschnitts wird Test-Fixture.
- Keine Schema-Änderung: Die Kurvenpakete laufen als Rohpakete in die bestehende Tabelle `raw_packets`.
- Design: Canvas „Stroke & Split Frontend“, Screens „Live: freies Rudern“, „Live: Vorlage mit Zonen“, die beiden Querformat-Screens und „Zustände: Kraftkurve & Puls“ (Abschnitt Kraftkurve).
