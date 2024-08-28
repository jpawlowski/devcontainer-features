#!/usr/bin/env pwsh

<#PSScriptInfo
.VERSION 1.0.0
.GUID a3238c59-8a0e-4c11-a334-f071772d1255
.AUTHOR Julian Pawlowski
.COPYRIGHT © 2024 Julian Pawlowski.
.TAGS nerd-fonts, nerdfonts
.LICENSEURI https://github.com/jpawlowski/devcontainer-features/blob/main/LICENSE.txt
.PROJECTURI https://github.com/jpawlowski/devcontainer-features
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
    Version 1.0.0 (2024-08-20)
    - Initial release.
#>

<#
.SYNOPSIS
    Install Nerd Fonts on Windows, macOS, or Linux.

    You may also run this script directly from the web using the following command:

    ```powershell
    & ([scriptblock]::Create((iwr 'https://bit.ly/ps-install-nerdfont')))
    ```

.DESCRIPTION
    This PowerShell script installs Nerd Fonts on Windows, macOS, or Linux.
    Nerd Fonts is a project that patches developer targeted fonts with a high number of glyphs (icons).

    The script also supports the installation of the Cascadia Code fonts from the Microsoft repository.
    These fonts have native Nerd Font and Powerline support since version 2404.23.

    The script downloads the font archive from the GitHub release page and extracts the font files to
    the user's font directory, or the system font directory when using the AllUsers scope on Windows
    with elevated permissions.

    You may also run this script directly from the web using the following command:

    ```powershell
    & ([scriptblock]::Create((iwr 'https://bit.ly/ps-install-nerdfont')))
    ```

    Parameters may be passed just like any other PowerShell script. For example:

    ```powershell
    & ([scriptblock]::Create((iwr 'https://bit.ly/ps-install-nerdfont'))) -Name cascadia-code, cascadia-mono
    ```

.PARAMETER Name
    The name of the Nerd Font to install.
    Multiple font names can be specified as an array of strings.
    If no font name is specified, the script provides an interactive menu to select the font to install
    (unless the All parameter is used).

    The menu is displayed only if the script is run in an interactive environment.

    If the script is run in a non-interactive environment, the Name parameter is mandatory.

.PARAMETER All
    Install all available Nerd Fonts.
    You will be prompted to confirm the installation for each font with the option to skip, cancel,
    or install all without further confirmation.

.PARAMETER List
    List available Nerd Fonts matching the specified pattern.
    Use '*' or 'All' to list all available Nerd Fonts.
    This parameter does not install any fonts.

.PARAMETER Scope
    Defined the scope in which the Nerd Font should be installed on Windows.
    The default value is CurrentUser.

    The AllUsers scope requires elevated permissions on Windows.
    The CurrentUser scope installs the font for the current user only.

    The scope parameter is ignored on macOS and Linux.

.PARAMETER Force
    Overwrite existing font files instead of skipping them.

.EXAMPLE
    Install-NerdFont -Name cascadia-code
    Install the Cascadia Code fonts from the Microsoft repository.

.EXAMPLE
    Install-NerdFont -Name cascadia-mono
    Install the Cascadia Mono fonts from the Microsoft repository.

.EXAMPLE
    Install-NerdFont -Name cascadia-code, cascadia-mono
    Install the Cascadia Code and Cascadia Mono fonts from the Microsoft repository.

.EXAMPLE
    Install-NerdFont -All -WhatIf
    Show what would happen if all fonts were installed.

.EXAMPLE
    Install-NerdFont -List cascadia*
    List all fonts with names starting with 'cascadia'.

.NOTES
    This script must be run on your local machine, not in a container.

    If available, OpenType fonts are preferred over TrueType fonts.
    Also, static fonts are preferred over variable fonts.
    Both is determined by directories in the font archive and the font file extension.
#>

[CmdletBinding(DefaultParameterSetName = 'ByName', SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'ByAll')]
    [switch]$All,

    [Parameter(Mandatory = $false, ParameterSetName = 'ListOnly')]
    [AllowNull()]
    [AllowEmptyString()]
    [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
            @('All') | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
        })]
    [string]$List,

    [Parameter(Mandatory = $false, ParameterSetName = 'ByAll', HelpMessage = 'In which scope do you want to install the Nerd Font, AllUsers or CurrentUser?')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ByName', HelpMessage = 'In which scope do you want to install the Nerd Font, AllUsers or CurrentUser?')]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string]$Scope = 'CurrentUser',

    [switch]$Force
)

