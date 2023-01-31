##########################################################
# Installed required Windows Features & PowerShell Modules
##########################################################

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$MaximumFunctionCount = 10000
# https://github.com/microsoftgraph/msgraph-sdk-powershell

###############################################
# These are not the droids you're looking for..
###############################################

Select-MgProfile -Name "beta"

$RequiredModules = @(

    'AzureAD',
    'Az.Resources',
    'Microsoft.Graph',
    'PSWriteWord',
    'MSAL.PS',
    'PSWriteHTML'

)


foreach ($RequiredModule in $RequiredModules){
if(-not (Get-Module $RequiredModule -ListAvailable)){
        "Installing $RequiredModule now, please wait...."
        Install-Module $RequiredModule -AllowClobber -Force
        "Importing $RequiredModule now, please wait...."
        Import-Module $RequiredModule
    }
}


(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/w159/365-Risk-Assessment/main/Connect-O365Services.ps1') | iex
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/w159/365-Risk-Assessment/main/New-S5AppRegistration.ps1') | iex


#############################
# Variables to Prompt For
#############################
# Path to Logo.png file - Prompts for file select using Explorer dialog
$FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
    InitialDirectory = [Environment]::GetFolderPath('Desktop') 
    Filter = 'PNG (*.png)|*.png'
}
$null = $FileBrowser.ShowDialog()
$PNGLogoPath = $FileBrowser.FileName


# Tenant Domain - Prompts for Tenant Default Domain
Add-Type -AssemblyName Microsoft.VisualBasic
$DomainPromptTitle = 'Tenant Domain'
$DomainPromptMessage   = 'Enter 365 Tenant Default Domain (ie "Domain.com"):'
$TenantDomain = [Microsoft.VisualBasic.Interaction]::InputBox($DomainPromptMessage, $DomainPromptTitle)


## The following four lines only need to be declared once in your script.
$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Description."
$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Description."
$Cancel = New-Object System.Management.Automation.Host.ChoiceDescription "&Cancel","Description."
$Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No, $Cancel)
## Use the following each time your want to prompt the use
$AppRegistrationCheckTitle = "App Registration Check" 
$AppRegistrationCheckmessage = "Has the S5 Risk Assessment App been created yet?"
$AppRegistrationCheckresult = $host.ui.PromptForChoice($AppRegistrationCheckTitle, $AppRegistrationCheckmessage, $Options, 1)
switch ($AppRegistrationCheckresult) {
  0{
    Write-Host "Yes"
  }1{
    Write-Host "No"
  }2{
  Write-Host "Cancel"
  }
}
# Select stored in $AppRegistrationCheckresult variable
# Yes = 0 & and No = 1


################################################
# Create S5 Risk Assessment Report App if needed
################################################

# Connect to your tenant
Connect-O365Services
Connect-AzureAD -TenantId "$TenantDomain"

if ($AppRegistrationCheckresult -eq "1") {

    New-S5AppRegistration -TokenLifetimeDays "365"
    $DisplayName = "S5 Logic - Risk Assessment Report"
    $App = Get-AzureADApplication -SearchString $DisplayName
    $StartDate = Get-Date
    $EndDate = $StartDate.AddDays(365)
    $appPwd = New-AzureADApplicationPasswordCredential -ObjectId $app.ObjectId -CustomKeyIdentifier ((New-Guid).Guid.Replace("-","").subString(0, 30)) -StartDate $StartDate -EndDate $EndDate

    
    $clientId = $App.AppId
    $clientSecret = $AppPwd.Value
    $tenantID = (Get-AzureADCurrentSessionInfo).TenantId

}


## Use the following each time your want to prompt the use
$GrantAdminConsentTitle = "Grant Admin Consent for S5 Risk Assessment App" 
$GrantAdminConsentmessage = "The S5 Risk Assessment App needs to be granted Admin consent. Would you like to open Chrome to do this now?"
$GrantAdminConsentresult = $host.ui.PromptForChoice($GrantAdminConsentTitle, $GrantAdminConsentmessage, $Options, 1)
switch ($AppRegistrationCheckresult) {
  0{
    Write-Host "Yes"
  }1{
    Write-Host "No"
  }2{
  Write-Host "Cancel"
  }
}
# Select stored in $AppRegistrationCheckresult variable
# Yes = 0 & and No = 1
if ($GrantAdminConsentresult -eq "0") {

    Start-Process "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/CallAnAPI/appId/$clientId/isMSAApp~/false"
    
}

# Using interactive authentication.
Connect-MgGraph -Scopes "User.ReadBasic.All", "Application.ReadWrite.All"


