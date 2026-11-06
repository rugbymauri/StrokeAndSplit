# Stroke & Split

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
| `make coverage` | Tests mit Coverage, zeigt die Zeilenabdeckung je Paket; lcov-Dateien in `coverage/` und `packages/erg_protocol/coverage/` |
| `make l10n` | Übersetzungen neu erzeugen, nach Änderungen an `lib/l10n/app_*.arb` |
| `make codegen` | drift-Code neu erzeugen, nach Änderungen an `lib/data/db/database.dart` |
| `make schema` | Schema-Snapshot und Migrationstests erzeugen, nach dem Erhöhen von `schemaVersion` |
| `make check-generated` | Alles Generierte neu erzeugen und prüfen, dass es mit den eingecheckten Dateien übereinstimmt (wie in CI, braucht ein sauberes Arbeitsverzeichnis) |
| `make spike` / `make spike-android` | Minimal-App, die Rohpakete von PM5 und FTMS-Rudergeräten mitschneidet (siehe unten) |
| `make ftms-rower FILE=…` | Software-FTMS-Rudergerät, das eine Aufnahme über Bluetooth abspielt (siehe unten) |
| `make pull-recordings` | Mitschnitte vom Android-Gerät nach `./recordings` kopieren |
| `make build-linux` | Linux-Release-Bundle bauen |
| `make apk` | Universal-APK für Android bauen, Version optional mit `BUILD_NAME=1.2.0 BUILD_NUMBER=42` |
| `make install-apk` | Universal-APK bauen und auf dem per USB verbundenen Android-Gerät installieren; `APK=datei.apk` installiert stattdessen eine geladene APK |
| `make appimage` | Linux-Bundle nach `make build-linux` als AppImage nach `build/appimage/` packen |

## Verwendung

1. **Geräte wählen**: Am PM5 das Bluetooth-Menü öffnen (Verbinden) bzw. ein FTMS-Rudergerät einschalten. Die App sucht beim Start und listet die gefundenen Rudergeräte, jeweils mit dem Hinweis, ob es ein PM5 oder ein FTMS-Gerät ist, darunter **Simulator** und **Simulator (FTMS)**. Gerät wählen und **Weiter**. Viele Rudergeräte erlauben nur eine Bluetooth-Verbindung, ErgData oder andere Apps müssen also getrennt sein. Ein FTMS-Rudergerät fordert die App nach dem Verbinden zum Senden auf, setzt es aber nie zurück.
2. Die App merkt sich das Rudergerät. Beim nächsten Start sucht sie es bis zu 10 s, verbindet und überspringt „Geräte wählen“. Wird es nicht gefunden, erscheint „Geräte wählen“ mit diesem Gerät vorausgewählt. War es ein Simulator, geht es ohne Suche weiter.
3. **Startbildschirm**: Oben steht das gewählte Rudergerät, Antippen führt zurück zu „Geräte wählen“. Ist es verbunden, steht darunter „Verbunden“, und **Trennen** beendet die Verbindung, etwa damit ErgData das Gerät übernehmen kann. Ein anderes Gerät in „Geräte wählen“ trennt das bisherige ebenfalls. **Rudern** öffnet die Vorlagen (siehe unten), **Frei rudern** das Live-Display ohne Vorlage, beide nutzen eine bestehende Verbindung oder verbinden neu. Unter **Sessions** lassen sich Sessions abspielen, als `.strokesplit` exportieren, importieren und löschen.
4. Beim freien Rudern im Live-Display **Session starten**. Zeit und Distanz zählen ab 0, auch wenn das Gerät schon etwas anzeigt, und laufen über Resets am Gerät hinweg weiter. Bei FTMS misst die App die Zeit selbst und hält sie an, sobald 4 s lang weder Distanz noch Schläge dazukommen. Schlagdetails wie Kraft und Zuglänge liefert nur der PM5. Die Watt übernimmt die App vom FTMS-Rudergerät, damit sie mit seinem Display übereinstimmen; meldet es keine, rechnet sie sie wie beim PM5 aus der Pace aus. Meldet ein FTMS-Rudergerät seine Widerstandsstufe (z.B. der Domyos Woodrower), steht sie klein unter den Watt („Stufe 7“), auch beim Rudern einer Vorlage. Der Simulator (FTMS) meldet Stufe 5.

   Lässt sich die Stufe über Bluetooth setzen (Woodrower: Stufe 1–15), stehen Ruderblatt-Tasten neben der Stufe: hoch erhöht, runter senkt um eine Stufe. Mehrere schnelle Tipps zählen zusammen. Angezeigt wird immer die Stufe, die das Gerät meldet; lehnt es ab, steht kurz „Stufe nicht gesetzt“. Beim Rudern einer Vorlage setzt die App zu Beginn jeder Zone mit Stufe diese Stufe, in freien Abschnitten und Zonen ohne Stufe die Grundstufe, also die Stufe beim Start der Session. Wer mitten in einem Abschnitt die Stufe ändert, über die Tasten oder am Gerät, behält sie bis zum nächsten Abschnitt; in einem Abschnitt ohne Stufe wird sie zur neuen Grundstufe. Das gilt auch für eine Änderung in einer Pause. Nach einem Verbindungsabbruch sendet die App die geltende Stufe erneut. Gesendet wird „Set Target Resistance Level“ als ein Byte in Zehnteln, wie FTMS 1.0 und der Woodrower es verlangen; meldet ein Gerät „ungültiger Wert“, versucht es die App einmal mit 16 Bit. Der Simulator (FTMS) nimmt Stufen 1–15 an.
