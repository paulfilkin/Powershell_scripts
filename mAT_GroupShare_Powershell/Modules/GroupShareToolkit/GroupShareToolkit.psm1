# GroupShareToolkit.psm1

<#
.SYNOPSIS
    Provides functions for automating GroupShare tasks.

.DESCRIPTION
    The GroupShareToolkit module includes functions to handle authentication, 
    module loading, and user management for GroupShare.

    This module is designed to simplify working with GroupShare APIs, providing 
    a set of tools that can be used to interact with the server, authenticate 
    users, and perform various tasks related to project management and resource 
    handling.

.EXAMPLE
    Import the module:
    Import-Module GroupShareToolkit

    Get help on specific functions:
    Get-Help Get-Credentials
    Get-Help Connect-User
    Get-Help Import-GroupShareModules

.NOTES
    For more detailed examples and usage, refer to the individual function help 
    or the official GroupShare documentation.
#>

<#
    function Get-Credentials

    .SYNOPSIS
    Retrieves user credentials and server information from an XML file.

    .DESCRIPTION
    The `Get-Credentials` function opens a file dialog allowing the user to select an XML file that contains encrypted credentials and server information.
    The function constructs the path to the `CredentialStore` directory based on the location of the executing script. The selected XML file is then imported,
    and the secure data is returned as a PowerShell object.

    The returned object typically contains properties such as `DatasetName`, `Credential`, and `ServerUrl`, which can be used for subsequent operations that require
    authentication or server details.

    .PARAMETER ScriptParentDir
    The directory path where the script is located. This is used to determine the initial location of the `CredentialStore` directory.

    .PARAMETER CredentialStoreFolder
    The name of the folder where the credential XML files are stored. The default is `"CredentialStore"`. This folder is assumed to be located one level above the script's directory.

    .EXAMPLE
    $credentials = Get-Credentials -ScriptParentDir "C:\Scripts\GroupShare"

    Opens a file dialog starting in the `CredentialStore` directory located one level above `C:\Scripts\GroupShare`. The selected XML file is imported and returned as a secure object.

    .EXAMPLE
    $credentials = Get-Credentials

    Opens a file dialog starting in the default `CredentialStore` directory located one level above the script's directory. The selected XML file is imported and returned as a secure object.

    .NOTES
    The function uses the Windows Forms library to open a file dialog, which requires that the user be operating in a graphical user interface (GUI) environment.
    If the user cancels the file selection dialog, the function returns `$null` and the script is terminated with an appropriate message.

    The XML file must be in a specific format compatible with `Import-CliXml` to ensure that the secure data is correctly deserialized.

    .OUTPUTS
    [PSCustomObject]

    The function returns a PowerShell object containing the deserialized secure data from the XML file. This object typically includes properties such as `DatasetName`, `Credential`, and `ServerUrl`.

    .LINK
    See also `Import-CliXml` cmdlet for more information on how XML data is imported and deserialized into PowerShell objects.
#>

function Get-Credentials {
    param (
        [string]$ScriptParentDir = $(if ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { $PWD.Path }),
        [string]$CredentialStoreFolder = "CredentialStore" # PSScriptAnalyzer rule: PSAvoidUsingPlainTextForPassword - suppress warning
    )

    # Construct the relative path to the CredentialStore directory
    $directoryPath = Join-Path -Path $ScriptParentDir -ChildPath "..\$CredentialStoreFolder"

    # Normalize the path
    $directoryPath = [System.IO.Path]::GetFullPath($directoryPath)

    # Open a file dialog to select the XML file
    Add-Type -AssemblyName System.Windows.Forms
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.InitialDirectory = $directoryPath
    $fileDialog.Filter = "XML files (*.xml)|*.xml"
    $fileDialog.Multiselect = $false

    $dialogResult = $fileDialog.ShowDialog()

    if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedFile = $fileDialog.FileName
    } else {
        Write-Host "No file selected. Exiting script." -ForegroundColor Red
        return $null
    }

    $secureData = Import-CliXml -Path $selectedFile
    return $secureData
}




<#
    function Import-GroupShareModules

    .SYNOPSIS
    Loads the specified GroupShare PowerShell modules from the defined directories.

    .DESCRIPTION
    The `Load-GroupShareModules` function is designed to dynamically load a set of GroupShare-related PowerShell modules
    from specified directories. It first attempts to load the modules from a directory relative to the script's location.
    If the modules are not found there, it then attempts to load them from a fallback directory within the user's profile.

    The function takes a list of module names and attempts to load each one. If a module is found, it is imported into the
    current PowerShell session. If a module is not found, an error message is displayed.

    .PARAMETER ScriptParentDir
    The directory path where the script is located. This is used to determine the initial location from which to load the modules.

    .PARAMETER UserProfileModulesDir
    The fallback directory within the user's profile from which to load the modules if they are not found in the initial location.
    The default is `"Documents\GroupSharePowershellToolkit\Modules"`.

    .PARAMETER Modules
    An array of module names that should be loaded. The function will attempt to load each module by its name, looking for a `.psm1`
    file within the specified directories.

    .EXAMPLE
    Load-GroupShareModules -ScriptParentDir "C:\Scripts\GroupShare"

    Attempts to load the modules from the `C:\Scripts\GroupShare\Modules` directory first, and then falls back to the user's profile
    if the modules are not found.

    .EXAMPLE
    $customModules = @("CustomModule1", "CustomModule2")
    Load-GroupShareModules -ScriptParentDir "C:\Scripts\GroupShare" -Modules $customModules

    Loads the custom list of modules specified in the `$customModules` array from the directories defined by `ScriptParentDir` and `UserProfileModulesDir`.

    .NOTES
    The function assumes that the modules are stored in directories named after the modules themselves, with each module having a `.psm1` file
    within its respective directory.

    If a module is not found in either the script's directory or the fallback directory, an error message is displayed.

    .OUTPUTS
    None. The function loads modules into the current session but does not return a value.

    .LINK
    See also `Import-Module` cmdlet for more information on how modules are loaded into a PowerShell session.
