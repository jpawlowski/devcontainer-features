#!/bin/bash

set -ex

# Optional: Import test library
# shellcheck source=/dev/null
source dev-container-features-test-lib

sudo apt-get update
export DEBIAN_FRONTEND=noninteractive
sudo apt-get install -y --no-install-recommends ca-certificates curl jq unzip

# Feature-specific tests
check "Cascadia Code is available" bash -c "fc-list | grep -q 'Cascadia Code'"

# Report result
reportResults
