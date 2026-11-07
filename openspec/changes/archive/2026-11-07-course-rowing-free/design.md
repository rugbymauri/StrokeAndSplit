# Design

## Context

- Eine Session hängt heute über `SessionTemplate` (ID, Name, Strecke, Rundenzahl) an einer Vorlage. `SessionRecorder.start(template:)` in `lib/data/sessions/session_providers.dart` legt die Session an (`SessionRepository.create(template:)` setzt `template_id`, `template_name`, `course_version_id`, `planned_laps`), baut einen `SessionAccumulator` mit Strecke und `plannedLaps` und meldet `ActiveRecording.template` und `.lap`.
- Die Tabelle `sessions` erlaubt schon eine Session ohne Vorlage mit Strecke: `template_id` und `template_name` sind nullable, `course_version_id` und `planned_laps` ebenso. Die Ranglisten von Strecke und Zone (`ranking_repository.dart`) lesen nur `course_version_id` und `laps`, nicht die Vorlage.
- Die Sessionzeit ohne Pausen ist `_pause.activeMs` im `SessionAccumulator` (Change `auto-pause`). Der `LapTracker` bekommt sie als `wallMs`. Auf Zeitstrecken messen Runden also schon heute die Ruderzeit ohne Pausen. Die Main-Spec `course-rowing` („Fortschritt nach Wanduhr messen“) beschreibt noch den Stand vor `auto-pause`, das ändert dieser Change nicht.
- Eine Session endet von selbst, wenn `accumulator.lapsFinished` wahr wird (`_finishAfterLastLap`). Beim Beenden speichert `SessionRepository` die angefangene Runde als unvollständig (`_finishLastLap`).
- `ProgressFrameModel` (`lib/features/live/progress_frame_model.dart`) baut den äusseren Ring aus `plannedLaps × Länge`. Ohne Rundenzahl gibt es keinen äusseren Ring.
- Ghost-Keys (`liveGhostsKey`), Platzmarken (`session_places.dart`) und Titel (`templateName` in Session-Liste und Zusammenfassung) setzen eine Vorlagen-ID bzw. einen Vorlagennamen voraus. Die Zusammenfassung fällt schon auf den Streckennamen zurück (`session.templateName ?? course.name`), die Liste nicht.
- Change `template-screen` bringt `ActiveRecording.ghost` und `startRowing(..., ghost:)` (dort D4) sowie den Ghost-Schalter auf dem Vorlagen-Screen (D5). Dieser Change setzt ihn voraus.

## Goals / Non-Goals

**Goals:**
- Ein Begriff für „was gerudert wird“, der Vorlage und Strecke ohne Vorlage gleich behandelt, damit Recorder, Live-Display und Ghost nur an einer Stelle unterscheiden.
- Das Ende nach Dauer nutzt denselben Weg wie das Ende nach der letzten Runde.

**Non-Goals:**
- Keine Änderung an der Ranglisten-Berechnung. Sessions ohne Vorlage zählen über `course_version_id` ohnehin.
- Keine Dauer in Vorlagen, kein Editor-Umbau.

## Decisions

### D1: `SessionPlan` statt `SessionTemplate` im Recorder

Neu ist `SessionPlan` in `lib/data/sessions/session_plan.dart`: die `Course` in ihrer Version, eine Länge und optional die Vorlage (ID und Name). Die Länge ist eine von drei Formen:

```
sealed class PlanLength
  LapCount(int count)      -> Ende nach der letzten Runde
  TimeLimit(Duration time) -> Ende nach der Ruderzeit
  OpenLength()             -> Ende durch den Nutzer
```

`SessionTemplate` liefert ihren Plan über `toPlan()` (`LapCount` oder `OpenLength`). `LapCount` statt `Laps`, weil `Laps` schon die Tabelle der Runden in Drift ist (bei der Umsetzung geändert). Der Recorder startet mit `start(plan:, ghost:)`, `ActiveRecording` trägt `plan` statt `template`. `SessionRepository.create(plan:)` setzt `template_id` und `template_name` nur mit Vorlage, sonst `course_version_id`, `planned_laps` und neu `planned_duration_ms`. Frei rudern bleibt `plan: null`.

*Alternative*: `SessionTemplate` mit `id: null` und leerem Namen. Verworfen, weil dann jede Stelle, die heute eine echte Vorlage annimmt (Ghost der Vorlage, Platzmarke), still eine falsche Vorlage bekäme. Mit `plan.template == null` ist der Fall sichtbar.

### D2: Ende nach Dauer im Akkumulator

`SessionAccumulator` bekommt `plannedDuration` und meldet `planFinished`, sobald `lapsFinished` oder `_pause.activeMs >= plannedDuration` gilt. Der Recorder reagiert darauf wie heute auf `lapsFinished` (`_finishAfterLastLap` wird `_finishAfterPlan`). Weil `stop()` die angefangene Runde ohnehin als unvollständig speichert, braucht das Ende mitten in der Runde nichts Neues. Bei Dauer läuft der `LapTracker` mit offener Rundenzahl, damit er nie selbst beendet.

Das Ende liegt beim ersten Datenpunkt, dessen Ruderzeit die Dauer erreicht. Bei Datenpunkten alle 0.5–1 s endet die Session also höchstens etwa 1 s nach der Dauer. Ein Abschneiden der Werte auf genau 30:00 gibt es nicht, die Zusammenfassung zeigt die tatsächliche Zeit.

