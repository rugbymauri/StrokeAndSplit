# Design

## Context

- `TemplatesScreen` (`lib/features/templates/templates_screen.dart`) hat drei Tabs. Im Tab „Vorlagen“ hält `_TemplatesTabState._opened` die eine aufgeklappte Karte. `_TemplateCard` zeigt aufgeklappt Zonenbänder, `TemplatePodium`, das Bearbeiten-Symbol und „Starten“ (`template-start`). `selectedTemplateId` aus „Nochmal“ klappt eine Karte auf und scrollt sie ins Bild. Deshalb ist die Liste eine nicht-lazy `SingleChildScrollView`.
- Gestartet wird über `startRowing(context, ref, template:)` in `lib/features/connection/rower_connection.dart`: verbinden, dann `LiveScreen(template:)`. `LiveScreen` startet die Aufnahme mit `sessionRecorderProvider.notifier.start(template:)`.
- Das Live-Display liest die Vorlage aus `ActiveRecording.template` (`lib/data/sessions/session_providers.dart`). `_courseView` beobachtet `liveGhostsProvider` und reicht `FrameGhost` und `ghostGap` an `CourseLiveView` weiter. Beide sind dort schon optional.
- Der Editor (`TemplateEditorScreen`) speichert oder löscht und schliesst sich danach mit `pop()`. `templatesProvider` liefert die Liste neu.
- Live-Display und Zusammenfassung kehren mit `popUntil(isFirst)` zum Startbildschirm zurück, unabhängig davon, wie viele Screens dazwischen liegen.

## Goals / Non-Goals

**Goals:**
- Der Vorlagen-Screen übernimmt alles, was heute in der aufgeklappten Karte steht, und hat zusätzlich den Ghost-Schalter.
- Ob ein Ghost läuft, hängt an der laufenden Aufnahme, nicht am Widget, und steht damit mit dem Start fest.
- Ohne Ghost lädt das Live-Display keine Ghost-Spuren aus der Datenbank.

**Non-Goals:**
- Kein neuer Routing-Mechanismus. Die App bleibt bei `Navigator.push` mit `MaterialPageRoute`.
- Keine Änderung an Ranglisten, Ghost-Berechnung oder Fortschrittsrahmen.

## Decisions

### D1: Eigener Screen `TemplateScreen`, beobachtet die Vorlage per ID

Neu ist `lib/features/templates/template_screen.dart`. Er bekommt die ID der Vorlage und liest sie aus `templatesProvider`. So zeigt er nach dem Speichern im Editor den neuen Stand. Fehlt die Vorlage in der geladenen Liste, weil sie im Editor gelöscht wurde, schliesst er sich mit `pop()` und die Liste erscheint (Spec „Vorlage auf dem Screen bearbeiten“).

Aufbau, hoch- und querformat gleich, mit maximal 640 px Breite wie die Liste:

```
+-------------------------------------+
| <-  Seerunde x3                [e]  |   AppBar: Name, Bearbeiten
|-------------------------------------|
|  Seerunde · 3 Runden                |   scrollt
|  [=====|=====|======]               |
|  Sprint 1:45-1:50 · ...             |
|                                     |
|  Bestleistungen                     |
|   1. 12:31  [G]                     |
|   2. 12:48                          |
|-------------------------------------|
|  [G] Gegen den Ghost rudern  [==o]  |   fest unten
|  [           Starten             ]  |
+-------------------------------------+
```

Zonen, Details und Podium scrollen, Schalter und „Starten“ stehen fest unten. So bleibt „Starten“ auch bei vielen Zonen ohne Scrollen erreichbar, wie bei einem Gerät am Erg nötig. Den Zeilenaufbau der Zonen (`templateZoneLines`) und `TemplatePodium` übernimmt der Screen unverändert aus der Karte.

*Alternative*: die Vorlage als Objekt übergeben. Verworfen, weil der Screen nach dem Bearbeiten den alten Stand zeigen würde.

### D2: Kompakte Karte ohne Zustand

