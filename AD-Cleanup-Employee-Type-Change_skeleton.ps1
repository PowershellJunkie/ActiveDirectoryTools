<#
Get the input for the Department Number and the desired Job Code here. The way our AD is layed out, the $JCode will be used twice; 
Once to determine the sub-OU that the user(s) in question are located and again to actually change their 'employeetype' AD attribute
#>

$JCode = Read-Host "Please input Job code desired"
$OU1 = Read-Host "Input OU here"
$OU2 = Read-Host "Input Sub-OU here"
$OU3 = Read-Host "Input sub-sub-OU here"

# Build the array of users based on the input given

$usrArray = @()
$usrdeets = Get-ADUser -SearchBase "OU=$JCode,OU=$OU3,OU=$OU2,OU=$OU1,DC=tbc,DC=local" -Filter * | Select-Object sAMAccountName
$usrArray += $usrdeets

# Loop through the array and change the 'employeetype' to the desired Job Code

$usrArray | ForEach-Object{

$user = $_.sAMAccountName

Set-ADUser -Identity $user -Replace @{employeetype=$JCode}

}