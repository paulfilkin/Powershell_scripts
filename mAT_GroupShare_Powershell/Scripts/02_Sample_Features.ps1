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


###################################
### START THE SAMPLE DEMOS HERE ###

# Retrieve and count the containers
$containers = Get-AllContainers -authorizationToken $token
$containerCount = $containers.Count
Write-Host "`n$containerCount containers found. Listing a maximum of 10 only." -ForegroundColor Yellow

# List the first 10 containers at most
Write-Host "`nListing up to the first 10 containers:" -ForegroundColor Cyan
for ($i = 0; $i -lt $containerCount -and $i -lt 10; $i++) {
    Write-Host "[$($i + 1)] $($containers[$i].DisplayName)" -ForegroundColor Green
}

# Retrieve and count the organizations
$organizations = Get-AllOrganizations -authorizationToken $token
$organizationCount = $organizations.Count
Write-Host "`n$organizationCount organizations found. Listing a maximum of 10 only." -ForegroundColor Yellow

# List up to the first 10 organizations
Write-Host "`nListing the first 10 organizations:" -ForegroundColor Cyan
for ($i = 0; $i -lt $organizationCount -and $i -lt 10; $i++) {
    Write-Host "[$($i + 1)] $($organizations[$i].Name)" -ForegroundColor Green
}


# Prompt for the organisation at the start
$myOrganization = Read-Host "`nEnter the organisation for the rest of the demo"

# Retrieve all organisations once
$organizations = Get-AllOrganizations -authorizationToken $token

# Check if the provided organisation exists by matching the Name property
$selectedOrganization = $organizations | Where-Object { $_.Name -eq $myOrganization }

if ($null -eq $selectedOrganization) {
    Write-Host "There is no such organisation available." -ForegroundColor Red
    return
}


# ########################################################################################
# # This is left commented out because it requires administrative permissions above my own
# # Prompt for the container name, and container database name
# $containerName = Read-Host "Enter the container name"
# $containerDbName = Read-Host "Enter the container database name"

# # Create a new container within the selected organization
# Write-Host "`nCreating a new container..." -ForegroundColor Cyan

# # Retrieve available database servers
# $dbServers = Get-AllDbServers -authorizationToken $token

# # Create the new container using the provided details
# $workingContainer = New-Container -authorizationToken $token -containerName $containerName -organization $selectedOrganization -dbServer $dbServers[0] -containerDbName $containerDbName

# # Check if the container was created; if not, retrieve the existing one
# if ($null -eq $workingContainer) {
#     Write-Host "Container already exists. Retrieving the existing container..." -ForegroundColor Yellow
#     $workingContainer = Get-Container -authorizationToken $token -containerName $containerName
# } else {
#     Write-Host "New container created successfully: $($workingContainer.DisplayName)" -ForegroundColor Green
# }


#######################################################
# List the first 10 users in the specified organisation
Write-Host "`nListing up to 10 users in the organisation $($selectedOrganization.Name):" -ForegroundColor Cyan

# Retrieve users for the specific organization
$users = Get-AllUsers -authorizationToken $token -organization $selectedOrganization -maxLimit 10

# Iterate through the users and display their display names
for ($i = 0; $i -lt $users.Count; $i++) {
    Write-Host "[$($i + 1)] $($users[$i].DisplayName)" -ForegroundColor Green
}

#####################################
# Create a new user within the system
Write-Host "`nCreating a new user..." -ForegroundColor Cyan

# Prompt for the new user's details
$displayName = Read-Host "Enter the display name for the new user"
$userName = Read-Host "Enter the email address (username) for the new user"
$password = Read-Host "Enter the password for the new user"

# Retrieve roles
$roles = Get-AllRoles -authorizationToken $token
$userType = "SDLUser"  # Corrected UserType

# Proceed to create the new user within the selected organisation
$newUser = New-User -authorizationToken $token -userName $userName -password $password -role $roles[0] -organization $selectedOrganization -userType $userType -displayName $displayName -emailAddress $userName

# Check if the user was created; if not, retrieve the existing user
if ($null -eq $newUser) {
    Write-Host "User already exists. Retrieving the existing user..." -ForegroundColor Yellow
    $user = Get-User -authorizationToken $token -userName $userName
    Write-Host "User [$($user.DisplayName)] retrieved..." -ForegroundColor Yellow
} else {
    Write-Host "New user created: $($newUser.DisplayName)" -ForegroundColor Green
}


######################################################################################
# List the Translation Memories (TMs) and their Container in the selected organisation
Write-Host "`nListing the first 10 Translation Memories (and their Container) in the selected organization:" -ForegroundColor Cyan

# Retrieve all containers
$containers = Get-AllContainers -authorizationToken $token

# Find the containers associated with the selected organization
$targetContainers = $containers | Where-Object { $_.OwnerId -eq $selectedOrganization.UniqueId }

# If no containers are found, exit the script
if ($null -eq $targetContainers -or $targetContainers.Count -eq 0) {
    Write-Host "No containers found for the organization '$myOrganization'." -ForegroundColor Red
    return
}

# Retrieve all TMs
$tms = Get-AllTMs -authorizationToken $token

