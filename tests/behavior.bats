#!/usr/bin/env bats
#
# Behavioral tests: negative cases, multi-match, idempotency, skip paths, nesting.

load test_helper

# =============================================================================
# Negative tests: directory without sentinel should NOT be excluded
# =============================================================================

@test "does not exclude node_modules without package.json" {
  mkdir -p "${HOME}/Code/My-Project/node_modules"
  run_asimov
  refute_excluded "${HOME}/Code/My-Project/node_modules"
  [[ "$(count_exclusions)" -eq 0 ]]
}

@test "does not exclude vendor without any sentinel" {
  mkdir -p "${HOME}/Code/My-Project/vendor"
  run_asimov
  refute_excluded "${HOME}/Code/My-Project/vendor"
  [[ "$(count_exclusions)" -eq 0 ]]
}

@test "does not exclude target without any sentinel" {
  mkdir -p "${HOME}/Code/My-Project/target"
  run_asimov
  refute_excluded "${HOME}/Code/My-Project/target"
  [[ "$(count_exclusions)" -eq 0 ]]
}

@test "does not exclude .venv without any sentinel" {
  mkdir -p "${HOME}/Code/My-Project/.venv"
  run_asimov
  refute_excluded "${HOME}/Code/My-Project/.venv"
  [[ "$(count_exclusions)" -eq 0 ]]
}

@test "does not exclude DerivedData without *.xcodeproj" {
  mkdir -p "${HOME}/Code/My-Project/DerivedData"
  run_asimov
  refute_excluded "${HOME}/Code/My-Project/DerivedData"
  [[ "$(count_exclusions)" -eq 0 ]]
}

@test "does not exclude bin without any .NET project file" {
  mkdir -p "${HOME}/Code/My-Project/bin"
  run_asimov
  refute_excluded "${HOME}/Code/My-Project/bin"
  [[ "$(count_exclusions)" -eq 0 ]]
}

# =============================================================================
# Multi-match and deduplication
# =============================================================================

@test "finds multiple matches in a single run" {
  create_project "Code/First-Project" "composer.json" "vendor"
  create_project "Code/Second-Project" "composer.json" "vendor"
  run_asimov
  assert_excluded "${HOME}/Code/First-Project/vendor"
  assert_excluded "${HOME}/Code/Second-Project/vendor"
  [[ "$(count_exclusions)" -eq 2 ]]
}

@test "finds multiple different dependency types in a single run" {
  create_project "Code/Node-Project" "package.json" "node_modules"
  create_project "Code/Rust-Project" "Cargo.toml" "target"
  create_project "Code/Python-Project" "requirements.txt" ".venv"
  run_asimov
  assert_excluded "${HOME}/Code/Node-Project/node_modules"
  assert_excluded "${HOME}/Code/Rust-Project/target"
  assert_excluded "${HOME}/Code/Python-Project/.venv"
  [[ "$(count_exclusions)" -eq 3 ]]
}

@test "excludes same directory when multiple sentinels match" {
  # A project with both build.gradle and build.gradle.kts should still
  # only exclude .gradle once (deduplication by find -prune).
  create_project "Code/My-Project" "build.gradle" ".gradle"
  echo "sentinel" > "${HOME}/Code/My-Project/build.gradle.kts"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/.gradle"
}

# =============================================================================
# Idempotency
# =============================================================================

@test "does not re-exclude already excluded paths" {
  create_project "Code/My-Project" "composer.json" "vendor"
  run_asimov

  local first_count
  first_count="$(count_exclusions)"
  [[ "$first_count" -eq 1 ]]

  run_asimov

  local second_count
  second_count="$(count_exclusions)"
  [[ "$second_count" -eq 1 ]]
}

# =============================================================================
# Skip paths
# =============================================================================

@test "does not check paths inside .Trash" {
  mkdir -p "${HOME}/.Trash/My-Project/vendor"
  echo "sentinel" > "${HOME}/.Trash/My-Project/composer.json"
  run_asimov
  [[ "$(count_exclusions)" -eq 0 ]]
}

@test "does not check paths inside ~/Library" {
  mkdir -p "${HOME}/Library/My-Project/node_modules"
  echo "sentinel" > "${HOME}/Library/My-Project/package.json"
  run_asimov
  [[ "$(count_exclusions)" -eq 0 ]]
}

# =============================================================================
# Nested project handling
# =============================================================================

