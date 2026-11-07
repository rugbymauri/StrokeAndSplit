# Design

## Context

`CourseEditorScreen` (`lib/features/courses/course_editor_screen.dart`) hält die Lage der Zonen als `_placements` (`ZonePlacement(zoneId, start)`) und rechnet daraus mit `resolveCourse` den Ablauf und die Fehler. Einbauen und Verschieben laufen beide über `_PlaceZoneDialog`, einen `AlertDialog`:
- oben die Zonen als Radio-Liste (`_ZoneOption`), die der anderen Achse ausgegraut,
- darunter der Start als `OarStepper` mit `max = Streckenlänge − Zonenlänge`,
- dann eine Vorschau oder der Fehler aus `resolveCourse` und „Einbauen“ bzw. „Verschieben“.

Ein Tipp auf einen Abschnitt im Balken (`CourseStrip.onSegmentTap`) oder in der Liste (`_SectionTile`) ruft `_openSegment` auf. Ein freier Abschnitt öffnet so den Dialog mit seinem Anfang als Start, eine Zone den Dialog zum Verschieben. `_selected` umrandet den Abschnitt, solange der Dialog offen ist.

`zoneIntensity` (`lib/data/courses/zone_intensity.dart`) liefert die Härte, `CourseStrip.segmentColors` die Farbe, `openZoneEditor` (`zones_screen.dart`) öffnet den Zonen-Editor und liefert die id der neuen Zone.

## Goals / Non-Goals

**Goals:**
- Einbauen vom Ort aus: Start wählen, passende Zonen sehen, eine antippen.
- Verschieben ohne Dialog, direkt im Editor, nie in einen ungültigen Zustand.

**Non-Goals:**
- Ziehen mit dem Finger, Verschieben über Nachbarzonen hinweg.
- Änderungen am Zonen-Editor oder an der Speicherung.

## Decisions

**D1: `PlaceZoneScreen` als eigene Route.** Neu `lib/features/courses/place_zone_screen.dart`, geöffnet mit `Navigator.push<ZonePlacement>`. Er bekommt Achse, Länge, die eingebauten `placements` und einen Start und liefert die neue `ZonePlacement` oder `null`. Aufbau von oben:
1. Start als `OarStepper` (Key `place-start`, Schritt wie bisher 50 m bzw. 10 s), `min 0`, `max` = Streckenlänge minus ein Schritt. Ein Maximum, das von der Zonenlänge abhängt, gibt es nicht mehr, weil noch keine Zone gewählt ist.
2. `CourseStrip` der aktuellen Strecke mit einer Marke am Start, damit man sieht, wo man einbaut.
3. Die Zonen der Achse in drei Gruppen mit Überschrift „Leicht“, „Mittel“, „Hart“ (nach `zoneIntensity(zone.segment)`), innerhalb der Gruppe nach Name. Leere Gruppen entfallen. Jede Zeile zeigt Farbmarke, Name und `zoneSummary`, Key `zone-option-<id>`.
4. „Zone anlegen“.

Eine Zone passt, wenn `resolveCourse` mit `[...placements, ZonePlacement(zone, start)]` für die neue Platzierung keinen Fehler meldet. Passt sie nicht, ist die Zeile deaktiviert und zeigt `placementErrorText` als Grund.

Alternative: Start unten lassen und nur den Dialog in einen Screen umziehen. Verworfen, weil der Nutzer ausdrücklich den Start zuerst will und das die Prüfung umdreht.

**D2: Ein Tipp baut ein.** Ein Tipp auf eine passende Zone poppt den Screen mit der Platzierung. „Zone anlegen“ ruft `openZoneEditor(context, axis: axis)` auf. Kommt eine id zurück und passt die Zone am Start, poppt der Screen sofort mit ihr; sonst bleibt er offen, und die neue Zone steht ausgegraut mit Grund in ihrer Gruppe.

**D3: Verschieben im Editor über einen Zustand `_moving`.** `_moving` ist der Index in `_placements` der markierten Zone oder `null`.
- Markieren: `CourseStrip` bekommt `onSegmentLongPress`. Langdruck und Tipp auf eine Zone im Balken und ein Tipp auf eine Zonenzeile der Liste setzen `_moving`.
- Erneuter Tipp auf dieselbe Zone oder „Fertig“ (`actionDone`) setzt `_moving = null`. Ein Tipp auf einen freien Abschnitt beendet das Verschieben und öffnet D1.
- Bedienfeld unter dem Balken (Key `move-panel`): Name der Zone, `OarStepper` (Key `move-start`) und „Fertig“. `onChanged` ersetzt `_placements[_moving]` sofort.
- Grenzen: `min` = Ende der vorherigen Zone oder 0, `max` = Start der nächsten Zone bzw. Streckenlänge minus Zonenlänge. Weil `OarStepper` eine Taste sperrt, sobald ein voller Schritt die Grenze überschreiten würde, bleibt ein Rest unter einem Schritt frei. Das ist hingenommen: Die Zone liegt nie ungültig, und lückenlos setzt man sie über D1.
- `_selected` (Umrandung) folgt `_moving`. Der Index bleibt gültig, weil sich beim Verschieben zwischen den Nachbarn die Reihenfolge nicht ändert.

Alternative: Markieren nur per Langdruck. Verworfen, weil Langdruck schwer zu entdecken ist und der Tipp auf eine Zone sonst keine Aufgabe mehr hätte.

**D4: Farbe in der Fehleransicht.** Die `_SectionTile` der Fehleransicht nimmt `CourseStrip.segmentColors([zone.segment]).single` statt `AppColors.zoneIn`.

**D5: Texte.** Neu:
- `placeZoneGroupEasy`, `placeZoneGroupMedium` und `placeZoneGroupHard` („Leicht“, „Mittel“, „Hart“).
- `courseMovingZone(zone)` mit „{zone} verschieben“.

Es fallen weg:
- `coursePlace`, `courseMove`, `courseMoveZone` und `coursePlacedAt`.
- `courseOtherAxis`, wenn es sonst nicht gebraucht wird.

`coursePlaceZone` bleibt als Titel des Screens und als Knopf.

## Risks / Trade-offs

- Restlücke unter einem Schritt beim Verschieben an eine Nachbarzone → siehe D3; über „Zone einbauen“ lässt sich eine Zone genau an den Nachbarn setzen.
- Langdruck auf einem 28 px hohen Balken ist bei kurzen Zonen ungenau → der Tipp in der Abschnittsliste markiert ebenso.
- Viele Tests bauen über den Dialog ein (Keys `place-start`, `zone-option-*`, Text „Einbauen“) → die Keys bleiben, die Tests verlieren den Tipp auf „Einbauen“.
