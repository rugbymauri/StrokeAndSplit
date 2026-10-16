# course-rowing Specification

## Purpose

Begleitet das Rudern einer Vorlage: Die App zählt Runden und Segmente, zeigt im Boot, ob Pace und Schlagzahl in der Zone liegen, und speichert pro Runde und Segment vergleichbare Ergebnisse. Diese Runden sind die Datengrundlage für den späteren Ghost.

## Requirements

### Requirement: Fortschritt nach Wanduhr messen
Beim Rudern einer Vorlage SHALL der Fortschritt einer Zeitstrecke nach Wanduhr gemessen werden, einschliesslich Pausen, in denen der PM5 seine Uhr anhält. Rundenzeiten von Distanzstrecken MUST ebenfalls Pausen enthalten.

#### Scenario: Pause in einer Distanzrunde
- **WHEN** der Nutzer eine 1000-m-Runde in 4:00 Ruderzeit rudert und dabei 30 Sekunden pausiert
- **THEN** ist die Rundenzeit 4:30

#### Scenario: Pause in einer Zeitrunde
- **WHEN** der Nutzer in einer 4-min-Runde nach 3 Minuten 30 Sekunden pausiert und weiterrudert
- **THEN** endet die Runde 4 Minuten nach ihrem Beginn und die Rundendistanz enthält nur die geruderten Meter

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
Beim Rudern einer Vorlage SHALL das Live-Display die aktuelle Runde (bei fester Zahl als „Runde 2 von 3“), den aktuellen Abschnitt mit dem Namen seiner Zone bzw. „frei“, die Restdistanz bzw. Restzeit bis zum Abschnittsende und die Zielbänder der Zone anzeigen.

#### Scenario: Mitten in der Zone Tempo
- **WHEN** der Nutzer in Runde 2 von 3 bei 520 m in der Zone „Tempo“ von 200 bis 800 m mit Band 2:05–2:10 rudert
- **THEN** zeigt das Display „Runde 2 von 3“, „Tempo“, „280 m“ bis zum Abschnittsende und „2:05–2:10“

#### Scenario: Freier Abschnitt
- **WHEN** der Nutzer bei 300 m einer Strecke rudert, in der die erste Zone bei 500 m beginnt
- **THEN** zeigt das Display „frei“ und „200 m“ bis zum Abschnittsende

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
Für jedes Segment mit mindestens einem Band SHALL die App den Anteil der Zeit messen, in dem alle gesetzten Bänder gleichzeitig eingehalten wurden. Zeit ohne gültigen Messwert, etwa in einer Pause, MUST als ausserhalb der Zone zählen. Das Live-Display SHALL den laufenden Anteil der aktuellen Runde anzeigen.

#### Scenario: Teilweise in der Zone
- **WHEN** der Nutzer ein 60-Sekunden-Segment 45 Sekunden lang in beiden Bändern rudert
- **THEN** beträgt der Anteil in der Zone für dieses Segment 75 %

#### Scenario: Pause im Segment
- **WHEN** der Nutzer in einem Segment mit Band 10 Sekunden pausiert
- **THEN** zählen diese 10 Sekunden als ausserhalb der Zone

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
