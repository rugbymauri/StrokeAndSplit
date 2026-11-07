# courses Specification

## Purpose

Lässt den Nutzer wiederverwendbare Strecken definieren: eine Länge in Metern oder Minuten, unterteilt in Segmente mit optionalen Zielbändern für Pace und Schlagzahl. Strecken sind die Grundlage für Workouts, Rundenvergleiche und den späteren Ghost.

## Requirements

### Requirement: Strecke mit einer Achse anlegen
Der Nutzer SHALL eine Strecke mit Namen anlegen können, die entweder distanzbasiert (Länge in Metern) oder zeitbasiert (Länge in Minuten und Sekunden) ist. Eine Strecke MUST genau eine dieser Achsen haben, und ihre Länge MUST grösser als null sein.

#### Scenario: Distanzstrecke anlegen
- **WHEN** der Nutzer die Strecke „Seerunde“ mit der Achse Distanz und 1000 m anlegt
- **THEN** erscheint „Seerunde, 1000 m“ in der Streckenliste

#### Scenario: Zeitstrecke anlegen
- **WHEN** der Nutzer die Strecke „Vier Minuten“ mit der Achse Zeit und 4:00 anlegt
- **THEN** erscheint „Vier Minuten, 4:00“ in der Streckenliste

#### Scenario: Länge null
- **WHEN** der Nutzer eine Strecke mit 0 m speichern will
- **THEN** wird sie nicht gespeichert und der Nutzer sieht, dass die Länge fehlt

### Requirement: Strecke in Segmente teilen
Eine Strecke SHALL sich aus ihren eingebauten Zonen und den freien Abschnitten dazwischen zusammensetzen, die zusammen genau die Länge der Strecke ergeben. Eine neue Strecke MUST ohne Zonen beginnen und ist dann ein einziger freier Abschnitt. Ändert der Nutzer die Länge der Strecke, MUST die App die Änderung ablehnen, wenn danach eine eingebaute Zone über das Streckenende ragen würde.

#### Scenario: Neue Strecke
- **WHEN** der Nutzer die Strecke „Locker 5 km“ mit 5000 m anlegt
- **THEN** besteht sie aus einem freien Abschnitt von 0 bis 5000 m

#### Scenario: Strecke zu kurz für ihre Zonen
- **WHEN** der Nutzer „2 km Intervall“ mit einer Zone von 1000 bis 1500 m auf 1200 m kürzen will
- **THEN** wird die Länge nicht gespeichert und der Editor nennt die Zone, die nicht mehr passt

### Requirement: Strecken auflisten und bearbeiten
Die App SHALL alle Strecken in einer Liste mit Name, Achse und Länge anzeigen. Der Nutzer SHALL Name, Länge, Segmente und Bänder einer Strecke bearbeiten können.

#### Scenario: Strecke umbenennen
- **WHEN** der Nutzer die Strecke „Seerunde“ in „Seerunde lang“ umbenennt
- **THEN** zeigt die Liste „Seerunde lang“

### Requirement: Geruderte Strecken versionieren
Ändert der Nutzer Länge, Segmente oder Bänder einer Strecke, die bereits in einer Session gerudert wurde, SHALL die Änderung als neue Version der Strecke gespeichert werden. Bestehende Sessions MUST mit der Version verknüpft bleiben, die gerudert wurde. Die Liste zeigt nur die neueste Version.

#### Scenario: Gerudert, dann geändert
- **WHEN** die Strecke „Seerunde“ mit 1000 m schon gerudert wurde und der Nutzer sie auf 1200 m ändert
- **THEN** zeigen alte Sessions weiterhin 1000 m und neue Sessions rudern 1200 m

#### Scenario: Nur umbenannt
- **WHEN** der Nutzer eine bereits geruderte Strecke nur umbenennt
- **THEN** entsteht keine neue Version und auch alte Sessions zeigen den neuen Namen

### Requirement: Strecke löschen
Der Nutzer SHALL eine Strecke nach Bestätigung löschen können. Eine gelöschte Strecke verschwindet aus der Streckenliste, aus der Auswahl für Workouts und aus allen Workouts, die sie enthalten. Ein Workout, das danach keine Strecke mehr hätte, MUST mitgelöscht werden. Sessions, die auf ihr gerudert wurden, MUST mit ihren Runden erhalten bleiben.

#### Scenario: Geruderte Strecke löschen
- **WHEN** der Nutzer die bereits geruderte Strecke „Seerunde“ löscht und bestätigt
- **THEN** ist sie nicht mehr in der Streckenliste und die alten Sessions zeigen weiterhin ihre Rundenzeiten auf „Seerunde“

#### Scenario: Strecke eines Workouts löschen
- **WHEN** der Nutzer eine Strecke löschen will, die die einzige Strecke eines Workouts ist
- **THEN** weist die Bestätigung darauf hin, dass auch das Workout gelöscht wird

#### Scenario: Strecke aus einer Kette löschen
- **WHEN** der Nutzer „Ausrudern“ löscht, das in „Intervalltraining“ neben zwei anderen Strecken steckt, und bestätigt
- **THEN** bleibt „Intervalltraining“ mit „Einrudern“ und „2 km Intervall“ erhalten, und die Bestätigung nannte es nicht als gelöscht

### Requirement: Zonen in eine Strecke einbauen
Der Nutzer SHALL vordefinierte Zonen in eine Strecke einbauen können, jede mit einer Startposition in der Achse der Strecke. Eine Zone MUST dieselbe Achse wie die Strecke haben, ganz innerhalb der Strecke liegen und darf keine andere eingebaute Zone überschneiden. Dieselbe Zone darf mehrfach eingebaut werden. Abschnitte ohne Zone sind frei. Eine Zone, die am gewählten Start nicht passt, MUST auf dem Screen „Zone einbauen“ ausgegraut sein und den Grund nennen.

