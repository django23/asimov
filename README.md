# Asimov

[![Tests](https://github.com/django23/asimov/actions/workflows/tests.yml/badge.svg?branch=develop)](https://github.com/django23/asimov/actions/workflows/tests.yml)
[![Homebrew](https://img.shields.io/badge/homebrew-available-orange?logo=homebrew&logoColor=white)](https://formulae.brew.sh/formula/asimov)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple&logoColor=white)](https://support.apple.com/en-us/HT201250)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE.txt)
[![Shell: Bash](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnubash&logoColor=white)](asimov)

> Those people who think they know everything are a great annoyance to those of us who do.<br>— Isaac Asimov

**Asimov automatically excludes development dependencies from macOS [Time Machine](https://support.apple.com/en-us/HT201250) backups.** It scans your home directory for known dependency directories (e.g. `node_modules/`, `vendor/`, `.venv/`), verifies that the corresponding config file exists alongside them, and tells Time Machine to skip them. No more wasting backup space on files you can restore with a single command.

## Quick start

```sh
brew install asimov
sudo brew services start asimov   # run daily via launchd
```

That's it. Asimov will now run once a day and exclude any dependency directories it finds.

To run on-demand instead:

```sh
asimov
```

## Supported ecosystems

Asimov recognizes dependency directories across **30+ patterns** in these ecosystems:

| Ecosystem | Directories excluded |
|---|---|
| **JavaScript / TypeScript** | `node_modules`, `.next`, `.nuxt`, `.angular`, `.svelte-kit`, `.turbo`, `.yarn`, `.parcel-cache`, `bower_components`, `elm-stuff` |
| **Python** | `.venv`, `venv`, `.tox`, `.nox`, `__pypackages__`, `build`, `dist` |
| **Rust** | `target` |
| **Go** | `vendor` |
| **PHP** | `vendor` |
| **Ruby** | `vendor` |
| **Java / Kotlin / Scala** | `.gradle`, `build`, `target` |
| **Swift / Apple** | `.build`, `Carthage`, `Pods` |
| **Dart / Flutter** | `.dart_tool`, `.packages`, `build` |
| **Elixir** | `deps`, `_build`, `.build` |
| **Clojure** | `target`, `.cpcache`, `.shadow-cljs` |
| **Haskell** | `.stack-work` |
| **OCaml** | `_build` |
| **Zig** | `.zig-cache`, `zig-out` |
| **R** | `renv` |
| **DevOps / IaC** | `.terraform`, `.terragrunt-cache`, `.vagrant`, `.direnv`, `cdk.out` |
| **Game dev** | `.godot` |

Each directory is only excluded when its corresponding config file (the "sentinel") exists — so `node_modules` is only excluded if `package.json` is present, `vendor` only if `composer.json`, `go.mod`, or `Gemfile` exists, etc.

## Installation

### Homebrew (recommended)

```sh
brew install asimov
```

For the latest development version:

```sh
brew install asimov --head
```

Schedule Asimov to run daily:

```sh
sudo brew services start asimov
```

### Manual

```sh
git clone https://github.com/stevegrunwell/asimov.git --depth 1
cd asimov
make install
```

This copies Asimov to `/usr/local/bin`, sets up a daily launchd schedule, and runs it immediately.

> **Tip:** Edit `com.stevegrunwell.asimov.plist` before running `make install` to customize the schedule.

### Uninstall

```sh
make uninstall     # manual installations
# or
brew uninstall asimov
```

## How it works

Asimov is a thin wrapper around Apple's [`tmutil`](https://ss64.com/mac/tmutil.html). It builds a single `find` command from all known dependency patterns, walks your home directory (skipping `~/Library` and `~/.Trash`), and pipes matching paths through `tmutil addexclusion`. Directories already excluded are skipped automatically — safe to run as often as you like.

### Inspecting exclusions

List everything excluded from Time Machine:

```sh
sudo mdfind "com_apple_backup_excludeItem = 'com.apple.backupd'"
```

Remove an exclusion added in error:

```sh
tmutil removeexclusion /path/to/directory
```

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, guidelines, and how to add new dependency patterns.

## License

[MIT](LICENSE.txt) — Steve Grunwell
