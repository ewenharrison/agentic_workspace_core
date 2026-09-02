[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$typeNames = @{
    0 = 'None'; 1 = 'Insert'; 2 = 'Delete'; 3 = 'Property';
    4 = 'ParagraphNumber'; 5 = 'DisplayField'; 6 = 'Reconcile';
    7 = 'Conflict'; 8 = 'Style'; 9 = 'Replace';
    10 = 'ParagraphProperty'; 11 = 'TableProperty'; 12 = 'SectionProperty';
    13 = 'StyleDefinition'; 14 = 'MovedFrom'; 15 = 'MovedTo';
    16 = 'CellInsertion'; 17 = 'CellDeletion'; 18 = 'CellMerge';
    19 = 'CellSplit'; 20 = 'ConflictInsert'; 21 = 'ConflictDelete'
}

$word = $null
$documents = @()

try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0

    foreach ($path in $InputPath) {
        $resolved = (Resolve-Path -LiteralPath $path).Path
        $document = $null

        try {
            $document = $word.Documents.Open($resolved, $false, $true, $false)
            $revisions = @()

            foreach ($revision in $document.Revisions) {
                $range = $revision.Range
                $paragraph = $range.Paragraphs.Item(1).Range
                $page = $null

                try { $page = $range.Information(3) } catch { $page = $null }

                $type = [int]$revision.Type
                $typeName = if ($typeNames.ContainsKey($type)) {
                    $typeNames[$type]
                }
                else {
                    "Type$type"
                }

                $date = $null
                try { $date = $revision.Date.ToString('yyyy-MM-dd HH:mm:ss') } catch { $date = $null }

                $revisions += [pscustomobject]@{
                    Index         = $revision.Index
                    Type          = $type
                    TypeName      = $typeName
                    Author        = $revision.Author
                    Date          = $date
                    Page          = $page
                    Start         = $range.Start
                    End           = $range.End
                    Text          = ($range.Text -replace "`r", ' ' -replace "`a", ' ').Trim()
                    ParagraphText = ($paragraph.Text -replace "`r", ' ' -replace "`a", ' ').Trim()
                }
            }

            $documents += [pscustomobject]@{
                Path          = $resolved
                Name          = [IO.Path]::GetFileName($resolved)
                RevisionCount = $document.Revisions.Count
                Revisions     = $revisions
            }
        }
        finally {
            if ($null -ne $document) {
                $document.Close(0)
                [Runtime.InteropServices.Marshal]::ReleaseComObject($document) | Out-Null
            }
        }
    }

    $outputResolved = [IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath))
    $outputDirectory = [IO.Path]::GetDirectoryName($outputResolved)
    if (-not [IO.Directory]::Exists($outputDirectory)) {
        [IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
    }

    $json = $documents | ConvertTo-Json -Depth 6
    [IO.File]::WriteAllText($outputResolved, $json, (New-Object Text.UTF8Encoding($false)))
    Write-Output "Exported revisions from $($documents.Count) document(s) to $outputResolved"
}
finally {
    if ($null -ne $word) {
        $word.Quit()
        [Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
