# Design

## Context

`LiveScreen` ruft `SessionRecorder.start(template:)` auf, sobald die Quelle verbunden ist. `start` legt die Session sofort in der Datenbank an, und der `SessionAccumulator` setzt den Nullpunkt (`SessionOffset`) und den Wanduhr-Nullpunkt auf das erste Paket bzw. den ersten Messwert. Der `LapTracker` misst Zeitabschnitte, Runden und den Ghost auf der Wanduhr. Alles läuft also ab der Verbindung.

Die Fixtures zeigen, wann die erste Bewegung erkennbar ist:

- `just_row.jsonl` und `force_curve.jsonl` (PM5): Im Leerlauf sendet der PM5 etwa alle 0.3–0.5 s 0 m und 0:00. Zuerst kommt ein Schlag-Paket (Schlag 0, 0:00, 0 m), danach der erste Messwert mit 0.1 m. Der PM5 beginnt seine Zeit selbst erst mit dem ersten Schlag.
- `ftms_just_row.jsonl` (FTMS): Ein Datensatz pro Sekunde; die Distanz steigt im Datensatz vor dem ersten gemeldeten Schlag.
- `pause.jsonl` (PM5): In der Pause zeigt der PM5 weiter die Schlagzahl 28 bei stehender Distanz.
- Simulator: rudert ab der Verbindung, der erste Messwert zeigt schon Distanz.

## Goals / Non-Goals

**Goals:** Zeit, Zeitabschnitte und Ghost laufen erst ab dem ersten Schlag; nichts vom ersten Schlag geht verloren; Abbruch vor dem Start hinterlässt nichts.

**Non-Goals:** Freies Rudern mit Start beim ersten Schlag; Anpassung des Simulators.

## Decisions

### D1: Bereit-Zustand im Recorder, Session erst beim Start anlegen

`start(template:)` legt nur noch einen Bereit-Zustand an: `ActiveRecording` ohne `sessionId`, mit Fortschritt 0 und dem Stand eines frischen `LapTracker` (Runde 1, Abschnitt 1, Zeiten 0, Ghost am Start). Die Session wird erst in der Datenbank angelegt, wenn die erste Bewegung erkannt ist. `stop()` im Bereit-Zustand beendet das Warten und liefert `null`, so dass Trennen und „Session beenden“ ohne Sonderweg nichts speichern.

Alternative: Session sofort anlegen und bei Abbruch löschen. Verworfen, weil ein Absturz im Bereit-Zustand eine leere, unvollständige Session hinterliesse, die die Wiederherstellung dann aufnimmt.

### D2: Erste Bewegung und Nullpunkt

Ein eigener Detektor dekodiert die Pakete im Bereit-Zustand mit einem eigenen Decoder. Der letzte Messwert ist die Basis. Erste Bewegung ist, was zuerst kommt:

- ein Messwert mit mehr Distanz als die Basis,
- ein Schlag-Ereignis,
- eine Schlagzahl über 0, wenn die Basis keine Schlagzahl über 0 hatte.

Die letzte Bedingung weicht vom Wunsch „Schlagzahl > 0“ ab: Laut `pause.jsonl` zeigt der PM5 in einer Pause die alte Schlagzahl weiter; sie allein darf die Session nicht starten. Sinkt die Distanz (Reset am PM5), wird der neue Messwert einfach die Basis.

Erkennt der Detektor die Bewegung, beginnt die Session mit den Paketen ab dem ersten Paket der Basis. Der Accumulator erhält sie wie gewohnt; sein erster Messwert ist die Basis und damit Nullpunkt von Zeit und Distanz, das erste Basis-Paket der Wanduhr-Nullpunkt. Gibt es noch keine Basis (erster Messwert zeigt schon Distanz, z. B. beim Simulator), wird der erste Messwert die Basis; so verhält es sich wie bisher.

Pakete, die während des asynchronen Anlegens der Session eintreffen, werden gepuffert und danach in Reihenfolge verarbeitet. Der Wanduhr-Start (`startedAt`) ist der Moment der Erkennung.

### D3: Rohpakete beginnen mit dem Nullpunkt

Gespeichert werden die Rohpakete ab dem ersten Paket der Basis, nicht die Wartezeit davor. Gründe:

- Die Session beginnt mit dem Start; Wartezeit gehört nicht dazu und würde den Export bei langem Warten nur aufblähen.
- Import und Replay dekodieren die gespeicherten Pakete mit einem frischen Accumulator. Weil die gespeicherten Pakete mit der Basis beginnen, setzt dieser denselben Nullpunkt, und es ergeben sich dieselben Messwerte, Runden und Abschnitte.
- Ein Replay einer solchen Session als Quelle startet eine gewählte Vorlage wieder beim ersten Schlag, weil die Basis davor liegt.

### D4: Nur für Vorlagen

Freies Rudern bleibt beim Button „Session starten“, der sofort startet: Wer ihn drückt, will jetzt starten. Bei Vorlagen startet heute die Verbindung die Session, nicht der Nutzer.

### D5: Hinweis als eigenes Widget

Der Hinweis „Bereit – startet mit dem ersten Schlag“ ist ein eigenes Widget in `lib/features/live/ready_hint.dart`, das `LiveScreen` mit einer Zeile über der Anzeige einblendet, solange die Session bereit ist. So bleiben die Änderungen in den Live-Dateien klein.

## Risks / Trade-offs

- [Simulator rudert ab der Verbindung] → Der Bereit-Zustand ist dort nur einen Messwert lang sichtbar; die Session startet praktisch sofort. Für einen manuellen Test eignet sich der PM5 oder FTMS-Rower.
- [Bis zu einem Messintervall vor dem ersten Schlag zählt zur Wanduhr] → Der Nullpunkt ist der letzte Leerlauf-Messwert (PM5 0.3–0.5 s, FTMS 1 s davor). Die PM5-Zeit beginnt trotzdem bei 0:00; nur die Wanduhr enthält diesen kurzen Rest. Lieber etwas zu früh als den ersten Schlag abschneiden.
- [Session im Bereit-Zustand bei Absturz] → Es gibt nichts wiederherzustellen, die Vorlage muss neu gewählt werden.
