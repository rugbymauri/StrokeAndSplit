# Design

## Context

Motivation und Umfang stehen in `proposal.md`. Der Name „AergRow“ steckt in drei Arten von Stellen: im sichtbaren Text, in technischen Kennungen der Plattformen und des Dart-Pakets sowie in gespeicherten Daten (Datenbankname, Dateiendung und Formatname der Session-Dateien). Nur die letzte Gruppe betrifft bestehende Nutzerdaten.

Das Design der App liegt im Claude-Design-Canvas „AergRow Frontend“. Dort stehen der Name auf dem Startbildschirm und der Canvas-Titel.

## Decisions

### D1: Schreibweisen

| Zweck | Schreibweise |
|---|---|
| Anzeigename | `Stroke & Split` |
| Dart-Paket, Binärname, Datenbank | `strokesplit` |
| App-ID / Bundle-ID | `ch.strokesplit.strokesplit` |
| Dateiendung | `.strokesplit` |
| Formatname Rohaufnahme | `strokesplit-raw` |
| Dateityp im Dateidialog | `Stroke & Split Session` |

*Alternative*: `strokeandsplit` als Kennung. Verworfen, weil sie länger ist und sich schlechter liest. `strokesplit` entspricht der kürzeren der beiden geprüften Domains.

### D2: Gespeicherte Daten

- **Session-Dateien**: Der Export schreibt `.strokesplit` mit `strokesplit-raw`. Der Import akzeptiert beide Endungen und beide Formatnamen. Die Test-Fixtures bleiben unverändert im alten Format. Sie belegen so die Rückwärtskompatibilität.
- **Datenbank**: Die App öffnet die Datenbank `strokesplit`. Existiert sie nicht, aber eine Datenbank `aergrow` am selben Ort, wird diese beim ersten Start umbenannt. Das betrifft vor allem Linux und macOS, wo der Speicherort nicht an der App-ID hängt. Unter Android und iOS liegt die alte Datenbank in der alten App und ist für die neue unsichtbar.
- **Android und iOS**: Eine neue App-ID ist eine neue App. Die alte bleibt installiert, bis der Nutzer sie entfernt. Für den Umzug dient der bestehende Export und Import. Eine automatische Übernahme gibt es nicht, weil die App bisher nur auf Testgeräten läuft.

*Alternative*: die App-ID `ch.aergrow.aergrow` behalten und nur den Anzeigenamen ändern. Damit bliebe die Installation erhalten, aber der alte Name stünde dauerhaft in der ID und später in den Store-Einträgen. Verworfen, solange es keine veröffentlichte Version gibt. Vor einer Store-Veröffentlichung ist die ID nicht mehr änderbar.

### D3: Reihenfolge

1. Anzeigename und sichtbare Texte.
2. Formatname und Endung mit Rückwärtskompatibilität.
3. Dart-Paket und Klassennamen in einem einzigen mechanischen Commit, damit der Diff überprüfbar bleibt.
4. Plattform-IDs und Datenbank-Umzug.
5. README, Makefile, Specs.

## Risks / Trade-offs

- **Konflikte mit offenen Branches**: Schritt 3 ändert jede Datei mit Imports. Deshalb erst nach dem Merge der offenen Branches umsetzen.
- **Verlust lokaler Daten auf dem Handy**, wenn die alte App vor dem Export gelöscht wird. Die README und der Hinweis beim ersten Start der neuen App weisen darauf hin.

## Open Questions

Keine. Entschieden (Nutzer, 2026-10-16):

- Anzeigename mit „&“: **„Stroke & Split“** (F9).
- App-ID **`ch.strokesplit`**, nicht mit der Domain des Herausgebers (F10).
- Vor der Umsetzung Domains sichern und eine Markenrecherche bei Swissreg, EUIPO und USPTO machen.
