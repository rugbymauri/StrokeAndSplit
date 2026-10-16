# Tasks

Neue und geänderte Texte nur über `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb` mit `@`-Beschreibung, danach `make l10n` (`ui-design` Design D9). Das gilt für jeden Task.

Reihenfolge: Gruppe 1 legt die gemeinsamen Typen und das Symbol fest und kommt zuerst. Danach sind die Gruppen 2–6 unabhängig voneinander und können parallel umgesetzt werden:
- Gruppe 2 (Verlauf laden) in `lib/data`,
- Gruppe 3 (Position und Abstand) als reine Funktionen in `lib/data/courses` und `lib/data/ghost`,
- Gruppe 4 (Rahmen) in `progress_frame.dart`,
- Gruppe 5 (Pace-Box) in `pace_box.dart`,
- Gruppe 6 (Vorlagenwahl) in `lib/features/templates`.

Gruppe 7 verbindet alles im Live-Display und braucht die Gruppen 2–5. Gruppe 8 schliesst ab. Voraussetzung: `ui-design` und `statistics` sind umgesetzt (Fortschrittsrahmen, Pace-Box, Ranglisten mit Beginn und Ende nach `statistics` Design D5).

## 1. Grundlagen

- [x] 1.1 Typen in `lib/data/ghost/ghost.dart`: `GhostTrack` als Verlauf eines Ranglisten-Eintrags aus Punkten (Wanduhr und Distanz relativ zum Beginn des Eintrags), mit linear interpolierter Achsenposition zu einer Wanduhr (Distanz auf einer Distanzachse, Zeit auf einer Zeitachse) und umgekehrt der Wanduhr, zu der eine Distanz erreicht wurde. Vor dem Beginn steht der Ghost am Start, nach dem Ende am Ziel. Dazu `GhostGap` mit Achse, Betrag (Sekunden bzw. Meter) und ob der Ghost vorne liegt (D4). Verifikation: Unit-Tests für Interpolation zwischen zwei Punkten, vor dem ersten und nach dem letzten Punkt, Umkehrung auf einer Distanzachse und einen Verlauf mit Pause (Distanz steht, Wanduhr läuft)
- [x] 1.2 Widget `GhostSymbol`: dieselbe Raute wie das Ghost-Schiffchen, 10 px breit, in `AppColors.ghost` mit Rand in der Farbe der Fläche (D1), mit Screenreader-Beschriftung „Ghost“. Das Token `AppColors.ghost` (`#C9B6FF`) ist schon da. Verifikation: Widget-Test für Grösse und Semantics, Golden-Test des Symbols

## 2. Verlauf des Ghosts laden

Hängt nur an Gruppe 1.

- [ ] 2.1 `SessionRepository` (oder eigenes `GhostRepository` in `lib/data/ghost`) liest zu einem `RankingEntry` die `samples` seiner Session zwischen `startWallMs` und `endWallMs` und baut daraus einen `GhostTrack`, Wanduhr und Distanz relativ zu Beginn des Eintrags (D2, D3). Samples ohne `wallMs` (vor Schema 2) oder ein Eintrag ohne Samples ergeben keinen Verlauf. Keine Schema-Änderung. Verifikation: Unit-Tests mit der Test-Datenbank für eine Runde, die zweite Zonenfahrt einer Runde (Beginn nach `statistics` 1.3), eine ganze Session über drei Runden und eine Session ohne `wallMs`
- [ ] 2.2 Riverpod-Provider für die drei Ghosts einer laufenden Vorlage, jeweils Platz 1 der Rangliste mit passender Länge, nicht einfach die erste Rangliste (die aktuelle Länge steht nur vorne, wenn sie Einträge hat): aussen `templateRankingsProvider` mit Streckenlänge und Rundenzahl der Vorlage, in der Mitte `courseRankingsProvider` mit der Länge der Strecke, innen `zoneRankingsProvider` mit `zoneId` und Länge des aktuellen Abschnitts. Den Verlauf lädt der Provider einmal pro Eintrag. Die Ghosts folgen der Rangliste live (D6): wird eine Runde oder Zonenfahrt der laufenden Session neuer Platz 1, gilt sie ab der nächsten Runde bzw. Fahrt. Ohne Rangliste, ohne Eintrag oder ohne Verlauf liefert er null. Läuft die Session im Simulator, liefert er die Ghosts genauso. Verifikation: Provider-Tests für „Neue Bestleistung in derselben Session“ (Runde 2 wird Platz 1, der Runden-Ghost wechselt ab Runde 3), Simulator-Session mit Ghost, „Offene Rundenzahl“ (aussen null, Mitte gesetzt), „Freier Abschnitt“ (innen null), eine Vorlage, deren aktuelle Länge noch keinen Eintrag hat, und eine Simulator-Session, die nie Ghost wird

## 3. Position und Abstand berechnen

Hängt nur an Gruppe 1.

