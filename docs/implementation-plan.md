# Implementierungsplan

Reihenfolge, Abhängigkeiten und offene Punkte der geplanten OpenSpec-Changes. Der Plan ist die eine Stelle, an der nichts vergessen gehen soll.

**Pflege:** Der Plan wird bei jedem Schritt nachgeführt, im selben Commit wie die Änderung:

- beim Start eines Changes (Branch, Stand),
- wenn ein Task fertig ist oder eine Frage entschieden wird,
- wenn Neues auftaucht (Bug, Nacharbeit, Idee), unter „Offene Punkte“ oder beim betroffenen Change,
- beim Archivieren: den Change nach „Erledigt“ verschieben und die Changes danach auf Folgen prüfen.

Stand: 2026-10-16, `main` nach dem Merge von `foundation`, `courses` und `zones`; `device-types` an diesen Stand angepasst.

## Überblick

| # | Change | Tasks | Kann starten? | Wartet auf |
|---|---|---|---|---|
| 1 | `device-types` | 0/33 | ja, angepasst | – |
| 2 | `ui-design` | 0/16 | nach 1 | Entscheid Puls-Herkunft (F1) |
| 3 | `force-curve` | 0/8 | nach 2 | Spike am echten PM5 (Characteristic bestätigen) |
| 4 | `heart-rate` | 0/22 | nach 1 und 2 | Entscheide F3, F4 |
| 5 | `ghost` | – (keine Tasks) | nein | Entscheide F5–F8, dann Specs und Tasks; braucht 2 |
| 6 | `rename-stroke-and-split` | 0/10 | zuletzt | Entscheide F9, F10; Domain- und Markenrecherche |

## Warum diese Reihenfolge

1. **`device-types` zuerst**, weil er das Fundament der Daten umbaut: ein Decoder pro Protokoll, Rohpakete mit Protokoll, nullable Schlagdetails mit Migration. Alles, was später Rohpakete, Schläge oder Quellen anfasst (`force-curve`, `heart-rate`), baut dann auf dem neuen Stand auf, statt ihn zu kreuzen. Ausserdem kennt `ui-design` dann schon FTMS-Geräte, wenn es den Startbildschirm und die Geräteliste neu gestaltet.
2. **`ui-design`** schafft das Layout, in das Kraftkurve, Puls und Ghost ihren reservierten Platz bekommen. Erst danach lohnt sich deren Anzeige.
3. **`force-curve`** ist klein und hängt nur an einem Spike am PM5 und am Layout aus 2.
4. **`heart-rate`** kommt nach `device-types`, weil beide dieselben Anforderungen ändern und der Gurt an die Quelle andockt, die `device-types` umbaut.
5. **`ghost`** braucht den Fortschrittsrahmen aus `ui-design` und vorher Entscheide, wer der Ghost ist.
6. **`rename-stroke-and-split`** zuletzt, damit nicht jeder Change auf halbem Weg die Namen wechselt.

## Changes

### 1. `device-types`: FTMS-Rudergeräte, SkiErg/BikeErg abweisen

Ziel: Nur Rudergeräte. PM5 an SkiErg/BikeErg wird abgewiesen, FTMS-Rower (`0x1826`) kommen als zweite Geräteart dazu. Ohne FTMS-Hardware verifiziert über Spec-Tests, FTMS-Modus im Simulator und einen Software-Rower (BlueZ) unter `tool/`.

Vor dem Start anpassen:
- [x] Task 1.1: Branch startet von `main` statt Rebase auf `feature/courses`; Hinweis am Ende von `tasks.md` gestrichen.
- [x] Task 2.2 und Design D1/D9: **Schema 4** (Migration `from3To4`), Migrationstests 3→4 und 1→4 auch mit Runden und Zonen.
- [x] MODIFIED-Anforderungen gegen die Main-Specs geprüft: Kein Szenario geht verloren, `courses` und `zones` haben nur Anforderungen ergänzt. `openspec validate device-types --strict` ist gültig.
- [x] Task 2.5, 4.2 und 7.3: Export, End-to-End-Test und manueller Test mit Strecke und eingebauten Zonen.

Bereit zum Start (`/opsx:apply device-types`).

