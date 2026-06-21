function ConvertTo-MSDouble {
        param(
            [AllowNull()]
            [object]$Value
        )

        if ($null -eq $Value) {
            return $null
        }

        if (
            $Value -is [double] -or
            $Value -is [single] -or
            $Value -is [decimal] -or
            $Value -is [int] -or
            $Value -is [long]
        ) {
            return [double]$Value
        }

        $text = [string]$Value

        if ([string]::IsNullOrWhiteSpace($text)) {
            return $null
        }

        $clean = $text.Trim()
        $clean = $clean -replace ',', ''
        $clean = $clean -replace [char]0x00A0, ' '

        $multiplier = 1.0

        if ($clean -match '(?i)\b([0-9]+(?:\.[0-9]+)?)\s*K\b') {
            $clean = $Matches[1]
            $multiplier = 1000.0
        }
        elseif ($clean -match '(?i)\b([0-9]+(?:\.[0-9]+)?)\s*M\b') {
            $clean = $Matches[1]
            $multiplier = 1000000.0
        }
        elseif ($clean -match '(?i)\b([0-9]+(?:\.[0-9]+)?)\s*B\b') {
            $clean = $Matches[1]
            $multiplier = 1000000000.0
        }
        elseif ($clean -match '([0-9]+(?:\.[0-9]+)?)') {
            $clean = $Matches[1]
        }

        $number = 0.0

        if ([double]::TryParse(
            $clean,
            [System.Globalization.NumberStyles]::Float,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref]$number
        )) {
            return ($number * $multiplier)
        }

        return $null
    }

