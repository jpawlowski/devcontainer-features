#!/bin/bash

set -e

# Import test library for `check` command
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Extension-specific tests
check "powershell.config.json" sudo test -f /opt/microsoft/powershell/7/powershell.config.json
check "PSCommandWithArgs" jq -e '.ExperimentalFeatures[] | select(. == "PSCommandWithArgs")' /opt/microsoft/powershell/7/powershell.config.json

# Report result
reportResults
