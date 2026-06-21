function ConvertTo-MSMangaCatalogItemFromInfo {
        param(
            [Parameter(Mandatory)]
            [object]$Info,

            [Parameter(Mandatory)]
            [object]$DiscoveryItem,

            [Parameter(Mandatory)]
            [datetimeoffset]$RunDate
        )

        return [ordered]@{
            schemaVersion = 1
            source = [ordered]@{
                site                = $Info.Source.Site
                mangaUrl            = $Info.Source.MangaUrl
                slug                = $Info.Source.Slug
                metadataHtmlFile    = $null
                allChaptersHtmlFile = $null
            }
            catalog = [ordered]@{
                discoveredAt     = $RunDate.ToString('o')
                sourcePageNumber = $DiscoveryItem.PageNumber
                sourceApiUrl     = $DiscoveryItem.ApiUrl
                detailParsed     = $true
                parseError       = $null
            }
            download = [ordered]@{
                firstDownloadedAt     = $null
                lastDownloadedAt      = $null
                lastMetadataChangedAt = $null
                downloadCount         = 0
                metadataChanged       = $null
            }
            manga = [ordered]@{
                name       = $Info.Manga.Name
                author     = $Info.Manga.Author
                status     = $Info.Manga.Status
                about      = $Info.Manga.About
                categories = @($Info.Manga.Categories)
            }
            rating = [ordered]@{
                value   = $Info.Rating.Value
                count   = $Info.Rating.Count
                rawText = $Info.Rating.RawText
            }
            chapters = [ordered]@{
                count         = $Info.Chapters.Count
                rawText       = $Info.Chapters.RawText
                localCbzCount = 0
            }
            lastUpdate = [ordered]@{
                rawText        = $Info.LastUpdate.RawText
                estimatedDate  = $Info.LastUpdate.EstimatedDate
                calculatedFrom = $Info.LastUpdate.CalculatedFrom
                ageYears       = $Info.LastUpdate.AgeYears
                ageMonths      = $Info.LastUpdate.AgeMonths
                ageWeeks       = $Info.LastUpdate.AgeWeeks
                ageDays        = $Info.LastUpdate.AgeDays
                totalAgeMonths = $Info.LastUpdate.TotalAgeMonths
                isApproximate  = $Info.LastUpdate.IsApproximate
            }
            images = [ordered]@{
                coverImageUrl   = $Info.Images.CoverImageUrl
                sourceCoverFile = $null
                folderCoverFile = $null
            }
        }
    }

