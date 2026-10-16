# Design

## Context

Motivation und Umfang stehen in `proposal.md`. Gestaltung: Claude-Design-Canvas **AergRow Frontend** (privat, Freigabe über das Share-Menü):

| Screen im Canvas | Inhalt |
|---|---|
| Zonenliste | Tab „Zonen“, nach Achse gruppiert, mit Länge, Bändern und Verwendung („in 2 Strecken“, „nicht verwendet“) |
| Zonen-Editor | Name, Achse, Länge, Pace- und Schlagzahl-Band, Hinweis auf betroffene Strecken, Löschen |
| Strecken-Editor | Name, Achse, Länge, Ablauf als Balken, Liste aus freien Lücken und eingebauten Zonen mit Startposition, „Zone einbauen“ |
| Zone einbauen | Auswahl der Zone (andere Achse ausgegraut), Startposition, Vorschau mit Prüfung auf Überschneidung |
| Streckenliste | Strecken mit Ablaufbalken und verwendeten Zonen |

Ausgangslage aus `courses`: Eine Streckenversion speichert ihre Segmente in `course_segments` (Position, Länge, Bänder). Der `LapTracker` bekommt diese Segmente und bewertet die Zonen. Sessions verweisen auf die geruderte Version.

## Goals / Non-Goals

**Goals:**
- Runden-Logik, Zonenbewertung und gespeicherte Rundenergebnisse bleiben unverändert.
- Alte Sessions zeigen nach der Migration dieselben Runden und Anteile in der Zone wie vorher.
- Jede Streckenversion ist weiterhin für sich vollständig, auch wenn die Zone später geändert oder gelöscht wird.

**Non-Goals:**
- Zonen über die Achsengrenze hinweg (Zeit-Zone in Distanzstrecke).
- Länge einer Zone pro Strecke überschreiben.

## Decisions

### D1: Zone als Bibliothekseintrag, Version als Abschnitts-Schnappschuss

```
zones            (id, name, axis, length, paceFastDs?, paceSlowDs?,
                  spmMin?, spmMax?, deletedAt?)
course_segments  (versionId, position, start, length,
                  paceFastDs?, paceSlowDs?, spmMin?, spmMax?,
                  zoneId?, zoneName?)          -- zoneId/zoneName neu
```

Die bearbeitbare Definition einer Strecke ist ihre Länge plus eine Liste von Einbauten `(zoneId, start)`. Gespeichert wird sie als aufgelöste Abschnitte der aktuellen Version: Abschnitte mit `zoneId` sind Einbauten und tragen eine Kopie der Bänder und des Namens. Abschnitte ohne `zoneId` sind freie Lücken ohne Band. Damit braucht der `LapTracker` nichts Neues, und eine alte Version bleibt lesbar, auch wenn die Zone sich ändert oder gelöscht ist.

*Alternative*: eine eigene Tabelle für Einbauten und das Auflösen erst beim Rudern. Verworfen, weil dann eine geruderte Version von der aktuellen Zone abhinge und sich rückwirkend ändern würde.

### D2: Auflösen einer Strecke

Eine reine Funktion `resolve(length, placements, zones)` sortiert die Einbauten nach Start, prüft Achse, Lage innerhalb der Strecke und Überschneidungen und füllt die Lücken mit freien Abschnitten. Lücken der Länge 0 entstehen nicht. Die Funktion liefert entweder die Abschnitte oder einen Fehler mit der betroffenen Zone.

### D3: Zone ändern

Speichert der Nutzer eine Zone, löst die App jede nicht gelöschte Strecke, die sie enthält, neu auf und wendet die bestehende Versionsregel aus `courses` an: Ist die aktuelle Version schon gerudert, entsteht eine neue Version, sonst wird sie überschrieben. Ergibt das Auflösen einen Fehler, etwa weil die verlängerte Zone jetzt eine andere überschneidet oder über das Streckenende ragt, speichert die App die Zone nicht und nennt die betroffenen Strecken. Alles läuft in einer Transaktion.

Die Achse einer Zone lässt sich nur ändern, solange sie in keiner Strecke steckt.

### D4: Zone löschen

Nach Bestätigung mit der Liste der betroffenen Strecken wird die Zone weich gelöscht. Ihre Einbauten werden aus den Strecken entfernt, die Stellen werden frei. Für geruderte Strecken entsteht dabei eine neue Version. Alte Sessions behalten ihre Abschnitte mit dem Namen der Zone.

### D5: Migration von Schema 2 auf 3

Für jede aktuelle Streckenversion wird jedes Segment mit mindestens einem Band zu einer eigenen Zone mit Namen „<Strecke> <Position>“, z. B. „Seerunde 2“, und als Einbau an seiner bisherigen Startposition eingetragen. Freie Segmente bleiben freie Abschnitte. Ältere, schon geruderte Versionen bekommen nur `zoneName`, aber keine `zoneId`, weil sie sich nicht mehr ändern. Der Nutzer kann die erzeugten Zonen danach umbenennen oder zusammenlegen.

### D6: Export und Import

Der Header von `.aergrow` führt pro Abschnitt `zone: {name, axis, length, bands}` mit, wenn es ein Einbau ist. Der Import sucht eine nicht gelöschte Zone mit gleichem Namen und gleicher Definition, sonst legt er sie an. Dateien aus `courses` ohne Zonen werden wie in D5 behandelt.

### D7: Anzeige

Im Live-Display nennt die Legende der Pace-Box den aktuellen Abschnitt mit dem Zonennamen („Zone Tempo“) bzw. „frei“ und die Restdistanz bzw. Restzeit. Die Zusammenfassung zeigt bei Segmentzeiten den Zonennamen. Im Ablaufbalken haben Zonen die Farbe nach Tempo aus `ui-design` (Design D4), freie Lücken `line`.

## Risks / Trade-offs

- **Unerwartete neue Versionen**: Das Ändern einer Zone erzeugt neue Versionen in mehreren Strecken auf einmal. Der Hinweis im Zonen-Editor nennt die betroffenen Strecken vor dem Speichern.
- **Automatisch erzeugte Zonennamen** nach der Migration sind unschön. Da die App bisher nur auf Testgeräten läuft, ist das vertretbar.

## Open Questions

- Soll das Live-Display beim Übergang in eine Zone kurz vorwarnen, etwa 50 m vorher „Sprint in 50 m“?
