# Tasks

## 1. Schema und Migration

- [x] 1.1 Tabelle `zones` und Spalten `course_segments.zoneId/zoneName` (Design D1), `schemaVersion` 3 mit Migration nach Design D5. Verifikation: `make codegen`, `make schema` und Migrationstests grün, dazu ein Test, der die Strecke „Seerunde“ (200/600/200 m, Band in der Mitte) migriert und eine Zone „Seerunde 2“ ab 200 m sowie unveränderte Runden alter Sessions findet

## 2. Zonen (Capability zones)

- [x] 2.1 `ZoneRepository`: anlegen, auflisten mit Verwendung, bearbeiten, weich löschen. Validierung (Länge > 0, mindestens ein Band, Grenzen nicht vertauscht). Verifikation: Unit-Tests für alle Szenarien der Spec zones ausser denen, die Strecken betreffen
- [ ] 2.2 Zonenliste und Zonen-Editor nach den Canvas-Screens „Zonenliste“ und „Zonen-Editor“, dritter Tab „Zonen“. Verifikation: Widget-Tests für Anlegen, fehlendes Band, Hinweis auf betroffene Strecken und Löschen mit Bestätigung

## 3. Strecken aus Zonen (Capability courses)

- [x] 3.1 Reine Funktion `resolve` nach Design D2. Verifikation: Unit-Tests für das Spec-Beispiel „2 km Intervall“, Überschneidung, Ende überschritten, falsche Achse und Zone doppelt eingebaut
- [ ] 3.2 `CourseRepository` speichert Einbauten als aufgelöste Abschnitte, Zonenänderung und -löschung lösen alle betroffenen Strecken in einer Transaktion neu auf und versionieren (Design D3, D4). Verifikation: Unit-Tests „Sprint verlängern“, „Änderung passt nicht“, „Zone einer geruderten Strecke ändern“ und „Verwendete Zone löschen“
- [ ] 3.3 Strecken-Editor mit Ablauf und „Zone einbauen“ nach den Canvas-Screens „Strecken-Editor“ und „Zone einbauen“, Segment-Editor entfällt. Verifikation: Widget-Tests für Einbauen, Überschneidung, ausgegraute Zeit-Zone und zu kurze Strecke

## 4. Rudern und Austausch

- [ ] 4.1 Live-Display und Zusammenfassung nennen den Zonennamen bzw. „frei“ (Design D7). Verifikation: Widget-Tests für die beiden Szenarien der Delta-Spec course-rowing
- [ ] 4.2 Export mit Zonen im Header, Import legt fehlende Zonen an (Design D6). Verifikation: Roundtrip-Test, Import einer Datei aus `courses` ohne Zonen

## 5. Abschluss

- [ ] 5.1 README um Zonen ergänzen. Verifikation: Die beschriebenen Schritte funktionieren im Simulator
