# Proposal

## Why

Wer eine Strecke rudern will, braucht heute eine Vorlage dafür. Für ein einmaliges Training, etwa „heute 30 min auf der Seerunde“, muss man also erst eine Vorlage anlegen, die danach in der Liste liegen bleibt. Ausserdem kann keine Vorlage eine Gesamtdauer: Sie kennt nur eine feste oder offene Rundenzahl. Eine Strecke soll sich deshalb direkt rudern lassen, mit Runden, einer Gesamtdauer oder offen, ohne dass dabei eine Vorlage entsteht.

## What Changes

- **„Rudern“ in der Detailansicht einer Strecke**: Der Button öffnet einen Start-Screen für diese Strecke.
- **Start-Screen mit drei Optionen**: Runden, Dauer oder offen. Sie schliessen sich aus, sichtbar ist nur die Eingabe der gewählten Option: die Rundenzahl (ab 1), die Dauer in Schritten von 1 min oder bei offen nur ein Hinweis. Darunter der Ghost-Schalter wie auf dem Vorlagen-Screen aus `template-screen` und „Starten“. Es wird keine Vorlage gespeichert.
- **Gesamtdauer**: Die Session endet von selbst, sobald die effektive Ruderzeit die Dauer erreicht. Pausen zählen nicht mit. Das Ende darf mitten in einer Runde liegen; diese Runde bleibt unvollständig und zählt wie heute in keiner Rangliste. Der äussere Ring des Fortschrittsrahmens zeigt die Ruderzeit bis zur Dauer.
- **Session ohne Vorlage auf einer Strecke**: Sie trägt Strecke und Rundenzahl bzw. geplante Dauer, aber keine Vorlage. In Liste und Zusammenfassung heisst sie wie die Strecke, etwa „Seerunde · 30 min“. Ihre Runden und Zonenfahrten zählen in den Ranglisten von Strecke und Zone. Einen Ghost der Vorlage und die Abstandszeile in der Pace-Box gibt es nicht, Runden- und Zonen-Ghost laufen, sofern der Schalter an ist.
- **Geplante Dauer gespeichert**: Die Session speichert die geplante Dauer, auch im Export `.strokesplit`. Ältere Dateien ohne Dauer bleiben lesbar.

Nicht Teil dieses Changes:

- Eine Gesamtdauer in Vorlagen, eine Rangliste „beste Distanz in 30 min“ oder eine Gesamtdistanz als vierte Option.
- Die Wahl auf dem Start-Screen merken. Jeder Aufruf beginnt mit Vorgabewerten.
- Eine Session ohne Vorlage nachträglich als Vorlage speichern.

## Capabilities

### New Capabilities

- `course-session-setup`: Eine Strecke direkt rudern: Einstieg über „Rudern“ in der Detailansicht der Strecke, Start-Screen mit Runden, Dauer oder offen, Grenzen und Vorgaben der Eingaben, Start ohne gespeicherte Vorlage.

### Modified Capabilities

- `course-rowing`: Eine Strecke lässt sich auch ohne Vorlage rudern, ihre Runden zählen in den Ranglisten von Strecke und Zone; eine Session kann nach einer Gesamtdauer aus effektiver Ruderzeit enden, auch mitten in einer Runde; der äussere Ring zeigt dann die Zeit. Die Zusammenfassung zeigt bei einer Session ohne Vorlage die Strecke und die geplante Länge.
- `session-recording`: Eine Session speichert die geplante Dauer und exportiert und importiert sie; die Session-Liste nennt bei einer Session ohne Vorlage Strecke und geplante Länge.
- `ghost`: Der Ghost-Schalter steht auch auf dem Start-Screen einer Strecke; ohne Vorlage gibt es keinen Ghost der Vorlage. Die Capability entsteht erst mit dem Archivieren von Change `ghost`.

## Impact

- **Code**:
  - `lib/data/sessions/`: Der Recorder startet nicht mehr nur mit einer `SessionTemplate`, sondern mit „Strecke + Runden, Dauer oder offen, optional Vorlage“. Das Ende nach Dauer kommt zum Ende nach der letzten Runde hinzu.
  - `lib/data/db/`: Schema 10 mit `sessions.planned_duration_ms` und Migration `from9To10`.
  - `lib/data/ghost/`, `lib/data/statistics/session_places.dart`: Keys und Platzmarken ohne Vorlagen-ID.
  - `lib/features/courses/course_detail_screen.dart`: Button „Rudern“. Neu ein Start-Screen unter `lib/features/courses/`.
  - `lib/features/live/`: äusserer Ring und Titel ohne Vorlage. `lib/features/sessions/`: Titel „Strecke · Dauer“.
  - `lib/l10n/*.arb`: Texte für den Start-Screen.
- **Daten**: Schema 9 → 10. `.strokesplit` bekommt ein optionales Feld für die geplante Dauer.
- **Andere Changes**: baut auf `template-screen` auf (Ghost-Wahl in der Aufnahme, Aufbau des Start-Screens). Erst nach `ghost` und `template-screen` archivieren, weil das `ghost`-Delta auf dessen Capability zielt und der Ghost-Schalter aus `template-screen` stammt.
- **Doku**: README-Abschnitte zu Strecken und zum Rudern.
