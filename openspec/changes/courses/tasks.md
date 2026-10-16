# Tasks

## 1. Schema und Migration

- [x] 1.1 Tabellen `courses`, `course_versions`, `course_segments`, `templates`, `template_blocks`, `laps` und `lap_segments` sowie die Spalten `sessions.templateId/templateName/courseVersionId/plannedLaps` und `samples.wallMs` anlegen (Design D4), `schemaVersion` 2 mit Migration `from1To2`. Verifikation: `make codegen` und `make check` sind grün
- [x] 1.2 `make schema` ausführen, Snapshot v2 und generierte Migrationstests einchecken, dazu einen Test, der eine Session aus Version 1 migriert und Zusammenfassung, Samples und Replay-Rohdaten unverändert wiederfindet. Verifikation: Migrationstests grün

## 2. Strecken (Capability courses)

- [x] 2.1 `CourseRepository`: anlegen, auflisten (nur nicht gelöschte, neueste Version), umbenennen, Definition ändern mit Versionierungsregel (neue Version nur, wenn die aktuelle schon gerudert wurde), weich löschen inkl. Löschen abhängiger Vorlagen. Verifikation: Unit-Tests gegen In-Memory-DB für alle Szenarien der Spec courses
- [x] 2.2 Validierung einer Streckendefinition (Länge > 0, Segmentsumme gleich Länge, Bänder mit Untergrenze ≤ Obergrenze) als reine Funktion mit verständlichen Fehlermeldungen. Verifikation: Unit-Tests für Länge 0, Abweichung 100 m und vertauschtes Pace-Band
- [x] 2.3 Strecken-Liste und Strecken-Editor (Name, Achse, Länge, Segmente teilen und zusammenlegen, optionale Bänder, Eingabe m:ss bei Zeit), Löschen mit Bestätigung und Hinweis auf betroffene Vorlagen. Verifikation: Widget-Tests für Anlegen einer Distanz- und einer Zeitstrecke, Unterteilen, Fehleranzeige und Löschen

## 3. Vorlagen (Capability session-templates)

- [x] 3.1 `TemplateRepository`: anlegen, auflisten mit Strecke und Rundenzahl, bearbeiten, löschen (setzt `sessions.templateId` auf null, `templateName` bleibt). Verifikation: Unit-Tests für feste und offene Rundenzahl, Ändern der Rundenzahl und Löschen mit bestehender Session
- [x] 3.2 Vorlagen-Liste und -Editor, Hinweis zum Anlegen einer Strecke, wenn keine existiert, und Eintrag „Vorlage rudern“ auf dem Startbildschirm. Verifikation: Widget-Tests für Liste, Editor, leeren Zustand ohne Strecke und Navigation vom Startbildschirm

## 4. Runden-Logik (Capability course-rowing, Kern)

- [x] 4.1 Reiner `LapTracker` (Design D2): Achsenposition, Runden- und Segmentgrenzen mit Interpolation, Überschuss an die nächste Runde, mehrere Grenzen zwischen zwei Messpunkten, `finished` bei fester Rundenzahl. Verifikation: Unit-Tests mit konstruierten Messpunkten, darunter das Spec-Beispiel 998 m/1003 m mit dem Ergebnis 3:59.4
- [x] 4.2 Zonenbewertung im `LapTracker` (Design D3): Zonenstatus mit Richtung, zeitgewichteter Anteil pro Segment und Runde, fehlende Werte zählen als ausserhalb, Teilung von Intervallen an Segmentgrenzen. Verifikation: Unit-Tests für 45 von 60 s gleich 75 %, Pause im Segment und freies Segment
- [x] 4.3 Abschluss einer angefangenen Runde als unvollständig. Verifikation: Unit-Test „bei 1400 m beendet“ ergibt Runde 1 vollständig und Runde 2 unvollständig mit 400 m

## 5. Aufzeichnung auf einer Strecke (session-recording, course-rowing)

