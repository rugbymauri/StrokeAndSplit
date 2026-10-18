# Design

## Context

Der `SessionAccumulator` macht aus den Rohpaketen einer Session Samples, Schläge und, auf einer Vorlage, über den `LapTracker` Runden und Abschnitte. Er kennt drei Zeiten:

- `samples.t_ms`: die Zeit des Monitors über `SessionOffset`. Der PM5 hält sie an, wenn er nicht mehr rudern meldet; der `FtmsDecoder` zählt seine eigene Uhr nur, solange in den letzten 4 s Distanz oder Schläge dazukamen.
- `samples.wall_ms`: Wanduhr seit dem ersten Paket der Session (`RawPacket.time`).
- `LapTracker`: Runden, Abschnitte, Zonenanteil und `courseTime` des Ghosts auf `wall_ms`.

Die Zusammenfassung nimmt `MAX(t_ms)` als Dauer. Die Live-Anzeige zeigt die Monitor-Zeit.

Die Fixtures zeigen, wie ein Stillstand aussieht:

- `pause.jsonl` (PM5): Der letzte Schlag endet bei 101.3 s. Das Schwungrad läuft aus, die Distanz steigt noch bis 108.1 s und der PM5 meldet so lange „rudert“. Erst dann meldet er „rudert nicht“, hält seine Uhr an und schickt im selben Paket den letzten, noch offenen Schlag (der Decoder gibt ihn mit `_flushStroke` aus). Beim Weiterrudern steigt die Distanz bei 188.3 s, „rudert“ kommt bei 189.1 s, der erste Schlag bei 190.1 s.
- `just_row.jsonl`, `force_curve.jsonl`: Schläge kommen einmal pro Zyklus, am Ende der Rückrollphase, im Abstand von 1.8 bis 3.8 s.
- `ftms_just_row.jsonl`: ein Datensatz pro Sekunde, Schläge aus dem Schlagzähler.

## Goals / Non-Goals

**Goals:** Eine Regel für PM5, FTMS, Simulator, Import und Replay; Sessionzeit, Runden, Abschnitte, Zonenanteil und Ghost auf derselben Achse; gespeicherte Sessions bleiben gültig.

**Non-Goals:** Einstellbare Schwelle; Neuberechnung gespeicherter Sessions; Änderung des Export-Formats; Änderung der Monitor-Zeit `t_ms`.

## Decisions

### D1: Pause aus dem Schlagrhythmus erkennen

Ein reiner Detektor (`lib/data/sessions/auto_pause.dart`) bekommt pro Paket dessen Wanduhr-Zeit und die dekodierten Ereignisse. Er arbeitet nur mit `Stroke` und `StatusTick`, also gleich für PM5 und FTMS.

- **Zählende Schläge:** jedes `Stroke`-Ereignis, ausser es kommt im selben Paket wie ein `StatusTick` mit `isRowing == false`. Das ist der Schlag, den der PM5 beim Stillstand nachreicht (`pause.jsonl` bei 108.1 s); er darf eine Pause weder verzögern noch beenden.
- **Rhythmus:** Abstand der letzten beiden zählenden Schläge, höchstens 6 s. Nach dem Start und nach einer Pause, solange es noch keine zwei Schläge gibt, ist er 0.
- **Beginn der Pause:** letzter zählender Schlag (oder Beginn der Session bzw. Ende der letzten Pause, wenn seitdem keiner kam) + Rhythmus + 3 s. Die Pause beginnt genau zu diesem Zeitpunkt, erkannt wird sie mit dem ersten Paket danach. Die Zeit bis dahin zählt zur Session, es wird nichts rückwirkend abgezogen. So läuft die Sessionzeit nie rückwärts.
- **Ende der Pause:** ein zählender Schlag oder ein Messwert, mit dem der Monitor von „rudert nicht“ auf „rudert“ wechselt. Beim Schlag endet die Pause mit dessen Paket. Beim Wechsel endet sie beim ersten Messwert, ab dem die Distanz wieder gestiegen ist (`pause.jsonl`: 188.3 s statt 189.1 s), frühestens aber bei ihrem Beginn. So geht vom ersten Schlag nach der Pause wenig verloren.

Alternativen:

