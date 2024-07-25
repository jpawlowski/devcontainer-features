#!/bin/bash

set -e

# Optional: Import test library
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "PnP.PowerShell is available" pwsh -Command "(Get-Module -Name PnP.PowerShell -ListAvailable -ErrorAction SilentlyContinue).Version.ToString()"

# Report result
reportResults
