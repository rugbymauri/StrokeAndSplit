# Design

## Context

- `zoneErrors` in `lib/data/zones/zone.dart` verlangt ein Pace- oder Schlagzahl-Band (`ZoneError.bandMissing`). Die Stufe wird nur auf `< 1` geprüft.
- `CourseSegment.isFree` in `lib/data/courses/course.dart` ist `!hasPaceBand && !hasSpmBand`. Die Stufe zählt ausdrücklich nicht mit (Kommentar aus `resistance-control`). Wer `isFree` aufruft, will eins von zwei Dingen wissen:
  - **Ist das ein Zonenabschnitt?** Name, Farbe und Markierung:
    - `course_strip.dart` (Name, Farbe `zoneIn`)
    - `templates_screen.dart` (`templateZoneLines`)
    - `courses_screen.dart` (Zahl der Zonen)
    - `progress_frame_model.dart` (Zonen im Rahmen)
    - `pace_box.dart` (Name statt „frei“)
    - `zone_repository.dart` (`placeZones`: nur Zonenabschnitte bekommen eine gespeicherte Zone)
  - **Gibt es etwas zu messen?** `lap_tracker.dart` (`_count`, Anteil in der Zone) und `upcoming_zone.dart` (Hinweis „Gleich …“ auf ein Band).
- Welche Stufe gesetzt wird, entscheidet `resistance_director.dart` allein über `segment.resistanceLevel`, unabhängig von `isFree`. Eine Zone nur mit Stufe setzt ihre Stufe also schon heute, sobald es sie gibt.
- Die Zonenstatus für Pace und Schlagzahl (`_paceStatus`, `_spmStatus`) prüfen je ihr eigenes Band. Ohne Band sind sie neutral.
- Ranglisten und Zonen-Ghost gehen über `course_segments.zone_id` und die Zeit, nicht über die Bänder.

## Goals / Non-Goals

**Goals:**
- Eine Zone nur mit Stufe verhält sich in Listen, Streckenbalken und Live-Anzeige wie jede Zone, nur ohne Messung.

**Non-Goals:**
- Kein neuer Live-Hinweis für die Stufe, keine Änderung an `resistance_director`.
- Keine Schema-Änderung, keine Migration.

## Decisions

### D1: `isFree` zählt die Stufe, neu `hasBand`

`isFree` wird `!hasBand && resistanceLevel == null`, und neu kommt `hasBand => hasPaceBand || hasSpmBand` dazu. Wer messen will, fragt `hasBand`, also `lap_tracker._count` und `upcomingZone`. Alle anderen Aufrufer behalten `isFree` und bekommen die neue Bedeutung, ohne dass sich ihr Code ändert.

*Alternative*: `isFree` lassen und ein neues `isZone` einführen. Verworfen, weil dann die sechs Aufrufer aus der Gruppe „Zonenabschnitt“ umziehen müssten. Nur zwei Aufrufer messen tatsächlich.

### D2: Fehler `targetMissing` statt `bandMissing`

`ZoneError.bandMissing` heisst künftig `targetMissing`. Den Fehler gibt es nur noch, wenn weder Pace, Schlagzahl noch Stufe gesetzt sind. Der Text-Key `zoneErrorBandMissing` wird ebenso zu `zoneErrorTargetMissing`: „Gib Pace, Schlagzahl oder Stufe an.“ / „Set a pace, a stroke rate or a level.“ Angepasst werden auch der Hinweis `zoneBandHint` im Editor und der Text der leeren Liste `zonesEmpty`. Ihre Keys bleiben, nur der Wortlaut nennt die Stufe mit.

Ist nur eine Grenze eines Bands gesetzt, bleibt das `paceBoundMissing` bzw. `spmBoundMissing`, auch wenn eine Stufe gesetzt ist.

### D3: Hinweis „Gleich …“ nur bei Band

`upcomingZone` gibt für einen nächsten Abschnitt ohne Band `null` zurück (`!next.hasBand` statt `next.isFree`). Die Pills zeigen ohnehin nur ein Pace- oder Schlagzahl-Band. So bleibt das Verhalten für Zonen nur mit Stufe sichtbar gleich, und kein Aufrufer bekommt ein Segment, mit dem er nichts anzeigen kann. `_sameBands` bleibt ohne Stufe.

### D4: Darstellung einer Zone nur mit Stufe

Weil `isFree` falsch ist, bekommt eine solche Zone:
- im Streckenbalken die Farbe `zoneIn` und ihren Namen,
- in `templateZoneLines` die Zeile „Kraft Stufe 12“,
- in der Pace-Box ihren Namen,
- im Fortschrittsrahmen ihre Zonenmarke.

Pace und Schlagzahl bleiben ohne Zonenfarbe, und der Anteil in der Zone erscheint nicht, weil `lapInZoneShare` ohne gezählte Bandzeit `null` ist. Den Text liefert `formatSegmentBands`, das die Stufe schon ausgibt. Dafür ist nichts Neues nötig.

## Risks / Trade-offs

- [Eine Zone nur mit Stufe ist auf dem PM5 wirkungslos] → So gewollt (proposal, nicht Teil). Sie bleibt ein benannter Abschnitt, und ihre Runden zählen in der Rangliste der Zone.
- [`placeZones` legt beim Import Zonen nur mit Stufe an] → Das ist richtig. Bisher wäre ein solcher Abschnitt still frei geworden und hätte seine Stufe ohne Zone behalten. `findOrCreate` vergleicht über `sameAs`, das die Stufe schon einschliesst.
- [Change `resistance-control` ist nicht archiviert, das Delta ändert seine Requirement „Widerstandsstufe einer Zone“] → `resistance-control` vor diesem Change archivieren, sonst schlägt das Archivieren fehl.
