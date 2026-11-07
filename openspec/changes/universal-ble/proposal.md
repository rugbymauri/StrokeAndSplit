# Proposal

## Why

Die BLE-Bibliothek `flutter_blue_plus` 2.x steht unter der FlutterBluePlus License: frei nur für nicht-kommerzielle Nutzung (`License.nonprofit`), sonst kostenpflichtig, und sie sendet beim Build Telemetrie. Damit ist die App nicht frei verwendbar und weitergebbar. Design D4 des Changes `foundation` hat `universal_ble` (BSD-3, ebenfalls mit Linux) als Alternative vorgesehen; mit dem Wechsel wird die App frei von dieser Lizenzbindung.

## What Changes

- `flutter_blue_plus` wird durch `universal_ble` (3.x) ersetzt, in `pubspec.yaml`, im Transport der App und im BLE-Spike.
- `FlutterBluePlusTransport` wird zu `UniversalBleTransport`; die Schnittstellen `BleTransport`, `HeartRateTransport` und `GattConnection` bleiben unverändert, ebenso Erkennung, Verbindungsaufbau und Wiederverbindung darüber.
- Die Übersetzung von Scan-Fehlern in `BluetoothReadiness` nutzt die typisierten Fehler von `universal_ble` (`UniversalBleException.code`) statt Textvergleichen.
- Der Linux-Umweg über `systemDevices` für Geräte im BlueZ-Cache entfällt, falls der Scan von `universal_ble` diese Geräte selbst meldet (Design D3).
- Die Pin von `wakelock_plus` auf < 1.8.1 (wegen eines `dbus`-Konflikts mit `flutter_blue_plus`) wird aufgehoben, sofern die Abhängigkeiten das zulassen.
- README-Lizenzhinweis und die Notiz in `packages/erg_protocol/README.md` werden nachgeführt.

Am Verhalten der App ändert sich nichts: Suche, Verbinden, Wiederverbinden, Gurt und Fehlermeldungen bleiben wie spezifiziert.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

Keine. Der Wechsel betrifft nur die Umsetzung; die Anforderungen von `erg-connection`, `heart-rate-monitor` und `resistance-control` gelten unverändert. Der Change setzt deshalb `skip_specs: true`.

## Impact

- Code: `lib/data/sources/ble/flutter_blue_plus_transport.dart` (ersetzt), `lib/app/platform_providers.dart`, `lib/spike/spike_main.dart`, `test/data/sources/ble/flutter_blue_plus_transport_test.dart`.
- Abhängigkeiten: `flutter_blue_plus` raus, `universal_ble` rein; `wakelock_plus` evtl. ohne Pin; `pubspec.lock`, generierte Plugin-Registrierungen (macOS u. a.).
- Plattformen: Android-Berechtigungen und macOS-Entitlement bleiben gleich; Linux (BlueZ) und Android müssen am Gerät neu geprüft werden (PM5, FTMS-Rudergerät, Pulsgurt).
- Doku: README-Lizenzhinweis, `packages/erg_protocol/README.md`, `docs/implementation-plan.md`.
