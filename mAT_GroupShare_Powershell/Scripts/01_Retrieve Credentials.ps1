# Define the directory path to open
$directoryPath = "c:\Users\pfilkin\Documents\GroupSharePowershellToolkit\CredentialStore\"

# Open a file dialog to select the XML file
Add-Type -AssemblyName System.Windows.Forms
$fileDialog = New-Object System.Windows.Forms.OpenFileDialog
$fileDialog.InitialDirectory = $directoryPath
$fileDialog.Filter = "XML files (*.xml)|*.xml"
$fileDialog.Multiselect = $false

$dialogResult = $fileDialog.ShowDialog()

if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedFile = $fileDialog.FileName
} else {
    Write-Host "No file selected. Exiting script." -ForegroundColor Red
    exit
}

# Import the secure data object from the selected XML file
$secureData = Import-CliXml -Path $selectedFile

# Extract the dataset name, credentials, and server URL
$datasetName = $secureData.DatasetName
$credential = $secureData.Credential
$server = $secureData.ServerUrl

# Extract username and password
$userName = $credential.UserName
$password = $credential.GetNetworkCredential().Password

# Print the retrieved information
Write-Host "`nRetrieved Dataset Name: $datasetName" -ForegroundColor Cyan
Write-Host "Retrieved Server URL: $server" -ForegroundColor Cyan
Write-Host "Retrieved UserName: $userName" -ForegroundColor Cyan
Write-Host "Retrieved Password: $password" -ForegroundColor Cyan
