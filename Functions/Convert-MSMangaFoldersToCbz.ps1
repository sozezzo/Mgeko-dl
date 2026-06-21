function Convert-MSMangaFoldersToCbz {
<#
.SYNOPSIS
    Converts manga chapter folders into CBZ files.

.DESCRIPTION
    Scans a root folder where each direct subfolder is one chapter.

    It fixes natural sorting problems such as:

        chapter-1
        chapter-2
        chapter-10

        chapter-1.1
        chapter-1.2
        chapter-10-1
        chapter-10-2

        0.jpg
        1.jpg
        2.jpg
        10.jpg

        01.jpg
        02.jpg
        010.jpg
        011.jpg

    Original files are not modified.

.EXAMPLE
    Convert-MSMangaFoldersToCbz -RootPath "C:\temp\Manga\MyManga" -Overwrite
#>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ -PathType Container })]
        [string]$RootPath,

        [string]$OutputPath,

        [switch]$Overwrite,

        [switch]$IncludeSubFolders,

        [ValidateRange(3, 8)]
        [int]$PagePadding = 4,

        [ValidateRange(3, 8)]
        [int]$ChapterPadding = 4,

        [ValidateSet('Optimal', 'Fastest', 'NoCompression')]
        [string]$CompressionLevel = 'Fastest'
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem

    

    

    

    

    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $OutputPath = Join-Path $RootPath '_CBZ'
    }

    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null

    $resolvedOutputPath = (Resolve-Path $OutputPath).Path.TrimEnd('\')

    $imageExtensions = @(
        '.jpg',
        '.jpeg',
        '.png',
        '.webp'
    )

    $zipCompressionLevel = [System.Enum]::Parse(
        [System.IO.Compression.CompressionLevel],
        $CompressionLevel
    )

    $chapterFolders = @(
        Get-ChildItem -Path $RootPath -Directory |
        Where-Object {
            $_.FullName.TrimEnd('\') -ne $resolvedOutputPath -and
            $_.Name -ne '_CBZ'
        } |
        Sort-Object @{ Expression = { Get-MSNaturalSortKey $_.Name } }
    )

    $total = $chapterFolders.Count
    $current = 0

    $results = foreach ($chapter in $chapterFolders) {
        $current++

        Write-Progress `
            -Activity "Creating CBZ files" `
            -Status "$current of $total - $($chapter.Name)" `
            -PercentComplete (($current / [Math]::Max($total, 1)) * 100)

        if ($IncludeSubFolders) {
            $images = @(
                Get-ChildItem -Path $chapter.FullName -File -Recurse |
                Where-Object {
                    $imageExtensions -contains $_.Extension.ToLowerInvariant()
                } |
                Sort-Object @{ Expression = { Get-MSNaturalSortKey $_.FullName } }
            )
        }
        else {
            $images = @(
                Get-ChildItem -Path $chapter.FullName -File |
                Where-Object {
                    $imageExtensions -contains $_.Extension.ToLowerInvariant()
                } |
                Sort-Object @{ Expression = { Get-MSNaturalSortKey $_.Name } }
            )
        }

        if ($images.Count -eq 0) {
            [pscustomobject]@{
                Chapter = $chapter.Name
                Status  = 'Skipped - no image files'
                File    = $null
                Pages   = 0
            }

            continue
        }

        $safeChapterName = ConvertTo-MSSafeFileName (
            ConvertTo-MSPaddedChapterName `
                -Name $chapter.Name `
                -Padding $ChapterPadding
        )

        $cbzPath = Join-Path $OutputPath "$safeChapterName.cbz"

        if ((Test-Path $cbzPath) -and (-not $Overwrite)) {
            [pscustomobject]@{
                Chapter = $chapter.Name
                Status  = 'Skipped - CBZ already exists'
                File    = $cbzPath
                Pages   = $images.Count
            }

            continue
        }

        if (Test-Path $cbzPath) {
            Remove-Item $cbzPath -Force
        }

        $tempFolder = Join-Path ([System.IO.Path]::GetTempPath()) ("cbz_" + [guid]::NewGuid().ToString('N'))

        try {
            New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null

            $firstImageNumber = Get-MSFirstImageNumber -File $images[0]

            if ($firstImageNumber -eq 0) {
                $pageNumber = 0
            }
            else {
                $pageNumber = 1
            }

            foreach ($image in $images) {
                $extension = $image.Extension.ToLowerInvariant()

                $newName = ('{0:D' + $PagePadding + '}{1}') -f $pageNumber, $extension
                $destination = Join-Path $tempFolder $newName

                Copy-Item -Path $image.FullName -Destination $destination -Force

                $pageNumber++
            }

            [System.IO.Compression.ZipFile]::CreateFromDirectory(
                $tempFolder,
                $cbzPath,
                $zipCompressionLevel,
                $false
            )

            [pscustomobject]@{
                Chapter = $chapter.Name
                Status  = 'Created'
                File    = $cbzPath
                Pages   = $images.Count
            }
        }
        catch {
            [pscustomobject]@{
                Chapter = $chapter.Name
                Status  = "Error - $($_.Exception.Message)"
                File    = $cbzPath
                Pages   = $images.Count
            }
        }
        finally {
            if (Test-Path $tempFolder) {
                Remove-Item $tempFolder -Recurse -Force
            }
        }
    }

    Write-Progress -Activity "Creating CBZ files" -Completed

    return $results
}

