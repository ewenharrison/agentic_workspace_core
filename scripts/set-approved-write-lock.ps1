param(
    [ValidateSet("Lock", "Unlock", "Status")]
    [string]$Mode = "Status",

    [string]$Project = "",

    [switch]$AllProjects
)

$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    $root = (& git rev-parse --show-toplevel 2>$null)
    if (-not $root) {
        throw "Not inside a git repository."
    }
    return $root.Trim()
}

function Get-ApprovedRoots {
    param(
        [string]$RepoRoot,
        [string]$Project,
        [bool]$AllProjects
    )

    $projectsRoot = Join-Path $RepoRoot "workspace\projects"

    if ($Project) {
        $projectPath = Join-Path $projectsRoot ($Project -replace '/', '\')
        $approvedPath = Join-Path $projectPath "approved"
        if (-not (Test-Path -LiteralPath $approvedPath)) {
            throw "Approved folder not found: $approvedPath"
        }
        return @(Get-Item -LiteralPath $approvedPath)
    }

    if ($AllProjects) {
        return @(Get-ChildItem -LiteralPath $projectsRoot -Directory -Recurse -Filter approved)
    }

    throw "Specify -Project <slug> or -AllProjects."
}

function Get-ApprovedDirectories {
    param([System.IO.DirectoryInfo[]]$ApprovedRoots)

    $directories = New-Object System.Collections.Generic.List[System.IO.DirectoryInfo]
    foreach ($root in $ApprovedRoots) {
        $directories.Add($root)
        Get-ChildItem -LiteralPath $root.FullName -Directory -Recurse | ForEach-Object {
            $directories.Add($_)
        }
    }
    return $directories
}

function New-LockRule {
    param([string]$Identity)

    $rights = [System.Security.AccessControl.FileSystemRights]::CreateFiles -bor `
        [System.Security.AccessControl.FileSystemRights]::CreateDirectories

    return New-Object System.Security.AccessControl.FileSystemAccessRule(
        $Identity,
        $rights,
        [System.Security.AccessControl.InheritanceFlags]::None,
        [System.Security.AccessControl.PropagationFlags]::None,
        [System.Security.AccessControl.AccessControlType]::Deny
    )
}

function Test-DirectoryLocked {
    param(
        [string]$Path,
        [string]$Identity
    )

    $rights = [System.Security.AccessControl.FileSystemRights]::CreateFiles -bor `
        [System.Security.AccessControl.FileSystemRights]::CreateDirectories

    $acl = Get-Acl -LiteralPath $Path
    foreach ($rule in $acl.Access) {
        if ($rule.IdentityReference.Value -eq $Identity -and
            $rule.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Deny -and
            (($rule.FileSystemRights -band $rights) -ne 0)) {
            return $true
        }
    }
    return $false
}

function Set-DirectoryLock {
    param(
        [string]$Path,
        [string]$Identity,
        [bool]$Locked
    )

    $acl = Get-Acl -LiteralPath $Path
    $rule = New-LockRule -Identity $Identity

    if ($Locked) {
        if (-not (Test-DirectoryLocked -Path $Path -Identity $Identity)) {
            $acl.AddAccessRule($rule)
            Set-Acl -LiteralPath $Path -AclObject $acl
        }
        return
    }

    $acl.RemoveAccessRuleAll($rule)
    Set-Acl -LiteralPath $Path -AclObject $acl
}

$repoRoot = Get-RepoRoot
$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$approvedRoots = Get-ApprovedRoots -RepoRoot $repoRoot -Project $Project -AllProjects:$AllProjects
$directories = Get-ApprovedDirectories -ApprovedRoots $approvedRoots

foreach ($directory in $directories) {
    if ($Mode -eq "Lock") {
        Set-DirectoryLock -Path $directory.FullName -Identity $identity -Locked $true
    }
    elseif ($Mode -eq "Unlock") {
        Set-DirectoryLock -Path $directory.FullName -Identity $identity -Locked $false
    }

    $locked = Test-DirectoryLocked -Path $directory.FullName -Identity $identity
    $state = if ($locked) { "locked" } else { "unlocked" }
    Write-Host "$state`t$($directory.FullName)"
}
