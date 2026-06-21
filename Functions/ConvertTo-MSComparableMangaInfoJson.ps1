function ConvertTo-MSComparableMangaInfoJson {
        param(
            [Parameter(Mandatory)]
            [object]$Info
        )

        $comparable = [ordered]@{
            source = [ordered]@{
                site     = $Info.Source.Site
                mangaUrl = $Info.Source.MangaUrl
                slug     = $Info.Source.Slug
            }
            manga = [ordered]@{
                name       = $Info.Manga.Name
                author     = $Info.Manga.Author
                status     = $Info.Manga.Status
                about      = $Info.Manga.About
                categories = @($Info.Manga.Categories)
            }
            rating = [ordered]@{
                value = $Info.Rating.Value
                count = $Info.Rating.Count
            }
            chapters = [ordered]@{
                count = $Info.Chapters.Count
            }
            lastUpdate = [ordered]@{
                rawText       = $Info.LastUpdate.RawText
                estimatedDate = $Info.LastUpdate.EstimatedDate
            }
            images = [ordered]@{
                coverImageUrl = $Info.Images.CoverImageUrl
            }
        }

        return ($comparable | ConvertTo-Json -Depth 20 -Compress)
    }

