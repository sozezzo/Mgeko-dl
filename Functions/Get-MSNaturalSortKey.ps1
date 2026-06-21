function Get-MSNaturalSortKey {
        param(
            [Parameter(Mandatory)]
            [string]$Text
        )

        return [regex]::Replace(
            $Text,
            '\d+',
            {
                param($Match)
                $Match.Value.PadLeft(20, '0')
            }
        )
    }

