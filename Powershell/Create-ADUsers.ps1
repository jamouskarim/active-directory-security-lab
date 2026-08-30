Import-Module ActiveDirectory

$csvPath = "C:\Lab\ad_users_30.csv"

if (-not (Test-Path $csvPath)) {
    Write-Host "CSV not found: $csvPath"
    exit
}

$users = Import-Csv $csvPath
$password = Read-Host "Enter the temporary password for the new users" -AsSecureString

$created = 0
$skipped = 0
$failed = 0

foreach ($u in $users) {

    $ouPath = "OU=$($u.OU),OU=Users,OU=Ethetic,DC=corp,DC=ethetic,DC=com"

    $existingUser = Get-ADUser -Filter "SamAccountName -eq '$($u.Username)'" -ErrorAction SilentlyContinue

    if ($existingUser) {
        Write-Host "SKIPPED: $($u.Username) already exists"
        $skipped++
        continue
    }

    $userParams = @{
        Name                  = "$($u.FirstName) $($u.LastName)"
        GivenName             = $u.FirstName
        Surname               = $u.LastName
        SamAccountName        = $u.Username
        UserPrincipalName     = "$($u.Username)@corp.ethetic.com"
        Department            = $u.Department
        Path                  = $ouPath
        AccountPassword       = $password
        Enabled               = $true
        ChangePasswordAtLogon = $true
        ErrorAction           = "Stop"
    }

    try {
        New-ADUser @userParams
        Write-Host "CREATED: $($u.Username) -> $($u.OU)"
        $created++
    }
    catch {
        Write-Host "FAILED: $($u.Username) - $($_.Exception.Message)"
        $failed++
    }
}

Write-Host ""
Write-Host "Finished"
Write-Host "Created: $created"
Write-Host "Skipped: $skipped"
Write-Host "Failed:  $failed"
