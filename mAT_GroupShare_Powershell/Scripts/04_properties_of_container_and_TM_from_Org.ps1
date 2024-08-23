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

################################################################################
################################################################################
################################################################################

# Prompt for the organisation at the start
$myOrganization = Read-Host "`nEnter the organisation for the rest of the demo"

# Retrieve the organization object using its name
$selectedOrganization = Get-Organization -authorizationToken $token -organizationName $myOrganization

# If the organization is not found, exit the script
if ($null -eq $selectedOrganization) {
    Write-Host "There is no such organisation available." -ForegroundColor Red
    return
}

# Display the selected organization properties
Write-Host "`nSelected Organization:"
$selectedOrganization | Format-List *

# List all containers associated with the selected organization
Write-Host "`nListing all containers owned by the selected organization:" -ForegroundColor Cyan

# Retrieve all containers
$containers = Get-AllContainers -authorizationToken $token

# Filter containers by the selected organization's UniqueId (OwnerId match)
$orgContainers = $containers | Where-Object { $_.OwnerId -eq $selectedOrganization.UniqueId }

# Display the filtered containers
if ($orgContainers.Count -gt 0) {
    $orgContainers | ForEach-Object { Write-Host "Container Name: $($_.DisplayName), ContainerId: $($_.ContainerId)" }

    # Assume we are interested in the first container found (or you can modify this to select a specific one)
    $targetContainer = $orgContainers[0]

    Write-Host "`nFound Container: $($targetContainer.DisplayName)"
    
    # List all properties of the found container
    Write-Host "`nProperties of Container '$($targetContainer.DisplayName)':"
    $targetContainer | Format-List *  # This will display all properties of the container

    # Retrieve all TMs
    $tms = Get-AllTMs -authorizationToken $token

    # Filter TMs by the target container's ContainerId
    $containerTMs = $tms | Where-Object { $_.ContainerId -eq $targetContainer.ContainerId }

    if ($containerTMs.Count -gt 0) {
        Write-Host "`nTranslation Memories in Container '$($targetContainer.DisplayName)':"
        $containerTMs | ForEach-Object { 
            Write-Host "TM Name: $($_.Name)"
            
            # Display all properties of the TM
            Write-Host "`nProperties of Translation Memory '$($_.Name)':"
            $_ | Format-List *
        }
    } else {
        Write-Host "No Translation Memories found in Container '$($targetContainer.DisplayName)'." -ForegroundColor Yellow
    }
} else {
    Write-Host "No containers found in the selected organization." -ForegroundColor Yellow
}
