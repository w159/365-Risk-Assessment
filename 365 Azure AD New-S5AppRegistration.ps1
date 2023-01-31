Function New-S5AppRegistration(){

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    Param(
        [int]
        $TokenLifetimeDays = 365
    )
    
    Write-Host "Start Script $Scriptname"

    $AzureAD = Get-Module -Name AzureAD
    if($AzureAD){
        Write-Verbose -Message "AzureAD module is loaded."
    } else {
        Write-Warning -Message "AzureAD module is not loaded, please install by 'Install-Module AzureAD'."
    }

    Connect-AzureAD | Out-Null

    $DisplayName = "S5 Logic - Risk Assessment Report"
    $AppPermissionsRequired = @("AccessReview.Read.All","Agreement.Read.All","AppCatalog.Read.All","Application.Read.All", `
                                "CloudPC.Read.All","ConsentRequest.Read.All","Device.Read.All","DeviceManagementApps.Read.All", `
                                "DeviceManagementConfiguration.Read.All","DeviceManagementManagedDevices.Read.All","DeviceManagementRBAC.Read.All", `
                                "DeviceManagementServiceConfig.Read.All","Directory.Read.All","Domain.Read.All","Organization.Read.All", `
                                "Policy.Read.All","Policy.ReadWrite.AuthenticationMethod","Policy.ReadWrite.FeatureRollout","PrintConnector.Read.All", `
                                "Printer.Read.All","PrinterShare.Read.All","PrintSettings.Read.All","PrivilegedAccess.Read.AzureAD","PrivilegedAccess.Read.AzureADGroup", `
                                "PrivilegedAccess.Read.AzureResources","User.Read" ,"IdentityProvider.Read.All","InformationProtectionPolicy.Read.All" `
                                )

    $TargetServicePrincipalName = 'Microsoft Graph'

    if (!(Get-AzureADApplication -SearchString $DisplayName)) {
        $App = New-AzureADApplication -DisplayName $DisplayName `
            -Homepage "https://www.s5logic.com/" `
            -ReplyUrls "https://www.s5logic.com/" `
            -PublicClient $false

        Write-Debug ('Creating SPN for App Registration {0}' -f $DisplayName)

        $StartDate = Get-Date
        $EndDate = $StartDate.AddDays($TokenLifetimeDays)
        $appPwd = New-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId -CustomKeyIdentifier ((New-Guid).Guid.Replace("-","").subString(0, 30)) -StartDate $StartDate -EndDate $EndDate

        $SPForApp = New-AzureADServicePrincipal -AppId $App.AppId -PasswordCredentials @($AppPwd)
        Set-AzureADAppPermission -targetServicePrincipalName $TargetServicePrincipalName -appPermissionsRequired $AppPermissionsRequired -childApp $App -spForApp $SPForApp
        Set-AzureADApplicationLogo -ObjectId $App.ObjectId -FilePath $PNGLogoPath
    
    } else {

        Write-Debug ('App Registration {0} already exists' -f $DisplayName)
        $App = Get-AzureADApplication -SearchString $DisplayName
        $SPForApp = Get-AzureADServicePrincipal -SearchString $App.AppId
        # create a password (spn key)
        $StartDate = Get-Date
        $EndDate = $StartDate.AddDays($TokenLifetimeDays)
        $AppPwd = New-AzureADApplicationPasswordCredential -ObjectId $App.ObjectId -CustomKeyIdentifier ((New-Guid).Guid.Replace("-","").subString(0, 30)) -StartDate $StartDate -EndDate $EndDate
        Set-AzureADAppPermission -targetServicePrincipalName $TargetServicePrincipalName -appPermissionsRequired $AppPermissionsRequired -childApp $App -spForApp $SPForApp -ErrorAction SilentlyContinue
        Set-AzureADApplicationLogo -ObjectId $App.ObjectId -FilePath $PNGLogoPath
    
    }

    [PSCustomObject]@{
        ClientID = $App.AppId
        ClientSecret = $AppPwd.Value
        ClientSecretExpiration = $AppPwd.EndDate
        TenantId = (Get-AzureADCurrentSessionInfo).TenantId
    }

    Write-Log -Type Warn -Message "Please close the Powershell session and reopen it. Otherwise the connection may fail."
    Write-Log "End Script $Scriptname"

}