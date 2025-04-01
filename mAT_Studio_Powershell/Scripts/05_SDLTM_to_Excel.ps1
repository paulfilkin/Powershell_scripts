$ErrorActionPreference = "Stop"

# Set the script to use Trados Studio 2024
$StudioVersion = "Studio18";

# Display a message to indicate the purpose of the script
Write-Host "This script converts SDLTM to TMX and then to an Excel spreadsheet.";

# Notify the user that the necessary modules for Trados Studio will be loaded next
Write-Host "Loading PowerShell Toolkit modules.";

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
    }
    else {
        $modulesDir = Join-Path $Env:USERPROFILE "Documents\WindowsPowerShell\Modules"
    }
}

# Import the ToolkitInitializer module to initialize the Trados Studio environment.
$modulePath = Join-Path $modulesDir "ToolkitInitializer\ToolkitInitializer.psm1"
if (Test-Path $modulePath) {
    Import-Module -Name $modulePath
}
else {
    Write-Host "ToolkitInitializer module not found at $modulePath"
    exit
}

# Import the specific toolkit modules corresponding to the SDL Trados Studio version being used.
Import-ToolkitModules $StudioVersion

Add-Type -AssemblyName System.Windows.Forms

# Open a file dialog to select an SDLTM file
$fileDialog = New-Object System.Windows.Forms.OpenFileDialog
$fileDialog.Filter = "SDL Translation Memory (*.sdltm)|*.sdltm"
$fileDialog.Title = "Select an SDL Translation Memory file"

$dialogResult = $fileDialog.ShowDialog()

if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
    $sdltmFilePath = $fileDialog.FileName

    # Get the directory and base name for the TMX export
    $exportDirectory = [System.IO.Path]::GetDirectoryName($sdltmFilePath)
    $tmxBaseName = [System.IO.Path]::GetFileNameWithoutExtension($sdltmFilePath)
    $exportFilePath = Join-Path $exportDirectory "${tmxBaseName}_exported.tmx"

    # Notify the user
    Write-Host "Selected SDLTM file: $sdltmFilePath"
    Write-Host "Exporting to TMX file: $exportFilePath"

    # Export the selected SDLTM to a TMX file
    Export-Tmx -exportFilePath $exportFilePath -tmPath $sdltmFilePath

    Write-Host "TMX export completed successfully."

    # Path to the Python script
    $pythonScriptPath = Join-Path $scriptParentDir "convert_tmx_to_excel.py"

    # Check if the Python script exists
    if (-not (Test-Path $pythonScriptPath)) {
        Write-Host "Python script not found at $pythonScriptPath"
        exit
    }

    # Execute the Python script
    Write-Host "Converting TMX to Excel format using Python script..."
    try {
        $pythonPath = "python" # Adjust to "python3" if required on your system
        $command = "$pythonPath `"$pythonScriptPath`" `"$exportFilePath`""

        # Start the process and wait for it to complete
        $process = Start-Process -FilePath $pythonPath -ArgumentList "`"$pythonScriptPath`" `"$exportFilePath`"" -NoNewWindow -PassThru -Wait

        if ($process.ExitCode -eq 0) {
            Write-Host "Excel file created successfully using Python script."
        }
        else {
            Write-Host "Python script execution failed with exit code: $($process.ExitCode)"
        }
    }
    catch {
        Write-Host "Error executing Python script: $_"
    }
}
else {
    Write-Host "No file selected. Operation cancelled."
}

# Wait for user input before closing (optional)
Read-Host -Prompt "Press Enter to exit"
