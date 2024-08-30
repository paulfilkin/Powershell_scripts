# Set the path to the folder containing the files
$sourceFolder = "C:\Path\To\Your\Folder"

# Get all files in the folder
$files = Get-ChildItem -Path $sourceFolder -File

foreach ($file in $files) {
    # Get the correct creation date of the file from the 'Date' column
    $creationDate = $file.LastWriteTime

    # Format the date as "YYYY-MM" for the folder name
    $folderName = $creationDate.ToString("yyyy-MM")

    # Create the destination folder path
    $destinationFolder = Join-Path -Path $sourceFolder -ChildPath $folderName

    # Create the folder if it doesn't exist
    if (-not (Test-Path -Path $destinationFolder)) {
        New-Item -Path $destinationFolder -ItemType Directory
    }

    # Move the file to the destination folder
    $destinationPath = Join-Path -Path $destinationFolder -ChildPath $file.Name
    Move-Item -Path $file.FullName -Destination $destinationPath -Force

    Write-Host "Moved $($file.Name) to $destinationFolder"
}

Write-Host "Files have been successfully moved to folders based on their creation date."
