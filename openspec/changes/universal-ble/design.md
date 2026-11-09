# Design

## Context

Siehe proposal.md – Why. Heute kapselt `FlutterBluePlusTransport` (`lib/data/sources/ble/flutter_blue_plus_transport.dart`) die ganze BLE-Bibliothek: Bereitschaft, Scan (Rudergeräte und Gurte), Verbinden mit Service-Discovery und eine `GattConnection` mit Kurz-IDs (`0031` für PM5-Characteristics, `2ad1` für Standard-UUIDs). Alles darüber (`setUpRower`, `setUpHeartRateMonitor`, `BleRowerSource`, Wiederverbindung, Filter `rowerFromAdvertisement` / `heartRateMonitorFromAdvertisement`) arbeitet nur gegen diese Schnittstellen und bleibt unberührt. Daneben nutzt der Spike `lib/spike/spike_main.dart` die Bibliothek direkt.

`universal_ble` 3.2.0 (BSD-3) deckt Android, iOS, macOS, Linux (über `bluez`), Windows und Web ab. Unterschiede, die den Transport betreffen:

- UUIDs sind Strings, immer 128 Bit klein geschrieben; Geräte-IDs sind klein geschrieben.
- `scanStream` liefert ein `BleDevice` pro Treffer statt Listen; `startScan` hat keinen Timeout und es gibt keinen Scan-Zustand als Stream.
- Kein `isSupported`; ein fehlender Adapter heisst `AvailabilityState.unsupported`.
- Fehler sind typisiert: `UniversalBleException` mit `UniversalBleErrorCode`.
- Verbindungsabbruch über `connectionStream(deviceId)` (`bool`).
- Auf Linux meldet `startScan` nach dem Start der Discovery auch alle Geräte, die BlueZ schon kennt (`_client.devices`); der Cache-Umweg über `systemDevices` ist dort also nicht mehr nötig.
- Standard-Queue `QueueType.auto`: auf Android und Linux laufen Befehle pro Gerät nacheinander.

## Goals / Non-Goals

**Goals:**
- Kein Code und keine Abhängigkeit mehr auf `flutter_blue_plus`, auch nicht transitiv.
- Gleiches Verhalten auf Linux und Android wie heute (Suche, Verbinden, Wiederverbinden, Gurt, Meldungen bei Bluetooth aus oder fehlender Berechtigung).

**Non-Goals:**
- Keine neuen Plattformen (Windows, Web) freischalten oder testen.
- Kein Umbau der Schnittstellen `BleTransport`, `HeartRateTransport`, `GattConnection`.
- Keine neuen Funktionen der Bibliothek nutzen (Pairing, MTU, Auto-Connect).

## Decisions

### D1: Nur den Transport austauschen

`FlutterBluePlusTransport` wird durch `UniversalBleTransport` in `lib/data/sources/ble/universal_ble_transport.dart` ersetzt, `platform_providers.dart` zeigt darauf. Die Schnittstellen bleiben, die Tests mit Fakes darüber laufen unverändert weiter.
Alternative: eine eigene Abstraktion für beide Bibliotheken zum Umschalten. Verworfen: es gibt keinen Grund, `flutter_blue_plus` zu behalten, und die Schnittstellen sind schon die Abstraktion.

### D2: Low-Level-API mit Geräte-ID

Der Transport arbeitet mit `BleDevice(deviceId: id, name: …)` und den Extension-Methoden (`connect`, `discoverServices`, `BleCharacteristic.read/write/notifications.subscribe/onValueReceived`). Die `GattConnection` hält wie heute eine Map Kurz-ID → Characteristic. Die Kurz-ID der Characteristics ist bei `universal_ble` für alle UUIDs `uuid.substring(4, 8)`, weil jede UUID als 128-Bit-Text kommt (`ce060031-…` → `0031`, `00002ad1-0000-1000-8000-00805f9b34fb` → `2ad1`); die Sonderbehandlung nach Präfix `ce06` fällt weg. Die Scan-Filter erwarten Service-IDs weiter kurz (`180d`, `1826`); `shortServiceId` kürzt nur UUIDs auf der Bluetooth-Basis-UUID und lässt Hersteller-UUIDs lang.
`FoundRower.id` und `FoundHeartRateMonitor.id` sind künftig klein geschrieben. Ein gemerkter Gurt oder ein gemerktes Rudergerät (`shared_preferences`) mit gross geschriebener Android-MAC muss weiter erkannt werden: IDs werden beim Vergleich bzw. beim Lesen der gemerkten ID mit `UniversalBle.canonicalDeviceId` (bzw. `toLowerCase`) vereinheitlicht. Umgesetzt beim Lesen der gemerkten Wahl (`rower_choice.dart`, `heart_rate_choice.dart`, Task 2.5). Die Geräteliste zeigt die MAC weiterhin gross geschrieben, damit sich die Anzeige nicht ändert.

