# Design

## Context

- `PaceBox` (`lib/features/live/pace_box.dart`) zeigt unter der Pace einen Platz der Höhe `statusHeight` (32). Dort steht der Hinweis als `ZonePill` mit Band, z. B. „Schneller · 2:05–2:10“, oder die blinkende `UpcomingPill` „Gleich 2:05–2:10“. Ohne Pace-Band bleibt der Platz leer. Die Höhe ausserhalb der Pace rechnet `_aroundPace` (190) grosszügig ein, damit `paceFontSizeFor` stimmt.
- `ProgressFramePainter` (`progress_frame.dart`) malt drei Spuren. Zonen auf Strecken- und Rundenspur kommen aus `FrameTrack.zones` als Anteile `(start, end)` und sind `AppColors.trackZone` (leer) bzw. `AppColors.text` (gefüllt). Die Abschnittsspur hat keine Zonen; ihr gefüllter Teil ist `segmentColor(pace)`: blau, orange oder neutral.
- `zoneIntensity(CourseSegment)` (`lib/data/courses/zone_intensity.dart`) liefert leicht, mittel, hart oder `null`. `CourseStrip` bildet sie auf `AppColors.intensityEasy/Medium/Hard` ab, frei ist `AppColors.line`.
- `UpcomingPill` (`upcoming_zone.dart`) ist gelb (`AppColors.upcoming`) mit dunkler Schrift und wird in der Pace-Box und auf der Schlagzahlkarte genutzt.
- Die Legendenzeile des Abschnitts hat einen Punkt in `segmentColor(pace)`.
- Im Querformat (`LiveCourse._landscape`) steht rechts neben der Pace-Box eine Spalte mit der Schlagzahlkarte (`Expanded`), darunter die Kacheln der Session (64 hoch) und der Status; ganz rechts eine schmale Spalte (128) mit Rundenzeit, Watt und Puls. Die Stufe steht als Fussnote in `WattsTile`, bei setzbarer Stufe mit kleinen Ruderblatt-Tasten (`TileStepper`). `resistanceProvider` liefert `level`, `canSet`, `canLower`, `canRaise` und `step(±1)`.

## Goals / Non-Goals

**Goals:**
- Die Vorgaben der aktuellen Zone sind immer lesbar, auch in der Zone und ohne Pace-Band.
- Eine Zone hat in der Live-Anzeige dieselbe Farbe wie im Streckenbalken.
- Zustand (in/ausserhalb) und Härte bleiben getrennt erkennbar.

- Die Stufe im Querformat ist so gross und bedienbar wie die Schlagzahl.

**Non-Goals:**
- Frei rudern, Schlagzahlkarte (ausser der kommenden Zone), Kraftkurve, Stufe im Hochformat.
- Neue Farben oder Grenzen der Härte.

## Decisions

**D1: Eine Abbildung Härte → Farbe für Strecke und Live.** `intensityColor(ZoneIntensity?)` in `lib/app/design_tokens.dart` (neben den Farben): `null` → `AppColors.line`, sonst die drei Härte-Farben. `CourseStrip.segmentColors` nutzt sie statt der eigenen Abbildung. Dazu `intensityDim(Color)` für den gedämpften Ton: dieselbe Farbe mit etwa 45 % Deckkraft über dem Spurgrund. Der genaue Wert wird beim Linux-Test so gewählt, dass gedämpft und kräftig klar verschieden sind und gedämpftes Orange nicht wie „ausserhalb“ aussieht.

**D2: Zonen einer Spur tragen ihre Härte.** `FrameTrack.zones` wird zu einer Liste von `(start, end, intensity)`. `ProgressFrameModel.of` setzt die Härte aus dem Segment der Strecke. Für die Strecken- und Rundenspur malt der Painter jede Zone gedämpft und bis zum Anteil `share` kräftig in ihrer Farbe, statt `trackZone`/`text`. Freie Teile bleiben wie bisher (`track` leer, `text` bzw. `textMuted` gefüllt).

**D3: Abschnittsspur.** Die Abschnittsspur bekommt die Härte des aktuellen Segments (`null` bei frei). Leer: gedämpfte Härte-Farbe, bei frei `trackInner`. Gefüllt: bei Zone mit Pace-Band `segmentColor(pace)` wie bisher, bei Zone ohne Pace-Band die kräftige Härte-Farbe, bei frei neutral. So bleibt die Requirement „Abschnittsspur zeigt den Zonenstatus“ erfüllt, und eine Zone nur mit Stufe ist nicht mehr grau.

