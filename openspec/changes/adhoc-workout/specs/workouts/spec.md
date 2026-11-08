## ADDED Requirements

### Requirement: Workout ohne Speichern rudern
Der Workout-Editor SHALL neben „Speichern“ „Starten ohne Speichern“ anbieten. Damit beginnt sofort eine Session auf den zusammengestellten Strecken mit der gewählten Länge, ohne dass ein Workout angelegt oder geändert wird. Dafür MUST mindestens eine Strecke gewählt sein; ein Name MUST NOT nötig sein und wird nicht verwendet. Die Session MUST zu keinem Workout gehören: Liste und Zusammenfassung nennen die Strecken und die geplante Länge, sie zählt in den Ranglisten ihrer Strecken und Zonen, aber in keiner Workout-Rangliste.

#### Scenario: Kette ohne Namen starten
- **WHEN** der Nutzer in einem neuen Workout ohne Namen „Einrudern“, „2 km Intervall“ und „Ausrudern“ mit 1 Runde wählt und „Starten ohne Speichern“ tippt
- **THEN** beginnt eine Session in Runde 1 auf „Einrudern“, und die Workout-Liste enthält kein neues Workout

#### Scenario: Ohne Strecke
- **WHEN** der Nutzer „Starten ohne Speichern“ tippt, ohne eine Strecke gewählt zu haben
- **THEN** startet keine Session und der Editor meldet die fehlende Strecke

#### Scenario: Bestehendes Workout geändert starten
- **WHEN** der Nutzer im Editor von „Seerunde x3“ die Rundenzahl auf 1 stellt und „Starten ohne Speichern“ tippt
- **THEN** läuft eine Session mit 1 Runde, und „Seerunde x3“ hat danach weiterhin 3 Runden

#### Scenario: Name in Liste und Zusammenfassung
- **WHEN** der Nutzer die Kette „Einrudern + 2 km Intervall + Ausrudern“ mit 1 Runde ohne Speichern gerudert hat
- **THEN** zeigen Session-Liste und Zusammenfassung „Einrudern + 2 km Intervall + Ausrudern · 1 Runde“ und keine Platzmarke für ein Workout

#### Scenario: Ranglisten
- **WHEN** die Session an einem Rudergerät vollständig gerudert wurde
- **THEN** steht der Abschnitt auf „2 km Intervall“ in der Rangliste dieser Strecke, aber die Session in keiner Workout-Rangliste

#### Scenario: Zurück im Editor
- **WHEN** der Nutzer die Session beendet und die Zusammenfassung schliesst
- **THEN** steht er wieder im Editor mit „Einrudern“, „2 km Intervall“, „Ausrudern“ und 1 Runde und kann das Workout speichern
