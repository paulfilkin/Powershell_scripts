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

# Notify the user that the script will now create a new Translation Memory (TM)
Write-Host "Now let's create a new empty TM.";

# Set the directory where the new TM will be saved
$tmDirectory = "c:\Users\pfilkin\Documents\StudioPowershellToolkit\TM in here\"

# Prompt the user for the source language code for the Translation Memory
$sdltmsrclangcode = Read-Host -Prompt "Please enter the source language code (e.g., en-GB)"

# Prompt the user for the target language code for the Translation Memory
$sdltmtgtlangcode = Read-Host -Prompt "Please enter the target language code (e.g., de-DE)"

# Prompt the user for the name of the TM file (without extension)
$tmBaseName = Read-Host -Prompt "Please enter the name for the TM (without extension)"

# Extract language codes for the filename
$srcLangAbbr = $sdltmsrclangcode.Split("-")[0]
$srcCountryAbbr = $sdltmsrclangcode.Split("-")[1]

$tgtLangAbbr = $sdltmtgtlangcode.Split("-")[0]
$tgtCountryAbbr = $sdltmtgtlangcode.Split("-")[1]

# Construct the full TM file name
$tmFileName = "${srcLangAbbr}(${srcCountryAbbr}) - ${tgtLangAbbr}(${tgtCountryAbbr})_${tmBaseName}.sdltm"

# Define the full file path where the new Translation Memory will be saved
$tmFilePath = Join-Path $tmDirectory $tmFileName

# Set a description for the Translation Memory
$sdltmdesc = "Created by PowerShell";

# Create a new file-based Translation Memory (TM) using the specified parameters
New-FileBasedTM -filePath $tmFilePath -description $sdltmdesc -sourceLanguageName $sdltmsrclangcode -targetLanguageName $sdltmtgtlangcode;

# Inform the user that the Translation Memory has been successfully created and display its file path
Write-Host "A TM created at: " $tmFilePath;

# Wait for user input before closing
Read-Host -Prompt "Press Enter to exit"
