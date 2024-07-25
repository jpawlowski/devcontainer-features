#!/bin/bash

set -e

# Import test library for `check` command
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Extension-specific tests
check "Az.Accounts" pwsh -Command "[string](Get-Module -ListAvailable -Name Az.Accounts -ErrorAction Stop).Version"
check "Az.Resources" pwsh -Command "[string](Get-Module -ListAvailable -Name Az.Resources -ErrorAction Stop).Version"

# Report result
reportResults
