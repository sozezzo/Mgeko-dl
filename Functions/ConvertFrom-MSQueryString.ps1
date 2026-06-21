function ConvertFrom-MSQueryString {
        param(
            [AllowNull()]
            [AllowEmptyString()]
            [string]$Query
        )

        $hash = [ordered]@{}

        if ([string]::IsNullOrWhiteSpace($Query)) {
            return $hash
        }

        $queryText = $Query.TrimStart('?')

        foreach ($pair in ($queryText -split '&')) {
            if ([string]::IsNullOrWhiteSpace($pair)) {
                continue
            }

            $parts = $pair -split '=', 2
            $key = [System.Uri]::UnescapeDataString($parts[0])

            if ($parts.Count -gt 1) {
                $value = [System.Uri]::UnescapeDataString($parts[1])
            }
            else {
                $value = ''
            }

            $hash[$key] = $value
        }

        return $hash
    }

