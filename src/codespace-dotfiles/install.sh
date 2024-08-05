#!/bin/bash

set -e

# Ensure that the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

if [ -f /workspaces/.codespaces/shared/.env ]; then
    # shellcheck disable=SC1091
    source /workspaces/.codespaces/shared/.env
fi

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
USERHOME="${USERHOME:-"${_REMOTE_USER_HOME:-"automatic"}"}"
DOTFILES_REPOSITORY="${REPOSITORY:-""}"
TARGET_PATH="${TARGETPATH:-"~/dotfiles"}"
INSTALL_COMMAND="${INSTALLCOMMAND:-""}"
INSTALL_FALLBACK_METHOD="${INSTALLFALLBACKMETHOD:-"symlink"}"

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" >/etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    USERHOME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "${CURRENT_USER}" >/dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            USERHOME=$(su - "${USERNAME}" -c 'echo ${HOME}')
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        if [ -n "${_CONTAINER_USER}" ] && id -u "${_CONTAINER_USER}" >/dev/null 2>&1; then
            USERNAME="${_CONTAINER_USER}"
            USERHOME="${_CONTAINER_USER_HOME}"
        else
            USERNAME='root'
            USERHOME='/root'
        fi
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u "${USERNAME}" >/dev/null 2>&1; then
    if [ -n "${_CONTAINER_USER}" ] && id -u "${_CONTAINER_USER}" >/dev/null 2>&1; then
        USERNAME="${_CONTAINER_USER}"
        USERHOME="${_CONTAINER_USER_HOME}"
    else
        USERNAME='root'
        USERHOME='/root'
    fi
fi

generate_dummy_postStartCommand() {
    mkdir -p /usr/local/share/devcontainers/features/codespace-dotfiles
    cat > /usr/local/share/devcontainers/features/codespace-dotfiles/postStartOnce.sh << EOF
#!/bin/bash

# Dummy postStartCommand to comply with devcontainer.json
EOF
    chmod +x /usr/local/share/devcontainers/features/codespace-dotfiles/postStartOnce.sh
}

# If dotfiles are already installed by Codespaces, skip the installation
if [ -d "/workspaces/.codespaces/.persistedshare/dotfiles" ]; then
    echo "dotfiles already installed by GitHub Codespaces. Skipping custom installation."
    generate_dummy_postStartCommand
    exit 0
fi

if [ "${CODESPACES}" = 'true' ] || [ "${FORCE}" = 'true' ]; then # FORCE is only used for testing outside of Codespaces
    echo 'Running in GitHub Codespaces.'
    # Proceed with the installation
else
    echo 'Skipping codespace-dotfiles installation: This script is only meant to be run in GitHub Codespaces or during a Codespace prebuild in GitHub Actions. Use native devcontainer personalization instead.'
    generate_dummy_postStartCommand
    exit 0
fi

if [ -z "${DOTFILES_REPOSITORY}" ]; then
    echo "dotfiles Git repository must be provided."
    exit 1
fi

