# Design

## Context

- **Verbindung**: `setUpRower` in `lib/data/sources/ble/rower_connector.dart` abonniert bei FTMS die Rower Data und sendet einmal Request Control (`00`) und Start/Resume (`07`) an den Control Point `2ad9` (device-types D7). Danach leitet `_GattLink` nur `2ad1` weiter. Antworten des Control Points und der Machine Status `2ada` gehen verloren. `GattConnection` kann abonnieren und schreiben, aber nicht lesen.
- **Anzeige**: Seit ui-design 5.15 trägt `StatusTick.resistanceLevel` die gemeldete Stufe als ganze Zahl, und die Live-Anzeige zeigt sie als Fussnote der Watt-Kachel.
- **Strecken**: Ein `CourseSegment` ist eine Kopie der Zone mit ihren Bändern (Tabellen `zones` und `course_segments`, Schema 8). `LapTracker` liefert in `LapProgress` den Index des aktuellen Segments. Die Session speichert eine Kopie der Strecke als JSON (`session_repository.dart`), und `.strokesplit` übernimmt sie.
- **Spike am Woodrower (2026-11-05)**: Features `a6 56 00 00 04 00 00 00` (Stufe gemeldet, Stufe setzbar), Bereich `2ad6` = `0a 00 96 00 0a 00` (1,0 bis 15,0, Schritt 1,0, in Zehnteln). `04 3c` wird mit `80 04 01` angenommen. Danach meldet der Machine Status `07 3c`, und die Rower Data melden Stufe 6. s16 und Werte ohne Faktor 10 lehnt er mit `03` ab. Was nach einer Pause geschah, war eine Handänderung des Nutzers.

## Goals / Non-Goals

**Goals:**
- Eine reine, ohne Gerät testbare Logik, die aus Segmentwechseln, gemeldeten Stufen und Tipps auf −/+ die zu sendende Stufe bestimmt.
- Gleicher Weg für BLE-Gerät und Simulator, damit die ganze Kette im Simulator läuft.

**Non-Goals:**
- Eine allgemeine FTMS-Steuerung mit Zielleistung, Neigung oder Simulationsparametern. Die Kodierung wird so geschnitten, dass sie später dazukommen kann, mehr nicht.
- Erkennen, ob das Gerät die Stufe von selbst ändert.

## Decisions

### D1: Steuerung als optionale Fähigkeit der Quelle

`ErgSource` bekommt `ResistanceControl? get resistanceControl`. Das Objekt ist null für PM5, Replay, den Simulator im PM5-Modus und FTMS-Geräte ohne Bit 2 in den Target Settings. Es liefert:

- `range` (min, max, Schritt als ganze Stufen),
- `Future<ResistanceResult> setLevel(int level)`.

`ResistanceResult` ist `accepted`, `rejected(code)` oder `noAnswer`. Die Live-Anzeige und die Logik fragen nur die Fähigkeit ab und kennen kein FTMS.

*Alternative*: Ein eigener Provider, der direkt auf den BLE-Transport schreibt. Verworfen, weil der Simulator dann einen zweiten Weg bräuchte und das Wiederverbinden die Verbindung austauscht.

### D2: Setup liest Features und Bereich, der Link hält den Control Point

`GattConnection` bekommt `Future<List<int>> read(String id)`. `_setUpFtms` liest `2acc` und, wenn Bit 2 der Target Settings gesetzt ist, `2ad6`. Der Control Point bleibt abonniert. Der Link gibt die Steuerung als eigenes Objekt heraus, das schreibt und auf die passende Antwort `80 04 xx` wartet (Timeout 2 s, wie `controlTimeout`). Die Antworten gehen nicht in `packets`, damit Decoder und Rohdaten unverändert bleiben.

Fehlt der Bereich oder ist er unplausibel (min > max, Schritt 0), gilt 1 bis 15 nicht als Annahme. Dann wird die Steuerung nicht angeboten. So sendet die App nie ins Blaue.

