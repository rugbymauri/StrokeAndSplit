# Implementierungsplan

Reihenfolge, Abhängigkeiten und offene Punkte der geplanten OpenSpec-Changes. Der Plan ist die eine Stelle, an der nichts vergessen gehen soll.

**Pflege:** Der Plan wird bei jedem Schritt nachgeführt, im selben Commit wie die Änderung:

- beim Start eines Changes (Branch, Stand),
- wenn ein Task fertig ist oder eine Frage entschieden wird,
- wenn Neues auftaucht (Bug, Nacharbeit, Idee), unter „Offene Punkte“ oder beim betroffenen Change,
- beim Archivieren: den Change nach „Erledigt“ verschieben und die Changes danach auf Folgen prüfen.

Stand: 2026-10-16, `main` nach dem Merge von `foundation`, `courses`, `zones`, `device-types` und `translations`; Change `statistics` geplant; Change `gitlab-pipeline` geplant.

## Überblick

| # | Change | Tasks | Kann starten? | Wartet auf |
|---|---|---|---|---|
| 1 | `device-types` | 30/33 | umgesetzt, in `main` gemergt | Nutzer: manuelle Tests 7.1–7.3 |
| 2 | `translations` | 15/16 | umgesetzt, in `main` gemergt | Nutzer: manueller Test 6.3 |
| 3 | `ui-design` | 17/18 | umgesetzt, in `main` gemergt | Nutzer: Abgleich mit dem Canvas am Gerät (6.1) |
| 4 | `force-curve` | 10/11 | in Umsetzung | – |
| 5 | `heart-rate` | 21/25 | in Umsetzung | Spike mit Gurt am Gerät (1.1/1.2, Nutzer) |
| 6 | `statistics` | 12/13 | umgesetzt, in `main` gemergt | Nutzer: Test am Gerät (5.2) |
| 7 | `ghost` | 13/14 | in Umsetzung | – |
| 8 | `rename-stroke-and-split` | 10/11 | zuletzt | Domain- und Markenrecherche (Nutzer) |
| 9 | `gitlab-pipeline` | 6/17 | umgesetzt, in `main` gemergt, nach GitHub Actions umgezogen | Nutzer: Secret `ANDROID_DEBUG_KEYSTORE` in GitHub (2.2), Probe-Release `v0.1.0` |
| 11 | `auto-pause` | 10/11 | umgesetzt, in `main` gemergt | Nutzer: Test am Gerät (5.2) |
| 12 | `health-connect` | 11/13 | in Umsetzung (`feature/health-connect`) | Spike (1.2) und Gerätetest (6.1), Nutzer |
| 13 | `resistance-control` | 12/13 | in Umsetzung (`feature/resistance-control`) | – (Gerätetest 6.2 am Woodrower am Schluss, Nutzer) |
| 14 | `template-screen` | 8/9 | umgesetzt, in `main` gemergt | Nutzer: Test am Gerät (4.3); nach `ui-design`, `ghost` und `statistics` archivieren |
| 15 | `course-rowing-free` | 11/12 | umgesetzt bis auf Gerätetest 7.3 (`feature/course-rowing-free`) | setzt `template-screen` voraus; erst nach `ghost` und `template-screen` archivieren |
| 16 | `zone-level-only` | 3/5 | in Umsetzung (`feature/zone-level-only`) | erst nach `resistance-control` archivieren |

## Warum diese Reihenfolge

1. **`device-types` zuerst**, weil er das Fundament der Daten umbaut: ein Decoder pro Protokoll, Rohpakete mit Protokoll, nullable Schlagdetails mit Migration. Alles, was später Rohpakete, Schläge oder Quellen anfasst (`force-curve`, `heart-rate`), baut dann auf dem neuen Stand auf, statt ihn zu kreuzen. Ausserdem kennt `ui-design` dann schon FTMS-Geräte, wenn es den Startbildschirm und die Geräteliste neu gestaltet.
2. **`translations`** vor `ui-design`, weil dieser fast alle Screens neu baut: Steht die Lokalisierung schon, entstehen die neuen Screens gleich mit ARB-Keys, statt danach ein zweites Mal Texte herauszuziehen. Nach `device-types`, weil dieser selbst Texte der Geräteliste ändert (Task 5.5). Das Herausziehen aus Screens, die `ui-design` ersetzt, ist teils Wegwerfarbeit; die meisten Texte bleiben aber erhalten.
3. **`ui-design`** schafft das Layout, in das Kraftkurve, Puls und Ghost ihren reservierten Platz bekommen. Erst danach lohnt sich deren Anzeige.
4. **`force-curve`** ist klein und hängt nur an einem Spike am PM5 und am Layout aus 3.
5. **`heart-rate`** kommt nach `device-types`, weil beide dieselben Anforderungen ändern und der Gurt an die Quelle andockt, die `device-types` umbaut.
6. **`statistics`** hängt an keinem offenen Change: Die Ranglisten werden aus den Runden aus `courses` und `zones` berechnet. Er kann auch vor `ui-design` kommen, dann gestaltet `ui-design` die neuen Elemente mit.
7. **`ghost`** braucht den Fortschrittsrahmen aus `ui-design` und die Ranglisten aus `statistics`, denn der Ghost ist Platz 1.
8. **`rename-stroke-and-split`** zuletzt, damit nicht jeder Change auf halbem Weg die Namen wechselt. Nach `translations` steht der Anzeigename an einer Stelle in den ARB-Dateien.
9. **`gitlab-pipeline`** hängt an keinem Change und ändert kein App-Verhalten. Er kann parallel laufen. Kommt er vor `rename-stroke-and-split`, stellt der Rename die Namen in CI mit um.

## Changes

### 1. `device-types`: FTMS-Rudergeräte, SkiErg/BikeErg abweisen

Ziel: Nur Rudergeräte. PM5 an SkiErg/BikeErg wird abgewiesen, FTMS-Rower (`0x1826`) kommen als zweite Geräteart dazu. Ohne FTMS-Hardware verifiziert über Spec-Tests, FTMS-Modus im Simulator und einen Software-Rower (BlueZ) unter `tool/`.

Vor dem Start anpassen:
- [x] Task 1.1: Branch startet von `main` statt Rebase auf `feature/courses`; Hinweis am Ende von `tasks.md` gestrichen.
- [x] Task 2.2 und Design D1/D9: **Schema 4** (Migration `from3To4`), Migrationstests 3→4 und 1→4 auch mit Runden und Zonen.
- [x] MODIFIED-Anforderungen gegen die Main-Specs geprüft: Kein Szenario geht verloren, `courses` und `zones` haben nur Anforderungen ergänzt. `openspec validate device-types --strict` ist gültig.
- [x] Task 2.5, 4.2 und 7.3: Export, End-to-End-Test und manueller Test mit Strecke und eingebauten Zonen.

Umgesetzt am 2026-10-16 auf `feature/device-types`: `make check` grün (261 App-, 86 Package-Tests), `openspec validate device-types --strict` gültig. Offen sind nur Task 3.5 (Erg-Typ-Werte prüfen) und die manuellen Tests 7.1–7.3, die der Nutzer in einer späteren Session macht. Am 2026-10-16 auf `main` rebased und gemergt. Archiviert wird nach den manuellen Tests.

Bei der Umsetzung mitnehmen:
- [x] Zeile über 120 Zeichen in `Stroke.toString` (Task 2.1) umgebrochen.
- [x] Task 3.5 (Entscheid des Nutzers, 2026-10-18): Ski und Bike werden nicht getestet, die Werte bleiben aus der Spezifikation. Früherer Stand: `Pm5ErgType` ist umgesetzt, aber die Ski- und Bike-Werte sind nicht gegen das aktuelle Concept2-Dokument geprüft. Online war die Liste nicht zu finden, nur der Wert 0 (RowErg) ist an den Aufnahmen bestätigt. Der Nutzer prüft sie gegen die *PM5 Bluetooth Smart Interface Definition* oder an einem SkiErg/BikeErg, dann Task abhaken.
- [x] Task 3.6: README-Abschnitt FTMS und Erg-Typ steht, die Fixtures-Tabelle kam mit Task 4.3 (`ftms_just_row.jsonl` ist aus `just_row.jsonl` umgerechnet, keine Aufnahme eines echten FTMS-Geräts).
- Task 4.2: Zusätzlich zum Umschalter in der Simulator-Bedienung bietet „Vorlage rudern“ die Quelle „Simulator (FTMS)“ an, weil eine Vorlage die Session sofort startet und der Umschalter während einer Session gesperrt ist. Mit `ui-design` (Startbildschirm, Quellenwahl) übernehmen.
- Reihenfolge: Abschnitt 3 (FTMS-Protokoll) vor 2.4/2.5 umgesetzt, weil deren Tests den FTMS-Decoder brauchen.
- Task 4.4: Der Software-Rower startet unter Linux und registriert seine Advertisement bei BlueZ. Ob er vom Handy aus als FTMS-Gerät erscheint und Control Point und Notifications funktionieren, ist ungeprüft und gehört zu 7.2. bless 0.3 kann keine Service Data setzen; das Skript ergänzt sie im Advertisement-Objekt von bless. Nach einem Update von bless prüfen.
- Task 5.2 weicht von D5 ab: Der Scan läuft ohne Plattformfilter, weil flutter_blue_plus unter Android das Keyword `PM5` nicht mit dem Service `0x1826` kombiniert. `rowerFromAdvertisement` filtert auf allen Plattformen. Unter Linux liefert `systemDevices` den BlueZ-Cache nur mit Namen; dort wird nur ein PM5 erkannt. Ein FTMS-Gerät im Cache erscheint unter Linux erst, wenn BlueZ es neu entdeckt. Das betrifft nur Linux, getestet wird FTMS vom Handy aus.
- Task 5.3/5.4: Die Protokolllogik beim Verbinden (Abtastrate, Abos, Erg-Typ, Control Point) liegt in `setUpRower` über einer dünnen `GattConnection`, damit sie ohne Bluetooth testbar ist. `FlutterBluePlusTransport` verbindet nur noch und sucht die Characteristics der Services `0x0030` und `0x1826`.
- Task 7.4: Die README-Zeile „nur mit Software-Rower getestet“ stimmt erst nach dem manuellen Test 7.2; bis dahin ist FTMS nur automatisch getestet.
- Design D8 angepasst: Beim FTMS-Reset beginnt die eigene Uhr wieder bei 0, sonst zählt die Session die Zeit doppelt.
- [x] Nachtrag (Nutzer, 2026-11-05, `feature/ftms-device-power`, Task 3.7): Bei FTMS-Rudergeräten zeigt die App die Watt des Geräts statt der aus der Pace berechneten, damit sie mit dem Display übereinstimmen (Domyos Woodrower); ohne Geräteleistung wie bisher aus der Pace. Szenario „Gleiche Pace, gleiche Leistung“ gilt nur noch für Geräte ohne Leistungsfeld.
- [x] Zeile über 120 Zeichen in `lib/features/connection/device_list_screen.dart` (Fehlertext „Suche nach dem PM5“) mit Task 5.5 umgebrochen.
- Task 5.5: „PM5 suchen“ heisst jetzt überall „Rudergerät suchen“, auch auf dem Startbildschirm und in „Vorlage rudern“. Mit `ui-design` übernehmen.

