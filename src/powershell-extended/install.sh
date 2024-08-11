#!/bin/bash

# Original version from: https://github.com/devcontainers/features/blob/main/src/powershell/

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# load common functions
# shellcheck source=/dev/null
source "$(dirname "$0")/lib.sh" # Input variables are exported from here
export POWERSHELL_TELEMETRY_OPTOUT=1
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
FEATURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Clean up
rm -rf /var/lib/apt/lists/*

# Define PowerShell preferences
prefs="\$ProgressPreference='SilentlyContinue'; \$InformationPreference='Continue'; \$VerbosePreference='SilentlyContinue'; \$ConfirmPreference='None'; \$ErrorActionPreference='Stop';"

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "${CURRENT_USER}" >/dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u "${USERNAME}" >/dev/null 2>&1; then
    USERNAME=root
fi

# Install PowerShell if not already installed
if ! command -v pwsh >/dev/null 2>&1; then
    # Ensure that login shells get the correct path if the user updated the PATH using ENV.
    rm -f /etc/profile.d/00-restore-env.sh
    echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" >/etc/profile.d/00-restore-env.sh
    chmod +x /etc/profile.d/00-restore-env.sh

    # Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
    . /etc/os-release
    # Get an adjusted ID independent of distro variants
    if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
        ADJUSTED_ID="debian"
    # elif [[ "${ID}" = "rhel" || "${ID}" = "fedora" || "${ID}" = "mariner" || "${ID_LIKE}" = *"rhel"* || "${ID_LIKE}" = *"fedora"* || "${ID_LIKE}" = *"mariner"* ]]; then
    #     ADJUSTED_ID="rhel"
    #     VERSION_CODENAME="${ID}${VERSION_ID}"
    # elif [ "${ID}" = "alpine" ]; then
    #     ADJUSTED_ID="alpine"
    else
        echo "Linux distro ${ID} not supported."
        exit 1
    fi

    # if [ "${ADJUSTED_ID}" = "rhel" ] && [ "${VERSION_CODENAME-}" = "centos7" ]; then
    #     # As of 1 July 2024, mirrorlist.centos.org no longer exists.
    #     # Update the repo files to reference vault.centos.org.
    #     sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo
    #     sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo
    #     sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo
    # fi

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

    # Wait for PSModuleAnalysisCachePath to be created
    # Also avoids issues where the PSGallery repository cannot be found (yet)
    pwsh \
        -NoLogo \
        -NoProfile \
        -Command " \
            \$ErrorActionPreference = 'Stop' ; \
            \$ProgressPreference = 'SilentlyContinue' ; \
            while(!(Test-Path -Path \$env:PSModuleAnalysisCachePath)) {  \
                Write-Host "Waiting for \$env:PSModuleAnalysisCachePath" ; \
                Start-Sleep -Seconds 6 ; \
            }"

    if [ "$POWERSHELL_UPDATE_PSRESOURCEGET" != 'none' ]; then
        if [ "$POWERSHELL_VERSION" = 'latest' ] || ! version_compare "$POWERSHELL_VERSION" 'ge' '7.4.0'; then
            # Update Microsoft.PowerShell.PSResourceGet
            prerelease=""
            if [ "$POWERSHELL_UPDATE_PSRESOURCEGET" = 'prerelease' ]; then
                prerelease="-Prerelease"
            fi
            currentVersion=$("$(command -v pwsh)" -NoLogo -NoProfile -Command "(Get-Module -ListAvailable -Name Microsoft.PowerShell.PSResourceGet).Version.ToString()")
            latestVersion=$("$(command -v pwsh)" -NoLogo -NoProfile -Command "(Find-PSResource -Name Microsoft.PowerShell.PSResourceGet -Repository PSGallery -Type Module $prerelease | Sort-Object -Property {[version]\$_.Version} -Descending | Select-Object -First 1).Version.ToString()")
            if version_compare "$latestVersion" 'gt' "$currentVersion"; then
                echo "Updating Microsoft.PowerShell.PSResourceGet"
                "$(command -v pwsh)" -NoLogo -NoProfile -Command "$prefs; Install-PSResource -Verbose -Repository PSGallery -TrustRepository -Scope AllUsers -Name Microsoft.PowerShell.PSResourceGet $prerelease"
            fi
        else
            # Installing Microsoft.PowerShell.PSResourceGet
            prerelease=""
            if [ "$POWERSHELL_UPDATE_PSRESOURCEGET" = 'prerelease' ]; then
                prerelease="-AllowPrerelease"
            fi
            echo "Installing Microsoft.PowerShell.PSResourceGet"
            "$(command -v pwsh)" -NoLogo -NoProfile -Command "$prefs; Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; Install-Module -Verbose -Repository PSGallery -Scope AllUsers -Name Microsoft.PowerShell.PSResourceGet -Force -AllowClobber $prerelease; Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted"
        fi
    fi

    # If default shell is requested, set it
    if [ "$POWERSHELL_ROOT_DEFAULT_SHELL" = 'true' ]; then
        echo "[root] Set default shell to pwsh"
        chsh --shell "$(command -v pwsh)"
    fi
    if [ "$POWERSHELL_USER_DEFAULT_SHELL" = 'true' ] && [ "${USERNAME}" != 'root' ]; then
        echo "[${USERNAME}] Set default shell to pwsh"
        chsh --shell "$(command -v pwsh)" "${USERNAME}"
    fi
else
    echo "PowerShell is already installed."
fi

# Get existing repositories
IFS=';' read -r -a repos <<<"$("$(command -v pwsh)" -NoLogo -NoProfile -Command "(Get-PSResourceRepository).Uri.OriginalString -join ';'")"

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
                "$(command -v pwsh)" -NoLogo -NoProfile -Command "$prefs; Set-PSResourceRepository -Name PSGallery -Trusted"
                if [ "${USERNAME}" != 'root' ]; then
                    echo "[${USERNAME}] Set PSGallery as trusted repository"
                    sudo -H -u "${USERNAME}" "$(command -v pwsh)" -NoLogo -NoProfile -Command "$prefs; Set-PSResourceRepository -Name PSGallery -Trusted"
                fi

            elif [[ "$repoPrio" =~ ^[0-9]+$ ]] && [ "$repoPrio" -ge 0 ] && [ "$repoPrio" -le 100 ]; then
                # Update priority and set to trusted
                echo "[root] Set PSGallery as trusted repository and update priority to '$repoPrio'"
                "$(command -v pwsh)" -NoLogo -NoProfile -Command "$prefs; Set-PSResourceRepository -Name PSGallery -Trusted -Priority $repoPrio"
                if [ "${USERNAME}" != 'root' ]; then
                    echo "[${USERNAME}] Set PSGallery as trusted repository and update priority to '$repoPrio'"
                    sudo -H -u "${USERNAME}" "$(command -v pwsh)" -NoLogo -NoProfile -Command "$prefs; Set-PSResourceRepository -Name PSGallery -Trusted -Priority $repoPrio"
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
            "$(command -v pwsh)" -NoLogo -NoProfile -Command "$prefs; Register-PSResourceRepository $repoargs"
            if [ "${USERNAME}" != 'root' ]; then
                echo "[${USERNAME}] Register-PSResourceRepository $repoargs"
                sudo -H -u "${USERNAME}" "$(command -v pwsh)" -NoLogo -NoProfile -Command "$prefs; Register-PSResourceRepository $repoargs"
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
                "$(command -v pwsh)" -NoLogo -NoProfile -Command "$prefs; Register-PSResourceRepository $repoargs"
                if [ "${USERNAME}" != 'root' ]; then
                    echo "[${USERNAME}] Register-PSResourceRepository $repoargs"
                    sudo -H -u "${USERNAME}" "$(command -v pwsh)" -NoLogo -NoProfile -Command "$prefs; Register-PSResourceRepository $repoargs"
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
        "$(command -v pwsh)" -NoLogo -NoProfile -Command "$prefs; Install-PSResource -Verbose $args"
    done
fi

# If PSReadLine update is requested, check and update
if [ -n "$POWERSHELL_UPDATE_PSREADLINE" ]; then
    prerelease=""
    if [ "$POWERSHELL_UPDATE_PSREADLINE" = 'prerelease' ]; then
        prerelease="-Prerelease"
    fi

    currentVersion=$("$(command -v pwsh)" -NoLogo -NoProfile -Command "(Get-Module -ListAvailable -Name PSReadLine).Version.ToString()")
    latestVersion=$("$(command -v pwsh)" -NoLogo -NoProfile -Command "(Find-PSResource -Name PSReadLine -Repository PSGallery -Type Module $prerelease | Sort-Object -Property {[version]\$_.Version} -Descending | Select-Object -First 1).Version.ToString()")
    if version_compare "$latestVersion" 'gt' "$currentVersion"; then
        echo "Updating PSReadLine"
        "$(command -v pwsh)" -NoLogo -NoProfile -Command "$prefs; Install-PSResource -Verbose -Repository PSGallery -TrustRepository -Scope AllUsers -Name PSReadLine $prerelease"
    fi
fi

# Update Help Files
if [ "$POWERSHELL_UPDATE_MODULESHELP" = 'true' ]; then
    echo "Updating PowerShell Modules Help"
    if [ "${USERNAME}" = 'root' ]; then
        "$(command -v pwsh)" -NoLogo -NoProfile -Command "$prefs; Update-Help -Scope AllUsers -UICulture en-US -ErrorAction Stop"
        touch "/root/.local/powershell/Update-Help.lock"
    else
        # shellcheck disable=SC2140
        sudo -H -u "${USERNAME}" "$(command -v pwsh)" -NoLogo -NoProfile -Command "$prefs; Update-Help -Scope CurrentUser -UICulture en-US -ErrorAction Stop; New-Item -Path "\$env:HOME/.local/powershell/Update-Help.lock" -ItemType File -Force"
    fi
fi

# Get profile path from currently installed pwsh
globalProfilePath=$("$(command -v pwsh)" -NoLogo -NoProfile -Command "\$PROFILE.AllUsersAllHosts")

# If URL for PowerShell profile is provided, download it to '/opt/microsoft/powershell/7/profile.ps1'
if [ "$POWERSHELL_PROFILE_URL" != '' ]; then
    # If file is not existing yet, download it
    if [ ! -f "$globalProfilePath" ]; then
        echo "Downloading PowerShell Profile from: $POWERSHELL_PROFILE_URL"
        curl -sSL -o "$globalProfilePath" "$POWERSHELL_PROFILE_URL"
    else
        echo "PowerShell Profile already exists at: $globalProfilePath"
    fi
fi

# Install global default profile if it does not exist
if [ ! -f "$globalProfilePath" ]; then
    echo "Installing global default profile"
    cp "${FEATURE_DIR}/PROFILE.AllUsersAllHosts.ps1" "$globalProfilePath"
    globalProfileFunctionsPath="${globalProfilePath%.*}.functions.ps1"
    cp "${FEATURE_DIR}/PROFILE.Functions.ps1" "$globalProfileFunctionsPath"
fi

# If Oh My Posh installation is requested, install it
if [ "$INSTALL_OHMYPOSH" = 'true' ]; then
    group_name=$(id -gn "${USERNAME}")
    if [ "${USERNAME}" = "root" ]; then
        user_home="/root"
    # Check if user already has a home directory other than /home/${USERNAME}
    elif [ "/home/${USERNAME}" != "$(getent passwd "${USERNAME}" | cut -d: -f6)" ]; then
        user_home=$(getent passwd "${USERNAME}" | cut -d: -f6)
    else
        user_home="/home/${USERNAME}"
        if [ ! -d "${user_home}" ]; then
            mkdir -p "${user_home}"
            chown "${USERNAME}":"${group_name}" "${user_home}"
        fi
    fi

    root_local_dir="/root/.local"
    root_local_bin_dir="${root_local_dir}/bin"
    user_local_dir="${user_home}/.local"
    user_local_bin_dir="${user_local_dir}/bin"

    if ! command -v oh-my-posh >/dev/null 2>&1; then
        echo "Installing Oh My Posh"
        mkdir -p "$root_local_bin_dir"
        curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$root_local_bin_dir"

        # Install for non-root user if specified
        if [ "${USERNAME}" != 'root' ] && [ ! -e "${user_local_bin_dir}/oh-my-posh" ]; then
            sudo -H -u "${USERNAME}" mkdir -p "$user_local_bin_dir"
            sudo -H -u "${USERNAME}" curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$user_local_bin_dir"
        fi
    else
        echo "Oh My Posh is already installed."
    fi

    if [ "$INSTALL_OHMYPOSH_CONFIG" = 'true' ]; then
        install_oh_my_posh_config() {
            local target_home=$1
            local target_user=$2
            local target_group=$3

            echo "Installing Oh My Posh configuration for $target_user"
            shopt -s dotglob
            find "${FEATURE_DIR}/dotfiles" -type f | while read -r file; do
                # Get the relative path of the file
                relative_path="${file#"${FEATURE_DIR}/dotfiles/"}"
                user_file="${target_home}/${relative_path}"
                user_dir=$(dirname "$user_file")

                # Create the directory structure if it does not exist
                if [ ! -d "$user_dir" ]; then
                    echo "Creating directory $user_dir"
                    mkdir -p "$user_dir"
                fi

                # Copy the file if it does not exist
                if [ ! -f "$user_file" ]; then
                    echo "Copying $relative_path to $user_file"
                    cp "$file" "$user_file"
                else
                    echo "$relative_path already exists at $user_file"
                fi
            done
            chown --recursive "${target_user}":"${target_group}" "${target_home}"
            shopt -u dotglob
        }

        install_oh_my_posh_config "/root" "root" "root"

        # Run for non-root user if specified
        if [ "${USERNAME}" != 'root' ]; then
            install_oh_my_posh_config "${user_home}" "${USERNAME}" "${group_name}"
        fi
    fi
fi

# Clean up
apt-get clean -y
rm -rf /var/lib/apt/lists/* /root/.cache

echo "Done!"
