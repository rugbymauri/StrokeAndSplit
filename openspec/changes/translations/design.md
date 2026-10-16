# Design

## Context

Motivation und Umfang stehen in `proposal.md`, das Verhalten in `specs/app-language/spec.md`.

Stand heute:
- **Texte:** `MaterialApp` ohne `localizationsDelegates`. Die Texte stehen als Literale in 17 Screens unter `lib/features/`.
- **Datenschicht:** Sie baut an drei Stellen deutsche Sätze.
  - `zoneErrors` in `lib/data/zones/zone.dart` liefert eine Liste von Sätzen. `ZoneRepository` wirft sie als `ArgumentError(errors.join(' '))`.
  - `PlacementError` in `lib/data/courses/course_layout.dart` trägt einen fertigen Satz mit Zonennamen, Bereichen und Längen.
  - `RowerConnectException` in `lib/data/sources/ble/` trägt einen Satz, `notARower` und bei technischen Fehlern den Text der Ausnahme.
- **Formatierer:** Sie sind reine Funktionen ohne Sprache.
  - `formatDateTime` schreibt `15.10.2026, 18:30`.
  - `formatStrokeRate` schreibt `22.5`.
  - `formatSegmentBands` schreibt `frei`.
  - `formatZoneUsage` schreibt „in 2 Strecken“.
- **Tests:** Die Widget-Tests suchen deutsche Texte.

## Goals / Non-Goals

**Goals:**
- Eine weitere Sprache braucht nur eine ARB-Datei und ihren Eintrag in der Liste der Sprachen.
- Die bestehenden Widget-Tests bleiben auf Deutsch und laufen unverändert weiter, abgesehen vom Aufbau der Testumgebung.
- Die Datenschicht bleibt ohne Flutter-Abhängigkeit für Texte.

**Non-Goals:**
- Rechts-nach-links-Sprachen.
- Übersetzte Inhalte in Exportdateien. Der Header von `.aergrow` bleibt sprachneutral (Codes, Zahlen, Namen).
- Der BLE-Spike und Texte für Entwickler (Logs, `toString`, Ausnahmen, die Programmierfehler melden).

## Decisions

### D1: `gen-l10n` mit ARB-Dateien

Grundlage sind `flutter_localizations` und `intl` mit `generate: true` und einer `l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_de.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
required-resource-attributes: true
```

- `app_de.arb` ist die Vorlage. Jeder Eintrag hat eine `@`-Beschreibung, wo er erscheint, damit Übersetzer den Zusammenhang kennen.
- Der erzeugte Code liegt unter `lib/l10n/` und wird wie der drift-Code eingecheckt. Ein `make l10n` erzeugt ihn neu.
- Zugriff in Widgets über `context.l10n`, eine Extension auf `BuildContext`.
- Keys sind englisch und nach Screen gruppiert, z.B. `deviceListTitle`, `zoneErrorNoBand`.
- Mengen und Werte nutzen ICU-Platzhalter und `plural`, z.B. `zoneUsage` mit `=0`, `=1` und `other`.

*Alternative:* `easy_localization` oder `slang`. Verworfen, weil `gen-l10n` zum SDK gehört, typsichere Getter erzeugt und ohne weiteres Paket auskommt.

### D2: Sprache als `AppLanguage` mit `shared_preferences` (F16)

- `enum AppLanguage { de, en }` trägt `locale` und den Eigennamen (`Deutsch`, `English`). Die Reihenfolge der Werte ist die Reihenfolge in der Sprachwahl.
- Ein Riverpod-Notifier `appLanguageProvider` liest die Sprache beim Start aus einem `LanguageStore`. Das ist eine kleine Schnittstelle über `SharedPreferencesWithCache`, Key `language`. Der Notifier schreibt bei jeder Wahl.
- Ohne Eintrag gilt `de`. Ein unbekannter Wert, z.B. eine entfernte Sprache, gilt ebenfalls als `de`.
- `main` öffnet den Store vor `runApp`. So erscheint der erste Frame schon in der gewählten Sprache.
- `MaterialApp` bekommt `locale: language.locale`, die Delegates und `supportedLocales` aus `AppLocalizations`. Weil `locale` immer gesetzt ist, spielt die Systemsprache keine Rolle (F14).
- Tests überschreiben den Store mit einer Variante im Speicher.

*Alternative:* eine drift-Tabelle für Einstellungen. Verworfen, weil sie eine Migration bräuchte und `heart-rate` dann Schema 6 statt 5 bekäme, und das für einen einzigen Wert.

### D3: Sprachwahl vorerst im Startbildschirm

Ein Symbol `Icons.language` in der AppBar des Startbildschirms öffnet einen Dialog mit den Sprachen. Die gewählte ist markiert. `ui-design` verlegt die Sprachwahl in sein Layout.

