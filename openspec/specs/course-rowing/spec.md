# course-rowing Specification

## Purpose

Begleitet das Rudern einer Vorlage: Die App zählt Runden und Segmente, zeigt im Boot, ob Pace und Schlagzahl in der Zone liegen, und speichert pro Runde und Segment vergleichbare Ergebnisse. Diese Runden sind die Datengrundlage für den späteren Ghost.

## Requirements

### Requirement: Fortschritt nach Sessionzeit messen
Beim Rudern einer Vorlage SHALL der Fortschritt einer Zeitstrecke nach der Sessionzeit gemessen werden, also nach Wanduhr ohne die Pausen der Session, unabhängig davon, ob der PM5 seine Uhr anhält. Rundenzeiten und Abschnittszeiten MUST ebenfalls nach der Sessionzeit gemessen werden und die Pausen damit nicht enthalten.

#### Scenario: Pause in einer Distanzrunde
- **WHEN** der Nutzer in einer 1000-m-Runde rudert und dabei 30 Sekunden stillsitzt
- **THEN** enthält die Rundenzeit die Zeit bis zum Beginn der Pause, aber nicht die Pause

#### Scenario: Pause in einer Zeitrunde
- **WHEN** der Nutzer in einer 4-min-Runde nach 3 Minuten aufhört, 30 Sekunden stillsitzt und weiterrudert
- **THEN** steht die Restzeit der Runde in der Pause still, und die Runde endet nach 4 Minuten Sessionzeit

#### Scenario: Ältere Session in der Rangliste
- **WHEN** eine Session aus einer früheren Version mit einer Pause in der Rangliste steht
- **THEN** zählt ihre Runde weiter mit der gespeicherten Zeit einschliesslich der Pause

### Requirement: Runden fortlaufend zählen
Die App SHALL eine Runde beenden, sobald die Länge der Strecke erreicht ist, und die nächste Runde unmittelbar anschliessen. Die Rundengrenze MUST zwischen zwei Messpunkten auf die exakte Streckenlänge interpoliert werden, und Überschuss MUST der nächsten Runde zugerechnet werden.

#### Scenario: Grenze zwischen zwei Messpunkten
- **WHEN** ein Messpunkt bei 998 m nach 3:59.0 und der nächste bei 1003 m nach 4:00.0 liegt
- **THEN** endet Runde 1 bei 1000 m nach 3:59.4 und Runde 2 beginnt bei 1000 m

#### Scenario: Offene Rundenzahl
- **WHEN** eine Vorlage mit offener Rundenzahl gerudert wird
- **THEN** folgt auf jede Runde eine weitere, bis der Nutzer die Session beendet

### Requirement: Nach der letzten Runde beenden
Bei einer festen Rundenzahl SHALL die Session nach dem Ende der letzten Runde automatisch beendet und die Zusammenfassung angezeigt werden.

#### Scenario: Drei Runden geschafft
- **WHEN** der Nutzer bei „Seerunde x3“ die dritte Runde beendet
- **THEN** endet die Session und die Zusammenfassung mit drei Rundenzeiten erscheint

### Requirement: Angefangene Runde beim Beenden
Beendet der Nutzer die Session mitten in einer Runde, SHALL die angefangene Runde als unvollständig gespeichert werden. Eine unvollständige Runde MUST in der Zusammenfassung erkennbar sein und darf nicht als Rundenzeit oder Bestzeit zählen.

#### Scenario: Mitten in Runde 2 beendet
- **WHEN** der Nutzer bei 1400 m auf einer 1000-m-Strecke „Session beenden“ wählt
- **THEN** zeigt die Zusammenfassung Runde 1 mit ihrer Zeit und Runde 2 als unvollständig mit 400 m

### Requirement: Runde und Segment live anzeigen
Beim Rudern einer Vorlage SHALL das Live-Display die aktuelle Runde (bei fester Zahl als „Runde 2 / 3“), den aktuellen Abschnitt mit dem Namen seiner Zone bzw. „frei“, die Restdistanz bzw. Restzeit bis zum Abschnittsende und die Zielbänder der Zone anzeigen.

#### Scenario: Mitten in der Zone Tempo
- **WHEN** der Nutzer in Runde 2 von 3 bei 520 m in der Zone „Tempo“ von 200 bis 800 m mit Band 2:05–2:10 rudert
- **THEN** zeigt das Display „Runde 2 / 3“, „Tempo“, „280 m“ bis zum Abschnittsende und „2:05–2:10“

