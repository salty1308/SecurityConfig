$csv = Import-Csv -Path "myfilepath"
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

$outfile = $critRisk | select -Unique name,risk,host,cvss 
$outfile += $HighRisk | select -Unique name,risk,host,cvss
$outfile += $medRisk | select -Unique name,risk,host,cvss 
$outfile += $lowRisk | select -Unique name,risk,host,cvss 

$outfile | select host,risk,cvss,name | Export-Csv -Path C:\temp\nessustest.csv | Out-Null

