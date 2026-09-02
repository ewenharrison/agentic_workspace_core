param(
    [Parameter(Mandatory = $true)]
    [string]$Project,

    [string]$Title = "",

    [string]$ResumeIntent = "",

    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    $root = (& git rev-parse --show-toplevel 2>$null)
    if (-not $root) {
        throw "Not inside a git repository."
    }
    return $root.Trim()
}

function Convert-ToMarkdownPath {
    param([string]$Path)
    return ($Path -replace '\\', '/')
}

function Get-RepoPrefix {
    param([string]$Project)

    $segments = @($Project -replace '\\', '/' -split '/' | Where-Object { $_ })
    return ("../" * ($segments.Count + 1)) + "repo"
}

function Write-TextFile {
    param(
        [string]$Path,
        [string]$Content,
        [bool]$Force
    )

    if ((Test-Path -LiteralPath $Path) -and -not $Force) {
        throw "File already exists: $Path"
    }

    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }

    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
}

$repoRoot = Get-RepoRoot
$projectSlug = ($Project.Trim() -replace '\\', '/').Trim('/')
if (-not $projectSlug) {
    throw "Project slug is empty."
}

$projectRoot = Join-Path $repoRoot ("workspace\projects\" + ($projectSlug -replace '/', '\'))
if ((Test-Path -LiteralPath $projectRoot) -and -not $Force) {
    throw "Project already exists: $projectRoot"
}

$titleText = if ($Title) { $Title } else { $projectSlug }
$resumeText = if ($ResumeIntent) { $ResumeIntent } else { "Reload this project from memory before doing new work." }
$repoPrefix = Get-RepoPrefix -Project $projectSlug
$sharedPath = Convert-ToMarkdownPath (Join-Path $repoPrefix "shared-procedures.md")
$preflightPath = Convert-ToMarkdownPath (Join-Path $repoPrefix "preflight-checklists.md")

$directories = @(
    "working",
    "sources\files",
    "logs",
    "auto",
    "approved",
    "approved\framing",
    "approved\sources",
    "approved\syntheses",
    "approved\outputs"
)

New-Item -ItemType Directory -Force -Path $projectRoot | Out-Null
foreach ($directory in $directories) {
    New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot $directory) | Out-Null
}

Write-TextFile -Path (Join-Path $projectRoot "init.md") -Force:$Force -Content @"
# Initialise ``$projectSlug``

Use this file when a new session needs to resume the project cleanly.

## Accepted Command

``Initialise project $projectSlug``

## Required Read Order

1. [$sharedPath]($sharedPath)
2. [$preflightPath]($preflightPath)
3. [memory.md](./memory.md)
4. [project.md](./project.md)
5. [approved/index.md](./approved/index.md)
6. [auto/index.md](./auto/index.md)
7. [logs/activity.md](./logs/activity.md)

## Project Creation Boundary

Agent-created notes, syntheses, tasks, and outputs start in ``working/``; ``approved/`` is human-gated. Use the ``New Project Initiation Or Scaffolding`` checklist before adding new scaffolded material.

## Current Resume Intent

$resumeText
"@

Write-TextFile -Path (Join-Path $projectRoot "project.md") -Force:$Force -Content @"
# $titleText

## Overview

Project scaffold created through ``scripts/new-project.ps1``.

## Quick Access

- Fast session briefing: [memory.md](./memory.md)
- Approved index: [approved/index.md](./approved/index.md)
- Session bootstrap: [init.md](./init.md)
- Shared procedures: [$sharedPath]($sharedPath)
- Preflight checklists: [$preflightPath]($preflightPath)

## Scope

- In scope:
- Out of scope:

## Goals

- [ ] Define project goals.

## Active Tasks

- [ ] Add first working draft or source note.

## Key Decisions

- Decision: ``approved/`` is human-gated.
  Reason: Agent-created material is draft material until explicitly reviewed and promoted by the user.

## Open Questions

- What is the immediate deliverable?

## Current Understanding

No substantive project claims have been approved yet.

## Working Rule

Open ``memory.md`` first when resuming this project. Use this file for slower-changing project structure, goals and governance.

## Important Sources

- Draft and unreviewed material belongs in ``working/``.

## Risks Or Unknowns

- Avoid treating unreviewed agent summaries as approved project knowledge.

## Next Review

- Date:
- Focus:
"@

Write-TextFile -Path (Join-Path $projectRoot "memory.md") -Force:$Force -Content @"
# Project Memory Snapshot

## Current Snapshot

Project scaffold created through ``scripts/new-project.ps1``. No substantive project claims or outputs have been approved yet.

## Current Objective

Define the immediate project objective.

## Key Claims We Are Carrying Forward

- None yet.

## Open Loops

- ``[Q1]`` Define the first deliverable.

## Active Sources

- None yet.

## What Changed Recently

- Created project scaffold.

## Next Actions

- [ ] Add raw source files under ``sources/`` if supplied.
- [ ] Put draft source notes, syntheses, tasks, and outputs in ``working/``.

## Suggested Next Prompts

- "Initialise project $projectSlug."

## Guardrails

- ``approved/`` is human-gated. Do not create or move files there without explicit human approval or an explicit instruction to promote a named draft.
- Agent-created material starts in ``working/``.
"@

Write-TextFile -Path (Join-Path $projectRoot "approved\index.md") -Force:$Force -Content @"
# Approved Index

This folder is intentionally empty until the user explicitly reviews and promotes material.

## Approval Rule

Files may enter ``approved/`` only after explicit human approval or an explicit instruction to promote a named draft. Agent-created source notes, syntheses, tasks, and outputs must start in ``working/``.

## Approved Folders

- ``framing/``: approved positioning, rationale, and argument scaffolding
- ``sources/``: approved source notes
- ``syntheses/``: approved syntheses and analyses
- ``outputs/``: final or agreed deliverables

## Current Approved Material

None.
"@

foreach ($approvedSubfolder in @("framing", "sources", "syntheses", "outputs")) {
    Write-TextFile -Path (Join-Path $projectRoot "approved\$approvedSubfolder\.gitkeep") -Force:$Force -Content ""
}

Write-TextFile -Path (Join-Path $projectRoot "auto\index.md") -Force:$Force -Content @"
# Auto Index

No autonomous or machine-generated syntheses are currently promoted for this project.
"@

Write-TextFile -Path (Join-Path $projectRoot "logs\activity.md") -Force:$Force -Content @"
# Activity Log

## $(Get-Date -Format yyyy-MM-dd)

- Created project scaffold through ``scripts/new-project.ps1``.
- Created empty human-gated ``approved/index.md``.
"@

& (Join-Path $repoRoot "scripts\set-approved-write-lock.ps1") -Mode Lock -Project $projectSlug | Out-Host

Write-Host "Created project: $projectRoot"
