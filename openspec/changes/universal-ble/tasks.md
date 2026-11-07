# Tasks

## 1. Abhängigkeiten

- [ ] 1.1 In `pubspec.yaml` `flutter_blue_plus` durch `universal_ble: ^3.2.0` ersetzen (vorher neuste Version auf pub.dev prüfen), `flutter pub get`; prüfen, dass `flutter pub deps` kein `flutter_blue_plus` mehr enthält
- [ ] 1.2 Pin von `wakelock_plus` (< 1.8.1) aufheben und auf die neuste Version heben, wenn `pub get` ohne `dbus`-Konflikt auflöst; sonst Pin behalten und den Kommentar mit der neuen Ursache nachführen (Design D6); verifizieren mit `flutter pub get`

## 2. Transport

- [ ] 2.1 `UniversalBleTransport` in `lib/data/sources/ble/universal_ble_transport.dart` umsetzen: `readiness` (D4), `scan`/`scanHeartRateMonitors` mit eigenem Timeout und ohne Linux-`systemDevices` (D3), `connect`/`connectHeartRateMonitor` mit Discovery und Kurz-IDs `uuid.substring(4, 8)` (D2), `GattConnection` mit `connectionStream` für `lost` (D5); `flutter_blue_plus_transport.dart` löschen; verifizieren mit `flutter analyze` ohne Befunde
- [ ] 2.2 `readinessForScanError` auf `UniversalBleException.code` umstellen, Rückfall auf `PlatformException`-Text behalten; Test als `test/data/sources/ble/universal_ble_transport_test.dart` mit Fällen für die Fehlercodes (`bluetoothUnauthorized`, `bluetoothNotEnabled`, andere) und die bisherigen `PlatformException`-Fälle; `flutter test test/data/sources/ble` grün
- [ ] 2.3 Kurz-ID-Bildung als kleine Funktion herausziehen und testen (PM5 `ce060031-…` → `0031`, `00002ad1-0000-1000-8000-00805f9b34fb` → `2ad1`, `0000180d-…` → `180d`); Test grün
- [ ] 2.4 `platform_providers.dart` auf `UniversalBleTransport` umstellen; `flutter test` komplett grün
- [ ] 2.5 Gemerkte Geräte-IDs beim Lesen in `rower_choice.dart` und `heart_rate_choice.dart` klein schreiben (D2), damit eine alte gross geschriebene Android-MAC zu den Scan-Treffern passt; Unit-Test mit gross geschriebener gespeicherter ID grün

## 3. Spike und Doku

- [ ] 3.1 `lib/spike/spike_main.dart` auf `universal_ble` umstellen (Scan, Verbinden, Notifications, Control Point, Widerstandsbereich lesen); verifizieren mit `flutter analyze` und `flutter build linux -t lib/spike/spike_main.dart`
- [ ] 3.2 README: Lizenzhinweis zu `flutter_blue_plus` durch einen Hinweis auf `universal_ble` (BSD-3) ersetzen; `packages/erg_protocol/README.md` (Linux-Notiz zu `systemDevices`) nachführen; `grep -rn flutter_blue` ausserhalb von `openspec/changes/archive` findet nichts mehr
- [ ] 3.3 `docs/implementation-plan.md`: Change `universal-ble` mit Branch und Stand eintragen

## 4. Gerätetests

- [ ] 4.1 Linux (`make run`): PM5 finden (auch wenn er schon im BlueZ-Cache ist), verbinden, Session rudern, PM5 kurz ausschalten → Wiederverbindung; Bluetooth aus → Meldung „Bluetooth aus“
- [ ] 4.2 Android: PM5 und FTMS-Rudergerät (Woodrower) finden und verbinden, Widerstandsstufe setzen, Session rudern; Berechtigung entzogen → Meldung „Berechtigung fehlt“; gemerktes Gerät aus der alten Version wird wieder verbunden
- [ ] 4.3 Pulsgurt auf Linux und Android: finden, koppeln, automatisch mit dem Rudergerät verbinden, kurz ausser Reichweite → Wiederverbindung
- [ ] 4.4 Release-Builds der CI (APK, AppImage) laufen durch

## Workflow follow-up

- Nach den Gerätetests mergen und den Change archivieren; offene Gerätetests in `docs/implementation-plan.md` übernehmen.
