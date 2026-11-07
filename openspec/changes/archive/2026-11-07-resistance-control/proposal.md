# Proposal

## Why

Der Nutzer rudert auf einem Domyos Woodrower, einem FTMS-Rudergerät mit elektrischem Widerstand in 15 Stufen. Die App zeigt die Stufe schon an, verstellen lässt sie sich aber nur am Gerät. Für Intervalle heisst das: mitten in der Zone vom Griff loslassen und am Gerät drehen. Der Spike-Test am 2026-11-05 hat gezeigt, dass der Woodrower die Stufe über den FTMS Control Point annimmt. Damit kann die App die Stufe selbst setzen, von Hand und passend zur Zone einer Vorlage.

## What Changes

- **Stufe von Hand setzen**: Im Live-Display lässt sich die Stufe unter den Watt mit − und + verstellen, frei und mit Vorlage. Das gibt es nur bei Geräten, die das Setzen der Stufe melden. Beim PM5 und bei FTMS-Geräten ohne diese Funktion bleibt die Anzeige wie heute.
- **Stufe pro Zone**: Eine Zone kann optional eine Widerstandsstufe tragen. Sie steckt wie die Bänder als Kopie im Segment der Strecke. Beim Rudern einer Vorlage setzt die App die Stufe, sobald ein Segment mit Stufe beginnt.
- **Grundstufe**: Segmente ohne Stufe, also freie Abschnitte und Zonen ohne Stufe, rudert man auf der Grundstufe. Das ist die Stufe, die beim Start der Session gilt, oder die zuletzt von Hand gesetzte Stufe in einem solchen Segment. Die App legt dafür keine eigene Einstellung an.
- **Handänderung gilt bis zum nächsten Segment**: Verstellt der Nutzer die Stufe während eines Segments, in der App oder am Gerät, setzt die App sie bis zum Ende dieses Segments nicht zurück. Mit dem nächsten Segment gilt wieder dessen Stufe.
- **Pause ändert nichts**: Die App kann nicht unterscheiden, ob das Gerät die Stufe in einer Pause selbst ändert oder der Nutzer dreht. Jede vom Gerät gemeldete Änderung gilt deshalb als Handänderung, auch in der Pause. Nach einem Abbruch der Verbindung sendet die App die geltende Stufe dagegen erneut.
- **Simulator**: Im FTMS-Modus nimmt der Simulator die Stufe an und meldet sie zurück. So lässt sich alles ohne Gerät prüfen.
- **Ehrliche Kennzeichnung**: Das Setzen ist am Woodrower getestet, an anderen FTMS-Geräten nur nach Spezifikation.

Nicht Teil dieses Changes:

- Die Stufe auf die Leistung oder die Ranglisten anrechnen. Eine Runde auf Stufe 3 und eine auf Stufe 10 zählen gleich.
- Die gesendeten Befehle in den Rohdaten aufzeichnen. Die gemeldete Stufe steckt schon in den Rower Data.
- Andere FTMS-Ziele wie Zielleistung oder Simulationsparameter, etwa für Strömung auf einer Flusskarte.
- Eine Zone, die nur aus einer Stufe besteht. Eine Zone braucht weiterhin mindestens ein Band.

## Capabilities

### New Capabilities

- `resistance-control`: Wann und wie die App die Widerstandsstufe eines FTMS-Rudergeräts setzt: Fähigkeit und Bereich erkennen, Stufe senden, Stufe pro Segment, Grundstufe, Vorrang einer Handänderung, Pause und Wiederverbinden, Verhalten bei Ablehnung.

### Modified Capabilities

- `zones`: Eine Zone kann eine optionale Widerstandsstufe tragen, die in der Liste und im Editor sichtbar ist.
- `live-display`: Die Stufe unter den Watt lässt sich mit − und + verstellen, wenn das Gerät das Setzen erlaubt.
- `erg-simulation`: Der Simulator nimmt im FTMS-Modus eine gesetzte Stufe an und meldet sie zurück.

## Impact

- **Code**:
  - `lib/data/sources/ble/` (`rower_connector.dart`): Features und Stufenbereich lesen, Control Point offen halten, Stufe senden. `GattConnection` bekommt ein `read`.
  - `lib/data/sources/`: `ErgSource` bietet eine optionale Steuerung des Widerstands an. Der Simulator setzt sie um.
  - `packages/erg_protocol/`: Kodierung von „Set Target Resistance Level“, Dekodierung der Antwort, Features und Stufenbereich.
  - Eine neue, reine Logik entscheidet, welche Stufe gilt. Sie hängt an Segmentwechsel, Handänderung und Wiederverbinden.
  - `lib/features/live/`: −/+ an der Stufe. `lib/features/zones/`: Feld „Stufe“ im Editor und in der Liste.
- **Datenbank**: Schema 9 mit einer nullable Spalte für die Stufe in `zones` und `course_segments`. Die Kopie der Strecke in einer Session und das `.strokesplit`-Format bekommen ein optionales Feld. Alte Dateien ohne Stufe bleiben lesbar.
- **Andere Changes**: `device-types` (FTMS, Task 3.7) und `ui-design` (Task 5.15, Anzeige der Stufe) sind auf `main`, aber nicht archiviert. Dieser Change baut auf deren Stand auf. `health-connect` hat Schema 8, dieser Change nimmt 9.
- **Risiken**: Andere FTMS-Geräte kodieren die Stufe anders (s16 statt u8, mit oder ohne Faktor 10). Die App fällt deshalb bei „ungültiger Wert“ einmal auf s16 zurück. Ein Gerät kann die Kontrolle einem anderen Client geben. Dann bleibt die Stufe unverändert, und die App meldet es.
