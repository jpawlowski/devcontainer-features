#!/bin/bash

set -e

# Import test library for `check` command
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Extension-specific tests
check "Powershell version as installed by feature" bash -c "pwsh --version"

# shellcheck source=/dev/null
source lib.sh

sudo mkdir -p /var/lib/apt/lists/

echo -e "\nInstalling Powershell with find_prev_version_from_git_tags() fn 👈🏻"
install_using_github "mode1"
check "Powershell version as installed by test (find_prev_version_from_git_tags() fn)" bash -c "pwsh --version"

echo -e "\nInstalling Powershell with GitHub Api 👈🏻"
install_using_github "mode2"
check "Powershell version as installed by test (GitHub Api)" bash -c "pwsh --version"

# Report result
reportResults
