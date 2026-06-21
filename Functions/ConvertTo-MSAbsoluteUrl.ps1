function ConvertTo-MSAbsoluteUrl {
        param(
            [Parameter(Mandatory)]
            [string]$Value
        )

        $Value = [System.Net.WebUtility]::HtmlDecode($Value.Trim())

        if ([string]::IsNullOrWhiteSpace($Value)) {
            return $null
        }

        if ($null -ne $baseUri) {
            try {
                return ([System.Uri]::new($baseUri, $Value)).AbsoluteUri
            }
            catch {
                return $Value
            }
        }

        return $Value
    }

