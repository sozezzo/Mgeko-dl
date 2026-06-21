function Get-MSMangaMetadataFromHtml {
<#
.SYNOPSIS
    Extracts manga metadata from an HTML file.

.DESCRIPTION
    Extracts metadata from meta/link tags.

    Returns:
        Title
        Description
        Keywords
        CoverImageUrl
        MangaUrl
        CanonicalUrl
        SiteName
        RawMeta
#>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [AllowNull()]
        [AllowEmptyString()]
        [string]$BaseUrl = $null
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    $FilePath = $FilePath.Trim(" `t`r`n")
    $fullFilePath = [System.IO.Path]::GetFullPath($FilePath)

    if (-not (Test-Path -LiteralPath $fullFilePath -PathType Leaf)) {
        throw "HTML file not found: $fullFilePath"
    }

    $baseUri = $null

    if (-not [string]::IsNullOrWhiteSpace($BaseUrl)) {
        $baseUri = [System.Uri]::new($BaseUrl)
    }

    

    $html = Get-Content -LiteralPath $fullFilePath -Raw

    $metaMap = @{}

    $metaTags = @([regex]::Matches($html, '(?is)<meta\b[^>]*>'))

    foreach ($metaTag in $metaTags) {
        $tag = $metaTag.Value

        $name     = Get-MSHtmlAttributeValue -Tag $tag -AttributeName 'name'
        $property = Get-MSHtmlAttributeValue -Tag $tag -AttributeName 'property'
        $itemprop = Get-MSHtmlAttributeValue -Tag $tag -AttributeName 'itemprop'
        $content  = Get-MSHtmlAttributeValue -Tag $tag -AttributeName 'content'

        if (-not [string]::IsNullOrWhiteSpace($name) -and -not [string]::IsNullOrWhiteSpace($content)) {
            $metaMap["name:$name"] = $content
        }

        if (-not [string]::IsNullOrWhiteSpace($property) -and -not [string]::IsNullOrWhiteSpace($content)) {
            $metaMap["property:$property"] = $content
        }

        if (-not [string]::IsNullOrWhiteSpace($itemprop) -and -not [string]::IsNullOrWhiteSpace($content)) {
            $metaMap["itemprop:$itemprop"] = $content
        }
    }

    $canonicalUrl = $null
    $imageSrcLink = $null

    $linkTags = @([regex]::Matches($html, '(?is)<link\b[^>]*>'))

    foreach ($linkTag in $linkTags) {
        $tag = $linkTag.Value

        $rel  = Get-MSHtmlAttributeValue -Tag $tag -AttributeName 'rel'
        $href = Get-MSHtmlAttributeValue -Tag $tag -AttributeName 'href'

        if ([string]::IsNullOrWhiteSpace($rel) -or [string]::IsNullOrWhiteSpace($href)) {
            continue
        }

        if ($rel -match '(^|\s)canonical(\s|$)') {
            $canonicalUrl = ConvertTo-MSAbsoluteMetadataUrl -Value $href
        }

        if ($rel -match '(^|\s)image_src(\s|$)') {
            $imageSrcLink = ConvertTo-MSAbsoluteMetadataUrl -Value $href
        }
    }

    $title = $null

    foreach ($candidate in @(
        $metaMap['name:title'],
        $metaMap['property:og:title'],
        $metaMap['name:twitter:title']
    )) {
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $title = $candidate.Trim()
            break
        }
    }

    if ([string]::IsNullOrWhiteSpace($title)) {
        $titleTag = [regex]::Match($html, '(?is)<title\b[^>]*>(.*?)</title>')

        if ($titleTag.Success) {
            $title = [System.Net.WebUtility]::HtmlDecode($titleTag.Groups[1].Value.Trim())
        }
    }

    $description = $null

    foreach ($candidate in @(
        $metaMap['name:description'],
        $metaMap['property:og:description'],
        $metaMap['name:twitter:description']
    )) {
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $description = $candidate.Trim()
            break
        }
    }

    $keywords = $metaMap['name:keywords']

    $coverImageUrl = $null

    foreach ($candidate in @(
        $metaMap['property:og:image'],
        $metaMap['property:og:image:secure_url'],
        $metaMap['name:image'],
        $metaMap['itemprop:image'],
        $metaMap['name:twitter:image'],
        $imageSrcLink
    )) {
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $coverImageUrl = ConvertTo-MSAbsoluteMetadataUrl -Value $candidate
            break
        }
    }

    $mangaUrl = $null

    foreach ($candidate in @(
        $metaMap['property:og:url'],
        $metaMap['name:twitter:url'],
        $canonicalUrl
    )) {
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $mangaUrl = ConvertTo-MSAbsoluteMetadataUrl -Value $candidate
            break
        }
    }

    $siteName = $null

    foreach ($candidate in @(
        $metaMap['property:og:site_name'],
        $metaMap['name:twitter:site']
    )) {
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $siteName = $candidate.Trim()
            break
        }
    }

    return [pscustomobject]@{
        Title         = $title
        Description   = $description
        Keywords      = $keywords
        CoverImageUrl = $coverImageUrl
        MangaUrl      = $mangaUrl
        CanonicalUrl  = $canonicalUrl
        SiteName      = $siteName
        RawMeta       = $metaMap
    }
}

