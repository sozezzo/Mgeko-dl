function ConvertTo-MSPaddedChapterName {
        param(
            [Parameter(Mandatory)]
            [string]$Name,

            [Parameter(Mandatory)]
            [int]$Padding
        )

        return [regex]::Replace(
            $Name,
            '\d+',
            {
                param($Match)
                $Match.Value.PadLeft($Padding, '0')
            }
        )
    }

