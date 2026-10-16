# Tasks

## 1. Grundlagen

- [ ] 1.1 Image-Tag `ghcr.io/cirruslabs/flutter:3.47.7` prüfen (Design D1, Risiko). Fehlt er, den Fallback wählen und in `design.md` nachtragen. Verifikation: `docker pull` des gewählten Tags gelingt, `flutter --version` im Container zeigt 3.47.x
- [ ] 1.2 `docs/implementation-plan.md`: Change `gitlab-pipeline` in Überblick, Reihenfolge und Abschnitt „Changes“ aufnehmen, Hinweis bei `rename-stroke-and-split` auf die Namen in CI (D9). Verifikation: Durchsicht, im selben Commit wie 1.3
- [ ] 1.3 `.gitlab-ci.yml` mit `workflow:rules` (MR, `main`, Tags), Variablen `APP_NAME` und `FLUTTER_VERSION`, Pub-Cache (D10) und Job `check` mit `make check` (D2). `.gradle/` in `.gitignore`. Verifikation: `glab ci lint` meldet gültig, die MR-Pipeline des Branches läuft mit grünem `check`
- [ ] 1.4 Bei Bedarf fehlende native Bibliotheken für die Tests (z. B. `libsqlite3`) in `check` nachinstallieren (Risiko „native Bibliotheken“). Verifikation: `check` ist grün mit derselben Testanzahl wie lokal `make check`

## 2. Android-Paket

- [x] 2.1 `make apk`: `flutter build apk --release` mit optionalen `BUILD_NAME`/`BUILD_NUMBER` als `--build-name`/`--build-number` (D4, D6), bestehendes `build-linux` unverändert. `make help` listet das Ziel. Verifikation: lokal `make apk BUILD_NAME=0.0.1 BUILD_NUMBER=7` erzeugt eine APK, `aapt dump badging` bzw. `apkanalyzer` zeigt `versionName=0.0.1`, `versionCode=7`. Erledigt: `aapt dump badging` zeigt `versionCode='7' versionName='0.0.1'`, Universal-APK mit `arm64-v8a`, `armeabi-v7a`, `x86_64`
- [ ] 2.2 Anleitung im README: Debug-Keystore mit `keytool` erzeugen (Alias `androiddebugkey`, Passwort `android`), als protected File-Variable `ANDROID_DEBUG_KEYSTORE` hinterlegen, `v*` als geschützten Tag einrichten (D5). Der Nutzer führt die Schritte in GitLab aus. Verifikation: die Variable und der geschützte Tag sind in den Projekteinstellungen sichtbar
- [ ] 2.3 Job `build-apk` (nur Tags `vX.Y.Z`): Keystore nach `~/.android/debug.keystore`, Abbruch mit Meldung, wenn die Variable fehlt, `make apk` mit Version aus Tag und `CI_PIPELINE_IID`, Gradle-Cache, Artefakt `${APP_NAME}-X.Y.Z-android.apk` mit kurzer Ablaufzeit. Verifikation: in der Pipeline des Probe-Tags `v0.1.0` (Task 4.3) liegt die APK als Artefakt vor, `apksigner verify --print-certs` zeigt das Zertifikat des hinterlegten Keystores

## 3. Linux-Paket

- [x] 3.1 `linux/packaging/`: `app.desktop.in` (D7: `Name`, `Exec`, `Icon`, `Categories=Utility;`, `StartupWMClass=ch.aergrow.aergrow`), `AppRun` und `icon.png` (Android-Launcher-Icon auf 256x256). Verifikation: `desktop-file-validate` auf die ausgefüllte Vorlage ist fehlerfrei. Erledigt: `desktop-file-validate` fehlerfrei
- [ ] 3.2 `tool/build_appimage.sh` und `make appimage`: AppDir aus `build/linux/x64/release/bundle/`, gepinntes `appimagetool` mit Prüfsumme, `APPIMAGE_EXTRACT_AND_RUN=1`, Ausgabe `${APP_NAME}-X.Y.Z-x86_64.AppImage`, App-Name per Umgebungsvariable (D9). `make help` listet das Ziel. Verifikation: lokal auf Fedora `make build-linux appimage` erzeugt ein AppImage, das nach `chmod +x` das App-Fenster öffnet
- [ ] 3.3 Job `build-appimage` (nur Tags `vX.Y.Z`): apt-Pakete aus D1, `flutter build linux --release` mit Version aus dem Tag, `make appimage`, Artefakt mit kurzer Ablaufzeit. Verifikation: das AppImage aus dem CI-Artefakt startet auf Fedora

## 4. Release

- [ ] 4.1 Job `verify-tag` in `.pre` (D3): Abbruch mit Meldung, wenn der Tag-Commit nicht in `origin/main` liegt oder das Release schon existiert. Verifikation: der Tag `v0.0.99` auf einem Commit, der nicht in `main` liegt, lässt die Pipeline in `verify-tag` mit der Meldung fehlschlagen, ohne dass Build-Jobs laufen. Danach den Tag löschen. Ein Tag `probe-1` erzeugt nur `check`
- [ ] 4.2 Job `upload`: beide Dateien mit `CI_JOB_TOKEN` in die Generic Package Registry `packages/generic/${APP_NAME}/X.Y.Z/` (D8). Verifikation: das Paket erscheint unter „Deploy → Package Registry“ mit beiden Dateien
- [ ] 4.3 Job `release` (`needs: upload`) mit dem `release:`-Keyword, Asset-Links `link_type: package` auf die Paket-URLs, Beschreibung mit Commit und Hinweis auf die Debug-Signierung. Verifikation: Probe-Release `v0.1.0` zeigt beide Downloads, die heruntergeladene APK installiert sich auf dem Handy, das AppImage startet auf Fedora
- [ ] 4.4 Wiederholung prüfen: Pipeline zu `v0.1.0` erneut starten. Verifikation: `verify-tag` schlägt fehl, Release und Paketdateien von `v0.1.0` sind unverändert (gleiche Anzahl Dateien in der Registry)
- [ ] 4.5 Update prüfen: mit installiertem `v0.1.0` und mindestens einer gespeicherten Session `v0.1.1` taggen und dessen APK installieren. Verifikation: Android installiert ohne Signaturfehler, die Session ist noch da, die App-Infos zeigen `0.1.1`

## 5. Dokumentation

- [ ] 5.1 README: Abschnitt „CI und Releases“ (was in MR/`main`/Tag läuft, wie man ein Release taggt, Tag nur auf `main`) und Abschnitt zur Installation von APK (unbekannte Quellen, Anmeldung im privaten Projekt) und AppImage (`chmod +x`, GTK 3), dazu die Keystore-Anleitung aus 2.2. Plattform-Status ergänzen. Verifikation: Durchsicht, die beschriebenen Befehle laufen wie angegeben
- [ ] 5.2 `docs/implementation-plan.md` auf den Endstand bringen (umgesetzt, Probe-Release, offene Punkte wie Release-Keystore und eigenes Logo). Verifikation: Durchsicht

## Workflow follow-up

- Probe-Releases `v0.1.0`/`v0.1.1` nach Wunsch behalten oder in GitLab löschen.
- Change nach dem Merge archivieren und in `docs/implementation-plan.md` nach „Erledigt“ verschieben.
