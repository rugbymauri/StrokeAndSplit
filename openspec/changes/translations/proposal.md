# Proposal

## Why

Die Oberfläche ist heute fest deutsch: rund 250 Texte stehen direkt in den Screens, einige Fehlermeldungen kommen als deutsche Sätze aus der Datenschicht. Wer kein Deutsch liest, kann die App nicht nutzen. Jetzt, weil `ui-design` fast alle Screens neu baut: Steht die Übersetzbarkeit vorher, entstehen die neuen Screens gleich mit übersetzbaren Texten, statt sie danach ein zweites Mal herauszuziehen.

## What Changes

- Die Oberfläche ist übersetzbar. Zuerst gibt es Deutsch und Englisch, weitere Sprachen kommen als zusätzliche Übersetzungsdatei dazu, ohne Code zu ändern.
- Die Sprache wird in der App gewählt, die Wahl bleibt über einen Neustart erhalten. Beim ersten Start ist die App deutsch, die Systemsprache spielt keine Rolle (Entscheide F13, F14).
- Deutsch heisst Schweizer Rechtschreibung mit „ss“ statt „ß“, wie heute (F15, vorläufig nach Vorschlag).
- Die Datenschicht liefert Fehler als Codes mit Werten statt als deutsche Sätze. Die Oberfläche macht daraus Text in der gewählten Sprache. Betroffen sind die Prüfung von Zonen, das Einbauen von Zonen in Strecken und das Verbinden mit einem Rudergerät.
- Datum und Dezimalzahlen folgen der Sprache, z.B. „15.10.2026, 18:30“ und „22,5“ auf Deutsch. Pace und Zeiten bleiben im Format des PM5 (`2:05.3`).
- Was Nutzer selbst benennen (Zonen, Strecken, Vorlagen) und Gerätenamen werden nicht übersetzt.

Nicht Teil dieses Changes: der BLE-Spike (Entwicklerwerkzeug, bleibt deutsch), Log- und Ausnahmetexte für Entwickler (bleiben englisch) und die Gestaltung der Sprachwahl im neuen Layout (kommt mit `ui-design`).

## Capabilities

### New Capabilities

- `app-language`: Sprache der Oberfläche wählen und merken, übersetzte Texte und Meldungen, Formate nach Sprache, eigene Namen unübersetzt.

### Modified Capabilities

Keine. Die bestehenden Specs nennen Texte auf Deutsch; sie gelten weiter für die deutsche Oberfläche.

## Impact

- Abhängigkeiten: `flutter_localizations` (SDK), `intl`, `shared_preferences` für die gewählte Sprache. Keine Datenbankmigration, die Schemanummern bleiben (Schema 5 für `heart-rate`, F16, vorläufig nach Vorschlag).
- `l10n.yaml`, `lib/l10n/app_de.arb` (Vorlage) und `lib/l10n/app_en.arb`; generierter Code unter `lib/l10n/`.
- `lib/app`: `MaterialApp` mit Lokalisierung und gewählter Sprache, Sprachwahl.
- Alle Screens unter `lib/features/`: Texte aus den ARB-Dateien.
- `lib/data/zones/zone.dart`, `lib/data/courses/course_layout.dart`, `lib/data/sources/ble/`: Fehler als Codes.
- Formatierer in `lib/features/live/formatters.dart`, `lib/features/courses/course_format.dart`, `lib/features/zones/zone_format.dart`.
- Tests: Widget-Tests laufen mit Lokalisierung, neue Tests für Englisch und die Sprachwahl.
- Folge für alle späteren Changes: neue Texte nur über die ARB-Dateien, in jeder Sprache.
