# Development commands for Stroke & Split. Run `make` to list them.

FLUTTER ?= $(or $(shell command -v flutter 2>/dev/null),$(HOME)/dev/flutter/bin/flutter)
DART    ?= $(dir $(FLUTTER))dart
ADB     ?= $(or $(shell command -v adb 2>/dev/null),$(HOME)/Android/Sdk/platform-tools/adb)
# First Android device connected via adb; override with ANDROID_DEVICE=<id>.
# Only ids made of safe characters are taken, as the id ends up in a shell command.
ANDROID_DEVICE ?= $(shell $(ADB) devices 2>/dev/null | awk 'NR > 1 && $$2 == "device" && $$1 ~ /^[A-Za-z0-9._:-]+$$/ { print $$1; exit }')

PROTOCOL       := packages/erg_protocol
SPIKE          := lib/spike/spike_main.dart
RECORDINGS     := recordings
ANDROID_FILES  := /sdcard/Android/data/ch.strokesplit.strokesplit/files

# Optional version for release builds, e.g. `make apk BUILD_NAME=1.2.0 BUILD_NUMBER=42`.
# Without them, Flutter takes the version from pubspec.yaml.
BUILD_NAME   ?=
BUILD_NUMBER ?=
BUILD_FLAGS  := $(if $(BUILD_NAME),--build-name $(BUILD_NAME)) $(if $(BUILD_NUMBER),--build-number $(BUILD_NUMBER))

# APK installed by `make install-apk`; set APK=<file> to install a downloaded one instead of building.
APK ?=
APK_BUILT := build/app/outputs/flutter-apk/app-release.apk

.DEFAULT_GOAL := help
.PHONY: help doctor deps analyze format test check coverage codegen l10n schema check-generated icons run run-android spike spike-android pull-recordings build-linux apk install-apk appimage clean

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-z-]+:.*## / {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

doctor: ## Check the Flutter installation
	$(FLUTTER) doctor

deps: ## Fetch dependencies of the app and the local packages
	$(FLUTTER) pub get
	cd $(PROTOCOL) && $(DART) pub get

analyze: ## Run static analysis and the format check on the app and the local packages
	@$(DART) format --output=none --set-exit-if-changed . > /dev/null \
		|| { $(DART) format --output=none . | grep '^Changed'; echo "Code is not formatted: run make format."; exit 1; }
	$(FLUTTER) analyze
	cd $(PROTOCOL) && $(DART) analyze --fatal-infos

test: ## Run all tests of the app and the local packages
	$(FLUTTER) test
	cd $(PROTOCOL) && $(DART) test

format: ## Format all Dart code of the app and the local packages
	$(DART) format .

check: analyze test ## Run analysis and tests (same as tool/check.sh)

coverage: ## Run all tests with coverage and print it (lcov files in coverage/ and $(PROTOCOL)/coverage/)
	$(FLUTTER) test --coverage
	cd $(PROTOCOL) && $(DART) test --coverage-path=coverage/lcov.info
	@tool/coverage_summary.sh App=coverage/lcov.info erg_protocol=$(PROTOCOL)/coverage/lcov.info

codegen: ## Generate code (drift, ...) with build_runner
	$(DART) run build_runner build --delete-conflicting-outputs

l10n: ## Generate the translations from lib/l10n/*.arb (after changing an ARB file)
	$(FLUTTER) gen-l10n

schema: ## Snapshot the drift schema and generate migration tests (after bumping schemaVersion)
	$(DART) run drift_dev make-migrations

check-generated: codegen l10n schema ## Fail if drift code, translations or schema snapshots differ from the committed files (needs a clean working tree)
	@if [ -n "$$(git status --porcelain)" ]; then \
		git status --short; git diff --stat; \
		echo "Generated files are out of date: run make codegen l10n schema and commit the result."; exit 1; \
	fi

icons: ## Render the app icon from assets/icon/*.svg and generate the platform icons (after changing an SVG, needs ImageMagick with librsvg)
	magick -background none assets/icon/app_icon.svg assets/icon/app_icon.png
	magick -background none assets/icon/app_icon_foreground.svg assets/icon/app_icon_foreground.png
	magick assets/icon/app_icon.png -resize 512x512 linux/packaging/icon.png
	$(DART) run flutter_launcher_icons
	@# flutter_launcher_icons sets an invalid value for ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS
	git checkout -- ios/Runner.xcodeproj/project.pbxproj

run: ## Start the app on the Linux desktop
	$(FLUTTER) run -d linux

run-android: ## Start the app on a connected Android device
	$(FLUTTER) run -d $(or $(ANDROID_DEVICE),$(error No Android device found, check `$(ADB) devices`))

spike: ## Start the BLE spike for PM5 and FTMS rowers on the Linux desktop (recordings go to the documents folder, e.g. ~/Dokumente)
	$(FLUTTER) run -d linux -t $(SPIKE)

spike-android: ## Start the BLE spike for PM5 and FTMS rowers on a connected Android device
	$(FLUTTER) run -d $(or $(ANDROID_DEVICE),$(error No Android device found, check `$(ADB) devices`)) -t $(SPIKE)

ftms-rower: ## Play an FTMS recording as a software FTMS rower over Bluetooth (FILE=recording.jsonl, test from a phone)
	uv run tool/ftms_rower/ftms_rower.py $(or $(FILE),$(error Set FILE to an FTMS recording, e.g. packages/erg_protocol/test/fixtures/ftms_just_row.jsonl)) $(ARGS)

pull-recordings: ## Copy spike recordings from the Android device to ./recordings
	mkdir -p $(RECORDINGS)
	$(ADB) pull $(ANDROID_FILES)/. $(RECORDINGS)/

build-linux: ## Build a Linux release bundle
	$(FLUTTER) build linux --release $(BUILD_FLAGS)

apk: ## Build a universal Android release APK (BUILD_NAME=1.2.0 BUILD_NUMBER=42 optional)
	$(FLUTTER) build apk --release $(BUILD_FLAGS)

install-apk: ## Build the release APK and install it on a connected Android device (APK=file installs that one instead)
	$(if $(APK),,$(MAKE) apk)
	$(ADB) -s $(or $(ANDROID_DEVICE),$(error No Android device found, check `$(ADB) devices`)) install -r $(or $(APK),$(APK_BUILT))

appimage: ## Pack the Linux release bundle into an AppImage (after build-linux; BUILD_NAME optional)
	tool/build_appimage.sh $(BUILD_NAME)

clean: ## Remove build output
	$(FLUTTER) clean
	rm -rf $(PROTOCOL)/.dart_tool
