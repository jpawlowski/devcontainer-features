#!/bin/bash

set -e

# Import test library for `check` command
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Extension-specific tests
check "installation checkmark" [ -f /home/vscode/.local/share/devcontainers/features/codespace-dotfiles/.dotFilesInstalled ] && exit 0 || exit 1

# Report result
reportResults
