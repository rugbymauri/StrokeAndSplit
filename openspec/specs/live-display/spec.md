# live-display Specification

## Purpose

Zeigt dem Nutzer während des Ruderns die wichtigsten Messwerte gross und gut lesbar an, auf dem Handy am Erg ebenso wie auf dem Laptop.

## Requirements

### Requirement: Kernwerte anzeigen
Das Live-Display SHALL mindestens Pace pro 500 m, Schlagzahl, Watt, verstrichene Zeit und Distanz anzeigen. Die Herzfrequenz SHALL angezeigt werden, wenn sie vorhanden ist.

#### Scenario: Rudern mit Herzfrequenz
- **WHEN** der Nutzer rudert und ein Herzfrequenzgurt verbunden ist
- **THEN** zeigt das Display Pace, Schlagzahl, Watt, Zeit, Distanz und Herzfrequenz

#### Scenario: Rudern ohne Herzfrequenz
- **WHEN** keine Herzfrequenz vorhanden ist
- **THEN** wird kein Herzfrequenzfeld mit falschem Wert angezeigt

### Requirement: Werte in gewohnten Formaten anzeigen
Pace und Zeit SHALL im Format Minuten:Sekunden angezeigt werden (z.B. „2:05“ bzw. „12:34“), die Pace in ganzen Sekunden ohne Zehntel, Distanz in ganzen Metern, Watt und Schlagzahl als ganze Zahlen, so wie es Ruderer vom PM5 kennen.

#### Scenario: Pace-Darstellung
- **WHEN** die aktuelle Pace 125,3 Sekunden pro 500 m beträgt
- **THEN** zeigt das Display „2:05“

#### Scenario: Pace wird auf ganze Sekunden gerundet
- **WHEN** die aktuelle Pace 125,6 Sekunden pro 500 m beträgt
- **THEN** zeigt das Display „2:06“

### Requirement: Lesbar aus Ruderdistanz
Das Live-Display SHALL so gestaltet sein, dass die Pace als wichtigster Wert am grössten dargestellt wird, und SHALL sich an Hoch- und Querformat sowie an Handy- und Laptop-Bildschirme anpassen.

#### Scenario: Handy im Querformat
- **WHEN** das Handy im Querformat am Erg-Halter steckt
- **THEN** sind alle Kernwerte ohne Scrollen sichtbar und die Pace ist der grösste Wert

#### Scenario: Laptop-Fenster
- **WHEN** die App auf dem Laptop in einem Fenster läuft
- **THEN** passt sich das Display der Fenstergrösse an, ohne Werte abzuschneiden

### Requirement: Bildschirm aktiv halten
Solange das Live-Display offen und eine Datenquelle verbunden ist, SHALL die App verhindern, dass sich der Bildschirm automatisch ausschaltet.

#### Scenario: Lange Session
- **WHEN** der Nutzer 30 Minuten rudert, ohne den Bildschirm zu berühren
- **THEN** bleibt der Bildschirm eingeschaltet

### Requirement: Statusleiste ausblenden
Solange das Live-Display offen ist, SHALL die App unter Android die Statusleiste mit Uhrzeit und Akkustand ausblenden; die Navigationsleiste MUST sichtbar bleiben. Verlässt der Nutzer das Live-Display, MUST die Statusleiste wieder erscheinen.

#### Scenario: Live-Display öffnen
- **WHEN** der Nutzer unter Android das Live-Display öffnet, ob verbunden oder nicht
- **THEN** ist oben keine Statusleiste mit Uhrzeit und Akkustand zu sehen, und die Navigationsleiste bleibt

#### Scenario: Live-Display verlassen
- **WHEN** der Nutzer das Live-Display zum Startbildschirm verlässt
- **THEN** zeigt der Startbildschirm die Statusleiste wieder

### Requirement: Veraltete Daten kennzeichnen
Treffen länger als 3 Sekunden keine Daten von der Datenquelle ein, SHALL das Live-Display die Werte als veraltet kennzeichnen, statt den letzten Stand unkommentiert stehen zu lassen.

#### Scenario: Datenfluss stockt
- **WHEN** 3 Sekunden lang keine Daten eintreffen, die Verbindung aber nicht als getrennt gemeldet ist
- **THEN** werden die angezeigten Werte sichtbar als veraltet markiert

