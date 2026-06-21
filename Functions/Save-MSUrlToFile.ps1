function Save-MSUrlToFile {
<#
.SYNOPSIS
    Downloads a URL and saves it to a local file.

.DESCRIPTION
    Uses Invoke-WebRequest to download a file from a URL.

    If the destination file already exists, the function stops unless -Force
    or -Overwrite is used.

.PARAMETER Url
    Source URL to download.

.PARAMETER FilePath
    Full path where the file will be saved.

.PARAMETER Force
    Overwrites the file if it already exists.

.PARAMETER Overwrite
    Alias for -Force.

.EXAMPLE
    Save-MSUrlToFile `
        -Url "https://example.com/image.jpg" `
        -FilePath "C:\temp\Manga\chapter-1\0001.jpg"

.EXAMPLE
    Save-MSUrlToFile `
        -Url "https://example.com/image.jpg" `
        -FilePath "C:\temp\Manga\chapter-1\0001.jpg" `
        -Force

.EXAMPLE
    Save-MSUrlToFile `
        -Url "https://example.com/image.jpg" `
        -FilePath "C:\temp\Manga\chapter-1\0001.jpg" `
        -Overwrite
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [uri]$Url,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Alias('Overwrite')]
        [switch]$Force
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $fullFilePath = [System.IO.Path]::GetFullPath($FilePath)
    $folderPath = Split-Path -Path $fullFilePath -Parent

    if (-not (Test-Path -Path $folderPath -PathType Container)) {
        New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
    }

    if ((Test-Path -Path $fullFilePath -PathType Leaf) -and (-not $Force)) {
        throw "File already exists: $fullFilePath. Use -Force or -Overwrite to replace it."
    }

    if ((Test-Path -Path $fullFilePath -PathType Leaf) -and $Force) {
        Remove-Item -Path $fullFilePath -Force
    }

    $oldProgressPreference = $ProgressPreference

    try {
        $ProgressPreference = 'SilentlyContinue'

        Invoke-WebRequest `
            -Uri $Url `
            -OutFile $fullFilePath `
            -UseBasicParsing

        return [pscustomobject]@{
            Url      = $Url.AbsoluteUri
            FilePath = $fullFilePath
            SizeMB   = [math]::Round((Get-Item $fullFilePath).Length / 1MB, 2)
            Status   = 'Downloaded'
        }
    }
    finally {
        $ProgressPreference = $oldProgressPreference
    }
}

