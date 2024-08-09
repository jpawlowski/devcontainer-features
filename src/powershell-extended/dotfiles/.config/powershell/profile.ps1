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

#Requires -Version 7.2

try {
    if ($Error) { return } # Skip if there was an error loading the profile before

    #region Functions ==============================================================
    $__PSProfileFunctionsPath = Join-Path -Path ($PROFILE.AllUsersAllHosts | Split-Path -Parent) -ChildPath 'profile.functions.ps1'
    if ([System.IO.File]::Exists($__PSProfileFunctionsPath)) { . $__PSProfileFunctionsPath } else { throw "Profile functions file not found at $__PSProfileFunctionsPath" }
    #
    # Hint:
    # To load your own functions, you may put them into profile.functions.my.ps1 in
    # the same directory as this file. Note that you must define them explicitly into the global scope,
    # e.g., 'function Global:MyFunction { ... }'.
    #
    #endregion Functions -----------------------------------------------------------

    __PSProfile-Write-ProfileLoadMessage "👤 Loading $($PSStyle.Bold)user$($PSStyle.BoldOff) profile."

    #region Import Modules =========================================================
    __PSProfile-Import-ModuleAndInstallIfMissing -Name PSReadLine
    #endregion Import Modules ------------------------------------------------------

    #region PSReadLine, except predictor plugins ===================================
    # This is based on an example profile for PSReadLine from
    # https://github.com/PowerShell/PSReadLine/blob/e9122d38e932614393ff61faf57d6518990d7226/PSReadLine/SamplePSReadLineProfile.ps1
    #

    Set-PSReadLineOption -EditMode $(if ($env:PSPROFILE_PSREADLINE_EDITMODE) { $env:PSPROFILE_PSREADLINE_EDITMODE } else { 'Emacs' })

    # Searching for commands with up/down arrow is really handy.  The
    # option "moves to end" is useful if you want the cursor at the end
    # of the line while cycling through history like it does w/o searching,
    # without that option, the cursor will remain at the position it was
    # when you used up arrow, which can be useful if you forget the exact
    # string you started the search on.
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

    # In Emacs mode - Tab acts like in bash, but the Windows style completion
    # is still useful sometimes, so bind some keys so we can do both
    Set-PSReadLineKeyHandler -Key Ctrl+q -Function TabCompleteNext
    Set-PSReadLineKeyHandler -Key Ctrl+Q -Function TabCompletePrevious

    # Clipboard interaction is bound by default in Windows mode, but not Emacs mode.
    Set-PSReadLineKeyHandler -Key Ctrl+C -Function Copy
    Set-PSReadLineKeyHandler -Key Ctrl+v -Function Paste

    # CaptureScreen is good for blog posts or email showing a transaction
    # of what you did when asking for help or demonstrating a technique.
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d,Ctrl+c' -Function CaptureScreen

    # The built-in word movement uses character delimiters, but token based word
    # movement is also very useful - these are the bindings you'd use if you
    # prefer the token based movements bound to the normal emacs word movement
    # key bindings.
    Set-PSReadLineKeyHandler -Key Alt+d -Function ShellKillWord
    Set-PSReadLineKeyHandler -Key Alt+Backspace -Function ShellBackwardKillWord
    Set-PSReadLineKeyHandler -Key Alt+b -Function ShellBackwardWord
    Set-PSReadLineKeyHandler -Key Alt+f -Function ShellForwardWord
    Set-PSReadLineKeyHandler -Key Alt+B -Function SelectShellBackwardWord
    Set-PSReadLineKeyHandler -Key Alt+F -Function SelectShellForwardWord

    # Insert text from the clipboard as a here string
    $__PSProfilePSRParams = @{
        Key              = 'Ctrl+v'
        BriefDescription = 'PasteAsHereString'
        LongDescription  = 'Paste the clipboard text as a here string'
        ScriptBlock      = {
            param($key, $arg)

            Add-Type -Assembly PresentationCore
            if ([System.Windows.Clipboard]::ContainsText()) {
                # Get clipboard text - remove trailing spaces, convert \r\n to \n, and remove the final \n.
                $text = ([System.Windows.Clipboard]::GetText() -replace "\p{Zs}*`r?`n", "`n").TrimEnd()
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert("@'`n$text`n'@")
            }
            else {
                [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
            }
        }
    }
    Set-PSReadLineKeyHandler @__PSProfilePSRParams

    # `ForwardChar` accepts the entire suggestion text when the cursor is at the end of the line.
    # This custom binding makes `RightArrow` behave similarly - accepting the next word instead of the entire suggestion text.
    Set-PSReadLineKeyHandler -Key RightArrow `
        -BriefDescription ForwardCharAndAcceptNextSuggestionWord `
        -LongDescription "Move cursor one character to the right in the current editing line and accept the next word in suggestion when it's at the end of current editing line" `
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
    #endregion PSReadLine ----------------------------------------------------------

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
    Write-Error "An error occurred while loading the user profile: $_" -ErrorAction Continue
    throw
}
finally {
    if (Get-Command -Name '__PSProfile-Clear-Environment' -ErrorAction Ignore) { __PSProfile-Clear-Environment }
}
