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
    #region Functions ==============================================================
    $__PSProfileFunctionsPath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($PROFILE.AllUsersAllHosts), 'profile.functions.ps1')
    if ([System.IO.File]::Exists($__PSProfileFunctionsPath)) { . $__PSProfileFunctionsPath } else { throw "Profile functions file not found at $__PSProfileFunctionsPath" }
    __PSProfile-Initialize-Profile
    #endregion Functions -----------------------------------------------------------

    if ($IsWindows) { return } # This global profile is for *nix only

    #region Script Variables =======================================================
    $__PSProfileEnvPathOriginal = [Environment]::GetEnvironmentVariable('PATH')
    $__PSProfileEnvHome = [Environment]::GetEnvironmentVariable('HOME')
    $__PSProfileEnvTermProgram = [Environment]::GetEnvironmentVariable('TERM_PROGRAM')

    $__PSProfileEnvAliasDirForce = [System.Environment]::GetEnvironmentVariable('PSPROFILE_ALIAS_DIR_FORCE')
    $__PSProfileEnvAliasDirHidden = [System.Environment]::GetEnvironmentVariable('PSPROFILE_ALIAS_DIR_HIDDEN')
    $__PSProfileEnvAliasDirSort = [System.Environment]::GetEnvironmentVariable('PSPROFILE_ALIAS_DIR_SORT')
    if ($null -eq $__PSProfileEnvAliasDirForce) { $__PSProfileEnvAliasDirForce = $false; [System.Environment]::SetEnvironmentVariable('PSPROFILE_ALIAS_DIR_FORCE', $__PSProfileEnvAliasDirForce) }
    if ($null -eq $__PSProfileEnvAliasDirHidden) { $__PSProfileEnvAliasDirHidden = $true; [System.Environment]::SetEnvironmentVariable('PSPROFILE_ALIAS_DIR_HIDDEN', $__PSProfileEnvAliasDirHidden) }
    if ($null -eq $__PSProfileEnvAliasDirSort) { $__PSProfileEnvAliasDirSort = $true; [System.Environment]::SetEnvironmentVariable('PSPROFILE_ALIAS_DIR_SORT', $__PSProfileEnvAliasDirSort) }
    #endregion Script Variables ----------------------------------------------------

    # Display optional first run image specific notice if configured and terminal is interactive
    if (
        (__PSProfile-Assert-IsUserInteractiveShell) -and
        $__PSProfileEnvTermProgram -match '^(vscode|codespaces)$' -and
        -not ([System.IO.File]::Exists("$__PSProfileEnvHome/.config/vscode-dev-containers/first-run-notice-already-displayed"))
    ) {
        if ([System.IO.File]::Exists('/usr/local/etc/vscode-dev-containers/first-run-notice.txt')) {
            [System.IO.File]::ReadAllText('/usr/local/etc/vscode-dev-containers/first-run-notice.txt')
        }
        elseif ([System.IO.File]::Exists('/workspaces/.codespaces/shared/first-run-notice.txt')) {
            [System.IO.File]::ReadAllText('/workspaces/.codespaces/shared/first-run-notice.txt')
        }
        # Mark first run notice as displayed after 10s to avoid problems with fast terminal refreshes hiding it
        $null = Start-ThreadJob -Name FirstRunNoticeAlreadyDisplayed -ScriptBlock {
            Start-Sleep -Seconds 10
            $null = New-Item -ItemType Directory -Force -Path "$env:HOME/.config/vscode-dev-containers"
            $null = New-Item -ItemType File -Force -Path "$env:HOME/.config/vscode-dev-containers/first-run-notice-already-displayed"
        }
    }

    __PSProfile-Write-ProfileLoadMessage "🌐 Loading $($PSStyle.Bold)global$($PSStyle.BoldOff) profile."

    #region Global Variables =======================================================
    $Global:__PSProfileSource = 'DevContainer-Feature:PowerShell-Extended'
    #endregion Global Variables ----------------------------------------------------

    #region Environment Variables ==================================================
    # Add local bin directory to PATH if not already present
    if ($__PSProfileEnvPathOriginal.Split(':') -notcontains "$__PSProfileEnvHome/.local/bin") { [Environment]::SetEnvironmentVariable('PATH', "${__PSProfileOriginalPath}:$__PSProfileEnvHome/.local/bin") }

    # Set the USER environment variable if not already set
    if ($null -eq [Environment]::GetEnvironmentVariable('USER') -and $null -eq [Environment]::GetEnvironmentVariable('USERNAME')) { [Environment]::SetEnvironmentVariable('USER', (& $(& which whoami))) }

    # Set the default git editor if not already set
    if (
        $null -eq [Environment]::GetEnvironmentVariable('GIT_EDITOR') -and
        $null -eq $(try { git config --get core.editor } catch { $Error.Clear(); $null })
    ) {
        # Check if the terminal program is vscode
        if ($__PSProfileEnvTermProgram -match '^(vscode|codespaces)$') {
            # Check if code-insiders is available and code is not available
            if ((Get-Command -Name 'code-insiders' -ErrorAction Ignore) -and $null -eq (Get-Command -Name 'code' -ErrorAction Ignore)) {
                [Environment]::SetEnvironmentVariable('GIT_EDITOR', 'code-insiders --wait')
            }
            else {
                [Environment]::SetEnvironmentVariable('GIT_EDITOR', 'code --wait')
            }
        }
    }
    #endregion Environment Variables -----------------------------------------------

    #region Aliases ================================================================
    if (
        $__PSProfileEnvAliasDirForce -eq $true -or
        $__PSProfileEnvAliasDirHidden -eq $true -or
        $__PSProfileEnvAliasDirSort -eq $true
    ) {
        <#
        This is a copy of:

        CommandType Name          Version Source
        ----------- ----          ------- ------
        Cmdlet      Get-ChildItem 7.0.0.0 Microsoft.PowerShell.Management

        Created: 2024-08-11
        Author : Julian Pawlowski

        Created with PSScriptTools: Copy-Command Get-Childitem -AsProxy -UseForwardHelp -IncludeDynamic
        #>
        function __PSProfileAliasDir {
            <#
            .ForwardHelpTargetName Microsoft.PowerShell.Management\Get-ChildItem
            .ForwardHelpCategory Cmdlet
            #>
            [CmdletBinding(DefaultParameterSetName = 'Items', HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=2096492')]
            Param(
                [Parameter(ParameterSetName = 'Items', Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
                [string[]]
                ${Path},

                [Parameter(ParameterSetName = 'LiteralItems', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
                [Alias('PSPath', 'LP')]
                [string[]]
                ${LiteralPath},

                [Parameter(Position = 1)]
                [string]
                ${Filter},

                [string[]]
                ${Include},

                [string[]]
                ${Exclude},

                [Alias('s')]
                [switch]
                ${Recurse},

                [uint]
                ${Depth},

                [switch]
                ${Force},

                [switch]
                ${Name},

                [System.Management.Automation.FlagsExpression[System.IO.FileAttributes]]
                ${Attributes},

                [switch]
                ${FollowSymlink},

                [Alias('ad')]
                [switch]
                ${Directory},

                [Alias('af')]
                [switch]
                ${File},

                [Alias('ah', 'h')]
                [switch]
                ${Hidden},

                [Alias('ar')]
                [switch]
                ${ReadOnly},

                [Alias('as')]
                [switch]
                ${System}
            )

            Begin {
                Write-Verbose "[BEGIN  ] Starting $($MyInvocation.MyCommand)"
                Write-Verbose "[BEGIN  ] Using parameter set $($PSCmdlet.ParameterSetName)"
                Write-Verbose ($PSBoundParameters | Out-String)
                try {
                    $outBuffer = $null
                    if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                        $PSBoundParameters['OutBuffer'] = 1
                    }
                    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_ALIAS_DIR_FORCE') -eq $true) {
                        $PSBoundParameters['Force'] = $true
                    }
                    elseif ([System.Environment]::GetEnvironmentVariable('PSPROFILE_ALIAS_DIR_HIDDEN') -eq $true) {
                        $PSBoundParameters['Hidden'] = $true
                    }

                    $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Management\Get-ChildItem', [System.Management.Automation.CommandTypes]::Cmdlet)
                    if ([System.Environment]::GetEnvironmentVariable('PSPROFILE_ALIAS_DIR_SORT') -eq $true) {
                        $scriptCmd = { & $wrappedCmd @PSBoundParameters | Sort-Object -Property { -not $_.psiscontainer }, Name }
                    }
                    else {
                        $scriptCmd = { & $wrappedCmd @PSBoundParameters }
                    }

                    $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
                    $steppablePipeline.Begin($PSCmdlet)
                }
                catch { throw }
            }
            Process {
                try { $steppablePipeline.Process($_) } catch { throw }
            }
            End {
                Write-Verbose "[END    ] Ending $($MyInvocation.MyCommand)"
                try { $steppablePipeline.End() } catch { throw }
            }
        }
        New-Alias -Name dir -Value __PSProfileAliasDir -Option AllScope -Force
    }
    #endregion Import Modules ------------------------------------------------------

    #region Custom Profile =========================================================
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
    #endregion Custom Profile ------------------------------------------------------
}
catch {
    $__PSProfileError = "`n❌ Interrupting profile load process.`n"
    if (Get-Command -Name '__PSProfile-Write-ProfileLoadMessage' -ErrorAction Ignore) { __PSProfile-Write-ProfileLoadMessage $__PSProfileError -ForegroundColor DarkRed } else { Write-Host $__PSProfileError -ForegroundColor DarkRed }
    Write-Error "An error occurred while loading the global profile." -ErrorAction Continue
    throw
}
finally {
    if (Get-Command -Name '__PSProfile-Clear-Environment' -ErrorAction Ignore) { __PSProfile-Clear-Environment }
}
