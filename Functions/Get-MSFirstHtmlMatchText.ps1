function Get-MSFirstHtmlMatchText {
        param(
            [Parameter(Mandatory)]
            [string]$Html,

            [Parameter(Mandatory)]
            [string]$Pattern
        )

        $match = [regex]::Match($Html, $Pattern, 'IgnoreCase, Singleline')

        if (-not $match.Success) {
            return $null
        }

        return ConvertFrom-MSHtmlText -Value $match.Groups[1].Value
    }

