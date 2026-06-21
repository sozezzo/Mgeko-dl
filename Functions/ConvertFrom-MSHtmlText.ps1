function ConvertFrom-MSHtmlText {
        param(
            [AllowNull()]
            [AllowEmptyString()]
            [string]$Value
        )

        if ([string]::IsNullOrWhiteSpace($Value)) {
            return $null
        }

        $text = $Value -replace '(?is)<script\b.*?</script>', ' '
        $text = $text -replace '(?is)<style\b.*?</style>', ' '
        $text = $text -replace '(?is)<br\s*/?>', "`n"
        $text = $text -replace '(?is)<[^>]+>', ' '
        $text = [System.Net.WebUtility]::HtmlDecode($text)
        $text = $text -replace [char]0x00A0, ' '
        $text = $text -replace '[ \t]+', ' '
        $text = $text -replace "(`r`n|`r|`n)\s+", "`n"
        $text = $text.Trim()

        return $text
    }

