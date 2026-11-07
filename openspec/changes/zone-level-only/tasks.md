# Tasks

Setzt `resistance-control` in `main` voraus (Stufe in Zone und Segment). Neue oder geänderte Texte nur über `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb` mit `@`-Beschreibung, danach `make l10n`; der generierte Code wird committet.

## 1. Zone nur mit Stufe speichern

- [x] 1.1 `zoneErrors` nach D2: `ZoneError.bandMissing` → `targetMissing`, nur wenn weder Pace, Schlagzahl noch Stufe gesetzt sind; Key `zoneErrorBandMissing` → `zoneErrorTargetMissing`, neuer Wortlaut in `zoneBandHint` und `zonesEmpty` (de/en). Verifikation:
  - In `zone_repository_test.dart` wird „a zone with only a resistance level“ fehlerfrei gespeichert; „a zone without any band“ ohne Stufe ergibt `targetMissing`; eine halbe Pace-Grenze mit Stufe ergibt weiter `paceBoundMissing`.
  - Ein Widget-Test des Zonen-Editors speichert „Kraft“ mit 500 m und Stufe 12, und die Zonenliste zeigt „500 m · Stufe 12“.
  - Die deutschen und englischen Texte sind geprüft.

## 2. Zone nur mit Stufe beim Rudern

- [ ] 2.1 `CourseSegment.isFree` zählt die Stufe, neu `hasBand` (D1); `lap_tracker._count` und `upcomingZone` fragen `hasBand` (D3); Kommentar an `resistanceLevel` angepasst. Verifikation:
  - `LapTracker`-Test: Ein Segment nur mit Stufe ergibt weder für das Segment noch für die Runde einen Anteil in der Zone.
  - `upcomingZone`-Test: Vor einem Segment nur mit Stufe kommt kein Hinweis.
  - `ProgressFrameModel`-Test: Das Segment nur mit Stufe ist eine Zone im Rahmen.
  - `CourseStrip`-Widget-Test: Name und Farbe `zoneIn`.
  - `templateZoneLines` ergibt „Kraft Stufe 12“.
  - Live-Widget-Test: Die Pace-Box zeigt „Kraft“ statt „frei“, ohne Zonenfarbe bei Pace und Schlagzahl.
  - `placeZones`-Test: Ein importierter Abschnitt nur mit Stufe bekommt eine Zone.
  - Alle bestehenden Tests sind grün.

## 3. Doku und Abschluss

- [ ] 3.1 README: Abschnitte Zonen und Widerstand. „Eine Stufe allein ersetzt kein Band“ wird zu „mindestens eins von Pace, Schlagzahl oder Stufe“, und es kommt dazu, was eine Zone nur mit Stufe beim Rudern zeigt und was nicht. Verifikation: Beide Abschnitte widersprechen den Specs nicht mehr.
- [ ] 3.2 Gesamtprüfung: `make check` grün. In der App unter Linux mit Simulator (FTMS) die Zone „Kraft“ nur mit Stufe 12 anlegen, in eine Strecke setzen und rudern. Verifikation:
  - Der Streckenbalken zeigt „Kraft“, die Pace-Box „Kraft“.
  - Der Simulator meldet Stufe 12 in der Zone.
  - Es gibt keinen Anteil in der Zone.
- [ ] 3.3 Test am Gerät (Nutzer, Woodrower): eine Strecke mit einer Zone nur mit Stufe rudern und prüfen, ob die Stufe mit der Zone wechselt.

## Workflow follow-up

- Erst nach `resistance-control` archivieren, weil das Delta `zones` dessen Requirement „Widerstandsstufe einer Zone“ ändert.