### Requirement: Streckenangaben ohne Verlust der Lesbarkeit
Beim Rudern eines Workouts SHALL das Live-Display Runde, Segment, Restdistanz bzw. Restzeit, Zielbänder und Zonenstatus zusätzlich zu den Kernwerten zeigen. Die Pace MUST dabei der grösste Wert bleiben, und alle Angaben MUST in Hoch- und Querformat auf Handy und Laptop ohne Scrollen sichtbar sein.

#### Scenario: Handy im Querformat mit Workout
- **WHEN** der Nutzer ein Workout mit Pace- und Schlagzahl-Band auf dem Handy im Querformat rudert
- **THEN** sind Kernwerte, Runde, Segment, Restdistanz und Zonenstatus ohne Scrollen sichtbar und die Pace ist der grösste Wert

### Requirement: Zonenstatus ohne Farbe erkennbar
Der Zonenstatus SHALL nicht allein über Farbe vermittelt werden. Ausserhalb der Zone MUST ein Richtungssymbol oder Text die Abweichung zeigen. Liegt die Schlagzahl ausserhalb ihres Bands, MUST die Schlagzahl-Karte in Hoch- und Querformat eine deutliche Anweisung zeigen: Pfeil nach oben und „Mehr Schläge“ bzw. Pfeil nach unten und „Weniger Schläge“, zusammen mit dem Band, in der Farbe für ausserhalb der Zone, vollständig lesbar und mindestens so auffällig wie der Zonenstatus der Pace. In der Zone SHALL der Status dezent bleiben, und ohne Schlagzahl-Band MUST die Anweisung entfallen.

#### Scenario: Ausserhalb der Zone
- **WHEN** die Pace langsamer als das Band ist
- **THEN** zeigt das Display neben der Farbe einen Pfeil bzw. den Hinweis „schneller“

#### Scenario: Schlagzahl zu niedrig
- **WHEN** die aktuelle Zone das Schlagzahl-Band 20–22 spm hat und die Schlagzahl 18 spm beträgt
- **THEN** zeigt die Schlagzahl-Karte gut sichtbar einen Pfeil nach oben, „Mehr Schläge“ und das Band 20–22 spm

#### Scenario: Schlagzahl zu hoch
- **WHEN** die aktuelle Zone das Schlagzahl-Band 20–22 spm hat und die Schlagzahl 24 spm beträgt
- **THEN** zeigt die Schlagzahl-Karte gut sichtbar einen Pfeil nach unten, „Weniger Schläge“ und das Band 20–22 spm

#### Scenario: Schlagzahl in der Zone
- **WHEN** die Schlagzahl im Band liegt
- **THEN** zeigt die Schlagzahl-Karte dezent „In der Zone“ und keine Anweisung

#### Scenario: Abschnitt ohne Schlagzahl-Band
- **WHEN** der aktuelle Abschnitt frei ist oder seine Zone kein Schlagzahl-Band hat
- **THEN** zeigt die Schlagzahl-Karte keine Anweisung

### Requirement: Fortschrittsrahmen um die Pace
Beim Rudern eines Workouts SHALL die Pace in einer Box stehen, deren Rahmen den Fortschritt als drei Spuren zeigt: aussen die Gesamtstrecke, in der Mitte die Runde, innen den Abschnitt (Zone oder frei). Bei offener Rundenzahl und bei genau einer Runde MUST die äussere Spur fehlen. Jede Spur MUST oben in der Mitte beginnen, im Uhrzeigersinn wachsen und an der Spitze ein Schiffchen tragen. Die Box SHALL neben der Pace den Zonenstatus, die Zielwerte des Abschnitts, den Zonennamen bzw. „frei“ und pro Spur die Restdistanz bzw. Restzeit zeigen. Der Zonenstatus MUST Zustand und Richtung nennen; das Band steht in der Zeile der Zielwerte.

