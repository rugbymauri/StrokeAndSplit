# Design

## Context

Motivation und Umfang stehen in `proposal.md`, das Verhalten in den Specs. Dieses Design baut auf dem Stand von `foundation` auf:

- Alle Datenquellen liefern `RawPacket`s mit einer Zeit relativ zum Start der Quelle. Beim PM5 und beim Simulator ist das die **Wanduhr**. Der PM5 sendet auch in Pausen weiter (250 ms), nur seine eigene Uhr und Distanz stehen dann still (siehe `packages/pm5_protocol/README.md`).
- Die Aufzeichnung läuft über einen reinen `SessionAccumulator`, der Rohpakete in session-relative `samples`, `strokes` und `raw_packets` übersetzt. Live-Aufzeichnung und Import nutzen ihn gleichermassen, deshalb ergibt ein Import exakt dieselben Zeilen.
- `samples.tMs` ist die session-relative **PM5-Zeit**. Das drift-Schema hat Version 1, das Migrations-Setup (`make schema`) ist vorbereitet.
- Das Live-Display hört auf den Event-Stream der aktiven Quelle und auf den Zustand des Recorders.

## Goals / Non-Goals

**Goals:**
- Live und beim Import entstehen dieselben Runden- und Segmentergebnisse, weil beide aus derselben reinen Logik stammen.
- Die Runden einer Session lassen sich später für den Ghost als (Wanduhr, Distanz)-Verlauf rekonstruieren, ohne dass `ghost` das Schema ändern muss.
- Bestehende Sessions bleiben nach der Migration unverändert nutzbar.

**Non-Goals:**
- Runden- und Zonenanzeige beim Replay im Live-Display. Ein Replay zeigt wie bisher nur die Rohwerte.
- Mehrere Blöcke pro Vorlage. Das Schema erlaubt sie, die App legt und liest aber genau einen.
- Strecken und Vorlagen ohne Session austauschen.

## Decisions

### D1: Wanduhr-Zeit aus den Paketzeiten

Der Accumulator speichert pro Sample zusätzlich `wallMs = packet.time - erstesPaket.time`, also dieselbe Basis wie bei `raw_packets.tMs`. Damit läuft die Wanduhr in Pausen weiter, weil der PM5 weiter Status-Pakete sendet. Bei einem Verbindungsabbruch entsteht beim Wiederverbinden ein Sprung, der wie eine Pause zählt. Das ist gewollt.

Weil der Import die gespeicherten Paketzeiten verwendet, ergibt er dieselbe Wanduhr. Das ist die Voraussetzung für die Spec „Export und Import einer Vorlagen-Session“.

Der PM5 hält seine Uhr in der Pause an. Bisher wurden Samples mit gleicher PM5-Zeit und Distanz verworfen. Diese Regel fällt weg, sobald eine Session auf einer Strecke läuft, denn die Zonenzählung braucht auch Pausensamples (sie zählen als ausserhalb). Für freie Sessions bleibt die Regel bestehen, damit `samples` nicht unnötig wächst.

*Alternativen:* eine eigene `clock.now()`-Messung im Recorder. Verworfen, weil sie beim Import nicht reproduzierbar ist. Die PM5-Zeit plus erkannte Pausen ist zu fehleranfällig, weil der PM5 Pausen nicht meldet.

### D2: Reiner Runden-Tracker

Ein reiner `LapTracker` bekommt die Strecke (Achse, Länge, Segmente mit Bändern), die geplante Rundenzahl und nacheinander Messpunkte `(wallMs, distanceDm, pace?, strokeRate?)`. Er liefert:
- den aktuellen Stand für das Live-Display: Runde, Segment, Rest bis zum Segmentende, Zonenstatus und laufenden Anteil in der Zone
- fertige Segment- und Rundenergebnisse, sobald eine Grenze überschritten ist
- `finished`, wenn bei einer festen Rundenzahl die letzte Runde vorbei ist

Die Achsenposition ist bei Distanzstrecken die Session-Distanz und bei Zeitstrecken `wallMs`. Eine Grenze zwischen zwei Messpunkten wird linear interpoliert: Der andere Wert (Zeit bzw. Distanz) wird anteilig berechnet, der Überschuss geht an die nächste Runde. Über mehrere Grenzen hinweg, etwa nach einem langen Verbindungsabbruch, interpoliert der Tracker jede Grenze einzeln.

