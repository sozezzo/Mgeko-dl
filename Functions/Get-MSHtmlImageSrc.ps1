function Get-MSHtmlImageSrc {
<#
.SYNOPSIS
    Extracts image URLs from img tags in a local HTML file.

.DESCRIPTION
    Returns an array of image source strings.

    Checks, in order:
        src
        data-src
        data-original
        data-lazy-src
        data-url
        data-cfsrc

    If -IncludeSrcSet is used, it also reads srcset and returns the URLs inside it.

.PARAMETER FilePath
    Path to the local HTML file.

.PARAMETER BaseUrl
    Optional base URL used to convert relative image paths into absolute URLs.
    Can be null or empty.

.PARAMETER Unique
    Returns only distinct image URLs.

.PARAMETER IncludeSrcSet
    Also extracts image URLs from srcset attributes.

.EXAMPLE
    $images = @(Get-MSHtmlImageSrc -FilePath "C:\temp\page.html")

.EXAMPLE
    $images = @(Get-MSHtmlImageSrc `
        -FilePath "C:\temp\page.html" `
        -BaseUrl "https://www.mgeko.cc/reader/en/goblin-slayer-chapter-91-eng-li/" `
        -Unique)
#>

    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$BaseUrl = $null,

        [switch]$Unique,

        [switch]$IncludeSrcSet
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $FilePath = $FilePath.Trim(" `t`r`n")
    $fullFilePath = [System.IO.Path]::GetFullPath($FilePath)

    if (-not (Test-Path -LiteralPath $fullFilePath -PathType Leaf)) {
        throw "HTML file not found: $fullFilePath"
    }

    $html = Get-Content -LiteralPath $fullFilePath -Raw

    $baseUri = $null

    if (-not [string]::IsNullOrWhiteSpace($BaseUrl)) {
        try {
            $baseUri = [System.Uri]::new($BaseUrl)
        }
        catch {
            throw "Invalid BaseUrl: $BaseUrl"
        }
    }

    

    

    $imgTagPattern = '(?is)<img\b[^>]*>'
    $imgTags = @([regex]::Matches($html, $imgTagPattern))

    $attributeNames = @(
        'src',
        'data-src',
        'data-original',
        'data-lazy-src',
        'data-url',
        'data-cfsrc'
    )

    $srcList = @(
        foreach ($imgTag in $imgTags) {
            $tag = $imgTag.Value

            foreach ($attributeName in $attributeNames) {
                $value = Get-MSAttributeValue -Tag $tag -AttributeName $attributeName

                if (-not [string]::IsNullOrWhiteSpace($value)) {
                    ConvertTo-MSAbsoluteUrl -Value $value
                    break
                }
            }

            if ($IncludeSrcSet) {
                $srcSetValue = Get-MSAttributeValue -Tag $tag -AttributeName 'srcset'

                if (-not [string]::IsNullOrWhiteSpace($srcSetValue)) {
                    $srcSetParts = $srcSetValue -split ','

                    foreach ($srcSetPart in $srcSetParts) {
                        $urlPart = ($srcSetPart.Trim() -split '\s+')[0]

                        if (-not [string]::IsNullOrWhiteSpace($urlPart)) {
                            ConvertTo-MSAbsoluteUrl -Value $urlPart
                        }
                    }
                }
            }
        }
    )

    $srcList = @(
        $srcList |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    )

    if ($Unique) {
        $srcList = @($srcList | Sort-Object -Unique)
    }

    return [string[]]$srcList
}

