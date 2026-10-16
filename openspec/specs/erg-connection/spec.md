# erg-connection Specification

## Purpose

Stellt die Verbindung zwischen der App und einem Concept2 PM5 über Bluetooth LE her und hält sie während des Ruderns stabil, damit Live-Daten zuverlässig ankommen.

## Requirements

### Requirement: PM5 in der Nähe finden
Die App SHALL auf Anfrage nach Concept2 PM5 in Bluetooth-Reichweite suchen und gefundene Geräte mit ihrem Namen (z.B. „PM5 430012345“) auflisten. Andere Bluetooth-Geräte MUST NOT angezeigt werden.

#### Scenario: PM5 eingeschaltet und in Reichweite
- **WHEN** der Nutzer die Suche startet und ein PM5 in Reichweite eingeschaltet ist
- **THEN** erscheint der PM5 mit seinem Namen in der Geräteliste

#### Scenario: Kein PM5 gefunden
- **WHEN** die Suche 15 Sekunden läuft, ohne einen PM5 zu finden
- **THEN** zeigt die App einen Hinweis, dass kein PM5 gefunden wurde, mit Tipps (PM5 aufwecken, andere Apps wie ErgData trennen)

### Requirement: Mit einem PM5 verbinden
Die App SHALL sich mit einem ausgewählten PM5 verbinden und die Rowing-Daten abonnieren. Danach MUST sie den Zustand „verbunden“ anzeigen.

#### Scenario: Erfolgreiche Verbindung
- **WHEN** der Nutzer einen PM5 aus der Liste auswählt
- **THEN** verbindet sich die App, zeigt „verbunden“ und beginnt Live-Daten zu empfangen

#### Scenario: Verbindung schlägt fehl
- **WHEN** der Verbindungsaufbau scheitert, z.B. weil eine andere App bereits verbunden ist
- **THEN** zeigt die App eine verständliche Fehlermeldung mit dem Hinweis, dass ein PM5 nur eine Bluetooth-Verbindung gleichzeitig erlaubt

### Requirement: Verbindungszustand sichtbar machen
Die App SHALL den aktuellen Verbindungszustand (getrennt, suchend, verbindend, verbunden, wiederverbindend) jederzeit sichtbar anzeigen.

#### Scenario: Zustand während des Ruderns
- **WHEN** der Nutzer im Live-Display ist
- **THEN** ist der Verbindungszustand ohne Navigation erkennbar

### Requirement: Automatisch wiederverbinden
Bricht die Verbindung zu einem PM5 unbeabsichtigt ab, SHALL die App bis zu 30 Sekunden lang versuchen, sich mit demselben PM5 wieder zu verbinden. Danach MUST sie in den Zustand „getrennt“ wechseln.

#### Scenario: Kurzer Abbruch
- **WHEN** die Verbindung abbricht und der PM5 innerhalb von 30 Sekunden wieder erreichbar ist
- **THEN** verbindet sich die App ohne Nutzeraktion neu und die Live-Daten laufen weiter

#### Scenario: Dauerhafter Abbruch
- **WHEN** der PM5 30 Sekunden lang nicht erreichbar ist
- **THEN** zeigt die App „getrennt“ und bietet an, erneut zu suchen

### Requirement: Bewusst trennen
Die App SHALL dem Nutzer erlauben, die Verbindung zum PM5 bewusst zu trennen. Nach einer bewussten Trennung MUST NOT ein automatisches Wiederverbinden erfolgen.

#### Scenario: Nutzer trennt
- **WHEN** der Nutzer „Trennen“ wählt
- **THEN** wird die Verbindung beendet, der PM5 ist für andere Apps frei und die App versucht keine Wiederverbindung

### Requirement: Bluetooth-Voraussetzungen prüfen
Die App SHALL vor der Suche prüfen, ob Bluetooth verfügbar und eingeschaltet ist und die nötigen Berechtigungen erteilt sind. Fehlt etwas, MUST sie dem Nutzer sagen, was fehlt.

#### Scenario: Bluetooth ausgeschaltet
- **WHEN** der Nutzer die Suche startet und Bluetooth ausgeschaltet ist
- **THEN** zeigt die App einen Hinweis, Bluetooth einzuschalten, statt eine leere Liste

#### Scenario: Berechtigung verweigert
- **WHEN** die Bluetooth-Berechtigung verweigert wurde
- **THEN** erklärt die App, warum die Berechtigung nötig ist, und wie sie erteilt werden kann
