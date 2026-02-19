.DEFAULT_GOAL := help
.PHONY: help test lint check install uninstall exclusions


help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'

test: ## Run Bats tests
	@bats tests/sentinels.bats tests/behavior.bats

lint: ## Run Shellcheck on all shell scripts
	@shellcheck asimov scripts/install.sh scripts/uninstall.sh tests/bin/run-tests.sh tests/bin/tmutil

check: test lint ## Run tests and linting

install: ## Install Asimov and schedule via launchd
	@scripts/install.sh

uninstall: ## Uninstall Asimov and remove launchd schedule
	@scripts/uninstall.sh

exclusions: ## List all paths excluded from Time Machine
	@sudo mdfind "com_apple_backup_excludeItem = 'com.apple.backupd'"
