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
    __PSProfile-Initialize-Profile
    __PSProfile-Write-ProfileLoadMessage "📝 Applying configurations for $($PSStyle.Bold)PowerShell Extension$($PSStyle.BoldOff)." -ForegroundColor DarkCyan

    #region Import Modules =====================================================
    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_VSCODE_TERMINAL_COMPLETION_GIT') -eq $true) { __PSProfile-Import-ModuleAndInstallIfMissing -Name posh-git }
    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_VSCODE_TERMINAL_COMPLETION_PSFZF') -eq $true -and $null -ne (Get-Command -Name fzf -CommandType Application -ErrorAction Ignore)) { __PSProfile-Import-ModuleAndInstallIfMissing -Name PSFzf }
    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_VSCODE_TERMINAL_COMPLETION_PREDICTOR') -eq $true) { __PSProfile-Import-ModuleAndInstallIfMissing -Name CompletionPredictor }
    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_VSCODE_TERMINAL_COMPLETION_PREDICTOR_AZ') -eq $true) { if (Get-Module -Name Az.Accounts -ListAvailable) { __PSProfile-Import-ModuleAndInstallIfMissing -Name Az.Tools.Predictor } }
    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_VSCODE_TERMINAL_Z') -eq $true) { __PSProfile-Import-ModuleAndInstallIfMissing -Name z }
    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_VSCODE_TERMINAL_ICONS') -eq $true) { __PSProfile-Import-ModuleAndInstallIfMissing -Name Terminal-Icons }
    #endregion Import Modules --------------------------------------------------

    #region PSReadLine Predictor plugins =======================================
    $__PSProfilePSReadLineOptions = @{}
    $__PSProfileEnvPSReadlinePredictionSource = [System.Environment]::GetEnvironmentVariable('PSPROFILE_VSCODE_PSREADLINE_PREDICTION_SOURCE')
    $__PSProfileEnvPSReadlinePredictionViewStyle = [System.Environment]::GetEnvironmentVariable('PSPROFILE_VSCODE_PSREADLINE_PREDICTION_VIEWSTYLE')
    if ($null -ne $__PSProfileEnvPSReadlinePredictionSource) { $__PSProfilePSReadLineOptions.PredictionSource = $__PSProfileEnvPSReadlinePredictionSource }
    if ($null -ne $__PSProfileEnvPSReadlinePredictionViewStyle) { $__PSProfilePSReadLineOptions.PredictionViewStyle = $__PSProfileEnvPSReadlinePredictionViewStyle }
    if ($__PSProfilePSReadLineOptions.Count -gt 0) { Set-PSReadLineOption @__PSProfilePSReadLineOptions }
    #endregion PSReadLine ------------------------------------------------------

    #region Environment ========================================================
    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_VSCODE_AUTOUPDATE_MODULEHELP') -eq $true) { __PSProfile-Update-Help }
    #endregion Environment -----------------------------------------------------

    #region Oh My Posh =========================================================
    $__PSProfileEnvOhMyPoshDisableUpgradeNotice = [System.Environment]::GetEnvironmentVariable('PSPROFILE_POSH_DISABLE_UPGRADE_NOTICE')
    $__PSProfileEnvOhMyPoshTheme = [System.Environment]::GetEnvironmentVariable('PSPROFILE_VSCODE_POSH_THEME')
    if ($null -eq $__PSProfileEnvOhMyPoshDisableUpgradeNotice -or $__PSProfileEnvOhMyPoshDisableUpgradeNotice -eq $true) { __PSProfile-Set-OhMyPosh-UpdateNotice -Disable }
    if ($null -ne $__PSProfileEnvOhMyPoshTheme) { __PSProfile-Enable-OhMyPosh-Theme -ThemeName $__PSProfileEnvOhMyPoshTheme } else { __PSProfile-Enable-OhMyPosh-Theme }
    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_VSCODE_TERMINAL_COMPLETION_POSH') -eq $true -and $null -ne [System.Environment]::GetEnvironmentVariable('POSH_PID')) { oh-my-posh completion powershell | Out-String | Invoke-Expression }
    #endregion Oh My Posh ------------------------------------------------------

    #region Custom Profile =====================================================
    #
    # Hint:
    # To load your own custom profile, you may create a directory named 'Microsoft.VSCode_profile.d' in the same directory as this file.
    # Then, place your custom profile files in the 'Microsoft.VSCode_profile.d' directory to load them automatically.
    #
    $__PSProfileDirectoryPath = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, '.d')
    if ([System.IO.Directory]::Exists($__PSProfileDirectoryPath)) {
        foreach ($file in [System.Array]::Sort( [System.IO.Directory]::GetFiles($__PSProfileDirectoryPath, '*.ps1') )) {
            . $file
        }
    }
    #endregion Custom Profile --------------------------------------------------
}
catch {
    __PSProfile-Write-ProfileLoadMessage "`n❌ Interrupting profile load process.`n" -ForegroundColor DarkRed
    Write-Error "An error occurred while loading the user profile." -ErrorAction Continue
    throw
}
finally {
    __PSProfile-Clear-Environment
}
