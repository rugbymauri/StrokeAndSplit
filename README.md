# AergRow

Ruder-App für den Concept2-Ergometer mit PM5. Sie verbindet sich per Bluetooth mit dem PM5, zeigt die Werte live und zeichnet Sessions lokal auf. Läuft auf Android, iOS und dem Linux-Desktop. Ohne Erg funktioniert sie mit dem eingebauten Simulator.

Geplant ist Gamification im Sinne von „gegen sich selbst rudern“: Strecken mit Zonen, Ghost und Progression. Diese Grundlage (Change `foundation`) liefert Verbindung, Live-Display, Simulator, Aufzeichnung und Replay.

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

## Projektstruktur

```
lib/
  app/                 App-Rahmen und Plattformdienste (BLE, Wakelock, Dateien)
  data/
    sources/           Datenquellen: PM5 (BLE), Simulator, Replay
    db/                drift-Schema (SQLite)
    sessions/          Aufzeichnung, Zusammenfassung, Export/Import
  features/
    connection/        Startbildschirm, PM5-Suche, Verbindungsanzeige
    live/              Live-Display
    sessions/          Session-Liste und Zusammenfassung
    simulator/         Bedienung des Simulators
  spike/               BLE-Spike zum Mitschneiden von Rohpaketen
packages/pm5_protocol/ PM5-Protokoll als reines Dart-Package (Decoder, Encoder, Rohformat)
drift_schemas/         Schema-Snapshots für Migrationstests
openspec/              Anforderungen, Design und Tasks (OpenSpec)
```

Alle Quellen liefern rohe PM5-Pakete. Ein einziger Decoder in `pm5_protocol` macht daraus Messwerte. So laufen Simulator und Replay durch denselben Code wie der echte PM5. Die Byte-Layouts und Beobachtungen am echten PM5 stehen in [`packages/pm5_protocol/README.md`](packages/pm5_protocol/README.md).

## Dateiformat `.aergrow`

gzip-komprimiertes JSON Lines. Die erste Zeile ist ein Header mit Format, Quelle, Gerät, Startzeit und Zusammenfassung, danach folgt pro Rohpaket eine Zeile `{"t": ms, "c": "0031", "b": "<base64>"}`. Beim Import werden Messwerte und Zusammenfassung aus den Rohpaketen neu berechnet. Unkomprimierte Spike-Mitschnitte (`.jsonl`) lassen sich ebenfalls importieren.

## Spike

`make spike` startet eine Minimal-App, die sich mit dem PM5 verbindet und alle Pakete mit Zeitstempel als `pm5-<zeit>.jsonl` speichert. Unter Linux landen sie im Dokumente-Ordner des Benutzers (z.B. `~/Dokumente`), unter Android im externen App-Verzeichnis (`make pull-recordings`). Solche Mitschnitte dienen als Test-Fixtures in `packages/pm5_protocol/test/fixtures/`.

## Plattform-Status

| Plattform | Stand |
|---|---|
| Linux | Am echten PM5 verifiziert: Spike, Verbinden, Reconnect, Fehlermeldungen |
| Android | Gebaut und konfiguriert, Verifikation am PM5 steht aus |
| iOS | Konfiguriert (`Info.plist`), ungetestet, da kein Mac verfügbar |
| macOS | Konfiguriert (Entitlements), ungetestet |

## Lizenzhinweis

Die BLE-Bibliothek `flutter_blue_plus` 2.x ist für nicht-kommerzielle Nutzung frei (`License.nonprofit`). Für eine kommerzielle Nutzung ist eine Lizenz nötig oder ein Wechsel auf eine Alternative wie `universal_ble` (siehe Design D4 im Change `foundation`).
