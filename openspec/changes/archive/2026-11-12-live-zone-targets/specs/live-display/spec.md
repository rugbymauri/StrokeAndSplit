## ADDED Requirements

### Requirement: Zielwerte der Zone unter der Pace
Beim Rudern eines Workouts oder einer Strecke SHALL die Pace-Box unter der Pace immer eine Zeile mit den Vorgaben des aktuellen Abschnitts zeigen: den Namen der Zone, das Pace-Band, das Schlagzahl-Band und die Stufe, getrennt durch „·“. Hat die Zone eine Vorgabe nicht, MUST nur deren Teil fehlen. In einem freien Abschnitt MUST die Zeile „frei“ zeigen. Die Zeile MUST unabhängig davon stehen, ob der Ruderer in der Zone ist, und darf die Pace nicht verschieben, wenn sie sich ändert.

#### Scenario: Alle Vorgaben in der Zone
- **WHEN** der Nutzer in der Zone „Tempo“ mit Pace-Band 2:05–2:10, Schlagzahl 20–22 und Stufe 8 rudert und seine Pace 2:07 im Band liegt
- **THEN** zeigt die Pace-Box unter der Pace „Tempo · 2:05–2:10 · 20–22 spm · Stufe 8“

#### Scenario: Ausserhalb der Zone
- **WHEN** derselbe Nutzer mit Pace 2:13 rudert
- **THEN** zeigt die Pace-Box den Hinweis „Schneller“ und darunter weiterhin „Tempo · 2:05–2:10 · 20–22 spm · Stufe 8“

#### Scenario: Zone nur mit Stufe
- **WHEN** der Nutzer in der Zone „Kraft“ rudert, die nur Stufe 12 vorgibt
- **THEN** zeigt die Zeile „Kraft · Stufe 12“ und die Pace-Box keinen Hinweis für die Pace

#### Scenario: Freier Abschnitt
- **WHEN** der Nutzer in einem freien Abschnitt rudert
- **THEN** zeigt die Zeile „frei“

#### Scenario: Zone ohne Namen
- **WHEN** die Zone keinen Namen hat und nur das Pace-Band 2:20–2:25 vorgibt
- **THEN** zeigt die Zeile „Zone · 2:20–2:25“

### Requirement: Zonen im Fortschrittsrahmen nach Härte
Der Fortschrittsrahmen SHALL jede Zone auf der Strecken- und der Rundenspur in ihrer Härte-Farbe zeigen, grün (leicht), orange (mittel) oder rot (hart), wie im Streckenbalken: gedämpft, wo noch nicht gerudert wurde, und kräftig, wo schon. Freie Abschnitte MUST grau bleiben. Der Punkt vor der Abschnittszeile der Legende MUST die Härte-Farbe der aktuellen Zone haben, in einem freien Abschnitt grau. Der Hinweis auf eine kommende Zone MUST in deren Härte-Farbe erscheinen und weiter blinken.

#### Scenario: Leichte und harte Zone in einer Runde
- **WHEN** die Strecke eine leichte Zone von 0 bis 500 m und eine harte von 500 bis 1000 m hat und der Nutzer bei 700 m steht
- **THEN** ist die leichte Zone auf der Rundenspur kräftig grün, die harte bis 700 m kräftig und danach gedämpft rot

#### Scenario: Gleiche Farbe wie in der Strecke
- **WHEN** eine Zone im Streckenbalken orange ist
- **THEN** ist sie auch auf den Spuren des Fortschrittsrahmens orange

#### Scenario: Kommende harte Zone
- **WHEN** in wenigen Sekunden eine harte Zone mit Band 1:55–2:00 beginnt
- **THEN** blinkt der Hinweis „Gleich 1:55–2:00“ in Rot

#### Scenario: Legende im freien Abschnitt
- **WHEN** der Nutzer in einem freien Abschnitt rudert
- **THEN** ist der Punkt vor der Abschnittszeile grau

### Requirement: Stufe unter der Schlagzahl im Querformat
Beim Rudern eines Workouts oder einer Strecke im Querformat SHALL die Live-Anzeige direkt unter der Schlagzahlkarte eine Karte „Stufe“ in derselben Breite zeigen, sobald das Rudergerät eine Stufe meldet. Die Karte MUST die aktuelle Stufe gross zeigen. Lässt sich die Stufe setzen, MUST die Karte links und rechts Ruderblatt-Tasten zum Senken und Erhöhen um eine Stufe haben, die aus Ruderdistanz treffbar sind und an der Grenze des Bereichs gesperrt sind. Im Querformat MUST die Watt-Kachel die Stufe dann nicht noch einmal zeigen. Das Hochformat und frei rudern bleiben unverändert.

#### Scenario: Stufe erhöhen im Querformat
- **WHEN** das Handy quer steckt, ein Workout läuft und der Woodrower Stufe 6 meldet
- **THEN** steht unter der Schlagzahlkarte gleich breit die Karte „Stufe 6“ mit Ruderblatt-Tasten, und nach einem Tipp auf die rechte Taste zeigt sie „Stufe 7“, sobald das Gerät sie meldet

