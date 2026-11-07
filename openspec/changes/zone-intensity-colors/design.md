# Design

## Context

`CourseStrip.segmentColors` in `lib/features/courses/course_strip.dart` liefert die Farbe jedes Abschnitts: grau für frei, blau für Zonen, Pace-Bänder relativ zueinander zwischen `fastestPace` und `slowestPace` abgestuft. Die Zonenliste (`zones_screen.dart`) und der Strecken-Editor (`course_editor_screen.dart`) holen ihre Farbmarken ebenfalls dort. Die Zonenliste ruft die Funktion mit allen Zonen einer Achse auf, darum hing die Farbe auch dort von den anderen Zonen ab.

`CourseSegment` trägt `paceFastCs`/`paceSlowCs` (Hundertstelsekunden pro 500 m), `spmMin`/`spmMax` und `resistanceLevel`. `Zone.segment` liefert dasselbe für eine Zone.

Die Live-Anzeige färbt den Fortschrittsrahmen über `ProgressFramePainter.segmentColor` nach dem Zonenstatus. Das ist ein anderer Weg und bleibt unverändert.

## Goals / Non-Goals

**Goals:**
- Die Härte eines Abschnitts als reine, ohne Widget testbare Funktion.
- Die Farbe hängt nur von der Zone ab, nicht von den anderen Abschnitten.

**Non-Goals:**
- Einstellbare Grenzen, Grenzen pro Gerät.
- Änderungen an der Live-Anzeige.

## Decisions

**D1: Härte als Enum in `lib/data/courses/zone_intensity.dart`.** `enum ZoneIntensity { easy, medium, hard }` und eine Funktion `ZoneIntensity? zoneIntensity(CourseSegment s)`. Sie gibt `null` für einen freien Abschnitt (`s.isFree`) und sonst das Maximum der Härten der gesetzten Vorgaben. Die Grenzen stehen als Konstanten daneben:
- Pace: Mitte `(paceFastCs + paceSlowCs) / 2`; ab 18000 (3:00) leicht, ab 15000 (2:30) mittel, sonst hart.
- Schlagzahl: Mitte `(spmMin + spmMax) / 2`; bis 21 leicht, unter 24 mittel, sonst hart. Eine Mitte von 21,5 ist mittel.
- Stufe: bis 5 leicht, bis 10 mittel, sonst hart.

Die Funktion liegt im Datenteil, weil sie nichts mit Farben zu tun hat und später auch anderswo brauchbar ist, etwa für eine Beschriftung.

Alternative: die Härte in `CourseSegment` als Getter. Verworfen, weil die Grenzen eine Darstellungsentscheidung sind und das Datenmodell nicht wachsen soll.

**D2: Drei neue Farben in `AppColors`.** `intensityEasy`, `intensityMedium`, `intensityHard`, gedämpft auf dem dunklen Hintergrund, Startwerte:
- leicht `0xFF2F8F5B` (dunkler und grauer als `connected` `0xFF4CD07D`),
- mittel `0xFFB97A2E` (dunkler als `zoneOut` `0xFFFF9A3D`),
- hart `0xFFB8443F`.

Die Werte werden bei der Umsetzung an den Screens geprüft und bei Bedarf angepasst. Die Namen auf den Balken nutzen weiter `_textOn`, das je nach Helligkeit hell oder dunkel schreibt.

**D3: `segmentColors` bleibt die eine Stelle.** Sie bildet jeden Abschnitt über `zoneIntensity` auf `AppColors.line` (frei) oder eine der drei Farben ab. `slowestPace`, `fastestPace`, `minShadeStep`, `_paceShades` und `_paceSum` fallen weg. Die Aufrufer bleiben unverändert. Weil die Farbe nicht mehr von den Nachbarn abhängt, liesse sich die Signatur auf einen Abschnitt verkleinern; das bleibt aber eine Liste, damit die Aufrufer nicht angefasst werden müssen.

## Risks / Trade-offs

- Rot und Orange erinnern an Warnungen → gedämpfte Töne und die unveränderte Live-Anzeige halten die Bedeutungen getrennt.
- Feste Grenzen passen nicht zu jedem Ruderer oder Gerät → bewusst vorerst fest; einstellbar wäre ein eigener Change.
- Zwei Zonen gleicher Härte sind nicht mehr unterscheidbar, wo die blaue Abstufung sie trennte → die Namen stehen im Editor-Balken, und die Liste zeigt die Werte.
- Farbenblinde unterscheiden grün und rot schlecht → die Farbe ist nur ein Zusatz; Werte und Namen stehen überall daneben.
