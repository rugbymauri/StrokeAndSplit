# Proposal

## Why

Ist der Pulsgurt am FTMS-Rudergerät gekoppelt (z. B. am Woodrower), ist seine einzige Bluetooth-Verbindung belegt. Die App versucht trotzdem, sich direkt mit ihm zu verbinden, scheitert und zeigt während des Ruderns dauerhaft die Meldung, dass der Gurt nicht erreichbar ist, mit „Erneut versuchen“ als einziger Aktion. Der Puls kommt in diesem Fall aber schon über das Rudergerät. Seit `remove-rr-intervals` bringt der direkt verbundene Gurt gegenüber dem Puls vom Rudergerät nichts mehr.

## What Changes

- **Kein Gurtversuch bei Puls vom Rudergerät**: Nach dem Verbinden mit dem Rudergerät wartet die App bis zu 5 Sekunden auf dessen Puls. Liefert das Rudergerät einen Puls, verbindet sie sich nicht mit dem Gurt. Sonst verbindet sie sich wie bisher.
- **Puls vom Rudergerät taucht später auf**: Kommt der Puls vom Rudergerät erst, während die App den Gurt verbindet, wiederverbindet oder die Meldung zeigt, beendet sie den Gurtversuch und blendet die Meldung aus.
- **Herz grün**: Kommt der Puls vom Rudergerät, zeigt das Herz in der Kopfzeile den grünen Punkt wie bei einem verbundenen Gurt. Die Herkunft des Pulses wird weiterhin nicht angezeigt.
- **„Abbrechen“ in der Meldung**: Neben „Erneut versuchen“ steht „Abbrechen“. Abbrechen blendet die Meldung aus, und die App versucht den Gurt erst bei der nächsten Verbindung mit dem Rudergerät wieder; das Herz zeigt dann den leeren grauen Ring.
- **Automatisch abbrechen**: Tippt der Nutzer innerhalb von 60 Sekunden nach Erscheinen der Meldung weder „Abbrechen“ noch „Erneut versuchen“, bricht die App von selbst ab.

Nicht Teil dieses Changes:

- Ein Schalter, der den Gurt dauerhaft dem Rudergerät überlässt.
- Änderungen an der Gurt-Suche und am Koppeln in „Geräte wählen“.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `heart-rate-monitor`: „Gurt mit dem Rudergerät verbinden“ wartet auf den Puls des Rudergeräts; „Gurt automatisch wiederverbinden“ und „Gurt-Zustand sichtbar machen“ angepasst; neu „Gurtversuch bei Puls vom Rudergerät beenden“ und „Gurt-Meldung abbrechen“.

## Impact

- **Code**:
  - `lib/data/sources/heart_rate_monitor.dart`: Wartezeit, Puls des Rudergeräts aus `rowingEventsProvider`, neue Phasen für „Puls vom Rudergerät“ und „abgebrochen“, `cancel()`, Zeitgeber für 60 Sekunden.
  - `lib/features/connection/heart_rate_indicator.dart`: Farbe und Text der neuen Phasen, Knopf „Abbrechen“ in `HeartRateNotice`.
  - Der Text „Abbrechen“ besteht schon (`actionCancel`); keine neuen Texte nötig.
- **Tests**: `heart_rate_monitor_test.dart`, Tests für Indikator und Meldung.
- **Doku**: README, Abschnitt Pulsgurt.
- **Daten**: keine Schema-Änderung.
- **Abhängigkeit**: nach `remove-rr-intervals` umsetzen; beide ändern den README-Abschnitt Pulsgurt.
