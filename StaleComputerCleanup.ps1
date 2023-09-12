#-----NOTE: ALL VALUES IN <> NEED TO BE REPLACED BY YOUR REAL WORLD VALUE OR VARIABLE NAME-----#
#---- Get the date and set it to minus 90 days from the current date ----
$date = (Get-Date).AddDays(-90)

#---- Get stale computers that aren't servers or <anotherthing> for later cleanup ----
$stale = Get-ADComputer -Filter {lastLogonDate -lt $date} -Properties name,samaccountname,lastLogonDate | Select name,samaccountname,lastLogonDate | Sort-Object -Property lastLogonDate `
| Where {$_.name -notlike "*<something>*" -and $_.name -notlike "*vcenter*" -and $_.name -notlike "*<somethingelse>*" -and $_.name -notlike "*<anotherthing>*" -and $_.name -notlike "*san*" -and $_.name -notlike "*TEAMROOM*"}

#---- Get Servers for Stale report ----
$sysad = Get-ADComputer -Filter {lastLogonDate -lt $date} -Properties lastLogonDate | Select name,lastLogonDate | Sort-Object -Property lastLogonDate | Where {$_.name -like "*san*" -or $_.name -like "*vcenter*" -or $_.name -like "*<something>*" -or $_.name -like "*<somethingelse>*"}

#----Get Stale <anotherthing> machines for report ----
$stale<anotherthing> = Get-ADComputer -Filter {lastLogonDate -lt $date} -Properties lastLogonDate | Select name,lastLogonDate | Sort-Object -Property lastLogonDate | Where {$_.name -like "*<anotherthing>*"}

#---- Loop through the stale array and remove each offending device from Active Directory ----
$stale | ForEach-Object{

    $comp = $_.samaccountname
    Get-ADComputer -Identity $comp | Remove-ADObject -Recursive -Confirm:$false

    }


<#
#-- Test queries, uncomment if needed --

$stale | Write-Output| ft
$stale.Count

$stale<anotherthing> | Write-Output | ft
$stale<anotherthing>.Count
#>

#---- Set counts and convert tables to HTML format for reports ----
$count = $stale.Count
$count2 = $stale<anotherthing>.Count
$count3 = $sysad.Count
$rabbit = $sysad | ConvertTo-Html -As Table -Fragment
$elmer = $stale | ConvertTo-Html -As Table -Fragment
$porky = $stale<anotherthing> | ConvertTo-Html -As Table -Fragment

#-----Setup HTML body for Stale <anotherthing> (manual removal) report-----
$<anotherthing>report = @" 
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
    Font-size: 34pt;
    font-family: Verdana, Arial;
}
h2 {
    text-align: left;
    color:#323a33;
    Font-size: 20pt;
}
h3 {
    text-align: center;
    color:#211b1c;
    Font-size: 15pt;
}
h4 {
    text-align: left;
    color:#2a2d2a;
    Font-size: 15pt;
}
h5 {
    text-align: center;
    color:#2a2d2a;
    Font-size: 12pt;
}
a:link {
    color:#0098e5;
    text-decoration: underline;
    cursor: auto;
    font-weight: 500;
}
a:visited {
    color:#05a3b7;
    text-decoration: underline;
    cursor: auto;
    font-weight: 500;
}
</style>
</head>
<body>
<h1>Stale <anotherthing> Computers</h1> 
<h2>Stale Device Count: $count2</h2>
<hr><br><br>
<h4>Stale Computers</h4>
$porky
<br>


</body> 
</html> 
"@ 

#-----Setup HTML body for Stale Servers (manual removal) report-----
$daffyduck = @" 
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
    Font-size: 34pt;
    font-family: Verdana, Arial;
}
h2 {
    text-align: left;
    color:#323a33;
    Font-size: 20pt;
}
h3 {
    text-align: center;
    color:#211b1c;
    Font-size: 15pt;
}
h4 {
    text-align: left;
    color:#2a2d2a;
    Font-size: 15pt;
}
h5 {
    text-align: center;
    color:#2a2d2a;
    Font-size: 12pt;
}
a:link {
    color:#0098e5;
    text-decoration: underline;
    cursor: auto;
    font-weight: 500;
}
a:visited {
    color:#05a3b7;
    text-decoration: underline;
    cursor: auto;
    font-weight: 500;
}
</style>
</head>
<body>
<h1>Stale Servers</h1> 
<h2>Stale Device Count: $count3</h2>
<hr><br><br>
<h4>Stale Servers</h4>
$rabbit
<br>


</body> 
</html> 
"@ 

#-----Setup HTML body for Stale (removed) report-----
$RemovedReport = @" 
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
    Font-size: 34pt;
    font-family: Verdana, Arial;
}
h2 {
    text-align: left;
    color:#323a33;
    Font-size: 20pt;
}
h3 {
    text-align: center;
    color:#211b1c;
    Font-size: 15pt;
}
h4 {
    text-align: left;
    color:#2a2d2a;
    Font-size: 15pt;
}
h5 {
    text-align: center;
    color:#2a2d2a;
    Font-size: 12pt;
}
a:link {
    color:#0098e5;
    text-decoration: underline;
    cursor: auto;
    font-weight: 500;
}
a:visited {
    color:#05a3b7;
    text-decoration: underline;
    cursor: auto;
    font-weight: 500;
}
</style>
</head>
<body>
<h1>Stale Computers (Removed from AD)</h1> 
<h2>Stale Devices Removed: $count</h2>
<hr><br><br>
<h4>Stale Computers</h4>
$elmer
<br>


</body> 
</html> 
"@ 

#------Email the reports------

Send-MailMessage -To "somerecipient@yourdomain.com","helpdesk@yourdomain.com" -From "somesender@yourdomain.com" -Subject "Stale Machine Cleanup - Removal Report" -BodyAsHtml $RemovedReport -SmtpServer yourdomain-com.mail.protection.outlook.com

Send-MailMessage -To "somerecipient@yourdomain.com" -From "somesender@yourdomain.com" -Subject "Stale Machine Cleanup - <anotherthing> Report" -BodyAsHtml $<anotherthing>report -SmtpServer yourdomain-com.mail.protection.outlook.com

Send-MailMessage -To "somerecipient@yourdomain.com" -From "somesender@yourdomain.com" -Subject "Stale Machine Cleanup - Server Report" -BodyAsHtml $daffyduck -SmtpServer yourdomain-com.mail.protection.outlook.com
