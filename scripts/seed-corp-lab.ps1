<#
.SYNOPSIS
    Seeds the corp.lab Active Directory environment with OUs,
    security groups, and test users.

.DESCRIPTION
    Creates three OUs (Helpdesk, Sales, IT), one security group per OU,
    and six test users. Idempotent: safe to re-run.

.NOTES
    Author:  Ricardo Jaimes Hernandez
    Project: Azure Help Desk Portfolio Lab
    Run from an elevated PowerShell session after AD DS is installed
    and the domain is promoted.
#>

$domain = "corp.lab"
$dn = "DC=corp,DC=lab"
$defaultPassword = ConvertTo-SecureString "TempPass123!" -AsPlainText -Force

# Create OUs
$ous = @("Helpdesk", "Sales", "IT")
foreach ($ou in $ous) {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$ou'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $ou -Path $dn -ProtectedFromAccidentalDeletion $false
        Write-Host "Created OU: $ou" -ForegroundColor Green
    }
}

# Create security groups (one per OU)
$groups = @{
    "HelpdeskAgents" = "Helpdesk"
    "SalesUsers"     = "Sales"
    "ITAdmins"       = "IT"
}
foreach ($groupName in $groups.Keys) {
    $ouPath = "OU=$($groups[$groupName]),$dn"
    if (-not (Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $groupName -GroupScope Global -GroupCategory Security -Path $ouPath
        Write-Host "Created Group: $groupName" -ForegroundColor Green
    }
}

# Create users
$users = @(
    @{First="Maria"; Last="Lopez";   Dept="Helpdesk"; Group="HelpdeskAgents"; Title="Help Desk Technician"},
    @{First="James"; Last="Chen";    Dept="Helpdesk"; Group="HelpdeskAgents"; Title="Help Desk Technician"},
    @{First="Sarah"; Last="Patel";   Dept="Sales";    Group="SalesUsers";     Title="Account Executive"},
    @{First="David"; Last="Nguyen";  Dept="Sales";    Group="SalesUsers";     Title="Sales Representative"},
    @{First="Alex";  Last="Johnson"; Dept="IT";       Group="ITAdmins";       Title="Systems Administrator"},
    @{First="Priya"; Last="Singh";   Dept="IT";       Group="ITAdmins";       Title="IT Manager"}
)

foreach ($u in $users) {
    $sam = ($u.First.Substring(0,1) + $u.Last).ToLower()
    $upn = "$sam@$domain"
    $ouPath = "OU=$($u.Dept),$dn"

    if (-not (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue)) {
        New-ADUser `
            -Name "$($u.First) $($u.Last)" `
            -GivenName $u.First `
            -Surname $u.Last `
            -SamAccountName $sam `
            -UserPrincipalName $upn `
            -DisplayName "$($u.First) $($u.Last)" `
            -Title $u.Title `
            -Department $u.Dept `
            -Path $ouPath `
            -AccountPassword $defaultPassword `
            -Enabled $true `
            -ChangePasswordAtLogon $false

        Add-ADGroupMember -Identity $u.Group -Members $sam
        Write-Host "Created user: $sam" -ForegroundColor Green
    }
}

Write-Host "`n=== Seed complete ===" -ForegroundColor Cyan
Write-Host "Default password: TempPass123!" -ForegroundColor Cyan