Nach einem Wiederverbinden durchläuft das Setup dieselben Schritte. `BleRowerSource` tauscht dabei die Steuerung aus und meldet über einen Stream, dass sie neu ist (D5).

### D3: Kodierung u8 in Zehnteln, Rückfall auf s16

„Set Target Resistance Level“ ist `04` plus der Wert in Zehnteln, nach FTMS 1.0 als UINT8. Das hat der Woodrower bestätigt. Antwortet ein Gerät mit `03` (ungültiger Wert), sendet die App denselben Wert einmal als s16 little-endian. Gelingt das, bleibt sie für diese Verbindung bei s16. Liegt das Maximum über 25,5, passt der Wert nicht in ein Byte, und die App sendet gleich s16.

Antwortet das Gerät mit `05` (Kontrolle nicht erlaubt), schickt die App einmal Request Control und versucht es erneut. Kodierung und Dekodierung liegen in `packages/erg_protocol/lib/src/ftms/` (`ftms_control.dart`), samt Parser für Features und Bereich.

### D4: Reine Logik `ResistanceDirector`

Eine Klasse unter `lib/data/sessions/` ohne Flutter- und BLE-Abhängigkeit. Ihre Eingaben:

- `start(reportedLevel)`: Die erste gemeldete Stufe der Session wird die Grundstufe.
- `segmentStarted(CourseSegment?)`: null beim freien Rudern.
- `reported(level)`: die Stufe aus den Rower Data.
- `step(+1 | -1)`: ein Tipp auf + oder −.
- `reconnected()`

Sie liefert die Stufe, die gesendet werden soll, oder nichts. Regeln:

- **Ziel**: `segment.resistanceLevel ?? grundstufe`, auf den Bereich geklemmt und auf den Schritt gerundet. Gesendet wird nur, wenn das Ziel von der zuletzt gemeldeten Stufe abweicht.
- **Handänderung**: Weicht eine gemeldete Stufe vom zuletzt gesendeten Ziel ab und steht keine Antwort mehr aus, gilt sie als Handänderung. Sie wird das Ziel bis zum nächsten Segment. In einem Segment ohne Stufe wird sie die Grundstufe. Ein gesendetes Ziel, das das Gerät noch nicht meldet, gilt für 3 s nicht als abgewichen. So wird die Verzögerung zwischen Antwort und nächstem Messwert nicht als Handänderung gelesen.
- **−/+**: Der Schritt geht vom aktuellen Ziel aus, nicht von der gemeldeten Stufe. So landen drei schnelle Tipps bei 6 auf 9. Ein Tipp ist eine Handänderung wie oben.
- **Pause**: Die Pause ist kein Ereignis. Eine Änderung in der Pause ist eine Handänderung.
- **Wiederverbinden**: Das aktuelle Ziel wird erneut gesendet.

Beim freien Rudern wird `segmentStarted` nie aufgerufen, also sendet nur −/+. Ein Provider verbindet die Klasse mit `lapProgress` (Segmentindex wechselt, auch bei neuer Runde), mit den `StatusTick`s und mit `resistanceControl` der aktiven Quelle. Er serialisiert die Aufrufe von `setLevel`: Neue Ziele ersetzen ein noch nicht gesendetes.

*Alternative*: Die Logik in `SessionAccumulator`. Verworfen, weil der Accumulator auch Import und Replay rechnet und dort nichts gesendet werden darf.

### D5: Fehler sichtbar, aber leise

Bei `rejected` oder `noAnswer` zeigt die Live-Anzeige zwei Sekunden lang einen Hinweis „Stufe nicht gesetzt“ an der Stufe, wie beim Zonenhinweis. Die Logik übernimmt danach die gemeldete Stufe als Ziel, damit sie nicht immer wieder sendet. Bei Fehlern versucht sie es erst beim nächsten Segment oder Tipp wieder.

### D6: Bedienung in der Live-Anzeige

