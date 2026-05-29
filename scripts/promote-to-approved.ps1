param(
    [Parameter(Mandatory = $true)]
    [string]$WorkingPath,

    [Parameter(Mandatory = $true)]
    [ValidateSet("framing", "sources", "syntheses", "outputs")]
    [string]$ApprovedSubfolder,

    [Parameter(Mandatory = $true)]
    [string]$ApprovedBy,

    [string]$NewName = ""
)

$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    $root = (& git rev-parse --show-toplevel 2>$null)
    if (-not $root) {
        throw "Not inside a git repository."
    }
    return $root.Trim()
}

function Get-RelativePath {
    param(
        [string]$BasePath,
        [string]$TargetPath
    )

    $baseUri = [Uri]((Resolve-Path -LiteralPath $BasePath).Path.TrimEnd('\') + '\')
    $targetUri = [Uri]((Resolve-Path -LiteralPath $TargetPath).Path)
    return [Uri]::UnescapeDataString($baseUri.MakeRelativeUri($targetUri).ToString()) -replace '/', '\'
}

$repoRoot = Get-RepoRoot
$resolvedWorking = Resolve-Path -LiteralPath $WorkingPath
$workingItem = Get-Item -LiteralPath $resolvedWorking.Path
if ($workingItem.PSIsContainer) {
    throw "WorkingPath must be a file, not a directory: $WorkingPath"
}

$relativeWorking = Get-RelativePath -BasePath $repoRoot -TargetPath $workingItem.FullName
if ($relativeWorking -notmatch '^workspace\\projects\\(.+)\\(working|auto)\\') {
    throw "WorkingPath must be under workspace/projects/<project>/working or auto: $relativeWorking"
}

$projectPart = $Matches[1]
$projectRoot = Join-Path $repoRoot ("workspace\projects\" + $projectPart)
$approvedRoot = Join-Path $projectRoot "approved"
$approvedDestinationDirectory = Join-Path $approvedRoot $ApprovedSubfolder
$destinationName = if ($NewName) { $NewName } else { $workingItem.Name }
$destinationPath = Join-Path $approvedDestinationDirectory $destinationName

if (Test-Path -LiteralPath $destinationPath) {
    throw "Approved destination already exists: $destinationPath"
}

Write-Host "Promotion approved by: $ApprovedBy"
Write-Host "From: $($workingItem.FullName)"
Write-Host "To:   $destinationPath"

& (Join-Path $repoRoot "scripts\set-approved-write-lock.ps1") -Mode Unlock -Project ($projectPart -replace '\\', '/') | Out-Host

try {
    New-Item -ItemType Directory -Force -Path $approvedDestinationDirectory | Out-Null
    Move-Item -LiteralPath $workingItem.FullName -Destination $destinationPath
}
finally {
    & (Join-Path $repoRoot "scripts\set-approved-write-lock.ps1") -Mode Lock -Project ($projectPart -replace '\\', '/') | Out-Host
}

Write-Host "Promoted file. Update approved/index.md, project links, and memory.md before reporting completion."
