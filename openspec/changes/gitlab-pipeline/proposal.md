# Proposal

## Why

Das Projekt hat keine CI. Ob `main` grün ist, weiss nur, wer lokal `make check` laufen lässt. Eine installierbare Version gibt es nur auf dem Rechner, auf dem sie gebaut wurde. Wer die App auf dem Handy oder einem anderen Linux-Rechner ausprobieren will, braucht heute eine eigene Flutter- und Android-Toolchain.

## What Changes

- **Tests in GitLab CI**: Bei jedem Push auf `main` und in jeder Merge Request laufen statische Analyse und Tests der App und von `packages/erg_protocol`, also dasselbe wie `make check`.
- **Release per Tag**: Ein Tag `vX.Y.Z` auf einem Commit von `main` erzeugt nach grünen Tests ein GitLab-Release `vX.Y.Z` mit zwei Downloads:
  - eine Android-APK (Universal-APK, **vorerst mit einem Debug-Key signiert**, nicht Play-Store-tauglich),
  - ein Linux-AppImage für x86_64.
- **Version aus dem Tag**: Versionsname und Versionscode der Pakete kommen aus dem Tag und der Pipeline, nicht aus `pubspec.yaml`.
- **Fester Debug-Keystore**: Alle CI-Builds signieren mit demselben Debug-Keystore aus einer GitLab-CI/CD-Variable. Damit lässt sich eine neue APK über eine ältere installieren, ohne die Sessions zu verlieren.
- **Linux-Desktop-Integration**: Eine `.desktop`-Datei und ein Platzhalter-Icon für das AppImage. Das Icon ist das bestehende Flutter-Standard-Launcher-Icon.
- Gebaut wird in Docker-Images auf den geteilten Linux-Runnern.

Nicht Teil dieses Changes: ein Release-Keystore und die Release-Signierung, Play Store und AAB, iOS-, macOS- und Windows-Builds, `.deb` oder Flatpak, ein eigenes Logo, automatische Changelogs.

## Capabilities

### New Capabilities

- `release-pipeline`: Automatische Prüfung von `main` und von Merge Requests sowie die Veröffentlichung versionierter Android- und Linux-Pakete als GitLab-Release.

### Modified Capabilities

Keine. Das Verhalten der App ändert sich nicht.

## Impact

- Neu: `.gitlab-ci.yml`, `linux/packaging/` (`.desktop`-Vorlage, `AppRun`, Platzhalter-Icon), gegebenenfalls ein Skript unter `tool/` für den AppImage-Bau.
- GitLab-Projekt: neue CI/CD-Variable für den Debug-Keystore. Releases und die Generic Package Registry werden genutzt. Das Projekt ist privat, die Downloads erfordern also Projektzugriff.
- `Makefile`: Ziele für den APK- und AppImage-Bau, damit CI und lokal dieselben Befehle nutzen.
- `README.md`: Abschnitt zu CI, Release-Ablauf und Installation von APK und AppImage.
- `docs/implementation-plan.md`: neuer Change in Überblick und Reihenfolge.
- Wechselwirkung mit `rename-stroke-and-split`: App- und Binärname stehen in der Pipeline an einer zentralen Stelle, der Rename-Change muss sie dort nachziehen.
