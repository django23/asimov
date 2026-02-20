# Config File Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add an optional `~/.config/asimov/config` INI file so users can control fixed-dir exclusions, add extra paths, add extra sentinel pairs, and disable built-in pairs.

**Architecture:** A `load_config()` function reads the INI file with pure bash (no external parser) into four internal variables. The fixed-dirs loop is gated behind `ASIMOV_CONFIG_FIXED_DIRS_ENABLED` (default `false`). `build_find_vendor_params()` skips disabled pairs and appends extra sentinel pairs. User-defined `extra` fixed dirs are always processed regardless of the `enabled` flag.

**Tech Stack:** bash 3.2+, Bats test framework (`make test`), ShellCheck (`make lint`)

---

### Task 1: Add `write_config()` test helper and update existing fixed-dirs tests

**Files:**
- Modify: `tests/test_helper.bash`
- Modify: `tests/behavior.bats` (existing fixed-dirs tests only)

**Context:**
The existing tests "excludes fixed directory when it exists", "excludes multiple fixed directories when they exist", and "does not re-exclude already excluded fixed directory" will break when the default for fixed dirs changes to `false`. Update them now to add an `enabled = true` config before running asimov.

**Step 1: Add `write_config()` to `tests/test_helper.bash`**

Append after the last function (after `refute_excluded`, line 67):

```bash
# Write a config file into the test home directory.
#
# Usage: write_config <content>
#
# Example:
#   write_config "[fixed_dirs]
# enabled = true"
write_config() {
  local config_dir="${HOME}/.config/asimov"
  mkdir -p "$config_dir"
  printf '%s\n' "$1" > "${config_dir}/config"
}
```

**Step 2: Update three existing fixed-dirs tests in `tests/behavior.bats`**

In "excludes fixed directory when it exists" — add `write_config` call before `run_asimov`:
```bash
@test "excludes fixed directory when it exists" {
  mkdir -p "${HOME}/.cache"
  write_config "[fixed_dirs]
enabled = true"
  run_asimov
  assert_excluded "${HOME}/.cache"
}
```

In "excludes multiple fixed directories when they exist" — same pattern:
```bash
@test "excludes multiple fixed directories when they exist" {
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
```

In "does not re-exclude already excluded fixed directory" — same pattern:
```bash
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
```

**Step 3: Run all tests — they should still pass (asimov unchanged so far)**

```bash
make test
```

Expected: all tests pass (fixed-dirs tests still pass because asimov still processes ASIMOV_FIXED_DIRS unconditionally at this point).

**Step 4: Commit**

```bash
git add tests/test_helper.bash tests/behavior.bats
git commit -m "test(config): add write_config helper and update fixed-dirs tests for opt-in default"
```

---

### Task 2: Write failing tests for `load_config()` defaults

**Files:**
- Modify: `tests/behavior.bats`

**Step 1: Append these two tests at the end of the `# Fixed directories` section in `tests/behavior.bats`**

```bash
# =============================================================================
# Config file
# =============================================================================

@test "config: missing config file is silently ignored" {
  # No config file exists. asimov should run without error and without
  # excluding fixed dirs.
  mkdir -p "${HOME}/.cache"
  run_asimov
  [[ "$status" -eq 0 ]]
  refute_excluded "${HOME}/.cache"
}

@test "config: unknown keys and sections are silently ignored" {
  write_config "[unknown_section]
unknown_key = some_value"
  run_asimov
  [[ "$status" -eq 0 ]]
  [[ "$(count_exclusions)" -eq 0 ]]
}
```

**Step 2: Run these two tests to confirm they fail**

```bash
make test 2>&1 | grep -A3 "config:"
```

Expected: "missing config file" FAILS because `~/.cache` IS excluded by the current code (ASIMOV_FIXED_DIRS is unconditional). "unknown keys" passes because asimov ignores config files it doesn't understand.

**Step 3: Commit the failing tests**

```bash
git add tests/behavior.bats
git commit -m "test(config): add failing tests for config defaults"
```

---

### Task 3: Implement `load_config()` and gate fixed-dirs behind it

**Files:**
- Modify: `asimov`

**Step 1: Add `load_config()` to `asimov` after `ASIMOV_FIXED_DIRS` (after line 175)**

Insert before `record_excluded_path()`:

```bash
# Load user configuration from ${ASIMOV_ROOT}/.config/asimov/config.
# File format: INI-style with [section] headers and key = value pairs.
# Silently ignored if the file does not exist or contains unknown keys.
# Sets four global variables used throughout the script.
load_config() {
    local config_file="${ASIMOV_ROOT}/.config/asimov/config"
    ASIMOV_CONFIG_FIXED_DIRS_ENABLED=false
    ASIMOV_CONFIG_EXTRA_FIXED_DIRS=()
    ASIMOV_CONFIG_EXTRA_SENTINELS=()
    ASIMOV_CONFIG_DISABLED_SENTINELS=()

    [[ -f "$config_file" ]] || return 0

    local section='' line key val leading
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Strip inline comments, then trim surrounding whitespace
        line="${line%%#*}"
        leading="${line%%[![:space:]]*}"
        line="${line#"$leading"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" ]] && continue

        # Section header: [section_name]
        if [[ "$line" =~ ^\[([a-zA-Z_]+)\]$ ]]; then
            section="${BASH_REMATCH[1]}"
            continue
        fi

        # key = value
        if [[ "$line" =~ ^([a-zA-Z_]+)[[:space:]]*=[[:space:]]*(.*) ]]; then
            key="${BASH_REMATCH[1]}"
            val="${BASH_REMATCH[2]}"
            val="${val%"${val##*[![:space:]]}"}"
            # Expand leading tilde
            [[ "$val" == '~'* ]] && val="${ASIMOV_ROOT}${val:1}"

            case "${section}/${key}" in
                fixed_dirs/enabled)   ASIMOV_CONFIG_FIXED_DIRS_ENABLED="$val" ;;
                fixed_dirs/extra)     ASIMOV_CONFIG_EXTRA_FIXED_DIRS+=("$val") ;;
                sentinels/extra)      ASIMOV_CONFIG_EXTRA_SENTINELS+=("$val")  ;;
                sentinels/disabled)   ASIMOV_CONFIG_DISABLED_SENTINELS+=("$val") ;;
            esac
        fi
    done < "$config_file"
}
```

**Step 2: Call `load_config()` in the main section**

In the main execution block (around line 293–298), after the `ASIMOV_ROOT` validation, add the call:

```bash
if [[ ! -d "$ASIMOV_ROOT" ]]; then
    echo "asimov: root directory does not exist or is not a directory: $ASIMOV_ROOT" >&2
    exit 1
fi

load_config

build_find_skip_params
build_find_vendor_params
```

**Step 3: Gate the fixed-dirs loop behind `ASIMOV_CONFIG_FIXED_DIRS_ENABLED`**

Replace the existing fixed-dirs section (lines 309–314):

```bash
printf '\n%sExcluding known cache directories…%s\n' "$ASIMOV_COLOR_INFO" "$ASIMOV_COLOR_RESET"
for fixed_dir in "${ASIMOV_FIXED_DIRS[@]}"; do
    if [[ -d "$fixed_dir" ]]; then
        echo "$fixed_dir"
    fi
done | exclude_paths_from_stdin
```

With:

```bash
printf '\n%sExcluding known cache directories…%s\n' "$ASIMOV_COLOR_INFO" "$ASIMOV_COLOR_RESET"
{
    if [[ "$ASIMOV_CONFIG_FIXED_DIRS_ENABLED" == true ]]; then
        for fixed_dir in "${ASIMOV_FIXED_DIRS[@]}"; do
            [[ -d "$fixed_dir" ]] && echo "$fixed_dir"
        done
    fi
    for extra_dir in "${ASIMOV_CONFIG_EXTRA_FIXED_DIRS[@]+"${ASIMOV_CONFIG_EXTRA_FIXED_DIRS[@]}"}"; do
        [[ -d "$extra_dir" ]] && echo "$extra_dir"
    done
} | exclude_paths_from_stdin
```

**Step 4: Run ShellCheck**

```bash
make lint
```

Expected: no errors.

**Step 5: Run all tests**

```bash
make test
```

Expected: all tests pass, including the two new config tests.

**Step 6: Commit**

```bash
git add asimov
git commit -m "feat(config): add load_config() and gate fixed dirs behind enabled flag"
```

---

### Task 4: Write and pass tests for fixed-dirs toggle and extra fixed dirs

**Files:**
- Modify: `tests/behavior.bats`

**Step 1: Append these tests under the `# Config file` section**

