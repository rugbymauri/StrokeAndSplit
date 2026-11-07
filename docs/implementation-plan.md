# Implementierungsplan

Reihenfolge, Abhängigkeiten und offene Punkte der geplanten OpenSpec-Changes. Der Plan ist die eine Stelle, an der nichts vergessen gehen soll.

**Pflege:** Der Plan wird bei jedem Schritt nachgeführt, im selben Commit wie die Änderung:

- beim Start eines Changes (Branch, Stand),
- wenn ein Task fertig ist oder eine Frage entschieden wird,
- wenn Neues auftaucht (Bug, Nacharbeit, Idee), unter „Offene Punkte“ oder beim betroffenen Change,
- beim Archivieren: den Change nach „Erledigt“ verschieben und die Changes danach auf Folgen prüfen.

Stand: 2026-11-07, alle umgesetzten Changes archiviert; `gitlab-pipeline` gelöscht (Nutzer), CI und Releases laufen über GitHub Actions. Geplant: `zone-intensity-colors`.

## Überblick

Die archivierten Changes stehen unter „Erledigt“, ihre offenen Gerätetests unter „Offene Punkte“.

### `zone-intensity-colors`

- **Ziel**: Zonen nach Härte grün, orange oder rot statt blau mit relativer Pace-Abstufung.
- **Branch**: Planung auf `docs/zone-intensity-colors-proposal`, Stand 2026-11-07 geplant, 0/6.
- **Entschieden** (Nutzer, 2026-11-07):
  - Stufe 1–5 grün, 6–10 orange, ab 11 rot.
  - Pace 3:00 und langsamer grün, bis 2:30 orange, schneller rot.
  - Schlagzahl bis 21 grün, ab 22 orange, ab 24 rot.
- **Annahmen**, beim Review bestätigen:
  - Rot bei der Schlagzahl ab 24 (die Zahl fehlte in der Antwort).
  - Bei einem Band zählt die Mitte.
  - Die härteste Vorgabe bestimmt die Farbe.
  - Die Live-Anzeige bleibt blau/orange.

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
| ~~F17~~ | Release nur für Tags auf `main`? Hinfällig, Change `gitlab-pipeline` gelöscht (2026-11-07); die GitHub-Actions-Pipeline regelt das selbst | gitlab-pipeline | hinfällig |

## Offene Punkte

