#!/bin/bash

set -e

# Import test library for `check` command
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Extension-specific tests
check "profile" pwsh -Command "if (\$null -eq \$env:ProfileLoaded) { echo 'Not set!'; exit 1 } else { if ( [bool]\$env:ProfileLoaded ) { echo 'Profile loaded.'; exit 0 } else { echo 'False value!'; exit 1 } }"

# Report result
reportResults
