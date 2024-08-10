# /opt/microsoft/powershell/7/profile.ps1 - Source: https://github.com/jpawlowski/devcontainer-features/src/powershell-extended/PROFILE.AllUsersAllHosts.ps1
# This profile is executed by all PowerShell hosts (e.g., PowerShell console, VSCode Integrated Terminal) on startup for all users.
#
# Purpose:
# This file is intended for settings and configurations that should apply to all PowerShell hosts for all users.
# It should include non-visual configurations that are essential for all users. Visual configurations should typically be left to user-specific profiles.
#
# Non-visual configurations include:
# - Functions
# - Module imports
# - Aliases
# - Environment variables
# - PSReadLine configurations (e.g., key bindings, edit mode)
#   - Exception: PSReadLine predictor plugins and other shell completion modules should be placed in host-specific profiles to improve performance.
#
# Note:
# Non-visual configurations are settings that affect the behavior of PowerShell itself, regardless of the host.
# A "host" in this context refers to the application or interface where PowerShell commands are executed, such as the PowerShell console or the VSCode Integrated Terminal.
#
# Per-user profiles:
# - $PROFILE.CurrentUserAllHosts: ~/.config/powershell/profile.ps1
#   This profile is executed by all PowerShell hosts on startup for the current user.
#   It should include user-specific non-visual configurations and visual configurations.
# - $PROFILE.CurrentUserCurrentHost: ~/.config/powershell/Microsoft.VSCode_profile.ps1
#   This profile is executed by the VSCode Integrated Terminal on startup for the current user.
#   It should include user-specific visual configurations for the VSCode Integrated Terminal.
#
# Best Practices:
# - Global profiles should focus on essential non-visual configurations that apply to all users to avoid redundancy.
# - Visual configurations and user-specific settings should be placed in user-specific profiles to improve performance and customization.
# - Avoid duplicating settings in global and user-specific profiles to prevent unnecessary loading and potential conflicts.

#Requires -Version 7.0

try {
    if ($IsWindows) { return } # This global profile is for *nix only
    $__PSProfileConfirmPreference = $ConfirmPreference; $ConfirmPreference = 'None'
    $__PSProfileErrorActionPreference = $ErrorActionPreference; $ErrorActionPreference = 'Stop'

    #region Functions ==============================================================
    $__PSProfileFunctionsPath = Join-Path -Path ($PROFILE.AllUsersAllHosts | Split-Path -Parent) -ChildPath 'profile.functions.ps1'
    if ([System.IO.File]::Exists($__PSProfileFunctionsPath)) { . $__PSProfileFunctionsPath } else { throw "Profile functions file not found at $__PSProfileFunctionsPath" }
    #
    # Hint:
    # To load your own functions, you may put them into profile.my.functions.ps1 in
    # the same directory as this file. Note that you must define them explicitly into the global scope,
    # e.g., 'function Global:MyFunction { ... }'.
    #
    #endregion Functions -----------------------------------------------------------

    __PSProfile-Write-ProfileLoadMessage "🌐 Loading $($PSStyle.Bold)global$($PSStyle.BoldOff) profile."

    #region Global Variables =======================================================
    $Global:__PSProfileSource = "PSDocker-DevContainer-Feature"
    #endregion Global Variables ----------------------------------------------------

    #region Environment Variables ==================================================
    $__PSProfileOriginalPath = [Environment]::GetEnvironmentVariable('PATH')
    if ($__PSProfileOriginalPath.Split(':') -notcontains "$([Environment]::GetEnvironmentVariable('HOME'))/.local/bin") { [Environment]::SetEnvironmentVariable('PATH', "${__PSProfileOriginalPath}:$([Environment]::GetEnvironmentVariable('HOME'))/.local/bin") }
    if (-not [Environment]::GetEnvironmentVariable('USER') && -not [Environment]::GetEnvironmentVariable('USERNAME')) { [Environment]::SetEnvironmentVariable('USER', (& $(& which whoami))) }

    # Set the SHELL environment variable to a Unix native shell to avoid issues with VS Code userEnvProbe
    $__PSProfileUserEnvProbeShell = [Environment]::GetEnvironmentVariable('VSCODE_USER_ENVIRONMENT_PROBE_SHELL')
    if ($__PSProfileUserEnvProbeShell -and [Environment]::GetEnvironmentVariable('SHELL') -like '*/pwsh*' -and $__PSProfileUserEnvProbeShell -notlike '*/pwsh*') {
        if (
            -not ([System.IO.File]::Exists($__PSProfileUserEnvProbeShell)) -or
            -not ([System.IO.File]::ReadAllLines('/etc/shells') | Where-Object { $_ -eq $__PSProfileUserEnvProbeShell })
        ) {
            Write-Warning "The shell specified in the VSCODE_USER_ENVIRONMENT_PROBE_SHELL environment variable is not a valid shell. Falling back to /bin/bash."
            [Environment]::SetEnvironmentVariable('VSCODE_USER_ENVIRONMENT_PROBE_SHELL', '/bin/bash')
        }
        if ([Environment]::GetEnvironmentVariable('VSCODE_USER_ENVIRONMENT_PROBE_SHELL') -ne 'none') { [Environment]::SetEnvironmentVariable('SHELL', [Environment]::GetEnvironmentVariable('VSCODE_USER_ENVIRONMENT_PROBE_SHELL')) }
    }
    #endregion Environment Variables -----------------------------------------------

    #region Custom Profile =========================================================
    __PSProfile-Invoke-CustomProfileFilePath -FilePath $MyInvocation.MyCommand.Path -CustomSuffix 'my'
    #
    # Hint:
    # To load your own custom profile, you may put it into profile.my.ps1 in
    # the same directory as this file.
    #
    #endregion Custom Profile ------------------------------------------------------
}
catch {
    $__PSProfileError = "`n❌ Interrupting profile load process.`n"
    if (Get-Command -Name '__PSProfile-Write-ProfileLoadMessage' -ErrorAction Ignore) { __PSProfile-Write-ProfileLoadMessage $__PSProfileError -ForegroundColor DarkRed } else { Write-Host $__PSProfileError -ForegroundColor DarkRed }
    Write-Error "An error occurred while loading the global profile: $_" -ErrorAction Continue
    throw
}
finally {
    if (Get-Command -Name '__PSProfile-Clear-Environment' -ErrorAction Ignore) { __PSProfile-Clear-Environment }
}
