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


##################################################
### Pull the known details for a specific user ###
# Prompt for the username
$myUsername = Read-Host "`nEnter the username of the user in question"

# Retrieve the user object using the username
$user = Get-User -authorizationToken $token -userName $myUsername

# Check if the user was found
if ($null -eq $user) {
    Write-Host "User '$myUsername' was not found." -ForegroundColor Red
    return
}

# Display basic user properties excluding the 'Roles' property
Write-Host "`nProperties of User '$($user.DisplayName)':"
$user | Select-Object -Property UniqueId, Name, DisplayName, Description, EmailAddress, PhoneNumber, Locale, OrganizationId, UserType, IsProtected | Format-List

# Fetch and display roles grouped by organization
Write-Host "Roles for User '$($user.DisplayName)':" -ForegroundColor Cyan
$roleGroups = @{}

foreach ($role in $user.Roles) {
    # Get the organization
    $organization = Get-Organization -authorizationToken $token -organizationId $role.OrganizationId
    $organizationName = if ($organization) { $organization.Name } else { "Unknown Organization" }
    
    # Get the role name
    $roleDetails = Get-Role -authorizationToken $token -roleId $role.RoleId
    $roleName = if ($roleDetails) { $roleDetails.Name } else { "Unknown Role" }
    
    # Group roles by organization
    if (-not $roleGroups.ContainsKey($organizationName)) {
        $roleGroups[$organizationName] = @()
    }
    $roleGroups[$organizationName] += $roleName
}

# Print the roles grouped by organization in the desired format
foreach ($org in $roleGroups.Keys) {
    Write-Host "`tOrganization: $org" -ForegroundColor Yellow
    $roleGroups[$org] | ForEach-Object { Write-Host "`t`tRole: $_" -ForegroundColor Green }
}
