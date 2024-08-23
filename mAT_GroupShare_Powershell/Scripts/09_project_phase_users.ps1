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

#########################################
### PROJECT PHASES AND ASSIGNED USERS ###

# Prompt for the project name
$myProjectName = Read-Host "`nEnter the project name"

# Retrieve the project object using the project name
$project = Get-Project -authorizationToken $token -projectName $myProjectName

# Check if the project was found
if ($null -eq $project) {
    Write-Host "Project '$myProjectName' was not found." -ForegroundColor Red
    return
}

# Retrieve the source language from the project
$sourceLanguage = $project.SourceLanguage

# Retrieve the project phases
$phases = Get-ProjectPhases -authorizationToken $token -project $project

# Define the desired phase order
$phaseOrder = @("Preparation", "Translation", "Review", "Finalisation")

# Retrieve the files with their phases and assignees
$files = Get-FilesPhasesFromProject -authorizationToken $token -project $project

# Create a hashtable to store data by phase and language pair
$phaseData = @{}

# Iterate through each file and organise data by phase and language pair
foreach ($file in $files) {
    foreach ($phaseDetail in $file.Phases) {
        $phaseName = ($phases | Where-Object { $_.ProjectPhaseId -eq $phaseDetail.ProjectPhaseId }).Name

        if (-not $phaseData.ContainsKey($phaseName)) {
            $phaseData[$phaseName] = @{}
        }

        if (-not $phaseData[$phaseName].ContainsKey($file.LanguageCode)) {
            $phaseData[$phaseName][$file.LanguageCode] = @{}
        }

        foreach ($assigneeId in $phaseDetail.Assignees) {
            $assigneeDetails = Get-User -authorizationToken $token -userId $assigneeId
            if ($assigneeDetails) {
                $userDisplayName = $assigneeDetails.DisplayName
                $userEmail = $assigneeDetails.EmailAddress
                $userKey = "$userDisplayName, email: $userEmail"
                
                if (-not $phaseData[$phaseName][$file.LanguageCode].ContainsKey($userKey)) {
                    $phaseData[$phaseName][$file.LanguageCode][$userKey] = @()
                }
                $phaseData[$phaseName][$file.LanguageCode][$userKey] += $file.FileName
            }
        }
    }
}

# Output the organised data in the correct order
foreach ($phaseName in $phaseOrder) {
    if ($phaseData.ContainsKey($phaseName)) {
        Write-Host "`nPhase: $phaseName" -ForegroundColor Cyan

        foreach ($languageCode in $phaseData[$phaseName].Keys) {
            Write-Host "`tLanguage Pair: $sourceLanguage -> $languageCode" -ForegroundColor Yellow

            foreach ($userKey in $phaseData[$phaseName][$languageCode].Keys) {
                Write-Host "`t`tUser: $userKey" -ForegroundColor Green

                foreach ($fileName in $phaseData[$phaseName][$languageCode][$userKey]) {
                    Write-Host "`t`t`tFile: $fileName" -ForegroundColor White
                }
            }
        }
    }
}