5. **Session beenden** zeigt die Zusammenfassung mit Durchschnittswerten und, bei einer Vorlage, den Runden. **Fertig** führt zum Startbildschirm, das Rudergerät bleibt verbunden.

Das Live-Display passt sich dem Platz an: Ist er breiter als hoch, gilt das Querformat, auch im breiten Laptop-Fenster. Die Kopfzeile zeigt den Namen der Vorlage bzw. „Frei rudern“ und davor die Verbindung als Punkt: grün verbunden, orange beim Verbinden oder Wiederverbinden (mit Text darunter), leerer Ring getrennt. Simulator und Replay sind rechts markiert. Zurück, auf dem Desktop auch Esc, führt zum Startbildschirm, ohne zu trennen; eine laufende Session wird dabei gespeichert, eine noch nicht begonnene Vorlage verworfen. Ein Replay endet mit Zurück und führt zu den Sessions.

Wird die App während einer Session beendet, bleibt die Session bis kurz davor erhalten. Beim nächsten Start ist sie als unvollständig markiert.

### Zonen, Strecken und Vorlagen

**Rudern** führt zu „Vorlage rudern“ mit drei Tabs: **Vorlagen**, **Strecken** und **Zonen**. Zahlen wie Länge, Bänder, Startposition und Runden werden in allen Editoren mit zwei Ruderblatt-Tasten eingestellt, nicht getippt: Die Taste mit dem Pfeil nach oben gibt mehr, die mit dem Pfeil nach unten weniger. Gedrückt halten wiederholt den Schritt, nach etwa einer Sekunde schneller. Am Minimum oder Maximum ist die Taste gesperrt.

1. **Zonen** → **Zone anlegen**: Name, Achse (Distanz oder Zeit), feste Länge und mindestens ein Band, ein Pace-Band (z.B. 1:45–1:50) und/oder ein Schlagzahl-Band (z.B. 30–34). Die Liste zeigt die Zonen nach Achse und in wie vielen Strecken sie stecken.
2. **Strecken** → **Strecke anlegen**: Name, Achse (Distanz in Metern oder Zeit als m:ss) und Länge. Mit **Zone einbauen** eine Zone wählen und ihre Startposition einstellen. Zonen der anderen Achse sind ausgegraut. Die Vorschau zeigt, wo die Zone liegt, und lehnt sie ab, wenn sie über das Streckenende ragt oder eine andere Zone überschneidet. Dieselbe Zone darf mehrfach vorkommen. Was zwischen den Zonen liegt, ist frei. Mit **+** bei einem freien Abschnitt beginnt die neue Zone dort, eine eingebaute Zone lässt sich antippen und verschieben oder mit **×** entfernen. Im Balken über der Liste heisst grau frei und blau Zone, schnellere Pace-Bänder sind heller.
3. **Vorlagen** → **Vorlage anlegen** mit Name, Strecke und Runden, **Feste Anzahl** oder **Offen bis Stopp**.
4. Vorlage antippen öffnet ihren eigenen Screen mit Strecke, Runden, Zonen und Bändern sowie den Plätzen 1–3. Unten stehen der Schalter **Gegen den Ghost rudern** (siehe Ghost) und **Starten**, das das gewählte Rudergerät verbindet und die Session sofort startet. Der Stift öffnet den Editor, dort lässt sich die Vorlage auch löschen; danach zeigt die App wieder die Liste.
5. Nach der letzten Runde endet die Session von selbst und die Zusammenfassung zeigt alle Runden mit dem Anteil in der Zone, die beste mit Stern. Bei offener Rundenzahl endet sie mit **Session beenden**, eine angefangene Runde ist dann unvollständig.

