# Implementierungsplan

Reihenfolge, Abhängigkeiten und offene Punkte der geplanten OpenSpec-Changes. Der Plan ist die eine Stelle, an der nichts vergessen gehen soll.

**Pflege:** Der Plan wird bei jedem Schritt nachgeführt, im selben Commit wie die Änderung:

- beim Start eines Changes (Branch, Stand),
- wenn ein Task fertig ist oder eine Frage entschieden wird,
- wenn Neues auftaucht (Bug, Nacharbeit, Idee), unter „Offene Punkte“ oder beim betroffenen Change,
- beim Archivieren: den Change nach „Erledigt“ verschieben und die Changes danach auf Folgen prüfen.

Stand: 2026-10-16, `main` nach dem Merge von `foundation`, `courses`, `zones` und `device-types`; `translations` in Arbeit.

## Überblick

| # | Change | Tasks | Kann starten? | Wartet auf |
|---|---|---|---|---|
| 1 | `device-types` | 29/33 | umgesetzt, in `main` gemergt | Nutzer: Task 3.5 und manuelle Tests 7.1–7.3 |
| 2 | `translations` | 1/16 | in Arbeit auf `feature/translations` | – |
| 3 | `ui-design` | 0/18 | nach 2 | Entscheid Puls-Herkunft (F1) |
| 4 | `force-curve` | 0/8 | nach 3 | Spike am echten PM5 (Characteristic bestätigen) |
| 5 | `heart-rate` | 0/22 | nach 1 und 3 | Entscheide F3, F4 |
| 6 | `ghost` | – (keine Tasks) | nein | Entscheide F5–F8, dann Specs und Tasks; braucht 3 |
| 7 | `rename-stroke-and-split` | 0/10 | zuletzt | Entscheide F9, F10; Domain- und Markenrecherche |

## Warum diese Reihenfolge

