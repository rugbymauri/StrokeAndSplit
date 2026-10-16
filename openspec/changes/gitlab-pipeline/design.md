# Design

## Context

Motivation siehe `proposal.md`, Anforderungen siehe `specs/release-pipeline/spec.md`.

Stand im Repo:
- Flutter 3.47.7 stable (`.metadata`), App `aergrow` plus lokales Paket `packages/erg_protocol`. `make check` = `flutter analyze` + `dart analyze --fatal-infos` im Paket + `flutter test` + `dart test` im Paket. Das `Makefile` findet `flutter` über `command -v`.
- Generierter Code (`database.g.dart`, `app_localizations*.dart`) ist eingecheckt. CI braucht kein `build_runner`.
- Android: `applicationId` `ch.aergrow.aergrow`, der Release-Build ist schon jetzt mit `signingConfigs.getByName("debug")` signiert (`android/app/build.gradle.kts`). `versionName` und `versionCode` kommen aus Flutter, also aus `--build-name` und `--build-number`.
- Linux: `BINARY_NAME` `aergrow`, `APPLICATION_ID` `ch.aergrow.aergrow`. `flutter build linux --release` legt das Bundle in `build/linux/x64/release/bundle/` ab. Icon und `.desktop`-Datei gibt es nicht. Ein Launcher-Icon existiert nur für Android (`android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`, Flutter-Standard).
- GitLab 19.5 EE, Projekt privat. Geteilte Runner: Docker, amd64, nehmen auch Jobs ohne Tags (`run_untagged`). Es gibt noch keine geschützten Tags, keine Releases und keine Pipeline.

## Goals / Non-Goals

**Goals:**
- Eine `.gitlab-ci.yml` ohne externe Includes. Fertige CI-Templates für PHP-Projekte helfen hier nicht.
- CI und lokal bauen mit denselben `make`-Zielen, damit sich ein Fehler im CI-Job lokal nachstellen lässt.
- Die Namen (App, Binary) stehen an einer Stelle, damit `rename-stroke-and-split` sie dort umstellen kann.

**Non-Goals:**
- Release-Signierung, AAB, Play Store. Die Debug-Signierung ist eine bewusste Zwischenlösung.
- Prüfen, ob der eingecheckte generierte Code aktuell ist (`gen-l10n`, `build_runner` mit `git diff --exit-code`). Das kann später ein eigener Job werden.
- Ein eigenes CI-Image im Container-Registry des Projekts, solange die Laufzeit mit `apt-get` im Job erträglich bleibt.
- Linux arm64, Builds auf dem macOS- oder Windows-Runner.

## Decisions

### D1: Image `ghcr.io/cirruslabs/flutter:<Version von .metadata>`

Das Image enthält das Flutter-SDK und das Android-SDK samt Lizenzen, es basiert auf Ubuntu. Die Version ist auf die lokal genutzte (3.47.7) gepinnt und steht als Variable `FLUTTER_VERSION` in der `.gitlab-ci.yml`. Für den Linux-Build kommen im Job per `apt-get` `clang cmake ninja-build pkg-config libgtk-3-dev` dazu, für das AppImage zusätzlich `file` und `desktop-file-utils`.

Alternativen: Flutter im Job klonen. Das ist langsam und muss jedes Mal das Android-SDK beschaffen. Ein eigenes Image: der beste Cache, aber ein zweites Artefakt zu pflegen. Das wäre der nächste Schritt, wenn die apt-Schritte stören.

**Nachtrag bei der Umsetzung (Task 1.1):** Einen Tag `3.47.7` gibt es bei cirruslabs nicht. Die Registry `ghcr.io/cirruslabs/flutter` endet am 16.10.2026 bei `3.44.0` (= `stable`), es gibt keinen 3.47.x-Tag. `3.44.0` bringt Dart 3.12 mit, das Projekt verlangt `sdk: ^3.13.5`, das Image allein reicht also nicht. Gewählt ist darum eine Mischung aus Image und Flutter-Git-Tag: Die Jobs nutzen `ghcr.io/cirruslabs/flutter:3.44.0` (Variable `FLUTTER_IMAGE`) für Ubuntu 24.04, JDK und Android-SDK samt Lizenzen. Im `before_script` wird dessen Flutter-Checkout (`$FLUTTER_HOME`, ein flacher Git-Klon) per `git fetch --depth 1` auf den Tag `$FLUTTER_VERSION` umgestellt. Beim ersten `flutter`-Aufruf lädt Flutter dann das passende Dart-SDK und die Engine-Artefakte. Das kostet pro Job etwa eine Minute, ist aber deutlich kleiner als das Release-Archiv (1,5 GB) und braucht kein eigenes Image. Lokal im Container geprüft: `flutter --version` zeigt 3.47.7 mit Dart 3.13.5, `make check` läuft mit denselben Testzahlen wie auf dem Host. Erscheint bei cirruslabs wieder ein passender Tag, entfällt das Umstellen, und `FLUTTER_IMAGE` zeigt direkt auf ihn.

