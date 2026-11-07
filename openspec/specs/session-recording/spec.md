# session-recording Specification

## Purpose

Zeichnet Rudersessions lokal auf dem Gerät auf, mit Zusammenfassung und vollständigem Datenverlauf. Darauf bauen Historie, Replay und später Ghost und Progression auf.

## Requirements

### Requirement: Session starten und beenden
Der Nutzer SHALL eine Session in der App starten und beenden können, solange eine Datenquelle verbunden ist. Distanz und Zeit der Session MUST ab dem Start der Session zählen, unabhängig vom Stand der Anzeige am Rudergerät. Bei freiem Rudern startet die Session mit „Session starten“, mit einem Workout erst mit dem ersten Ruderschlag.

#### Scenario: Session starten
- **WHEN** der Nutzer mit verbundenem PM5 „Session starten“ wählt, während der PM5 bereits 500 m anzeigt
- **THEN** beginnt die Session bei 0 m und 0:00

#### Scenario: Session mit FTMS-Rudergerät starten
- **WHEN** der Nutzer mit verbundenem FTMS-Rudergerät „Session starten“ wählt, während das Gerät bereits 800 m meldet
- **THEN** beginnt die Session bei 0 m und 0:00

#### Scenario: Session beenden
- **WHEN** der Nutzer „Session beenden“ wählt
- **THEN** wird die Session gespeichert und ihre Zusammenfassung angezeigt

#### Scenario: Workout gewählt
- **WHEN** der Nutzer ein Workout wählt und die Datenquelle verbunden ist
- **THEN** ist die Session bereit, aber noch nicht gestartet

### Requirement: Geräte-Reset während einer Session überstehen
Setzt das Rudergerät während einer laufenden Session Zeit oder Distanz zurück, SHALL die Session ohne Rücksprung weiterzählen. Das gilt für den PM5 und für FTMS-Rudergeräte.

#### Scenario: Neues Workout am PM5 mitten in der Session
- **WHEN** die Session bei 1200 m steht und der Nutzer am PM5 ein neues Workout startet
- **THEN** zählt die Session ab 1200 m weiter, sobald wieder gerudert wird

#### Scenario: FTMS-Rudergerät setzt die Distanz zurück
- **WHEN** die Session bei 1200 m steht und das FTMS-Rudergerät plötzlich 0 m meldet
- **THEN** zählt die Session ab 1200 m weiter, sobald wieder gerudert wird

### Requirement: Session vollständig speichern
Die App SHALL zu jeder Session eine Zusammenfassung (Startzeitpunkt, Dauer, Distanz, Durchschnittspace, Durchschnittswatt, Durchschnittsschlagzahl, Anzahl Schläge, Anzahl und Gesamtdauer der Pausen, Durchschnitts- und Maximalpuls falls vorhanden, Datenquelle, Geräteart) sowie den zeitlichen Verlauf aller Messwerte, RR-Intervalle und Schlag-Ereignisse lokal speichern. Schlagdetails, die das Gerät nicht liefert, MUST als „nicht vorhanden“ gespeichert werden. Dauer, Durchschnittspace und Durchschnittsschlagzahl MUST auf der Sessionzeit ohne Pausen beruhen.

#### Scenario: Session nach App-Neustart
- **WHEN** der Nutzer eine Session beendet und die App neu startet
- **THEN** ist die Session mit Zusammenfassung und Verlauf weiterhin vorhanden

#### Scenario: Session mit FTMS-Rudergerät
- **WHEN** der Nutzer eine Session mit einem FTMS-Rudergerät mit 120 Schlägen beendet
- **THEN** zeigt die Zusammenfassung 120 Schläge und das Gerät als FTMS-Rudergerät, und die gespeicherten Schläge haben keine Durchzugs- und Kraftwerte

#### Scenario: Session mit Puls
- **WHEN** der Nutzer eine Session mit Puls beendet, ob vom Gurt oder vom Rudergerät
- **THEN** zeigt die Zusammenfassung Durchschnitts- und Maximalpuls als ganze Schläge pro Minute

#### Scenario: Session ohne Puls
- **WHEN** der Nutzer eine Session ohne Puls beendet
- **THEN** zeigt die Zusammenfassung keine Pulswerte statt 0

