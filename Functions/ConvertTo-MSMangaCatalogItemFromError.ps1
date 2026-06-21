function ConvertTo-MSMangaCatalogItemFromError {
        param(
            [Parameter(Mandatory)]
            [object]$DiscoveryItem,

            [Parameter(Mandatory)]
            [string]$ErrorMessage,

            [Parameter(Mandatory)]
            [datetimeoffset]$RunDate
        )

        return [ordered]@{
            schemaVersion = 1
            source = [ordered]@{
                site                = 'Mgeko'
                mangaUrl            = $DiscoveryItem.MangaUrl
                slug                = $DiscoveryItem.Slug
                metadataHtmlFile    = $null
                allChaptersHtmlFile = $null
            }
            catalog = [ordered]@{
                discoveredAt     = $RunDate.ToString('o')
                sourcePageNumber = $DiscoveryItem.PageNumber
                sourceApiUrl     = $DiscoveryItem.ApiUrl
                detailParsed     = $false
                parseError       = $ErrorMessage
            }
            download = [ordered]@{
                firstDownloadedAt     = $null
                lastDownloadedAt      = $null
                lastMetadataChangedAt = $null
                downloadCount         = 0
                metadataChanged       = $null
            }
            manga = [ordered]@{
                name       = $DiscoveryItem.Title
                author     = $null
                status     = $null
                about      = $null
                categories = @()
            }
            rating = [ordered]@{
                value   = $null
                count   = $null
                rawText = $null
            }
            chapters = [ordered]@{
                count         = $null
                rawText       = $null
                localCbzCount = 0
            }
            lastUpdate = [ordered]@{
                rawText        = $null
                estimatedDate  = $null
                calculatedFrom = $RunDate.DateTime.Date.ToString('yyyy-MM-dd')
                ageYears       = $null
                ageMonths      = $null
                ageWeeks       = $null
                ageDays        = $null
                totalAgeMonths = $null
                isApproximate  = $null
            }
            images = [ordered]@{
                coverImageUrl   = $null
                sourceCoverFile = $null
                folderCoverFile = $null
            }
        }
    }

