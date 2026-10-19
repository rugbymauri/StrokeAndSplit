# Design

## Context

Alles, was die Ranglisten brauchen, wird seit `courses` und `zones` schon gespeichert (Schema 4 nach `device-types`):

```
 sessions --(courseVersionId)--> course_versions (courseId, length) --> courses (axis, deletedAt)
    |                                   |
    |                                   +--> course_segments (position, length, zoneId) --> zones (deletedAt)
    |                                                ^
    +--> laps (lapNo, start/endWallMs, start/endDistanceDm, complete)
    +--> lap_segments (lapNo, position, durationMs, distanceDm)
    |        position + geruderte Version  ----------+
    +--> templateId, plannedLaps, source, startedAt
```

- Die Zeiten von Runden und Abschnitten sind Sessionzeiten ohne Pausen (`course-rowing`, „Fortschritt nach Sessionzeit messen“, Change `auto-pause`). Bei Sessions von vor `auto-pause` sind es Wanduhrzeiten inklusive Pausen.
- Eine Zone gehört zu einem Abschnitt einer Runde über `lap_segments.position` und das `course_segments` der Version, die die Session gerudert hat. Dort steht auch die Länge der Zone zu diesem Zeitpunkt.
- Strecken und Zonen werden weich gelöscht (`deletedAt`). Eine gelöschte Vorlage setzt `sessions.templateId` auf `NULL`, eine gelöschte Session löscht ihre Runden und Abschnitte mit.

## Goals / Non-Goals

**Goals:**
- Plätze 1–3 jeder Rangliste schnell genug für Listen und die Vorlagenwahl.
- Ein Eintrag verweist so genau auf seine Session und ihren Bereich (Runde bzw. Abschnitt), dass `ghost` daraus den Verlauf rekonstruieren kann.

**Non-Goals:**
- Den Ghost-Verlauf aus den `samples` berechnen. Das macht `ghost`.
- Ranglisten speichern oder zwischenspeichern.
- Mehr als die Plätze 1–3 anzeigen.

## Decisions

### D1: Berechnen statt speichern

Ranglisten werden bei jeder Anzeige per Abfrage aus den gespeicherten Sessions berechnet und nicht in einer eigenen Tabelle abgelegt. So bleiben sie ohne Nachführen richtig, wenn Sessions gelöscht, importiert oder nach einem Absturz wiederhergestellt werden, und es braucht keine eigene Tabelle. Der einzige Schema-Wechsel ist die Markierung importierter Sessions (D3, Schema 5). Die Abfragen laufen als beobachtete Streams wie die übrigen Listen, damit eine neue Session sofort erscheint.

Alternative: eine Tabelle mit Bestleistungen, die beim Beenden einer Session nachgeführt wird. Verworfen, weil jeder Löschpfad (Session, Strecke, Zone, Vorlage) und der Import sie ebenfalls nachführen müssten.

Zeigt sich am Gerät, dass die Abfragen zu langsam sind, kommt ein Index auf `lap_segments` bzw. `laps` dazu (siehe Risiken), immer noch ohne neue Tabelle.

### D2: Drei Ebenen, drei Schlüssel

| Rangliste | Eintrag | Gruppiert nach | Wert |
|---|---|---|---|
| Vorlage | Session mit `plannedLaps` vollständigen Runden | Vorlage, Streckenlänge, Rundenzahl | Summe der Rundenzeiten bzw. Rundendistanzen |
| Strecke | vollständige Runde | Strecke (`courseId`), Länge der geruderten Version | Rundenzeit bzw. Rundendistanz |
| Zone | Abschnitt einer vollständigen Runde, der auf diese Zone fällt | Zone (`zoneId`), Länge des Abschnitts in der geruderten Version | Dauer bzw. Distanz des Abschnitts |

- Auf einer Distanzachse ist der kleinere Wert besser, auf einer Zeitachse der grössere.
- Versionen einer Strecke mit derselben Länge gehören zusammen, auch wenn ihre Zonen sich unterscheiden. Eine Strecke mit mehreren Längen hat eine Rangliste pro Länge.
- Für die Vorlage zählt die Streckenlänge der geruderten Version. Ändert der Nutzer die Strecke einer Vorlage auf eine andere mit gleicher Länge, laufen die Einträge in derselben Rangliste weiter.
- Abschnitte zählen nur aus vollständigen Runden. Bei einer unvollständigen Runde ist nicht sicher, ob der letzte Abschnitt fertig gerudert wurde.

