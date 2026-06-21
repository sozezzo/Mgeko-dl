function ConvertTo-MSQueryString {
        param(
            [Parameter(Mandatory)]
            [System.Collections.IDictionary]$Query
        )

        $items = foreach ($key in $Query.Keys) {
            if ($null -eq $Query[$key]) {
                continue
            }

            $encodedKey = [System.Uri]::EscapeDataString([string]$key)
            $encodedValue = [System.Uri]::EscapeDataString([string]$Query[$key])

            "$encodedKey=$encodedValue"
        }

        return ($items -join '&')
    }

