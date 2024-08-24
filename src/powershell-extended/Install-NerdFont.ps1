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

.DESCRIPTION
    This PowerShell script installs Nerd Fonts on Windows, macOS, or Linux.
    Nerd Fonts is a project that patches developer targeted fonts with a high number of glyphs (icons).

    The script also supports the installation of the Cascadia Code, Cascadia Mono, and Cascadia fonts
    from the Microsoft repository. These fonts have native Nerd Font and Powerline support since
    version 2404.23.

    The script downloads the font archive from the GitHub release page and extracts the font files to
    the user's font directory.

.PARAMETER FontName
    The name of the Nerd Font to install.
    Multiple font names can be specified as an array of strings.
    If no font name is specified, the script provides an interactive menu to select the font to install
    (unless the All parameter is used).

.PARAMETER All
    Install all available Nerd Fonts.

.EXAMPLE
    Install-NerdFont -FontName 'Cascadia'
    Install the Cascadia fonts from the Microsoft repository. This includes the Cascadia Code and Cascadia Mono fonts.

.EXAMPLE
    Install-NerdFont -FontName 'CascadiaCode'
    Install the Cascadia Code fonts from the Microsoft repository.

.EXAMPLE
    Install-NerdFont -FontName 'CascadiaMono'
    Install the Cascadia Mono fonts from the Microsoft repository.

.NOTES
    This script must be run on your local machine, not in a container.
#>

[CmdletBinding(DefaultParameterSetName = 'ByFontName', SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $false, ParameterSetName = 'ByFontName')]
    [ArgumentCompleter(
        {
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
            @(
                '0xProto'
                '3270'
                'Agave'
                'AnonymicePro'
                'AnonymousPro'
                'Arimo'
                'AurulentSansMono'
                'BigBlueTerminal'
                'BitstreamVeraSansMono'
                'Cascadia'
                'CascadiaCode'
                'CascadiaMono'
                'CaskaydiaCove'
                'CaskaydiaMono'
                'CodeNewRoman'
                'ComicShannsMono'
                'CommitMono'
                'Cousine'
                'D2Coding'
                'DaddyTimeMono'
                'DejaVuSansMono'
                'DroidSansMono'
                'EnvyCodeR'
                'FantasqueSansMono'
                'FiraCode'
                'FiraMono'
                'GeistMono'
                'Go-Mono'
                'Gohu'
                'Hack'
                'Hasklig'
                'Hasklug'
                'HeavyData'
                'Hermit'
                'Hurmit'
                'iA-Writer'
                'IBMPlexMono'
                'iMWriting'
                'Inconsolata'
                'InconsolataGo'
                'InconsolataLGC'
                'IntelOneMono'
                'IntoneMono'
                'Iosevka'
                'IosevkaTerm'
                'IosevkaTermSlab'
                'JetBrainsMono'
                'Lekton'
                'LiberationMono'
                'Lilex'
                'LiterationMono'
                'MartianMono'
                'Meslo'
                'Monaspace'
                'Monaspice'
                'Monofur'
                'Monoid'
                'Mononoki'
                'MPlus'
                'NerdFontsSymbolsOnly'
                'Noto'
                'OpenDyslexic'
                'Overpass'
                'ProFont'
                'ProggyClean'
                'Recursive'
                'RobotoMono'
                'SauceCodePro'
                'ShareTechMono'
                'SourceCodePro'
                'SpaceMono'
                'SureTechMono'
                'Terminess'
                'Terminus'
                'Tinos'
                'Ubuntu'
                'UbuntuMono'
                'UbuntuSans'
                'VictorMono'
                'ZedMono'
            ) |
            Where-Object { $_ -like "$wordToComplete*" } |
            ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
        }
    )]
    [string[]]$FontName,

    [Parameter(Mandatory = $true, ParameterSetName = 'ByAll')]
    [switch]$All
)

# Abort if running in a container
if (
    $null -ne $env:REMOTE_CONTAINERS -or
    $null -ne $env:CODESPACES -or
    $null -ne $env:WSL_INTEROP
) {
    Write-Host 'This script most be run on your local machine, not in a container. Exiting...' -ForegroundColor Yellow
    return
}

