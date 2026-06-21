@{
    RootModule        = 'Mgeko-dl.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'fb00c3ef-c6a4-48db-84ca-354f047cd327'
    Author            = 'Mgeko-dl contributors'
    Description       = 'Tools to discover Mgeko manga catalogs, download chapters, create CBZ files, and manage manga metadata.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Convert-MSMangaFoldersToCbz'
        'Convert-MSRelativeLastUpdateToDate'
        'Find-MSMangaCatalog'
        'Get-MSHtmlAttributeValue'
        'Get-MSHtmlHref'
        'Get-MSHtmlImageSrc'
        'Get-MSMangaCatalogCategory'
        'Get-MSMangaInfoFromHtml'
        'Get-MSMangaMetadataFromHtml'
        'Get-MSUrlLastPart'
        'Invoke-MSMangaCatalogDiscovery'
        'Invoke-MSMangaDownloadBrowser'
        'Invoke-MSMangaDownloadToCbz'
        'New-MSMangaFolderCoverFromHtml'
        'Save-MSMangaInfoJson'
        'Save-MSUrlToFile'
        'Save-MSUrlToFileWithUrlSubFolder'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData       = @{
        PSData = @{
            LicenseUri = 'https://opensource.org/license/mit'
        }
    }
}
