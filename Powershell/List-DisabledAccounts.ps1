Import-Module ActiveDirectory

Write-Host "Searching Active Directory for disabled user accounts..."
Write-Host ""

$disabledUsers = Search-ADAccount -AccountDisabled -UsersOnly

if ($disabledUsers) {
    $disabledUsers |
        Select-Object Name, SamAccountName, DistinguishedName |
        Format-Table -AutoSize

    Write-Host ""
    Write-Host "Disabled accounts found: $($disabledUsers.Count)"
}
else {
    Write-Host "No disabled user accounts were found."
}

Write-Host ""
Read-Host "Press Enter to close"
