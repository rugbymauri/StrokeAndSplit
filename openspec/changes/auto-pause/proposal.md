# Proposal

## Why

Hört der Nutzer auf zu rudern, läuft die Session heute weiter: Die Wanduhr zählt, Zeitstrecken laufen ab, Rundenzeiten und der Zonenanteil enthalten die Pause, und auch der Ghost fährt davon. Wer kurz trinkt oder den Fuss neu festschnallt, verdirbt damit die Runde. Wie bei einer Sportuhr mit Auto-Pause soll die Session anhalten, wenn nicht mehr gerudert wird, und mit dem nächsten Schlag weiterlaufen.

## What Changes

- **Auto-Pause:** Bleibt der nächste Ruderschlag aus, pausiert die Session 3 s nach dem Zeitpunkt, an dem er im bisherigen Rhythmus fällig gewesen wäre. Mit dem nächsten Schlag läuft sie weiter. Gilt für freies Rudern und Vorlagen, für PM5 und FTMS-Rudergeräte.
- **Alles hält an:** In der Pause stehen Sessionzeit, Rundenzeit, Abschnittszeit, der Fortschritt einer Zeitstrecke und die Ghost-Zeit still. Die Pause zählt nicht zum Anteil in der Zone. **BREAKING** gegenüber den heutigen Specs, nach denen Wanduhr-Zeit und Pausen in Zeitstrecken, Rundenzeiten und den Zonenanteil eingehen.
- **Sessionzeit:** Neben PM5-Zeit und Wanduhr-Zeit speichert die App pro Messwert die Sessionzeit (Wanduhr ohne Pausen). Dauer, Durchschnittspace und -schlagzahl der Zusammenfassung beruhen auf der Sessionzeit.
- **Pausen speichern:** Jede Pause wird mit Beginn und Ende gespeichert. Die Zusammenfassung zeigt Anzahl und Gesamtdauer der Pausen.
- **Live-Display:** Während der Pause zeigt es deutlich „Pause“.
- **Bestand:** Sessions aus früheren Versionen behalten ihre Werte und haben keine Pausen. Beim Import werden Pausen aus den Rohdaten erkannt; eine Session ohne Stillstand ergibt dieselben Werte wie bisher.

Nicht Teil dieses Changes: eine einstellbare Schwelle, Auto-Pause abschalten, manuelles Pausieren per Button, Neuberechnung bereits gespeicherter Sessions.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `session-recording`: neue Anforderungen zur Auto-Pause und zum Speichern der Pausen; „Wanduhr-Zeitachse aufzeichnen“ ergänzt die Sessionzeit; „Session vollständig speichern“ nennt die Pausen und die Dauer ohne Pausen.
- `course-rowing`: „Fortschritt nach Wanduhr messen“ wird zu „Fortschritt nach Sessionzeit messen“ (Zeitstrecken und Rundenzeiten ohne Pausen); „Anteil in der Zone zählen“ lässt Pausen aus.
- `live-display`: neue Anforderung, die Pause anzuzeigen.

## Impact

- `lib/data/sessions`: eigener Pausen-Detektor auf den dekodierten Ereignissen, im `SessionAccumulator` für Aufzeichnung, Import und Replay gleich; der `LapTracker` läuft auf der Sessionzeit; der Recorder meldet den Pausen-Zustand.
- `lib/data/db`: Schema 7 mit `samples.active_ms`, Tabelle `pauses` und den Pausen-Summen in `sessions`; Migration und Schema-Snapshot.
- `lib/data/ghost`: Ghost-Verlauf aus der Sessionzeit der Samples.
- `lib/features/live`, `lib/features/sessions`, `lib/features/statistics`: Hinweis „Pause“, Pausen in der Zusammenfassung, Hinweistext der Ranglisten.
- `lib/l10n`: neue und geänderte Texte auf Deutsch und Englisch.
- Export-Format unverändert; Import und Replay erkennen die Pausen aus den Rohdaten.
