function ConvertTo-MSNormalizedText {
        param(
            [AllowNull()]
            [AllowEmptyString()]
            [string]$Value
        )

        if ([string]::IsNullOrWhiteSpace($Value)) {
            return ''
        }

        return $Value.Trim().ToLowerInvariant()
    }

