function Invoke-MSMangaCatalogDiscovery {
<#
.SYNOPSIS
    Discovers all Mgeko manga from the browse API and creates one catalog JSON.

.DESCRIPTION
    This function does not download chapters, images, or CBZ files.

    It copies the website JavaScript logic:

        1. Start from a browse page:
           https://www.mgeko.cc/browse-comics/?sort=az&page=1&safe_mode=0

        2. Convert it to the API endpoint:
           https://www.mgeko.cc/browse-comics/data/?sort=az&page=1&safe_mode=0

        3. Read:
           data.results_html
           data.total_results
           data.page
           data.num_pages

        4. Extract manga URLs from:
           a.comic-card__button href

        5. For each manga URL, download the manga info page.

        6. Parse full metadata using Get-MSMangaInfoFromHtml.

        7. Save one JSON file:
           <RootFolder>\mgeko-manga-catalog.json

.PARAMETER StartUrl
    Entry browse URL.

.PARAMETER RootFolder
    Folder where the catalog JSON will be saved.

.PARAMETER OutputFileName
    Catalog JSON filename.

.PARAMETER MaxPages
    Optional test limit. 0 = all pages.

.PARAMETER MaxManga
    Optional test limit. 0 = all discovered manga.

.PARAMETER PageDelayMs
    Delay between browse API page calls.

.PARAMETER MangaDelayMs
    Delay between manga detail page calls.

.PARAMETER KeepRawBrowsePages
    Saves API JSON and results_html pages for debugging.

.PARAMETER KeepMangaInfoPages
    Keeps temporary manga info HTML files for debugging.

.EXAMPLE
    Invoke-MSMangaCatalogDiscovery `
        -StartUrl "https://www.mgeko.cc/browse-comics/?sort=az&page=1&safe_mode=0" `
        -RootFolder "C:\temp\mgeko-manga\mgeko-download" `
        -Verbose

.EXAMPLE
    Invoke-MSMangaCatalogDiscovery `
        -StartUrl "https://www.mgeko.cc/browse-comics/?sort=az&page=1&safe_mode=0" `
        -RootFolder "C:\temp\mgeko-manga\mgeko-download" `
        -MaxPages 2 `
        -MaxManga 20 `
        -KeepRawBrowsePages `
        -KeepMangaInfoPages `
        -Verbose
#>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$StartUrl,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RootFolder,

        [ValidateNotNullOrEmpty()]
        [string]$OutputFileName = 'mgeko-manga-catalog.json',

        [ValidateRange(0, 999999)]
        [int]$MaxPages = 0,

        [ValidateRange(0, 999999)]
        [int]$MaxManga = 0,

        [ValidateRange(0, 60000)]
        [int]$PageDelayMs = 250,

        [ValidateRange(0, 60000)]
        [int]$MangaDelayMs = 250,

        [switch]$KeepRawBrowsePages,

        [switch]$KeepMangaInfoPages,

        [ValidateNotNullOrEmpty()]
        [string]$UserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome Safari'
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    foreach ($requiredFunction in @(
        'Get-MSMangaInfoFromHtml'
    )) {
        if (-not (Get-Command $requiredFunction -ErrorAction SilentlyContinue)) {
            throw "Required function not found: $requiredFunction"
        }
    }

    

    

    

    

    

    

    

    

    

    

    

    

    if (-not (Test-Path -LiteralPath $RootFolder -PathType Container)) {
        New-Item -Path $RootFolder -ItemType Directory -Force | Out-Null
    }

    $RootFolder = [System.IO.Path]::GetFullPath($RootFolder)

    $outputFilePath = Join-Path $RootFolder $OutputFileName
    $rawFolder = Join-Path $RootFolder '_mgeko-browse-api-pages'
    $detailFolder = Join-Path $RootFolder '_mgeko-catalog-detail-pages'

    if ($KeepRawBrowsePages -and -not (Test-Path -LiteralPath $rawFolder -PathType Container)) {
        New-Item -Path $rawFolder -ItemType Directory -Force | Out-Null
    }

    if ($KeepMangaInfoPages -and -not (Test-Path -LiteralPath $detailFolder -PathType Container)) {
        New-Item -Path $detailFolder -ItemType Directory -Force | Out-Null
    }

    $runDate = [datetimeoffset]::Now
    $runIso = $runDate.ToString('o')

    $startUri = [System.Uri]::new($StartUrl)
    $baseUrl = "$($startUri.Scheme)://$($startUri.Host)/"

    $firstApiUrl = New-MSMgekoBrowseApiUrl `
        -InputUrl $StartUrl `
        -Page 1

    $firstResponse = Invoke-MSMgekoGetJson -Url $firstApiUrl
    $firstJson = $firstResponse.Json

    $totalPages = 1
    $totalResults = $null

    if ($firstJson.PSObject.Properties.Name -contains 'num_pages') {
        $totalPages = [int]$firstJson.num_pages
    }

    if ($firstJson.PSObject.Properties.Name -contains 'total_results') {
        $totalResults = [int]$firstJson.total_results
    }

    if ($MaxPages -gt 0 -and $MaxPages -lt $totalPages) {
        $pagesToProcess = $MaxPages
    }
    else {
        $pagesToProcess = $totalPages
    }

    Write-Verbose "First API URL     : $firstApiUrl"
    Write-Verbose "Total results     : $totalResults"
    Write-Verbose "Total pages       : $totalPages"
    Write-Verbose "Pages to process  : $pagesToProcess"

    $mangaByUrl = [ordered]@{}

    for ($pageNumber = 1; $pageNumber -le $pagesToProcess; $pageNumber++) {
        if ($pageNumber -eq 1) {
            $apiUrl = $firstApiUrl
            $apiResponse = $firstResponse
            $pageJson = $firstJson
        }
        else {
            $apiUrl = New-MSMgekoBrowseApiUrl `
                -InputUrl $StartUrl `
                -Page $pageNumber

            $apiResponse = Invoke-MSMgekoGetJson -Url $apiUrl
            $pageJson = $apiResponse.Json
        }

        if ($KeepRawBrowsePages) {
            $jsonFile = Join-Path $rawFolder ('browse-api-page-{0:000000}.json' -f $pageNumber)
            Set-Content -LiteralPath $jsonFile -Value $apiResponse.RawContent -Encoding UTF8

            if ($pageJson.PSObject.Properties.Name -contains 'results_html') {
                $htmlFile = Join-Path $rawFolder ('browse-api-page-{0:000000}.html' -f $pageNumber)
                Set-Content -LiteralPath $htmlFile -Value ([string]$pageJson.results_html) -Encoding UTF8
            }
        }

        $resultsHtml = ''

        if ($pageJson.PSObject.Properties.Name -contains 'results_html') {
            $resultsHtml = [string]$pageJson.results_html
        }

        $pageItems = @(
            Get-MSMgekoMangaUrlFromResultsHtml `
                -ResultsHtml $resultsHtml `
                -BaseUrl $baseUrl `
                -PageNumber $pageNumber `
                -ApiUrl $apiUrl
        )

        Write-Verbose ("Page {0}/{1}: {2} manga URLs found" -f $pageNumber, $pagesToProcess, $pageItems.Count)

        foreach ($item in $pageItems) {
            if ([string]::IsNullOrWhiteSpace($item.MangaUrl)) {
                continue
            }

            if (-not $mangaByUrl.Contains($item.MangaUrl)) {
                $mangaByUrl[$item.MangaUrl] = $item
            }
        }

        if ($PageDelayMs -gt 0 -and $pageNumber -lt $pagesToProcess) {
            Start-Sleep -Milliseconds $PageDelayMs
        }
    }

    $discoveredManga = @($mangaByUrl.Values)

    if ($MaxManga -gt 0 -and $MaxManga -lt $discoveredManga.Count) {
        $discoveredManga = @($discoveredManga | Select-Object -First $MaxManga)
    }

    Write-Verbose "Unique manga URLs : $($discoveredManga.Count)"

    $catalogItems = [System.Collections.Generic.List[object]]::new()

    for ($i = 0; $i -lt $discoveredManga.Count; $i++) {
        $item = $discoveredManga[$i]
        $number = $i + 1

        Write-Verbose ("Manga {0}/{1}: {2}" -f $number, $discoveredManga.Count, $item.MangaUrl)

        $detailFile = Join-Path $detailFolder "$($item.Slug).html"

        if (-not $KeepMangaInfoPages) {
            $detailFile = Join-Path ([System.IO.Path]::GetTempPath()) ("mgeko-catalog-{0}-{1}.html" -f $item.Slug, [guid]::NewGuid().ToString('N'))
        }

        try {
            $detailHtml = Invoke-MSMgekoGetHtml -Url $item.MangaUrl

            Set-Content `
                -LiteralPath $detailFile `
                -Value $detailHtml `
                -Encoding UTF8

            $info = Get-MSMangaInfoFromHtml `
                -HtmlFilePath $detailFile `
                -MangaUrl $item.MangaUrl `
                -Slug $item.Slug `
                -DownloadDate $runDate.DateTime.Date

            $catalogItems.Add(
                (ConvertTo-MSMangaCatalogItemFromInfo `
                    -Info $info `
                    -DiscoveryItem $item `
                    -RunDate $runDate)
            )
        }
        catch {
            Write-Warning "Failed to parse manga page: $($item.MangaUrl). Error: $($_.Exception.Message)"

            $catalogItems.Add(
                (ConvertTo-MSMangaCatalogItemFromError `
                    -DiscoveryItem $item `
                    -ErrorMessage $_.Exception.Message `
                    -RunDate $runDate)
            )
        }
        finally {
            if (-not $KeepMangaInfoPages) {
                Remove-Item -LiteralPath $detailFile -Force -ErrorAction SilentlyContinue
            }
        }

        if ($MangaDelayMs -gt 0 -and $number -lt $discoveredManga.Count) {
            Start-Sleep -Milliseconds $MangaDelayMs
        }
    }

    $catalog = [ordered]@{
        schemaVersion = 1
        source = [ordered]@{
            site             = 'Mgeko'
            startUrl         = $StartUrl
            firstApiUrl      = $firstApiUrl
            generatedAt      = $runIso
            totalResults     = $totalResults
            totalPages       = $totalPages
            pagesProcessed   = $pagesToProcess
            uniqueMangaFound = $discoveredManga.Count
        }
        files = [ordered]@{
            outputFile          = $outputFilePath
            rawBrowsePagesFolder = if ($KeepRawBrowsePages) { $rawFolder } else { $null }
            detailPagesFolder    = if ($KeepMangaInfoPages) { $detailFolder } else { $null }
        }
        items = @($catalogItems)
    }

    $json = $catalog | ConvertTo-Json -Depth 50

    Set-Content `
        -LiteralPath $outputFilePath `
        -Value $json `
        -Encoding UTF8

    return [pscustomobject]@{
        Status           = 'Saved'
        OutputFilePath   = $outputFilePath
        StartUrl         = $StartUrl
        FirstApiUrl      = $firstApiUrl
        TotalResults     = $totalResults
        TotalPages       = $totalPages
        PagesProcessed   = $pagesToProcess
        UniqueMangaFound = $discoveredManga.Count
        ItemsSaved       = $catalogItems.Count
        GeneratedAt      = $runIso
    }
}

