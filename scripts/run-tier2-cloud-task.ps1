param(
    [Parameter(Mandatory = $false)]
    [string]$Project = "sample-project",

    [Parameter(Mandatory = $false)]
    [string]$TaskPrompt = "Refresh Tier 2 working memory and capture any administrative decisions.",

    [Parameter(Mandatory = $false)]
    [string]$RunMode = "manual",

    [Parameter(Mandatory = $false)]
    [string]$AgentMode = "general",

    [Parameter(Mandatory = $false)]
    [switch]$SkipModelCall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Add-LineIfMissing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Line
    )

    $content = Get-Content -LiteralPath $Path -Raw
    if ($content -notmatch [regex]::Escape($Line)) {
        $trimmed = $content.TrimEnd("`r", "`n")
        Set-Content -LiteralPath $Path -Value ($trimmed + "`r`n" + $Line + "`r`n")
    }
}

function Convert-ToSlug {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $slug = $Value.ToLowerInvariant()
    $slug = [regex]::Replace($slug, "[^a-z0-9]+", "-")
    $slug = $slug.Trim("-")

    if ([string]::IsNullOrWhiteSpace($slug)) {
        return "tier2-note"
    }

    if ($slug.Length -gt 60) {
        return $slug.Substring(0, 60).Trim("-")
    }

    return $slug
}

function Get-TrimmedFileBlock {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Label,

        [Parameter(Mandatory = $false)]
        [int]$MaxChars = 6000
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return "## $Label`nMissing: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw
    if ($raw.Length -gt $MaxChars) {
        $raw = $raw.Substring(0, $MaxChars) + "`n`n[Truncated for cloud context]"
    }

    return "## $Label`nPath: $Path`n`n$raw"
}

function Resolve-AgentMode {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $normalised = $Value.Trim().ToLowerInvariant()
    switch ($normalised) {
        "general" { return "general" }
        "context_scout" { return "context_scout" }
        "context-scout" { return "context_scout" }
        "synthesis_agent" { return "synthesis_agent" }
        "synthesis-agent" { return "synthesis_agent" }
        "literature_scout" { throw "The 'literature_scout' mode is reserved for a future workflow with real external search capability. Use 'context_scout' for repo-context scanning, or run a literature search separately and pass the results to synthesis_agent." }
        "literature-scout" { throw "The 'literature_scout' mode is reserved for a future workflow with real external search capability. Use 'context_scout' for repo-context scanning, or run a literature search separately and pass the results to synthesis_agent." }
        default { throw "Unsupported agent mode '$Value'. Use 'general', 'context_scout', or 'synthesis_agent'." }
    }
}

function Get-AgentModeLabel {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Mode
    )

    switch ($Mode) {
        "context_scout" { return "Context Scout" }
        "synthesis_agent" { return "Synthesis Agent" }
        default { return "General Tier 2 Agent" }
    }
}

function Get-AgentPromptTemplateText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [string]$Mode
    )

    $templateMap = @{
        context_scout    = "workspace\_templates\context_scout_prompt.md"
        synthesis_agent  = "workspace\_templates\synthesis_agent_prompt.md"
    }

    if (-not $templateMap.ContainsKey($Mode)) {
        return ""
    }

    $templatePath = Join-Path $RepoRoot $templateMap[$Mode]
    if (-not (Test-Path -LiteralPath $templatePath)) {
        return ""
    }

    return Get-Content -LiteralPath $templatePath -Raw
}

function Resolve-LanePolicyPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AutoDirectory
    )

    $preferredNames = @(
        "autonomous-lane-policy.md",
        "autonomous_lane_policy.md"
    )

    foreach ($name in $preferredNames) {
        $candidate = Join-Path $AutoDirectory $name
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    $datedCandidate = Get-ChildItem -LiteralPath $AutoDirectory -Filter *autonomous-lane-policy*.md -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($null -ne $datedCandidate) {
        return $datedCandidate.FullName
    }

    return $null
}

