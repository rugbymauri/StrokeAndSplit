# Spec Delta

## Purpose

Verbindet die App direkt per Bluetooth LE mit einem Brustgurt, damit Puls und RR-Intervalle unabhängig vom Rudergerät und ohne dessen Kopplungsmenü ankommen.

## ADDED Requirements

### Requirement: Brustgurte in der Nähe finden
Die App SHALL auf Anfrage nach Bluetooth-Geräten suchen, die den Standard-Heart-Rate-Service anbieten, und sie mit ihrem Namen auflisten. Andere Bluetooth-Geräte, auch PM5 und FTMS-Rudergeräte, MUST NOT in dieser Liste erscheinen.

#### Scenario: Gurt angelegt und in Reichweite
- **WHEN** der Nutzer die Gurt-Suche startet und einen Brustgurt trägt
- **THEN** erscheint der Gurt mit seinem Namen (z.B. „Polar H10 1A2B3C4D“) in der Liste

#### Scenario: Kein Gurt gefunden
- **WHEN** die Gurt-Suche 15 Sekunden läuft, ohne einen Gurt zu finden
- **THEN** zeigt die App einen Hinweis mit Tipps: Gurt anfeuchten und anlegen, Gurt von anderen Apps oder Uhren trennen

### Requirement: Gurt koppeln und merken
Der Nutzer SHALL in „Geräte wählen“ vor dem Startbildschirm optional einen gefundenen Gurt koppeln können. Die App MUST sich den gekoppelten Gurt über einen Neustart hinweg merken und den Nutzer den Gurt dort wechseln oder vergessen lassen. Ohne Gurt MUST „Weiter“ möglich sein, sobald ein Rudergerät gewählt ist. Der Startbildschirm SHALL den gekoppelten Gurt in der Gerätezeile neben dem Rudergerät zeigen.

#### Scenario: Gurt koppeln
- **WHEN** der Nutzer in „Geräte wählen“ einen Gurt aus der Liste wählt
- **THEN** zeigt „Geräte wählen“ diesen Gurt als gekoppelt an, auch nach einem Neustart der App

#### Scenario: Gurt wechseln
- **WHEN** der Nutzer bei gekoppeltem Gurt einen anderen Gurt aus der Liste wählt
- **THEN** ist nur noch der neue Gurt gekoppelt

#### Scenario: Gurt vergessen
- **WHEN** der Nutzer den gekoppelten Gurt vergisst
- **THEN** verbindet sich die App mit keinem Gurt mehr, bis wieder einer gekoppelt ist

#### Scenario: Weiter ohne Gurt
- **WHEN** der Nutzer ein Rudergerät gewählt und keinen Gurt gekoppelt hat
- **THEN** führt „Weiter“ zum Startbildschirm, und die Gerätezeile zeigt nur das Rudergerät

#### Scenario: Gurt in der Gerätezeile
- **WHEN** der Nutzer mit gekoppeltem Gurt den Startbildschirm öffnet
- **THEN** zeigt die Gerätezeile das Rudergerät und den Namen des Gurts

### Requirement: Gurt mit dem Rudergerät verbinden
Sobald die App mit einem echten Rudergerät über Bluetooth verbunden ist, einem PM5 oder einem FTMS-Rudergerät, und ein Gurt gekoppelt ist, SHALL sie sich ohne Nutzeraktion mit dem Gurt verbinden. Mit einem Simulator oder Replay als Quelle MUST NOT eine Verbindung zum Gurt aufgebaut werden.

#### Scenario: PM5 verbunden, Gurt gekoppelt
- **WHEN** der Nutzer sich mit einem PM5 verbindet und einen Gurt gekoppelt hat
- **THEN** verbindet sich die App auch mit dem Gurt und empfängt dessen Puls

#### Scenario: FTMS-Rudergerät verbunden, Gurt gekoppelt
- **WHEN** der Nutzer sich mit einem FTMS-Rudergerät verbindet und einen Gurt gekoppelt hat
- **THEN** verbindet sich die App auch mit dem Gurt und empfängt dessen Puls

#### Scenario: Simulator als Quelle
- **WHEN** der Nutzer einen Simulator startet und einen Gurt gekoppelt hat
- **THEN** baut die App keine Verbindung zum Gurt auf

#### Scenario: Replay als Quelle
- **WHEN** der Nutzer eine Session abspielt und einen Gurt gekoppelt hat
- **THEN** baut die App keine Verbindung zum Gurt auf

#### Scenario: Rudergerät getrennt
- **WHEN** der Nutzer die Verbindung zum Rudergerät bewusst trennt
- **THEN** trennt die App auch die Verbindung zum Gurt

### Requirement: Gurt-Ausfall unabhängig vom Rudergerät
Ein Abbruch oder Fehlschlag der Verbindung zum Gurt MUST NOT die Verbindung zum Rudergerät, das Live-Display oder eine laufende Session unterbrechen.

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
Scheitert die Verbindung zum Gurt, SHALL die App eine verständliche Meldung zeigen mit dem Hinweis, dass viele Gurte nur eine begrenzte Zahl gleichzeitiger Bluetooth-Verbindungen erlauben, etwa wenn der Gurt schon an einer Uhr oder am Rudergerät hängt.

#### Scenario: Gurt an einer Uhr verbunden
- **WHEN** die Verbindung zum Gurt scheitert, weil er bereits mit einer Uhr verbunden ist
- **THEN** zeigt die App die Meldung mit dem Hinweis, den Gurt von anderen Geräten zu trennen, und die Verbindung zum Rudergerät bleibt bestehen

### Requirement: Gurt-Zustand sichtbar machen
Die App SHALL den Verbindungszustand des Gurts (nicht gekoppelt, verbindend, verbunden, wiederverbindend, getrennt) getrennt vom Zustand des Rudergeräts anzeigen.

#### Scenario: Zustand im Live-Display
- **WHEN** der Nutzer mit Rudergerät und gekoppeltem Gurt im Live-Display ist
- **THEN** ist der Zustand des Gurts ohne Navigation neben dem des Rudergeräts erkennbar
