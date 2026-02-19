.DEFAULT_GOAL := help
.PHONY: help test lint check


help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'

test: ## Run Bats tests
	@bats tests/asimov.bats

lint: ## Run Shellcheck on all shell scripts
	@shellcheck asimov install.sh tests/bin/run-tests.sh tests/bin/tmutil

check: test lint ## Run tests and linting
