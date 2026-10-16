# Tasks

## 1. Grundlagen

- [x] 1.1 `flutter_localizations`, `intl` und `shared_preferences` einbinden, `l10n.yaml` nach D1, `lib/l10n/app_de.arb` und `app_en.arb` mit dem App-Titel, `make l10n`, `context.l10n`; `MaterialApp` mit Delegates und `supportedLocales`. Verifikation: `make check` grün, `flutter gen-l10n` ohne Warnung
- [x] 1.2 `test/support/localized_app.dart` (D7) und Test, der die Keys aller ARB-Dateien mit der Vorlage vergleicht. Bestehende Widget-Tests nutzen den Helfer. Verifikation: alle bestehenden Tests grün, der Key-Test schlägt mit einem fehlenden Key fehl

## 2. Sprachwahl

- [x] 2.1 `AppLanguage`, `LanguageStore` über `SharedPreferencesWithCache` und `appLanguageProvider` nach D2; `main` lädt den Store vor `runApp`, `MaterialApp` folgt der Sprache. Verifikation: Unit-Tests für Standard `de`, gespeicherte Sprache, unbekannten Wert und Schreiben bei der Wahl
- [x] 2.2 Sprachwahl im Startbildschirm nach D3, Sprachen in ihrer eigenen Schreibweise, Wahl gilt sofort. Verifikation: Widget-Test wechselt auf „English“, der Startbildschirm zeigt „Find rower“, ein neuer Container mit demselben Store startet englisch

## 3. Datenschicht ohne Sätze

- [x] 3.1 `ZoneError` und `ZoneValidationException` nach D4; Zonen-Editor übersetzt die Codes. Verifikation: Unit-Tests der Prüfung auf Codes umgestellt, Widget-Test im Zonen-Editor zeigt den Fehler deutsch und englisch
- [x] 3.2 `PlacementErrorKind` mit Werten nach D4; Strecken-Editor und Zonen-Editor übersetzen die Fehler. Verifikation: Unit-Tests in `course_layout_test.dart` prüfen Art und Werte, Widget-Test zeigt „ragt über das Streckenende“ deutsch und englisch
- [x] 3.3 `RowerConnectError` nach D4; Geräteliste übersetzt die Codes. Verifikation: Tests in `rower_connector_test.dart` prüfen die Codes, Widget-Test zeigt die BikeErg-Meldung deutsch und englisch

## 4. Texte der Screens

- [ ] 4.1 Verbindung: Startbildschirm, Geräteliste, Verbindungsanzeige, Bluetooth-Hinweise. Verifikation: Widget-Tests in `test/features/connection/` grün, ein Test der Geräteliste auf Englisch
- [ ] 4.2 Live-Display, Streckenleiste und Simulator-Bedienung. Verifikation: Layout-Tests grün, ein Live-Test mit Vorlage auf Englisch
- [ ] 4.3 Sessions: Liste, Zusammenfassung, Aktionen (Abspielen, Export, Import, Löschen) und die Bezeichnung der Quelle. Verifikation: Tests in `test/features/sessions/` grün, Zusammenfassung auf Englisch
- [ ] 4.4 Vorlagen: Liste mit Quellenwahl und Vorlagen-Editor. Verifikation: Tests in `test/features/templates/` grün, Editor auf Englisch
- [ ] 4.5 Strecken: Liste und Strecken-Editor. Verifikation: Tests in `test/features/courses/` grün, Editor auf Englisch
- [ ] 4.6 Zonen: Liste und Zonen-Editor. Verifikation: Tests in `test/features/zones/` grün, Liste auf Englisch

## 5. Formate

- [ ] 5.1 Datum mit Uhrzeit und Dezimalzahlen nach Sprache (D5), Muster in der ARB-Datei; „frei“, Nutzung der Zonen mit `plural`. Pace und Zeiten bleiben unverändert. Verifikation: Unit-Tests für „15.10.2026, 18:30“, „Oct 15, 2026, 18:30“, „22,5“, „22.5“ und unveränderte Pace in beiden Sprachen

## 6. Abschluss

- [ ] 6.1 Suche nach verbliebenen Text-Literalen in `lib/features/` und `lib/app/`; was übrig bleibt, ist begründet (Einheiten, Formate, Eigennamen). README: Abschnitt Sprache und Hinweis „neue Texte nur über die ARB-Dateien“ für Beitragende. Verifikation: Durchsicht der Suchergebnisse, README gelesen
- [ ] 6.2 `make check` grün und `openspec validate translations --strict` gültig
- [ ] 6.3 Manuell auf Linux und Android: Sprache wechseln, App neu starten, alle Screens in beiden Sprachen durchgehen, keine abgeschnittenen Texte

## Workflow follow-up

- Change archivieren, sobald der manuelle Test 6.3 abgeschlossen ist.
