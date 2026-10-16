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
| `make check` | Statische Analyse und Tests von App und `erg_protocol` |
| `make codegen` | drift-Code neu erzeugen, nach Änderungen an `lib/data/db/database.dart` |
| `make schema` | Schema-Snapshot und Migrationstests erzeugen, nach dem Erhöhen von `schemaVersion` |
| `make spike` / `make spike-android` | Minimal-App, die Rohpakete von PM5 und FTMS-Rudergeräten mitschneidet (siehe unten) |
| `make ftms-rower FILE=…` | Software-FTMS-Rudergerät, das eine Aufnahme über Bluetooth abspielt (siehe unten) |
| `make pull-recordings` | Mitschnitte vom Android-Gerät nach `./recordings` kopieren |
| `make build-linux` | Linux-Release-Bundle bauen |

## Verwendung

1. **PM5 suchen**: Am PM5 das Bluetooth-Menü öffnen (Verbinden), dann in der App den PM5 wählen. Der PM5 erlaubt nur eine Bluetooth-Verbindung, ErgData oder andere Apps müssen also getrennt sein.
2. Im Live-Display **Session starten**. Zeit und Distanz zählen ab 0, auch wenn der PM5 schon etwas anzeigt, und laufen über Resets am PM5 hinweg weiter.
3. **Session beenden** zeigt die Zusammenfassung. Unter **Sessions** auf dem Startbildschirm lassen sich Sessions abspielen, als `.aergrow` exportieren, importieren und löschen.

Wird die App während einer Session beendet, bleibt die Session bis kurz davor erhalten. Beim nächsten Start ist sie als unvollständig markiert.

### Zonen, Strecken und Vorlagen

**Vorlage rudern** auf dem Startbildschirm hat drei Tabs: **Vorlagen**, **Strecken** und **Zonen**.

1. **Zonen** → **Zone anlegen**: Name, Achse (Distanz oder Zeit), feste Länge und mindestens ein Band, ein Pace-Band (z.B. 1:45–1:50) und/oder ein Schlagzahl-Band (z.B. 30–34). Die Liste zeigt die Zonen nach Achse und in wie vielen Strecken sie stecken.
2. **Strecken** → **Strecke anlegen**: Name, Achse (Distanz in Metern oder Zeit als m:ss) und Länge. Mit **Zone einbauen** eine Zone wählen und ihre Startposition eingeben. Zonen der anderen Achse sind ausgegraut. Die Vorschau zeigt, wo die Zone liegt, und lehnt sie ab, wenn sie über das Streckenende ragt oder eine andere Zone überschneidet. Dieselbe Zone darf mehrfach vorkommen. Was zwischen den Zonen liegt, ist frei. Mit **+** bei einem freien Abschnitt beginnt die neue Zone dort, eine eingebaute Zone lässt sich antippen und verschieben oder mit **×** entfernen.
3. **Vorlagen** → **Vorlage anlegen** mit Name, Strecke und Rundenzahl, fest oder offen.
4. Vorlage antippen und die Quelle wählen (PM5 oder Simulator). Sobald die Quelle verbunden ist, startet die Session. Über den Werten stehen die Runde, die aktuelle Zone bzw. „frei“, der Rest bis zum Abschnittsende, die Bänder und der Anteil in der Zone. Pace und Schlagzahl werden grün, wenn sie im Band liegen, und zeigen sonst die Richtung („schneller“, „mehr Schläge“).
5. Nach der letzten Runde endet die Session von selbst und die Zusammenfassung zeigt alle Runden mit der besten hervorgehoben. Bei offener Rundenzahl endet sie mit **Session beenden**, eine angefangene Runde ist dann unvollständig.

Eine geänderte Zone gilt in allen Strecken, die sie enthalten. Passt sie danach in eine davon nicht mehr, wird die Änderung abgelehnt und der Editor nennt die Strecke. Eine gelöschte Zone macht ihre Stellen frei.

Runden laufen nach Wanduhr: Eine Pause kostet bei Distanzstrecken Zeit und bei Zeitstrecken Meter, auch wenn der PM5 seine Uhr anhält. Wird eine schon geruderte Strecke geändert, auch über eine ihrer Zonen, entsteht eine neue Version, alte Sessions behalten ihre.

## Projektstruktur

```
lib/
  app/                 App-Rahmen und Plattformdienste (BLE, Wakelock, Dateien)
  data/
    sources/           Datenquellen: PM5 (BLE), Simulator, Replay
    db/                drift-Schema (SQLite)
    courses/           Strecken, Versionen, Aufbau aus Zonen und Runden-Logik (LapTracker)
    zones/             Wiederverwendbare Zonen
    templates/         Vorlagen aus Strecke und Rundenzahl
    sessions/          Aufzeichnung, Zusammenfassung, Export/Import
  features/
    connection/        Startbildschirm, PM5-Suche, Verbindungsanzeige
    courses/           Strecken-Liste und -Editor mit „Zone einbauen“
    zones/             Zonen-Liste und -Editor
    templates/         Vorlagen-Liste und -Editor
    live/              Live-Display mit Streckenleiste
    sessions/          Session-Liste und Zusammenfassung
    simulator/         Bedienung des Simulators
  spike/               BLE-Spike zum Mitschneiden von Rohpaketen
packages/erg_protocol/ PM5-Protokoll als reines Dart-Package (Decoder, Encoder, Rohformat)
drift_schemas/         Schema-Snapshots für Migrationstests
openspec/              Anforderungen, Design und Tasks (OpenSpec)
```

Alle Quellen liefern rohe PM5-Pakete. Ein einziger Decoder in `erg_protocol` macht daraus Messwerte. So laufen Simulator und Replay durch denselben Code wie der echte PM5. Die Byte-Layouts und Beobachtungen am echten PM5 stehen in [`packages/erg_protocol/README.md`](packages/erg_protocol/README.md).