Im Live-Display mit Vorlage ist die Pace der grösste Wert. Darunter steht der Zonenstatus mit dem Band („In der Zone · 2:05–2:10“, sonst „Schneller“ bzw. „Langsamer“), die Schlagzahl-Karte zeigt ihr Band ebenso („Mehr Schläge“, „Weniger Schläge“). Blau heisst in der Zone, orange ausserhalb. Dazu kommen Kacheln für Rundenzeit, Watt, Puls (wenn Gurt oder Rudergerät ihn liefern) und den Anteil in der Zone.

Um die Pace läuft ein Fortschrittsrahmen aus drei Spuren, jede beginnt oben in der Mitte und läuft im Uhrzeigersinn, an der Spitze sitzt ein Schiffchen:

| Spur | Zeigt | Legende, z.B. |
|---|---|---|
| aussen, weiss | die ganze Strecke über alle Runden, Kerben an den Rundengrenzen | „Gesamt 1 460 / 3 000 m“ |
| Mitte, grau | die aktuelle Runde, Kerben an den Abschnittsgrenzen | „Runde 2 / 3 · noch 540 m“ |
| innen, farbig | den aktuellen Abschnitt, blau bzw. orange nach dem Zonenstatus der Pace, grau, wenn er frei ist | „Tempo · noch 340 m“ bzw. „frei · noch 340 m“ |

Bei offener Rundenzahl fehlt die äussere Spur, die Legende zeigt dann „Runde 2“. Bei Zeitstrecken stehen statt Metern Zeiten.

Eine Zone kann zusätzlich eine Widerstandsstufe (1–25) tragen, die die App beim Rudern auf einem FTMS-Rudergerät mit verstellbarem Widerstand setzt (siehe oben); sie steht in den Listen hinter den Bändern („· Stufe 10“). Eine Stufe allein ersetzt kein Band. Hat das Gerät weniger Stufen, nimmt die App seine höchste.

Eine geänderte Zone gilt in allen Strecken, die sie enthalten. Passt sie danach in eine davon nicht mehr, wird die Änderung abgelehnt und der Editor nennt die Strecke. Eine gelöschte Zone macht ihre Stellen frei.

Runden laufen nach Wanduhr: Eine Pause kostet bei Distanzstrecken Zeit und bei Zeitstrecken Meter, auch wenn der PM5 seine Uhr anhält. Wird eine schon geruderte Strecke geändert, auch über eine ihrer Zonen, entsteht eine neue Version, alte Sessions behalten ihre.

### Bestenlisten

Die App führt Bestenlisten und zeigt jeweils die Plätze 1–3 mit Wert, Pace pro 500 m und Datum:

- **Vorlage**: ganze Sessions, in denen alle geplanten Runden vollständig gerudert wurden, gewertet nach der Summe der Runden. Eine Liste pro Streckenlänge und Rundenzahl. Der Screen der Vorlage zeigt die Plätze 1–3 ihrer aktuellen Länge und Rundenzahl. Bei offener Rundenzahl gibt es keine.
- **Strecke**: jede vollständige Runde, egal mit welcher Vorlage. Hatte die Strecke verschiedene Längen, gibt es eine Liste pro Länge.
- **Zone**: jede Fahrt durch die Zone in einer vollständigen Runde, egal auf welcher Strecke, auch mehrere aus derselben Session. Eine Liste pro Zonenlänge.

Strecke oder Zone in ihrer Liste antippen öffnet die Detailansicht mit den Plätzen pro Länge, die aktuelle zuerst. Der Stift dort öffnet den Editor. Die Zusammenfassung markiert jede Runde und Zonenfahrt auf Platz 1–3 (z.B. „Platz 2“, „Sprint · Platz 1“) und ebenso die Session in der Liste ihrer Vorlage. Die Marken zeigen den aktuellen Stand, wird eine Runde später überholt, verschwindet ihre Marke.

Gewertet wird nach Wanduhr, Pausen zählen also mit, auch in der Pace: Distanzen nach der Zeit, Zeitstrecken und -zonen nach den Metern. Bei Gleichstand liegt der frühere Eintrag vorne. Es zählen nur Sessions, die auf diesem Gerät an einem PM5 oder FTMS-Rudergerät gerudert wurden, keine aus dem Simulator, aus einem Replay oder importierte. Gelöschte Sessions verschwinden aus den Listen. Wird eine Vorlage, Strecke oder Zone gelöscht, fällt ihre Liste weg, die Sessions bleiben.

### Ghost