### D3: Was zählt

- Nur Sessions mit der Quelle `pm5` oder `ftms`. `simulator` und `replay` zählen nicht.
- Importierte Sessions zählen nie, auch wenn sie an einem Rudergerät entstanden sind. Sie behalten ihre Quelle, der Import setzt die neue Spalte `sessions.imported` (bool, Default `false`, `schemaVersion` 5). Die Migration markiert bestehende Sessions als nicht importiert, denn vor Schema 5 lässt sich ein Import nicht mehr erkennen. So bleiben die Ranglisten bei den Sessions, die auf diesem Gerät gerudert wurden, und eine Kopie derselben Session über Export und Import erscheint nie doppelt.
- Alternative: importierte Sessions an der Quelle erkennen, z. B. mit einer eigenen Quelle `import`. Verworfen, weil die Quelle für Anzeige und Rohdaten-Dekodierung gebraucht wird.
- Gelöschte Strecken, Zonen und Vorlagen haben keine Rangliste. Ihre Sessions bleiben unverändert.
- Jede Fahrt ist ein eigener Eintrag. Alle drei Plätze dürfen aus derselben Session stammen.
- Bei Gleichstand liegt der frühere Eintrag vorne. Wer eine Zeit zuerst gerudert hat, behält den Platz.

### D4: Pace

Pace pro 500 m = Sessionzeit des Eintrags ÷ Distanz × 500. Seit Change `auto-pause` gehen Pausen weder in die Zeit noch in die Pace ein, bei älteren Sessions schon (Wanduhr). Die Pace passt so zur Zeit, nach der der Platz bestimmt wird.

### D5: Eintrag für den Ghost

Jeder Eintrag trägt:
- `sessionId`,
- die Runde,
- bei Zonen die Position des Abschnitts,
- Beginn und Ende als Sessionzeit (vor `auto-pause`: Wanduhrzeit) und Distanz.

Für Runden steht das direkt in `laps`. Für Abschnitte ergibt es sich aus dem Rundenbeginn und den Abschnitten davor. Mehr braucht `ghost` nicht, um den Verlauf aus den `samples` zu lesen.

### D6: Anzeige

- **Vorlagenwahl**: Die aufgeklappte Vorlage zeigt Platz 1–3 mit Wert, Pace und Datum. Platz 1 trägt das Ghost-Symbol, sobald `ghost` umgesetzt ist. Bei offener Rundenzahl steht dort statt der Plätze ein Hinweis, dass es keine Bestzeit gibt.
- **Detailansicht Strecke und Zone**: Sie ist neu und öffnet sich per Tipp aus der Strecken- bzw. Zonenliste. Dort stehen die Plätze 1–3 pro Länge, die aktuelle Länge zuerst. Bearbeiten erreicht man von dort aus.
- **Zusammenfassung**: Jede Runde und jede Zonenfahrt dieser Session, die in ihrer Rangliste auf Platz 1–3 steht, bekommt ihren Platz als Marke. Ebenso die Session selbst, wenn sie in der Rangliste ihrer Vorlage auf Platz 1–3 steht. Gezeigt wird der aktuelle Platz. Öffnet man die Zusammenfassung später, kann die Marke weggefallen sein.

Die Gestaltung folgt `ui-design`. Wird `statistics` vor `ui-design` umgesetzt, kommen die Elemente schlicht im heutigen Material-Stil und `ui-design` gestaltet sie mit.

## Risks / Trade-offs

- [Abfragen über alle Abschnitte werden mit vielen Sessions langsam] → Die Zahl der Abschnitte wächst mit Runden mal Zonen, nicht mit den Messpunkten. Erst messen, dann bei Bedarf einen Index ergänzen (D1).
- [Strecke kurz umgestellt und zurück: Die Rangliste der alten Länge taucht wieder auf] → Gewollt, weil vergleichbar ist, was gleich lang ist.
- [Pace mit Pausen sieht langsamer aus als im Live-Display] → In der Detailansicht kennzeichnen, dass Pausen mitzählen.
- [Eine neu angelegte Zone mit gleichem Namen beginnt bei null] → Gewollt. Mit einer gelöschten Zone ist auch ihre Rangliste weg.
