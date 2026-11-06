# Spec Delta

## MODIFIED Requirements

### Requirement: Plätze in der Vorlagenwahl
Der Screen einer Vorlage SHALL die Plätze 1–3 ihrer Rangliste mit Wert, Pace und Datum zeigen, für die aktuelle Streckenlänge und Rundenzahl. Gibt es noch keinen Eintrag oder ist die Rundenzahl offen, MUST stattdessen ein Hinweis stehen und kein Platz.

#### Scenario: Zwei Einträge
- **WHEN** „Seerunde x3“ zweimal vollständig gerudert wurde und der Nutzer in der Vorlagenliste ihren Screen öffnet
- **THEN** sieht er Platz 1 und 2 mit Zeit, Pace und Datum

#### Scenario: Noch nie gerudert
- **WHEN** der Nutzer den Screen einer neuen Vorlage öffnet
- **THEN** steht dort, dass es noch keine Bestzeit gibt
