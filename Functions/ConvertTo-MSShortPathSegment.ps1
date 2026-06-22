function ConvertTo-MSShortPathSegment {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateRange(10, 255)]
        [int]$MaximumLength
    )

    if ($Name.Length -le $MaximumLength) {
        return $Name
    }

    $sha256 = [System.Security.Cryptography.SHA256]::Create()

    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Name)
        $hashBytes = $sha256.ComputeHash($bytes)
        $hash = ([System.BitConverter]::ToString($hashBytes)).Replace('-', '').Substring(0, 8).ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }

    $prefixLength = $MaximumLength - $hash.Length - 1
    $prefix = $Name.Substring(0, $prefixLength).TrimEnd(' ', '.', '-', '_')

    if ([string]::IsNullOrWhiteSpace($prefix)) {
        $prefix = $Name.Substring(0, $prefixLength)
    }

    return "$prefix-$hash"
}
