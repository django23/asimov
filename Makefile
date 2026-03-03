.DEFAULT_GOAL := help
.PHONY: help test lint check bench bench-home install uninstall exclusions version release release-beta

## —————————— 🎵 Asimov 🎵 ————————————————————————————————————

help: ## Show this help
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

version: ## Print asimov version
	@./asimov --version

exclusions: ## List all paths excluded from Time Machine
	@sudo mdfind "com_apple_backup_excludeItem = 'com.apple.backupd'"


## —————————— 🛠 Development ———————————————————————————————————


test: ## Run Bats tests
	@bats tests/sentinels.bats tests/behavior.bats tests/format.bats tests/plist.bats

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
	VERSION=$$(./asimov --version); \
	TAG="v$$VERSION"; \
	echo "Tagging $$TAG..."; \
	git tag -a "$$TAG" -m "Release $$TAG"; \
	git push origin "$$TAG"; \
	echo "Tag $$TAG pushed — GitHub Actions will create the release."

release-beta: check ## Tag and push a beta pre-release — GitHub Actions will create the pre-release
	@set -e; \
	VERSION=$$(./asimov --version); \
	BETA_NUM=1; \
	while git tag | grep -q "^v$$VERSION-beta\.$$BETA_NUM$$"; do \
	  BETA_NUM=$$((BETA_NUM + 1)); \
	done; \
	TAG="v$$VERSION-beta.$$BETA_NUM"; \
	echo "Tagging $$TAG..."; \
	git tag -a "$$TAG" -m "Pre-release $$TAG"; \
	git push origin "$$TAG"; \
	echo "Tag $$TAG pushed — GitHub Actions will create the pre-release."
