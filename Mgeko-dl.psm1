$functionsPath = Join-Path $PSScriptRoot 'Functions'
Get-ChildItem -LiteralPath $functionsPath -Filter '*.ps1' -File |
    Sort-Object -Property Name |
    ForEach-Object { . $_.FullName }

Export-ModuleMember -Function @(
    'Convert-MSMangaFoldersToCbz',
    'Save-MSUrlToFile',
    'Get-MSHtmlHref',
    'Get-MSUrlLastPart',
    'Get-MSHtmlImageSrc',
    'Save-MSUrlToFileWithUrlSubFolder',
    'Get-MSHtmlAttributeValue',
    'Get-MSMangaMetadataFromHtml',
    'New-MSMangaFolderCoverFromHtml',
    'Convert-MSRelativeLastUpdateToDate',
    'Get-MSMangaInfoFromHtml',
    'Save-MSMangaInfoJson',
    'Invoke-MSMangaDownloadToCbz',
    'Invoke-MSMangaCatalogDiscovery',
    'Invoke-MSMangaDownloadBrowser',
    'Get-MSMangaCatalogCategory',
    'Find-MSMangaCatalog'
)
