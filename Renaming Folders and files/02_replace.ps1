##########################################################################################################
### A SCRIPT TO READ THE TEXT FILE, LOOP THROUGH ALL THE FILES AND FOLDERS, AND REPLACE WITH TRANSLATION ###
##########################################################################################################

# Prompt the user to enter the full path to the translated text file, typically named "filelist.txt".
$translatedFilePath = Read-Host "Please enter the full path to the translated text file (filelist.txt)"

# Load the content from the translation file into an array where each line represents a file or folder and its translation details.
$content = Get-Content -Path $translatedFilePath

# Sort the content by the depth of the file/folder paths, with deeper paths appearing first.
# This ensures that the script processes items from the deepest level upwards, avoiding issues with renaming parent directories before their contents.
$sortedContent = $content | Sort-Object {($_ -split "`t")[1].Split('\').Length} -Descending

# Loop through each line in the sorted content.
foreach ($line in $sortedContent) {
    # Split the line into its components, which typically include the type (File/Folder), the full path, and the new name.
    $parts = $line -split "`t"
    $type = $parts[0]          # The type of item, either "File" or "Folder".
    $fullPath = $parts[1]      # The full original path of the item.
    $newName = $parts[3]       # The new name for the item, as specified in the translation file.

    # Check if the file or folder exists at the specified path.
    if (Test-Path $fullPath) {
        # Get the parent directory of the item to construct the full path for the renamed item.
        $parentPath = Split-Path -Path $fullPath
        $newFullPath = Join-Path -Path $parentPath -ChildPath $newName

        # Check if the new path is different from the original path.
        # This prevents unnecessary renaming operations and avoids errors when the name hasn't changed.
        if ($fullPath -ne $newFullPath) {
            try {
                # Attempt to rename the item to the new name.
                Rename-Item -Path $fullPath -NewName $newName
                Write-Host "Successfully renamed $type at '$fullPath' to '$newName'."
            } catch {
                # If an error occurs during renaming, display a warning message with the error details.
                Write-Warning "Failed to rename $type at '$fullPath' to '$newName': $_"
            }
        } else {
            # If the new name is the same as the old name, skip the renaming operation and notify the user.
            Write-Host "Skipping renaming $type at '$fullPath' because the name is unchanged."
        }
    } else {
        # If the item cannot be found at the specified path, display a warning message.
        Write-Warning "Could not find $type at path: $fullPath"
    }
}
