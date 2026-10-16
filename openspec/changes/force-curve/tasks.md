# Tasks

## 1. Protokoll

- [x] 1.0 Spike um das Abonnement der Kraftkurven-Characteristic `003d` erweitern. Verifikation: `flutter analyze lib/spike` ohne Befund; eine fehlende Characteristic meldet der Spike und nimmt weiter auf
- [x] 1.1 Am PM5 mitschneiden (`make spike`), UUID, Paketaufbau, Einheit und Werte pro Schlag in `packages/erg_protocol/README.md` und im Abschnitt „Stand des Spikes“ von `design.md` festhalten. Mitschnitt vom 2026-10-16, 22:32, etwa 70 s mit 22 Kurven. Verifikation: Ausschnitt von wenigen Schlägen liegt als Fixture unter `packages/erg_protocol/test/fixtures/force_curve.jsonl`, Maximum jeder Kurve passt zur Spitzenkraft aus `0x0035`
- [x] 1.2 Decoder für die Kurvenpakete mit Zusammensetzen pro Schlag, Zuordnung zur Schlagnummer aus dem vorangehenden `0x0035` und Verwerfen unvollständiger Kurven (Design D1). Verifikation: Unit-Tests mit `force_curve.jsonl` (17 Kurven für die Schläge 2–18, Maximum jeder Kurve gleich Spitzenkraft aus `0x0035` ganzzahlig abgeschnitten, keine Kurve für die Schläge 0 und 1, keine Warnung für `003d`, Durchzugslänge aus dem vorangehenden `0x0035` im Kurvenereignis, z. B. 1.06 m bei Schlag 4) und mit einem künstlich entfernten Paket

## 2. Quellen und Aufzeichnung

- [x] 2.1 PM5-Quelle abonniert die Characteristic, die Pakete laufen in `raw_packets`. Verifikation: Unit-Test, dass der Accumulator die Pakete speichert und der Import dieselben Kurven ergibt
- [ ] 2.2 Simulator liefert eine Kurve pro Schlag, skaliert nach Leistung, mit Durchzugslänge (Design D4). Verifikation: Unit-Test für höhere Leistung ergibt höhere Kurve; jede simulierte Kurve trägt eine Länge zwischen 0.8 und 1.3 m
- [ ] 2.3 Replay liefert die Kurvenereignisse. Verifikation: Unit-Test mit der Fixture

## 3. Anzeige

- [ ] 3.1 Widget `ForceCurve` nach Design D2 mit den Zuständen aus D3. Verifikation: Golden-Tests für zwei Kurven, ersten Schlag und Warten
- [ ] 3.2 Schlaglänge an der Kurve nach Design D4, Format über `lib/features/live/formatters.dart`. Verifikation: Unit-Test für das Format („1,06 m“ auf Deutsch, „1.06 m“ auf Englisch); Golden-Tests mit Länge und ohne Länge (keine Angabe, kein „0 m“)
- [ ] 3.3 Einbau in die vier Live-Layouts an den Stellen aus der Tabelle in `design.md`, Karte entfällt ohne Unterstützung. Verifikation: bestehende Layout-Tests in allen vier Grössen ohne Überlauf, mit PM5-Fixture und mit einer Quelle ohne Kurve; Schlaglänge in allen vier Layouts sichtbar und ohne Überlauf
- [ ] 3.4 Manueller Test am PM5 hoch und quer. Verifikation: Sichtprüfung, angezeigte Schlaglänge plausibel (etwa 0.6–1.2 m) und bei langen Schlägen sichtbar grösser als bei kurzen, Ergebnis in der README
