Import-Module ActiveDirectory

$searchBase = "OU=Users,OU=Ethetic,DC=corp,DC=ethetic,DC=com"

Write-Host "Building group membership report..."
Write-Host ""

$users = Get-ADUser -SearchBase $searchBase -Filter *

$report = foreach ($user in $users) {

    $groups = Get-ADPrincipalGroupMembership -Identity $user |
        Where-Object { $_.Name -ne "Domain Users" } |
        Select-Object -ExpandProperty Name

    [PSCustomObject]@{
        Name           = $user.Name
        SamAccountName = $user.SamAccountName
        Groups         = if ($groups) { $groups -join ", " } else { "None" }
    }
}

$report |
    Sort-Object Name |
    Format-Table -AutoSize -Wrap

Write-Host ""
Write-Host "Users reported: $($report.Count)"
Write-Host ""

Read-Host "Press Enter to close"
