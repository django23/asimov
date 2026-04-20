# Contributing to Asimov

Thanks for your interest in contributing! Asimov is a small, focused project and contributions of all sizes are welcome.

## Getting started

**Prerequisites:** macOS with [Homebrew](https://brew.sh) installed.

```sh
git clone https://github.com/django23/asimov.git
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

The main script supports `--help`, `--version`, `--dry-run`, `--verbose`, and `--quiet`; unknown options exit with an error.

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

- Branch from `main` (the default branch).
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
  format.bats           # Unit tests for format_size_kb()
  plist.bats            # Tests for the LaunchAgent plist
  test_helper.bash      # Shared setup/teardown and assertions
  bin/tmutil            # Mock tmutil for testing
  bin/mdfind            # Mock mdfind for testing
scripts/
  install.sh            # Local installation script
  install-remote.sh     # Curl-based remote installer
  uninstall.sh          # Uninstallation script
Makefile                # Build targets (test, lint, check, install, uninstall)
```

## Releasing (maintainers only)

Releases are tagged from `main`. The flow is:

1. **Prepare** — on a feature branch, bump the version in `./asimov` (line `ASIMOV_VERSION=`), move entries from `[Unreleased]` to a new `[X.Y.Z]` section in `CHANGELOG.md`, open a PR into `main`.
2. **Merge** the PR. Make sure `main` is clean and `make check` passes.
3. **Tag + push** (signed, requires SSH signing configured — see below):
   ```sh
   git checkout main && git pull
   make release        # stable, e.g. v0.6.1
   # or
   make release-beta   # pre-release, e.g. v0.6.1-beta.1
   ```
   `make release` enforces: clean tree, on `main`, tag doesn't already exist, and creates a signed tag. Pushing the tag triggers `.github/workflows/release.yml`, which runs tests and publishes a GitHub release with notes pulled from `CHANGELOG.md`.
4. **Bump the Homebrew formula** — clone the tap alongside this repo (one-time):
   ```sh
   git clone git@github.com:django23/homebrew-tap.git ../homebrew-tap
   ```
   Then, after the release is live:
   ```sh
   make bump-formula   # downloads the tarball, computes sha256, updates Formula/asimov.rb, commits
   cd ../homebrew-tap && git push
   ```
   Verify with `brew install django23/tap/asimov`.

### One-time setup: SSH-signed commits + tags

Branch protection on `main` requires signed commits. Configure once per clone:

```sh
# Generate a dedicated signing key (no passphrase is fine for signing)
ssh-keygen -t ed25519 -C "your signing key" -f ~/.ssh/id_ed25519_signing -N ""

# Upload to GitHub as a signing key
gh auth refresh -s admin:ssh_signing_key
gh ssh-key add ~/.ssh/id_ed25519_signing.pub --type signing --title "$(hostname)-signing"

# Configure git for this repo
git config user.email "$(gh api user --jq '.id')+$(gh api user --jq '.login')@users.noreply.github.com"
git config gpg.format ssh
git config user.signingkey ~/.ssh/id_ed25519_signing.pub
git config commit.gpgsign true
git config tag.gpgsign true

# Allow local verification with `git tag -v` / `git log --show-signature`
mkdir -p ~/.config/git
echo "$(git config user.email) $(cat ~/.ssh/id_ed25519_signing.pub | awk '{print $1, $2}')" >> ~/.config/git/allowed_signers
git config gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
```

## Questions?

Open an [issue](https://github.com/django23/asimov/issues) — happy to help.
