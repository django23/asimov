# Asimov Change Log

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added

* Support glob patterns in sentinel definitions, enabling wildcards like `*.xcodeproj` ([stevegrunwell/asimov#64], props @mdab121)
* Exclude Xcode DerivedData when `*.xcodeproj` is present ([stevegrunwell/asimov#64], props @mdab121)
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

* Skip directories already excluded from Time Machine backups for faster subsequent runs (inspired by [stevegrunwell/asimov#97], props @VladRassokhin)
* Migrated test suite from PHP/PHPUnit to [Bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System), removing the PHP dependency for contributors
* Replaced Travis CI pipeline with GitHub Actions (macOS 14 + 15 matrix)
* Replaced PHP `tmutil` mock with a pure bash implementation
* Moved install script to `scripts/install.sh` with shared variables, now copies binary instead of symlinking ([#35], props @sylver)

### Fixed

* Fixed duplicate Gradle sentinel entries in the sentinels list
* Fixed typo in comment ("decendents" → "descendants")

### Removed

* Removed PHP test infrastructure (`composer.json`, `phpunit.xml.dist`, and PHP test files)
* Removed Travis CI configuration (`.travis.yml`)


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


[Unreleased]: https://github.com/stevegrunwell/asimov/compare/master...develop
[Version 0.1.0]: https://github.com/stevegrunwell/asimov/releases/tag/v0.1.0
[Version 0.2.0]: https://github.com/stevegrunwell/asimov/releases/tag/v0.2.0
[Version 0.3.0]: https://github.com/stevegrunwell/asimov/releases/tag/v0.3.0
[#5]: https://github.com/stevegrunwell/asimov/issues/5
[#7]: https://github.com/stevegrunwell/asimov/issues/7
[#10]: https://github.com/stevegrunwell/asimov/issues/10
[#15]: https://github.com/stevegrunwell/asimov/pull/15
[#16]: https://github.com/stevegrunwell/asimov/pull/16
[#17]: https://github.com/stevegrunwell/asimov/pull/17
[#18]: https://github.com/stevegrunwell/asimov/pull/18
[#20]: https://github.com/stevegrunwell/asimov/pull/20
[#22]: https://github.com/stevegrunwell/asimov/pull/22
[#30]: https://github.com/stevegrunwell/asimov/pull/30
[#31]: https://github.com/stevegrunwell/asimov/pull/31
[#32]: https://github.com/stevegrunwell/asimov/pull/32
[#33]: https://github.com/stevegrunwell/asimov/pull/33
[#34]: https://github.com/stevegrunwell/asimov/pull/34
[#36]: https://github.com/stevegrunwell/asimov/pull/36
[#37]: https://github.com/stevegrunwell/asimov/pull/37
[#43]: https://github.com/stevegrunwell/asimov/pull/43
[#52]: https://github.com/stevegrunwell/asimov/pull/52
[#55]: https://github.com/stevegrunwell/asimov/pull/55
[#35]: https://github.com/stevegrunwell/asimov/pull/35
[#56]: https://github.com/stevegrunwell/asimov/pull/56
[stevegrunwell/asimov#64]: https://github.com/stevegrunwell/asimov/pull/64
[stevegrunwell/asimov#87]: https://github.com/stevegrunwell/asimov/pull/87
[stevegrunwell/asimov#97]: https://github.com/stevegrunwell/asimov/pull/97