### D2: Stages und wann was läuft

```
  stage      job              MR   main   Tag vX.Y.Z   anderer Tag
  ---------  ---------------  ---  -----  -----------  -----------
  .pre       verify-tag        -     -        x            -
  test       check             x     x        x            -
  build      build-apk         -     -        x            -
  build      build-appimage    -     -        x            -
  release    upload            -     -        x            -
  release    release           -     -        x            -
```

`workflow:rules` lassen Pipelines nur für Merge Requests, für `main` und für Tags zu. Für einen Branch mit offener MR läuft nur die MR-Pipeline (`$CI_OPEN_MERGE_REQUESTS`), so entstehen keine doppelten Pipelines. Branches ohne MR bekommen keine Pipeline. Ausnahme (bei der Umsetzung ergänzt): Von Hand gestartete Pipelines (`web`, `api`, z. B. „Run pipeline“ oder `glab ci run`) laufen auf jedem Branch, damit sich die Pipeline ohne MR ausprobieren lässt. Tags anderer Form lassen nur `check` laufen (wie Task 4.1 es verlangt), Pakete und Release entstehen nur bei `vX.Y.Z`. Die Release-Jobs haben `rules: if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/`.

`check` führt `make check` aus. Eine eigene Testlogik in YAML gibt es nicht.

### D3: `verify-tag` prüft vor allem anderen

Der Job läuft in `.pre`, damit bei einem ungültigen Tag nichts gebaut wird. Er hat `GIT_DEPTH: 0` und
1. holt `main` und prüft mit `git merge-base --is-ancestor "$CI_COMMIT_SHA" origin/main`, ob der Tag-Commit in `main` liegt (Spec: Tag ausserhalb von `main`),
2. fragt über die Releases-API ab, ob es das Release `$CI_COMMIT_TAG` schon gibt, und bricht dann ab (Spec: kein Überschreiben). Dadurch lädt `upload` bei einem erneuten Lauf keine neuen Dateien in die Registry hoch.

Die Fehlermeldungen nennen den Grund im Klartext. Ein Image mit `git` und `curl` reicht, z. B. `alpine/git` oder das Flutter-Image.

Alternative: nur geschützte Tags. Das verhindert nicht, dass ein Maintainer einen Branch-Commit taggt.

### D4: Version aus Tag und Pipeline

`--build-name "${CI_COMMIT_TAG#v}"` und `--build-number "$CI_PIPELINE_IID"`. Die IID wächst pro Projekt monoton. Ein später erstellter Tag hat also immer einen höheren Versionscode, auch wenn er eine kleinere Version trägt. Ein Retry eines Jobs behält die IID, ein Neustart der Pipeline holt eine neue. Beides ist zulässig, weil `verify-tag` doppelte Releases ohnehin abweist. `pubspec.yaml` bleibt auf `1.0.0+1`, lokale Builds sind davon nicht betroffen.

Alternative: Versionscode aus der Version ableiten, z. B. `X*10000 + Y*100 + Z`. Das ist reproduzierbar, setzt aber Grenzen (Y, Z < 100). Ausserdem bekäme ein Hotfix `v1.1.5` nach `v1.2.0` einen kleineren Code, was die Spec (aufsteigender Versionscode) verletzt. Die IID ist einfacher.

### D5: Fester Debug-Keystore aus einer File-Variable

