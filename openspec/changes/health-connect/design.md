# Design

## Context

Motivation: siehe proposal.md. Was übertragen wird: siehe `specs/health-export/spec.md`.

Stand im Code (2026-11-02):
- **Datenbank:** Sessions liegen in drift mit Schema 7.
  - `sessions`: Startzeit, Ende, Quelle (`pm5`, `ftms`, `simulator`, `replay`) und Vorlagenname.
  - `samples` pro Statusmeldung: `wallMs`, `activeMs`, `distanceDm`, `paceCs`, `watts`, `heartRate`, `calories`.
  - `laps`: `startWallMs`/`endWallMs` als Sessionzeit ohne Pausen, Distanz in dm.
  - `pauses`: auf der Wanduhr-Achse der Samples.
- **Sessionende:** `SessionRecorder.stop` speichert die Zusammenfassung und meldet die id über `finishedSessionProvider`. Das gilt auch nach der letzten Runde einer Vorlage.
- **Einstellungen:** Sprache, Rudergerät und Gurt stehen in `shared_preferences`, hinter einer Store-Schnittstelle mit Memory-Fake (F16, F18).
- **Android:** AGP 9.1, Kotlin 2.4, compileSdk 36 von Flutter. minSdk ist Flutters Vorgabe 24. `MainActivity` ist eine `FlutterActivity` ohne eigenen Plattformcode.

Health Connect, recherchiert am 2026-11-02:
- **Google Fit:** Die APIs werden nur bis Ende 2026 unterstützt. Health Connect ist der Ersatz für Apps auf dem Gerät.
- **Android-Versionen:** Ab Android 14 ist Health Connect Teil des Systems. Davor braucht es die Health-Connect-App aus dem Play Store, die ab API 28 läuft.
- **Datentypen:**
  - `ExerciseSessionRecord` kennt `EXERCISE_TYPE_ROWING_MACHINE`, Runden (`ExerciseLap` mit Länge) und Segmente (`ExerciseSegment`, darunter `PAUSE` und `ROWING_MACHINE`).
  - Leistung, Geschwindigkeit und Puls sind Serien-Records (`PowerRecord`, `SpeedRecord`, `HeartRateRecord`).
  - Distanz und Kalorien sind Intervall-Records (`DistanceRecord`, `TotalCaloriesBurnedRecord`).
  - Für Schlagzahl gibt es keinen Typ.
- **Eigene Daten:** Jeder Record kann eine `clientRecordId` mit `clientRecordVersion` tragen. Eine App darf nur ihre eigenen Records löschen, auch nach Zeitraum.
- **Pflichten:** Die App muss im Manifest einen Intent für den Datenschutz-Hinweis behandeln (`ACTION_SHOW_PERMISSIONS_RATIONALE`). Ab Android 14 braucht sie zusätzlich einen Activity-Alias für `VIEW_PERMISSION_USAGE`.
- **Das Paket `health` 13.3.2:**
  - Es kann Trainingseinheit, Distanz und Kalorien schreiben.
  - Puls und Geschwindigkeit schreibt es nur als einzelne Records mit je einem Wert.
  - Leistung, Runden, Segmente und `clientRecordId` für Trainingseinheiten fehlen.

## Goals / Non-Goals

**Goals:**
- Eine Session ergibt in Health Connect genau eine Trainingseinheit mit ihren Verläufen, auch bei wiederholter Übertragung.
- Die Abbildung von Session auf Health-Connect-Daten ist reiner Dart-Code, ohne Gerät testbar. Der Plattformcode schreibt nur, was er bekommt.
- Ohne eingeschaltete Übertragung und unter Linux ändert sich für den Nutzer nichts.

**Non-Goals:**
- Kein Hintergrunddienst, keine Warteschlange und kein WorkManager. Übertragen wird im Vordergrund, direkt nach dem Speichern oder auf Knopfdruck.
- Keine Health-Connect-Abstraktion für mehrere Plattformen. Die Schnittstelle bleibt so schmal, dass Apple Health später daneben passt, wird dafür aber nicht vorgebaut.

## Decisions