$AllNerdFonts = @(
    '0xProto'
    '3270'
    'Agave'
    'AnonymicePro'
    'AnonymousPro'
    'Arimo'
    'AurulentSansMono'
    'BigBlueTerminal'
    'BitstreamVeraSansMono'
    'Cascadia'
    'CascadiaCode'
    'CascadiaMono'
    'CaskaydiaCove'
    'CaskaydiaMono'
    'CodeNewRoman'
    'ComicShannsMono'
    'CommitMono'
    'Cousine'
    'D2Coding'
    'DaddyTimeMono'
    'DejaVuSansMono'
    'DroidSansMono'
    'EnvyCodeR'
    'FantasqueSansMono'
    'FiraCode'
    'FiraMono'
    'GeistMono'
    'Go-Mono'
    'Gohu'
    'Hack'
    'Hasklig'
    'Hasklug'
    'HeavyData'
    'Hermit'
    'Hurmit'
    'iA-Writer'
    'IBMPlexMono'
    'iMWriting'
    'Inconsolata'
    'InconsolataGo'
    'InconsolataLGC'
    'IntelOneMono'
    'IntoneMono'
    'Iosevka'
    'IosevkaTerm'
    'IosevkaTermSlab'
    'JetBrainsMono'
    'Lekton'
    'LiberationMono'
    'Lilex'
    'LiterationMono'
    'MartianMono'
    'Meslo'
    'Monaspace'
    'Monaspice'
    'Monofur'
    'Monoid'
    'Mononoki'
    'MPlus'
    'NerdFontsSymbolsOnly'
    'Noto'
    'OpenDyslexic'
    'Overpass'
    'ProFont'
    'ProggyClean'
    'Recursive'
    'RobotoMono'
    'SauceCodePro'
    'ShareTechMono'
    'SourceCodePro'
    'SpaceMono'
    'SureTechMono'
    'Terminess'
    'Terminus'
    'Tinos'
    'Ubuntu'
    'UbuntuMono'
    'UbuntuSans'
    'VictorMono'
    'ZedMono'
) | Sort-Object

function Show-Menu {
    param (
        $Options
    )
    Clear-Host

    # Function to draw the menu
    function Draw-Menu {
        param (
            $Options,
            $terminalWidth
        )

        # Print the centered and bold title
        $title = "`u{1F913} $($PSStyle.Bold)Nerd Fonts Installation$($PSStyle.BoldOff)"
        $padding = [math]::Max(0, ($terminalWidth - $title.Length) / 2)
        Write-Host (' ' * $padding + $title) -ForegroundColor Cyan -NoNewline
        Write-Host -ForegroundColor Cyan
        Write-Host (("=" * $terminalWidth) + "`n") -ForegroundColor Cyan

        # Calculate the maximum width of each column
        $maxOptionLength = ($Options | Measure-Object -Maximum Length).Maximum
        $maxIndexLength = ($Options.Length).ToString().Length
        $columnWidth = $maxIndexLength + $maxOptionLength + 4  # 4 for padding and ": "

        # Calculate the number of columns that can fit in the terminal width
        $numColumns = [math]::Floor($terminalWidth / $columnWidth)

        # Calculate the number of rows
        $numRows = [math]::Ceiling($Options.Length / $numColumns)

        # Print the options in rows
        for ($row = 0; $row -lt $numRows; $row++) {
            for ($col = 0; $col -lt $numColumns; $col++) {
                $index = $row + $col * $numRows
                if ($index -lt $Options.Length) {
                    $number = $index + 1
                    $fontName = $Options[$index]
                    $numberText = ("{0," + $maxIndexLength + "}") -f $number
                    $fontText = ("{0,-" + $maxOptionLength + "}") -f $fontName
                    Write-Host -NoNewline -ForegroundColor DarkYellow $numberText
                    Write-Host -NoNewline -ForegroundColor Yellow ": "
                    Write-Host -NoNewline -ForegroundColor White "$($PSStyle.Bold)$fontText$($PSStyle.BoldOff)"
                }
            }
            Write-Host
        }
    }

    # Initial terminal width
    $initialWidth = [console]::WindowWidth

    # Draw the initial menu
    Draw-Menu -Options $Options -terminalWidth $initialWidth

    Write-Host "`nEnter 'q' to quit." -ForegroundColor Cyan

    # Loop to handle user input and terminal resizing
    while ($true) {
        $currentWidth = [console]::WindowWidth
        if ($currentWidth -ne $initialWidth) {
            Clear-Host
            Draw-Menu -Options $Options -terminalWidth $currentWidth
            Write-Host "`nEnter 'q' to quit." -ForegroundColor Cyan
            $initialWidth = $currentWidth
        }

        $selection = Read-Host "`nSelect a number"
        if ($selection -eq 'q') {
            return 'quit'
        }
        elseif ($selection -match '^\d+$') {
            $selection = [int]$selection
            if ($selection -ge 1 -and $selection -le $Options.Length) {
                return $Options[$selection - 1]
            }
        }
        Write-Host "Invalid selection. Please enter a number between 1 and $($Options.Length) or 'q' to quit." -ForegroundColor Red
    }
}