#### Scenario: Intervallstrecke aufbauen
- **WHEN** der Nutzer in die 2000-m-Strecke „2 km Intervall“ die Zone „Sprint“ (100 m) ab 500 m und die Zone „Ausdauer 2:30“ (500 m) ab 1000 m einbaut
- **THEN** zeigt der Editor den Ablauf 0–500 m frei, 500–600 m Sprint, 600–1000 m frei, 1000–1500 m Ausdauer 2:30 und 1500–2000 m frei

#### Scenario: Überschneidung
- **WHEN** der Nutzer auf dem Screen „Zone einbauen“ den Start 1300 m wählt und dort schon eine Zone von 1000 bis 1500 m liegt
- **THEN** ist „Ausdauer 2:30“ ausgegraut, nennt die Überschneidung und lässt sich nicht einbauen

#### Scenario: Über das Ende hinaus
- **WHEN** der Nutzer in einer 2000-m-Strecke den Start 1800 m wählt
- **THEN** ist eine 500-m-Zone ausgegraut und nennt, dass sie über das Streckenende ragt

#### Scenario: Falsche Achse
- **WHEN** der Nutzer in einer Distanzstrecke „Zone einbauen“ öffnet
- **THEN** erscheinen Zonen mit der Achse Zeit nicht in der Auswahl

### Requirement: Screen „Zone einbauen“
Eingebaut wird auf einem eigenen Screen: zuerst der Start, darunter die Zonen der Achse der Strecke, gruppiert nach ihrer Härte (leicht, mittel, hart). Ein Tipp auf eine passende Zone SHALL sie einbauen und zum Strecken-Editor zurückführen.

#### Scenario: Start zuerst
- **WHEN** der Nutzer „Zone einbauen“ öffnet
- **THEN** steht der Start mit einer Vorschau der Strecke oben, darunter die Zonen unter „Leicht“, „Mittel“ und „Hart“

#### Scenario: Ein Tipp baut ein
- **WHEN** der Nutzer bei Start 500 m die passende Zone „Sprint“ antippt
- **THEN** liegt „Sprint“ bei 500–600 m, und die App zeigt wieder den Strecken-Editor

#### Scenario: Freien Abschnitt antippen
- **WHEN** der Nutzer im Strecken-Editor den freien Abschnitt 600–1000 m antippt
- **THEN** öffnet sich „Zone einbauen“ mit dem Start 600 m

#### Scenario: Neue Zone gleich einbauen
- **WHEN** der Nutzer auf „Zone einbauen“ bei Start 0 m „Zone anlegen“ wählt und eine 100-m-Zone speichert, die dort passt
- **THEN** ist die neue Zone ab 0 m eingebaut, und die App zeigt wieder den Strecken-Editor

### Requirement: Zonenänderungen versionieren geruderte Strecken
Ändert sich eine eingebaute Zone oder wird sie gelöscht, SHALL jede betroffene Strecke wie bei einer eigenen Definitionsänderung behandelt werden: Wurde die aktuelle Version schon gerudert, entsteht eine neue Version, sonst wird sie angepasst. Bestehende Sessions MUST mit der Version verknüpft bleiben, die gerudert wurde.

#### Scenario: Zone einer geruderten Strecke ändern
- **WHEN** „2 km Intervall“ schon gerudert wurde und der Nutzer das Pace-Band von „Ausdauer 2:30“ auf 2:25–2:30 ändert
- **THEN** zeigen alte Sessions weiterhin 2:28–2:32 und neue Sessions rudern mit 2:25–2:30

### Requirement: Zone in einer Strecke verschieben
Der Nutzer SHALL eine eingebaute Zone im Strecken-Editor mit Ruderblatt-Tasten verschieben können. Ein Langdruck oder Tipp auf die Zone im Balken oder in der Abschnittsliste MUST sie markieren und unter dem Balken ihren Namen, ihren Start mit den Tasten und „Fertig“ zeigen. Jeder Tipp MUST die Zone sofort verschieben. Sie MUST zwischen ihren Nachbarzonen bzw. Anfang und Ende der Strecke bleiben. Gespeichert wird erst mit „Speichern“.

#### Scenario: Zone markieren
- **WHEN** der Nutzer im Balken lange auf „Sprint“ ab 500 m drückt
- **THEN** ist „Sprint“ markiert, und unter dem Balken stehen „Sprint“, der Start 500 m mit Ruderblatt-Tasten und „Fertig“

#### Scenario: Mit den Tasten verschieben
- **WHEN** „Sprint“ (100 m) ab 500 m markiert ist und der Nutzer einmal auf „mehr“ tippt
- **THEN** liegt „Sprint“ bei 550–650 m, im Balken und in der Liste

#### Scenario: Anschlag an der Nachbarzone
- **WHEN** „Sprint“ (100 m) bei 800–900 m liegt und „Ausdauer 2:30“ bei 1000 m beginnt
- **THEN** lässt sich „Sprint“ höchstens bis 900–1000 m verschieben, danach ist „mehr“ gesperrt

#### Scenario: Fertig
- **WHEN** der Nutzer beim Verschieben „Fertig“ antippt
- **THEN** ist keine Zone mehr markiert, das Bedienfeld verschwindet, und die neue Lage bleibt bis zum Speichern

#### Scenario: Andere Zone markieren
- **WHEN** „Sprint“ markiert ist und der Nutzer „Ausdauer 2:30“ in der Abschnittsliste antippt
- **THEN** ist „Ausdauer 2:30“ markiert und das Bedienfeld zeigt ihren Start
