#!/usr/bin/env bats
#
# Cache tests: path cache creation, cached runs, incremental discovery, flags.

load test_helper

# =============================================================================
# First run — cache creation
# =============================================================================

@test "first run creates cache file" {
  create_project "Code/My-Project" "package.json" "node_modules"
  run_asimov
  [[ "$status" -eq 0 ]]
  assert_excluded "${HOME}/Code/My-Project/node_modules"
  [[ -f "${HOME}/.cache/asimov/paths" ]]
  assert_cached "${HOME}/Code/My-Project/node_modules"
}

@test "first run with no matches creates cache with only header" {
  run_asimov
  [[ "$status" -eq 0 ]]
  [[ -f "${HOME}/.cache/asimov/paths" ]]
  # Cache should exist but contain no paths (just the header comment)
  local path_count
  path_count="$(read_path_cache | wc -l | tr -d ' ')"
  [[ "$path_count" -eq 0 ]]
}

# =============================================================================
# Cached run — uses cache, skips find
# =============================================================================

@test "cached run uses cache and excludes paths" {
  create_project "Code/My-Project" "package.json" "node_modules"
  # First run: full scan, creates cache
  run_asimov
  [[ "$status" -eq 0 ]]
  assert_excluded "${HOME}/Code/My-Project/node_modules"
  assert_cached "${HOME}/Code/My-Project/node_modules"

  # Second run: should use cache (output says "Using cached paths")
  run_asimov
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Using cached paths"* ]]
}

@test "stale paths are removed from cache" {
  create_project "Code/My-Project" "package.json" "node_modules"
  create_project "Code/Stale-Project" "Cargo.toml" "target"

  # First run: both projects get cached
  run_asimov
  assert_cached "${HOME}/Code/My-Project/node_modules"
  assert_cached "${HOME}/Code/Stale-Project/target"

  # Remove the stale project directory
  rm -rf "${HOME}/Code/Stale-Project"

  # Second run: stale path should be removed from cache
  run_asimov
  assert_cached "${HOME}/Code/My-Project/node_modules"
  refute_cached "${HOME}/Code/Stale-Project/target"
}

# =============================================================================
# Incremental discovery via mdfind
# =============================================================================

@test "incremental discovery finds new projects via mdfind" {
  create_project "Code/Existing-Project" "package.json" "node_modules"

  # First run: creates cache with existing project
  run_asimov
  assert_excluded "${HOME}/Code/Existing-Project/node_modules"
  assert_cached "${HOME}/Code/Existing-Project/node_modules"

  # Create a new project that wasn't there during the first scan
  create_project "Code/New-Project" "Cargo.toml" "target"

  # Set up mdfind to report the new project's directory
  ASIMOV_TEST_MDFIND_SENTINEL_RESULTS="${TEST_TEMP_DIR}/.mdfind_sentinel_results"
  export ASIMOV_TEST_MDFIND_SENTINEL_RESULTS
  echo "${HOME}/Code/New-Project/target" > "$ASIMOV_TEST_MDFIND_SENTINEL_RESULTS"

  # Second run: should discover the new project via mdfind
  run_asimov
  [[ "$status" -eq 0 ]]
  assert_excluded "${HOME}/Code/New-Project/target"
  assert_cached "${HOME}/Code/New-Project/target"
}

@test "mdfind candidate without sentinel is not cached" {
  create_project "Code/Existing-Project" "package.json" "node_modules"

  # First run: creates cache
  run_asimov
  assert_cached "${HOME}/Code/Existing-Project/node_modules"

  # Create a directory with no sentinel (false positive from mdfind)
  mkdir -p "${HOME}/Code/No-Sentinel/target"

  ASIMOV_TEST_MDFIND_SENTINEL_RESULTS="${TEST_TEMP_DIR}/.mdfind_sentinel_results"
  export ASIMOV_TEST_MDFIND_SENTINEL_RESULTS
  echo "${HOME}/Code/No-Sentinel/target" > "$ASIMOV_TEST_MDFIND_SENTINEL_RESULTS"

  # Second run: target without sentinel should not be cached or excluded
  run_asimov
  refute_excluded "${HOME}/Code/No-Sentinel/target"
  refute_cached "${HOME}/Code/No-Sentinel/target"
}

# =============================================================================
# Nested path deduplication
# =============================================================================

