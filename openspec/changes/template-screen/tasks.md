# Tasks

Neue Texte nur über `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb` mit `@`-Beschreibung, danach `make l10n`; der generierte Code wird committet.

## 1. Ghost-Wahl in der Aufnahme

- [x] 1.1 `ActiveRecording.ghost` und `start(template:, ghost:)` nach D4, Standard an; ohne Vorlage ohne Bedeutung. Verifikation: Unit-Test im Recorder: Start mit `ghost: false` hält das Flag über Ticks, Runden und Wiederverbinden, Start ohne Angabe hat es an
- [x] 1.2 `LiveScreen(ghost:)` und `startRowing(..., ghost:)` reichen die Wahl an den Start durch; `_courseView` beobachtet `liveGhostsProvider` nur mit Ghost und übergibt sonst `ghost: null`, `ghostGap: null` (D4). Verifikation: Test in `live_screen_test.dart` (Gruppe „with ghosts“): mit Ghost wie bisher Schiffchen und Abstandszeile, ohne Ghost bei denselben Bestleistungen keines von beiden auf allen drei Spuren, kein Schalter im Live-Display

## 2. Vorlagen-Screen

- [x] 2.1 `TemplateScreen` in `lib/features/templates/template_screen.dart` nach D1: Vorlage per ID aus `templatesProvider`, AppBar mit Name und Bearbeiten, scrollender Teil mit Details, Segmentbalken, Zonen und `TemplatePodium`, fest unten „Starten“; schliesst sich, wenn die Vorlage fehlt. Verifikation: neue `test/features/templates/template_screen_test.dart`: zeigt Strecke, Runden, Zonen und Plätze; nach Umbenennen im Editor der neue Name; nach Löschen im Editor die Liste ohne die Vorlage; Overflow-Test bei 390 px und quer
- [x] 2.2 Ghost-Schalter nach D5: Zeile mit `GhostSymbol`, Text und `Switch` über „Starten“, lokal, beim Öffnen an, startet mit `startRowing(..., ghost: _ghost)`. Verifikation: Widget-Tests: Schalter steht beim Öffnen auf an, auch ohne Bestleistung; aus und „Starten“ startet ohne Ghost (Aufnahme mit `ghost: false`); erneutes Öffnen zeigt wieder an; Touch-Ziel mindestens 48 dp; deutsche und englische Texte

## 3. Liste und Startbildschirm

- [x] 3.1 Kompakte `_TemplateCard` ohne Aufklappen, Auswahlrahmen und `scrollIntoView`, mit Chevron; Tipp öffnet den Screen; `_TemplatesTab` als `ConsumerWidget` mit lazy Liste (D2). Verifikation: `templates_screen_test.dart` angepasst: Tipp öffnet den Screen, keine Karte zeigt Zonen oder „Starten“; Tests zu Bändern, Start, Podium und Ghost-Symbol laufen über den Screen (gemeinsamer Helfer zum Öffnen) und bleiben inhaltlich gleich
- [x] 3.2 „Nochmal“ entfernen (D3): `_RowAgain`, `rowAgainProvider`, Texte `startAgain`/`startAgainDaysAgo` (danach `make l10n`), `TemplatesScreen.selectedTemplateId`; README-Absatz zum Startbildschirm anpassen. Verifikation: Gruppe „Nochmal“ in `start_screen_test.dart` und der „Nochmal“-Test in `templates_screen_test.dart` entfernt; neuer Test: Startbildschirm zeigt nach einer Session mit Vorlage keine Kachel „Nochmal“; `grep -rn -i -e rowAgain -e startAgain lib test` ohne Treffer

## 4. Doku und Abschluss

- [x] 4.1 README: Abschnitte zu Vorlagen und Ghost auf den Vorlagen-Screen und den Schalter umstellen. In `ui-design` (design.md D6, aufklappbare Karten) und `statistics` (Plätze in der aufgeklappten Vorlage) einen Vermerk setzen, dass dieser Change sie ablöst. Verifikation: `grep -n -i aufklapp README.md` ohne Treffer zur Vorlagenwahl; Vermerke in beiden Changes vorhanden
- [ ] 4.2 Gesamtprüfung: `make check` grün; App unter Linux mit Simulator: Vorlage öffnen, Ghost aus, starten, kein Ghost im Rahmen; mit Ghost wie bisher; Startbildschirm ohne „Nochmal“
- [ ] 4.3 Test am Gerät (Nutzer): Vorlage am Handy öffnen, Schalter und „Starten“ ohne Scrollen erreichbar, Session ohne Ghost

## Workflow follow-up

- Erst nach `ui-design`, `ghost` und `statistics` archivieren, weil die Deltas ihre Anforderungen ändern.
