#!/usr/bin/env bash

# Uninstall Asimov.
#
# @author  Steve Grunwell
# @license MIT

# shellcheck disable=SC1090
source "$(pwd -P)/$(dirname "$0")/vars"

printf '\n\033[0;36mRemoving command %s\033[0m\n' "${BIN}"
[[ -f ${BIN} ]] && rm "${BIN}"

if launchctl list | grep -q com.django23.asimov; then
  printf '\n\033[0;36mUnloading current instance of %s\033[0m\n' "${PLIST}"
  launchctl unload "${DIR}/${PLIST}"
fi

printf '\n\033[0;32mAsimov has been successfully uninstalled.\033[0m\n'