### D1: Eigener Kanal zu `connect-client` statt Paket `health`

Ein MethodChannel `ch.strokesplit/health_connect` mit einer kleinen Kotlin-Klasse ruft `androidx.health.connect:connect-client` direkt auf.

**Methoden:**
- `status` liefert verfügbar, Update nötig oder nicht installiert.
- `grantedPermissions`
- `requestPermissions`
- `openInstall` führt in den Play Store.
- `writeSession(map)`
- `launchAction` meldet, ob die App für den Datenschutz-Hinweis geöffnet wurde.

**`writeSession`** löscht zuerst die eigenen Records der betroffenen Typen im Zeitraum der Session. Danach fügt es alle Records der Session in einem einzigen `insertRecords`-Aufruf ein.

**Warum nicht `health`:**
- Eine Session von 30 min hätte mit dem Paket rund 1 800 Puls-Records mit je einem Wert, also ebenso viele Aufrufe. Das stösst an die Ratenbegrenzung von Health Connect.
- Leistung, Runden, Pausen-Segmente und das Ersetzen einer Trainingseinheit gingen mit dem Paket gar nicht.
- Der eigene Code ist überschaubar, rund 200 Zeilen Kotlin. Er hängt an einer offiziellen Google-Bibliothek statt an einem Community-Paket.

*Alternativen:*
- **Paket `health` für die Einheit, eigener Kanal für den Rest:** zwei Wege zu derselben API, ohne Gewinn.
- **Paket `health` forken:** Die Pflege des Forks kostet mehr als der eigene Kanal.

### D2: Ersetzen statt Verdoppeln

Jede Übertragung einer Session hat zwei Teile:
- **Löschen nach Zeitraum:** Zuerst löscht sie die eigenen Records der Typen Training, Distanz, Kalorien, Puls, Leistung und Geschwindigkeit im Zeitraum der Session. Das trifft auch Reste einer früheren Übertragung, deren Aufteilung anders war.
- **Ids zur Absicherung:** Jeder Record bekommt eine `clientRecordId` der Form `strokesplit-<Startzeit in UTC-ms>-<Typ>[-<Teil>]`. Die `clientRecordVersion` ist der Zeitpunkt der Übertragung. Die Startzeit statt der Datenbank-id hält die Kennung auch über einen Export und Import auf ein anderes Gerät stabil. Zwei Übertragungen im gleichen Moment überschreiben sich dann gegenseitig, statt sich zu verdoppeln.

Scheitert das Einfügen nach dem Löschen, gilt die Session als nicht übertragen (Spec „Status und Fehler“). Der Nutzer überträgt sie erneut.

### D3: Abbildung einer Session

Die reine Funktion `healthWorkoutOf(session, samples, laps, pauses, title)` liefert ein `HealthWorkout`. Der Kanal schreibt es eins zu eins.

**Zeitachse:**
- Wanduhrzeit eines Samples = `startedAt + wallMs`. Vor Schema 2 gab es kein `wallMs`, dann gilt `tMs`.
- Ende = `endedAt`, ohne Ende die Zeit des letzten Samples.
- Runden sind in Sessionzeit gespeichert. Sie werden über die Pausen auf die Wanduhr umgerechnet: Jede Pause, die vor einem Zeitpunkt beginnt, verschiebt ihn um ihre Dauer.

**Inhalt:**

| Health Connect | Quelle |
|---|---|
| Trainingseinheit `ROWING_MACHINE` | Zeitraum der Session. Titel ist der Vorlagenname, bei freiem Rudern der übersetzte Text für freies Rudern in der Sprache der App. |
| `DistanceRecord` | `distanceDm` der Session, über den ganzen Zeitraum |
| `TotalCaloriesBurnedRecord` | höchster `calories`-Wert der Samples. Fehlt er oder ist er 0, gibt es keinen Record. |
| `HeartRateRecord` | `heartRate` > 0 |
| `PowerRecord` | `watts` ≠ null |
| `SpeedRecord` | 500 m / Pace, nur für `paceCs` > 0 |
| `ExerciseLap` | Runden mit Länge in m |
| `ExerciseSegment` `PAUSE` | Pausen |

