# Tasks

## 1. Basis und Package-Umbau

- [x] 1.1 Branch `feature/device-types` von `main` erstellen, auf dem `courses` und `zones` gemergt sind (Design D1); `make check` ist grün
- [x] 1.2 `packages/pm5_protocol` in `packages/erg_protocol` umbenennen, PM5-Dateien nach `src/pm5/` verschieben, Imports, `pubspec.yaml`, Makefile (`PROTOCOL`) und README-Verweise anpassen, rein mechanisch und ohne Verhaltensänderung (D2); `make check` ist grün
- [x] 1.3 `ErgProtocol { pm5, ftms }` und das Interface `ErgDecoder` mit `ErgDecoder.forProtocol` einführen, `Pm5Decoder` implementiert es, `wattsForPace` auf oberste Ebene ziehen, `SessionOffset`-Parameter neutral benennen (D2); bestehende Decoder-Tests laufen unverändert, ein Test prüft die Factory

## 2. Datenmodell und Schema

- [x] 2.1 Schlagdetails in `Stroke` nullable machen (`driveLengthMeters`, `driveTime`, `recoveryTime`, `peakForceNewtons`, `averageForceNewtons`) und alle Verwender anpassen (D9); `make check` ist grün
- [x] 2.2 Schema 4: Spalten in `Strokes` nullable per `TableMigration`, `Sessions.protocol` (Text-Enum, Default `pm5`), `schemaVersion` auf 4, Schritt `from3To4`, `make codegen` und `make schema` ausführen (D9); Migrationstests 3→4 und 1→4 in `test/data/db/migration_test.dart` prüfen, dass bestehende Sessions mit allen Schlagdetails, Runden und Strecken samt Zonen erhalten bleiben und als `pm5` gelten
- [x] 2.3 `ErgSourceKind.ftms` ergänzen und `ErgSource.protocol` einführen, alle Quellen und Fakes (`test/support/fake_erg_source.dart`) liefern ihr Protokoll (D3, D4); Analyse ist grün
- [x] 2.4 `rowingEventsProvider` und `SessionAccumulator` erzeugen den Decoder über `ErgDecoder.forProtocol`, die Session speichert `protocol` und `deviceName` auch für `ftms` (D3); Tests in `erg_source_providers_test.dart` und den Session-Tests decken eine Quelle mit Protokoll `ftms` ab
- [x] 2.5 Rohformat und `.aergrow`: `"protocol"` im Header schreiben und lesen, fehlend gilt `pm5`, `ReplaySource` übernimmt das Protokoll aus dem Header (D3); Tests in `session_export_test.dart` und `replay_source_test.dart` prüfen Export/Import mit Protokoll, Strecke und Zonen sowie den Import einer Datei ohne Protokoll
- [x] 2.6 Quellenanzeige und Zusammenfassung zeigen FTMS-Geräte mit Namen und Kennzeichnung „FTMS“, den Simulator im FTMS-Modus als „SIMULATOR (FTMS)“ (D4); Widget-Tests in `connection_indicator_test.dart` und `session_summary`-Tests

## 3. FTMS-Protokoll

- [x] 3.1 Rower-Data-Parser in `src/ftms/`: Flags lesen, alle Felder in Spec-Reihenfolge mit Einheiten, invertiertes Bit 0, zu kurze Pakete werden mit Warnung verworfen (D8); Unit-Tests mit handgebauten Paketen für jedes Flag einzeln, typische Kombinationen und abgeschnittene Pakete
- [x] 3.2 `FtmsEncoder` für Rower Data (Stroke Rate/Count, Distanz, Pace, Leistung, Energie, Zeit) (D10); Round-Trip-Tests Encoder → Parser
- [x] 3.3 `FtmsDecoder` für `StatusTick`: Felder über More-Data-Teile zusammensetzen, Tick am Ende eines Datensatzes, eigene Uhr aus `RawPacket.time` nur während des Ruderns, Rudern-Erkennung über 4 s, Pace und Watt aus der Pace, Plausibilitätsgrenzen, `workoutType`/`workoutState` `unknown` (D8); Tests für Gerät ohne Zeitfeld, Pause, Pace 0, HR 0, Schlagzahl 120, Kalorien `0xFFFF`, gleiche Watt wie PM5 bei 2:00
- [x] 3.4 `FtmsDecoder` für Schläge und Reset: ein `Stroke` je Zählerschritt ohne Details, kein Ereignis bei mehr als 10 Schlägen Sprung, Reset bei zurückfallender Distanz oder zurückfallendem Zähler (D8); Tests für 40→42, ersten Datensatz mitten im Rudern, Reset von 1500 m auf 0 m
- [ ] 3.5 `Pm5ErgType` mit den Ski- und Bike-Werten aus der Concept2-Spezifikation (Werte gegen das aktuelle Dokument prüfen) und Auswertung von `0x0032` Byte 16 (D6); Unit-Tests für RowErg, SkiErg, BikeErg und unbekannte Werte
- [x] 3.6 Package-README: Abschnitt FTMS mit Byte-Layout von Rower Data, Control Point, eigener Uhr, Plausibilitätsgrenzen und der Erg-Typ-Tabelle; Fixtures-Tabelle ergänzt

## 4. Simulator und Test-Rower

