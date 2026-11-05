# Tasks

Neue Texte nur über `lib/l10n/app_de.arb` und `lib/l10n/app_en.arb` mit `@`-Beschreibung, danach `make l10n`; der generierte Code wird committet.

## 1. Protokoll

- [x] 1.1 `ftms_control.dart` in `packages/erg_protocol/lib/src/ftms/` nach D3: Parser für Features (`2acc`: Stufe gemeldet, Stufe setzbar) und Bereich (`2ad6`: min, max, Schritt in Zehnteln → ganze Stufen; unplausibel → null), Kodierung von „Set Target Resistance Level“ als u8 oder s16 in Zehnteln, Dekodierung der Antwort `80 <op> <result>`. Verifikation: Unit-Tests mit den Bytes des Woodrowers (`a6 56 00 00 04 00 00 00`, `0a 00 96 00 0a 00`, `04 3c`, `80 04 01`/`03`/`05`), Maximum über 25,5 kodiert s16, fehlerhafte Pakete
- [x] 1.2 Stufe in Zehnteln erkennen (Risiko in design.md): Liegt eine gemeldete Stufe über dem Maximum des Bereichs und durch 10 geteilt darin, rechnet die Steuerung in Zehnteln; der Decoder bleibt unverändert. Verifikation: Unit-Test mit Bereich 1–15 und gemeldeter Stufe 60

## 2. Verbindung und Steuerung

- [x] 2.1 `GattConnection.read` in `rower_connector.dart` und der flutter_blue_plus-Umsetzung; `_setUpFtms` liest Features und Bereich nach D2 und lässt den Control Point abonniert. Verifikation: Tests mit Fake-`GattConnection`: Woodrower-Features liefern eine Steuerung mit 1–15, ohne Bit 2 oder ohne `2ad6` keine, Rower Data unverändert weitergeleitet, Antworten des Control Points nicht in den Notifications des Links
- [x] 2.2 `ResistanceControl` und `ResistanceResult` nach D1, Umsetzung über den Control Point mit Timeout, Rückfall auf s16 bei `03` und erneutem Request Control bei `05` (D3); `ErgSource.resistanceControl`, `BleRowerSource` tauscht sie beim Wiederverbinden aus und meldet das. Verifikation: Tests mit Fake-`GattConnection`: angenommen, abgelehnt, keine Antwort, `03` → s16 und dabei bleiben, `05` → Request Control und Wiederholung, neue Steuerung nach Wiederverbinden; PM5 und Replay ohne Steuerung
- [x] 2.3 Simulator nach D8: FTMS-Modus mit Steuerung 1–15, Start 5, gesetzte Stufe ab dem nächsten Paket gemeldet; PM5-Modus ohne. Verifikation: Unit-Test des Simulators, bestehende Simulator-Tests grün

## 3. Datenmodell

- [x] 3.1 Schema 9 nach D7: `zones.resistance_level`, `course_segments.resistance_level`, `from8To9`, `make schema`, `make codegen`; `Zone`, `CourseSegment` (`sameAs`, `withLength`, `segment`, `==`, `hashCode`) und Repositories mit dem Feld. Verifikation: generierter Migrationstest 8 → 9, Repository-Tests: Stufe gespeichert, geladen und beim Ändern der Zone in alle Strecken übernommen, alte Strecken ohne Stufe
- [x] 3.2 Kopie der Strecke in der Session und `.strokesplit` mit optionalem `resistanceLevel`. Verifikation: Export/Import-Test mit und ohne Stufe, bestehende Dateien ohne Feld lesbar

## 4. Logik

- [x] 4.1 `ResistanceDirector` nach D4 in `lib/data/sessions/`. Verifikation: Unit-Tests zu allen Szenarien von `resistance-control`: Intervall mit Stufen, zurück auf die Grundstufe, neue Runde, freies Rudern sendet nie von selbst, gleiche Stufe zweimal sendet nichts, Klemmen auf den Bereich, Handänderung am Gerät und per −/+ bis zum Segmentende, neue Grundstufe, Pause mit Handänderung, Wiederverbinden sendet erneut, verzögerte Meldung innerhalb von 3 s ist keine Handänderung, drei schnelle Tipps von 6 auf 9, nach Ablehnung kein erneutes Senden bis zum nächsten Segment
- [x] 4.2 Provider, der den `ResistanceDirector` mit `lapProgress`, den `StatusTick`s und der Steuerung der aktiven Quelle verbindet und `setLevel` serialisiert (D4), plus Zustand für den Hinweis bei Fehlern (D5). Verifikation: Provider-Test mit Simulator (FTMS) und einer Vorlage mit Sprint auf Stufe 10: im Sprint meldet der Simulator Stufe 10; Test mit einer Steuerung, die ablehnt: Hinweis gesetzt, kein zweiter Versuch

## 5. Oberfläche

- [x] 5.1 −/+ an der Stufe in der Watt-Kachel nach D6, frei und mit Vorlage, gesperrt an den Grenzen, Hinweis „Stufe nicht gesetzt“ nach D5. Verifikation: Widget-Tests: Tasten nur mit Steuerung, Tipp auf + sendet Ziel + 1, + bei 15 gesperrt, Gerät ohne setzbare Stufe zeigt nur die Fussnote, Overflow-Test bei 390 px (frei und mit Vorlage) wie in ui-design 5.15, Tasten mindestens 48 × 48 dp
- [ ] 5.2 Stufe im Zoneneditor (Schalter und `OarStepper` 1–25) und in der Zonenliste („· Stufe 10“), auch in der Segmentbeschreibung der Strecke. Verifikation: Widget-Tests: Zone mit Stufe speichern und in der Liste sehen, Zone nur mit Stufe zeigt „Band fehlt“, Zone ohne Stufe ohne Angabe

## 6. Dokumentation und Gerätetest

- [ ] 6.1 README (Abschnitt FTMS: Stufe setzen, am Woodrower getestet, andere Geräte nach Spezifikation), Implementierungsplan nachführen. Verifikation: Durchsicht
- [ ] 6.2 (Nutzer, am Woodrower) Gerätetest: frei mit −/+ verstellen, Vorlage mit Zonen auf verschiedenen Stufen rudern, mitten in einer Zone am Gerät drehen, eine Pause ohne Drehen machen und prüfen, ob der Woodrower die Stufe hält, Verbindung kurz trennen. Verifikation: Stufe am Display des Geräts folgt der App wie in den Specs; Ergebnis der Pause in design.md nachgetragen
