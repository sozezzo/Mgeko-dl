function Get-MSSortChapters {
        param(
            [Parameter(Mandatory)]
            [object]$Row
        )

        $value = $null

        if ($PassThru) {
            $value = Get-MSValue -Object $Row -Path 'chapters.count'
        }
        else {
            $value = $Row.Chapters
        }

        $number = ConvertTo-MSDouble -Value $value

        if ($null -eq $number) {
            return 0
        }

        return $number
    }

