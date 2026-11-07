# Spec Delta

## MODIFIED Requirements

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
