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


##########################################
# Prompt for the organisation at the start
$myOrganization = Read-Host "`nEnter the organisation name"

# Retrieve all organisations once
$organizations = Get-AllOrganizations -authorizationToken $token

# Check if the provided organisation exists by matching the Name property
$selectedOrganization = $organizations | Where-Object { $_.Name -eq $myOrganization }

if ($selectedOrganization.Count -eq 0) {
    Write-Host "There is no such organisation available." -ForegroundColor Red
    return
} elseif ($selectedOrganization.Count -gt 1) {
    Write-Host "Multiple organisations found with the name '$myOrganization'. Please specify a unique name." -ForegroundColor Red
    return
} else {
    $selectedOrganization = $selectedOrganization[0]  # Access the first and only match
}

#######################################################
# List all users in the specified organisation
Write-Host "`nListing all users in the organisation $($selectedOrganization.Name):" -ForegroundColor Cyan

# Retrieve users for the specific organization without a limit
$users = Get-AllUsers -authorizationToken $token -organization $selectedOrganization

# Check if users were retrieved successfully
if ($null -eq $users -or $users.Count -eq 0) {
    Write-Host "No users found in the organisation '$($selectedOrganization.Name)'." -ForegroundColor Yellow
    return
}

# Create a table with the required fields, including retrieving roles for each user
$usersTable = $users | ForEach-Object {
    # Retrieve detailed user information to access roles
    $userDetails = Get-User -authorizationToken $token -userId $_.UniqueId

    # Fetch roles and map them to their organization names
    $roles = @()
    if ($userDetails -and $userDetails.Roles) {
        foreach ($role in $userDetails.Roles) {
            # Get the role name
            $roleDetails = Get-Role -authorizationToken $token -roleId $role.RoleId
            $roleName = if ($roleDetails) { $roleDetails.Name } else { "Unknown Role" }
            $roles += $roleName
        }
    }

    [PSCustomObject]@{
        "Display Name" = $_.DisplayName
        "User Type"    = $_.UserType
        "Username"     = $_.Name
        "Email"        = $_.EmailAddress
        "Roles"        = $roles -join ", "
    }
}

# Display the table in the console
$usersTable | Format-Table -AutoSize
