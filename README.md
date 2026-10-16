# AergRow

Ruder-App für den Concept2-RowErg mit PM5 und für Rudergeräte mit dem Bluetooth-Standard FTMS (Fitness Machine Service). Sie verbindet sich per Bluetooth mit dem Rudergerät, zeigt die Werte live und zeichnet Sessions lokal auf. Läuft auf Android, iOS und dem Linux-Desktop. Ohne Rudergerät funktioniert sie mit dem eingebauten Simulator, der wahlweise wie ein PM5 oder wie ein FTMS-Rudergerät sendet. Ein PM5 am SkiErg oder BikeErg und FTMS-Geräte, die keine Rudergeräte sind, werden abgewiesen.

Die Gamification heisst hier „gegen sich selbst rudern“. Vorhanden sind Verbindung, Live-Display, Simulator, Aufzeichnung und Replay (Change `foundation`), Strecken mit Zonen und Runden (Changes `courses` und `zones`), FTMS-Rudergeräte (Change `device-types`) sowie Deutsch und Englisch (Change `translations`). Geplant sind Ghost und Progression.

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
| `make l10n` | Übersetzungen neu erzeugen, nach Änderungen an `lib/l10n/app_*.arb` |
| `make codegen` | drift-Code neu erzeugen, nach Änderungen an `lib/data/db/database.dart` |
| `make schema` | Schema-Snapshot und Migrationstests erzeugen, nach dem Erhöhen von `schemaVersion` |
| `make spike` / `make spike-android` | Minimal-App, die Rohpakete von PM5 und FTMS-Rudergeräten mitschneidet (siehe unten) |
| `make ftms-rower FILE=…` | Software-FTMS-Rudergerät, das eine Aufnahme über Bluetooth abspielt (siehe unten) |
| `make pull-recordings` | Mitschnitte vom Android-Gerät nach `./recordings` kopieren |
| `make build-linux` | Linux-Release-Bundle bauen |

## Verwendung

1. **Geräte wählen**: Am PM5 das Bluetooth-Menü öffnen (Verbinden) bzw. ein FTMS-Rudergerät einschalten. Die App sucht beim Start und listet die gefundenen Rudergeräte, jeweils mit dem Hinweis, ob es ein PM5 oder ein FTMS-Gerät ist, darunter **Simulator** und **Simulator (FTMS)**. Gerät wählen und **Weiter**. Viele Rudergeräte erlauben nur eine Bluetooth-Verbindung, ErgData oder andere Apps müssen also getrennt sein. Ein FTMS-Rudergerät fordert die App nach dem Verbinden zum Senden auf, setzt es aber nie zurück.
2. Die App merkt sich das Rudergerät. Beim nächsten Start sucht sie es bis zu 10 s, verbindet und überspringt „Geräte wählen“. Wird es nicht gefunden, erscheint „Geräte wählen“ mit diesem Gerät vorausgewählt. War es ein Simulator, geht es ohne Suche weiter.
3. **Startbildschirm**: Oben steht das gewählte Rudergerät, Antippen führt zurück zu „Geräte wählen“. **Rudern** öffnet die Vorlagen (siehe unten), **Frei rudern** das Live-Display ohne Vorlage. **Nochmal** zeigt die zuletzt geruderte Vorlage und öffnet sie aufgeklappt in den Vorlagen. Unter **Sessions** lassen sich Sessions abspielen, als `.aergrow` exportieren, importieren und löschen.
4. Beim freien Rudern im Live-Display **Session starten**. Zeit und Distanz zählen ab 0, auch wenn das Gerät schon etwas anzeigt, und laufen über Resets am Gerät hinweg weiter. Bei FTMS misst die App die Zeit selbst und hält sie an, sobald 4 s lang weder Distanz noch Schläge dazukommen. Schlagdetails wie Kraft und Zuglänge liefert nur der PM5.
5. **Session beenden** zeigt die Zusammenfassung mit Durchschnittswerten und, bei einer Vorlage, den Runden. **Fertig** trennt das Rudergerät und führt zum Startbildschirm, die nächste Session verbindet wieder.

