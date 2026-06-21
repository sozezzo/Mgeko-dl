function Get-MSMgekoMangaUrlFromResultsHtml {
        param(
            [Parameter(Mandatory)]
            [string]$ResultsHtml,

            [Parameter(Mandatory)]
            [string]$BaseUrl,

            [Parameter(Mandatory)]
            [int]$PageNumber,

            [Parameter(Mandatory)]
            [string]$ApiUrl
        )

        $items = [System.Collections.Generic.List[object]]::new()

        if ([string]::IsNullOrWhiteSpace($ResultsHtml)) {
            return @()
        }

        $cardMatches = @(
            [regex]::Matches(
                $ResultsHtml,
                '(?is)<div\b[^>]*class\s*=\s*["''][^"'']*comic-card[^"'']*["''][^>]*>.*?(?=<div\b[^>]*class\s*=\s*["''][^"'']*comic-card[^"'']*["'']|$)'
            )
        )

        foreach ($cardMatch in $cardMatches) {
            $cardHtml = $cardMatch.Value

            # Primary source:
            # <a class="comic-card__button" href="/manga/...">
            $buttonMatch = [regex]::Match(
                $cardHtml,
                '<a\b(?=[^>]*class\s*=\s*(?:"[^"]*comic-card__button[^"]*"|''[^'']*comic-card__button[^'']*''))[^>]*href\s*=\s*(?:"([^"]+)"|''([^'']+)''|([^\s>]+))',
                'IgnoreCase, Singleline'
            )

            $href = $null

            if ($buttonMatch.Success) {
                if ($buttonMatch.Groups[1].Success) {
                    $href = $buttonMatch.Groups[1].Value
                }
                elseif ($buttonMatch.Groups[2].Success) {
                    $href = $buttonMatch.Groups[2].Value
                }
                elseif ($buttonMatch.Groups[3].Success) {
                    $href = $buttonMatch.Groups[3].Value
                }
            }

            # Fallback:
            # Any href containing /manga/ inside the card.
            if ([string]::IsNullOrWhiteSpace($href)) {
                $fallbackMatch = [regex]::Match(
                    $cardHtml,
                    '<a\b[^>]*href\s*=\s*(?:"([^"]*/manga/[^"]+)"|''([^'']*/manga/[^'']+)''|([^\s>]+/manga/[^\s>]+))',
                    'IgnoreCase, Singleline'
                )

                if ($fallbackMatch.Success) {
                    if ($fallbackMatch.Groups[1].Success) {
                        $href = $fallbackMatch.Groups[1].Value
                    }
                    elseif ($fallbackMatch.Groups[2].Success) {
                        $href = $fallbackMatch.Groups[2].Value
                    }
                    elseif ($fallbackMatch.Groups[3].Success) {
                        $href = $fallbackMatch.Groups[3].Value
                    }
                }
            }

            if ([string]::IsNullOrWhiteSpace($href)) {
                continue
            }

            $mangaUrl = Resolve-MSUrl -BaseUrl $BaseUrl -Url $href

            if ($mangaUrl -notmatch '/manga/[^/]+/?$') {
                continue
            }

            $slug = Get-MSUrlLastPart -Url $mangaUrl

            $title = $null

            $titleMatch = [regex]::Match(
                $cardHtml,
                '<[^>]*class\s*=\s*["''][^"'']*comic-card__title[^"'']*["''][^>]*>.*?<a\b[^>]*>(.*?)</a>',
                'IgnoreCase, Singleline'
            )

            if ($titleMatch.Success) {
                $title = ConvertFrom-MSHtmlText -Value $titleMatch.Groups[1].Value
            }

            $items.Add([pscustomobject]@{
                PageNumber = $PageNumber
                ApiUrl     = $ApiUrl
                MangaUrl   = $mangaUrl
                Slug       = $slug
                Title      = $title
            })
        }

        return @($items)
    }

