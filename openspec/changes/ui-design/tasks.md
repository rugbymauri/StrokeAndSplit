# Tasks

Neue und geänderte Texte nur über `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb` mit `@`-Beschreibung, danach `make l10n` (Design D9). Das gilt für jeden Task.

## 1. Grundlagen

- [x] 1.1 Schriften Barlow Condensed und IBM Plex Sans als Assets einbinden, Lizenzen (OFL) ablegen. Verifikation: `make check` grün, Schriften erscheinen ohne Netz
- [x] 1.2 Theme mit den Tokens aus Design D1 (Farben, Schriftstile, Radien, Abstände) in `lib/app`. Bestehende Screens nutzen es. Verifikation: bestehende Widget-Tests grün
- [x] 1.3 `CourseStrip` aus `zones` (`lib/features/courses/course_strip.dart`) nach Design D4 ausbauen statt ein neues Widget `SegmentBar` zu bauen: Tokens, Breite, frei/Zone, Helligkeit nach Tempo, Auswahl, Höhen. Bestehende Aufrufe in Streckenliste und Strecken-Editor bleiben. Verifikation: Widget-Tests für freie Strecke, eine Zone und abgestufte Pace-Bänder

- [x] 1.4 Widget `OarStepper` nach Design D7 (Ruderblatt-Form, gross und kompakt, Schritt, Grenzen, gesperrte Taste, Wiederholung beim Gedrückthalten, Screenreader-Beschriftung). Verifikation: Widget-Tests für Schritt, Grenze, Gedrückthalten und Semantics

## 2. Fortschrittsrahmen

- [x] 2.1 Reine Funktion, die aus Lap-Tracker-Zustand und Vorlage die drei Anteile, die Grenzen (Runden und Abschnitte) und die Restangaben berechnet (Design D3, Berechnung). Verifikation: Unit-Tests für das Spec-Beispiel 460 m in Runde 2, für eine Zeitstrecke und für offene Rundenzahl
- [x] 2.2 `ProgressFrame` als `CustomPainter` nach Design D3: drei Spuren in Boxform, Start oben Mitte, Kerben, gerade Enden, Schiffchen mit Tangente, Farbe der Abschnittsspur nach Zonenstatus, optionale Ghost-Positionen. Verifikation: Golden-Tests für 0 %, 46 % (Unterkante), 38 % (in einer Ecke) und 100 %, mit und ohne Streckenspur
- [x] 2.3 Pace-Box mit Rahmen, Pace, Zonenstatus und Legende mit Zonenname bzw. „frei“ und „Runde 2 / 3“. Verifikation: Widget-Tests für in der Zone, zu langsam, Zone ohne Name und freier Abschnitt

## 3. Live-Display

- [x] 3.1 Layout-Wahl nach Seitenverhältnis (Design D2). Verifikation: Widget-Test 1200 × 700 ergibt Querformat, 390 × 844 Hochformat
- [x] 3.2 Live frei, hoch und quer, nach den Canvas-Screens „Live: freies Rudern“ und „Live quer: freies Rudern“. Fläche für die Kraftkurve vorhanden, ohne Daten ausgeblendet. Verifikation: bestehende Layout-Tests in allen vier Grössen ohne Überlauf
- [x] 3.3 Live mit Vorlage, hoch und quer, nach „Live: Vorlage mit Zonen“ und „Live quer: Vorlage mit Zonen“, Schlagzahl-Karte mit Zonenstatus, vier Kacheln. Was `course_bar.dart` zeigt, nach der Tabelle in Design D3 übernehmen, insbesondere Zonenname bzw. „frei“ in die Legende der Pace-Box; `ZoneHint` in eine eigene Datei, danach entfällt `course_bar.dart`. Verifikation: Layout-Tests in allen vier Grössen mit Vorlage ohne Überlauf, Pace bleibt der grösste Text; bestehende Tests zu Runde, Zonenname, „frei“ und Rest auf die Pace-Box umgestellt und grün
- [x] 3.4 Schlagzahl-Karte: ausserhalb des Bands eine Anweisung als Pille wie in der Pace-Box, „Mehr Schläge“ bzw. „Weniger Schläge“ mit Pfeil und Band, in der Zone dezent, ohne Band keine (Design D3, Schlagzahl-Karte). Verifikation: Widget-Tests für zu niedrig, zu hoch, in der Zone und freien Abschnitt in allen vier Grössen ohne Überlauf, Anweisung vollständig und grösser als die Beschriftung

## 4. Vorlagen und Strecken

