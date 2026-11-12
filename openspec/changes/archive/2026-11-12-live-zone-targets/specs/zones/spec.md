## MODIFIED Requirements

### Requirement: Zonen nach Härte einfärben
Die App SHALL Zonen nach ihrer Härte grün (leicht), orange (mittel) oder rot (hart) zeigen: im Streckenbalken jeder Liste und Detailansicht, im Balken und in den Abschnittszeilen des Strecken-Editors, als Farbmarke in der Zonenliste und in der Live-Anzeige auf den Spuren des Fortschrittsrahmens, am Punkt der Abschnittszeile und am Hinweis auf die kommende Zone. Freie Abschnitte MUST grau bleiben. Die drei Farben MUST sich von den Farben für „in der Zone“, „ausserhalb der Zone“ und „verbunden“ unterscheiden; in der Live-Anzeige zeigen blau und orange weiterhin den Zustand der Pace.

#### Scenario: Gleiche Zone in zwei Strecken
- **WHEN** „Ausdauer 2:30“ in einer Strecke allein und in einer anderen neben einem Sprint mit 1:45 steckt
- **THEN** hat sie in beiden Streckenbalken dieselbe Farbe

#### Scenario: Freier Abschnitt
- **WHEN** eine Strecke zwischen zwei Zonen einen freien Abschnitt hat
- **THEN** ist dieser Abschnitt grau

#### Scenario: Live wie in der Strecke
- **WHEN** der Nutzer eine Strecke rudert, deren Zone „Tempo“ im Streckenbalken rot ist
- **THEN** ist „Tempo“ auch im Fortschrittsrahmen der Live-Anzeige rot
