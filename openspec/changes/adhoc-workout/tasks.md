# Tasks

Keine Schema-Änderung. Neue Texte nur über `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb` mit `@`-Beschreibung, danach `make l10n`; der generierte Code wird committet.

## 1. Starten ohne Speichern

- [x] 1.1 Knopf „Starten ohne Speichern“ nach D1 mit neuem Text `workoutStartUnsaved` (de „Starten ohne Speichern“, en „Start without saving“), Start nach D2 und D3. Verifikation in `workout_editor_screen_test.dart`:
  - Neues Workout ohne Namen mit drei Strecken und 1 Runde: der Knopf öffnet den Live-Screen mit einem Plan aus diesen drei Strecken, `LapCount(1)` und ohne Workout; die Workout-Liste bleibt leer.
  - Ohne Strecke: kein Live-Screen, die Meldung zur fehlenden Strecke erscheint.
  - Bestehendes „Seerunde x3“ auf 1 Runde gestellt und ohne Speichern gestartet: der Plan hat 1 Runde, das gespeicherte Workout weiter 3.
  - Nach dem Schliessen des Live-Screens steht der Editor mit denselben Strecken und derselben Länge da.
  - 400 × 400 ohne Overflow mit beiden Knöpfen.
- [x] 1.2 Aufzeichnung einer Kette ohne Workout. Verifikation: Test in `session_course_chain_test.dart`: Session mit drei Strecken ohne Workout speichert drei Einträge in `session_courses`, `workoutId` und `workoutName` sind leer, `sessionName` ergibt „Einrudern + 2 km Intervall + Ausrudern · 1 Runde“; die Rangliste von „2 km Intervall“ enthält den Abschnitt, `rankings.workout` hat keinen Eintrag dafür.

## 2. Doku und Abschluss

- [ ] 2.1 README, Abschnitt Workouts: „Starten ohne Speichern“ beschreiben. Verifikation: der Abschnitt widerspricht dem Spec nicht.
- [ ] 2.2 Gesamtprüfung in der Linux-App (Scratch-DB, Simulator): Kette ohne Namen ohne Speichern rudern, Liste, Zusammenfassung und Rückkehr in den Editor prüfen. Verifikation: Screenshots; `make check` grün.
- [ ] 2.3 Am Handy (Nutzer): eine Kette ohne Speichern rudern.
