#!/bin/bash

set -e

# Optional: Import test library
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "m365 is available" bash -c ". /usr/local/share/nvm/nvm.sh && m365 version"

# Report result
reportResults
