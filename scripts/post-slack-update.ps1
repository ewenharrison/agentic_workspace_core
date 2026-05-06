param(
    [Parameter(Mandatory = $true)]
    [string]$Project,

    [string]$File = "",

    [string]$Title = "",

    [string]$Target = "default"
)

$ErrorActionPreference = "Stop"

function Get-WebhookUrl {
    param([string]$Target)

    $configPath = Join-Path $PSScriptRoot "..\config\slack-webhook-url.txt"
    $multiConfigPath = Join-Path $PSScriptRoot "..\config\slack-webhooks.json"

    if ($env:SLACK_WEBHOOK_URL -and $Target -eq "default") {
        return $env:SLACK_WEBHOOK_URL
    }

    if (Test-Path $multiConfigPath) {
        $config = Get-Content $multiConfigPath -Raw | ConvertFrom-Json
        $targetConfig = $config.PSObject.Properties[$Target]
        if ($null -ne $targetConfig) {
            $value = [string]$targetConfig.Value
            if ($value.Trim()) {
                return $value.Trim()
            }
        }
    }

    if (Test-Path $configPath -and $Target -eq "default") {
        $value = (Get-Content $configPath -Raw).Trim()
        if ($value) {
            return $value
        }
    }

    throw "No Slack webhook URL found for target '$Target'. Use config/slack-webhooks.json, or for the default target set SLACK_WEBHOOK_URL or create config/slack-webhook-url.txt."
}

function Get-DefaultFile {
    param([string]$Project)

    $candidate = Join-Path $PSScriptRoot "..\workspace\projects\$Project\collab\slack-update.md"
    if (Test-Path $candidate) {
        return $candidate
    }

    throw "No default update file found for project '$Project'. Expected $candidate"
}

function Convert-MarkdownToSlackMrkdwn {
    param([string]$Markdown)

    $text = $Markdown.Trim()
    $text = $text -replace '\r\n', "`n"
    $text = $text -replace '\[([^\]]+)\]\(([^)]+)\)', '<$2|$1>'
    $text = $text -replace '```', '```'
    $text = [regex]::Replace($text, '^(#)\s+(.+)$', '*$2*', 'Multiline')
    $text = [regex]::Replace($text, '^(##)\s+(.+)$', '*$2*', 'Multiline')
    $text = [regex]::Replace($text, '^(###)\s+(.+)$', '*$2*', 'Multiline')
    return $text
}

$webhookUrl = Get-WebhookUrl -Target $Target
$resolvedFile = if ($File) { $File } else { Get-DefaultFile -Project $Project }

if (-not (Test-Path $resolvedFile)) {
    throw "Update file not found: $resolvedFile"
}

$rawMarkdown = Get-Content $resolvedFile -Raw
$slackText = Convert-MarkdownToSlackMrkdwn -Markdown $rawMarkdown
$messageTitle = if ($Title) { $Title } else { "Project update: $Project" }
$fallbackText = "$messageTitle`n`n$($rawMarkdown.Trim())"

$payload = @{
    text = $fallbackText
    blocks = @(
        @{
            type = "header"
            text = @{
                type = "plain_text"
                text = $messageTitle
                emoji = $true
            }
        },
        @{
            type = "section"
            text = @{
                type = "mrkdwn"
                text = $slackText
            }
        }
    )
} | ConvertTo-Json -Depth 8

try {
    $response = Invoke-RestMethod -Method Post -ContentType "application/json" -Body $payload -Uri $webhookUrl
    Write-Output "Posted Slack update for '$Project' from '$resolvedFile' using target '$Target'."
    if ($null -ne $response) {
        Write-Output ($response | ConvertTo-Json -Depth 8 -Compress)
    }
} catch {
    Write-Error "Slack post failed: $($_.Exception.Message)"
    throw
}
