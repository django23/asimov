#!/usr/bin/env bash
#
# Bats test helper for the Asimov test suite.

# Set up a clean, isolated environment for each test.
setup() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export HOME="$TEST_TEMP_DIR"
  export PATH="${BATS_TEST_DIRNAME}/bin:$PATH"

  ASIMOV_TEST_EXCLUSIONS="${TEST_TEMP_DIR}/.exclusions"
  export ASIMOV_TEST_EXCLUSIONS
  touch "$ASIMOV_TEST_EXCLUSIONS"
}

# Clean up the temporary directory after each test.
teardown() {
  rm -rf "$TEST_TEMP_DIR"
}

# Create a project directory with a sentinel file and dependency directory.
#
# Usage: create_project <base_dir> <sentinel_file> <deps_dir>
#
# Example: create_project "Code/My-Project" "package.json" "node_modules"
create_project() {
  local base="$1"
  local sentinel="$2"
  local deps_dir="$3"

  mkdir -p "${HOME}/${base}/${deps_dir}"
  echo "sentinel" > "${HOME}/${base}/${sentinel}"
}

# Run the asimov script under test. Pass any arguments (e.g. --dry-run, --help).
run_asimov() {
  run "${BATS_TEST_DIRNAME}/../asimov" "$@"
}

# Return the number of exclusions recorded by the mock tmutil.
count_exclusions() {
  local count
  count="$(wc -l < "$ASIMOV_TEST_EXCLUSIONS" | tr -d ' ')"
  echo "$count"
}

# Assert that a path was excluded by the mock tmutil.
assert_excluded() {
  local path="$1"
  if ! grep -Fxq "$path" "$ASIMOV_TEST_EXCLUSIONS"; then
    echo "Expected '$path' to be excluded, but it was not." >&2
    echo "Exclusions:" >&2
    cat "$ASIMOV_TEST_EXCLUSIONS" >&2
    return 1
  fi
}

# Assert that a path was NOT excluded by the mock tmutil.
refute_excluded() {
  local path="$1"
  if grep -Fxq "$path" "$ASIMOV_TEST_EXCLUSIONS"; then
    echo "Expected '$path' to NOT be excluded, but it was." >&2
    echo "Exclusions:" >&2
    cat "$ASIMOV_TEST_EXCLUSIONS" >&2
    return 1
  fi
}