Beim Rudern einer Vorlage läuft auf jeder Spur des Fortschrittsrahmens ein Ghost mit, ein violettes Schiffchen, schmaler als das eigene. Es zeigt, wo Platz 1 der passenden Bestenliste zur gleichen Zeit war:

| Spur | Ghost | Läuft |
|---|---|---|
| aussen | Platz 1 der Vorlage mit gleicher Streckenlänge und Rundenzahl | über die ganze Session |
| Mitte | Platz 1 der Strecke mit gleicher Länge | startet mit jeder Runde neu |
| innen | Platz 1 der Zone des aktuellen Abschnitts mit gleicher Länge | startet mit jeder Fahrt durch die Zone neu |

Wo es keine Bestenliste oder noch keinen Eintrag gibt, läuft kein Ghost: aussen nicht bei offener Rundenzahl, innen nicht in einem freien Abschnitt, beim freien Rudern gar keiner. Kämen sich Ghost und eigenes Schiffchen in die Quere, rückt der Ghost quer zur Spur nach aussen und kehrt auf die Mitte zurück, sobald wieder Platz ist. Auf Zeitstrecken lägen beide immer auf gleicher Höhe, dort zeigt der Rahmen deshalb keinen Ghost.

Die Pace-Box zeigt in der Zeile **Ghost** den Abstand zum Ghost der Vorlage (aussen): auf Distanzstrecken in Sekunden, auf Zeitstrecken in Metern, z.B. „7.6 s vor dir“ (Rückstand, orange), „12 m hinter dir“ (Vorsprung, blau) oder „gleichauf“. Ohne Ghost aussen fehlt die Zeile, die Ghosts auf den anderen Spuren laufen trotzdem.

Die Ghosts folgen den Bestenlisten live: Wird eine Runde oder Zonenfahrt der laufenden Session neuer Platz 1, läuft der Ghost dieser Spur ab der nächsten Runde bzw. Fahrt gegen sie. Im Simulator laufen die Ghosts ebenso mit. Da Simulator-Sessions nicht in die Bestenlisten kommen, werden sie selbst nie Ghost. Auf dem Screen der Vorlage trägt Platz 1 das Ghost-Symbol.

Der Schalter **Gegen den Ghost rudern** auf dem Screen der Vorlage steht bei jedem Öffnen auf an. Ausgeschaltet läuft in der Session, die von dort startet, auf keiner Spur ein Ghost, und die Pace-Box zeigt keinen Abstand. Die Wahl gilt nur für diese eine Session und lässt sich während der Fahrt nicht ändern.

### Pulsgurt

Ein Brustgurt mit dem Bluetooth-Standard Heart Rate (z.B. Polar H10) liefert Puls und RR-Intervalle direkt an die App, unabhängig vom Rudergerät. Er ist optional.

1. In **Geräte wählen** unter **Pulsgurt** auf **Gurt koppeln** tippen. Die Gurt-Suche listet nur Gurte, keine Rudergeräte. Findet sie in 15 s keinen, zeigt sie Tipps: Elektroden anfeuchten und Gurt anlegen, Gurt von anderen Apps oder Uhren trennen. Gurt antippen koppelt ihn. Die App merkt ihn sich über einen Neustart hinaus, **Gurt wechseln** wählt einen anderen, **Vergessen** entkoppelt ihn. **Weiter** hängt nur vom Rudergerät ab, der Startbildschirm zeigt den Gurt neben dem Rudergerät.
2. Sobald die App mit einem PM5 oder FTMS-Rudergerät verbunden ist, verbindet sie den gekoppelten Gurt von selbst. Mit Simulator oder Replay verbindet sie keinen Gurt. Bricht die Verbindung ab, versucht sie es 30 s lang erneut, ein Ausfall des Gurts stört Rudergerät und Session nicht. Wird das Rudergerät bewusst getrennt, trennt sie auch den Gurt.

Für den Puls gilt: Gurt vor Rudergerät vor kein Puls. Der Gurt zählt, solange seine letzte Messung höchstens 3 s alt ist, sonst gilt der Puls des PM5 bzw. FTMS-Rudergeräts. Woher der Puls stammt, zeigt die App nicht an. Ohne Puls fehlt der Wert.

Im Live-Display steht in der Kopfzeile neben der Verbindung des Rudergeräts ein Herz mit Punkt für den Gurt: grün verbunden, orange beim (Wieder-)Verbinden, leerer Ring wartend oder getrennt. Scheitert die Verbindung, erscheint eine Meldung mit dem Hinweis, dass viele Gurte nur eine oder zwei Bluetooth-Verbindungen gleichzeitig erlauben, und **Erneut versuchen**. Beim Puls steht klein das letzte RR-Intervall (z.B. „812 ms“), es verschwindet, wenn 3 s lang keines nachkommt.