- [x] `resistance-control`, gefunden im Linux-Test von `zone-level-only` (2026-11-07), behoben in `fix/resistance-base-level` (PR #8): Beginnt die Strecke mit einer Zone mit Stufe (ab 0 m), bleibt nach der Zone deren Stufe (12) statt der Grundstufe des Simulators (5). Vermutete Ursache: Beim Start hat das Gerät noch keine Stufe gemeldet, `ResistanceDirector.segmentStarted` sendet 12, und die erste Meldung danach (schon 12) wird zur Grundstufe. Betrifft jede Zone mit Stufe am Streckenanfang, nicht nur Zonen ohne Band. Der `ResistanceDirector` wartet jetzt mit dem ersten Segment auf die erste Meldung. Beim Gerätetest `resistance-control` 6.2 am Woodrower mitprüfen.

Manuelle Tests archivierter Changes (Nutzer):
- [ ] `courses` 7.1: Vorlage im Simulator in der Linux-App rudern (`make run`), Session endet nach der letzten Runde, Zusammenfassung mit Runden.
- [ ] `courses` 7.2: am echten PM5 500 m × 3 mit Pause in Runde 2.
- [ ] `courses` 7.3: README-Schritte im Simulator (inzwischen inklusive Zonen).
- [ ] `device-types` 7.1: am echten PM5 (Linux und Android) Suche, Verbinden, Session, Replay und Import alter Sessions unverändert.
- [ ] `device-types` 7.2: Software-Rower vom Android-Handy: erscheint als FTMS, Verbinden, Control Point, Live-Daten, Pause, Reset.
- [ ] `device-types` 7.3: Vorlage mit Zonen mit dem Software-Rower rudern; Zonenanzeige, Bänder und Runden.
- [ ] `translations` 6.3: auf Linux und Android Sprache wechseln, neu starten, alle Screens in beiden Sprachen, keine abgeschnittenen Texte.
- [ ] `ui-design` 6.1: Screenshots der Screens mit dem Canvas vergleichen, Abweichungen im Canvas oder Code bereinigen.
- [ ] `force-curve` 3.4: am PM5 hoch und quer, angezeigte Schlaglänge plausibel (etwa 60–120 cm).
- [ ] `heart-rate` 1.1/1.2: Spike mit Gurt neben PM5 bzw. FTMS-Rudergerät, Mitschnitt `heart_rate.jsonl` (ca. 2 min am PM5 mit Gurt).
- [ ] `heart-rate` 2.6: Test gegen `heart_rate.jsonl` mit Puls- und RR-Werten (braucht den Mitschnitt aus 1.2).
- [ ] `heart-rate` 6.3: auf Android und Linux mit Gurt, je mit PM5 und FTMS-Rudergerät: Koppeln, automatisch verbinden, Gurt kurz ausser Reichweite.
- [ ] `statistics` 5.2: am Rudergerät „Seerunde x3“ zweimal rudern, Plätze in Vorlagenwahl und Detailansichten prüfen.
- [ ] `ghost` 8.2: am Rudergerät „Seerunde x3“ mit vorhandenen Einträgen rudern, Ghost auf allen drei Spuren.
- [ ] `rename-stroke-and-split` 3.3: Übernahme einer `aergrow`-Datenbank ist umgesetzt (`legacy_database.dart`), der Haken fehlte; beim nächsten Durchsehen abhaken.
- [ ] `start-on-first-stroke` 4.2: am PM5 Vorlage wählen, warten (Hinweis, 0:00, Ghost am Start), erster Schlag startet ab 0.
- [ ] `auto-pause` 5.2: mit PM5 und FTMS-Rudergerät frei und mit Vorlage rudern und anhalten, „Pause“ sichtbar.
- [ ] `health-connect` 1.2: Spike, Probe-Einheit `ROWING_MACHINE` mit Runden und Pause in Health Connect.
- [ ] `health-connect` 6.1: am Android-Gerät Übertragung einschalten, Vorlage am PM5 mit Gurt und Pause rudern, Einheit in Health Connect prüfen.
- [ ] `resistance-control` 6.2: am Woodrower frei mit −/+, Vorlage mit Zonen auf verschiedenen Stufen, mitten in der Zone am Gerät drehen, Pause, Verbindung trennen; dazu die Grundstufe nach einer Zone am Streckenanfang.
- [ ] `template-screen` 4.3: am Handy Vorlage öffnen, Schalter und „Starten“ ohne Scrollen erreichbar, Session ohne Ghost.
- [ ] `course-rowing-free` 7.3: eine Strecke mit Dauer am Rudergerät rudern, Ende und Titel prüfen.
- [ ] `zone-level-only` 3.3: am Woodrower eine Strecke mit einer Zone nur mit Stufe rudern, Stufe wechselt mit der Zone.
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
| `device-types` | 2026-11-07 | FTMS-Rudergeräte, SkiErg/BikeErg abgewiesen; manuelle Tests 7.1–7.3 offen |
| `translations` | 2026-11-07 | Deutsch und Englisch, Sprachwahl in der App; 6.3 offen |
| `ui-design` | 2026-11-07 | Designsprache und Screens aus dem Canvas; 6.1 offen |
| `force-curve` | 2026-11-07 | Kraftkurve lesen, anzeigen, aufzeichnen; 3.4 offen |
| `heart-rate` | 2026-11-07 | Gurt direkt koppeln, RR-Intervalle; Spike 1.1/1.2, 2.6 und 6.3 offen |
| `statistics` | 2026-11-07 | Ranglisten pro Vorlage, Strecke und Zone; 5.2 offen |
| `ghost` | 2026-11-07 | Gegen Platz 1 rudern, drei Spuren; 8.2 offen |
| `rename-stroke-and-split` | 2026-11-07 | App heisst „Stroke & Split“, App-ID `ch.strokesplit`; Haken 3.3 offen |
| `start-on-first-stroke` | 2026-11-07 | Vorlage startet mit dem ersten Schlag; 4.2 offen. Beim Archivieren das Delta `session-recording` um das Szenario FTMS aus `device-types` ergänzt |
| `auto-pause` | 2026-11-07 | Automatische Pause; 5.2 offen. Beim Archivieren „Session vollständig speichern“ mit `device-types` und `heart-rate` zusammengeführt |
| `health-connect` | 2026-11-07 | Sessions an Health Connect; 1.2 und 6.1 offen |
| `resistance-control` | 2026-11-07 | Widerstandsstufe von FTMS-Rudergeräten setzen; 6.2 offen |
| `template-screen` | 2026-11-07 | Vorlage auf eigenem Screen, Ghost abschaltbar; 4.3 offen |
| `course-rowing-free` | 2026-11-07 | Strecke ohne Vorlage rudern, Runden, Dauer oder offen; 7.3 offen |
| `zone-level-only` | 2026-11-07 | Zone nur mit Stufe; 3.3 offen. Nach dem Archivieren in `course-rowing` die Texte aus `ui-design` („Runde 2 / 3“) und `auto-pause` (Pausen) wiederhergestellt, die das Delta überschrieben hatte |
| `gitlab-pipeline` | – | gelöscht (Nutzer, 2026-11-07), nicht archiviert: CI und Releases laufen über GitHub Actions |
