# erg-connection Specification

## Purpose

Stellt die Verbindung zwischen der App und einem Concept2 PM5 über Bluetooth LE her und hält sie während des Ruderns stabil, damit Live-Daten zuverlässig ankommen.

## Requirements

### Requirement: Rudergeräte in der Nähe finden
Die App SHALL auf Anfrage nach Rudergeräten in Bluetooth-Reichweite suchen: Concept2 PM5 und Geräte mit dem Bluetooth-Standard FTMS (Fitness Machine Service). Gefundene Geräte MUST mit ihrem Namen und ihrer Geräteart (PM5 oder FTMS) aufgelistet werden. Andere Bluetooth-Geräte MUST NOT angezeigt werden.

#### Scenario: PM5 eingeschaltet und in Reichweite
- **WHEN** der Nutzer die Suche startet und ein PM5 an einem RowErg in Reichweite eingeschaltet ist
- **THEN** erscheint der PM5 mit seinem Namen in der Geräteliste

#### Scenario: FTMS-Rudergerät in Reichweite
- **WHEN** der Nutzer die Suche startet und ein Rudergerät mit FTMS in Reichweite eingeschaltet ist
- **THEN** erscheint es mit seinem Namen und als FTMS-Gerät gekennzeichnet in der Geräteliste

#### Scenario: PM5, der auch FTMS anbietet
- **WHEN** ein PM5 sowohl seine Concept2-Schnittstelle als auch FTMS anbietet
- **THEN** erscheint er genau einmal in der Liste, als PM5

#### Scenario: Kein PM5 gefunden
- **WHEN** die Suche 15 Sekunden läuft, ohne ein Rudergerät zu finden
- **THEN** zeigt die App einen Hinweis, dass kein Rudergerät gefunden wurde, mit Tipps (Gerät aufwecken, andere Apps wie ErgData trennen, näher herangehen)

### Requirement: Mit einem Rudergerät verbinden
Die App SHALL sich mit einem ausgewählten Rudergerät verbinden und dessen Rudern-Daten abonnieren. Danach MUST sie den Zustand „verbunden“ anzeigen.

#### Scenario: Erfolgreiche Verbindung
- **WHEN** der Nutzer einen PM5 aus der Liste auswählt
- **THEN** verbindet sich die App, zeigt „verbunden“ und beginnt Live-Daten zu empfangen

#### Scenario: Erfolgreiche Verbindung mit einem FTMS-Rudergerät
- **WHEN** der Nutzer ein FTMS-Rudergerät aus der Liste auswählt
- **THEN** verbindet sich die App, zeigt „verbunden“ und beginnt Live-Daten zu empfangen

#### Scenario: Verbindung schlägt fehl
- **WHEN** der Verbindungsaufbau scheitert, z.B. weil eine andere App bereits verbunden ist
- **THEN** zeigt die App eine verständliche Fehlermeldung mit dem Hinweis, dass viele Rudergeräte nur eine Bluetooth-Verbindung gleichzeitig erlauben

### Requirement: Verbindungszustand sichtbar machen
Die App SHALL den aktuellen Verbindungszustand (getrennt, suchend, verbindend, verbunden, wiederverbindend) jederzeit sichtbar anzeigen.

#### Scenario: Zustand während des Ruderns
- **WHEN** der Nutzer im Live-Display ist
- **THEN** ist der Verbindungszustand ohne Navigation erkennbar

### Requirement: Automatisch wiederverbinden
Bricht die Verbindung zu einem Rudergerät unbeabsichtigt ab, SHALL die App bis zu 30 Sekunden lang versuchen, sich mit demselben Gerät wieder zu verbinden. Danach MUST sie in den Zustand „getrennt“ wechseln.

#### Scenario: Kurzer Abbruch
- **WHEN** die Verbindung abbricht und das Rudergerät innerhalb von 30 Sekunden wieder erreichbar ist
- **THEN** verbindet sich die App ohne Nutzeraktion neu und die Live-Daten laufen weiter

#### Scenario: Dauerhafter Abbruch
- **WHEN** das Rudergerät 30 Sekunden lang nicht erreichbar ist
- **THEN** zeigt die App „getrennt“ und bietet an, erneut zu suchen

### Requirement: Bewusst trennen
Die App SHALL dem Nutzer erlauben, die Verbindung zum Rudergerät bewusst zu trennen. Nach einer bewussten Trennung MUST NOT ein automatisches Wiederverbinden erfolgen.

