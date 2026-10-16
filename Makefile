# Development commands for AergRow. Run `make` to list them.

FLUTTER ?= $(or $(shell command -v flutter 2>/dev/null),$(HOME)/dev/flutter/bin/flutter)
DART    ?= $(dir $(FLUTTER))dart
ADB     ?= $(or $(shell command -v adb 2>/dev/null),$(HOME)/Android/Sdk/platform-tools/adb)
# First Android device connected via adb; override with ANDROID_DEVICE=<id>.
# Only ids made of safe characters are taken, as the id ends up in a shell command.
ANDROID_DEVICE ?= $(shell $(ADB) devices 2>/dev/null | awk 'NR > 1 && $$2 == "device" && $$1 ~ /^[A-Za-z0-9._:-]+$$/ { print $$1; exit }')

PROTOCOL       := packages/erg_protocol
SPIKE          := lib/spike/spike_main.dart
RECORDINGS     := recordings
ANDROID_FILES  := /sdcard/Android/data/ch.aergrow.aergrow/files

.DEFAULT_GOAL := help
.PHONY: help doctor deps analyze test check codegen schema run run-android spike spike-android pull-recordings build-linux clean

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-z-]+:.*## / {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

doctor: ## Check the Flutter installation
	$(FLUTTER) doctor

deps: ## Fetch dependencies of the app and the local packages
	$(FLUTTER) pub get
	cd $(PROTOCOL) && $(DART) pub get

analyze: ## Run static analysis on the app and the local packages
	$(FLUTTER) analyze
	cd $(PROTOCOL) && $(DART) analyze --fatal-infos

test: ## Run all tests of the app and the local packages
	$(FLUTTER) test
	cd $(PROTOCOL) && $(DART) test

check: analyze test ## Run analysis and tests (same as tool/check.sh)

codegen: ## Generate code (drift, ...) with build_runner
	$(DART) run build_runner build --delete-conflicting-outputs

schema: ## Snapshot the drift schema and generate migration tests (after bumping schemaVersion)
	$(DART) run drift_dev make-migrations

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
	$(FLUTTER) build linux --release

clean: ## Remove build output
	$(FLUTTER) clean
	rm -rf $(PROTOCOL)/.dart_tool