#### Scenario: Freier Abschnitt
- **WHEN** der Nutzer bei 300 m einer Strecke rudert, in der die erste Zone bei 500 m beginnt
- **THEN** zeigt das Display „frei“ und „200 m“ bis zum Abschnittsende

#### Scenario: Zone nur mit Stufe
- **WHEN** der Nutzer bei 700 m in der Zone „Kraft“ von 500 bis 1000 m rudert, die nur Stufe 12 und kein Band hat
- **THEN** zeigt das Display „Kraft“ statt „frei“ und „300 m“ bis zum Abschnittsende, aber kein Zielband

### Requirement: Zonenstatus anzeigen
Hat das aktuelle Segment ein Band, SHALL das Live-Display für Pace bzw. Schlagzahl sichtbar anzeigen, ob der aktuelle Wert im Band liegt. Liegt er ausserhalb, MUST die Anzeige die Richtung zeigen: schneller oder langsamer bzw. mehr oder weniger Schläge.

#### Scenario: Zu langsam
- **WHEN** das Band 2:05–2:10 ist und die aktuelle Pace 2:13.0 beträgt
- **THEN** ist die Pace als ausserhalb markiert mit dem Hinweis „schneller“

#### Scenario: Im Band
- **WHEN** die Pace 2:07.5 und die Schlagzahl 21 bei Bändern 2:05–2:10 und 20–22 betragen
- **THEN** sind beide Werte als in der Zone markiert

#### Scenario: Freies Segment
- **WHEN** das aktuelle Segment kein Band hat
- **THEN** zeigt das Display keine Zonenmarkierung

### Requirement: Anteil in der Zone zählen
Für jedes Segment mit mindestens einem Band SHALL die App den Anteil der Sessionzeit messen, in dem alle gesetzten Bänder gleichzeitig eingehalten wurden. Zeit ohne gültigen Messwert ausserhalb einer Pause MUST als ausserhalb der Zone zählen. Die Pausen der Session MUST weder als innerhalb noch als ausserhalb zählen. Das Live-Display SHALL den laufenden Anteil der aktuellen Runde anzeigen.

#### Scenario: Teilweise in der Zone
- **WHEN** der Nutzer ein 60-Sekunden-Segment 45 Sekunden lang in beiden Bändern rudert
- **THEN** beträgt der Anteil in der Zone für dieses Segment 75 %

#### Scenario: Pause im Segment
- **WHEN** der Nutzer in einem Segment mit Band 30 Sekunden stillsitzt
- **THEN** zählt die Pause nicht zum Anteil in der Zone, nur die Zeit bis zum Beginn der Pause

#### Scenario: Zone nur mit Stufe
- **WHEN** der Nutzer eine Runde rudert, deren einzige Zone „Kraft“ nur Stufe 12 und kein Band hat
- **THEN** hat weder das Segment noch die Runde einen Anteil in der Zone

### Requirement: Runden- und Segmentergebnisse speichern
Die App SHALL pro Runde Beginn, Ende, Dauer, Distanz, Status (vollständig oder unvollständig) und Anteil in der Zone speichern und pro Segment einer Runde Dauer, Distanz und Anteil in der Zone. Die Ergebnisse MUST eine App-Beendigung während der Session so überstehen wie die übrige Aufzeichnung.

#### Scenario: Nach App-Neustart
- **WHEN** der Nutzer eine Session mit drei Runden beendet und die App neu startet
- **THEN** sind alle drei Runden mit ihren Segmentergebnissen vorhanden

#### Scenario: Absturz in Runde 3
- **WHEN** die App in Runde 3 unerwartet beendet wird
- **THEN** sind nach dem Neustart Runde 1 und 2 vollständig und Runde 3 als unvollständig gespeichert

### Requirement: Zusammenfassung mit Runden
Die Zusammenfassung einer Session auf einer Vorlage SHALL Vorlage, Strecke und alle Runden mit ihrer Zeit (Distanzstrecke) bzw. Distanz (Zeitstrecke) und ihrem Anteil in der Zone zeigen. Die beste vollständige Runde MUST hervorgehoben sein.

#### Scenario: Drei Runden auf Distanz
- **WHEN** die Runden 4:12, 4:08 und 4:15 dauerten
- **THEN** zeigt die Zusammenfassung alle drei Zeiten und hebt 4:08 hervor