Manuell (vom Nutzer): 7.x mit dem Software-Rower vom Android-Handy aus.

### 2. `translations`: Deutsch und Englisch, erweiterbar

Ziel: Die Oberfläche ist übersetzbar, zuerst Deutsch und Englisch, weitere Sprachen kommen als zusätzliche ARB-Datei dazu. Die Sprache wird in der App gewählt, die App startet auf Deutsch, die Systemsprache spielt keine Rolle (F13, F14). Was Nutzer selbst benennen (Zonen, Strecken, Vorlagen), wird nicht übersetzt; eigene Inhalte mit Namen liefert die App nicht mit.

Stand heute: kein `flutter_localizations`, keine `l10n.yaml`, rund 250 deutsche Texte direkt in 17 Screens unter `lib/features/`.

Arbeitspunkte:
- `flutter_localizations` und `gen-l10n` einrichten, `app_de.arb` als Vorlage, `app_en.arb` als zweite Sprache.
- Texte aus den Screens in die ARB-Dateien ziehen.
- Deutsche Sätze aus `lib/data/` lösen: Die Schicht liefert Codes bzw. Enums, die Oberfläche übersetzt sie. Betroffen u.a. `RowerConnectException` (`rower_connector.dart`, `flutter_blue_plus_transport.dart`), `PlacementError` (`course_layout.dart`), `zoneErrors` / `ArgumentError(errors.join(' '))` (`zone_repository.dart`).
- Formate nach Sprache (`intl`): Datum (`formatDateTime`, heute fest `15.10.2026, 18:30`) und Dezimalzeichen (`formatStrokeRate`, heute `22.5`). Die Pace `2:05.3` bleibt fest wie am PM5.
- Sprachwahl in der App, gewählte Sprache gemerkt (F16).
- Ab dann für alle Changes: neue Texte nur über die ARB-Dateien, in jeder Sprache.

Vor dem Start:
- [x] Change angelegt (2026-10-16): Capability `app-language`, keine geänderten Specs.
- [x] F15 und F16 vorläufig nach Vorschlag entschieden (Schweizer Rechtschreibung, `shared_preferences`), im Design als D6 und D2. Der Nutzer kann sie noch kippen.
- Sprachwahl vorerst als Symbol im Startbildschirm (Design D3); `ui-design` verlegt sie.
- Texte des Startbildschirms schon mit Task 2.2 übersetzt, weil der Test der Sprachwahl sie braucht; Task 4.1 übernimmt den Rest der Verbindung.
- Nach 6.1 bleiben als Literale nur Einheiten (`m`, `spm`, `m:ss`), Formate, Eigennamen (PM5, FTMS, Concept2) und der Dateityp „AergRow-Session“ im Dateidialog; den benennt `rename-stroke-and-split` um.
- Offen ist nur noch der manuelle Test 6.3 auf Linux und Android (User).

### 3. `ui-design`: Designsprache und neue Screens aus dem Claude-Design-Canvas

Ziel: dunkles Thema, Barlow Condensed/IBM Plex Sans, Fortschrittsrahmen um die Pace, neue Editoren, Startbildschirm, Zusammenfassung. Vorlage ist der Design-Canvas „Stroke & Split Frontend“.

Vor dem Start angepasst (2026-10-16, in Proposal, Design, Specs und Tasks eingearbeitet):
- [x] Task 1.3 baut `CourseStrip` aus `zones` aus statt einer zweiten `SegmentBar` (D4 „Ablaufbalken“).
- [x] Task 4.1 gestaltet nur die bestehenden drei Tabs Vorlagen | Strecken | Zonen.
- [x] Task 3.3: Tabelle in D3, wohin jede Angabe aus `course_bar.dart` wandert (Zonenname bzw. „frei“ in die Legende).
- [x] Begriffe: Abschnitt = Zone oder frei, Spur heisst „Abschnittsspur“; Szenario „Freier Abschnitt“ ergänzt.
- [x] Startbildschirm: Quellenwahl mit FTMS-Rudergeräten (D6, Task 5.1).
- [x] Neue Texte nur über die ARB-Dateien (D9).
- [x] Sprachwahl (D8).

Vorläufig, vom Nutzer zu bestätigen:
- [x] D6 Geräte zuerst (Nutzer, 2026-10-16): Die App beginnt mit „Geräte wählen“ (Rudergerät inkl. Simulatoren, optional Pulsgurt aus `heart-rate`), dann Startbildschirm mit Gerätezeile. Der Quellen-Dialog beim Start einer Vorlage fällt weg. `heart-rate` 5.1 koppelt den Gurt dort statt auf dem Startbildschirm.
- [x] „Geräte wählen“ wird übersprungen, wenn das zuletzt gewählte Rudergerät gefunden wird (Nutzer, 2026-10-16). Vorläufig: Suche bis 10 s, Simulator als letzte Wahl geht direkt zum Startbildschirm.
- [x] D8 Sprachwahl als Symbol in der App-Leiste des Startbildschirms und von „Geräte wählen“, also schon beim ersten Start (Nutzer, 2026-10-16; `LanguageButton` in `lib/app/widgets/`).
- [x] Legende „Runde 2 / 3“ (Nutzer, 2026-10-16); dafür MODIFIED-Delta zu `course-rowing` nötig (mit 2.3). Vorläufig: Bereich „200–800 m“ entfällt.
- [x] OFL-Lizenzen der Schriften auf der Lizenzseite der App (`registerFontLicenses` in `lib/app/font_licenses.dart`) und Barlow Condensed 500 für Einheiten (Nutzer, 2026-10-16).

Alle Entscheide getroffen: F1 (Puls-Herkunft), F2 (Mittelweg, Design D6) und F12 (Schritte auf der Zeitachse, Design D7) sind entschieden.

