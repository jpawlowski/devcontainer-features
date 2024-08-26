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

    The script also supports the installation of the Cascadia Code, Cascadia Mono, and Cascadia fonts
    from the Microsoft repository. These fonts have native Nerd Font and Powerline support since
    version 2404.23.

    The script downloads the font archive from the GitHub release page and extracts the font files to
    the user's font directory.

    You may also run this script directly from the web using the following command:

    ```powershell
    & ([scriptblock]::Create((iwr 'https://bit.ly/ps-install-nerdfont')))
    ```

    Parameters may be passed just like any other PowerShell script. For example:

    ```powershell
    & ([scriptblock]::Create((iwr 'https://bit.ly/ps-install-nerdfont'))) -Name 'Cascadia'
    ```

.PARAMETER Name
    The name of the Nerd Font to install.
    Multiple font names can be specified as an array of strings.
    If no font name is specified, the script provides an interactive menu to select the font to install
    (unless the All parameter is used).

.PARAMETER All
    Install all available Nerd Fonts.

.EXAMPLE
    Install-NerdFont -Name cascadia-code
    Install the Cascadia Code fonts from the Microsoft repository.

.EXAMPLE
    Install-NerdFont -Name cascadia-mono
    Install the Cascadia Mono fonts from the Microsoft repository.

.NOTES
    This script must be run on your local machine, not in a container.
#>

