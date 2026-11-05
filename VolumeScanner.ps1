$Servers = [System.Collections.ArrayList]::new()

$Machines = Get-ADComputer `
    -Filter 'OperatingSystem -like "*Server*" -and Enabled -eq $true' `
    -Properties OperatingSystem

foreach ($Machine in $Machines) {

    $ConnectionSuccessful = Test-NetConnection `
        -ComputerName $Machine.Name `
        -Port 5985 `
        -InformationLevel Quiet `
        -WarningAction SilentlyContinue `
        -ErrorAction SilentlyContinue

    if ($ConnectionSuccessful) {

        $ServerObject = [PSCustomObject]@{
            Name            = $Machine.Name
            OperatingSystem = $Machine.OperatingSystem
        }

        [void]$Servers.Add($ServerObject)
    }
}


[System.Collections.ArrayList]$FreeSpace = @()

foreach ($Server in $Servers) {

    if ($Server.OperatingSystem -like "*2008 R2*") {

        # Server 2008 R2 query
        $Volumes = Get-WmiObject `
            -Class Win32_LogicalDisk `
            -ComputerName $Server.Name `
            -Filter "DriveType = 3" `
            -ErrorAction SilentlyContinue

        foreach ($Volume in $Volumes) {

            if ($null -ne $Volume.DeviceID -and $Volume.Size -gt 0) {

                $Value = [PSCustomObject]@{
                    Name    = $Server.Name
                    Drive   = $Volume.DeviceID
                    Label   = $Volume.VolumeName
                    Size    = [Math]::Round($Volume.Size / 1GB, 2)
                    Free    = [Math]::Round($Volume.FreeSpace / 1GB, 2)
                    Percent = [Math]::Round(
                        ($Volume.FreeSpace / $Volume.Size) * 100,
                        2
                    )
                }

                [void]$FreeSpace.Add($Value)
            }
        }
    }
    else {

        # Server 2012 and newer query
        $Volumes = Get-Volume `
            -CimSession $Server.Name `
            -ErrorAction SilentlyContinue |
            Where-Object {
                $null -ne $_.DriveLetter -and
                $_.Size -gt 0
            }

        foreach ($Volume in $Volumes) {

            $Value = [PSCustomObject]@{
                Name    = $Server.Name
                Drive   = "$($Volume.DriveLetter):"
                Label   = $Volume.FileSystemLabel
                Size    = [Math]::Round($Volume.Size / 1GB, 2)
                Free    = [Math]::Round($Volume.SizeRemaining / 1GB, 2)
                Percent = [Math]::Round(
                    ($Volume.SizeRemaining / $Volume.Size) * 100,
                    2
                )
            }

            [void]$FreeSpace.Add($Value)
        }
    }
}

<#
$FreeSpace |
    Sort-Object Name, Drive |
    Format-Table Name, Drive, Label, Size, Free, Percent -AutoSize


foreach ($Item in $FreeSpace) {

    if ($Item.Percent -lt 20 -and $Item.Label -notlike "*TempDB*") {

        Write-Host (
            "Disk space on {0} is less than 20%. Check drive {1} and increase space if needed." -f
            $Item.Name,
            $Item.Drive
        ) -ForegroundColor Yellow
    }
}
#>

[System.Collections.ArrayList]$CriticalFreeSpace = @()
[System.Collections.ArrayList]$WarningFreeSpace  = @()

foreach ($Item in $FreeSpace) {

    # Exclude TempDB volumes
    if ($Item.Label -notlike "*TempDB*") {

        # Critical: 10% free or less
        if ($Item.Percent -le 10) {
            [void]$CriticalFreeSpace.Add($Item)
        }

        # Warning: Greater than 10%, but less than 20%
        elseif ($Item.Percent -gt 10 -and $Item.Percent -lt 20) {
            [void]$WarningFreeSpace.Add($Item)
        }
    }
}

# -----------------------------
# WARNING HTML TABLE
# -----------------------------

$WarningRows = foreach ($Item in $WarningFreeSpace) {

    @"
<tr>
    <td>$($Item.Name)</td>
    <td>$($Item.Drive)</td>
    <td>$($Item.Label)</td>
    <td>$($Item.Size) GB</td>
    <td>$($Item.Free) GB</td>
    <td style="color:#B8860B; font-weight:bold;">$($Item.Percent)%</td>
</tr>
"@
}

$WarningTable = @"
<table>
    <tr>
        <th>Server</th>
        <th>Drive</th>
        <th>Label</th>
        <th>Size</th>
        <th>Free</th>
        <th>Percent Free</th>
    </tr>
    $($WarningRows -join "`r`n")
</table>
"@


# -----------------------------
# CRITICAL HTML TABLE
# -----------------------------

$CriticalRows = foreach ($Item in $CriticalFreeSpace) {

    @"
<tr>
    <td>$($Item.Name)</td>
    <td>$($Item.Drive)</td>
    <td>$($Item.Label)</td>
    <td>$($Item.Size) GB</td>
    <td>$($Item.Free) GB</td>
    <td style="color:red; font-weight:bold;">$($Item.Percent)%</td>
</tr>
"@
}

$CriticalTable = @"
<table>
    <tr>
        <th>Server</th>
        <th>Drive</th>
        <th>Label</th>
        <th>Size</th>
        <th>Free</th>
        <th>Percent Free</th>
    </tr>
    $($CriticalRows -join "`r`n")
</table>
"@


# -----------------------------
# BUILD HTML EMAIL BODY
# -----------------------------

$HTMLBody = @"
<html>
<head>
<style>

body {
    font-family: Arial, Helvetica, sans-serif;
    font-size: 14px;
}

table {
    border-collapse: collapse;
    margin-bottom: 25px;
}

th {
    background-color: #4472C4;
    color: white;
    padding: 6px 10px;
    border: 1px solid #808080;
    text-align: left;
}

td {
    padding: 6px 10px;
    border: 1px solid #808080;
}

.warning {
    color: #B8860B;
}

.critical {
    color: red;
}

</style>
</head>

<body>

<h2>Server Disk Space Report</h2>

<p>
This dynamic report pulls all servers from Active Directory and reports only on low disk space for every online Windows server.
The following server volumes have less than 20% free disk space.
</p>

<h3>Critical - 10% or Less Free</h3>

$CriticalTable

<h3>Warning - Greater Than 10% and Less Than 20% Free</h3>

$WarningTable

</body>
</html>
"@

Send-MailMessage -To "<someone@yourdomain>" -From "Infrastructure Volume Scanner <someoneelse@yourdomain>" -Subject "Disk Space Report" -BodyAsHtml $HTMLBody -SmtpServer <your mail relay address goes here>
