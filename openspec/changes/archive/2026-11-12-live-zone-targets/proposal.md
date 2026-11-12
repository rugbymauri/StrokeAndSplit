# Proposal

## Why

Beim Rudern sieht man die Vorgaben der aktuellen Zone nur teilweise: Das Pace-Band steht nur im Hinweis neben „Schneller“ oder „In der Zone“, die Stufe gar nicht, und in einem Abschnitt ohne Pace-Band steht unter der Pace nichts. Ausserdem hat die Live-Anzeige andere Farben als die Strecken: Dort ist eine Zone grün, orange oder rot nach ihrer Härte, im Fortschrittsrahmen ist jede Zone gleich grau. Man soll beim Rudern auf einen Blick sehen, was die Zone verlangt und wie hart sie ist.

## What Changes

- **Zielwerte unter der Pace**: In der Pace-Box steht unter dem Hinweis immer eine Zeile mit allen Vorgaben der aktuellen Zone, z. B. „Tempo · 2:05–2:10 · 20–22 spm · Stufe 8“. Fehlt eine Vorgabe, fehlt nur ihr Teil („Kraft · Stufe 12“). In einem freien Abschnitt steht „frei“.
- **Hinweis ohne Band**: Der Hinweis über der Zeile zeigt nur noch Zustand und Richtung („In der Zone“, „Schneller“), weil das Band jetzt in der Zeile steht. Der Hinweis auf die kommende Zone („Gleich 2:05–2:10“) bleibt an seiner Stelle.
- **Härte-Farben im Fortschrittsrahmen**: Die Zonen auf der Strecken- und der Rundenspur erscheinen in ihrer Härte-Farbe (grün, orange, rot) wie im Streckenbalken, gedämpft wo noch nicht gerudert, kräftig wo gerudert. Freie Abschnitte bleiben grau.
- **Abschnittsspur**: Der noch nicht geruderte Teil einer Zone zeigt die Härte-Farbe gedämpft. Der gerudete Teil zeigt weiterhin den Zustand der Pace (blau in der Zone, orange ausserhalb); eine Zone ohne Pace-Band füllt sich in ihrer Härte-Farbe statt neutral.
- **Legende und kommende Zone**: Der Punkt vor der Abschnittszeile der Legende und der blinkende Hinweis auf die kommende Zone haben die Härte-Farbe der jeweiligen Zone statt der Zustandsfarbe bzw. Gelb.
- **Stufe unter der Schlagzahl im Querformat**: Beim Rudern eines Workouts oder einer Strecke im Querformat steht unter der Schlagzahlkarte eine eigene Karte „Stufe“ in derselben Breite, mit der aktuellen Stufe gross und den Ruderblatt-Tasten links und rechts, um sie zu senken oder zu erhöhen. Die Watt-Kachel zeigt die Stufe im Querformat dann nicht mehr. Ohne gemeldete Stufe fehlt die Karte; lässt sich die Stufe nicht setzen, zeigt sie nur den Wert ohne Tasten. Das Hochformat und frei rudern bleiben wie bisher.
- **Zustandsfarben bleiben**: Blau heisst weiterhin „in der Zone“ und orange „ausserhalb“, immer mit Symbol und Wort; die Tönung der Pace-Box und der Schlagzahlkarte bleibt.

Nicht Teil dieses Changes:

- Frei rudern ohne Strecke (keine Zonen).
- Andere Farben für die Härte oder andere Grenzen.
- Die Schlagzahlkarte zeigt ihr Band wie bisher.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `live-display`: neue Requirements „Zielwerte der Zone unter der Pace“, „Zonen im Fortschrittsrahmen nach Härte“ und „Stufe unter der Schlagzahl im Querformat“; „Fortschrittsrahmen um die Pace“ (Band in der Zielwertzeile statt im Hinweis) und „Abschnittsspur zeigt den Zonenstatus“ (Härte-Farbe im ungeruderten Teil und bei Zonen ohne Pace-Band) ändern sich.
- `zones`: „Zonen nach Härte einfärben“ nennt die Live-Anzeige als weiteren Ort statt „bleibt unverändert“.

## Impact

- **Code**:
  - `lib/features/live/pace_box.dart`: Zielwertzeile, Hinweis ohne Band, Legendenpunkt in Härte-Farbe, Platz für die Zeile in der Höhenrechnung.
  - `lib/features/live/progress_frame.dart`: Zonen auf den Spuren in Härte-Farbe; die Abschnittsspur gedämpft in Härte-Farbe.
  - `lib/features/live/progress_frame_model.dart`: die Zonen einer Spur tragen ihre Härte.
  - `lib/features/live/upcoming_zone.dart`: Farbe der kommenden Zone.
  - `lib/features/live/live_course.dart` und neu `lib/features/live/resistance_card.dart`: Karte „Stufe“ im Querformat; `watts_tile.dart` ohne Stufe im Querformat.
  - `lib/app/design_tokens.dart`: Farbe für die Härte an einer Stelle, die Strecke und Live gemeinsam nutzen.
  - Texte für „Stufe 8“ und die Zielwertzeile in `lib/l10n/app_de.arb` und `app_en.arb`.
- **Tests**: `pace_box_test.dart`, `progress_frame_test.dart`, `progress_frame_model_test.dart`, `live_screen_test.dart`, `live_layout_test.dart`, neu `resistance_card_test.dart`.
- **Doku**: README, Abschnitt Live-Anzeige.
- **Daten**: keine Schema-Änderung.
