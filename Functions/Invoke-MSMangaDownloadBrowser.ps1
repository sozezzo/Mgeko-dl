function Invoke-MSMangaDownloadBrowser {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$MangaBrowserUrl,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RootFolder 
        )

    $RootMangaBrowserfolder = Join-Path $RootFolder "web\_browser"
    $RootMangaBrowserFile   = Join-Path $RootFolder "web\_browser\catalogue.html"
    $RootCBZfolder   = Join-Path $RootFolder "cbz\"

    #Always download
    #Save-MSUrlToFile -Url $MangaBrowserUrl -FilePath $RootMangaBrowserFile -Force
    Invoke-MSMangaCatalogDiscovery -StartUrl $MangaBrowserUrl -RootFolder $RootFolder -

}

