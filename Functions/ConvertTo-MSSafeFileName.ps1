function ConvertTo-MSSafeFileName {
        param(
            [Parameter(Mandatory)]
            [string]$Name
        )

        foreach ($char in [System.IO.Path]::GetInvalidFileNameChars()) {
            $Name = $Name.Replace($char, '_')
        }

        return $Name
    }