- [x] F2 in Proposal, Design D6 und Task 5.1 eingetragen.
- [x] Ruderblatt-Tasten für Zahlen (2026-10-16) als Design D7, Spec `number-steppers` und Tasks 1.4 und 4.4 aufgenommen. Betrifft auch die Editoren aus `zones`.
- [x] F12 entschieden: Zeitachse Strecke 30 s, Zone und Startposition 10 s (Design D7, Spec `number-steppers`).
- [x] Task 1.4 `OarStepper` in `lib/app/widgets/`, D1-Farben als `AppColors` in `lib/app/design_tokens.dart` (Grundlage für 1.2). Vorläufig: Tasten waagrecht wie im Canvas, keine Tooltips (beissen sich mit Gedrückthalten), Blattrand `#4A545E` und Gedrückt-Farbe `#1D3A55` als private Konstanten, Beschriftung „mehr/weniger“ statt „kürzer/länger“. Offen für 4.4: Hintergrund `bg` für kompakte Felder in Karten.
- [x] Task 1.1 Schriften unter `assets/fonts/` mit OFL (IBM Plex Sans aus `IBM/plex`, weil google/fonts nur die variable Schrift führt); zusammen ca. 715 kB statt der geschätzten 400 kB.
- [x] Task 2.1 `ProgressFrameModel` in `lib/features/live/progress_frame_model.dart`.
- [x] Task 1.3 `CourseStrip` nach D4 (Höhe 8 px in Listen, 28 px mit Zonennamen im Strecken-Editor). Entschieden (Nutzer, 2026-10-16): Helligkeit proportional zum Tempo mit mindestens 15 % Abstand zwischen verschiedenen Bändern, freie Lücken ohne Text. Vorläufig: Zonen ohne Pace-Band in `zoneIn`; Auswahl (`selected`, `onSegmentTap`) nur vorbereitet, Anbindung mit 4.3.
- [x] Task 2.2 `ProgressFrame` in `lib/features/live/progress_frame.dart` mit Goldens. Entschieden (2026-10-16): Startkerbe oben in der Mitte auf Strecken- und Rundenspur, leere innere Spur als Token `AppColors.trackInner`. Vorläufig: ohne Pace färbt die Abschnittsspur `zoneOut`; Masse feste Pixel aus dem Canvas.
- [x] Task 3.1 `LiveLayout.of(Size)` in `lib/features/live/live_layout.dart`: Querformat nur, wenn breiter als hoch; gilt vorerst für die Fläche der Messwerte.
- [x] Task 3.2/3.3 Live-Display hoch und quer, frei (`live_free.dart`) und mit Vorlage (`live_course.dart`, Pace-Box, Schlagzahl-Karte, Kacheln); `course_bar.dart` und `courseLapOf` entfallen, `ZoneHint` in `zone_hint.dart`, Zonenstatus grossgeschrieben (Nutzer). Fläche für die Kraftkurve vorhanden, ohne Daten ausgeblendet. Vorläufig: andere Werte höchstens 80 % der Pace-Grösse; mit Vorlage entfallen Zeit/Distanz (Legende „Gesamt“); quer kurzer Button „Beenden“; Kopfzeile (Nutzer, 2026-10-16): nur der Vorlagenname bzw. „Frei rudern“, Verbindung als grüner Punkt (`AppColors.connected`); vorläufig: orange beim Verbinden/Wiederverbinden mit Zustandstext unter der App-Leiste (Spec `erg-connection`), grauer Ring getrennt, Badge für Simulator/Replay bleibt (Spec `erg-simulation`), „Trennen“ als Symbol. Für 6.1: 640 × 480 kürzt die Legende; `LiveLayoutBuilder` ungenutzt.
- [x] Task 2.3 `PaceBox` in `lib/features/live/pace_box.dart`, Legende „Runde 2 / 3“ mit MODIFIED-Delta zu `course-rowing`. Bis 3.3 zeigt `course_bar.dart` noch „Runde 2 von 3“ (`courseLapOf` entfällt mit 3.3). Vorläufig: unter 260 px Höhe wird der Inhalt verkleinert (auf dem Gerät prüfen, 6.1); Zonenstatus „in der Zone“ klein wie bisher.
- [x] Task 5.1 „Geräte wählen“ (`choose_devices_screen.dart`, gemerktes Rudergerät in `rower_choice.dart`, `LaunchScreen` sucht es bis 10 s) und Startbildschirm mit Gerätezeile, „Rudern“, „Frei rudern“, „Nochmal“, „Sessions“; Quellen-Dialog beim Vorlagenstart entfernt. Vorläufig: „Nochmal“ fällt auf eine ältere Session zurück, wenn die Vorlage der jüngsten gelöscht ist; Pulsgurt-Bereich fehlt bis `heart-rate`. Nur am Gerät prüfbar: Wiederverbinden per ID ohne Scan (BlueZ), 10-s-Suche mit PM5/FTMS, Bluetooth aus beim Start.
- [x] Task 5.2 Zusammenfassung nach Canvas (`session_summary_screen.dart`), Platz für die Marken aus `statistics` rechts der Runden und neben dem Titel. Entschieden (Nutzer, 2026-10-16): kein Anteil in der Zone für die ganze Session, nur pro Runde; „Fertig“ nach einer Session trennt und führt zum Startbildschirm. Vorläufig: Kopf mit Vorlage und Quelle; Schläge als vierter Durchschnittswert; beste Runde mit Stern.
- [x] Task 6.2 README-Bedienung nachgeführt (Geräte wählen, Startbildschirm, Vorlagen, Ruderblatt-Tasten, Fortschrittsrahmen, Live-Kopfzeile, Sprache).
- [ ] Offen: Task 6.1 Abgleich mit dem Canvas auf Android hoch/quer und Linux (Nutzer), danach archivieren.
- [x] Task 4.1 Vorlagen-Tab: Tabs als Segment-Umschalter, Vorlagen als aufklappbare Karten mit Bändern und „Starten“ (gewählte Quelle), Vorauswahl aus „Nochmal“ aufgeklappt und ins Bild gescrollt; Zonen-Tab angeglichen; „⌀“ durch „Ø“ ersetzt (Glyphe fehlt in IBM Plex Sans). Entschieden (Nutzer, 2026-10-16): Vorlagen werden im Editor gelöscht, nicht in der Liste. Vorläufig: Titel „Vorlage rudern“ ohne Geräteanzeige; kein „Frei rudern“ im Vorlagen-Tab; Platz für Ghost und Ranglisten-Marken frei.
- [x] Task 4.2 Vorlagen-Editor (Umschalter „Feste Anzahl“/„Offen bis Stopp“, Runden mit `OarStepper`, Ergebnis-Zeile „3 × 1000 m“ ohne Zeitschätzung, vom Nutzer bestätigt) und 4.4 Zahlenfelder als `OarStepper` in Strecken-, Zonen-Editor und „Zone einbauen“; `OarStepper.background` für Karten. Entschieden (Nutzer, 2026-10-16): Pace-Band einer neuen Zone startet bei 2:45–2:50; Grenzen Pace 1:00–5:00, Schlagzahl 10–60, Runden bis 99. Vorläufig: Startwerte neue Strecke 2000 m bzw. 4:00, neue Zone 100 m bzw. 1:00 (Schlagzahl-Band aus, sonst 24–26); Texte aus dem Canvas („Pace-Band“, „Schnellste“ …).
- [x] Task 4.3 Streckenliste (Karte mit Balken, „12× gerudert“, Legende) und Strecken-Kopf (Achse/Länge nebeneinander, Positionen am grossen Balken, Abschnitte als Karte, Versionierungshinweis); `courseRowCountsProvider` zählt Sessions pro Strecke. Vorläufig: Antippen im Balken öffnet „Zone verschieben“ bzw. „Zone einbauen“ an der Lücke; Liste zählt alle Versionen, Hinweis nur die neueste (Simulator zählt mit); Hinweistext wörtlich aus dem Canvas; Button „Strecke anlegen“.
- [x] Task 1.2 dunkles Theme in `lib/app/app_theme.dart`, Tokens `AppFonts`, `AppTextStyles`, `AppRadii`, `AppSpacing`; kein helles Theme mehr. Primärfarbe Blau `zoneIn`, auch für den gefüllten Button (Nutzer, 2026-10-16). Vorläufig: Sekundärfarbe `textMuted`, Material-Schriftgrössen bleiben (Canvas-Grössen in `AppTextStyles`).
- [x] Nach Gerätetest (Nutzer, 2026-10-16): Live-Display ohne Titelbalken (Verbindung, Puls, Quelle und Trennen neben dem Session-Button), Werte deutlich grösser (Obergrenze 56 → 112 px), Überschriften kleiner (10–11 px).
- [x] Nach Gerätetest (Nutzer, 2026-10-17): Pace überall in ganzen Sekunden („2:05“, gerundet), Spec `live-display` als MODIFIED in `ui-design`, `translations` und README nachgeführt.
- [x] Task 4.5 (Nutzer, 2026-10-17): Pace-Band im Zonen-Editor startet mit 10 s Abstand, die schnellste Pace verschiebt das ganze Band, die langsamste ändert den Abstand; am Rand gesperrt.
- [x] Task 3.4 (Nutzer, 2026-10-17): Schlagzahl-Karte zeigt ausserhalb des Bands eine Pille „↑ Mehr Schläge“ / „↓ Weniger Schläge“ wie die Pace-Box, nie abgeschnitten (vorher 13-px-Text mit Ellipsis). Offen: Pace-Pille schneidet auf 360 px Breite das Band ab.
- [x] Nach Gerätetest (Nutzer, 2026-10-17): Fortschrittsrahmen hebt Zonen auf der Rundenspur heller hervor (leer `trackZone`, gefüllt `text`) und markiert das Rundenende mit einer hellen Linie (Rundenspur oben, Streckenspur an jeder Rundengrenze).
- [x] Tasks 5.3, 5.4 (Nutzer, 2026-10-18): Trennen nicht mehr im Live-Display, sondern in der Gerätezeile des Startbildschirms; Zurück, Esc und „Fertig“ führen zum Start und halten die Verbindung; „Sessions“ als Button. Offen: Wortlaut in `start-on-first-stroke` (Szenario „Trennen vor dem ersten Schlag“, Task 3.3) beim Archivieren angleichen.
- [x] Nachtrag (Nutzer, 2026-10-18, `feature/course-session-time`, Task 5.5): Beim Rudern einer Vorlage zeigen die Kacheln auch Zeit und Distanz der Session, hochkant als eigene Reihe über Runde/Watt/Puls, quer unter der Schlagzahl-Karte. Die Kraftkurve braucht hochkant jetzt 806 px Innenhöhe (vorher 720), bei 360×740 entfällt sie.
- [x] Nachtrag (Nutzer, 2026-10-18, `feature/stroke-card-frame`, Task 5.6): Schlagzahl-Karte ohne Band und Kraftkurven-Karte haben einen ruhigen Rahmen (`AppColors.trackZone`, 2 px).
- [x] Nachtrag (Nutzer, 2026-10-18, `feature/live-value-font`, Task 5.7): Live-Werte in Barlow statt Barlow Condensed (bei gleicher Breite rund 12 % niedriger), übrige Screens bleiben Condensed. Hochkant mit Vorlage Schlagzahl-Karte 80 px, Kacheln 64 px; die Kraftkurve erscheint, solange die Pace-Box mit ihr mindestens 336 px hoch bleibt, damit wieder bei 360×740.
- [x] Nachtrag (Nutzer, 2026-10-19, `feature/course-calories`, Task 5.8): Beim Rudern einer Vorlage zeigt eine dritte Kachel neben Zeit und Distanz die Kalorien des Rudergeräts (PM5 0x0033, FTMS Total Energy); ohne Wert keine Kachel. Beim freien Rudern standen sie schon in der Zeile unter den Kacheln.
- [x] Nachtrag (Nutzer, 2026-10-19, `feature/pace-zone-box`, Task 5.9): Die Pace-Box ist wie die Schlagzahl-Karte ganz in der Zonenfarbe getönt, im Band blau, ausserhalb orange; in einem freien Abschnitt bleibt sie wie bisher.
- [x] Nachtrag (Nutzer, 2026-10-19, `feature/summary-pace`, Tasks 5.10, 5.11): Die Zusammenfassung zeigt schnellste, durchschnittliche und langsamste Pace mit ihrem Verlauf als Kurve (Schritte gleicher geruderter Zeit, ohne Pausen, Design D10) und neben Ø und Max. Puls den niedrigsten Puls.
- [x] Nachtrag (Nutzer, 2026-10-19, `feature/live-average-pace`, Task 5.12): Beim Rudern einer Vorlage zeigt die Pace-Box als erste Legendenzeile die Ø Pace der Session; als vierte Kachel wären die Werte auf dem Handy zu klein geworden.
- [x] Nachtrag (Nutzer, 2026-10-26, `feature/upcoming-zone`, Task 5.13): 10 s vor dem Beginn einer Zone blinken ihr Pace- und Schlagzahl-Band gelb an Stelle des Zonenstatus unter der Pace und auf der Schlagzahl-Karte.
- [x] Nachtrag (Nutzer, 2026-10-26, `refactor/pace-band-rounding`, Task 5.14): Der Zonenstatus der Pace vergleicht die angezeigte Pace in ganzen Sekunden, damit „2:45“ bei einem Band von 2:45–2:50 an beiden Grenzen in der Zone ist.
- [x] Nachtrag (Nutzer, 2026-11-05, `feature/resistance-level`, Task 5.15): Meldet ein FTMS-Rudergerät seine Widerstandsstufe (Domyos Woodrower), steht sie klein unter den Watt, frei und mit Vorlage; der Simulator (FTMS) meldet Stufe 5. Das Verstellen des Widerstands über die App ist offen, erst nach einem Test am Gerät. Dafür zeigt der Spike Features und Stufenbereich und setzt die Stufe am Control Point in vier Kodierungen (`feature/spike-resistance`); der Test am Woodrower macht der Nutzer.

