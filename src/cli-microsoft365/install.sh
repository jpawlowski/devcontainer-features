#!/bin/bash

export NVM_DIR="${NVMINSTALLPATH:-"/usr/local/share/nvm"}"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
CLI_VERSION="${VERSION:-"latest"}"
COMMAND_COMPLETION="${COMMANDCOMPLETION:-"true"}"
COMMAND_COMPLETIONPS="${COMMANDCOMPLETIONPS:-"true"}"

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
. /etc/os-release
# Get an adjusted ID independent of distro variants
MAJOR_VERSION_ID=$(echo ${VERSION_ID} | cut -d . -f 1)
if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
    ADJUSTED_ID="debian"
elif [[ "${ID}" = "rhel" || "${ID}" = "fedora" || "${ID}" = "mariner" || "${ID_LIKE}" = *"rhel"* || "${ID_LIKE}" = *"fedora"* || "${ID_LIKE}" = *"mariner"* ]]; then
    ADJUSTED_ID="rhel"
    if [[ "${ID}" = "rhel" ]] || [[ "${ID}" = *"alma"* ]] || [[ "${ID}" = *"rocky"* ]]; then
        VERSION_CODENAME="rhel${MAJOR_VERSION_ID}"
    else
        VERSION_CODENAME="${ID}${MAJOR_VERSION_ID}"
    fi
else
    echo "Linux distro ${ID} not supported."
    exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" >/etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

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

# Install m365-cli
umask 0002
if bash -c ". '${NVM_DIR}/nvm.sh' && type npm >/dev/null 2>&1"; then
    if ! bash -c ". '${NVM_DIR}/nvm.sh' && type m365 >/dev/null 2>&1"; then
        . "${NVM_DIR}/nvm.sh"
        [ ! -z "$http_proxy" ] && npm set proxy="$http_proxy"
        [ ! -z "$https_proxy" ] && npm set https-proxy="$https_proxy"
        [ ! -z "$no_proxy" ] && npm set noproxy="$no_proxy"
        npm install -g @pnp/cli-microsoft365@${CLI_VERSION}
        npm cache clean --force

        # Install command completion in Bash and Zsh
        if [ "${COMMAND_COMPLETION}" = "true" ]; then
            echo "Installing shell completion"
            case $ADJUSTED_ID in
            debian)
                apt-get update
                export DEBIAN_FRONTEND=noninteractive
                apt-get install --no-install-recommends -y bash-completion
                apt-get clean -y
                rm -rf /var/lib/apt/lists/*
                ;;
            rhel)
                yum install -y bash-completion
                yum clean all
                ;;
            esac

            su "${USERNAME}" bash -c ". '${NVM_DIR}/nvm.sh' && m365 cli completion sh setup"
            echo "Bash command completion activated"

            if type zsh >/dev/null 2>&1; then
                su "${USERNAME}" zsh -c ". '${NVM_DIR}/nvm.sh' && m365 cli completion sh setup"
                echo "Zsh command completion activated"
            fi

            if type fish >/dev/null 2>&1; then
                su "${USERNAME}" fish -c ". '${NVM_DIR}/nvm.sh' && m365 cli completion sh setup"
                echo "Fish command completion activated"
            fi
        fi

        # Enable PowerShell command completion
        if [ "${COMMAND_COMPLETIONPS}" = "true" ]; then
            # Find the path of pwsh if it exists in the PATH
            set +e
            pwsh_path=$(command -v pwsh)
            set -e

            if [ -z "$pwsh_path" ]; then
                echo "PowerShell is not installed. Skipping PowerShell completion setup."
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
                chmod 755 "$real_path"
                echo "Execution bit set for $real_path"

                # Install cli completion
                . "${NVM_DIR}/nvm.sh"
                pwsh -Command 'm365 cli completion pwsh setup --profile $PROFILE.AllUsersAllHosts'
                pwsh -Command 'Add-Content -Path $PROFILE.AllUsersAllHosts -Value "`nSet-Alias -Name m365? -Value m365_chili"'
                echo "PowerShell command completion activated"
            fi
        fi
    else
        echo "m365-cli is already installed. Skipping installation."
    fi
else
    echo "ERROR: NPM is not installed. Please install NPM and try again."
    exit 1
fi

echo "Done!"
