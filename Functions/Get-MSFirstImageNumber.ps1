function Get-MSFirstImageNumber {
        param(
            [Parameter(Mandatory)]
            [System.IO.FileInfo]$File
        )

        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)

        if ($baseName -match '^\d+$') {
            return [int]$baseName
        }

        $match = [regex]::Match($baseName, '\d+')

        if ($match.Success) {
            return [int]$match.Value
        }

        return $null
    }

