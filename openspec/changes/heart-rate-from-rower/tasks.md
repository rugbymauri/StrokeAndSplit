# Tasks

Keine Schema-Änderung und keine neuen Texte („Abbrechen“ ist `actionCancel`). Nach `remove-rr-intervals` umsetzen.

## 1. Gurtverbindung

- [x] 1.1 Phasen `fromRower` und `cancelled`, Wartezeit `rowerHeartRateWait` und Erkennung des Pulses vom Rudergerät aus `rowingEventsProvider` nach D1–D3. Verifikation in `heart_rate_monitor_test.dart` mit kurzen Zeiten:
  - Ein Rudergerät mit Puls 95 nach 2 s ergibt `fromRower` und keinen Aufruf von `connectHeartRateMonitor`.
  - Ohne Puls oder mit Puls 0 verbindet die App nach der Wartezeit den Gurt.
  - Puls vom Rudergerät in `connecting`, `reconnecting` und `disconnected` ergibt `fromRower`; eine danach noch gelingende Gurtverbindung wird getrennt.
  - Der Puls des Gurts selbst bis 3 s nach dem Abbruch löst kein `fromRower` aus.
  - Nach `disconnected` des Rudergeräts und neuem `connected` beginnt das Warten wieder.
  - Mit Simulator und Replay bleibt es bei `ready` ohne Gurtversuch.
- [x] 1.2 `cancel()` und Zeitgeber `cancelAfter` nach D4. Verifikation in `heart_rate_monitor_test.dart` (mit `fakeAsync`):
  - `cancel()` aus `disconnected` ergibt `cancelled`; danach startet `retry()` keinen Versuch.
  - Nach 60 s in `disconnected` ohne Aktion ist die Phase `cancelled`.
  - `retry()` nach 40 s stoppt den Zeitgeber; scheitert der Versuch, läuft er wieder volle 60 s.
  - Ein automatisches Wiederverbinden des Rudergeräts setzt `cancelled` nicht zurück, ein neues Verbinden schon.

## 2. Anzeige

- [x] 2.1 `HeartRateIndicator` und `HeartRateNotice` nach D5. Verifikation in einem Widget-Test:
  - Bei `fromRower` ist der Punkt grün und gefüllt, der Text „Pulsgurt: Verbunden“, und es gibt keine `heart-rate-notice`.
  - Bei `cancelled` ist es der leere graue Ring ohne Meldung.
  - Bei `disconnected` gibt es „Abbrechen“ und „Erneut versuchen“; „Abbrechen“ ruft `cancel()`.
  - 400 × 400 hoch und 740 × 360 quer mit der längsten Meldung ohne Overflow.
- [x] 2.2 README, Abschnitt Pulsgurt: Puls vom Rudergerät ohne Gurtversuch, „Abbrechen“ und Abbruch nach 60 Sekunden. Verifikation: der Abschnitt widerspricht der Spec nicht.

## 3. Abschluss

- [ ] 3.1 Gesamtprüfung in der Linux-App mit Scratch-DB, Simulator (FTMS) und gekoppeltem Test-Gurt, soweit ohne echtes Gerät möglich (z. B. mit einem Gurt-Transport, der scheitert): Meldung mit beiden Knöpfen, Abbrechen, Ablauf nach 60 s. Verifikation: Screenshots; `make check` grün.
- [ ] 3.2 Am Woodrower (Nutzer): Gurt am Rudergerät gekoppelt, in der App ebenfalls gekoppelt; keine Meldung, Herz grün, Puls läuft. Danach Gurt vom Rudergerät trennen und an einer Uhr verbinden: Meldung, „Abbrechen“ und Ablauf nach 60 s.
