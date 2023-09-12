<#
The purpose of this script is to disable the default "User must change password on next logon" option in AD.
The reason you would want this is that it ABSOLUTELY creates MASSIVE issues for new users and first time logins when syncing from on-prem AD to Azure.
This script is meant to be unattended housekeeping, schedule it as appropriate.
#>

Get-ADUser -SearchBase "OU=<your user OU>,DC=<domain>,DC=<com>" -Filter * -Properties samaccountname,pwdlastset | Select samaccountname,pwdlastset | Where {$_.pwdlastset -eq "0"} | ForEach-Object {$usr=$_.samaccountname; Set-ADUser -Identity $usr -ChangePasswordAtLogon $false}

# Force replication to all DC's

$dcsession = New-PSSession -ComputerName <your pdc name>
$dcscript = {repadmin /syncall}
Invoke-Command -Session $dcsession -ScriptBlock $dcscript
Remove-PSSession $dcsession



# Force Sync to Azure to begin device details upload/export
$session = New-PSSession -ComputerName <your syncronization server name>
$script = {Start-ADSyncSyncCycle -PolicyType Delta}
Invoke-Command -Session $session -ScriptBlock $script
Remove-PSSession $session