#### Scenario: Nutzer trennt
- **WHEN** der Nutzer „Trennen“ wählt
- **THEN** wird die Verbindung beendet, das Rudergerät ist für andere Apps frei und die App versucht keine Wiederverbindung

### Requirement: Bluetooth-Voraussetzungen prüfen
Die App SHALL vor der Suche prüfen, ob Bluetooth verfügbar und eingeschaltet ist und die nötigen Berechtigungen erteilt sind. Fehlt etwas, MUST sie dem Nutzer sagen, was fehlt.

#### Scenario: Bluetooth ausgeschaltet
- **WHEN** der Nutzer die Suche startet und Bluetooth ausgeschaltet ist
- **THEN** zeigt die App einen Hinweis, Bluetooth einzuschalten, statt eine leere Liste

#### Scenario: Berechtigung verweigert
- **WHEN** die Bluetooth-Berechtigung verweigert wurde
- **THEN** erklärt die App, warum die Berechtigung nötig ist, und wie sie erteilt werden kann

### Requirement: Nur Rudergeräte zulassen
Die App SHALL ausschliesslich Rudergeräte unterstützen. Ein PM5 an einem SkiErg oder BikeErg und FTMS-Geräte, die keine Rudergeräte sind, MUST abgewiesen werden: möglichst schon in der Geräteliste, spätestens beim Verbinden. Beim Abweisen nach dem Verbinden MUST die App die Verbindung wieder trennen und sagen, warum.

#### Scenario: PM5 am SkiErg in der Liste
- **WHEN** ein PM5 in Reichweite ist, dessen Name ihn als SkiErg oder BikeErg ausweist
- **THEN** erscheint er nicht in der Geräteliste

#### Scenario: PM5 am BikeErg beim Verbinden erkannt
- **WHEN** der Nutzer einen PM5 auswählt, der nach dem Verbinden einen BikeErg als Gerätetyp meldet
- **THEN** trennt die App die Verbindung und zeigt den Hinweis, dass nur Rudergeräte unterstützt werden

#### Scenario: FTMS-Gerät ohne Rudern-Daten
- **WHEN** der Nutzer ein FTMS-Gerät auswählt, das keine Rudern-Daten anbietet, z.B. ein Indoor-Bike
- **THEN** trennt die App die Verbindung und zeigt den Hinweis, dass nur Rudergeräte unterstützt werden

#### Scenario: Unbekannter Gerätetyp am PM5
- **WHEN** ein PM5 einen Gerätetyp meldet, der weder als SkiErg noch als BikeErg bekannt ist
- **THEN** lässt die App die Verbindung zu

### Requirement: FTMS-Rudergerät zum Senden auffordern
Bietet ein FTMS-Rudergerät eine Steuerschnittstelle an, SHALL die App nach dem Verbinden die Steuerung anfordern und das Gerät auffordern, ein Training zu starten oder fortzusetzen. Lehnt das Gerät ab oder antwortet es nicht, MUST die Verbindung trotzdem bestehen bleiben. Die App MUST NOT das Gerät zurücksetzen oder ein laufendes Training beenden.

#### Scenario: Gerät sendet erst nach Aufforderung
- **WHEN** ein FTMS-Rudergerät mit Steuerschnittstelle verbunden wird
- **THEN** fordert die App die Steuerung an, sendet „Start/Fortsetzen“ und empfängt danach Live-Daten

#### Scenario: Gerät lehnt die Steuerung ab
- **WHEN** das Gerät die Anforderung der Steuerung ablehnt oder nicht innerhalb weniger Sekunden antwortet
- **THEN** bleibt die App verbunden und zeigt die Daten an, die das Gerät von sich aus sendet

#### Scenario: Bewusstes Trennen während des Trainings
- **WHEN** der Nutzer die Verbindung zu einem FTMS-Rudergerät trennt
- **THEN** sendet die App keinen Befehl, der das Training am Gerät beendet oder zurücksetzt

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
- **WHEN** das Rudergerät verbunden ist und der Nutzer „Frei rudern“ oder ein Workout startet
- **THEN** öffnet die App das Live-Display mit derselben Verbindung, ohne neu zu verbinden

#### Scenario: Anderes Gerät wählen
- **WHEN** ein Rudergerät verbunden ist und der Nutzer in „Geräte wählen“ ein anderes Gerät oder den Simulator wählt
- **THEN** trennt die App zuerst die bisherige Verbindung