- [x] 4.1 Die bestehenden drei Tabs „Vorlagen“, „Strecken“ und „Zonen“ aus `zones` nach „Vorlage wählen“ und „Streckenliste“ gestalten, Aufbau und Navigation bleiben; aufklappbare Vorlage mit „Starten“. Verifikation: bestehende Tests zum Tabwechsel grün, Widget-Tests für Aufklappen, Auswahl und Start mit der gewählten Quelle
- [x] 4.2 Vorlagen-Editor nach „Vorlagen-Editor“ (Umschalter feste Anzahl/offen, Zähler, Ergebnis-Zeile). Verifikation: Widget-Tests für feste und offene Rundenzahl
- [x] 4.3 Gestaltung der Streckenliste und des Strecken-Kopfs (Name, Achse, Länge, Ablaufbalken) nach „Streckenliste“ und „Strecken-Editor“. Einbauen von Zonen und Zonen-Editor setzt der Change `zones` um. Verifikation: Widget-Tests für Streckenliste und Versionierungshinweis

- [x] 4.4 Zahlenfelder durch `OarStepper` ersetzen: Rundenzahl im Vorlagen-Editor, Länge im Strecken-Editor, Länge, Pace- und Schlagzahl-Band im Zonen-Editor, Startposition in „Zone einbauen“, mit den Schritten aus D7. Verifikation: bestehende Editor-Tests auf Tippen umgestellt und grün, Widget-Tests für die Spec-Szenarien „Pace-Band anpassen“ und „Zone verschieben“
- [x] 4.5 Pace-Band im Zonen-Editor nach D7 mit 10 s Abstand vorbelegen und mit der schnellsten Pace als Ganzes verschieben, die langsamste Pace ändert nur sich selbst; Schlagzahl-Band bleibt. Verifikation: Widget-Tests für neue Zone, schnellste Pace verschieben, langsamste einzeln verstellen und gesperrte Taste an der Obergrenze

## 5. Start und Zusammenfassung

