[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$word = $null
$document = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0

    $resolved = (Resolve-Path -LiteralPath $InputPath).Path
    $document = $word.Documents.Open($resolved, $false, $true, $false)
    $paragraphs = @()

    for ($index = 1; $index -le $document.Paragraphs.Count; $index++) {
        $range = $document.Paragraphs.Item($index).Range
        $style = $null
        $listString = ''
        $page = $null

        try { $style = $range.Style.NameLocal } catch { $style = [string]$range.Style }
        try { $listString = [string]$range.ListFormat.ListString } catch { $listString = '' }
        try { $page = $range.Information(3) } catch { $page = $null }

        $paragraphs += [pscustomobject]@{
            Index      = $index
            Page       = $page
            Start      = $range.Start
            End        = $range.End
            Style      = $style
            ListString = $listString
            Text       = ($range.Text -replace "`r", ' ' -replace "`a", ' ').Trim()
        }
    }

    $outputResolved = [IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath))
    $outputDirectory = [IO.Path]::GetDirectoryName($outputResolved)
    if (-not [IO.Directory]::Exists($outputDirectory)) {
        [IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
    }

    $json = $paragraphs | ConvertTo-Json -Depth 4
    [IO.File]::WriteAllText($outputResolved, $json, (New-Object Text.UTF8Encoding($false)))
    Write-Output "Exported $($paragraphs.Count) paragraphs to $outputResolved"
}
finally {
    if ($null -ne $document) {
        $document.Close(0)
        [Runtime.InteropServices.Marshal]::ReleaseComObject($document) | Out-Null
    }
    if ($null -ne $word) {
        $word.Quit()
        [Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
