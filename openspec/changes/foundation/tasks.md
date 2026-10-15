# Tasks

## 1. Setup

- [x] 1.1 Flutter-SDK (stable) auf Fedora installieren und `flutter doctor` für Linux-Desktop und Android grün bekommen. Verifikation: `flutter doctor` ohne Fehler für Linux und Android
- [x] 1.2 Git-Repo initialisieren, `.gitignore` für Flutter anlegen und das OpenSpec-Verzeichnis committen. Verifikation: `git log` zeigt den Initial-Commit
- [x] 1.3 Flutter-App `aergrow` im Repo-Root anlegen (Plattformen: android, ios, linux, macos) und Riverpod, drift, flutter_blue_plus, wakelock_plus hinzufügen. Verifikation: `flutter run -d linux` startet eine leere App
- [x] 1.4 Dart-Package `packages/pm5_protocol` anlegen und per `path:` einbinden. Verifikation: `dart test` im Package läuft (leerer Test grün)
- [x] 1.5 Linting (`flutter_lints`) und CI-freundliche Befehle (`flutter analyze`, `flutter test`, `dart test packages/pm5_protocol`) einrichten. Verifikation: alle drei Befehle laufen ohne Fehler

## 2. BLE-Spike am echten PM5

- [ ] 2.1 Minimalen Spike-Screen bauen: PM5 scannen, verbinden, Characteristics `0x0031`–`0x0036` abonnieren, Sample Rate auf 250 ms setzen und Rohpakete mit Zeitstempel in eine Datei schreiben. Verifikation: auf Android am PM5 läuft ein Log mit Paketen aller abonnierten Characteristics
- [x] 2.2 Aufnahmen erstellen: ca. 2 min Just Row, Rudern–Stopp–Pause (≥ 60 s)–Weiterrudern, sowie Workout-Reset am PM5. Ablage unter `packages/pm5_protocol/test/fixtures/`. Verifikation: drei Fixture-Dateien sind committed
- [x] 2.3 Byte-Layouts aus den Dumps gegen die PM5-Interface-Definition prüfen und Abweichungen in `packages/pm5_protocol/README.md` festhalten. Dabei auch das Verhalten der Elapsed Time bei Pause notieren (Open Question aus dem Design). Verifikation: README enthält die Layout-Tabelle und die Pausen-Beobachtung
- [x] 2.4 Den Spike auch unter Linux-Desktop ausführen und das Ergebnis (funktioniert / Probleme) im README festhalten. Verifikation: README-Eintrag zu Linux-BLE vorhanden

## 3. Protokoll-Package `pm5_protocol` (Capability rowing-telemetry)

- [x] 3.1 Modelle definieren: `RawPacket`, `RowingEvent` (`StatusTick`, `Stroke`, `WorkoutStateChanged`), Workout-Typ und Workout-Zustand als Enums. Verifikation: `dart analyze` ohne Fehler
- [x] 3.2 Decoder für `0x0031`, `0x0032`, `0x0033` zu `StatusTick` implementieren, inklusive HR „nicht vorhanden“. Verifikation: Unit-Tests gegen Spike-Fixtures prüfen konkrete Werte (Zeit, Distanz, Pace, Watt, SPM, HR, Kalorien)
- [x] 3.3 Decoder für `0x0035`/`0x0036` zu `Stroke` implementieren, mit genau einem Ereignis pro Schlag. Verifikation: Unit-Test zählt Schläge in einer Fixture und prüft fortlaufende Schlagnummern
- [x] 3.4 Workout-Zustandswechsel und PM5-Reset als `WorkoutStateChanged` erkennen. Verifikation: Unit-Test mit der Reset-Fixture meldet den Wechsel
- [x] 3.5 Multiplexed-Format (`0x0080`) im Decoder unterstützen. Verifikation: Unit-Test mit selbst gebauten Multiplexed-Paketen ergibt dieselben Events wie die Einzel-Characteristics
- [x] 3.6 Robustheit: unbekannte oder zu kurze Pakete werden verworfen und geloggt, ohne Exception. Verifikation: Unit-Tests mit kaputten Paketen
- [x] 3.7 `Pm5Encoder` implementieren (Events zu Bytes). Verifikation: Roundtrip-Tests encode→decode für alle Event-Typen
- [x] 3.8 Session-Offset-Akkumulator (Design D6) als reine Funktion implementieren. Verifikation: Unit-Tests für Start bei PM5 ≠ 0, Reset mitten in der Session und mehrfachen Reset

## 4. Datenquellen (Capabilities erg-connection, erg-simulation)

- [x] 4.1 Interface `ErgSource` (Stream von `RawPacket`, Verbindungszustand, Quelltyp) und den austauschbaren Riverpod-Provider der aktiven Quelle anlegen. Verifikation: Widget-Test wechselt die Quelle per Provider-Override
- [ ] 4.2 `Pm5BleSource`: Scan mit Filter auf PM5 und 15-s-Timeout, Verbinden, Subscriptions, Sample Rate setzen. Verifikation: manuell auf Android, PM5 erscheint in der Liste und liefert Pakete
- [ ] 4.3 Verbindungs-Zustandsautomat mit 30-s-Reconnect und bewusstem Trennen ohne Reconnect (Design D4). Logik testbar vom BLE-Plugin getrennt halten. Verifikation: Unit-Tests mit Fake-Transport für alle Übergänge, plus manueller Test „PM5 kurz aus der Reichweite tragen“
- [ ] 4.4 Bluetooth-Voraussetzungen prüfen (Adapter aus, Berechtigung verweigert), Android-12+-Permissions und iOS-`Info.plist` eintragen. Verifikation: manuell auf Android mit ausgeschaltetem Bluetooth und verweigerter Berechtigung, die Hinweise erscheinen
- [ ] 4.5 Fehlermeldung bei fehlgeschlagener Verbindung mit Hinweis auf „nur eine Verbindung“. Verifikation: manuell mit parallel verbundenem ErgData
- [ ] 4.6 `SimulatedSource` mit Ziel-Pace, Ziel-SPM, Pause/Fortsetzen, Schwankung und Seed (Design D9), die Bytes über `Pm5Encoder` erzeugt. Verifikation: Unit-Test mit festem Seed zeigt, dass sich die Pace nach Änderung innerhalb von ≤ 5 Schlägen dem Ziel nähert und während Pause keine Distanzzunahme stattfindet
- [ ] 4.7 `ReplaySource` aus gespeicherten Rohpaketen mit Geschwindigkeitsfaktor (1×, 10×). Verifikation: Unit-Test zeigt, dass Replay einer Fixture dieselben Events wie direktes Dekodieren ergibt und 10× die Laufzeit entsprechend verkürzt