Bei der Umsetzung mitnehmen:
- Zeilen über 120 Zeichen in `packages/pm5_protocol/lib/src/rowing_event.dart` (`Stroke.toString`, ändert sich mit Task 2.1) und `lib/features/connection/device_list_screen.dart` (Fehlertext „Suche nach dem PM5“, ändert sich mit Task 5.5) umbrechen.

Manuell (vom Nutzer): 7.x mit dem Software-Rower vom Android-Handy aus.

### 2. `ui-design`: Designsprache und neue Screens aus dem Claude-Design-Canvas

Ziel: dunkles Thema, Barlow Condensed/IBM Plex Sans, Fortschrittsrahmen um die Pace, neue Editoren, Startbildschirm, Zusammenfassung. Canvas

Vor dem Start anpassen:
- [ ] Task 1.3 `SegmentBar` überschneidet sich mit `CourseStrip` aus `zones` (`lib/features/courses/course_strip.dart`): ausbauen statt doppelt bauen.
- [ ] Task 4.1 „Tabs Vorlagen und Strecken“: Die drei Tabs Vorlagen | Strecken | Zonen gibt es seit `zones` schon. Task auf das Gestalten reduzieren.
- [ ] Task 3.3: `course_bar.dart` zeigt seit `zones` den Zonennamen bzw. „frei“; das muss in die Pace-Box übernommen werden.
- [ ] Spec-Delta `live-display` spricht von „Segmenten“ und „Segmentspur“; Begriffe mit `zones` abgleichen (Abschnitt = Zone oder frei).
- [ ] Startbildschirm: Quellenwahl muss FTMS-Rudergeräte aus `device-types` aufnehmen.

Offene Entscheide: F1. F2 ist entschieden (Mittelweg, Design D6).

- [x] F2 in Proposal, Design D6 und Task 5.1 eingetragen.

### 3. `force-curve`: Kraftkurve lesen, anzeigen, aufzeichnen

Ziel: Kurve des letzten und vorherigen Schlags im Live-Display, Aufzeichnung und Replay, Kurve im Simulator.

Vor dem Start:
- [ ] Spike am echten PM5: Characteristic `0x003D` und Paketaufbau per Mitschnitt bestätigen (`make spike`). Braucht den Nutzer am Erg.
- [ ] Rohpakete tragen nach `device-types` ein Protokoll; die Kurvenpakete passen dort hinein.
- [ ] Platz der Karte im Layout aus `ui-design`.

### 4. `heart-rate`: Brustgurt direkt koppeln, RR-Intervalle, HRV

Ziel: Gurt koppeln und merken, automatisch verbinden, Puls-Vorrang Gurt vor PM5, RR-Intervalle, Ø/max Puls und RMSSD in der Zusammenfassung.

Vor dem Start anpassen:
- [x] Task 3.1 erhöht das Schema: nach `device-types` ist das **Schema 5**. In Proposal und Design vermerkt, `tasks.md` spricht ohnehin von „erhöhen“.
- [ ] Design bindet den Gurt an `Pm5BleSource`; nach `device-types` gibt es auch FTMS-Quellen. Festlegen, ob der Gurt auch mit FTMS verbunden wird.
- [ ] Gleiche MODIFIED-Anforderungen wie `device-types` (`rowing-telemetry` „Laufende Messwerte bereitstellen“, `session-recording` „Session vollständig speichern“, „Rohdaten für Replay speichern“): Deltas auf den Text nach dem Archivieren von `device-types` umschreiben, sonst überschreibt das Archiv dessen Änderungen.

Offene Entscheide: F3, F4.

### 5. `ghost`: gegen die eigene Bestzeit rudern

Ziel: violettes Schiffchen auf den Spuren des Fortschrittsrahmens, Abstand in Metern und Sekunden, Ghost-Zeit in der Vorlagenwahl. Daten liefern die gespeicherten Runden aus `courses`.

Blockiert: `design.md` hat offene Fragen F5–F8. Danach Specs zur Auswahl des Ghosts und `tasks.md` ergänzen (`/opsx:continue ghost`). Braucht den Fortschrittsrahmen aus `ui-design`.

### 6. `rename-stroke-and-split`: App heisst „Stroke & Split“

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
