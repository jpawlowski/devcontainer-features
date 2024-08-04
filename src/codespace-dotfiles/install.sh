#!/bin/bash

set -e

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
REPO="${REPOSITORY:-""}"
TARGET_PATH="${TARGETPATH:-"~/dotfiles"}"
INSTALL_COMMAND="${INSTALLCOMMAND:-""}"

# Ensure that the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Only run in GitHub Codespaces
if [ -z "${CODESPACES}" ]; then
    echo -e "\033[31mSkipping dotfiles installation: This script is only meant to be run in GitHub Codespaces. Use native devcontainer personalization instead.\033[0m"
    exit 0
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

if [ -z "${REPO}" ]; then
    echo "dotfiles repository must be provided."
    exit 1
fi

# If dotfiles are already installed by Codespaces, skip the installation
if [ -d "/workspaces/.codespaces/.persistedshare/dotfiles" ]; then
    echo "dotfiles already installed by GitHub Codespaces. Skipping custom installation."

    # Generate dummy postCreateCommand to finalize dotfiles installation
    mkdir -p /usr/local/share/jpawlowski.codespace-dotfiles
    tee /usr/local/share/jpawlowski.codespace-dotfiles/install.sh > /dev/null << EOF
#!/bin/bash

# Dummy postCreateCommand to avoid issues with Codespaces
EOF
    chmod +x /usr/local/share/jpawlowski.codespace-dotfiles/install.sh

    exit 0
fi

# If the target path already exists, skip the installation
if [ ! -d "${TARGET_PATH}" ]; then
    # If repo does not begin with https:// or git://, assume it is a GitHub repo
    if [[ ! "${REPO}" =~ ^https:// && ! "${REPO}" =~ ^git:// ]]; then
        REPO="https://github.com/${REPO}"
    fi
    if [[ ! "${REPO}" =~ \.git$ ]]; then
        REPO="${REPO}.git"
    fi

    echo "Cloning dotfiles from ${REPO} to ${TARGET_PATH} ..."
    mkdir -p ${TARGET_PATH}
    git clone ${REPO} ${TARGET_PATH}
    chown -R ${USERNAME}:${USERNAME} ${TARGET_PATH}

    if [[ "${INSTALL_COMMAND}" == */* ]]; then
        echo "Install script ${INSTALL_COMMAND} must be in the root of the dotfiles repository."
        exit 1
    fi

    # Generate postCreateCommand to finalize dotfiles installation
    mkdir -p /usr/local/share/jpawlowski.codespace-dotfiles
    tee /usr/local/share/jpawlowski.codespace-dotfiles/install.sh > /dev/null << EOF
#!/bin/bash

set -e

# Static values
INSTALL_COMMAND="${INSTALL_COMMAND}"
TARGET_PATH="${TARGET_PATH}"
USERNAME="${USERNAME}"

if [ -f "/usr/local/share/jpawlowski.codespace-dotfiles/installed" ]; then
    echo "dotfiles already installed on $(cat /usr/local/share/jpawlowski.codespace-dotfiles/installed)."
    exit 0
fi

# If dotfiles are already installed by Codespaces, skip the installation
if [ -d "/workspaces/.codespaces/.persistedshare/dotfiles" ]; then
    echo "dotfiles already installed by GitHub Codespaces. Skipping custom installation."
    rm -rf "\${TARGET_PATH}"
    exit 0
fi

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
        su -m "\${USERNAME}" bash -c "cd \${TARGET_PATH} && chmod +x \${INSTALL_COMMAND} && ./\${INSTALL_COMMAND}"
    else
        echo "Install script \${INSTALL_COMMAND} not found in dotfiles repository."
        exit 1
    fi
else
    echo "No install script found in dotfiles repository. Copying dotfiles to home directory ..."
    su "\${USERNAME}" bash -c 'shopt -s dotglob nullglob; files=(\${TARGET_PATH}/.[^.]*); if [ \${#files[@]} -gt 0 ]; then cp -fav "\${files[@]}" ~/; fi'
fi

# Mark dotfiles as installed
date -u +"%Y-%m-%dT%H:%M:%SZ" > /usr/local/share/jpawlowski.codespace-dotfiles/installed
EOF
    chmod +x /usr/local/share/jpawlowski.codespace-dotfiles/install.sh
    echo "postCreateCommand generated at /usr/local/share/jpawlowski.codespace-dotfiles/install.sh to finalize dotfiles installation."
else
    echo "dotfiles already installed at ${TARGET_PATH}."
fi

echo "Done!"