### D4: Datenschicht liefert Codes

- `zoneErrors` liefert `List<ZoneError>`, ein Enum: `nameMissing`, `lengthMissing`, `bandMissing`, `paceBoundMissing`, `paceReversed`, `spmBoundMissing`, `spmReversed`.
  - `ZoneRepository` wirft `ZoneValidationException(errors)` statt `ArgumentError` mit Text.
- `PlacementError` bekommt eine Art (`PlacementErrorKind`: `lengthMissing`, `zoneMissing`, `axisMismatch`, `beforeStart`, `beyondEnd`, `overlap`).
  - Die Werte für den Text kommen als Felder mit: Zonennamen, Achsen, Bereich, Streckenlänge.
  - Bereiche und Längen bleiben als formatierte Zahlen (`500–600 m`, `4:00`). Diese Formate sind sprachneutral.
  - `placements` bleibt, wie es ist.
- `RowerConnectException` bekommt `RowerConnectError`: `failed`, `noRowingService`, `skiErg`, `bikeErg`, `noRowerData`.
  - `notARower` ergibt sich aus dem Code (`skiErg`, `bikeErg`, `noRowerData`).
  - `message` bleibt als technisches Detail für Logs. Die Oberfläche zeigt es nicht.
- Je eine Funktion unter `lib/features/` macht aus dem Code einen Text, z.B. `zoneErrorText(l10n, error)`.

*Alternative:* `AppLocalizations` in die Datenschicht reichen. Verworfen, weil die Datenschicht sonst von der Oberfläche abhängt und Tests der Datenschicht eine Sprache bräuchten.

### D5: Formate über `intl`

Die Formatierer, die von der Sprache abhängen, bekommen den Locale-Namen bzw. `AppLocalizations` als Parameter:

- **Datum mit Uhrzeit:**
  - `de`: `dd.MM.yyyy, HH:mm`, also `15.10.2026, 18:30`.
  - `en`: `MMM d, y, HH:mm`, also `Oct 15, 2026, 18:30`.
  - Das Muster pro Sprache steht in der ARB-Datei (`dateTimePattern`), damit eine neue Sprache es mitbringt.
- **Dezimalzahlen:** `NumberFormat('0.0', locale)` ergibt `22,5` bzw. `22.5`.
- **Pace, Zeiten, Rundenzeiten, Distanz in Metern:** bleiben ohne Sprache.
- **„frei“, „in 2 Strecken“ und Einheitenwörter:** kommen aus den ARB-Dateien. `m` und `spm` bleiben in beiden Sprachen gleich.

### D6: Deutsch mit Schweizer Rechtschreibung (F15)

`app_de.arb` ist Deutsch ohne „ß“, Locale `de`. Eine eigene Variante `de_CH` gibt es nicht, weil es nur eine deutsche Datei gibt. Kommt eine Fassung für Deutschland dazu, wird sie `app_de_DE.arb`.

### D7: Tests

- `test/support/localized_app.dart` stellt `MaterialApp` mit Delegates und Sprache bereit. Die bestehenden Widget-Tests nutzen es statt `MaterialApp(home: …)`.
- Ein Test vergleicht die Keys aller ARB-Dateien mit der Vorlage. Fehlt ein Key oder ist einer zu viel, schlägt er fehl.
- Pro Bereich (Verbindung, Live, Sessions, Vorlagen, Strecken, Zonen) prüft mindestens ein Widget-Test die englische Oberfläche, inklusive einer Meldung aus der Datenschicht.

## Risks / Trade-offs

- [Texte aus Screens, die `ui-design` bald ersetzt, werden zweimal angefasst.] → Die meisten Texte bleiben erhalten und wandern mit ihren Keys in die neuen Screens. `ui-design` verwendet die vorhandenen Keys.
- [Ein vergessenes Literal fällt in Tests nicht auf, solange es deutsch ist.] → Die englischen Widget-Tests pro Bereich, dazu eine Suche nach Literalen in `lib/features/` als Prüfschritt im letzten Task.
- [Englische Übersetzungen ohne Muttersprachler.] → Kurze, eindeutige Texte. Die `@`-Beschreibungen erleichtern eine spätere Durchsicht.
- [`shared_preferences` ist ein weiteres Plugin, auch für Linux.] → Es ist ein Flutter-Favorite mit Linux-Unterstützung. Der Store steckt hinter einer Schnittstelle.

## Migration Plan

Keine Datenmigration. Nach dem Update ist die App deutsch wie vorher. Rückgängig machen heisst den Change zurücknehmen; der Eintrag in `shared_preferences` bleibt dann ungelesen liegen.