Der Accumulator besitzt einen Tracker, wenn die Session eine Strecke hat, und füttert ihn aus jedem Status-Tick. Seine Ergebnisse landen im selben 2-s-Batch wie die Samples. Damit gelten Absturzsicherheit und Import automatisch auch für Runden.

*Alternative:* Runden nachträglich aus `samples` berechnen. Verworfen für den Live-Betrieb, weil das Display den Stand ohnehin laufend braucht. Für die Crash-Recovery wird es aber genutzt (siehe D5).

### D3: Zonenbewertung zeitgewichtet

Ein Messpunkt ist „in der Zone“, wenn alle gesetzten Bänder des Segments erfüllt sind: `schnellste ≤ pace ≤ langsamste` und `min ≤ spm ≤ max`. Ein fehlender Wert (`pace == null` in der Pause, keine Schlagzahl) gilt als ausserhalb. Der Anteil ist zeitgewichtet: Jedes Intervall zwischen zwei Messpunkten zählt mit seiner Wanduhr-Dauer und dem Zustand des früheren Punkts. Liegt ein Intervall auf einer Segmentgrenze, wird es dort geteilt.

Der Rundenanteil ist der zeitgewichtete Anteil über alle Segmente der Runde, die mindestens ein Band haben. Hat keines eines, ist er leer (`null`).

### D4: Datenmodell (Schema-Version 2)

```
 courses          (id, name, axis: distance|time, deletedAt?)
 course_versions  (id, courseId, version, length, createdAt)
                   length in m (Distanz) bzw. s (Zeit)
 course_segments  (versionId, position, length,
                   paceFastCs?, paceSlowCs?, spmMin?, spmMax?)
 templates        (id, name, createdAt)
 template_blocks  (templateId, position, courseId, laps?)   laps null = offen
 sessions        + templateId?, templateName?, courseVersionId?, plannedLaps?
 samples         + wallMs?                                   null bei alten Sessions
 laps             (sessionId, lapNo, startWallMs, endWallMs,
                   startDistanceDm, endDistanceDm, complete, inZoneShare?)
 lap_segments     (sessionId, lapNo, position, durationMs, distanceDm, inZoneShare?)
```

- **Name an der Strecke, Definition an der Version.** Umbenennen ändert nur `courses.name`, alle Sessions zeigen den neuen Namen. Ändern sich Länge, Segmente oder Bänder und gibt es schon eine Session mit `courseVersionId` der aktuellen Version, entsteht eine neue Version. Sonst wird die aktuelle Version überschrieben. Das erfüllt „Geruderte Strecken versionieren“, ohne Versionen von nie gerudertem Herumprobieren anzuhäufen.
- **Strecken werden weich gelöscht** (`deletedAt`), weil Sessions auf ihre Versionen zeigen. Vorlagen, die eine gelöschte Strecke verwenden, werden im selben Schritt hart gelöscht (siehe Spec „Strecke einer Vorlage löschen“).
- **Vorlagen werden hart gelöscht.** Sessions halten dafür `templateName` als Kopie und `templateId` als nullable Verweis, der beim Löschen auf `null` gesetzt wird. Die Session zeigt ihren Namen von damals. Bei einer Umbenennung zeigt sie bewusst den alten Namen, weil die Session mit diesem Namen gerudert wurde.
- **`template_blocks` mit `position`** schon jetzt, damit Abfolgen später ohne Migration möglich sind (siehe Proposal).
- **`plannedLaps` in der Session**, weil die Vorlage später geändert werden kann. Die Session zeigt „Runde 2 von 3“ dann weiterhin korrekt.

### D5: Crash-Recovery für Runden

Die Recovery aus `foundation` setzt `recording` auf `incomplete`. Neu kommt hinzu: Hat die Session eine Strecke, wird die letzte gespeicherte Runde, falls nicht `complete`, aus den gespeicherten Samples abgeschlossen. Dafür fährt die Recovery den `LapTracker` über die Samples ab dem Beginn dieser Runde und speichert das Ergebnis als unvollständige Runde. Vollständige Runden sind schon im Batch gelandet und bleiben unangetastet.

### D6: Recorder und automatisches Ende

`SessionRecorder.start()` bekommt optional eine Vorlage. Daraus löst er die aktuelle Strecken-Version auf, schreibt die Verweise in die Session und gibt dem Accumulator einen Tracker mit. Der Recorder-Zustand trägt zusätzlich den Live-Stand des Trackers. Meldet der Tracker `finished`, beendet der Recorder die Session selbst, und das Live-Display reagiert auf den Wechsel von „läuft“ auf „beendet mit Session-ID“ und öffnet die Zusammenfassung. Endet die Session per Knopf, schliesst der Recorder eine angefangene Runde als unvollständig ab.