1. **`device-types` zuerst**, weil er das Fundament der Daten umbaut: ein Decoder pro Protokoll, Rohpakete mit Protokoll, nullable Schlagdetails mit Migration. Alles, was später Rohpakete, Schläge oder Quellen anfasst (`force-curve`, `heart-rate`), baut dann auf dem neuen Stand auf, statt ihn zu kreuzen. Ausserdem kennt `ui-design` dann schon FTMS-Geräte, wenn es den Startbildschirm und die Geräteliste neu gestaltet.
2. **`translations`** vor `ui-design`, weil dieser fast alle Screens neu baut: Steht die Lokalisierung schon, entstehen die neuen Screens gleich mit ARB-Keys, statt danach ein zweites Mal Texte herauszuziehen. Nach `device-types`, weil dieser selbst Texte der Geräteliste ändert (Task 5.5). Das Herausziehen aus Screens, die `ui-design` ersetzt, ist teils Wegwerfarbeit; die meisten Texte bleiben aber erhalten.
3. **`ui-design`** schafft das Layout, in das Kraftkurve, Puls und Ghost ihren reservierten Platz bekommen. Erst danach lohnt sich deren Anzeige.
4. **`force-curve`** ist klein und hängt nur an einem Spike am PM5 und am Layout aus 3.
5. **`heart-rate`** kommt nach `device-types`, weil beide dieselben Anforderungen ändern und der Gurt an die Quelle andockt, die `device-types` umbaut.
6. **`ghost`** braucht den Fortschrittsrahmen aus `ui-design` und vorher Entscheide, wer der Ghost ist.
7. **`rename-stroke-and-split`** zuletzt, damit nicht jeder Change auf halbem Weg die Namen wechselt. Nach `translations` steht der Anzeigename an einer Stelle in den ARB-Dateien.

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
- [ ] Task 3.5: `Pm5ErgType` ist umgesetzt, aber die Ski- und Bike-Werte sind nicht gegen das aktuelle Concept2-Dokument geprüft. Online war die Liste nicht zu finden, nur der Wert 0 (RowErg) ist an den Aufnahmen bestätigt. Der Nutzer prüft sie gegen die *PM5 Bluetooth Smart Interface Definition* oder an einem SkiErg/BikeErg, dann Task abhaken.
- [x] Task 3.6: README-Abschnitt FTMS und Erg-Typ steht, die Fixtures-Tabelle kam mit Task 4.3 (`ftms_just_row.jsonl` ist aus `just_row.jsonl` umgerechnet, keine Aufnahme eines echten FTMS-Geräts).
- Task 4.2: Zusätzlich zum Umschalter in der Simulator-Bedienung bietet „Vorlage rudern“ die Quelle „Simulator (FTMS)“ an, weil eine Vorlage die Session sofort startet und der Umschalter während einer Session gesperrt ist. Mit `ui-design` (Startbildschirm, Quellenwahl) übernehmen.
- Reihenfolge: Abschnitt 3 (FTMS-Protokoll) vor 2.4/2.5 umgesetzt, weil deren Tests den FTMS-Decoder brauchen.
- Task 4.4: Der Software-Rower startet unter Linux und registriert seine Advertisement bei BlueZ. Ob er vom Handy aus als FTMS-Gerät erscheint und Control Point und Notifications funktionieren, ist ungeprüft und gehört zu 7.2. bless 0.3 kann keine Service Data setzen; das Skript ergänzt sie im Advertisement-Objekt von bless. Nach einem Update von bless prüfen.
- Task 5.2 weicht von D5 ab: Der Scan läuft ohne Plattformfilter, weil flutter_blue_plus unter Android das Keyword `PM5` nicht mit dem Service `0x1826` kombiniert. `rowerFromAdvertisement` filtert auf allen Plattformen. Unter Linux liefert `systemDevices` den BlueZ-Cache nur mit Namen; dort wird nur ein PM5 erkannt. Ein FTMS-Gerät im Cache erscheint unter Linux erst, wenn BlueZ es neu entdeckt. Das betrifft nur Linux, getestet wird FTMS vom Handy aus.
- Task 5.3/5.4: Die Protokolllogik beim Verbinden (Abtastrate, Abos, Erg-Typ, Control Point) liegt in `setUpRower` über einer dünnen `GattConnection`, damit sie ohne Bluetooth testbar ist. `FlutterBluePlusTransport` verbindet nur noch und sucht die Characteristics der Services `0x0030` und `0x1826`.
- Task 7.4: Die README-Zeile „nur mit Software-Rower getestet“ stimmt erst nach dem manuellen Test 7.2; bis dahin ist FTMS nur automatisch getestet.
- Design D8 angepasst: Beim FTMS-Reset beginnt die eigene Uhr wieder bei 0, sonst zählt die Session die Zeit doppelt.
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

### 3. `ui-design`: Designsprache und neue Screens aus dem Claude-Design-Canvas

Ziel: dunkles Thema, Barlow Condensed/IBM Plex Sans, Fortschrittsrahmen um die Pace, neue Editoren, Startbildschirm, Zusammenfassung. Canvas

Vor dem Start anpassen:
- [ ] Task 1.3 `SegmentBar` überschneidet sich mit `CourseStrip` aus `zones` (`lib/features/courses/course_strip.dart`): ausbauen statt doppelt bauen.
- [ ] Task 4.1 „Tabs Vorlagen und Strecken“: Die drei Tabs Vorlagen | Strecken | Zonen gibt es seit `zones` schon. Task auf das Gestalten reduzieren.
- [ ] Task 3.3: `course_bar.dart` zeigt seit `zones` den Zonennamen bzw. „frei“; das muss in die Pace-Box übernommen werden.
- [ ] Spec-Delta `live-display` spricht von „Segmenten“ und „Segmentspur“; Begriffe mit `zones` abgleichen (Abschnitt = Zone oder frei).
- [ ] Startbildschirm: Quellenwahl muss FTMS-Rudergeräte aus `device-types` aufnehmen.
- [ ] Neue Texte über die ARB-Dateien aus `translations`, nicht hart codiert.
- [ ] Platz für die Sprachwahl aus `translations` im neuen Layout festlegen (Einstellungen bzw. Startbildschirm).

