# Proposal

## Why

Im Streckenbalken sind heute alle Zonen blau. Nur Pace-Bänder sind abgestuft, und zwar relativ zueinander innerhalb einer Strecke: Dieselbe Zone kann so in zwei Strecken verschieden hell sein. Schlagzahl und Stufe zählen gar nicht. Wie hart ein Abschnitt ist, sieht man darum erst, wenn man die Werte liest. Die Zonen sollen deshalb nach ihrer Härte grün, orange oder rot sein, mit festen Grenzen, die für jede Strecke gleich gelten.

## What Changes

- **Härte einer Zone**: Jede Vorgabe einer Zone hat eine von drei Stufen, leicht, mittel oder hart:

  | Vorgabe | leicht (grün) | mittel (orange) | hart (rot) |
  |---|---|---|---|
  | Stufe | 1–5 | 6–10 | ab 11 |
  | Pace (Mitte des Bands) | 3:00 und langsamer | schneller als 3:00 bis einschliesslich 2:30 | schneller als 2:30 |
  | Schlagzahl (Mitte des Bands) | bis 21 | über 21 bis unter 24 | ab 24 |

  Hat eine Zone mehrere Vorgaben, bestimmt die härteste die Farbe.
- **Wo die Farbe erscheint**: Streckenbalken in allen Listen und Detailansichten, Balken und Abschnittszeilen im Strecken-Editor, Farbmarke vor jeder Zone in der Zonenliste. Freie Abschnitte bleiben grau.
- **Legende der Streckenliste**: zeigt „leicht“, „mittel“, „hart“ und „frei“ statt „Zone“ und „Helligkeit = Tempo“.
- **Die relative Abstufung der Pace-Bänder entfällt.** **BREAKING** nur für das Aussehen: Eine Strecke mit mehreren Pace-Zonen ist nicht mehr hell- bis dunkelblau.
- **Live-Anzeige unverändert**: Dort heisst blau weiterhin „in der Zone“ und orange „ausserhalb“. Die neuen Farben sind gedämpfte, eigene Töne und stehen nicht für Warnung, Fehler oder „verbunden“.

Nicht Teil dieses Changes:

- Einstellbare Grenzen. Sie sind vorerst fest.
- Grenzen pro Gerät. Stufen über 15 eines anderen FTMS-Geräts sind einfach hart.
- Die Farbe im Fortschrittsrahmen der Live-Anzeige.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `zones`: neue Requirement „Härte einer Zone als Farbe“. Sie legt die Grenzen, die Regel „härteste Vorgabe gewinnt“ und die Orte fest, an denen die Farbe erscheint.

## Impact

- **Code**:
  - `lib/features/courses/course_strip.dart`: `segmentColors` rechnet die Farbe aus der Härte statt aus der relativen Pace; `slowestPace`, `fastestPace`, `minShadeStep` und `_paceShades` fallen weg.
  - `lib/app/design_tokens.dart`: drei neue Farben für leicht, mittel und hart.
  - Neu eine reine Funktion für die Härte eines `CourseSegment` (in `lib/data/courses/`), damit sie ohne Widget testbar ist.
  - Aufrufer `zones_screen.dart` und `course_editor_screen.dart` bleiben unverändert, weil sie `segmentColors` nutzen.
- **Tests**: `test/features/courses/course_strip_test.dart` (Abstufungstests ersetzen), neuer Test der Härte.
- **Doku**: README, Abschnitt Zonen.
- **Daten**: keine Schema-Änderung.
