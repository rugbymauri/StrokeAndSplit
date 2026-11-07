# Proposal

## Why

Wer gegen den Ghost rudert, vergleicht sich mit seiner Bestleistung. Für eine lockere Ausfahrt oder ein Intervalltraining will man das nicht, heute läuft der Ghost aber bei jeder Vorlage mit. Dafür braucht es vor dem Start einen Ort, an dem man das abschalten kann. Die aufgeklappte Vorlagenkarte ist dafür zu eng: Sie zeigt schon Zonen, Podium und „Starten“, und ein Schalter mehr bläht die Liste weiter auf. Eine Vorlage bekommt deshalb einen eigenen Screen, auf dem man sie ansieht und startet.

## What Changes

- **Vorlagen-Screen**: Ein Tipp auf eine Vorlage in der Liste öffnet einen eigenen Screen statt die Karte aufzuklappen. Er zeigt Name, Segmentbalken, Zonenbänder, die Plätze 1–3, den Ghost-Schalter und „Starten“. Bearbeiten erreicht man von dort. **BREAKING** für die Bedienung: Karten klappen nicht mehr auf.
- **Kompakte Liste**: Die Vorlagenkarten zeigen nur noch Name, Details und Segmentbalken. Es gibt keine geöffnete oder ausgewählte Karte mehr.
- **„Nochmal“ entfällt**: Die Kachel auf dem Startbildschirm wird entfernt. Vorlagen erreicht man über „Rudern“. **BREAKING** für die Bedienung.
- **Ghost abschaltbar**: Auf dem Vorlagen-Screen schaltet ein Schalter den Ghost für die Session ab, die man von dort startet. Aus heisst: kein Ghost-Schiffchen auf einer der drei Spuren und keine Abstandszeile in der Pace-Box. Der Schalter steht bei jedem Öffnen des Screens auf an. Die Wahl wird nicht gespeichert.
- **Kein Umschalten während der Fahrt**: Ob ein Ghost läuft, steht mit dem Start fest. Das Live-Display bekommt keinen Schalter.

Nicht Teil dieses Changes:

- Die Wahl merken, global oder pro Vorlage.
- Einzelne Spuren abschalten.
- Festhalten, ob eine Session mit oder ohne Ghost gerudert wurde. Die Ranglisten zählen jede Session gleich.
- Eigene Screens für Strecken oder Zonen. Deren Detailansicht aus `statistics` bleibt, wie sie ist.

## Capabilities

### New Capabilities

Keine.

### Modified Capabilities

- `session-templates`: Eine Vorlage wird auf einem eigenen Screen angesehen und gestartet.
- `erg-connection`: „Nochmal“ fällt aus der Anforderung, eine bestehende Verbindung weiter zu nutzen. Die Anforderung entsteht erst mit dem Archivieren von Change `ui-design`.
- `ghost`: Der Ghost lässt sich vor dem Start einer Vorlage für diese Session abschalten. Die Capability entsteht erst mit dem Archivieren von Change `ghost`.
- `statistics`: Die Plätze 1–3 einer Vorlage stehen auf dem Vorlagen-Screen statt in der aufgeklappten Karte. Die Capability entsteht erst mit dem Archivieren von Change `statistics`.

## Impact

- **Code**:
  - `lib/features/templates/templates_screen.dart`: Karten ohne Aufklappen, Tipp öffnet den neuen Screen, `selectedTemplateId` entfällt.
  - `lib/features/connection/start_screen.dart`: Kachel „Nochmal“ und `rowAgainProvider` entfallen, ebenso die Texte `startAgain` und `startAgainDaysAgo`.
  - Neu `lib/features/templates/template_screen.dart`: Zonen, `TemplatePodium`, Ghost-Schalter, „Starten“, Bearbeiten.
  - `lib/features/connection/rower_connection.dart` (`startRowing`) und `lib/features/live/live_screen.dart`: ein Flag, ob der Ghost läuft. Ohne Ghost fallen `FrameGhost` und `ghostGap` weg.
  - `lib/l10n/*.arb`: Texte für den Schalter und den Screen.
- **Tests**: `test/features/templates/templates_screen_test.dart` zieht teilweise in einen Test des neuen Screens um. Die Gruppe „Nochmal“ in `start_screen_test.dart` entfällt. Neue Tests für den Schalter und das Live-Display ohne Ghost.
- **Daten**: keine. Kein neues Schema, nichts in den SharedPreferences.
- **Andere Changes**: `ui-design` (D6, Task 4.1: aufklappbare Karten und die Kachel „Nochmal“) und `statistics` (Plätze in der aufgeklappten Vorlage) werden in diesem Punkt abgelöst. `ui-design`, `ghost` und `statistics` müssen vor diesem Change archiviert werden, weil seine Deltas ihre Capabilities ändern.
- **Doku**: README-Abschnitte zu Startbildschirm, Vorlagen und Ghost.