function Get-ResponseOutputText {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Response
    )

    if ($null -ne $Response.PSObject.Properties["output_text"] -and -not [string]::IsNullOrWhiteSpace([string]$Response.output_text)) {
        return [string]$Response.output_text
    }

    if ($null -ne $Response.PSObject.Properties["output"]) {
        foreach ($item in $Response.output) {
            if ($null -eq $item) {
                continue
            }

            if ($null -ne $item.PSObject.Properties["content"]) {
                foreach ($contentItem in $item.content) {
                    if ($null -eq $contentItem) {
                        continue
                    }

                    if ($contentItem.type -eq "output_text") {
                        return [string]$contentItem.text
                    }

                    if ($contentItem.type -eq "refusal") {
                        throw "OpenAI refusal: $($contentItem.refusal)"
                    }
                }
            }
        }
    }

    $responsePreview = $Response | ConvertTo-Json -Depth 10
    throw "No output text could be extracted from the OpenAI response. Response preview: $responsePreview"
}

function Invoke-OpenAISynthesis {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $true)]
        [string]$Prompt,

        [Parameter(Mandatory = $true)]
        [string]$ContextText,

        [Parameter(Mandatory = $true)]
        [string]$RunModeValue,

        [Parameter(Mandatory = $true)]
        [string]$AgentModeValue,

        [Parameter(Mandatory = $true)]
        [string]$AgentModeLabel,

        [Parameter(Mandatory = $false)]
        [string]$AgentTemplateText
    )

    $apiKey = $env:OPENAI_API_KEY
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        throw "OPENAI_API_KEY is not set. Add it as a GitHub Actions secret before running cloud synthesis."
    }

    $model = if ([string]::IsNullOrWhiteSpace($env:OPENAI_MODEL)) { "gpt-5-mini" } else { $env:OPENAI_MODEL }
    $reasoningEffort = if ([string]::IsNullOrWhiteSpace($env:OPENAI_REASONING_EFFORT)) { "low" } else { $env:OPENAI_REASONING_EFFORT }

    $schema = @{
        type = "object"
        additionalProperties = $false
        properties = @{
            note_title = @{ type = "string" }
            summary = @{
                type = "array"
                items = @{ type = "string" }
            }
            key_updates = @{
                type = "array"
                items = @{ type = "string" }
            }
            open_loops = @{
                type = "array"
                items = @{ type = "string" }
            }
            next_actions = @{
                type = "array"
                items = @{ type = "string" }
            }
            evidence_used = @{
                type = "array"
                items = @{ type = "string" }
            }
            guardrails = @{
                type = "array"
                items = @{ type = "string" }
            }
        }
        required = @(
            "note_title",
            "summary",
            "key_updates",
            "open_loops",
            "next_actions",
            "evidence_used",
            "guardrails"
        )
    }

    $developerInstructions = @'
You are maintaining a Tier 2 autonomous memory lane in a project-based academic memory repository.

Rules:
- Use only the supplied project context.
- Do not invent papers, decisions, collaborators, or claims.
- Keep the note concise, specific, and written in British English.
- Treat Tier 2 outputs as provisional working memory, not canonical approved memory.
- Prefer surfacing updates, tensions, and next actions over restating the whole project.
- If the supplied context does not support a strong new synthesis, say so plainly and keep the note modest.
- Return valid JSON that matches the schema exactly.
'@

    if (-not [string]::IsNullOrWhiteSpace($AgentTemplateText)) {
        $developerInstructions += "`n`nAgent mode: $AgentModeLabel (`$AgentModeValue = $AgentModeValue)`n`n$AgentTemplateText"
    }
    else {
        $developerInstructions += "`n`nAgent mode: $AgentModeLabel"
    }

    $userPrompt = @"
Project: $ProjectName
Run mode: $RunModeValue
Agent mode: $AgentModeLabel
Task prompt: $Prompt

Produce a Tier 2 working note with:
- a short title
- 2 to 4 summary bullets
- concise key updates
- concise open loops
- concise next actions
- explicit evidence references using file names or note labels from the provided context
- guardrails that prevent overclaiming

Project context follows.

