function Invoke-MSMgekoGetHtml {
        param(
            [Parameter(Mandatory)]
            [string]$Url
        )

        Write-Verbose "GET HTML: $Url"

        $response = Invoke-WebRequest `
            -Uri $Url `
            -UseBasicParsing `
            -Headers @{
                'User-Agent' = $UserAgent
                'Accept'     = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
                'Referer'    = $StartUrl
            }

        return [string]$response.Content
    }

