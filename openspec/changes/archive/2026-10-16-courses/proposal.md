# Proposal

## Why

Mit dem Fundament lässt sich frei rudern und aufzeichnen. Es fehlt aber ein Ziel, gegen das man rudert. Strecken mit Zonen und Runden geben jeder Session eine Struktur: Man sieht im Boot, ob man in der geplanten Pace und Schlagzahl liegt, und jede Runde liefert eine vergleichbare Zeit. Damit wird Disziplin sichtbar, und die gespeicherten Runden sind die Datengrundlage für den Ghost im nächsten Change.

## What Changes

- **Strecken definieren**: Eine Strecke ist entweder distanzbasiert (z.B. 1000 m) oder zeitbasiert (z.B. 4 min), mit genau einer Achse. Sie besteht aus Segmenten, und jedes Segment hat optional ein Pace-Band (z.B. 2:05–2:10 /500 m) und optional ein Schlagzahl-Band (z.B. 20–22 spm). Ein Segment ohne Band ist ein freier Abschnitt. Strecken lassen sich in der App anlegen, bearbeiten und löschen. Wird eine Strecke bearbeitet, die schon gerudert wurde, entsteht eine neue Version, damit alte Rundenzeiten vergleichbar bleiben.
- **Session-Vorlagen**: Eine Vorlage besteht aus einer Strecke und einer Rundenzahl, entweder fest (z.B. 3) oder offen bis zum Stopp. Vorlagen lassen sich anlegen, bearbeiten, löschen und starten. Intern ist eine Vorlage eine Liste von Blöcken mit vorerst genau einem Block, damit Abfolgen wie Einrudern, Runden und Ausrudern später ohne Migration möglich sind.
- **Vorlage rudern**: Nach der Wahl von Quelle und Vorlage zeigt das Live-Display zusätzlich die aktuelle Runde, das Segment, die Restdistanz bzw. Restzeit und die Zone. Es zeigt pro Wert farbig an, ob er im Band liegt, mit Pfeil für schneller/langsamer bzw. mehr/weniger Schläge, und es zeigt den laufenden Anteil in der Zone.
- **Ergebnisse speichern**: Pro Runde und Segment werden Zeit, Distanz und Anteil in der Zone gespeichert. Die Zusammenfassung zeigt die Rundenzeiten bzw. Rundendistanzen und den Anteil in der Zone. Eine beim Beenden angefangene Runde wird als unvollständig gespeichert und zählt nicht als Rundenzeit. Rundengrenzen werden zwischen zwei Messpunkten interpoliert.
- **Pausen zählen**: Runden und Zeitstrecken laufen nach Wanduhr. Der PM5 hält seine Uhr in einer Pause an, eine Pause während einer Runde kostet trotzdem Zeit bzw. Meter. Dafür bekommt jede Session neben der PM5-Zeit eine Wanduhr-Zeitachse.
- Freies Rudern ohne Vorlage bleibt unverändert möglich.

Nicht Teil dieses Changes: der Ghost (eigener Change `ghost`, direkt im Anschluss), Abfolgen aus mehreren Blöcken mit Pausenblöcken, benannte Intensitäten mit persönlichen Pace-Werten, Puls-Zonen, Punkte, Abzeichen und Serien (Change `progression`), Export und Import von Strecken und Vorlagen.

## Capabilities

### New Capabilities

- `courses`: Strecken mit Achse (Distanz oder Zeit), Segmenten und optionalen Pace- und Schlagzahl-Bändern anlegen, bearbeiten, versionieren und löschen.
- `session-templates`: Vorlagen aus Strecke und Rundenzahl (fest oder offen) anlegen, bearbeiten, löschen und starten.
- `course-rowing`: Eine Vorlage rudern, also Runden und Segmente live verfolgen, Zonen anzeigen und bewerten sowie Runden- und Segmentergebnisse speichern und zusammenfassen.

### Modified Capabilities

Die folgenden Capabilities entstehen mit dem Change `foundation`, der noch nicht archiviert ist. Die Deltas beziehen sich auf deren Stand nach der Archivierung.

- `session-recording`: Eine Session bekommt zusätzlich eine Wanduhr-Zeitachse, in der Pausen enthalten sind. Eine Session kann einer Vorlage zugeordnet sein und speichert dann ihre Runden.
- `live-display`: Das Live-Display zeigt beim Rudern einer Vorlage Runde, Segment, Restdistanz bzw. Restzeit und den Zonenstatus.

## Impact

- Datenbank: neue Tabellen für Strecken (mit Versionen), Segmente, Vorlagen, Runden und Segmentergebnisse. Die `samples` bekommen eine Wanduhr-Spalte. Das ist die erste Schema-Migration (Version 1 → 2) und nutzt das Migrations-Setup aus `foundation`.
- Session-Recorder: Er braucht neben der PM5-Zeit die Ankunftszeit der Pakete und eine Runden- und Segment-Logik, die beim Aufzeichnen und beim Import gleich arbeitet, so wie der heutige Akkumulator.
- Neue Screens: Strecken-Editor, Vorlagen-Liste und -Editor, Vorlagenwahl beim Start. Live-Display und Zusammenfassung werden erweitert.
- Export `.aergrow`: Das Format bleibt, die Rohpakete enthalten die nötigen Zeitstempel bereits. Ob Vorlage und Strecke in den Header gehören, entscheidet das Design.
- Voraussetzung: `foundation` sollte vor der Umsetzung archiviert sein, damit die Deltas auf echten Specs aufsetzen.
