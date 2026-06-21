function Invoke-MSMgekoGetJson {
        param(
            [Parameter(Mandatory)]
            [string]$Url
        )

        Write-Verbose "GET JSON: $Url"

        $response = Invoke-WebRequest `
            -Uri $Url `
            -UseBasicParsing `
            -Headers @{
                'User-Agent' = $UserAgent
                'Accept'     = 'application/json,text/html;q=0.9,*/*;q=0.8'
                'Referer'    = $StartUrl
            }

        return [pscustomobject]@{
            RawContent = [string]$response.Content
            Json       = ($response.Content | ConvertFrom-Json)
        }
    }