if (-not $FontName -and -not $All) {
    # Provide interactive selection if no font name is specified
    do {
        $FontName = Show-Menu -Options $AllNerdFonts
        if ($FontName -eq 'quit') {
            Write-Host "Selection process canceled."
            return
        }
    } while (-not $FontName)

    if ($FontName) {
        Write-Host "`nYour selected font: $FontName`n" -ForegroundColor Yellow
        # Proceed with the installation of the selected font
    }
    else {
        Write-Host "No font selected."
        return
    }
}

$FontAliasNames = @{
    'AnonymicePro'   = 'AnonymousPro'
    'BitstromWera'   = 'BitstreamVeraSansMono'
    'BlexMono'       = 'IBMPlexMono'
    'CaskaydiaCove'  = 'CascadiaCode'
    'CaskaydiaMono'  = 'CascadiaMono'
    'Hasklug'        = 'Hasklig'
    'Hurmit'         = 'Hermit'
    'iMWriting'      = 'iA-Writer'
    'IntoneMono'     = 'IntelOneMono'
    'LiterationMono' = 'LiberationMono'
    'Monaspice'      = 'Monaspace'
    'SureTechMono'   = 'ShareTechMono'
    'SauceCodePro'   = 'SourceCodePro'
    'Terminess'      = 'Terminus'
}

if ($All) {
    $FontName = $AllNerdFonts | Where-Object { $_ -notin $FontAliasNames.Keys }
}

$resetFontCache = $null

$releaseInfo = @{}