Einmalig wird lokal ein Debug-Keystore erzeugt, und zwar wie der Android-Standard (`keytool`, Alias `androiddebugkey`, Passwörter `android`). Er wird als CI/CD-Variable vom Typ *File* `ANDROID_DEBUG_KEYSTORE` hinterlegt, *protected*. `build-apk` kopiert ihn vor dem Build nach `~/.android/debug.keystore`. Gradle nutzt dann diesen Schlüssel, weil `build.gradle.kts` den Release-Build mit der Debug-Config signiert. Am Gradle-Code ändert sich nichts.

Fehlt die Variable, bricht `build-apk` ab, statt mit einem frischen Zufallsschlüssel zu bauen. Ein solcher Build liesse sich nicht über ältere Releases installieren (Spec: Update über ein älteres Release).

Weil die Variable *protected* ist, muss `v*` als geschützter Tag eingerichtet werden. Sonst sieht der Tag-Job die Variable nicht. Der Keystore ist kein Geheimnis von Wert (Debug, Standardpasswort). *Protected* verhindert nur, dass MR-Pipelines ihn sehen und mit ihm signieren.

Wird später auf einen Release-Keystore gewechselt, ist das ein Schlüsselwechsel. Android verlangt dann eine Deinstallation, ausser der Wechsel fällt mit dem neuen App-ID aus `rename-stroke-and-split` zusammen. Dann ist es ohnehin eine neue App.

### D6: Universal-APK

`flutter build apk --release` ohne `--split-per-abi` liefert eine APK für alle ABIs. Die Datei wird grösser, aber Nutzer müssen keine ABI wählen. Sie wird als `${APP_NAME}-X.Y.Z-android.apk` abgelegt.

### D7: AppImage mit `appimagetool` aus einem eigenen Skript

`tool/build_appimage.sh` setzt das AppDir aus dem Linux-Bundle zusammen und ruft `appimagetool` auf. `make appimage` ruft das Skript auf. Aufbau:

```
  ${APP_NAME}.AppDir/
  +-- AppRun                 Shell-Skript: exec "$APPDIR/usr/bin/${APP_NAME}" "$@"
  +-- ${APP_NAME}.desktop    aus linux/packaging/app.desktop.in
  +-- ${APP_NAME}.png        aus linux/packaging/icon.png (256x256, Platzhalter)
  +-- usr/bin/               Inhalt von build/linux/x64/release/bundle/
                             (Binary, lib/, data/; das Flutter-Bundle sucht
                             lib/ und data/ relativ zum Binary)
```

- `appimagetool` (1.9.1) und die AppImage-Runtime (`type2-runtime` 20251108) werden als feste Release-Versionen heruntergeladen, die Prüfsummen sind im Skript hinterlegt. Ohne `--runtime-file` holte `appimagetool` die jeweils neueste Runtime. Docker-Runner haben kein FUSE, darum läuft es mit `APPIMAGE_EXTRACT_AND_RUN=1`.
- Die `.desktop`-Datei: `Name=AergRow`, `Exec=${APP_NAME}`, `Icon=${APP_NAME}`, `Categories=Utility;`, `StartupWMClass=ch.aergrow.aergrow`. Damit ordnet der Desktop das GTK-Fenster dem Eintrag zu. `Sports` verlangt laut Desktop-Menu-Spec die Hauptkategorie `Game` und passt nicht. `appimagetool` prüft die Datei mit `desktop-file-validate`.
- Das Icon ist das Android-Launcher-Icon, auf 256x256 hochskaliert und als eigene Datei unter `linux/packaging/` eingecheckt, damit das Linux-Paket nicht vom Android-Ordner abhängt. Mit einem echten Logo wird nur diese Datei ersetzt.
- GTK 3 und glibc werden nicht gebündelt (Spec: Zielsysteme mit GTK 3). Weil im Ubuntu-Image des Flutter-Images gebaut wird, ist die glibc-Untergrenze die dieses Ubuntu. Aktuelle Fedora- und Ubuntu-Versionen liegen darüber.

Alternativen: `linuxdeploy` mit GTK-Plugin bündelt GTK mit. Das ist portabler, aber deutlich grösser und fehleranfälliger mit Themes. `flutter_distributor` braucht eine zusätzliche Dart-Abhängigkeit und Konfiguration für einen Zweck, den 40 Zeilen Shell erfüllen.

### D8: Downloads in der Generic Package Registry, Release mit Links

