function ConvertTo-MSAbsoluteMetadataUrl {
        param(
            [AllowNull()]
            [AllowEmptyString()]
            [string]$Value
        )

        if ([string]::IsNullOrWhiteSpace($Value)) {
            return $null
        }

        $Value = [System.Net.WebUtility]::HtmlDecode($Value.Trim())

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

