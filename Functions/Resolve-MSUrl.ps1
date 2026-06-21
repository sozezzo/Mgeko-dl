function Resolve-MSUrl {
        param(
            [Parameter(Mandatory)]
            [string]$BaseUrl,

            [AllowNull()]
            [AllowEmptyString()]
            [string]$Url
        )

        if ([string]::IsNullOrWhiteSpace($Url)) {
            return $null
        }

        try {
            return ([System.Uri]::new([System.Uri]$BaseUrl, $Url)).AbsoluteUri
        }
        catch {
            return $Url
        }
    }

