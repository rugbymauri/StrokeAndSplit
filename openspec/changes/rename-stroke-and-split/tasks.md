# Tasks

## 0. Vorbereitung

- [x] 0.1 Offene Fragen aus `design.md` klären (Schreibweise, App-ID) und Domains sichern. Verifikation: Entscheide in `design.md` nachgetragen
- [x] 0.2 Offene Branches mergen, bevor die Umsetzung beginnt (Design D3). Verifikation: `git branch --no-merged main` zeigt keine Feature-Branches mehr

## 1. Sichtbarer Name

- [x] 1.1 Anzeigename „Stroke & Split“ in App-Titel, Startbildschirm, Meldungen, Android-Label, iOS `CFBundleDisplayName`, Linux-Fenstertitel und macOS-Produktname. Verifikation: `make check` grün, `git grep -i "aergrow"` findet keinen sichtbaren Text mehr in `lib`

## 2. Session-Dateien

- [x] 2.1 Export mit `.strokesplit` und `strokesplit-raw`, Import akzeptiert alt und neu, Dateidialog mit beiden Endungen. Verifikation: Unit-Tests für Roundtrip im neuen Format und Import der unveränderten Fixtures `just_row.jsonl`, `pause.jsonl`, `reset.jsonl`

## 3. Kennungen

- [ ] 3.1 Dart-Paket `aergrow` → `strokesplit`, `AergRowApp` → `StrokeSplitApp`, Dateinamen, als ein mechanischer Commit. Verifikation: `make check` grün
- [ ] 3.2 Plattform-IDs auf `ch.strokesplit.strokesplit`, Linux `BINARY_NAME` und `APPLICATION_ID`, Makefile-Pfade. Verifikation: `make build-linux` und `make run-android` starten die App unter dem neuen Namen
- [ ] 3.3 Datenbank `strokesplit` mit Übernahme einer vorhandenen `aergrow`-Datenbank (Design D2). Verifikation: Unit-Test mit einer Datei `aergrow` im Datenverzeichnis, manueller Test auf Linux mit bestehenden Sessions

## 4. Dokumentation

- [ ] 4.1 README mit neuem Namen und Abschnitt zum Umzug der Sessions per Export und Import auf Android und iOS. Verifikation: Durchsicht
- [ ] 4.2 Specs und Change-Dokumente mit `.aergrow` auf das neue Format aktualisieren, soweit sie nicht archiviert sind. Verifikation: `openspec validate --all` grün
- [ ] 4.3 Canvas „AergRow Frontend“ auf den neuen Namen umstellen. Verifikation: Startbildschirm und Canvas-Titel zeigen „Stroke & Split“
