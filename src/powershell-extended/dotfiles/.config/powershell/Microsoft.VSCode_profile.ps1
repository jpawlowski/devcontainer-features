# ~/.config/powershell/Microsoft.VSCode_profile.ps1 - Source: https://github.com/jpawlowski/devcontainer-features/src/powershell-extended/dotfiles/.config/powershell/Microsoft.VSCode_profile.ps1
# This profile is executed by the VSCode Integrated Terminal on startup.
#
# Purpose:
# This file is intended for settings and configurations that should apply only to the VSCode Integrated Terminal
# (also known as the terminal section of VSCode with the display name "PowerShell Extension").
# It should include visual configurations. Non-visual configurations should be placed in:
# - profile.ps1
#
# Note:
# This file is only executed by the VSCode Integrated Terminal, not the PowerShell console host.
# See Microsoft.PowerShell_profile.ps1 for settings that apply to the PowerShell console host.
#
# Visual configurations include:
# - Prompt customization
# - Themes (e.g., Oh My Posh themes)
# - Host-specific settings (e.g., settings specific to the VSCode Integrated Terminal)
# - Command line completion modules and PSReadLine predictor plugins (While not visual, these are included here to enhance the user experience in the VSCode Integrated Terminal)
#
# Performance Considerations:
# When adding command line completion modules or PSReadLine predictor plugins, ensure they do not degrade performance during profile load.
# This is crucial because when dev containers start and PowerShell is configured as the default shell for the user (not the VSCode settings),
# VSCode may report slow response times during the userEnvProbe process.
#
# About userEnvProbe:
# The userEnvProbe process is used by VSCode to gather environment variables and other shell settings during the startup of a dev container.
# This process occurs before any terminal is started and ensures that environment settings from devcontainer.json (such as remoteEnv) are correctly applied.
# It is important for this process to be quick to ensure a smooth startup experience for the dev container.
# Keeping the profile lightweight and efficient helps avoid performance issues during this probe.
#
# Note:
# Visual configurations are settings that affect the appearance of the VSCode Integrated Terminal.
# For an explanation of the difference between a PowerShell host and a terminal emulator, see profile.ps1.

#Requires -Version 7.2

try {
    if ($Error) { return } # Skip if there was an error loading the profile before

    #region Functions ==============================================================
    $__PSProfileFunctionsPath = Join-Path -Path ($PROFILE.AllUsersAllHosts | Split-Path -Parent) -ChildPath 'profile.functions.ps1'
    if ([System.IO.File]::Exists($__PSProfileFunctionsPath)) { . $__PSProfileFunctionsPath } else { throw "Profile functions file not found at $__PSProfileFunctionsPath" }
    #
    # Note:
    # To load your own functions, you may put them into Microsoft.VSCode_profile.functions.ps1 in
    # the same directory as this file. Note that you must define them explicitly into the global scope,
    # e.g., 'function Global:MyFunction { ... }'.
    #
    #endregion Functions -----------------------------------------------------------

    __PSProfile-Write-ProfileLoadMessage "📝 Applying configurations for $($PSStyle.Bold)PowerShell Extension$($PSStyle.BoldOff)." -ForegroundColor DarkCyan

    #region Import Modules =========================================================
    if ($env:VSCODE_TERMINAL_ICONS -eq $true) { __PSProfile-Import-ModuleAndInstallIfMissing -Name Terminal-Icons }
    if ($env:VSCODE_TERMINAL_COMPLETION_PREDICTOR -eq $true) { __PSProfile-Import-ModuleAndInstallIfMissing -Name CompletionPredictor }
    if ($env:VSCODE_TERMINAL_COMPLETION_PREDICTOR_AZ -eq $true) { if (Get-Module -Name Az.Accounts -ListAvailable) { __PSProfile-Import-ModuleAndInstallIfMissing -Name Az.Tools.Predictor } }
    if ($env:VSCODE_TERMINAL_COMPLETION_GIT -eq $true) { __PSProfile-Import-ModuleAndInstallIfMissing -Name posh-git }
    #endregion Import Modules ------------------------------------------------------

    #region Oh My Posh =============================================================
    if (-not ($env:POSH_THEME -eq $false)) {
        if ($env:VSCODE_POSH_THEME) { __PSProfile-Enable-OhMyPosh-Theme -ThemeName $env:VSCODE_POSH_THEME } else { __PSProfile-Enable-OhMyPosh-Theme }
        if ($env:VSCODE_TERMINAL_COMPLETION_POSH -eq $true -and $env:POSH_PID) { oh-my-posh completion powershell | Out-String | Invoke-Expression }
        if ($env:POSH_DISABLE_UPGRADE_NOTICE -eq $true -and $env:POSH_PID) { oh-my-posh disable notice }
    }
    #endregion Oh My Posh ----------------------------------------------------------

    #region Custom Profile =========================================================
    __PSProfile-Invoke-CustomProfileFilePath -FilePath $MyInvocation.MyCommand.Path -CustomSuffix 'my'
    #
    # Hint:
    # To load your own custom profile, you may put it into
    # Microsoft.VSCode_profile.my.ps1 in the same directory as this file.
    #
    #endregion Custom Profile ------------------------------------------------------
}
catch {
    $__PSProfileError = "`n❌ Interrupting profile load process.`n"
    if (Get-Command -Name '__PSProfile-Write-ProfileLoadMessage' -ErrorAction Ignore) { __PSProfile-Write-ProfileLoadMessage $__PSProfileError -ForegroundColor DarkRed } else { Write-Host $__PSProfileError -ForegroundColor DarkRed }
    Write-Error "An error occurred while loading the host profile: $_" -ErrorAction Continue
    throw
}
finally {
    if (Get-Command -Name '__PSProfile-Clear-Environment' -ErrorAction Ignore) { __PSProfile-Clear-Environment }
}
