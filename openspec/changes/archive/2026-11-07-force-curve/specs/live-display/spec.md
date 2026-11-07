# Spec Delta

## ADDED Requirements

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
