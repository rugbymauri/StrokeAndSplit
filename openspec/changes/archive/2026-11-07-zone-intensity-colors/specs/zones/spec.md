## ADDED Requirements

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
