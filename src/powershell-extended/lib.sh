#!/bin/bash

export POWERSHELL_VERSION=${VERSION:-"latest"}
export POWERSHELL_INSTALLATION_METHOD=${INSTALLATIONMETHOD:-"package"}
export POWERSHELL_RESOURCES="${RESOURCES:-""}"
export POWERSHELL_REPOSITORIES="${REPOSITORIES:-""}"
export POWERSHELL_UPDATE_PSRESOURCEGET=${UPDATEPSRESOURCEGET:-"release"}
export POWERSHELL_UPDATE_PSREADLINE=${UPDATEPSREADLINE:-"release"}
export POWERSHELL_PROFILE_URL="${PROFILEURLALLUSERSALLHOSTS}"

export MICROSOFT_GPG_KEYS_URI="https://packages.microsoft.com/keys/microsoft.asc"
export POWERSHELL_ARCHIVE_ARCHITECTURES="amd64 arm64"
export POWERSHELL_ARCHIVE_VERSION_CODENAMES="bionic focal bullseye jammy bookworm noble"
export GPG_KEY_SERVERS="keyserver hkp://keyserver.ubuntu.com
keyserver hkp://keyserver.ubuntu.com:80
keyserver hkps://keys.openpgp.org
keyserver hkp://keyserver.pgp.com"

# Figure out correct version if a three part version number is not passed
function find_version_from_git_tags() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    local last_part_optional=${5:-"false"}    
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local last_part
        if [ "${last_part_optional}" = "true" ]; then
            last_part="(${escaped_separator}[0-9]+)?"
        else
            last_part="${escaped_separator}[0-9]+"
        fi
        local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
        local version_list
        version_list="$(git ls-remote --tags "${repository}" | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            declare -g "${variable_name}"="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            declare -g "${variable_name}"="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
    fi
    if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" > /dev/null 2>&1; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        exit 1
    fi
    echo "${variable_name}=${!variable_name}"
}

function apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
function check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

function install_using_apt() {
    # Install dependencies
    check_packages apt-transport-https curl ca-certificates gnupg2 dirmngr
    # Import key safely (new 'signed-by' method rather than deprecated apt-key approach) and install
    curl -sSL ${MICROSOFT_GPG_KEYS_URI} | gpg --dearmor > /usr/share/keyrings/microsoft-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/microsoft-${ID}-${VERSION_CODENAME}-prod ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/microsoft.list

    # Update lists
    apt-get update -yq

    # Soft version matching for CLI
    if [ "${POWERSHELL_VERSION}" = "latest" ] || [ "${POWERSHELL_VERSION}" = "lts" ] || [ "${POWERSHELL_VERSION}" = "stable" ]; then
        # Empty, meaning grab whatever "latest" is in apt repo
        version_suffix=""
    else    
        version_suffix="=$(apt-cache madison powershell | awk -F"|" '{print $2}' | sed -e 's/^[ \t]*//' | grep -E -m 1 "^(${POWERSHELL_VERSION})(\.|$|\+.*|-.*)")"

        if [ -z "${version_suffix}" ] || [ "${version_suffix}" = '=' ]; then
            echo "Provided POWERSHELL_VERSION (${POWERSHELL_VERSION}) was not found in the apt-cache for this package+distribution combo";
            return 1
        fi
        echo "version_suffix ${version_suffix}"
    fi

    apt-get install -yq "powershell${version_suffix}" || return 1
}

# Use semver logic to decrement a version number then look for the closest match
function find_prev_version_from_git_tags() {
    local variable_name=$1
    local current_version=${!variable_name}
    local repository=$2
    # Normally a "v" is used before the version number, but support alternate cases
    local prefix=${3:-"tags/v"}
    # Some repositories use "_" instead of "." for version number part separation, support that
    local separator=${4:-"."}
    # Some tools release versions that omit the last digit (e.g. go)
    local last_part_optional=${5:-"false"}
    # Some repositories may have tags that include a suffix (e.g. actions/node-versions)
    # shellcheck disable=SC2034  # Unused variables left for readability
    local version_suffix_regex=$6
    # Try one break fix version number less if we get a failure. Use "set +e" since "set -e" can cause failures in valid scenarios.
    set +e
        major="$(echo "${current_version}" | grep -oE '^[0-9]+' || echo '')"
        minor="$(echo "${current_version}" | grep -oP '^[0-9]+\.\K[0-9]+' || echo '')"
        breakfix="$(echo "${current_version}" | grep -oP '^[0-9]+\.[0-9]+\.\K[0-9]+' 2>/dev/null || echo '')"

        if [ "${minor}" = "0" ] && [ "${breakfix}" = "0" ]; then
            ((major=major-1))
            declare -g "${variable_name}"="${major}"
            # Look for latest version from previous major release
            find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
        # Handle situations like Go's odd version pattern where "0" releases omit the last part
        elif [ "${breakfix}" = "" ] || [ "${breakfix}" = "0" ]; then
            ((minor=minor-1))
            declare -g "${variable_name}"="${major}.${minor}"
            # Look for latest version from previous minor release
            find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
        else
            ((breakfix=breakfix-1))
            if [ "${breakfix}" = "0" ] && [ "${last_part_optional}" = "true" ]; then
                declare -g "${variable_name}"="${major}.${minor}"
            else 
                declare -g "${variable_name}"="${major}.${minor}.${breakfix}"
            fi
        fi
    set -e
}