- *3 s seit dem letzten Schlag, wörtlich:* verworfen. Schläge kommen einmal pro Zyklus; bei 18 Schlägen pro Minute liegen 3.3 s dazwischen, die Session würde bei jedem Schlag kurz pausieren. „3 s ohne Schlag“ wird daher als „3 s ohne den fälligen Schlag“ umgesetzt (siehe offene Fragen).
- *Pause, wenn die Distanz 3 s steht:* verworfen. Der PM5 zählt Distanz, solange das Schwungrad ausläuft, in `pause.jsonl` 7 s nach dem letzten Schlag; die Pause käme erst nach etwa 10 s.
- *„rudert“ des Monitors:* nur als Ende der Pause genutzt. Als Beginn wäre es auf dem PM5 zu spät (s. o.) und auf FTMS nur eine Schwelle des eigenen Decoders.
- *Distanzanstieg als Ende:* verworfen, weil die auslaufende Distanz eine früh erkannte Pause sofort wieder beenden würde.

### D2: Sessionzeit als eigene Achse

Sessionzeit = Wanduhr minus abgeschlossene Pausen minus laufende Pause. Der Accumulator führt sie neben Monitor- und Wanduhr-Zeit:

- `SessionAccumulator.progress` liefert Distanz und Sessionzeit; das sieht das Live-Display ohne Änderung. Die Monitor-Zeit bleibt in `t_ms` und für die Lage der Schläge.
- Neue Spalte `samples.active_ms`. Null bei Sessions vor Schema 7; Leser nehmen dann `wall_ms` (`COALESCE(active_ms, wall_ms)`), damit Ghost und Wiederherstellung für alte Sessions wie bisher arbeiten.
- Der `LapTracker` bekommt die Sessionzeit statt der Wanduhr. Er bleibt unverändert und rein; Zeitstrecke, Runden- und Abschnittszeiten, `courseTime` (Ghost) und Zonenanteil stehen in der Pause damit von selbst still, und die Pause zählt im Zonenanteil weder innen noch aussen.
- Die Spalten `laps.start_wall_ms`/`end_wall_ms` behalten ihren Namen und enthalten ab Schema 7 die Sessionzeit. Bei älteren Sessions ist es die Wanduhr, die dort ohne Pausenerkennung dasselbe bedeutet. Ein Umbenennen hätte Ranglisten- und Ghost-Abfragen sowie die offenen Changes berührt, ohne am Verhalten etwas zu ändern. Der Kommentar im Schema hält die Bedeutung fest.
- Samples werden wie bisher ohne Vorlage nur gespeichert, wenn sich Monitor-Zeit, Distanz oder Sessionzeit ändern; auf einer Vorlage weiter jeder Messwert, damit die Wiederherstellung den `LapTracker` mit denselben Punkten füttert.

### D3: Pausen und Summen speichern

- Tabelle `pauses` (`session_id`, `start_wall_ms`, `end_wall_ms`), Primärschlüssel `session_id` + `start_wall_ms`. Eine Pause wird mit ihrem Ende Teil des nächsten Batches.
- Eine Pause, die beim Beenden noch läuft, wird verworfen: Die Session endet mit dem Stand vor der Pause, gezählt wird sie nicht. Bei der Wiederherstellung nach einem Absturz gilt dasselbe.
- `sessions.pause_count` und `sessions.paused_ms` (Default 0) rechnet `finish()` aus der Tabelle. `duration_ms` ist `MAX(active_ms)`, für alte Sessions bei der Wiederherstellung `MAX(t_ms)` wie bisher. Durchschnittspace und -schlagzahl folgen der Dauer.
- Der Export schreibt `pauseCount` und `pausedMs` zusätzlich in den Kopf. Der Import liest sie nicht, sondern erkennt die Pausen wie bei der Aufzeichnung aus den Rohdaten.

### D4: Live-Display

