# Spec Delta

## Purpose

Die Oberfläche von AergRow in der Sprache zeigen, die der Nutzer in der App wählt, zuerst Deutsch oder Englisch, und um weitere Sprachen erweiterbar bleiben.

## ADDED Requirements

### Requirement: Sprache in der App wählen
Die App SHALL Deutsch und Englisch als Sprache der Oberfläche anbieten. Der Nutzer MUST die Sprache in der App wählen können, jede Sprache steht dort in ihrer eigenen Schreibweise („Deutsch“, „English“). Die Wahl MUST sofort gelten, ohne Neustart, und über einen Neustart der App erhalten bleiben. Ohne Wahl MUST die App deutsch sein, unabhängig von der Systemsprache.

#### Scenario: Erster Start
- **WHEN** die App zum ersten Mal startet und das System auf Englisch eingestellt ist
- **THEN** ist die Oberfläche deutsch

#### Scenario: Auf Englisch umstellen
- **WHEN** der Nutzer in der Sprachwahl „English“ wählt
- **THEN** erscheinen alle Texte der Oberfläche sofort auf Englisch, z.B. „Rudergerät suchen“ als „Find rower“

#### Scenario: Wahl bleibt erhalten
- **WHEN** der Nutzer Englisch gewählt hat und die App neu startet
- **THEN** ist die Oberfläche englisch

### Requirement: Alle Texte übersetzt
Jeder Text der Oberfläche SHALL in jeder angebotenen Sprache vorliegen, auch Hinweise, Fehlermeldungen, Bestätigungen und Meldungen aus der Prüfung von Eingaben. Keine Sprache MUST Texte einer anderen Sprache zeigen.

#### Scenario: Fehlermeldung beim Verbinden auf Englisch
- **WHEN** die Oberfläche englisch ist und ein PM5 an einem BikeErg abgewiesen wird
- **THEN** erklärt die Meldung auf Englisch, dass nur Rudergeräte unterstützt werden

#### Scenario: Prüfung einer Zone auf Englisch
- **WHEN** die Oberfläche englisch ist und der Nutzer eine Zone ohne Band speichern will
- **THEN** nennt der Editor den Fehler auf Englisch

#### Scenario: Neue Sprache
- **WHEN** eine weitere Sprache dazukommt
- **THEN** braucht es dafür nur eine zusätzliche Übersetzungsdatei, und die Sprache erscheint in der Sprachwahl

### Requirement: Eigene Namen bleiben unübersetzt
Namen, die der Nutzer vergibt (Zonen, Strecken, Vorlagen), und Namen von Geräten SHALL in jeder Sprache so erscheinen, wie sie gespeichert sind.

#### Scenario: Vorlage auf Englisch
- **WHEN** die Oberfläche englisch ist und eine Vorlage „Seerunde x3“ heisst
- **THEN** steht sie als „Seerunde x3“ in der Liste

### Requirement: Formate nach Sprache
Datum, Uhrzeit und Dezimalzahlen SHALL im Format der gewählten Sprache erscheinen. Pace, Zeiten und Rundenzeiten MUST in jeder Sprache das Format des PM5 behalten (`2:05.3`, `12:34`).

#### Scenario: Datum und Dezimalzahl auf Deutsch
- **WHEN** die Oberfläche deutsch ist und eine Session am 15. Oktober 2026 um 18:30 mit Ø 22.5 Schlägen pro Minute gespeichert ist
- **THEN** zeigt die App „15.10.2026, 18:30“ und „22,5“

#### Scenario: Datum und Dezimalzahl auf Englisch
- **WHEN** die Oberfläche englisch ist
- **THEN** zeigt die App dieselbe Session mit „Oct 15, 2026, 18:30“ und „22.5“

#### Scenario: Pace in jeder Sprache gleich
- **WHEN** die Pace 2 Minuten 5,3 Sekunden pro 500 m beträgt
- **THEN** steht sie in jeder Sprache als „2:05.3“
