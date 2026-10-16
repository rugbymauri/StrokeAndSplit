# Proposal

## Why

AergRow soll eine Rudergame-App für den Concept2 PM5 werden: Strecken mit Zonen, Ghost-Rennen, Progression. All das braucht ein verlässliches Fundament, das Live-Daten vom Erg liest, sie anzeigt und Sessions aufzeichnet. Das grösste technische Risiko des Projekts steckt in BLE und im PM5-Protokoll. Deshalb kommt das Fundament zuerst, bevor darauf Spielmechanik gebaut wird.

## What Changes

- Neue Flutter-App für **Android, iOS und Desktop** (Linux als primäre Desktop-Plattform), lokal-first ohne Backend.
- **Verbindung zum PM5 via Bluetooth LE**: suchen, verbinden, trennen, automatisch wiederverbinden. Die App liest nur, sie programmiert keine Workouts (kein CSAFE-Steuern).
- **Dekodierung der PM5-Rowing-Daten** in einheitliche Messwerte: Zeit, Distanz, Pace, Watt, Schlagzahl, Herzfrequenz, Kalorien, Schlagdaten und Workout-Zustand.
- **Simulierter Erg und Replay** aufgezeichneter Sessions als gleichwertige Datenquellen. So lässt sich ohne Erg entwickeln und testen.
- **Live-Display** mit den wichtigsten Kennzahlen, das auf Handy und Laptop lesbar ist.
- **Session-Aufzeichnung** in einer lokalen Datenbank, inklusive der Rohdaten. Dazu eine einfache Liste vergangener Sessions.

Nicht Teil dieses Changes und als spätere Changes vorgesehen: Strecken mit Zonen und Loops, Ghost, Progression, Sync und Concept2-Logbook, Kraftkurven-Auswertung.

## Capabilities

### New Capabilities

- `erg-connection`: PM5 per Bluetooth LE finden, verbinden, Verbindungszustand anzeigen, Verbindungsabbrüche behandeln.
- `rowing-telemetry`: PM5-Rohdaten in einheitliche Messwerte und Ereignisse übersetzen, unabhängig von der Datenquelle.
- `erg-simulation`: simulierter Ruderer und Replay aufgezeichneter Sessions als alternative Datenquellen.
- `live-display`: Live-Anzeige der aktuellen Rudermesswerte während einer Session.
- `session-recording`: Sessions starten und beenden, lokal speichern (Zusammenfassung und Rohdaten) und auflisten.

### Modified Capabilities

_Keine (neues Projekt)._

## Impact

- Neues Flutter-Projekt im Repo-Root. Abhängigkeiten: BLE-Plugin, lokale SQLite-Datenbank, State-Management.
- Plattform-Berechtigungen: Bluetooth auf Android (inkl. `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT`), Bluetooth-Usage-Description auf iOS, BlueZ auf Linux.
- Entwicklungsumgebung: Flutter-SDK muss installiert werden. Für iOS-Builds ist ein Mac nötig.
- Ein echter PM5 wird für die Verifikation der BLE-Schicht und für die erste Replay-Aufnahme gebraucht.
