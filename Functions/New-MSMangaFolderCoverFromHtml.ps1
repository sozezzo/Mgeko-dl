function New-MSMangaFolderCoverFromHtml {
<#
.SYNOPSIS
    Creates manga cover files from HTML metadata.

.DESCRIPTION
    Reads metadata from a manga HTML page, downloads the cover image, and creates
    a composed folder cover image.

    Creates:
        cover-source.jpg
        folder-cover.jpg

    Does not create manga-info.txt.
    Metadata is now handled by Save-MSMangaInfoJson.

.PARAMETER HtmlFilePath
    Path to manga-info-page.html or another HTML file containing metadata.

.PARAMETER OutputFolder
    Folder where cover files will be saved.

.PARAMETER BaseUrl
    Optional base URL used to resolve relative metadata URLs.

.PARAMETER Force
    Re-downloads/recreates cover files even if they already exist.

.PARAMETER SourceCoverFileName
    File name for the original downloaded cover.

.PARAMETER OutputCoverFileName
    File name for the generated composed cover.

.EXAMPLE
    New-MSMangaFolderCoverFromHtml `
        -HtmlFilePath "C:\temp\manga\cbz\revival-man\manga-info-page.html" `
        -BaseUrl "https://www.mgeko.cc/manga/revival-man/" `
        -OutputFolder "C:\temp\manga\cbz\revival-man" `
        -Force
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

        [AllowNull()]
        [AllowEmptyString()]
        [string]$BaseUrl = $null,

        [switch]$Force,

        [ValidateNotNullOrEmpty()]
        [string]$SourceCoverFileName = 'cover-source.jpg',

        [ValidateNotNullOrEmpty()]
        [string]$OutputCoverFileName = 'folder-cover.jpg'
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    foreach ($requiredFunction in @(
        'Save-MSUrlToFile',
        'Get-MSMangaMetadataFromHtml'
    )) {
        if (-not (Get-Command $requiredFunction -ErrorAction SilentlyContinue)) {
            throw "Required function not found: $requiredFunction"
        }
    }

    Add-Type -AssemblyName System.Drawing

    $HtmlFilePath = $HtmlFilePath.Trim(" `t`r`n")
    $fullHtmlFilePath = [System.IO.Path]::GetFullPath($HtmlFilePath)

    if (-not (Test-Path -LiteralPath $fullHtmlFilePath -PathType Leaf)) {
        throw "HTML file not found: $fullHtmlFilePath"
    }

    if (-not (Test-Path -LiteralPath $OutputFolder -PathType Container)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }

    $OutputFolder = [System.IO.Path]::GetFullPath($OutputFolder)

    $meta = Get-MSMangaMetadataFromHtml `
        -FilePath $fullHtmlFilePath `
        -BaseUrl $BaseUrl

    if ([string]::IsNullOrWhiteSpace($meta.CoverImageUrl)) {
        throw "No cover image URL was found in the HTML metadata."
    }

    $sourceCoverPath = Join-Path $OutputFolder $SourceCoverFileName
    $outputCoverPath = Join-Path $OutputFolder $OutputCoverFileName

    if ((-not (Test-Path -LiteralPath $sourceCoverPath -PathType Leaf)) -or $Force) {
        Save-MSUrlToFile `
            -Url $meta.CoverImageUrl `
            -FilePath $sourceCoverPath `
            -Force:$Force | Out-Null
    }

    if (-not (Test-Path -LiteralPath $sourceCoverPath -PathType Leaf)) {
        throw "Cover image was not downloaded: $sourceCoverPath"
    }

    $title = [string]$meta.Title

    if ([string]::IsNullOrWhiteSpace($title)) {
        $title = 'Unknown Title'
    }

    $description = [string]$meta.Description

    if ([string]::IsNullOrWhiteSpace($description)) {
        $description = ''
    }

    $mangaUrl = [string]$meta.MangaUrl

    if ([string]::IsNullOrWhiteSpace($mangaUrl)) {
        $mangaUrl = ''
    }

    $siteName = [string]$meta.SiteName

    if ([string]::IsNullOrWhiteSpace($siteName)) {
        $siteName = ''
    }

    if ((Test-Path -LiteralPath $outputCoverPath -PathType Leaf) -and (-not $Force)) {
        return [pscustomobject]@{
            Status           = 'SkippedExisting'
            Title            = $title
            CoverImageUrl    = $meta.CoverImageUrl
            SourceCoverPath  = $sourceCoverPath
            OutputCoverPath  = $outputCoverPath
            MangaUrl         = $mangaUrl
            CanonicalUrl     = $meta.CanonicalUrl
            HtmlFilePath     = $fullHtmlFilePath
        }
    }

    [int]$canvasWidth  = 1200
    [int]$canvasHeight = 1800

    $bitmap     = $null
    $graphics   = $null
    $coverImage = $null

    $titleFont = $null
    $bodyFont  = $null
    $smallFont = $null

    $titleBrush = $null
    $bodyBrush  = $null
    $smallBrush = $null
    $bgBrush    = $null
    $panelBrush = $null
    $borderPen  = $null

    try {
        $bitmap   = [System.Drawing.Bitmap]::new($canvasWidth, $canvasHeight)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

        $graphics.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

        $bgBrush    = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 18, 18, 22))
        $panelBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(230, 30, 30, 36))
        $titleBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
        $bodyBrush  = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::Gainsboro)
        $smallBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::Silver)
        $borderPen  = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 80, 80, 90), 2)

        $titleFont = [System.Drawing.Font]::new('Segoe UI', 28, [System.Drawing.FontStyle]::Bold)
        $bodyFont  = [System.Drawing.Font]::new('Segoe UI', 16, [System.Drawing.FontStyle]::Regular)
        $smallFont = [System.Drawing.Font]::new('Segoe UI', 12, [System.Drawing.FontStyle]::Regular)

        $graphics.FillRectangle(
            $bgBrush,
            [int]0,
            [int]0,
            [int]$canvasWidth,
            [int]$canvasHeight
        )

        $coverImage = [System.Drawing.Image]::FromFile($sourceCoverPath)

        [int]$padding       = 40
        [int]$topAreaHeight = 1100
        [int]$textAreaTop   = 1160

        [int]$availableWidth  = [int]$canvasWidth - ([int]$padding * 2)
        [int]$availableHeight = [int]$topAreaHeight - [int]$padding

        [double]$scaleX = [double]$availableWidth / [double]$coverImage.Width
        [double]$scaleY = [double]$availableHeight / [double]$coverImage.Height
        [double]$scale  = [Math]::Min($scaleX, $scaleY)

        [int]$drawWidth  = [int]([double]$coverImage.Width * $scale)
        [int]$drawHeight = [int]([double]$coverImage.Height * $scale)

        [int]$drawX = [int](([int]$canvasWidth - [int]$drawWidth) / 2)
        [int]$drawY = [int](([int]$topAreaHeight - [int]$drawHeight) / 2)

        $graphics.DrawImage(
            $coverImage,
            [int]$drawX,
            [int]$drawY,
            [int]$drawWidth,
            [int]$drawHeight
        )

        $graphics.DrawRectangle(
            $borderPen,
            [int]$drawX,
            [int]$drawY,
            [int]$drawWidth,
            [int]$drawHeight
        )

        [int]$panelX      = 30
        [int]$panelY      = $textAreaTop
        [int]$panelWidth  = [int]$canvasWidth - 60
        [int]$panelHeight = [int]$canvasHeight - [int]$textAreaTop - 30

        $graphics.FillRectangle(
            $panelBrush,
            [int]$panelX,
            [int]$panelY,
            [int]$panelWidth,
            [int]$panelHeight
        )

        $titleRect = [System.Drawing.RectangleF]::new(
            [single]60,
            [single]($textAreaTop + 30),
            [single]($canvasWidth - 120),
            [single]120
        )

        $graphics.DrawString(
            [string]$title,
            $titleFont,
            $titleBrush,
            $titleRect
        )

        $descriptionText = [string]$description

        if ($descriptionText.Length -gt 650) {
            $descriptionText = $descriptionText.Substring(0, 650).Trim() + '...'
        }

        $descRect = [System.Drawing.RectangleF]::new(
            [single]60,
            [single]($textAreaTop + 150),
            [single]($canvasWidth - 120),
            [single]340
        )

        $graphics.DrawString(
            [string]$descriptionText,
            $bodyFont,
            $bodyBrush,
            $descRect
        )

        $footerLines = @()

        if (-not [string]::IsNullOrWhiteSpace($siteName)) {
            $footerLines += "Source: $siteName"
        }

        if (-not [string]::IsNullOrWhiteSpace($mangaUrl)) {
            $footerLines += "URL: $mangaUrl"
        }

        $footerText = [string]($footerLines -join [Environment]::NewLine)

        $footerRect = [System.Drawing.RectangleF]::new(
            [single]60,
            [single]($canvasHeight - 140),
            [single]($canvasWidth - 120),
            [single]90
        )

        $graphics.DrawString(
            $footerText,
            $smallFont,
            $smallBrush,
            $footerRect
        )

        $bitmap.Save(
            $outputCoverPath,
            [System.Drawing.Imaging.ImageFormat]::Jpeg
        )
    }
    finally {
        if ($coverImage) { $coverImage.Dispose() }
        if ($graphics)   { $graphics.Dispose() }
        if ($bitmap)     { $bitmap.Dispose() }

        if ($titleFont)  { $titleFont.Dispose() }
        if ($bodyFont)   { $bodyFont.Dispose() }
        if ($smallFont)  { $smallFont.Dispose() }

        if ($titleBrush) { $titleBrush.Dispose() }
        if ($bodyBrush)  { $bodyBrush.Dispose() }
        if ($smallBrush) { $smallBrush.Dispose() }
        if ($bgBrush)    { $bgBrush.Dispose() }
        if ($panelBrush) { $panelBrush.Dispose() }
        if ($borderPen)  { $borderPen.Dispose() }
    }

    return [pscustomobject]@{
        Status           = 'Created'
        Title            = $title
        CoverImageUrl    = $meta.CoverImageUrl
        SourceCoverPath  = $sourceCoverPath
        OutputCoverPath  = $outputCoverPath
        MangaUrl         = $mangaUrl
        CanonicalUrl     = $meta.CanonicalUrl
        HtmlFilePath     = $fullHtmlFilePath
    }
}