[CmdletBinding(DefaultParameterSetName = 'ByName', SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'ByAll')]
    [switch]$All,

    [Parameter(Mandatory = $false, ParameterSetName = 'ByAll', HelpMessage = 'In which scope do you want to install the Nerd Font, AllUsers or CurrentUser?')]
    [Parameter(Mandatory = $false, ParameterSetName = 'ByName', HelpMessage = 'In which scope do you want to install the Nerd Font, AllUsers or CurrentUser?')]
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string]$Scope = 'CurrentUser'
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
        if (Test-Path $cacheFilePath) {
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
                unpatchedName          = 'Cascadia Code'
                licenseId              = 'OFL-1.1-RFN'
                RFN                    = $true
                version                = 'latest'
                patchedName            = 'CascadiaCode'
                folderName             = 'CascadiaCode'
                imagePreviewFont       = 'Cascadia Code'
                imagePreviewFontSource = $null
                linkPreviewFont        = $null
                caskName               = 'cascadia-code'
                repoRelease            = $false
                description            = 'Cascadia Code is a monospaced font designed to work well with the new Windows Terminal.'
                releaseUrl             = 'https://api.github.com/repos/microsoft/cascadia-code/releases/latest'
            },
            [PSCustomObject]@{
                unpatchedName          = 'Cascadia Mono'
                licenseId              = 'OFL-1.1-RFN'
                RFN                    = $true
                version                = 'latest'
                patchedName            = 'CascadiaMono'
                folderName             = 'CascadiaMono'
                imagePreviewFont       = 'Cascadia Mono'
                imagePreviewFontSource = $null
                linkPreviewFont        = $null
                caskName               = 'cascadia-mono'
                repoRelease            = $false
                description            = 'Cascadia Mono is a monospaced font designed to work well with the new Windows Terminal.'
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

            # Print the centered and bold title
            if ($IsCoreCLR) {
                $title = "`u{1F913} $($PSStyle.Bold)Nerd Fonts Installation$($PSStyle.BoldOff)"
            }
            else {
                $title = 'Nerd Fonts Installation'
            }
            $padding = [math]::Max(0, ($terminalWidth - $title.Length) / 2)
            Write-Host (' ' * $padding + $title) -ForegroundColor Cyan -NoNewline
            Write-Host -ForegroundColor Cyan
            Write-Host (('=' * $terminalWidth) + "`n") -ForegroundColor Cyan

            # Add the 'All Nerd Fonts' option at the top
            $Options = @([pscustomobject]@{ imagePreviewFont = 'All Nerd Fonts'; unpatchedName = 'All'; caskName = 'All' }) + $Options

            # Calculate the maximum width of each column
            $maxOptionLength = ($Options | ForEach-Object { $_.imagePreviewFont.Length } | Measure-Object -Maximum).Maximum
            $maxIndexLength = ($Options.Length).ToString().Length
            $columnWidth = $maxIndexLength + $maxOptionLength + 4  # 4 for padding and ': '

            # Calculate the number of columns that can fit in the terminal width
            $numColumns = [math]::Floor($terminalWidth / $columnWidth)

            # Calculate the number of rows
            $numRows = [math]::Ceiling($Options.Length / $numColumns)

            # Print the options in rows
            for ($row = 0; $row -lt $numRows; $row++) {
                for ($col = 0; $col -lt $numColumns; $col++) {
                    $index = $row + $col * $numRows
                    if ($index -lt $Options.Length) {
                        $number = $index
                        $fontName = $Options[$index].imagePreviewFont
                        $numberText = ('{0,' + $maxIndexLength + '}') -f $number
                        $fontText = ('{0,-' + $maxOptionLength + '}') -f $fontName

                        if ($index -eq 0) {
                            # Special formatting for 'All Nerd Fonts'
                            Write-Host -NoNewline -ForegroundColor Magenta $numberText
                            Write-Host -NoNewline -ForegroundColor Magenta ': '
                            Write-Host -NoNewline -ForegroundColor Magenta "$($PSStyle.Italic)$fontText$($PSStyle.ItalicOff)"
                        }
                        else {
                            Write-Host -NoNewline -ForegroundColor DarkYellow $numberText
                            Write-Host -NoNewline -ForegroundColor Yellow ': '
                            Write-Host -NoNewline -ForegroundColor White "$($PSStyle.Bold)$fontText$($PSStyle.BoldOff)"
                        }
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
                if ($number -match '^\d+$') {
                    $number = [int]$number
                    if ($number -eq 0) {
                        return 'All'
                    }
                    elseif ($number -ge 1 -and $number -le $Options.Length) {
                        $validSelections += $Options[$number - 1]
                    }
                    else {
                        $invalidSelections += $number - 1
                    }
                }
                else {
                    $invalidSelections += $number - 1
                }
            }

            if ($invalidSelections.Count -eq 0) {
                # Check for conflicting fonts
                $conflictingFonts = $validSelections | Group-Object -Property unpatchedName | Where-Object { $_.Count -gt 1 }
                if ($conflictingFonts.Count -eq 0) {
                    return $validSelections.caskName
                }
                else {
                    foreach ($conflict in $conflictingFonts) {
                        $conflictNames = $conflict.Group | ForEach-Object { $_.imagePreviewFont }
                        Write-Host "Conflicting selection(s): $($conflictNames -join ', '). These fonts cannot be installed together because they share the same base font name." -ForegroundColor Red
                    }
                }
            }
            else {
                Write-Host "Invalid selection(s): $($invalidSelections -join ', '). Please enter valid numbers between 0 and $($Options.Length - 1) or 'q' to quit." -ForegroundColor Red
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
                return
            }
        } while (-not $Name)

        if ($Name) {
            if ($Name -eq 'All') {
                Write-Host "`nYou selected all Nerd Fonts.`n" -ForegroundColor Yellow
                # Proceed with the installation of all fonts
            }
            else {
                Write-Host "`nYour selected font(s): $($Name -join ', ')`n" -ForegroundColor Yellow
                # Proceed with the installation of the selected font(s)
            }
        }
        else {
            Write-Host 'No font selected.'
            return
        }
    }
    elseif ($PSBoundParameters.Name) {
        $Name = $PSBoundParameters.Name
    }

    $nerdFontsToInstall = @()

    if ($PSBoundParameters.All -or $Name -eq 'All') {
        # Group fonts by unpatchedName to identify conflicts
        $groupedFonts = $allNerdFonts | Group-Object -Property unpatchedName

        # Resolve conflicts by giving precedence to fonts with imagePreviewFontSource = $null
        $resolvedFonts = @()
        foreach ($group in $groupedFonts) {
            $fonts = $group.Group
            $preferredFont = $fonts | Where-Object { $_.imagePreviewFontSource -eq $null }
            if ($preferredFont) {
                $resolvedFonts += $preferredFont
            }
            else {
                $resolvedFonts += $fonts[0]  # If no preferred font, take the first one
            }
        }

        $nerdFontsToInstall = $resolvedFonts
    }
    else {
        # Remove duplicates and collect selected fonts
        $uniqueNames = [System.Collections.Generic.HashSet[string]]::new()
        $selectedFonts = @()
        $conflictCheck = @{}

        foreach ($fontName in $Name) {
            if ($uniqueNames.Add($fontName)) {
                $matchingFonts = $allNerdFonts | Where-Object { $_.caskName -eq $fontName -or $_.folderName -eq $fontName }
                foreach ($font in $matchingFonts) {
                    $selectedFonts += $font
                    if ($conflictCheck.ContainsKey($font.unpatchedName)) {
                        $conflictCheck[$font.unpatchedName] += $font.imagePreviewFont
                    }
                    else {
                        $conflictCheck[$font.unpatchedName] = @($font.imagePreviewFont)
                    }
                }
            }
        }

        # Check for conflicting fonts
        $conflictMessages = @()
        foreach ($key in $conflictCheck.Keys) {
            if ($conflictCheck[$key].Count -gt 1) {
                $conflictMessages += "Conflicting fonts: $($conflictCheck[$key] -join ', '). These fonts cannot be installed together because they share the same base font name."
            }
        }

        if ($conflictMessages.Count -gt 0) {
            $PSCmdlet.ThrowTerminatingError(
                [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new($conflictMessages -join "`n"),
                    'ConflictMessagesPresent',
                    [System.Management.Automation.ErrorCategory]::ResourceUnavailable,
                    $null
                )
            )
        }

        # Add unique and non-conflicting fonts to the installation list
        $nerdFontsToInstall = $selectedFonts
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

    # Generate a unique temporary directory to store the font files
    $tempFile = [System.IO.Path]::GetTempFileName()
    $tempPath = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($tempFile), [System.IO.Path]::GetFileNameWithoutExtension($tempFile))
    $null = [System.IO.Directory]::CreateDirectory($tempPath)
    [System.IO.File]::Delete($tempFile)
    Write-Verbose "Using temporary directory: $tempPath"

    $resetFontCache = $null
}