Offene Entscheide: F1. F2 (Mittelweg, Design D6) und F12 (Schritte auf der Zeitachse, Design D7) sind entschieden.

- [x] F2 in Proposal, Design D6 und Task 5.1 eingetragen.
- [x] Ruderblatt-Tasten für Zahlen (2026-10-16) als Design D7, Spec `number-steppers` und Tasks 1.4 und 4.4 aufgenommen. Betrifft auch die Editoren aus `zones`.
- [x] F12 entschieden: Zeitachse Strecke 30 s, Zone und Startposition 10 s (Design D7, Spec `number-steppers`).

### 4. `force-curve`: Kraftkurve lesen, anzeigen, aufzeichnen

Ziel: Kurve des letzten und vorherigen Schlags im Live-Display, Aufzeichnung und Replay, Kurve im Simulator.

Vor dem Start:
- [ ] Spike am echten PM5: Characteristic `0x003D` und Paketaufbau per Mitschnitt bestätigen (`make spike`). Braucht den Nutzer am Erg.
- [ ] Rohpakete tragen nach `device-types` ein Protokoll; die Kurvenpakete passen dort hinein.
- [ ] Platz der Karte im Layout aus `ui-design`.

### 5. `heart-rate`: Brustgurt direkt koppeln, RR-Intervalle, HRV

Ziel: Gurt koppeln und merken, automatisch verbinden, Puls-Vorrang Gurt vor PM5, RR-Intervalle, Ø/max Puls und RMSSD in der Zusammenfassung.

Vor dem Start anpassen:
- [x] Task 3.1 erhöht das Schema: nach `device-types` ist das **Schema 5**. In Proposal und Design vermerkt, `tasks.md` spricht ohnehin von „erhöhen“.
- [ ] Design bindet den Gurt an `Pm5BleSource`; nach `device-types` gibt es auch FTMS-Quellen. Festlegen, ob der Gurt auch mit FTMS verbunden wird.
- [ ] Gleiche MODIFIED-Anforderungen wie `device-types` (`rowing-telemetry` „Laufende Messwerte bereitstellen“, `session-recording` „Session vollständig speichern“, „Rohdaten für Replay speichern“): Deltas auf den Text nach dem Archivieren von `device-types` umschreiben, sonst überschreibt das Archiv dessen Änderungen.

Offene Entscheide: F3, F4.

### 6. `ghost`: gegen die eigene Bestzeit rudern

Ziel: violettes Schiffchen auf den Spuren des Fortschrittsrahmens, Abstand in Metern und Sekunden, Ghost-Zeit in der Vorlagenwahl. Daten liefern die gespeicherten Runden aus `courses`.

Blockiert: `design.md` hat offene Fragen F5–F8. Danach Specs zur Auswahl des Ghosts und `tasks.md` ergänzen (`/opsx:continue ghost`). Braucht den Fortschrittsrahmen aus `ui-design`.

### 7. `rename-stroke-and-split`: App heisst „Stroke & Split“

Ziel: Anzeigename, Paket- und App-ID `strokesplit`, Dateiendung `.strokesplit`, Import liest weiter `.aergrow`.

Vor dem Start:
- [ ] Entscheide F9, F10.
- [ ] Domains sichern, Markenrecherche (Swissreg, EUIPO, USPTO). Ausserhalb der App, durch den Nutzer.
- [ ] Neue App-ID ist unter Android eine neue App: Umzug per Export/Import im README beschreiben (Task im Change).

## Offene Entscheide

