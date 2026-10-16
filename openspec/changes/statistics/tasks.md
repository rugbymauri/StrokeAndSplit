# Tasks

Reihenfolge: Gruppe 1 hängt an keinem offenen Change und kann jederzeit umgesetzt werden. Die Gruppen 2–4 bauen auf den Screens aus `ui-design` auf:
- Gruppe 2 auf der Strecken- und Zonenliste (Task 4.3),
- Gruppe 3 auf der Vorlagenwahl (Task 4.1),
- Gruppe 4 auf der Zusammenfassung (Task 5.2).

Sie starten deshalb erst, wenn `ui-design` umgesetzt ist (siehe `docs/implementation-plan.md`).

## 1. Ranglisten berechnen

- [x] 1.1 Typen für Rangliste und Eintrag mit Wert, Pace, Datum und Verweis auf Session, Runde, Abschnittsposition sowie Beginn und Ende (Wanduhr, Distanz) nach Design D5. Dazu eine reine Funktion, die Einträge nach Achse wertet (Zeit aufsteigend, Meter absteigend, bei Gleichstand der frühere vorne) und die Pace mit Pausen berechnet (D4). Verifikation: Unit-Tests für die Spec-Szenarien „Distanzzone“, „Zeitstrecke“, „Pause zählt mit“ und „Gleichstand“
- [x] 1.2 Rangliste einer Strecke als Abfrage über `laps` und `course_versions`, gruppiert nach Länge der geruderten Version, nur vollständige Runden (D2). Verifikation: Unit-Tests mit der Test-Datenbank für „Über Vorlagen hinweg“, „Länge geändert“, „Nur Zonen geändert“ und eine unvollständige Runde, die nicht zählt
- [x] 1.3 Rangliste einer Zone als Abfrage über `lap_segments` und das `course_segments` der geruderten Version, gruppiert nach Abschnittslänge, nur aus vollständigen Runden. Beginn und Ende des Abschnitts aus dem Rundenbeginn und den Abschnitten davor (D2, D5). Verifikation: Unit-Tests für „Über Strecken hinweg“, „Mehrfach in einer Session“ (sechs Einträge) und „Zone verlängert“, dazu ein Test, dass Beginn und Ende des zweiten Sprints einer Runde stimmen
- [x] 1.4 Rangliste einer Vorlage: Sessions mit `plannedLaps` vollständigen Runden, Summe der Runden, gruppiert nach Streckenlänge und Rundenzahl, keine Rangliste bei offener Rundenzahl (D2). Verifikation: Unit-Tests für „Drei Runden“, „Abgebrochene Session“, „Rundenzahl geändert“ und „Offene Rundenzahl“
- [x] 1.5 Filter für alle drei Ranglisten: nur die Quellen `pm5` und `ftms`, keine Ranglisten gelöschter Strecken, Zonen und Vorlagen (D3). Verifikation: Unit-Tests für „Simulator“, „Import“ (Roundtrip einer PM5-Session über Export und Import; seit 1.7 zählt sie nicht), „Zone gelöscht“, „Vorlage gelöscht“ und „Session gelöscht“
- [x] 1.6 Riverpod-Provider, die die Plätze 1–3 als Stream liefern und bei neuen, importierten oder gelöschten Sessions neu ausgeben (D1). Mit 200 erzeugten Sessions zu je 3 Runden und 2 Zonen die Abfragezeit messen. Liegt sie über 100 ms, einen Index mit eigener Migration ergänzen. Das Schema wird dann erhöht, die Nummer ist mit `heart-rate` abzustimmen (seit 1.7 hat `statistics` Schema 5, `heart-rate` 6). Verifikation: Provider-Test, der nach dem Beenden einer Session einen neuen Platz 1 sieht, Messwert im Implementierungsplan notiert
- [x] 1.7 Importierte Sessions aus allen Ranglisten nehmen (D3): Spalte `sessions.imported` (bool, Default `false`) mit `schemaVersion` 5 und Migrationsschritt `from4To5`, Snapshot und Migrationstest über `make schema`; `SessionRepository.import` setzt sie, der Filter der drei Ranglisten schliesst importierte Sessions aus. Verifikation: Migrationstests 4→5 und 1→5 (bestehende Sessions gelten als nicht importiert), Unit-Test „Import“ (Roundtrip einer PM5-Session über Export und Import, keine Rangliste von Vorlage, Strecke und Zone)

## 2. Detailansicht von Strecke und Zone

- [x] 2.1 Detailansicht einer Strecke, die sich per Tipp aus der Streckenliste öffnet. Sie zeigt die Plätze 1–3 pro Länge, die aktuelle Länge zuerst, mit Wert, Pace und Datum, einen Hinweis, dass Pausen mitzählen, und den Weg zum Bearbeiten. Ohne Eintrag erscheint ein Hinweis statt der Plätze. Gestaltung im Stil von `ui-design`. Verifikation: Widget-Tests für „Mehrere Längen“, eine Strecke ohne Einträge und den Weg zum Editor
- [x] 2.2 Dasselbe für Zonen, geöffnet aus der Zonenliste. Verifikation: Widget-Tests für „Zone ansehen“ und eine Zone mit zwei Längen

## 3. Plätze in der Vorlagenwahl

- [x] 3.1 Die aufgeklappte Vorlage zeigt Platz 1–3 der Rangliste für ihre aktuelle Streckenlänge und Rundenzahl mit Wert, Pace und Datum. Ohne Eintrag und bei offener Rundenzahl erscheint ein Hinweis. Platz 1 lässt Raum für das Ghost-Symbol aus `ghost`. Verifikation: Widget-Tests für „Zwei Einträge“, „Noch nie gerudert“ und offene Rundenzahl

## 4. Plätze in der Zusammenfassung

- [x] 4.1 Die Zusammenfassung markiert jede Runde und jede Zonenfahrt mit ihrem aktuellen Platz, wenn er 1–3 ist, und ebenso die Session in der Rangliste ihrer Vorlage (D6). Verifikation: Widget-Tests für „Neue zweitbeste Runde“, „Später überholt“, eine simulierte Session ohne Marken und eine Session auf Platz 1 ihrer Vorlage

## 5. Abschluss

- [ ] 5.1 README um die Ranglisten ergänzen, inklusive des Hinweises, dass Simulator-Sessions nicht zählen. Verifikation: `make check` grün, `openspec validate statistics --strict` gültig, Durchsicht des README
- [ ] 5.2 Manueller Test durch den Nutzer: am Rudergerät „Seerunde x3“ zweimal rudern. Danach müssen in der Vorlagenwahl, in den Detailansichten von Strecke und Zone und in der Zusammenfassung die erwarteten Plätze stehen. Verifikation: Rückmeldung des Nutzers

## Workflow follow-up

- Nach dem Archivieren in `ghost` prüfen, ob die Einträge aus D5 für den Verlauf reichen, und die Tasks von `ghost` darauf aufbauen.