dynamicparam {
    # Define the URL and cache file path
    $url = 'https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/bin/scripts/lib/fonts.json'
    $cacheFilePath = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), 'github-nerd-fonts.json')
    $cacheDuration = [TimeSpan]::FromMinutes(2)

    #region Functions ==========================================================
    function Get-FontsListFromWeb {
        <#
        .SYNOPSIS
        Fetch fonts list from the web server.

        .DESCRIPTION
        This function fetches the fonts list from the specified web server URL.
        It also adds a release URL property to each font object.
        #>
        try {
            $fonts = (Invoke-RestMethod -Uri $url -ErrorAction Stop -Verbose:$false -Debug:$false).fonts
            $releaseUrl = "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"
            foreach ($font in $fonts) {
                $font.PSObject.Properties.Add([PSNoteProperty]::new("releaseUrl", $releaseUrl))
            }
            return $fonts
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }

    function Get-FontsListFromCache {
        <#
        .SYNOPSIS
        Load fonts list from cache.

        .DESCRIPTION
        This function loads the fonts list from a cache file if it exists and is not expired.
        #>
        if ([System.IO.Directory]::Exists($cacheFilePath)) {
            $cacheFile = Get-Item $cacheFilePath
            if ((Get-Date) -lt $cacheFile.LastWriteTime.Add($cacheDuration)) {
                return Get-Content $cacheFilePath | ConvertFrom-Json
            }
        }
        return $null
    }

    function Save-FontsListToCache($fonts) {
        <#
        .SYNOPSIS
        Save fonts list to cache.

        .DESCRIPTION
        This function saves the fonts list to a cache file in JSON format.
        #>
        $fonts | ConvertTo-Json | Set-Content $cacheFilePath
    }

    function Add-CustomEntries($fonts) {
        <#
        .SYNOPSIS
        Add custom entries to the fonts list.

        .DESCRIPTION
        This function adds custom font entries to the provided fonts list and sorts them by folder name.
        #>
        $customEntries = @(
            [PSCustomObject]@{
                unpatchedName          = 'Cascadia Code Font Family'
                licenseId              = 'OFL-1.1-RFN'
                RFN                    = $true
                version                = 'latest'
                patchedName            = 'Cascadia Code Font Family'
                folderName             = 'CascadiaCode'
                imagePreviewFont       = 'Cascadia Code Font Family'
                imagePreviewFontSource = $null
                linkPreviewFont        = 'cascadia-code'
                caskName               = 'cascadia-code'
                repoRelease            = $false
                description            = 'The official Cascadia Code font by Microsoft with all variants, including Nerd Font and Powerline'
                releaseUrl             = 'https://api.github.com/repos/microsoft/cascadia-code/releases/latest'
            },
            [PSCustomObject]@{
                unpatchedName          = 'Cascadia Code NF'
                licenseId              = 'OFL-1.1-RFN'
                RFN                    = $true
                version                = 'latest'
                patchedName            = 'Cascadia Code NF'
                folderName             = 'CascadiaCodeNF'
                imagePreviewFont       = 'Cascadia Code Nerd Font'
                imagePreviewFontSource = $null
                linkPreviewFont        = 'cascadia-code'
                caskName               = 'cascadia-code-nerd-font'
                repoRelease            = $false
                description            = 'The official Cascadia Code font by Microsoft that is enabled with Nerd Font symbols'
                releaseUrl             = 'https://api.github.com/repos/microsoft/cascadia-code/releases/latest'
            },
            [PSCustomObject]@{
                unpatchedName          = 'Cascadia Code PL'
                licenseId              = 'OFL-1.1-RFN'
                RFN                    = $true
                version                = 'latest'
                patchedName            = 'Cascadia Code PL'
                folderName             = 'CascadiaCodePL'
                imagePreviewFont       = 'Cascadia Code Powerline Font'
                imagePreviewFontSource = $null
                linkPreviewFont        = 'cascadia-code'
                caskName               = 'cascadia-code-powerline-font'
                repoRelease            = $false
                description            = 'The official Cascadia Code font by Microsoft that is enabled with Powerline symbols'
                releaseUrl             = 'https://api.github.com/repos/microsoft/cascadia-code/releases/latest'
            },
            [PSCustomObject]@{
                unpatchedName          = 'Cascadia Mono Font Family'
                licenseId              = 'OFL-1.1-RFN'
                RFN                    = $true
                version                = 'latest'
                patchedName            = 'Cascadia Mono Font Family'
                folderName             = 'CascadiaMono'
                imagePreviewFont       = 'Cascadia Mono Font Family'
                imagePreviewFontSource = $null
                linkPreviewFont        = $null
                caskName               = 'cascadia-mono'
                repoRelease            = $false
                description            = 'The official Cascadia Mono font by Microsoft with all variants, including Nerd Font and Powerline'
                releaseUrl             = 'https://api.github.com/repos/microsoft/cascadia-code/releases/latest'
            },
            [PSCustomObject]@{
                unpatchedName          = 'Cascadia Mono NF'
                licenseId              = 'OFL-1.1-RFN'
                RFN                    = $true
                version                = 'latest'
                patchedName            = 'Cascadia Mono NF'
                folderName             = 'CascadiaMonoNF'
                imagePreviewFont       = 'Cascadia Mono Nerd Font'
                imagePreviewFontSource = $null
                linkPreviewFont        = $null
                caskName               = 'cascadia-mono-nerd-font'
                repoRelease            = $false
                description            = 'The official Cascadia Mono font by Microsoft that is enabled with Nerd Font symbols'
                releaseUrl             = 'https://api.github.com/repos/microsoft/cascadia-code/releases/latest'
            },
            [PSCustomObject]@{
                unpatchedName          = 'Cascadia Mono PL'
                licenseId              = 'OFL-1.1-RFN'
                RFN                    = $true
                version                = 'latest'
                patchedName            = 'Cascadia Mono PL'
                folderName             = 'CascadiaMonoPL'
                imagePreviewFont       = 'Cascadia Mono Powerline Font'
                imagePreviewFontSource = $null
                linkPreviewFont        = $null
                caskName               = 'cascadia-mono-powerline-font'
                repoRelease            = $false
                description            = 'The official Cascadia Mono font by Microsoft that is enabled with Powerline symbols'
                releaseUrl             = 'https://api.github.com/repos/microsoft/cascadia-code/releases/latest'
            }
        )

        # Combine the original fonts with custom entries and sort by folderName
        $allFonts = $fonts + $customEntries
        $sortedFonts = $allFonts | Sort-Object -Property caskName

        return $sortedFonts
    }
    #endregion Functions -------------------------------------------------------

    # Try to load fonts list from cache
    $allNerdFonts = Get-FontsListFromCache

    # If cache is not valid, fetch from web, add custom entries, and update cache
    if (-not $allNerdFonts) {
        $allNerdFonts = Get-FontsListFromWeb
        $allNerdFonts = Add-CustomEntries $allNerdFonts
        Save-FontsListToCache $allNerdFonts
    }

    # Extract caskName values for auto-completion
    $caskNames = [string[]]@($allNerdFonts | ForEach-Object { $_.caskName })

    # Define the name and type of the dynamic parameter
    $paramName = 'Name'
    $paramType = [string[]]

    # Create a collection to hold the attributes for the dynamic parameter
    $attributes = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()

    # Convert the caskNames array to a string representation
    $caskNamesString = $caskNames -join "', '"
    $caskNamesString = "@('$caskNamesString')"

    # Create an ArgumentCompleter attribute using the caskName values for auto-completion and add it to the collection
    $argumentCompleterScript = [scriptblock]::Create(@"
param(`$commandName, `$parameterName, `$wordToComplete, `$commandAst, `$fakeBoundParameter)
# Static array of cask names for auto-completion
`$caskNames = $caskNamesString

# Filter and return matching cask names
`$caskNames | Where-Object { `$_ -like "`$wordToComplete*" } | ForEach-Object {
    [System.Management.Automation.CompletionResult]::new(`$_, `$_, 'ParameterValue', `$_)
}
"@)

    $argumentCompleterAttribute = [System.Management.Automation.ArgumentCompleterAttribute]::new($argumentCompleterScript)
    $attributes.Add($argumentCompleterAttribute)

    # Create a Parameter attribute and add it to the collection
    $paramAttribute = [System.Management.Automation.ParameterAttribute]::new()
    $paramAttribute.Mandatory = $(
        # Make the parameter mandatory if the script is not running interactively
        if (
            $null -ne ([System.Environment]::GetCommandLineArgs() | Where-Object { $_ -match '^-NonI.*' }) -or
            (
                $null -ne ($__PSProfileEnvCommandLineArgs | Where-Object { $_ -match '^-C.*' }) -and
                $null -eq ($__PSProfileEnvCommandLineArgs | Where-Object { $_ -match '^-NoE.*' })
            )
        ) {
            $true
        }
        elseif ($Host.UI.RawUI.KeyAvailable -or [System.Environment]::UserInteractive) {
            $false
        }
        else {
            $true
        }
    )
    $paramAttribute.Position = 0
    $paramAttribute.ParameterSetName = 'ByName'
    $paramAttribute.HelpMessage = 'Which Nerd Font do you want to install?' + "`n" + "Available values: $($caskNames -join ', ')"
    $paramAttribute.ValueFromPipeline = $true
    $paramAttribute.ValueFromPipelineByPropertyName = $true
    $attributes.Add($paramAttribute)

    # Create the dynamic parameter
    $runtimeParam = [System.Management.Automation.RuntimeDefinedParameter]::new($paramName, $paramType, $attributes)

    # Create a dictionary to hold the dynamic parameters
    $paramDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
    $paramDictionary.Add($paramName, $runtimeParam)

    # Return the dictionary
    return $paramDictionary
}

begin {
    if ($PSBoundParameters.ContainsKey('List')) {
        # Set default value if List is null or empty
        if ([string]::IsNullOrEmpty($List)) {
            $List = "*"
        }
        else {
            $List = $List.Trim()
        }

        # Handle special case for 'All'
        if ($List -eq 'All') {
            $List = "*"
        }
        elseif ($List -notmatch '\*') {
            # Ensure the List contains wildcard characters
            $List = "*$List*"
        }

        # Filter and format the output
        $allNerdFonts | Where-Object { $_.caskName -like $List } | ForEach-Object {
            [PSCustomObject]@{
                Name        = $_.caskName
                DisplayName = $_.imagePreviewFont
                Description = $_.description
                SourceUrl   = $_.releaseUrl -replace '^(https?://)(?:[^/]+\.)*([^/]+\.[^/]+)/repos/([^/]+)/([^/]+).*', '$1$2/$3/$4'
            }
        }
        return
    }

    if (
        $null -ne $env:REMOTE_CONTAINERS -or
        $null -ne $env:CODESPACES -or
        $null -ne $env:WSL_INTEROP
    ) {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('This script must be run on your local machine, not in a container.'),
                'NotLocalMachine',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
        )
    }

    if (
        $Scope -eq 'AllUsers' -and
        $PSVersionTable.Platform -ne 'Unix' -and
        -not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
    ) {
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Elevated permissions are required to install fonts for all users. Alternatively, you can install fonts for the current user using the -Scope parameter with the CurrentUser value.'),
                'InsufficientPermissions',
                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                $null
            )
        )
    }

    #region Functions ==========================================================
    function Show-Menu {
        <#
        .SYNOPSIS
        Displays a menu for selecting fonts.

        .DESCRIPTION
        This function clears the host and displays a menu with options for selecting fonts.
        It handles user input and terminal resizing to dynamically adjust the menu display.
        #>
        param (
            $Options
        )
        Clear-Host

        function Show-MenuOptions {
            <#
            .SYNOPSIS
            Draws the menu options.

            .DESCRIPTION
            This function prints the menu options in a formatted manner.
            It calculates the number of columns and rows based on the terminal width and displays the options accordingly.
            #>
            param (
                $Options,
                $terminalWidth
            )

            # Add the 'All Fonts' option at the top
            $Options = @([pscustomobject]@{ imagePreviewFont = 'All Fonts'; unpatchedName = 'All'; caskName = 'All' }) + $Options

            # Calculate the maximum width of each column
            $maxOptionLength = ($Options | ForEach-Object { $_.imagePreviewFont.Length } | Measure-Object -Maximum).Maximum + 1 # 1 for padding
            $maxIndexLength = ($Options.Length).ToString().Length
            $linkSymbolLength = 1
            $columnWidth = $maxIndexLength + $maxOptionLength + $linkSymbolLength + 3  # 3 for padding and ': '

            # Calculate the number of columns that can fit in the terminal width
            $numColumns = [math]::Floor($terminalWidth / $columnWidth)

            # Calculate the number of rows
            $numRows = [math]::Ceiling($Options.Length / $numColumns)

            # Print the centered and bold title
            if ($IsCoreCLR) {
                $title = "`u{1F913} $($PSStyle.Bold)`e]8;;https://www.nerdfonts.com/`e\Nerd Fonts`e]8;;`e\ Installation$($PSStyle.BoldOff)"
            }
            else {
                $title = 'Nerd Fonts Installation'
            }
            $totalWidth = $columnWidth * $numColumns
            $padding = [math]::Max(0, ($totalWidth - ($title.Length / 2)) / 2)
            Write-Host (' ' * $padding + $title) -ForegroundColor Cyan -NoNewline
            Write-Host -ForegroundColor Cyan
            Write-Host (('_' * $totalWidth) + "`n") -ForegroundColor Cyan

            # Print the options in rows
            for ($row = 0; $row -lt $numRows; $row++) {
                for ($col = 0; $col -lt $numColumns; $col++) {
                    $index = $row + $col * $numRows
                    if ($index -lt $Options.Length) {
                        $number = $index
                        $fontName = $Options[$index].imagePreviewFont
                        $numberText = ('{0,' + $maxIndexLength + '}') -f $number
                        $linkSymbol = "`u{2197}" # Up-Right Arrow

                        if ($index -eq 0) {
                            # Special formatting for 'All Fonts'
                            Write-Host -NoNewline -ForegroundColor Magenta $numberText
                            Write-Host -NoNewline -ForegroundColor Magenta ': '
                            Write-Host -NoNewline -ForegroundColor Magenta "$($PSStyle.Italic)$fontName$($PSStyle.ItalicOff)  "
                        }
                        else {
                            Write-Host -NoNewline -ForegroundColor DarkYellow $numberText
                            Write-Host -NoNewline -ForegroundColor Yellow ': '
                            if ($fontName -match '^(.+)(Font Family)(.*)$') {
                                if ($IsCoreCLR -and $Options[$index].linkPreviewFont -is [string] -and -not [string]::IsNullOrEmpty($Options[$index].linkPreviewFont)) {
                                    $link = $Options[$index].linkPreviewFont
                                    if ($link -notmatch '^https?://') {
                                        $link = "https://www.programmingfonts.org/#$link"
                                    }
                                    $clickableLinkSymbol = " `e]8;;$link`e\$linkSymbol`e]8;;`e\"
                                    Write-Host -NoNewline -ForegroundColor White "$($PSStyle.Bold)$($Matches[1])$($PSStyle.BoldOff)"
                                    Write-Host -NoNewline -ForegroundColor Gray "$($PSStyle.Italic)$($Matches[2])$($PSStyle.ItalicOff)"
                                    Write-Host -NoNewline -ForegroundColor White "$($Matches[3])"
                                    Write-Host -NoNewline -ForegroundColor DarkBlue "$clickableLinkSymbol"
                                }
                                else {
                                    Write-Host -NoNewline -ForegroundColor White "$($PSStyle.Bold)$($Matches[1])$($PSStyle.BoldOff)"
                                    Write-Host -NoNewline -ForegroundColor Gray "$($PSStyle.Italic)$($Matches[2])$($PSStyle.ItalicOff)"
                                    Write-Host -NoNewline -ForegroundColor White "$($Matches[3])  "
                                }
                            }
                            else {
                                if ($IsCoreCLR -and $Options[$index].linkPreviewFont -is [string] -and -not [string]::IsNullOrEmpty($Options[$index].linkPreviewFont)) {
                                    $link = $Options[$index].linkPreviewFont
                                    if ($link -notmatch '^https?://') {
                                        $link = "https://www.programmingfonts.org/#$link"
                                    }
                                    $clickableLinkSymbol = " `e]8;;$link`e\$linkSymbol`e]8;;`e\"
                                    Write-Host -NoNewline -ForegroundColor White "$($PSStyle.Bold)$fontName$($PSStyle.BoldOff)"
                                    Write-Host -NoNewline -ForegroundColor DarkBlue "$clickableLinkSymbol"
                                }
                                else {
                                    Write-Host -NoNewline -ForegroundColor White "$($PSStyle.Bold)$fontName$($PSStyle.BoldOff)  "
                                }
                            }
                        }
                        # Add padding to align columns
                        $paddingLength = $maxOptionLength - $fontName.Length
                        Write-Host -NoNewline (' ' * $paddingLength)
                    }
                }
                Write-Host
            }
        }

        # Initial terminal width
        $initialWidth = [console]::WindowWidth

        # Draw the initial menu
        Show-MenuOptions -Options $Options -terminalWidth $initialWidth

        Write-Host "`nEnter 'q' to quit." -ForegroundColor Cyan

        # Loop to handle user input and terminal resizing
        while ($true) {
            $currentWidth = [console]::WindowWidth
            if ($currentWidth -ne $initialWidth) {
                Clear-Host
                Show-MenuOptions -Options $Options -terminalWidth $currentWidth
                Write-Host "`nEnter 'q' to quit." -ForegroundColor Cyan
                $initialWidth = $currentWidth
            }

            $selection = Read-Host "`nSelect one or more numbers separated by commas"
            if ($selection -eq 'q') {
                return 'quit'
            }

            # Remove spaces and split the input by commas
            $selection = $selection -replace '\s', ''
            $numbers = $selection -split ',' | Select-Object -Unique

            # Validate each number
            $validSelections = @()
            $invalidSelections = @()
            foreach ($number in $numbers) {
                if ($number -match '^-?\d+$') {
                    $index = [int]$number - 1
                    if ($index -lt 0) {
                        return 'All'
                    }
                    elseif ($index -ge 0 -and $index -lt $Options.Count) {
                        $validSelections += $Options[$index]
                    }
                    else {
                        $invalidSelections += $number
                    }
                }
                else {
                    $invalidSelections += $number
                }
            }

            if ($invalidSelections.Count -eq 0) {
                return $validSelections.caskName
            }
            else {
                Write-Host "Invalid selection(s): $($invalidSelections -join ', '). Please enter valid numbers between 0 and $($Options.Length) or 'q' to quit." -ForegroundColor Red
            }
        }
    }

    function Invoke-GitHubApiRequest {
        <#
        .SYNOPSIS
        Makes anonymous requests to GitHub API and handles rate limiting.

        .DESCRIPTION
        This function sends a request to the specified GitHub API URI and handles rate limiting by retrying the request
        up to a maximum number of retries. It also converts JSON responses to PowerShell objects.
        #>
        param (
            [string]$Uri
        )
        $maxRetries = 5
        $retryCount = 0
        $baseWaitTime = 15

        while ($retryCount -lt $maxRetries) {
            try {
                $headers = @{}
                $parsedUri = [System.Uri]$Uri
                if ($parsedUri.Host -eq "api.github.com") {
                    $headers["Accept"] = "application/vnd.github.v3+json"
                }

                $response = Invoke-RestMethod -Uri $Uri -Headers $headers -ErrorAction Stop -Verbose:$false -Debug:$false

                return [PSCustomObject]@{
                    Headers = $response.PSObject.Properties["Headers"].Value
                    Content = $response
                }
            }
            catch {
                if ($_.Exception.Response.StatusCode -eq 403 -or $_.Exception.Response.StatusCode -eq 429) {
                    $retryAfter = $null
                    $rateLimitReset = $null
                    $waitTime = 0

                    if ($_.Exception.Response.Headers -and $_.Exception.Response.Headers["Retry-After"]) {
                        $retryAfter = $_.Exception.Response.Headers["Retry-After"]
                    }
                    if ($_.Exception.Response.Headers -and $_.Exception.Response.Headers["X-RateLimit-Reset"]) {
                        $rateLimitReset = $_.Exception.Response.Headers["X-RateLimit-Reset"]
                    }

                    if ($retryAfter) {
                        $waitTime = [int]$retryAfter
                    }
                    elseif ($rateLimitReset) {
                        $resetTime = [DateTimeOffset]::FromUnixTimeSeconds([int]$rateLimitReset).LocalDateTime
                        $waitTime = ($resetTime - (Get-Date)).TotalSeconds
                    }

                    if ($waitTime -gt 0 -and $waitTime -le 60) {
                        Write-Host "Rate limit exceeded. Waiting for $waitTime seconds."
                        Start-Sleep -Seconds $waitTime
                    }
                    else {
                        $exponentialWait = $baseWaitTime * [math]::Pow(2, $retryCount)
                        Write-Host "Rate limit exceeded. Waiting for $exponentialWait seconds."
                        Start-Sleep -Seconds $exponentialWait
                    }
                    $retryCount++
                }
                else {
                    $PSCmdlet.ThrowTerminatingError($_)
                }
            }
        }
        $PSCmdlet.ThrowTerminatingError(
            [System.Management.Automation.ErrorRecord]::new(
                [System.Exception]::new('Max retries exceeded. Please try again later.'),
                'MaxRetriesExceeded',
                [System.Management.Automation.ErrorCategory]::ResourceUnavailable,
                $null
            )
        )
    }

    function Invoke-GitHubApiPaginatedRequest {
        <#
        .SYNOPSIS
        Fetches all pages of a paginated response if the host is api.github.com.

        .DESCRIPTION
        This function sends requests to the specified GitHub API URI and handles pagination by following the 'next' links
        in the response headers. It collects all pages of data and returns them as a single array.
        #>
        param (
            [string]$Uri
        )
        $allData = @()
        $parsedUri = [System.Uri]$Uri

        if ($parsedUri.Host -eq "api.github.com") {
            while ($true) {
                $response = Invoke-GitHubApiRequest -Uri $Uri
                if ($null -eq $response) {
                    break
                }
                $data = $response.Content
                $allData += $data
                $linkHeader = $null
                if ($response.Headers -and $response.Headers["Link"]) {
                    $linkHeader = $response.Headers["Link"]
                }
                if ($linkHeader -notmatch 'rel="next"') {
                    break
                }
                $nextLink = ($linkHeader -split ',') | Where-Object { $_ -match 'rel="next"' } | ForEach-Object { ($_ -split ';')[0].Trim('<> ') }
                $Uri = $nextLink
            }
        }
        else {
            $response = Invoke-GitHubApiRequest -Uri $Uri
            $allData = $response.Content
        }
        return $allData
    }
    #endregion Functions -------------------------------------------------------

    # Provide interactive selection if no font name is specified
    if (-not $PSBoundParameters.Name -and -not $PSBoundParameters.All) {
        do {
            $Name = Show-Menu -Options $allNerdFonts
            if ($Name -eq 'quit') {
                Write-Host "Selection process canceled."
                if ($null -eq $MyInvocation.InvocationName -or $MyInvocation.InvocationName -eq '&') {
                    # Running as a script block
                    return
                }
                else {
                    # Running as a standalone script
                    exit
                }
            }
        } while (-not $Name)

        if ($Name) {
            if ($Name -eq 'All') {
                Write-Host "`nYou selected all fonts.`n" -ForegroundColor Yellow
                # Proceed with the installation of all fonts
            }
            else {
                Write-Host "`nYour selected font(s): $($Name -join ', ')`n" -ForegroundColor Yellow
                # Proceed with the installation of the selected font(s)
            }
        }
        else {
            Write-Host 'No font selected.'
            if ($null -eq $MyInvocation.InvocationName -or $MyInvocation.InvocationName -eq '&') {
                # Running as a script block
                return
            }
            else {
                # Running as a standalone script
                exit
            }
    }
    }
    elseif ($PSBoundParameters.Name) {
        $Name = $PSBoundParameters.Name
    }

    $nerdFontsToInstall = if ($PSBoundParameters.All -or $Name -contains 'All') {
        $allNerdFonts
    }
    else {
        $allNerdFonts | Where-Object { $Name -contains $_.caskName }
    }

    if ($nerdFontsToInstall.Count -eq 0) {
        Write-Error "No matching fonts found."
        if ($null -eq $MyInvocation.InvocationName -or $MyInvocation.InvocationName -eq '&') {
            # Running as a script block
            return
        }
        else {
            # Running as a standalone script
            exit
        }
}

    # Fetch releases for each unique URL
    $fontReleases = @{}
    foreach ($url in $nerdFontsToInstall.releaseUrl | Sort-Object -Unique) {
        Write-Verbose "Fetching release data for $url"
        $release = Invoke-GitHubApiPaginatedRequest -Uri $url
        $fontReleases[$url] = @{
            ReleaseData = $release
            Sha256Data  = @{}
        }

        # Check if the release contains a SHA-256.txt asset
        $shaAsset = $release.assets | Where-Object { $_.name -eq 'SHA-256.txt' }
        if ($shaAsset) {
            $shaUrl = $shaAsset.browser_download_url
            Write-Verbose "Fetching SHA-256.txt content from $shaUrl"
            $shaContent = Invoke-WebRequest -Uri $shaUrl -ErrorAction Stop -Verbose:$false -Debug:$false

            # Convert the binary content to a string
            $shaContentString = [System.Text.Encoding]::UTF8.GetString($shaContent.Content)

            # Parse the SHA-256.txt content
            $shaLines = $shaContentString -split "`n"
            foreach ($line in $shaLines) {
                if ($line -match '^\s*([a-fA-F0-9]{64})\s+(.+)$') {
                    $sha256 = $matches[1]
                    $fileName = $matches[2].Trim()
                    $fontReleases[$url].Sha256Data[$fileName] = $sha256
                    Write-Debug "SHA-256: $sha256, File: $fileName"
                }
            }
        }
    }

    if ($IsMacOS) {
        if ($Scope -eq 'AllUsers') {
            $fontDestinationFolderPath = '/Library/Fonts'
        }
        else {
            $fontDestinationFolderPath = "${HOME}/Library/Fonts"
        }
    }
    elseif ($IsLinux) {
        if ($Scope -eq 'AllUsers') {
            $fontDestinationFolderPath = '/usr/share/fonts'
        }
        else {
            $fontDestinationFolderPath = "${HOME}/.local/share/fonts"
        }
    }
    elseif ($Scope -eq 'AllUsers') {
        $fontDestinationFolderPath = "${env:windir}\Fonts"
    }
    else {
        $fontDestinationFolderPath = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    }
    $null = [System.IO.Directory]::CreateDirectory($fontDestinationFolderPath)
    Write-Verbose "Font Destination directory: $fontDestinationFolderPath"

    # Generate a unique temporary directory to store the font files
    $tempFile = [System.IO.Path]::GetTempFileName()
    $tempPath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($tempFile), [System.IO.Path]::GetFileNameWithoutExtension($tempFile))
    $null = [System.IO.Directory]::CreateDirectory($tempPath)
    [System.IO.File]::Delete($tempFile)
    Write-Verbose "Using temporary directory: $tempPath"
}