## Dateiformat `.aergrow`

gzip-komprimiertes JSON Lines. Die erste Zeile ist ein Header mit Format, Quelle, Gerät, Startzeit und Zusammenfassung, danach folgt pro Rohpaket eine Zeile `{"t": ms, "c": "0031", "b": "<base64>"}`. Die Zeit `t` ist die Wanduhr seit dem ersten Paket. Beim Import werden Messwerte und Zusammenfassung aus den Rohpaketen neu berechnet. Unkomprimierte Spike-Mitschnitte (`.jsonl`) lassen sich ebenfalls importieren.

Eine Session auf einer Vorlage hat im Header zusätzlich die Vorlage und die geruderte Version der Strecke:

```json
"template": {"name": "Seerunde x3", "laps": 3},
"course": {"name": "Seerunde", "axis": "distance", "length": 1000,
           "segments": [{"length": 200},
                        {"length": 600, "paceFastCs": 12500, "paceSlowCs": 13000, "spmMin": 20, "spmMax": 22,
                         "zone": {"name": "Tempo", "axis": "distance", "length": 600, "paceFastCs": 12500,
                                  "paceSlowCs": 13000, "spmMin": 20, "spmMax": 22}},
                        {"length": 200}]}
```

Beim Import wird eine Strecke mit gleichem Namen und gleichem Ablauf wiederverwendet, sonst angelegt. Fehlende Zonen legt der Import an, eine Zone mit gleichem Namen und gleichen Bändern wird wiederverwendet. Dateien von vor den Zonen haben kein `zone`, ihre Segmente mit Band werden zu Zonen nach dem Muster „Seerunde 2“. Die Runden entstehen aus den Rohpaketen neu und sind deshalb identisch. `laps` ist `null` bei offener Rundenzahl, `length` ist in Metern bzw. Sekunden.

## Spike

`make spike` startet eine Minimal-App, die sich mit einem PM5 oder einem FTMS-Rudergerät verbindet und alle Pakete mit Zeitstempel als `pm5-<zeit>.jsonl` bzw. `ftms-<zeit>.jsonl` speichert. Unter Linux landen sie im Dokumente-Ordner des Benutzers (z.B. `~/Dokumente`), unter Android im externen App-Verzeichnis (`make pull-recordings`). Solche Mitschnitte dienen als Test-Fixtures in `packages/erg_protocol/test/fixtures/` und lassen sich in der App importieren und abspielen.

Bei einem FTMS-Gerät liest der Spike die Fitness Machine Features (als Marker im Mitschnitt), schneidet Rower Data (`2ad1`), Machine Status (`2ada`) und die Antworten am Control Point (`2ad9`) mit und sendet wie die App Request Control und Start/Resume. Der Header trägt `"protocol": "ftms"`. Wer ein echtes FTMS-Rudergerät hat, liefert so direkt brauchbare Fixtures.

## Software-Rower

Ohne echtes FTMS-Rudergerät lässt sich die FTMS-Anbindung mit einem Software-Rower testen. Er läuft auf dem Linux-PC, meldet sich als `AergRow FTMS Rower` mit dem Fitness Machine Service `0x1826` und spielt eine FTMS-Aufnahme zeitgetreu als Rower-Data-Notifications ab.

Voraussetzungen: BlueZ mit eingeschaltetem Adapter und [`uv`](https://docs.astral.sh/uv/). Die Python-Abhängigkeit (`bless`) holt `uv` beim ersten Start selbst.

```sh
# PM5-Aufnahme in eine FTMS-Aufnahme umrechnen (.jsonl oder .aergrow)
cd packages/erg_protocol && dart run erg_protocol:pm5_to_ftms test/fixtures/just_row.jsonl /tmp/ftms.jsonl
# Software-Rower starten, ARGS=--loop spielt die Aufnahme endlos
make ftms-rower FILE=packages/erg_protocol/test/fixtures/ftms_just_row.jsonl
```

Getestet wird vom **Android-Handy** aus: `make run-android`, in der Geräteliste erscheint der Software-Rower als FTMS-Rudergerät. Zur Kontrolle zeigt ihn auch nRF Connect mit dem Service `0x1826`. Nach dem Verbinden bestätigt er Request Control und Start/Resume am Control Point und beginnt abzuspielen; ohne Start-Befehl beginnt er 2 s nach dem Verbinden. Einen Reset simuliert man, indem man den Software-Rower neu startet.

Vom selben Linux-Rechner aus geht es nicht: Der Bluetooth-Adapter kann nicht gleichzeitig Peripheral für den Software-Rower und Central für die App sein. Wer ein zweites Linux-Gerät hat, kann die App dort starten.

## Plattform-Status

| Plattform | Stand |
|---|---|
| Linux | Am echten PM5 verifiziert: Spike, Verbinden, Reconnect, Fehlermeldungen, Aufzeichnung, Replay, Import |
| Android | Am echten PM5 verifiziert (Pixel 8 Pro, Android 17): Spike, Verbinden, Bluetooth-Hinweise, Aufzeichnung (Distanz und Zeit exakt wie am PM5), Replay, Export, Bildschirm bleibt an |
| iOS | Konfiguriert (`Info.plist`), ungetestet, da kein Mac verfügbar |
| macOS | Konfiguriert (Entitlements), ungetestet |

## Lizenzhinweis

Die BLE-Bibliothek `flutter_blue_plus` 2.x ist für nicht-kommerzielle Nutzung frei (`License.nonprofit`). Für eine kommerzielle Nutzung ist eine Lizenz nötig oder ein Wechsel auf eine Alternative wie `universal_ble` (siehe Design D4 im Change `foundation`).
