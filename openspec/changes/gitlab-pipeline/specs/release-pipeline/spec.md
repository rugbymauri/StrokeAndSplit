# Spec Delta

## Purpose

Prüft jeden Stand von `main` und jede Merge Request automatisch und veröffentlicht zu einem Versions-Tag installierbare Android- und Linux-Pakete als GitLab-Release.

## ADDED Requirements

### Requirement: Prüfung von main und Merge Requests
Die Pipeline SHALL bei jedem Push auf `main` und bei jeder Merge Request die statische Analyse und alle Tests der App und der lokalen Pakete ausführen. Schlägt eine Prüfung fehl, SHALL die Pipeline fehlschlagen.

#### Scenario: Push auf main mit grünen Tests
- **WHEN** ein Commit auf `main` gepusht wird und Analyse und Tests fehlerfrei sind
- **THEN** ist die Pipeline erfolgreich und erzeugt kein Release

#### Scenario: Merge Request mit fehlschlagendem Test
- **WHEN** eine Merge Request einen Commit enthält, bei dem ein Test der App oder von `erg_protocol` fehlschlägt
- **THEN** schlägt die Pipeline der Merge Request fehl

#### Scenario: Analyse-Fehler
- **WHEN** die statische Analyse der App oder eines lokalen Pakets einen Befund meldet, der lokal `make analyze` fehlschlagen lässt
- **THEN** schlägt die Pipeline fehl

### Requirement: Release aus einem Versions-Tag
Ein Tag der Form `vX.Y.Z` (X, Y, Z nicht-negative Ganzzahlen), dessen Commit auf `main` liegt, SHALL nach erfolgreichen Prüfungen ein GitLab-Release mit dem Namen des Tags erzeugen. Tags anderer Form und Tags auf Commits ausserhalb von `main` SHALL kein Release erzeugen.

#### Scenario: Gültiger Tag auf main
- **WHEN** der Tag `v1.2.0` auf einen Commit von `main` gesetzt wird und die Prüfungen grün sind
- **THEN** existiert danach ein Release `v1.2.0` mit einem Android- und einem Linux-Download

#### Scenario: Prüfung schlägt beim Tag fehl
- **WHEN** der Tag `v1.2.1` gesetzt wird und ein Test fehlschlägt
- **THEN** wird kein Paket gebaut und kein Release erzeugt

#### Scenario: Tag ausserhalb von main
- **WHEN** der Tag `v1.3.0` auf einen Commit gesetzt wird, der nicht in `main` enthalten ist
- **THEN** schlägt die Pipeline mit einer Meldung fehl, die den Grund nennt, und es entsteht kein Release

#### Scenario: Tag ohne Versionsform
- **WHEN** der Tag `spike-ftms` gesetzt wird
- **THEN** werden keine Pakete gebaut und es entsteht kein Release

### Requirement: Version der Pakete
Die Pakete eines Releases SHALL als Versionsnamen `X.Y.Z` aus dem Tag tragen. Der Android-Versionscode SHALL bei jedem späteren Release grösser sein als bei jedem früheren.

#### Scenario: Versionsname in der App
- **WHEN** das Release `v1.2.0` auf Android installiert wird
- **THEN** zeigen die App-Infos des Systems die Version `1.2.0`

#### Scenario: Aufsteigender Versionscode
- **WHEN** nach dem Release `v1.2.0` das Release `v1.2.1` gebaut wird
- **THEN** hat die APK von `v1.2.1` einen höheren Versionscode als die von `v1.2.0`

### Requirement: Android-Paket
Jedes Release SHALL eine einzelne, auf allen unterstützten Android-ABIs installierbare APK enthalten. Alle APKs aus der Pipeline SHALL mit demselben Schlüssel signiert sein, damit eine neuere APK eine ältere ohne Deinstallation und ohne Datenverlust ersetzt.

#### Scenario: Erstinstallation
- **WHEN** die APK eines Releases auf ein Android-Gerät geladen und installiert wird, das die Installation aus unbekannten Quellen erlaubt
- **THEN** startet die App und kann nach einem Rudergerät suchen

#### Scenario: Update über ein älteres Release
- **WHEN** auf einem Gerät mit installiertem Release `v1.2.0` und gespeicherten Sessions die APK von `v1.2.1` installiert wird
- **THEN** ersetzt Android die App ohne Signaturfehler, und die Sessions sind weiterhin vorhanden

### Requirement: Linux-Paket
Jedes Release SHALL ein AppImage für Linux x86_64 enthalten, das ohne Installation startet und einen Desktop-Eintrag mit Namen und Icon mitbringt. Es SHALL auf einem aktuellen Fedora und einem aktuellen Ubuntu mit installiertem GTK 3 laufen.

#### Scenario: Start des AppImage
- **WHEN** das AppImage eines Releases auf einem aktuellen Fedora heruntergeladen, ausführbar gemacht und gestartet wird
- **THEN** öffnet sich das App-Fenster

#### Scenario: Desktop-Eintrag
- **WHEN** das AppImage mit einem AppImage-Integrationswerkzeug ins Menü übernommen wird
- **THEN** erscheint die App mit ihrem Namen und Icon im Anwendungsmenü

### Requirement: Dauerhafte Downloads
Die Downloads eines Releases SHALL über die Release-Seite im GitLab-Projekt erreichbar sein und SHALL nicht nach einer Frist verfallen. Die Dateinamen SHALL App-Name, Version und Plattform enthalten.

#### Scenario: Älteres Release herunterladen
- **WHEN** ein Nutzer mit Projektzugriff Monate nach dem Release `v1.2.0` dessen Download-Links auf der Release-Seite öffnet
- **THEN** werden APK und AppImage von `v1.2.0` heruntergeladen

#### Scenario: Dateinamen
- **WHEN** das Release `v1.2.0` erzeugt wird
- **THEN** heissen die Dateien so, dass Version und Plattform ohne Öffnen erkennbar sind, z. B. `aergrow-1.2.0-android.apk` und `aergrow-1.2.0-x86_64.AppImage`

### Requirement: Kein Überschreiben veröffentlichter Releases
Die Pipeline SHALL ein bestehendes Release oder seine Downloads nicht überschreiben. Ein erneuter Lauf zu einem Tag, zu dem bereits ein Release existiert, SHALL fehlschlagen.

#### Scenario: Pipeline zu einem Tag erneut starten
- **WHEN** die Pipeline zum Tag `v1.2.0` erneut läuft, nachdem das Release `v1.2.0` schon erzeugt wurde
- **THEN** schlägt der Release-Schritt fehl, und Release und Downloads von `v1.2.0` bleiben unverändert
