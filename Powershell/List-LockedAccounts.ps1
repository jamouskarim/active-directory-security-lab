Import-Module ActiveDirectory

Write-Host "Searching Active Directory for locked user accounts..."
Write-Host ""

$lockedUsers = Search-ADAccount -LockedOut -UsersOnly

if ($lockedUsers) {
    $lockedUsers |
        Select-Object Name, SamAccountName, DistinguishedName |
        Format-Table -AutoSize

    Write-Host ""
    Write-Host "Locked accounts found: $($lockedUsers.Count)"
}
else {
    Write-Host "No locked user accounts were found."
}

Write-Host ""
Read-Host "Press Enter to close"
