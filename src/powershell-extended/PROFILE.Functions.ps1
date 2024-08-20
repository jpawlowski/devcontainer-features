# /opt/microsoft/powershell/7/profile.functions.ps1 - Source: https://githhub.com/jpawlowski/devcontainer-features/src/powershell-extended/PROFILE.Functions.ps1
# These functions are used by the user profile.ps1 files.

#region Profile Functions ======================================================
function __PSProfile-Initialize-Profile {
    <#
    .SYNOPSIS
        Initializes the profile.
    .DESCRIPTION
        This function initializes the profile.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    param ()
    if (-not $Script:___PSProfiles) {
        $Script:__PSProfileConfirmPreference = $ConfirmPreference; $ConfirmPreference = 'None'
        $Script:__PSProfileErrorActionPreference = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
        $Script:___PSProfiles = [object[]]::new(4)
        $Script:__PSProfileIndex = 0
    }
    if ($Script:__PSProfileIndex -lt 4) {
        $Script:___PSProfiles[$Script:__PSProfileIndex] = (__PSProfile-Get-ProfileInfoFromFilePath -FilePath $MyInvocation.ScriptName)
        $Script:__PSProfileIndex++
    }
}
function __PSProfile-Write-ProfileLoadMessage {
    <#
    .SYNOPSIS
        Writes a message to the console unless the environment variable POWERSHELL_HIDE_PROFILE_LOAD_MESSAGES is set to true or if the Force parameter is specified.
        By default, messages are only shown in interactive sessions.
    .DESCRIPTION
        This function checks the environment variable POWERSHELL_HIDE_PROFILE_LOAD_MESSAGES. If it is not set to true, or if the Force parameter is specified, it writes the provided
        message to the console in the specified foreground color. Optionally, a background color can also be specified. Additional parameters allow for more control
        over the output. By default, messages are only shown in interactive sessions. The Force parameter can be used to override this behavior and show messages
        regardless of the session type.
    .PARAMETER Message
        The message to be written to the console.
    .PARAMETER ForegroundColor
        The color of the text. Default is 'Cyan'.
    .PARAMETER BackgroundColor
        The background color of the text. If not specified, no background color is set.
    .PARAMETER NoNewLine
        If specified, the output will not include a newline at the end.
    .PARAMETER Separator
        A string to use as a separator between multiple messages.
    .PARAMETER Force
        If specified, the message will be written regardless of the POWERSHELL_HIDE_PROFILE_LOAD_MESSAGES environment variable or session type. This overrides the default
        behavior of only showing messages in interactive sessions.
    .EXAMPLE
        __PSProfile-Write-ProfileLoadMessage -Message "Loading profile..."
        This will write "Loading profile..." to the console in cyan color unless POWERSHELL_HIDE_PROFILE_LOAD_MESSAGES is set to true and the session is interactive.
    .EXAMPLE
        __PSProfile-Write-ProfileLoadMessage -Message "Loading profile..." -BackgroundColor 'Black'
        This will write "Loading profile..." to the console in cyan text with a black background unless POWERSHELL_HIDE_PROFILE_LOAD_MESSAGES is set to true and the session is
        interactive.
    .EXAMPLE
        __PSProfile-Write-ProfileLoadMessage -Message "Loading profile..." -NoNewLine
        This will write "Loading profile..." to the console without a newline at the end unless POWERSHELL_HIDE_PROFILE_LOAD_MESSAGES is set to true and the session is interactive.
    .EXAMPLE
        __PSProfile-Write-ProfileLoadMessage -Message "Loading profile..." -Separator " - "
        This will write "Loading profile..." to the console with " - " as a separator unless POWERSHELL_HIDE_PROFILE_LOAD_MESSAGES is set to true and the session is interactive.
    .EXAMPLE
        __PSProfile-Write-ProfileLoadMessage -Message "Loading profile..." -Force
        This will write "Loading profile..." to the console regardless of the POWERSHELL_HIDE_PROFILE_LOAD_MESSAGES environment variable or session type.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    param (
        [string]$Message,
        [ValidateSet('Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta', 'DarkYellow', 'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red',
            'Magenta', 'Yellow', 'White')]
        [string]$ForegroundColor = 'Cyan',
        [ValidateSet('Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta', 'DarkYellow', 'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red',
            'Magenta', 'Yellow', 'White')]
        [string]$BackgroundColor = $null,
        [switch]$NoNewLine,
        [string]$Separator = ' ',
        [switch]$Force
    )

    if ($Force -or ([System.Environment]::GetEnvironmentVariable('POWERSHELL_HIDE_PROFILE_LOAD_MESSAGES') -ne $true -and (__PSProfile-Assert-IsUserInteractiveShell))) {
        $writeHostParams = @{
            Object          = $Message
            ForegroundColor = $ForegroundColor
        }
        if ($BackgroundColor) {
            $writeHostParams.BackgroundColor = $BackgroundColor
        }
        if ($NoNewLine) {
            $writeHostParams.NoNewline = $true
        }
        if ($Separator) {
            $writeHostParams.Separator = $Separator
        }
        Write-Host @writeHostParams
    }
}
function __PSProfile-Import-ModuleAndInstallIfMissing {
    <#
    .SYNOPSIS
        Imports a module and installs it from the PowerShell Gallery if it is not already installed.
    .DESCRIPTION
        This function imports a module and installs it from the PowerShell Gallery if it is not already installed.
    .PARAMETER Name
        The name of the module to import.
    .PARAMETER ArgumentList
        An array of arguments to pass to the module when importing it.
    .PARAMETER InstallInBackground
        Indicates whether the module should be installed in the background if it is not already installed. Default is $true.
    .PARAMETER ImportInBackground
        Indicates whether the module should be imported in the background if it is not already imported. Default is $true.
    .PARAMETER DelaySeconds
        The number of seconds to delay before starting the installation. Default is 0 (no delay).
    .EXAMPLE
        __PSProfile-Import-ModuleAndInstallIfMissing -Name Microsoft.PowerShell.Utility
        This will import the Microsoft.PowerShell.Utility module and install it from the PowerShell Gallery if it is not already installed.
    .EXAMPLE
        __PSProfile-Import-ModuleAndInstallIfMissing -Name Microsoft.PowerShell.Utility -InstallInBackground $false -ImportInBackground $false
        This will import the Microsoft.PowerShell.Utility module and install it from the PowerShell Gallery if it is not already installed, without running the installation or import in the background.
    .EXAMPLE
        __PSProfile-Import-ModuleAndInstallIfMissing -Name Microsoft.PowerShell.Utility -DelaySeconds 5
        This will import the Microsoft.PowerShell.Utility module and install it from the PowerShell Gallery if it is not already installed, with a delay of 5 seconds before starting the installation.
    .NOTES
        Requires PowerShell 7.2 or later for background installation.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    param (
        [string]$Name,
        [array]$ArgumentList,
        [bool]$InstallInBackground = $true,
        [bool]$ImportInBackground = $true,
        [int]$InstallDelaySeconds = 0
    )

    $mutexName = "Global\ModuleInstallMutex"

    try {
        __PSProfile-Import-ModuleIfNotLoaded -Name $Name -ArgumentList $ArgumentList -ImportInBackground $ImportInBackground
    }
    catch {
        if ($_.FullyQualifiedErrorId -eq 'ModuleNotFound') {
            $Error.Clear() # Clear the error because we are going to solve it
            if ($InstallInBackground) {
                $job = Start-ThreadJob -Name "Install-$Name" -ScriptBlock {
                    param (
                        $moduleName,
                        $mutexName,
                        $delaySeconds
                    )

                    Start-Sleep -Seconds $delaySeconds

                    $mutex = [System.Threading.Mutex]::new($false, $mutexName)
                    $mutex.WaitOne()

                    try {
                        if (-not (Get-Module -ListAvailable -Name $moduleName)) {
                            if (Get-Module -ListAvailable -Name Microsoft.PowerShell.PSResourceGet) {
                                Microsoft.PowerShell.PSResourceGet\Install-PSResource -Name $moduleName -Repository PSGallery -TrustRepository -Scope CurrentUser -AcceptLicense -Quiet -ProgressAction Ignore -Confirm:$false -Verbose:$false -Debug:$false
                            }
                            else {
                                PowerShellGet\Install-Module -Name $moduleName -Repository PSGallery -Scope CurrentUser -AcceptLicense -Force -AllowClobber -ProgressAction Ignore -Confirm:$false -Verbose:$false -Debug:$false
                            }
                        }
                        return $true
                    }
                    catch {
                        return $false
                    }
                    finally {
                        $mutex.ReleaseMutex()
                        $mutex.Dispose()
                    }
                } -ArgumentList $Name, $mutexName, $InstallDelaySeconds

                $null = Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
                    switch ($EventArgs.JobStateInfo.State) {
                        Completed {
                            Import-Module -Force -Scope Global -Name $Event.MessageData -DisableNameChecking -ErrorAction Ignore
                            Unregister-Event -SourceIdentifier $Event.SourceIdentifier
                            Remove-Job -Job $Sender -ErrorAction Ignore
                            Remove-Job -Name $Event.SourceIdentifier
                        }
                        { @('Failed', 'Stopped') -contains $_ } {
                            Unregister-Event -SourceIdentifier $Event.SourceIdentifier
                            Remove-Job -Job $Sender -ErrorAction Ignore
                            Remove-Job -Name $Event.SourceIdentifier
                        }
                        Default {
                            # Do nothing
                        }
                    }
                } -MessageData $Name -SourceIdentifier "Import-$Name"
            }
            else {
                $mutex = New-Object System.Threading.Mutex($false, $mutexName)
                $mutex.WaitOne()

                try {
                    if (-not (Get-Module -ListAvailable -Name $Name)) {
                        if (Get-Module -ListAvailable -Name Microsoft.PowerShell.PSResourceGet) {
                            Microsoft.PowerShell.PSResourceGet\Install-PSResource -Name $Name -Repository PSGallery -TrustRepository -Scope CurrentUser -AcceptLicense -Quiet -ProgressAction Ignore -Confirm:$false -Verbose:$false -Debug:$false
                        }
                        else {
                            PowerShellGet\Install-Module -Name $Name -Repository PSGallery -Scope CurrentUser -AcceptLicense -Force -AllowClobber -ProgressAction Ignore -Confirm:$false -Verbose:$false -Debug:$false
                        }
                    }
                    __PSProfile-Import-ModuleIfNotLoaded -Name $Name -ArgumentList $ArgumentList -ImportInBackground $ImportInBackground
                }
                finally {
                    $mutex.ReleaseMutex()
                    $mutex.Dispose()
                }
            }
        }
        else {
            throw "Failed to import module '$Name'. Error: $_"
        }
    }
}
function __PSProfile-Import-ModuleIfNotLoaded {
    <#
    .SYNOPSIS
        Imports a module if it is not already loaded.
    .DESCRIPTION
        This function imports a module if it is not already loaded.
    .PARAMETER Name
        The name of the module to import.
    .PARAMETER ArgumentList
        An array of arguments to pass to the module when importing it.
    .PARAMETER ImportInBackground
        Indicates whether the module should be imported in the background if it is not already imported. Default is $true.
    .EXAMPLE
        __PSProfile-Import-ModuleIfNotLoaded -ModuleName Microsoft.PowerShell.Utility
        This will import the Microsoft.PowerShell.Utility module if it is not already loaded.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    param (
        [string]$Name,
        [array]$ArgumentList,
        [bool]$ImportInBackground = $true
    )

    # Check if the module is already loaded
    if (-not (Get-Module -Name $Name)) {
        # Check if the module is available
        if (Get-Module -ListAvailable -Name $Name) {
            try {
                if ($ImportInBackground) {
                    $scriptBlockString = [System.Text.StringBuilder]::new("Import-Module -Force -Scope Global -Name $Name -DisableNameChecking -ErrorAction Ignore")
                    if ($ArgumentList) {
                        [void]$scriptBlockString.Append(" -ArgumentList @(")
                        [void]$scriptBlockString.Append(($ArgumentList | ForEach-Object { "'$_'" }) -join ',')
                        [void]$scriptBlockString.Append(')')
                    }

                    # Register an engine event that triggers when PowerShell is idle for at least 300 milliseconds.
                    # We can't use Start-ThreadJob here because it runs in its own runspace and can't import modules into the current runspace.
                    # Credits to https://matt.kotsenas.com/posts/pwsh-profiling-async-startup
                    $job = Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action $([scriptblock]::Create($scriptBlockString))

                    # Register an object event to monitor the state changes of the job
                    $null = Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
                        if ($EventArgs.JobStateInfo.State -eq 'Stopped') {
                            Unregister-Event -SourceIdentifier $Event.SourceIdentifier
                            Remove-Job -Job $Sender -ErrorAction Ignore
                            Remove-Job -Name $Event.SourceIdentifier
                        }
                    }
                }
                else {
                    $importParams = @{
                        Name                = $Name
                        DisableNameChecking = $true
                        Force               = $true
                        Scope               = 'Global'
                        ErrorAction         = 'Ignore'
                    }
                    if ($ArgumentList) {
                        $params.ArgumentList = $ArgumentList
                    }
                    Import-Module @importParams
                }
            }
            catch {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new("Module '$ModuleName' could not be loaded."),
                    'ModuleLoadFailed',
                    [System.Management.Automation.ErrorCategory]::NotSpecified,
                    $ModuleName
                )
                throw $errorRecord
            }
        }
        else {
            $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new("Module '$ModuleName' does not exist."),
                'ModuleNotFound',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                $ModuleName
            )
            throw $errorRecord
        }
    }
}
function __PSProfile-Assert-IsUserInteractiveShell {
    <#
    .SYNOPSIS
        Determines if the current shell is interactive.
    .DESCRIPTION
        This function determines if the current shell is interactive. It checks if the shell is running in an interactive session by examining the environment variables and command line arguments.
        If the shell is interactive, the function returns $true; otherwise, it returns $false.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    param()

    if ($null -ne $Script:__PSProfileIsUserInteractiveShell) {
        return $Script:__PSProfileIsUserInteractiveShell
    }

    $__PSProfileEnvCommandLineArgs = [System.Environment]::GetCommandLineArgs()
    if (
            ($__PSProfileEnvCommandLineArgs | Where-Object { $_ -match '^-NonI.*' }) -or
        (
                ($__PSProfileEnvCommandLineArgs | Where-Object { $_ -match '^-C.*' }) -and
            -not ($__PSProfileEnvCommandLineArgs | Where-Object { $_ -match '^-NoE.*' })
        )
    ) {
        $Script:__PSProfileIsUserInteractiveShell = $false
        return $Script:__PSProfileIsUserInteractiveShell
    }

    if ($Host.UI.RawUI.KeyAvailable -or [System.Environment]::UserInteractive) {
        $Script:__PSProfileIsUserInteractiveShell = $true
    }
    else {
        $Script:__PSProfileIsUserInteractiveShell = $false
    }
    return $Script:__PSProfileIsUserInteractiveShell
}
function __PSProfile-Set-OhMyPosh-UpdateNotice {
    <#
    .SYNOPSIS
        Sets the Oh My Posh update notice.
    .DESCRIPTION
        This function sets the Oh My Posh update notice.
    .PARAMETER Disable
        Indicates whether to disable the update notice. Default is $true.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    param(
        [switch]$Disable
    )
    if ([System.IO.File]::Exists("${HOME}/.local/state/oh-my-posh/.psProfileInitializeMarker")) { return }
    if ($Disable) { oh-my-posh disable notice } else { oh-my-posh enable notice }
    if (-not [System.IO.Directory]::Exists("${HOME}/.local/state/oh-my-posh")) {
        [void][System.IO.Directory]::CreateDirectory("${HOME}/.local/state/oh-my-posh")
    }
    $null = [System.IO.File]::Create("${HOME}/.local/state/oh-my-posh/.psProfileInitializeMarker")
}
function __PSProfile-Enable-OhMyPosh-Theme {
    <#
    .SYNOPSIS
        Enables an Oh My Posh theme.
    .DESCRIPTION
        This function enables an Oh My Posh theme.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    param(
        [string]$Theme = 'devcontainers.minimal.omp.json'
    )

    if ($Theme -notmatch '^https?://') {
        # Let codespaces always be an alias for devcontainers
        $Theme = [regex]::Replace($Theme, 'codespaces', 'devcontainers')

        # Ensure the theme file has the correct extension
        if ($Theme -notmatch '\.omp\.[^\.]+$') { $Theme = "$Theme.omp.json" }

        # Find path to theme file
        if ($Theme -notmatch '^/') {
            if ([System.IO.File]::Exists("${HOME}/.config/oh-my-posh/themes/$Theme")) {
                $Theme = "${HOME}/.config/oh-my-posh/themes/$Theme"
            }
            else {
                if (-not [System.Environment]::GetEnvironmentVariable('POSH_THEMES_PATH')) { [System.Environment]::SetEnvironmentVariable('POSH_THEMES_PATH', "${HOME}/.cache/oh-my-posh/themes") }
                $Theme = "${HOME}/.cache/oh-my-posh/themes/$Theme"
            }
        }
    }

    try {
        & ([ScriptBlock]::Create((oh-my-posh init pwsh --config "$Theme" --print) -join "`n"))
    }
    catch {}
}
function __PSProfile-Clear-Environment {
    <#
    .SYNOPSIS
        Clear global environment from temporary profile artifacts.
    .DESCRIPTION
        This function clears global environment from temporary profile artifacts.
        This prevents the environment from being polluted with temporary variables and functions created during the profile load process.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    param()

    # Initialize the profile load count if it hasn't been initialized yet
    if (-not $Script:__PSProfileTotalCount) {
        $Script:__PSProfileTotalCount = @(
            $PROFILE.AllUsersAllHosts,
            $PROFILE.AllUsersCurrentHost,
            $PROFILE.CurrentUserAllHosts,
            $PROFILE.CurrentUserCurrentHost
        ) | Where-Object { [System.IO.File]::Exists($_) } | Measure-Object | Select-Object -ExpandProperty Count
    }

    # Check if the profile load is still in progress
    if ($Script:__PSProfileIndex -lt $Script:__PSProfileTotalCount) {
        return
    }

    if ($__PSProfileConfirmPreference) { $Global:ConfirmPreference = $__PSProfileConfirmPreference }
    if ($__PSProfileDebugPreference) { $Global:DebugPreference = $__PSProfileDebugPreference }
    if ($__PSProfileErrorActionPreference) { $Global:ErrorActionPreference = $__PSProfileErrorActionPreference }
    if ($__PSProfileErrorView) { $Global:ErrorView = $__PSProfileErrorView }
    if ($__PSProfileInformationPreference) { $Global:InformationPreference = $__PSProfileInformationPreference }

    # Remove temporary functions
    Remove-Item -Path "Function:\__PSProfile*" -Force -WarningAction Ignore -ErrorAction Ignore -Verbose:$false -Debug:$false -Confirm:$false -WhatIf:$false

    # Generate the profile load duration information
    $i = 0
    foreach ($item in $Script:___PSProfiles) {
        if ($i -lt $Script:__PSProfileIndex -and $Script:___PSProfiles[$i + 1].LoadBeginDate) {
            $EndDate = $Script:___PSProfiles[$i + 1].LoadBeginDate
        }
        else {
            $EndDate = Get-Date
        }
        Add-Member -InputObject $Script:___PSProfiles[$i] -MemberType NoteProperty -Name 'LoadEndDate' -Value $EndDate
        Add-Member -InputObject $Script:___PSProfiles[$i] -MemberType NoteProperty -Name 'LoadDuration' -Value ($EndDate - $Script:___PSProfiles[$i].LoadBeginDate)
        $i++
        if ($i -eq $Script:__PSProfileIndex) { break }
    }

    # Remove temporary variables
    Remove-Variable -Name "__PSProfile*" -Scope 1 -Force -WarningAction Ignore -ErrorAction Ignore -Verbose:$false -Debug:$false -Confirm:$false -WhatIf:$false
}
function __PSProfile-Get-ProfileInfoFromFilePath {
    <#
    .SYNOPSIS
        Gets the profile information from the file path.
    .DESCRIPTION
        This function gets the profile information from the file path.
    .PARAMETER FilePath
        The file path to check.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    param(
        [string]$FilePath
    )

    $psprofile = [PSCustomObject]@{
        Type          = $null
        Path          = $FilePath
        LoadBeginDate = Get-Date
    }

    switch ($FilePath) {
        $PROFILE.AllUsersAllHosts { $psprofile.Type = 'AllUsersAllHosts' }
        $PROFILE.AllUsersCurrentHost { $psprofile.Type = 'AllUsersCurrentHost' }
        $PROFILE.CurrentUserAllHosts { $psprofile.Type = 'CurrentUserAllHosts' }
        $PROFILE.CurrentUserCurrentHost { $psprofile.Type = 'CurrentUserCurrentHost' }
    }

    if ($psprofile.Type) { return $psprofile }
    return $null
}
function __PSProfile-Update-Help {
    <#
    .SYNOPSIS
        Updates the help for the current user.
    .DESCRIPTION
        This function updates the help for the current user.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    param()
    $__PSProfileModulesHelpLockFilePath = "${HOME}/.local/state/powershell/.updateHelpMarker"
    if (-not [System.IO.File]::Exists($__PSProfileModulesHelpLockFilePath) -or [System.IO.FileInfo]::new($__PSProfileModulesHelpLockFilePath).LastWriteTime -lt [DateTime]::Now.AddDays(-1)) {
        $__PSProfileModulesHelpLockFileDirectory = [System.IO.Path]::GetDirectoryName($__PSProfileModulesHelpLockFilePath)
        if (-not [System.IO.Directory]::Exists($__PSProfileModulesHelpLockFileDirectory)) { [void][System.IO.Directory]::CreateDirectory($__PSProfileModulesHelpLockFileDirectory) }
        [System.IO.File]::Create($__PSProfileModulesHelpLockFilePath).Dispose()
        $null = Start-ThreadJob -Name 'UpdateHelp' -ScriptBlock { Microsoft.PowerShell.Core\Update-Help -Scope CurrentUser -ErrorAction Ignore -ProgressAction Ignore }
    }
}
function __PSProfile-Register-ArgumentCompleter-AzureCli {
    <#
    .SYNOPSIS
        Registers the argument completer for the 'az' command.
    .DESCRIPTION
        This function registers the argument completer for the 'az' command.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
    param()

    if (-not (Get-Command -Name az -CommandType Application -ErrorAction Ignore)) { return }

    # https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli#enable-tab-completion-on-powershell
    Register-ArgumentCompleter -Native -CommandName az -ScriptBlock {
        param($commandName, $wordToComplete, $cursorPosition)
        $completion_file = New-TemporaryFile
        [System.Environment]::SetEnvironmentVariable('ARGCOMPLETE_USE_TEMPFILES', '1')
        [System.Environment]::SetEnvironmentVariable('_ARGCOMPLETE_STDOUT_FILENAME', $completion_file)
        [System.Environment]::SetEnvironmentVariable('COMP_LINE', $wordToComplete)
        [System.Environment]::SetEnvironmentVariable('COMP_POINT', $cursorPosition)
        [System.Environment]::SetEnvironmentVariable('_ARGCOMPLETE', '1')
        [System.Environment]::SetEnvironmentVariable('_ARGCOMPLETE_SUPPRESS_SPACE', '0')
        [System.Environment]::SetEnvironmentVariable('_ARGCOMPLETE_IFS', "`n")
        [System.Environment]::SetEnvironmentVariable('_ARGCOMPLETE_SHELL', 'powershell')
        $null = az 2>&1
        $lines = [System.IO.File]::ReadAllLines($completion_file)
        [array]::Sort($lines)
        foreach ($line in $lines) {
            [System.Management.Automation.CompletionResult]::new($line, $line, 'ParameterValue', $line)
        }
        Remove-Item $completion_file, Env:\_ARGCOMPLETE_STDOUT_FILENAME, Env:\ARGCOMPLETE_USE_TEMPFILES, Env:\COMP_LINE, Env:\COMP_POINT, Env:\_ARGCOMPLETE, Env:\_ARGCOMPLETE_SUPPRESS_SPACE, Env:\_ARGCOMPLETE_IFS, Env:\_ARGCOMPLETE_SHELL
    }
}
#endregion Profile Functions ---------------------------------------------------
