

Function New-AppRegistration(){
  <#
  .DESCRIPTION
  This script will create an App registration in Azure AD. Global Admin privileges are required during execution of this function. 
  Afterwards the created client secret can be used to execute the Intune Documentation silently. 

  .EXAMPLE
  $S5App = New-AppRegistration
  $S5App | Format-List

  ClientID               : d5cf6364-82f7-4024-9ac1-73a9fd2a6ec3
  ClientSecret           : S03AESdMlhLQIPYYw/cYtLkGkQS0H49jXh02AS6Ek0U=
  ClientSecretExpiration : 21.07.2025 21:39:02
  TenantId               : d873f16a-73a2-4ccf-9d36-67b8243ab99a

  #>
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
  Param(
      [int]
      $TokenLifetimeDays = 365
  )
  
  #region Initialization
  ########################################################
  Write-Host "Start Script New-AppRegistration for Microsoft Graph" -ForegroundColor Yellow -BackgroundColor Green

  $AzureAD = Get-Module -Name AzureAD
  if($AzureAD){
      Write-Host -Message "AzureAD module is loaded." -ForegroundColor Yellow -BackgroundColor Green
  } else {
      Write-Host -Message "AzureAD module is not loaded, please install by 'Install-Module AzureAD'." -ForegroundColor Yellow -BackgroundColor DarkRed
  }

  #region Authentication
  Connect-AzureAD | Out-Null
  #endregion
  #region Main Script
  ########################################################
  
  $displayName = "S5 Logic - Risk Assessment Report"
  $GraphappPermissionsRequired   = @("AccessReview.Read.All","Agreement.Read.All","AppCatalog.Read.All","Application.Read.All", `
                                "CloudPC.Read.All","ConsentRequest.Read.All","Device.Read.All","DeviceManagementApps.Read.All", `
                                "DeviceManagementConfiguration.Read.All","DeviceManagementManagedDevices.Read.All","DeviceManagementRBAC.Read.All", `
                                "DeviceManagementServiceConfig.Read.All","Directory.Read.All","Domain.Read.All","Organization.Read.All", `
                                "Policy.Read.All","Policy.ReadWrite.AuthenticationMethod","Policy.ReadWrite.FeatureRollout","PrintConnector.Read.All", `
                                "Printer.Read.All","PrinterShare.Read.All","PrintSettings.Read.All","PrivilegedAccess.Read.AzureAD","PrivilegedAccess.Read.AzureADGroup", `
                                "PrivilegedAccess.Read.AzureResources","User.Read","IdentityProvider.Read.All","InformationProtectionPolicy.Read.All","Calendars.Read" `
                                )

  $GraphtargetServicePrincipalName = 'Microsoft Graph'

  if (!(Get-AzureADApplication -SearchString $displayName)) {
      $app = New-AzureADApplication -DisplayName $displayName `
          -Homepage "https://www.s5logic.com/" `
          -ReplyUrls "urn:ietf:wg:oauth:2.0:oob" `
          -PublicClient $false


      # create SPN for App Registration
      Write-Host ('Creating SPN for Graph App Registration {0}' -f $displayName) -ForegroundColor Yellow -BackgroundColor DarkRed

      # create a password (spn key)
      $startDate = Get-Date
      $endDate = $startDate.AddDays($TokenLifetimeDays)
      $appPwd = New-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId -CustomKeyIdentifier ((New-Guid).Guid.Replace("-","").subString(0, 30)) -StartDate $startDate -EndDate $endDate

      # create a service principal for your application
      # you need this to be able to grant your application the required permission
      $spForApp = New-AzureADServicePrincipal -AppId $app.AppId -PasswordCredentials @($appPwd)
      Set-GraphAzureADAppPermission -targetServicePrincipalName $GraphtargetServicePrincipalName -appPermissionsRequired $GraphappPermissionsRequired -childApp $app -spForApp $spForApp
      Set-AzureADApplicationLogo -ObjectId $App.ObjectId -FilePath $PNGLogoPath
  
  } else {

      Write-Host ('App Registration {0} already exists. Updating Graph permissions.' -f $displayName) -ForegroundColor Yellow -BackgroundColor DarkRed
      $app = Get-AzureADApplication -SearchString $displayName
      $spForApp = Get-AzureADServicePrincipal -SearchString $app.AppId
      # create a password (spn key)
      $startDate = Get-Date
      $endDate = $startDate.AddDays($TokenLifetimeDays)
      $appPwd = New-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId -CustomKeyIdentifier ((New-Guid).Guid.Replace("-","").subString(0, 30)) -StartDate $startDate -EndDate $endDate
      Set-GraphAzureADAppPermission -targetServicePrincipalName $GraphtargetServicePrincipalName -appPermissionsRequired $GraphappPermissionsRequired -childApp $app -spForApp $spForApp -ErrorAction SilentlyContinue
  
  }

  $DefenderappPermissionsRequired   = @("AdvancedQuery.Read.All","Alert.Read.All","Ip.Read.All","Machine.Read.All", `
                                        "RemediationTasks.Read.All","Score.Read.All","SecurityBaselinesAssessment.Read.All", `
                                        "SecurityConfiguration.Read.All","SecurityRecommendation.Read.All","Software.Read.All", `
                                        "Url.Read.All","Vulnerability.Read.All" `
                                        )

  $DefendertargetServicePrincipalName = 'WindowsDefenderATP'

  if (!(Get-AzureADApplication -SearchString $displayName)) {
      $app = New-AzureADApplication -DisplayName $displayName `
          -Homepage "https://www.s5logic.com/" `
          -ReplyUrls "urn:ietf:wg:oauth:2.0:oob" `
          -PublicClient $false


      # create SPN for App Registration
      Write-Host ('Creating SPN for Defender App Registration {0}' -f $displayName) -ForegroundColor Yellow -BackgroundColor DarkRed

      # create a password (spn key)
      $startDate = Get-Date
      $endDate = $startDate.AddDays($TokenLifetimeDays)
      $appPwd = New-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId -CustomKeyIdentifier ((New-Guid).Guid.Replace("-","").subString(0, 30)) -StartDate $startDate -EndDate $endDate

      # create a service principal for your application
      # you need this to be able to grant your application the required permission
      $spForApp = New-AzureADServicePrincipal -AppId $app.AppId -PasswordCredentials @($appPwd)
      Set-DefenderAzureADAppPermission -targetServicePrincipalName $DefendertargetServicePrincipalName -appPermissionsRequired $DefenderappPermissionsRequired -childApp $app -spForApp $spForApp
  
  } else {

      Write-Host ('App Registration {0} already exists. Updating Defender permissions.' -f $displayName) -ForegroundColor Yellow -BackgroundColor DarkRed
      $app = Get-AzureADApplication -SearchString $displayName
      $spForApp = Get-AzureADServicePrincipal -SearchString $app.AppId
      # create a password (spn key)
      $startDate = Get-Date
      $endDate = $startDate.AddDays($TokenLifetimeDays)
      $appPwd = New-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId -CustomKeyIdentifier ((New-Guid).Guid.Replace("-","").subString(0, 30)) -StartDate $startDate -EndDate $endDate
      Set-DefenderAzureADAppPermission -targetServicePrincipalName $DefendertargetServicePrincipalName -appPermissionsRequired $DefenderappPermissionsRequired -childApp $app -spForApp $spForApp -ErrorAction SilentlyContinue
  
  }

  #endregion
  #region Finishing
  ########################################################
  [PSCustomObject]@{
      ClientID = $app.AppId
      ClientSecret = $appPwd.Value
      ClientSecretExpiration = $appPwd.EndDate
      TenantId = (Get-AzureADCurrentSessionInfo).TenantId
  }

  Write-Host "Please close the Powershell session and reopen it. Otherwise the connection may fail." -ForegroundColor Yellow -BackgroundColor DarkRed
  Write-Host "End Script $Scriptname" -ForegroundColor Yellow -BackgroundColor DarkRed
  #endregion

}