Die Fussnote „Stufe 6“ der Watt-Kachel wird zu einer Zeile `− Stufe 6 +` mit zwei Tasten von mindestens 48 × 48 dp, links und rechts der Fussnote. Die Kachel bekommt dafür keine zusätzliche Höhe, die Tasten liegen in der Fussnotenzeile. Ist die Zeile bei 390 px zu eng, kommen die Tasten unter die Kachel. Das klärt Task 5.1 mit dem Overflow-Test von 5.15.

An der Bereichsgrenze ist die Taste deaktiviert. Ohne `resistanceControl` bleibt die heutige Fussnote. Die Tasten verwenden die Ruderblatt-Symbole des `OarStepper` in kleiner Form, damit sie zur Designsprache passen.

*Alternative*: Ein Tipp auf die Stufe öffnet einen grossen `OarStepper` als Overlay. Verworfen, weil das zwei Tipps pro Änderung braucht und die Kernwerte verdeckt.

### D7: Datenmodell, Schema 9

- `zones.resistance_level` und `course_segments.resistance_level`: `INTEGER NULL`, ganze Stufe.
- `from8To9` fügt beide Spalten hinzu (`make schema`, Schritt-Test wie bei 8).
- `Zone`, `CourseSegment` (inkl. `sameAs`, `withLength`, `segment`) und die Repositories tragen das Feld.
- Die JSON-Kopie der Strecke in der Session schreibt `resistanceLevel` nur, wenn gesetzt, und liest es optional. Das `.strokesplit`-Format bleibt damit abwärtskompatibel.
- Eine Zone mit Stufe, aber ohne Band, bleibt ungültig (`bandMissing`). `isFree` eines Segments bleibt nur von den Bändern abhängig. Ein freier Abschnitt hat nie eine Stufe, weil er keine Zone ist.
- Im Zoneneditor ist die Stufe ein optionales Feld mit Schalter wie die Bänder, `OarStepper` 1 bis 25, Start 5. Die Obergrenze des Geräts ist beim Bearbeiten nicht bekannt, die App klemmt beim Rudern (Spec „Stufe ausserhalb des Bereichs“).

### D8: Simulator

`SimulatedSource` im FTMS-Modus bietet eine `ResistanceControl` mit Bereich 1 bis 15, Schritt 1 an. `setLevel` antwortet sofort mit `accepted` und setzt die Stufe, die ab dem nächsten Paket gemeldet wird (heute fest `ftmsResistanceLevel = 5`, das wird der Startwert). Die Simulator-Steuerung bekommt kein eigenes Stufenfeld. Wer das Verhalten am Gerät nachstellen will, nutzt −/+ in der Live-Anzeige.

## Risks / Trade-offs

- [Eine gemeldete Stufe kommt spät, und die Logik hält sie für eine Handänderung] → Schonfrist von 3 s nach dem Senden (D4). Ein Unit-Test deckt eine verzögerte Meldung ab.
- [Gerät stellt die Stufe selbst um, zum Beispiel nach einer Pause] → gilt als Handänderung, bis zum nächsten Segment. Ein Gerätetest prüft das am Woodrower (Task 6.2). Zeigt er ein Zurückstellen, wird der Change angepasst.
- [Request Control nimmt einer anderen App die Kontrolle] → Die App fragt schon heute beim Verbinden danach (device-types D7). Neu ist nur der Retry bei `05`.
- [Andere FTMS-Geräte melden die Stufe in Zehnteln statt ganz] → Die Anzeige würde 60 statt 6 zeigen. Die App vergleicht die gemeldete Stufe mit dem Bereich: Liegt sie über dem Maximum und ist sie durch 10 geteilt im Bereich, rechnet sie in Zehnteln. Das bleibt eine Heuristik und ist nur am Woodrower geprüft.
- [Die Fussnotenzeile wird zu eng] → Rückfall unter die Kachel (D6), mit Test bei 390 px.

## Migration Plan

Schema 8 → 9 mit zwei nullable Spalten, kein Datenumbau. Ein Rückweg ist nicht nötig, alte App-Versionen lesen Schema 9 ohnehin nicht. `.strokesplit`-Dateien ohne Stufe bleiben gültig.
