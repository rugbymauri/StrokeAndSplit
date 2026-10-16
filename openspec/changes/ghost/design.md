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

### D2: Wer der Ghost ist (F5, entschieden 2026-10-16)

Es gibt einen Ghost pro Spur. Jeder ist Platz 1 der Rangliste seiner Ebene aus dem Change `statistics`:

| Spur | Ghost | Läuft |
|---|---|---|
| Strecke (aussen) | beste Session der Vorlage mit gleicher Streckenlänge und Rundenzahl | über die ganze Session |
| Runde (Mitte) | beste vollständige Runde der Strecke mit gleicher Länge | startet mit jeder Runde neu |
| Abschnitt (innen) | beste Fahrt durch die Zone mit gleicher Länge | startet mit jeder Fahrt durch die Zone neu |

- Vorlagen mit offener Rundenzahl haben keine Rangliste, also läuft aussen kein Ghost.
- Freie Abschnitte haben keine Rangliste, dort läuft innen kein Ghost.
- Simulierte Sessions zählen in `statistics` nicht, sind also nie Ghost.
- Den Verlauf liest `ghost` aus den `samples` der Session, auf die der Eintrag zeigt (`statistics` Design D5).

Verworfen sind die letzte Session derselben Vorlage und ein wählbarer Ghost. Gerudert wird immer gegen Platz 1.

### D3: Position pro Spur

Der Ghost hat zu jedem Zeitpunkt der Session eine Achsenposition. Daraus folgt seine Position auf jeder Spur wie beim eigenen Fortschritt. Fehlen für eine Ebene Daten, etwa weil der Ghost nur Rundenzeiten ohne Verlauf hat, entfällt das Schiffchen auf dieser Spur.

## Open Questions

- **Welcher Abstand steht in der Box**, wenn die Abstände pro Ebene verschieden sind? Seit D2 hat jede Spur einen eigenen Ghost. Vorschlag: der Abstand zum Ghost der Runde, weil er am häufigsten neu startet und damit am ehesten zum aktuellen Tempo passt.
- **Meter, Sekunden oder beides?** Das Design zeigt beides. Am Erg ist zu prüfen, ob das zu viel ist.
- **Nahe beieinander**: Bleibt das Überlappen der Schiffchen lesbar, oder rückt der Ghost bei kleinem Abstand nach aussen?

Sind diese Fragen geklärt, kommt `tasks.md` dazu. Die Auswahl des Ghosts steht seit D2 in den Specs.