@test "nested paths in cache are deduped (only outermost excluded)" {
  create_project "Code/My-Project" "package.json" "node_modules"

  # Manually seed the cache with a nested node_modules (as mdfind might discover)
  write_path_cache \
    "${HOME}/Code/My-Project/node_modules" \
    "${HOME}/Code/My-Project/node_modules/dep/node_modules"
  # Create the nested directory so it passes the "exists" check
  mkdir -p "${HOME}/Code/My-Project/node_modules/dep/node_modules"
  echo "sentinel" > "${HOME}/Code/My-Project/node_modules/dep/package.json"

  # Cached run: only the outermost should be excluded (TM exclusions are recursive)
  run_asimov
  [[ "$status" -eq 0 ]]
  assert_excluded "${HOME}/Code/My-Project/node_modules"
  refute_excluded "${HOME}/Code/My-Project/node_modules/dep/node_modules"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "finalize removes nested paths from cache file" {
  create_project "Code/My-Project" "package.json" "node_modules"

  # Seed cache with nested paths
  write_path_cache \
    "${HOME}/Code/My-Project/node_modules" \
    "${HOME}/Code/My-Project/node_modules/dep/node_modules"
  mkdir -p "${HOME}/Code/My-Project/node_modules/dep/node_modules"
  echo "sentinel" > "${HOME}/Code/My-Project/node_modules/dep/package.json"

  run_asimov
  [[ "$status" -eq 0 ]]

  # After finalize, nested path should be removed from cache
  assert_cached "${HOME}/Code/My-Project/node_modules"
  refute_cached "${HOME}/Code/My-Project/node_modules/dep/node_modules"
}

# =============================================================================
# --full-scan
# =============================================================================

@test "--full-scan ignores cache and rebuilds it" {
  create_project "Code/My-Project" "package.json" "node_modules"

  # First run: creates cache
  run_asimov
  assert_cached "${HOME}/Code/My-Project/node_modules"

  # Add a new project
  create_project "Code/New-Project" "Cargo.toml" "target"

  # Run with --full-scan: should find the new project via find (not mdfind)
  run_asimov --full-scan
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Scanning for dependency"* ]]
  [[ "$output" != *"Using cached paths"* ]]
  assert_excluded "${HOME}/Code/New-Project/target"
  assert_cached "${HOME}/Code/New-Project/target"
}

# =============================================================================
# --no-cache
# =============================================================================

@test "--no-cache does full scan and does not write cache" {
  create_project "Code/My-Project" "package.json" "node_modules"
  run_asimov --no-cache
  [[ "$status" -eq 0 ]]
  assert_excluded "${HOME}/Code/My-Project/node_modules"
  [[ "$output" == *"Scanning for dependency"* ]]
  # Cache file should not exist
  [[ ! -f "${HOME}/.cache/asimov/paths" ]]
}

@test "--no-cache ignores existing cache" {
  create_project "Code/My-Project" "package.json" "node_modules"

  # First run: creates cache
  run_asimov
  assert_cached "${HOME}/Code/My-Project/node_modules"

  # Run with --no-cache: should do full scan, not use cache
  run_asimov --no-cache
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Scanning for dependency"* ]]
  [[ "$output" != *"Using cached paths"* ]]
}

# =============================================================================
# --dry-run with cache
# =============================================================================

@test "--dry-run reads cache but does not write it" {
  create_project "Code/My-Project" "package.json" "node_modules"

  # First run: creates cache (non-dry-run)
  run_asimov
  assert_cached "${HOME}/Code/My-Project/node_modules"
  local original_cache
  original_cache="$(cat "${HOME}/.cache/asimov/paths")"

  # Create a new project
  create_project "Code/New-Project" "Cargo.toml" "target"

  ASIMOV_TEST_MDFIND_SENTINEL_RESULTS="${TEST_TEMP_DIR}/.mdfind_sentinel_results"
  export ASIMOV_TEST_MDFIND_SENTINEL_RESULTS
  echo "${HOME}/Code/New-Project/target" > "$ASIMOV_TEST_MDFIND_SENTINEL_RESULTS"

  # Dry run: should read cache but not update it
  run_asimov --dry-run
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Using cached paths"* ]]
  # Cache should not have been updated (new project not added)
  refute_cached "${HOME}/Code/New-Project/target"
}

@test "--dry-run without cache does full scan and does not create cache" {
  create_project "Code/My-Project" "package.json" "node_modules"
  run_asimov --dry-run
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Would exclude"* ]]
  # Cache file should not exist
  [[ ! -f "${HOME}/.cache/asimov/paths" ]]
}

# =============================================================================
# Mutual exclusivity
# =============================================================================

@test "--full-scan and --no-cache together exits with error" {
  run_asimov --full-scan --no-cache
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"mutually exclusive"* ]]
}

# =============================================================================
# Scoped runs
# =============================================================================

@test "cached run with directory argument filters to scoped paths" {
  create_project "Code/My-Project" "package.json" "node_modules"
  create_project "Other/My-Project" "Cargo.toml" "target"

  # First run: full scan, caches both
  run_asimov
  assert_cached "${HOME}/Code/My-Project/node_modules"
  assert_cached "${HOME}/Other/My-Project/target"

  # Second run scoped to Code/: should only process Code/ paths from cache
  run_asimov "${HOME}/Code"
  [[ "$status" -eq 0 ]]
  [[ "$output" == *"Using cached paths"* ]]
}
