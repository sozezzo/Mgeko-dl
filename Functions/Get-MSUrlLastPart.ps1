function Get-MSUrlLastPart {
<#
.SYNOPSIS
    Returns the last meaningful part of a URL or path.

.DESCRIPTION
    Extracts the last right-side segment from a URL-like string.

    Handles:
      - trailing /
      - trailing spaces
      - forward slashes /
      - backslashes \
      - query strings
      - fragments

.EXAMPLE
    Get-MSUrlLastPart "https://www.mgeko.cc/reader/en/goblin-slayer-chapter-89-eng-li/"

.EXAMPLE
    Get-MSUrlLastPart "https://www.mgeko.cc/reader/en/goblin-slayer-chapter-89-eng-li"

.EXAMPLE
    Get-MSUrlLastPart "https://www.mgeko.cc/reader/en/goblin-slayer-chapter-89-eng-li \igm01.jpg"
#>

    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Url
    )

    process {
        Set-StrictMode -Version Latest
        $ErrorActionPreference = 'Stop'

        $value = $Url.Trim()

        # Normalize backslashes as path separators
        $value = $value.Replace('\', '/')

        # Remove query string and fragment
        $value = ($value -split '[?#]', 2)[0]

        # Remove trailing slashes and spaces
        $value = $value.Trim().TrimEnd('/').Trim()

        if ([string]::IsNullOrWhiteSpace($value)) {
            return ''
        }

        # Split by slash and return the last non-empty part
        $parts = @(
            $value -split '/' |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )

        if ($parts.Count -eq 0) {
            return ''
        }

        return [System.Net.WebUtility]::UrlDecode($parts[-1].Trim())
    }
}