try {
    if (
        (
            $FontName.Contains('CascadiaCode') -and
            $FontName.Contains('CascadiaMono')
        ) -or
        (
            $FontName.Contains('Cascadia') -and
            $FontName.Contains('CascadiaCode')
        ) -or
        (
            $FontName.Contains('Cascadia') -and
            $FontName.Contains('CascadiaMono')
        )
    ) {
        Write-Verbose "CascadiaCode and CascadiaMono fonts are in the same package as Cascadia: Removing duplicates."
        $FontName = $FontName | Where-Object { $_ -ne 'Cascadia' -and $_ -ne 'CascadiaCode' -and $_ -ne 'CascadiaMono' }
        $FontName += 'Cascadia'
    }

    if (
        (
            $FontName.Contains('CaskaydiaCove') -or
            $FontName.Contains('CaskaydiaMono')
        ) -and
        (
            $FontName.Contains('Cascadia') -or
            $FontName.Contains('CascadiaCode') -or
            $FontName.Contains('CascadiaMono')
        )
    ) {
        Write-Host "CaskaydiaCove and CaskaydiaMono are clones, giving priority to Cascadia original fonts." -ForegroundColor Magenta
        $FontName = $FontName | Where-Object { $_ -ne 'CaskaydiaCove' -and $_ -ne 'CaskaydiaMono' }
    }

    $FontName | Sort-Object | ForEach-Object {
        if (@('Cascadia', 'CascadiaCode', 'CascadiaMono') -contains $_.Trim() ) {
            $FontName = $_.Trim()
            $sourceName = 'GitHub.com/Microsoft'
            $releaseUrl = 'https://api.github.com/repos/microsoft/cascadia-code/releases/latest'
            if (-not $releaseInfo[$releaseUrl]) {
                $releaseInfo[$releaseUrl] = Invoke-RestMethod -Uri $releaseUrl -ErrorAction Stop
            }
            $assetUrl = $releaseInfo[$releaseUrl].assets | Where-Object { $_.name -like '*.zip' } | Select-Object -ExpandProperty browser_download_url
            $sha256Url = $null
        }
        else {
            if ($FontAliasNames.ContainsKey($_.Trim())) {
                Write-Host "Font alias found: $FontName ➜ $($FontAliasNames[$_])" -ForegroundColor Yellow
                $FontName = $FontAliasNames.$_
            }
            else {
                $FontName = $_.Trim()
            }

            $sourceName = 'GitHub.com/ryanoasis'
            $releaseUrl = 'https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest'
            if (-not $releaseInfo[$releaseUrl]) {
                $releaseInfo[$releaseUrl] = Invoke-RestMethod -Uri $releaseUrl -ErrorAction Stop
            }
            $assetUrl = $releaseInfo[$releaseUrl].assets | Where-Object { $_.name -like "$FontName.zip" } | Select-Object -ExpandProperty browser_download_url
            $sha256Url = $releaseInfo[$releaseUrl].assets | Where-Object { $_.name -eq 'SHA-256.txt' } | Select-Object -ExpandProperty browser_download_url
        }

        Write-Verbose "Font '$FontName' asset URL: $assetUrl"
        Write-Verbose "Font '$FontName' SHA-256 URL: $sha256Url"

        if (-not $assetUrl) {
            if ($WhatIfPreference -eq $true) {
                Write-Warning "Font '$FontName' not found."
            }
            else {
                Write-Error "Font '$FontName' not found."
            }
            return
        }
        if ($assetUrl -notlike '*.zip') {
            if ($WhatIfPreference -eq $true) {
                Write-Warning "Font '$FontName' archive format is not supported."
            }
            else {
                Write-Error "Font '$FontName' archive format is not supported."
            }
            return
        }

        # Define the local paths
        if ($IsWindows) {
            $zipPath = "$env:TEMP\NerdFont_$FontName.zip"
            $extractPath = "$env:TEMP\NerdFont_$FontName"
        }
        else {
            $zipPath = "$env:TMPDIR/NerdFont_$FontName.zip"
            $extractPath = "$env:TMPDIR/NerdFont_$FontName"
        }

        Write-Verbose "Zip download path: $zipPath"
        Write-Verbose "Extract path: $extractPath"

        if (
            $PSCmdlet.ShouldProcess(
                "Install the font '$FontName' from $sourceName",
                "Do you confirm to install the font '$FontName' from $sourceName ?",
                "Nerd Fonts Installation"
            )
        ) {
            # Download the zip file if not already downloaded
            if (Test-Path -Path $zipPath) {
                Write-Verbose "Font '$FontName' already downloaded."
            }
            else {
                Write-Verbose "Downloading font '$FontName' from $assetUrl ..."
                Invoke-WebRequest -Uri $assetUrl -OutFile $zipPath -ErrorAction Stop
            }

            # Verify the SHA-256 hash
            if ($sha256Url) {
                Write-Verbose "Verifying SHA-256 hash ..."
                $sha256Path = "$zipPath.sha256"
                $zipName = (Get-Item $zipPath).Name -replace '^NerdFont_', ''

                if (Test-Path -Path $sha256Path) {
                    Write-Verbose 'SHA-256 hash file already downloaded.'
                }
                else {
                    Write-Verbose "Downloading SHA-256 hash file from $sha256Url ..."
                    Invoke-WebRequest -Uri $sha256Url -OutFile $sha256Path -ErrorAction Stop
                }

                $hash = Get-FileHash -Path $zipPath -Algorithm SHA256
                $expectedHashes = Get-Content -Path $sha256Path

                $hashVerified = $false

                Write-Verbose "Searching for hash $($hash.Hash) of $zipName in SHA-256 file ..."
                foreach ($line in $expectedHashes) {
                    if ($line -match '^\s*([a-fA-F0-9]{64})\s+(.+)$') {
                        # Line contains a hash and a filename
                        $expectedHash = $matches[1]
                        $fileName = $matches[2]
                        if ($fileName -eq $zipName -and $hash.Hash -eq $expectedHash) {
                            Write-Verbose "Found hash $expectedHash for $fileName."
                            $hashVerified = $true
                            break
                        }
                    }
                    elseif ($line -match '^\s*([a-fA-F0-9]{64})\s*$') {
                        # Line contains only a hash
                        $expectedHash = $matches[1]
                        if ($hash.Hash -eq $expectedHash) {
                            Write-Verbose "Found hash $expectedHash."
                            $hashVerified = $true
                            break
                        }
                    }
                }

                if (-not $hashVerified) {
                    throw 'SHA-256 hash mismatch.'
                }
            }

            # Extract the zip file
            Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

            # Install the fonts
            if ($IsWindows) {
                $Destination = (New-Object -ComObject Shell.Application).Namespace(0x14)
                Write-Host "`nInstalling font files to Current User Font Directory" -ForegroundColor White
                Get-ChildItem -Path $extractPath -Filter "$FontName*.ttf" -Recurse | ForEach-Object {
                    if ($_.FullName -like '*static*') {
                        Write-Verbose "Skipping static font file: $($_.Name)"
                        return
                    }
                    Write-Host "  $($_.Name)"
                    $Destination.CopyHere($_.FullName, 0x10)
                }
            }
            elseif ($IsMacOS) {
                $Destination = "${HOME}/Library/Fonts"
                $null = New-Item -Path $Destination -ItemType Directory -Force
                Write-Host "`nInstalling font files to $Destination" -ForegroundColor White
                Get-ChildItem -Path $extractPath -Filter "$FontName*.ttf" -Recurse | ForEach-Object {
                    if ($_.FullName -like '*static*') {
                        Write-Verbose "Skipping static font file: $($_.Name)"
                        return
                    }
                    Write-Host "  $($_.Name)"
                    Copy-Item -Path $_.FullName -Destination $Destination -Force -Confirm:$false -Verbose:$(if ($VerbosePreference -eq 'Continue') { $true } else { $false })
                }
            }
            elseif ($IsLinux) {
                $Destination = "${HOME}/.local/share/fonts"
                $null = New-Item -Path $Destination -ItemType Directory -Force
                Write-Host "`nInstalling font files to $Destination" -ForegroundColor White
                Get-ChildItem -Path $extractPath -Filter "$FontName*.ttf" -Recurse | ForEach-Object {
                    if ($_.FullName -like '*static*') {
                        Write-Verbose "Skipping static font file: $($_.Name)"
                        return
                    }
                    Write-Host "  $($_.Name)"
                    Copy-Item -Path $_.FullName -Destination $Destination -Force -Confirm:$false -Verbose:$(if ($VerbosePreference -eq 'Continue') { $true } else { $false })
                }

                $Script:resetFontCache = $Destination
            }
            else {
                throw 'Unsupported operating system.'
            }

            Write-Host "$FontName font installed successfully.`n" -ForegroundColor Green
        }
        else {
            return
        }
    }
}
catch {
    Write-Error "Failed to install font:`n$_"
}
finally {
    if ($IsWindows) {
        Remove-Item -Path "$env:TEMP/NerdFont_*" -Force -Recurse -Confirm:$false
    }
    else {
        Remove-Item -Path "$env:TMPDIR/NerdFont_*" -Force -Recurse -Confirm:$false
    }
}

# Refresh the font cache
if ($resetFontCache -and (Get-Command -Name fc-cache -ErrorAction Ignore)) {
    Write-Host "Resetting font cache in $resetFontCache ..." -ForegroundColor Yellow
    fc-cache -f $resetFontCache
}