#### Scenario: Obere Grenze
- **WHEN** das Gerät Stufe 15 meldet und höchstens 15 erlaubt
- **THEN** ist die Taste zum Erhöhen gesperrt

#### Scenario: Stufe nicht setzbar
- **WHEN** ein Gerät seine Stufe meldet, das Setzen aber nicht unterstützt
- **THEN** zeigt die Karte nur die Stufe, ohne Tasten

#### Scenario: Gerät ohne Stufe
- **WHEN** der PM5 verbunden ist, der keine Stufe meldet
- **THEN** gibt es keine Karte „Stufe“, und die Schlagzahlkarte nutzt die Höhe

#### Scenario: Hochformat
- **WHEN** das Handy hochkant steckt
- **THEN** steht die Stufe wie bisher unter den Watt

## MODIFIED Requirements

### Requirement: Fortschrittsrahmen um die Pace
Beim Rudern eines Workouts SHALL die Pace in einer Box stehen, deren Rahmen den Fortschritt als drei Spuren zeigt: aussen die Gesamtstrecke, in der Mitte die Runde, innen den Abschnitt (Zone oder frei). Jede Spur MUST oben in der Mitte beginnen, im Uhrzeigersinn wachsen und an der Spitze ein Schiffchen tragen. Die Box SHALL neben der Pace den Zonenstatus, die Zielwerte des Abschnitts, den Zonennamen bzw. „frei“ und pro Spur die Restdistanz bzw. Restzeit zeigen. Der Zonenstatus MUST Zustand und Richtung nennen; das Band steht in der Zeile der Zielwerte.

#### Scenario: Mitten in Runde 2
- **WHEN** der Nutzer das Workout „Seerunde x3“ rudert, dessen Strecke 1000 m lang ist und die Zone „Tempo“ von 200 bis 800 m enthält, und bei 460 m in Runde 2 steht
- **THEN** ist die Streckenspur zu 49 %, die Rundenspur zu 46 % und die Abschnittsspur zu 43 % gefüllt, und die Box zeigt „1 460 / 3 000 m“, „noch 540 m“, „Tempo“ und „noch 340 m“

#### Scenario: Freier Abschnitt
- **WHEN** der Nutzer in demselben Workout bei 100 m einer Runde steht
- **THEN** zeigt die Box für den Abschnitt „frei“ und „noch 100 m“

#### Scenario: Offene Rundenzahl
- **WHEN** der Nutzer ein Workout mit offener Rundenzahl rudert
- **THEN** zeigt der Rahmen nur die Spuren für Runde und Abschnitt und die Box nennt die Runde ohne Gesamtzahl

#### Scenario: Grenzen sichtbar
- **WHEN** die Strecke aus drei Abschnitten besteht und drei Runden geplant sind
- **THEN** markieren Kerben auf der Streckenspur die zwei Rundengrenzen und auf der Rundenspur die zwei Abschnittsgrenzen

#### Scenario: Hinweis ohne Band
- **WHEN** die aktuelle Zone das Band 2:05–2:10 hat und die Pace 2:07 beträgt
- **THEN** zeigt der Hinweis „In der Zone“ ohne Band, und „2:05–2:10“ steht in der Zeile der Zielwerte

### Requirement: Abschnittsspur zeigt den Zonenstatus
Die innere Spur des Fortschrittsrahmens SHALL im geruderten Teil in der Farbe des Pace-Zonenstatus erscheinen: in der Zone und ausserhalb unterscheidbar in Farbe und Helligkeit. Der noch nicht geruderte Teil einer Zone MUST die Härte-Farbe der Zone gedämpft zeigen. In einer Zone ohne Pace-Band MUST sich die Spur in der Härte-Farbe der Zone füllen, in einem freien Abschnitt neutral. Der Zonenstatus MUST zusätzlich als Text oder Symbol in der Box stehen.

#### Scenario: Pace zu langsam
- **WHEN** die aktuelle Zone das Band 2:05–2:10 hat und die Pace 2:13.0 beträgt
- **THEN** ist der geruderte Teil der Abschnittsspur als ausserhalb eingefärbt und die Box zeigt den Hinweis „schneller“

#### Scenario: Rest der Zone in Härte-Farbe
- **WHEN** der Nutzer in einer harten Zone mit Pace-Band bei der Hälfte steht
- **THEN** zeigt die zweite Hälfte der Abschnittsspur gedämpftes Rot

#### Scenario: Zone ohne Pace-Band
- **WHEN** die aktuelle Zone nur Stufe 12 vorgibt und damit hart ist
- **THEN** füllt sich die Abschnittsspur in Rot und die Box zeigt keinen Zonenstatus für die Pace

#### Scenario: Abschnitt ohne Pace-Band
- **WHEN** der aktuelle Abschnitt frei ist
- **THEN** ist die Abschnittsspur neutral und die Box zeigt keinen Zonenstatus für die Pace
