function Get-MSSortName {
        param(
            [Parameter(Mandatory)]
            [object]$Row
        )

        if ($PassThru) {
            return [string](Get-MSValue -Object $Row -Path 'manga.name')
        }

        return [string]$Row.Name
    }

