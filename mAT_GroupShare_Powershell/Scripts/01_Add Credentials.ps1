# Prompt for the dataset name
$datasetName = Read-Host -Prompt "Enter the name for this credentials dataset"

# Prompt for the server URL
$server = Read-Host -Prompt "Enter the GroupShare server URL"

# Prompt for credentials
$credential = Get-Credential

# Create a custom object to store the dataset name, credentials, and server URL
$secureData = [PSCustomObject]@{
    DatasetName = $datasetName
    Credential  = $credential
    ServerUrl   = $server
}

# Define the path to save the encrypted XML file using the dataset name
$xmlFilePath = "c:\Users\pfilkin\Documents\GroupSharePowershellToolkit\CredentialStore\$datasetName-Credentials.xml"

# Export the secure data object to an encrypted XML file
$secureData | Export-CliXml -Path $xmlFilePath

Write-Host "Credentials and server URL saved to $xmlFilePath" -ForegroundColor Green
