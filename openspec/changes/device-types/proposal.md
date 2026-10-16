# Proposal

## Why

AergRow funktioniert heute nur mit einem Concept2 PM5. Viele Rudergeräte anderer Hersteller sprechen den Bluetooth-Standard FTMS (Fitness Machine Service). Wer ein solches Gerät hat, soll Strecken, Zonen und später den Ghost genauso nutzen können. Ausserdem steckt der PM5 nicht nur im RowErg, sondern auch im SkiErg und BikeErg. Heute würde die App deren Daten ungeprüft als Rudern aufzeichnen. Jetzt ist der richtige Zeitpunkt, weil Strecken und Zonen schon und der Ghost bald auf den Messwerten aufbauen: Je früher die Datenschicht mehrere Protokolle trägt, desto weniger muss später umgebaut werden.

## What Changes

- **Nur Rudergeräte**: Die App unterstützt ausschliesslich Rudergeräte. Ein PM5 an einem SkiErg oder BikeErg wird erkannt und abgewiesen, möglichst schon in der Geräteliste, spätestens nach dem Verbinden anhand des vom PM5 gemeldeten Erg-Typs.
- **FTMS-Rudergeräte** als zweite Geräteart neben dem PM5: suchen (Service `0x1826`), verbinden, wiederverbinden und Rower Data lesen. FTMS ist das einzige Fremdprotokoll, herstellerspezifische Protokolle sind nicht vorgesehen.
- **Ein Decoder pro Protokoll, ein gemeinsames Ergebnis**: Rohpakete bleiben die Wahrheit und tragen künftig ihr Protokoll (PM5 oder FTMS). Beide Decoder liefern dieselben Messwerte und Ereignisse. FTMS-Daten werden nicht in PM5-Pakete übersetzt.
- **Optionale Schlagdetails**: Ein Schlag-Ereignis hat weiterhin Nummer, Zeit und Distanz. Durchzugslänge, Durchzugs- und Erholungszeit sowie Kräfte sind optional, weil FTMS sie nicht liefert. Fehlende Werte werden nicht erfunden. **BREAKING** für das Datenbankschema: die betroffenen Spalten werden nullable, eine Migration ist nötig.
- **Eigene Uhr und Reset-Erkennung bei FTMS**: Fehlt die Zeit im Paket, misst die App sie selbst. Fallen Distanz oder Zeit zurück, gilt das als Reset am Gerät, und die Session zählt ohne Rücksprung weiter.
- **Protokoll in Aufnahmen**: Sessions, `.aergrow`-Dateien und Spike-Mitschnitte vermerken das Protokoll, damit Replay und Import den richtigen Decoder wählen. Bestehende Dateien ohne Angabe gelten als PM5.
- **Verifikation ohne FTMS-Hardware**, da kein Gerät zur Verfügung steht:
  1. Unit-Tests mit Paketen nach Spezifikation, inklusive aller Flag-Kombinationen und fehlerhafter Pakete.
  2. Ein FTMS-Modus im Simulator, der die ganze Kette von Live-Display bis Export durchläuft.
  3. Ein Software-Rower unter `tool/`, der auf einem Linux-PC per BlueZ als FTMS-Rudergerät auftritt und PM5-Mitschnitte als FTMS-Daten sendet. Damit wird der echte Bluetooth-Weg geprüft, zum Beispiel vom Android-Handy aus.
- **Ehrliche Kennzeichnung**: FTMS gilt als „nach Spezifikation umgesetzt, ungetestet an echter Hardware“, analog zu iOS im README.

Nicht Teil dieses Changes:

- SkiErg und BikeErg als unterstützte Geräte.
- Andere Fremdprotokolle.
- Eine Auswertung der Kraftkurve.
- Die Frage, welche Herzfrequenz gilt, wenn FTMS-Gerät und separater Gurt beide eine liefern. Das entscheidet der Change `heart-rate`. Bis dahin reicht FTMS seine Herzfrequenz durch, so wie heute der PM5.

## Capabilities

### New Capabilities

_Keine._ Die Änderungen erweitern die bestehenden Capabilities um eine zweite Geräteart.

### Modified Capabilities

- `erg-connection`: Die Suche findet PM5 und FTMS-Rudergeräte und zeigt nur Rudergeräte. Ein PM5 an SkiErg oder BikeErg wird abgewiesen. Verbinden, Wiederverbinden und Trennen gelten für beide Gerätearten. Hinweise und Fehlermeldungen sind nicht mehr PM5-spezifisch.
- `rowing-telemetry`: Messwerte und Ereignisse kommen aus PM5- oder FTMS-Daten, mit gleicher Form und Bedeutung. Schlagdetails sind optional. Bei FTMS fehlt der Workout-Zustand, Zeit und Reset ermittelt die App selbst. Unplausible Werte aus FTMS werden verworfen.
- `erg-simulation`: Der Simulator kann wahlweise als PM5 oder als FTMS-Rudergerät Daten liefern. Die Anzeige der Datenquelle unterscheidet PM5 und FTMS-Gerät.
- `session-recording`: Das Überstehen eines Resets am Gerät gilt auch für FTMS. Die Rohdaten und das `.aergrow`-Format vermerken das Protokoll, und der Import wählt danach den Decoder.

## Impact

- **Code**: `lib/data/sources/` (neue FTMS-BLE-Quelle, Scan nach PM5 und FTMS, Abweisen von Nicht-RowErgs), `lib/features/connection/` (Geräteliste und Texte), Simulator und Replay. Das Package `packages/pm5_protocol/` wird voraussichtlich zu einem Protokoll-Package mit PM5- und FTMS-Teil umgebaut. Wie es heisst und aufgeteilt wird, entscheidet das Design.
- **Datenbank**: Schema-Migration (`schemaVersion` erhöhen, `make schema`) für nullable Schlagdetails und das Protokoll der Rohdaten.
- **Dateiformat**: Der `.aergrow`-Header bekommt ein Protokollfeld. Das Format bleibt abwärtskompatibel.
- **Werkzeuge**: neuer Software-Rower unter `tool/` (Linux, BlueZ als GATT-Peripheral). Der Spike schneidet zusätzlich FTMS mit.
- **Andere Changes**: Strecken und Zonen (`courses`, `zones`, bereits auf `main`) brauchen nur Pace, Schlagzahl, Zeit und Distanz, und die liefert FTMS. Die Migration baut auf deren Schema 3 auf. Mit `heart-rate` überschneidet sich die Herzfrequenz aus FTMS, und beide ändern dieselben Requirements in `rowing-telemetry` und `session-recording`: `heart-rate` wird nach dem Archivieren dieses Changes auf dessen Text angepasst.
- **Risiken**: Manche Geräte senden erst nach einem Start über den FTMS Control Point (`0x2AD9`). Hersteller weichen vom Standard ab, etwa mit falschen Flags, 0 statt „kein Wert“ oder anderen Einheiten. Beides lässt sich ohne echte Hardware nur nach Spezifikation und defensiv abfangen.