#>


function Import-GroupShareModules {
    param (
        [string]$ScriptParentDir,
        [string]$UserProfileModulesDir = "$Env:USERPROFILE\Documents\GroupSharePowershellToolkit\Modules",
        [string[]]$Modules = @(
            "AuthenticationHelper",
            "BackgroundTaskHelper",
            "ProjectServerHelper",
            "ResourcesHelper",
            "SystemConfigurationHelper",
            "UserManagerHelper"
        ),
        [string]$ServerUrl # New parameter to pass the server URL
    )

    $modulesDir = Join-Path $ScriptParentDir "Modules"

    if (-not (Test-Path $modulesDir)) {
        $modulesDir = $UserProfileModulesDir
    }

    $importResults = @()

    foreach ($module in $Modules) {
        $modulePath = Join-Path $modulesDir "$module\$module.psm1"
        if (-not (Test-Path $modulePath)) {
            $importResults += [PSCustomObject]@{Module = $module; Status = "File Not Found"}
            continue
        }

        Write-Host "Importing module: $module" -ForegroundColor Cyan
        Import-Module -Name $modulePath -Scope Global -ArgumentList $ServerUrl -ErrorAction SilentlyContinue

        if (Get-Module -Name $module) {
            $importResults += [PSCustomObject]@{Module = $module; Status = "Success"}
        } else {
            $importResults += [PSCustomObject]@{Module = $module; Status = "Failed"}
        }
    }

    Write-Host "`nModules import process completed." -ForegroundColor Green

    # Report the results
    Write-Host "`nImport Summary:" -ForegroundColor Yellow
    foreach ($result in $importResults) {
        if ($result.Status -eq "Success") {
            Write-Host "Successfully imported module: $($result.Module)" -ForegroundColor Green
        } elseif ($result.Status -eq "File Not Found") {
            Write-Host "Module file not found: $($result.Module)" -ForegroundColor Red
        } else {
            Write-Host "Failed to import module: $($result.Module)" -ForegroundColor Red
        }
    }
}




<#
    function Connect-User

    .SYNOPSIS
    Authenticates the user against the GroupShare server and retrieves an authorization token.

    .DESCRIPTION
    The `Authenticate-User` function generates an authorization token for the GroupShare server using the provided credentials.
    This token can then be used for subsequent requests to access protected resources on the server.
    
    The function takes in the server URL and user credentials (username and password) and returns an authorization token as a string.
    This token should be stored in a variable for reuse with other functions that require authenticated access to the GroupShare server.

    .PARAMETER ServerUrl
    The base URL of the GroupShare server. This should be the URL where the authentication endpoint is hosted.
    Example: "https://yourgroupshare.server.com"

    .PARAMETER Credential
    A PSCredential object containing the username and password of the user. The username and password are required for authentication
    and must be valid for the GroupShare server.

    .EXAMPLE
    $credential = Get-Credential
    $token = Authenticate-User -ServerUrl "https://yourgroupshare.server.com" -Credential $credential

    Retrieves an authorization token using the provided credentials and server URL. The token is stored in the `$token` variable.

    .EXAMPLE
    $credential = New-Object System.Management.Automation.PSCredential("username", (ConvertTo-SecureString "password" -AsPlainText -Force))
    $token = Authenticate-User -ServerUrl "https://yourgroupshare.server.com" -Credential $credential

    Manually creates a PSCredential object and retrieves an authorization token using the provided credentials and server URL.

    .NOTES
    Ensure that the `SignIn` function is available and properly implemented, as it is used internally to handle the authentication process.

    If the credentials are invalid or the server URL is incorrect, the function will output an error message indicating the failure.
    This function is essential for any script or module that interacts with GroupShare server resources requiring authentication.

    .OUTPUTS
    [System.String]

    The function returns a string representing the access token. This token should be passed to other functions that require
    authentication to access GroupShare resources.

    .LINK
    See also `SignIn` function which is invoked within this function to handle the HTTP request and response for authentication.
#>


function Connect-User {
    param (
        [string]$ServerUrl,
        [PSCredential]$Credential
    )

    $userName = $Credential.UserName
    $password = $Credential.GetNetworkCredential().Password

    $authenticationUrl = $ServerUrl.TrimEnd('/') + "/authentication"
    Write-Host "`nAuthentication URL: $authenticationUrl" -ForegroundColor Cyan

    $token = SignIn -userName $userName -password $password

    Write-Host "Authentication process completed." -ForegroundColor Green

    return $token
}