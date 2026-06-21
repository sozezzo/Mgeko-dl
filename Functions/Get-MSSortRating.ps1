function Get-MSSortRating {
        param(
            [Parameter(Mandatory)]
            [object]$Row
        )

        $value = $null

        if ($PassThru) {
            $value = Get-MSValue -Object $Row -Path 'rating.value'
        }
        else {
            $value = $Row.Rating
        }

        $number = ConvertTo-MSDouble -Value $value

        if ($null -eq $number) {
            return -1
        }

        return $number
    }