#### Scenario: Bestehende Sessions nach dem Update
- **WHEN** die App mit Sessions aus einer früheren Version auf diese Version aktualisiert wird
- **THEN** sind alle Sessions mit Zusammenfassung, Verlauf, vollständigen Schlagdetails und Replay weiterhin vorhanden, gelten als PM5-Sessions, sofern sie mit einem PM5 aufgezeichnet wurden, und haben keine Pulszusammenfassung

#### Scenario: Zusammenfassung mit Pausen
- **WHEN** der Nutzer 10 Minuten rudert und dazwischen zweimal je etwa eine Minute stillsitzt
- **THEN** zeigt die Zusammenfassung eine Dauer von etwa 10 Minuten und 2 Pausen mit ihrer Gesamtdauer

#### Scenario: Session ohne Pause
- **WHEN** der Nutzer ohne Unterbrechung rudert
- **THEN** zeigt die Zusammenfassung keine Pausen

### Requirement: Session bei Abbruch nicht verlieren
Bricht die Verbindung ab oder wird die App unerwartet beendet, SHALL die bis dahin aufgezeichnete Session erhalten bleiben.

#### Scenario: App stürzt während der Session ab
- **WHEN** die App nach 10 Minuten Session unerwartet beendet wird
- **THEN** ist nach dem Neustart eine Session mit den Daten bis kurz vor dem Abbruch vorhanden und als unvollständig gekennzeichnet

### Requirement: Rohdaten für Replay speichern
Für Sessions mit einem echten Rudergerät SHALL die App die empfangenen Rohdaten des Rudergeräts und eines direkt verbundenen Gurts mit Zeitstempel auf einer gemeinsamen Zeitachse und mit dem Protokoll des Rudergeräts (PM5 oder FTMS) speichern, sodass die Session später exakt wieder abgespielt werden kann.

#### Scenario: Replay einer echten Session
- **WHEN** eine mit einem echten PM5 aufgezeichnete Session abgespielt wird
- **THEN** ergeben sich dieselben Messwerte wie bei der Aufzeichnung

#### Scenario: Replay einer FTMS-Session
- **WHEN** eine mit einem FTMS-Rudergerät aufgezeichnete Session abgespielt wird
- **THEN** werden die Rohdaten als FTMS-Daten gelesen und ergeben dieselben Messwerte wie bei der Aufzeichnung

#### Scenario: Replay einer Session mit direkt verbundenem Gurt
- **WHEN** eine Session abgespielt wird, bei der ein Gurt direkt verbunden war, ob mit PM5 oder FTMS-Rudergerät
- **THEN** ergeben sich derselbe Puls und dieselben RR-Intervalle wie bei der Aufzeichnung

#### Scenario: Export und Import mit Gurt-Daten
- **WHEN** eine Session mit direkt verbundenem Gurt exportiert und auf einem anderen Gerät importiert wird
- **THEN** zeigt die importierte Session denselben Puls, dieselben RR-Intervalle und dieselbe Zusammenfassung

### Requirement: Sessions auflisten
Die App SHALL eine Liste aller gespeicherten Sessions anzeigen, neueste zuerst, mit Datum, Dauer, Distanz und Durchschnittspace.

#### Scenario: Mehrere Sessions vorhanden
- **WHEN** der Nutzer die Session-Liste öffnet
- **THEN** sieht er alle Sessions, die neueste oben

### Requirement: Session löschen
Der Nutzer SHALL eine gespeicherte Session nach einer Bestätigung löschen können.

#### Scenario: Session löschen
- **WHEN** der Nutzer eine Session löschen will und bestätigt
- **THEN** ist die Session samt Verlauf und Rohdaten entfernt

### Requirement: Session als Datei exportieren
Die App SHALL eine Session inklusive Rohdaten und Protokoll als Datei exportieren und eine solche Datei wieder importieren können, damit Aufnahmen zwischen Geräten und als Testdaten weitergegeben werden können. Dateien ohne Protokollangabe MUST als PM5-Aufnahmen gelesen werden.

#### Scenario: Export und Import
- **WHEN** der Nutzer eine Session auf dem Handy exportiert und auf dem Laptop importiert
- **THEN** ist sie auf dem Laptop in der Liste und kann abgespielt werden

#### Scenario: Import einer FTMS-Session
- **WHEN** der Nutzer eine exportierte FTMS-Session importiert
- **THEN** werden Messwerte und Zusammenfassung aus den FTMS-Rohdaten neu berechnet und stimmen mit dem Original überein

