# Proposal

## Why

Mit Strecken und Runden lässt sich jede Session vergleichen, und `statistics` führt die Bestleistungen pro Vorlage, Strecke und Zone. Das sieht man aber erst vor oder nach dem Rudern. Der Ghost macht den Vergleich während des Ruderns sichtbar: Man rudert gegen die eigene Bestleistung, Platz 1 der Rangliste, und sieht laufend, ob man vorne oder hinten liegt. Das ist der Kern von „gegen sich selbst rudern“. `courses` speichert die Runden bereits so, dass sich ihr Verlauf nachbilden lässt.

## What Changes

- **Ghost im Fortschrittsrahmen**: Auf jeder Spur des Fortschrittsrahmens aus `ui-design` (Strecke, Runde, Segment) steht ein kleines violettes Schiffchen an der Position, an der der Ghost zur gleichen Zeit war. Es fehlt auf einer Spur, wenn für diese Ebene keine Ghost-Daten vorhanden sind.
- **Abstand in der Pace-Box**: Eine Zeile „Ghost“ nennt den Abstand in Metern und Sekunden, z. B. „30 m vor dir · 7.6 s“. Liegt man zurück, ist der Wert orange, liegt man vorne, blau.
- **Wer der Ghost ist**: Auf jeder Spur ist es Platz 1 der Rangliste dieser Ebene aus `statistics`. Aussen ist es die Vorlage, in der Mitte die Strecke, auf die jede Runde neu startet, innen die Zone, auf die jede Fahrt neu startet.
- **Ghost-Symbol in der Vorlagenwahl**: Platz 1 der Plätze, die `statistics` in der aufgeklappten Vorlage zeigt, trägt das Schiffchen-Symbol.

Noch zu entscheiden, bevor die Tasks entstehen (siehe Open Questions in `design.md`): welcher Abstand bei unterschiedlichen Ebenen in der Box steht, ob Meter und Sekunden beide bleiben und wie nahe Schiffchen dargestellt werden. Wer der Ghost ist, ist entschieden (Design D2).

Nicht Teil dieses Changes: Ghosts anderer Personen, Ghost beim Replay, Ghost bei freiem Rudern.

## Capabilities

### New Capabilities

- `ghost`: Eine frühere Leistung auf derselben Strecke als Vergleich während des Ruderns mitführen und im Fortschrittsrahmen sowie als Abstand anzeigen.

### Modified Capabilities

Keine. Die Anzeige nutzt die Ghost-Positionen, die das Widget aus `ui-design` bereits entgegennimmt.

## Impact

- `lib/data/sessions`: Den Verlauf (Wanduhr, Achsenposition) des Eintrags auf Platz 1 aus den `samples` seiner Session rekonstruieren. Den Eintrag liefert `statistics`. Keine Schema-Änderung, das war ein Ziel von `courses`.
- `lib/features/live`: Ghost-Positionen an den Fortschrittsrahmen übergeben, Zeile in der Legende.
- `lib/features/templates`: Ghost-Zeit in der Vorlagenwahl.
- Design: Canvas „Stroke & Split Frontend“, Screens „Live: Vorlage mit Zonen“, „Live quer: Vorlage mit Zonen“ und „Vorlage wählen“.
- Voraussetzung: `ui-design` und `statistics` sind umgesetzt.
