# Proposal

## Why

„AergRow“ war ein Arbeitstitel. Er ist schwer auszusprechen, und das „Aerg“ erschliesst sich nur, wer „Erg“ kennt und den Umlaut mitdenkt. Der neue Name **Stroke & Split** nennt die zwei Zahlen, um die sich beim Rudern am Erg alles dreht: den Schlag und den Split pro 500 m. Er ist für Ruderer sofort verständlich und klingt nicht nach einer offiziellen Concept2-App. Eine erste Recherche (Oktober 2026) fand keine App und keine Marke mit diesem Namen, die Domains `strokeandsplit.com` und `strokesplit.com` waren nicht registriert.

## What Changes

- **Anzeigename**: Die App heisst überall, wo Nutzer sie sehen, „Stroke & Split“: Launcher, Fenstertitel, Startbildschirm, Meldungen, README.
- **Technische Kennungen**: Paketname, App-ID und Binärname wechseln auf `strokesplit`. Das „&“ ist in Kennungen, Dateiendungen und Domains nicht verwendbar.
- **Session-Dateien**: Exporte erhalten die Endung `.strokesplit` und den Formatnamen `strokesplit-raw`. Der Import liest weiterhin `.aergrow`-Dateien und das Format `aergrow-raw`, damit bestehende Exporte und Test-Fixtures gültig bleiben.
- **Bestehende Daten**: Unter Android und iOS ist eine neue App-ID eine neue App. Die alte Installation behält ihre Sessions. Der Umzug läuft über Export in der alten und Import in der neuen App. Die README beschreibt das.
- Das Design im Canvas wird auf den neuen Namen umgestellt.

Nicht Teil dieses Changes: Logo und App-Icon, Store-Einträge, Domain-Registrierung, Markenanmeldung sowie die Umbenennung des Git-Repositorys und des Projektordners.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `session-recording`: Neue Endung und neuer Formatname für exportierte Sessions, Import alter Dateien bleibt möglich.

## Impact

- `pubspec.yaml`: Paketname `aergrow` → `strokesplit`. Damit ändern sich alle `package:aergrow/…`-Imports in `lib` und `test`.
- `lib/app/aergrow_app.dart`, Klasse `AergRowApp`: Umbenennung, App-Titel.
- Android (`namespace`, `applicationId` `ch.aergrow.aergrow`, Label), iOS (`PRODUCT_BUNDLE_IDENTIFIER`, `CFBundleDisplayName`), Linux (`BINARY_NAME`, `APPLICATION_ID`), macOS (Bundle-ID, Produktname).
- `lib/data/db/database.dart`: Name der lokalen Datenbank. Auf dem Linux-Desktop bleibt die App-ID-unabhängige Datei sonst verwaist, siehe `design.md`.
- `packages/pm5_protocol`: Formatname der Rohaufnahmen mit Rückwärtskompatibilität.
- `lib/features/sessions`, `lib/app/platform_providers.dart`: Dateiendung und Meldungstexte.
- `Makefile` (z. B. Pfade unter `/sdcard/Android/data/ch.aergrow.aergrow`), `README.md`, OpenSpec-Specs mit `.aergrow`.
- Zeitpunkt: Die Umbenennung berührt fast jede Datei. Sie sollte erst laufen, wenn die offenen Branches (`feature/courses`, `feature/heart-rate`, `feature/device-types`, `feature/ui-design`) gemerged sind, sonst entstehen grosse Konflikte.
