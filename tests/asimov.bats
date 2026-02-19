#!/usr/bin/env bats
#
# Tests for the main Asimov script.

load test_helper

# --- Sentinel-pattern tests ---

@test "Bower: excludes bower_components when bower.json is present" {
  create_project "Code/My-Project" "bower.json" "bower_components"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/bower_components"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "Bundler: excludes vendor when Gemfile is present" {
  create_project "Code/My-Project" "Gemfile" "vendor"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/vendor"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "Cargo: excludes target when Cargo.toml is present" {
  create_project "Code/My-Project" "Cargo.toml" "target"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/target"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "Carthage: excludes Carthage when Cartfile is present" {
  create_project "Code/My-Project" "Cartfile" "Carthage"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/Carthage"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "CocoaPods: excludes Pods when Podfile is present" {
  create_project "Code/My-Project" "Podfile" "Pods"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/Pods"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "Composer: excludes vendor when composer.json is present" {
  create_project "Code/My-Project" "composer.json" "vendor"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/vendor"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "Dart: excludes .packages when pubspec.yaml is present" {
  create_project "Code/My-Project" "pubspec.yaml" ".packages"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/.packages"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "Maven: excludes target when pom.xml is present" {
  create_project "Code/My-Project" "pom.xml" "target"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/target"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "Node: excludes node_modules when package.json is present" {
  create_project "Code/My-Project" "package.json" "node_modules"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/node_modules"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "Stack: excludes .stack-work when stack.yaml is present" {
  create_project "Code/My-Project" "stack.yaml" ".stack-work"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/.stack-work"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "Swift: excludes .build when Package.swift is present" {
  create_project "Code/My-Project" "Package.swift" ".build"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/.build"
  [[ "$(count_exclusions)" -eq 1 ]]
}

@test "Vagrant: excludes .vagrant when Vagrantfile is present" {
  create_project "Code/My-Project" "Vagrantfile" ".vagrant"
  run_asimov
  assert_excluded "${HOME}/Code/My-Project/.vagrant"
  [[ "$(count_exclusions)" -eq 1 ]]
}

# --- Multi-match, idempotency, and skip-path tests ---

@test "finds multiple matches in a single run" {
  create_project "Code/First-Project" "composer.json" "vendor"
  create_project "Code/Second-Project" "composer.json" "vendor"
  run_asimov
  assert_excluded "${HOME}/Code/First-Project/vendor"
  assert_excluded "${HOME}/Code/Second-Project/vendor"
  [[ "$(count_exclusions)" -eq 2 ]]
}

@test "does not re-exclude already excluded paths" {
  create_project "Code/My-Project" "composer.json" "vendor"
  run_asimov

  local first_count
  first_count="$(count_exclusions)"
  [[ "$first_count" -eq 1 ]]

  run_asimov

  local second_count
  second_count="$(count_exclusions)"
  [[ "$second_count" -eq 1 ]]
}

@test "does not check paths inside .Trash" {
  mkdir -p "${HOME}/.Trash/My-Project/vendor"
  echo "sentinel" > "${HOME}/.Trash/My-Project/composer.json"
  run_asimov
  [[ "$(count_exclusions)" -eq 0 ]]
}