`_TemplateCard` verliert `opened`, `scrollIntoView` und den Auswahlrahmen. Sie zeigt Name, `templateDetails` und den Segmentbalken, dazu einen Chevron rechts als Hinweis, dass ein Screen folgt. Ein Tipp ruft `openTemplate(context, id)` auf, das den Screen pusht. `_TemplatesTab` wird ein `ConsumerWidget`, die Liste darf wieder lazy (`ListView.separated`) sein, weil nichts mehr ins Bild gescrollt werden muss.

### D3: „Nochmal“ öffnet den Screen über der Liste

`TemplatesScreen(selectedTemplateId:)` bleibt die Einstiegsstelle von „Nochmal“. Statt aufzuklappen, pusht `_TemplatesTab` nach dem ersten Frame (`addPostFrameCallback`) einmal den Screen dieser Vorlage. Der Navigator-Stapel ist dann Start → Liste → Vorlage, „Zurück“ führt zur Liste (Spec „Nochmal öffnet die Vorlage“). Dass der Screen nur einmal gepusht wird, sichert ein Flag im State, damit ein Rebuild der Liste ihn nicht erneut öffnet.

*Alternative*: Start → Vorlage direkt, ohne Liste. Vom Nutzer verworfen (Entscheidung b), „Zurück“ soll zur Liste führen.

### D4: Ghost-Wahl in der Aufnahme

`startRowing` bekommt `bool ghost = true` und reicht es an `LiveScreen(template:, ghost:)` weiter. `LiveScreen` startet mit `start(template:, ghost:)`, und `ActiveRecording` trägt ein `ghost`-Flag neben `template`. `_courseView` liest es aus der Aufnahme: Ist es aus, beobachtet es `liveGhostsProvider` gar nicht und übergibt `ghost: null` und `ghostGap: null`.

Damit steht die Wahl mit dem Start fest (Spec „Ghost während der Fahrt unveränderlich“). Auch ein Neuaufbau des `LiveScreen` oder ein Wiederverbinden ändert nichts daran. Das Flag lebt nur im Speicher und kommt nicht in die Datenbank.

*Alternative*: Flag nur am `LiveScreen`. Verworfen, weil die Vorlage selbst schon aus der Aufnahme kommt und zwei Quellen für denselben Lauf auseinanderlaufen könnten.

### D5: Schalter als `SwitchListTile`-artige Zeile, ohne Gedächtnis

Der Schalter ist lokaler State des Screens (`var _ghost = true`). Er wird bei jedem Öffnen neu angelegt und steht damit auf an. Die Zeile zeigt links das `GhostSymbol` aus `lib/app/widgets/ghost_symbol.dart`, dann den Text, rechts einen `Switch`. Die ganze Zeile ist antippbar, Touch-Ziel ab 48 px. Er erscheint immer, auch ohne Bestleistung, damit der Screen gleich aussieht. Ohne Eintrag läuft dann einfach kein Ghost.

## Risks / Trade-offs

- [Ein Tipp mehr bis zum Start] → Vorher: aufklappen und „Starten“, jetzt: öffnen und „Starten“, gleich viele Tipps. Nur „Nochmal“ führt zusätzlich über die Liste, so gewünscht.
- [Viele Tests greifen auf die aufgeklappte Karte zu] → Ein gemeinsamer Helfer in den Tests öffnet den Screen einer Vorlage. Die Tests zu Podium und Start ziehen in `template_screen_test.dart` um, ohne ihren Inhalt zu ändern.
- [Doppeltes Pushen bei „Nochmal“] → Flag im State (D3) und ein Test, dass „Zurück“ zur Liste führt und nicht auf einen zweiten Vorlagen-Screen.
- [Deltas auf Capabilities, die es noch nicht gibt] → `ghost` und `statistics` liegen erst als Changes vor. Dieser Change wird nach ihnen archiviert. Sonst lehnt das Archivieren das MODIFIED-Delta von `statistics` ab.
- [Abgelöste Entscheidungen in `ui-design` und `statistics`] → In beiden Changes einen Vermerk setzen, dass die aufgeklappte Karte und „Nochmal mit aufgeklappter Vorlage“ durch diesen Change ersetzt sind.
