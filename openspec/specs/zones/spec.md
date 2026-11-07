# zones Specification

## Purpose

Lässt den Nutzer benannte Belastungen einmal definieren und in beliebig vielen Strecken wiederverwenden.

## Requirements

### Requirement: Zone anlegen
Der Nutzer SHALL eine Zone mit Namen, Achse (Distanz oder Zeit), Länge und mindestens einer Vorgabe anlegen können: einem Pace-Band (schnellste und langsamste Pace pro 500 m), einem Schlagzahl-Band (niedrigste und höchste Schlagzahl), einer Widerstandsstufe oder einer Kombination davon. Die Länge MUST grösser als null sein, und bei jedem Band MUST die Untergrenze nicht über der Obergrenze liegen.

#### Scenario: Sprint anlegen
- **WHEN** der Nutzer die Zone „Sprint“ mit Achse Distanz, 100 m, Pace-Band 1:45–1:50 und Schlagzahl-Band 30–34 anlegt
- **THEN** erscheint „Sprint, 100 m, 1:45–1:50 · 30–34 spm“ in der Zonenliste

#### Scenario: Nur Pace
- **WHEN** der Nutzer die Zone „Ausdauer 2:30“ mit 500 m und nur dem Pace-Band 2:28–2:32 anlegt
- **THEN** erscheint sie ohne Schlagzahl-Band in der Liste

#### Scenario: Ohne Band
- **WHEN** der Nutzer eine Zone ohne Pace-Band, ohne Schlagzahl-Band und ohne Stufe speichern will
- **THEN** wird sie nicht gespeichert und der Nutzer sieht, dass Pace, Schlagzahl oder Stufe fehlt

#### Scenario: Vertauschte Grenzen
- **WHEN** der Nutzer als Schlagzahl-Band 22–20 eingibt
- **THEN** wird die Zone nicht gespeichert und der Nutzer sieht den Fehler

### Requirement: Zonen auflisten
Die App SHALL alle Zonen nach Achse gruppiert mit Name, Länge, Bändern und der Zahl der Strecken anzeigen, in denen sie stecken.

#### Scenario: Verwendung sichtbar
- **WHEN** die Zone „Sprint“ in zwei Strecken eingebaut ist
- **THEN** zeigt die Liste bei „Sprint“ „in 2 Strecken“

### Requirement: Zone bearbeiten
Der Nutzer SHALL Name, Länge und Bänder einer Zone ändern können. Die Achse SHALL nur änderbar sein, solange die Zone in keiner Strecke steckt. Eine Änderung MUST in allen Strecken gelten, die die Zone enthalten. Wäre eine dieser Strecken danach ungültig, weil die Zone über das Streckenende ragt oder eine andere Zone überschneidet, MUST die Änderung abgelehnt werden und der Nutzer sieht die betroffenen Strecken.

#### Scenario: Sprint verlängern
- **WHEN** der Nutzer „Sprint“ von 100 m auf 150 m ändert und die Strecken genug Platz haben
- **THEN** ist der Sprint in allen Strecken, die ihn enthalten, 150 m lang

#### Scenario: Änderung passt nicht
- **WHEN** der Nutzer „Sprint“ auf 600 m verlängert und der Sprint in „2 km Intervall“ dann die Zone bei 1000 m überschneiden würde
- **THEN** wird die Änderung nicht gespeichert und der Nutzer sieht „2 km Intervall“ als betroffene Strecke

#### Scenario: Umbenennen
- **WHEN** der Nutzer „Sprint“ in „Spurt“ umbenennt
- **THEN** zeigen alle Strecken mit dieser Zone „Spurt“

### Requirement: Zone löschen
Der Nutzer SHALL eine Zone nach Bestätigung löschen können. Die Bestätigung MUST die Strecken nennen, die die Zone enthalten. Nach dem Löschen sind diese Stellen in den Strecken frei. Sessions, die mit der Zone gerudert wurden, MUST ihre Runden und den Zonennamen behalten.

#### Scenario: Verwendete Zone löschen
- **WHEN** der Nutzer die Zone „Sprint“ löscht, die in „2 km Intervall“ ab 500 m steckt, und bestätigt
- **THEN** ist in „2 km Intervall“ die Stelle 500–600 m frei, und alte Sessions zeigen weiterhin „Sprint“

