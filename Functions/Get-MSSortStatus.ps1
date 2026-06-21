function Get-MSSortStatus {
        param(
            [Parameter(Mandatory)]
            [object]$Row
        )

        if ($PassThru) {
            return [string](Get-MSValue -Object $Row -Path 'manga.status')
        }

        return [string]$Row.Status
    }

