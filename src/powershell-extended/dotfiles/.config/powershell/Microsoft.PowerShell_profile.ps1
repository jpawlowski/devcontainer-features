# ~/.config/powershell/Microsoft.PowerShell_profile.ps1 - Source: https://github.com/jpawlowski/devcontainer-features/src/powershell-extended/dotfiles/.config/powershell/Microsoft.PowerShell_profile.ps1
# This profile is executed by the PowerShell console host on startup.
#
# Purpose:
# This file is intended for settings and configurations that should apply only to the PowerShell console host.
# It should include visual configurations and other "nice-to-have" functionalities that enhance the user experience.
# Non-visual configurations should be placed in:
# - profile.ps1
#
# Note:
# This file is only executed by the PowerShell console host, not the VSCode Integrated Terminal.
# See Microsoft.VSCode_profile.ps1 for settings that apply to the VSCode Integrated Terminal.
#
# Visual configurations and "nice-to-have" functionalities include:
# - Prompt customization
# - Themes (e.g., Oh My Posh themes)
# - Host-specific settings (e.g., settings specific to the PowerShell console host)
# - Command line completion modules and PSReadLine predictor plugins (While not visual, these are included here to enhance the user experience in the PowerShell console host)
#
# Note:
# Visual configurations are settings that affect the appearance of the PowerShell console host.
# For an explanation of the difference between a PowerShell host and a terminal emulator, see profile.ps1.

#Requires -Version 7.2

