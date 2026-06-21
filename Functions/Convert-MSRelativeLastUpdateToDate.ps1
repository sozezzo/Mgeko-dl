function Convert-MSRelativeLastUpdateToDate {
<#
.SYNOPSIS
    Converts relative manga last update text to an estimated date.

.DESCRIPTION
    Examples:
        "6 years"           -> Download date minus 6 years
        "3 years, 4 months" -> Download date minus 3 years and 4 months
        "4 months"          -> Download date minus 4 months
        "15 days"           -> Download date minus 15 days

    The result is approximate because the site usually gives relative time,
    not an exact update date.
#>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$RawText,

        [datetime]$ReferenceDate = (Get-Date)
    )

    Set-StrictMode -Version Latest

    $cleanText = ''

    if (-not [string]::IsNullOrWhiteSpace($RawText)) {
        $cleanText = $RawText -replace [char]0x00A0, ' '
        $cleanText = $cleanText.Trim()
        $cleanText = $cleanText -replace '\s+', ' '
        $cleanText = $cleanText -replace '(?i)^last\s+update\s*:\s*', ''
        $cleanText = $cleanText.Trim()
    }

    $years  = 0
    $months = 0
    $weeks  = 0
    $days   = 0

    if ($cleanText -match '(?i)(\d+)\s*(year|years|yr|yrs)') {
        $years = [int]$Matches[1]
    }

    if ($cleanText -match '(?i)(\d+)\s*(month|months|mo|mos)') {
        $months = [int]$Matches[1]
    }

    if ($cleanText -match '(?i)(\d+)\s*(week|weeks|wk|wks)') {
        $weeks = [int]$Matches[1]
    }

    if ($cleanText -match '(?i)(\d+)\s*(day|days)') {
        $days = [int]$Matches[1]
    }

    $estimatedDate = $ReferenceDate.Date

    if ($years -ne 0) {
        $estimatedDate = $estimatedDate.AddYears(-$years)
    }

    if ($months -ne 0) {
        $estimatedDate = $estimatedDate.AddMonths(-$months)
    }

    if ($weeks -ne 0) {
        $estimatedDate = $estimatedDate.AddDays(-7 * $weeks)
    }

    if ($days -ne 0) {
        $estimatedDate = $estimatedDate.AddDays(-$days)
    }

    $isApproximate = $true

    # If nothing relative was found, try parsing as a real date.
    if ($years -eq 0 -and $months -eq 0 -and $weeks -eq 0 -and $days -eq 0) {
        $parsedDate = [datetime]::MinValue

        if ([datetime]::TryParse($cleanText, [ref]$parsedDate)) {
            $estimatedDate = $parsedDate.Date
            $isApproximate = $false
        }
    }

    return [pscustomobject]@{
        RawText        = $cleanText
        EstimatedDate  = $estimatedDate.ToString('yyyy-MM-dd')
        CalculatedFrom = $ReferenceDate.Date.ToString('yyyy-MM-dd')
        AgeYears       = $years
        AgeMonths      = $months
        AgeWeeks       = $weeks
        AgeDays        = $days
        TotalAgeMonths = (($years * 12) + $months)
        IsApproximate  = $isApproximate
    }
}

