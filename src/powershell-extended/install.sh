#!/bin/bash

# Original version from: https://github.com/devcontainers/features/blob/main/src/powershell/

set -e

# load common functions
# shellcheck source=/dev/null
source "$(dirname "$0")/lib.sh" # Input variables are exported from here

# Clean up
rm -rf /var/lib/apt/lists/*

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Define PowerShell preferences
prefs="\$ProgressPreference='SilentlyContinue'; \$InformationPreference='Continue'; \$VerbosePreference='SilentlyContinue'; \$ConfirmPreference='None'; \$ErrorActionPreference='Stop';"

# Install PowerShell if not already installed
if ! type pwsh >/dev/null 2>&1; then
    if [ "$POWERSHELL_INSTALLATION_METHOD" = 'package' ]; then
        export DEBIAN_FRONTEND=noninteractive

        # Source /etc/os-release to get OS info
        # shellcheck source=/dev/null
        . /etc/os-release
        architecture="$(dpkg --print-architecture)"

        if [[ "${POWERSHELL_ARCHIVE_ARCHITECTURES}" = *"${architecture}"* ]] && [[ "${POWERSHELL_ARCHIVE_VERSION_CODENAMES}" = *"${VERSION_CODENAME}"* ]]; then
            install_using_apt || use_github="true"
        else
            use_github="true"
        fi
    else
        use_github="true"
    fi

    if [ "${use_github}" = "true" ]; then
        echo "Attempting install from GitHub release..."
        install_using_github
    fi

    if [ "$POWERSHELL_UPDATE_PSRESOURCEGET" != 'none' ]; then
        if [ "$POWERSHELL_VERSION" = 'latest' ] || ! version_compare "$POWERSHELL_VERSION" 'ge' '7.4.0'; then
            # Update Microsoft.PowerShell.PSResourceGet
            prerelease=""
            if [ "$POWERSHELL_UPDATE_PSRESOURCEGET" = 'prerelease' ]; then
                prerelease="-Prerelease"
            fi
            currentVersion=$(pwsh -NoProfile -Command "(Get-Module -ListAvailable -Name Microsoft.PowerShell.PSResourceGet).Version.ToString()")
            latestVersion=$(pwsh -NoProfile -Command "(Find-PSResource -Name Microsoft.PowerShell.PSResourceGet -Repository PSGallery -Type Module $prerelease | Sort-Object -Property {[version]\$_.Version} -Descending | Select-Object -First 1).Version.ToString()")
            if version_compare "$latestVersion" 'gt' "$currentVersion"; then
                echo "Updating Microsoft.PowerShell.PSResourceGet"
                pwsh -NoProfile -Command "$prefs; Install-PSResource -Verbose -Repository PSGallery -TrustRepository -Scope AllUsers -Name Microsoft.PowerShell.PSResourceGet $prerelease"
            fi
        else
            # Installing Microsoft.PowerShell.PSResourceGet
            prerelease=""
            if [ "$POWERSHELL_UPDATE_PSRESOURCEGET" = 'prerelease' ]; then
                prerelease="-AllowPrerelease"
            fi
            echo "Installing Microsoft.PowerShell.PSResourceGet"
            pwsh -NoProfile -Command "$prefs; Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module -Verbose -Repository PSGallery -Scope AllUsers -Name Microsoft.PowerShell.PSResourceGet -Force -AllowClobber $prerelease; Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted"
        fi
    fi

    # If default shell is requested, set it
    if [ "$POWERSHELL_SET_DEFAULT_SHELL" = 'true' ]; then
        echo "Setting default shell to pwsh"
        chsh -s "$(command -v pwsh)"
        echo "[root] Set default shell to pwsh"
        if [ -n "$_REMOTE_USER" ] && [ "$_REMOTE_USER" != 'root' ]; then
            echo "[$_REMOTE_USER] Set default shell to pwsh"
            chsh "$_REMOTE_USER" -s "$(command -v pwsh)"
        fi
    fi
else
    echo "PowerShell is already installed."
fi

# Get existing repositories
IFS=';' read -r -a repos <<<"$(pwsh -NoProfile -Command "(Get-PSResourceRepository).Uri.OriginalString -join ';'")"

# If PowerShell repositories are requested, loop through and register
if [ "$POWERSHELL_REPOSITORIES" != '' ]; then
    echo "Registering PowerShell Repositories:"

    IFS=';' read -r -a repositories <<<"$(echo "$POWERSHELL_REPOSITORIES" | tr -d '[:space:]')"
    for item in "${repositories[@]}"; do
        # Handle priority for PSGallery
        if [[ "$item" =~ ^PSGallery(\^[0-9]+)?$|^(PSGallery=)?https://www\.powershellgallery\.com ]]; then
            IFS='=' read -r repoName repoFullUri <<<"$item"
            if [ "$repoFullUri" != '' ]; then
                IFS='^' read -r repoUri repoPrio <<<"$repoFullUri"
            else
                IFS='^' read -r repoName2 repoPrio <<<"$repoName"
            fi

            if [ -z "$repoPrio" ]; then
                # Set PSGallery to trusted only
                echo "[root] Set PSGallery as trusted repository"
                pwsh -NoProfile -Command "$prefs; Set-PSResourceRepository -Name PSGallery -Trusted"
                if [ -n "$_REMOTE_USER" ] && [ "$_REMOTE_USER" != 'root' ]; then
                    echo "[$_REMOTE_USER] Set PSGallery as trusted repository"
                    su "$_REMOTE_USER" /bin/bash -c "pwsh -NoProfile -Command \"$prefs; Set-PSResourceRepository -Name PSGallery -Trusted\""
                fi

            elif [[ "$repoPrio" =~ ^[0-9]+$ ]] && [ "$repoPrio" -ge 0 ] && [ "$repoPrio" -le 100 ]; then
                # Update priority and set to trusted
                echo "[root] Set PSGallery as trusted repository and update priority to '$repoPrio'"
                pwsh -NoProfile -Command "$prefs; Set-PSResourceRepository -Name PSGallery -Trusted -Priority $repoPrio"
                if [ -n "$_REMOTE_USER" ] && [ "$_REMOTE_USER" != 'root' ]; then
                    echo "[$_REMOTE_USER] Set PSGallery as trusted repository and update priority to '$repoPrio'"
                    su "$_REMOTE_USER" /bin/bash -c "pwsh -NoProfile -Command \"$prefs; Set-PSResourceRepository -Name PSGallery -Trusted -Priority $repoPrio\""
                fi
            else
                echo "Invalid priority for 'PSGallery': $repoPrio"
                exit 1
            fi

            continue
        fi

        # Extract repository name, URI, and priority
        IFS='=' read -r repoName repoFullUri <<<"$item"
        IFS='^' read -r repoUri repoPrio <<<"$repoFullUri"

        # Exit if repository URI is empty
        if [ "$repoUri" = '' ]; then
            echo "Invalid repository: $item"
            exit 1
        fi

        # Check if repository is already registered
        if [[ ! "${repos[*]}" =~ $repoUri ]]; then
            # Validate if repository is a valid URI
            if [[ ! "$repoUri" =~ ^https?:// ]]; then
                echo "Invalid repository URI: $repoUri"
                exit 1
            fi

            # Use domain name as repository name if not provided
            if [ -z "$repoName" ]; then
                repoName=$(echo "$repoUri" | sed -E 's|^[a-zA-Z]+://([^:/]+).*|\1|')
            fi

            repoargs="-Name '$repoName' -Uri '$repoUri' -Trusted"

            # Add priority if provided
            if [ -n "$repoPrio" ]; then
                if [[ "$repoPrio" =~ ^[0-9]+$ ]] && [ "$repoPrio" -ge 0 ] && [ "$repoPrio" -le 100 ]; then
                    repoargs+=" -Priority $repoPrio"
                else
                    echo "Invalid priority for '$repoName': $repoPrio"
                    exit 1                    
                fi
            fi

            # Register repository
            echo "[root] Register-PSResourceRepository $repoargs"
            pwsh -NoProfile -Command "$prefs; Register-PSResourceRepository $repoargs"
            if [ -n "$_REMOTE_USER" ] && [ "$_REMOTE_USER" != 'root' ]; then
                echo "[$_REMOTE_USER] Register-PSResourceRepository $repoargs"
                su "$_REMOTE_USER" /bin/bash -c "pwsh -NoProfile -Command \"$prefs; Register-PSResourceRepository $repoargs\""
            fi

            # Add to list of repositories
            repos+=("$repoUri")
            echo "Registered repository: $repoName"
        else
            echo "Repository already registered: $item"
        fi
    done
fi

# If PowerShell resources are requested, loop through and install
if [ "$POWERSHELL_RESOURCES" != '' ]; then
    echo "Installing PowerShell Resources:"

    IFS=';' read -r -a resources <<<"$(echo "$POWERSHELL_RESOURCES" | tr -d '[:space:]')"
    for item in "${resources[@]}"; do
        args="-Scope AllUsers -TrustRepository -AcceptLicense"
        repoName=""
        repoUri=""
        repoPrio=""
        resourceName=""
        fullVersion=""
        version=""
        prerelease=""
        versionStart=""
        prereleaseStart=""
        versionEnd=""
        prereleaseEnd=""

        # Split item at '@' if present
        if [[ "$item" == *"@"* ]]; then
            IFS='@' read -r uri fullVersion <<<"$item"
            args+=" -Version '$fullVersion'"

            # Check for version NuGet format
            if [[ "$fullVersion" =~ (\[|\().*(\]|\)) ]]; then
                # Trim brackets
                versionContent=${fullVersion:1:-1}

                # Check for version range
                if [[ "$versionContent" == *","* ]]; then
                    IFS=',' read -r versionStart versionEnd <<<"$versionContent"
                    # Handle potential prerelease for each version
                    if [[ "$versionStart" == *"-"* ]]; then
                        IFS='-' read -r versionStart prereleaseStart <<<"$versionStart"
                        args+=" -Prerelease"
                    fi
                    if [[ "$versionEnd" == *"-"* ]]; then
                        IFS='-' read -r versionEnd prereleaseEnd <<<"$versionEnd"
                        args+=" -Prerelease"
                    fi
                else
                    # Single version, possibly with prerelease
                    if [[ "$versionContent" == *"-"* ]]; then
                        IFS='-' read -r version prerelease <<<"$versionContent"
                        args+=" -Prerelease"
                    else
                        version="$fullVersion"
                    fi
                fi
            # SemVer format
            elif [[ "$fullVersion" == *"-"* ]]; then
                IFS='-' read -r version prerelease <<<"$fullVersion"
                args+=" -Prerelease"
            else
                version="$fullVersion"
            fi

            # Set item without version
            item="$uri"
        fi

        # Extract resourceName
        resourceName=${item##*/}
        args+=" -Name '$resourceName'"

        # Extract original repository URI
        if [[ "$item" == */* ]]; then
            repoOrigUri=${item%/*}
        else
            repoOrigUri=""
        fi

        # Extract repository name and URI
        IFS='=' read -r repoName repoFullUri <<<"$repoOrigUri"
        IFS='^' read -r repoUri repoPrio <<<"$repoFullUri"

        # If provided, check if repository is already registered
        if [ "$repoUri" != '' ]; then
            if [[ ! "${repos[*]}" =~ $repoUri ]]; then
                # Validate if repository is a valid URI
                if [[ ! "$repoUri" =~ ^https?:// ]]; then
                    echo "Invalid repository URI: $repoUri"
                    exit 1
                fi

                # Use domain name as repository name if not provided
                if [ -z "$repoName" ]; then
                    repoName=$(echo "$repoUri" | sed -E 's|^[a-zA-Z]+://([^:/]+).*|\1|')
                fi

                repoargs="-Name '$repoName' -Uri '$repoUri'"

                # Add priority if provided
                if [ -n "$repoPrio" ]; then
                    if [[ "$repoPrio" =~ ^\d+$ ]] && [ "$repoPrio" -ge 0 ] && [ "$repoPrio" -le 100 ]; then
                        repoargs+=" -Priority $repoPrio"
                    else
                        echo "Invalid priority for '$repoName': $repoPrio"
                        exit 1
                    fi
                fi

                # Register repository
                echo "[root] Register-PSResourceRepository $repoargs"
                pwsh -NoProfile -Command "$prefs; Register-PSResourceRepository $repoargs"
                if [ -n "$_REMOTE_USER" ] && [ "$_REMOTE_USER" != 'root' ]; then
                    echo "[$_REMOTE_USER] Register-PSResourceRepository $repoargs"
                    su "$_REMOTE_USER" /bin/bash -c "pwsh -NoProfile -Command \"$prefs; Register-PSResourceRepository $repoargs\""
                fi

                # Add to list of repositories
                repos+=("$repoUri")
                echo "Registered repository: $repoName"
            else
                echo "Repository already registered: $repoName"
            fi
        fi

        # If provided, add repository name to args
        if [ -n "$repoName" ]; then
            args+=" -Repository '$repoName'"
        fi

        # Install the resource
        echo "---------------------------"
        echo "| Installing $resourceName"
        echo "---------------------------"
        echo "Repository Name: $repoName"
        echo "Repository URI: $repoUri"
        echo "Repository Priority: $repoPrio"
        echo "Resource Name: $resourceName"
        echo "Version: $version - Prerelease: $prerelease"
        echo "Version Range Start: $versionStart - Prerelease: $prereleaseStart"
        echo "Version Range End: $versionEnd - Prerelease: $prereleaseEnd"
        echo "---------------------------"
        echo ""

        echo "Install-PSResource $args"
        pwsh -NoProfile -Command "$prefs; Install-PSResource -Verbose $args"
    done
fi

# If PSReadLine update is requested, check and update
if [ -n "$POWERSHELL_UPDATE_PSREADLINE" ]; then
    prerelease=""
    if [ "$POWERSHELL_UPDATE_PSREADLINE" = 'prerelease' ]; then
        prerelease="-Prerelease"
    fi

    currentVersion=$(pwsh -NoProfile -Command "(Get-Module -ListAvailable -Name PSReadLine).Version.ToString()")
    latestVersion=$(pwsh -NoProfile -Command "(Find-PSResource -Name PSReadLine -Repository PSGallery -Type Module $prerelease | Sort-Object -Property {[version]\$_.Version} -Descending | Select-Object -First 1).Version.ToString()")
    if version_compare "$latestVersion" 'gt' "$currentVersion"; then
        echo "Updating PSReadLine"
        pwsh -NoProfile -Command "$prefs; Install-PSResource -Verbose -Repository PSGallery -TrustRepository -Scope AllUsers -Name PSReadLine $prerelease"
    fi
fi

# If URL for PowerShell profile is provided, download it to '/opt/microsoft/powershell/7/profile.ps1'
if [ "$POWERSHELL_PROFILE_URL" != '' ]; then
    # Get profile path from currently installed pwsh
    profilePath=$(pwsh -NoProfile -Command "\$PROFILE.AllUsersAllHosts")

    # If file is not existing yet, download it
    if [ ! -f "$profilePath" ]; then
        echo "Downloading PowerShell Profile from: $POWERSHELL_PROFILE_URL"
        curl -sSL -o "$profilePath" "$POWERSHELL_PROFILE_URL"
    else
        echo "PowerShell Profile already exists at: $profilePath"
    fi
fi

# Clean up
apt-get clean -y
rm -rf /var/lib/apt/lists/*

echo "Done!"
