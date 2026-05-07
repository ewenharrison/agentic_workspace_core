param(
    [string]$Destination = ".\exports\agentic_workspace_core"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$destinationPath = if ([System.IO.Path]::IsPathRooted($Destination)) {
    $Destination
} else {
    Join-Path $repoRoot $Destination
}

$includePaths = @(
    "README.core.md",
    "PUBLISHING.core.md",
    "profile.core",
    "config\slack-webhooks.json.example",
    "config\teams-webhook-url.txt.example",
    "workspace\_templates",
    "workspace\repo",
    "workspace\workflows",
    "workspace\registry",
    "workspace\registry\index.core.md",
    "workspace\runs\agent-runs.core.md",
    "workspace\projects\sample-project",
    ".github\workflows\pubmed-literature-search.yml",
    ".github\workflows\tier2-cloud-maintenance.core.yml",
    "scripts\export-markdown-to-word.ps1",
    "scripts\post-slack-file.ps1",
    "scripts\post-slack-update.ps1",
    "scripts\post-teams-update.ps1",
    "scripts\run-pubmed-literature-search.ps1",
    "scripts\run-tier2-cloud-task.ps1",
    "scripts\export-agentic-memory-core.ps1"
)

if (Test-Path -LiteralPath $destinationPath) {
    Remove-Item -LiteralPath $destinationPath -Recurse -Force
}

New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null

foreach ($relativePath in $includePaths) {
    $sourcePath = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        Write-Warning "Skipping missing path: $relativePath"
        continue
    }

    $targetPath = Join-Path $destinationPath $relativePath
    if ($relativePath -eq "README.core.md") {
        $targetPath = Join-Path $destinationPath "README.md"
    }
    if ($relativePath -eq "PUBLISHING.core.md") {
        $targetPath = Join-Path $destinationPath "PUBLISHING.md"
    }
    if ($relativePath -eq "profile.core") {
        $targetPath = Join-Path $destinationPath "profile"
    }
    if ($relativePath -eq "workspace\\registry\\index.core.md") {
        $targetPath = Join-Path $destinationPath "workspace\\registry\\index.md"
    }
    if ($relativePath -match 'tier2-cloud-maintenance\.core\.yml$') {
        $targetPath = Join-Path $destinationPath ".github\\workflows\\tier2-cloud-maintenance.yml"
    }
    if ($relativePath -eq "workspace\runs\agent-runs.core.md") {
        $targetPath = Join-Path $destinationPath "workspace\runs\agent-runs.md"
    }
    $targetParent = Split-Path -Parent $targetPath
    if ($targetParent) {
        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
    }

    Copy-Item -LiteralPath $sourcePath -Destination $targetPath -Recurse -Force
}

$exportRegistryPath = Join-Path $destinationPath "workspace\registry"
$exportRegistryIndexPath = Join-Path $exportRegistryPath "index.md"
$coreRegistryIndexSource = Join-Path $repoRoot "workspace\registry\index.core.md"

if (Test-Path -LiteralPath $exportRegistryIndexPath) {
    Remove-Item -LiteralPath $exportRegistryIndexPath -Force
}

Get-Content -LiteralPath $coreRegistryIndexSource -Raw | Set-Content -LiteralPath $exportRegistryIndexPath

$privateRepoNotes = Get-ChildItem -LiteralPath (Join-Path $destinationPath "workspace\repo") -Filter "*-core-promotion-review.md" -File -ErrorAction SilentlyContinue
foreach ($note in $privateRepoNotes) {
    Remove-Item -LiteralPath $note.FullName -Force
}

$privateOnlyRepoFiles = @(
    "email-procedure.md",
    "evernote-email-procedure.md"
)
foreach ($fileName in $privateOnlyRepoFiles) {
    $privateOnlyPath = Join-Path (Join-Path $destinationPath "workspace\repo") $fileName
    if (Test-Path -LiteralPath $privateOnlyPath) {
        Remove-Item -LiteralPath $privateOnlyPath -Force
    }
}

@"
# Local secrets
config/teams-webhook-url.txt
config/slack-webhook-url.txt
config/slack-webhooks.json
config/gmail-smtp.json

# Export artefacts
exports/

# OS / editor noise
.DS_Store
Thumbs.db
.vscode/
~$*.docx
"@ | Set-Content -LiteralPath (Join-Path $destinationPath ".gitignore")

Write-Host "Exported framework-only core bundle to: $destinationPath"
