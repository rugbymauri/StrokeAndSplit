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
