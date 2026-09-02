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

function Convert-ProofingRange {
    param(
        [Parameter(Mandatory = $true)]
        $Range,

        [Parameter(Mandatory = $true)]
        [string]$Kind
    )

    $page = $null
    $paragraph = $null
    $sentence = $null

    try { $page = $Range.Information(3) } catch { $page = $null }
    try { $paragraph = $Range.Paragraphs.Item(1).Range.Text } catch { $paragraph = '' }
    try { $sentence = $Range.Sentences.Item(1).Text } catch { $sentence = '' }

    [pscustomobject]@{
        Kind          = $Kind
        Page          = $page
        Start         = $Range.Start
        End           = $Range.End
        Text          = ($Range.Text -replace "`r", ' ' -replace "`a", ' ').Trim()
        SentenceText  = ($sentence -replace "`r", ' ' -replace "`a", ' ').Trim()
        ParagraphText = ($paragraph -replace "`r", ' ' -replace "`a", ' ').Trim()
    }
}

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0

    $resolved = (Resolve-Path -LiteralPath $InputPath).Path
    $document = $word.Documents.Open($resolved, $false, $true, $false)

    $spelling = @()
    foreach ($errorRange in $document.SpellingErrors) {
        $spelling += Convert-ProofingRange -Range $errorRange -Kind 'Spelling'
    }

    $grammar = @()
    foreach ($errorRange in $document.GrammaticalErrors) {
        $grammar += Convert-ProofingRange -Range $errorRange -Kind 'Grammar'
    }

    $result = [pscustomobject]@{
        Path          = $resolved
        Name          = [IO.Path]::GetFileName($resolved)
        PageCount     = $document.ComputeStatistics(2)
        WordCount     = $document.ComputeStatistics(0)
        CommentCount  = $document.Comments.Count
        RevisionCount = $document.Revisions.Count
        SpellingCount = $spelling.Count
        GrammarCount  = $grammar.Count
        Spelling      = $spelling
        Grammar       = $grammar
    }

    $outputResolved = [IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath))
    $outputDirectory = [IO.Path]::GetDirectoryName($outputResolved)
    if (-not [IO.Directory]::Exists($outputDirectory)) {
        [IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
    }

    $json = $result | ConvertTo-Json -Depth 6
    [IO.File]::WriteAllText($outputResolved, $json, (New-Object Text.UTF8Encoding($false)))
    Write-Output "Exported proofing flags to $outputResolved"
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