**Serien:**
- Pro Sekunde bleibt höchstens ein Wert, der letzte dieser Sekunde. Statusmeldungen kommen mehrmals pro Sekunde, und Health-Apps zeigen Sekundenwerte.
- Eine Serie wird in Records zu je höchstens 10 Minuten geteilt. So bleibt jeder Record weit unter den Grenzen von Health Connect, auch bei langen Sessions.

**Segmente:** Nur bei Pausen: `PAUSE`-Segmente für die Pausen, `ROWING_MACHINE`-Segmente für das Rudern dazwischen, lückenlos über die Einheit. Die Prüfung in `connect-client` 1.1.0 erlaubt beide in einer Rudergerät-Einheit (`PAUSE` gilt für jede Einheit, `ROWING_MACHINE` ist der Rudergerät-Einheit zugeordnet) und verlangt nur, dass Segmente sich nicht überlappen und in der Einheit liegen (Quellen gelesen am 2026-11-02). Ob Health Connect auf dem Gerät gleich prüft, zeigt Task 1.2. Lehnt es die Segmente ab, entfallen sie, und die Pausen gehen verloren.

Eine Runde, die im Moment einer Pause beginnt, beginnt nach der Pause; eine, die dann endet, endet vor ihr. Messwerte nach dem Ende der Session fallen weg.

### D4: Wann übertragen wird

**Automatisch:**
- `SessionRecorder.stop()` ruft nach dem Speichern `HealthExporter.sessionFinished` auf. `finishedSessionProvider` reicht nicht: Er meldet nur Sessions, die nach der letzten Runde von selbst enden, nicht die vom Nutzer gestoppten.
- Der `HealthExporter` (Riverpod) überträgt, wenn die Übertragung eingeschaltet ist und die Quelle `pm5` oder `ftms` ist. Sessions aus dem Simulator und aus Replays (Quelle `replay`) werden übersprungen.
- Ein Fehler landet in `healthExportFailureProvider`, den die Oberfläche als Snackbar zeigt.
- Er läuft ohne `await` im Hintergrund der UI. Die Zusammenfassung zeigt den Status, sobald er feststeht.
- Nach einem Absturz wiederhergestellte Sessions (`recoverInterrupted`) werden nicht automatisch übertragen.

**Nachträglich:**
- Ein Eintrag „An Health Connect senden“ im Menü der Session-Liste und eine Schaltfläche in der Zusammenfassung.
- Beide sind nur sichtbar, wenn die Übertragung eingeschaltet ist und die Session nicht aus dem Simulator oder einem Replay stammt.

### D5: Einstellung und Einstieg

**Speicherort:** Die Einstellung steht in `shared_preferences` unter `healthConnect`, mit Store und Memory-Fake wie bei der Sprache (F16, F18).

**Einstieg:**
- Die App hat keinen Einstellungsscreen. Deshalb kommt der Einstieg auf den Screen „Sessions“: eine Schaltfläche mit Health-Connect-Symbol in der App-Leiste. Sie öffnet ein Bottom-Sheet mit:
  - dem Schalter
  - dem Status: verfügbar, fehlt oder Berechtigung fehlt
  - einem Link zu Health Connect zum Verwalten der Berechtigungen
  - dem Link zum Datenschutz-Hinweis
- Unter Linux fehlt die Schaltfläche.

**Plattform:** `Platform.isAndroid` steckt hinter einem Provider `healthExportAvailableProvider`, damit Widget-Tests beide Fälle abdecken.

**Berechtigungen:** angefragt werden die Schreibrechte für Training, Distanz, Kalorien, Puls, Leistung und Geschwindigkeit.
- Ohne Trainingsrecht bleibt die Übertragung ausgeschaltet.
- Fehlen einzelne Rechte wie Puls, werden diese Records weggelassen, statt dass die Übertragung scheitert.

### D6: Schema 8

Neue Spalte `sessions.healthExportedAt` (DateTime, nullable). Die Migration von 7 auf 8 fügt die Spalte hinzu, bestehende Sessions bleiben `null`.

