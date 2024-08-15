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
    if ([Environment]::GetEnvironmentVariable('PSPROFILE_TERMINAL_COMPLETION_GIT') -eq $true) { __PSProfile-Import-ModuleAndInstallIfMissing -Name posh-git }
    if ([Environment]::GetEnvironmentVariable('PSPROFILE_TERMINAL_COMPLETION_PSFZF') -eq $true -and $null -ne (Get-Command -Name fzf -CommandType Application -ErrorAction Ignore)) { __PSProfile-Import-ModuleAndInstallIfMissing -Name PSFzf }
    if ([Environment]::GetEnvironmentVariable('PSPROFILE_TERMINAL_COMPLETION_PREDICTOR') -eq $true) { __PSProfile-Import-ModuleAndInstallIfMissing -Name CompletionPredictor }
    if ([Environment]::GetEnvironmentVariable('PSPROFILE_TERMINAL_COMPLETION_PREDICTOR_AZ') -eq $true) { if (Get-Module -Name Az.Accounts -ListAvailable) { __PSProfile-Import-ModuleAndInstallIfMissing -Name Az.Tools.Predictor } }
    if ([Environment]::GetEnvironmentVariable('PSPROFILE_TERMINAL_Z') -eq $true) { __PSProfile-Import-ModuleAndInstallIfMissing -Name z }
    if ([Environment]::GetEnvironmentVariable('PSPROFILE_TERMINAL_ICONS') -eq $true) { __PSProfile-Import-ModuleAndInstallIfMissing -Name Terminal-Icons }
    #endregion Import Modules --------------------------------------------------

    #region PSReadLine predictor plugins =======================================
    $__PSProfilePSReadLineOptions = @{}
    $__PSProfileEnvPSReadlinePredictionSource = [Environment]::GetEnvironmentVariable('PSPROFILE_PSREADLINE_PREDICTION_SOURCE')
    $__PSProfileEnvPSReadlinePredictionViewStyle = [Environment]::GetEnvironmentVariable('PSPROFILE_PSREADLINE_PREDICTION_VIEWSTYLE')
    if ($null -ne $__PSProfileEnvPSReadlinePredictionSource) { $__PSProfilePSReadLineOptions.PredictionSource = $__PSProfileEnvPSReadlinePredictionSource }
    if ($null -ne $__PSProfileEnvPSReadlinePredictionViewStyle) { $__PSProfilePSReadLineOptions.PredictionViewStyle = $__PSProfileEnvPSReadlinePredictionViewStyle }
    if ($__PSProfilePSReadLineOptions.Count -gt 0) { Set-PSReadLineOption @__PSProfilePSReadLineOptions }
    #endregion PSReadLine ------------------------------------------------------

    #region Environment ========================================================
    $__PSProfileEnvAutoUpdateModuleHelp = [Environment]::GetEnvironmentVariable('PSPROFILE_AUTOUPDATE_MODULEHELP')
    if ($null -eq $__PSProfileEnvAutoUpdateModuleHelp -or $__PSProfileEnvAutoUpdateModuleHelp -eq $true) { __PSProfile-Update-Help }
    #endregion Environment -----------------------------------------------------

    #region Oh My Posh =========================================================
    $__PSProfileEnvOhMyPoshTheme = [Environment]::GetEnvironmentVariable('PSPROFILE_POSH_THEME')
    if ($null -ne $__PSProfileEnvOhMyPoshTheme) { __PSProfile-Enable-OhMyPosh-Theme -ThemeName $__PSProfileEnvOhMyPoshTheme } else { __PSProfile-Enable-OhMyPosh-Theme }
    if ([Environment]::GetEnvironmentVariable('PSPROFILE_TERMINAL_COMPLETION_POSH') -eq $true) { oh-my-posh completion powershell | Out-String | Invoke-Expression }
    if ([Environment]::GetEnvironmentVariable('PSPROFILE_POSH_DISABLE_UPGRADE_NOTICE') -eq $true) { $null = Start-ThreadJob -Name 'PoshDisableNotice' -ScriptBlock { oh-my-posh disable notice } }
    #endregion Oh My Posh ------------------------------------------------------

    # Check the terminal emulator
    if ($null -ne $env:TERM_PROGRAM) {
        switch -Wildcard ($env:TERM_PROGRAM) {
            # VSCode and Operating System native terminals
            'vscode*' {
                __PSProfile-Write-ProfileLoadMessage "📝 Applying configurations for $($PSStyle.Bold)VSCode Integrated Terminal$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any VSCode-specific configurations here ...
            }
            'Windows_Terminal*' {
                __PSProfile-Write-ProfileLoadMessage "🖥️ Applying configurations for $($PSStyle.Bold)Windows Terminal$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any Windows Terminal-specific configurations here ...
            }
            'Apple_Terminal*' {
                __PSProfile-Write-ProfileLoadMessage " Applying configurations for $($PSStyle.Bold)Apple Terminal$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any Apple Terminal-specific configurations here ...
            }

            # Popular modern terminals
            'Alacritty*' {
                __PSProfile-Write-ProfileLoadMessage "🪄 Applying configurations for $($PSStyle.Bold)Alacritty$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any Alacritty-specific configurations here ...
            }
            'WezTerm*' {
                __PSProfile-Write-ProfileLoadMessage "🪄 Applying configurations for $($PSStyle.Bold)WezTerm$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any WezTerm-specific configurations here ...
            }
            'Warp*' {
                __PSProfile-Write-ProfileLoadMessage "🪄 Applying configurations for $($PSStyle.Bold)Warp$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any Warp-specific configurations here ...
            }
            'Tabby*' {
                __PSProfile-Write-ProfileLoadMessage "🪄 Applying configurations for $($PSStyle.Bold)Tabby$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any Tabby-specific configurations here ...
            }
            'Terminus*' {
                __PSProfile-Write-ProfileLoadMessage "🪄 Applying configurations for $($PSStyle.Bold)Terminus$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any Terminus-specific configurations here ...
            }
            'Upterm*' {
                __PSProfile-Write-ProfileLoadMessage "🪄 Applying configurations for $($PSStyle.Bold)Upterm$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any Upterm-specific configurations here ...
            }

            # Browser-based terminals
            'Hyper*' {
                __PSProfile-Write-ProfileLoadMessage "🪄 Applying configurations for $($PSStyle.Bold)Hyper terminal$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any Hyper-specific configurations here ...
            }

            # Other common terminals
            'gnome-terminal*' {
                __PSProfile-Write-ProfileLoadMessage "🪄 Applying configurations for $($PSStyle.Bold)GNOME Terminal$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any GNOME Terminal-specific configurations here ...
            }
            'iTerm.app*' {
                __PSProfile-Write-ProfileLoadMessage "🪄 Applying configurations for $($PSStyle.Bold)iTerm2$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any iTerm2-specific configurations here ...
            }
            'Kitty*' {
                __PSProfile-Write-ProfileLoadMessage "🪄 Applying configurations for $($PSStyle.Bold)Kitty$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any Kitty-specific configurations here ...
            }
            'Konsole*' {
                __PSProfile-Write-ProfileLoadMessage "🪄 Applying configurations for $($PSStyle.Bold)Konsole$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any Konsole-specific configurations here ...
            }
            'Terminator*' {
                __PSProfile-Write-ProfileLoadMessage "🪄 Applying configurations for $($PSStyle.Bold)Terminator terminal$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any Terminator-specific configurations here ...
            }
            'Terminology*' {
                __PSProfile-Write-ProfileLoadMessage "🪄 Applying configurations for $($PSStyle.Bold)Terminology$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any Terminology-specific configurations here ...
            }
            'Tilix*' {
                __PSProfile-Write-ProfileLoadMessage "🪄 Applying configurations for $($PSStyle.Bold)Tilix$($PSStyle.BoldOff)." -ForegroundColor DarkCyan
                # ... Add any Tilix-specific configurations here ...
            }
            default {
                __PSProfile-Write-ProfileLoadMessage "🟡 Applying configurations for $($PSStyle.Bold)unknown$($PSStyle.BoldOff) terminal emulator." -ForegroundColor DarkCyan
                # ... Add any default configurations here
            }
        }
    }

    # Check the terminal multiplexer or console emulator
    else {
        switch -Wildcard ($env:TERM) {
            # Terminal Multiplexers and Console Emulators
            'xterm*' {
                __PSProfile-Write-ProfileLoadMessage "⌨️ Applying configurations for $($PSStyle.Bold)XTerm$($PSStyle.BoldOff)." -ForegroundColor DarkGray
                # ... Add any XTerm-specific configurations here ...
            }
            'screen*' {
                __PSProfile-Write-ProfileLoadMessage "⌨️ Applying configurations for $($PSStyle.Bold)screen$($PSStyle.BoldOff) session." -ForegroundColor DarkGray
                # ... Add any screen-specific configurations here ...
            }
            'linux*' {
                __PSProfile-Write-ProfileLoadMessage "⌨️ Applying configurations for $($PSStyle.Bold)Linux console$($PSStyle.BoldOff)." -ForegroundColor DarkGray
                # ... Add any Linux console-specific configurations here ...
            }
            'tmux*' {
                __PSProfile-Write-ProfileLoadMessage "⌨️ Applying configurations for $($PSStyle.Bold)tmux$($PSStyle.BoldOff) session." -ForegroundColor DarkGray
                # ... Add any tmux-specific configurations here ...
            }
            default {
                __PSProfile-Write-ProfileLoadMessage "⌨️ Applying configurations for $($PSStyle.Bold)unknown$($PSStyle.BoldOff) terminal multiplexer or console emulator." -ForegroundColor DarkGray
                # ... Add any default configurations here
            }
        }
    }

    #region Custom Profile =====================================================
    #
    # Hint:
    # To load your own custom profile, you may create a directory named 'Microsoft.PowerShell_profile.d' in the same directory as this file.
    # Then, place your custom profile files in the 'Microsoft.PowerShell_profile.d' directory to load them automatically.
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
