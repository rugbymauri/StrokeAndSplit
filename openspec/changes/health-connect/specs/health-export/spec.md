# Spec Delta

## Purpose

Überträgt gespeicherte Rudersessions an die Gesundheitsplattform des Geräts, heute Health Connect unter Android. So erscheinen sie in Gesundheits- und Trainings-Apps wie Google Fit bzw. Google Health.

## ADDED Requirements

### Requirement: Übertragung einschalten
Unter Android SHALL der Nutzer die Übertragung an Health Connect ein- und ausschalten können. Beim Einschalten MUST die App die nötigen Schreibberechtigungen anfragen. Die Übertragung MUST erst als eingeschaltet gelten, wenn mindestens das Schreiben von Trainingseinheiten erlaubt ist. Ist Health Connect nicht verfügbar, MUST die App das sagen und zur Installation führen, wo das möglich ist. Die Einstellung MUST einen Neustart überdauern.

#### Scenario: Einschalten mit Berechtigung
- **WHEN** der Nutzer die Übertragung einschaltet und die Berechtigungen erteilt
- **THEN** ist die Übertragung eingeschaltet, auch nach einem Neustart der App

#### Scenario: Berechtigung verweigert
- **WHEN** der Nutzer die Übertragung einschaltet, das Schreiben von Trainingseinheiten aber ablehnt
- **THEN** bleibt die Übertragung ausgeschaltet, und die App sagt, dass die Berechtigung fehlt

#### Scenario: Health Connect fehlt
- **WHEN** der Nutzer die Übertragung auf einem Android-Gerät ohne Health Connect einschalten will
- **THEN** sagt die App, dass Health Connect fehlt, und bietet an, es zu installieren

### Requirement: Nur mit Health Connect
Auf Plattformen ohne Health Connect SHALL die App weder die Einstellung noch andere Bedienelemente der Übertragung zeigen.

#### Scenario: Linux
- **WHEN** der Nutzer die App unter Linux verwendet
- **THEN** zeigt die App nichts zur Übertragung an Health Connect

### Requirement: Abgeschlossene Sessions automatisch übertragen
Ist die Übertragung eingeschaltet, SHALL die App jede abgeschlossene Session von einem Rudergerät (PM5 oder FTMS) nach dem Speichern an Health Connect übertragen, ohne dass der Nutzer etwas tun muss. Sessions aus dem Simulator MUST NOT übertragen werden. Ein Fehler beim Übertragen MUST das Speichern und die Zusammenfassung der Session nicht beeinträchtigen.

#### Scenario: Session nach dem Rudern
- **WHEN** die Übertragung eingeschaltet ist und der Nutzer eine Session am PM5 beendet
- **THEN** erscheint sie in Health Connect, und die Zusammenfassung zeigt sie als übertragen

#### Scenario: Simulator
- **WHEN** die Übertragung eingeschaltet ist und der Nutzer eine Session mit dem Simulator beendet
- **THEN** wird sie nicht an Health Connect übertragen

#### Scenario: Übertragung ausgeschaltet
- **WHEN** die Übertragung ausgeschaltet ist und der Nutzer eine Session beendet
- **THEN** wird nichts an Health Connect übertragen

### Requirement: Session nachträglich übertragen
Bei eingeschalteter Übertragung SHALL der Nutzer jede gespeicherte Session aus der Session-Liste und der Zusammenfassung an Health Connect übertragen können, auch importierte und schon übertragene Sessions, nicht aber Sessions aus dem Simulator. Wird eine Session erneut übertragen, MUST sie ihre frühere Übertragung in Health Connect ersetzen, statt eine zweite Trainingseinheit anzulegen.

#### Scenario: Ältere Session übertragen
- **WHEN** der Nutzer eine Session von letzter Woche aus der Liste überträgt
- **THEN** erscheint sie in Health Connect mit ihrem ursprünglichen Datum und ihrer Uhrzeit

