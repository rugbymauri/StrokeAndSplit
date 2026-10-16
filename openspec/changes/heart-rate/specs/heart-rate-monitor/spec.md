# Spec Delta

## Purpose

Verbindet die App direkt per Bluetooth LE mit einem Brustgurt, damit Puls und RR-Intervalle unabhängig vom PM5 und ohne dessen Kopplungsmenü ankommen.

## ADDED Requirements

### Requirement: Brustgurte in der Nähe finden
Die App SHALL auf Anfrage nach Bluetooth-Geräten suchen, die den Standard-Heart-Rate-Service anbieten, und sie mit ihrem Namen auflisten. Andere Bluetooth-Geräte, auch PM5, MUST NOT in dieser Liste erscheinen.

#### Scenario: Gurt angelegt und in Reichweite
- **WHEN** der Nutzer die Gurt-Suche startet und einen Brustgurt trägt
- **THEN** erscheint der Gurt mit seinem Namen (z.B. „Polar H10 1A2B3C4D“) in der Liste

#### Scenario: Kein Gurt gefunden
- **WHEN** die Gurt-Suche 15 Sekunden läuft, ohne einen Gurt zu finden
- **THEN** zeigt die App einen Hinweis mit Tipps: Gurt anfeuchten und anlegen, Gurt von anderen Apps oder Uhren trennen

### Requirement: Gurt koppeln und merken
Der Nutzer SHALL in „Geräte wählen“ vor dem Startbildschirm einen gefundenen Gurt koppeln können. Die App MUST sich den gekoppelten Gurt über einen Neustart hinweg merken und den Nutzer den Gurt wechseln oder vergessen lassen.

#### Scenario: Gurt koppeln
- **WHEN** der Nutzer einen Gurt aus der Liste wählt
- **THEN** zeigt „Geräte wählen“ diesen Gurt als gekoppelt an, auch nach einem Neustart der App

#### Scenario: Gurt vergessen
- **WHEN** der Nutzer den gekoppelten Gurt vergisst
- **THEN** verbindet sich die App mit keinem Gurt mehr, bis wieder einer gekoppelt ist

### Requirement: Gurt mit dem PM5 verbinden
Sobald die App mit einem echten PM5 verbunden ist und ein Gurt gekoppelt ist, SHALL sie sich ohne Nutzeraktion mit dem Gurt verbinden. Mit Simulator oder Replay als Quelle MUST NOT eine Verbindung zum Gurt aufgebaut werden.

#### Scenario: PM5 verbunden, Gurt gekoppelt
- **WHEN** der Nutzer sich mit einem PM5 verbindet und einen Gurt gekoppelt hat
- **THEN** verbindet sich die App auch mit dem Gurt und empfängt dessen Puls

#### Scenario: Simulator als Quelle
- **WHEN** der Nutzer den Simulator startet und einen Gurt gekoppelt hat
- **THEN** baut die App keine Verbindung zum Gurt auf

#### Scenario: PM5 getrennt
- **WHEN** der Nutzer die Verbindung zum PM5 bewusst trennt
- **THEN** trennt die App auch die Verbindung zum Gurt

### Requirement: Gurt-Ausfall unabhängig vom PM5
Ein Abbruch oder Fehlschlag der Verbindung zum Gurt MUST NOT die Verbindung zum PM5, das Live-Display oder eine laufende Session unterbrechen.

#### Scenario: Gurt-Batterie leer während einer Session
- **WHEN** der Gurt während einer laufenden Session ausfällt
- **THEN** laufen Session und Live-Werte weiter, nur der Puls aus dem Gurt fehlt

### Requirement: Gurt automatisch wiederverbinden
Bricht die Verbindung zum Gurt unbeabsichtigt ab, SHALL die App bis zu 30 Sekunden lang versuchen, sich wieder mit demselben Gurt zu verbinden. Danach MUST sie den Gurt als getrennt anzeigen und einen erneuten Verbindungsversuch anbieten.

#### Scenario: Kurzer Abbruch
- **WHEN** der Gurt kurz die Verbindung verliert und innerhalb von 30 Sekunden wieder erreichbar ist
- **THEN** verbindet sich die App ohne Nutzeraktion neu und der Puls aus dem Gurt läuft weiter

#### Scenario: Dauerhafter Abbruch
- **WHEN** der Gurt 30 Sekunden lang nicht erreichbar ist
- **THEN** zeigt die App den Gurt als getrennt und bietet an, es erneut zu versuchen

### Requirement: Verständliche Meldung bei belegtem Gurt
Scheitert die Verbindung zum Gurt, SHALL die App eine verständliche Meldung zeigen mit dem Hinweis, dass viele Gurte nur eine begrenzte Zahl gleichzeitiger Bluetooth-Verbindungen erlauben, etwa wenn der Gurt schon an einer Uhr oder per Bluetooth am PM5 hängt.

#### Scenario: Gurt an einer Uhr verbunden
- **WHEN** die Verbindung zum Gurt scheitert, weil er bereits mit einer Uhr verbunden ist
- **THEN** zeigt die App die Meldung mit dem Hinweis, den Gurt von anderen Geräten zu trennen, und die Verbindung zum PM5 bleibt bestehen

### Requirement: Gurt-Zustand sichtbar machen
Die App SHALL den Verbindungszustand des Gurts (nicht gekoppelt, verbindend, verbunden, wiederverbindend, getrennt) getrennt vom Zustand des PM5 anzeigen.

#### Scenario: Zustand im Live-Display
- **WHEN** der Nutzer mit PM5 und gekoppeltem Gurt im Live-Display ist
- **THEN** ist der Zustand des Gurts ohne Navigation neben dem des PM5 erkennbar