```bash
@test "config: fixed dirs are excluded when enabled=true" {
  mkdir -p "${HOME}/.cache"
  write_config "[fixed_dirs]
enabled = true"
  run_asimov
  assert_excluded "${HOME}/.cache"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "config: extra fixed dir is excluded regardless of enabled flag" {
  mkdir -p "${HOME}/.my-tool-cache"
  write_config "[fixed_dirs]
extra = ~/.my-tool-cache"
  run_asimov
  assert_excluded "${HOME}/.my-tool-cache"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "config: multiple extra fixed dirs are all excluded" {
  mkdir -p "${HOME}/.cache-a"
  mkdir -p "${HOME}/.cache-b"
  write_config "[fixed_dirs]
extra = ~/.cache-a
extra = ~/.cache-b"
  run_asimov
  assert_excluded "${HOME}/.cache-a"
  assert_excluded "${HOME}/.cache-b"
  [[ "$(count_exclusions)" -eq 2 ]]
}

@test "config: extra fixed dir is not excluded when it does not exist" {
  # Extra path that doesn't exist — asimov should still exit 0
  write_config "[fixed_dirs]
extra = ~/.nonexistent-cache"
  run_asimov
  [[ "$status" -eq 0 ]]
  [[ "$(count_exclusions)" -eq 0 ]]
}
```

**Step 2: Run the new tests**

```bash
bats tests/behavior.bats --filter "config:"
```

Expected: all four new tests pass (the implementation in Task 3 already covers these).

**Step 3: Run full test suite**

```bash
make test
```

Expected: all tests pass.

**Step 4: Commit**

```bash
git add tests/behavior.bats
git commit -m "test(config): add tests for fixed dirs toggle and extra fixed dirs"
```

---

### Task 5: Write failing tests for extra sentinel pairs

**Files:**
- Modify: `tests/behavior.bats`

**Step 1: Append these tests under the `# Config file` section**

```bash
@test "config: extra sentinel pair triggers exclusion" {
  create_project "Code/My-Project" "my-config.yaml" ".my-cache"
  write_config "[sentinels]
extra = .my-cache my-config.yaml"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/.my-cache"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "config: extra sentinel pair requires sentinel to be present" {
  mkdir -p "${HOME}/Code/My-Project/.my-cache"
  # No my-config.yaml sentinel — should NOT be excluded
  write_config "[sentinels]
extra = .my-cache my-config.yaml"
  run_asimov
  refute_excluded "${HOME}/Code/My-Project/.my-cache"
  [[ "$(count_exclusions)" -eq 0 ]]
}
```

**Step 2: Run to confirm they fail**

```bash
bats tests/behavior.bats --filter "config: extra sentinel"
```

Expected: both FAIL — extra sentinel pairs are not yet implemented.

**Step 3: Commit failing tests**

```bash
git add tests/behavior.bats
git commit -m "test(config): add failing tests for extra sentinel pairs"
```

---

### Task 6: Implement extra sentinel pairs in `build_find_vendor_params()`

**Files:**
- Modify: `asimov`

**Step 1: Update `build_find_vendor_params()` to also iterate `ASIMOV_CONFIG_EXTRA_SENTINELS`**

The current function iterates `ASIMOV_VENDOR_DIR_SENTINELS`. Replace the `for` loop header to combine both arrays:

```bash
build_find_vendor_params() {
    find_parameters_vendor=()
    local pair parts dir_name sentinel_name sentinel_check

    # Build the combined list: built-in pairs first, then user-defined extras.
    local -a all_sentinels=("${ASIMOV_VENDOR_DIR_SENTINELS[@]}")
    for pair in "${ASIMOV_CONFIG_EXTRA_SENTINELS[@]+"${ASIMOV_CONFIG_EXTRA_SENTINELS[@]}"}"; do
        all_sentinels+=("$pair")
    done

    for pair in "${all_sentinels[@]}"; do
        read -ra parts <<< "${pair}"
        dir_name="${parts[0]}"
        sentinel_name="${parts[1]}"

        if [[ "$sentinel_name" == *'*'* ]]; then
            sentinel_check=( -execdir sh -c 'ls -d '"${sentinel_name}"' >/dev/null 2>&1' \; )
        else
            sentinel_check=( -execdir test -e "${sentinel_name}" \; )
        fi

        find_parameters_vendor+=( -or \( \
            -type d \
            -name "${dir_name}" \
            "${sentinel_check[@]}" \
            -prune \
            -print \
        \) )
    done
}
```

