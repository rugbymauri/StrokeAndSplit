# Tasks

Neue Texte nur über `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb` mit `@`-Beschreibung, danach `make l10n`; der generierte Code wird committet.

## 1. Android-Gerüst und Spike

- [x] 1.1 Gerüst nach D7: `connect-client` im App-Build, minSdk 26, `MainActivity` als `FlutterFragmentActivity`, Manifest mit Schreibberechtigungen, `<queries>`, Rationale-Intent und Activity-Alias; Kotlin-Kanal `ch.strokesplit/health_connect` zunächst mit `status`, `grantedPermissions`, `requestPermissions`, `openInstall` und `launchAction`. Verifikation: `make apk` und `make check` grün, Bluetooth-Verbindung und Dateiauswahl in der App unverändert (bestehende Tests); `build-apk` läuft in CI nur für Release-Tags und wird mit dem Probe-Release geprüft
- [ ] 1.2 (Nutzer, am Gerät) Spike: eine Debug-Schaltfläche schreibt eine Probe-Einheit `ROWING_MACHINE` mit zwei Runden, einem `PAUSE`- und zwei `ROWING_MACHINE`-Segmenten, Puls-, Leistungs- und Geschwindigkeitsserie, danach ein zweites Mal mit gleichen Ids. Verifikation: In Health Connect (Daten und Zugriff) eine Einheit mit allen Werten, keine doppelte; Ergebnis zu Segmenten in D3 nachgetragen, Debug-Schaltfläche wieder entfernt

## 2. Abbildung einer Session

- [x] 2.1 Modell `HealthWorkout` (Zeitraum, Titel, Distanz, Kalorien, Serien, Runden, Pausen, Segmente, `clientRecordId`-Basis) und reine Funktion `healthWorkoutOf` nach D3 in `lib/data/health/`. Verifikation: Unit-Tests für Wanduhr aus `wallMs` (Rückfall auf `tMs` liefert das Repository, Test in 2.2), Ende ohne `endedAt`, Runden über Pausen auf die Wanduhr umgerechnet, Puls 0 und fehlende Werte ausgelassen, Geschwindigkeit aus der Pace, ein Wert pro Sekunde, Teilung der Serien nach 10 min, keine Kalorien bei 0 oder ohne Wert, Segmente je nach Ergebnis von 1.2
- [x] 2.2 `SessionRepository.healthData(id)` liefert, was `healthWorkoutOf` braucht (Samples mit `wallMs`/`tMs`, Puls, Watt, Pace, Kalorien; Runden; Pausen). Verifikation: Repository-Test mit Samples mit und ohne Wanduhr, Runde und Pause sowie mit der aufgezeichneten Session `pause`

## 3. Schreiben und Status

- [x] 3.1 Schema 8 nach D6: `sessions.health_exported_at`, Migration `from7To8`, `make schema`, `make codegen`; `SessionRepository.markHealthExported`/`clearHealthExported`. Verifikation: generierter Migrationstest 7 → 8, Export/Import unverändert (bestehende Tests grün), importierte Session ohne Status
- [x] 3.2 Kanal-Methode `writeSession` in Kotlin nach D1/D2: eigene Records der Typen im Zeitraum löschen, alle Records in einem `insertRecords` mit `clientRecordId` und Version; Typen ohne Berechtigung auslassen; Fehler als `PlatformException` mit Code (`permission`, `unavailable`, `failed`). Dart-Schnittstelle `HealthPlatform` mit Kanal- und Fake-Umsetzung. Verifikation: Dart-Test der Serialisierung gegen einen gemockten MethodChannel; Schreiben am Gerät in 6.1
- [x] 3.3 `HealthExporter` (Riverpod) nach D4: `export(id)` baut, schreibt und markiert; Fehler hebt den Status auf und liefert den Grund; automatisch aus `SessionRecorder.stop()` für `pm5`/`ftms` bei eingeschalteter Übertragung. Verifikation: Unit-Tests mit Fake-Plattform: Übertragung nach dem Ende, keine bei Simulator, Replay oder ausgeschaltet, Fehler lässt die Session unmarkiert, fehlende Berechtigung als Grund, erneute Übertragung ersetzt (Fake zählt eine Einheit)

## 4. Einstellung und Bedienung

- [x] 4.1 Store `healthConnect` in `shared_preferences` mit Memory-Fake nach D5, Provider `healthExportAvailableProvider` (Android). Verifikation: Unit-Test, Einstellung überdauert ein neues Öffnen des Stores
- [ ] 4.2 Schaltfläche in der App-Leiste von „Sessions“ und Bottom-Sheet nach D5 (Schalter, Status, Health Connect öffnen, Installation anbieten, Datenschutz-Link); Texte in DE/EN. Verifikation: Widget-Tests: unter Linux keine Schaltfläche, Einschalten mit erteilter Berechtigung, verweigerte Berechtigung lässt aus, Health Connect fehlt mit Installationsangebot
- [ ] 4.3 „An Health Connect senden“ im Menü der Session-Liste und in der Zusammenfassung, Status „Übertragen am …“ bzw. „Nicht übertragen“ in der Zusammenfassung, Snackbar bei Erfolg und Fehler (mit Angebot, die Berechtigung neu zu erteilen). Verifikation: Widget-Tests mit Fake: Eintrag nur bei eingeschalteter Übertragung und nicht für Sessions aus Simulator oder Replay, Status vor und nach der Übertragung, Fehlermeldung
- [ ] 4.4 Datenschutz-Seite nach Spec „Datenschutz-Hinweis“, geöffnet beim Start mit `launchAction` und über `onNewIntent`. Verifikation: Widget-Test der Seite in DE/EN, Test mit gemocktem Kanal öffnet die Seite beim Start

## 5. Dokumentation

- [ ] 5.1 README-Abschnitt „Health Connect“ (Einschalten, was übertragen wird, Grenzen), Implementierungsplan nachführen, Play-Store-Erklärung unter „Offene Punkte“. Verifikation: Durchsicht

## 6. Gerätetest

- [ ] 6.1 (Nutzer) Am Android-Gerät: Übertragung einschalten, Vorlage am PM5 mit Gurt und einer Pause rudern, Einheit in Health Connect mit Distanz, Kalorien, Puls, Leistung, Geschwindigkeit, Runden und Pause prüfen; dieselbe Session nachträglich erneut senden (keine doppelte); Berechtigung entziehen und senden (Meldung); Datenschutz-Hinweis aus den Health-Connect-Berechtigungen öffnen; ansehen, ob Google Fit bzw. Google Health die Einheit zeigt. Verifikation: Rückmeldung des Nutzers

## Workflow follow-up

- Nach 6.1 archivieren und den Change im Implementierungsplan nach „Erledigt“ verschieben.