Die Zusammenfassung zeigt **Ø Puls** und **Max. Puls**, sobald es einen Puls gab, mit Gurt dazu die Kurve der RR-Intervalle und „HRV (RMSSD) 16 ms“ (ab zwei Intervallen, aus den ungefilterten Intervallen). Die Gurt-Pakete werden wie die des Rudergeräts aufgezeichnet, exportiert und beim Import neu ausgewertet.

### Health Connect

Unter Android überträgt die App Sessions an Health Connect. Von dort lesen sie Apps wie Google Fit bzw. Google Health. Die Google-Fit-Schnittstellen laufen Ende 2026 aus, deshalb gibt es keinen direkten Weg zu Google Fit. Unter Linux, iOS und macOS fehlt die Funktion.

1. Unter **Sessions** öffnet das Herz-Symbol oben rechts die Einstellung. **An Health Connect übertragen** einschalten und die Berechtigungen erteilen. Die Übertragung gilt erst als eingeschaltet, wenn Trainingseinheiten geschrieben werden dürfen. Fehlt Health Connect oder ist es zu alt, bietet die App **Installieren** bzw. **Aktualisieren** an. **Health Connect öffnen** führt zu den Berechtigungen und den übertragenen Daten, **Datenschutz-Hinweis** erklärt, was die App schreibt.
2. Ist die Übertragung eingeschaltet, geht jede Session von einem PM5 oder FTMS-Rudergerät nach dem Rudern im Hintergrund an Health Connect. Sessions aus dem Simulator und aus Replays gehen nie an Health Connect.
3. **An Health Connect senden** im Menü einer Session und in der Zusammenfassung überträgt eine Session nachträglich, auch eine importierte. Erneutes Senden ersetzt die frühere Übertragung, es entsteht keine zweite Einheit.

In Health Connect erscheint eine Trainingseinheit „Rudergerät“ mit Beginn und Ende, als Titel der Name der Vorlage bzw. „Freies Rudern“, dazu Distanz, Kalorien (sofern das Rudergerät welche meldet), die Verläufe von Puls, Leistung und Geschwindigkeit (ein Wert pro Sekunde), die Runden einer Vorlage mit ihrer Distanz und die Pausen. Schlagzahl, Kraftkurve und Rohdaten bleiben in der App. Die App liest nichts aus Health Connect.

Die Zusammenfassung zeigt „An Health Connect übertragen am …“ bzw. „Nicht an Health Connect übertragen“. Schlägt eine Übertragung fehl, meldet die App den Grund, fehlt die Berechtigung, mit **Erteilen**. Eine automatische Wiederholung gibt es nicht. Der Status gehört zum Gerät: Export und Import nehmen ihn nicht mit, nach einem Update gelten alle bestehenden Sessions als nicht übertragen.

### Sprache

Die App startet auf Deutsch. Das Sprach-Symbol oben rechts auf „Geräte wählen“ und dem Startbildschirm schaltet zwischen **Deutsch** und **English** um, also schon beim ersten Start. Die Wahl gilt sofort und bleibt über einen Neustart erhalten. Die Systemsprache spielt keine Rolle. Namen, die du selbst vergibst (Zonen, Strecken, Vorlagen), werden nicht übersetzt. Datum und Dezimalzeichen folgen der Sprache (`15.10.2026, 18:30` bzw. `Oct 15, 2026, 18:30`), Pace und Zeiten erscheinen in jeder Sprache gleich (`2:05`, `12:34`).

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
    health/            Übertragung an Health Connect (Kotlin-Kanal in android/app/src/main/kotlin)
  l10n/                Übersetzungen: app_de.arb (Vorlage), app_en.arb und der erzeugte Code
  features/
    connection/        Geräte wählen, Startbildschirm, Verbindungsanzeige
    courses/           Strecken-Liste und -Editor mit „Zone einbauen“
    zones/             Zonen-Liste und -Editor
    templates/         Vorlagen-Liste, Screen einer Vorlage und Editor
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

## Dateiformat `.strokesplit`