#### Scenario: Mitten in Runde 2
- **WHEN** der Nutzer das Workout „Seerunde x3“ rudert, dessen Strecke 1000 m lang ist und die Zone „Tempo“ von 200 bis 800 m enthält, und bei 460 m in Runde 2 steht
- **THEN** ist die Streckenspur zu 49 %, die Rundenspur zu 46 % und die Abschnittsspur zu 43 % gefüllt, und die Box zeigt „1 460 / 3 000 m“, „noch 540 m“, „Tempo“ und „noch 340 m“

#### Scenario: Freier Abschnitt
- **WHEN** der Nutzer in demselben Workout bei 100 m einer Runde steht
- **THEN** zeigt die Box für den Abschnitt „frei“ und „noch 100 m“

#### Scenario: Offene Rundenzahl
- **WHEN** der Nutzer ein Workout mit offener Rundenzahl rudert
- **THEN** zeigt der Rahmen nur die Spuren für Runde und Abschnitt und die Box nennt die Runde ohne Gesamtzahl

#### Scenario: Eine Runde
- **WHEN** der Nutzer ein Workout mit genau einer Runde über eine 1000 m lange Strecke rudert und bei 460 m steht
- **THEN** zeigt der Rahmen nur die Spuren für Runde und Abschnitt, die Box zeigt keine Zeile „Gesamt“ und nennt die Runde ohne Zahl als „Runde“ mit „noch 540 m“

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

### Requirement: Layout nach Seitenverhältnis
Das Live-Display SHALL bei mehr Breite als Höhe ein eigenes Querformat-Layout verwenden, sonst das Hochformat-Layout. Das gilt mit und ohne Workout. In beiden Layouts MUST die Pace der grösste Wert sein und alle Werte ohne Scrollen sichtbar.

#### Scenario: Laptop-Fenster breiter als hoch
- **WHEN** die App auf dem Laptop in einem Fenster von 1200 × 700 läuft
- **THEN** zeigt das Live-Display das Querformat-Layout

#### Scenario: Handy quer mit Workout
- **WHEN** das Handy im Querformat steckt und ein Workout läuft
- **THEN** steht die Pace-Box mit Fortschrittsrahmen links fast über die volle Höhe, und Schlagzahl und weitere Werte stehen daneben

#### Scenario: Zeit und Distanz der Session mit Workout
- **WHEN** ein Workout seit 6:20 läuft und die Session 1520 m zurückgelegt hat
- **THEN** zeigt das Live-Display neben Rundenzeit, Watt und Puls die Kacheln „Zeit“ mit 6:20 und „Distanz“ mit 1 520 m, im Hochformat auch auf einem 360 px breiten Handy und im Querformat, ohne dass ein Wert abgeschnitten wird

### Requirement: Live-Display ohne Trennen verlassen
Das Live-Display SHALL kein Bedienelement zum Trennen zeigen. Zurück (Geste oder Taste) und auf dem Desktop die Esc-Taste MUST zum Startbildschirm führen, ohne die Verbindung zu trennen. Eine laufende Session MUST dabei wie mit „Session beenden“ gespeichert werden, eine bereite Session, die noch auf den ersten Schlag wartet, MUST verworfen werden. Der Bildschirm MUST nach dem Verlassen wieder ausgehen dürfen.

#### Scenario: Kein Trennen-Symbol
- **WHEN** der Nutzer frei oder mit einem Workout rudert, im Hoch- oder Querformat
- **THEN** zeigt das Live-Display Verbindungspunkt, Pulsgurt und Quelle, aber kein Symbol zum Trennen

#### Scenario: Esc auf dem Desktop
- **WHEN** der Nutzer auf dem Linux-Desktop im Live-Display Esc drückt
- **THEN** zeigt die App den Startbildschirm, das Rudergerät bleibt verbunden und der Bildschirm darf wieder ausgehen

#### Scenario: Zurück während einer Session
- **WHEN** der Nutzer während einer laufenden Session zurück geht
- **THEN** wird die Session gespeichert und die App zeigt den Startbildschirm

#### Scenario: Zurück vor dem ersten Schlag
- **WHEN** der Nutzer ein Workout startet und vor dem ersten Schlag zurück geht
- **THEN** wird keine Session gespeichert, und das Rudergerät bleibt verbunden

### Requirement: Kraftkurve anzeigen
Unterstützt die Quelle Kraftkurven, SHALL das Live-Display die Kurve des letzten Schlags und zum Vergleich die des vorherigen Schlags zeigen, beide auf derselben Skala und klar unterscheidbar. Die Kurve MUST kleiner bleiben als die Pace.