# If repo does not begin with https:// or git://, assume it is a GitHub repo
if [[ ! "${DOTFILES_REPOSITORY}" =~ ^https:// && ! "${DOTFILES_REPOSITORY}" =~ ^git:// ]]; then
    DOTFILES_REPOSITORY="https://github.com/${DOTFILES_REPOSITORY}"
fi
if [[ ! "${DOTFILES_REPOSITORY}" =~ \.git$ ]]; then
    DOTFILES_REPOSITORY="${DOTFILES_REPOSITORY}.git"
fi

# Expand TARGET_PATH if it starts with ~
if [[ "${TARGET_PATH}" == ~* ]]; then
    # shellcheck disable=SC2016
    TARGET_PATH="${USERHOME}${TARGET_PATH:1}"
fi

# Ensure that the target path is within the user's home directory
if [[ ! "${TARGET_PATH}" =~ ^${USERHOME} ]]; then
    echo "Target path must be within the user's home directory."
    exit 1
fi

# Ensure that the install command is in the root of the dotfiles repository
if [[ "${INSTALL_COMMAND}" == */* ]]; then
    echo "Install script ${INSTALL_COMMAND} must be in the root of the dotfiles repository."
    exit 1
fi

# Generate postStartCommand script to finalize dotfiles installation
mkdir -p /usr/local/share/devcontainers/features/codespace-dotfiles
cat > /usr/local/share/devcontainers/features/codespace-dotfiles/postStartOnce.sh << EOF
#!/bin/bash

# Install Codespace dotfiles in user context
# Generated $(date -u +"%Y-%m-%dT%H:%M:%SZ") by devcontainer-features/codespace-dotfiles/install.sh

set -e

# Static values
DOTFILES_REPOSITORY="${DOTFILES_REPOSITORY}"
TARGET_PATH="${TARGET_PATH}"
INSTALL_COMMAND="${INSTALL_COMMAND}"
INSTALL_FALLBACK_METHOD="${INSTALL_FALLBACK_METHOD}"
USERNAME="${USERNAME}"
USERHOME="${USERHOME}"

# Only run once
if [ -d "/workspaces/.codespaces/.persistedshare/dotfiles" ] || [ -f "\${USERHOME}/.local/share/devcontainers/features/codespace-dotfiles/installed" ]; then
    exit 0
fi

# If the target path already exists, throw an error
if [ -d "\${TARGET_PATH}" ]; then
    echo "codespace-dotfiles setup: Target path \${TARGET_PATH} already exists."
    exit 1
fi

# Clone the dotfiles repository
echo "Cloning dotfiles from \${DOTFILES_REPOSITORY} to '\${TARGET_PATH}' ..."
mkdir -p "\${TARGET_PATH}"
git clone "\${DOTFILES_REPOSITORY}" "\${TARGET_PATH}"

# Find install command if not provided
if [ -z "\${INSTALL_COMMAND}" ]; then
    POSSIBLE_COMMANDS=('install.sh' 'install' 'bootstrap.sh' 'bootstrap' 'setup.sh' 'setup')
    for COMMAND in "\${POSSIBLE_COMMANDS[@]}"; do
        if [ -f "\${TARGET_PATH}/\${COMMAND}" ]; then
            INSTALL_COMMAND="\${COMMAND}"
            break
        fi
    done
fi

# Run the install script
if [ -n "\${INSTALL_COMMAND}" ]; then
    if [ -f "\${TARGET_PATH}/\${INSTALL_COMMAND}" ]; then
        echo "Running dotfiles install script \${INSTALL_COMMAND} ..."
        cd "\${TARGET_PATH}"
        chmod +x \${INSTALL_COMMAND}
        ./\${INSTALL_COMMAND}
    else
        echo "Install script \${INSTALL_COMMAND} not found in dotfiles repository."
        exit 1
    fi
elif [ "\${INSTALL_FALLBACK_METHOD}" = "copy" ]; then
    echo "No install script found in dotfiles repository."
    echo "Copying dotfiles to home directory ..."
    shopt -s dotglob nullglob
    files=("\${TARGET_PATH}/.[^.]*")
    if [ \${#files[@]} -gt 0 ]; then
        cp -fav "\${files[@]}" ~/
    fi
    shopt -u dotglob nullglob
elif [ "\${INSTALL_FALLBACK_METHOD}" = "symlink" ]; then
    echo "No install script found in dotfiles repository."
    echo "Symlinking dotfiles to home directory ..."
    shopt -s dotglob nullglob
    files=("\${TARGET_PATH}/.[^.]*")
    if [ \${#files[@]} -gt 0 ]; then
        ln -sfnv "\${files[@]}" ~/
    fi
    shopt -u dotglob nullglob
else
    echo "No install script found in dotfiles repository."
    echo "No fallback method specified."
    exit 1
fi

# Mark codespace-dotfiles as installed
mkdir -p "\${USERHOME}/.local/share/devcontainers/features/codespace-dotfiles"
date -u +"%Y-%m-%dT%H:%M:%SZ" > "\${USERHOME}/.local/share/devcontainers/features/codespace-dotfiles/installed"
EOF

chmod +x /usr/local/share/devcontainers/features/codespace-dotfiles/postStartOnce.sh
echo "postCreateCommand generated at /usr/local/share/devcontainers/features/codespace-dotfiles/postStartOnce.sh to finalize dotfiles installation:"

echo ">>>>>>>>>>>>>>>> /usr/local/share/devcontainers/features/codespace-dotfiles/postStartOnce.sh >>>>>>>>>>>>>>"
cat /usr/local/share/devcontainers/features/codespace-dotfiles/postStartOnce.sh
echo "<<<<<<<<<<<<<<<< /usr/local/share/devcontainers/features/codespace-dotfiles/postStartOnce.sh <<<<<<<<<<<<<<"

echo "Done!"
