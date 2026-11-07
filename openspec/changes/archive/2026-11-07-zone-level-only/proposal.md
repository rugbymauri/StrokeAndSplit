# Proposal

## Why

Eine Zone braucht heute ein Pace- oder Schlagzahl-Band. Die Widerstandsstufe aus `resistance-control` kommt nur zusätzlich dazu. Wer am Woodrower einen Abschnitt nur auf einer bestimmten Stufe rudern will, etwa „Kraft, 500 m auf Stufe 12“, muss deshalb ein Band erfinden, das er gar nicht einhalten will. Eine Zone soll sich darum auch nur mit einer Stufe anlegen lassen. Nötig ist dann mindestens eins von Pace, Schlagzahl oder Stufe.

## What Changes

- **Zonen-Editor**: Eine Zone braucht mindestens eins von Pace-Band, Schlagzahl-Band oder Stufe. Eine Zone nur mit Stufe lässt sich speichern. Fehlermeldung, Hinweis im Editor und der Text der leeren Zonenliste nennen die Stufe mit.
- **Zone nur mit Stufe beim Rudern**:
  - Sie gilt als Zone und nicht als freier Abschnitt.
  - Ihr Name steht im Streckenbalken, in den Zonenzeilen der Vorlage, in der Pace-Box und im Fortschrittsrahmen.
  - Mit ihr setzt die App die Stufe wie bei jeder Zone mit Stufe.
- **Was ohne Band entfällt**: Eine Zonenmarkierung (in/ausserhalb, Richtung), einen Anteil in der Zone und einen Hinweis „Gleich …“ gibt es dafür nicht, weil es nichts zu messen gibt.
- **Ranglisten bleiben**: Die Rangliste der Zone und der Zonen-Ghost zählen wie bei jeder Zone, weil sie nach der Zeit über die Zone gehen.
- **Zonenliste unverändert**: Sie zeigt schon Name, Länge, Bänder und Stufe. Eine Zone nur mit Stufe erscheint als „Kraft, 500 m · Stufe 12“.

Nicht Teil dieses Changes:

- Ein Hinweis „Gleich Stufe 12“ vor einer Zone. Die App setzt die Stufe selbst.
- Eine Wirkung auf dem PM5. Dort lässt sich keine Stufe setzen, und eine Zone nur mit Stufe ist dort nur ein benannter Abschnitt.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `zones`:
  - Eine Zone braucht mindestens eins von Pace-Band, Schlagzahl-Band oder Stufe („Zone anlegen“).
  - Eine Stufe allein reicht („Widerstandsstufe einer Zone“). Diese Requirement kommt mit dem Archivieren von Change `resistance-control` in die Main-Spec.
- `course-rowing`:
  - Ein Abschnitt aus einer Zone nur mit Stufe zeigt live den Namen der Zone statt „frei“.
  - Er hat keinen Anteil in der Zone.

## Impact

- **Code**:
  - `lib/data/zones/zone.dart`: Validierung.
  - `lib/data/courses/course.dart`: `isFree` zählt die Stufe mit; neu `hasBand` für alles, was ein Band zum Messen braucht.
  - Aufrufer von `isFree` in `lib/data/courses/lap_tracker.dart`, `lib/data/zones/zone_repository.dart`, `lib/features/live/`, `lib/features/courses/` und `lib/features/templates/`.
- **Texte**: `zoneErrorBandMissing`, `zoneBandHint`, `zonesEmpty` in `lib/l10n/app_de.arb` und `app_en.arb`.
- **Doku**: README, Abschnitte Zonen und Widerstand.
- **Daten**: keine Schema-Änderung, `resistance_level` gibt es schon bei Zonen und Segmenten.
- **Abhängigkeit**: `resistance-control` muss vor diesem Change archiviert werden, weil das Spec-Delta dessen Requirement ändert.