### 4. `force-curve`: Kraftkurve lesen, anzeigen, aufzeichnen

Ziel: Kurve des letzten und vorherigen Schlags im Live-Display, Aufzeichnung und Replay, Kurve im Simulator.

Vor dem Start:
- [x] Spike am echten PM5: Characteristic `0x003D` und Paketaufbau per Mitschnitt bestätigen (`make spike`). Braucht den Nutzer am Erg.
  - 2026-10-16: Mitschnitt vom 16.10. enthält keine Kurvenpakete, weil der Spike `003d` nicht abonniert hatte. Spike erweitert (Task 1.0); `0x0035` kommt zweimal pro Schlag, Spitzenkraft 420–550 N, Durchschnitt 280–350 N als Prüfwerte für die Kurve. Neuer Mitschnitt nötig, mit unterschiedlich harten Schlägen.
  - 2026-10-16, zweiter Mitschnitt: Format bestätigt (Byte 0 Pakete/Werte als Nibbles, Byte 1 Zähler, u16 LE in ganzen lbf; Maximum = Spitzenkraft aus `0035`). Kurve kommt direkt nach dem ersten `0035` am Ende des Durchzugs, rund 2 s vor dem `Stroke`-Ereignis; erste Kurve ab Schlag 2. Fixture `force_curve.jsonl` (17 Kurven).
  - Nutzer (2026-10-16): Schlaglänge an der Kurve anzeigen, wenn vorhanden (Byte 6 von `0035`, 0.01 m; FTMS hat keine). Design D4, neuer Task 3.2. Vorläufig: Simulator liefert 0.8–1.3 m statt fest 1.4 m.
- [ ] Rohpakete tragen nach `device-types` ein Protokoll; die Kurvenpakete passen dort hinein.
- [ ] Platz der Karte im Layout aus `ui-design`.
- [x] Tasks 1.2, 2.1–2.3: Ereignis `StrokeForceCurve` (Schlagnummer, Kräfte in N, Schlaglänge), `Pm5Decoder` setzt `003d` zusammen und verwirft unvollständige Kurven, PM5 abonniert `003d`, Simulator sendet Kurven (Länge 1.05 ± 0.1 m), Replay getestet. Die Kurve kommt 1.5–2 s vor dem `Stroke` desselben Schlags.
- [x] Tasks 3.1, 3.2: Widget `ForceCurve` (Varianten card/strip/inline/tinted, letzter und vorheriger Schlag, Warten), Schlaglänge per `formatDriveLength`, neues Token `AppColors.previousCurve`. Vorläufig: Läufe gleicher Werte für die Darstellung zusammengefasst und geglättet.
- [x] Task 3.3: Kraftkurve mit Schlaglänge in allen vier Live-Layouts; Quellen melden `providesForceCurves` (PM5 und PM5-Simulator ja, FTMS nein, Replay nur mit Kurvenpaketen). Feste Kartenhöhen aus ui-design beibehalten (120/72 px statt ~96/44 px).
- [x] Nach Gerätetest (Nutzer, 2026-10-17): Schlaglänge in ganzen Zentimetern („106 cm“), Spec und D4 nachgeführt; Kachel „In Zone“ im Live-Display mit Vorlage entfernt (Anteil weiter in der Zusammenfassung).
- [x] Task 3.5 (Nutzer, 2026-10-18): Kraftkurve auf absoluter Skala 0–1000 N (Stufen von 500 N nur nach oben, Rücksetzen bei neuer Quelle/Session), Hilfslinien alle 500 N, Spitzenkraft „620 N“ neben der Schlaglänge. Fixture-Spitzen 147–658 N.

### 5. `heart-rate`: Brustgurt direkt koppeln, RR-Intervalle, HRV

Ziel: Gurt koppeln und merken, automatisch verbinden, Puls-Vorrang Gurt vor PM5, RR-Intervalle, Ø/max Puls und RMSSD in der Zusammenfassung.

Vor dem Start anpassen:
- [x] Task 3.1 erhöht das Schema: nach `device-types` und `statistics` ist das **Schema 6** (`statistics` 1.7 nimmt 5, 2026-10-16). In Proposal und Design vermerkt, `tasks.md` spricht ohnehin von „erhöhen“.
- [ ] Design bindet den Gurt an `Pm5BleSource`; nach `device-types` gibt es auch FTMS-Quellen. Festlegen, ob der Gurt auch mit FTMS verbunden wird.
- [ ] Gleiche MODIFIED-Anforderungen wie `device-types` (`rowing-telemetry` „Laufende Messwerte bereitstellen“, `session-recording` „Session vollständig speichern“, „Rohdaten für Replay speichern“): Deltas auf den Text nach dem Archivieren von `device-types` umschreiben, sonst überschreibt das Archiv dessen Änderungen.

Entscheide F3 und F4 getroffen (Design D7, D8).

