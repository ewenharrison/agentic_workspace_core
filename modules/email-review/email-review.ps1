#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('setup', 'doctor', 'demo', 'scan', 'complete', 'run', 'enable-api', 'schedule', 'status', 'disable', 'uninstall')]
    [string]$Command = 'status',
    [string]$WorkspaceRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$Mailbox = '',
    [string[]]$Projects = @(),
    [string]$Model = '',
    [string]$ReviewPath = '',
    [ValidatePattern('^([01][0-9]|2[0-3]):[0-5][0-9]$')]
    [string]$Time = '08:00',
    [switch]$AcceptApiTransfer
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'EmailReview.psm1') -Force -DisableNameChecking
. (Join-Path $PSScriptRoot 'Outlook.ps1')
$WorkspaceRoot = (Resolve-Path -LiteralPath $WorkspaceRoot).Path
$runtime = Get-ERRuntime $WorkspaceRoot
$configPath = Join-Path $runtime 'config.json'
$statePath = Join-Path $runtime 'state.json'
$pendingPath = Join-Path $runtime 'pending.json'
$taskName = 'AgenticEmailReview-' + (Get-ERHash $WorkspaceRoot.ToLowerInvariant()).Substring(0, 12)

function Show-Pending($Packet) {
    Write-Host "Packet: $pendingPath"
    Write-Host ('Review template: ' + (Join-Path $runtime 'review.json'))
    Write-Host "Messages: $(@($Packet.Messages).Count); unknown classification: $($Packet.UnknownCount); window exhausted: $($Packet.Exhausted)"
    Write-Host 'Review with your agent using modules/email-review/review-prompt.md, then run complete. Nothing has advanced yet.'
}

if ($Command -eq 'doctor') {
    Write-Host "PowerShell: $($PSVersionTable.PSVersion) / $($PSVersionTable.PSEdition)"
    Write-Host "Workspace: $WorkspaceRoot"
    $mailboxes = @(Get-ERMailboxes)
    $mailboxes | Select-Object Name
    Write-Host 'Classic Outlook access succeeded. No messages read.'
    return
}
if ($Command -eq 'demo') {
    & (Join-Path $PSScriptRoot 'tests\run-tests.ps1') -ShowDemo
    return
}
if ($Command -eq 'status') {
    if (-not (Test-Path -LiteralPath $configPath)) { Write-Host 'Email review is not installed. Run setup.'; return }
    $config = Read-ERJson $configPath
    Write-Host "Enabled: $($config.Enabled); mailbox: $($config.Mailbox); API enabled: $($config.ApiEnabled)"
    Write-Host "Configuration: $configPath"
    Write-Host "Pending batch: $(Test-Path -LiteralPath $pendingPath)"
    if (Test-Path -LiteralPath $statePath) {
        $state = Read-ERJson $statePath
        Write-Host "Last completed window (UTC): $($state.LastCompletedUtc)"
        Write-Host "Last digest: $($state.LastDigest)"
        Write-Host "Unfinished window (UTC): $($state.WindowStartUtc) to $($state.WindowEndUtc)"
    }
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) { Write-Host "Scheduled task: $taskName ($($task.State))" }
    else { Write-Host 'Scheduled task: none' }
    $failure = Join-Path $runtime 'last-error.txt'
    if (Test-Path -LiteralPath $failure) { Write-Host ('Last failure: ' + (Get-Content -LiteralPath $failure -Raw)) }
    return
}

