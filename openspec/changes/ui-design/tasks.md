# Tasks

## 1. Grundlagen

- [ ] 1.1 Schriften Barlow Condensed und IBM Plex Sans als Assets einbinden, Lizenzen (OFL) ablegen. Verifikation: `make check` grün, Schriften erscheinen ohne Netz
- [ ] 1.2 Theme mit den Tokens aus Design D1 (Farben, Schriftstile, Radien, Abstände) in `lib/app`. Bestehende Screens nutzen es. Verifikation: bestehende Widget-Tests grün
- [ ] 1.3 Widget `SegmentBar` nach Design D4 (Breite, frei/Band, Helligkeit nach Tempo, Auswahl). Verifikation: Widget-Tests für freie Strecke, ein Band und abgestufte Pace-Bänder

## 2. Fortschrittsrahmen

- [ ] 2.1 Reine Funktion, die aus Lap-Tracker-Zustand und Vorlage die drei Anteile, die Grenzen und die Restangaben berechnet. Verifikation: Unit-Tests für das Spec-Beispiel 460 m in Runde 2, für eine Zeitstrecke und für offene Rundenzahl
- [ ] 2.2 `ProgressFrame` als `CustomPainter` nach Design D3: drei Spuren in Boxform, Start oben Mitte, Kerben, gerade Enden, Schiffchen mit Tangente, Farbe der Segmentspur nach Zonenstatus, optionale Ghost-Positionen. Verifikation: Golden-Tests für 0 %, 46 % (Unterkante), 38 % (in einer Ecke) und 100 %, mit und ohne Streckenspur
- [ ] 2.3 Pace-Box mit Rahmen, Pace, Zonenstatus und Legende. Verifikation: Widget-Tests für in der Zone, zu langsam und freies Segment

## 3. Live-Display

- [ ] 3.1 Layout-Wahl nach Seitenverhältnis (Design D2). Verifikation: Widget-Test 1200 × 700 ergibt Querformat, 390 × 844 Hochformat
- [ ] 3.2 Live frei, hoch und quer, nach den Canvas-Screens „Live: freies Rudern“ und „Live quer: freies Rudern“. Fläche für die Kraftkurve vorhanden, ohne Daten ausgeblendet. Verifikation: bestehende Layout-Tests in allen vier Grössen ohne Überlauf
- [ ] 3.3 Live mit Vorlage, hoch und quer, nach „Live: Vorlage mit Zonen“ und „Live quer: Vorlage mit Zonen“, Schlagzahl-Karte mit Zonenstatus, vier Kacheln. `course_bar.dart` entfällt. Verifikation: Layout-Tests in allen vier Grössen mit Vorlage ohne Überlauf, Pace bleibt der grösste Text

## 4. Vorlagen und Strecken

- [ ] 4.1 Gemeinsamer Screen mit Tabs „Vorlagen“ und „Strecken“ nach „Vorlage wählen“ und „Streckenliste“, aufklappbare Vorlage mit „Starten“. Verifikation: Widget-Tests für Tabwechsel, Auswahl und Start mit dem Simulator
- [ ] 4.2 Vorlagen-Editor nach „Vorlagen-Editor“ (Umschalter feste Anzahl/offen, Zähler, Ergebnis-Zeile). Verifikation: Widget-Tests für feste und offene Rundenzahl
- [ ] 4.3 Gestaltung der Streckenliste und des Strecken-Kopfs (Name, Achse, Länge, Segmentbalken) nach „Streckenliste“ und „Strecken-Editor“. Einbauen von Zonen und Zonen-Editor setzt der Change `zones` um. Verifikation: Widget-Tests für Streckenliste und Versionierungshinweis

## 5. Start und Zusammenfassung

- [ ] 5.1 Startbildschirm nach Design D6 (Quelle, „Rudern“, „Frei rudern“, Kachel „Nochmal“, Link „Sessions“), Gestaltung nach „Start“ im Canvas. Verifikation: Widget-Tests für Simulator wählen, „Rudern“, „Frei rudern“, Kachel „Nochmal“ mit vorausgewählter Vorlage, keine Kachel ohne Session und keine Kachel, wenn die Vorlage der jüngsten Session gelöscht ist
- [ ] 5.2 Zusammenfassung nach „Zusammenfassung“ mit Rundenbalken für den Anteil in der Zone. Verifikation: Widget-Tests für Distanz- und Zeitstrecke sowie eine freie Session

## 6. Abschluss

- [ ] 6.1 Screenshots der umgesetzten Screens mit dem Canvas vergleichen und Abweichungen im Canvas oder im Code bereinigen. Verifikation: manuelle Sichtprüfung auf Android hoch und quer sowie Linux
- [ ] 6.2 README-Abschnitt zur Bedienung aktualisieren. Verifikation: Durchsicht
