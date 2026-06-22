function Invoke-MSMangaDownloadToCbz {
<#
.SYNOPSIS
    Downloads manga chapters/images, creates CBZ files, cover files, and manga-info.json.

.DESCRIPTION
    Folder layout:

        <RootFolder>
        â”œâ”€â”€ web
        â”‚   â””â”€â”€ <mangapath>
        â”‚       â”œâ”€â”€ chapter HTML files
        â”‚       â””â”€â”€ image folders
        â”‚
        â””â”€â”€ cbz
            â””â”€â”€ <mangapath>
                â”œâ”€â”€ manga-info-page.html
                â”œâ”€â”€ allchapters.html
                â”œâ”€â”€ manga-info.json
                â”œâ”€â”€ cover-source.jpg
                â”œâ”€â”€ folder-cover.jpg
                â””â”€â”€ *.cbz

    Main page:
        Used for metadata, cover, and manga-info.json.

    All-chapters page:
        Used for chapter URLs.

.PARAMETER MangaUrl
    Main manga URL.

.PARAMETER RootFolder
    Root local folder where web and cbz folders will be created.
    The resolved path must not exceed 40 characters. Use a short root such as
    C:\manga\mgeko to leave enough room for long chapter filenames.

.PARAMETER ForceDownload
    Re-downloads chapter HTML files and image files even if they already exist.
    The manga info page and all-chapters page are always refreshed.

.PARAMETER ForceCover
    Recreates cover files even if they already exist.

.PARAMETER SkipCover
    Does not create cover files.

.PARAMETER SkipCbz
    Downloads files but does not create CBZ files.

.PARAMETER OverwriteCbz
    Recreates CBZ files if they already exist.

.PARAMETER ChapterUrlLikePattern
    Optional custom pattern to filter chapter URLs.

.PARAMETER ImageUrlLikePattern
    Optional custom pattern to filter image URLs.

.PARAMETER SourceCoverFileName
    Filename for original downloaded cover.

.PARAMETER OutputCoverFileName
    Filename for generated folder cover.

.EXAMPLE
    Invoke-MSMangaDownloadToCbz `
        -MangaUrl "https://www.mgeko.cc/manga/revival-man/" `
        -RootFolder "C:\temp\mgeko-manga\mgeko-download" `
        -Verbose
#>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$MangaUrl,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RootFolder,

        [switch]$ForceDownload,

        [switch]$ForceCover,

        [switch]$SkipCover,

        [switch]$SkipCbz,

        [switch]$OverwriteCbz,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$ChapterUrlLikePattern = $null,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$ImageUrlLikePattern = $null,

        [ValidateNotNullOrEmpty()]
        [string]$SourceCoverFileName = 'cover-source.jpg',

        [ValidateNotNullOrEmpty()]
        [string]$OutputCoverFileName = 'folder-cover.jpg'
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $maximumRootPathLength = 40
    $maximumMangaFolderNameLength = 50

    $requiredFunctions = @(
        'Get-MSUrlLastPart',
        'Save-MSUrlToFile',
        'Get-MSHtmlHref',
        'Get-MSHtmlImageSrc',
        'Save-MSMangaInfoJson',
        'ConvertTo-MSSafeFileName',
        'ConvertTo-MSShortPathSegment'
    )

    if (-not $SkipCbz) {
        $requiredFunctions += 'Convert-MSMangaFoldersToCbz'
    }

    if (-not $SkipCover) {
        $requiredFunctions += 'New-MSMangaFolderCoverFromHtml'
    }

    foreach ($functionName in $requiredFunctions) {
        if (-not (Get-Command $functionName -ErrorAction SilentlyContinue)) {
            throw "Required function not found: $functionName"
        }
    }

    try {
        $resolvedRootFolder = [System.IO.Path]::GetFullPath($RootFolder)
        $resolvedPathRoot = [System.IO.Path]::GetPathRoot($resolvedRootFolder)

        if ($resolvedRootFolder -ne $resolvedPathRoot) {
            $resolvedRootFolder = $resolvedRootFolder.TrimEnd('\', '/')
        }
    }
    catch {
        throw "RootFolder is not a valid filesystem path: '$RootFolder'. Use a short root, for example 'C:\manga\mgeko'. $($_.Exception.Message)"
    }

    if ($resolvedRootFolder.Length -gt $maximumRootPathLength) {
        throw "RootFolder is too long ($($resolvedRootFolder.Length) characters; maximum $maximumRootPathLength): '$resolvedRootFolder'. Use a shorter root, for example 'C:\manga\mgeko'."
    }

    if (-not (Test-Path -LiteralPath $resolvedRootFolder -PathType Container)) {
        New-Item -Path $resolvedRootFolder -ItemType Directory -Force | Out-Null
    }

    $MangaUrl = $MangaUrl.Trim()
    $mangaUrlClean = $MangaUrl.TrimEnd('/')

    $mangapath = Get-MSUrlLastPart -Url $mangaUrlClean

    if ([string]::IsNullOrWhiteSpace($mangapath)) {
        throw "Unable to detect manga path from URL: $MangaUrl"
    }

    $mangaBaseUrl = (
        $mangaUrlClean -replace ([regex]::Escape("/$mangapath") + '$'), ''
    ).TrimEnd('/')

    # Keep $mangapath unchanged because it is also used for URLs, matching, and metadata.
    # Only the filesystem folder component is made safe and shortened.
    $safeMangaFolderName = ConvertTo-MSSafeFileName -Name $mangapath
    $mangaFolderName = ConvertTo-MSShortPathSegment `
        -Name $safeMangaFolderName `
        -MaximumLength $maximumMangaFolderNameLength

    $RootMangafolder = Join-Path $resolvedRootFolder "web\$mangaFolderName"
    $RootCBZfolder   = Join-Path $resolvedRootFolder "cbz\$mangaFolderName"

    $MangaInfoUrl  = "$mangaBaseUrl/$mangapath/"
    $MangaInfoFile = Join-Path $RootCBZfolder "manga-info-page.html"

    $AllchaptersUrl  = "$mangaBaseUrl/$mangapath/all-chapters/"
    $AllChaptersFile = Join-Path $RootCBZfolder "allchapters.html"

    if ([string]::IsNullOrWhiteSpace($ChapterUrlLikePattern)) {
        $ChapterUrlLikePattern = "*$mangapath-chapter*"
    }

    if ([string]::IsNullOrWhiteSpace($ImageUrlLikePattern)) {
        $ImageUrlLikePattern = "*/chapter*"
    }

    Write-Verbose "MangaUrl        : $MangaUrl"
    Write-Verbose "MangaPath       : $mangapath"
    Write-Verbose "MangaFolderName : $mangaFolderName"
    Write-Verbose "MangaBaseUrl    : $mangaBaseUrl"
    Write-Verbose "MangaInfoUrl    : $MangaInfoUrl"
    Write-Verbose "AllChaptersUrl  : $AllchaptersUrl"
    Write-Verbose "RootMangaFolder : $RootMangafolder"
    Write-Verbose "RootCBZFolder   : $RootCBZfolder"
    Write-Verbose "Chapter Pattern : $ChapterUrlLikePattern"
    Write-Verbose "Image Pattern   : $ImageUrlLikePattern"

    if (-not (Test-Path -LiteralPath $RootMangafolder -PathType Container)) {
        New-Item -Path $RootMangafolder -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path -LiteralPath $RootCBZfolder -PathType Container)) {
        New-Item -Path $RootCBZfolder -ItemType Directory -Force | Out-Null
    }

    # Always refresh the main manga page.
    # This file is portable with the CBZ folder.
    Save-MSUrlToFile `
        -Url $MangaInfoUrl `
        -FilePath $MangaInfoFile `
        -Force | Out-Null

    # Always refresh all-chapters page.
    # This file is portable with the CBZ folder.
    Save-MSUrlToFile `
        -Url $AllchaptersUrl `
        -FilePath $AllChaptersFile `
        -Force | Out-Null

    $coverResult = $null

    if (-not $SkipCover) {
        $coverHtmlCandidates = @(
            [pscustomobject]@{
                FilePath = $MangaInfoFile
                BaseUrl  = $MangaInfoUrl
                Name     = 'MangaInfoPage'
            },
            [pscustomobject]@{
                FilePath = $AllChaptersFile
                BaseUrl  = $AllchaptersUrl
                Name     = 'AllChaptersPage'
            }
        )

        $coverCreated = $false
        $lastCoverError = $null

        foreach ($coverHtmlCandidate in $coverHtmlCandidates) {
            try {
                Write-Verbose "Trying cover metadata from: $($coverHtmlCandidate.Name)"

                $coverResult = New-MSMangaFolderCoverFromHtml `
                    -HtmlFilePath $coverHtmlCandidate.FilePath `
                    -BaseUrl $coverHtmlCandidate.BaseUrl `
                    -OutputFolder $RootCBZfolder `
                    -SourceCoverFileName $SourceCoverFileName `
                    -OutputCoverFileName $OutputCoverFileName `
                    -Force:($ForceCover -or $ForceDownload)

                $coverCreated = $true
                Write-Verbose "Cover result: $($coverResult.Status)"
                Write-Verbose "Cover file  : $($coverResult.OutputCoverPath)"
                break
            }
            catch {
                $lastCoverError = $_.Exception.Message
                Write-Verbose "Cover failed from $($coverHtmlCandidate.Name): $lastCoverError"
            }
        }

        if (-not $coverCreated) {
            Write-Warning "Cover creation failed: $lastCoverError"

            $coverResult = [pscustomobject]@{
                Status          = 'Error'
                ErrorMessage    = $lastCoverError
                HtmlFilePath    = $null
                OutputFolder    = $RootCBZfolder
                SourceCoverPath = $null
                OutputCoverPath = $null
            }
        }
    }
    else {
        $coverResult = [pscustomobject]@{
            Status          = 'Skipped'
            ErrorMessage    = $null
            HtmlFilePath    = $null
            OutputFolder    = $RootCBZfolder
            SourceCoverPath = $null
            OutputCoverPath = $null
        }
    }

    $hrefPages = @(
        Get-MSHtmlHref `
            -FilePath $AllChaptersFile `
            -Unique `
            -BaseUrl "$mangaBaseUrl/$mangapath/"
    )

    $hrefPages = @(
        $hrefPages |
            Where-Object { $_ -like $ChapterUrlLikePattern }
    )

    Write-host "Chapter links found: $($hrefPages.Count)"

    $report = [System.Collections.Generic.List[object]]::new()

    foreach ($mangaChapterUrl in $hrefPages) {
        #Write-Verbose ""
        Write-host "Chapter URL: $mangaChapterUrl"

        $chapterName = Get-MSUrlLastPart -Url $mangaChapterUrl
        $mangaChapterFileName = Join-Path $RootMangafolder "$chapterName.html"

        if ($mangaChapterFileName.Length -ge 260) {
            throw "The generated chapter path is too long ($($mangaChapterFileName.Length) characters; maximum 259): '$mangaChapterFileName'. Stop and use a shorter RootFolder, for example 'C:\manga\mgeko'."
        }

        Write-Verbose "Chapter name: $chapterName"
        Write-Verbose "Chapter file: $mangaChapterFileName"

        $chapterStatus = $null

        if ((-not (Test-Path -LiteralPath $mangaChapterFileName -PathType Leaf)) -or $ForceDownload) {
            Save-MSUrlToFile `
                -Url $mangaChapterUrl `
                -FilePath $mangaChapterFileName `
                -Force:$ForceDownload | Out-Null

            $chapterStatus = 'Downloaded'
        }
        else {
            Write-Verbose "Skipped existing chapter file: $mangaChapterFileName"
            $chapterStatus = 'SkippedExisting'
        }

        $report.Add([pscustomobject]@{
            Type     = 'ChapterHtml'
            Status   = $chapterStatus
            Chapter  = $chapterName
            Url      = $mangaChapterUrl
            FilePath = $mangaChapterFileName
        })

        $mangaChapterImagesSrc = @(
            Get-MSHtmlImageSrc `
                -FilePath $mangaChapterFileName `
                -BaseUrl $mangaChapterUrl
        )

        $mangaChapterImagesSrc = @(
            $mangaChapterImagesSrc |
                Where-Object {
                    $_ -like $ImageUrlLikePattern -and
                    $_ -match '\.(jpg|jpeg|png|webp)(\?|#|$)'
                }
        )

        Write-Verbose "Images found: $($mangaChapterImagesSrc.Count)"

        foreach ($ImageSrc in $mangaChapterImagesSrc) {
            try {
                $imageUri = [System.Uri]::new($ImageSrc)
            }
            catch {
                Write-Warning "Invalid image URL: $ImageSrc"

                $report.Add([pscustomobject]@{
                    Type     = 'Image'
                    Status   = 'InvalidUrl'
                    Chapter  = $chapterName
                    Url      = $ImageSrc
                    FilePath = $null
                })

                continue
            }

            $imageSegments = @(
                $imageUri.AbsolutePath -split '/' |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
            )

            if ($imageSegments.Count -lt 2) {
                Write-Warning "Cannot parse image URL path: $ImageSrc"

                $report.Add([pscustomobject]@{
                    Type     = 'Image'
                    Status   = 'CannotParsePath'
                    Chapter  = $chapterName
                    Url      = $ImageSrc
                    FilePath = $null
                })

                continue
            }

            $ImageSrcFileName = [System.Net.WebUtility]::UrlDecode($imageSegments[-1])
            $ImageSrcFolder   = [System.Net.WebUtility]::UrlDecode($imageSegments[-2])

            $ImageSrcFileName = ConvertTo-MSSafeFileName -Name $ImageSrcFileName
            $ImageSrcFolder   = ConvertTo-MSSafeFileName -Name $ImageSrcFolder

            $ImageSrcFolderFullName = Join-Path $RootMangafolder $ImageSrcFolder
            $ImageSrcFileFullName   = Join-Path $ImageSrcFolderFullName $ImageSrcFileName

            if ($ImageSrcFileFullName.Length -ge 260) {
                throw "The generated image path is too long ($($ImageSrcFileFullName.Length) characters; maximum 259): '$ImageSrcFileFullName'. Stop and use a shorter RootFolder, for example 'C:\manga\mgeko'."
            }

            Write-host "Image URL : $ImageSrc"
            Write-Verbose "Folder    : $ImageSrcFolder"
            Write-Verbose "File      : $ImageSrcFileName"
            Write-Verbose "Save as   : $ImageSrcFileFullName"

            $imageStatus = $null

            if ((-not (Test-Path -LiteralPath $ImageSrcFileFullName -PathType Leaf)) -or $ForceDownload) {
                Save-MSUrlToFile `
                    -Url $ImageSrc `
                    -FilePath $ImageSrcFileFullName `
                    -Force:$ForceDownload | Out-Null

                $imageStatus = 'Downloaded'
            }
            else {
                Write-Verbose "Skipped existing image: $ImageSrcFileFullName"
                $imageStatus = 'SkippedExisting'
            }

            $report.Add([pscustomobject]@{
                Type     = 'Image'
                Status   = $imageStatus
                Chapter  = $chapterName
                Url      = $ImageSrc
                FilePath = $ImageSrcFileFullName
            })
        }
    }

    $cbzResult = $null

    if (-not $SkipCbz) {
        $cbzResult = @(
            Convert-MSMangaFoldersToCbz `
                -RootPath $RootMangafolder `
                -OutputPath $RootCBZfolder `
                -Overwrite:$OverwriteCbz
        )
    }

    $localCbzCount = @(
        Get-ChildItem `
            -LiteralPath $RootCBZfolder `
            -Filter '*.cbz' `
            -File `
            -ErrorAction SilentlyContinue
    ).Count

    $mangaInfoJsonResult = Save-MSMangaInfoJson `
        -HtmlFilePath $MangaInfoFile `
        -OutputFolder $RootCBZfolder `
        -MangaUrl $MangaInfoUrl `
        -Slug $mangapath `
        -LocalCbzCount $localCbzCount `
        -SourceCoverFileName $SourceCoverFileName `
        -FolderCoverFileName $OutputCoverFileName

    $chapterDownloadedCount = @(
        $report |
            Where-Object { $_.Type -eq 'ChapterHtml' -and $_.Status -eq 'Downloaded' }
    ).Count

    $chapterSkippedCount = @(
        $report |
            Where-Object { $_.Type -eq 'ChapterHtml' -and $_.Status -eq 'SkippedExisting' }
    ).Count

    $imageDownloadedCount = @(
        $report |
            Where-Object { $_.Type -eq 'Image' -and $_.Status -eq 'Downloaded' }
    ).Count

    $imageSkippedCount = @(
        $report |
            Where-Object { $_.Type -eq 'Image' -and $_.Status -eq 'SkippedExisting' }
    ).Count

    $imageErrorCount = @(
        $report |
            Where-Object {
                $_.Type -eq 'Image' -and
                $_.Status -notin @('Downloaded', 'SkippedExisting')
            }
    ).Count

    return [pscustomobject]@{
        MangaUrl              = $MangaUrl
        MangaPath             = $mangapath
        MangaFolderName       = $mangaFolderName
        MangaBaseUrl          = $mangaBaseUrl
        MangaInfoUrl          = $MangaInfoUrl
        MangaInfoFile         = $MangaInfoFile
        RootMangaFolder       = $RootMangafolder
        RootCBZFolder         = $RootCBZfolder
        AllChaptersUrl        = $AllchaptersUrl
        AllChaptersFile       = $AllChaptersFile
        ChapterLinksFound     = $hrefPages.Count
        ChapterHtmlDownloaded = $chapterDownloadedCount
        ChapterHtmlSkipped    = $chapterSkippedCount
        ImagesDownloaded      = $imageDownloadedCount
        ImagesSkipped         = $imageSkippedCount
        ImageErrors           = $imageErrorCount
        LocalCbzCount         = $localCbzCount
        CoverResult           = $coverResult
        MangaInfoJsonResult   = $mangaInfoJsonResult
        Report                = @($report)
        CbzResult             = @($cbzResult)
    }
}

