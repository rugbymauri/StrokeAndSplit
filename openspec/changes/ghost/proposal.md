# Proposal

## Why

Mit Strecken und Runden lässt sich jede Session vergleichen, aber erst hinterher in der Zusammenfassung. Der Ghost macht den Vergleich während des Ruderns sichtbar: Man rudert gegen eine frühere eigene Leistung auf derselben Strecke und sieht laufend, ob man vorne oder hinten liegt. Das ist der Kern von „gegen sich selbst rudern“. `courses` speichert die Runden bereits so, dass sich ihr Verlauf nachbilden lässt.

## What Changes

- **Ghost im Fortschrittsrahmen**: Auf jeder Spur des Fortschrittsrahmens aus `ui-design` (Strecke, Runde, Segment) steht ein kleines violettes Schiffchen an der Position, an der der Ghost zur gleichen Zeit war. Es fehlt auf einer Spur, wenn für diese Ebene keine Ghost-Daten vorhanden sind.
- **Abstand in der Pace-Box**: Eine Zeile „Ghost“ nennt den Abstand in Metern und Sekunden, z. B. „30 m vor dir · 7.6 s“. Liegt man zurück, ist der Wert orange, liegt man vorne, blau.
- **Ghost-Bestzeit in der Vorlagenwahl**: Die aufgeklappte Vorlage zeigt mit Schiffchen-Symbol die Zeit des Ghosts.

Noch zu entscheiden, bevor Specs und Tasks vollständig sind (siehe Open Questions in `design.md`): wer der Ghost ist und welcher Abstand bei unterschiedlichen Ebenen in der Box steht.

Nicht Teil dieses Changes: Ghosts anderer Personen, Ghost beim Replay, Ghost bei freiem Rudern.

## Capabilities

### New Capabilities

- `ghost`: Eine frühere Leistung auf derselben Strecke als Vergleich während des Ruderns mitführen und im Fortschrittsrahmen sowie als Abstand anzeigen.

### Modified Capabilities

Keine. Die Anzeige nutzt die Ghost-Positionen, die das Widget aus `ui-design` bereits entgegennimmt.

## Impact

- `lib/data/sessions`: Verlauf (Wanduhr, Achsenposition) einer früheren Runde bzw. Session aus `laps`, `lap_segments` und `samples` rekonstruieren. Keine Schema-Änderung, das war ein Ziel von `courses`.
- `lib/features/live`: Ghost-Positionen an den Fortschrittsrahmen übergeben, Zeile in der Legende.
- `lib/features/templates`: Ghost-Zeit in der Vorlagenwahl.
- Design: Canvas „AergRow Frontend“, Screens „Live: Vorlage mit Zonen“, „Live quer: Vorlage mit Zonen“ und „Vorlage wählen“.
- Voraussetzung: `ui-design` ist umgesetzt.