gzip-komprimiertes JSON Lines. Die erste Zeile ist ein Header mit Format (`"format": "strokesplit-raw"`), Quelle, Protokoll, Gerät, Startzeit und Zusammenfassung, danach folgt pro Rohpaket eine Zeile `{"t": ms, "c": "0031", "b": "<base64>"}`. `protocol` ist `pm5` oder `ftms` und bestimmt, wie die Rohpakete dekodiert werden (`c` ist bei FTMS z.B. `2ad1`). Dateien von vor FTMS haben kein `protocol` und gelten als PM5. Die Zeit `t` ist die Wanduhr seit dem ersten Paket. Pakete eines Pulsgurts stehen mit `"c": "2a37"` auf derselben Zeitachse, der `session`-Block im Header enthält, sofern vorhanden, `averageHeartRate`, `maxHeartRate` und `rmssdMs`. Beim Import werden Messwerte und Zusammenfassung aus den Rohpaketen neu berechnet. Unkomprimierte Spike-Mitschnitte (`.jsonl`) lassen sich ebenfalls importieren. Dateien von vor der Umbenennung (Endung `.aergrow`, Format `aergrow-raw`) liest der Import weiterhin, die Test-Fixtures sind bewusst in diesem alten Format.

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

Zum Widerstand zeigt der Spike im Protokoll, ob das Gerät seine Stufe meldet und ob sie sich setzen lässt (aus den Features), und den Stufenbereich (`2ad6`). Hat das Gerät einen Control Point, erscheint unter den Knöpfen der Bereich **Widerstand** mit der gemeldeten Stufe, **−**/**+** für die Wunschstufe und vier Knöpfe, die „Set Target Resistance Level“ (`04`) in den Kodierungen senden, die Geräte verwenden: `u8 ×10` (FTMS 1.0, Schritte von 0,1), `s16 ×10` (neuere FTMS-Versionen), `u8 Stufe` und `s16 Stufe` (die Stufe ohne Faktor). Die Antwort des Geräts („Erfolg“, „nicht unterstützt“, „ungültiger Wert“ …) und Meldungen des Machine Status stehen im Protokoll, jeder Versuch als Marker im Mitschnitt. **Request Control** fordert die Steuerung erneut an, falls das Gerät mit „Steuerung nicht erlaubt“ antwortet.

## Software-Rower

Ohne echtes FTMS-Rudergerät lässt sich die FTMS-Anbindung mit einem Software-Rower testen. Er läuft auf dem Linux-PC, meldet sich als `Stroke & Split FTMS` mit dem Fitness Machine Service `0x1826` und spielt eine FTMS-Aufnahme zeitgetreu als Rower-Data-Notifications ab.

Voraussetzungen: BlueZ mit eingeschaltetem Adapter und [`uv`](https://docs.astral.sh/uv/). Die Python-Abhängigkeit (`bless`) holt `uv` beim ersten Start selbst.

```sh
# PM5-Aufnahme in eine FTMS-Aufnahme umrechnen (.jsonl, .strokesplit oder .aergrow)
cd packages/erg_protocol && dart run erg_protocol:pm5_to_ftms test/fixtures/just_row.jsonl /tmp/ftms.jsonl
# Software-Rower starten, ARGS=--loop spielt die Aufnahme endlos
make ftms-rower FILE=packages/erg_protocol/test/fixtures/ftms_just_row.jsonl
```

Getestet wird vom **Android-Handy** aus: `make run-android`, in der Geräteliste erscheint der Software-Rower als FTMS-Rudergerät. Zur Kontrolle zeigt ihn auch nRF Connect mit dem Service `0x1826`. Nach dem Verbinden bestätigt er Request Control und Start/Resume am Control Point und beginnt abzuspielen; ohne Start-Befehl beginnt er 2 s nach dem Verbinden. Einen Reset simuliert man, indem man den Software-Rower neu startet.

Vom selben Linux-Rechner aus geht es nicht: Der Bluetooth-Adapter kann nicht gleichzeitig Peripheral für den Software-Rower und Central für die App sein. Wer ein zweites Linux-Gerät hat, kann die App dort starten.

## CI und Releases

Die Pipeline läuft mit GitHub Actions (`.github/workflows/`) in Docker-Images von `cirruslabs/flutter`. Analyse und Tests stehen in `check.yml`, die Builds von APK und AppImage in `build.yml`; `ci.yml` und `release.yml` rufen beide auf.

| Anlass | Was läuft |
|---|---|
| Pull Request | `ci.yml`: `check` (`make deps analyze coverage`, also Analyse und Tests von App und `erg_protocol` mit Coverage), `generated` (`make check-generated`), `build` (APK und AppImage, nur wenn der Pull Request Build-Dateien ändert) |
| Push auf `main` | `ci.yml`: `check`, `generated`, `build` |
| Tag `vX.Y.Z` | `release.yml`: `verify-tag` und `check`, `build` (APK und AppImage), dann `release` |
| von Hand gestartet („Run workflow“, `gh workflow run ci.yml --ref <branch>`) | `ci.yml`: `check`, `generated`, `build`, auf jedem Branch |
| Pull Request oder Push auf `main`, der `.github/` ändert | `lint-workflows.yml`: `actionlint` (Syntax und Ausdrücke) und `zizmor` (Sicherheit, Konfiguration in `.github/zizmor.yml`) |

Ein Branch ohne Pull Request bekommt keine Pipeline, andere Tags ebenfalls nicht.

`check` schreibt die Zeilenabdeckung je Paket in die Zusammenfassung des Workflow-Laufs und hängt die lcov-Dateien sieben Tage als Artefakt `coverage` an, etwa für die Anzeige im Editor (VS Code „Coverage Gutters“). Die Zahl der App enthält auch generierten Code.

`build` findet Fehler in Gradle, CMake oder im AppImage-Skript vor dem Release. In Pull Requests läuft es nur, wenn sich `android/`, `linux/`, `assets/`, die `pubspec`-Dateien, das Makefile, `tool/build_appimage.sh`, `build.yml` oder `.github/actions/` ändern. Die APK und das AppImage hängen sieben Tage als Artefakte am Workflow-Lauf und heissen `strokesplit-dev-…`. Die APK ist mit einem zufälligen Debug-Schlüssel signiert und lässt sich deshalb nicht über ein Release installieren.

`generated` erzeugt drift-Code, Übersetzungen und drift-Schema-Snapshots neu (`make codegen l10n schema`) und schlägt fehl, wenn sich danach etwas von den eingecheckten Dateien unterscheidet, etwa weil nach einer Änderung an einer Tabelle, einer ARB-Datei oder an `schemaVersion` das Generieren vergessen wurde. Lokal läuft dasselbe mit `make check-generated` auf einem sauberen Arbeitsverzeichnis.

Alle Actions sind auf einen Commit-SHA gepinnt, die Version steht als Kommentar dahinter. Dependabot hebt beides gemeinsam an. Checkouts behalten kein Token (`persist-credentials: false`), Release-Builds laufen ohne Cache, damit kein manipulierter Cache in ein veröffentlichtes Paket gelangt. Lokal prüfen: `uvx zizmor .` und `docker run --rm -v "$PWD:/repo" -w /repo rhysd/actionlint`.

**Release erstellen**: Einen Commit von `main` mit der neuen Version taggen und den Tag pushen.

```sh
git checkout main && git pull
git tag v1.2.0
git push origin v1.2.0
```

`verify-tag` bricht ab, wenn der Commit nicht auf `main` liegt oder es das Release schon gibt. Ein Release wird nie überschrieben, ein fehlerhaftes Release in GitHub löschen und mit einer neuen Version taggen. Der Versionsname der Pakete kommt aus dem Tag (`1.2.0`), der Android-Versionscode ist die Laufnummer des Release-Workflows (`GITHUB_RUN_NUMBER`) und steigt damit mit jedem Release. `pubspec.yaml` bleibt unverändert. Das Release enthält `strokesplit-1.2.0-android.apk` und `strokesplit-1.2.0-x86_64.AppImage` als Dateien.

### Einrichtung in GitHub (einmalig)

Alle APKs aus der Pipeline sind mit demselben Debug-Schlüssel signiert, damit eine neue Version über eine ältere installiert werden kann. Der Schlüssel ist ein gewöhnlicher Android-Debug-Keystore und nicht für den Play Store gedacht.

1. Keystore erzeugen:
   ```sh
   keytool -genkeypair -v -keystore strokesplit-debug.keystore -storetype PKCS12 \
     -alias androiddebugkey -storepass android -keypass android \
     -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
   ```
2. Den Keystore Base64-kodiert als Repository-Secret `ANDROID_DEBUG_KEYSTORE` anlegen. Secrets sind Text, `build.yml` dekodiert ihn im Release wieder:
   ```sh
   base64 -w0 strokesplit-debug.keystore | gh secret set ANDROID_DEBUG_KEYSTORE
   ```
   Alternativ unter „Settings → Secrets and variables → Actions“. Pull Requests aus Forks sehen das Secret nicht.
3. Die Keystore-Datei sicher aufbewahren. Geht sie verloren, müssen alle Nutzer die App vor dem nächsten Update deinstallieren.

Fehlt das Secret, bricht der APK-Build eines Releases mit einer Meldung ab, statt mit einem Zufallsschlüssel zu signieren.

### Abhängigkeiten aktualisieren

Dependabot (`.github/dependabot.yml`) öffnet jede Woche Pull Requests für die Dart-Pakete von App und `erg_protocol`, den Gradle-Build und die GitHub Actions. Minor- und Patch-Updates kommen pro Ökosystem gebündelt in einem Pull Request, Major-Updates einzeln. Neue Versionen nimmt Dependabot erst nach einer Woche, damit fehlerhafte oder gekaperte Releases vorher auffallen. Das Flutter-Image `ghcr.io/cirruslabs/flutter` in den Workflows und die Flutter-Version in `.github/actions/setup-flutter` erfasst Dependabot nicht, sie werden zusammen mit dem lokalen Flutter von Hand angehoben.

### Installation

**Android**: Die APK von der Release-Seite laden, im Handy-Browser oder am Rechner und dann aufs Handy übertragen (z. B. `adb install strokesplit-1.2.0-android.apk`). Beim Öffnen fragt Android, ob der Browser bzw. Dateimanager Apps aus unbekannten Quellen installieren darf. Eine neuere APK aus der Pipeline lässt sich über eine ältere installieren, die Sessions bleiben erhalten. Eine selbst gebaute APK (`make apk`, `make run-android`) hat einen anderen Schlüssel, vor dem Wechsel muss die App deinstalliert werden.

**Linux**: Das AppImage für x86_64 laden, ausführbar machen und starten. GTK 3 muss installiert sein, auf GNOME- und KDE-Desktops ist es das in der Regel.

```sh
chmod +x strokesplit-1.2.0-x86_64.AppImage
./strokesplit-1.2.0-x86_64.AppImage
```

Mit einem Werkzeug wie Gear Lever oder AppImageLauncher erscheint die App mit Name und Icon im Anwendungsmenü.

### Umzug von AergRow

Die App hiess früher „AergRow“ (App-ID `ch.aergrow.aergrow`). Seit der Umbenennung hat sie die App-ID `ch.strokesplit.strokesplit`.

**Android, iOS und macOS**: Die neue App-ID macht Stroke & Split zu einer neuen App, die neben der alten installiert wird und deren Sessions nicht sieht. Der Umzug läuft über Export und Import:

1. In der alten AergRow-App unter **Sessions** jede Session exportieren (`.aergrow`-Datei) und die Dateien ausserhalb der App sichern, z. B. in einem Cloud-Ordner oder auf dem Rechner.
2. Stroke & Split installieren.
3. In Stroke & Split unter **Sessions** → **Importieren** die `.aergrow`-Dateien einlesen.
4. Erst wenn alle Sessions in Stroke & Split erscheinen, die alte App deinstallieren. Mit der Deinstallation löscht das System ihre Sessions.

Strecken und Zonen kommen mit, soweit eine exportierte Session auf ihnen gerudert wurde. Vorlagen und nie geruderte Strecken müssen in Stroke & Split neu angelegt werden. Importierte Sessions zählen in keiner Bestenliste. Unter macOS gilt dasselbe, weil die Sandbox die Daten im Container der App-ID ablegt.

**Linux**: Hier hängt der Speicherort nicht an der App-ID. Beim ersten Start übernimmt Stroke & Split die bisherige Datenbank `aergrow.sqlite` im Dokumente-Ordner (z. B. `~/Dokumente`), indem es sie in `strokesplit.sqlite` umbenennt. Sessions, Strecken, Zonen und Vorlagen bleiben erhalten.

## Plattform-Status

| Plattform | Stand |
|---|---|
| Linux | Am echten PM5 verifiziert: Spike, Verbinden, Reconnect, Fehlermeldungen, Aufzeichnung, Replay, Import |
| Android | Am echten PM5 verifiziert (Pixel 8 Pro, Android 17): Spike, Verbinden, Bluetooth-Hinweise, Aufzeichnung (Distanz und Zeit exakt wie am PM5), Replay, Export, Bildschirm bleibt an |
| FTMS-Rudergeräte | Nach Spezifikation umgesetzt und mit dem Software-Rower getestet. Am Domyos Woodrower: Werte, Watt und Stufe angezeigt, Setzen der Stufe im Spike bestätigt; Setzen aus der App noch ohne Gerätetest. Andere Geräte ungetestet |
| iOS | Konfiguriert (`Info.plist`), ungetestet, da kein Mac verfügbar |
| macOS | Konfiguriert (Entitlements), ungetestet |
| Pakete aus CI | APK (debug-signiert) und AppImage x86_64 per Tag `vX.Y.Z`, lokal im CI-Image gebaut, noch ohne Probe-Release |

## Lizenzhinweis

Die BLE-Bibliothek `flutter_blue_plus` 2.x ist für nicht-kommerzielle Nutzung frei (`License.nonprofit`). Für eine kommerzielle Nutzung ist eine Lizenz nötig oder ein Wechsel auf eine Alternative wie `universal_ble` (siehe Design D4 im Change `foundation`).