- [x] Artefakte an `device-types`, `ui-design` und `statistics` angeglichen (2026-10-16): BLE-Rudergerät statt PM5 (`BleRowerSource`, `erg_protocol`), Vorrangregel in einem `HeartRateDecoder`, der den Decoder des Rudergeräts umhüllt; FTMS-Puls dekodiert schon und dient als Rückfall; Schema 6 mit `from5To6`. `tasks.md` neu: 25 Tasks in 6 Gruppen; 2, 4 und der Spike (1) parallel, 3 nach 2.1.
- [ ] Archivieren: `device-types` vor `heart-rate`, weil dessen MODIFIED-Anforderungen auf `device-types` aufbauen.
- [x] Tasks 2.1–2.5 Protokoll: `HeartBeatIntervals` mit `intervalEnds` (D4), `StatusTick.copyWith(heartRate:)`, Parser und Encoder für `2a37`, `HeartRateDecoder` umhüllt PM5- und FTMS-Decoder (`ErgDecoder.forProtocol`). Vorläufig: Gurt-Puls 0 gilt als kein Wert; Gurt gilt bis einschliesslich 3 s; `elapsed` der RR-Ereignisse ist die des letzten Ticks. Offen: 2.6 braucht die Fixture vom Gerät.
- [x] Tasks 4.1, 4.2, 4.4, 4.5 Gurt-Verbindung: `HeartRateTransport` (`scanHeartRateMonitors`, `connectHeartRateMonitor`), `setUpHeartRateMonitor`, `BleRowerSource.attachHeartRate`, gemeinsame 30-s-Schleife `reconnectWithin`, `heartRateMonitorProvider` mit Phasen und `retry()`. Vorläufig: Gurt nur im Speicher bis 4.3; nach 30 s ohne Rudergerät wird der Gurt getrennt; nach Fehler nur über `retry()`; der Provider verbindet nur, solange ihn jemand beobachtet (5.3 hängt ihn ein). Manuell offen: echter Gurt in der Suche. F18 entschieden: Gurt in `shared_preferences`.
- [x] Tasks 4.3, 3.1–3.4: Gurt in `shared_preferences` (Key `heartRateMonitor`, JSON id/name); Schema 6 mit `rr_intervals` und Ø/Max-Puls/RMSSD in `sessions`; RR-Intervalle auf der Wanduhr-Achse der Session (nicht der PM5-Uhr, die in Pausen steht); Export/Import mit Pulswerten. Vorläufig: frühe Intervalle der ersten Messung können leicht negative Zeiten haben.
- [x] Tasks 5.1, 5.2: Bereich „Pulsgurt“ in „Geräte wählen“ mit eigener Gurt-Suche (`heart_rate_search_screen.dart`, 15 s, Tipps, „Erneut suchen“), Koppeln/Wechseln/Vergessen; Startbildschirm zeigt den Gurt unter dem Rudergerät. Vorläufig: Wahl in der Suche koppelt sofort; der Berechtigungstext der Gurt-Suche spricht noch vom Rudergerät.
- [x] Tasks 5.3–5.5: `HeartRateIndicator` neben `ConnectionIndicator` mit `HeartRateNotice` und „Erneut versuchen“; Gurt verbindet app-weit, sobald das Rudergerät verbunden ist (`ref.listen` in `aergrow_app.dart`, D7); letztes RR-Intervall klein beim Puls, ausgeblendet ab 3 s; Zusammenfassung mit Ø/Max-Puls, RR-Kurve und HRV (RMSSD). Vorläufig: RR-Kurve und Herz in `AppColors.zoneOut` (orange) wie das bestehende `HeartIcon`; Text „Wartet auf das Rudergerät“ für einen bereiten Gurt.
- [x] Tasks 6.1, 6.2: README-Abschnitt „Pulsgurt“, Dateiformat um `2a37` und Pulswerte ergänzt. Offen: 1.1/1.2 Mitschnitt mit Gurt und 6.3 Test am Gerät; 2.6 braucht die Fixture.
- [x] Erster Gerätetest (Nutzer, 2026-10-16): BLE-Gurt ohne PM5 gekoppelt, Puls wird angezeigt. Offen für 6.3: mit PM5 und mit FTMS-Rudergerät, Wiederverbinden, Rückfall auf den Puls des Rudergeräts, Zusammenfassung, Replay, Export/Import; danach 1.1/1.2 Mitschnitt mit `make spike`.

### 6. `statistics`: Ranglisten pro Vorlage, Strecke und Zone

Ziel: Plätze 1–3 jeder Vorlage, Strecke und Zone. Gewertet wird die Zeit (Distanzachse) bzw. die Meter (Zeitachse) nach Wanduhr inklusive Pausen, dazu Pace und Datum. Anzeige in der Vorlagenwahl, in einer neuen Detailansicht von Strecke und Zone und als Marke in der Zusammenfassung. Proposal, Design und Spec stehen (2026-10-16), Entscheide in Design D2–D6.

Vor dem Start:
- [x] `tasks.md` erstellt (2026-10-16), 12 Tasks in 5 Gruppen; Task 1.7 (Import) am 2026-10-16 ergänzt.
- [x] Reihenfolge entschieden (2026-10-16): **nach `ui-design`**. Vorlagenwahl (`ui-design` 4.1), Strecken-/Zonenliste (4.3) und Zusammenfassung (5.2) werden dort neu gestaltet. Würden die Plätze vorher eingebaut, müsste man sie zweimal gestalten. Gruppe 1 (Ranglisten berechnen) hängt an nichts Offenem und darf vorgezogen werden.

Bei der Umsetzung mitnehmen:
- Keine eigene Tabelle (Design D1). Einziger Schema-Wechsel ist die Import-Markierung aus Task 1.7 (Schema 5); `heart-rate` nimmt danach 6.
- Gezählt werden nur die Quellen `pm5` und `ftms`, nicht `simulator` und `replay` (Design D3).

Gruppe 1 umgesetzt (2026-10-16, Tasks 1.1–1.6, `lib/data/statistics/`):
- [x] Messung 1.6: 200 Sessions mit je 3 Runden und 2 Zonen, alle vier Abfragen zusammen 22–69 ms. Kein Index, kein Schema-Wechsel, Schema bleibt 4.
- [x] Kleine Entscheide: aktuelle Länge zuerst, ältere nach Länge aufsteigend; zusätzlich nach Achse gruppiert; bei Gleichstand gewinnt, wer früher gerudert hat; Status der Session wird nicht gefiltert (auch abgebrochene Sessions zählen mit vollständigen Runden); Vorlage mit heute offener Rundenzahl hat keine Rangliste.
- [x] Entschieden (Nutzer, 2026-10-16): importierte Sessions werden nicht mit der Statistik verbunden. Task 1.7: Spalte `sessions.imported`, Schema 5 mit `from4To5`, der Import setzt sie, alle Ranglisten lassen importierte Sessions weg; Spec-Szenario „Import“ und Design D1/D3 angepasst, `heart-rate` auf Schema 6 nachgeführt.
- [x] Task 3.1 Plätze 1–3 in der aufgeklappten Vorlage (`template_podium.dart`), Lücke für das Ghost-Symbol bei Platz 1. Vorläufig: Überschrift „Bestleistungen“ und Hinweistexte selbst formuliert; Datum als `DateFormat.yMd`; ist die aktuelle Länge noch nie gerudert, erscheint der Hinweis statt einer älteren Rangliste.
- [x] Tasks 2.1/2.2 Detailansicht von Strecke und Zone (`course_detail_screen.dart`, `zone_detail_screen.dart`, gemeinsam `lib/features/statistics/ranking_sections.dart`), Tipp in der Liste öffnet sie, Stift öffnet den Editor. Vorläufig: nach dem Speichern zurück in die Detailansicht; Löschen bleibt in Liste bzw. Editor; Zeit im Rundenformat (`0:18.2`); Datum kurz ohne Uhrzeit; hat die aktuelle Länge keine Einträge, fehlt ihre Rangliste ohne eigenen Hinweis.
- [x] Task 4.1 Platzmarken in der Zusammenfassung (`session_places.dart`, `sessionPlacesProvider`): Session neben dem Titel, Runden und Zonenfahrten („Sprint · Platz 1“) in der Rundenzeile; Marken folgen der Rangliste live; Simulator, Replay und Import ohne Marken. Vorläufig: neutrale Pille für alle Plätze (kein Ghost-Violett); Session ohne Vorlage ohne eigene Marke.
- [x] Task 5.1 README-Abschnitt „Bestenlisten“ (Ebenen, Orte der Anzeige, Wanduhr inkl. Pausen, Simulator/Replay/Import zählen nicht).
- [x] Nach 5.1 bereinigt: Strecken-Detailansicht schliesst sich, wenn die Strecke gelöscht wird (wie bei Zonen); Design D6 nennt den Hinweis bei offener Rundenzahl.
- [x] Entschieden (Nutzer, 2026-10-16): Die Bestenliste gehört zur Vorlage und wird nicht nach Strecke getrennt; Sessions mit einer früheren Strecke gleicher Achse und Länge bleiben in derselben Liste.
- [ ] Offen: Task 5.2 Test am Gerät (Nutzer), danach archivieren.

### 7. `ghost`: gegen die eigene Bestzeit rudern

Ziel: violettes Schiffchen auf den Spuren des Fortschrittsrahmens, Abstand in Metern und Sekunden, Ghost-Symbol bei Platz 1 in der Vorlagenwahl. Der Ghost jeder Spur ist Platz 1 der Rangliste dieser Ebene aus `statistics` (F5, Design D2, Spec „Platz 1 ist der Ghost“).

Entscheide F6–F8 getroffen (Design D4, D5).

