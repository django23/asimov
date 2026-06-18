# asimov

**Stop backing up files you'll never restore.**

[![Tests](https://github.com/django23/asimov/actions/workflows/tests.yml/badge.svg)](https://github.com/django23/asimov/actions/workflows/tests.yml)
[![Latest release](https://img.shields.io/github/v/release/django23/asimov?sort=semver&color=blue)](https://github.com/django23/asimov/releases)
[![Stars](https://img.shields.io/github/stars/django23/asimov?style=flat)](https://github.com/django23/asimov/stargazers)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue?logo=apple&logoColor=white)](https://support.apple.com/en-us/HT201250)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE.txt)
[![Shell: Bash](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnubash&logoColor=white)](asimov)

Every Time Machine snapshot copies your `node_modules`, `.venv`, `target`, `DerivedData`; gigabytes of files you can rebuild with one command. With git worktrees and AI coding agents spinning up parallel copies of every project, that waste compounds fast.

Asimov scans your home directory, finds dependency folders next to their config files, and tells Time Machine to skip them. Install once, run daily, forget it exists.

## Install

```sh
brew install django23/tap/asimov
brew services start django23/tap/asimov
```

That's it — Asimov runs at midday, every day. Prefer no Homebrew? See [other install methods](#other-install-methods).

## What you'll see

```
$ asimov --dry-run --stats

⏳ Scanning for dependency directories…
📦 Processing matches…
- Would exclude: ~/Code/myapp/node_modules (412M).
- Would exclude: ~/Code/myapp/.next (89M).
- Would exclude: ~/Code/api/.venv (1.2G).
- Would exclude: ~/Code/rust-cli/target (2.4G).
- Would exclude: ~/Code/worktrees/feature-auth/node_modules (1.6G).
- Would exclude: ~/Code/worktrees/feature-auth/.next (492M).
- Would exclude: ~/Code/worktrees/refactor-billing/node_modules (1.6G).
…

Would exclude 27 directories, totalling 18.4G.
```

`--dry-run` previews without changing anything. Drop the flag — and the `--stats` if you want it fast — to apply.

## How it works

Asimov pairs each dependency directory with a **sentinel** config file. A folder is only excluded if its sentinel exists alongside it:

- `node_modules/` → requires `package.json`
- `vendor/` → requires `composer.json` or `go.mod`
- `target/` → requires `Cargo.toml` or `pom.xml`

This means Asimov never touches a folder that just happens to share a common name. Safe to run anywhere in your home directory.

**Supported ecosystems (30+ patterns)**


| Ecosystem                   | Directories excluded                                                                                                             |
| --------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **JavaScript / TypeScript** | `node_modules`, `.next`, `.nuxt`, `.angular`, `.svelte-kit`, `.turbo`, `.yarn`, `.parcel-cache`, `bower_components`, `elm-stuff` |
| **Python**                  | `.venv`, `venv`, `.tox`, `.nox`, `__pypackages__`, `build`, `dist`                                                               |
| **Rust**                    | `target`                                                                                                                         |
| **Go**                      | `vendor`                                                                                                                         |
| **PHP**                     | `vendor`                                                                                                                         |
| **Ruby**                    | `vendor`                                                                                                                         |
| **Java / Kotlin / Scala**   | `.gradle`, `build`, `target`                                                                                                     |
| **.NET (C# / F#)**          | `bin`, `obj`                                                                                                                     |
| **Swift / Apple**           | `.build`, `Carthage`, `Pods`, `DerivedData`                                                                                      |
| **Dart / Flutter**          | `.dart_tool`, `.packages`, `build`                                                                                               |
| **Elixir**                  | `deps`, `_build`, `.build`                                                                                                       |
| **Clojure**                 | `target`, `.cpcache`, `.shadow-cljs`                                                                                             |
| **Haskell**                 | `.stack-work`                                                                                                                    |
| **OCaml**                   | `_build`                                                                                                                         |
| **Zig**                     | `.zig-cache`, `zig-out`                                                                                                          |
| **R**                       | `renv`                                                                                                                           |
| **DevOps / IaC**            | `.terraform`, `.terragrunt-cache`, `.vagrant`, `.direnv`, `cdk.out`                                                              |
| **Game dev**                | `.godot`                                                                                                                         |
| **Global caches** (opt-in)  | `~/.cache`, `~/.gradle/caches`, `~/.m2/repository`, `~/.npm/_cacache`, `~/.nuget/packages`, `~/.kube/cache`                      |

**Don't see your tool?** You can teach Asimov your own directory + sentinel pairs in a couple of lines — no need to wait for a release. See [Add your own patterns](#add-your-own-patterns).


## Usage

```
asimov [--dry-run] [--verbose] [--quiet] [--stats] [--help] [--version]
```


| Option      | Description                                                |
| ----------- | ---------------------------------------------------------- |
| `--dry-run` | Print what would be excluded without changing Time Machine |
| `--verbose` | Show all directories including already-excluded ones       |
| `--quiet`   | Suppress all output except errors                          |
| `--stats`   | Show per-directory sizes and a total-space summary         |


## Schedule

If you installed via Homebrew, `brew services start django23/tap/asimov` already set up a daily run. To trigger one immediately or stop the schedule:

```sh
launchctl kickstart gui/$(id -u)/com.django23.asimov   # run now
launchctl bootout   gui/$(id -u)/com.django23.asimov   # stop schedule
```

Manual and curl installers set up the same launchd job automatically.

## Configuration

Asimov works out of the box. To customize it, drop a config file at `~/.config/asimov/config`. The most useful thing you can do here is **teach it dependency directories of your own.**

### Add your own patterns

Using a tool Asimov doesn't know about yet? Add it yourself. Each pattern is a `directory sentinel` pair — exactly the same mechanism the [built-ins](#how-it-works) use: the directory is excluded **only** when the sentinel file sits right beside it, so it's safe even for common folder names.

```ini
[sentinels]
extra = .cache my-tool.toml      # exclude .cache only when my-tool.toml is its sibling
extra = generated codegen.yml    # one "extra =" line per pattern
extra = dist *.podspec           # glob sentinels work too
```

Want to turn a built-in off? List its exact pair under `disabled`:

```ini
[sentinels]
disabled = vendor Gemfile        # stop excluding Ruby's vendor/ directories
```

### Global caches (opt-in)

Global tool caches in your home directory (`~/.cache`, `~/.gradle/caches`, …) are left alone by default. Opt in, and add paths of your own:

```ini
[fixed_dirs]
enabled = true                   # exclude the built-in global caches
extra   = ~/my-build-cache       # plus any paths you name (always excluded when they exist)
```

## Other install methods

**curl (no Homebrew):**

```sh
curl -fsSL https://raw.githubusercontent.com/django23/asimov/main/scripts/install-remote.sh | bash
```

**From source:**

```sh
git clone https://github.com/django23/asimov.git --depth 1
cd asimov && make install
```

## Uninstall

```sh
brew uninstall asimov                                # Homebrew
rm ~/.local/bin/asimov                               # curl install
launchctl bootout gui/$(id -u)/com.django23.asimov   # stop schedule
make uninstall                                       # source install
```

## Upgrading

See [UPGRADING.md](UPGRADING.md) for migrating from v0.4.x or the [original asimov](https://github.com/stevegrunwell/asimov).

## Credits

Asimov was originally created by [Steve Grunwell](https://github.com/stevegrunwell/asimov). This fork is actively maintained at [django23/asimov](https://github.com/django23/asimov) with performance improvements, config file support, and expanded ecosystem coverage.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for setup and guidelines. Security issues: see [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE.txt)
