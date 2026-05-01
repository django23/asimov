# asimov

**Stop backing up files you'll never restore.**

[Tests](https://github.com/django23/asimov/actions/workflows/tests.yml)
[Latest release](https://github.com/django23/asimov/releases)
[Stars](https://github.com/django23/asimov/stargazers)
[macOS 14+](https://support.apple.com/en-us/HT201250)
[License: MIT](LICENSE.txt)
[Shell: Bash](asimov)

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

Asimov works out of the box. For custom patterns or to enable global cache exclusions, drop a config at `~/.config/asimov/config`:

```ini
[fixed_dirs]
enabled = true                          # exclude global caches like ~/.cache
extra   = ~/my-build-cache              # plus your own paths

[sentinels]
extra    = .custom-deps custom.config   # add custom dependency patterns
disabled = vendor Gemfile               # disable a built-in pattern
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
