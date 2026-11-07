# Spec Delta

## MODIFIED Requirements

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

### Requirement: Wanduhr-Zeitachse aufzeichnen
Die App SHALL zu jedem gespeicherten Messwert einer Session zusätzlich zur Zeit des PM5 die seit Session-Beginn vergangene Wanduhr-Zeit und die Sessionzeit speichern. Die Wanduhr-Zeit MUST auch dann weiterlaufen, wenn der PM5 seine Uhr anhält oder die Session pausiert. Die Sessionzeit ist die Wanduhr-Zeit ohne die Pausen der Session; sie MUST unabhängig davon sein, ob der PM5 seine Uhr anhält.

#### Scenario: Pause in einer Session
- **WHEN** der Nutzer nach 2 Minuten Rudern 30 Sekunden stillsitzt und dann weiterrudert
- **THEN** zeigt der nächste Messwert eine Wanduhr-Zeit von etwa 2:30 und eine Sessionzeit, die nur die Zeit bis zum Beginn der Pause enthält

#### Scenario: Bestehende Sessions nach dem Update
- **WHEN** die App mit Sessions aus einer früheren Version aktualisiert wird
- **THEN** bleiben diese Sessions mit Zusammenfassung, Verlauf und Replay erhalten, mit ihrer bisherigen Dauer und ohne Pausen

## ADDED Requirements

### Requirement: Session pausiert, wenn nicht gerudert wird
Bleibt während einer laufenden Session der nächste Ruderschlag aus, SHALL die Session pausieren, sobald 3 s seit dem Zeitpunkt vergangen sind, an dem er im Rhythmus der letzten Schläge fällig gewesen wäre. Ein langsamer Rhythmus allein MUST keine Pause auslösen. In der Pause MUST die Sessionzeit stillstehen; die Zeit bis zum Beginn der Pause zählt zur Session. Das gilt für freies Rudern und Vorlagen, für PM5 und FTMS-Rudergeräte.

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