#### Scenario: Während des Ruderns
- **WHEN** der Nutzer mit dem PM5 rudert und mindestens zwei Kraftkurven eingetroffen sind
- **THEN** zeigt das Display die Kurven der letzten beiden Schläge, die neuere hervorgehoben

#### Scenario: Vor dem ersten Schlag
- **WHEN** die Session läuft, aber noch keine Kraftkurve eingetroffen ist, etwa beim ersten Schlag, für den der PM5 keine Kurve liefert
- **THEN** zeigt die Karte den Hinweis „Warte auf ersten Schlag“

#### Scenario: Gerät ohne Kraftkurve und ohne Schlaglänge
- **WHEN** ein FTMS-Rudergerät verbunden ist, das weder Kraftkurve noch Durchzugslänge liefert
- **THEN** zeigt das Display weder die Kraftkurve noch eine Schlaglänge

#### Scenario: Quelle ohne Kraftkurve
- **WHEN** die verbundene Quelle keine Kraftkurven liefert
- **THEN** zeigt das Display keine Kraftkurven-Karte, und die übrigen Werte nutzen den Platz

### Requirement: Schlaglänge zur Kraftkurve
Liefert die Quelle zur Kraftkurve die Durchzugslänge desselben Schlags, SHALL die Kraftkurven-Karte diese Schlaglänge in ganzen Zentimetern neben der Kurve des letzten Schlags zeigen, etwa „102 cm“. Fehlt die Länge, MUST die Angabe entfallen, ohne einen Ersatzwert wie „0 cm“ zu zeigen.

#### Scenario: Schlag mit Länge
- **WHEN** der PM5 nach einem Durchzug von 1.06 m die Kurve dieses Schlags liefert
- **THEN** zeigt die Karte die neue Kurve zusammen mit „106 cm“

#### Scenario: Kurve ohne Länge
- **WHEN** zu einer Kurve keine Durchzugslänge vorliegt, etwa weil der Wert fehlt oder 0 ist
- **THEN** zeigt die Karte die Kurve ohne Längenangabe

### Requirement: Absolute Kraftskala
Die Kraftkurven SHALL auf einer absoluten Kraftskala in Newton stehen, die bei 1000 N beginnt und nicht auf die Spitze der gezeigten Kurven normiert wird. Geht eine Kurve darüber, MUST die Skala in Stufen von 500 N wachsen, statt die Kurve abzuschneiden; innerhalb einer Session MUST sie nie wieder kleiner werden. Hilfslinien alle 500 N SHALL die Skala zeigen, beschriftet, wo der Platz reicht, und neben der Kurve SHALL die Spitzenkraft des letzten Schlags stehen.

#### Scenario: Schwacher Schlag erscheint niedriger als kräftiger
- **WHEN** auf einen Schlag mit 600 N Spitzenkraft einer mit 300 N folgt
- **THEN** reicht die Kurve des schwächeren Schlags nur halb so hoch wie die des kräftigeren, statt wie diese bis zum oberen Rand

#### Scenario: Schlag über der Skala
- **WHEN** ein Schlag 1200 N Spitzenkraft erreicht, während die Skala bis 1000 N reicht
- **THEN** reicht die Skala bis 1500 N, die Kurve wird vollständig gezeichnet und nicht abgeschnitten

#### Scenario: Skala springt nicht zurück
- **WHEN** nach einem Schlag, der die Skala auf 1500 N erweitert hat, schwächere Schläge folgen
- **THEN** bleibt die Skala bis zum Ende der Session bei 1500 N

#### Scenario: Neue Session
- **WHEN** die Quelle wechselt oder die Schlagnummern neu beginnen
- **THEN** beginnt die Skala wieder bei 1000 N

#### Scenario: Hilfslinien und Spitzenkraft
- **WHEN** eine Kurve mit 620 N Spitzenkraft in der grossen Karte gezeigt wird
- **THEN** zeigt die Karte Hilfslinien bei 500 N und 1000 N mit Beschriftung und daneben „620 N“

