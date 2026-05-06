param(
    [Parameter(Mandatory = $true)]
    [string]$File,

    [string]$Target = "default",

    [string]$Title = "",

    [int]$ChunkSize = 3500
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

function Split-TextIntoChunks {
    param(
        [string]$Text,
        [int]$MaxLength
    )

    $normalized = $Text -replace "\r\n", "`n"
    $lines = $normalized -split "`n"
    $chunks = New-Object System.Collections.Generic.List[string]
    $current = ""

    foreach ($line in $lines) {
        $candidate = if ([string]::IsNullOrEmpty($current)) { $line } else { $current + "`n" + $line }
        if ($candidate.Length -le $MaxLength) {
            $current = $candidate
            continue
        }

        if (-not [string]::IsNullOrEmpty($current)) {
            $chunks.Add($current)
            $current = ""
        }

        if ($line.Length -le $MaxLength) {
            $current = $line
            continue
        }

        $start = 0
        while ($start -lt $line.Length) {
            $length = [Math]::Min($MaxLength, $line.Length - $start)
            $chunks.Add($line.Substring($start, $length))
            $start += $length
        }
    }

    if (-not [string]::IsNullOrEmpty($current)) {
        $chunks.Add($current)
    }

    return $chunks
}

if (-not (Test-Path $File)) {
    throw "File not found: $File"
}

if ($ChunkSize -lt 500) {
    throw "ChunkSize must be at least 500 characters."
}

$webhookUrl = Get-WebhookUrl -Target $Target
$resolvedFile = (Resolve-Path $File).Path
$rawText = Get-Content $resolvedFile -Raw
$fence = [string]([char]96) * 3
$fileName = Split-Path $resolvedFile -Leaf
$baseTitle = if ($Title) { $Title } else { $fileName }
$chunks = Split-TextIntoChunks -Text $rawText -MaxLength $ChunkSize
$totalChunks = $chunks.Count

for ($i = 0; $i -lt $totalChunks; $i++) {
    $partNumber = $i + 1
    $messageTitle = if ($totalChunks -gt 1) {
        "$baseTitle ($partNumber/$totalChunks)"
    } else {
        $baseTitle
    }

    $messageText = $messageTitle + "`n" + $fence + "`n" + $chunks[$i] + "`n" + $fence
    $payload = @{
        text = $messageText
    } | ConvertTo-Json -Depth 4

    try {
        $response = Invoke-RestMethod -Method Post -ContentType "application/json" -Body $payload -Uri $webhookUrl
        Write-Output "Posted Slack file chunk $partNumber/$totalChunks from '$resolvedFile' using target '$Target'."
        if ($null -ne $response) {
            Write-Output ($response | ConvertTo-Json -Depth 8 -Compress)
        }
    } catch {
        Write-Error "Slack file post failed on chunk ${partNumber}/${totalChunks}: $($_.Exception.Message)"
        throw
    }

    if ($partNumber -lt $totalChunks) {
        Start-Sleep -Milliseconds 400
    }
}