process {
    try {
        Write-Verbose "Installing $($nerdFontsToInstall.Count) Nerd Fonts to $Scope scope."

        foreach ($nerdFont in $nerdFontsToInstall) {
            $sourceName = $nerdFont.releaseUrl -replace '^https?://(?:[^/]+\.)*([^/]+\.[^/]+)/repos/([^/]+)/([^/]+).*', '$1/$2/$3'

            if (
                $PSCmdlet.ShouldProcess(
                    "Install '$($nerdFont.imagePreviewFont)' from $sourceName",
                    "Do you confirm to install '$($nerdFont.imagePreviewFont)' from $sourceName ?",
                    "Nerd Fonts Installation"
                )
            ) {
                Write-Verbose "Processing font: $($nerdFont.folderName) [$($nerdFont.caskName)] ($($nerdFont.imagePreviewFont)) from $sourceName"
                if ($null -eq $nerdFont.imagePreviewFontSource) {
                    $assetUrl = $fontReleases[$nerdFont.releaseUrl].ReleaseData.assets | Where-Object { $_.name -match "\.zip$" } | Select-Object -ExpandProperty browser_download_url
                }
                else {
                    $assetUrl = $fontReleases[$nerdFont.releaseUrl].ReleaseData.assets | Where-Object { $_.name -match "^$($nerdFont.folderName)\.zip$" } | Select-Object -ExpandProperty browser_download_url
                }
                if ([string]::IsNullOrEmpty($assetUrl)) {
                    if ($WhatIfPreference -eq $true) {
                        Write-Warning "Nerd Font '$($nerdFont.folderName)' not found."
                    }
                    else {
                        Write-Error "Nerd Font '$($nerdFont.folderName)' not found."
                    }
                    continue
                }
                if ($assetUrl -notmatch '\.zip$') {
                    if ($WhatIfPreference -eq $true) {
                        Write-Warning "Nerd Font '$($nerdFont.folderName)' archive format is not supported."
                    }
                    else {
                        Write-Error "Nerd Font '$($nerdFont.folderName)' archive format is not supported."
                    }
                    continue
                }

                Write-Verbose "Font archive URL: $assetUrl"

                # Download the zip file if not already downloaded
                $zipPath = [System.IO.Path]::Combine($tempPath, [System.IO.Path]::GetFileName(([System.Uri]::new($assetUrl)).LocalPath))
                if (Test-Path -Path $zipPath) {
                    Write-Verbose "Font archive already downloaded: $zipPath"
                }
                else {
                    Write-Verbose "Downloading font archive from $assetUrl to $zipPath"
                    Invoke-WebRequest -Uri $assetUrl -OutFile $zipPath -ErrorAction Stop -Verbose:$false -Debug:$false
                }

                # Verify the SHA-256 hash if available
                if ($fontReleases[$nerdFont.releaseUrl].Sha256Data.Count -gt 0) {
                    if (-not $fontReleases[$nerdFont.releaseUrl].Sha256Data.ContainsKey("$($nerdFont.folderName).zip")) {
                        Write-Warning "SHA-256 Hash not found for $($nerdFont.folderName).zip. Skipping installation."
                        continue
                    }

                    $expectedSha256 = $fontReleases[$nerdFont.releaseUrl].Sha256Data["$($nerdFont.folderName).zip"]
                    $actualSha256 = Get-FileHash -Path $zipPath -Algorithm SHA256 | Select-Object -ExpandProperty Hash
                    if ($expectedSha256 -ne $actualSha256) {
                        Write-Error "SHA-256 Hash mismatch for $($nerdFont.folderName).zip. Skipping installation."
                        continue
                    }
                    Write-Verbose "SHA-256 Hash verified for $($nerdFont.folderName).zip"
                }

                # Extract the font files if not already extracted
                $extractPath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($zipPath), [System.IO.Path]::GetFileNameWithoutExtension($zipPath))
                if (Test-Path -Path $extractPath) {
                    Write-Verbose "Font files already extracted to $extractPath"
                }
                else {
                    Write-Verbose "Extracting font files to $extractPath"
                    $null = [System.IO.Directory]::CreateDirectory($extractPath)
                    Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
                    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $extractPath)
                }

                # Search for .otf files by default
                $filter = '*.otf'

                # Special case for font archives with multiple fonts like 'Cascadia'
                if ($null -eq $nerdFont.imagePreviewFontSource) {
                    $filter = "$($nerdFont.folderName)$filter"
                }

                $otfPath = [System.IO.Path]::Combine($extractPath, 'otf')
                $ttfPath = [System.IO.Path]::Combine($extractPath, 'ttf')
                $staticPath = [System.IO.Path]::Combine($extractPath, 'static')

                # Use otf subfolder if it exists
                if (Test-Path -Path $otfPath) {
                    # Use static subfolder if it exists
                    $staticPath = [System.IO.Path]::Combine($otfPath, 'static')
                    if (Test-Path -Path $staticPath) {
                        Write-Verbose "Using static font files from $staticPath"
                        $extractPath = $staticPath
                    }
                    else {
                        Write-Verbose "Using font files from $otfPath"
                        $extractPath = $otfPath
                    }
                }

                # Use ttf subfolder if it exists
                elseif (Test-Path -Path $ttfPath) {
                    # Use static subfolder if it exists
                    $staticPath = [System.IO.Path]::Combine($ttfPath, 'static')
                    if (Test-Path -Path $staticPath) {
                        Write-Verbose "Using static font files from $staticPath"
                        $extractPath = $staticPath
                    }
                    else {
                        Write-Verbose "Using font files from $ttfPath"
                        $extractPath = $ttfPath
                    }
                }

                # Use static subfolder if it exists
                elseif (Test-Path -Path $staticPath) {
                    $otfPath = [System.IO.Path]::Combine($staticPath, 'otf')
                    $ttfPath = [System.IO.Path]::Combine($staticPath, 'ttf')
                    if (Test-Path -Path $otfPath) {
                        # Use otf subfolder if it exists
                        Write-Verbose "Using static font files from $otfPath"
                        $extractPath = $otfPath
                    }
                    elseif (Test-Path -Path $ttfPath) {
                        # Use otf subfolder if it exists
                        Write-Verbose "Using static font files from $ttfPath"
                        $extractPath = $ttfPath
                    }
                    else {
                        Write-Verbose "Using static font files from $staticPath"
                        $extractPath = $staticPath
                    }
                }

                # Get .otf files
                $otfFiles = Get-ChildItem -Path $extractPath -Filter $filter

                # Check if any .otf files were found
                if ($otfFiles.Count -eq 0) {
                    # No .otf files found, fall back to .ttf files
                    $filter = "*.ttf"

                    # Special case for font archives with multiple fonts like 'Cascadia'
                    if ($null -eq $nerdFont.imagePreviewFontSource) {
                        $filter = "$($nerdFont.folderName)$filter"
                    }

                    $fontFiles = Get-ChildItem -Path $extractPath -Filter $filter
                    if ($fontFiles -eq 0) {
                        Write-Error "No font files found for $($nerdFont.folderName)."
                        continue
                    }
                }
                else {
                    # .otf files found, use them
                    $fontFiles = $otfFiles
                }

                # Install the font files
                foreach ($fontFile in $fontFiles) {
                    try {
                        $fontFileDestinationPath = [System.IO.Path]::Combine($fontDestinationFolderPath, $fontFile.Name)

                        if (-not $Force -and (Test-Path -Path $fontFileDestinationPath)) {
                            if ($Force) {
                                Write-Verbose "Overwriting font file: $($fontFile.Name)"
                            }
                            Write-Verbose "Font file already exists: $($fontFile.Name)"
                            Write-Host -NoNewline "  `u{2713} " -ForegroundColor Green
                        }
                        else {
                            if ($Force) {
                                Write-Verbose "Overwriting font file: $($fontFile.Name)"
                            }
                            else {
                                Write-Verbose "Copying font file: $($fontFile.Name)"
                            }

                            $maxRetries = 10
                            $retryIntervalSeconds = 1
                            $retryCount = 0
                            $fileCopied = $false
                            do {
                                try {
                                    $null = $fontFile.CopyTo($fontFileDestinationPath, $Force)
                                    $fileCopied = $true
                                }
                                catch {
                                    $retryCount++
                                    if ($retryCount -eq $maxRetries) {
                                        Write-Verbose "Failed to copy font file: $($fontFile.Name). Maximum retries exceeded."
                                        break
                                    }
                                    Write-Verbose "Failed to copy font file: $($fontFile.Name). Retrying in $retryIntervalSeconds seconds ..."
                                    Start-Sleep -Seconds $retryIntervalSeconds
                                }
                            } while (-not $fileCopied -and $retryCount -lt $maxRetries)

                            if (-not $fileCopied) {
                                throw "Failed to copy font file: $($fontFile.Name)."
                            }

                            # Register font file on Windows
                            if ($IsWindows) {
                                $fontType = if ([System.IO.Path]::GetExtension($fontFile.FullName).TrimStart('.') -eq 'otf') { 'OpenType' } else { 'TrueType' }
                                $params = @{
                                    Name         = "$($fontFile.BaseName) ($fontType)"
                                    Path         = if ($Scope -eq 'AllUsers') { 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' } else { 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' }
                                    PropertyType = 'string'
                                    Value        = if ($Scope -eq 'AllUsers') { $fontFile.Name } else { $fontFileDestinationPath }
                                    Force        = $true
                                    ErrorAction  = 'Stop'
                                }
                                Write-Verbose "Registering font file as '$($params.Name)' in $($params.Path)"
                                $null = New-ItemProperty @params
                            }

                            Write-Host -NoNewline "  $($PSStyle.Bold)`u{2713}$($PSStyle.BoldOff) " -ForegroundColor Green
                        }
                        Write-Host $fontFile.Name
                    }
                    catch {
                        Write-Host -NoNewline "  `u{2717} " -ForegroundColor Red
                        Write-Host $fontFile.Name
                        throw $_
                    }
                }

                Write-Host "`n$($PSStyle.Bold)'$($nerdFont.imagePreviewFont)'$($PSStyle.BoldOff) installed successfully.`n" -ForegroundColor Green
            }
            elseif ($WhatIfPreference -eq $true) {
                Write-Verbose "Predicted installation: $($nerdFont.folderName) [$($nerdFont.caskName)] ($($nerdFont.imagePreviewFont))"
            }
            else {
                Write-Verbose "Skipping font: $($nerdFont.folderName) [$($nerdFont.caskName)] ($($nerdFont.imagePreviewFont))"
            }
        }
    }
    catch {
        if ([System.IO.Directory]::Exists($tempPath)) {
            Write-Verbose "Removing temporary directory: $tempPath"
            [System.IO.Directory]::Delete($tempPath, $true)
        }
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

end {
    if ([System.IO.Directory]::Exists($tempPath)) {
        Write-Verbose "Removing temporary directory: $tempPath"
        [System.IO.Directory]::Delete($tempPath, $true)
    }

    if ($IsLinux -and (Get-Command -Name fc-cache -ErrorAction Ignore)) {
        if ($Verbose) {
            Write-Verbose "Refreshing font cache"
            fc-cache -fv
        }
        else {
            fc-cache -f
        }
    }
}