#### Scenario: Zeitstrecke
- **WHEN** auf einer 4-min-Strecke 1012 m, 1030 m und 998 m gerudert wurden
- **THEN** zeigt die Zusammenfassung die drei Distanzen und hebt 1030 m hervor

### Requirement: Export und Import einer Vorlagen-Session
Wird eine Session auf einer Vorlage exportiert und wieder importiert, SHALL sie dieselben Runden- und Segmentergebnisse ergeben wie bei der Aufzeichnung. Fehlt beim Import die passende Strecke, MUST die Strecke in der gespeicherten Version aus der Datei angelegt werden.

#### Scenario: Export und Import
- **WHEN** eine Session „Seerunde x3“ auf dem Handy exportiert und auf dem Laptop importiert wird, wo es die Strecke nicht gibt
- **THEN** zeigt die importierte Session dieselben drei Rundenzeiten und die Strecke „Seerunde“ ist auf dem Laptop vorhanden

### Requirement: Strecke ohne Vorlage rudern
Eine Session, die ohne Vorlage auf einer Strecke läuft, SHALL Runden, Abschnitte, Zonenstatus, Anteil in der Zone und Ergebnisse genauso messen, anzeigen und speichern wie eine Session auf einer Vorlage mit dieser Strecke. Ihre vollständigen Runden und Zonenfahrten MUST in den Ranglisten von Strecke und Zone zählen.

#### Scenario: Drei Runden ohne Vorlage
- **WHEN** der Nutzer „Seerunde“ ohne Vorlage mit 3 Runden rudert
- **THEN** zeigt das Live-Display „Runde 2 von 3“ und den aktuellen Abschnitt, und die Session endet nach der dritten Runde

#### Scenario: Rangliste der Strecke
- **WHEN** der Nutzer „Seerunde“ ohne Vorlage rudert und eine Runde in 4:05 schafft, schneller als alle bisherigen
- **THEN** steht diese Runde auf Platz 1 der Rangliste von „Seerunde“

### Requirement: Nach der Gesamtdauer beenden
Bei einer Session mit Gesamtdauer SHALL die App die Session automatisch beenden, sobald die Ruderzeit ohne Pausen die Dauer erreicht, und die Zusammenfassung zeigen. Liegt das Ende mitten in einer Runde, MUST diese Runde als unvollständig gespeichert werden.

#### Scenario: Ende mitten in der Runde
- **WHEN** der Nutzer 30 min auf „Seerunde“ rudert und nach 30 min Ruderzeit in Runde 8 bei 1.3 km von 2.4 km ist
- **THEN** endet die Session, Runde 8 ist unvollständig, und die Zusammenfassung erscheint

#### Scenario: Pause zählt nicht
- **WHEN** der Nutzer bei 30 min Dauer nach 20 min Ruderzeit 2 min pausiert
- **THEN** endet die Session erst nach weiteren 10 min Ruderzeit

#### Scenario: Zeitstrecke mit Gesamtdauer
- **WHEN** der Nutzer die Zeitstrecke „Vier Minuten“ 30 min lang rudert
- **THEN** sind 7 Runden vollständig und Runde 8 nach 2 min unvollständig

### Requirement: Gesamtdauer live anzeigen
Bei einer Session mit Gesamtdauer SHALL der äussere Ring des Fortschrittsrahmens den Anteil der Ruderzeit an der Dauer zeigen, ohne Rundengrenzen. Das Live-Display MUST die verbleibende Ruderzeit zeigen und die Runde ohne Gesamtzahl, etwa „Runde 3“.

#### Scenario: Halbzeit
- **WHEN** der Nutzer bei 30 min Dauer 15 min gerudert hat
- **THEN** ist der äussere Ring zur Hälfte gefüllt, und das Live-Display zeigt 15:00 verbleibend

### Requirement: Zusammenfassung ohne Vorlage
Die Zusammenfassung einer Session ohne Vorlage auf einer Strecke SHALL statt der Vorlage die Strecke und die geplante Länge nennen: die Rundenzahl, die Dauer oder „offen“. Sie MUST alle Runden wie bei einer Vorlage zeigen und keine Platzmarke für eine Vorlage.

#### Scenario: 30 min auf der Seerunde
- **WHEN** der Nutzer die Zusammenfassung einer Session mit 30 min auf „Seerunde“ öffnet
- **THEN** steht dort „Seerunde · 30 min“ mit allen Runden, die letzte als unvollständig markiert
