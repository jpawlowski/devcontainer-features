# ~/.config/powershell/profile.ps1 - Source: https://github.com/jpawlowski/devcontainer-features/src/powershell-extended/dotfiles/.config/powershell/profile.ps1
# This profile is executed by all PowerShell hosts (e.g., PowerShell console, VSCode Integrated Terminal) on startup for the current user.
#
# Purpose:
# This file is intended for settings and configurations that should apply to all PowerShell hosts.
# It should include non-visual configurations. Visual configurations should be placed in:
# - Microsoft.PowerShell_profile.ps1
# - Microsoft.VSCode_profile.ps1
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
#
# Explanation: What is a PowerShell host and a terminal emulator?
# A "PowerShell host" is the application or interface where PowerShell commands are executed. Examples include the PowerShell console, the VSCode Integrated Terminal, and the PowerShell ISE.
# A "terminal emulator" is a program that emulates a video terminal within another display architecture. Examples include VSCode's terminal, Windows Terminal, Apple Terminal, iTerm2, GNOME Terminal, and others.
# The PowerShell host runs within the terminal emulator, providing the environment where PowerShell commands are executed.
# For instance, when you run PowerShell in VSCode, the VSCode Integrated Terminal acts as the terminal emulator, and the PowerShell extension acts as the PowerShell host.
# Similarly, when you run PowerShell in Windows Terminal, Windows Terminal acts as the terminal emulator, and the PowerShell console acts as the PowerShell host.

#Requires -Version 7.2 -Modules PSReadLine

try {
    if ($Error) { return } # Skip if there was an error loading the profile before
    __PSProfile-Initialize-Profile
    __PSProfile-Write-ProfileLoadMessage "👤 Loading $($PSStyle.Bold)user$($PSStyle.BoldOff) profile."

    #region PSReadLine, except predictor plugins ===============================
    $__PSProfileEnvPSReadlineEditMode = [System.Environment]::GetEnvironmentVariable('PSPROFILE_PSREADLINE_EDITMODE')
    $__PSProfilePSReadLineOptions = @{
        EditMode = $(if ($null -ne $__PSProfileEnvPSReadlineEditMode) { $__PSProfileEnvPSReadlineEditMode } else { 'Emacs' })
        HistorySearchCursorMovesToEnd = $true
        BellStyle = 'None'
    }
    Set-PSReadLineOption @__PSProfilePSReadLineOptions

    Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

    # `ForwardChar` accepts the entire suggestion text when the cursor is at the end of the line.
    # This custom binding makes `RightArrow` behave similarly - accepting the next word instead of the entire suggestion text.
    Set-PSReadLineKeyHandler -Key RightArrow `
        -BriefDescription ForwardCharAndAcceptNextSuggestionWord `
        -LongDescription 'Move cursor one character to the right in the current editing line and accept the next word in suggestion when it''s at the end of current editing line' `
        -ScriptBlock {
        param($key, $arg)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        if ($cursor -lt $line.Length) {
            [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($key, $arg)
        }
        else {
            [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
        }
    }

    # Custom binding for the `End` key to jump to the end of the line and accept the entire suggestion
    Set-PSReadLineKeyHandler -Key End `
        -BriefDescription AcceptEntireSuggestion `
        -LongDescription 'Move cursor to the end of the current editing line and accept the entire suggestion' `
        -ScriptBlock {
        param($key, $arg)

        $line = $null
        $cursor = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

        # Move cursor to the end of the line
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine($key, $arg)

        # Accept the entire suggestion
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptSuggestion($key, $arg)
    }
    #endregion PSReadLine ------------------------------------------------------

    #region Custom Profile =====================================================
    #
    # Hint:
    # To load your own custom profile, you may create a directory named 'profile.d' in the same directory as this file.
    # Then, place your custom profile files in the 'profile.d' directory to load them automatically.
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
