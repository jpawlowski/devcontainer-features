#!/bin/bash

set -e

# Import test library for `check` command
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Extension-specific tests
check "Az.Accounts" pwsh -Command "if (Get-Module -ListAvailable -Name Az.Accounts -ErrorAction Stop | Where-Object { \$_.Version -eq '3.0.0' }) { echo '3.0.0'; exit 0 } else { echo 'Not found'; exit 1 }"
check "Az.Resources" pwsh -Command "if (Get-Module -ListAvailable -Name Az.Resources -ErrorAction Stop | Where-Object { \$_.Version -eq '7.2.0' }) { echo '7.2.0'; exit 0 } else { echo 'Not found'; exit 1 }"

# Report result
reportResults
