# Prompt the user to select a folder or file
$selectedPath = Read-Host "Please enter the path to the folder or file you want to unblock"

# Check if the selected path is a folder or a file
if (Test-Path -Path $selectedPath -PathType Container) {
    # The selected path is a folder
    $files = Get-ChildItem -Path $selectedPath -Recurse -File
} elseif (Test-Path -Path $selectedPath -PathType Leaf) {
    # The selected path is a file
    $files = Get-Item -Path $selectedPath
} else {
    Write-Host "The path you entered is invalid. Please run the script again with a valid folder or file path."
    exit
}

# Unblock each file
foreach ($file in $files) {
    try {
        Unblock-File -Path $file.FullName
        Write-Host "Unblocked: $($file.FullName)"
    } catch {
        Write-Host "Failed to unblock: $($file.FullName) - $_"
    }
}

Write-Host "All files processed."