### D7: Export und Import

Der Header von `.aergrow` bekommt `template: {name, laps}` und `course: {name, axis, length, segments: [...]}` mit der geruderten Version. Beim Import sucht die App eine nicht gelöschte Strecke mit gleichem Namen und einer Version mit identischer Definition. Gibt es sie, wird die Session damit verknüpft, sonst wird eine neue Strecke mit dieser Version angelegt. Eine Vorlage wird beim Import nicht angelegt, nur `templateName` gesetzt. Runden und Segmente entstehen wie alle anderen Zeilen über den Accumulator neu. Dateien ohne diese Felder werden wie bisher als freie Sessions importiert.

### D8: Bedienung

```
 Start
  +-- PM5 suchen / Simulator   -> Live (frei, "Session starten")
  +-- Vorlage rudern           -> Vorlagen-Liste
  |                                +-- Vorlage antippen -> Quelle wählen
  |                                |      (PM5 suchen | Simulator)
  |                                |      -> Live, Session startet sofort
  |                                +-- Vorlage anlegen/bearbeiten
  |                                +-- Strecken -> Strecken-Liste/-Editor
  +-- Sessions
```

- **Strecken-Editor:** Er arbeitet mit numerischen Eingaben statt Ziehen. Ein Segment wird geteilt, indem man an einer Position einen Schnitt setzt, und Bänder sind optionale Felder pro Segment. Bei Zeitstrecken wird im Format m:ss eingegeben.
- **Live-Display:** Über den Kernwerten erscheint eine Streckenleiste mit Runde, Segment, Rest und Zonenanteil. Die Kacheln von Pace und Schlagzahl zeigen Zonenfarbe und Pfeil. Im Querformat wird die Leiste einzeilig. Die bestehenden Layout-Tests werden um eine Vorlagen-Variante erweitert (Spec live-display).

## Risks / Trade-offs

- **[Unregelmässige BLE-Zustellung, Pakete in Bündeln]** → Rundengrenzen werden an der Wanduhr der Pakete gemessen, also auf etwa 50 ms genau. Für Rundenzeiten mit Zehntelsekunden ist das ausreichend. Die Interpolation glättet zusätzlich.
- **[Die PM5-Pace ist geglättet und reagiert verzögert]** → Bei einem Segmentwechsel mit anderem Pace-Band ist man die ersten Sekunden ausserhalb, obwohl man richtig rudert. Das wird vorerst in Kauf genommen und ist eine offene Frage für eine Toleranzzeit.
- **[Pausensamples vergrössern die Datenbank]** → Das betrifft nur Sessions auf Strecken, und es sind 4 Zeilen pro Sekunde Pause. Das ist unkritisch.
- **[Schema-Migration 1 → 2 ist die erste echte Migration]** → Neue Spalten sind nullable, neue Tabellen sind additiv. Generierte Migrationstests (`make schema`) prüfen den Schritt mit Daten aus Version 1.
- **[`foundation` ist noch nicht archiviert]** → Die Deltas für `session-recording` und `live-display` setzen dessen Specs voraus. `foundation` wird vor `/opsx:apply courses` archiviert.

## Migration Plan

1. `schemaVersion` auf 2 setzen, neue Tabellen und Spalten anlegen, `make schema` erzeugt den Snapshot v2 und die Migrationstests.
2. Die Migration `from1To2` legt die Tabellen an und ergänzt die Spalten. Alte Sessions behalten `wallMs = null` und keine Verweise. Ihre Zusammenfassung ändert sich nicht.
3. Ein Rollback auf eine App-Version mit Schema 1 ist nicht vorgesehen, weil die App nur lokal läuft. Vor dem Update lassen sich Sessions als `.aergrow` exportieren.

## Open Questions

- Toleranzzeit nach einem Segmentwechsel, z.B. die ersten 5 s nicht werten. Das lässt sich nach den ersten echten Sessions entscheiden, ist ein Parameter im `LapTracker` und ändert weder Specs noch Schema.
- Ob die Zusammenfassung zusätzlich Segmentzeiten pro Runde als Tabelle zeigt. Die Daten sind gespeichert, die Darstellung kann nachziehen.