@test "excludes dependency directory in nested project structure" {
  create_project "Code/Parent/Child" "package.json" "node_modules"
  run_asimov
  assert_excluded "${HOME}/Code/Parent/Child/node_modules"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "excludes directory when project path contains spaces" {
  create_project "Code/My Project" "package.json" "node_modules"
  run_asimov
  assert_excluded "${HOME}/Code/My Project/node_modules"
  [[ "$(count_exclusions)" -eq 1 ]]
}

# =============================================================================
# ASIMOV_ROOT detection
# =============================================================================
# When not root, ASIMOV_ROOT equals HOME (verified below). When running as root
# (e.g. launchd/sudo), ASIMOV_ROOT is the console user's home — that path is
# tested manually or via integration; full simulation would require mocked stat/dscl.

@test "uses HOME as root directory when not running as root" {
  create_project "Code/My-Project" "package.json" "node_modules"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/node_modules"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "exits with error when root directory does not exist" {
  run env HOME=/nonexistent-asimov-root "${BATS_TEST_DIRNAME}/../asimov"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"root directory"* ]]
  [[ "$output" == *"does not exist"* ]]
}

@test "does not descend into excluded dependency directories" {
  # A node_modules inside another node_modules should not be separately excluded
  create_project "Code/My-Project" "package.json" "node_modules"
  mkdir -p "${HOME}/Code/My-Project/node_modules/dep/node_modules"
  echo "sentinel" > "${HOME}/Code/My-Project/node_modules/dep/package.json"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/node_modules"
  refute_excluded "${HOME}/Code/My-Project/node_modules/dep/node_modules"
  [[ "$(count_exclusions)" -eq 1 ]]
}

# =============================================================================
# Skip already-excluded directories (mdfind optimization)
# =============================================================================

@test "skips directories already excluded from Time Machine" {
  create_project "Code/Already-Excluded" "package.json" "node_modules"
  create_project "Code/New-Project" "package.json" "node_modules"

  # Pre-exclude the first project manually
  echo "${HOME}/Code/Already-Excluded/node_modules" > "$ASIMOV_TEST_EXCLUSIONS"

  # Tell mock mdfind to report it as already excluded
  ASIMOV_TEST_MDFIND_RESULTS="${TEST_TEMP_DIR}/.mdfind_results"
  export ASIMOV_TEST_MDFIND_RESULTS
  echo "${HOME}/Code/Already-Excluded" > "$ASIMOV_TEST_MDFIND_RESULTS"

  run_asimov

  # The new project should be excluded
  assert_excluded "${HOME}/Code/New-Project/node_modules"
  # The already-excluded one should still only have 1 entry (not duplicated)
  [[ "$(count_exclusions)" -eq 2 ]]
}

# =============================================================================
# Fixed directories (global caches)
# =============================================================================

@test "does not exclude fixed directories by default (no config)" {
  mkdir -p "${HOME}/.cache"
  run_asimov
  refute_excluded "${HOME}/.cache"
}

@test "excludes fixed directory when config enables them" {
  mkdir -p "${HOME}/.cache"
  write_config "[fixed_dirs]
enabled = true"
  run_asimov
  assert_excluded "${HOME}/.cache"
}

@test "does not fail when fixed directory does not exist" {
  write_config "[fixed_dirs]
enabled = true"
  run_asimov
  [[ "$status" -eq 0 ]]
  [[ "$(count_exclusions)" -eq 0 ]]
}

@test "excludes multiple fixed directories when config enables them" {
  mkdir -p "${HOME}/.cache"
  mkdir -p "${HOME}/.gradle/caches"
  mkdir -p "${HOME}/.npm/_cacache"
  write_config "[fixed_dirs]
enabled = true"
  run_asimov
  assert_excluded "${HOME}/.cache"
  assert_excluded "${HOME}/.gradle/caches"
  assert_excluded "${HOME}/.npm/_cacache"
  [[ "$(count_exclusions)" -eq 3 ]]
}

@test "does not re-exclude already excluded fixed directory" {
  mkdir -p "${HOME}/.cache"
  write_config "[fixed_dirs]
enabled = true"
  run_asimov
  assert_excluded "${HOME}/.cache"
  local first_count
  first_count="$(count_exclusions)"
  [[ "$first_count" -eq 1 ]]

  run_asimov
  local second_count
  second_count="$(count_exclusions)"
  [[ "$second_count" -eq 1 ]]
}

# =============================================================================
# Config file
# =============================================================================

