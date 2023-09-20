$zombies = <your query, array or values>

ForEach($zombie in $zombies){

    Get-ADUser -Identity $zombie -Properties Memberof | ForEach-Object{$_.MemberOf `
    | Disable-ADAccount | Remove-ADGroupMember -Members $_.DistinguishedName -Confirm:$false `
    | Get-ADObject -Filter {sAMAccountName -eq $zombie} | Select ObjectGUID `
    | Move-ADObject -TargetPath "OU=Disabled,DC=domain,DC=com"}

    }
