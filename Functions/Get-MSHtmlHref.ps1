function Get-MSHtmlHref {
<#
.SYNOPSIS
    Extracts all href values from a local HTML file.

.DESCRIPTION
    Parses a local HTML file and returns all href attribute values as a string array.

    Supports:

        href="..."
        href='...'
        href=...

    If -BaseUrl is provided, relative href values are converted to absolute URLs.

.PARAMETER FilePath
    Path to the local HTML file.

.PARAMETER BaseUrl
    URL where the page was downloaded from, or the root/base URL to use for relative links.

    Examples:

        https://example.com/
        https://example.com/manga/
        https://example.com/manga/index.html

.PARAMETER Unique
    Returns only distinct href values.

.EXAMPLE
    $hrefs = Get-MSHtmlHref -FilePath "C:\temp\page.html"

.EXAMPLE
    $hrefs = Get-MSHtmlHref `
        -FilePath "C:\temp\page.html" `
        -BaseUrl "https://example.com/manga/"

.EXAMPLE
    $hrefs = Get-MSHtmlHref `
        -FilePath "C:\temp\page.html" `
        -BaseUrl "https://example.com/manga/index.html" `
        -Unique
#>

    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [string]$FilePath,

        [uri]$BaseUrl,

        [switch]$Unique
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $html = Get-Content -Path $FilePath -Raw

    $pattern = '(?i)\bhref\s*=\s*(?:"([^"]*)"|''([^'']*)''|([^\s>]+))'

    $matches = [regex]::Matches($html, $pattern)

    $hrefs = @(
        foreach ($match in $matches) {
            $value = $null

            if ($match.Groups[1].Success) {
                $value = $match.Groups[1].Value
            }
            elseif ($match.Groups[2].Success) {
                $value = $match.Groups[2].Value
            }
            elseif ($match.Groups[3].Success) {
                $value = $match.Groups[3].Value
            }

            if ([string]::IsNullOrWhiteSpace($value)) {
                continue
            }

            $value = [System.Net.WebUtility]::HtmlDecode($value.Trim())

            if ($BaseUrl) {
                try {
                    $absoluteUri = [System.Uri]::new($BaseUrl, $value)
                    $absoluteUri.AbsoluteUri
                }
                catch {
                    $value
                }
            }
            else {
                $value
            }
        }
    )

    if ($Unique) {
        $hrefs = @($hrefs | Sort-Object -Unique)
    }

    return [string[]]$hrefs
}

