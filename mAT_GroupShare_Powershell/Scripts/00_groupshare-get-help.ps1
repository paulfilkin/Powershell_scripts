#############################################
### SIGN IN, IMPORT MODULES, AUTHENTICATE ###

# Import the GroupShareToolkit module
Import-Module -Name "c:\Users\pfilkin\Documents\GroupSharePowershellToolkit\Modules\GroupShareToolkit\GroupShareToolkit.psm1"

# Get the credentials from the CredentialStore directory
$credentials = Get-Credentials
if ($credentials) {
    # $datasetName = $credentials.DatasetName
    $server = $credentials.ServerUrl
    $credential = $credentials.Credential

    # Import the GroupShare modules, pass $server as a parameter
    Import-GroupShareModules -ScriptParentDir (Split-Path -Parent $MyInvocation.MyCommand.Path) -ServerUrl $server

    # Connect and authenticate the user
    $token = Connect-User -ServerUrl $server -Credential $credential
}

Write-Host "`nNow get-help`n" -ForegroundColor Green