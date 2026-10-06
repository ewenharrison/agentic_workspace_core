function Get-EROutlook {
    if ($PSVersionTable.PSEdition -ne 'Desktop') { throw 'Use Windows PowerShell 5.1 (powershell.exe), not pwsh. Classic Outlook is required.' }
    try { return [Runtime.InteropServices.Marshal]::GetActiveObject('Outlook.Application') }
    catch { throw 'Open classic Outlook, unlock/sign in to your Windows session, then retry. New Outlook is unsupported. Run host-side with agent approval when sandboxed.' }
}

function Close-ERCom($Object) {
    if ($null -ne $Object -and [Runtime.InteropServices.Marshal]::IsComObject($Object)) {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($Object)
    }
}

function Get-ERMailboxes {
    $outlook = $session = $stores = $null
    try {
        $outlook = Get-EROutlook
        $session = $outlook.Session
        $stores = $session.Stores
        for ($i = 1; $i -le $stores.Count; $i++) {
            $store = $null
            try {
                $store = $stores.Item($i)
                [pscustomobject]@{ Name = [string]$store.DisplayName; StoreId = [string]$store.StoreID }
            }
            finally { Close-ERCom $store }
        }
    }
    finally { Close-ERCom $stores; Close-ERCom $session; Close-ERCom $outlook }
}

function Get-EROutlookBatch($State, $Config, $Window) {
    $outlook = $session = $stores = $store = $inbox = $allItems = $items = $null
    try {
        $outlook = Get-EROutlook
        $session = $outlook.Session
        $stores = $session.Stores
        for ($i = 1; $i -le $stores.Count; $i++) {
            $candidate = $stores.Item($i)
            if ([string]$candidate.StoreID -ceq $Config.StoreId) { $store = $candidate; break }
            Close-ERCom $candidate
        }
        if ($null -eq $store) { throw 'Configured mailbox is not available in this Outlook profile. No fallback mailbox was selected.' }
        $inbox = $store.GetDefaultFolder(6)
        $allItems = $inbox.Items
        # Outlook date filters have locale/minute precision. Apply exact UTC bounds again below.
        $start = $Window.Start.LocalDateTime.AddMinutes(-1).ToString('g').Replace("'", "''")
        $end = $Window.End.LocalDateTime.AddMinutes(1).ToString('g').Replace("'", "''")
        $items = $allItems.Restrict("[ReceivedTime] >= '$start' AND [ReceivedTime] <= '$end'")
        $items.Sort('[ReceivedTime]', $false)
        $entryIds = @{}
        $readItem = {
            param($index)
            $mail = $property = $null
            try {
                $mail = $items.Item($index)
                $entry = [string]$mail.EntryID
                $id = Get-ERHash $entry
                $entryIds[$index] = $entry
                if ($mail.Class -ne 43) { return [pscustomobject]@{ Id = $id; IsMail = $false } }
                $classification = 'unknown'
                try {
                    $property = $mail.PropertyAccessor
                    $value = $property.GetProperty('http://schemas.microsoft.com/mapi/proptag/0x12130003')
                    if ($value -eq 1) { $classification = 'other' }
                    elseif ($value -eq 0) { $classification = 'focused' }
                }
                catch { $classification = 'unknown' }
                return [pscustomobject]@{
                    Id = $id; IsMail = $true
                    ReceivedUtc = ([datetimeoffset]([datetime]$mail.ReceivedTime)).ToUniversalTime().ToString('o')
                    Sender = [string]$mail.SenderName; Subject = [string]$mail.Subject
                    To = [string]$mail.To; Cc = [string]$mail.CC
                    Classification = $classification
                }
            }
            finally { Close-ERCom $property; Close-ERCom $mail }
        }
        $readBody = {
            param($index)
            $mail = $null
            try {
                $mail = $session.GetItemFromID($entryIds[$index], $Config.StoreId)
                return [string]$mail.Body
            }
            finally { Close-ERCom $mail }
        }
        return Get-ERBatch $State $Config $Window $items.Count $readItem $readBody
    }
    finally {
        Close-ERCom $items; Close-ERCom $allItems; Close-ERCom $inbox
        Close-ERCom $store; Close-ERCom $stores; Close-ERCom $session; Close-ERCom $outlook
    }
}