Export- und Importdateien nehmen die Spalte nicht auf. Eine importierte Session gilt als nicht übertragen. Ihre `clientRecordId` aus der Startzeit verhindert trotzdem ein Duplikat, wenn sie auf dem anderen Gerät schon übertragen war (D2).

*Alternative:* Status in `shared_preferences`. Verworfen: Er gehört zur Session und soll mit ihr gelöscht werden.

### D7: Android-Gerüst

- **MainActivity:** wird zur `FlutterFragmentActivity`. Die Berechtigungsanfrage von Health Connect braucht `registerForActivityResult` einer `ComponentActivity`.
- **minSdk:** wird 26, so verlangt es `connect-client`. Android 7 fällt damit weg; Health Connect selbst läuft erst ab Android 9.
- **Manifest:**
  - `uses-permission` für `health.WRITE_EXERCISE`, `WRITE_DISTANCE`, `WRITE_TOTAL_CALORIES_BURNED`, `WRITE_HEART_RATE`, `WRITE_POWER` und `WRITE_SPEED`.
  - `<queries>` für `com.google.android.apps.healthdata`.
  - Intent-Filter `androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE` an `MainActivity`.
  - Activity-Alias `ViewPermissionUsageActivity` mit `android.intent.action.VIEW_PERMISSION_USAGE` / `android.intent.category.HEALTH_PERMISSIONS` und `android:permission="android.permission.START_VIEW_PERMISSION_USAGE"` auf `MainActivity`.
- **Datenschutz-Hinweis:** Öffnet einer dieser Intents die App, meldet `launchAction` das an Dart, und die App zeigt die Datenschutz-Seite. Bei laufender App kommt die Meldung über `onNewIntent`.
- **Test im CI:** Ein Release-Build in CI (`make apk`) prüft, dass das Gerüst baut.

## Risks / Trade-offs

- **[`connect-client` braucht neuere Build-Werkzeuge]** → AGP 9.1 und compileSdk 36 erfüllen die Vorgaben schon. Task 1.1 baut zuerst nur das Gerüst mit der Abhängigkeit und prüft das CI-Image (Flutter-Image 3.44.0 mit eigenem SDK).
- **[Segmente werden abgelehnt]** → Task 1.2 schreibt eine Probe-Einheit am Gerät, bevor die Abbildung fertig ist. Rückfall: ohne Segmente (D3).
- **[Löschen nach Zeitraum trifft eigene Records einer überlappenden Session]** → Zwei Sessions der App überlappen zeitlich nicht, denn es läuft immer nur eine. Eine importierte Session von einem anderen Gerät mit überlappender Zeit ist praktisch ausgeschlossen und würde nur die eigene ältere Übertragung ersetzen.
- **[Übertragung läuft noch, wenn die App geschlossen wird]** → Die Session bleibt dann ohne Status und kann nachträglich übertragen werden. Ein doppelter Eintrag entsteht nicht (D2).
- **[Kalorien des Rudergeräts sind Gesamtkalorien inklusive Grundumsatz]** → Sie werden als `TotalCaloriesBurned` geschrieben, nicht als aktive Kalorien. So meldet sie auch der PM5.
- **[Ohne Play-Store-Erklärung]** → Für die Debug-APK aus GitLab nicht nötig. Vor einer Veröffentlichung im Play Store kommt sie unter „Offene Punkte“ in den Implementierungsplan.

## Migration Plan

- Schema 7 → 8 mit Migrationstest (drift-Schema-Dump `schema_v8`).
- Die Übertragung ist nach dem Update ausgeschaltet. Bestehende Sessions bleiben unverändert und können nachträglich übertragen werden.
- Rückweg: Ausschalten genügt. Was übertragen wurde, verwaltet der Nutzer in Health Connect.

## Open Questions

- Zeigt die Google-Health-App (Nachfolge von Google Fit) Trainingseinheiten fremder Apps aus Health Connect an? Prüft der Nutzer beim Gerätetest. Die Übertragung bleibt davon unabhängig richtig.
