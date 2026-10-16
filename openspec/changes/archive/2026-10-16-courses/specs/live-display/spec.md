# Spec Delta

## ADDED Requirements

### Requirement: Streckenangaben ohne Verlust der Lesbarkeit
Beim Rudern einer Vorlage SHALL das Live-Display Runde, Segment, Restdistanz bzw. Restzeit, Zielbänder und Zonenstatus zusätzlich zu den Kernwerten zeigen. Die Pace MUST dabei der grösste Wert bleiben, und alle Angaben MUST in Hoch- und Querformat auf Handy und Laptop ohne Scrollen sichtbar sein.

#### Scenario: Handy im Querformat mit Vorlage
- **WHEN** der Nutzer eine Vorlage mit Pace- und Schlagzahl-Band auf dem Handy im Querformat rudert
- **THEN** sind Kernwerte, Runde, Segment, Restdistanz und Zonenstatus ohne Scrollen sichtbar und die Pace ist der grösste Wert

### Requirement: Zonenstatus ohne Farbe erkennbar
Der Zonenstatus SHALL nicht allein über Farbe vermittelt werden. Ausserhalb der Zone MUST ein Richtungssymbol oder Text die Abweichung zeigen.

#### Scenario: Ausserhalb der Zone
- **WHEN** die Pace langsamer als das Band ist
- **THEN** zeigt das Display neben der Farbe einen Pfeil bzw. den Hinweis „schneller“
