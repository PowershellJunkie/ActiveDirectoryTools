<#
This script is for domains that use ADFS services to sync users/accounts to Azure. 
If you are syncing your accounts via Group membership, this script will ensure that all new users created have this group so they will sync on your appropriate cycles.
This script is intended to be unattended, meaning you can set it to run on a schedule and not think about it.
Next version will include a reporting piece.
#>

#---Initial filter variable (array) to grab every active user on your domain, minus the ones you don't want. You will need to edit the exceptions to meet your own needs---#
$stuff = {Enabled -eq $true -and Name -notlike "*test*" -and Name -notlike "*a-name*" -and Name -notlike "*service account*" -and Name -notlike "*Bird Person*" -and Name -notlike "*Mail Flow Check*" -and Name -notlike "*Rick C138*" -and Name -notlike "*Limited User*" -and Name -notlike "*Super User*"}

#---Blank array, to be filled shortly---#
$results = @()

#---Actual query, with your pre-defined filter variable from above---#
$users = Get-ADUser -SearchBase "OU=<your user OU>,OU=<another OU if needed>,DC=<domain>,DC=<com>" -Filter $stuff  -Properties memberof

#---Loop to get what we want and fill our blank array---#
foreach ($user in $users) {
    $groups = $user.memberof -join ';'
    $results += New-Object psObject -Property @{'User'=$user.samaccountname;'Groups'= $groups}
    }

#---Final array filtering out which user accounts aren't members of your ADFS Sync group ---#
$addme = $results | Where-Object { $_.groups -notmatch '<ADFSSync group>' } | Select-Object user

#---Final loop to add any stray user accounts to your ADFS Sync group---#
$addme | ForEach-Object{
    
    $me = $_.User
    Add-ADGroupMember -Identity "<ADFSSync group>" -Members $me

    }
