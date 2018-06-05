$tenantID = "tenant"
 $entPack = ($tenant+":ENTERPRISEPACK")
 $Office365EnterpriseE3_ExcludingExchangeOnline = New-MsolLicenseOptions -AccountSkuId $entPack -DisabledPlans EXCHANGE_S_ENTERPRISE,INTUNE_O365,SWAY,PROJECTWORKMANAGEMENT,YAMMER_ENTERPRISE,RMS_S_ENTERPRISE,OFFICESUBSCRIPTION,SHAREPOINTWAC

$users = Get-MsolUser -all | Where-Object {$_.isLicensed -eq "TRUE"}

$i = 0
$Users | ForEach-Object {
Write-Progress -Activity "Assigning Licenses" -PercentComplete ($i / $users.count) -Status $i
$_.UserPrincipalName
try{
Set-MsolUserLicense -UserPrincipalName $_.UserPrincipalName -RemoveLicenses $entPack #-ErrorAction Stop
Set-MsolUserLicense -UserPrincipalName $_.UserPrincipalName -AddLicenses $entPack -LicenseOptions $Office365EnterpriseE3_ExcludingExchangeOnline -ErrorAction Stop
}catch{
Set-MsolUserLicense -UserPrincipalName $_.UserPrincipalName -AddLicenses $entPack -LicenseOptions $Office365EnterpriseE3_ExcludingExchangeOnline
}
$i++
}
