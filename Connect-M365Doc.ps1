Function Connect-M365Doc(){

    [CmdletBinding(DefaultParameterSetName = 'Interactive')]
    param(
        [parameter(Mandatory=$true, ParameterSetName='CustomToken')]
        [Microsoft.Identity.Client.AuthenticationResult]$token,
        [parameter(Mandatory=$true, ParameterSetName='PublicClient-Silent')]
        [guid]$ClientID,
        [parameter(Mandatory=$true, ParameterSetName='PublicClient-Silent')]
        [string]$ClientSecret,
        [parameter(Mandatory=$true, ParameterSetName='PublicClient-Silent')]
        [guid]$TenantId ,
        [parameter(Mandatory=$false, ParameterSetName='Interactive')]
        [switch]$Force
    )
    switch -Wildcard ($PSCmdlet.ParameterSetName) {
        "CustomToken" {
            # Verify token
            if ($token.ExpiresOn.LocalDateTime -le $(Get-Date)) {
                Write-Error "Token expired, please pass a valid and not expired token."
            } elseif($null -eq $token){
                Write-Error "No Token passed as token parameter, please pass a valid and not expired token."
            } else {
                $script:token = $token
            }
           break
        }
        "PublicClient-Silent" {
           # Connect to Microsoft Intune PowerShell App
            $params = @{
                ClientId = $ClientId
                RedirectUri = "msal37f82fa9-674e-4cae-9286-4b21eb9a6389://auth"
                TenantId = $TenantId
                ClientSecret = $ClientSecret
                
            }
            $script:token = Get-MsalToken @params
            # Verify token
            if (-not ($script:token -and $script:token.ExpiresOn.LocalDateTime -ge $(Get-Date))) {
                Write-Error "Connection failed."
            }
            break
        }
       "Interactive" {
            # Connect to Microsoft Intune PowerShell App
            $params = @{
                ClientId    = "37f82fa9-674e-4cae-9286-4b21eb9a6389"
                RedirectUri = "msal37f82fa9-674e-4cae-9286-4b21eb9a6389://auth"
            }

            # Verify token
            if (-not ($token -and $token.ExpiresOn.LocalDateTime -ge $(Get-Date))) {
                $script:token = Get-MsalToken @params
            } else {
                if($Force){
                    Write-Information "Force reconnection"
                    $script:token = Get-MsalToken @params
                } else {
                    Write-Information "Already connected."
                }
            }
           break
       }
   }
    
}