*Alternative*: ein Timer im Recorder. Verworfen, weil er Pausen selbst nachbilden müsste und bei Replay und Simulator mit Zeitraffer auseinanderliefe.

### D3: Schema 10 und Export

`sessions.planned_duration_ms` (nullable), Migration `from9To10`, `make schema` für die Migrationstests. Im `.strokesplit`-Header bleibt der Block `template` (für bestehende Leser), mit `name` null ohne Vorlage und neu `durationMs`, nur wenn gesetzt. Der Import liest `durationMs` optional. Ältere Dateien ohne Feld importieren unverändert.

*Alternative*: ein neuer Block `plan`. Verworfen, weil ältere App-Versionen dann die Rundenzahl nicht mehr fänden.

### D4: Äusserer Ring und Anzeige bei Dauer

`ProgressFrameModel` bekommt neben `LapProgress` die Ruderzeit und die Dauer. Bei Dauer ist der äussere Ring `activeMs / Dauer`, ohne Rundengrenzen, weil die Zahl der Runden offen ist. Wo heute bei fester Rundenzahl die gesamte Strecke steht (`courseDone`/`courseLength`), zeigt die Box die verbleibende Ruderzeit. Die Runde erscheint ohne Gesamtzahl („Runde 3“), wie heute bei offener Rundenzahl. Mit Runden und offen bleibt alles wie heute.

### D5: Ghost und Platzmarken ohne Vorlage

`LiveGhostsKey.templateId` wird nullable. Ohne Vorlage gibt es keinen Ghost der Vorlage, Runden- und Zonen-Ghost laufen über Strecke und Zone wie bisher. Bei Dauer hat der Key keine Rundenzahl, der Ghost der Vorlage fiele also ohnehin weg. Die Ghost-Wahl kommt aus `ActiveRecording.ghost` (`template-screen` D4). Die Platzmarken setzen schon heute ohne Vorlage keine Marke für die Session; Runden und Zonenfahrten bekommen ihre Marken wie bei einer Vorlage.

### D6: Start-Screen `CourseStartScreen`

Neu in `lib/features/courses/course_start_screen.dart`, geöffnet vom Button „Rudern“ in `CourseDetailScreen` (unten fest unter den Ranglisten). Aufbau wie der Vorlagen-Screen aus `template-screen`:

```
+-------------------------------------+
| <-  Seerunde                        |
|-------------------------------------|
|  [=====|=====|======]   2.4 km      |
|                                     |
|  [ Runden | Dauer | Offen ]         |   SegmentedButton
|                                     |
|  Runden        [-]   3   [+]        |   nur die gewählte Eingabe
|-------------------------------------|
|  [G] Gegen den Ghost rudern  [==o]  |   fest unten
|  [           Starten             ]  |
+-------------------------------------+
```

- Optionen als `SegmentedButton`, beim Öffnen „Runden“. Bei der Umsetzung geändert: die Optionsleiste des Vorlagen-Editors, nach `lib/app/widgets/segment_choice.dart` gezogen, damit beide gleich aussehen. Die Werte der anderen Optionen bleiben im State, solange der Screen offen ist.
- Rundenzahl mit `OarStepper` wie im Vorlagen-Editor, ab 1, Start 3.
- Dauer mit `OarStepper` in 1-min-Schritten, 1–180 min, Start 30. Gedrückt halten wiederholt schneller. Anzeige über die vorhandene Zeitformatierung (`30:00`, `1:30:00`).
- Ghost-Zeile und „Starten“ sind dasselbe Widget wie auf dem Vorlagen-Screen. `template-screen` legt es so an, dass es sich teilen lässt; sonst zieht dieser Change es nach `lib/app/widgets/`.
- „Starten“ ruft `startRowing(context, ref, plan:, ghost:)`.
- Gelöschte Strecke, während der Screen offen ist: Er schliesst sich wie die Detailansicht.

### D7: Titel ohne Vorlage

Eine Hilfsfunktion `planLabel(l10n, plannedLaps, plannedDuration)` liefert „3 Runden“, „30 min“ oder „offen“. Die Session-Liste zeigt ohne Vorlage `Streckenname · planLabel`. Dafür lädt die Liste den Streckennamen über `course_version_id` mit. Die Zusammenfassung zeigt dasselbe. Der Titel für Health Connect nimmt ohne Vorlage den Streckennamen.

## Risks / Trade-offs

- [Umbau von `template` zu `plan` berührt viele Stellen] → Der Umbau kommt als erster Schritt ohne Verhaltensänderung, mit allen bestehenden Tests grün, bevor Dauer und Start-Screen dazukommen.
- [Ende bis etwa 1 s nach der Dauer] → So gewollt (D2), damit das Ende auf echten Daten liegt. Test mit Simulator im Zeitraffer.
- [Die Session-Liste braucht den Streckennamen] → ein Join über `course_versions` und `courses` in der Abfrage der Liste. Gelöschte Strecken behalten ihre Versionen, der Name bleibt also lesbar.
- [Vorgaben ohne Rückmeldung des Nutzers] → „Runden“ als Start-Option und 3 Runden als Startwert sind Vorgaben dieses Designs, ebenso 1–180 min mit Start 30 min. Sie lassen sich ohne Folgen für Datenmodell und Specs ändern.
- [Abhängigkeit von `template-screen`] → Ghost-Wahl und Ghost-Zeile kommen von dort. Dieser Change startet erst, wenn `template-screen` in `main` umgesetzt ist.
