# File and Folder Name Translation Scripts

This repository contains two PowerShell scripts designed to facilitate the translation of filenames and folder names within a specified directory structure. The scripts work together to first extract the current names of all files and folders into a text file, which can then be manually translated. The second script uses this translated text file to rename the files and folders accordingly.

## Scripts

### 1. `01_extract.ps1`

**Purpose:**  
This script recursively scans a specified root folder and generates a text file (`filelist.txt`) that lists all files and folders within that root, including their full paths and original names. This text file is intended to be manually edited with translated names.

**How it works:**
- Prompts the user to enter the path of the root folder where the scan should begin.
- Retrieves the parent directory of the root folder to save the output file (`filelist.txt`) in the same location.
- Recursively scans all files and folders within the root folder.
- For each file and folder, the script outputs a line in `filelist.txt` in the following format:
  ```
  Type    FullPath    OriginalName    OriginalName
  ```
  Where `Type` is either "File" or "Folder".

**Usage:**
```powershell
.\01_extract.ps1
```
Follow the prompt to enter the root folder path.

### 2. `02_replace.ps1`

**Purpose:**  
This script reads the translated `filelist.txt` and renames the files and folders according to the new names provided in the text file.

**How it works:**
- Prompts the user to enter the full path to the translated text file (`filelist.txt`).
- Loads the content of `filelist.txt` and sorts the items by their directory depth (deepest first).
- Iterates through each item in the list, renaming files and folders as specified.
- Checks if the new name is different from the current name to avoid unnecessary operations.
- Handles errors gracefully and provides feedback on successful or failed renaming operations.

**Usage:**
```powershell
.\02_replace.ps1
```
Follow the prompt to enter the full path to the `filelist.txt` file that has been edited with translated names.

## Workflow

1. **Download and unzip `Project Folder.zip`:**  
   This file provides an example file/folder structure to test with. Once downloaded, unzip it to a location of your choice.

2. **Run `01_extract.ps1`:**  
   This generates a `filelist.txt` file that lists all files and folders under the specified root folder.

3. **Translate `filelist.txt`:**  
   Open `filelist.txt` in a text editor and replace the original names with their translated counterparts in the appropriate column.

4. **Optional: Use the provided `filelist.zip`:**  
   This file contains a translated `filelist.txt` you can use instead of creating your own. However, before running the script, remember to search and replace the folder locations in the file to match the location you are using, or the script will fail.

5. **Run `02_replace.ps1`:**  
   This script reads the translated `filelist.txt` and renames the files and folders as specified.

## Notes

- Ensure that `filelist.txt` is correctly formatted after translation, with no extraneous tab characters or line breaks, to avoid errors during the renaming process.
- The scripts are designed to handle deep directory structures by processing deeper items before their parent directories, preventing conflicts during renaming.