# Filter TMs by the target containers' ContainerIds and associate them with their containers
$containerTMs = @()
foreach ($container in $targetContainers) {
    $containerTMs += $tms | Where-Object { $_.ContainerId -eq $container.ContainerId } | ForEach-Object {
        [PSCustomObject]@{
            TMName = $_.Name
            ContainerName = $container.Name
        }
    }
}

# Display the filtered TMs along with their containers
if ($containerTMs.Count -gt 0) {
    Write-Host "`nTranslation Memories in the organization '$myOrganization':"
    $containerTMs | Select-Object -First 10 | ForEach-Object { 
        Write-Host "TM Name: $($_.TMName) (Container: $($_.ContainerName))" 
    }
} else {
    Write-Host "No Translation Memories found in the organization '$myOrganization'." -ForegroundColor Yellow
}


###############################################
# Create a new Translation Memory in the system

Write-Host "`nCreating a new Translation Memory..." -ForegroundColor Cyan

# Prompt for the translation memory name
$tmName = Read-Host "Enter the name for the new Translation Memory"

# Prompt for the source and target language codes
$sourceLanguage = Read-Host "Enter the source language code (e.g., en-gb)"
$targetLanguages = Read-Host "Enter the target language codes, separated by commas (e.g., ro-ro)"

# Convert the target languages to an array
$targetLanguageArray = $targetLanguages -split ",\s*"

# Define language pairs
$languageDirections = Get-LanguageDirections -source $sourceLanguage -target $targetLanguageArray

# Retrieve the container by name
$containers = Get-AllContainers -authorizationToken $token
$workingContainer = $containers | Where-Object { $_.DisplayName -eq "multifarious_Container" }

if ($null -eq $workingContainer) {
    Write-Host "Container 'multifarious_Container' not found." -ForegroundColor Red
    return
}

# Create the new Translation Memory
$workingTM = New-TM -authorizationToken $token -tmName $tmName -container $workingContainer -organization $selectedOrganization -languageDirections $languageDirections

# Confirm the creation of the new TM
if ($null -eq $workingTM) {
    Write-Host "Failed to create Translation Memory." -ForegroundColor Red
} else {
    Write-Host "Translation Memory created: $($workingTM.Name)" -ForegroundColor Green
}

##########################################################
# Create a new Project Template using the newly created TM

Write-Host "`nCreating a new Project Template with the Translation Memory..." -ForegroundColor Cyan
$templateName = Read-Host "Enter the name for the new Project Template"

# Create the new Project Template using the newly created TM
$projectTemplate = New-ProjectTemplate -authorizationToken $token -templateName $templateName -organization $selectedOrganization -sourceLanguageCode $sourceLanguage -targetLanguageCodes $targetLanguageArray -translationMemories @($workingTM)

# Check if the project template was created; if not, retrieve the existing one
if ($null -eq $projectTemplate) {
    $projectTemplate = Get-ProjectTemplate -authorizationToken $token -templateName $templateName
    Write-Host "Existing Project Template retrieved: $($projectTemplate.Name)" -ForegroundColor Yellow
} else {
    Write-Host "New Project Template created: $($projectTemplate.Name)" -ForegroundColor Green
}

#################################################################
# Create a sample project with a demo file created by this script

# Prompt for the project name
$projectName = Read-Host "Enter the project name"

# Create a sample text file to be used in the project creation
Write-Host "`nCreating a sample file for project creation..." -ForegroundColor Cyan
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path  # Get the directory where the script is located
$fileName = "sample.txt"  # Set the name of the sample file
$filePath = Join-Path -Path $scriptDirectory -ChildPath $fileName  # Create the full path for the file
$null = New-Item -Path $filePath -ItemType File -Force  # Create the new text file at the specified location
Add-Content -Path $filePath -Value "This is a sample text."  # Add content to the sample file

# Confirm that the sample file was created
Write-Host "Sample file created at: $filePath" -ForegroundColor Green

# Schedule the creation of a new project using the sample file
Write-Host "`nScheduling a new project creation with the sample file..." -ForegroundColor Cyan
$projectCreationResult = New-Project -authorizationToken $token -projectName $projectName -organization $selectedOrganization -projectTemplate $projectTemplate -filesPath $filePath

# Check if the project was created successfully
if ($null -eq $projectCreationResult) {
    Write-Host "Failed to schedule project creation." -ForegroundColor Red
} else {
    Write-Host "Project creation has been scheduled. The project will be uploaded in a few moments." -ForegroundColor Green
}

# Clean up by removing all loaded modules from the current PowerShell session
Write-Host "`nCleaning up and removing modules from the PowerShell session..." -ForegroundColor Cyan
Remove-Module -Name AuthenticationHelper
Remove-Module -Name BackgroundTaskHelper
Remove-Module -Name ProjectServerHelper
Remove-Module -Name ResourcesHelper
Remove-Module -Name SystemConfigurationHelper
Remove-Module -Name UserManagerHelper

# Confirm that all modules were removed successfully
Write-Host "Modules removed successfully." -ForegroundColor Green

# Display script completion message with decorative separators
Write-Host "`n======================================" -ForegroundColor Yellow
Write-Host "            Script Completed            " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Yellow
