# AergRow

Ruder-App für den Concept2-Ergometer mit PM5. Sie verbindet sich per Bluetooth mit dem PM5, zeigt die Werte live und zeichnet Sessions lokal auf. Läuft auf Android, iOS und dem Linux-Desktop. Ohne Erg funktioniert sie mit dem eingebauten Simulator.

Die Gamification heisst hier „gegen sich selbst rudern“. Vorhanden sind Verbindung, Live-Display, Simulator, Aufzeichnung und Replay (Change `foundation`) sowie Strecken mit Zonen und Runden (Change `courses`). Geplant sind Ghost und Progression.

## Setup

Voraussetzungen:

- Flutter (stable), z.B. nach `~/dev/flutter` geklont. Das Makefile findet es dort auch ohne `PATH`-Eintrag.
- Für Android: Android Studio mit SDK, cmdline-tools und akzeptierten Lizenzen.
- Für Linux: `clang`, `cmake`, `ninja`, GTK-Entwicklungspakete und BlueZ.
- Für iOS/macOS: ein Mac mit Xcode.

```sh
make doctor   # Flutter-Installation prüfen
make deps     # Abhängigkeiten holen
make check    # Analyse und alle Tests
make run      # App auf dem Linux-Desktop starten
```

Alle Befehle zeigt `make help`.

| Befehl | Zweck |
|---|---|
| `make run` / `make run-android` | App auf Linux bzw. einem per USB verbundenen Android-Gerät starten |
| `make check` | Statische Analyse und Tests von App und `pm5_protocol` |
| `make codegen` | drift-Code neu erzeugen, nach Änderungen an `lib/data/db/database.dart` |
| `make schema` | Schema-Snapshot und Migrationstests erzeugen, nach dem Erhöhen von `schemaVersion` |
| `make spike` / `make spike-android` | Minimal-App, die PM5-Rohpakete mitschneidet (siehe unten) |
| `make pull-recordings` | Mitschnitte vom Android-Gerät nach `./recordings` kopieren |
| `make build-linux` | Linux-Release-Bundle bauen |

## Verwendung

1. **PM5 suchen**: Am PM5 das Bluetooth-Menü öffnen (Verbinden), dann in der App den PM5 wählen. Der PM5 erlaubt nur eine Bluetooth-Verbindung, ErgData oder andere Apps müssen also getrennt sein.
2. Im Live-Display **Session starten**. Zeit und Distanz zählen ab 0, auch wenn der PM5 schon etwas anzeigt, und laufen über Resets am PM5 hinweg weiter.
3. **Session beenden** zeigt die Zusammenfassung. Unter **Sessions** auf dem Startbildschirm lassen sich Sessions abspielen, als `.aergrow` exportieren, importieren und löschen.

Wird die App während einer Session beendet, bleibt die Session bis kurz davor erhalten. Beim nächsten Start ist sie als unvollständig markiert.

### Strecken und Vorlagen

1. **Vorlage rudern** auf dem Startbildschirm öffnen, dann oben rechts **Strecken**.
2. **Strecke anlegen**: Name, Achse (Distanz in Metern oder Zeit als m:ss) und Länge. Mit **Segment teilen** und **Mit nächstem zusammenlegen** wird die Strecke unterteilt, die Längen der Segmente lassen sich direkt eingeben. Pro Segment sind ein Pace-Band (z.B. 2:05–2:10) und ein Schlagzahl-Band (z.B. 20–22) möglich. Ein Segment ohne Band ist frei.
3. Zurück in **Vorlage rudern**: **Vorlage anlegen** mit Name, Strecke und Rundenzahl, fest oder offen.
4. Vorlage antippen und die Quelle wählen (PM5 oder Simulator). Sobald die Quelle verbunden ist, startet die Session. Über den Werten stehen Runde, Segment, Rest bis zum Segmentende, die Bänder und der Anteil in der Zone. Pace und Schlagzahl werden grün, wenn sie im Band liegen, und zeigen sonst die Richtung („schneller“, „mehr Schläge“).
5. Nach der letzten Runde endet die Session von selbst und die Zusammenfassung zeigt alle Runden mit der besten hervorgehoben. Bei offener Rundenzahl endet sie mit **Session beenden**, eine angefangene Runde ist dann unvollständig.

Runden laufen nach Wanduhr: Eine Pause kostet bei Distanzstrecken Zeit und bei Zeitstrecken Meter, auch wenn der PM5 seine Uhr anhält. Wird eine schon geruderte Strecke geändert, entsteht eine neue Version, alte Sessions behalten ihre.

