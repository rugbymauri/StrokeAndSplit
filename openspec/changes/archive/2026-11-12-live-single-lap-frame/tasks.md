# Tasks

## 1. Fortschrittsrahmen

- [x] 1.1 Bei genau einer geplanten Runde ohne Dauer keine Gesamtspur im Modell des Fortschrittsrahmens, wie bei offener Rundenzahl; ein Ghost läuft nur auf Runde und Abschnitt. Verifikation: Unit-Test des Modells (eine Runde ohne Gesamtspur, drei Runden und Dauer unverändert).
- [x] 1.2 Legende der Pace-Box bei einer Runde ohne Zeile „Gesamt“, Rundenzeile mit eigener Übersetzung „Runde“ / „Lap“ (nicht `metricLapTime`) und Restdistanz bzw. Restzeit. Verifikation: Widget-Test in `pace_box_test.dart` (Deutsch und Englisch) und Szenario „Eine Runde“ im Live-Display-Test.

## 2. Dokumentation und Test

- [x] 2.1 README-Abschnitt zum Fortschrittsrahmen nachführen (bei einer Runde fehlt die äussere Spur, Legende „Runde“).
- [x] 2.2 Linux-Test mit dem Simulator: Workout mit einer Runde starten, Rahmen mit zwei Spuren und Legende ohne „Gesamt“; Workout mit drei Runden weiterhin mit drei Spuren.
- [ ] 2.3 Am Gerät (Nutzer): Workout mit einer Runde rudern, keine äussere Spur, Legende „Runde · noch …“.