process {
    try {
        Write-Verbose "Installing $($nerdFontsToInstall.Count) Nerd Fonts to $Scope scope."

        foreach ($nerdFont in $nerdFontsToInstall) {
            $sourceName = $nerdFont.releaseUrl -replace '^https?://(?:[^/]+\.)*([^/]+\.[^/]+)/repos/([^/]+)/([^/]+).*', '$1/$2/$3'
            Write-Verbose "Processing font: $($nerdFont.folderName) [$($nerdFont.caskName)] ($($nerdFont.imagePreviewFont)) from $sourceName"

            if (
                $PSCmdlet.ShouldProcess(
                    "Install the font '$($nerdFont.imagePreviewFont)' from $sourceName",
                    "Do you confirm to install the font '$($nerdFont.imagePreviewFont)' from $sourceName ?",
                    "Nerd Fonts Installation"
                )
            ) {
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

                # Install the fonts
                $fileCounter = 0
                if ($null -eq $nerdFont.imagePreviewFontSource) {
                    $filter = "$($nerdFont.folderName)*.ttf"
                }
                else {
                    $filter = "*.ttf"
                }

                if ($IsMacOS) {
                    $Destination = "${HOME}/Library/Fonts"
                    $null = [System.IO.Directory]::CreateDirectory($Destination)
                    Write-Host "`nInstalling font files to $Destination" -ForegroundColor White
                    Write-Verbose "Searching for $filter font files in $extractPath"
                    Get-ChildItem -Path $extractPath -Filter $filter -Recurse | ForEach-Object {
                        if ($null -eq $nerdFont.imagePreviewFontSource -and $_.FullName -like '*static*') {
                            Write-Verbose "Skipping static font file: $($_.Name)"
                            return
                        }
                        Write-Host "  $($_.Name)"
                        Copy-Item -Path $_.FullName -Destination $Destination -Force -Confirm:$false -Verbose:$(if ($VerbosePreference -eq 'Continue') { $true } else { $false })
                        $fileCounter++
                    }
                }
                elseif ($IsLinux) {
                    $Destination = "${HOME}/.local/share/fonts"
                    $null = [System.IO.Directory]::CreateDirectory($Destination)
                    Write-Host "`nInstalling font files to $Destination" -ForegroundColor White
                    Write-Verbose "Searching for $filter font files in $extractPath"
                    Get-ChildItem -Path $extractPath -Filter $filter -Recurse | ForEach-Object {
                        if ($null -eq $nerdFont.imagePreviewFontSource -and $_.FullName -like '*static*') {
                            Write-Verbose "Skipping static font file: $($_.Name)"
                            return
                        }
                        Write-Host "  $($_.Name)"
                        Copy-Item -Path $_.FullName -Destination $Destination -Force -Confirm:$false -Verbose:$(if ($VerbosePreference -eq 'Continue') { $true } else { $false })
                        $fileCounter++
                    }

                    $Script:resetFontCache = $Destination
                }
                elseif ($Scope -eq 'AllUsers') {
                    $Destination = "${env:windir}\Fonts"
                    Write-Host "`nInstalling font files to All Users Font Directory" -ForegroundColor White
                    Write-Verbose "Searching for $filter font files in $extractPath"
                    Get-ChildItem -Path $extractPath -Filter $filter -Recurse | ForEach-Object {
                        if ($null -eq $nerdFont.imagePreviewFontSource -and $_.FullName -like '*static*') {
                            Write-Verbose "Skipping static font file: $($_.Name)"
                            return
                        }
                        Write-Host "  $($_.Name)"
                        Copy-Item -Path $_.FullName -Destination $Destination -Force -Confirm:$false -Verbose:$(if ($VerbosePreference -eq 'Continue') { $true } else { $false })
                        $fileCounter++
                    }
                }
                else {
                    $Destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
                    Write-Host "`nInstalling font files to Current User Font Directory" -ForegroundColor White
                    Write-Verbose "Searching for $filter font files in $extractPath"
                    Get-ChildItem -Path $extractPath -Filter $filter -Recurse | ForEach-Object {
                        if ($null -eq $nerdFont.imagePreviewFontSource -and $_.FullName -like '*static*') {
                            Write-Verbose "Skipping static font file: $($_.Name)"
                            return
                        }
                        Write-Host "  $($_.Name)"
                        $Destination.CopyHere($_.FullName, 0x10)
                        $fileCounter++
                    }
                }

                if ($fileCounter -eq 0) {
                    Write-Error "No TTF font files found for $($nerdFont.folderName)."
                }
                else {
                    Write-Host "'$($nerdFont.imagePreviewFont)' font installed successfully.`n" -ForegroundColor Green
                }
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

    # Refresh the font cache
    if ($resetFontCache -and (Get-Command -Name fc-cache -ErrorAction Ignore)) {
        Write-Host "Resetting font cache in $resetFontCache ..." -ForegroundColor Yellow
        fc-cache -f $resetFontCache
    }
}
