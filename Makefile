.DEFAULT_GOAL := help
.PHONY: help test lint check bench bench-home install uninstall exclusions version release release-beta bump-formula

TAP_DIR ?= ../homebrew-tap

## —————————— 🎵 Asimov 🎵 ————————————————————————————————————

help: ## Show this help
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

version: ## Print asimov version
	@./asimov --version

exclusions: ## List all paths excluded from Time Machine
	@sudo mdfind "com_apple_backup_excludeItem = 'com.apple.backupd'"


## —————————— 🛠 Development ———————————————————————————————————


test: ## Run Bats tests
	@bats tests/sentinels.bats tests/behavior.bats tests/cache.bats tests/format.bats tests/plist.bats

lint: ## Run Shellcheck on all shell scripts
	@shellcheck asimov scripts/install.sh scripts/install-remote.sh scripts/uninstall.sh tests/test_helper.bash tests/bin/run-tests.sh tests/bin/tmutil tests/bin/mdfind

check: test lint ## Run tests and linting

## bench: Compare dry-run scan timing: current vs v0.4.2, against tests/fixture
bench:
	@git show v0.4.2:asimov > /tmp/asimov-v042 && chmod +x /tmp/asimov-v042
	@echo "=== v0.4.2 (HOME=tests/fixture) ==="
	@bash -c 'time HOME="$(CURDIR)/tests/fixture" /tmp/asimov-v042 --dry-run'
	@echo ""
	@echo "=== v0.5.x (directory=tests/fixture) ==="
	@bash -c 'time HOME="$(CURDIR)/tests/fixture" ./asimov --dry-run "$(CURDIR)/tests/fixture"'
	@rm -f /tmp/asimov-v042

## bench-home: Compare dry-run scan timing: current vs v0.4.2, against real home directory
bench-home:
	@git show v0.4.2:asimov > /tmp/asimov-v042 && chmod +x /tmp/asimov-v042
	@echo "=== v0.4.2 (full home) ==="
	@bash -c 'time /tmp/asimov-v042 --dry-run'
	@echo ""
	@echo "=== v0.5.x (full home) ==="
	@bash -c 'time ./asimov --dry-run'
	@rm -f /tmp/asimov-v042


## —————————— 📦 Installation ——————————————————————————————————


NAME ?= asimov

install: ## Install Asimov and schedule via launchd (NAME=asimov2 to install under a different name for testing)
	@NAME=$(NAME) scripts/install.sh

uninstall: ## Uninstall Asimov and remove launchd schedule (NAME=asimov2 to remove a non-default install)
	@NAME=$(NAME) scripts/uninstall.sh


## —————————— 🚀 Release ———————————————————————————————————————


release: check ## Tag and push a stable release — GitHub Actions will create the release
	@set -e; \
	if [ -n "$$(git status --porcelain)" ]; then echo "error: working tree not clean"; exit 1; fi; \
	BRANCH=$$(git rev-parse --abbrev-ref HEAD); \
	if [ "$$BRANCH" != "main" ]; then echo "error: releases must be tagged from main (on $$BRANCH)"; exit 1; fi; \
	VERSION=$$(./asimov --version); \
	TAG="v$$VERSION"; \
	if git rev-parse "$$TAG" >/dev/null 2>&1; then echo "error: $$TAG already exists"; exit 1; fi; \
	echo "Tagging $$TAG (signed)..."; \
	git tag -s "$$TAG" -m "Release $$TAG"; \
	git push origin "$$TAG"; \
	echo "Tag $$TAG pushed — GitHub Actions will create the release."; \
	echo "Next: run 'make bump-formula' once the release tarball is available."

release-beta: check ## Tag and push a beta pre-release — GitHub Actions will create the pre-release
	@set -e; \
	if [ -n "$$(git status --porcelain)" ]; then echo "error: working tree not clean"; exit 1; fi; \
	VERSION=$$(./asimov --version); \
	BETA_NUM=1; \
	while git tag | grep -q "^v$$VERSION-beta\.$$BETA_NUM$$"; do \
	  BETA_NUM=$$((BETA_NUM + 1)); \
	done; \
	TAG="v$$VERSION-beta.$$BETA_NUM"; \
	echo "Tagging $$TAG (signed)..."; \
	git tag -s "$$TAG" -m "Pre-release $$TAG"; \
	git push origin "$$TAG"; \
	echo "Tag $$TAG pushed — GitHub Actions will create the pre-release."

bump-formula: ## Update the Homebrew tap formula to match the current asimov version (TAP_DIR=../homebrew-tap)
	@set -e; \
	if [ ! -d "$(TAP_DIR)/Formula" ]; then echo "error: $(TAP_DIR)/Formula not found — clone django23/homebrew-tap to $(TAP_DIR)"; exit 1; fi; \
	VERSION=$$(./asimov --version); \
	TAG="v$$VERSION"; \
	URL="https://github.com/django23/asimov/archive/refs/tags/$$TAG.tar.gz"; \
	echo "Fetching $$URL ..."; \
	SHA=$$(curl -fsSL "$$URL" | shasum -a 256 | awk '{print $$1}'); \
	if [ -z "$$SHA" ] || [ "$$SHA" = "0000000000000000000000000000000000000000000000000000000000000000" ]; then echo "error: failed to compute sha256 (is the release published?)"; exit 1; fi; \
	echo "sha256: $$SHA"; \
	FORMULA="$(TAP_DIR)/Formula/asimov.rb"; \
	/usr/bin/sed -i '' -E "s|url \"https://github.com/django23/asimov/archive/refs/tags/v[^\"]+\"|url \"$$URL\"|" "$$FORMULA"; \
	/usr/bin/sed -i '' -E "s|sha256 \"[a-f0-9]{64}\"|sha256 \"$$SHA\"|" "$$FORMULA"; \
	/usr/bin/sed -i '' -E "s|version \"[^\"]+\"|version \"$$VERSION\"|" "$$FORMULA"; \
	echo "Updated $$FORMULA"; \
	( cd "$(TAP_DIR)" && git diff --stat Formula/asimov.rb; \
	  git add Formula/asimov.rb && \
	  git commit -S -m "asimov $$VERSION" && \
	  echo "Review the commit in $(TAP_DIR), then: cd $(TAP_DIR) && git push" )
