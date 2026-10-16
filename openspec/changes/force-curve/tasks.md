# Tasks

## 1. Protokoll

- [ ] 1.1 Spike um das Abonnement der Kraftkurven-Characteristic erweitern und einige Minuten am PM5 mitschneiden. UUID, Paketaufbau und Werte pro Schlag in `packages/pm5_protocol/README.md` festhalten. Verifikation: Mitschnitt liegt als Fixture unter `recordings`
- [ ] 1.2 Decoder für die Kurvenpakete mit Zusammensetzen pro Schlag und Verwerfen unvollständiger Kurven (Design D1). Verifikation: Unit-Tests mit dem Mitschnitt und mit einem künstlich entfernten Paket

## 2. Quellen und Aufzeichnung

- [ ] 2.1 PM5-Quelle abonniert die Characteristic, die Pakete laufen in `raw_packets`. Verifikation: Unit-Test, dass der Accumulator die Pakete speichert und der Import dieselben Kurven ergibt
- [ ] 2.2 Simulator liefert eine Kurve pro Schlag, skaliert nach Leistung. Verifikation: Unit-Test für höhere Leistung ergibt höhere Kurve
- [ ] 2.3 Replay liefert die Kurvenereignisse. Verifikation: Unit-Test mit der Fixture

## 3. Anzeige

- [ ] 3.1 Widget `ForceCurve` nach Design D2 mit den Zuständen aus D3. Verifikation: Golden-Tests für zwei Kurven, ersten Schlag und Warten
- [ ] 3.2 Einbau in die vier Live-Layouts an den Stellen aus der Tabelle in `design.md`, Karte entfällt ohne Unterstützung. Verifikation: bestehende Layout-Tests in allen vier Grössen ohne Überlauf, mit PM5-Fixture und mit einer Quelle ohne Kurve
- [ ] 3.3 Manueller Test am PM5 hoch und quer. Verifikation: Sichtprüfung, Ergebnis in der README