$lock = $null
try {
    $lock = Open-ERLock $runtime
    if ($Command -eq 'setup') {
        if (Test-Path -LiteralPath $configPath) { throw 'Already installed. Edit the reported local configuration; setup never overwrites it.' }
        $mailboxes = @(Get-ERMailboxes)
        if (-not $Mailbox) {
            for ($i = 0; $i -lt $mailboxes.Count; $i++) { Write-Host "$($i + 1). $($mailboxes[$i].Name)" }
            $choice = Read-Host 'Mailbox number'
            $number = 0
            if (-not [int]::TryParse($choice, [ref]$number) -or $number -lt 1 -or $number -gt $mailboxes.Count) { throw 'Invalid mailbox selection.' }
            $selected = $mailboxes[$number - 1]
        }
        else {
            $matches = @($mailboxes | Where-Object { $_.Name -eq $Mailbox })
            if ($matches.Count -ne 1) { throw 'Mailbox name must match exactly one Outlook store.' }
            $selected = $matches[0]
        }
        if (-not $PSBoundParameters.ContainsKey('Projects')) {
            $projectRoot = Join-Path $WorkspaceRoot 'workspace\projects'
            Write-Host 'Available project slugs:'
            Get-ChildItem -LiteralPath $projectRoot -Filter project.md -Recurse -File | ForEach-Object {
                Write-Host ($_.DirectoryName.Substring($projectRoot.Length + 1).Replace('\', '/'))
            }
            $selection = Read-Host 'Comma-separated project slugs (blank = no project context)'
            $Projects = @($selection -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }
        $config = New-ERConfig $selected.StoreId $selected.Name $Projects
        Assert-ERConfig $config
        $null = @(Get-ERProjectBriefs $WorkspaceRoot $config)
        # Local ignore protects private runtime even when the module is copied into another repo.
        [IO.File]::WriteAllText((Join-Path $runtime '.gitignore'), "*`n!.gitignore`n", [Text.UTF8Encoding]::new($false))
        Write-ERJson $configPath $config
        Write-Host "Installed: $configPath"
        Write-Host 'Manual mode ready. Run demo, then scan for a small live review. Outlook stays open. No schedule installed.'
        return
    }

    if (-not (Test-Path -LiteralPath $configPath)) { throw 'Run setup first.' }
    $config = Read-ERJson $configPath
    Assert-ERConfig $config
    if ($Command -in @('disable', 'uninstall')) {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($task) { Unregister-ScheduledTask -TaskName $taskName -Confirm:$false }
        $config.Enabled = $false
        Write-ERJson $configPath $config
        Write-Host "Disabled and removed this workspace's scheduled task. Private data retained: $runtime"
        if ($Command -eq 'uninstall') { Write-Host 'Module is inactive; files retained for recovery. No mailbox or source files deleted.' }
        return
    }
    if ($Command -eq 'enable-api') {
        if (-not $AcceptApiTransfer -or -not $Model) { throw 'Supply -Model and -AcceptApiTransfer. API mode sends email excerpts and selected project briefs to OpenAI; API usage is billed separately.' }
        $null = Get-ERApiKey
        $config.Model = $Model; $config.ApiEnabled = $true
        Write-ERJson $configPath $config
        Write-Host 'API mode configured. No API request made; scheduling is still separate.'
        return
    }
    if ($Command -eq 'schedule') {
        if (-not $config.ApiEnabled -or -not $config.Model) { throw 'Enable API review before scheduling.' }
        if (-not [Environment]::GetEnvironmentVariable('OPENAI_API_KEY', 'User')) { throw 'Scheduled tasks need OPENAI_API_KEY in the Windows user environment, not only this terminal.' }
        if (-not (Test-Path -LiteralPath $statePath) -or -not (Read-ERJson $statePath).LastRunId) { throw 'Complete a live manual review before scheduling.' }
        $scriptPath = Join-Path $PSScriptRoot 'email-review.ps1'
        if ($scriptPath.Contains('"') -or $WorkspaceRoot.Contains('"')) { throw 'Unsupported quote in task path.' }
        $args = '-NoProfile -NonInteractive -Sta -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $scriptPath + '" run -WorkspaceRoot "' + $WorkspaceRoot + '"'
        $action = New-ScheduledTaskAction -Execute (Get-Command powershell.exe).Source -Argument $args -WorkingDirectory $WorkspaceRoot
        $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday,Tuesday,Wednesday,Thursday,Friday -At ([datetime]::ParseExact($Time, 'HH:mm', [Globalization.CultureInfo]::InvariantCulture))
        $principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
        $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 60)
        $config.Enabled = $true
        Write-ERJson $configPath $config
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Local read-only email digest. Requires classic Outlook open in this user session.' -Force | Out-Null
        Write-Host "Scheduled weekdays at $Time (Windows local time): $taskName"
        return
    }
    if (-not $config.Enabled) { throw 'Email review is disabled. Set Enabled to true in the local config to resume manual review.' }
    $state = if (Test-Path -LiteralPath $statePath) { Read-ERJson $statePath } else { New-ERState $config }
    $null = Get-ERWindow $state $config
    $iterations = if ($Command -eq 'run') { $config.MaxBatchesPerRun } else { 1 }
    if ($Command -eq 'run') {
        if (-not $config.ApiEnabled -or -not $config.Model) { throw 'Enable API review first, or use scan for interactive review.' }
        $null = Get-ERApiKey
    }
    for ($batchIndex = 0; $batchIndex -lt $iterations; $batchIndex++) {
        $packet = if (Test-Path -LiteralPath $pendingPath) { Read-ERJson $pendingPath } else { $null }
        # Recover a crash after atomic state commit but before pending-file cleanup.
        if ($packet -and $packet.RunId -eq $state.LastRunId) {
            Remove-Item -LiteralPath $pendingPath
            $packet = $null
            if ($Command -eq 'complete') { Write-Host "Already completed: $($state.LastDigest)"; return }
        }
        if ($Command -eq 'complete' -and -not $packet) { throw 'No pending packet to complete.' }
        if (-not $packet) {
            $briefs = @(Get-ERProjectBriefs $WorkspaceRoot $config)
            $window = Get-ERWindow $state $config
            $batch = Get-EROutlookBatch $state $config $window
            $packet = New-ERPacket $state $config $window $batch $briefs
            Write-ERJson $pendingPath $packet
            Write-ERJson (Join-Path $runtime 'review.json') (New-ERReviewTemplate $packet)
        }
        if ($Command -eq 'scan') { Show-Pending $packet; return }
        if ($packet.StateHash -ne (Get-ERHash ($state | ConvertTo-Json -Depth 10 -Compress))) { throw 'Pending packet is stale. Check state before proceeding.' }
        if ($Command -eq 'complete') {
            if (-not $ReviewPath) { $ReviewPath = Join-Path $runtime 'review.json' }
            $review = Read-ERJson $ReviewPath
        }
        else {
            $packetSlugs = @($packet.Projects | ForEach-Object { $_.Slug })
            foreach ($slug in $packetSlugs) { if ($slug -cnotin @($config.Projects)) { throw 'Pending packet includes a project removed from configuration. Finish it interactively before API review.' } }
            $review = if (@($packet.Messages).Count -eq 0) { New-ERReviewTemplate $packet } else { Invoke-ERApi $config $packet }
            Write-ERJson (Join-Path $runtime 'review.json') $review
        }
        $state = Complete-ERPacket $runtime $state $packet $review
        Remove-Item -LiteralPath $pendingPath
        Write-Host "Digest: $($state.LastDigest)"
        if (Test-Path -LiteralPath (Join-Path $runtime 'last-error.txt')) { Remove-Item -LiteralPath (Join-Path $runtime 'last-error.txt') }
        if ($packet.Exhausted) { Write-Host 'Window complete.'; break }
        Write-Host 'Batch complete; the window remains open for the next batch.'
    }
}
catch {
    if ($null -ne $lock) { [IO.File]::WriteAllText((Join-Path $runtime 'last-error.txt'), ([datetime]::UtcNow.ToString('o') + ' ' + $_.Exception.Message)) }
    throw
}
finally { if ($null -ne $lock) { $lock.Dispose() } }
