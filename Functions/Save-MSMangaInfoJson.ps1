function Save-MSMangaInfoJson {
<#
.SYNOPSIS
    Saves or updates manga-info.json.

.DESCRIPTION
    Reads manga-info-page.html, extracts metadata, compares it with the existing
    manga-info.json if present, and updates download/change timestamps.

    Replaces manga-info.txt.
#>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$HtmlFilePath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputFolder,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$MangaUrl,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Slug,

        [int]$LocalCbzCount = 0,

        [string]$JsonFileName = 'manga-info.json',

        [string]$SourceCoverFileName = 'cover-source.jpg',

        [string]$FolderCoverFileName = 'folder-cover.jpg',

        [datetimeoffset]$DownloadDate = ([datetimeoffset]::Now)
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    if (-not (Get-Command Get-MSMangaInfoFromHtml -ErrorAction SilentlyContinue)) {
        throw "Required function not found: Get-MSMangaInfoFromHtml"
    }

    if (-not (Test-Path -LiteralPath $OutputFolder -PathType Container)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }

    $jsonFilePath = Join-Path $OutputFolder $JsonFileName

    $downloadIso = $DownloadDate.ToString('o')
    $downloadDateOnly = $DownloadDate.DateTime.Date

    $newInfo = Get-MSMangaInfoFromHtml `
        -HtmlFilePath $HtmlFilePath `
        -MangaUrl $MangaUrl `
        -Slug $Slug `
        -DownloadDate $downloadDateOnly `
        -SourceCoverFileName $SourceCoverFileName `
        -FolderCoverFileName $FolderCoverFileName

    $newInfo.Chapters.LocalCbzCount = $LocalCbzCount

    $oldInfo = $null
    $oldComparableJson = $null

    if (Test-Path -LiteralPath $jsonFilePath -PathType Leaf) {
        try {
            $oldInfo = Get-Content -LiteralPath $jsonFilePath -Raw | ConvertFrom-Json
        }
        catch {
            Write-Warning "Existing manga-info.json could not be parsed. It will be replaced. Error: $($_.Exception.Message)"
        }
    }

    

    $newComparableJson = ConvertTo-MSComparableMangaInfoJson -Info $newInfo

    $firstDownloadedAt = $downloadIso
    $lastMetadataChangedAt = $downloadIso
    $downloadCount = 1
    $metadataChanged = $true

    if ($null -ne $oldInfo) {
        if ($oldInfo.PSObject.Properties.Name -contains 'Download') {
            if ($oldInfo.Download.PSObject.Properties.Name -contains 'FirstDownloadedAt') {
                if (-not [string]::IsNullOrWhiteSpace($oldInfo.Download.FirstDownloadedAt)) {
                    $firstDownloadedAt = $oldInfo.Download.FirstDownloadedAt
                }
            }

            if ($oldInfo.Download.PSObject.Properties.Name -contains 'LastMetadataChangedAt') {
                if (-not [string]::IsNullOrWhiteSpace($oldInfo.Download.LastMetadataChangedAt)) {
                    $lastMetadataChangedAt = $oldInfo.Download.LastMetadataChangedAt
                }
            }

            if ($oldInfo.Download.PSObject.Properties.Name -contains 'DownloadCount') {
                if ($null -ne $oldInfo.Download.DownloadCount) {
                    $downloadCount = [int]$oldInfo.Download.DownloadCount + 1
                }
            }
        }

        try {
            $oldComparableJson = ConvertTo-MSComparableMangaInfoJson -Info $oldInfo
        }
        catch {
            $oldComparableJson = $null
        }

        if ($oldComparableJson -eq $newComparableJson) {
            $metadataChanged = $false
        }
        else {
            $metadataChanged = $true
            $lastMetadataChangedAt = $downloadIso
        }
    }

    $finalInfo = [ordered]@{
        schemaVersion = 1
        source = [ordered]@{
            site                = $newInfo.Source.Site
            mangaUrl            = $newInfo.Source.MangaUrl
            slug                = $newInfo.Source.Slug
            metadataHtmlFile    = $newInfo.Source.MetadataHtmlFile
            allChaptersHtmlFile = $newInfo.Source.AllChaptersHtmlFile
        }
        download = [ordered]@{
            firstDownloadedAt     = $firstDownloadedAt
            lastDownloadedAt      = $downloadIso
            lastMetadataChangedAt = $lastMetadataChangedAt
            downloadCount         = $downloadCount
            metadataChanged       = $metadataChanged
        }
        manga = [ordered]@{
            name       = $newInfo.Manga.Name
            author     = $newInfo.Manga.Author
            status     = $newInfo.Manga.Status
            about      = $newInfo.Manga.About
            categories = @($newInfo.Manga.Categories)
        }
        rating = [ordered]@{
            value   = $newInfo.Rating.Value
            count   = $newInfo.Rating.Count
            rawText = $newInfo.Rating.RawText
        }
        chapters = [ordered]@{
            count         = $newInfo.Chapters.Count
            rawText       = $newInfo.Chapters.RawText
            localCbzCount = $newInfo.Chapters.LocalCbzCount
        }
        lastUpdate = [ordered]@{
            rawText        = $newInfo.LastUpdate.RawText
            estimatedDate  = $newInfo.LastUpdate.EstimatedDate
            calculatedFrom = $newInfo.LastUpdate.CalculatedFrom
            ageYears       = $newInfo.LastUpdate.AgeYears
            ageMonths      = $newInfo.LastUpdate.AgeMonths
            ageWeeks       = $newInfo.LastUpdate.AgeWeeks
            ageDays        = $newInfo.LastUpdate.AgeDays
            totalAgeMonths = $newInfo.LastUpdate.TotalAgeMonths
            isApproximate  = $newInfo.LastUpdate.IsApproximate
        }
        images = [ordered]@{
            coverImageUrl   = $newInfo.Images.CoverImageUrl
            sourceCoverFile = $newInfo.Images.SourceCoverFile
            folderCoverFile = $newInfo.Images.FolderCoverFile
        }
    }

    $json = $finalInfo | ConvertTo-Json -Depth 20

    Set-Content `
        -LiteralPath $jsonFilePath `
        -Value $json `
        -Encoding UTF8

    return [pscustomobject]@{
        Status                = 'Saved'
        JsonFilePath          = $jsonFilePath
        MetadataChanged       = $metadataChanged
        FirstDownloadedAt     = $firstDownloadedAt
        LastDownloadedAt      = $downloadIso
        LastMetadataChangedAt = $lastMetadataChangedAt
        DownloadCount         = $downloadCount
        MangaName             = $newInfo.Manga.Name
        Rating                = $newInfo.Rating.Value
        Categories            = @($newInfo.Manga.Categories)
        ChapterCount          = $newInfo.Chapters.Count
        LocalCbzCount         = $newInfo.Chapters.LocalCbzCount
        LastUpdateRawText     = $newInfo.LastUpdate.RawText
        LastUpdateDate        = $newInfo.LastUpdate.EstimatedDate
    }
}