# Function to fetch the version released prior to the latest version
function get_previous_version() {
    local url=$1
    local repo_url=$2
    local variable_name=$3
    prev_version=${!variable_name}
    
    output=$(curl -s "$repo_url");
    check_packages jq
    message=$(echo "$output" | jq -r '.message')

    if [[ $message == "API rate limit exceeded"* ]]; then
        echo -e "\nAn attempt to find latest version using GitHub Api Failed... \nReason: ${message}"
        echo -e "\nAttempting to find latest version using GitHub tags."
        find_prev_version_from_git_tags prev_version "$url" "tags/v"
        declare -g "${variable_name}"="${prev_version}"
    else 
        echo -e "\nAttempting to find latest version using GitHub Api."
        version=$(echo "$output" | jq -r '.tag_name')
        declare -g "${variable_name}"="${version#v}"
    fi  
    echo "${variable_name}=${!variable_name}"
}

function get_github_api_repo_url() {
    local url=$1
    echo "${url/https:\/\/github.com/https:\/\/api.github.com\/repos}/releases/latest"
}


function install_prev_pwsh() {
    pwsh_url=$1
    repo_url=$(get_github_api_repo_url "$pwsh_url")
    echo -e "\n(!) Failed to fetch the latest artifacts for powershell v${POWERSHELL_VERSION}..."
    get_previous_version "$pwsh_url" "$repo_url" POWERSHELL_VERSION
    echo -e "\nAttempting to install v${POWERSHELL_VERSION}"
    install_pwsh "${POWERSHELL_VERSION}"
}

function install_pwsh() {
    POWERSHELL_VERSION=$1
    local architecture
    architecture="$(dpkg --print-architecture)"
    if [ "${architecture}" = "amd64" ]; then
        architecture="x64"
    fi
    powershell_filename="powershell-${POWERSHELL_VERSION}-linux-${architecture}.tar.gz"
    powershell_target_path="/opt/microsoft/powershell/$(echo "${POWERSHELL_VERSION}" | grep -oE '[^\.]+' | head -n 1)"
    mkdir -p /tmp/pwsh "${powershell_target_path}"
    cd /tmp/pwsh
    curl -sSL -o "${powershell_filename}" "https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/${powershell_filename}"
}

function install_using_github() {
    # Fall back on direct download if no apt package exists in microsoft pool
    check_packages curl ca-certificates gnupg2 dirmngr libc6 libgcc1 libgssapi-krb5-2 libstdc++6 libunwind8 libuuid1 zlib1g libicu[0-9][0-9]
    if ! type git > /dev/null 2>&1; then
        check_packages git
    fi
    pwsh_url="https://github.com/PowerShell/PowerShell"
    find_version_from_git_tags POWERSHELL_VERSION $pwsh_url
    install_pwsh "${POWERSHELL_VERSION}"
    if grep -q "Not Found" "${powershell_filename}"; then
        install_prev_pwsh $pwsh_url
    fi

    # Ugly - but only way to get sha256 is to parse release HTML. Remove newlines and tags, then look for filename followed by 64 hex characters.
    curl -sSL -o "release.html" "https://github.com/PowerShell/PowerShell/releases/tag/v${POWERSHELL_VERSION}"
    powershell_archive_sha256="$(tr '\n' ' ' < release.html | sed 's|<[^>]*>||g' | grep -oP "${powershell_filename}\s+\K[0-9a-fA-F]{64}" || echo '')"
    if [ -z "${powershell_archive_sha256}" ]; then
        echo "(!) WARNING: Failed to retrieve SHA256 for archive. Skipping validaiton."
    else
        echo "SHA256: ${powershell_archive_sha256}"
        echo "${powershell_archive_sha256} *${powershell_filename}" | sha256sum -c -
    fi
    tar xf "${powershell_filename}" -C "${powershell_target_path}"
    chmod +x "${powershell_target_path}/pwsh"
    ln -sf "${powershell_target_path}/pwsh" /usr/bin/pwsh
    add-shell "/usr/bin/pwsh"
    cd ~
    rm -rf /tmp/pwsh
}

function version_compare() {
    local comparison_type="$1"
    local version1="$2"
    local version2="$3"

    # Function to compare two versions
    compare_versions() {
        local v1="$1"
        local v2="$2"

        # Split versions into arrays
        IFS='.-' read -r -a v1_parts <<< "$v1"
        IFS='.-' read -r -a v2_parts <<< "$v2"

        # Compare each part
        for ((i=0; i<${#v1_parts[@]}; i++)); do
            if [[ -z "${v2_parts[i]}" ]]; then
                # If v2 part is missing, v1 is greater
                return 0
            fi

            if [[ "${v1_parts[i]}" =~ ^[0-9]+$ && "${v2_parts[i]}" =~ ^[0-9]+$ ]]; then
                # Numeric comparison
                if ((10#${v1_parts[i]} > 10#${v2_parts[i]})); then
                    return 0
                elif ((10#${v1_parts[i]} < 10#${v2_parts[i]})); then
                    return 1
                fi
            else
                # Lexical comparison
                if [[ "${v1_parts[i]}" > "${v2_parts[i]}" ]]; then
                    return 0
                elif [[ "${v1_parts[i]}" < "${v2_parts[i]}" ]]; then
                    return 1
                fi
            fi
        done

        # If we reach here, all parts are equal, so compare lengths
        if (( ${#v1_parts[@]} > ${#v2_parts[@]} )); then
            return 0
        elif (( ${#v1_parts[@]} < ${#v2_parts[@]} )); then
            return 1
        else
            return 0
        fi
    }

    # Compare the versions
    compare_versions "$version1" "$version2"
    local result=$?

    # Determine the final result based on comparison type
    if [[ "$comparison_type" == "ge" ]]; then
        return $result
    elif [[ "$comparison_type" == "gt" ]]; then
        if [[ $result -eq 0 ]]; then
            # If versions are equal, return false for "gt"
            return 1
        else
            return $result
        fi
    else
        echo "Invalid comparison type: $comparison_type"
        return 2
    fi
}
