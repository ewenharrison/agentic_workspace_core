#Requires -Version 5.1
param([switch]$ShowDemo)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path (Split-Path -Parent $PSScriptRoot) 'EmailReview.psm1') -Force -DisableNameChecking
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('email-review-test-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($testRoot)
$passed = 0
function Assert($Condition, [string]$Name) {
    if (-not $Condition) { throw "FAIL: $Name" }
    $script:passed++
    Write-Host "PASS: $Name"
}
function Assert-Throws([scriptblock]$Action, [string]$Name) {
    $thrown = $false
    try { & $Action | Out-Null } catch { $thrown = $true }
    Assert $thrown $Name
}
function New-Message([string]$Id, [string]$Classification = 'focused', [string]$Received = '2026-01-02T10:00:00Z') {
    return [pscustomobject]@{ Id = $Id; Classification = $Classification; IsMail = $true; ReceivedUtc = $Received; Sender = 'Example colleague'; To = 'Example mailbox'; Cc = ''; Subject = 'Sample project meeting'; Body = 'Please comment on the project agenda.' }
}
function Read-Batch($Records, $State, $Config, $Window) {
    $reader = { param($index) return $Records[$index - 1] }.GetNewClosure()
    $body = { param($index) return $Records[$index - 1].Body }.GetNewClosure()
    return Get-ERBatch $State $Config $Window @($Records).Count $reader $body
}
function Valid-Review($Packet) {
    $review = New-ERReviewTemplate $Packet
    foreach ($item in $review.Items) { $item.Summary = 'Reviewed synthetic meeting request.'; $item.Priority = 'watch' }
    return $review
}
try {
    $config = New-ERConfig 'synthetic-store' 'Example mailbox'
    Assert-ERConfig $config
    Assert (-not $config.ApiEnabled) 'manual mode by default'
    $state = New-ERState $config
    $window = Get-ERWindow $state $config ([datetimeoffset]'2026-01-03T12:00:00Z')
    Assert (($window.End - $window.Start).TotalDays -eq 7) 'first scan uses seven days'
    $config.MaxMessages = 2
    $records = @(New-Message 'A'; New-Message 'B'; New-Message 'C'; New-Message 'D'; New-Message 'E')
    $batch = Read-Batch $records $state $config $window
    Assert (@($batch.Messages).Count -eq 2 -and -not $batch.Exhausted) 'cap produces partial batch'
    $packet = New-ERPacket $state $config $window $batch
    Assert-Throws { Complete-ERPacket $testRoot $state $packet (New-ERReviewTemplate $packet) } 'scaffold cannot advance state'
    Assert (-not (Test-Path (Join-Path $testRoot 'state.json'))) 'failed review leaves checkpoint absent'
    $review = Valid-Review $packet
    $bad = $review | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    $bad.Items[1].Id = 'A'
    Assert-Throws { Assert-ERReview $packet $bad } 'duplicate coverage rejected'
    $bad.Items = @($bad.Items[0])
    Assert-Throws { Assert-ERReview $packet $bad } 'missing coverage rejected'
    $bad = Valid-Review $packet
    $bad.Items[0].Project = 'not-selected'
    Assert-Throws { Assert-ERReview $packet $bad } 'invented project rejected'
    $bad = Valid-Review $packet
    $bad.RunId = 'another-run'
    Assert-Throws { Assert-ERReview $packet $bad } 'wrong run rejected'
    $state = Complete-ERPacket $testRoot $state $packet $review
    Assert (-not $state.LastCompletedUtc -and $state.WindowEndUtc) 'partial review retains frozen window'
    Assert (Test-Path -LiteralPath $state.LastDigest) 'digest exists before checkpoint'
    Assert-Throws { Complete-ERPacket $testRoot $state $packet $review } 'stale packet replay rejected'
    $window2 = Get-ERWindow $state $config ([datetimeoffset]'2026-01-04T12:00:00Z')
    Assert ($window2.End -eq $window.End) 'resume retains original upper bound'
    $reviewed = @('A', 'B')
    for ($i = 0; $i -lt 4 -and $state.WindowEndUtc; $i++) {
        $batch = Read-Batch $records $state $config $window2
        $reviewed += @($batch.Messages | ForEach-Object { $_.Id })
        $packet = New-ERPacket $state $config $window2 $batch
        $state = Complete-ERPacket $testRoot $state $packet (Valid-Review $packet)
    }
    Assert (($reviewed -join ',') -eq 'A,B,C,D,E') 'all same-timestamp messages reviewed exactly once across caps'
    Assert ($state.LastCompletedUtc -eq $window.End.ToString('o') -and -not $state.WindowEndUtc) 'only full traversal advances completed window'
    $state = New-ERState $config
    $config.MaxScanItems = 1
    $batch = Read-Batch @(New-Message 'other' 'other'; New-Message 'wanted') $state $config $window
    Assert (@($batch.Messages).Count -eq 0 -and -not $batch.Exhausted) 'inspection cap before relevant mail remains partial'
    $packet = New-ERPacket $state $config $window $batch
    $state = Complete-ERPacket $testRoot $state $packet (Valid-Review $packet)
    $batch = Read-Batch @(New-Message 'other' 'other'; New-Message 'wanted') $state $config $window
    Assert ($batch.Messages[0].Id -eq 'wanted') 'filtered messages do not trap subsequent batches'
    $config.MaxScanItems = 200
    $state = New-ERState $config
    $batch = Read-Batch @(New-Message 'unknown' 'unknown') $state $config $window
    Assert ($batch.UnknownCount -eq 1 -and @($batch.Messages).Count -eq 1) 'unknown classification exposed and included by default'
    $config.UnknownClassification = 'exclude'
    $state = New-ERState $config
    $batch = Read-Batch @(New-Message 'unknown' 'unknown') $state $config $window
    Assert ($batch.UnknownCount -eq 1 -and @($batch.Messages).Count -eq 0) 'unknown classification exclusion respected'
    $config.UnknownClassification = 'include'
    $state = New-ERState $config
    $batch = Read-Batch @(New-Message 'future' 'focused' '2026-01-03T12:00:00Z') $state $config $window
    Assert (@($batch.ExaminedIds).Count -eq 0) 'exclusive upper-bound message not marked processed'
    $state.LastCompletedUtc = '2026-01-03T12:00:00Z'
    $state.RecentIds = @('overlap')
    $overlapWindow = Get-ERWindow $state $config ([datetimeoffset]'2026-01-03T12:00:30Z')
    $batch = Read-Batch @(New-Message 'overlap' 'focused' '2026-01-03T11:59:30Z'; New-Message 'late' 'focused' '2026-01-03T11:59:45Z') $state $config $overlapWindow
    Assert (@($batch.Messages).Count -eq 1 -and $batch.Messages[0].Id -eq 'late') 'overlap deduplicates known mail and includes late arrival'
    $packet = New-ERPacket $state $config $overlapWindow $batch
    $state = Complete-ERPacket $testRoot $state $packet (Valid-Review $packet)
    Assert ('overlap' -cin $state.RecentIds) 'dedupe history survives repeated short scans'
    $different = New-ERConfig 'different-store' 'Different mailbox'
    Assert-Throws { Get-ERWindow $state $different } 'checkpoint bound to mailbox'
    $different = New-ERConfig 'synthetic-store' 'Example mailbox'
    $different.Scope = 'all'
    Assert-Throws { Get-ERWindow $state $different } 'scope changes cannot silently reuse history'
    $lock = Open-ERLock $testRoot
    Assert-Throws { Open-ERLock $testRoot } 'concurrent run rejected'
    $lock.Dispose()
    $lock = Open-ERLock $testRoot
    $lock.Dispose()
    Assert $true 'persistent lock file reusable after release'
    $empty = New-ERState $config
    $emptyBatch = Read-Batch @() $empty $config $window
    Assert ($emptyBatch.Exhausted -and @($emptyBatch.Messages).Count -eq 0) 'empty window completes without model call'
    $readerFailure = { param($index) throw 'Simulated item access failure' }
    Assert-Throws { Get-ERBatch $empty $config $window 1 $readerFailure { '' } } 'collection failure cannot create partial-success packet'
    $config.Projects = @('../private')
    Assert-Throws { Get-ERProjectBriefs $testRoot $config } 'project path traversal rejected'
    $config.Projects = @()
    Assert (@(Get-ERProjectBriefs $testRoot $config).Count -eq 0) 'empty allowlist loads no project context'
    $packet = New-ERPacket $empty $config $window $emptyBatch
    Assert-Throws { New-ERApiRequest $config $packet } 'API requires explicit enablement'
    $config.ApiEnabled = $true; $config.Model = 'example-model'
    $request = New-ERApiRequest $config $packet
    Assert (-not $request.store -and $request.text.format.strict) 'API request uses nonstored structured response'
    Assert (-not $request.ContainsKey('tools')) 'model receives no action tools'
    Assert ($request.instructions -match 'untrusted DATA') 'mail prompt injection boundary explicit'
    $requestText = $request.input
    Assert ($requestText -notmatch 'StoreId|AccountKey|StateHash|ExaminedIds') 'API payload excludes local account and checkpoint data'
    Assert ((ConvertTo-ERPlainMarkdown '<script>[click](url)') -notmatch '[<>\[\]]') 'rendered text cannot inject HTML or markdown links'
    $config.BodyChars = 4
    $bodyBatch = Read-Batch @(New-Message 'body-limit') $empty $config $window
    Assert ($bodyBatch.Messages[0].Body.Length -eq 4 -and $bodyBatch.Messages[0].BodyTruncated) 'message excerpts bounded and truncation recorded'
    $config.BodyChars = 0
    $bodyBatch = Get-ERBatch $empty $config $window 1 { param($i) New-Message 'headers-only' } { throw 'Body must not be read' }
    Assert ($bodyBatch.Messages[0].Body -eq '') 'headers-only mode never reads body'
    $invalid = New-ERConfig 'store' 'mailbox'
    $invalid.MaxMessages = 0
    Assert-Throws { Assert-ERConfig $invalid } 'invalid batch limits rejected'
    $blockedRuntime = Join-Path $testRoot 'blocked-digest'
    [void][IO.Directory]::CreateDirectory($blockedRuntime)
    [IO.File]::WriteAllText((Join-Path $blockedRuntime 'working'), 'Blocks output directory')
    Assert-Throws { Complete-ERPacket $blockedRuntime $empty $packet (Valid-Review $packet) } 'digest write failure blocks state commit'
    Assert (-not (Test-Path (Join-Path $blockedRuntime 'state.json'))) 'no checkpoint after digest write failure'
    $commandRoot = Join-Path $testRoot 'command-workspace'
    $runtime = Get-ERRuntime $commandRoot
    [void][IO.Directory]::CreateDirectory($runtime)
    $commandConfig = New-ERConfig 'synthetic-store' 'Example mailbox'
    $commandState = New-ERState $commandConfig
    $commandBatch = Read-Batch @(New-Message 'command-example') $commandState $commandConfig $window
    $commandPacket = New-ERPacket $commandState $commandConfig $window $commandBatch
    Write-ERJson (Join-Path $runtime 'config.json') $commandConfig
    Write-ERJson (Join-Path $runtime 'pending.json') $commandPacket
    Write-ERJson (Join-Path $runtime 'review.json') (Valid-Review $commandPacket)
    $cli = Join-Path (Split-Path -Parent $PSScriptRoot) 'email-review.ps1'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $cli complete -WorkspaceRoot $commandRoot
    Assert ($LASTEXITCODE -eq 0) 'complete command works end to end without Outlook'
    Assert (-not (Test-Path (Join-Path $runtime 'pending.json'))) 'successful complete removes pending packet'
    $committed = Read-ERJson (Join-Path $runtime 'state.json')
    Assert ($committed.LastRunId -eq $commandPacket.RunId) 'complete commits matching run'
    Write-ERJson (Join-Path $runtime 'pending.json') $commandPacket
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $cli complete -WorkspaceRoot $commandRoot
    Assert ($LASTEXITCODE -eq 0 -and -not (Test-Path (Join-Path $runtime 'pending.json'))) 'restart cleans pending file after committed checkpoint'
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'Outlook.ps1')
    $property = [pscustomobject]@{}
    $property | Add-Member ScriptMethod GetProperty { param($name) return 0 }
    $fakeMail = [pscustomobject]@{
        Class = 43; EntryID = 'synthetic-entry'; ReceivedTime = ([datetimeoffset]'2026-01-02T10:00:00Z').LocalDateTime
        SenderName = 'Synthetic sender'; Subject = 'Synthetic subject'; To = 'Example mailbox'; CC = ''
        Body = 'Synthetic body'; PropertyAccessor = $property
    }
    $fakeItems = [pscustomobject]@{ Count = 1; Records = @($fakeMail) }
    $fakeItems | Add-Member ScriptMethod Item { param($index) return $this.Records[$index - 1] }
    $fakeItems | Add-Member ScriptMethod Restrict { param($filter) return $this }
    $fakeItems | Add-Member ScriptMethod Sort { param($field, $descending) }
    $fakeStore = [pscustomobject]@{ StoreID = 'synthetic-store'; DisplayName = 'Example mailbox'; Inbox = [pscustomobject]@{ Items = $fakeItems } }
    $fakeStore | Add-Member ScriptMethod GetDefaultFolder { param($number) if ($number -ne 6) { throw 'Only inbox allowed' }; return $this.Inbox }
    $fakeStores = [pscustomobject]@{ Count = 1; Records = @($fakeStore) }
    $fakeStores | Add-Member ScriptMethod Item { param($index) return $this.Records[$index - 1] }
    $fakeSession = [pscustomobject]@{ Stores = $fakeStores; Mail = $fakeMail }
    $fakeSession | Add-Member ScriptMethod GetItemFromID { param($id, $store) return $this.Mail }
    $script:fakeOutlook = [pscustomobject]@{ Session = $fakeSession }
    function Get-EROutlook { return $script:fakeOutlook }
    $outlookBatch = Get-EROutlookBatch $commandState $commandConfig $window
    Assert (@($outlookBatch.Messages).Count -eq 1 -and $outlookBatch.Messages[0].Body -eq 'Synthetic body') 'Outlook adapter works against fake object model'
    $fakeMail.PropertyAccessor = [pscustomobject]@{}
    $outlookBatch = Get-EROutlookBatch $commandState $commandConfig $window
    Assert ($outlookBatch.UnknownCount -eq 1) 'Outlook adapter reports missing classification'
    $wrongMailbox = New-ERConfig 'unavailable-store' 'Missing'
    Assert-Throws { Get-EROutlookBatch (New-ERState $wrongMailbox) $wrongMailbox $window } 'Outlook adapter never falls back to a different store'
    foreach ($file in Get-ChildItem -LiteralPath (Split-Path -Parent $PSScriptRoot) -Recurse -File | Where-Object { $_.Extension -in @('.ps1', '.psm1') }) {
        $tokens = $null; $errors = $null
        [void][Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors)
        Assert ($errors.Count -eq 0) ('PowerShell syntax: ' + $file.Name)
    }
    $collector = Get-Content (Join-Path (Split-Path -Parent $PSScriptRoot) 'Outlook.ps1') -Raw
    Assert ($collector -notmatch '\.(Send|Save|Move|Delete|Quit|Display|CreateItem)\(' -and $collector -notmatch '\.UnRead\s*=') 'collector contains no mailbox mutation or application shutdown calls'
    if ($ShowDemo) {
        $sample = Read-Batch @(New-Message 'demo-message') $empty $config $window
        $demo = New-ERPacket $empty $config $window $sample
        Write-Host (ConvertTo-ERDigest $demo (Valid-Review $demo))
    }
    Write-Host "$passed checks passed. No mailbox, network, API key, or scheduled task was used."
}
finally {
    $resolved = [IO.Path]::GetFullPath($testRoot)
    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($resolved.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path $resolved -Leaf) -like 'email-review-test-*') {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
