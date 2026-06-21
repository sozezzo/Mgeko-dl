function Find-MSMangaCatalog {
<#
.SYNOPSIS
    Filters and sorts manga from mgeko-manga-catalog.json.

.DESCRIPTION
    Reads the catalog JSON created by Invoke-MSMangaCatalogDiscovery and filters by:
        - Included categories
        - Excluded categories
        - Minimum / maximum rating
        - Status
        - Part of manga name

    Supports ordering by:
        - Rating
        - A-Z
        - Popular
        - Status
        - LastUpdate
        - Chapters
        - Name

.PARAMETER CatalogFile
    Path to mgeko-manga-catalog.json.

.PARAMETER IncludeCategory
    One or more categories that must be present.
    Matching is case-insensitive.

.PARAMETER IncludeMode
    Any = manga must contain at least one included category.
    All = manga must contain all included categories.

.PARAMETER ExcludeCategory
    One or more categories that must not be present.
    Matching is case-insensitive.

.PARAMETER MinRating
    Minimum rating value.

.PARAMETER MaxRating
    Maximum rating value.

.PARAMETER Status
    Filter by status. Example: Ongoing, Completed, Hiatus.
    Matching is case-insensitive.

.PARAMETER NameContains
    Filters by part of the manga name.
    Matching is case-insensitive.

.PARAMETER OrderBy
    Sort field:
        Rating
        A-Z
        Popular
        Status
        LastUpdate
        Chapters
        Name

.PARAMETER SortDirection
    Auto:
        Rating, Popular, LastUpdate, Chapters = Descending
        A-Z, Name, Status = Ascending

.PARAMETER First
    Returns only the first N rows.
    0 = all.

.PARAMETER PassThru
    Returns the original catalog item instead of a flattened object.

.EXAMPLE
    Find-MSMangaCatalog `
        -CatalogFile "C:\temp\mgeko-download\mgeko-manga-catalog.json" `
        -IncludeCategory "Psychological","Action" `
        -MinRating 4.5 `
        -OrderBy Rating

.EXAMPLE
    Find-MSMangaCatalog `
        -CatalogFile "C:\temp\mgeko-download\mgeko-manga-catalog.json" `
        -ExcludeCategory "Harem","Romance" `
        -Status "Completed" `
        -OrderBy A-Z

.EXAMPLE
    Find-MSMangaCatalog `
        -CatalogFile "C:\temp\mgeko-download\mgeko-manga-catalog.json" `
        -NameContains "goblin" `
        -OrderBy Popular
#>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$CatalogFile,

        [string[]]$IncludeCategory,

        [string[]]$ExcludeCategory,

        [Nullable[double]]$MinRating,

        [Nullable[double]]$MaxRating,

        [string[]]$Status,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$NameContains,

        [ValidateSet('Rating', 'A-Z', 'Popular', 'Status', 'LastUpdate', 'Chapters', 'Name')]
        [string]$OrderBy = 'Rating',

        [ValidateSet('Auto', 'Ascending', 'Descending')]
        [string]$SortDirection = 'Auto',

        [ValidateRange(0, 999999)]
        [int]$First = 0,

        [switch]$PassThru
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    

    

    

    

    

    

    

    

    

    

    

    

    

    if (-not (Test-Path -LiteralPath $CatalogFile -PathType Leaf)) {
        throw "Catalog file not found: $CatalogFile"
    }

    $catalog = Get-Content -LiteralPath $CatalogFile -Raw | ConvertFrom-Json

    if (-not (Test-MSPropertyExists -Object $catalog -PropertyName 'items')) {
        throw "Invalid catalog JSON. Property not found: items"
    }

    $includeNormalized = @(
        $IncludeCategory |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { ConvertTo-MSNormalizedText -Value $_ }
    )

    $excludeNormalized = @(
        $ExcludeCategory |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { ConvertTo-MSNormalizedText -Value $_ }
    )

    $statusNormalized = @(
        $Status |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { ConvertTo-MSNormalizedText -Value $_ }
    )

    $nameSearch = ConvertTo-MSNormalizedText -Value $NameContains

    $items = @($catalog.items)

    $filtered = foreach ($item in $items) {
        $name = [string](Get-MSValue -Object $item -Path 'manga.name')
        $itemStatus = [string](Get-MSValue -Object $item -Path 'manga.status')
        $rating = ConvertTo-MSDouble -Value (Get-MSValue -Object $item -Path 'rating.value')
        $ratingCount = ConvertTo-MSDouble -Value (Get-MSValue -Object $item -Path 'rating.count')
        $chapterCount = ConvertTo-MSDouble -Value (Get-MSValue -Object $item -Path 'chapters.count')
        $lastUpdateDate = ConvertTo-MSDate -Value (Get-MSValue -Object $item -Path 'lastUpdate.estimatedDate')
        $popularValue = Get-MSPopularityValue -Item $item

        $categories = @(Get-MSCategoryArray -Item $item)
        $categoriesNormalized = @(
            $categories |
                ForEach-Object { ConvertTo-MSNormalizedText -Value $_ }
        )

        if ($nameSearch.Length -gt 0) {
            if ((ConvertTo-MSNormalizedText -Value $name) -notlike "*$nameSearch*") {
                continue
            }
        }

        if ($statusNormalized.Count -gt 0) {
            if ($statusNormalized -notcontains (ConvertTo-MSNormalizedText -Value $itemStatus)) {
                continue
            }
        }

        if ($null -ne $MinRating) {
            if ($null -eq $rating -or $rating -lt [double]$MinRating) {
                continue
            }
        }

        if ($null -ne $MaxRating) {
            if ($null -eq $rating -or $rating -gt [double]$MaxRating) {
                continue
            }
        }

        # IncludeCategory uses AND logic:
        # The manga must contain ALL included categories.
        if ($includeNormalized.Count -gt 0) {
            $hasAllIncludedCategories = $true

            foreach ($category in $includeNormalized) {
                if ($categoriesNormalized -notcontains $category) {
                    $hasAllIncludedCategories = $false
                    break
                }
            }

            if (-not $hasAllIncludedCategories) {
                continue
            }
        }

        if ($excludeNormalized.Count -gt 0) {
            $hasExcluded = $false

            foreach ($category in $excludeNormalized) {
                if ($categoriesNormalized -contains $category) {
                    $hasExcluded = $true
                    break
                }
            }

            if ($hasExcluded) {
                continue
            }
        }

        if ($PassThru) {
            $item
        }
        else {
            [pscustomobject]@{
                Name           = $name
                Author         = Get-MSValue -Object $item -Path 'manga.author'
                Status         = $itemStatus
                Rating         = $rating
                RatingCount    = $ratingCount
                Popular        = $popularValue
                Chapters       = $chapterCount
                LastUpdate     = if ($null -ne $lastUpdateDate) { $lastUpdateDate.ToString('yyyy-MM-dd') } else { $null }
                LastUpdateText = Get-MSValue -Object $item -Path 'lastUpdate.rawText'
                Categories     = ($categories -join ', ')
                Url            = Get-MSValue -Object $item -Path 'source.mangaUrl'
                Item           = $item
            }
        }
    }

    $filtered = @($filtered)

    $descending = $false

    switch ($SortDirection) {
        'Ascending' {
            $descending = $false
        }

        'Descending' {
            $descending = $true
        }

        'Auto' {
            switch ($OrderBy) {
                'Rating' {
                    $descending = $true
                }

                'Popular' {
                    $descending = $true
                }

                'LastUpdate' {
                    $descending = $true
                }

                'Chapters' {
                    $descending = $true
                }

                default {
                    $descending = $false
                }
            }
        }
    }

    $sorted = switch ($OrderBy) {
        'Rating' {
            $filtered | Sort-Object -Property `
                @{ Expression = { Get-MSSortRating -Row $_ }; Descending = $descending },
                @{ Expression = { Get-MSSortName -Row $_ }; Ascending = $true }
        }

        'A-Z' {
            $filtered | Sort-Object -Property `
                @{ Expression = { Get-MSSortName -Row $_ }; Descending = $descending }
        }

        'Name' {
            $filtered | Sort-Object -Property `
                @{ Expression = { Get-MSSortName -Row $_ }; Descending = $descending }
        }

        'Popular' {
            $filtered | Sort-Object -Property `
                @{ Expression = { Get-MSSortPopularity -Row $_ }; Descending = $descending },
                @{ Expression = { Get-MSSortName -Row $_ }; Ascending = $true }
        }

        'Status' {
            $filtered | Sort-Object -Property `
                @{ Expression = { Get-MSSortStatus -Row $_ }; Descending = $descending },
                @{ Expression = { Get-MSSortName -Row $_ }; Ascending = $true }
        }

        'LastUpdate' {
            $filtered | Sort-Object -Property `
                @{ Expression = { Get-MSSortLastUpdate -Row $_ }; Descending = $descending },
                @{ Expression = { Get-MSSortName -Row $_ }; Ascending = $true }
        }

        'Chapters' {
            $filtered | Sort-Object -Property `
                @{ Expression = { Get-MSSortChapters -Row $_ }; Descending = $descending },
                @{ Expression = { Get-MSSortName -Row $_ }; Ascending = $true }
        }
    }

    $sorted = @($sorted)

    if ($First -gt 0) {
        $sorted = @($sorted | Select-Object -First $First)
    }

    return @($sorted)
}

