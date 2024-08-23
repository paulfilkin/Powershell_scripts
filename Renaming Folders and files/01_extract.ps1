########################################################################################
### A SCRIPT TO LOOP THROUGH ALL THE FILES AND FOLDERS AND WRITE THEIR NAMES TO FILE ###

# Prompt the user to enter the path of the root folder where the file and folder search should begin.
$rootFolder = Read-Host "Enter the path of the root folder"

# Get the parent directory of the root folder.
$parentDirectory = (Get-Item $rootFolder).Parent.FullName

# Define the path to the output file in the parent directory of the root folder.
$outputFile = "$parentDirectory\filelist.txt"

# Define a function called Get-FileFolderList that takes a path as input.
function Get-FileFolderList($path) {

    # Get all files and folders within the specified path, including subdirectories, using Get-ChildItem.
    # For each item found (file or folder), execute the following code block.
    Get-ChildItem -Path $path -Recurse | ForEach-Object {

        # Store the original name of the current item (file or folder) in a variable.
        $originalName = $_.Name

        # Check if the current item is a directory (folder).
        if ($_.PSIsContainer) {

            # If the item is a folder, format the output as "Folder    FullName    originalName    originalName"
            "Folder`t$($_.FullName)`t$originalName`t$originalName"
        } else {

            # If the item is a file, format the output as "File    FullName    originalName    originalName"
            "File`t$($_.FullName)`t$originalName`t$originalName"
        }
    }
}

# Call the Get-FileFolderList function with the user-provided root folder path.
# Pipe the output of the function to Out-File to save it to the specified output file.
Get-FileFolderList -path $rootFolder | Out-File $outputFile

# Inform the user that the file list has been successfully created, and display the path to the output file.
Write-Host "The file list has been successfully created at $outputFile"
