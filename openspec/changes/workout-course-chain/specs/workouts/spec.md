## ADDED Requirements

### Requirement: Strecken eines Workouts zusammenstellen
Ein Workout SHALL eine oder mehrere Strecken in fester Reihenfolge lückenlos aneinanderreihen. Der Nutzer SHALL im Editor Strecken anhängen, entfernen und verschieben können. Alle Strecken MUST dieselbe Achse haben: Die erste legt sie fest, danach bietet die Auswahl nur Strecken dieser Achse an. Dieselbe Strecke darf mehrfach vorkommen. Ein Workout MUST mindestens eine Strecke haben. Eine Runde ist die ganze Kette, ihre Länge die Summe der Streckenlängen.

#### Scenario: Strecke anhängen
- **WHEN** der Nutzer im Workout „Intervalltraining“ mit „Einrudern“ (500 m) die Strecke „2 km Intervall“ anhängt
- **THEN** zeigt der Editor „Einrudern“ und darunter „2 km Intervall“, und eine Runde ist 2500 m lang

#### Scenario: Nur gleiche Achse
- **WHEN** das Workout mit der Distanzstrecke „Einrudern“ beginnt und der Nutzer eine weitere Strecke anhängen will
- **THEN** bietet die Auswahl nur Distanzstrecken an, keine Zeitstrecke wie „Vier Minuten“

#### Scenario: Strecke verschieben
- **WHEN** der Nutzer in „Einrudern, 2 km Intervall, Ausrudern“ die Strecke „Ausrudern“ nach oben verschiebt
- **THEN** lautet die Reihenfolge „Einrudern, Ausrudern, 2 km Intervall“

#### Scenario: Letzte Strecke
- **WHEN** das Workout nur noch eine Strecke hat
- **THEN** lässt sie sich nicht entfernen, nur durch eine andere ersetzen

#### Scenario: Erste Strecke ersetzen
- **WHEN** das Workout nur die Distanzstrecke „Einrudern“ hat und der Nutzer sie entfernen und durch eine Zeitstrecke ersetzen will
- **THEN** bietet die Auswahl für diese einzige Strecke Strecken beider Achsen an

### Requirement: Runden, Dauer oder offen im Workout
Ein Workout SHALL genau eine von drei Längen festlegen: eine Rundenzahl, eine Gesamtdauer oder offen. Der Editor MUST dafür dieselben Optionen und Grenzen bieten wie der Start-Screen einer Strecke: Runden ab 1 in Schritten von 1, Dauer von 1 bis 180 min in Schritten von 1 min. Ein neues Workout beginnt mit 3 Runden. Die Länge gilt für die ganze Kette.

#### Scenario: Dauer wählen
- **WHEN** der Nutzer im Workout „Intervalltraining“ „Dauer“ mit 45 min wählt und speichert
- **THEN** zeigt die Workout-Liste „Intervalltraining“ mit „45:00“ statt einer Rundenzahl

#### Scenario: Werte bleiben beim Wechseln
- **WHEN** der Nutzer im Editor 5 Runden einstellt, auf „Dauer“ und wieder auf „Runden“ wechselt
- **THEN** zeigt die Rundenzahl wieder 5

## MODIFIED Requirements

### Requirement: Workout anlegen
Der Nutzer SHALL ein Workout mit Namen anlegen können, das eine oder mehrere Strecken und eine Länge festlegt. Die Länge MUST eine feste Rundenzahl von mindestens 1, eine Gesamtdauer oder „offen“ sein. Bei „offen“ wird gerudert, bis der Nutzer die Session beendet.

#### Scenario: Feste Rundenzahl
- **WHEN** der Nutzer das Workout „Seerunde x3“ mit der Strecke „Seerunde“ und 3 Runden anlegt
- **THEN** erscheint „Seerunde x3 · Seerunde · 3 Runden“ in der Workout-Liste

#### Scenario: Offene Rundenzahl
- **WHEN** der Nutzer das Workout „Seerunde offen“ mit der Rundenzahl „offen“ anlegt
- **THEN** erscheint es mit „offen“ statt einer Rundenzahl in der Liste

#### Scenario: Keine Strecke vorhanden
- **WHEN** der Nutzer ein Workout anlegen will und es gibt noch keine Strecke
- **THEN** bietet die App an, zuerst eine Strecke anzulegen

