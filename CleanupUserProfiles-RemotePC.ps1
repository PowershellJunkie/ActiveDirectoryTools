$computername = Read-Host "Enter computername"
$initfree = Get-Volume -CimSession $computername -DriveLetter C| Select-Object DriveLetter, @{Name="FreeSpace"; Expression={[Math]::Round($_.SizeRemaining / 1GB, 2)}}
Write-Host -ForegroundColor Yellow "Free space remaining before operation" $initfree.FreeSpace "GB"
# This line is the one you use for exclusion parameters unique to your user name types and local accounts you don't want deleted, be they local only or domain accounts
# Simply adding -and $_.Name -notlike "*Bob*" to the Where statement will exclude the "Bob" profile folder, for example
$users = Get-ChildItem -Path "\\$computername\C$\Users" | Select Name | Where {$_.Name -notlike "*Public*" -and $_.Name -notlike "*Default*"}
#$users | Write-Output | ft
#$users.Count

[System.Collections.ArrayList]$acnts = @()

$users | ForEach-Object{

    $user = $_.Name
    $person = Get-ADUser -Filter {samaccountname -like $user}
    
    $val = [pscustomobject]@{
    
    'User' = $person.samaccountname
    'Enabled' = $person.Enabled
    }
    $acnts.Add($val) | Out-Null
    $val = $null
    }
    
   #$acnts | Write-Output | ft 

   $disabled = $acnts | Select User,Enabled | Where {$_.Enabled -eq $false}

   #$disabled | Write-Output | ft
   #$disabled.Count
   

   $disabled | ForEach-Object{

   $username = $_.User
   Write-Host -ForegroundColor Yellow "Deleting user profile for" $username "on computer" $computername
   Get-CimInstance -ComputerName $computername -Class Win32_UserProfile | Where-Object { $_.LocalPath -like "*$username*" } | Remove-CimInstance -Verbose

   }

$finfree = Get-Volume -CimSession $computername -DriveLetter C| Select-Object DriveLetter, @{Name="FreeSpace"; Expression={[Math]::Round($_.SizeRemaining / 1GB, 2)}}
$totalgain = $finfree.FreeSpace - $initfree.FreeSpace
Write-Host -ForegroundColor Green "Free space remaining after operation" $finfree.FreeSpace "GB"
Write-Host -ForegroundColor Green "Total space gained" $totalgain "GB"
Write-Host -ForegroundColor Green "Operation Complete"
