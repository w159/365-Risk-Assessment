Function Set-AzureADAppPermission
{
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param
    (
        [string] $targetServicePrincipalName,
        $appPermissionsRequired,
        $childApp,
        $spForApp
    )
    if ($PSCmdlet.ShouldProcess("Target", "Operation"))
		{
        $targetSp = Get-AzureADServicePrincipal -Filter "DisplayName eq '$($targetServicePrincipalName)'"

        # Iterate Permissions array
        Write-Verbose ('Retrieve Role Assignments objects')
        $RoleAssignments = @()
        Foreach ($AppPermission in $appPermissionsRequired) {
            $RoleAssignment = $targetSp.AppRoles | Where-Object { $_.Value -eq $AppPermission}
            $RoleAssignments += $RoleAssignment
        }

        $ResourceAccessObjects = New-Object 'System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.ResourceAccess]'
        foreach ($RoleAssignment in $RoleAssignments) {
            $resourceAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess"
            $resourceAccess.Id = $RoleAssignment.Id
            $resourceAccess.Type = 'Role'
            $ResourceAccessObjects.Add($resourceAccess)
        }
        $requiredResourceAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
        $requiredResourceAccess.ResourceAppId = $targetSp.AppId
        $requiredResourceAccess.ResourceAccess = $ResourceAccessObjects

        # set the required resource access
        Set-AzureADApplication -ObjectId $childApp.ObjectId -RequiredResourceAccess $requiredResourceAccess 
        Start-Sleep -s 1

        # grant the required resource access
        foreach ($RoleAssignment in $RoleAssignments) {
            Write-Verbose ('Granting admin consent for App Role: {0}' -f $($RoleAssignment.Value))
            New-AzureADServiceAppRoleAssignment -ObjectId $spForApp.ObjectId -Id $RoleAssignment.Id -PrincipalId $spForApp.ObjectId -ResourceId $targetSp.ObjectId
            Start-Sleep -s 1
        }
    } else  {
        Write-Information "Create Azure AD Application and set permission."
    }
}

Function New-S5AppRegistration(){

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    Param(
        [int]
        $TokenLifetimeHours = "24"
    )
    
    Write-Host "Start Script $Scriptname" -ForegroundColor Yellow -BackgroundColor DarkRed

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
            -ReplyUrls "urn:ietf:wg:oauth:2.0:oob" `
            -PublicClient $false

        Write-Host ('Creating SPN for App Registration {0}' -f $DisplayName) -ForegroundColor Yellow -BackgroundColor DarkRed

        $StartDate = Get-Date
        $EndDate = $StartDate.AddHours($TokenLifetimeHours)
        $appPwd = New-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId -CustomKeyIdentifier ((New-Guid).Guid.Replace("-","").subString(0, 30)) -StartDate $StartDate -EndDate $EndDate
        $SPForApp = New-AzureADServicePrincipal -AppId $App.AppId -PasswordCredentials @($AppPwd)
        Set-AzureADAppPermission -targetServicePrincipalName $TargetServicePrincipalName -appPermissionsRequired $AppPermissionsRequired -childApp $App -spForApp $SPForApp
        Set-AzureADApplicationLogo -ObjectId $App.ObjectId -FilePath $PNGLogoPath

    } else {

        Write-Host ('App Registration {0} already exists' -f $DisplayName) -ForegroundColor Yellow -BackgroundColor DarkRed
        $App = Get-AzureADApplication -SearchString $DisplayName
        $SPForApp = Get-AzureADServicePrincipal -SearchString $App.AppId
        # create a password (spn key)
        $StartDate = Get-Date
        $EndDate = $StartDate.AddHours($TokenLifetimeHours)
        $AppPwd = New-AzureADApplicationPasswordCredential -ObjectId $App.ObjectId -CustomKeyIdentifier ((New-Guid).Guid.Replace("-","").subString(0, 30)) -StartDate $StartDate -EndDate $EndDate
        Set-AzureADAppPermission -targetServicePrincipalName $TargetServicePrincipalName -appPermissionsRequired $AppPermissionsRequired -childApp $App -spForApp $SPForApp -ErrorAction SilentlyContinue
        Set-AzureADApplicationLogo -ObjectId $App.ObjectId -FilePath $PNGLogoPath
    
    }
        $AppPermissionsRequired = @("AdvancedQuery.Read.All","Alert.Read.All","Ip.Read.All","Machine.Read.All", `
                                    "RemediationTasks.Read.All","Score.Read.All","SecurityBaselinesAssessment.Read.All", `
                                    "SecurityConfiguration.Read.All","SecurityRecommendation.Read.All","Software.Read.All", `
                                    "Url.Read.All","Vulnerability.Read.All" `
                                )

        $TargetServicePrincipalName = 'WindowsDefenderATP'

    if (!(Get-AzureADApplication -SearchString $DisplayName)) {
        $App = New-AzureADApplication -DisplayName $DisplayName `
            -Homepage "https://www.s5logic.com/" `
            -ReplyUrls "urn:ietf:wg:oauth:2.0:oob" `
            -PublicClient $false

        Write-Host ('Creating SPN for App Registration {0}' -f $DisplayName) -ForegroundColor Yellow -BackgroundColor DarkRed

        $StartDate = Get-Date
        $EndDate = $StartDate.AddHours($TokenLifetimeHours)
        $appPwd = New-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId -CustomKeyIdentifier ((New-Guid).Guid.Replace("-","").subString(0, 30)) -StartDate $StartDate -EndDate $EndDate
        $SPForApp = New-AzureADServicePrincipal -AppId $App.AppId -PasswordCredentials @($AppPwd)
     
    
    } else {

        Write-Host ('App Registration {0} already exists' -f $DisplayName) -ForegroundColor Yellow -BackgroundColor DarkRed
        $App = Get-AzureADApplication -SearchString $DisplayName
        $SPForApp = Get-AzureADServicePrincipal -SearchString $App.AppId
        # create a password (spn key)
        $StartDate = Get-Date
        $EndDate = $StartDate.AddHours($TokenLifetimeHours)
        $AppPwd = New-AzureADApplicationPasswordCredential -ObjectId $App.ObjectId -CustomKeyIdentifier ((New-Guid).Guid.Replace("-","").subString(0, 30)) -StartDate $StartDate -EndDate $EndDate
    
    }

    $CurrentLocation = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\')

    Write-Host "App Information saved to "$CurrentLocation\APP_Variables.csv"" -ForegroundColor Yellow -BackgroundColor DarkRed

    [PSCustomObject]@{
        ClientID = $App.AppId
        ClientSecret = $AppPwd.Value
        ClientSecretExpiration = $AppPwd.EndDate
        TenantId = (Get-AzureADCurrentSessionInfo).TenantId
    } | Export-CSV -Path "$CurrentLocation\APP_Variables.csv" -NoTypeInformation

    Write-Host "Please close the Powershell session and reopen it. Otherwise the connection may fail." -ForegroundColor Yellow -BackgroundColor DarkRed
    Write-Host "End Script $Scriptname" -ForegroundColor Yellow -BackgroundColor DarkRed

}
