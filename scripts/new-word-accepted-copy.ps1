param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [switch]$RemoveComments
)

$ErrorActionPreference = "Stop"

$resolvedInput = Resolve-Path -LiteralPath $InputPath
$outputDirectory = Split-Path -Parent $OutputPath
if ($outputDirectory -and -not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

Copy-Item -LiteralPath $resolvedInput.Path -Destination $OutputPath -Force
$resolvedOutput = Resolve-Path -LiteralPath $OutputPath

$word = $null
$document = $null

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0

    $document = $word.Documents.Open($resolvedOutput.Path, $false, $false)
    $initialRevisions = $document.Revisions.Count
    $initialComments = $document.Comments.Count

    if ($initialRevisions -gt 0) {
        $document.AcceptAllRevisions()
    }

    if ($RemoveComments) {
        for ($i = $document.Comments.Count; $i -ge 1; $i--) {
            $document.Comments.Item($i).Delete()
        }
    }

    $document.Save()

    [pscustomobject]@{
        File = $resolvedOutput.Path
        InitialRevisions = $initialRevisions
        InitialComments = $initialComments
        FinalRevisions = $document.Revisions.Count
        FinalComments = $document.Comments.Count
        RemovedComments = [bool]$RemoveComments
    }
}
finally {
    if ($null -ne $document) {
        $document.Close($false)
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($document) | Out-Null
    }
    if ($null -ne $word) {
        $word.Quit()
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    }
}
