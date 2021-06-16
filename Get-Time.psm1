function Get-Time {
 
[CmdletBinding()]
 
param
(
 
[Parameter(Mandatory=$false, HelpMessage='Enter the following values: AllServer, DomainController, Computer')]
[ValidateSet("AllServer", "DomainController", "Computer")]
$Scope,
 
[parameter(Mandatory=$false)]
$Computer="$env:Computername"
 
)
$server=(Get-ADComputer -Filter 'operatingsystem -like "*server*"-and enabled -eq "true"').Name
$dc=Get-ADDomainController -Filter * | Select-Object -ExpandProperty Name
 
$result=@()
 
switch ($Scope)
 
{
 
'AllServer' {
 
foreach ($s in $server) {
$t=Invoke-Command -ComputerName $s {Get-Date -Displayhint time | Select-Object -ExpandProperty DateTime} -ErrorAction SilentlyContinue
 
$result +=New-Object -TypeName PSCustomObject -Property ([ordered]@{
'Server'= $s
'Time' = $t
 
})}
 
}
 
'DomainController' {
 
foreach ($d in $dc) {
$t=Invoke-Command -ComputerName $d {Get-Date -Displayhint time | Select-Object -ExpandProperty DateTime} -ErrorAction SilentlyContinue
 
$result +=New-Object -TypeName PSCustomObject -Property ([ordered]@{
'Server'= $d
'Time' = $t
 
})}
 
}
 
}
 
If ($Computer -ne "$env:computername") {
 
Try {
 
$t=Invoke-Command -ComputerName $Computer {Get-Date -Displayhint time | Select-Object -ExpandProperty DateTime} -ErrorAction Stop
 
$result +=New-Object -TypeName PSObject -Property ([ordered]@{
'Computer'= $Computer
'Time' = $t
 
})
 
}
 
Catch {
 
$result+=New-Object -TypeName PSObject -Property ([ordered]@{
'Computer'=$Computer
'Time'='Computer could not be reached'
 
})
 
}
 
}
 
If (($computer -eq "$env:computername") -and ($scope -eq $null)) {
Get-Date -Displayhint time | Select-Object -ExpandProperty DateTime
 
}
 
Write-Output $result
}
