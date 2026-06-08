<#
.SYNOPSIS
    Enables Windows audit policies on a domain controller for SOC monitoring.

.DESCRIPTION
    Configures success and failure auditing for the event categories most
    relevant to SOC analysis: Logon/Logoff, Account Lockout, User Account
    Management, Security Group Management, Sensitive Privilege Use, and
    Directory Service Changes.

    Required for Windows to write the corresponding events to the Security
    log so they can be ingested by Azure Monitor Agent and queried in
    Azure Log Analytics.

.NOTES
    Author:  Ricardo Jaimes Hernandez
    Project: Azure Help Desk Portfolio Lab
    Run from an elevated PowerShell session on the domain controller.
#>

# Logon/Logoff events (failed and successful)
auditpol /set /subcategory:"Logon" /success:enable /failure:enable
auditpol /set /subcategory:"Logoff" /success:enable /failure:enable
auditpol /set /subcategory:"Account Lockout" /success:enable /failure:enable

# Account Management (password resets, user creation, group changes)
auditpol /set /subcategory:"User Account Management" /success:enable /failure:enable
auditpol /set /subcategory:"Security Group Management" /success:enable /failure:enable

# Privilege Use (when someone uses elevated privileges)
auditpol /set /subcategory:"Sensitive Privilege Use" /success:enable /failure:enable

# Directory Service Access (changes to AD itself)
auditpol /set /subcategory:"Directory Service Changes" /success:enable /failure:enable

# Verify what's enabled
Write-Host "`n=== Enabled Audit Policies ===" -ForegroundColor Cyan
auditpol /get /category:"Logon/Logoff"
auditpol /get /category:"Account Management"

# Set domain account lockout policy
# AD ships with LockoutThreshold = 0 by default (lockouts disabled).
# This applies a baseline policy: 5 failed attempts, 15-minute lockout.
Set-ADDefaultDomainPasswordPolicy -Identity "corp.lab" `
    -LockoutThreshold 5 `
    -LockoutDuration 00:15:00 `
    -LockoutObservationWindow 00:15:00

Write-Host "`n=== Domain Lockout Policy ===" -ForegroundColor Cyan
Get-ADDefaultDomainPasswordPolicy |
    Select-Object LockoutThreshold, LockoutObservationWindow, LockoutDuration