### D3: Scan mit eigenem Timeout und ohne Linux-Cache-Umweg

`_scan` sammelt die `BleDevice`s aus `UniversalBle.scanStream`, wendet wie heute `recognise` an (Name: `name`, Services: `services`, Service-Daten: `serviceData`, Schlüssel 128 Bit klein) und emittiert die wachsende Liste. Ein `Timer` ruft nach `timeout` `stopScan` und schliesst den Stream; bricht der Aufrufer das Abo ab, wird ebenfalls gestoppt. `withServices` geht als `ScanFilter(withServices: …)` mit (nur bei Gurten).
Der Aufruf von `systemDevices` auf Linux entfällt, weil `startScan` dort die bekannten BlueZ-Geräte selbst meldet. Sie haben keine frische Werbung, liefern aber Name und die gespeicherten Service-UUIDs von BlueZ, also werden PM5 (Name) und Gurt (Service) wie heute erkannt. Bestätigt sich das im Linux-Test nicht, kommt `UniversalBle.getSystemDevices` als Fallback zurück.

### D4: Bereitschaft und Scan-Fehler über Zustände und Fehlercodes

`readiness()` wartet höchstens 3 s auf einen Zustand ausser `unknown`/`resetting` (erst `getBluetoothAvailabilityState`, dann `availabilityStream`) und bildet ab: `poweredOn` → `ready`, `unauthorized` → `unauthorized`, `unsupported` → `unsupported`, sonst `off`.
`readinessForScanError` prüft zuerst `UniversalBleException.code` (`bluetoothUnauthorized`, `bluetoothNotAllowed` → `unauthorized`; `bluetoothNotEnabled`, `bluetoothNotAvailable` → `off`) und behält als Rückfall den Textvergleich auf `PlatformException`, weil eine Android-Berechtigung auch als `PlatformException` ankommen kann. Die Tests bekommen Fälle für die Fehlercodes.

### D5: Abbruch über `connectionStream`

Die `GattConnection` hört auf `UniversalBle.connectionStream(id)`; `false`, ohne dass die App selbst trennt, schliesst `lost` wie heute. `disconnect` meldet ab, beendet die Abos und trennt.

### D6: `wakelock_plus` entpinnen, wenn möglich

Der Pin < 1.8.1 bestand nur wegen des `dbus`-Konflikts mit `flutter_blue_plus`. Nach dem Wechsel wird `wakelock_plus` auf die neuste Version gehoben, falls `bluez`/`dbus` von `universal_ble` das zulassen; sonst bleibt ein Pin mit neuer Begründung.

## Risks / Trade-offs

- [Linux-Backend verhält sich anders als bei `flutter_blue_plus` (Cache, Namen, Notifications)] → Linux-Gerätetest mit PM5 und Gurt vor dem Merge; Fallback `getSystemDevices` (D3).
- [Per-Device-Queue verzögert Notifications oder Schreibvorgänge am Control Point] → Gerätetest FTMS (Woodrower) mit Widerstandsstufen; falls nötig `UniversalBle.queueType` anpassen.
- [Gemerkte IDs in Grossbuchstaben passen nicht mehr] → Vergleich normalisieren (D2), Unit-Test dazu.
- [Pulsgurt wird an einer Uhr gehalten: Fehlermeldung unterscheidet sich] → Meldung „belegter Gurt“ im Gerätetest prüfen; Fehlertext kommt aus `HeartRateConnectError`, nicht aus der Bibliothek.

## Migration Plan

Keine Datenmigration. Gemerkte Geräte bleiben gültig (D2). Rückweg: Revert des Branches.
