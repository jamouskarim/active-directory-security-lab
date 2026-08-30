Import-Module ActiveDirectory

# -----------------------------
# SETTINGS
# -----------------------------
$csvPath = "C:\Users\Administrator\Desktop\terminated_users.csv"
$terminatedOU = "OU=Terminated Users,OU=Users,OU=Ethetic,DC=corp,DC=ethetic,DC=com"

# -----------------------------
# SAFETY CHECKS
# -----------------------------
if (-not (Test-Path $csvPath)) {
    Write-Host "CSV not found: $csvPath"
    Read-Host "Press Enter to close"
    exit
}

$ouExists = Get-ADOrganizationalUnit -Identity $terminatedOU -ErrorAction SilentlyContinue

if (-not $ouExists) {
    Write-Host "WARNING: Terminated Users OU was not found."
    Write-Host "Accounts will still be disabled, but they will NOT be moved."
    Write-Host ""
}

$users = Import-Csv $csvPath

$disabled = 0
$alreadyDisabled = 0
$notFound = 0
$protected = 0
$failed = 0

# -----------------------------
# PROCESS EACH USER
# -----------------------------
foreach ($row in $users) {

    $username = $row.Username

    try {
        $user = Get-ADUser -Identity $username -Properties Enabled, MemberOf, DistinguishedName -ErrorAction Stop
    }
    catch {
        Write-Host "NOT FOUND: $username"
        $notFound++
        continue
    }

    # Do not accidentally disable critical/admin accounts.
    $isDomainAdmin = $user.MemberOf -contains "CN=Domain Admins,CN=Users,DC=corp,DC=ethetic,DC=com"
    $protectedNames = @("Administrator", "krbtgt", "jamousk")

    if ($protectedNames -contains $user.SamAccountName -or $isDomainAdmin) {
        Write-Host "PROTECTED: $username was skipped"
        $protected++
        continue
    }

    if (-not $user.Enabled) {
        Write-Host "ALREADY DISABLED: $username"
        $alreadyDisabled++
    }
    else {
        try {
            Disable-ADAccount -Identity $user
            Write-Host "DISABLED: $username"
            $disabled++
        }
        catch {
            Write-Host "FAILED TO DISABLE: $username - $($_.Exception.Message)"
            $failed++
            continue
        }
    }

    # Move the disabled account if the Terminated Users OU exists.
    if ($ouExists) {
        try {
            Move-ADObject -Identity $user.DistinguishedName -TargetPath $terminatedOU
            Write-Host "MOVED: $username -> Terminated Users"
        }
        catch {
            Write-Host "MOVE FAILED: $username - $($_.Exception.Message)"
            $failed++
        }
    }

    Write-Host ""
}

# -----------------------------
# SUMMARY
# -----------------------------
Write-Host "Finished"
Write-Host "Disabled:          $disabled"
Write-Host "Already disabled:  $alreadyDisabled"
Write-Host "Not found:         $notFound"
Write-Host "Protected/skipped: $protected"
Write-Host "Failed:            $failed"

Read-Host "Press Enter to close"
