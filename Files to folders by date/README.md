# Organise Files by Creation Date

This PowerShell script automatically organises files into folders based on their creation dates. The script scans all files in a specified directory, identifies their creation dates, and then moves each file into a corresponding folder named after the year and month of its creation.

## Features

- Automatically creates folders based on the year and month (formatted as `YYYY-MM`).
- Moves files into their respective folders based on their creation dates.
- Ensures that all files in a specified directory are neatly organised with minimal manual effort.

## Usage

1. Clone or download this repository to your local machine.

2. Open the script in a text editor and set the path to the folder containing your files:

   ```powershell
   $sourceFolder = "C:\Path\To\Your\Folder"

Save the script and run it in PowerShell.

3. - The script will read the creation date of each file and move it into a folder named according to the format `YYYY-MM`, based on the creation date.
   - If a folder does not exist, the script will create it automatically.
   
4. The script will provide output in the PowerShell console, showing where each file has been moved.

## Example

If your source folder contains files with the following creation dates:

- `08/04/2024 21.12.28.jpg`
- `07/22/2024 19.06.00.jpg`
- `06/01/2024 16.40.11.jpg`

The script will create the following folders:

- `2024-08`
- `2024-07`
- `2024-06`

And the files will be moved into their corresponding folders.

## Notes

- Ensure that the script is run with appropriate permissions, as it will move files within the specified directory.
- Backup your files before running the script if you are unsure about the changes it will make.