- [x] `tasks.md` erstellt (2026-10-16): 13 Tasks in 8 Gruppen. Gruppe 1 zuerst, dann 2–6 parallel, 7 verbindet, 8 schliesst ab. `AppColors.ghost` und das Ghost-Schiffchen im Painter gibt es schon; Task 4.1 baut es nach D5 um.
- [x] Entschieden (Nutzer, 2026-10-16, Design D6): auf Zeitstrecken sitzt der Ghost neben dem eigenen Schiffchen, so gewollt; eine neue Bestleistung in derselben Session wird ab der nächsten Runde bzw. Fahrt zum Ghost; in der Vorlagenwahl nur das Symbol; im Simulator läuft der Ghost mit. Danach `tasks.md` ergänzen (`/opsx:continue ghost`). Braucht den Fortschrittsrahmen aus `ui-design` und die Ranglisten aus `statistics`.
- [x] Gruppe 1: `GhostTrack`, `GhostPoint`, `GhostGap` in `lib/data/ghost/ghost.dart`, `GhostSymbol` in `lib/app/widgets/ghost_symbol.dart`. Vorläufig: Symbol 10 × 4 px mit 1 px Rand (Höhe aus dem Canvas); Gleichstand als Abstand 0 ohne Rückstand.
- [x] Task 6.1 `GhostSymbol` bei Platz 1 in `TemplatePodium`, Platz 2 und 3 mit leerem Slot gleicher Breite.
- [x] Task 5.1 Ghost-Zeile in der Pace-Box (`PaceBox.ghostGap`): „7.6 s vor dir“ orange, „12 m hinter dir“ blau, ab 60 s als `1:12.3`. Vorläufig: Gleichstand als „gleichauf“ gedämpft; Zehntel immer mit Punkt; `_aroundPace` 160 → 190, die Pace wird mit Ghost-Zeile etwas kleiner.
- [x] Task 4.1 Ghost rückt bei Überlappung quer nach aussen (D5), erkannt an der Form der Rauten, höchstens 9.5 px über die Box; Ghosts von aussen nach innen gesetzt. Neue Goldens `progress_frame_ghost_*.png`. Offen für Gruppe 7: hochkant oben nur 8 px Platz, ein Ghost auf der äussersten Spur ragt 1.5 px unter die AppBar → oberes Padding in `live_course.dart` auf mindestens 10 px.
- [x] Tasks 2.1, 2.2, 3.1–3.3: `GhostRepository.track`, `liveGhostsProvider` (folgt der Rangliste live, auch im Simulator), `LapProgress.courseTime/segmentTime/courseDistanceDm`, `ghostShares` und `ghostGap` in `lib/data/ghost/ghost_progress.dart`. Vorläufig: neue Bestleistung wird erst nach dem Schreiben der Runde Ghost, also bis etwa 2 s nach Beginn der nächsten Runde (das Schiffchen springt einmal); kein Abstand mehr, wenn man weiter ist, als der Ghost je kam.
- [x] Task 7.1 Ghosts im Live-Display: `LiveScreen` rechnet `ghostShares` und `ghostGap` pro Tick und gibt sie an `CourseLiveView`; oberes Padding hochkant jetzt 10 px (Überhang des Ghosts). Offen: 8.1 README, 8.2 Test am Gerät (Nutzer).
- [x] Task 8.1 README-Abschnitt „Ghost“. Offen: 8.2 Test am Gerät (Nutzer), danach archivieren (nach `statistics`).
- [x] Nachtrag (Nutzer, 2026-10-18, `feature/time-course-no-ghost`): Auf Zeitstrecken zeigt der Rahmen keinen Ghost mehr, der Vorsprung oder Rückstand steht nur in Metern in der Pace-Box (D6 geändert, Task 7.2).

### 8. `rename-stroke-and-split`: App heisst „Stroke & Split“

Ziel: Anzeigename, Paket- und App-ID `strokesplit`, Dateiendung `.strokesplit`, Import liest weiter `.aergrow`.

Vor dem Start:
- [x] Entscheide F9, F10 (2026-10-16): „Stroke & Split“, App-ID `ch.strokesplit`.
- [x] Domains sichern, Markenrecherche (Swissreg, EUIPO, USPTO). Ausserhalb der App, durch den Nutzer; Namensrechte bestätigt (2026-10-18).
- [x] Neue App-ID ist unter Android eine neue App: Umzug per Export/Import im README beschreiben (Task im Change).
- [x] Ist `gitlab-pipeline` schon umgesetzt: `APP_NAME` in `.gitlab-ci.yml`, Default in `tool/build_appimage.sh` und `linux/packaging/app.desktop.in` (`Name`, `StartupWMClass`) mit umstellen (Design D9 von `gitlab-pipeline`). Task in `tasks.md` ergänzen.
- [x] Task 1.1 vorgezogen (Nutzer, 2026-10-17): Anzeigename „Stroke & Split“ in App, Android-Label, iOS, macOS (`CFBundleDisplayName`, `PRODUCT_NAME` bleibt), Linux-Fenstertitel, Desktop-Datei und Dateidialog. Dateiendung, Paket, App-ID und Datenbank bleiben vorerst `aergrow`; die App-ID-Änderung (3.2) installiert eine neue App neben der alten.
- [x] Umgesetzt (2026-10-18, `feature/rename-strokesplit`): Export `.strokesplit`/`strokesplit-raw` (Import liest weiter `.aergrow`), Dart-Paket `strokesplit`, App-ID `ch.strokesplit.strokesplit` auf allen Plattformen, CI-`APP_NAME` und AppImage `strokesplit` (Task 3.4), Übernahme von `aergrow.sqlite` unter Linux, README-Abschnitt „Umzug von AergRow“, Canvas „Stroke & Split Frontend“. Offen: 3.3 manueller Test auf Linux mit bestehenden Sessions. macOS (Sandbox) zieht wie Android/iOS per Export/Import um. drift-Schema-Ordner heissen weiter `aergrow`.

### 9. `gitlab-pipeline`: Tests in CI, Releases mit APK und AppImage

Ziel: `make check` in jeder MR und auf `main`. Ein Tag `vX.Y.Z` auf `main` erzeugt ein GitLab-Release mit einer debug-signierten Universal-APK und einem Linux-AppImage (x86_64), gebaut in Docker-Images (`cirruslabs/flutter`). Version aus dem Tag, Versionscode `CI_PIPELINE_IID`, Downloads in der Generic Package Registry.

Vor dem Start:
- [x] Task 1.1: Einen Image-Tag `3.47.7` gibt es nicht (Liste endet bei `3.44.0` mit Dart 3.12). Die Jobs nutzen `3.44.0` für JDK und Android-SDK und stellen Flutter im `before_script` auf 3.47.7 um (Design D1).
- [ ] Task 2.2 (Nutzer, in GitLab): Debug-Keystore **Base64-kodiert** als protected File-Variable `ANDROID_DEBUG_KEYSTORE` (GitLab speichert Variablen als Text, Design D5), `v*` als geschützten Tag einrichten. Anleitung im README unter „Einrichtung in GitLab“.
- [x] Umgesetzt (2026-10-16): `check` in jeder Pipeline, `build-apk`, `build-appimage`, `verify-tag`, `upload`, `release` für Tags `vX.Y.Z`; `make apk`, `make appimage`; Branch-Pipeline 312096 grün. Workflow-Regel für `web`/`api` ergänzt, damit Pipelines von Hand startbar sind. Andere Tags lassen nur `check` laufen.
- [x] Umzug nach GitHub (2026-11-06): Pipeline als GitHub Actions nachgebaut (`.github/workflows/ci.yml`, `check.yml`, `release.yml`), `.gitlab-ci.yml` entfernt. Gleiche Images und `make`-Ziele; Release-Dateien hängen direkt am GitHub-Release statt in der Package Registry, Versionscode `GITHUB_RUN_NUMBER`, Keystore als Repository-Secret. Ohne geschützte Tags: Das Secret sieht jeder Workflow-Lauf im Repo, Pull Requests aus Forks nicht. Die GitLab-spezifischen Tasks im Change gelten sinngemäss.
- [x] Ausbau der Actions (2026-11-06, `feat/actions`): Dependabot für pub, Gradle und Actions; `lint-workflows.yml` mit actionlint und zizmor, Actions auf SHAs gepinnt, Release-Builds ohne Cache; Job `generated` (`make check-generated`); Builds in `build.yml`, auch in CI (Pull Requests nur bei geänderten Build-Dateien); Coverage (`make coverage`) in der Job-Zusammenfassung; Build-Provenance für Release-Dateien; Release-Notes mit git-cliff (`cliff.toml`); Commitlint in Pull Requests; Code einmal komplett formatiert, `make analyze` prüft die Formatierung.
- [ ] Offen: Probe-Release `v0.1.0` nach 2.2 verifiziert 2.3, 3.3 und 4.1–4.5; AppImage-Fenster kurz ansehen (3.2); README-Durchsicht (5.1); danach 5.2.

Später, nicht Teil des Changes: Release-Keystore und Play Store (Schlüsselwechsel am besten zusammen mit der neuen App-ID aus `rename-stroke-and-split`). Eigenes App-Icon statt des Platzhalters: erledigt (2026-10-18, `feature/app-icon`, `make icons`).

### 10. `start-on-first-stroke`: Vorlage startet mit dem ersten Ruderschlag

Wunsch des Nutzers nach dem Gerätetest (2026-10-16). Stand 10/11.

- [x] Umgesetzt: Nach der Vorlagenwahl ist die Session „bereit“ (Hinweis, keine Zeit, kein Datenbankeintrag), der erste Schlag (Schlagmeldung oder Distanzanstieg) startet sie; Nullpunkt ist der letzte Messwert davor. Freies Rudern unverändert. Simulator rudert ab Verbindung, Bereit-Zustand dort kaum sichtbar.
- [ ] Task 4.2 (Nutzer): Gerätetest am PM5.

### 11. `auto-pause`: Session pausiert, wenn man aufhört zu rudern

Ziel: 3 s nach dem fälligen Schlag pausiert die Session; Sessionzeit, Rundenzeit und Zeitstrecken stehen still, bis wieder gerudert wird. Pausen werden gespeichert (Schema 7) und in der Zusammenfassung gezeigt; Ranglisten zählen ohne Pausen.

- [x] Umgesetzt (2026-10-19, `feature/auto-pause`): Pausenerkennung für PM5 und FTMS (Schlag zählt zum Zeitpunkt, an dem er gerudert wurde; Pause endet auch ohne gemeldeten Schlag, sobald die Meter wieder steigen), Schema 7 mit Tabelle `pauses` und Sessionzeit ohne Pausen, Hinweis „Pause“ in der Live-Ansicht, Pausen-Kachel in der Zusammenfassung, Ranglisten ohne Pausen (Change `statistics` angepasst). Entschieden (Nutzer): Schwelle 3 s nach dem fälligen Schlag, freies Rudern startet sofort, Pause am Ende wird verworfen, Ghost steht in der Pause still, alte Runden mit Pausen bleiben in den Ranglisten. Offen: 5.2 Gerätetest.

