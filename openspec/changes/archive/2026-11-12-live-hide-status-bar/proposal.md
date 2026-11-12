# Proposal

## Why

Im Live-Display steht unter Android oben die Statusleiste mit Uhrzeit und Akkustand. Sie lenkt beim Rudern ab und nimmt den Werten Platz weg.

## What Changes

- Solange das Live-Display offen ist, blendet die App unter Android die Statusleiste aus; die Navigationsleiste bleibt.
- Beim Verlassen des Live-Displays erscheint die Statusleiste wieder.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `live-display`: neue Anforderung „Statusleiste ausblenden“.

## Impact

- Live-Display und die Plattformdienste der App (Systemleisten). Keine Änderung an Daten oder Schema. Unter Linux, iOS und macOS ohne Wirkung auf eine Statusleiste.
