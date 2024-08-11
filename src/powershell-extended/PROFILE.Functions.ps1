# /opt/microsoft/powershell/7/profile.functions.ps1 - Source: https://githhub.com/jpawlowski/devcontainer-features/src/powershell-extended/PROFILE.Functions.ps1
# These functions are used by the user profile.ps1 files.

using namespace System.Management.Automation
using namespace System.Management.Automation.Language

#region Global Functions ======================================================
# Only define the functions if they are not already defined. Take only one function as an example.
if (-not (Get-Command -Name Test-IsWindowsTerminal -ErrorAction Ignore)) {
    function Test-IsWindowsTerminal {
        <#
        .SYNOPSIS
            Checks if the current process is running in Windows Terminal.
        .DESCRIPTION
            This function checks if the current process is running in Windows Terminal.
        .NOTES
            Credits to https://mikefrobbins.com/2024/05/16/detecting-windows-terminal-with-powershell/
        #>
        [CmdletBinding()]
        param ()

        # Check if PowerShell version is 5.1 or below, or if running on Windows
        if ($PSVersionTable.PSVersion.Major -le 5 -or $IsWindows -eq $true) {
            $currentPid = $PID

            # Loop through parent processes to check if Windows Terminal is in the hierarchy
            while ($currentPid) {
                try {
                    $process = Get-CimInstance Win32_Process -Filter "ProcessId = $currentPid" -ErrorAction Stop -Verbose:$false
                }
                catch {
                    # Return false if unable to get process information
                    return $false
                }

                Write-Verbose -Message "ProcessName: $($process.Name), Id: $($process.ProcessId), ParentId: $($process.ParentProcessId)"

                # Check if the current process is Windows Terminal
                if ($process.Name -eq 'WindowsTerminal.exe') {
                    return $true
                }
                else {
                    # Move to the parent process
                    $currentPid = $process.ParentProcessId
                }
            }

            # Return false if Windows Terminal is not found in the hierarchy
            return $false
        }
        else {
            Write-Verbose -Message 'Exiting due to non-Windows environment'
            return $false
        }
    }
}
#endregion Global Functions ---------------------------------------------------