### 12. `health-connect`: Sessions an Health Connect übertragen

Wunsch des Nutzers (2026-11-02): Sessions in Google Fit sehen. Google Fit nimmt keine neuen Apps an und läuft Ende 2026 aus, daher Health Connect unter Android; Fit bzw. Google Health liest daraus.

- [x] Geplant (2026-11-02, `docs/health-connect-proposal`): eigener Kotlin-Kanal zu `connect-client` statt Paket `health` (dieses schreibt Puls nur als Einzelwerte, keine Leistung, Runden, Pausen und kein Ersetzen); Einheit `ROWING_MACHINE` mit Distanz, Kalorien, Puls, Leistung, Geschwindigkeit, Runden und Pausen; automatisch nach jeder Session von PM5/FTMS, nachträglich aus Liste und Zusammenfassung; erneutes Senden ersetzt; Schema 8 (`sessions.health_exported_at`); minSdk 26, `FlutterFragmentActivity`.
- [x] Umsetzung begonnen (2026-11-02, `feature/health-connect`): Task 1.1 Android-Gerüst mit `connect-client` 1.1.0 (stabil), minSdk 26, `FlutterFragmentActivity`, Kotlin-Kanal; Release-APK baut lokal.
- [x] Abbildung, Schreiben und Status (2026-11-02, Tasks 2.1–3.3, 4.1): `HealthWorkout` aus den gespeicherten Messwerten, Schema 8, Kotlin-`writeSession` (löscht eigene Records im Zeitraum, dann ein `insertRecords`), `HealthExporter` aus `SessionRecorder.stop()` (nicht `finishedSessionProvider`, der nur selbst endende Sessions meldet), Einstellung `healthConnect`. Replays werden wie der Simulator nicht übertragen. Laut Quellen von `connect-client` 1.1.0 passen `PAUSE`- und `ROWING_MACHINE`-Segmente zur Rudergerät-Einheit.
- [x] Einstieg (2026-11-02, Task 4.2): Herz-Symbol in der App-Leiste von „Sessions“ (nur Android) öffnet ein Bottom-Sheet mit Schalter, Status (fehlt, veraltet, Berechtigung fehlt, aktiv), Health Connect öffnen und Datenschutz-Hinweis.
- [x] Senden (2026-11-02, Task 4.3): „An Health Connect senden“ im Menü der Liste und in der Zusammenfassung, Status „Übertragen am …“ / „Nicht übertragen“; Fehler nach dem Rudern meldet die App global per Snackbar, bei fehlender Berechtigung mit „Erteilen“ (ein langes Label lässt die Snackbar bei 390 px überlaufen).
- [x] Datenschutz-Hinweis (2026-11-02, Task 4.4): eigene Seite, aus dem Bottom-Sheet und von Health Connect geöffnet, beim Start (`launchAction`) und während die App läuft (`onNewIntent`).
- [x] Dokumentation (2026-11-02, Task 5.1): README-Abschnitt „Health Connect“; Play-Store-Erklärung steht unter „Offene Punkte“.
- [ ] Task 1.2 (Nutzer, nach 1.1): Probe-Einheit am Gerät, klärt, ob Rudergerät-Segmente angenommen werden.
- [ ] Task 6.1 (Nutzer): Gerätetest, auch ob Google Fit bzw. Google Health die Einheit zeigt.

### 13. `resistance-control`: Widerstandsstufe von FTMS-Rudergeräten setzen

Wunsch des Nutzers (2026-11-05) für den Domyos Woodrower. Der Spike am Gerät zeigt: Stufe setzbar über „Set Target Resistance Level“ als u8 in Zehnteln, Bereich 1–15; die Stufensenkung nach der Pause im Mitschnitt war eine Handänderung des Nutzers.

- [x] Geplant (2026-11-05, `docs/resistance-control-proposal`): −/+ an der Stufe unter den Watt; optionale Stufe pro Zone, als Kopie im Segment (Schema 9); Grundstufe = Stufe beim Start bzw. zuletzt von Hand gesetzte in Segmenten ohne Stufe; Handänderung (App oder Gerät, auch in der Pause) gilt bis zum nächsten Segment; nach Wiederverbinden erneut senden; Rückfall auf s16 bei „ungültiger Wert“; Simulator (FTMS) nimmt die Stufe an.
- [x] Protokoll (2026-11-05, Tasks 1.1–1.2): Features und Stufenbereich lesen, „Set Target Resistance Level“ als u8 oder s16 in Zehnteln, Antworten des Control Points; eine in Zehnteln gemeldete Stufe wird auf ganze Stufen umgerechnet.
- [x] Verbindung (2026-11-05, Tasks 2.1–2.2): Beim Verbinden liest die App Features und Stufenbereich; nur wenn beide passen, bietet die Quelle eine `ResistanceControl` an. Befehle gehen nacheinander über den Control Point, Antwort innert 2 s; bei `05` erneut Request Control, bei `03` einmal s16 und danach für die Verbindung bei s16. Nach dem Wiederverbinden gilt die Steuerung der neuen Verbindung.
- [x] Simulator (2026-11-05, Task 2.3): Im FTMS-Modus nimmt er Stufen 1–15 an und meldet sie ab dem nächsten Datensatz, Start bei 5.
- [x] Datenmodell (2026-11-05, Tasks 3.1–3.2): Schema 9 mit `resistance_level` in `zones` und `course_segments` (`from8To9`); Zone und Segment tragen die Stufe, eine Änderung der Zone gilt in allen Strecken; Stufe unter 1 ist ein Fehler, eine Stufe allein ersetzt kein Band. Kopie der Strecke im `.strokesplit`-Header mit optionalem `resistanceLevel`, der Import legt die Zone mit Stufe an.
- [x] Logik (2026-11-05, Task 4.1): `ResistanceDirector` entscheidet aus Segmentbeginn, gemeldeter Stufe, −/+ und Wiederverbinden, welche Stufe gesendet wird; 3 s nach dem Senden gilt die alte Stufe nicht als Handänderung.
- [x] Provider (2026-11-05, Task 4.2): `resistanceProvider` verbindet Logik, aktive Quelle, gemeldete Stufe und Segmente der laufenden Session; Stufen gehen nacheinander raus, eine neuere ersetzt eine wartende; Ablehnung zeigt 2 s einen Hinweis. Beginnt eine Session, ist die Stufe des Geräts die Grundstufe.
- [x] Live-Anzeige (2026-11-05, Task 5.1): Ruderblatt-Tasten an der Stufe unter den Watt, nur bei setzbarer Stufe, an der Grenze gesperrt; „Stufe nicht gesetzt“ für 2 s. Abweichung von D6: Tasten 44 × 47 (kompakter `OarStepper`) statt 48 × 48; ab 120 px Kachelhöhe in der Fussnotenzeile, sonst links und rechts neben dem Wert (kompakte Kachel mit Vorlage, 64 px hoch).
- [x] Zonen (2026-11-05, Task 5.2): Schalter „Widerstandsstufe“ mit Ruderblatt-Tasten 1–25 (Start 5) im Zoneneditor; „· Stufe 10“ hinter den Bändern in Zonenliste, Zonendetails, Streckeneditor und Vorlagen.
- [x] README (2026-11-05, Task 6.1): Setzen der Stufe über die Ruderblatt-Tasten und pro Zone, Grundstufe, Änderung von Hand, Stand der Gerätetests.
- [ ] Gerätetest 6.2 am Woodrower (Nutzer).

### 14. `template-screen`: Vorlage auf eigenem Screen, Ghost abschaltbar

Wunsch des Nutzers (2026-11-06): Ein Tipp auf eine Vorlage öffnet einen eigenen Screen statt die Karte aufzuklappen; dort lässt sich der Ghost vor dem Start abschalten.

- [x] Geplant (2026-11-06, `feature/template-screen`). Entschieden (Nutzer): Ghost aus heisst alle drei Spuren und keine Abstandszeile; nur vor dem Start wählbar, nicht während der Fahrt; nicht gespeichert, jeder Start beginnt mit Ghost an; „Nochmal“ öffnet die Liste und darüber gleich den Vorlagen-Screen, Zurück führt zur Liste. Vorgabe ohne Widerspruch: Schalter über „Starten“, sichtbar auch ohne Bestleistung. Löst die aufklappbaren Karten aus `ui-design` (D6, Task 4.1) und die Plätze in der aufgeklappten Vorlage aus `statistics` ab.
- [x] Geändert (Nutzer, 2026-11-06): Die Kachel „Nochmal“ entfällt ganz, statt Liste und Vorlagen-Screen zu öffnen (D3, Task 3.2). Neues Delta `erg-connection` ohne „Nochmal“; deshalb erst nach `ui-design`, `ghost` und `statistics` archivieren.
- [ ] Umsetzung begonnen (2026-11-06, `feature/template-screen-apply`): 1.1–4.1 umgesetzt: Ghost-Wahl in der Aufnahme, Live-Display ohne Ghost, Vorlagen-Screen mit Schalter, kompakte Liste, „Nochmal“ entfernt, README und Vermerke in `ui-design` und `statistics`. 4.2 geprüft (`make check`, App unter Linux mit Simulator; den Ghost zeigt der Simulator mangels gewerteter Sessions nicht, das decken die Widget-Tests ab). Offen: 4.3 Gerätetest (Nutzer).

