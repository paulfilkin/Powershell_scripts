$ErrorActionPreference = "Stop"

# Load necessary assemblies for GUI
Add-Type -AssemblyName System.Windows.Forms

$StudioVersion = "Studio18"; # Change this with the actual Trados Studio version
$TemplateFolderPath = "c:\Users\pfilkin\OneDrive - RWS\Documents\Studio 2024\Project Templates\" # Folder containing the templates

# Display a message to indicate the purpose of the script
Write-Host "This script demonstrates how the PowerShell Toolkit can be used to automate small workflows"
Write-Host "by creating a project from a project template and creating the translation packages at the same time."

# Set the script to use Trados Studio 2024
$StudioVersion = "Studio18";

# Display a message to indicate the purpose of the script
Write-Host "This script demonstrates how the PowerShell Toolkit can be used to create a TM";

# Notify the user that the necessary modules for Trados Studio will be loaded next
Write-Host "Start by loading PowerShell Toolkit modules.";

# Determine the script's directory
$scriptPath = $MyInvocation.MyCommand.Path
$scriptParentDir = Split-Path $scriptPath -Parent

# Attempt to find the Modules directory first relative to the script location
$modulesDir = Join-Path $scriptParentDir "Modules"

# Check PSModulePath for the correct module directory
$customModulePath = $Env:PSModulePath -split ';' | ForEach-Object {
    if ($_ -and (Test-Path $_)) {
        $potentialPath = Join-Path $_ "ToolkitInitializer\ToolkitInitializer.psm1"
        if (Test-Path $potentialPath) {
            return $_
        }
    }
}

# If no valid path is found in PSModulePath, fall back to default Documents location
if (-not (Test-Path $modulesDir)) {
    if ($customModulePath) {
        $modulesDir = $customModulePath
    } else {
        $modulesDir = Join-Path $Env:USERPROFILE "Documents\WindowsPowerShell\Modules"
    }
}

# Import the ToolkitInitializer module to initialize the Trados Studio environment.
$modulePath = Join-Path $modulesDir "ToolkitInitializer\ToolkitInitializer.psm1"
if (Test-Path $modulePath) {
    Import-Module -Name $modulePath
} else {
    Write-Host "ToolkitInitializer module not found at $modulePath"
    exit
}

# Import the specific toolkit modules corresponding to the SDL Trados Studio version being used.
# This command makes all necessary functions from the toolkit available for use in the script.
Import-ToolkitModules $StudioVersion

# Defining the necessary properties for Project Creation
$projectName = Read-Host "Please enter the project name"
$projectDestinationPath = "c:\Users\pfilkin\OneDrive - RWS\Documents\Studio 2024\Projects\" + $projectName;
$dueDate = Read-Host "Enter the due date (yyyy-mm-dd)";
$description = "ApiProject"

# Function to open a file dialog to select a template
function Select-Template {
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.InitialDirectory = $TemplateFolderPath
    $OpenFileDialog.Filter = "Project Templates (*.sdltpl)|*.sdltpl"
    $OpenFileDialog.Title = "Select a Project Template"
    
    if ($OpenFileDialog.ShowDialog() -eq "OK") {
        return $OpenFileDialog.FileName
    } else {
        Write-Host "No template selected. Exiting."
        exit
    }
}

# Prompt the user to select a template
$TemplatePath = Select-Template
Write-Host "Selected Template: $TemplatePath"


# Creates the project using the selected template with placeholder values
New-Project -ProjectName $projectName -projectDestination $projectDestinationPath -projectReference $TemplatePath -projectDueDate $dueDate -projectDescription $description -sourceFilesFolder "c:\Users\pfilkin\Documents\StudioPowershellToolkit\Project Source Files\";


Write-Host "A new project creation completed using the template."



Write-Host "Now opening the project and getting the analysis statistics."

# Retrieving the newly created project as a FileBasedProject instance
$project = Get-Project ($projectDestinationPath);

# Set the $sourceFolderPath to be based on the project path
$sourceFolderPath = Join-Path $projectDestinationPath "Reports"

# Define the destination folder for the TSV files
$destinationFolderPath = "c:\Users\pfilkin\OneDrive - RWS\Documents\Studio 2024\Packages\"

# Ensure the destination folder exists
if (-not (Test-Path -Path $destinationFolderPath)) {
    New-Item -Path $destinationFolderPath -ItemType Directory
}

# Get all XML files in the source folder that match the naming convention "Analyze Files *.xml"
$xmlFiles = Get-ChildItem -Path $sourceFolderPath -Filter "Analyze Files *.xml"

# Iterate through each matching XML file
foreach ($xmlFile in $xmlFiles) {
    # Load the XML file
    $xml = [xml](Get-Content -Path $xmlFile.FullName)

    # Extract the target language from the file name (e.g., "de-de" from "Analyze Files en-US_de-de.xml")
    $targetLanguage = ($xmlFile.BaseName -split "_")[-1]

    # Define the output TSV file name based on the target language
    $outputFileName = $projectName + "_$targetLanguage.tsv"
    $outputFilePath = Join-Path -Path $destinationFolderPath -ChildPath $outputFileName

    # Open the file for writing
    $outputFile = New-Item -Path $outputFilePath -ItemType File -Force
    $outputFile = [System.IO.StreamWriter]::new($outputFilePath)

    # Write headers
    $headers = "Run At`tProject Name`tProject Due Date`tLanguage`tTM Name`tFile Name`tSegment Type`tSegments`tWords`tCharacters`tPlaceables`tTags"
    $outputFile.WriteLine($headers)

    # Extract taskInfo data
    $taskInfo = $xml.task.taskInfo
    $runAt = $taskInfo.runAt
    $projectNameFromXML = $taskInfo.project.name
    $dueDate = $taskInfo.project.dueDate
    $language = $taskInfo.language.name
    $tmName = $taskInfo.tm.name

    # Extract file analysis data
    foreach ($file in $xml.task.file) {
        $fileName = $file.name

        foreach ($segment in $file.analyse.ChildNodes) {
            $segmentType = $segment.Name
            if ($segmentType -eq "fuzzy") {
                $min = $segment.min
                $max = $segment.max
                $segmentType = "fuzzy ($min-$max)"
            }

            $line = "$runAt`t$projectNameFromXML`t$dueDate`t$language`t$tmName`t$fileName`t$segmentType`t$($segment.segments)`t$($segment.words)`t$($segment.characters)`t$($segment.placeables)`t$($segment.tags)"
            $outputFile.WriteLine($line)
        }
    }

    # Close the file
    $outputFile.Close()

    Write-Output "TSV file created successfully at $outputFilePath"
}



Write-Host "Now creating a translation package for each target language."

# Retrieve project information
$projectInfo = $project.GetProjectInfo()

# Get the target languages from the project information
$targetLanguages = $projectInfo.TargetLanguages

# Export the package for each target language
foreach ($targetLanguage in $targetLanguages) {
    Export-Package -language $targetLanguage `
                   -packagePath "c:\Users\pfilkin\OneDrive - RWS\Documents\Studio 2024\Packages\$($projectName)_$($targetLanguage.IsoAbbreviation).sdlppx" `
                   -projectToProcess $project
}

Write-Host "Completed exporting packages."
