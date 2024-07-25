#!/bin/bash

set -e

# Import test library for `check` command
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Extension-specific tests
check "PSGallery registered (user)" pwsh -Command "(Get-PSResourceRepository -Name PSGallery -ErrorAction Stop).Uri.ToString()"
check "PSGallery trust status (user)" pwsh -Command "if ((Get-PSResourceRepository -Name PSGallery).Trusted -eq \$true) { echo 'Trusted'; exit 0 } else { echo 'Untrusted'; exit 1 }"
check "PoshTestGallery registered (user)" pwsh -Command "(Get-PSResourceRepository -Name PoshTestGallery -ErrorAction Stop).Uri.ToString()"
check "PoshTestGallery trust status (user)" pwsh -Command "if ((Get-PSResourceRepository -Name PoshTestGallery).Trusted -eq \$true) { echo 'Trusted'; exit 0 } else { echo 'Untrusted'; exit 1 }"

check "PSGallery registered (root)" sudo pwsh -Command "(Get-PSResourceRepository -Name PSGallery -ErrorAction Stop).Uri.ToString()"
check "PSGallery trust status (root)" sudo pwsh -Command "if ((Get-PSResourceRepository -Name PSGallery).Trusted -eq \$true) { echo 'Trusted'; exit 0 } else { echo 'Untrusted'; exit 1 }"
check "PoshTestGallery registered (root)" sudo pwsh -Command "(Get-PSResourceRepository -Name PoshTestGallery -ErrorAction Stop).Uri.ToString()"
check "PoshTestGallery trust status (root)" sudo pwsh -Command "if ((Get-PSResourceRepository -Name PoshTestGallery).Trusted -eq \$true) { echo 'Trusted'; exit 0 } else { echo 'Untrusted'; exit 1 }"

# Report result
reportResults
