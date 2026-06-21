function Get-MSAttributeValue {
        param(
            [Parameter(Mandatory)]
            [string]$Tag,

            [Parameter(Mandatory)]
            [string]$AttributeName
        )

        $escapedAttributeName = [regex]::Escape($AttributeName)

        $pattern = '(?i)\b' + $escapedAttributeName + '\s*=\s*(?:"([^"]*)"|''([^'']*)''|([^\s>]+))'

        $match = [regex]::Match($Tag, $pattern)

        if (-not $match.Success) {
            return $null
        }

        if ($match.Groups[1].Success) {
            return $match.Groups[1].Value
        }

        if ($match.Groups[2].Success) {
            return $match.Groups[2].Value
        }

        if ($match.Groups[3].Success) {
            return $match.Groups[3].Value
        }

        return $null
    }