@test "config: missing config file is silently ignored" {
  run_asimov
  [[ "$status" -eq 0 ]]
}

@test "config: unknown section is silently ignored" {
  write_config "[unknown_section]
foo = bar"
  run_asimov
  [[ "$status" -eq 0 ]]
}

@test "config: unknown key is silently ignored" {
  write_config "[fixed_dirs]
unknown_key = value"
  run_asimov
  [[ "$status" -eq 0 ]]
}

@test "config: extra fixed dir is excluded" {
  mkdir -p "${HOME}/.custom-cache"
  write_config "[fixed_dirs]
extra = ~/.custom-cache"
  run_asimov
  assert_excluded "${HOME}/.custom-cache"
}

@test "config: extra fixed dir is excluded even when fixed_dirs disabled" {
  mkdir -p "${HOME}/.custom-cache"
  write_config "[fixed_dirs]
enabled = false
extra = ~/.custom-cache"
  run_asimov
  assert_excluded "${HOME}/.custom-cache"
}

@test "config: multiple extra fixed dirs" {
  mkdir -p "${HOME}/.cache-a"
  mkdir -p "${HOME}/.cache-b"
  write_config "[fixed_dirs]
extra = ~/.cache-a
extra = ~/.cache-b"
  run_asimov
  assert_excluded "${HOME}/.cache-a"
  assert_excluded "${HOME}/.cache-b"
}

@test "config: extra sentinel pair triggers exclusion" {
  create_project "Code/My-Project" "custom.config" ".custom-deps"
  write_config "[sentinels]
extra = .custom-deps custom.config"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/.custom-deps"
}

@test "config: disabled sentinel pair is skipped" {
  create_project "Code/My-Project" "package.json" "node_modules"
  write_config "[sentinels]
disabled = node_modules package.json"
  run_asimov
  refute_excluded "${HOME}/Code/My-Project/node_modules"
}

# =============================================================================
# Summary output
# =============================================================================

@test "prints summary with count when directories are excluded" {
  create_project "Code/Project-A" "package.json" "node_modules"
  create_project "Code/Project-B" "composer.json" "vendor"
  run_asimov
  [[ "$output" == *"Excluded 2 directories"* ]]
  [[ "$output" == *"totalling"* ]]
  [[ "$output" =~ totalling\ .*[KMG]\. ]]
}

@test "prints no-exclusion message when nothing to exclude" {
  run_asimov
  [[ "$output" == *"No new directories to exclude"* ]]
}

@test "prints no-exclusion message when all directories already excluded" {
  create_project "Code/My-Project" "package.json" "node_modules"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/node_modules"

  # Simulate mdfind reporting the already-excluded path (as real macOS would)
  ASIMOV_TEST_MDFIND_RESULTS="${TEST_TEMP_DIR}/.mdfind_results"
  export ASIMOV_TEST_MDFIND_RESULTS
  echo "${HOME}/Code/My-Project/node_modules" > "$ASIMOV_TEST_MDFIND_RESULTS"

  # Run again — everything is already excluded and pruned by mdfind
  run_asimov
  [[ "$output" == *"No new directories to exclude"* ]]
}

# =============================================================================
# Error handling
# =============================================================================

@test "continues when tmutil fails for a path" {
  create_project "Code/Good-Project" "package.json" "node_modules"
  create_project "Code/Bad-Project" "Cargo.toml" "target"

  # Mark the bad project as one that will cause tmutil to fail
  ASIMOV_TEST_TMUTIL_FAIL_PATHS="${TEST_TEMP_DIR}/.tmutil_fail_paths"
  export ASIMOV_TEST_TMUTIL_FAIL_PATHS
  echo "${HOME}/Code/Bad-Project/target" > "$ASIMOV_TEST_TMUTIL_FAIL_PATHS"

  run_asimov

  # The good project should still be excluded
  assert_excluded "${HOME}/Code/Good-Project/node_modules"
  # The bad project should NOT be in the exclusions list
  refute_excluded "${HOME}/Code/Bad-Project/target"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "prints warning when tmutil fails" {
  create_project "Code/Bad-Project" "package.json" "node_modules"

  ASIMOV_TEST_TMUTIL_FAIL_PATHS="${TEST_TEMP_DIR}/.tmutil_fail_paths"
  export ASIMOV_TEST_TMUTIL_FAIL_PATHS
  echo "${HOME}/Code/Bad-Project/node_modules" > "$ASIMOV_TEST_TMUTIL_FAIL_PATHS"

  run_asimov

  # Script should succeed (exit 0) even though tmutil failed
  [[ "$status" -eq 0 ]]
  # Output should contain the warning
  [[ "$output" == *"failed to exclude"* ]]
  [[ "$(count_exclusions)" -eq 0 ]]
}

# =============================================================================
# --help, --version, unknown option
# =============================================================================

@test "help option prints usage and exits 0" {
  run_asimov --help
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Usage:"* ]]
  [[ "$output" == *"asimov"* ]]
  [[ "$output" == *"--dry-run"* ]]
  [[ "$output" == *"--verbose"* ]]
  [[ "$output" == *"--quiet"* ]]
}

@test "version option prints version and exits 0" {
  expected_version="$(grep '^readonly ASIMOV_VERSION=' "${BATS_TEST_DIRNAME}/../asimov" | cut -d"'" -f2)"
  run_asimov --version
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"$expected_version"* ]]
}