#### Scenario: Import einer älteren Datei
- **WHEN** der Nutzer eine Datei importiert, die vor dieser Version exportiert wurde und kein Protokoll angibt
- **THEN** wird sie als PM5-Aufnahme gelesen und wie bisher importiert

### Requirement: Wanduhr-Zeitachse aufzeichnen
Die App SHALL zu jedem gespeicherten Messwert einer Session zusätzlich zur Zeit des PM5 die seit Session-Beginn vergangene Wanduhr-Zeit und die Sessionzeit speichern. Die Wanduhr-Zeit MUST auch dann weiterlaufen, wenn der PM5 seine Uhr anhält oder die Session pausiert. Die Sessionzeit ist die Wanduhr-Zeit ohne die Pausen der Session; sie MUST unabhängig davon sein, ob der PM5 seine Uhr anhält.

#### Scenario: Pause in einer Session
- **WHEN** der Nutzer nach 2 Minuten Rudern 30 Sekunden stillsitzt und dann weiterrudert
- **THEN** zeigt der nächste Messwert eine Wanduhr-Zeit von etwa 2:30 und eine Sessionzeit, die nur die Zeit bis zum Beginn der Pause enthält

#### Scenario: Bestehende Sessions nach dem Update
- **WHEN** die App mit Sessions aus einer früheren Version aktualisiert wird
- **THEN** bleiben diese Sessions mit Zusammenfassung, Verlauf und Replay erhalten, mit ihrer bisherigen Dauer und ohne Pausen

### Requirement: Session eines Workouts zuordnen
Eine Session, die mit einem Workout gestartet wurde, SHALL mit dem Workout und der geruderten Version ihrer Strecke verknüpft sein. Die Session-Liste MUST bei solchen Sessions den Namen des Workouts anzeigen.

#### Scenario: Liste mit Workout-Session
- **WHEN** der Nutzer die Session-Liste öffnet und eine Session mit dem Workout „Seerunde x3“ gerudert hat
- **THEN** zeigt der Eintrag „Seerunde x3“ zusätzlich zu Datum, Dauer, Distanz und Pace

#### Scenario: Workout später gelöscht
- **WHEN** das Workout einer Session gelöscht wurde
- **THEN** zeigt die Session weiterhin den Namen des Workouts und der Strecke, mit dem sie gerudert wurde

### Requirement: Kraftkurve aufzeichnen
Die App SHALL die Kurvenpakete einer Session als Rohdaten mitspeichern, exportieren und importieren. Ein Replay MUST die Kraftkurve so zeigen wie während der Aufnahme.

#### Scenario: Replay mit Kraftkurve
- **WHEN** der Nutzer eine mit dem PM5 aufgezeichnete Session abspielt
- **THEN** zeigt das Live-Display die Kraftkurven der Schläge wie bei der Aufnahme

#### Scenario: Export und Import
- **WHEN** der Nutzer eine Session mit Kraftkurven exportiert und wieder importiert
- **THEN** zeigt das Replay der importierten Session dieselben Kurven

### Requirement: RR-Intervalle in der Zusammenfassung
Enthält eine Session RR-Intervalle, SHALL die Zusammenfassung ihren Verlauf über die Session als Kurve sowie die Herzratenvariabilität als RMSSD in ganzen Millisekunden zeigen. Ohne RR-Intervalle MUST NOT Kurve oder RMSSD erscheinen.

#### Scenario: Session mit RR-Intervallen
- **WHEN** der Nutzer eine Session beendet, bei der der Gurt RR-Intervalle gesendet hat
- **THEN** zeigt die Zusammenfassung die RR-Kurve und den RMSSD-Wert

#### Scenario: RMSSD-Berechnung
- **WHEN** eine Session die RR-Intervalle 800, 810 und 790 ms enthält
- **THEN** beträgt der RMSSD 16 ms (Wurzel aus dem Mittel von 10² und 20²)

#### Scenario: Puls nur über das Rudergerät
- **WHEN** der Nutzer eine Session beendet, bei der der Puls nur vom Rudergerät kam
- **THEN** zeigt die Zusammenfassung Durchschnitts- und Maximalpuls, aber weder RR-Kurve noch RMSSD

### Requirement: Session-Dateien unter dem neuen Namen
Exportierte Sessions SHALL die Endung `.strokesplit` und den Formatnamen `strokesplit-raw` tragen. Der Import MUST weiterhin Dateien mit der Endung `.aergrow` und dem Formatnamen `aergrow-raw` annehmen und daraus dieselbe Session erzeugen wie vor der Umbenennung.