**D4: Zielwertzeile.** Eine reine Funktion `zoneTargets(AppLocalizations, CourseSegment)` (in `lib/features/live/zone_hint.dart`) baut den Text: Name bzw. „Zone“ ohne Namen, dann `2:05–2:10`, `20–22 spm`, `Stufe 8`, verbunden mit „ · “; frei → „frei“. Die Teile kommen aus vorhandenen Formatierern (`formatPaceBound`) und einem neuen Text `zoneTargetLevel` („Stufe {level}“ / „level {level}“). Die Zeile steht in der Pace-Box direkt unter dem Platz des Hinweises, mit Key `pace-box-targets`, einzeilig, bei Platzmangel verkleinert (`FittedBox`), nie abgeschnitten. Die Höhe der Zeile kommt zu `_aroundPace` hinzu, damit die Pace nicht springt.

Alternative: das Band in der Hinweis-Pille lassen und die Zeile nur ohne Hinweis zeigen. Verworfen, weil das Band dann zweimal stünde bzw. springen würde.

**D5: Hinweis ohne Band.** `ZonePill` in der Pace-Box bekommt kein `band` mehr; der Text ist nur „In der Zone“, „Schneller“, „Langsamer“ oder „Keine Pace“. Die kommende Zone bleibt im Platz des Hinweises mit ihrem Band („Gleich 2:05–2:10“), weil sie eine andere Zone ankündigt als die Zeile darunter.

**D6: Kommende Zone und Legendenpunkt in Härte-Farbe.** `UpcomingPill` bekommt die Farbe als Parameter; die Aufrufer übergeben `intensityColor(zoneIntensity(upcoming))`. Schrift und Symbol wählen hell oder dunkel nach der Helligkeit des Hintergrunds, wie `_textOn` im Streckenbalken (die Funktion wird dafür geteilt). `AppColors.upcoming` entfällt, wenn sie sonst nirgends gebraucht wird. Der Punkt der Abschnittszeile nimmt `intensityColor(zoneIntensity(segment))` statt `segmentColor(pace)`.

**D7: Karte „Stufe“ im Querformat.** Neues Widget `ResistanceCard` (`lib/features/live/resistance_card.dart`), ein `ConsumerWidget` auf `resistanceProvider` und dem Tick wie `WattsTile`. Aufbau wie die Schlagzahlkarte: Fläche `surface`, Label „STUFE“, die Stufe als grosser Wert, links und rechts Ruderblatt-Tasten in der Grösse `OarStepperSize.large` (56 × 60), die `controller.step(-1)` bzw. `step(1)` aufrufen und bei `!canLower`/`!canRaise` gesperrt sind. Die Tasten nutzen dieselben Bausteine wie `OarStepper`, damit sie gleich aussehen; `OarStepper` selbst passt nicht, weil die Stufe vom Gerät zurückkommt und nicht lokal gesetzt wird. Die Werte zeigen „Stufe abgelehnt“ wie die Fussnote, wenn das Gerät ablehnt.

In `LiveCourse._landscape` steht die Karte zwischen Schlagzahlkarte und Session-Kacheln mit fester Höhe 72 und `AppSpacing`-Abstand, nur wenn eine Stufe bekannt ist (`resistance.level ?? tick?.resistanceLevel`). `WattsTile` bekommt `showResistance: false` im Querformat und zeigt dann weder Fussnote noch Tasten. Die Kraftkurve in der Schlagzahlkarte erscheint weiter ab 260 px Höhe der Spalte; reicht der Platz mit der Karte nicht, entfällt die Kurve vor der Stufe.

## Risks / Trade-offs

- Auf einem flachen Handy-Querformat (um 360 px Höhe) wird die Schlagzahlkarte um 78 px kleiner → die Schlagzahl schrumpft mit; der Layout-Test für 740 × 360 prüft, dass nichts abgeschnitten wird und die Kraftkurve notfalls entfällt.

- Mittel (gedämpftes Orange) und „ausserhalb“ (helles Orange) liegen nah beieinander → der Zustand ist zusätzlich Wort und Symbol; die Spur zeigt „ausserhalb“ nur im gerudeten Teil der aktuellen Zone, die Härte nur im ungeruderten; Prüfung im Linux-Test (Task) und am Handy.
- Die Zielwertzeile nimmt Höhe weg, die Pace wird auf kleinen Schirmen etwas kleiner → `paceFontSizeFor` rechnet sie ein; der Layout-Test für 400 × 400 prüft das.
- Die Zeile wiederholt den Zonennamen aus der Legende → bewusst, vom Nutzer so gewählt; die Legende zeigt dort auch die Restdistanz.
- Goldens der Live-Anzeige ändern sich → werden neu erzeugt und angesehen.