**Step 2: Run ShellCheck**

```bash
make lint
```

Expected: no errors.

**Step 3: Run the extra sentinel tests**

```bash
bats tests/behavior.bats --filter "config: extra sentinel"
```

Expected: both tests pass.

**Step 4: Run full test suite**

```bash
make test
```

Expected: all tests pass.

**Step 5: Commit**

```bash
git add asimov
git commit -m "feat(config): support extra sentinel pairs via config file"
```

---

### Task 7: Write failing tests for disabled sentinel pairs

**Files:**
- Modify: `tests/behavior.bats`

**Step 1: Append these tests under the `# Config file` section**

```bash
@test "config: disabled sentinel pair is not excluded" {
  create_project "Code/My-Project" "package.json" "node_modules"
  write_config "[sentinels]
disabled = node_modules package.json"
  run_asimov
  refute_excluded "${HOME}/Code/My-Project/node_modules"
  [[ "$(count_exclusions)" -eq 0 ]]
}

@test "config: disabled pair does not affect other sentinel pairs" {
  create_project "Code/Node-Project" "package.json" "node_modules"
  create_project "Code/Rust-Project" "Cargo.toml" "target"
  write_config "[sentinels]
disabled = node_modules package.json"
  run_asimov
  refute_excluded "${HOME}/Code/Node-Project/node_modules"
  assert_excluded "${HOME}/Code/Rust-Project/target"
  [[ "$(count_exclusions)" -eq 1 ]]
}
```

**Step 2: Run to confirm they fail**

```bash
bats tests/behavior.bats --filter "config: disabled"
```

Expected: both FAIL — disabled sentinels not yet implemented.

**Step 3: Commit failing tests**

```bash
git add tests/behavior.bats
git commit -m "test(config): add failing tests for disabled sentinel pairs"
```

---

### Task 8: Implement disabled sentinel pairs in `build_find_vendor_params()`

**Files:**
- Modify: `asimov`

**Step 1: Add the disabled-pair check inside `build_find_vendor_params()`**

Inside the `for pair in "${all_sentinels[@]}"` loop, add a skip check before processing each pair:

```bash
    for pair in "${all_sentinels[@]}"; do
        # Skip pairs the user has explicitly disabled in their config.
        local is_disabled=false
        local dis
        for dis in "${ASIMOV_CONFIG_DISABLED_SENTINELS[@]+"${ASIMOV_CONFIG_DISABLED_SENTINELS[@]}"}"; do
            if [[ "$pair" == "$dis" ]]; then
                is_disabled=true
                break
            fi
        done
        [[ "$is_disabled" == true ]] && continue

        read -ra parts <<< "${pair}"
        # ... rest of loop unchanged
```

**Step 2: Run ShellCheck**

```bash
make lint
```

Expected: no errors.

**Step 3: Run the disabled tests**

```bash
bats tests/behavior.bats --filter "config: disabled"
```

Expected: both tests pass.

**Step 4: Run full test suite**

```bash
make test
```

Expected: all tests pass.

**Step 5: Commit**

```bash
git add asimov
git commit -m "feat(config): support disabling built-in sentinel pairs via config file"
```

---

### Task 9: Update CHANGELOG

**Files:**
- Modify: `CHANGELOG.md`

**Step 1: Add entries under `[Unreleased]` → `Added`**

```markdown
## [Unreleased]

### Added

* Optional config file at `~/.config/asimov/config` (INI-style) for per-user preferences
* `[fixed_dirs] enabled = true/false` — opt-in to unconditional global-cache exclusions (default: `false`)
* `[fixed_dirs] extra = <path>` — user-defined paths to always exclude; repeatable
* `[sentinels] extra = <dir> <sentinel>` — user-defined sentinel pairs beyond the built-in list; repeatable
* `[sentinels] disabled = <dir> <sentinel>` — disable specific built-in sentinel pairs; repeatable

### Changed

* Fixed directory exclusions (`~/.cache`, `~/.gradle/caches`, etc.) are now **opt-in** via `[fixed_dirs] enabled = true` in the config file, preserving Asimov's conservative sentinel-based ethos by default
```

**Step 2: Run full test suite one final time**

```bash
make check
```

Expected: all tests and lint pass with zero errors.

**Step 3: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: update CHANGELOG for config file feature"
```