try {
    if ($Error) { return } # Skip if there was an error loading the profile before
    __PSProfile-Initialize-Profile
    __PSProfile-Write-ProfileLoadMessage '💻 Applying shared configurations for all terminals.' -ForegroundColor DarkCyan

    #region Import Modules =====================================================
    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_TERMINAL_COMPLETION_GIT') -eq $true) { __PSProfile-Import-ModuleAndInstallIfMissing -Name posh-git }
    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_TERMINAL_COMPLETION_PSFZF') -eq $true -and $null -ne (Get-Command -Name fzf -CommandType Application -ErrorAction Ignore)) { __PSProfile-Import-ModuleAndInstallIfMissing -Name PSFzf }
    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_TERMINAL_COMPLETION_PREDICTOR') -eq $true) { __PSProfile-Import-ModuleAndInstallIfMissing -Name CompletionPredictor }
    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_TERMINAL_COMPLETION_PREDICTOR_AZ') -eq $true) { if (Get-Module -Name Az.Accounts -ListAvailable) { __PSProfile-Import-ModuleAndInstallIfMissing -Name Az.Tools.Predictor } }
    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_TERMINAL_Z') -eq $true) { __PSProfile-Import-ModuleAndInstallIfMissing -Name z }
    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_TERMINAL_ICONS') -eq $true) { __PSProfile-Import-ModuleAndInstallIfMissing -Name Terminal-Icons }
    #endregion Import Modules --------------------------------------------------

    #region PSReadLine predictor plugins =======================================
    $__PSProfilePSReadLineOptions = @{}
    $__PSProfileEnvPSReadlinePredictionSource = [System.Environment]::GetEnvironmentVariable('PSPROFILE_PSREADLINE_PREDICTION_SOURCE')
    $__PSProfileEnvPSReadlinePredictionViewStyle = [System.Environment]::GetEnvironmentVariable('PSPROFILE_PSREADLINE_PREDICTION_VIEWSTYLE')
    if ($null -ne $__PSProfileEnvPSReadlinePredictionSource) { $__PSProfilePSReadLineOptions.PredictionSource = $__PSProfileEnvPSReadlinePredictionSource }
    if ($null -ne $__PSProfileEnvPSReadlinePredictionViewStyle) { $__PSProfilePSReadLineOptions.PredictionViewStyle = $__PSProfileEnvPSReadlinePredictionViewStyle }
    if ($__PSProfilePSReadLineOptions.Count -gt 0) { Set-PSReadLineOption @__PSProfilePSReadLineOptions }
    #endregion PSReadLine ------------------------------------------------------

    #region Environment ========================================================
    $__PSProfileEnvAutoUpdateModuleHelp = [System.Environment]::GetEnvironmentVariable('PSPROFILE_AUTOUPDATE_MODULEHELP')
    if ($null -eq $__PSProfileEnvAutoUpdateModuleHelp -or $__PSProfileEnvAutoUpdateModuleHelp -eq $true) { __PSProfile-Update-Help }
    #endregion Environment -----------------------------------------------------

    #region Oh My Posh =========================================================
    $__PSProfileEnvOhMyPoshDisableUpgradeNotice = [System.Environment]::GetEnvironmentVariable('PSPROFILE_POSH_DISABLE_UPGRADE_NOTICE')
    $__PSProfileEnvOhMyPoshTheme = [System.Environment]::GetEnvironmentVariable('PSPROFILE_POSH_THEME')
    if ($null -eq $__PSProfileEnvOhMyPoshDisableUpgradeNotice -or $__PSProfileEnvOhMyPoshDisableUpgradeNotice -eq $true) { __PSProfile-Set-OhMyPosh-UpdateNotice -Disable }
    if ($null -ne $__PSProfileEnvOhMyPoshTheme) { __PSProfile-Enable-OhMyPosh-Theme -ThemeName $__PSProfileEnvOhMyPoshTheme } else { __PSProfile-Enable-OhMyPosh-Theme }
    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_TERMINAL_COMPLETION_POSH') -eq $true -and $null -ne [System.Environment]::GetEnvironmentVariable('POSH_PID')) { oh-my-posh completion powershell | Out-String | Invoke-Expression }
    #endregion Oh My Posh ------------------------------------------------------

    #region Custom Profile =====================================================
    #
    # Hint:
    # To load your own custom profile, you may create a directory named 'Microsoft.PowerShell_profile.d' in the same directory as this file.
    # Then, place your custom profile files in the 'Microsoft.PowerShell_profile.d' directory to load them automatically.
    #
    $__PSProfileDirectoryPath = [System.IO.Path]::ChangeExtension($MyInvocation.MyCommand.Path, 'd')
    if ([System.IO.Directory]::Exists($__PSProfileDirectoryPath)) {
        foreach ($file in [System.Array]::Sort( [System.IO.Directory]::GetFiles($__PSProfileDirectoryPath, '*.ps1') )) {
            . $file
        }
    }
    #endregion Custom Profile --------------------------------------------------

    #region Custom Terminal Configuration ======================================
    #
    # Hint:
    # To load your own custom terminal configuration, you may create a directory named
    # 'Microsoft.PowerShell_profile_<TERM_PROGRAM>.d' in the same directory as this file.
    # Then, place your custom terminal configuration files in the 'Microsoft.PowerShell_profile_<TERM_PROGRAM>.d'
    # directory to load them automatically.
    #
    # Examples:
    # If you are using the VSCode Integrated Terminal, create a directory named 'Microsoft.PowerShell_profile_vscode.d'
    # in the same directory as this file. Then, place your custom terminal configuration files in the
    # 'Microsoft.PowerShell_profile_vscode.d' directory to load them automatically.
    #
    # If you are using the tmux terminal multiplexer, create a directory named 'Microsoft.PowerShell_profile_tmux.d'
    # in the same directory as this file. Then, place your custom terminal configuration files in the
    # 'Microsoft.PowerShell_profile_tmux.d' directory to load them automatically.
    #
    # If you are using the screen terminal multiplexer, create a directory named 'Microsoft.PowerShell_profile_screen.d'
    # in the same directory as this file. Then, place your custom terminal configuration files in the
    # 'Microsoft.PowerShell_profile_screen.d' directory to load them automatically.
    #
    $__PSProfileEnvTermProgram = [regex]::Split(
        (
            [regex]::Replace(
                (
                    [regex]::Replace(
                        [System.Environment]::GetEnvironmentVariable('TERM_PROGRAM'),
                        '\.[^\.]*$',
                        ''
                    )
                ),
                '[ .]',
                '_'
            )
        ),
        '-'
    )[0]
    if (-not [string]::IsNullOrEmpty($__PSProfileEnvTermProgram)) {
        $__PSProfileTerminalPrograms = @{
            'vscode' = @{
                'name' = 'VSCode Integrated Terminal'
                'icon' = '📝'
            }
            'tmux'   = @{
                'name' = 'tmux Terminal Multiplexer'
                'icon' = '🔲'
            }
            'screen' = @{
                'name' = 'Screen Terminal Multiplexer'
                'icon' = '🔲'
            }
        }

        if ($__PSProfileTerminalPrograms.ContainsKey($__PSProfileEnvTermProgram)) {
            $__PSProfileTerminalProgram = $__PSProfileTerminalPrograms.$__PSProfileEnvTermProgram
        }
        else {
            $__PSProfileTerminalProgram = @{
                'name' = $__PSProfileEnvTermProgram.Substring(0, 1).ToUpper() + $__PSProfileEnvTermProgram.Substring(1)
                'icon' = '🟡'
            }
        }
        __PSProfile-Write-ProfileLoadMessage "$($__PSProfileTerminalProgram.icon) Applying configurations for $($PSStyle.Bold)$($__PSProfileTerminalProgram.name)$($PSStyle.BoldOff)." -ForegroundColor DarkCyan

        $__PSProfileDirectoryPath = [regex]::Replace($MyInvocation.MyCommand.Path, '\.ps1$', "_$($__PSProfileEnvTermProgram.ToLower()).d")
        if ([System.IO.Directory]::Exists($__PSProfileDirectoryPath)) {
            foreach ($file in [System.Array]::Sort( [System.IO.Directory]::GetFiles($__PSProfileDirectoryPath, '*.ps1') )) {
                . $file
            }
        }
    }
    #endregion Custom Terminal Configuration -----------------------------------
}
catch {
    __PSProfile-Write-ProfileLoadMessage "`n❌ Interrupting profile load process.`n" -ForegroundColor DarkRed
    Write-Error "An error occurred while loading the user profile." -ErrorAction Continue
    throw
}
finally {
    __PSProfile-Clear-Environment
}
