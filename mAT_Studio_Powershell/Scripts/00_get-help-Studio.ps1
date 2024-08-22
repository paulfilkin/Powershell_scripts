# Set the script to use Trados Studio 2024
$StudioVersion = "Studio18";

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

Write-Host "Now get-help";