### 15. `course-rowing-free`: Strecke ohne Vorlage rudern, mit Runden, Dauer oder offen

Wunsch des Nutzers (2026-11-06): eine Strecke wählen, auf einem weiteren Screen Runden, Gesamtdauer oder offen wählen und starten, ohne dass eine Vorlage gespeichert wird.

- [x] Proposal (2026-11-06). Entschieden (Nutzer): Einstieg über „Rudern“ in der Detailansicht der Strecke; drei sich ausschliessende Optionen, sichtbar nur die Eingabe der gewählten; Dauer nur hier, nicht in Vorlagen; Ende nach effektiver Ruderzeit ohne Pausen, auch mitten in der Runde; Dauer in Schritten von 1 min; geplante Dauer wird gespeichert (Schema 10); Ghost-Schalter auch hier; „Nochmal“ entfällt (in `template-screen`). Vorgaben ohne Rückmeldung: Dauer 1–180 min, Start 30 min; angebrochene Runde zählt nicht; Titel „Strecke · 30 min“.
- [x] Design, Specs und Tasks (2026-11-06, 12 Tasks). Geklärt: Der `LapTracker` misst Zeitstrecken schon mit der Ruderzeit ohne Pausen (`auto-pause`), Runden und Dauer zählen also gleich. Entscheide im Design: `SessionPlan` statt `SessionTemplate` im Recorder (D1), Ende im Akkumulator beim ersten Datenpunkt über der Dauer (D2), `durationMs` im bestehenden Block `template` des Exports (D3), äusserer Ring nach Zeit ohne Rundengrenzen (D4). Vorgaben ohne Rückmeldung: Start-Option „Runden“ mit 3 Runden.
- [ ] Umsetzung begonnen (2026-11-06, `feature/course-rowing-free`): 1.1 `SessionPlan` im Recorder, 2.1 Schema 10, 2.2 Export und Import der Dauer, 3.1 Ende nach Ruderzeit, 3.2 Ranglisten ohne Vorlage (ohne Codeänderung, nur Test), 4.1 Ring und Restzeit bei Dauer, 4.2 Ghost ohne Vorlage (nur Test), 5.1 Start-Screen `CourseStartScreen`, 6.1 Titel ohne Vorlage (Streckenname über `courseVersionProvider` statt Join), 7.1 README, 7.2 `make check` und Linux-Test mit Simulator (3 min mit 36 s Pause, Ende nach 3:00 Ruderzeit, „Seerunde · 3 min“, keine neue Vorlage). Offen: 7.3 Gerätetest (Nutzer). Abweichungen: `LapCount` statt `Laps` (Name der Drift-Tabelle); Optionsleiste des Vorlagen-Editors (`SegmentChoice`) statt Material-`SegmentedButton`.

### 16. `zone-level-only`: Zone nur mit Widerstandsstufe

Wunsch des Nutzers (2026-11-07): Beim Anlegen einer Zone soll neben Pace und Schlagzahl auch die Stufe allein genügen; nötig ist mindestens eins der drei.

- [x] Proposal, Design, Specs und Tasks (2026-11-07, `docs/zone-level-only-proposal`, 5 Tasks). Entschieden (Nutzer): mindestens eins von Pace, Schlagzahl oder Stufe; die Zonenliste bleibt, sie zeigt die Werte schon. Vorgaben ohne Rückmeldung: Eine Zone nur mit Stufe gilt als Zone (Name im Streckenbalken, in der Pace-Box und im Rahmen, Stufe wird gesetzt), aber ohne Zonenmarkierung, ohne Anteil in der Zone und ohne Hinweis „Gleich …“; Ranglisten und Zonen-Ghost zählen wie bei jeder Zone. Im Design: `isFree` zählt die Stufe, neu `hasBand` für Messung und Hinweis (D1); Fehler `targetMissing` (D2). Keine Schema-Änderung. Das Delta `zones` ändert die Requirement „Widerstandsstufe einer Zone“ aus `resistance-control`, deshalb erst danach archivieren.
- [ ] Umsetzung begonnen (2026-11-07, `feature/zone-level-only`): 1.1 Zone nur mit Stufe speichern, Fehler `targetMissing`, Texte de/en; 2.1 `isFree` zählt die Stufe, `hasBand` für Anteil in der Zone und Hinweis „Gleich …“; 3.1 README.

## Offene Entscheide

| | Frage | Change | Entscheidet sich vor |
|---|---|---|---|
| ~~F1~~ | Puls-Herkunft: Gurt in „Geräte wählen“ wählen; Puls vom BLE-Gurt, sonst vom PM5, sonst keine Anzeige; Herkunft wird **nicht** angezeigt (2026-10-16) | ui-design, heart-rate | entschieden |
| ~~F2~~ | Startbildschirm: **Mittelweg** (2026-10-16): Quelle, „Rudern“, „Frei rudern“, Kachel „Nochmal“ mit der zuletzt geruderten Vorlage, Link „Sessions“ | ui-design | entschieden |
| ~~F3~~ | Welcher Puls gilt, wenn FTMS-Gerät und Gurt beide liefern: **der Gurt** (2026-10-16) | heart-rate | entschieden |
| ~~F4~~ | Gurt auch mit FTMS-Rudergeräten automatisch verbinden: **ja** (2026-10-16) | heart-rate | entschieden |
| ~~F5~~ | Wer ist der Ghost: **Platz 1 der Rangliste jeder Ebene** aus `statistics`, einer pro Spur (2026-10-16) | ghost | entschieden |
| ~~F6~~ | Welcher Abstand steht in der Box: **der zum Ghost der ganzen Vorlage** (2026-10-16) | ghost | entschieden |
| ~~F7~~ | Einheit des Abstands: **Sekunden auf der Distanzachse, Meter auf der Zeitachse** (2026-10-16) | ghost | entschieden |
| ~~F8~~ | Schiffchen bei kleinem Abstand: **Ghost rückt nach aussen** (2026-10-16) | ghost | entschieden |
| ~~F9~~ | Anzeigename: **„Stroke & Split“** (2026-10-16) | rename | entschieden |
| ~~F10~~ | App-ID: **`ch.strokesplit`** (2026-10-16) | rename | entschieden |
| ~~F11~~ | Live-Display beim Übergang in eine Zone vorwarnen: **10 s vorher blinken die Bänder der nächsten Zone gelb** (2026-10-26, Task 5.13) | ui-design | entschieden |
| ~~F12~~ | Schritte der Ruderblatt-Tasten auf der Zeitachse: **Strecke 30 s, Zone und Startposition 10 s** (2026-10-16) | ui-design | entschieden |
| ~~F13~~ | Rückfallsprache: **keine** (2026-10-16), die Sprache wird in der App gewählt (F14) | translations | entschieden |
| ~~F14~~ | Sprachwahl: **in der App** (2026-10-16), Start auf Deutsch, Systemsprache wird nicht beachtet | translations | entschieden |
| F15 | Schweizer Rechtschreibung (`ss` statt `ß`, wie heute im Code) als `de`? **Vorläufig ja** (2026-10-16, nach Vorschlag) | translations | vorläufig entschieden |
| ~~F18~~ | Gemerkter Gurt: **`shared_preferences`** wie Rudergerät und Sprache, keine Tabelle `settings` (2026-10-16) | heart-rate | entschieden |
| F16 | Wo wird die gewählte Sprache gespeichert? **Vorläufig `shared_preferences`** (2026-10-16, nach Vorschlag): keine Migration, `heart-rate` bekommt Schema 6, weil `statistics` 5 nimmt | translations, heart-rate | vorläufig entschieden |
| F17 | Release nur für Tags auf `main`? **Vorläufig ja** (2026-10-16, nach Vorschlag): Tags ausserhalb von `main` lassen `verify-tag` fehlschlagen | gitlab-pipeline | gitlab-pipeline |

## Offene Punkte

Manuelle Tests archivierter Changes (Nutzer):
- [ ] `courses` 7.1: Vorlage im Simulator in der Linux-App rudern (`make run`), Session endet nach der letzten Runde, Zusammenfassung mit Runden.
- [ ] `courses` 7.2: am echten PM5 500 m × 3 mit Pause in Runde 2.
- [ ] `courses` 7.3: README-Schritte im Simulator (inzwischen inklusive Zonen).
- iOS und macOS bleiben ungetestet, es gibt keinen Mac.

Vor einer Veröffentlichung im Play Store:
- [ ] Health-Apps-Erklärung in der Play Console für alle Datentypen von `health-connect` und eine Datenschutzerklärung, die der Datenschutz-Seite der App entspricht.

Nacharbeit:
- [x] Platzhalter-Test `packages/pm5_protocol/test/pm5_protocol_test.dart` („package loads“) gelöscht.
- [x] `lib/data/sessions/session_repository.dart`, `recoverInterrupted`: Zeile über 120 Zeichen umgebrochen.
- [x] Git-Remote eingerichtet (2026-10-16). Ab jetzt pushen und per MR arbeiten.

## Erledigt

| Change | Archiviert | Bemerkung |
|---|---|---|
| `foundation` | 2026-10-16 | PM5 verbinden, Live, Aufzeichnung, Replay, Export/Import; Android und Linux am PM5 verifiziert |
| `courses` | 2026-10-16 | Strecken, Vorlagen, Runden; manuelle Tests 7.1–7.3 offen (siehe oben) |
| `zones` | 2026-10-16 | Wiederverwendbare Zonen, in Strecken eingebaut; im Simulator vom Nutzer geprüft |
