$ErrorActionPreference = "Stop"

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
Write-Host "Now let's create a new empty TM."

# Set the directory where the new TM will be saved
$tmDirectory = "c:\Users\pfilkin\Documents\StudioPowershellToolkit\TM in here\"

# Prompt the user for the location of the TMX file
$tmxFilePath = Read-Host -Prompt "Please enter the full path of the TMX file"

# Ensure the file exists
if (-not (Test-Path $tmxFilePath)) {
    Write-Host "The specified TMX file does not exist. Exiting."
    exit
}

# Use XmlReader for faster XML parsing
$xmlReader = [System.Xml.XmlReader]::Create($tmxFilePath)

$sourceLangCode = $null
$targetLangCode = $null

while ($xmlReader.Read()) {
    if ($xmlReader.NodeType -eq [System.Xml.XmlNodeType]::Element -and $xmlReader.Name -eq "tuv") {
        if (-not $sourceLangCode) {
            $sourceLangCode = $xmlReader.GetAttribute("xml:lang")
        } elseif (-not $targetLangCode) {
            $targetLangCode = $xmlReader.GetAttribute("xml:lang")
            break  # Exit loop once both codes are found
        }
    }
}

$xmlReader.Close()

if ($sourceLangCode -and $targetLangCode) {
    Write-Host "Source Language: $sourceLangCode"
    Write-Host "Target Language: $targetLangCode"

    # Get the base name of the TMX file (without the extension)
    $tmBaseName = [System.IO.Path]::GetFileNameWithoutExtension($tmxFilePath)

    Write-Host "The base name for the new TM will be: $tmBaseName"

    # Extract language codes for the filename
    $srcLangAbbr = $sourceLangCode.Split("-")[0]
    $srcCountryAbbr = $sourceLangCode.Split("-")[1]

    $tgtLangAbbr = $targetLangCode.Split("-")[0]
    $tgtCountryAbbr = $targetLangCode.Split("-")[1]

    # Construct the full TM file name
    $tmFileName = "${srcLangAbbr}(${srcCountryAbbr}) - ${tgtLangAbbr}(${tgtCountryAbbr})_${tmBaseName}.sdltm"

    # Define the full file path where the new Translation Memory will be saved
    $tmFilePath = Join-Path $tmDirectory $tmFileName

    # Set a description for the Translation Memory
    $sdltmdesc = "Created by PowerShell";

    # Create a new file-based Translation Memory (TM) using the specified parameters
    New-FileBasedTM -filePath $tmFilePath -description $sdltmdesc -sourceLanguageName $sourceLangCode -targetLanguageName $targetLangCode;

    # Import the TMX file into the newly created Translation Memory
    Import-Tmx -importFilePath $tmxFilePath -tmPath $tmFilePath -sourceLanguage $sourceLangCode -targetLanguage $targetLangCode

    # Inform the user that the Translation Memory has been successfully created and display its file path
    Write-Host "A TM created at: " $tmFilePath;
} else {
    Write-Host "Error: Unable to find the source or target language codes in the TMX file."
}

# Wait for user input before closing
Read-Host -Prompt "Press Enter to exit"
