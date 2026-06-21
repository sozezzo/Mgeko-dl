function Get-MSMangaInfoFromHtml {
<#
.SYNOPSIS
    Extracts normalized manga information from a manga info HTML page.

.DESCRIPTION
    Extracts:
        Name
        Author
        Rating
        Categories
        Status
        About
        Last update
        Chapter count
        Cover image URL
#>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$HtmlFilePath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$MangaUrl,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Slug,

        [datetime]$DownloadDate = (Get-Date),

        [string]$SourceCoverFileName = 'cover-source.jpg',

        [string]$FolderCoverFileName = 'folder-cover.jpg'
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if (-not (Get-Command Get-MSHtmlAttributeValue -ErrorAction SilentlyContinue)) {
        throw "Required function not found: Get-MSHtmlAttributeValue"
    }

    if (-not (Get-Command Get-MSMangaMetadataFromHtml -ErrorAction SilentlyContinue)) {
        throw "Required function not found: Get-MSMangaMetadataFromHtml"
    }

    $HtmlFilePath = [System.IO.Path]::GetFullPath($HtmlFilePath)

    if (-not (Test-Path -LiteralPath $HtmlFilePath -PathType Leaf)) {
        throw "HTML file not found: $HtmlFilePath"
    }

    

    

    $html = Get-Content -LiteralPath $HtmlFilePath -Raw

    $basicMeta = Get-MSMangaMetadataFromHtml `
        -FilePath $HtmlFilePath `
        -BaseUrl $MangaUrl

    # Name
    $name = Get-MSFirstHtmlMatchText `
        -Html $html `
        -Pattern '<h1\b[^>]*class\s*=\s*["''][^"'']*novel-title[^"'']*["''][^>]*>(.*?)</h1>'

    if ([string]::IsNullOrWhiteSpace($name)) {
        $name = $basicMeta.Title
        $name = $name -replace '\s*\[ALL CHAPTERS\]\s*$', ''
        $name = $name -replace '^\[Manga\]\s*:?\s*Manga\s+', ''
        $name = $name -replace '\s+Read\s*$', ''
        $name = $name.Trim()
    }

    # Author
    $author = Get-MSFirstHtmlMatchText `
        -Html $html `
        -Pattern '<span\b[^>]*itemprop\s*=\s*["'']author["''][^>]*>(.*?)</span>'

    if ([string]::IsNullOrWhiteSpace($author)) {
        $author = Get-MSFirstHtmlMatchText `
            -Html $html `
            -Pattern '<div\b[^>]*class\s*=\s*["'']author["''][^>]*>.*?<a\b[^>]*>(.*?)</a>'
    }

    # Rating - visible text, e.g. 4.5 (4)
    $ratingValue = $null
    $ratingCount = $null
    $ratingRawText = $null

    $ratingMatch = [regex]::Match(
        $html,
        '<strong>\s*([0-9]+(?:\.[0-9]+)?)\s*<span[^>]*>\s*\(([0-9]+)\)\s*</span>\s*</strong>',
        'IgnoreCase, Singleline'
    )

    if ($ratingMatch.Success) {
        $ratingValue = [double]::Parse(
            $ratingMatch.Groups[1].Value,
            [System.Globalization.CultureInfo]::InvariantCulture
        )

        $ratingCount = [int]$ratingMatch.Groups[2].Value
        $ratingRawText = "$($ratingMatch.Groups[1].Value) ($($ratingMatch.Groups[2].Value))"
    }

    # Categories
    $categories = @()
    $categoriesBlockMatch = [regex]::Match(
        $html,
        '<div\b[^>]*class\s*=\s*["''][^"'']*categories[^"'']*["''][^>]*>(.*?)</div>',
        'IgnoreCase, Singleline'
    )

    if ($categoriesBlockMatch.Success) {
        $categoryLinks = @([regex]::Matches(
            $categoriesBlockMatch.Groups[1].Value,
            '<a\b[^>]*>(.*?)</a>',
            'IgnoreCase, Singleline'
        ))

        foreach ($categoryLink in $categoryLinks) {
            $categoryText = ConvertFrom-MSHtmlText -Value $categoryLink.Groups[1].Value

            if (-not [string]::IsNullOrWhiteSpace($categoryText)) {
                $categories += $categoryText.Trim()
            }
        }
    }

    $categories = @(
        $categories |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { $_.Trim() } |
            Sort-Object -Unique
    )

    # Status
    $status = Get-MSFirstHtmlMatchText `
        -Html $html `
        -Pattern '<strong\b[^>]*class\s*=\s*["''][^"'']*(ongoing|completed|hiatus|dropped)[^"'']*["''][^>]*>(.*?)</strong>'

    # The regex above captures class as group 1 and text as group 2.
    # If status did not resolve correctly, use another direct match.
    $statusMatch = [regex]::Match(
        $html,
        '<strong\b[^>]*class\s*=\s*["''][^"'']*(?:ongoing|completed|hiatus|dropped)[^"'']*["''][^>]*>(.*?)</strong>',
        'IgnoreCase, Singleline'
    )

    if ($statusMatch.Success) {
        $status = ConvertFrom-MSHtmlText -Value $statusMatch.Groups[1].Value
    }

    # About / description
    $about = Get-MSFirstHtmlMatchText `
        -Html $html `
        -Pattern '<p\b[^>]*class\s*=\s*["''][^"'']*description[^"'']*["''][^>]*>(.*?)</p>'

    if ([string]::IsNullOrWhiteSpace($about)) {
        $about = $basicMeta.Description
    }

    # Last update
    $lastUpdateRaw = Get-MSFirstHtmlMatchText `
        -Html $html `
        -Pattern '<div\b[^>]*class\s*=\s*["''][^"'']*updinfo[^"'']*["''][^>]*>.*?<strong\b[^>]*>(.*?)</strong>'

    $lastUpdate = Convert-MSRelativeLastUpdateToDate `
        -RawText $lastUpdateRaw `
        -ReferenceDate $DownloadDate

    # Chapter count
    $chaptersRawText = $null
    $chapterCount = $null

    $headerStatsMatch = [regex]::Match(
        $html,
        '<div\b[^>]*class\s*=\s*["''][^"'']*header-stats[^"'']*["''][^>]*>(.*?)</div>',
        'IgnoreCase, Singleline'
    )

    if ($headerStatsMatch.Success) {
        $statSpans = @([regex]::Matches(
            $headerStatsMatch.Groups[1].Value,
            '<span\b[^>]*>(.*?)</span>',
            'IgnoreCase, Singleline'
        ))

        foreach ($statSpan in $statSpans) {
            $spanHtml = $statSpan.Groups[1].Value
            $smallText = Get-MSFirstHtmlMatchText -Html $spanHtml -Pattern '<small\b[^>]*>(.*?)</small>'

            if ($smallText -eq 'Chapters') {
                $strongText = Get-MSFirstHtmlMatchText -Html $spanHtml -Pattern '<strong\b[^>]*>(.*?)</strong>'
                $chaptersRawText = $strongText

                if ($chaptersRawText -match '([0-9]+)') {
                    $chapterCount = [int]$Matches[1]
                }

                break
            }
        }
    }

    # Fallback from chapter links if header stat failed
    if ($null -eq $chapterCount) {
        $chapterNumbers = @()

        $chapterMatches = @([regex]::Matches(
            $html,
            '/reader/[^"'']*?-chapter-([0-9]+(?:\.[0-9]+)?)[^"'']*/',
            'IgnoreCase'
        ))

        foreach ($chapterMatch in $chapterMatches) {
            $numberText = $chapterMatch.Groups[1].Value

            if ($numberText -match '^\d+$') {
                $chapterNumbers += [int]$numberText
            }
        }

        if ($chapterNumbers.Count -gt 0) {
            $chapterCount = ($chapterNumbers | Measure-Object -Maximum).Maximum
            $chaptersRawText = [string]$chapterCount
        }
    }

    return [pscustomobject]@{
        SchemaVersion = 1
        Source = [pscustomobject]@{
            Site                = $basicMeta.SiteName
            MangaUrl            = $MangaUrl
            Slug                = $Slug
            MetadataHtmlFile    = 'manga-info-page.html'
            AllChaptersHtmlFile = 'allchapters.html'
        }
        Manga = [pscustomobject]@{
            Name       = $name
            Author     = $author
            Status     = $status
            About      = $about
            Categories = @($categories)
        }
        Rating = [pscustomobject]@{
            Value   = $ratingValue
            Count   = $ratingCount
            RawText = $ratingRawText
        }
        Chapters = [pscustomobject]@{
            Count         = $chapterCount
            RawText       = $chaptersRawText
            LocalCbzCount = $null
        }
        LastUpdate = [pscustomobject]@{
            RawText        = $lastUpdate.RawText
            EstimatedDate  = $lastUpdate.EstimatedDate
            CalculatedFrom = $lastUpdate.CalculatedFrom
            AgeYears       = $lastUpdate.AgeYears
            AgeMonths      = $lastUpdate.AgeMonths
            AgeWeeks       = $lastUpdate.AgeWeeks
            AgeDays        = $lastUpdate.AgeDays
            TotalAgeMonths = $lastUpdate.TotalAgeMonths
            IsApproximate  = $lastUpdate.IsApproximate
        }
        Images = [pscustomobject]@{
            CoverImageUrl   = $basicMeta.CoverImageUrl
            SourceCoverFile = $SourceCoverFileName
            FolderCoverFile = $FolderCoverFileName
        }
    }
}