## Projektstruktur

```
lib/
  app/                 App-Rahmen und Plattformdienste (BLE, Wakelock, Dateien)
  data/
    sources/           Datenquellen: PM5 (BLE), Simulator, Replay
    db/                drift-Schema (SQLite)
    courses/           Strecken, Versionen und Runden-Logik (LapTracker)
    templates/         Vorlagen aus Strecke und Rundenzahl
    sessions/          Aufzeichnung, Zusammenfassung, Export/Import
  features/
    connection/        Startbildschirm, PM5-Suche, Verbindungsanzeige
    courses/           Strecken-Liste und -Editor
    templates/         Vorlagen-Liste und -Editor
    live/              Live-Display mit Streckenleiste
    sessions/          Session-Liste und Zusammenfassung
    simulator/         Bedienung des Simulators
  spike/               BLE-Spike zum Mitschneiden von Rohpaketen
packages/pm5_protocol/ PM5-Protokoll als reines Dart-Package (Decoder, Encoder, Rohformat)
drift_schemas/         Schema-Snapshots für Migrationstests
openspec/              Anforderungen, Design und Tasks (OpenSpec)
```

Alle Quellen liefern rohe PM5-Pakete. Ein einziger Decoder in `pm5_protocol` macht daraus Messwerte. So laufen Simulator und Replay durch denselben Code wie der echte PM5. Die Byte-Layouts und Beobachtungen am echten PM5 stehen in [`packages/pm5_protocol/README.md`](packages/pm5_protocol/README.md).

## Dateiformat `.aergrow`

gzip-komprimiertes JSON Lines. Die erste Zeile ist ein Header mit Format, Quelle, Gerät, Startzeit und Zusammenfassung, danach folgt pro Rohpaket eine Zeile `{"t": ms, "c": "0031", "b": "<base64>"}`. Die Zeit `t` ist die Wanduhr seit dem ersten Paket. Beim Import werden Messwerte und Zusammenfassung aus den Rohpaketen neu berechnet. Unkomprimierte Spike-Mitschnitte (`.jsonl`) lassen sich ebenfalls importieren.

Eine Session auf einer Vorlage hat im Header zusätzlich die Vorlage und die geruderte Version der Strecke:

```json
"template": {"name": "Seerunde x3", "laps": 3},
"course": {"name": "Seerunde", "axis": "distance", "length": 1000,
           "segments": [{"length": 200}, {"length": 600, "paceFastCs": 12500, "paceSlowCs": 13000,
                         "spmMin": 20, "spmMax": 22}, {"length": 200}]}
```

Beim Import wird eine Strecke mit gleichem Namen und gleicher Definition wiederverwendet, sonst angelegt. Die Runden entstehen aus den Rohpaketen neu und sind deshalb identisch. `laps` ist `null` bei offener Rundenzahl, `length` ist in Metern bzw. Sekunden.

## Spike

`make spike` startet eine Minimal-App, die sich mit dem PM5 verbindet und alle Pakete mit Zeitstempel als `pm5-<zeit>.jsonl` speichert. Unter Linux landen sie im Dokumente-Ordner des Benutzers (z.B. `~/Dokumente`), unter Android im externen App-Verzeichnis (`make pull-recordings`). Solche Mitschnitte dienen als Test-Fixtures in `packages/pm5_protocol/test/fixtures/`.

## Plattform-Status

| Plattform | Stand |
|---|---|
| Linux | Am echten PM5 verifiziert: Spike, Verbinden, Reconnect, Fehlermeldungen, Aufzeichnung, Replay, Import |
| Android | Am echten PM5 verifiziert (Pixel 8 Pro, Android 17): Spike, Verbinden, Bluetooth-Hinweise, Aufzeichnung (Distanz und Zeit exakt wie am PM5), Replay, Export, Bildschirm bleibt an |
| iOS | Konfiguriert (`Info.plist`), ungetestet, da kein Mac verfügbar |
| macOS | Konfiguriert (Entitlements), ungetestet |

## Lizenzhinweis

Die BLE-Bibliothek `flutter_blue_plus` 2.x ist für nicht-kommerzielle Nutzung frei (`License.nonprofit`). Für eine kommerzielle Nutzung ist eine Lizenz nötig oder ein Wechsel auf eine Alternative wie `universal_ble` (siehe Design D4 im Change `foundation`).
