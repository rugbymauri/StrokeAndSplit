# Tasks

Keine Schema-Änderung. Neue Texte nur über `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb` mit `@`-Beschreibung, danach `make l10n`; der generierte Code wird committet.

## 1. Farben teilen

- [x] 1.1 `intensityColor(ZoneIntensity?)`, `intensityDim(Color)` und die Wahl von heller oder dunkler Schrift (`textOn`) nach D1/D6 an einer Stelle in `lib/app/design_tokens.dart`; `CourseStrip` nutzt sie. Verifikation: `course_strip_test.dart` bleibt grün; ein neuer Test bildet `null`, leicht, mittel und hart auf `line` und die drei Farben ab und prüft, dass `intensityDim` dieselbe Farbe mit geringerer Deckkraft ist.

## 2. Fortschrittsrahmen

- [ ] 2.1 `FrameTrack.zones` mit Härte nach D2; `ProgressFrameModel.of` setzt sie, die Abschnittsspur bekommt die Härte des aktuellen Segments nach D3. Verifikation: `progress_frame_model_test.dart` prüft für eine Strecke mit leichter Zone 0–500 m und harter Zone 500–1000 m die Härten auf Strecken- und Rundenspur und auf der Abschnittsspur in beiden Zonen sowie `null` in einem freien Abschnitt.
- [ ] 2.2 Painter nach D2/D3: Zonen auf Strecken- und Rundenspur gedämpft und bis `share` kräftig in Härte-Farbe; Abschnittsspur leer gedämpft in Härte-Farbe, gefüllt im Zustand bzw. bei Zone ohne Pace-Band in Härte-Farbe. Verifikation:
  - `progress_frame_test.dart`: Goldens neu erzeugt (`--update-goldens`) und angesehen; ein neuer Golden mit leichter, mittlerer und harter Zone und einer Zone nur mit Stufe.
  - Ein Test prüft `segmentColor` für eine Zone mit Pace-Band unverändert (blau/orange).

## 3. Pace-Box

- [ ] 3.1 `zoneTargets(l10n, segment)` nach D4 mit neuem Text `zoneTargetLevel` (de „Stufe {level}“, en „level {level}“). Verifikation: Test für die Szenarien „Alle Vorgaben“, „Zone nur mit Stufe“, „Freier Abschnitt“ und „Zone ohne Namen“ aus dem Spec, auf Deutsch und Englisch.
- [ ] 3.2 Pace-Box: Zielwertzeile `pace-box-targets` unter dem Hinweis, Hinweis ohne Band nach D5, Höhe in `_aroundPace` eingerechnet, Punkt der Abschnittszeile in Härte-Farbe nach D6. Verifikation in `pace_box_test.dart`:
  - In der Zone steht „In der Zone“ ohne Band und darunter „Tempo · 2:05–2:10 · 20–22 spm · Stufe 8“.
  - Bei Pace 2:13 steht „Schneller“ und dieselbe Zeile.
  - Im freien Abschnitt steht „frei“ und kein Hinweis.
  - Die Pace steht in allen drei Fällen an derselben Stelle.
  - 400 × 400 ohne Overflow, auch mit langem Zonennamen.
- [ ] 3.3 Kommende Zone nach D6 in Härte-Farbe in Pace-Box und Schlagzahlkarte. Verifikation: `upcoming_zone_test.dart` prüft die Farbe für eine harte kommende Zone und lesbare Schrift auf allen drei Farben; `live_screen_test.dart` bleibt grün.

## 4. Stufe im Querformat

- [ ] 4.1 `ResistanceCard` nach D7. Verifikation in `resistance_card_test.dart`: zeigt „6“ unter „STUFE“; Tipp rechts ruft `step(1)`, links `step(-1)`; bei Stufe 15 von 15 ist rechts gesperrt; ohne setzbare Stufe keine Tasten; bei Ablehnung der Text „abgelehnt“; die Tasten sind mindestens 56 × 60.
- [ ] 4.2 Einbau in `LiveCourse._landscape` und `WattsTile(showResistance:)` nach D7. Verifikation:
  - `live_screen_test.dart`: im Querformat mit FTMS-Simulator steht die Karte unter der Schlagzahlkarte und hat dieselbe Breite; die Watt-Kachel zeigt keine Stufe; ohne gemeldete Stufe (PM5-Simulator) gibt es keine Karte.
  - Im Hochformat steht die Stufe wie bisher unter den Watt.
  - `live_layout_test.dart`: 740 × 360 und 1200 × 700 im Querformat ohne Overflow, mit und ohne Kraftkurve.

## 5. Doku und Abschluss

- [ ] 5.1 README, Abschnitt Live-Anzeige: Zielwertzeile, Härte-Farben im Rahmen und Karte „Stufe“ im Querformat beschreiben. Verifikation: der Abschnitt widerspricht den Specs nicht.
- [ ] 5.2 Gesamtprüfung in der Linux-App (Scratch-DB, Simulator und Simulator (FTMS)): Strecke mit leichter, mittlerer und harter Zone und einer Zone nur mit Stufe rudern, im Querformat die Karte „Stufe“ mit den Tasten bedienen; Zielwertzeile, Hinweis, Farben im Rahmen, Legendenpunkt und kommende Zone ansehen, gedämpfte Töne bei Bedarf nachstellen und in D1 nachtragen. Verifikation: Screenshots; `make check` grün.
- [ ] 5.3 Am Handy (Nutzer): ein Workout mit Zonen rudern, Zielwerte und Farben gut lesbar; quer am Woodrower die Stufe mit den Tasten unter der Schlagzahl ändern.