`ActiveRecording` bekommt `paused`. Der Recorder setzt einen neuen Zustand, sobald sich Fortschritt oder `paused` ändern. Ein eigenes Widget `PauseHint` in `lib/features/live/pause_hint.dart` blendet „Pause“ wie den `ReadyHint` über der Anzeige ein. `LiveScreen` bekommt dafür eine Zeile neben dem `ReadyHint`; `live_course.dart` und `live_free.dart` bleiben unverändert, weil sie die Werte aus `progress` und `lap` schon richtig zeigen. Das hält den Rebase mit `feature/course-session-time` klein. Die Kennzeichnung „veraltet“ bleibt, wie sie ist: Sie hängt an ausbleibenden Daten, und PM5 und FTMS senden in der Pause weiter.

### D5: Bestand, Import und Ranglisten

- Gespeicherte Sessions werden nicht neu berechnet: Sie behalten Dauer, Runden und Zonenanteil mit Pausen und zeigen keine Pausen.
- Import und Replay laufen über denselben Accumulator. Eine Datei ohne Stillstand ergibt dieselben Werte wie bisher; eine ältere Datei mit Stillstand bekommt beim Import Pausen und kürzere Runden.
- Ranglisten mischen damit Runden mit Pausen (alt) und ohne (neu). Der Hinweis unter den Ranglisten sagt künftig, dass Pausen nicht zählen, ausser bei Sessions vor der Auto-Pause.

## Risks / Trade-offs

- [Ein Schlag nach sehr langer Rückrollphase, z. B. bei Technikübungen mit Halt, gilt als Pause] → Der Rhythmus misst bis 6 s mit; erst darüber pausiert die Session. Ein kurzer Halt kostet höchstens die Zeit bis zum nächsten Schlag.
- [Weiterrudern, solange der PM5 noch „rudert“ meldet, endet die Pause erst mit dem ersten gemeldeten Schlag, etwa 1–2 s nach dessen Beginn] → Hinnehmbar; die Distanz dieses Schlags zählt trotzdem, nur seine Zeit fehlt teilweise.
- [Bis zur Erkennung zählt der Stillstand zur Session, etwa Rhythmus + 3 s pro Pause] → So gewollt, damit die Zeit nie rückwärts läuft.
- [`laps.*_wall_ms` heisst anders, als es ab Schema 7 enthält] → Kommentar im Schema und hier; Umbenennen bei Bedarf in einem späteren Change.
- [Offene Changes mit Schema-Änderungen (`force-curve`, `heart-rate`-Nacharbeiten) kollidieren bei der Schema-Nummer] → Wer später merged, zählt hoch und erzeugt den Snapshot neu.
- [Der Change `statistics` (noch nicht archiviert) verlangt „Pause zählt mit“] → Kann hier nicht per Delta geändert werden, weil seine Spec noch nicht unter `openspec/specs` liegt; beim Archivieren von `statistics` bzw. danach dieses Changes nachziehen.

## Migration Plan

Schema 6 → 7: `samples.active_ms` (nullable), `sessions.pause_count` und `sessions.paused_ms` (Default 0), Tabelle `pauses`. Bestehende Zeilen bleiben unverändert. Snapshot und Migrationstests mit `make schema`. Kein Rollback ausser über ein Backup der Datenbank.

## Open Questions

Defaults sind gesetzt und umgesetzt; der Nutzer kann sie später ändern, ohne dass sich der Aufbau ändert:

1. **Schwelle relativ zum Rhythmus:** Umgesetzt ist „3 s nach dem fälligen Schlag“ statt „3 s nach dem letzten Schlag“ (D1). Soll es wörtlich 3 s ab dem letzten Schlag sein, pausieren langsame Rhythmen unter etwa 20 Schlägen pro Minute fälschlich.
2. **Pause vor dem ersten Schlag bei freiem Rudern:** Wer „Session starten“ wählt und erst später rudert, bekommt nach 3 s eine Pause, die in der Zusammenfassung mitzählt. Alternative: Die Sessionzeit startet erst mit dem ersten Schlag, wie bei Vorlagen.
3. **Pause am Ende:** Eine beim Beenden laufende Pause wird verworfen und nicht gezählt. Alternative: als Pause speichern.
4. **Ghost in der Pause:** Der Ghost steht still, weil er auf der Sessionzeit läuft. Alternative wäre ein Ghost, der auf der Wanduhr weiterfährt.
5. **Gemischte Ranglisten:** Alte Runden mit Pausen bleiben in den Ranglisten. Alternative: alte Sessions beim Update aus den Rohdaten neu berechnen.