Das Live-Display passt sich dem Platz an: Ist er breiter als hoch, gilt das Querformat, auch im breiten Laptop-Fenster. Die Kopfzeile zeigt den Namen der Vorlage bzw. „Frei rudern“ und davor die Verbindung als Punkt: grün verbunden, orange beim Verbinden oder Wiederverbinden (mit Text darunter), leerer Ring getrennt. Simulator und Replay sind rechts markiert, daneben trennt das Symbol die Verbindung, ebenso wie Zurück.

Wird die App während einer Session beendet, bleibt die Session bis kurz davor erhalten. Beim nächsten Start ist sie als unvollständig markiert.

### Zonen, Strecken und Vorlagen

**Rudern** führt zu „Vorlage rudern“ mit drei Tabs: **Vorlagen**, **Strecken** und **Zonen**. Zahlen wie Länge, Bänder, Startposition und Runden werden in allen Editoren mit zwei Ruderblatt-Tasten eingestellt, nicht getippt: Die Taste mit dem Pfeil nach oben gibt mehr, die mit dem Pfeil nach unten weniger. Gedrückt halten wiederholt den Schritt, nach etwa einer Sekunde schneller. Am Minimum oder Maximum ist die Taste gesperrt.

1. **Zonen** → **Zone anlegen**: Name, Achse (Distanz oder Zeit), feste Länge und mindestens ein Band, ein Pace-Band (z.B. 1:45–1:50) und/oder ein Schlagzahl-Band (z.B. 30–34). Die Liste zeigt die Zonen nach Achse und in wie vielen Strecken sie stecken.
2. **Strecken** → **Strecke anlegen**: Name, Achse (Distanz in Metern oder Zeit als m:ss) und Länge. Mit **Zone einbauen** eine Zone wählen und ihre Startposition einstellen. Zonen der anderen Achse sind ausgegraut. Die Vorschau zeigt, wo die Zone liegt, und lehnt sie ab, wenn sie über das Streckenende ragt oder eine andere Zone überschneidet. Dieselbe Zone darf mehrfach vorkommen. Was zwischen den Zonen liegt, ist frei. Mit **+** bei einem freien Abschnitt beginnt die neue Zone dort, eine eingebaute Zone lässt sich antippen und verschieben oder mit **×** entfernen. Im Balken über der Liste heisst grau frei und blau Zone, schnellere Pace-Bänder sind heller.
3. **Vorlagen** → **Vorlage anlegen** mit Name, Strecke und Runden, **Feste Anzahl** oder **Offen bis Stopp**.
4. Vorlage antippen klappt sie mit ihren Zonen und Bändern auf. **Starten** verbindet das gewählte Rudergerät und startet die Session sofort. Der Stift öffnet den Editor, dort lässt sich die Vorlage auch löschen.
5. Nach der letzten Runde endet die Session von selbst und die Zusammenfassung zeigt alle Runden mit dem Anteil in der Zone, die beste mit Stern. Bei offener Rundenzahl endet sie mit **Session beenden**, eine angefangene Runde ist dann unvollständig.

Im Live-Display mit Vorlage ist die Pace der grösste Wert. Darunter steht der Zonenstatus mit dem Band („In der Zone · 2:05–2:10“, sonst „Schneller“ bzw. „Langsamer“), die Schlagzahl-Karte zeigt ihr Band ebenso („Mehr Schläge“, „Weniger Schläge“). Blau heisst in der Zone, orange ausserhalb. Dazu kommen Kacheln für Rundenzeit, Watt, Puls (wenn das Rudergerät ihn liefert) und den Anteil in der Zone.

Um die Pace läuft ein Fortschrittsrahmen aus drei Spuren, jede beginnt oben in der Mitte und läuft im Uhrzeigersinn, an der Spitze sitzt ein Schiffchen:

| Spur | Zeigt | Legende, z.B. |
|---|---|---|
| aussen, weiss | die ganze Strecke über alle Runden, Kerben an den Rundengrenzen | „Gesamt 1 460 / 3 000 m“ |
| Mitte, grau | die aktuelle Runde, Kerben an den Abschnittsgrenzen | „Runde 2 / 3 · noch 540 m“ |
| innen, farbig | den aktuellen Abschnitt, blau bzw. orange nach dem Zonenstatus der Pace, grau, wenn er frei ist | „Tempo · noch 340 m“ bzw. „frei · noch 340 m“ |

Bei offener Rundenzahl fehlt die äussere Spur, die Legende zeigt dann „Runde 2“. Bei Zeitstrecken stehen statt Metern Zeiten.

Eine geänderte Zone gilt in allen Strecken, die sie enthalten. Passt sie danach in eine davon nicht mehr, wird die Änderung abgelehnt und der Editor nennt die Strecke. Eine gelöschte Zone macht ihre Stellen frei.

Runden laufen nach Wanduhr: Eine Pause kostet bei Distanzstrecken Zeit und bei Zeitstrecken Meter, auch wenn der PM5 seine Uhr anhält. Wird eine schon geruderte Strecke geändert, auch über eine ihrer Zonen, entsteht eine neue Version, alte Sessions behalten ihre.

### Bestenlisten

Die App führt Bestenlisten und zeigt jeweils die Plätze 1–3 mit Wert, Pace pro 500 m und Datum:

- **Vorlage**: ganze Sessions, in denen alle geplanten Runden vollständig gerudert wurden, gewertet nach der Summe der Runden. Eine Liste pro Streckenlänge und Rundenzahl. Die aufgeklappte Vorlage zeigt die Liste ihrer aktuellen Länge und Rundenzahl. Bei offener Rundenzahl gibt es keine.
- **Strecke**: jede vollständige Runde, egal mit welcher Vorlage. Hatte die Strecke verschiedene Längen, gibt es eine Liste pro Länge.
- **Zone**: jede Fahrt durch die Zone in einer vollständigen Runde, egal auf welcher Strecke, auch mehrere aus derselben Session. Eine Liste pro Zonenlänge.

Strecke oder Zone in ihrer Liste antippen öffnet die Detailansicht mit den Plätzen pro Länge, die aktuelle zuerst. Der Stift dort öffnet den Editor. Die Zusammenfassung markiert jede Runde und Zonenfahrt auf Platz 1–3 (z.B. „Platz 2“, „Sprint · Platz 1“) und ebenso die Session in der Liste ihrer Vorlage. Die Marken zeigen den aktuellen Stand, wird eine Runde später überholt, verschwindet ihre Marke.

Gewertet wird nach Wanduhr, Pausen zählen also mit, auch in der Pace: Distanzen nach der Zeit, Zeitstrecken und -zonen nach den Metern. Bei Gleichstand liegt der frühere Eintrag vorne. Es zählen nur Sessions, die auf diesem Gerät an einem PM5 oder FTMS-Rudergerät gerudert wurden, keine aus dem Simulator, aus einem Replay oder importierte. Gelöschte Sessions verschwinden aus den Listen. Wird eine Vorlage, Strecke oder Zone gelöscht, fällt ihre Liste weg, die Sessions bleiben.

### Sprache

Die App startet auf Deutsch. Das Sprach-Symbol oben rechts auf „Geräte wählen“ und dem Startbildschirm schaltet zwischen **Deutsch** und **English** um, also schon beim ersten Start. Die Wahl gilt sofort und bleibt über einen Neustart erhalten. Die Systemsprache spielt keine Rolle. Namen, die du selbst vergibst (Zonen, Strecken, Vorlagen), werden nicht übersetzt. Datum und Dezimalzeichen folgen der Sprache (`15.10.2026, 18:30` bzw. `Oct 15, 2026, 18:30`), Pace und Zeiten bleiben wie am PM5 (`2:05.3`).

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
  l10n/                Übersetzungen: app_de.arb (Vorlage), app_en.arb und der erzeugte Code
  features/
    connection/        Geräte wählen, Startbildschirm, Verbindungsanzeige
    courses/           Strecken-Liste und -Editor mit „Zone einbauen“
    zones/             Zonen-Liste und -Editor
    templates/         Vorlagen-Liste und -Editor
    live/              Live-Display mit Pace-Box und Fortschrittsrahmen
    sessions/          Session-Liste und Zusammenfassung
    simulator/         Bedienung des Simulators
  spike/               BLE-Spike zum Mitschneiden von Rohpaketen
