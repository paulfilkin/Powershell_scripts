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




########################################################
### Create Project using a selected project template ###

# Prompt user for necessary inputs
$organizationName = Read-Host "Please enter the name of the Organisation"

# Retrieve the Organisation object
$organization = Get-Organization -authorizationToken $token -organizationName $organizationName
if ($null -eq $organization) {
    Write-Host "Organization not found: $organizationName" -ForegroundColor Red
    exit
}

# Retrieve all Project Templates associated with the organisation
Write-Host "`nProject Templates associated with the Organization:" -ForegroundColor Cyan
$projectTemplates = Get-AllProjectTemplates -authorizationToken $token
$projectTemplatesForOrg = $projectTemplates | Where-Object { $_.OrganizationId -eq $organization.UniqueId }

if ($projectTemplatesForOrg.Count -gt 0) {
    # Display the list of Project Templates for the user to select
    for ($i = 0; $i -lt $projectTemplatesForOrg.Count; $i++) {
        Write-Host "$($i + 1). $($projectTemplatesForOrg[$i].Name)" -ForegroundColor Yellow
    }

    # Prompt the user to select a Project Template by its number
    $templateSelection = Read-Host "Please enter the number corresponding to the Project Template you wish to use"

    # Validate the user's selection
    if ($templateSelection -match '^\d+$' -and $templateSelection -ge 1 -and $templateSelection -le $projectTemplatesForOrg.Count) {
        $selectedTemplate = $projectTemplatesForOrg[$templateSelection - 1]
        Write-Host "Selected Project Template: $($selectedTemplate.Name)" -ForegroundColor Green
    } else {
        Write-Host "Invalid selection. Please enter a valid number." -ForegroundColor Red
        exit
    }

    # Prompt for ZIP file path
    $zipFilePath = Read-Host "Please provide the full path to the ZIP file containing the project files"

    # Check if the ZIP file exists
    if (-not (Test-Path -Path $zipFilePath)) {
        Write-Host "The specified ZIP file does not exist: $zipFilePath" -ForegroundColor Red
        exit
    }

    Write-Host "ZIP file located at: $zipFilePath" -ForegroundColor Green

    # Schedule the creation of a new project using the selected template and ZIP file
    Write-Host "`nScheduling a new project creation with the specified ZIP file..." -ForegroundColor Cyan
    $projectName = Read-Host "Please enter the name for the new project"

    $null = New-Project -authorizationToken $token `
                        -projectName $projectName `
                        -organization $organization `
                        -projectTemplate $selectedTemplate `
                        -filesPath $zipFilePath

    # Confirm that the project creation has been scheduled
    Write-Host "Project creation has been scheduled. The project will be uploaded in a few moments." -ForegroundColor Green

} else {
    Write-Host "No Project Templates found for this Organization." -ForegroundColor Red
}
