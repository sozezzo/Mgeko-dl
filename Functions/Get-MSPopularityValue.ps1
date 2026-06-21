function Get-MSPopularityValue {
        param(
            [Parameter(Mandatory)]
            [object]$Item
        )

        $candidatePaths = @(
            'stats.viewsNumber',
            'stats.viewCount',
            'stats.views',
            'stats.bookmarked',
            'stats.bookmarkedCount',
            'rating.count',
            'chapters.count'
        )

        foreach ($path in $candidatePaths) {
            $value = Get-MSValue -Object $Item -Path $path
            $number = ConvertTo-MSDouble -Value $value

            if ($null -ne $number) {
                return $number
            }
        }

        return 0.0
    }

