# Query-SecurityLogs.ps1
# Run this on DC01 as Administrator.

$hoursBack = 24
$startTime = (Get-Date).AddHours(-$hoursBack)

# Security events we care about in this lab
$eventNames = @{
    4624 = "Successful logon"
    4625 = "Failed logon"
    4672 = "Special privileges assigned"
    4688 = "Process created"
    4719 = "Audit policy changed"
    4720 = "User account created"
    4726 = "User account deleted"
    4728 = "Member added to global security group"
    4729 = "Member removed from global security group"
    4739 = "Domain policy changed"
    4740 = "User account locked out"
    4768 = "Kerberos TGT requested"
    4769 = "Kerberos service ticket requested"
}

$eventIDs = $eventNames.Keys

Write-Host "Searching the Security log for the last $hoursBack hours..."
Write-Host ""

try {
    $events = Get-WinEvent -FilterHashtable @{
        LogName   = "Security"
        Id        = $eventIDs
        StartTime = $startTime
    } -ErrorAction Stop
}
catch {
    Write-Host "FAILED: $($_.Exception.Message)"
    Write-Host ""
    Read-Host "Press Enter to close"
    exit
}

if (-not $events) {
    Write-Host "No matching Security events were found."
    Write-Host ""
    Read-Host "Press Enter to close"
    exit
}

$report = foreach ($event in $events) {
    [PSCustomObject]@{
        TimeCreated = $event.TimeCreated
        EventID     = $event.Id
        EventType   = $eventNames[$event.Id]
        Provider    = $event.ProviderName
        Computer    = $event.MachineName
    }
}

$report |
    Sort-Object TimeCreated -Descending |
    Format-Table -AutoSize -Wrap

Write-Host ""
Write-Host "Matching events found: $($report.Count)"
Write-Host ""

Read-Host "Press Enter to close"