$ContextText
"@

    $body = @{
        model = $model
        reasoning = @{
            effort = $reasoningEffort
        }
        input = @(
            @{
                role = "developer"
                content = @(
                    @{
                        type = "input_text"
                        text = $developerInstructions
                    }
                )
            },
            @{
                role = "user"
                content = @(
                    @{
                        type = "input_text"
                        text = $userPrompt
                    }
                )
            }
        )
        text = @{
            format = @{
                type = "json_schema"
                name = "tier2_cloud_note"
                strict = $true
                schema = $schema
            }
        }
    }

    $jsonBody = $body | ConvertTo-Json -Depth 20

    $headers = @{
        Authorization = "Bearer $apiKey"
        "Content-Type" = "application/json"
    }

    $response = Invoke-RestMethod `
        -Method Post `
        -Uri "https://api.openai.com/v1/responses" `
        -Headers $headers `
        -Body $jsonBody

    $outputText = Get-ResponseOutputText -Response $response
    $parsed = $outputText | ConvertFrom-Json

    return @{
        Parsed = $parsed
        Model = $model
        ReasoningEffort = $reasoningEffort
        ResponseId = $response.id
    }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$projectRoot = Join-Path $repoRoot "workspace\projects\$Project"
$resolvedAgentMode = Resolve-AgentMode -Value $AgentMode
$agentModeLabel = Get-AgentModeLabel -Mode $resolvedAgentMode
$agentTemplateText = Get-AgentPromptTemplateText -RepoRoot $repoRoot -Mode $resolvedAgentMode

if (-not (Test-Path -LiteralPath $projectRoot)) {
    throw "Project '$Project' not found at '$projectRoot'."
}

$autoDir = Join-Path $projectRoot "auto"
$logsPath = Join-Path $projectRoot "logs\activity.md"
$sourceIndexPath = Join-Path $autoDir "index.md"
$lanePolicyPath = Resolve-LanePolicyPath -AutoDirectory $autoDir
$memoryPath = Join-Path $projectRoot "memory.md"
$projectPath = Join-Path $projectRoot "project.md"
$approvedIndexPath = Join-Path $projectRoot "approved\index.md"

if ([string]::IsNullOrWhiteSpace($lanePolicyPath) -or -not (Test-Path -LiteralPath $lanePolicyPath)) {
    throw "Tier 2 lane policy missing for '$Project'. Expected an autonomous-lane-policy note in '$autoDir'."
}

$timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
$dateStamp = Get-Date -Format "yyyy-MM-dd"
$latestAutoNotes = Get-ChildItem -LiteralPath $autoDir -Filter *.md |
    Where-Object {
        $_.FullName -ne $lanePolicyPath -and
        $_.Name -ne "index.md" -and
        $_.Name -notlike "*cloud-maintenance-run.md"
    } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 3

$contextBlocks = @(
    (Get-TrimmedFileBlock -Path $memoryPath -Label "Project Snapshot"),
    (Get-TrimmedFileBlock -Path $projectPath -Label "Project Structure"),
    (Get-TrimmedFileBlock -Path $approvedIndexPath -Label "Approved Index"),
    (Get-TrimmedFileBlock -Path $sourceIndexPath -Label "Autonomous Source Index"),
    (Get-TrimmedFileBlock -Path $logsPath -Label "Activity Log" -MaxChars 4000),
    (Get-TrimmedFileBlock -Path $lanePolicyPath -Label "Autonomous Lane Policy" -MaxChars 2500)
)

foreach ($autoNote in $latestAutoNotes) {
    $contextBlocks += Get-TrimmedFileBlock -Path $autoNote.FullName -Label ("Recent Tier 2 Note: " + $autoNote.Name) -MaxChars 5000
}

$contextText = ($contextBlocks -join "`n`n")

