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

generate_dummy_postCreateCommand() {
    mkdir -p /usr/local/share/jpawlowski.codespace-dotfiles
    cat > /usr/local/share/jpawlowski.codespace-dotfiles/install.sh << EOF
#!/bin/bash

# Dummy postCreateCommand to comply with devcontainer.json
EOF
    chmod +x /usr/local/share/jpawlowski.codespace-dotfiles/install.sh
}

if [ ! "${FORCE}" = "true" ]; then
    # Only run in GitHub Codespaces or during a Codespace prebuild in GitHub Actions
    if [ ! "${CODESPACES}" = "true" ] && [ ! "${GITHUB_ACTIONS}" = "true" ]; then
        echo 'Skipping dotfiles installation: This script is only meant to be run in GitHub Codespaces or during a Codespace prebuild in GitHub Actions. Use native devcontainer personalization instead.'
        generate_dummy_postCreateCommand
        exit 0
    fi

    # Additional check for Codespace prebuild
    if [ "${GITHUB_ACTIONS}" = "true" ] && [ -n "${CODESPACE_NAME}" ]; then
        echo 'Detected Codespace prebuild in GitHub Actions.'
        # Proceed with the installation
    elif [ "${CODESPACES}" = "true" ]; then
        echo 'Running in GitHub Codespaces.'
        # Proceed with the installation
    else
        echo 'Skipping dotfiles installation: Not in a Codespace or Codespace prebuild.'
        generate_dummy_postCreateCommand
        exit 0
    fi

    # If dotfiles are already installed by Codespaces, skip the installation
    if [ -d "/workspaces/.codespaces/.persistedshare/dotfiles" ]; then
        echo "dotfiles already installed by GitHub Codespaces. Skipping custom installation."
        generate_dummy_postCreateCommand
        exit 0
    fi
fi

if [ -z "${REPO}" ]; then
    echo "dotfiles repository must be provided."
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

# Expand TARGET_PATH if it starts with ~
if [[ "${TARGET_PATH}" == ~* ]]; then
    # shellcheck disable=SC2016
    TARGET_PATH="$(su - "${USERNAME}" -c 'echo ${HOME}')${TARGET_PATH:1}"
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
    su - "${USERNAME}" -c "mkdir -p \"${TARGET_PATH}\" && git clone \"${REPO}\" \"${TARGET_PATH}\""
    ls -la "${TARGET_PATH}"

    if [[ "${INSTALL_COMMAND}" == */* ]]; then
        echo "Install script ${INSTALL_COMMAND} must be in the root of the dotfiles repository."
        exit 1
    fi

    # Generate postCreateCommand to finalize dotfiles installation
    mkdir -p /usr/local/share/jpawlowski.codespace-dotfiles
    cat > /usr/local/share/jpawlowski.codespace-dotfiles/install.sh << EOF
#!/bin/bash

set -e

# Static values
INSTALL_COMMAND="${INSTALL_COMMAND}"
TARGET_PATH="${TARGET_PATH}"
USERNAME="${USERNAME}"
USER_HOME=$(eval echo ~"\${USERNAME}")

if [ -f "\${USER_HOME}/.local/share/jpawlowski.codespace-dotfiles/installed" ]; then
    echo "dotfiles already installed on \$(cat \${USER_HOME}/.local/share/jpawlowski.codespace-dotfiles/installed)."
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
        cd \${TARGET_PATH}
        chmod +x \${INSTALL_COMMAND}
        ./\${INSTALL_COMMAND}
    else
        echo "Install script \${INSTALL_COMMAND} not found in dotfiles repository."
        exit 1
    fi
else
    echo "No install script found in dotfiles repository. Copying dotfiles to home directory ..."
    bash -c 'shopt -s dotglob nullglob; files=(\${TARGET_PATH}/.[^.]*); if [ \${#files[@]} -gt 0 ]; then cp -fav "\${files[@]}" ~/; fi'
fi

# Mark dotfiles as installed
mkdir -p "\${USER_HOME}/.local/share/jpawlowski.codespace-dotfiles"
date -u +"%Y-%m-%dT%H:%M:%SZ" > "\${USER_HOME}/.local/share/jpawlowski.codespace-dotfiles/installed"
EOF
    chmod +x /usr/local/share/jpawlowski.codespace-dotfiles/install.sh
    echo "postCreateCommand generated at /usr/local/share/jpawlowski.codespace-dotfiles/install.sh to finalize dotfiles installation:"

    echo ">>>>>>>>>>>>>>>> /usr/local/share/jpawlowski.codespace-dotfiles/install.sh >>>>>>>>>>>>>>"
    cat /usr/local/share/jpawlowski.codespace-dotfiles/install.sh
    echo "<<<<<<<<<<<<<<<< /usr/local/share/jpawlowski.codespace-dotfiles/install.sh <<<<<<<<<<<<<<"
else
    echo "dotfiles already installed at ${TARGET_PATH}."
fi

echo "Done!"