| | Frage | Change | Entscheidet sich vor |
|---|---|---|---|
| F1 | Puls-Herkunft „Über PM5“ im Live-Display zeigen? Canvas zeigt sie, `heart-rate` schliesst sie aus. | ui-design, heart-rate | ui-design |
| ~~F2~~ | Startbildschirm: **Mittelweg** (2026-10-16): Quelle, „Rudern“, „Frei rudern“, Kachel „Nochmal“ mit der zuletzt geruderten Vorlage, Link „Sessions“ | ui-design | entschieden |
| F3 | Welcher Puls gilt, wenn FTMS-Gerät und Gurt beide liefern? | heart-rate | heart-rate |
| F4 | Gurt auch mit FTMS-Rudergeräten automatisch verbinden? | heart-rate | heart-rate |
| F5 | Wer ist der Ghost: (a) beste Runde dieser Streckenversion, (b) letzte Session derselben Vorlage, (c) wählbar? | ghost | ghost |
| F6 | Welcher Abstand steht in der Box, wenn er pro Ebene verschieden ist? | ghost | ghost |
| F7 | Meter, Sekunden oder beides? Am Erg prüfen. | ghost | ghost |
| F8 | Schiffchen bei kleinem Abstand: überlappen lassen oder Ghost nach aussen rücken? | ghost | ghost |
| F9 | „Stroke & Split“ oder „Stroke and Split“? | rename | rename |
| F10 | App-ID `ch.strokesplit` oder `ch.<herausgeber>.strokesplit`? | rename | rename |
| F11 | Live-Display beim Übergang in eine Zone vorwarnen, z.B. „Sprint in 50 m“? (offen aus `zones`) | – (neuer Change) | – |
| ~~F12~~ | Schritte der Ruderblatt-Tasten auf der Zeitachse: **Strecke 30 s, Zone und Startposition 10 s** (2026-10-16) | ui-design | entschieden |
| ~~F13~~ | Rückfallsprache: **keine** (2026-10-16), die Sprache wird in der App gewählt (F14) | translations | entschieden |
| ~~F14~~ | Sprachwahl: **in der App** (2026-10-16), Start auf Deutsch, Systemsprache wird nicht beachtet | translations | entschieden |
| F15 | Schweizer Rechtschreibung (`ss` statt `ß`, wie heute im Code) als `de`? **Vorläufig ja** (2026-10-16, nach Vorschlag) | translations | vorläufig entschieden |
| F16 | Wo wird die gewählte Sprache gespeichert? **Vorläufig `shared_preferences`** (2026-10-16, nach Vorschlag): keine Migration, `heart-rate` bleibt Schema 5 | translations, heart-rate | vorläufig entschieden |

## Offene Punkte

Manuelle Tests archivierter Changes (Nutzer):
- [ ] `courses` 7.1: Vorlage im Simulator in der Linux-App rudern (`make run`), Session endet nach der letzten Runde, Zusammenfassung mit Runden.
- [ ] `courses` 7.2: am echten PM5 500 m × 3 mit Pause in Runde 2.
- [ ] `courses` 7.3: README-Schritte im Simulator (inzwischen inklusive Zonen).
- iOS und macOS bleiben ungetestet, es gibt keinen Mac.

Nacharbeit:
- [x] Platzhalter-Test `packages/pm5_protocol/test/pm5_protocol_test.dart` („package loads“) gelöscht.
- [x] `lib/data/sessions/session_repository.dart`, `recoverInterrupted`: Zeile über 120 Zeichen umgebrochen.
- [ ] Kein Git-Remote: Sobald es eines gibt, pushen und künftig per MR arbeiten.

## Erledigt

| Change | Archiviert | Bemerkung |
|---|---|---|
| `foundation` | 2026-10-16 | PM5 verbinden, Live, Aufzeichnung, Replay, Export/Import; Android und Linux am PM5 verifiziert |
| `courses` | 2026-10-16 | Strecken, Vorlagen, Runden; manuelle Tests 7.1–7.3 offen (siehe oben) |
| `zones` | 2026-10-16 | Wiederverwendbare Zonen, in Strecken eingebaut; im Simulator vom Nutzer geprüft |