#### Scenario: Export nach der Umbenennung
- **WHEN** der Nutzer eine Session exportiert
- **THEN** heisst die Datei `….strokesplit` und ihr Header nennt das Format `strokesplit-raw`

#### Scenario: Alten Export importieren
- **WHEN** der Nutzer eine vor der Umbenennung exportierte `.aergrow`-Datei importiert
- **THEN** erscheint die Session mit denselben Werten wie vor der Umbenennung

### Requirement: Lokale Daten nach der Umbenennung
Findet die App beim Start keine Datenbank unter dem neuen Namen, aber eine unter dem alten am selben Ort, SHALL sie diese übernehmen, sodass alle Sessions, Strecken und Workouts erhalten bleiben.

#### Scenario: Update auf dem Linux-Desktop
- **WHEN** der Nutzer auf dem Linux-Desktop die umbenannte Version zum ersten Mal startet
- **THEN** zeigt sie alle Sessions, Strecken und Workouts der bisherigen Version

### Requirement: Session mit Workout startet mit dem ersten Schlag
Eine bereite Session mit Workout SHALL mit der ersten Bewegung starten: wenn die Distanz steigt oder ein Ruderschlag gemeldet wird, je nachdem, was zuerst kommt. Bis dahin MUST keine Zeit laufen. Nullpunkt von Zeit, Distanz und Wanduhr MUST der letzte Messwert vor der ersten Bewegung sein, damit vom ersten Schlag nichts verloren geht. Eine Schlagzahl, die der Monitor aus einer früheren Fahrt noch anzeigt, ist keine Bewegung.

#### Scenario: Warten vor dem ersten Schlag
- **WHEN** der Nutzer „Seerunde x3“ wählt und eine Minute lang nicht rudert
- **THEN** zeigt die Session 0:00 und 0 m, Runde 1 und der Ghost stehen am Start

#### Scenario: Erster Schlag
- **WHEN** der PM5 nach der Wahl des Workouts 0 m zeigt und der Nutzer den ersten Schlag rudert
- **THEN** startet die Session, und ihre Distanz und Zeit enthalten den ganzen ersten Schlag

#### Scenario: Zeitstrecke
- **WHEN** der Nutzer ein Workout mit einem Abschnitt von 4 Minuten wählt und 30 Sekunden nach der Wahl zu rudern beginnt
- **THEN** endet der Abschnitt 4 Minuten nach dem ersten Schlag

#### Scenario: Monitor zeigt noch eine frühere Fahrt
- **WHEN** der PM5 nach einer Pause noch 288 m und 28 Schläge pro Minute anzeigt und der Nutzer ein Workout wählt
- **THEN** bleibt die Session bereit, bis die Distanz steigt oder ein neuer Schlag gemeldet wird, und beginnt dann bei 0 m und 0:00

#### Scenario: Replay
- **WHEN** eine Session mit Workout, die mit dem ersten Schlag gestartet wurde, abgespielt oder importiert wird
- **THEN** ergeben sich dieselben Messwerte, Runden und Abschnitte wie bei der Aufzeichnung

### Requirement: Bereite Session abbrechen
Trennt der Nutzer die Verbindung oder beendet er die Session, bevor sie mit dem ersten Schlag gestartet ist, SHALL keine Session gespeichert werden.

#### Scenario: Trennen vor dem ersten Schlag
- **WHEN** der Nutzer ein Workout wählt und vor dem ersten Schlag trennt
- **THEN** erscheint keine neue Session in der Liste

### Requirement: Session pausiert, wenn nicht gerudert wird
Bleibt während einer laufenden Session der nächste Ruderschlag aus, SHALL die Session pausieren, sobald 3 s seit dem Zeitpunkt vergangen sind, an dem er im Rhythmus der letzten Schläge fällig gewesen wäre. Ein langsamer Rhythmus allein MUST keine Pause auslösen. In der Pause MUST die Sessionzeit stillstehen; die Zeit bis zum Beginn der Pause zählt zur Session. Das gilt für freies Rudern und Workouts, für PM5 und FTMS-Rudergeräte.

#### Scenario: Aufhören zu rudern
- **WHEN** der Nutzer mit 24 Schlägen pro Minute rudert und dann aufhört
- **THEN** pausiert die Session 3 s nach dem Zeitpunkt, an dem der nächste Schlag fällig gewesen wäre, und die Sessionzeit steht still

