<#
This tool was built with the sole function of allowing an administrator to lock a specific account for testing purposes.
#>

$username = Read-Host "Enter sAMAccountName to lock out"

$AccountLockoutThreshold = "3"

if (!$AccountLockoutThreshold) { Write-Output "Account Lockout Threshold is Not Defined in Default Domain Policy"; return; }

Write-Output "Account will lock out after '$AccountLockoutThreshold' invalid login attempts"

$password = ConvertTo-SecureString 'incorrect password' -AsPlainText -Force

$credential = New-Object System.Management.Automation.PSCredential ($username, $password)   

$attempts = 0

Do {                         

    $attempts++

    Write-Output "'$username' login attempt $attempts"

    Enter-PSSession -ComputerName 2K19-DC -Credential $credential -ErrorAction SilentlyContinue           

}

Until ($attempts -eq $AccountLockoutThreshold)

Write-Output "'$username' successfully locked out." 
