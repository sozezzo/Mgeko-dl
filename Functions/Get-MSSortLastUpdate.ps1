function Get-MSSortLastUpdate {
        param(
            [Parameter(Mandatory)]
            [object]$Row
        )

        $value = $null

        if ($PassThru) {
            $value = Get-MSValue -Object $Row -Path 'lastUpdate.estimatedDate'
        }
        else {
            $value = $Row.LastUpdate
        }

        $date = ConvertTo-MSDate -Value $value

        if ($null -eq $date) {
            return [datetime]::MinValue
        }

        return $date
    }