packages/erg_protocol/ PM5-Protokoll als reines Dart-Package (Decoder, Encoder, Rohformat)
drift_schemas/         Schema-Snapshots für Migrationstests
openspec/              Anforderungen, Design und Tasks (OpenSpec)
```

Alle Quellen liefern rohe PM5-Pakete. Ein einziger Decoder in `erg_protocol` macht daraus Messwerte. So laufen Simulator und Replay durch denselben Code wie der echte PM5. Die Byte-Layouts und Beobachtungen am echten PM5 stehen in [`packages/erg_protocol/README.md`](packages/erg_protocol/README.md).

## Texte und Übersetzungen

Neue Texte der Oberfläche kommen nur über die ARB-Dateien in `lib/l10n/`, nie als Literal in den Code:

1. Den Key mit dem deutschen Text und einer `@`-Beschreibung in `app_de.arb` eintragen. Die Beschreibung ist Pflicht und sagt, wo der Text steht und was Platzhalter enthalten.
2. Denselben Key in `app_en.arb` übersetzen. Ein Test schlägt fehl, wenn einer Sprache ein Key fehlt oder sie einen zu viel hat.
3. `make l10n` erzeugt den Code neu, im Widget dann `context.l10n.<key>`. Der erzeugte Code wird eingecheckt.

Zahlen mit Mehrzahl über `plural`, Namen in Anführungszeichen stehen samt Zeichen in der ARB-Datei (`„{name}“` bzw. `“{name}”`). `lib/data/` liefert keine Sätze, sondern Codes, die `lib/features/` übersetzt. Ohne Übersetzung bleiben Einheiten (`m`, `spm`), Formate wie Pace und Zeiten und Eigennamen (PM5, FTMS, Concept2, ErgData). Eine weitere Sprache braucht eine weitere `app_<code>.arb`, einen Eintrag in `AppLanguage` und das Datumsmuster `dateTimePattern`. Deutsch folgt der Schweizer Rechtschreibung (`ss` statt `ß`).

## Dateiformat `.aergrow`

gzip-komprimiertes JSON Lines. Die erste Zeile ist ein Header mit Format, Quelle, Protokoll, Gerät, Startzeit und Zusammenfassung, danach folgt pro Rohpaket eine Zeile `{"t": ms, "c": "0031", "b": "<base64>"}`. `protocol` ist `pm5` oder `ftms` und bestimmt, wie die Rohpakete dekodiert werden (`c` ist bei FTMS z.B. `2ad1`). Dateien von vor FTMS haben kein `protocol` und gelten als PM5. Die Zeit `t` ist die Wanduhr seit dem ersten Paket. Beim Import werden Messwerte und Zusammenfassung aus den Rohpaketen neu berechnet. Unkomprimierte Spike-Mitschnitte (`.jsonl`) lassen sich ebenfalls importieren.

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
| FTMS-Rudergeräte | Nach Spezifikation umgesetzt, nur mit Software-Rower getestet, ungetestet an echter Hardware |
| iOS | Konfiguriert (`Info.plist`), ungetestet, da kein Mac verfügbar |
| macOS | Konfiguriert (Entitlements), ungetestet |

## Lizenzhinweis

Die BLE-Bibliothek `flutter_blue_plus` 2.x ist für nicht-kommerzielle Nutzung frei (`License.nonprofit`). Für eine kommerzielle Nutzung ist eine Lizenz nötig oder ein Wechsel auf eine Alternative wie `universal_ble` (siehe Design D4 im Change `foundation`).
