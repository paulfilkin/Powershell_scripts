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
# List all projects in the specified organisation
Write-Host "`nListing all projects in the organisation $($selectedOrganization.Name) grouped by Year-Month (Project Creation Date):" -ForegroundColor Cyan

# Retrieve projects for the specific organization with minimal filtering
$projects = Get-AllProjects -authorizationToken $token -organization $selectedOrganization -includeSubOrganizations $true -defaultPublishDates $false -defaultDueDates $false

# Check if projects were retrieved successfully
if ($null -eq $projects -or $projects.Count -eq 0) {
    Write-Host "No projects found in the organisation '$($selectedOrganization.Name)'." -ForegroundColor Yellow
    return
}

# Group projects by Year and Month
$groupedProjects = $projects | Group-Object { (Get-Date $_.CreatedAt).ToString("yyyy-MM") }

# Display the grouped projects
foreach ($group in $groupedProjects) {
    Write-Host "`nYear-Month: $($group.Name)" -ForegroundColor Yellow
    $group.Group | ForEach-Object {
        Write-Host "`tProject Name: $($_.Name), Project ID: $($_.ProjectId)" -ForegroundColor Green
    }
}

# Optionally, export the list of grouped projects to a text file
$outputFilePath = "c:\Users\pfilkin\Documents\GroupSharePowershellToolkit\Scripts\Projects_in_$($selectedOrganization.Name)_GroupedBy_YearMonth.txt"
$output = @()
foreach ($group in $groupedProjects) {
    $output += "Year-Month: $($group.Name)"
    $output += $group.Group | ForEach-Object { "`tProject Name: $($_.Name), Project ID: $($_.ProjectId)" }
}
$output | Out-File -FilePath $outputFilePath

Write-Host "`nGrouped project details have been saved to $outputFilePath" -ForegroundColor Cyan
