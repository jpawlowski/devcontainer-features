#!/bin/bash

set -e

# Optional: Import test library
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Definition specific tests
check "PowerShell is available" pwsh --version

# Report result
reportResults
