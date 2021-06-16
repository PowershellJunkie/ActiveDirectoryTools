# Set the path for AD Photos 
$path = "\\<server>\<folder>\<ad_pictures_folder>"

# Silence Errors so automation doesn't break
$ErrorActionPreference = 'SilentlyContinue'

# Create Array of user accounts without photos in AD
$usrArray = @()
$usrdet = Get-ADUser -Filter {ObjectClass -eq "User" -and Enabled -eq $True -and thumbnailPhoto -notLike "*"} | Select sAMAccountName
$usrArray += $usrdet

# Use array of users without photos to search folder (path) for the user photos and upload them to AD 
$usrArray | ForEach-Object {

$user = $_.sAMAccountName
$photo = [byte[]](Get-Content "$path\$user.jpg" -Encoding byte)
Set-ADUser $user -Replace @{thumbnailPhoto=$photo}

}

# Set array with rogue accounts that don't need photos and aren't in a specific OU
$rmaccts = @('service_account','service_account2','etc','etc')

# Create new array that searches for users still missing photos, excluding OU's that only contain test user accounts, subtracting rogue accounts using the rmaccts array 
$rptarray = @()
$rptdetails = Get-ADUser -SearchBase "OU=<yourOU>,OU=<yourOU>,DC=<yourDC>,DC=<yourDC>" -Filter {ObjectClass -eq "User" -and Enabled -eq $True -and thumbnailPhoto -notLike "*"} -Properties Name,sAMAccountName,mail | Where-Object {$_.DistinguishedName -notlike "*Something*" -and $_.DistinguishedName -notlike "*Something*" -and $_.DistinguishedName -notlike "*Darkside*"} | Select-Object Name,sAMAccountName,mail | Where {$rmaccts -notcontains $_.sAMAccountName}
$rptarray += $rptdetails

# Convert report array to HTML table 
$output = $rptarray | ConvertTo-Html -as Table -Fragment

# Create HTML output for email
 $htmlbod = @"
<html> 
<head>
<style>
body {
    Color: #252525;
    font-family: Verdana,Arial;
    font-size:11pt;
}
table {border: 1px solid rgb(104,107,112); text-align: left;}
th {background-color: #d2e3f7;border-bottom:2px solid rgb(79,129,189);text-align: left;}
tr {border-bottom:2px solid rgb(71,85,112);text-align: left;}
td {border-bottom:1px solid rgb(99,105,112);text-align: left;}
h1 {
    text-align: left;
    color:#5292f9;
    Font-size: 14pt;
    font-family: Verdana, Arial;
}
h2 {
    text-align: left;
    color:#323a33;
    Font-size: 20pt;
}

</style>
</head>
<body style="font-family:verdana;font-size:13">
Hello, <br><br>

The following list of people do not have an AD Photo. Please remediate this as soon as possible.<br>
<br>
<h2>People Missing A Photo</h2>
$output

<br>
<br>
Thank you,<br>
IT Department<br><br>

</body> 
</html> 
"@ 

# Set users/departments for email notification
$mailnotification = "someemail@yourdomain.com","anotheremail@yourdomain.com"

# Notification email that includes HTML report 
Send-MailMessage -From 'service_email@yourdomain.com' -To $mailnotification -Subject "MISSING! AD User Photos" -BodyAsHtml $htmlbod -SmtpServer 'your.smtp.server.yourdomain.com'