### Requirement: Widerstandsstufe einer Zone
Der Nutzer SHALL einer Zone eine Widerstandsstufe geben oder diese leer lassen können, zusätzlich zu ihren Bändern oder ohne Band. Die Stufe MUST eine ganze Zahl ab 1 sein. Die Liste und der Editor SHALL die Stufe zeigen, wenn sie gesetzt ist. Eine Änderung der Stufe SHALL wie eine Änderung der Bänder in allen Strecken gelten, die die Zone enthalten. Bereits geruderte Sessions SHALL die Stufe behalten, die beim Rudern galt.

#### Scenario: Sprint mit Stufe
- **WHEN** der Nutzer der Zone „Sprint“ mit Pace-Band 1:45–1:50 die Stufe 10 gibt
- **THEN** erscheint „Sprint, 100 m, 1:45–1:50 · Stufe 10“ in der Zonenliste

#### Scenario: Nur Stufe
- **WHEN** der Nutzer die Zone „Kraft“ mit 500 m ohne Pace- und Schlagzahl-Band, aber mit Stufe 12 speichert
- **THEN** wird sie gespeichert und erscheint als „Kraft, 500 m · Stufe 12“ in der Zonenliste

#### Scenario: Ohne Stufe
- **WHEN** der Nutzer eine Zone ohne Stufe speichert
- **THEN** zeigt die Liste keine Stufe, und beim Rudern gilt dort die Grundstufe

### Requirement: Härte einer Zone
Die App SHALL jeder Zone eine Härte geben, leicht, mittel oder hart, mit festen Grenzen, die in jeder Strecke gleich gelten. Bei einem Band zählt die Mitte des Bands. Die Grenzen sind:
- Stufe: 1–5 leicht, 6–10 mittel, ab 11 hart.
- Pace: 3:00 und langsamer leicht, schneller als 3:00 bis einschliesslich 2:30 mittel, schneller als 2:30 hart.
- Schlagzahl: bis 21 leicht, über 21 bis unter 24 mittel, ab 24 hart.

Hat eine Zone mehrere Vorgaben, MUST die härteste die Härte der Zone bestimmen.

#### Scenario: Leichte Zone
- **WHEN** die Zone „Ausdauer“ nur das Pace-Band 3:05–3:15 hat
- **THEN** ist sie in der Zonenliste und im Streckenbalken grün

#### Scenario: Mittlere Zone
- **WHEN** die Zone „Ausdauer 2:30“ nur das Pace-Band 2:28–2:32 hat
- **THEN** ist sie orange, weil die Mitte genau 2:30 ist

#### Scenario: Harte Zone nur mit Stufe
- **WHEN** die Zone „Kraft“ nur die Stufe 12 hat
- **THEN** ist sie rot

#### Scenario: Härteste Vorgabe gewinnt
- **WHEN** die Zone „Sprint“ das Pace-Band 2:50–3:00 (mittel), das Schlagzahl-Band 18–20 (leicht) und die Stufe 11 (hart) hat
- **THEN** ist sie rot

#### Scenario: Schlagzahl an der Grenze
- **WHEN** eine Zone nur das Schlagzahl-Band 20–22 hat
- **THEN** ist sie grün, weil die Mitte 21 ist
- **WHEN** eine Zone nur das Schlagzahl-Band 22–26 hat
- **THEN** ist sie rot, weil die Mitte 24 ist

### Requirement: Zonen nach Härte einfärben
Die App SHALL Zonen nach ihrer Härte grün (leicht), orange (mittel) oder rot (hart) zeigen: im Streckenbalken jeder Liste und Detailansicht, im Balken und in den Abschnittszeilen des Strecken-Editors und als Farbmarke in der Zonenliste. Freie Abschnitte MUST grau bleiben. Die drei Farben MUST sich von den Farben für „in der Zone“, „ausserhalb der Zone“ und „verbunden“ unterscheiden; die Live-Anzeige bleibt unverändert.

#### Scenario: Gleiche Zone in zwei Strecken
- **WHEN** „Ausdauer 2:30“ in einer Strecke allein und in einer anderen neben einem Sprint mit 1:45 steckt
- **THEN** hat sie in beiden Streckenbalken dieselbe Farbe

#### Scenario: Freier Abschnitt
- **WHEN** eine Strecke zwischen zwei Zonen einen freien Abschnitt hat
- **THEN** ist dieser Abschnitt grau
