# Tasks

Texte nur über `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb` mit `@`-Beschreibung ändern, danach `make l10n`; der generierte Code wird committet. Jede Gruppe endet mit grünem `make check`.

## 1. Datenbank

- [x] 1.1 Schema 11 nach D4: Tabellen `workouts` und `workout_blocks`, Spalten `workout_id` und `workout_name` in `sessions`, Migration `from10To11` mit `renameTable` und `renameColumn`; `make codegen` und `make schema`. Verifikation: Der erzeugte Migrationstest von 10 auf 11 ist grün. Ein zusätzlicher Test legt in Schema 10 ein Workout mit Block und eine damit geruderte Session an, migriert und findet Workout, Block, Verknüpfung und Namen wieder.

## 2. Code

- [x] 2.1 Mechanischer Rename nach D3 in `lib/` und `test/`: Ordner und Dateien mit `git mv`, dann Bezeichner, l10n-Keys und Widget-Keys. Die Texte selbst bleiben in diesem Schritt unverändert. Verifikation: `grep -rniE 'template' lib test` findet nur noch die Ausnahmen aus D3 und den Lese-Fallback aus D5; `make check` ist grün.
- [x] 2.2 `HealthWorkout` → `HealthExercise` nach D2, inklusive Datei, Funktion und Tests. Verifikation: `make check` grün.

## 3. Texte

- [x] 3.1 Deutsche Texte nach D1: jede Erwähnung von „Vorlage“ in `app_de.arb`, auch in zusammengesetzten Wörtern, mit passenden Artikeln und Pronomen. Verifikation: `grep -i vorlage lib/l10n/app_de.arb` ist leer; die Widget-Tests finden „Workout rudern“, den Tab „Workouts“, „Workout anlegen“ und „Workout löschen?“.
- [x] 3.2 Englische Texte nach D1 und D2: „template“ → „workout“, Health-Connect-Texte → „exercise sessions“. Verifikation: `grep -i template lib/l10n/app_en.arb` findet nur `@`-Beschreibungen, die selbst schon angepasst sind (also keine); der englische Widget-Test findet „Workouts“.

## 4. Session-Dateien

- [x] 4.1 Export schreibt `workout`, Import liest `workout` und als Fallback `template` (D5). Verifikation in den Repository-Tests: Export und Import einer Workout-Session ergeben Namen und Runden; eine Datei mit `template` aus einem bestehenden Fixture oder Test-Helper liefert den Namen „Seerunde x3“ als Workout.

## 5. Doku und Prüfung

- [x] 5.1 README (Abschnitt „Zonen, Strecken und Workouts“ und alle weiteren Stellen) und `docs/implementation-plan.md` sprechen von Workouts. Verifikation: `grep -i vorlage README.md` ist leer.
- [x] 5.2 Gesamtprüfung: `make check` grün; die Linux-App mit einer Scratch-DB in Schema 10 starten, die Migration läuft, Workouts, Strecken und Sessions sind da, und nirgends steht „Vorlage“.
- [x] 5.3 Am Handy (Nutzer): App über die bestehende Installation aktualisieren; die Workouts und Sessions sind noch da, die Texte sprechen von Workouts.

## Workflow follow-up

- Nach dem Archivieren in den Haupt-Specs die Szenario-Titel umbenennen, die noch „Vorlage“ enthalten (D6), und prüfen, dass `grep -rn Vorlage openspec/specs` leer ist.
