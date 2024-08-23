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


###########################################
### ADDING NEW USERS TO AN ORGANISATION ###

# Define the password complexity message
$passwordComplexityMessage = @"
Password must contain at least:
     1 digit
     1 upper case character
     1 lower case character
     3 characters in total
"@

# Function to validate password complexity
function Validate-PasswordComplexity {
    param (
        [string]$Password
    )

    if ($Password.Length -lt 3) {
        return $false
    }
    if ($Password -notmatch '\d') {
        return $false
    }
    if ($Password -notmatch '[A-Z]') {
        return $false
    }
    if ($Password -notmatch '[a-z]') {
        return $false
    }
    return $true
}

# Function to select a role
function Select-Role {
    param (
        [array]$Roles
    )

    Write-Host "`nAvailable Roles:"
    for ($i = 0; $i -lt $Roles.Count; $i++) {
        Write-Host "[$($i + 1)] $($Roles[$i].Name)"
    }

    $roleIndex = [int] (Read-Host "`nEnter the number corresponding to the role for the new user")

    # Validate role selection
    while ($roleIndex -lt 1 -or $roleIndex -gt $Roles.Count) {
        Write-Host "Invalid selection. Please enter a valid number." -ForegroundColor Red
        $roleIndex = [int] (Read-Host "`nEnter the number corresponding to the role for the new user")
    }

    return $Roles[$roleIndex - 1]
}

# Prompt for the organisation at the start
$myOrganization = Read-Host "`nEnter the organisation"

# Retrieve all organisations once
$organizations = Get-AllOrganizations -authorizationToken $token

# Check if the provided organisation exists by matching the Name property
$selectedOrganization = $organizations | Where-Object { $_.Name -eq $myOrganization }

if ($null -eq $selectedOrganization) {
    Write-Host "There is no such organisation available." -ForegroundColor Red
    return
}

# Retrieve roles
$roles = Get-AllRoles -authorizationToken $token

# Check if roles were retrieved successfully
if ($null -eq $roles -or $roles.Count -eq 0) {
    Write-Host "No roles could be retrieved. Please check the roles setup and try again." -ForegroundColor Red
    return
}

# Prompt for role selection
$selectedRole = Select-Role -Roles $roles

do {
    $userCreated = $false

    while (-not $userCreated) {
        Write-Host "`nCreating a new user..." -ForegroundColor Cyan

        # Prompt for the new user's details
        $displayName = Read-Host "Enter the display name for the new user"
        $userName = Read-Host "Enter the email address (username) for the new user"

        $passwordValid = $false

        while (-not $passwordValid) {
            $password = Read-Host "Enter the password for the new user"

            # Manually validate password complexity
            if (-not (Validate-PasswordComplexity -Password $password)) {
                Write-Host ""
                Write-Host $passwordComplexityMessage -ForegroundColor Red
                Write-Host ""
                continue
            } else {
                $passwordValid = $true
            }
        }

        # Attempt to create the user with the selected role
        try {
            $newUser = New-User -authorizationToken $token -userName $userName -password $password -role $selectedRole -organization $selectedOrganization -userType "SDLUser" -displayName $displayName -emailAddress $userName

            # Check if the user was created successfully
            if ($null -ne $newUser) {
                Write-Host "New user created: $($newUser.DisplayName)" -ForegroundColor Green
                $userCreated = $true
            } else {
                Write-Host "`nAn error occurred during user creation. Please check your inputs and try again." -ForegroundColor Red
            }

        } catch {
            $errorMessage = $_.Exception.Message

            # Filter out the specific "User does not exist" error
            if ($errorMessage -notmatch "User '.*' does not exist.") {
                Write-Host "Error occured:`n$errorMessage" -ForegroundColor Red
            } else {
                Write-Host "User creation failed due to a system issue. Please check your input and try again." -ForegroundColor Red
            }
        }
    }

    # Prompt to add another user
    $addAnother = Read-Host "`nDo you want to add another user? (Y/N)"
} while ($addAnother -eq 'Y')

