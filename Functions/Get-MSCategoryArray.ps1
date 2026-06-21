function Get-MSCategoryArray {
        param(
            [AllowNull()]
            [object]$Item
        )

        $categories = @(Get-MSValue -Object $Item -Path 'manga.categories')

        return @(
            $categories |
                Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } |
                ForEach-Object { ([string]$_).Trim() }
        )
    }

