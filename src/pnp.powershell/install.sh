#!/bin/bash

PSPNP_VERSION="${VERSION:-"latest"}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Find the path of pwsh if it exists in the PATH
set +e
pwsh_path=$(command -v pwsh)
set -e

if [ -z "$pwsh_path" ]; then
    echo "PowerShell (pwsh) is not installed. Please install PowerShell before running this script."
    exit 1
else
    # Check if the path is a symlink
    if [ -L "$pwsh_path" ]; then
        # It's a symlink; resolve it to the actual file path
        real_path=$(readlink -f "$pwsh_path")
    else
        # Not a symlink; use the path as is
        real_path=$pwsh_path
    fi

    # Set the execution bit for the owner, group, and others
    chmod +x "$real_path"
    echo "Execution bit set for $real_path"

    # Install PnP.PowerShell
    if ! pwsh -Command "if (Get-Module -Name PnP.PowerShell -ListAvailable -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"; then
        if [ "$PSPNP_VERSION" = "latest" ]; then
            pwsh -Command "Install-Module -Name PnP.PowerShell -Force -AllowClobber -Scope AllUsers"
        else
            pwsh -Command "Install-Module -Name PnP.PowerShell -RequiredVersion $PSPNP_VERSION -Force -AllowClobber -Scope AllUsers"
        fi
    else
        echo "PnP.PowerShell is already installed. Skipping installation."
        exit 0
    fi
fi

echo "Done!"
