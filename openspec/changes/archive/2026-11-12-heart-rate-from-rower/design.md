# Design

## Context

- `HeartRateMonitorNotifier` (`lib/data/sources/heart_rate_monitor.dart`) baut pro Rudergerät-Quelle (`BleRowerSource`) eine `_StrapConnection`. Sie folgt `source.connectionStates`: bei `connected` und Phase `ready` verbindet sie sofort den Gurt, bei `disconnected`, `scanning` oder `connecting` trennt sie ihn und geht auf `ready`. Ein Fehlschlag führt zu `disconnected` mit `unreachable` oder `noHeartRateService`, ein Abbruch nach 30 Sekunden Wiederverbinden zu `disconnected` mit `lost`. `retry()` verbindet erneut.
- `HeartRateIndicator` und `HeartRateNotice` (`lib/features/connection/heart_rate_indicator.dart`) zeigen die Phase; die Meldung mit „Erneut versuchen“ erscheint bei `reconnecting` (ohne Knopf) und `disconnected`.
- Der Puls des Rudergeräts kommt bei FTMS aus den Rower Data, beim PM5 aus dessen Status. `rowingEventsProvider` liefert die dekodierten `StatusTick`s mit `heartRate`. `HeartRateDecoder` setzt dort den Puls des Gurts ein, solange dessen letzter Wert höchstens `strapTimeout` (3 s) alt ist, sonst bleibt der des Rudergeräts.
- Nach `remove-rr-intervals` liefert der Gurt nur noch den Puls.

## Goals / Non-Goals

**Goals:**
- Keine Gurt-Meldung, wenn der Puls vom Rudergerät kommt.
- Die Meldung blockiert nie dauerhaft: abbrechbar und nach 60 Sekunden von selbst weg.

**Non-Goals:**
- Erkennen, ob der Puls des Rudergeräts tatsächlich vom gekoppelten Gurt stammt; jeder Puls über 0 vom Rudergerät genügt.
- Den Gurt wieder verbinden, wenn der Puls des Rudergeräts später ausbleibt.

## Decisions

**D1: Zwei neue Phasen.** `HeartRateMonitorPhase` bekommt `fromRower` (Rudergerät liefert den Puls, kein Gurtversuch) und `cancelled` (abgebrochen). Beide halten bis zur nächsten Verbindung mit dem Rudergerät: Ein `disconnected`, `scanning` oder `connecting` des Rudergeräts setzt wie bisher auf `ready` zurück, ein neues Quellobjekt baut ohnehin eine neue `_StrapConnection`. Ein automatisches Wiederverbinden des Rudergeräts (`reconnecting` → `connected`) setzt nicht zurück, weil `connected` nur aus `ready` heraus verbindet.

Neue Zustandsfolge:

```
ready --(Rudergerät connected)--> waiting (bis 5 s)
waiting --(Puls vom Rudergerät)--> fromRower
waiting --(5 s ohne Puls)--> connecting --> connected | disconnected
disconnected --(Erneut versuchen)--> connecting
disconnected --(Abbrechen | 60 s)--> cancelled
connecting | reconnecting | disconnected --(Puls vom Rudergerät)--> fromRower
```

`waiting` ist keine eigene öffentliche Phase: nach aussen bleibt es `ready` („Wartet auf das Rudergerät“), intern merkt sich `_StrapConnection` den laufenden Zeitgeber.

**D2: Puls des Rudergeräts erkennen.** `HeartRateMonitorNotifier` gibt der `_StrapConnection` den Stream aus `rowingEventsProvider`. Ein `StatusTick` mit `heartRate > 0` zählt als Puls vom Rudergerät, wenn kein Gurt angehängt ist und der letzte angehängte Gurt seit mehr als `HeartRateDecoder.strapTimeout` getrennt ist; sonst könnte es noch der Puls des Gurts sein. Während `connected` wird der Stream nicht ausgewertet. Ein Puls vom Rudergerät in `connecting` erhöht `_attempt`, sodass eine danach noch gelingende Verbindung wie heute verworfen und getrennt wird.

Alternative: den Puls des Rudergeräts getrennt im Ereignis führen. Verworfen, weil dafür `StatusTick` und alle Decoder geändert werden müssten; die Bedingung „kein Gurt seit 3 s“ reicht, weil der Decoder genau dann den Puls des Rudergeräts durchlässt.

**D3: Wartezeit 5 Sekunden.** `HeartRateMonitorNotifier` bekommt `rowerHeartRateWait` (Standard 5 s) neben `reconnectWindow`, damit Tests mit kurzen Zeiten laufen. Meldet das Rudergerät keinen Puls (oder 0, etwa ohne Hautkontakt), verbindet die App nach Ablauf den Gurt wie bisher; D2 fängt einen später auftauchenden Puls ab.

**D4: Abbrechen und Zeitgeber.** `HeartRateMonitorNotifier.cancel()` geht aus `disconnected` auf `cancelled`. Beim Eintritt in `disconnected` startet `_StrapConnection` einen Zeitgeber über `cancelAfter` (Standard 60 s), der `cancel()` auslöst; `retry()`, `fromRower`, `_drop()` und `close()` stoppen ihn. Scheitert ein erneuter Versuch, beginnt der Zeitgeber neu. Bei `reconnecting` läuft kein Zeitgeber, weil das Wiederverbinden selbst nach 30 Sekunden endet.

**D5: Anzeige.** `HeartRateIndicator`: `fromRower` wie `connected` (grün, gefüllt, Text „Verbunden“), `cancelled` wie `disconnected` (leerer grauer Ring, Text „Getrennt“). Es gibt keinen eigenen Text für die Herkunft, damit sie nach F1 nicht sichtbar wird. `HeartRateNotice` zeigt bei `disconnected` die Knöpfe „Abbrechen“ (`actionCancel`, Key `heart-rate-cancel`) und „Erneut versuchen“; bei `fromRower` und `cancelled` keine Meldung. Die Knöpfe müssen auf 400 Punkte Breite neben dem dreizeiligen Text Platz haben; sonst stehen sie unter dem Text.

## Risks / Trade-offs

- [Das Rudergerät meldet einen Puls, obwohl der Gurt gar nicht an ihm hängt, z. B. über Handgriff-Sensoren] → Dann verbindet die App den Gurt nicht; der Puls ist trotzdem da. Gewollt, weil der Puls vom Rudergerät gleichwertig ist.
- [Das Rudergerät sendet erst beim Rudern Daten] → Die App verbindet nach 5 Sekunden den Gurt; scheitert das, steht die Meldung, bis der erste Puls vom Rudergerät kommt (D2) oder nach 60 Sekunden.
- [Puls vom Rudergerät fällt später weg] → Kein erneuter Gurtversuch bis zur nächsten Verbindung; der Puls fehlt dann, wie heute ohne Gurt.
