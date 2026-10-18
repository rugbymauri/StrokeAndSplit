# Design

## Context

Gestaltung aus dem Claude-Design-Canvas **Stroke & Split Frontend** (privat, Freigabe über das Share-Menü). Relevante Screens: „Live: Vorlage mit Zonen“, „Live quer: Vorlage mit Zonen“ (Ghost auf allen drei Spuren und Zeile in der Legende) und „Vorlage wählen“ (Ghost-Zeit in der aufgeklappten Vorlage).

## Decisions

### D1: Darstellung

- Ghost-Schiffchen: Raute von etwa 18 × 7 px in `ghost` (`#C9B6FF`) mit 1.5 px Rand in der Farbe der Box. Es ist schmaler als das eigene Schiffchen (22 × 14 px), damit man beide auf einen Blick unterscheidet.
- Es liegt auf der Mitte der Spur, folgt der Laufrichtung und dreht sich in den Ecken mit.
- Liegen eigenes Schiffchen und Ghost so nah, dass sie sich überlappen würden, rückt der Ghost nach aussen (D5).
- Symbol in Legende und Vorlagenwahl: dieselbe Raute, 10 px breit.
- Der Abstand steht als vierte Legendenzeile: „Ghost“ links, rechts der Abstand nach D4, z. B. „7.6 s vor dir“ bzw. „2.9 s hinter dir“, orange bei Rückstand, blau bei Vorsprung.

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

### D4: Abstand in der Pace-Box (F6, F7, entschieden 2026-10-16)

- Die Box zeigt den Abstand zum Ghost der ganzen Vorlage (äussere Spur), nicht zu den Ghosts von Runde oder Zone. So bleibt die Zahl über die ganze Session vergleichbar und springt nicht bei jeder Runde.
- Eine Einheit je nach Achse: auf einer Distanzachse den Zeitabstand in Sekunden („7.6 s vor dir“), auf einer Zeitachse den Abstand in Metern („30 m vor dir“). Die Strecke legt fest, was gleich ist; der Abstand misst das andere.
- Läuft aussen kein Ghost (offene Rundenzahl oder noch kein Eintrag), entfällt die Legendenzeile. Die Ghosts auf Runden- und Abschnittsspur laufen trotzdem.

Verworfen: der Abstand zum Ghost der Runde, weil er mit jeder Runde neu beginnt; Meter und Sekunden zusammen, weil die Legende sonst zu voll wird.

### D5: Nahe beieinander (F8, entschieden 2026-10-16)

Würden sich eigenes Schiffchen und Ghost auf einer Spur überlappen, rückt der Ghost quer zur Laufrichtung nach aussen, aus der Box heraus, sodass beide ganz sichtbar bleiben. Er bleibt an seiner Position entlang der Spur und kehrt auf die Mitte der Spur zurück, sobald der Abstand wieder reicht. Auf der äussersten Spur rückt er ebenfalls nach aussen, in den Rand des Rahmens.

Verworfen: Überlappen mit dem Ghost oben, weil das eigene Schiffchen dann verdeckt wird.

### D6: Weitere Entscheide (2026-10-16)

- **Zeitstrecken:** Auf einer Zeitachse steht der Ghost an derselben Achsenposition wie das eigene Schiffchen, also nach D5 immer aussen daneben. Vorsprung oder Rückstand zeigt dort nur die Pace-Box in Metern (D4). So gewollt.
- **Neue Bestleistung in derselben Session:** Wird eine Runde oder eine Zonenfahrt der laufenden Session neuer Platz 1, läuft der Ghost dieser Spur ab der nächsten Runde bzw. Fahrt gegen sie. Die Ghosts folgen also der Rangliste live und werden nicht beim Start festgelegt.
- **Vorlagenwahl:** nur das Ghost-Symbol bei Platz 1, keine eigene Ghost-Zeit, weil Platz 1 die Zeit schon zeigt.
- **Simulator:** Auch im Simulator läuft der Ghost mit. Simulierte Sessions werden selbst nie Ghost (`statistics` D3), also ändert der Simulator die Ghosts nicht.

## Open Questions

Keine. Als Nächstes kommt `tasks.md` dazu. Die Auswahl des Ghosts steht seit D2 in den Specs.