#### Scenario: Langsam rudern
- **WHEN** der Nutzer gleichmässig mit 16 Schlägen pro Minute rudert
- **THEN** pausiert die Session nicht

#### Scenario: Monitor lässt seine Uhr weiterlaufen
- **WHEN** der Nutzer stillsitzt und der Monitor seine eigene Zeit weiterzählt oder anhält
- **THEN** steht die Sessionzeit in beiden Fällen ab dem Beginn der Pause still

#### Scenario: Freie Session vor dem ersten Schlag
- **WHEN** der Nutzer bei freiem Rudern „Session starten“ wählt und erst 20 Sekunden später zu rudern beginnt
- **THEN** pausiert die Session nach 3 Sekunden und läuft mit dem ersten Schlag weiter

### Requirement: Session läuft mit dem nächsten Schlag weiter
Ist die Session pausiert, SHALL sie mit dem nächsten Ruderschlag weiterlaufen, und die Sessionzeit MUST ab dem Stand vor der Pause weiterzählen. Meldet der Monitor den letzten Schlag vor dem Stillsitzen erst nach Beginn der Pause, MUST die Session pausiert bleiben.

#### Scenario: Weiterrudern
- **WHEN** die Session pausiert ist und der Nutzer wieder zu rudern beginnt
- **THEN** läuft die Sessionzeit mit dem ersten Schlag ab dem Stand vor der Pause weiter

#### Scenario: Monitor meldet den letzten Schlag verspätet
- **WHEN** der PM5 den letzten Schlag vor dem Stillsitzen erst meldet, nachdem die Session pausiert ist
- **THEN** bleibt die Session pausiert

### Requirement: Pausen speichern
Die App SHALL jede Pause einer Session mit Beginn und Ende auf der Wanduhr speichern. Eine Pause, die beim Beenden der Session noch andauert, MUST nicht als Pause zählen; die Session endet mit dem Stand vor der Pause. Wird eine Session importiert oder abgespielt, MUST die App die Pausen aus den Rohdaten genauso erkennen wie bei der Aufzeichnung.

#### Scenario: Pause gespeichert
- **WHEN** der Nutzer in einer Session einmal 45 Sekunden stillsitzt und danach weiterrudert
- **THEN** ist zu der Session eine Pause mit Beginn und Ende gespeichert

#### Scenario: Aufhören und dann beenden
- **WHEN** der Nutzer aufhört zu rudern und eine Minute später „Session beenden“ wählt
- **THEN** zeigt die Zusammenfassung keine Pause und die Dauer endet mit dem Beginn der Pause

#### Scenario: Export und Import
- **WHEN** eine Session mit zwei Pausen exportiert und wieder importiert wird
- **THEN** hat die importierte Session dieselben zwei Pausen und dieselbe Dauer

#### Scenario: Import einer Session ohne Stillstand
- **WHEN** eine Datei aus einer früheren Version importiert wird, in der ohne Unterbrechung gerudert wurde
- **THEN** ergibt die importierte Session dieselbe Distanz und dieselben Runden wie vor diesem Change, keine Pausen und eine Dauer, die höchstens um ein Messintervall von der bisherigen abweicht

### Requirement: Geplante Dauer speichern
Eine Session mit Gesamtdauer SHALL die geplante Dauer speichern. Der Export als Datei MUST sie enthalten, und der Import MUST sie wiederherstellen. Eine Datei ohne geplante Dauer MUST weiterhin importierbar sein.

#### Scenario: Export und Import
- **WHEN** der Nutzer eine Session mit 30 min auf „Seerunde“ exportiert und wieder importiert
- **THEN** zeigt die importierte Session „Seerunde · 30 min“ und dieselben Runden

#### Scenario: Ältere Datei
- **WHEN** der Nutzer eine Datei importiert, die vor diesem Change exportiert wurde
- **THEN** wird sie wie bisher importiert, ohne geplante Dauer

### Requirement: Session ohne Workout in der Liste
Die Session-Liste SHALL eine Session ohne Workout auf einer Strecke mit dem Namen der Strecke und der geplanten Länge zeigen: Rundenzahl, Dauer oder „offen“.

#### Scenario: Dauer in der Liste
- **WHEN** der Nutzer 30 min auf „Seerunde“ ohne Workout gerudert hat und die Session-Liste öffnet
- **THEN** zeigt der Eintrag „Seerunde · 30 min“
