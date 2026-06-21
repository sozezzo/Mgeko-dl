function ConvertTo-MSDate {
        param(
            [AllowNull()]
            [object]$Value
        )

        if ($null -eq $Value) {
            return $null
        }

        $text = [string]$Value

        if ([string]::IsNullOrWhiteSpace($text)) {
            return $null
        }

        $date = [datetime]::MinValue

        if ([datetime]::TryParse($text, [ref]$date)) {
            return $date
        }

        return $null
    }