if ($SkipModelCall) {
    $synthesis = @{
        Parsed = [pscustomobject]@{
            note_title = "Cloud Maintenance Dry Run"
            summary = @(
                "This is a dry-run note used to validate the Tier 2 cloud-maintenance script locally.",
                "No live OpenAI API call was made in this run."
            )
            key_updates = @(
                "The script successfully assembled bounded local project context for a future cloud synthesis request.",
                "The runner is ready to write a structured Tier 2 note, update the autonomous index, and append the activity log."
            )
            open_loops = @(
                "A live run still depends on `OPENAI_API_KEY` being configured in GitHub Actions secrets.",
                "Model and reasoning defaults may need tuning after the first few real runs."
            )
            next_actions = @(
                "Add `OPENAI_API_KEY` as a GitHub Actions secret.",
                "Trigger the workflow manually and inspect the first PR."
            )
            evidence_used = @(
                "memory.md",
                "project.md",
                "approved/index.md",
                "auto/index.md",
                "logs/activity.md"
            )
            guardrails = @(
                "Dry-run output is only a local validation artefact.",
                "Tier 2 outputs remain provisional until reviewed."
            )
        }
        Model = "dry-run"
        ReasoningEffort = "none"
        ResponseId = "dry-run"
    }
}
else {
    $synthesis = Invoke-OpenAISynthesis `
        -ProjectName $Project `
        -Prompt $TaskPrompt `
        -ContextText $contextText `
        -RunModeValue $RunMode `
        -AgentModeValue $resolvedAgentMode `
        -AgentModeLabel $agentModeLabel `
        -AgentTemplateText $agentTemplateText
}

$noteSlug = Convert-ToSlug -Value ([string]$synthesis.Parsed.note_title)
$noteName = "$timestamp-$noteSlug.md"
$notePath = Join-Path $autoDir $noteName
$relativeNotePath = "./$noteName"

$summaryLines = if ($synthesis.Parsed.summary.Count -gt 0) {
    ($synthesis.Parsed.summary | ForEach-Object { "- $_" }) -join "`n"
} else {
    "- No summary bullets returned."
}

$keyUpdateLines = if ($synthesis.Parsed.key_updates.Count -gt 0) {
    ($synthesis.Parsed.key_updates | ForEach-Object { "- $_" }) -join "`n"
} else {
    "- No key updates returned."
}

$openLoopLines = if ($synthesis.Parsed.open_loops.Count -gt 0) {
    ($synthesis.Parsed.open_loops | ForEach-Object { "- $_" }) -join "`n"
} else {
    "- No open loops returned."
}

$nextActionLines = if ($synthesis.Parsed.next_actions.Count -gt 0) {
    ($synthesis.Parsed.next_actions | ForEach-Object { "- $_" }) -join "`n"
} else {
    "- No next actions returned."
}

$evidenceLines = if ($synthesis.Parsed.evidence_used.Count -gt 0) {
    ($synthesis.Parsed.evidence_used | ForEach-Object { "- $_" }) -join "`n"
} else {
    "- No evidence lines returned."
}

$guardrailLines = if ($synthesis.Parsed.guardrails.Count -gt 0) {
    ($synthesis.Parsed.guardrails | ForEach-Object { "- $_" }) -join "`n"
} else {
    "- No guardrails returned."
}

$note = @'
# {0}

- Date: {1}
- Timestamp: {2}
- Project: {3}
- Run mode: {4}
- Agent mode: {5}
- Model: {6}
- Reasoning effort: {7}
- Response ID: {8}
- Status: Tier 2 cloud synthesis note

## Requested Task

{9}

## Summary

{10}

## Key Updates

{11}

## Open Loops

{12}

## Next Actions

{13}

## Evidence Used

{14}

## Guardrails

{15}
'@ -f `
    $synthesis.Parsed.note_title,
    $dateStamp,
    $timestamp,
    $Project,
    $RunMode,
    $agentModeLabel,
    $synthesis.Model,
    $synthesis.ReasoningEffort,
    $synthesis.ResponseId,
    $TaskPrompt,
    $summaryLines,
    $keyUpdateLines,
    $openLoopLines,
    $nextActionLines,
    $evidenceLines,
    $guardrailLines

Set-Content -LiteralPath $notePath -Value $note

$indexLine = "- [{0}]({1})" -f $synthesis.Parsed.note_title, $relativeNotePath
Add-LineIfMissing -Path $sourceIndexPath -Line $indexLine

$logLine = "- {0}: Recorded a cloud-triggered Tier 2 synthesis run for `{1}` in `{2}` mode using model `{3}` with note `{4}`." -f $dateStamp, $Project, $agentModeLabel, $synthesis.Model, $synthesis.Parsed.note_title
Add-LineIfMissing -Path $logsPath -Line $logLine

Write-Host "Created $notePath"
Write-Host "Updated $sourceIndexPath"
Write-Host "Updated $logsPath"
