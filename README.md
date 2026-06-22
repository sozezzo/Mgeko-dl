# Mgeko-dl

Mgeko-dl is a PowerShell module for discovering manga on Mgeko, downloading chapters and images, packaging chapters as CBZ archives, and preserving useful metadata and cover art alongside the collection.

The project began during a rainy weekend when I had nothing to do. I wanted a repeatable way to find manga, download it, and organize it into files that work well with comic-book readers. That small weekend experiment grew into this collection of reusable PowerShell commands.

## Recommended manga website

I recommend [Mgeko](https://www.mgeko.cc/), the website where I download my favorite manga. Mgeko-dl is designed around its browse pages, manga information pages, chapter pages, and current URL structure.

Websites can change their markup or endpoints without warning. If Mgeko changes, parsing or downloading commands may need to be updated. Please use the project responsibly, respect the website's terms and bandwidth, and support manga authors and official releases whenever possible.

## What the project does

Mgeko-dl can:

- Discover the Mgeko catalog and save it as searchable JSON.
- Filter manga by name, category, status, rating, popularity, update date, or chapter count.
- Download a manga's information page, chapter pages, and chapter images.
- Turn chapter image folders into naturally sorted CBZ archives.
- Download and generate cover files.
- Extract structured metadata from saved HTML.
- Create and update a `manga-info.json` file for a local collection.
- Avoid unnecessary downloads unless an overwrite or force option is supplied.

Every command and internal helper lives in its own file under `Functions`. The module loader imports those files and exports only the public commands.

## Requirements

- PowerShell 5.1 or newer.
- An internet connection for discovery and download commands.
- Permission to create files in the chosen library folder.
- A CBZ-compatible reader if you want to read the generated archives.

The project is primarily intended for Windows PowerShell, although many commands may also work in PowerShell 7.

## Installation

Clone or download the repository, open PowerShell in the project directory, and import the manifest:

```powershell
Import-Module ./Mgeko-dl.psd1 -Force
```

Confirm that the module loaded:

```powershell
Get-Module Mgeko-dl
Get-Command -Module Mgeko-dl
```

To make the module available in future PowerShell sessions, either import it from its full path in your PowerShell profile or copy the project folder into one of the directories listed in `$env:PSModulePath`.

Detailed help is embedded in most commands:

```powershell
Get-Help Invoke-MSMangaDownloadToCbz -Full
Get-Help Find-MSMangaCatalog -Examples
```

## Quick start: download one manga

The main end-to-end command is `Invoke-MSMangaDownloadToCbz`. Give it a manga page and a folder where the collection should be stored:

```powershell
$library = Join-Path $HOME 'Manga'

Invoke-MSMangaDownloadToCbz `
    -MangaUrl 'https://www.mgeko.cc/manga/revival-man/' `
    -RootFolder $library `
    -Verbose
```

The command refreshes the manga and chapter index pages, downloads missing chapter content, generates cover and metadata files, and creates CBZ archives. Existing chapter downloads are normally reused.

Useful switches include:

- `-ForceDownload` downloads chapter HTML and images again.
- `-ForceCover` recreates cover files.
- `-SkipCover` skips cover generation.
- `-SkipCbz` downloads source material without creating CBZ files.
- `-OverwriteCbz` recreates CBZ files that already exist.

Keep `-RootFolder` short because Windows limits legacy filesystem paths. The
resolved root may contain at most 40 characters; `C:\manga\mgeko` is a good
example. Manga URL slugs longer than 50 characters are shortened only when the
local `web` and `cbz` folder paths are created. The original slug remains intact
for URLs, matching, and metadata, and an eight-character hash prevents two long
names with the same prefix from using the same folder.

The generated structure resembles:

```text
Manga/
|-- web/
|   `-- <manga-slug>/
|       |-- chapter HTML files
|       `-- chapter image folders
`-- cbz/
    `-- <manga-slug>/
        |-- manga-info-page.html
        |-- allchapters.html
        |-- manga-info.json
        |-- cover-source.jpg
        |-- folder-cover.jpg
        `-- *.cbz
```

## Discover and search the catalog

Create a local catalog from the Mgeko browse pages:

```powershell
$library = Join-Path $HOME 'Manga'
$browseUrl = 'https://www.mgeko.cc/browse-comics/?sort=az&page=1&safe_mode=0'

Invoke-MSMangaCatalogDiscovery `
    -StartUrl $browseUrl `
    -RootFolder $library `
    -Verbose
```

This creates `mgeko-manga-catalog.json`. Catalog discovery does not download chapters or CBZ files. To make a small test catalog first, limit the work:

```powershell
Invoke-MSMangaCatalogDiscovery `
    -StartUrl $browseUrl `
    -RootFolder $library `
    -MaxPages 2 `
    -MaxManga 20 `
    -Verbose
```

List the available categories:

```powershell
$catalog = Join-Path $library 'mgeko-manga-catalog.json'
Get-MSMangaCatalogCategory -CatalogFile $catalog
```

Search the catalog for highly rated completed action manga:

```powershell
Find-MSMangaCatalog `
    -CatalogFile $catalog `
    -IncludeCategory 'Action' `
    -Status 'Completed' `
    -MinRating 4.5 `
    -OrderBy Rating `
    -First 20
```

Exclude unwanted categories or search by part of a title:

```powershell
Find-MSMangaCatalog `
    -CatalogFile $catalog `
    -ExcludeCategory 'Harem','Romance' `
    -NameContains 'goblin' `
    -OrderBy Popular
```

## Convert existing image folders to CBZ

If chapters are already stored as folders of images, they can be converted independently of the downloader:

```text
MyManga/
|-- chapter-1/
|   |-- 0.jpg
|   `-- 1.jpg
|-- chapter-2/
`-- chapter-10/
```

Run:

```powershell
Convert-MSMangaFoldersToCbz `
    -RootPath (Join-Path $HOME 'Manga/MyManga')
```

By default, archives are written to an `_CBZ` folder below the source folder. Original images are not modified. Chapter and image names are naturally sorted, so values such as `chapter-2` correctly appear before `chapter-10`.

Use `-OutputPath` to choose another destination, `-IncludeSubFolders` to search recursively inside chapters, or `-Overwrite` to replace existing archives.

## Public command reference

| Command | Purpose |
| --- | --- |
| `Invoke-MSMangaDownloadToCbz` | Runs the main download, metadata, cover, and CBZ workflow for one manga. |
| `Invoke-MSMangaDownloadBrowser` | Starts a manga download from a supplied Mgeko browser URL and root folder. |
| `Invoke-MSMangaCatalogDiscovery` | Builds a JSON catalog from the Mgeko browse API and manga information pages. |
| `Find-MSMangaCatalog` | Filters and sorts a generated catalog. |
| `Get-MSMangaCatalogCategory` | Lists distinct categories found in a catalog. |
| `Convert-MSMangaFoldersToCbz` | Converts chapter image folders into CBZ archives. |
| `Get-MSMangaInfoFromHtml` | Extracts normalized manga information from a saved HTML page. |
| `Get-MSMangaMetadataFromHtml` | Extracts manga metadata from a saved HTML file. |
| `Save-MSMangaInfoJson` | Creates or updates `manga-info.json`. |
| `New-MSMangaFolderCoverFromHtml` | Downloads and generates cover files using HTML metadata. |
| `Convert-MSRelativeLastUpdateToDate` | Converts text such as a relative update time into an estimated date. |
| `Get-MSHtmlHref` | Extracts links from a local HTML file. |
| `Get-MSHtmlImageSrc` | Extracts image URLs, including common lazy-loading attributes, from HTML. |
| `Get-MSHtmlAttributeValue` | Extracts one named attribute from an HTML tag. |
| `Get-MSUrlLastPart` | Returns the final meaningful segment of a URL or path. |
| `Save-MSUrlToFile` | Downloads one URL to a chosen file. |
| `Save-MSUrlToFileWithUrlSubFolder` | Downloads a URL into a subfolder derived from its path. |

## Updating an existing download

Run `Invoke-MSMangaDownloadToCbz` again with the same manga URL and root folder. Existing local content is reused, while the manga information and all-chapters pages are refreshed. Use the force and overwrite switches only when you intentionally want to replace existing files.

For troubleshooting, add `-Verbose` to commands. Catalog discovery also supports `-KeepRawBrowsePages` and `-KeepMangaInfoPages`, which preserve intermediate responses and HTML pages for inspection.

## Notes and limitations

- This project is intended solely for educational purposes.
- The project does not grant permission to download or redistribute third-party content. Users are responsible for following applicable laws, copyright rules, and website terms of service.
- The HTML parsers depend on Mgeko's page structure and may require maintenance when the website changes.
- A partial or interrupted download can usually be resumed by running the same command again.
- CBZ files are ZIP archives containing sequentially named images.
- Keep reasonable delays between large discovery requests. The catalog command provides `-PageDelayMs` and `-MangaDelayMs` for this purpose.
- Download only material you are permitted to access and retain.

## License

The Mgeko-dl source code is licensed under the [MIT License](LICENSE). This license applies only to the project source code; it does not grant rights to manga, images, website content, or other third-party material.
