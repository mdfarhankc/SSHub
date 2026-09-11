# SSHub developer tasks. Run `make` to list them.
#
# Needs GNU Make and a POSIX shell. On Windows the recipes are run through Git
# Bash (pinned below), so `make` works from PowerShell and cmd too.
#
# The build recipes mirror .github/workflows/release.yml on purpose: a build
# that breaks in CI should break here the same way.

# Recipes are POSIX shell. On Windows, force Git Bash so they parse whatever the
# calling terminal is, and never WSL's bash (System32), which mangles Windows
# paths. Override GIT_BASH if Git is installed somewhere other than the default.
ifeq ($(OS),Windows_NT)
  GIT_BASH ?= C:/Program Files/Git/bin/bash.exe
  SHELL := $(GIT_BASH)
  .SHELLFLAGS := -c
endif

ISCC ?= C:/Program Files (x86)/Inno Setup 6/ISCC.exe

.DEFAULT_GOAL := help
.PHONY: help windows mobile setup analyze format pigeon version build-windows \
        installer portable build-linux build-macos build-apk site site-build \
        tag clean

help: ## List the available tasks
	@grep -hE '^[a-z][a-z-]*:.*?## ' $(MAKEFILE_LIST) \
		| sed 's/:.*## /|/' \
		| awk -F'|' '{printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

windows: ## Run the app on Windows
	flutter run -d windows

mobile: ## Run the app on the first attached device (DEVICE=<id> to choose)
	flutter run $(if $(DEVICE),-d $(DEVICE),)

setup: ## Fetch Dart and site dependencies
	flutter pub get
	npm --prefix site install

analyze: ## Run the Dart analyzer
	flutter analyze

format: ## Format Dart sources (the vendored xterm is left alone)
	dart format lib

pigeon: ## Regenerate the platform bridge from pigeons/
	dart run pigeon --input pigeons/secure_platform.dart
	dart format lib/core/security

version: ## Print the version from every file that must agree, and fail on drift
	@pub=$$(grep '^version:' pubspec.yaml | sed 's/version: *//; s/+.*//'); \
	app=$$(grep -o '"[^"]*"' lib/core/app_info.dart | tr -d '"'); \
	iss=$$(grep '^#define MyAppVersion' windows/packaging/sshub.iss | grep -o '"[^"]*"' | tr -d '"'); \
	web=$$(grep 'export const VERSION' site/src/lib/site.ts | grep -o '"[^"]*"' | tr -d '"'); \
	notes=$$(head -1 RELEASE_NOTES.md | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'); \
	printf '  %-18s %s\n' 'pubspec.yaml' "$$pub" 'app_info.dart' "$$app" \
		'sshub.iss' "$$iss" 'site.ts' "$$web" 'RELEASE_NOTES.md' "$$notes"; \
	for v in "$$app" "$$iss" "$$web" "$$notes"; do \
		if [ "$$v" != "$$pub" ]; then \
			echo; echo "  version drift: everything should read $$pub"; exit 1; \
		fi; \
	done; \
	echo; echo "  all agree on $$pub"

build-windows: ## Build the Windows release
	flutter build windows --release

installer: build-windows ## Build Windows and compile the installer into dist/
	@iscc="$(ISCC)"; \
	if [ ! -f "$$iscc" ]; then \
		for c in \
			"$$LOCALAPPDATA/Programs/Inno Setup 6/ISCC.exe" \
			"/c/Program Files (x86)/Inno Setup 6/ISCC.exe" \
			"/c/Program Files/Inno Setup 6/ISCC.exe"; do \
			if [ -f "$$c" ]; then iscc="$$c"; break; fi; \
		done; \
	fi; \
	if [ ! -f "$$iscc" ]; then \
		echo "ISCC.exe not found. Install Inno Setup 6, or: make installer ISCC=/path/to/ISCC.exe"; \
		exit 1; \
	fi; \
	"$$iscc" windows/packaging/sshub.iss

portable: build-windows ## Zip the Windows release as the portable build
	@mkdir -p dist
	cd build/windows/x64/runner/Release && powershell -NoProfile -Command \
		"Compress-Archive -Path * -DestinationPath '$(CURDIR)/dist/sshub-windows-x64-portable.zip' -Force"

build-linux: ## Build the Linux release (Linux host only)
	flutter build linux --release

build-macos: ## Build the macOS release (macOS host only)
	flutter build macos --release

build-apk: ## Build the Android APK
	flutter build apk --release

site: ## Serve the landing page locally
	npm --prefix site run dev

site-build: ## Build the landing page into site/dist
	npm --prefix site run build

tag: version ## Tag the current version locally, once every file agrees
	@v=$$(grep '^version:' pubspec.yaml | sed 's/version: *//; s/+.*//'); \
	git tag -a "v$$v" -m "SSHub $$v"; \
	echo "  tagged v$$v. Push it when you are ready: git push origin v$$v"

clean: ## Remove build output
	flutter clean
	rm -rf dist site/dist
