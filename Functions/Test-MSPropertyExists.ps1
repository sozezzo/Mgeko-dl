function Test-MSPropertyExists {
        param(
            [AllowNull()]
            [object]$Object,

            [Parameter(Mandatory)]
            [string]$PropertyName
        )

        if ($null -eq $Object) {
            return $false
        }

        return ($Object.PSObject.Properties.Name -contains $PropertyName)
    }