## 5. Verbindungs-UI (Capability erg-connection, erg-simulation)

- [ ] 5.1 Startscreen mit Quellenwahl: „PM5 suchen“, „Simulator“, „Session abspielen“. Verifikation: Widget-Test zeigt alle drei Optionen
- [ ] 5.2 Geräteliste mit Suchzustand, Leerzustand und Tipps nach 15 s. Verifikation: Widget-Test mit Fake-Quelle für die Zustände „gefunden“, „keiner gefunden“ und „Bluetooth aus“
- [ ] 5.3 Permanenter Verbindungs- und Quellen-Indikator (inkl. deutlicher Kennzeichnung „Simulator“/„Replay“). Verifikation: Widget-Tests für alle Zustände und Quelltypen
- [ ] 5.4 Simulator-Steuerung (Ziel-Pace, Ziel-SPM, Pause). Verifikation: Widget-Test, bei dem eine Änderung der Steuerung den Simulator-Zielwert setzt

## 6. Live-Display (Capability live-display)

- [ ] 6.1 Formatierer für Pace (`2:05.3`), Zeit (`12:34` / `1:02:03`), Distanz, Watt, SPM. Verifikation: Unit-Tests inklusive Grenzfällen (0, > 1 h, keine Pace)
- [ ] 6.2 Live-Display-Layout mit Pace als grösstem Wert, responsiv für Hoch-/Querformat und Desktop-Fenster, HR nur wenn vorhanden. Verifikation: Golden- oder Widget-Tests für Handy hoch, Handy quer und Desktop; keine Overflow-Fehler
- [ ] 6.3 Veraltet-Markierung nach 3 s ohne Daten. Verifikation: Widget-Test mit Fake-Clock
- [ ] 6.4 Wakelock aktiv, solange Live-Display sichtbar und Quelle verbunden ist. Verifikation: manuell auf Android, Bildschirm bleibt bei > Display-Timeout an

## 7. Session-Aufzeichnung (Capability session-recording)

- [ ] 7.1 drift-Schema `sessions`, `samples`, `strokes`, `raw_packets` (Design D7) mit Migrationstest-Setup. Verifikation: Unit-Test gegen In-Memory-DB legt eine Session an und liest sie wieder
- [ ] 7.2 Recorder: Start/Stopp, session-relative Werte über den Offset-Akkumulator, gepufferte Batch-Writes alle 2 s, Zusammenfassung beim Beenden. Verifikation: Unit-Test mit Replay-Fixture und In-Memory-DB prüft Zusammenfassungswerte
- [ ] 7.3 Crash-Recovery: beim Start `recording` zu `incomplete` setzen und Zusammenfassung nachberechnen. Verifikation: Unit-Test simuliert einen Abbruch mitten in der Session
- [ ] 7.4 Session-Start/-Stopp-Bedienung im Live-Display und Zusammenfassungs-Screen nach dem Beenden. Verifikation: Widget-Test für den Ablauf Start, Ticks, Stopp, Zusammenfassung mit Simulator
- [ ] 7.5 Session-Liste (neueste zuerst) und Löschen mit Bestätigung. Verifikation: Widget-Test für Sortierung und Löschen
- [ ] 7.6 „Session abspielen“ aus der Liste mit `ReplaySource`. Verifikation: Widget-Test startet Replay und das Live-Display zeigt Werte, Kennzeichnung „Replay“
- [ ] 7.7 Export/Import `.aergrow` (Design D8) über den System-Teilen-Dialog bzw. Dateiauswahl. Verifikation: Unit-Test Export→Import-Roundtrip ergibt identische Zusammenfassung; manuell Handy→Laptop

## 8. Integration

- [ ] 8.1 Ende-zu-Ende am echten PM5 auf Android: verbinden, 5 min Session rudern, beenden, in Liste prüfen, abspielen. Verifikation: Werte der Zusammenfassung stimmen mit der PM5-Anzeige überein (±1 % Distanz)
- [ ] 8.2 Ende-zu-Ende auf Linux-Desktop mit Simulator und, falls Linux-BLE funktioniert, mit dem PM5. Verifikation: Session aufgezeichnet und abspielbar
- [ ] 8.3 iOS-Build und Test auf einem iPhone, sofern ein Mac verfügbar ist; sonst als offen im README vermerken. Verifikation: App verbindet sich auf iOS mit dem PM5 bzw. README-Vermerk
- [ ] 8.4 README im Repo-Root: Setup, Befehle, Projektstruktur, Plattform-Status. Verifikation: Setup-Schritte aus dem README funktionieren auf einem frischen Checkout

## Workflow follow-up

- Change nach Review und erfolgreicher Integration archivieren (`/opsx:archive`).
