function Get-MSSortPopularity {
        param(
            [Parameter(Mandatory)]
            [object]$Row
        )

        if ($PassThru) {
            return Get-MSPopularityValue -Item $Row
        }

        $number = ConvertTo-MSDouble -Value $Row.Popular

        if ($null -eq $number) {
            return 0
        }

        return $number
    }

