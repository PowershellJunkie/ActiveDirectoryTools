#Set the number of days within expiration.  This will start to send the email x number of days before it is expired.
$DaysWithinExpiration = 14
 
#Set the days where the password is already expired and needs to change. -- Do Not Modify --
$MaxPwdAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days
$expiredDate = (Get-Date).addDays(-$MaxPwdAge)
 
#Set the number of days until you would like to begin notifing the users. -- Do Not Modify --
$emailDate = (Get-Date).addDays( - ($MaxPwdAge - $DaysWithinExpiration))
 
#Filters for all users who's password is within $date of expiration.
$ExpiredUsers = Get-ADUser -Filter { (PasswordLastSet -lt $emailDate) -and (PasswordLastSet -gt $expiredDate) -and (PasswordNeverExpires -eq $false) -and (Enabled -eq $true) } -Properties DisplayName, PasswordNeverExpires, Manager, PasswordLastSet, Mail, "msDS-UserPasswordExpiryTimeComputed" -SearchBase "OU=TBC Employees, OU=TBC,DC=TBC,DC=Local" | Select-Object DisplayName, samaccountname, manager, PasswordLastSet, @{name = "DaysUntilExpired"; Expression = { $_.PasswordLastSet - $ExpiredDate | Select-Object -ExpandProperty Days } }, @{name = "EmailAddress"; Expression = { $_.mail } }, @{Name = "ExpiryDate"; Expression = { [datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed") } } | Sort-Object PasswordLastSet
 
$ExpiredUsers
#Users Email
foreach ($ExpiredUser in $ExpiredUsers) {
    $ReturnHTML = @" 
<html> 
<head>
<style>
body {
    Color: #252525;
    font-family: Verdana,Arial;
    font-size:11pt;
}
h1 {
    text-align: center;
    color:#C8102E;
    Font-size: 34pt;
    font-family: Verdana, Arial;
}
h2 {
    text-align: center;
    color:#9EA2A2;
    Font-size: 20pt;
}
h3 {
    text-align: center;
    color:#211b1c;
    Font-size: 15pt;
}
h4 {
    text-align: center;
    color:#242526;
    Font-size: 15pt;
}
a:link {
    color:#C8102E;
    text-decoration: underline;
    cursor: auto;
    font-weight: 700;
}
a:visited {
    color:#C8102E;
    text-decoration: underline;
    cursor: auto;
    font-weight: 700;
}
</style>
</head>
<body>
Dear $($ExpiredUser.DisplayName),<br><br>
Your password was last set on <i>$($ExpiredUser.PasswordLastSet)</i>. This means your password will expire in <b>$($ExpiredUser.DaysUntilExpired) Days</b>. Please reset your password before <b>$($ExpiredUser.ExpiryDate)</b><br>
<ol>
<li>Find a computer connected to the network</li>
<li>if the computer is logged in, on your keyboard press, <b>ctrl+alt+del</b> at the same time. </li>
<li>Select <b>Change Password</b></li>
<li>replace the username section with <b>$($ExpiredUser.samaccountname)</b>.</li>
<li>Enter your old password in the old password location.</li>
<li>Enter a new password in the new password location.</li>
<li>Confirm your new password in the confirm password location</li>
<li>Click Enter</li>
</ol>
<br>
<b><u>Instructions for Mac Users</u></b>
<br>
Please contact the Helpdesk for assistance with resetting your password.
<br>
<br>

Thank you<br>
IT Department
</body> 
</html> 
"@  
    Send-MailMessage -To $($ExpiredUser.EmailAddress) -From "Password Notification <somesender@yourdomain.com>" -Subject "$($ExpiredUser.DisplayName) Password Notification" -BodyAsHtml $ReturnHTML -SmtpServer <yourdomain-com>.mail.protection.outlook.com
}
$Managers = $ExpiredUsers | Select-Object -ExpandProperty manager -Unique
foreach ($Manager in $Managers) {
    $ReportingtoHTML = $ExpiredUsers | Where-Object { $_.manager -eq $Manager } | Select-Object -Property DisplayName, @{name = "EmailAddress"; Expression = { $_.mail } }, @{label = "DaysUntilExpired"; expression = { "$($_.DaysUntilExpired) Days" } }, ExpiryDate | ConvertTo-Html -Fragment -As Table
    $Manager = Get-ADUser $Manager -Properties DisplayName, PasswordNeverExpires, Manager, PasswordLastSet, "msDS-UserPasswordExpiryTimeComputed" | Select-Object DisplayName, samaccountname, mail, manager, PasswordLastSet, @{name = "DaysUntilExpired"; Expression = { $_.PasswordLastSet - $ExpiredDate | Select-Object -ExpandProperty Days } }, @{name = "EmailAddress"; Expression = { $_.mail } }, @{Name = "ExpiryDate"; Expression = { [datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed") } } | Sort-Object PasswordLastSet
    $ManagerReturnHTML = @" 
<html> 
<head>
<style>
h1 {
    text-align: center;
    color:#C8102E;
    Font-size: 34pt;
    font-family: Verdana, Arial;
}
h2 {
    text-align: center;
    color:#9EA2A2;
    Font-size: 20pt;
}
h3 {
    text-align: center;
    color:#211b1c;
    Font-size: 15pt;
}
h4 {
    text-align: center;
    color:#242526;
    Font-size: 15pt;
}
a:link {
    color:#C8102E;
    text-decoration: underline;
    cursor: auto;
    font-weight: 700;
}
a:visited {
    color:#C8102E;
    text-decoration: underline;
    cursor: auto;
    font-weight: 700;
}
body {
width:75%;
background-color:#ffffff;}
table {border-collapse: collapse; border: 1px solid rgb(45,41,38); text-align: Center;}
th {background-color: #f7a1af; text-align: Center;}
tr:nth-child(even) {background-color: #f2f2f2;}
tr {text-align: Center;}
td {border:1px solid rgb(45,41,38);text-align: Center;}
</style>
</head>
<body style="font-family:verdana;font-size:13"> 
Dear $($Manager.DisplayName),<br><br>
Here is a list of all employees that are reporting to you whose passwords are to expire within the next 14 days. Please have these employees reset their passwords <b>before</b> their expirydate. Please note that we have also sent an email to the employee with the instructions on how to reset their password.<br>
<br>
$ReportingtoHTML
<br>
<br>

Thank you<br>
IT Department
</body> 
</html> 
"@  
    Send-MailMessage -To $($Manager.EmailAddress) -From "Password Notification <somesender@yourdomain.com>" -Subject "User Password Notification" -BodyAsHtml $ManagerReturnHTML -SmtpServer <yourdomain-com>.mail.protection.outlook.com
}
$ITReturnHTML = $ExpiredUsers | Select-Object @{label = "Name"; expression = { $_.Displayname } }, @{Label = "UserName"; expression = { $_.samaccountname } }, EmailAddress, @{label = "Manager"; expression = { $(($_.Manager.Split(',')).split('=')[1]) } }, ExpiryDate, @{Label = "Days"; expression = { $_.DaysUntilExpired } } | ConvertTo-Html -Fragment -As Table
$ItReportReturnHTML = @" 
<html> 
<head>
<style>
h1 {
    text-align: center;
    color:#C8102E;
    Font-size: 34pt;
    font-family: Verdana, Arial;
}
h2 {
    text-align: center;
    color:#9EA2A2;
    Font-size: 20pt;
}
h3 {
    text-align: center;
    color:#211b1c;
    Font-size: 15pt;
}
h4 {
    text-align: center;
    color:#242526;
    Font-size: 15pt;
}
a:link {
    color:#C8102E;
    text-decoration: underline;
    cursor: auto;
    font-weight: 700;
}
a:visited {
    color:#C8102E;
    text-decoration: underline;
    cursor: auto;
    font-weight: 700;
}
body {
background-color:#ffffff;}
table {border-collapse: collapse; border: 1px solid rgb(45,41,38); text-align: Center;}
th {background-color: #54c6ff; text-align: Center;}
tr:nth-child(even) {background-color: #f2f2f2;}
tr {text-align: Center;width:20%;}
td {border:1px solid rgb(45,41,38);text-align: Center;}
</style>
</head>
<body style="font-family:verdana;font-size:13"> 
Dear IT,<br><br>
Please see the expiring/expired password list below.
<br><br>
$ITReturnHTML
<br>
<br>

Thank you<br>
IT Department
</body> 
</html> 
"@  
Send-MailMessage -To <somerecipient@yourdomain.com> -From "Password Notification <somerecipient@yourdomain.com>" -Subject "Password Expiry Notification" -BodyAsHtml $ItReportReturnHTML -SmtpServer <yourdomain-com>.mail.protection.outlook.com

$Admins = Get-ADUser -Filter { (samaccountname -like "*admin*") -and (PasswordLastSet -lt $emailDate) -and (PasswordLastSet -gt $expiredDate) -and (PasswordNeverExpires -eq $false) -and (enabled -eq $true) } -Properties  DisplayName, PasswordNeverExpires, Manager, PasswordLastSet, Mail, "msDS-UserPasswordExpiryTimeComputed" 
Foreach ($Admin in $Admins) {
    $Username = $Admin.samaccountname -replace "(_.*)", ""
    $User = Get-ADUser -Identity $Username -Properties *
    $ReturnHTML = @" 
<html> 
<head>
<style>
body {
    Color: #252525;
    font-family: Verdana,Arial;
    font-size:11pt;
}
h1 {
    text-align: center;
    color:#C8102E;
    Font-size: 34pt;
    font-family: Verdana, Arial;
}
h2 {
    text-align: center;
    color:#9EA2A2;
    Font-size: 20pt;
}
h3 {
    text-align: center;
    color:#211b1c;
    Font-size: 15pt;
}
h4 {
    text-align: center;
    color:#242526;
    Font-size: 15pt;
}
a:link {
    color:#C8102E;
    text-decoration: underline;
    cursor: auto;
    font-weight: 700;
}
a:visited {
    color:#C8102E;
    text-decoration: underline;
    cursor: auto;
    font-weight: 700;
}
</style>
</head>
<body>
Dear $($User.DisplayName),<br><br>
Your Admin password was last set on <i>$($Admin.PasswordLastSet)</i>. This means your password will expire in <b>$($admin.DaysUntilExpired) Days</b>. Please reset your password before <b>$($Admin.ExpiryDate)</b><br>
<ol>
<li>Find a computer connected to the network</li>
<li>if the computer is logged in, on your keyboard press, <b>ctrl+alt+del</b> at the same time. </li>
<li>Select <b>Change Password</b></li>
<li>replace the username section with <b>$($Admin.samaccountname)</b>.</li>
<li>Enter your old password in the old password location.</li>
<li>Enter a new password in the new password location.</li>
<li>Confirm your new password in the confirm password location</li>
<li>Click Enter</li>
</ol>
<br>
<hr>
<br>

Thank you<br>
IT Department
</body> 
</html> 
"@  
    Send-MailMessage -To $($User.EmailAddress) -From "Password Notification <somesender@yourdomain.com>" -Subject "$($User.DisplayName) Password Notification" -BodyAsHtml $ReturnHTML -SmtpServer <yourdomain-com>.mail.protection.outlook.com

}
