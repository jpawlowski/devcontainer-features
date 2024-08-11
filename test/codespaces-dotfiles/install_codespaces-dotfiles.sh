#!/bin/bash

set -e

# Import test library for `check` command
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Extension-specific tests
check "postStartOnce.sh present" [ -f /usr/local/share/devcontainers/features/codespaces-dotfiles/postStartOnce.sh ] && exit 0 || exit 1

# Report result
reportResults
