function Save-MSUrlToFileWithUrlSubFolder {
<#
.SYNOPSIS
    Downloads a URL and saves it under a subfolder based on the URL path.

.DESCRIPTION
    Reuses Save-MSUrlToFile.

    Example:

        Url  = https://mydomain.com/mg1/chapter-91/0.jpg
        Path = C:\temp\

    Output:

        C:\temp\chapter-91\0.jpg

.PARAMETER Url
    Source URL to download.

.PARAMETER Path
    Root folder where the URL subfolder will be created.

.PARAMETER Force
    Overwrites the file if it already exists.

.PARAMETER Overwrite
    Alias for -Force.

.EXAMPLE
    Save-MSUrlToFileWithUrlSubFolder `
        -Url "https://mydomain.com/mg1/chapter-91/0.jpg" `
        -Path "C:\temp\"

.EXAMPLE
    Save-MSUrlToFileWithUrlSubFolder `
        -Url "https://mydomain.com/mg1/chapter-91/0.jpg" `
        -Path "C:\temp\" `
        -Force
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Url,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Alias('Overwrite')]
        [switch]$Force
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if (-not (Get-Command Save-MSUrlToFile -ErrorAction SilentlyContinue)) {
        throw "Function Save-MSUrlToFile was not found. Load it before using this function."
    }

    $uri = [System.Uri]::new($Url)

    $segments = @(
        $uri.AbsolutePath -split '/' |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    if ($segments.Count -lt 2) {
        throw "URL does not contain enough path parts to create a subfolder and file name: $Url"
    }

    $fileName = [System.Net.WebUtility]::UrlDecode($segments[-1])
    $subFolderName = [System.Net.WebUtility]::UrlDecode($segments[-2])

    foreach ($char in [System.IO.Path]::GetInvalidFileNameChars()) {
        $fileName = $fileName.Replace($char, '_')
        $subFolderName = $subFolderName.Replace($char, '_')
    }

    $rootPath = [System.IO.Path]::GetFullPath($Path)
    $targetFolder = Join-Path $rootPath $subFolderName
    $targetFilePath = Join-Path $targetFolder $fileName

    Save-MSUrlToFile `
        -Url $uri.AbsoluteUri `
        -FilePath $targetFilePath `
        -Force:$Force

    return [pscustomobject]@{
        Url       = $uri.AbsoluteUri
        Folder    = $targetFolder
        FileName  = $fileName
        FilePath  = $targetFilePath
        Status    = 'Downloaded'
    }
}

