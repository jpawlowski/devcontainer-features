#!/bin/bash

set -e

# Import test library for `check` command
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Extension-specific tests
check "powershell.config.json" sudo test -f /opt/microsoft/powershell/7/powershell.config.json
check "ExperimentalFeature1" jq -e '.ExperimentalFeatures[] | select(. == "ExperimentalFeature1")' /opt/microsoft/powershell/7/powershell.config.json
check "ExperimentalFeature2" jq -e '.ExperimentalFeatures[] | select(. == "ExperimentalFeature2")' /opt/microsoft/powershell/7/powershell.config.json

# Report result
reportResults
