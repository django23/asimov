# Contributing to Asimov

Thanks for your interest in contributing! Asimov is a small, focused project and contributions of all sizes are welcome.

## Getting started

**Prerequisites:** macOS with [Homebrew](https://brew.sh) installed.

```sh
git clone https://github.com/stevegrunwell/asimov.git
cd asimov
brew install bats-core shellcheck
```

Verify everything works:

```sh
make check
```

## Development workflow

| Command | What it does |
|---|---|
| `make help` | List available make targets with descriptions |
| `make test` | Run the [Bats](https://github.com/bats-core/bats-core) test suite |
| `make lint` | Run [ShellCheck](https://www.shellcheck.net/) on all shell scripts |
| `make check` | Run both tests and linting |
| `make version` | Print asimov version |
| `make exclusions` | List all paths excluded from Time Machine (requires sudo) |

To run a single test by name: `bats tests/behavior.bats --filter "substring of test name"` or `bats tests/sentinels.bats --filter "npm"`.

The main script supports `--help`, `--version`, and `--dry-run`; unknown options exit with an error.

## Adding a new dependency pattern

This is the most common type of contribution. To add a new ecosystem or dependency directory:

1. **Add the sentinel pair** to the `ASIMOV_VENDOR_DIR_SENTINELS` array in [`asimov`](asimov) — one `'directory sentinel'` entry per pattern.
2. **Add a test** in [`tests/sentinels.bats`](tests/sentinels.bats) using `create_project` to build the fixture. Keep this file in sync with `ASIMOV_VENDOR_DIR_SENTINELS` (one test per sentinel pair).
3. **Run `make check`** to verify your changes pass tests and linting.
4. **Add a changelog entry** under the `[Unreleased]` section in [`CHANGELOG.md`](CHANGELOG.md).

**Example sentinel entry:**

```bash
'.zig-cache build.zig'   # Zig build cache
```

This means: exclude `.zig-cache/` only when `build.zig` exists in the same directory.

## Commit conventions

This project uses [Conventional Commits](https://www.conventionalcommits.org/). Format your commits as:

```
type(scope): short description
```

**Types:** `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `build`, `ci`

**Examples:**

- `feat(sentinels): add Zig build cache exclusion`
- `fix: prevent duplicate exclusions on re-run`
- `test: add coverage for Go modules`
- `docs: update installation instructions`

## Pull requests

- Branch from `develop` (the default branch).
- Keep PRs focused — one feature or fix per PR.
- Ensure `make check` passes before submitting.
- Update `CHANGELOG.md` for user-facing changes.

## Code style

- Bash/shell: **2-space indentation**, LF line endings, UTF-8.
- Enforced via [EditorConfig](.editorconfig) — most editors pick this up automatically.

## Project structure

```
asimov                  # Main bash script
tests/
  sentinels.bats        # Tests for each dependency pattern
  behavior.bats         # Tests for edge cases and general behavior
  test_helper.bash      # Shared setup/teardown and assertions
  bin/tmutil            # Mock tmutil for testing
scripts/
  install.sh            # Installation script
  uninstall.sh          # Uninstallation script
Makefile                # Build targets (test, lint, check, install, uninstall)
```

## Questions?

Open an [issue](https://github.com/stevegrunwell/asimov/issues) — happy to help.
