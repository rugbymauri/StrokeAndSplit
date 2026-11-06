# Spec Delta

## MODIFIED Requirements

### Requirement: Verbindung über das Rudern hinaus halten
Die App SHALL die Verbindung zum Rudergerät bzw. zum Simulator nach dem Rudern bestehen lassen, bis der Nutzer sie auf dem Startbildschirm trennt, ein anderes Gerät wählt oder die App beendet. Solange die Verbindung besteht, MUST der Startbildschirm das Gerät als verbunden zeigen und „Trennen“ anbieten. „Rudern“ und „Frei rudern“ MUST eine bestehende Verbindung nutzen, ohne neu zu verbinden.

#### Scenario: Fertig nach der Session
- **WHEN** der Nutzer nach „Session beenden“ in der Zusammenfassung „Fertig“ wählt
- **THEN** zeigt die App den Startbildschirm, und das Rudergerät bleibt verbunden

#### Scenario: Zurück aus dem Live-Display
- **WHEN** der Nutzer im Live-Display zurück geht, mit der Zurück-Geste oder auf dem Desktop mit Esc
- **THEN** zeigt die App den Startbildschirm, und das Rudergerät bleibt verbunden

#### Scenario: Verbunden auf dem Startbildschirm
- **WHEN** das Rudergerät „PM5 430000001 Row“ verbunden ist und der Startbildschirm erscheint
- **THEN** zeigt die Gerätezeile „PM5 430000001 Row“, „Verbunden“ und den Button „Trennen“

#### Scenario: Trennen auf dem Startbildschirm
- **WHEN** der Nutzer auf dem Startbildschirm „Trennen“ wählt
- **THEN** wird die Verbindung beendet, die App versucht keine Wiederverbindung, und die Gerätezeile zeigt das Gerät wieder als nicht verbunden

#### Scenario: Nochmals rudern mit bestehender Verbindung
- **WHEN** das Rudergerät verbunden ist und der Nutzer „Frei rudern“ oder eine Vorlage startet
- **THEN** öffnet die App das Live-Display mit derselben Verbindung, ohne neu zu verbinden

#### Scenario: Anderes Gerät wählen
- **WHEN** ein Rudergerät verbunden ist und der Nutzer in „Geräte wählen“ ein anderes Gerät oder den Simulator wählt
- **THEN** trennt die App zuerst die bisherige Verbindung
