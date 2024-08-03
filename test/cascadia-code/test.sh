#!/bin/bash

set -e

# Optional: Import test library
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Feature-specific tests
check "Cascadia Code is available" bash -c "fc-list | grep -q 'Cascadia Code'"

# Report result
reportResults
