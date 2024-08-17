#!/bin/bash

set -e

# Import test library for `check` command
# shellcheck source=/dev/null
source dev-container-features-test-lib

# Extension-specific tests
check "(root) oh-my-posh binary" sudo test -f /root/.local/bin/oh-my-posh
check "(root) oh-my-posh theme" sudo test -f /root/.config/oh-my-posh/themes/devcontainers.minimal.omp.json
check "(root) PROFILE.AllUsersAllHosts" sudo test -f /opt/microsoft/powershell/7/profile.ps1
check "(root) PROFILE.AllUsersAllHosts Functions" sudo test -f /opt/microsoft/powershell/7/profile.functions.ps1
check "(root) PROFILE.CurrentUserAllHosts" sudo test -f /root/.config/powershell/profile.ps1
check "(root) PROFILE.CurrentUserCurrentHost PowerShell" sudo test -f /root/.config/powershell/Microsoft.PowerShell_profile.ps1
check "(root) PROFILE.CurrentUserCurrentHost VSCode" sudo test -f /root/.config/powershell/Microsoft.VSCode_profile.ps1
check "(root) Loading Profile" sudo pwsh -Login -Command 'if ($Error.Count -gt 0) { echo "$($Error.Count) Errors during profile load: $Error"; exit 1 } else { exit 0 }'

check "(user) oh-my-posh binary" test -f /home/vscode/.local/bin/oh-my-posh
check "(user) oh-my-posh theme" sudo test -f /home/vscode/.config/oh-my-posh/themes/devcontainers.minimal.omp.json
check "(user) PROFILE.CurrentUserAllHosts" sudo test -f /home/vscode/.config/powershell/profile.ps1
check "(user) PROFILE.CurrentUserCurrentHost PowerShell" sudo test -f /home/vscode/.config/powershell/Microsoft.PowerShell_profile.ps1
check "(user) PROFILE.CurrentUserCurrentHost VSCode" sudo test -f /home/vscode/.config/powershell/Microsoft.VSCode_profile.ps1
check "(user) Loading Profile" pwsh -Login -Command 'if ($Error.Count -gt 0) { echo "$($Error.Count) Errors during profile load: $Error"; exit 1 } else { exit 0 }'
check "(user) Ownership" find ~ ! -user "$(whoami)" ! -group "$(id -gn)" -exec echo "Found: {}" \; -quit

# Report result
reportResults
