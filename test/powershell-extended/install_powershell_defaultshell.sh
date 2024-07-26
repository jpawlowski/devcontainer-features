#!/bin/bash

set -e

# Import test library for `check` command
# shellcheck source=/dev/null
source dev-container-features-test-lib

get_default_shell() {
    local user="$1"
    getent passwd "$user" | cut -d: -f7
}

# Extension-specific tests
check "default shell (user)" get_default_shell "$(whoami)" | grep -q "pwsh$" && exit 0 || exit 1
check "default shell (root)" get_default_shell root | grep -q "pwsh$" && exit 0 || exit 1

# Report result
reportResults
