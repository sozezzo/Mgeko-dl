function Get-MSValue {
        param(
            [AllowNull()]
            [object]$Object,

            [Parameter(Mandatory)]
            [string]$Path
        )

        if ($null -eq $Object) {
            return $null
        }

        $current = $Object

        foreach ($part in ($Path -split '\.')) {
            if ($null -eq $current) {
                return $null
            }

            if (-not (Test-MSPropertyExists -Object $current -PropertyName $part)) {
                return $null
            }

            $current = $current.$part
        }

        return $current
    }

