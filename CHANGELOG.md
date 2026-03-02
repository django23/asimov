# Asimov Change Log

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added

### Changed

### Fixed

### Removed

## [0.4.0] — 2025-02-20

### Added

* Validation that `ASIMOV_ROOT` exists and is a directory before running (clear error and exit 1 if not)
* Test for project paths containing spaces; test for dry-run summary format (count and size)
* `--help` and `--version` options; unknown options exit with an error and usage message
* `--dry-run` option to print what would be excluded without calling `tmutil`
* Support glob patterns in sentinel definitions, enabling wildcards like `*.xcodeproj` ([stevegrunwell/asimov#64], props @mdab121)
* Exclude Xcode DerivedData when `*.xcodeproj` is present ([stevegrunwell/asimov#64], props @mdab121)
* Exclude well-known global cache directories (`~/.cache`, `~/.gradle/caches`, `~/.m2/repository`, `~/.npm/_cacache`, `~/.nuget/packages`, `~/.kube/cache`, etc.) without requiring sentinel files (inspired by [stevegrunwell/asimov#69], props @pkuczynski)
* Display a summary of total count and size of newly excluded directories at the end of each run (inspired by [stevegrunwell/asimov#84], props @Vadorequest)
* Exclude Next.js build cache (`.next`)
* Exclude Nuxt build cache (`.nuxt`)
* Exclude Angular CLI cache (`.angular`)
* Exclude SvelteKit build output (`.svelte-kit`)
* Exclude Turborepo cache (`.turbo`)
* Exclude Yarn Berry cache (`.yarn`)
* Exclude Leiningen/Clojure CLI `target` and `.cpcache` directories
* Exclude Shadow-CLJS cache (`.shadow-cljs`)
* Exclude Python virtualenv `venv` with `pyproject.toml` sentinel
* Exclude PEP 582/PDM local packages (`__pypackages__`)
* Exclude Elixir/Mix standard `_build` directory
* Exclude Terraform providers/modules (`.terraform` with `.terraform.lock.hcl`)
* Exclude direnv output (`.direnv`)
* Exclude OCaml/Dune build output (`_build`)
* Exclude Zig build cache (`.zig-cache`) and output (`zig-out`)
* Exclude Elm packages (`elm-stuff`)
* Exclude Godot 4 editor cache (`.godot`)
* Exclude R renv environment (`renv`)
* Exclude .NET build output (`bin`, `obj`) when `*.csproj` or `*.fsproj` project files are present (inspired by [stevegrunwell/asimov#87], props @guigomesa)
* Added `make install` and `make uninstall` targets for streamlined setup and removal ([#35], props @sylver)
* Added `scripts/uninstall.sh` to cleanly remove Asimov and its launchd schedule ([#35], props @sylver)
* Added common interval reference comments to `com.stevegrunwell.asimov.plist` ([#35], props @sylver)

### Changed

* Use `ASIMOV_ROOT` in `ASIMOV_SKIP_PATHS` and `ASIMOV_FIXED_DIRS` so skip/fixed paths are correct when running as root (e.g. launchd)
* Refactor: extract `record_excluded_path()` for DRY size logging and output; `resolve_asimov_root()`, `build_find_skip_params()`, `build_find_vendor_params()`, `print_exclusion_summary()`, `format_size_kb()`; rename `exclude_file` to `exclude_paths_from_stdin`; add named constants for size and colors
* Skip non-directory paths in `exclude_paths_from_stdin` (avoids failures if a path disappears between find and processing)
* Use `printf` instead of `echo -e` in install/uninstall scripts for portability
* Skip directories already excluded from Time Machine backups for faster subsequent runs (inspired by [stevegrunwell/asimov#97], props @VladRassokhin)
* Migrated test suite from PHP/PHPUnit to [Bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System), removing the PHP dependency for contributors
* Replaced Travis CI pipeline with GitHub Actions (macOS 14 + 15 matrix)
* Replaced PHP `tmutil` mock with a pure bash implementation
* Moved install script to `scripts/install.sh` with shared variables, now copies binary instead of symlinking ([#35], props @sylver)

### Fixed

* Handle `tmutil` errors gracefully instead of crashing; paths that fail exclusion are skipped with a warning ([stevegrunwell/asimov#101], [stevegrunwell/asimov#86])
* Detect the logged-in user's home directory when running as root, fixing `brew services` and `sudo` invocations that would search `/var/root` instead ([stevegrunwell/asimov#72])
* Fixed duplicate Gradle sentinel entries in the sentinels list
* Fixed typo in comment ("decendents" → "descendants")

### Removed

* Removed PHP test infrastructure (`composer.json`, `phpunit.xml.dist`, and PHP test files)
* Removed Travis CI configuration (`.travis.yml`)

[0.4.0]: https://github.com/django23/asimov/compare/v0.3.0...v0.4.0

## [Version 0.3.0] — 2020-06-16

### Added

* Added Homebrew support 🙌 ([#34], props @Dids)
* Exclude Bower dependencies ([#22], props @moezzie)
* Exclude Maven builds ([#30], props @bertschneider)
* Exclude Stack dependencies ([#32], props @alex-kononovich)
* Exclude Carthage dependencies ([#37], props @qvacua)
* Exclude CocoaPods dependencies and Swift builds ([#43], props @slashmo)
* Exclude Bundler, Cargo, and Dart dependencies ([#56])
* Define a [Travis CI pipeline for Asimov](https://travis-ci.com/github/stevegrunwell/asimov) ([#20])
* Add an automated test suite using PHPUnit ([#31])

### Fixed

* Removed an extraneous `read -r path`, which was causing the first match to be skipped ([#15], props @rowanbeentje)
* Use the full system path when running `chmod` in `install.sh` ([#33], props @ko-dever)

### Changed

* The size of the excluded directories are now included in the Asimov output ([#16], props @rowanbeentje)
* Switch to using find's -prune switch to exclude match subdirectories for speed, and exclude ~/Library folder from searches ([#17], props @rowanbeentje)
* Rework the `find` command and path variables so that `find` is only run once however many FILEPATHS are set ([#18], @props @rowanbeentje, yet again 😉)
 Fix incorrect directory pruning, simplify path handling ([#36], props @rwe)
* Recommend cloning via HTTPS rather than SSH for manual installations ([#52], props @Artoria2e5)
* Don't look for matches in `~/.Trash` ([#55])


## [Version 0.2.0] — 2017-11-25

### Added

* Bundle the script with `com.stevegrunwell.asimov.plist`, enabling Asimov to be scheduled to run daily. Users can set this up in a single step by running the new `install.sh` script.
 Added a formal change log to the repository. ([#5])

### Fixed

* Fixed pathing issue when resolving the script directory for `install.sh`. Props @morganestes. ([#7])

### Changed
* Change the scope of Asimov to find matching directories within the current user's home directory, not just `~/Sites`. Props to @vitch for catching this! ([#10]).


## [Version 0.1.0] — 2017-10-17

Initial public release.


[Unreleased]: https://github.com/django23/asimov/compare/v0.4.0...improvements
[stevegrunwell/asimov#10]: https://github.com/stevegrunwell/asimov/issues/10
[stevegrunwell/asimov#15]: https://github.com/stevegrunwell/asimov/pull/15
[stevegrunwell/asimov#16]: https://github.com/stevegrunwell/asimov/pull/16
[stevegrunwell/asimov#17]: https://github.com/stevegrunwell/asimov/pull/17
[stevegrunwell/asimov#18]: https://github.com/stevegrunwell/asimov/pull/18
[stevegrunwell/asimov#20]: https://github.com/stevegrunwell/asimov/pull/20
[stevegrunwell/asimov#22]: https://github.com/stevegrunwell/asimov/pull/22
[stevegrunwell/asimov#30]: https://github.com/stevegrunwell/asimov/pull/30
[stevegrunwell/asimov#31]: https://github.com/stevegrunwell/asimov/pull/31
[stevegrunwell/asimov#32]: https://github.com/stevegrunwell/asimov/pull/32
[stevegrunwell/asimov#33]: https://github.com/stevegrunwell/asimov/pull/33
[stevegrunwell/asimov#34]: https://github.com/stevegrunwell/asimov/pull/34
[stevegrunwell/asimov#36]: https://github.com/stevegrunwell/asimov/pull/36
[stevegrunwell/asimov#37]: https://github.com/stevegrunwell/asimov/pull/37
[stevegrunwell/asimov#43]: https://github.com/stevegrunwell/asimov/pull/43
[stevegrunwell/asimov#52]: https://github.com/stevegrunwell/asimov/pull/52
[stevegrunwell/asimov#55]: https://github.com/stevegrunwell/asimov/pull/55
[stevegrunwell/asimov#35]: https://github.com/stevegrunwell/asimov/pull/35
[stevegrunwell/asimov#56]: https://github.com/stevegrunwell/asimov/pull/56
[stevegrunwell/asimov#64]: https://github.com/stevegrunwell/asimov/pull/64
[stevegrunwell/asimov#69]: https://github.com/stevegrunwell/asimov/pull/69
[stevegrunwell/asimov#86]: https://github.com/stevegrunwell/asimov/issues/86
[stevegrunwell/asimov#87]: https://github.com/stevegrunwell/asimov/pull/87
[stevegrunwell/asimov#97]: https://github.com/stevegrunwell/asimov/pull/97
[stevegrunwell/asimov#5]: https://github.com/stevegrunwell/asimov/issues/5
[stevegrunwell/asimov#7]: https://github.com/stevegrunwell/asimov/issues/7
[stevegrunwell/asimov#72]: https://github.com/stevegrunwell/asimov/issues/72
[stevegrunwell/asimov#84]: https://github.com/stevegrunwell/asimov/issues/84
[stevegrunwell/asimov#101]: https://github.com/stevegrunwell/asimov/issues/101
