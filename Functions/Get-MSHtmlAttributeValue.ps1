function Get-MSHtmlAttributeValue {
<#
.SYNOPSIS
    Extracts one attribute value from an HTML tag string.
#>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Tag,

        [Parameter(Mandatory)]
        [string]$AttributeName
    )

    Set-StrictMode -Version Latest

    $pattern = '(?i)\b' + [regex]::Escape($AttributeName) + '\s*=\s*(?:"([^"]*)"|''([^'']*)''|([^\s>]+))'
    $match = [regex]::Match($Tag, $pattern)

    if (-not $match.Success) {
        return $null
    }

    if ($match.Groups[1].Success) {
        return [System.Net.WebUtility]::HtmlDecode($match.Groups[1].Value.Trim())
    }

    if ($match.Groups[2].Success) {
        return [System.Net.WebUtility]::HtmlDecode($match.Groups[2].Value.Trim())
    }

    if ($match.Groups[3].Success) {
        return [System.Net.WebUtility]::HtmlDecode($match.Groups[3].Value.Trim())
    }

    return $null
}