#region Profile Functions ======================================================
# Only define the functions if they are not already defined. Take only one function as an example.
if (-not (Get-Command -Name __PSProfile-Write-ProfileLoadMessage -ErrorAction Ignore)) {
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

        if ($Force -or ($env:POWERSHELL_HIDE_PROFILE_LOAD_MESSAGES -ne $true -and (__PSProfile-Assert-IsUserInteractiveShell))) {
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
            [int]$DelaySeconds = 0
        )

        $psVersion = [System.Version]$PSVersionTable.PSVersion
        $minVersion = [System.Version]'7.2'
        $mutexName = "Global\ModuleInstallMutex"

        function Assert-PSGIsNewerVersionAvailable {
            [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
            param (
                [string]$ModuleName
            )
            $installedModule = Get-Module -ListAvailable -Name $ModuleName | Sort-Object { [version]$_.Version } -Descending | Select-Object -First 1
            $galleryModule = Find-Module -Name $ModuleName
            return $galleryModule.Version -gt $installedModule.Version
        }
        function Install-PSResourceGetIfNeeded {
            if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.PSResourceGet)) {
                if (Assert-PSGIsNewerVersionAvailable -ModuleName PowerShellGet) {
                    Install-Module -Name PowerShellGet -Force -Scope CurrentUser
                }
                Remove-Module -Name PowerShellGet -Force -ErrorAction Ignore -Confirm:$false
                Install-Module -Name Microsoft.PowerShell.PSResourceGet -Force -Scope CurrentUser
                Remove-Module -Name PowerShellGet -Force -ErrorAction Ignore -Confirm:$false
            }
        }

        try {
            __PSProfile-Import-ModuleIfNotLoaded -ModuleName $Name -ArgumentList $ArgumentList
        }
        catch {
            if ($_.FullyQualifiedErrorId -eq 'ModuleNotFound') {
                $Error.Clear() # Clear the error because we are going to solve it
                if ($psVersion -ge $minVersion -and $InstallInBackground) {
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
                                Microsoft.PowerShell.PSResourceGet\Install-PSResource -Name $moduleName -Repository PSGallery -TrustRepository -Scope CurrentUser -AcceptLicense -Confirm:$false -Quiet
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
                    } -ArgumentList $Name, $mutexName, $DelaySeconds

                    $null = Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
                        switch ($EventArgs.JobStateInfo.State) {
                            Completed {
                                Import-Module -Scope Global -Name $Event.MessageData -ErrorAction Stop -Verbose:$false -Debug:$false
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
                            Install-PSResourceGetIfNeeded
                            Microsoft.PowerShell.PSResourceGet\Install-PSResource -Name $Name -Repository PSGallery -TrustRepository -Scope CurrentUser -AcceptLicense -Confirm:$false -Quiet
                        }
                        if ($psVersion -ge $minVersion -and $ImportInBackground) {
                            Start-ThreadJob -ScriptBlock {
                                param ($moduleName)
                                Import-Module -Scope Global -Name $moduleName -ErrorAction Stop
                            } -ArgumentList $Name | Out-Null
                        }
                        else {
                            Import-Module -Scope Global -Name $moduleName -ErrorAction Stop
                        }
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
        .PARAMETER ModuleName
            The name of the module to import.
        .PARAMETER ArgumentList
            An array of arguments to pass to the module when importing it.
        .EXAMPLE
            __PSProfile-Import-ModuleIfNotLoaded -ModuleName Microsoft.PowerShell.Utility
            This will import the Microsoft.PowerShell.Utility module if it is not already loaded.
        #>
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
        param (
            [string]$ModuleName,
            [array]$ArgumentList
        )

        # Check if the module is already loaded
        if (-not (Get-Module -Name $ModuleName)) {
            # Check if the module is available
            if (Get-Module -ListAvailable -Name $ModuleName) {
                try {
                    # Import the module
                    $params = @{
                        Name        = $ModuleName
                        Scope       = 'Global'
                        ErrorAction = 'Stop'
                    }
                    if ($ArgumentList) {
                        $params.ArgumentList = $ArgumentList
                    }
                    Import-Module @params
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
        $IsInteractive = $true
        try { $null = $Host.UI.RawUI.KeyAvailable }
        catch { $IsInteractive = $false }
        $IsNonInteractive = $false
        $commandLineArgs = [System.Environment]::GetCommandLineArgs()
        if ($commandLineArgs | Where-Object { $_ -match '^-NonI.*' }) {
            # -NonInteractive
            $IsNonInteractive = $true
        }
        else {
            $hasC = $commandLineArgs | Where-Object { $_ -match '^-C.*' } # -Command
            $hasNoE = $commandLineArgs | Where-Object { $_ -match '^-NoE.*' } # -NoExit
            if ($hasC -and -not $hasNoE) {
                $IsNonInteractive = $true
            }
        }
        if (
            -not $IsNonInteractive -and
        ([System.Environment]::UserInteractive -or $IsInteractive)
        ) { return $true }
        return $false
    }
    function __PSProfile-Enable-OhMyPosh-Theme {
        <#
        .SYNOPSIS
            Enables an Oh My Posh theme.
        .DESCRIPTION
            This function enables an Oh My Posh theme.
        .EXAMPLE
            __PSProfile-Enable-OhMyPosh-Theme
            This will enable an Oh My Posh theme.
        #>
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
        param(
            [string]$Theme = 'devcontainers.minimal'
        )

        # Let codespaces always be an alias for devcontainers
        $Theme = [regex]::Replace($Theme, 'codespaces', 'devcontainers')

        # Ensure the theme file has the correct extension
        if ($Theme -notmatch '\.omp\.json$') { $Theme = "$Theme.omp.json" }

        # Find path to theme file
        if ($Theme -notmatch '^/') {
            if ([System.IO.File]::Exists("$env:HOME/.config/oh-my-posh/themes/$Theme")) {
                $Theme = "$env:HOME/.config/oh-my-posh/themes/$Theme"
            }
            else {
                if (-not $env:POSH_THEMES_PATH) { $env:POSH_THEMES_PATH = "$env:HOME/.cache/oh-my-posh/themes" }
                $Theme = "$env:POSH_THEMES_PATH/$Theme"
            }
        }

        if (Get-Command -Name 'oh-my-posh' -ErrorAction Ignore) {
            & ([ScriptBlock]::Create((oh-my-posh init pwsh --config "$Theme" --print) -join "`n"))
        }
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
        if ($Script:__PSProfilesIndex -lt $Script:__PSProfileTotalCount) {
            return
        }

        if ($__PSProfileConfirmPreference) { $Global:ConfirmPreference = $__PSProfileConfirmPreference }
        if ($__PSProfileDebugPreference) { $Global:DebugPreference = $__PSProfileDebugPreference }
        if ($__PSProfileErrorActionPreference) { $Global:ErrorActionPreference = $__PSProfileErrorActionPreference }
        if ($__PSProfileErrorView) { $Global:ErrorView = $__PSProfileErrorView }
        if ($__PSProfileInformationPreference) { $Global:InformationPreference = $__PSProfileInformationPreference }

        # Remove temporary functions
        $fnRegex = '^__PSProfile(?!Alias).*'
        foreach ($function in Get-Command -CommandType Function | Where-Object { $_.Name -match $fnRegex }) {
            Remove-Item -Path "Function:\$($function.Name)" -Force -WarningAction Ignore -ErrorAction Ignore -Verbose:$false -Debug:$false -Confirm:$false -WhatIf:$false
        }

        # Generate the profile load duration information
        $i = 0
        foreach ($item in $__PSProfiles) {
            if ($i -lt $Script:__PSProfilesIndex -and $__PSProfiles[$i + 1].LoadBeginDate) {
                $EndDate = $__PSProfiles[$i + 1].LoadBeginDate
            }
            else {
                $EndDate = Get-Date
            }
            Add-Member -InputObject $__PSProfiles[$i] -MemberType NoteProperty -Name 'LoadEndDate' -Value $EndDate
            Add-Member -InputObject $__PSProfiles[$i] -MemberType NoteProperty -Name 'LoadDuration' -Value ($EndDate - $__PSProfiles[$i].LoadBeginDate)
            $i++
            if ($i -eq $Script:__PSProfilesIndex) { break }
        }

        # Remove temporary variables
        $varRegex = '^__PSProfile(?!Source|s).*'
        foreach ($variable in Get-Variable -Scope 1 | Where-Object { $_.Name -match $varRegex }) {
            Remove-Variable -Name $variable.Name -Scope 1 -Force -WarningAction Ignore -ErrorAction Ignore -Verbose:$false -Debug:$false -Confirm:$false -WhatIf:$false
        }
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
    function __PSProfile-Invoke-CustomProfileFilePath {
        <#
        .SYNOPSIS
            Invokes a custom profile file based on the provided file path and custom suffix.
        .DESCRIPTION
            This function modifies the provided profile file path by appending a custom suffix and delimiter.
            If the resulting custom profile file exists, it is dot-sourced (executed in the current scope).
        .PARAMETER FilePath
            The path to the original profile file. This parameter is mandatory.
        .PARAMETER CustomSuffix
            The custom suffix to append to the file name. Default is 'my'.
        .PARAMETER Delimiter
            The delimiter to use between the original file name and the custom suffix. Default is '.'.
        .EXAMPLE
            __PSProfile-Invoke-CustomProfileFilePath -FilePath "C:\Users\Profile.ps1" -CustomSuffix "custom" -Delimiter "_"
            This will look for a file named "C:\Users\Profile_custom.ps1" and dot-source it if it exists.
        .NOTES
            This function ensures that the custom suffix starts with the delimiter and ends with '.ps1'.
        #>
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '')]
        param(
            [Parameter(Mandatory = $true)]
            [string]$FilePath,
            [string]$CustomSuffix = 'my',
            [string]$Delimiter = '.'
        )

        if ($CustomSuffix -notmatch "^$([regex]::Escape($Delimiter))") {
            $CustomSuffix = "$Delimiter$CustomSuffix"
        }

        if ($CustomSuffix -notmatch '\.ps1$') {
            $CustomSuffix = "$CustomSuffix.ps1"
        }

        $FilePath = [regex]::Replace($FilePath, '\.ps1$', $CustomSuffix)

        if ([System.IO.File]::Exists($FilePath)) {
            . $FilePath
        }
    }
}
#endregion Profile Functions ---------------------------------------------------

#region Global Variables =======================================================
if (-not $Script:__PSProfiles) {
    $Script:__PSProfiles = [object[]]::new(4)
    $Script:__PSProfilesIndex = 0
}
if ($Script:__PSProfilesIndex -lt 4) {
    $Script:__PSProfiles[$Script:__PSProfilesIndex] = (__PSProfile-Get-ProfileInfoFromFilePath -FilePath $MyInvocation.ScriptName)
    $Script:__PSProfilesIndex++
}
#endregion Global Variables ----------------------------------------------------

#region Custom Functions =======================================================
__PSProfile-Invoke-CustomProfileFilePath -FilePath $MyInvocation.ScriptName -CustomSuffix $(if ($MyInvocation.ScriptName -eq $PROFILE.AllUsersAllHosts) { 'my.functions' } else { 'functions' })
#endregion Custom Functions ----------------------------------------------------
