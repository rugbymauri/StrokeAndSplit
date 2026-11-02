# Proposal

## Why

Rudersessions bleiben heute in Stroke & Split. In der Gesundheits- oder Trainings-App, in der der Nutzer sonst seine Aktivitäten sieht, fehlen sie. Der Nutzer möchte sie in Google Fit sehen (Wunsch 2026-11-02). Google Fit nimmt keine neuen Apps mehr an, und seine APIs laufen Ende 2026 aus. Unter Android ist deshalb Health Connect der Weg. Daraus lesen Google Fit bzw. die Nachfolge-App Google Health, Samsung Health, Garmin, Strava und andere.

## What Changes

- **Schreiben in Health Connect:** Unter Android kann der Nutzer seine Sessions an Health Connect übertragen. Eine Session wird zu einer Trainingseinheit vom Typ „Rudergerät“. Dazu gehören Start und Ende, als Titel der Name der Vorlage oder „Freies Rudern“, Distanz, Kalorien des Rudergeräts, die Verläufe von Puls, Leistung und Geschwindigkeit, die Runden einer Vorlage und die Pausen.
- **Einschalten:** Der Nutzer schaltet die Übertragung einmal ein und erteilt dabei die Schreibberechtigung. Ab dann wird jede abgeschlossene Session von einem Rudergerät automatisch übertragen.
- **Nachträglich übertragen:** Eine gespeicherte Session kann der Nutzer aus der Liste oder der Zusammenfassung übertragen. Wird eine Session ein zweites Mal übertragen, ersetzt sie die erste, statt sie zu verdoppeln.
- **Status:** Die Zusammenfassung zeigt, ob und wann eine Session übertragen wurde. Ein Fehler wird gemeldet, und die Session bleibt zum erneuten Übertragen offen.
- **Datenbank:** Schema 8 merkt sich pro Session, wann sie übertragen wurde.
- **Datenschutz-Hinweis:** Android verlangt für Health Connect einen Hinweis, wozu die App die Daten nutzt. Die App zeigt ihn auf einer eigenen Seite.
- **Nur Android:** Unter Linux und auf anderen Plattformen gibt es die Übertragung und ihre Bedienelemente nicht.

Nicht Teil dieses Changes:
- Lesen aus Health Connect, etwa Puls oder Gewicht.
- Apple Health.
- Schlagzahl und Kraftkurve, weil Health Connect keinen passenden Datentyp hat.
- Entfernen aus Health Connect, wenn eine Session in der App gelöscht wird.
- Wiederholen im Hintergrund nach einem Fehler.
- Die Health-Apps-Erklärung in der Play Console. Sie wird erst mit einer Veröffentlichung im Play Store nötig.

## Capabilities

### New Capabilities

- `health-export`: Übertragen gespeicherter Sessions an die Gesundheitsplattform des Geräts (heute Health Connect unter Android): Einschalten und Berechtigung, automatisches und nachträgliches Übertragen, welche Daten wie übertragen werden, Ersetzen statt Verdoppeln, Status und Fehler, Datenschutz-Hinweis.

### Modified Capabilities

Keine. Die Session-Aufzeichnung bleibt unverändert, die Übertragung setzt auf gespeicherten Sessions auf.

## Impact

- **Android-Plattformcode:**
  - Ein eigener Kanal (MethodChannel) zu `androidx.health.connect:connect-client` schreibt die Trainingseinheit samt Verläufen. Begründung in Design D1.
  - `MainActivity` wird zur `FlutterFragmentActivity`.
  - Im Manifest kommen Schreibberechtigungen, die Health-Connect-Abfrage, der Intent für den Datenschutz-Hinweis und ein Activity-Alias hinzu.
  - Möglicherweise muss das Build-Setup angehoben werden (compileSdk 36, AGP ≥ 8.9.1, minSdk 26).
- **Dart:**
  - Ein Dienst `HealthExport` mit einer Android-Umsetzung und einer Fake-Umsetzung für Tests.
  - Die Abbildung einer Session aus Repository-Daten auf Health-Connect-Daten, rein und ohne Plattform testbar.
  - Eine Einstellung in `shared_preferences` wie bei Sprache und Gurt.
  - Ein Aufruf nach `SessionRecorder.stop`.
  - Bedienelemente in Session-Liste, Zusammenfassung und am Einstieg.
  - Eine Datenschutz-Seite.
  - Neue Texte in den ARB-Dateien.
- **Datenbank:** Schema 8 mit der Spalte `healthExportedAt` an `sessions` und einer Migration. Export- und Importdateien bleiben unverändert.
- **Abhängigkeiten:** keine neue Dart-Abhängigkeit. Im Android-Build kommt `connect-client` hinzu.
- **Tests:** Unit-Tests der Abbildung, Widget-Tests mit dem Fake, Migrationstest. Der Test auf dem Gerät mit Health Connect und einer Fit- bzw. Health-App macht der Nutzer.
