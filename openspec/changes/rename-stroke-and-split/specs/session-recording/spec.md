# Spec Delta

## ADDED Requirements

### Requirement: Session-Dateien unter dem neuen Namen
Exportierte Sessions SHALL die Endung `.strokesplit` und den Formatnamen `strokesplit-raw` tragen. Der Import MUST weiterhin Dateien mit der Endung `.aergrow` und dem Formatnamen `aergrow-raw` annehmen und daraus dieselbe Session erzeugen wie vor der Umbenennung.

#### Scenario: Export nach der Umbenennung
- **WHEN** der Nutzer eine Session exportiert
- **THEN** heisst die Datei `….strokesplit` und ihr Header nennt das Format `strokesplit-raw`

#### Scenario: Alten Export importieren
- **WHEN** der Nutzer eine vor der Umbenennung exportierte `.aergrow`-Datei importiert
- **THEN** erscheint die Session mit denselben Werten wie vor der Umbenennung

### Requirement: Lokale Daten nach der Umbenennung
Findet die App beim Start keine Datenbank unter dem neuen Namen, aber eine unter dem alten am selben Ort, SHALL sie diese übernehmen, sodass alle Sessions, Strecken und Vorlagen erhalten bleiben.

#### Scenario: Update auf dem Linux-Desktop
- **WHEN** der Nutzer auf dem Linux-Desktop die umbenannte Version zum ersten Mal startet
- **THEN** zeigt sie alle Sessions, Strecken und Vorlagen der bisherigen Version
