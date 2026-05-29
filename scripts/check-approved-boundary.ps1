param(
    [switch]$AllowApprovedChanges,
    [switch]$Strict
)

$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    $root = (& git rev-parse --show-toplevel 2>$null)
    if (-not $root) {
        throw "Not inside a git repository."
    }
    return $root.Trim()
}

function Get-StatusPath {
    param([string]$StatusLine)

    $path = $StatusLine.Substring(3)

    if ($path -match ' -> ') {
        $path = ($path -split ' -> ')[-1]
    }

    return $path.Trim().Trim('"') -replace '\\', '/'
}

$repoRoot = Get-RepoRoot
Set-Location -LiteralPath $repoRoot

$statusLines = & git status --porcelain=v1 -uall
$approvedChanges = @()
$indexOnlyChanges = @()

foreach ($line in $statusLines) {
    if (-not $line.Trim()) {
        continue
    }

    $path = Get-StatusPath -StatusLine $line
    if ($path -notmatch '^workspace/projects/.+/approved/.+') {
        continue
    }

    if (-not $Strict -and $path -match '^workspace/projects/.+/approved/(index\.md|.+/\.gitkeep)$') {
        $indexOnlyChanges += $line
        continue
    }

    $approvedChanges += $line
}

if ($approvedChanges.Count -eq 0) {
    if ($indexOnlyChanges.Count -gt 0) {
        Write-Host "Approved-boundary check passed. Only approved/index.md or approved subfolder .gitkeep changes were found:"
        $indexOnlyChanges | ForEach-Object { Write-Host "  $_" }
    }
    else {
        Write-Host "Approved-boundary check passed. No non-index approved/ changes found."
    }
    exit 0
}

if ($AllowApprovedChanges) {
    Write-Host "Approved-boundary override used. Explicitly allowing these approved/ changes:"
    $approvedChanges | ForEach-Object { Write-Host "  $_" }
    exit 0
}

Write-Error @"
Approval-boundary check failed.

The following uncommitted files are under workspace/projects/**/approved/:
$($approvedChanges | ForEach-Object { "  $_" } | Out-String)
Do not leave agent-created notes, syntheses, tasks, or outputs in approved/.
Move them to working/ unless the user explicitly approved promotion.

If the user explicitly approved these approved/ changes, rerun:
  powershell -ExecutionPolicy Bypass -File .\scripts\check-approved-boundary.ps1 -AllowApprovedChanges
"@

exit 2
