function get-admin(){
    $UserCredential = Get-Credential
    return $UserCredential
}

#connect to msonline
function connect-service($servicetype, $UserCredential, $tenantName){
    
    #sort out connections through proxy
    $browser = New-Object System.Net.WebClient
    $browser.Proxy.Credentials =[System.Net.CredentialCache]::DefaultNetworkCredentials
         
    if ($servicetype -eq "EXO"){
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication  Basic -AllowRedirection
        Import-PSSession $session -AllowClobber
    }elseif ($servicetype -eq "O365"){
        Connect-MsolService -Credential $UserCredential
    }elseif($servicetype -eq "Skype"){
        $session = New-CsOnlineSession -Credential $UserCredential -Verbose
        Import-PSSession $session -AllowClobber
    }elseif($servicetype -eq "SPO"){
        $SPOModulePath = 'C:\Program Files\SharePoint Online Management Shell\'
        $Env:PSModulePath = '{0};{1}' -f $Env:PSModulePath, $SPOModulePath
        Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
        Connect-SPOService -Url "https://$($tenantName)-admin.sharepoint.com"
    }else{
        Write-error "No Service Type to connect to specified - Service will now stop"
    }
}
function config-exchange(){
    #configure exchange to prevent client forwarding
    new-transportrule "Client Rules to External Blocking" -senttoscope NotInOrganization -MessageTypeMatches AutoForward -FromScope InOrganization -RejectMessageReasonText 'Client Forwarding Rules To External Domains Are Not Permitted.' -Comments "Generated to prevent forwarding on clients within the organisation"
    
    #Enable global audit logging
    Get-Mailbox -ResultSize Unlimited -Filter {RecipientTypeDetails -eq "UserMailbox" -or RecipientTypeDetails -eq "SharedMailbox" -or RecipientTypeDetails -eq "RoomMailbox" -or RecipientTypeDetails -eq "DiscoveryMailbox"} | Set-Mailbox -AuditEnabled $true -AuditLogAgeLimit 365 -AuditAdmin Update, MoveToDeletedItems, SoftDelete, HardDelete, SendAs, SendOnBehalf, Create, UpdateFolderPermission -AuditDelegate Update, SoftDelete, HardDelete, SendAs, Create, UpdateFolderPermissions, MoveToDeletedItems, SendOnBehalf -AuditOwner UpdateFolderPermission, MailboxLogin, Create, SoftDelete, HardDelete, Update, MoveToDeletedItems 

    #Double-Check It!
    #Get-Mailbox -ResultSize Unlimited | Select Name, AuditEnabled, AuditLogAgeLimit | Out-Gridview
}
function config-365($mfaType){
    #configure maf on global admins
    $O365ROLE = Get-MsolRole -RoleName “Company Administrator”
    $GlobalAdmins = Get-MsolRoleMember -RoleObjectId $O365ROLE.ObjectId
    if($mfaType -eq $null){
        $mfaType = read-host "MFA type: [Enforced|Enabled|Disabled] Default is Enabled :"
    }if($mfaType -eq $null){$mfaType = "ENABLED"}
    foreach($item in $GlobalAdmins){
         enforce-mfa $item.emailaddress $mfaType
    }

    #configure admin auditing
    Set-AdminAuditLogConfig -AdminAuditLogEnabled $true
}
function config-spo($expirationinDays){
    if($expirationinDays -eq $null){
        $expirationinDays = 90
    }
    set-spotenant -RequireAnonymousLinksExpireInDays $expirationinDays
    #put a file block on sharepoint uploads to prevent encrypted files
    (Get-SPOTenantSyncClientRestriction).excludedfileextensions
    Set-SPOTenantSyncClientRestriction  -ExcludedFileExtensions "ecc;ezz;exx;zzz;xyz;aaa;abc;ccc;vvv;xxx;ttt;micro;encrypted;locked;crypto;crinf;r5a;XRNT;XTBL;crypt;R16M01D05;pzdc;good;RDM;RRK;encryptedRSA;crjoker;EnCiPhErEd;LeChiffre;0x0;bleep;1999;vault;HA3;toxcrypt;magic;SUPERCRYPT;CTBL;CTB2;locky;cryp1;zepto"
}

function SOG-exchangerules($upn){ 
    Get-InboxRule -Mailbox $upn | Remove-InboxRule
}

[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null

function SOG-PasswordReset($upn, $newPassword) {
    if($newPassword -eq $null){
        $newPassword = ([System.Web.Security.Membership]::GeneratePassword(16,2))
    }
    Set-MsolUserPassword –UserPrincipalName $upn –NewPassword $newPassword -ForceChangePassword $True
    Write-Output "We've set the password for the account $upn to be $newPassword. Make sure you record this and share with the user, or be ready to reset the password again. They will have to reset their password on the next logon."
    
    Set-MsolUser -UserPrincipalName $upn -StrongPasswordRequired $True
}

function enforce-mfa($upn, $enforceType){
    $auth = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
    $auth.RelyingParty = "*"
    $auth.RememberDevicesNotIssuedBefore = (Get-Date)
    if(($enforceType.toupper()) -eq "ENFORCED"){
        $auth.State = "Enforced"
    }elseif(($enforceType.toupper()) -eq "DISABLED"){
        $auth = @()
    }else{
        $auth.State = "Enabled"
    }
    Set-MsolUser -UserPrincipalName $upn -StrongAuthenticationRequirements $auth

    #Get-MsolUser -UserPrincipalName $upn | select UserPrincipalName,StrongAuthenticationMethods,StrongAuthenticationRequirements
}

