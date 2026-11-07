# Proposal

## Why

Wählt der Nutzer eine Vorlage, startet die Session heute sofort, sobald die Datenquelle verbunden ist. Bis er die Füsse festgeschnallt und den Griff in der Hand hat, laufen schon Zeit, Zeitabschnitt und Ghost. Die erste Runde ist dadurch langsamer als gerudert, Zeitstrecken werden kürzer und der Vergleich mit dem Ghost ist verfälscht. Wie beim PM5 selbst soll die Zeit erst mit dem ersten Ruderschlag laufen.

## What Changes

- Nach der Wahl einer Vorlage (auch über „Nochmal“) ist die Session **bereit**, aber noch nicht gestartet: Es läuft keine Zeit, Runde, Abschnitt und Ghost stehen am Start, und es wird noch nichts gespeichert.
- Das Live-Display zeigt im Bereit-Zustand deutlich „Bereit – startet mit dem ersten Schlag“.
- Mit dem ersten Ruderschlag startet die Session: Wanduhr-Start, Zeit- und Distanz-Nullpunkt. Der Nullpunkt liegt beim letzten Messwert vor der ersten Bewegung, sodass vom ersten Schlag nichts verloren geht.
- Trennt oder beendet der Nutzer im Bereit-Zustand, entsteht keine gespeicherte Session.
- Freies Rudern bleibt unverändert: „Session starten“ startet sofort.

Nicht Teil dieses Changes: Start mit dem ersten Schlag bei freiem Rudern, ein Countdown, ein Simulator, der bis zum ersten Schlag wartet.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `session-recording`: „Session starten und beenden“ nennt den Start einer Vorlage mit dem ersten Schlag; neue Anforderungen zum Bereit-Zustand und zum Nullpunkt beim ersten Schlag.
- `live-display`: neue Anforderung, den Bereit-Zustand vor dem ersten Schlag anzuzeigen.

## Impact

- `lib/data/sessions`: Der Recorder kennt einen Bereit-Zustand ohne Session in der Datenbank und erkennt die erste Bewegung aus den dekodierten Ereignissen. Keine Schema-Änderung.
- `lib/features/live`: Hinweis im Bereit-Zustand als eigenes Widget; Beenden und Trennen im Bereit-Zustand speichern nichts.
- `lib/l10n`: neuer Text auf Deutsch und Englisch.
- Gespeicherte Rohdaten beginnen mit dem Nullpunkt; Export, Import und Replay bleiben kompatibel.