@test "unknown option exits 1 and prints error" {
  run_asimov --unknown
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"unknown option"* ]]
  [[ "$output" == *"Usage:"* ]]
}

@test "scans a specified directory instead of home" {
  create_project "Code/My-Project" "package.json" "node_modules"
  mkdir -p "${HOME}/Other-Project"
  run_asimov "${HOME}/Code"
  assert_excluded "${HOME}/Code/My-Project/node_modules"
}

@test "exits with error for non-existent directory argument" {
  run_asimov /does/not/exist
  [[ "$status" -eq 1 ]]
  [[ "$output" =~ "not a directory" ]]
}

# =============================================================================
# --verbose
# =============================================================================

@test "default output hides already-excluded messages" {
  create_project "Code/My-Project" "package.json" "node_modules"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/node_modules"

  # Run again — directory is already excluded
  run_asimov
  [[ "$output" != *"already excluded"* ]]
}

@test "verbose shows already-excluded messages" {
  create_project "Code/My-Project" "package.json" "node_modules"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/node_modules"

  # Run again with --verbose
  run_asimov --verbose
  [[ "$output" == *"already excluded"* ]]
}

# =============================================================================
# --quiet
# =============================================================================

@test "quiet mode suppresses all non-error output" {
  create_project "Code/My-Project" "package.json" "node_modules"
  run_asimov --quiet
  [[ "$status" -eq 0 ]]
  [[ -z "$output" ]]
  assert_excluded "${HOME}/Code/My-Project/node_modules"
}

@test "quiet mode still shows errors on stderr" {
  create_project "Code/Bad-Project" "package.json" "node_modules"

  ASIMOV_TEST_TMUTIL_FAIL_PATHS="${TEST_TEMP_DIR}/.tmutil_fail_paths"
  export ASIMOV_TEST_TMUTIL_FAIL_PATHS
  echo "${HOME}/Code/Bad-Project/node_modules" > "$ASIMOV_TEST_TMUTIL_FAIL_PATHS"

  run_asimov --quiet
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"failed to exclude"* ]]
}

@test "quiet and verbose together exits with error" {
  run_asimov --quiet --verbose
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"mutually exclusive"* ]]
}

# =============================================================================
# Flag combinations
# =============================================================================

@test "dry-run with verbose shows would-exclude messages" {
  create_project "Code/My-Project" "package.json" "node_modules"
  run_asimov --dry-run --verbose
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Would exclude"* ]]
  [[ "$output" == *"node_modules"* ]]
}

@test "dry-run with quiet suppresses output" {
  create_project "Code/My-Project" "package.json" "node_modules"
  run_asimov --dry-run --quiet
  [[ "$status" -eq 0 ]]
  [[ -z "$output" ]]
}

# =============================================================================
# --dry-run
# =============================================================================

@test "dry-run prints would-exclude but does not call tmutil" {
  create_project "Code/My-Project" "package.json" "node_modules"
  run_asimov --dry-run
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Would exclude"* ]]
  [[ "$output" == *"node_modules"* ]]
  # Summary line must show would-exclude and a size (K, M, or G)
  [[ "$output" == *"Would exclude"*"directories"* ]]
  [[ "$output" == *"totalling"* ]]
  [[ "$output" =~ totalling\ [0-9]+[KMG]\. ]]
  # Mock tmutil should not have recorded any exclusion
  [[ "$(count_exclusions)" -eq 0 ]]
}