#### Scenario: Zweimal übertragen
- **WHEN** der Nutzer dieselbe Session zweimal überträgt
- **THEN** steht sie in Health Connect nur einmal

### Requirement: Trainingseinheit übertragen
Eine übertragene Session SHALL in Health Connect eine Trainingseinheit vom Typ Rudergerät sein: mit Beginn und Ende der Session, als Titel dem Namen der Vorlage bzw. einem Titel für freies Rudern, mit der geruderten Distanz und mit den Kalorien des Rudergeräts, sofern es welche gemeldet hat. Schlagzahl, Kraftkurve und Rohdaten MUST NOT übertragen werden.

#### Scenario: Freie Session
- **WHEN** der Nutzer eine freie Session über 2 000 m überträgt
- **THEN** zeigt Health Connect eine Rudergerät-Einheit mit dem Titel für freies Rudern, ihrem Zeitraum und 2 000 m

### Requirement: Verläufe, Runden und Pausen übertragen
Zur Trainingseinheit SHALL die App die Verläufe von Puls, Leistung und Geschwindigkeit aus den gespeicherten Messwerten übertragen, soweit vorhanden, dazu die Runden einer Vorlage mit ihrer Distanz und die Pausen der Session. Messwerte ohne Wert und ein Puls von 0 MUST ausgelassen werden.

#### Scenario: Vorlage mit Puls
- **WHEN** der Nutzer eine Session „Seerunde x3“ mit Brustgurt überträgt
- **THEN** zeigt Health Connect eine Rudergerät-Einheit „Seerunde x3“ mit Distanz, Kalorien, Pulsverlauf, Leistungs- und Geschwindigkeitsverlauf und drei Runden

#### Scenario: Freies Rudern ohne Puls
- **WHEN** der Nutzer eine freie Session ohne Puls an einem FTMS-Rudergerät ohne Kalorien überträgt
- **THEN** enthält die Einheit Zeitraum, Titel, Distanz, Leistung und Geschwindigkeit, aber weder Puls noch Kalorien

#### Scenario: Session mit Pause
- **WHEN** der Nutzer eine Session mit einer Pause von einer Minute überträgt
- **THEN** enthält die Einheit die Pause mit Beginn und Ende

### Requirement: Status und Fehler der Übertragung
Die App SHALL sich pro Session merken, wann sie zuletzt erfolgreich an Health Connect übertragen wurde, und das in der Zusammenfassung zeigen. Schlägt eine Übertragung fehl, MUST die App das melden, und die Session MUST als nicht übertragen gelten. Eine automatische Wiederholung findet nicht statt; der Nutzer kann die Session nachträglich übertragen. Wurde eine Berechtigung inzwischen entzogen, MUST die App das als Grund nennen.

#### Scenario: Fehler beim Übertragen
- **WHEN** Health Connect eine Übertragung ablehnt
- **THEN** meldet die App den Fehler, und die Zusammenfassung zeigt die Session als nicht übertragen

#### Scenario: Berechtigung entzogen
- **WHEN** der Nutzer die Schreibberechtigung in den Systemeinstellungen entzogen hat und eine Session überträgt
- **THEN** sagt die App, dass die Berechtigung fehlt, und bietet an, sie neu zu erteilen

#### Scenario: Bestehende Sessions nach dem Update
- **WHEN** die App mit Sessions aus einer früheren Version aktualisiert wird
- **THEN** gelten diese Sessions als nicht übertragen und bleiben sonst unverändert

### Requirement: Datenschutz-Hinweis
Die App SHALL eine Seite haben, die erklärt, welche Daten sie an Health Connect schreibt, dass sie keine Daten aus Health Connect liest und dass keine Daten das Gerät über die App verlassen. Health Connect und die Android-Berechtigungsverwaltung MUST diese Seite öffnen können.

#### Scenario: Hinweis aus den Berechtigungen
- **WHEN** der Nutzer in den Health-Connect-Berechtigungen von Stroke & Split auf den Datenschutz-Hinweis tippt
- **THEN** öffnet sich die App mit dieser Seite