- [ ] 3.1 `LapProgress` um die Wanduhr seit Beginn der ersten Runde und seit Beginn des aktuellen Abschnitts ergänzen (seit Rundenbeginn gibt es schon `lapTime`), damit Runden- und Zonen-Ghost mit jeder Runde bzw. Fahrt neu starten (D2). Verifikation: Unit-Tests im Lap-Tracker für Rundenwechsel, Abschnittswechsel und eine Pause
- [ ] 3.2 Reine Funktion, die aus `LapProgress`, Vorlage und den drei `GhostTrack` die Anteile für `FrameGhost` (Strecke, Runde, Abschnitt) berechnet, wie `ProgressFrameModel` den eigenen Fortschritt (D3). Eine Spur ohne Ghost bleibt null. Verifikation: Unit-Tests für die Spec-Szenarien „Ghost liegt vorne“ (460 m in Runde 2, Ghost bei 490 m), „Nur Rundendaten“, „Runde 2“ (Ghost erreicht das Rundenende nach 4:08) und eine Zeitstrecke
- [ ] 3.3 Reine Funktion für den `GhostGap` zum Ghost der Vorlage (D4): auf einer Distanzachse die Differenz der Wanduhren bei der aktuellen Distanz in Sekunden, auf einer Zeitachse die Differenz der Distanzen bei der aktuellen Wanduhr in Metern; null ohne Ghost aussen. Verifikation: Unit-Tests für „Rückstand auf einer Distanzachse“ (7.6 s, Ghost vorne), „Vorsprung auf einer Zeitachse“ (12 m, Ghost hinten), Gleichstand und „Kein Ghost der Vorlage“

## 4. Ghost im Fortschrittsrahmen

Hängt nur an Gruppe 1 (oder an nichts, `FrameGhost` gibt es schon).

- [ ] 4.1 `ProgressFramePainter` nach D1 und D5: Das Ghost-Schiffchen (18 × 7 px, Rand 1.5 px, liegt schon) liegt nicht mehr über dem eigenen, sondern rückt quer zur Laufrichtung nach aussen, aus der Box bzw. auf der äussersten Spur in den Rand des Rahmens, sobald sich beide überlappen würden. Entlang der Spur bleibt es an seiner Position und kehrt auf die Mitte zurück, sobald der Abstand reicht. Den Rand dafür im Padding von `ProgressFrame` und in `PaceBox.paceFontSizeFor` berücksichtigen, falls er nicht schon reicht. Verifikation: bestehender Golden `progress_frame_ghost.png` neu, dazu Golden-Tests für Überlappung auf der Rundenspur, auf der äussersten Spur, in einer Ecke und knapp ohne Überlappung (Ghost auf der Mitte)

## 5. Abstand in der Pace-Box

Hängt nur an Gruppe 1.

- [x] 5.1 `PaceBox` nimmt einen optionalen `GhostGap` und zeigt ihn als vierte Legendenzeile (D1, D4): `GhostSymbol` statt Punkt, „Ghost“ links, rechts z. B. „7.6 s vor dir“ bzw. „12 m hinter dir“, orange (`zoneOut`) bei Rückstand, blau (`zoneIn`) bei Vorsprung. Vorne oder hinten steht im Text, nicht nur in der Farbe. Ohne `GhostGap` entfällt die Zeile. Prüfen, ob `_aroundPace` und `minContentHeight` die zusätzliche Zeile tragen. Verifikation: Widget-Tests für Rückstand auf einer Distanzachse, Vorsprung auf einer Zeitachse, keine Zeile ohne Ghost und eine schmale Box, in der die Pace weiterhin der grösste Text bleibt

## 6. Ghost-Symbol in der Vorlagenwahl

Hängt nur an Gruppe 1.

- [x] 6.1 `TemplatePodium` zeigt im Platzhalter `template-ghost-slot` bei Platz 1 das `GhostSymbol`. Den Kommentar-Platzhalter „The ghost's best time of `ghost` goes here.“ in `templates_screen.dart` entfernen, weil Platz 1 die Zeit schon zeigt. Verifikation: Widget-Test in `templates_screen_test.dart`, dass Platz 1 das Symbol trägt, Platz 2 und 3 nicht, und ohne Eintrag kein Symbol erscheint

## 7. Live-Display verbinden

Hängt an den Gruppen 2–5.

- [ ] 7.1 `LiveScreen`/`CourseLiveView` lesen die Ghosts aus 2.2 für die laufende Vorlage, berechnen mit 3.2 und 3.3 bei jedem Tick `FrameGhost` und `GhostGap` und geben sie an `PaceBox` weiter, hochkant und quer. Frei rudern zeigt keinen Ghost. Verifikation: Widget-Tests mit Test-Datenbank und simuliertem Verlauf für „Runde 2“ (Rundenspur mit Ghost, Abstand in der Box), „Offene Rundenzahl“ (kein Abstand, Rundenspur mit Ghost), „Freier Abschnitt“ (Abschnittsspur ohne Ghost) und frei rudern

## 8. Abschluss

- [ ] 8.1 README um den Ghost ergänzen: wer auf welcher Spur Ghost ist, dass er mit jeder Runde bzw. Zonenfahrt neu startet, was der Abstand in der Box misst, und dass Simulator-Sessions nie Ghost sind. Verifikation: `make check` grün, `openspec validate ghost --strict` gültig, Durchsicht des README
- [ ] 8.2 Manueller Test durch den Nutzer: am Rudergerät „Seerunde x3“ rudern, nachdem es dafür schon Einträge gibt. Auf allen drei Spuren muss ein Ghost laufen, der Runden-Ghost mit jeder Runde neu starten, der Abstand in der Box plausibel sein und der Ghost bei gleichauf nach aussen rücken. Danach eine Vorlage mit offener Rundenzahl rudern: kein Abstand in der Box, Ghost auf der Rundenspur. Verifikation: Rückmeldung des Nutzers

## Workflow follow-up

- Nach dem Umsetzen `docs/implementation-plan.md` nachführen und den Change archivieren, sobald der manuelle Test 8.2 bestanden ist.
