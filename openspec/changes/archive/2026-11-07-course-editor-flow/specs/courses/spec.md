## MODIFIED Requirements

### Requirement: Zonen in eine Strecke einbauen
Der Nutzer SHALL vordefinierte Zonen in eine Strecke einbauen können, jede mit einer Startposition in der Achse der Strecke. Eine Zone MUST dieselbe Achse wie die Strecke haben, ganz innerhalb der Strecke liegen und darf keine andere eingebaute Zone überschneiden. Dieselbe Zone darf mehrfach eingebaut werden. Abschnitte ohne Zone sind frei. Eingebaut wird auf einem eigenen Screen: zuerst der Start, darunter die Zonen der Achse der Strecke, gruppiert nach ihrer Härte (leicht, mittel, hart). Eine Zone, die am gewählten Start nicht passt, MUST ausgegraut sein und den Grund nennen. Ein Tipp auf eine passende Zone SHALL sie einbauen und zum Strecken-Editor zurückführen.

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

## ADDED Requirements

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
