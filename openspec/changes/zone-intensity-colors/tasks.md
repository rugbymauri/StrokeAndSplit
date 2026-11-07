# Tasks

Keine neuen Texte, keine Schema-Änderung.

## 1. Härte berechnen

- [x] 1.1 `lib/data/courses/zone_intensity.dart` nach D1: `ZoneIntensity { easy, medium, hard }`, `zoneIntensity(CourseSegment)` mit den Grenzen als Konstanten, `null` für freie Abschnitte, Maximum über die gesetzten Vorgaben. Verifikation: `test/data/courses/zone_intensity_test.dart` deckt die Szenarien aus dem Spec ab:
  - Pace 3:05–3:15 leicht, 2:28–2:32 mittel (Mitte genau 2:30), 2:55–3:05 leicht (Mitte genau 3:00), 2:20–2:30 hart.
  - Schlagzahl 20–22 leicht (Mitte 21), 21–22 mittel (Mitte 21,5), 22–26 hart (Mitte 24).
  - Stufe 5 leicht, 6 mittel, 10 mittel, 11 hart, 20 hart.
  - Pace 2:50–3:00, Schlagzahl 18–20 und Stufe 11 zusammen: hart.
  - Ein freier Abschnitt ergibt `null`.

## 2. Farben zeigen

- [x] 2.1 `AppColors.intensityEasy`, `intensityMedium`, `intensityHard` nach D2; `CourseStrip.segmentColors` über `zoneIntensity` nach D3, die relative Pace-Abstufung entfällt. Verifikation:
  - `course_strip_test.dart`: Die beiden Abstufungstests sind durch einen Test ersetzt, der leicht, mittel, hart und frei auf die vier Farben abbildet; der Test mit einer Zone nur mit Stufe erwartet `intensityHard` statt `zoneIn`.
  - Ein Test zeigt, dass dieselbe Zone neben verschiedenen Nachbarn dieselbe Farbe hat.
  - Die Live-Tests (`progress_frame_test.dart`, `pace_box_test.dart`) bleiben unverändert grün.
- [ ] 2.2 Farben in der App prüfen: unter Linux (Scratch-DB) Zonenliste, Streckenliste und Strecken-Editor mit je einer leichten, mittleren und harten Zone ansehen. Verifikation:
  - Die drei Farben sind auf dem dunklen Hintergrund klar unterscheidbar.
  - Sie sehen nicht aus wie „ausserhalb der Zone“ oder „verbunden“.
  - Die Zonennamen im Editor-Balken sind auf allen drei Farben lesbar.
  - Werte in `AppColors` bei Bedarf angepasst und in D2 nachgetragen.

## 3. Doku und Abschluss

- [ ] 3.1 README, Abschnitt Zonen: die Farben und ihre Grenzen nennen. Verifikation: Der Abschnitt widerspricht dem Spec nicht.
- [ ] 3.2 Gesamtprüfung: `make check` grün.
- [ ] 3.3 Am Handy (Nutzer): Strecken- und Zonenliste ansehen, die Farben sind gut unterscheidbar.