`upload` lädt beide Dateien mit `CI_JOB_TOKEN` nach `packages/generic/${APP_NAME}/X.Y.Z/<datei>`. `release` erzeugt das Release mit dem `release:`-Keyword (GitLab 19 nutzt dafür das `glab`-Image `registry.gitlab.com/gitlab-org/cli`). Die Asset-Links zeigen auf die Paket-URLs, `link_type: package`. Die Beschreibung nennt den Commit und den Hinweis auf die Debug-Signierung.

Job-Artefakte wären einfacher, verfallen aber (Spec: dauerhafte Downloads). Die Build-Jobs geben ihre Dateien als Artefakte mit kurzer Ablaufzeit an `upload` weiter.

### D9: Zentrale Namen

Oben in `.gitlab-ci.yml` stehen `APP_NAME: aergrow` (Binär- und Dateiname) und `FLUTTER_VERSION`. `tool/build_appimage.sh` nimmt den App-Namen als Umgebungsvariable mit Default `aergrow`. Der Rename-Change stellt an diesen Stellen und in der `.desktop`-Vorlage um.

### D10: Caches

`check` und die Build-Jobs teilen einen Cache für `$PUB_CACHE` (in das Projektverzeichnis umgebogen, `.pub-cache/`), Key `pubspec.lock` plus `packages/erg_protocol/pubspec.yaml`. Das Paket hat kein eingechecktes `pubspec.lock`, darum zählt dort die `pubspec.yaml`. `build-apk` cacht zusätzlich `.gradle/` (`GRADLE_USER_HOME`). `.pub-cache/` steht bereits in `.gitignore`, `.gradle/` muss dazukommen.

## Risks / Trade-offs

- [Kein Image-Tag `3.47.7` bei cirruslabs] → Eine Abfrage beim Planen bestätigte den Tag nicht. Task 1.1 prüft ihn vor allem anderen. Fallback: der nächstliegende 3.47.x-Tag, wenn `flutter analyze` und die Tests damit gleich laufen. Sonst ein eigenes Image aus `ubuntu` plus Flutter-Git-Tag.
- [Debug-signierte APK] → Nicht Play-Store-fähig, und wer den Keystore hat, kann eine APK mit derselben Signatur bauen. Für eine private Testverteilung ist das tragbar. Die Release-Beschreibung weist darauf hin.
- [Privates Projekt] → Die Download-Links verlangen eine Anmeldung bei GitLab. Auf dem Handy heisst das: im Browser angemeldet sein oder die Datei vom Rechner übertragen. Das README nennt beide Wege.
- [Tests brauchen native Bibliotheken] → Drift-Tests auf dem Host laden `libsqlite3`. Fehlt sie im Image, schlägt `check` fehl. Mitigation: in `check` per `apt-get` nachinstallieren, falls nötig.
- [BLE-abhängige Tests] → Die Tests laufen gegen Fakes und nicht gegen BlueZ. Sollte ein Test doch D-Bus brauchen, fällt das in CI zum ersten Mal auf und wird dort entschieden, nicht durch Ausschliessen.
- [Laufzeit] → apt plus Gradle-Erstlauf können pro Tag-Pipeline 10+ Minuten dauern. Bei Releases ist das akzeptabel. `check` braucht kein apt, ausser für sqlite.
- [Shared Runner mit `privileged`-Tag] → Wir brauchen kein Privileg. Die Jobs setzen keine Tags und laufen damit auf jedem Linux-Runner mit `run_untagged`.
- [Versionscode aus der IID] → Wird das Projekt einmal neu angelegt, beginnt die IID wieder bei 1. Dann müsste man die Build-Nummer mit einem Offset versehen. Unwahrscheinlich, steht hier als Hinweis.

## Migration Plan

1. Debug-Keystore erzeugen und als File-Variable hinterlegen, `v*` als geschützten Tag einrichten. Beides macht der Nutzer in GitLab, die Tasks beschreiben die Schritte.
2. Pipeline mergen. Ab dann laufen `check` in MRs und auf `main`.
3. Probe-Release mit einem Tag `v0.1.0`. Ist es fehlerhaft, lassen sich Release und Paket in GitLab löschen und mit einem neuen Tag (`v0.1.1`) wiederholen, ein Tag wird nicht neu vergeben.

Zurückrollen: `.gitlab-ci.yml` entfernen. Bestehende Releases bleiben bestehen.
