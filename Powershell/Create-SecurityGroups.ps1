Import-Module ActiveDirectory

# -----------------------------
# SETTINGS
# -----------------------------
$groupsOU = "OU=Groups,OU=Ethetic,DC=corp,DC=ethetic,DC=com"

$groupsToCreate = @(
    @{
        Name        = "Helpdesk-Tier2"
        Description = "Tier 2 IT support staff"
    },
    @{
        Name        = "VPN-Users"
        Description = "Users permitted to access the corporate VPN"
    },
    @{
        Name        = "Finance-Share-RW"
        Description = "Read/write access to finance file shares"
    },
    @{
        Name        = "IT-Software-Deploy"
        Description = "IT staff permitted to deploy approved software"
    },
    @{
        Name        = "Remote-Desktop-Users"
        Description = "Users permitted to use approved Remote Desktop access"
    }
)

# -----------------------------
# SAFETY CHECK
# -----------------------------
if (-not (Get-ADOrganizationalUnit -Identity $groupsOU -ErrorAction SilentlyContinue)) {
    Write-Host "Groups OU not found: $groupsOU"
    Read-Host "Press Enter to close"
    exit
}

$created = 0
$skipped = 0
$failed = 0

# -----------------------------
# CREATE GROUPS
# -----------------------------
foreach ($group in $groupsToCreate) {

    $existingGroup = Get-ADGroup `
        -Filter "Name -eq '$($group.Name)'" `
        -SearchBase $groupsOU `
        -ErrorAction SilentlyContinue

    if ($existingGroup) {
        Write-Host "SKIPPED: $($group.Name) already exists"
        $skipped++
        continue
    }

    try {
        New-ADGroup `
            -Name $group.Name `
            -SamAccountName $group.Name `
            -GroupCategory Security `
            -GroupScope Global `
            -Path $groupsOU `
            -Description $group.Description `
            -ErrorAction Stop

        Write-Host "CREATED: $($group.Name)"
        $created++
    }
    catch {
        Write-Host "FAILED: $($group.Name) - $($_.Exception.Message)"
        $failed++
    }
}

# -----------------------------
# SUMMARY
# -----------------------------
Write-Host ""
Write-Host "Finished"
Write-Host "Created: $created"
Write-Host "Skipped: $skipped"
Write-Host "Failed:  $failed"

Write-Host ""
Read-Host "Press Enter to close"