- [x] 4.1 `SimulatedSource` mit `protocol`: im FTMS-Modus ein Rower-Data-Paket pro Sekunde über `FtmsEncoder` (D10); Tests in `simulated_source_test.dart` prüfen, dass Pace-Annäherung, Pause und Schlagzählung im FTMS-Modus funktionieren
- [x] 4.2 Auswahl PM5/FTMS in der Simulator-Bedienung (D10); Widget-Test in `simulator_controls_test.dart`, und ein End-to-End-Test rudert eine Vorlage mit einer Strecke mit eingebauter Zone mit dem Simulator im FTMS-Modus bis zur gespeicherten Session mit Runden und Zonenanteil
- [x] 4.3 `dart run erg_protocol:pm5_to_ftms` wandelt eine PM5-Aufnahme in eine FTMS-Aufnahme (D11); daraus `test/fixtures/ftms_just_row.jsonl` erzeugen und in einem Test prüfen, dass Distanz und Schlaganzahl von PM5- und FTMS-Dekodierung übereinstimmen (Distanz auf ±1 m)
- [x] 4.4 `tool/ftms_rower/ftms_rower.py` (bless, inline-Abhängigkeiten, `uv run`) als BlueZ-Peripheral mit Service `0x1826`, Service Data „Rower“, Rower Data und Control Point, das eine FTMS-Aufnahme zeitgetreu abspielt, sowie `make ftms-rower FILE=…` (D11); läuft auf dem Linux-PC und erscheint in `bluetoothctl` bzw. nRF Connect auf dem Handy als FTMS-Gerät
- [x] 4.5 README-Abschnitt zum Software-Rower: Voraussetzungen, Start, Test vom Android-Handy aus, Grenze „nicht vom selben Linux-Rechner“

## 5. Bluetooth-Transport

- [x] 5.1 `FoundPm5`/`Pm5Link`/`Pm5ConnectException` in `FoundRower` (mit `protocol`)/`RowerLink`/`RowerConnectException` umbenennen, `Pm5BleSource` in `BleRowerSource` (D5); bestehende Tests in `pm5_ble_source_test.dart` und `fake_ble_transport.dart` laufen angepasst
- [x] 5.2 Scan nach PM5 und FTMS: Keyword `PM5` und Service `0x1826`, eigene Filterung inklusive Ski-/Bike-Suffix und Rower-Bit in der Service Data, ein PM5 mit FTMS erscheint nur als PM5, Linux-`systemDevices` für beide Services (D5); Unit-Tests der Filterfunktion für alle Fälle
- [ ] 5.3 PM5-Connect prüft den Erg-Typ aus dem ersten `0x0032` innerhalb von 3 s und trennt bei SkiErg/BikeErg mit Hinweis (D6); Test mit Fake-Transport für SkiErg, BikeErg, RowErg und ausbleibendes Paket
- [ ] 5.4 FTMS-Connect: `0x2AD1` abonnieren, ohne `0x2AD1` trennen mit Hinweis „kein Rudergerät“, Control Point mit Request Control und Start/Resume, 2 s Timeout, Fehler ignorieren, nie Reset/Stop (D5, D7); Tests mit Fake-Transport für Gerät mit, ohne und mit ablehnendem Control Point und für bewusstes Trennen ohne Stop-Befehl
- [ ] 5.5 Geräteliste und Texte: Geräteart je Eintrag, Hinweise und Fehlermeldungen sprechen von Rudergeräten statt nur vom PM5, Hinweis „nur Rudergeräte“ beim Abweisen (Spec `erg-connection`); Tests in `device_list_screen_test.dart`
- [ ] 5.6 Reconnect und bewusstes Trennen für FTMS-Quellen (Spec `erg-connection`); Tests in `pm5_ble_source_test.dart` bzw. dessen Nachfolger mit Protokoll `ftms`

## 6. Spike

- [ ] 6.1 Spike sucht auch FTMS-Rower und schneidet `0x2AD1`, `0x2ADA` und Control-Point-Antworten mit `"protocol": "ftms"` im Header mit (D12); ein Mitschnitt des Software-Rowers lässt sich in der App importieren und abspielen
- [ ] 6.2 README-Abschnitt Spike um FTMS ergänzen

## 7. Verifikation und Dokumentation

- [ ] 7.1 Manuell am echten PM5 (Linux und Android): Suche, Verbinden, Session, Replay und Import alter Sessions funktionieren unverändert, alte Sessions sind nach dem Update vollständig
- [ ] 7.2 Manuell mit dem Software-Rower vom Android-Handy aus: Gerät erscheint als FTMS, Verbinden, Control Point, Live-Daten, Pause, Reset (Software-Rower neu starten), Abbruch und Reconnect, Session aufzeichnen, exportieren, auf Linux importieren und abspielen
- [ ] 7.3 Manuell eine Vorlage mit einer Strecke mit eingebauten Zonen mit dem Software-Rower rudern; Zonenanzeige, Bänder und Runden funktionieren
- [ ] 7.4 README: Projektbeschreibung (PM5 und FTMS-Rudergeräte), Verwendung, Plattform-Status mit Zeile „FTMS-Rudergeräte: nach Spezifikation umgesetzt, nur mit Software-Rower getestet, ungetestet an echter Hardware“, Dateiformat mit `protocol`
- [ ] 7.5 `make check` grün und `openspec validate device-types --strict` gültig

## Workflow follow-up

- Change archivieren, sobald die manuellen Tests abgeschlossen sind.
