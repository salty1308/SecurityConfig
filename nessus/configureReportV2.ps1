
$csv = Import-Csv -Path "C:\Nessus\VM-L-VC-C-U_67d31s.csv"

$lowRisk = $csv | ?{$_.risk -eq "Low"}
$medRisk = $csv | ?{$_.risk -eq "Medium"}
$HighRisk = $csv | ?{$_.risk -eq "High"}
$critRisk = $csv | ?{$_.risk -eq "Critical"}
$Info = $csv | ?{$_.risk -eq "None"}

Write-Host -NoNewline "Critical Issues:: "
Write-Host $critRisk.count
Write-Host -NoNewline "High Issues:: "
Write-Host $HighRisk.count
Write-Host -NoNewline "Medium Issues:: "
Write-Host $medRisk.count
Write-Host -NoNewline "Low Issues:: "
Write-Host $lowRisk.count
Write-Host -NoNewline "Informational:: "
Write-Host $Info.count

$outfile = $critRisk | select -Unique name,risk,host,cvss,port,synopsis,description,solution,"plugin output","see also","plugin id"
$outfile += $HighRisk | select -Unique name,risk,host,cvss,port,synopsis,description,solution,"plugin output","see also","plugin id"
$outfile += $medRisk | select -Unique name,risk,host,cvss,port,synopsis,description,solution,"plugin output","see also","plugin id"
$outfile += $lowRisk | select -Unique name,risk,host,cvss,port,synopsis,description,solution,"plugin output","see also" ,"plugin id"

#generates the host data view
$outfile | select host,risk,cvss,name | Export-Csv -Path C:\temp\perhostReport.csv | Out-Null

#gernerate a vulnerability view
$outfile.count #how may issues to deal with (To Be Removed)
$vulnNames = $outfile | select -Unique name
Write-Host -NoNewline "Different types of vulnerabilities:: "
Write-Host $vulnNames.count

$VulnData = $outfile | Group-Object -Property name 

$out = @()
$output = New-Object System.Object
$VulnData| foreach{
    $output = New-Object System.Object
    $output | Add-Member -type NoteProperty -name Name -Value $_.name
    $tmp =""
    $_.Group.host | foreach{
        $tmp += $_ +" "
    }
    $output | Add-Member -type NoteProperty -name Host -Value ($tmp)
    $output | Add-Member -type NoteProperty -name CVSS -Value ($_.group.cvss | select -Unique)
    $output | Add-Member -type NoteProperty -name Port -Value ($_.Group.port| select -Unique)
    $output | Add-Member -type NoteProperty -name Synopsis -Value ($_.Group.synopsis| select -Unique)
    $output | Add-Member -type NoteProperty -name Description -Value ($_.Group.description | select -Unique)
    $output | Add-Member -type NoteProperty -name Solution -Value ($_.Group.solution | select -Unique)
    $out += $output
}
$out | Export-Csv C:\temp\PerVulnReport.csv

