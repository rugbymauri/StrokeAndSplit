# Design

## Context

Gestaltung aus dem Claude-Design-Canvas **AergRow Frontend** (privat, Freigabe über das Share-Menü). Relevante Screens: „Live: Vorlage mit Zonen“, „Live quer: Vorlage mit Zonen“ (Ghost auf allen drei Spuren und Zeile in der Legende) und „Vorlage wählen“ (Ghost-Zeit in der aufgeklappten Vorlage).

## Decisions

### D1: Darstellung

- Ghost-Schiffchen: Raute von etwa 18 × 7 px in `ghost` (`#C9B6FF`) mit 1.5 px Rand in der Farbe der Box. Es ist schmaler als das eigene Schiffchen (22 × 14 px), damit man beide auf einen Blick unterscheidet.
- Es liegt auf der Mitte der Spur, folgt der Laufrichtung und dreht sich in den Ecken mit.
- Überlappen sich eigenes Schiffchen und Ghost, liegt der Ghost oben.
- Symbol in Legende und Vorlagenwahl: dieselbe Raute, 10 px breit.
- Der Abstand steht als vierte Legendenzeile: „Ghost“ links, rechts „30 m vor dir · 7.6 s“ bzw. „12 m hinter dir · 2.9 s“, orange bei Rückstand, blau bei Vorsprung.

### D2: Position pro Spur

Der Ghost hat zu jedem Zeitpunkt der Session eine Achsenposition. Daraus folgt seine Position auf jeder Spur wie beim eigenen Fortschritt. Fehlen für eine Ebene Daten, etwa weil der Ghost nur Rundenzeiten ohne Verlauf hat, entfällt das Schiffchen auf dieser Spur.

## Open Questions

- **Wer ist der Ghost?** Varianten: (a) die beste vollständige Runde dieser Streckenversion, auf jede Runde neu gestartet, (b) die letzte Session mit derselben Vorlage über die ganze Strecke, (c) wählbar. Davon hängt ab, ob der Ghost auf der Streckenspur überhaupt Sinn hat. Bei (a) zeigt er dort nur den Abstand in der aktuellen Runde.
- **Welcher Abstand steht in der Box**, wenn die Abstände pro Ebene verschieden sind? Vorschlag: der Abstand auf der Ebene, zu der der Ghost gehört, also bei (a) die Runde.
- **Meter, Sekunden oder beides?** Das Design zeigt beides. Am Erg ist zu prüfen, ob das zu viel ist.
- **Nahe beieinander**: Bleibt das Überlappen der Schiffchen lesbar, oder rückt der Ghost bei kleinem Abstand nach aussen?

Sind diese Fragen geklärt, kommen die Specs zur Auswahl des Ghosts und `tasks.md` dazu.
