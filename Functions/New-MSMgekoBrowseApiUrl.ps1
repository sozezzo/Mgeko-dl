function New-MSMgekoBrowseApiUrl {
        param(
            [Parameter(Mandatory)]
            [string]$InputUrl,

            [Parameter(Mandatory)]
            [int]$Page
        )

        $uri = [System.Uri]::new($InputUrl)

        $query = ConvertFrom-MSQueryString -Query $uri.Query
        $query['page'] = [string]$Page

        $queryString = ConvertTo-MSQueryString -Query $query

        $builder = [System.UriBuilder]::new()
        $builder.Scheme = $uri.Scheme
        $builder.Host = $uri.Host
        $builder.Port = $uri.Port
        $builder.Path = '/browse-comics/data/'
        $builder.Query = $queryString

        return $builder.Uri.AbsoluteUri
    }