#### Scenario: Mehrere Strecken
- **WHEN** der Nutzer das Workout „Intervalltraining“ mit „Einrudern“, „2 km Intervall“ und „Ausrudern“ und 1 Runde anlegt
- **THEN** erscheint „Intervalltraining · Einrudern + 2 km Intervall + Ausrudern · 1 Runde“ in der Workout-Liste

### Requirement: Workouts auflisten, bearbeiten und löschen
Die App SHALL alle Workouts mit Name, Strecken und Länge auflisten. Der Nutzer SHALL Name, Strecken und Länge eines Workouts ändern und ein Workout nach Bestätigung löschen können. Sessions, die mit einem gelöschten oder geänderten Workout gerudert wurden, MUST mit ihren Strecken und Runden erhalten bleiben.

#### Scenario: Rundenzahl ändern
- **WHEN** der Nutzer bei „Seerunde x3“ die Rundenzahl auf 4 ändert
- **THEN** startet das Workout künftig mit 4 Runden und bereits geruderte Sessions zeigen weiterhin ihre 3 Runden

#### Scenario: Workout löschen
- **WHEN** der Nutzer das Workout „Seerunde x3“ löscht und bestätigt
- **THEN** verschwindet es aus der Liste und die damit geruderten Sessions bleiben in der Session-Liste

#### Scenario: Strecke anhängen nach dem Rudern
- **WHEN** der Nutzer an das bereits geruderte Workout „Seerunde x3“ die Strecke „Ausrudern“ anhängt
- **THEN** startet das Workout künftig mit beiden Strecken und die alten Sessions zeigen weiterhin nur „Seerunde“

### Requirement: Workout starten
Der Nutzer SHALL ein Workout auswählen und mit einer verbundenen Datenquelle (PM5, Simulator) starten können. Mit dem Start beginnt sofort eine aufgezeichnete Session, die mit dem Workout und der aktuellen Version jeder seiner Strecken verknüpft ist.

#### Scenario: Workout mit dem PM5 starten
- **WHEN** der Nutzer mit verbundenem PM5 das Workout „Seerunde x3“ startet
- **THEN** läuft eine Session auf der Strecke „Seerunde“ mit Runde 1 von 3

#### Scenario: Workout mit dem Simulator starten
- **WHEN** der Nutzer den Simulator als Quelle wählt und ein Workout startet
- **THEN** läuft die Session wie mit dem PM5 und ist als simuliert gekennzeichnet

#### Scenario: Workout mit mehreren Strecken starten
- **WHEN** der Nutzer „Intervalltraining“ mit „Einrudern“, „2 km Intervall“ und „Ausrudern“ startet
- **THEN** beginnt die Session in Runde 1 auf „Einrudern“

### Requirement: Workout auf eigenem Screen
Ein Tipp auf ein Workout in der Workout-Liste SHALL einen eigenen Screen dieses Workouts öffnen. Er MUST Name, Strecken in ihrer Reihenfolge, Länge und Zonen des Workouts zeigen und „Starten“ sowie Bearbeiten anbieten. Die Karten der Liste MUST NOT aufklappen. „Zurück“ führt zur Liste.

#### Scenario: Workout öffnen
- **WHEN** der Nutzer in der Workout-Liste „Seerunde x3“ antippt
- **THEN** öffnet sich der Screen „Seerunde x3“ mit Strecke „Seerunde“, 3 Runden, den Zonen der Strecke und dem Button „Starten“

#### Scenario: Zurück zur Liste
- **WHEN** der Nutzer auf dem Screen von „Seerunde x3“ zurück geht
- **THEN** zeigt die App die Workout-Liste, keine Karte ist aufgeklappt

#### Scenario: Starten vom Screen
- **WHEN** der Nutzer auf dem Screen von „Seerunde x3“ „Starten“ wählt
- **THEN** startet das Workout wie unter „Workout starten“ beschrieben

#### Scenario: Mehrere Strecken ansehen
- **WHEN** der Nutzer den Screen von „Intervalltraining“ öffnet
- **THEN** zeigt er „Einrudern“, „2 km Intervall“ und „Ausrudern“ in dieser Reihenfolge, jeweils mit ihren Zonen, und die Länge einer Runde als Summe
