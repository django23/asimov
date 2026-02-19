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

@test "excludes fixed directory when it exists" {
  mkdir -p "${HOME}/.cache"
  run_asimov
  assert_excluded "${HOME}/.cache"
}

@test "does not fail when fixed directory does not exist" {
  # Don't create any fixed dirs — asimov should still succeed
  run_asimov
  [[ "$status" -eq 0 ]]
  [[ "$(count_exclusions)" -eq 0 ]]
}

@test "excludes multiple fixed directories when they exist" {
  mkdir -p "${HOME}/.cache"
  mkdir -p "${HOME}/.gradle/caches"
  mkdir -p "${HOME}/.npm/_cacache"
  run_asimov
  assert_excluded "${HOME}/.cache"
  assert_excluded "${HOME}/.gradle/caches"
  assert_excluded "${HOME}/.npm/_cacache"
  [[ "$(count_exclusions)" -eq 3 ]]
}

@test "does not re-exclude already excluded fixed directory" {
  mkdir -p "${HOME}/.cache"
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
