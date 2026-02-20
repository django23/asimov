# Design: Asimov Config File

**Date:** 2026-02-20
**Branch:** improvements
**Status:** Approved

## Overview

Add an optional per-user config file at `~/.config/asimov/config` that lets users control:

1. Whether to enable unconditional global-cache exclusions (`[fixed_dirs] enabled`)
2. Additional user-defined fixed dirs (`[fixed_dirs] extra`)
3. Additional user-defined sentinel pairs (`[sentinels] extra`)
4. Built-in sentinel pairs to disable (`[sentinels] disabled`)

**Default behavior with no config file:** fixed dirs are **off**. This restores the original
conservative sentinel-based ethos — nothing is excluded without a matching sentinel file.

---

## Config File

**Location:** `~/.config/asimov/config`
**Format:** INI-style — `[section]` headers, `key = value` pairs, `#` line comments.
Repeated keys within a section define a list. Asimov never writes this file.

```ini
# ~/.config/asimov/config

[fixed_dirs]
# Set to true to exclude global tool caches unconditionally (no sentinel required).
# Default: false (opt-in, preserving the conservative sentinel-based ethos).
enabled = false

# Additional paths to always exclude (no sentinel required).
# Repeat this key to add multiple paths. Tilde expansion is applied.
# extra = ~/.my-tool-cache
# extra = ~/.another-cache

[sentinels]
# Additional dir/sentinel pairs beyond the built-in list.
# Format: extra = <dirname> <sentinel>   (same syntax as built-in pairs)
# extra = .build build.zig
# extra = .cache myconfig.yaml

# Built-in sentinel pairs to skip.
# Format: disabled = <dirname> <sentinel>  (must match the built-in entry exactly)
# disabled = node_modules package.json
# disabled = vendor Gemfile
```

---

## Architecture

### New function: `load_config()`

Added near the top of `asimov`, called once after `ASIMOV_ROOT` is resolved.
Reads `~/.config/asimov/config` with `awk`. If the file doesn't exist, all defaults apply silently.

Populates four new variables:

| Variable | Type | Default |
|---|---|---|
| `ASIMOV_CONFIG_FIXED_DIRS_ENABLED` | string (`true`/`false`) | `false` |
| `ASIMOV_CONFIG_EXTRA_FIXED_DIRS` | bash array | `()` |
| `ASIMOV_CONFIG_EXTRA_SENTINELS` | bash array | `()` |
| `ASIMOV_CONFIG_DISABLED_SENTINELS` | bash array | `()` |

### Modified: `build_find_vendor_params()`

- Skips any built-in `ASIMOV_VENDOR_DIR_SENTINELS` pair that appears verbatim in `ASIMOV_CONFIG_DISABLED_SENTINELS`.
- Appends `ASIMOV_CONFIG_EXTRA_SENTINELS` entries after the built-in pairs.

### Modified: fixed-dirs loop (main section)

- Guarded by `ASIMOV_CONFIG_FIXED_DIRS_ENABLED == true`.
- When enabled, also iterates `ASIMOV_CONFIG_EXTRA_FIXED_DIRS` (in addition to `ASIMOV_FIXED_DIRS`).
- When disabled, `ASIMOV_CONFIG_EXTRA_FIXED_DIRS` entries are still processed — a user who
  explicitly adds a path always wants it excluded.

---

## Error Handling

| Situation | Behaviour |
|---|---|
| Config file not found | Silent — all defaults apply |
| Unknown `[section]` or `key` | Silently ignored |
| Malformed line (no `=`) | Silently ignored by awk |
| `extra` path doesn't exist | Skipped by existing `[[ -d ]]` guard |
| `disabled` entry matches no built-in | Silently ignored (safe) |
| Tilde in `extra` path | Expanded via `eval` (tilde-only prefix, not arbitrary code) |

---

## Tests

New tests in `tests/behavior.bats`:

| Test name | What it checks |
|---|---|
| `config: fixed dirs disabled by default (no config)` | No config → `~/.cache` not excluded |
| `config: fixed dirs enabled when config says enabled=true` | `enabled=true` → `~/.cache` excluded |
| `config: extra fixed dir is excluded` | User `extra = ~/.custom` → excluded when it exists |
| `config: extra sentinel pair is used` | User `extra = .build build.zig` → triggers exclusion |
| `config: disabled sentinel pair is skipped` | `disabled = node_modules package.json` → not excluded |
| `config: multiple extras work (two extra = lines)` | Two `extra =` lines → both applied |
| `config: missing config file is silently ignored` | No config file, asimov exits 0 |
| `config: unknown key in config is silently ignored` | Malformed config → no crash |

`tests/test_helper.bash` gains a `write_config()` helper that writes
`$HOME/.config/asimov/config` in the test temp dir.
