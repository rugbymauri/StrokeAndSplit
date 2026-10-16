# Proposal

## Why

Die App speichert seit `courses` und `zones` jede Runde und jede Fahrt durch eine Zone. Diese Ergebnisse sieht man aber nur in der Zusammenfassung einer einzelnen Session. Wer wissen will, wie gut eine Vorlage, eine Strecke oder ein Sprint bisher gelungen ist und wann, muss die Sessions einzeln durchsuchen. Ranglisten machen die eigenen Bestleistungen sichtbar und liefern dem `ghost`-Change, gegen wen gerudert wird: Platz 1 jeder Ebene.

## What Changes

- **Drei Ranglisten**, berechnet aus den gespeicherten Sessions:
  - **Vorlage**: Ein Eintrag ist eine ganze Session mit allen geplanten Runden.
  - **Strecke**: Ein Eintrag ist eine vollständige Runde. Gezählt werden alle Vorlagen, die diese Strecke verwenden.
  - **Zone**: Ein Eintrag ist eine Fahrt durch die Zone. Gezählt werden alle Strecken, in die sie eingebaut ist.
- **Was zählt**: Auf einer Distanzachse ist es die benötigte Zeit, auf einer Zeitachse sind es die erreichten Meter. Gemessen wird nach Wanduhr inklusive Pausen, wie in `course-rowing`. Zu jedem Eintrag stehen Datum und Pace.
- **Vergleichbar ist, was gleich lang ist.** Eine Strecke oder Zone mit einer anderen Länge bekommt eine eigene Rangliste. Bei Vorlagen müssen Streckenlänge und Rundenzahl übereinstimmen. Vorlagen mit offener Rundenzahl haben keine eigene Rangliste.
- **Plätze 1–3** stehen an drei Stellen:
  - in der Vorlagenwahl,
  - in einer neuen Detailansicht von Strecke und Zone,
  - in der Zusammenfassung, wo ein Eintrag markiert wird, der neu auf Platz 1–3 kommt.
- Simulierte Sessions zählen nicht. Mit einer gelöschten Strecke, Zone, Vorlage oder Session verschwinden auch ihre Einträge.

Nicht Teil dieses Changes:
- der Ghost selbst (Change `ghost`; er nimmt Platz 1 als Ghost),
- Ranglisten über freie Abschnitte,
- Ranglisten über Personen hinweg,
- Diagramme und Verläufe über die Zeit.

## Capabilities

### New Capabilities

- `statistics`: Bestleistungen pro Vorlage, Strecke und Zone aus den geruderten Sessions bestimmen und die Plätze 1–3 anzeigen.

### Modified Capabilities

Keine. Die Zusammenfassung aus `course-rowing` bleibt, wie sie ist. Die Markierung neuer Plätze kommt als eigene Anforderung in `statistics` dazu.

## Impact

- `lib/data`: Abfragen über `sessions`, `laps`, `lap_segments` und `course_segments` der geruderten Version. Kein Schema-Wechsel, höchstens ein Index.
- `lib/features/templates`: Plätze in der Vorlagenwahl.
- `lib/features/courses`, `lib/features/zones`: neue Detailansicht mit den Ranglisten.
- `lib/features/sessions`: Markierung neuer Plätze in der Zusammenfassung.
- `ghost`: Damit ist F5 entschieden. Der Ghost jeder Ebene ist Platz 1 der Rangliste dieser Ebene.
- `ui-design`: Die Gestaltung von Vorlagenwahl und Zusammenfassung kommt aus `ui-design`. Wird `statistics` vorher umgesetzt, übernimmt `ui-design` die neuen Elemente.