- [x] 5.1 Accumulator schreibt `wallMs` aus den Paketzeiten (Design D1) und behält bei Sessions auf einer Strecke auch Pausensamples. Verifikation: Unit-Test mit `pause.jsonl` zeigt eine Wanduhr, die in der Pause weiterläuft, während die PM5-Zeit steht
- [x] 5.2 Accumulator führt einen `LapTracker` mit und legt Runden und Segmentergebnisse in den 2-s-Batch. Verifikation: Unit-Test mit `just_row.jsonl` auf einer kurzen Distanzstrecke ergibt dieselben Runden wie der Tracker direkt auf den Samples
- [ ] 5.3 `SessionRecorder.start(template:)` mit Session-Verweisen und `plannedLaps` sowie automatischem Ende bei `finished` (Design D6). Verifikation: Unit-Test „Seerunde x3“ mit dem Simulator endet nach Runde 3 von selbst
- [ ] 5.4 Crash-Recovery schliesst die letzte Runde aus den Samples ab (Design D5). Verifikation: Unit-Test „Absturz in Runde 3“ ergibt Runden 1 und 2 vollständig, Runde 3 unvollständig
- [ ] 5.5 Export mit `course` und `template` im Header, Import mit Wiederverwendung oder Anlage der Strecke (Design D7). Verifikation: Roundtrip-Test ergibt identische Runden, Import ohne vorhandene Strecke legt sie an, Import einer alten Datei bleibt eine freie Session

## 6. Live-Display und Zusammenfassung

- [ ] 6.1 Vorlage starten: Quelle wählen (PM5 suchen oder Simulator), nach dem Verbinden startet die Session mit der Vorlage. Verifikation: Widget-Test startet eine Vorlage mit dem Simulator und das Live-Display zeigt „Runde 1 von 3“
- [ ] 6.2 Streckenleiste im Live-Display (Runde, Segment, Rest, Zielbänder, Zonenanteil) und Zonenstatus an Pace- und Schlagzahl-Kachel mit Farbe und Pfeil bzw. Text. Verifikation: Widget-Tests für in der Zone, zu langsam und freies Segment sowie die bestehenden Layout-Tests in allen vier Grössen mit Vorlage ohne Überlauf
- [ ] 6.3 Nach automatischem Ende die Zusammenfassung öffnen. Die Zusammenfassung zeigt Vorlage, Strecke, Runden mit Zeit bzw. Distanz, Anteil in der Zone, die hervorgehobene beste Runde und unvollständige Runden. Verifikation: Widget-Test für Distanz- und Zeitstrecke
- [ ] 6.4 Session-Liste zeigt den Vorlagennamen. Verifikation: Widget-Test mit einer Vorlagen-Session und einer gelöschten Vorlage

## 7. Integration

- [ ] 7.1 Ende-zu-Ende mit dem Simulator auf Linux: Strecke mit drei Segmenten und Bändern anlegen, Vorlage x2 starten, im Simulator Pace ändern und pausieren, automatisches Ende, Zusammenfassung prüfen, exportieren und wieder importieren. Verifikation: Rundenzeiten und Zonenanteile vor und nach dem Import identisch
- [ ] 7.2 Am echten PM5: Vorlage mit einer 500-m-Strecke x3 rudern, dabei in Runde 2 kurz pausieren. Verifikation: Rundenzeiten plausibel zu den PM5-Werten, die Pause ist in Runde 2 enthalten
- [ ] 7.3 README um Strecken, Vorlagen und das erweiterte `.aergrow`-Format ergänzen. Verifikation: Die beschriebenen Schritte funktionieren im Simulator wie dokumentiert

## Workflow follow-up

- Vor `/opsx:apply courses` den Change `foundation` archivieren, damit die Deltas für `session-recording` und `live-display` auf echten Specs aufsetzen.
- Nach Review und Integration archivieren (`/opsx:archive`), danach folgt der Change `ghost`.
