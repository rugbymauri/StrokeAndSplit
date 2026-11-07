# Spec Delta

## ADDED Requirements

### Requirement: Strecke ohne Vorlage rudern
Eine Session, die ohne Vorlage auf einer Strecke läuft, SHALL Runden, Abschnitte, Zonenstatus, Anteil in der Zone und Ergebnisse genauso messen, anzeigen und speichern wie eine Session auf einer Vorlage mit dieser Strecke. Ihre vollständigen Runden und Zonenfahrten MUST in den Ranglisten von Strecke und Zone zählen.

#### Scenario: Drei Runden ohne Vorlage
- **WHEN** der Nutzer „Seerunde“ ohne Vorlage mit 3 Runden rudert
- **THEN** zeigt das Live-Display „Runde 2 von 3“ und den aktuellen Abschnitt, und die Session endet nach der dritten Runde

#### Scenario: Rangliste der Strecke
- **WHEN** der Nutzer „Seerunde“ ohne Vorlage rudert und eine Runde in 4:05 schafft, schneller als alle bisherigen
- **THEN** steht diese Runde auf Platz 1 der Rangliste von „Seerunde“

### Requirement: Nach der Gesamtdauer beenden
Bei einer Session mit Gesamtdauer SHALL die App die Session automatisch beenden, sobald die Ruderzeit ohne Pausen die Dauer erreicht, und die Zusammenfassung zeigen. Liegt das Ende mitten in einer Runde, MUST diese Runde als unvollständig gespeichert werden.

#### Scenario: Ende mitten in der Runde
- **WHEN** der Nutzer 30 min auf „Seerunde“ rudert und nach 30 min Ruderzeit in Runde 8 bei 1.3 km von 2.4 km ist
- **THEN** endet die Session, Runde 8 ist unvollständig, und die Zusammenfassung erscheint

#### Scenario: Pause zählt nicht
- **WHEN** der Nutzer bei 30 min Dauer nach 20 min Ruderzeit 2 min pausiert
- **THEN** endet die Session erst nach weiteren 10 min Ruderzeit

#### Scenario: Zeitstrecke mit Gesamtdauer
- **WHEN** der Nutzer die Zeitstrecke „Vier Minuten“ 30 min lang rudert
- **THEN** sind 7 Runden vollständig und Runde 8 nach 2 min unvollständig

### Requirement: Gesamtdauer live anzeigen
Bei einer Session mit Gesamtdauer SHALL der äussere Ring des Fortschrittsrahmens den Anteil der Ruderzeit an der Dauer zeigen, ohne Rundengrenzen. Das Live-Display MUST die verbleibende Ruderzeit zeigen und die Runde ohne Gesamtzahl, etwa „Runde 3“.

#### Scenario: Halbzeit
- **WHEN** der Nutzer bei 30 min Dauer 15 min gerudert hat
- **THEN** ist der äussere Ring zur Hälfte gefüllt, und das Live-Display zeigt 15:00 verbleibend

### Requirement: Zusammenfassung ohne Vorlage
Die Zusammenfassung einer Session ohne Vorlage auf einer Strecke SHALL statt der Vorlage die Strecke und die geplante Länge nennen: die Rundenzahl, die Dauer oder „offen“. Sie MUST alle Runden wie bei einer Vorlage zeigen und keine Platzmarke für eine Vorlage.

#### Scenario: 30 min auf der Seerunde
- **WHEN** der Nutzer die Zusammenfassung einer Session mit 30 min auf „Seerunde“ öffnet
- **THEN** steht dort „Seerunde · 30 min“ mit allen Runden, die letzte als unvollständig markiert
