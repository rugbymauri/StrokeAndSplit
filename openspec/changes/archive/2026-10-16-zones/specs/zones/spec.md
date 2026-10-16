# Spec Delta

## Purpose

Lässt den Nutzer benannte Belastungen einmal definieren und in beliebig vielen Strecken wiederverwenden.

## ADDED Requirements

### Requirement: Zone anlegen
Der Nutzer SHALL eine Zone mit Namen, Achse (Distanz oder Zeit), Länge und mindestens einem Band anlegen können: einem Pace-Band (schnellste und langsamste Pace pro 500 m), einem Schlagzahl-Band (niedrigste und höchste Schlagzahl) oder beiden. Die Länge MUST grösser als null sein, und bei jedem Band MUST die Untergrenze nicht über der Obergrenze liegen.

#### Scenario: Sprint anlegen
- **WHEN** der Nutzer die Zone „Sprint“ mit Achse Distanz, 100 m, Pace-Band 1:45–1:50 und Schlagzahl-Band 30–34 anlegt
- **THEN** erscheint „Sprint, 100 m, 1:45–1:50 · 30–34 spm“ in der Zonenliste

#### Scenario: Nur Pace
- **WHEN** der Nutzer die Zone „Ausdauer 2:30“ mit 500 m und nur dem Pace-Band 2:28–2:32 anlegt
- **THEN** erscheint sie ohne Schlagzahl-Band in der Liste

#### Scenario: Ohne Band
- **WHEN** der Nutzer eine Zone ohne Pace- und ohne Schlagzahl-Band speichern will
- **THEN** wird sie nicht gespeichert und der Nutzer sieht, dass ein Band fehlt

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