### Requirement: Gurt-Zustand im Live-Display
Ist ein Gurt gekoppelt und die Quelle ein echtes Rudergerät (PM5 oder FTMS), SHALL das Live-Display den Verbindungszustand des Gurts in der Kopfzeile neben dem des Rudergeräts anzeigen. Ohne gekoppelten Gurt oder mit einem Simulator oder Replay als Quelle MUST NOT ein Gurt-Zustand erscheinen.

#### Scenario: Gurt verbunden
- **WHEN** der Nutzer mit Rudergerät und verbundenem Gurt rudert
- **THEN** zeigt das Live-Display beide Verbindungen als verbunden

#### Scenario: Gurt wiederverbindend
- **WHEN** der Gurt die Verbindung verliert, das Rudergerät aber verbunden bleibt
- **THEN** zeigt das Live-Display den Gurt als wiederverbindend und das Rudergerät weiter als verbunden

#### Scenario: Simulator mit gekoppeltem Gurt
- **WHEN** der Nutzer mit einem Simulator rudert und einen Gurt gekoppelt hat
- **THEN** zeigt das Live-Display keinen Gurt-Zustand

### Requirement: Bereitschaft vor dem ersten Schlag anzeigen
Ist eine Session mit Workout bereit, aber noch nicht gestartet, SHALL das Live-Display deutlich zeigen, dass die Session mit dem ersten Schlag startet. Der Hinweis MUST verschwinden, sobald die Session gestartet ist.

#### Scenario: Workout gewählt
- **WHEN** der Nutzer ein Workout wählt und noch nicht rudert
- **THEN** zeigt das Display „Bereit – startet mit dem ersten Schlag“ (englisch „Ready – starts with your first stroke“)

#### Scenario: Erster Schlag
- **WHEN** der Nutzer den ersten Schlag rudert
- **THEN** verschwindet der Hinweis und die Zeit beginnt zu laufen

### Requirement: Pause anzeigen
Ist die laufende Session pausiert, SHALL das Live-Display das deutlich und aus Ruderdistanz lesbar mit „Pause“ zeigen (englisch „Paused“). Die Werte der Session MUST dabei auf dem Stand vor der Pause stehen bleiben. Der Hinweis MUST verschwinden, sobald die Session weiterläuft. In einer Pause MUST das Display die Werte nicht als veraltet kennzeichnen, solange weiter Daten eintreffen.

#### Scenario: Nutzer hört auf zu rudern
- **WHEN** die Session pausiert
- **THEN** zeigt das Display „Pause“, und die Zeit der Session steht still

#### Scenario: Weiterrudern
- **WHEN** der Nutzer in der Pause wieder rudert
- **THEN** verschwindet der Hinweis und die Zeit läuft weiter

### Requirement: Widerstandsstufe von Hand verstellen
Ist ein Rudergerät verbunden, dessen Stufe sich setzen lässt, SHALL die Live-Anzeige bei der Stufe unter den Watt eine Möglichkeit bieten, die Stufe um eine Stufe zu senken oder zu erhöhen, frei und mit Workout. Die Bedienelemente MUST aus Ruderdistanz treffbar sein und dürfen die Kernwerte nicht verdecken. An der Grenze des Bereichs MUST die jeweilige Richtung gesperrt sein. Lässt sich die Stufe nicht setzen, SHALL die Anzeige wie bisher nur die gemeldete Stufe zeigen.

#### Scenario: Stufe erhöhen
- **WHEN** das Gerät Stufe 6 meldet und der Nutzer auf + tippt
- **THEN** sendet die App Stufe 7 und die Anzeige zeigt „Stufe 7“, sobald das Gerät sie meldet

#### Scenario: Obere Grenze
- **WHEN** das Gerät Stufe 15 meldet und höchstens 15 erlaubt
- **THEN** ist + gesperrt

#### Scenario: Mehrmals schnell getippt
- **WHEN** der Nutzer bei Stufe 6 dreimal schnell auf + tippt
- **THEN** landet das Gerät auf Stufe 9

#### Scenario: Gerät ohne setzbare Stufe
- **WHEN** ein Gerät seine Stufe meldet, das Setzen aber nicht unterstützt
- **THEN** steht unter den Watt nur „Stufe 6“, ohne − und +

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
