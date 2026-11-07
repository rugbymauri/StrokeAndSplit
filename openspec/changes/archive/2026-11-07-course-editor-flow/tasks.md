# Tasks

Neue oder geänderte Texte nur über `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb` mit `@`-Beschreibung, danach `make l10n`; der generierte Code wird committet.

## 1. Screen „Zone einbauen“

- [x] 1.1 `PlaceZoneScreen` nach D1 und D2 mit den Texten aus D5; `_place` im Editor öffnet ihn statt `_PlaceZoneDialog`. Verifikation in `courses_screen_test.dart`:
  - Der Start steht über den Zonen.
  - Die Zonen stehen unter „Leicht“, „Mittel“ und „Hart“.
  - Eine Zeit-Zone fehlt in einer Distanzstrecke.
  - Bei Start 1300 m ist eine 500-m-Zone neben einer Zone 1000–1500 m ausgegraut und nennt die Überschneidung.
  - Bei Start 1800 m ist eine 500-m-Zone in 2000 m ausgegraut und nennt das Streckenende.
  - Ein Tipp auf „Sprint“ bei 500 m baut ihn ein und zeigt den Editor mit 500–600 m.
  - Ein Tipp auf den freien Abschnitt 600–1000 m öffnet den Screen mit Start 600 m.
  - „Zone anlegen“ mit einer passenden neuen Zone baut sie ein.
  - Die bestehenden Einbau-Tests in `courses_screen_test.dart` und `templates_screen_test.dart` sind umgestellt und grün.

## 2. Verschieben im Editor

- [x] 2.1 `CourseStrip.onSegmentLongPress`; `_moving`, Bedienfeld und Grenzen nach D3; `_PlaceZoneDialog` und `_ZoneOption` entfernen, nicht mehr gebrauchte Texte nach D5 entfernen. Verifikation in `courses_screen_test.dart`:
  - Langdruck auf eine Zone im Balken zeigt das Bedienfeld mit Name und Start.
  - Ein Tipp in der Liste markiert eine Zone ebenso.
  - „mehr“ verschiebt „Sprint“ von 500 auf 550 m in Balken und Liste.
  - An der Nachbarzone ist „mehr“ gesperrt.
  - „Fertig“ und ein erneuter Tipp beenden das Verschieben.
  - Ein Tipp auf eine andere Zone markiert diese.
  - Nach „Speichern“ hat die Strecke die neue Lage.
  - `course_strip_test.dart`: Langdruck meldet den Index.
- [x] 2.2 Fehleransicht nach D4. Verifikation: Ein Widget-Test kürzt eine Strecke unter ihre Zonen und findet die Härte-Farbe statt `AppColors.zoneIn`.

## 3. Doku und Abschluss

- [x] 3.1 README, Abschnitt „Zonen, Strecken und Vorlagen“ Schritt 2: Einbauen über den Screen mit Start zuerst und Gruppen, Verschieben per Langdruck oder Tipp mit den Ruderblatt-Tasten. Verifikation: Der Abschnitt widerspricht den Specs nicht.
- [x] 3.2 Gesamtprüfung: `make check` grün. In der Linux-App (Scratch-DB) eine Strecke mit drei Zonen zusammenstellen, eine verschieben und speichern. Verifikation: Screen, Gruppen, ausgegraute Zonen mit Grund, Bedienfeld und Anschlag verhalten sich wie im Spec.
- [x] 3.3 Am Handy (Nutzer): eine Strecke zusammenstellen und eine Zone per Langdruck verschieben.
