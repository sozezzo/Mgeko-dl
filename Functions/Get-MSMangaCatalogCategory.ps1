function Get-MSMangaCatalogCategory {
<#
.SYNOPSIS
    Lists distinct manga categories from a manga catalog JSON.

.DESCRIPTION
    Reads mgeko-manga-catalog.json and returns distinct category names.
    Comparison is case-insensitive, but output keeps the first original spelling found.

.PARAMETER CatalogFile
    Path to mgeko-manga-catalog.json.

.EXAMPLE
    Get-MSMangaCatalogCategory -CatalogFile "C:\temp\mgeko-download\mgeko-manga-catalog.json"
#>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$CatalogFile
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if (-not (Test-Path -LiteralPath $CatalogFile -PathType Leaf)) {
        throw "Catalog file not found: $CatalogFile"
    }

    $catalog = Get-Content -LiteralPath $CatalogFile -Raw | ConvertFrom-Json

    $categories =
        $catalog.items |
        ForEach-Object { $_.manga.categories } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.Trim() } |
        Group-Object -Property { $_.ToLowerInvariant() } |
        ForEach-Object { $_.Group[0] } |
        Sort-Object

    return @($categories)
}

