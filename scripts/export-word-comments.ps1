[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$InputPath,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

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
            $comments = @()

            foreach ($comment in $document.Comments) {
                $scope = $comment.Scope
                $paragraph = $scope.Paragraphs.Item(1).Range
                $page = $null
                $paragraphStyle = $null

                try {
                    $page = $scope.Information(3)
                }
                catch {
                    $page = $null
                }

                try {
                    $paragraphStyle = $paragraph.Style.NameLocal
                }
                catch {
                    $paragraphStyle = [string]$paragraph.Style
                }

                $comments += [pscustomobject]@{
                    Index      = $comment.Index
                    Author     = $comment.Author
                    Initial    = $comment.Initial
                    Date       = $comment.Date.ToString('yyyy-MM-dd HH:mm:ss')
                    Page       = $page
                    StoryType  = [int]$scope.StoryType
                    ScopeStart = $scope.Start
                    ScopeEnd   = $scope.End
                    ScopeText  = ($scope.Text -replace "`r", ' ' -replace "`a", ' ').Trim()
                    ParagraphStart = $paragraph.Start
                    ParagraphEnd   = $paragraph.End
                    ParagraphStyle = $paragraphStyle
                    ParagraphText  = ($paragraph.Text -replace "`r", ' ' -replace "`a", ' ').Trim()
                    Comment    = ($comment.Range.Text -replace "`r", "`n" -replace "`a", ' ').Trim()
                }
            }

            $documents += [pscustomobject]@{
                Path          = $resolved
                Name          = [IO.Path]::GetFileName($resolved)
                CommentCount  = $document.Comments.Count
                RevisionCount = $document.Revisions.Count
                Comments      = $comments
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
    Write-Output "Exported comments from $($documents.Count) document(s) to $outputResolved"
}
finally {
    if ($null -ne $word) {
        $word.Quit()
        [Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
}
