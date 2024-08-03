#!/bin/bash

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
FONT_VERSION="${VERSION:-"latest"}"
INSTALL_FONTCONFIG="${INSTALLFONTCONFIG:-"true"}"
FONT_VARIABLE_TTF="${INSTALLVARIABLETTF:-"false"}"
FONT_VARIABLE_WOFF2="${INSTALLVARIABLEWOFF2:-"false"}"
FONT_STATIC_TTF="${INSTALLSTATICTTF:-"true"}"
FONT_STATIC_OTF="${INSTALLSTATICOTF:-"false"}"
FONT_STATIC_WOFF2="${INSTALLSTATICWOFF2:-"false"}"

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
# shellcheck source=/dev/null
. /etc/os-release
# Get an adjusted ID independent of distro variants
MAJOR_VERSION_ID=$(echo "${VERSION_ID}" | cut -d . -f 1)
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

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}
yum_update() {
    if [ "$(find /var/cache/yum/* | wc -l)" = "0" ]; then
        echo "Running yum update..."
        yum makecache fast
    fi
}
check_packages() {
    case $ADJUSTED_ID in
    debian)
        if ! dpkg -s "$@" > /dev/null 2>&1; then
            apt_get_update
            export DEBIAN_FRONTEND=noninteractive
            apt-get -y install --no-install-recommends "$@"
        fi
        ;;
    rhel)
        if ! rpm -q "$@" > /dev/null 2>&1; then
            yum_update
            yum -y install "$@"
        fi
        ;;
    esac
}

# Install required packages
check_packages ca-certificates curl jq unzip

# Install fontconfig if it is not already installed
if [ "${INSTALL_FONTCONFIG}" = "true" ]; then
    check_packages fontconfig
fi

# Install Cascadia Code
if [ "${USERNAME}" = "root" ]; then
    FONT_BASE_DIR="/usr/share/fonts/cascadia-code"
else
    FONT_BASE_DIR="/home/${USERNAME}/.local/share/fonts/cascadia-code"
fi
if [ ! -d "${FONT_BASE_DIR}" ]; then
    umask 0002
    mkdir -p "${FONT_BASE_DIR}"
    chown -R "${USERNAME}" "${FONT_BASE_DIR}"
    if [ "${FONT_VERSION}" = "latest" ]; then
        FONT_VERSION=$(curl -fsSL "https://api.github.com/repos/microsoft/cascadia-code/releases/latest" | jq -r '.tag_name')
    fi

    FONT_URL="https://github.com/microsoft/cascadia-code/releases/download/${FONT_VERSION}/CascadiaCode-${FONT_VERSION#v}.zip"
    curl -fsSL "${FONT_URL}" -o "/tmp/CascadiaCode-${FONT_VERSION}.zip"
    unzip -q "/tmp/CascadiaCode-${FONT_VERSION}.zip" -d "/tmp/CascadiaCode-${FONT_VERSION}"
    ls -la "/tmp/CascadiaCode-${FONT_VERSION}"

    if [ "${FONT_VARIABLE_TTF}" = "true" ]; then
        TTF_DIR="${FONT_BASE_DIR}/ttf"
        mkdir -p "${TTF_DIR}"
        chown "${USERNAME}" "${TTF_DIR}"
        find "/tmp/CascadiaCode-${FONT_VERSION}/ttf/" -name "*.ttf" -exec cp -fv {} "${TTF_DIR}" \;
        echo "Cascadia Code (Variable TTF) installed."
    fi

    if [ "${FONT_VARIABLE_WOFF2}" = "true" ]; then
        WOFF2_DIR="${FONT_BASE_DIR}/woff2"
        mkdir -p "${WOFF2_DIR}"
        chown "${USERNAME}" "${WOFF2_DIR}"
        find "/tmp/CascadiaCode-${FONT_VERSION}/woff2/" -name "*.woff2" -exec cp -fv {} "${WOFF2_DIR}" \;
        echo "Cascadia Code (Variable WOFF2) installed."
    fi

    if [ "${FONT_STATIC_TTF}" = "true" ]; then
        TTF_DIR="${FONT_BASE_DIR}/ttf/static"
        mkdir -p "${TTF_DIR}"
        chown "${USERNAME}" "${TTF_DIR}"
        find "/tmp/CascadiaCode-${FONT_VERSION}/ttf/static/" -name "*.ttf" -exec cp -fv {} "${TTF_DIR}" \;
        echo "Cascadia Code (Static TTF) installed."
    fi

    if [ "${FONT_STATIC_OTF}" = "true" ]; then
        OTF_DIR="${FONT_BASE_DIR}/otf/static"
        mkdir -p "${OTF_DIR}"
        chown "${USERNAME}" "${OTF_DIR}"
        find "/tmp/CascadiaCode-${FONT_VERSION}/otf/static/"*.otf -exec cp -fv {} "${OTF_DIR}" \;
        echo "Cascadia Code (Static OTF) installed."
    fi

    if [ "${FONT_STATIC_WOFF2}" = "true" ]; then
        WOFF2_DIR="${FONT_BASE_DIR}/woff2/static"
        mkdir -p "${WOFF2_DIR}"
        chown "${USERNAME}" "${WOFF2_DIR}"
        find "/tmp/CascadiaCode-${FONT_VERSION}/woff2/static/" -name "*.woff2" -exec cp -fv {} "${WOFF2_DIR}" \;
        echo "Cascadia Code (Static WOFF2) installed."
    fi

    # Cleanup
    rm -rf "/tmp/CascadiaCode-${FONT_VERSION}.zip" "/tmp/CascadiaCode-${FONT_VERSION}"

    # Update font cache
    if command -v fc-cache >/dev/null 2>&1; then
        if [ "${USERNAME}" = "root" ]; then
            fc-cache -v "${FONT_BASE_DIR}"
        else
            su "${USERNAME}" -c "fc-cache -v ${FONT_BASE_DIR}"
        fi
    fi
else
    echo "Cascadia Code is already installed."
fi

echo "Done!"