- [x] 5.1 „Geräte wählen“ als erster Screen nach Design D6 (Rudergerät aus der Geräteliste für PM5 und FTMS, „Simulator“ und „Simulator (FTMS)“, Platz für den Pulsgurt, „Weiter“ erst mit Rudergerät; übersprungen, wenn das zuletzt gewählte Rudergerät gefunden wird) und danach der Startbildschirm (Gerätezeile, „Rudern“, „Frei rudern“, Kachel „Nochmal“, Link „Sessions“) und Sprachwahl in der App-Leiste beider Screens nach D8, Gestaltung nach „Start“ im Canvas. Der Quellen-Dialog beim Start einer Vorlage entfällt. Verifikation: Widget-Tests für Simulator und Simulator (FTMS) wählen, Rudergerät aus der Liste wählen, „Weiter“ gesperrt ohne Rudergerät, Gerätezeile führt zurück zu „Geräte wählen“, beim Start mit gefundenem letztem Rudergerät direkt der Startbildschirm, ohne gefundenes Gerät „Geräte wählen“ mit Vorauswahl, Sprachwahl auf dem Startbildschirm und auf „Geräte wählen“ beim ersten Start, „Rudern“, „Frei rudern“, Kachel „Nochmal“ mit vorausgewählter Vorlage, keine Kachel ohne Session und keine Kachel, wenn die Vorlage der jüngsten Session gelöscht ist
- [x] 5.2 Zusammenfassung nach „Zusammenfassung“ mit Rundenbalken für den Anteil in der Zone. Verifikation: Widget-Tests für Distanz- und Zeitstrecke sowie eine freie Session
- [x] 5.3 Trennen vom Live-Display auf den Startbildschirm verlegen (Design D2 Kopfzeile, D6 „Verbindung halten“): kein Trennen-Symbol im Live-Display, Zurück, Esc und „Fertig“ führen zum Startbildschirm und lassen die Verbindung bestehen, laufende Session endet beim Zurück, bereite wird verworfen, Replay endet; Gerätezeile zeigt „Verbunden“ und „Trennen“, „Rudern“, „Frei rudern“ und „Nochmal“ nutzen die bestehende Verbindung. Verifikation: Widget-Tests für kein Trennen-Symbol in allen vier Layouts, Zurück und Esc mit weiter verbundener Quelle und freigegebenem Wakelock, Replay endet beim Zurück, „Fertig“ mit verbundenem Simulator, Gerätezeile verbunden mit „Trennen“, „Trennen“ trennt, „Frei rudern“ und „Rudern“ ohne neues Verbinden, Simulator in „Geräte wählen“ trennt das bisherige Rudergerät, Zurück vor dem ersten Schlag speichert nichts
- [x] 5.4 „Sessions“ auf dem Startbildschirm als Button über die volle Breite mit Symbol statt Link (Design D6). Verifikation: Widget-Test für Button und Sessionliste, Startbildschirm ohne Überlauf hoch, quer und im kleinen Fenster
- [x] 5.5 Zeit und Distanz der Session beim Rudern einer Vorlage (Design D2): Kacheln „Zeit“ und „Distanz“ wie beim freien Rudern, im Hochformat als eigene Reihe über Rundenzeit, Watt und Puls, im Querformat unter der Schlagzahl-Karte. Verifikation: Widget-Tests für die Werte der Session statt des Rudergeräts, alle Kacheln ohne Überlauf in allen Layouts, lesbare Grösse bei 360 px Breite und im Querformat
- [x] 5.6 Schlagzahl-Karte ohne Band und Kraftkurven-Karte mit ruhigem Rahmen (`AppColors.trackZone`, 2 px), damit sie sich vom Hintergrund abheben (Nutzer, 2026-10-18). Verifikation: Goldens der Kraftkurve neu, Live-Tests grün
- [x] 5.7 Werte im Live-Display in der breiteren, niedrigeren Barlow statt Barlow Condensed, die gewonnene Höhe für Pace-Box und Kraftkurve nutzen (Design D1, D2; Nutzer, 2026-10-18). Verifikation: Live-Tests grün, Kraftkurve auf 360 × 740 mit Vorlage sichtbar und darunter nicht, Pace bleibt der grösste Text, Vorher/Nachher-Screenshots in sechs Grössen gesichtet
- [x] 5.8 Kalorien des Rudergeräts (PM5 0x0033, FTMS Total Energy) beim Rudern einer Vorlage als dritte Kachel neben Zeit und Distanz der Session; ohne Wert keine Kachel (Nutzer, 2026-10-19). Verifikation: Widget-Tests für Kachel mit Wert, keine Kachel ohne Wert, kein Überlauf in allen Layouts
- [x] 5.9 Pace-Box beim Rudern einer Vorlage wie die Schlagzahl-Karte in der Zonenfarbe getönt (im Band blau, ausserhalb orange, Pille voll), im freien Abschnitt unverändert (Design D3; Nutzer, 2026-10-19). Verifikation: Tests für Farbe der Box, Beschriftung und Pille in, ausserhalb und ohne Band; Goldens des Fortschrittsrahmens neu und gesichtet
- [x] 5.10 Zusammenfassung: schnellste, durchschnittliche und langsamste Pace und ihr Verlauf als Kurve in Schritten gleicher geruderter Zeit, ohne Pausen (Design D10; Nutzer, 2026-10-19). Verifikation: Unit-Tests der Schritte (gleichmässig, Wechsel, Pause, kurzer letzter Schritt, lange Session), Widget-Tests mit und ohne Samples
- [x] 5.11 Zusammenfassung: niedrigster Puls neben Ø und Max. Puls, aus den Samples ohne 0 (Design D10; Nutzer, 2026-10-19). Verifikation: Widget-Tests mit Samples und ohne
- [x] 5.12 Ø Pace der Session beim Rudern einer Vorlage als erste Zeile der Legende in der Pace-Box (Design D3; Nutzer, 2026-10-19). Verifikation: Widget-Tests mit Wert und vor dem ersten Meter, Live-Tests ohne Überlauf in allen Grössen, Pace bleibt der grösste Text
- [x] 5.13 10 s vor dem Beginn einer Zone blinken ihre Bänder gelb an Stelle des Zonenstatus unter der Pace und auf der Schlagzahl-Karte (Design D3; Nutzer, 2026-10-26). Verifikation: Unit-Tests der Vorschau (Distanz über die aktuelle Pace, Zeit, freier Abschnitt, gleiche Bänder, nächste Runde, letzte Runde), Widget-Tests des Blinkens und mit reduzierter Bewegung, Live-Tests ohne Überlauf in allen Grössen
- [x] 5.14 Zonenstatus der Pace mit der Pace in ganzen Sekunden, wie sie angezeigt wird, damit „2:45“ in einem Band ab 2:45 auch bei 2:44,6 in der Zone ist (Design D3; Nutzer, 2026-10-26). Verifikation: Unit-Tests an beiden Grenzen

## 6. Abschluss

- [ ] 6.1 Screenshots der umgesetzten Screens mit dem Canvas vergleichen und Abweichungen im Canvas oder im Code bereinigen. Verifikation: manuelle Sichtprüfung auf Android hoch und quer sowie Linux
- [x] 6.2 README-Abschnitt zur Bedienung aktualisieren. Verifikation: Durchsicht
