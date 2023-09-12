#---The purpose of this script is to clean up old Exchange Attributes from disabled (but not deleted) users. This will keep these attributes clean, should you ever need to re-hire that user in your new Exchange Online environment and prevent you having bigger issues---#
# Date range
$date = (Get-Date).AddDays(-30).Date

# Get user accounts disabled for longer than 30 days. The '-le' (less than or equal to) is deceptive, as it is inverse to the current date, meaning it gets accounts older than 30 days, which is the desired result. Using the '-ge' will actually get accounts that have been disabled less than 30 days, which we do not want to do, as it will clear their Exchange Online mailbox, so if we re-hire someone within the 30 day window (or in case of an accidental account disable!).

$disusers = Get-ADUser -Filter {Enabled -eq $false -and Modified -le $date} -Properties sAMAccountName,Modified | Select-Object sAMAccountName,Modified | Where {$_.sAMAccountName -notlike "*_T*"}


# Loop to remove/clear the Exchange attributes for accounts found in the previous variable
$disusers | ForEach-Object {

$user = $_.sAMAccountName

get-aduser $user| set-aduser -clear msExchMailboxGuid,msExchHomeServerName,legacyExchangeDN,mail,mailNickname,msExchMailboxSecurityDescriptor,msExchPoliciesIncluded,msExchRecipientDisplayType,msExchRecipientTypeDetails,msExchUMDtmfMap,msExchUserAccountControl,msExchVersion

}
