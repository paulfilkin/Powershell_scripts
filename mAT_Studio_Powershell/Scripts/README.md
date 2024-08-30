### 00_get-help-Studio.ps1

This script is designed to initialise the PowerShell environment for working with SDL Trados Studio 2024. It begins by identifying the appropriate version of Trados Studio (`Studio18`) and then attempts to load the necessary PowerShell Toolkit modules. The script locates these modules either relative to the script's location or within the user's PowerShell module paths. Once the modules are successfully imported, it prepares the environment for further Trados Studio automation tasks. If the required modules are not found, the script exits with an error message.

### 01_create_new_TM.ps1

This script automates the creation of a new Translation Memory (TM) using SDL Trados Studio 2024 via the PowerShell Toolkit. After loading the necessary modules, the script prompts the user to input the source and target language codes, along with a name for the TM. It then generates a filename based on these inputs and creates a new file-based TM at a specified directory. The script also sets a brief description for the TM and confirms its successful creation by displaying the file path to the user.

### 02_upgrade_TMX.ps1

This script automates the process of upgrading a TMX file into a file-based Translation Memory (TM) using SDL Trados Studio 2024. After loading the necessary PowerShell Toolkit modules, the script prompts the user to specify the location of a TMX file. It then parses the TMX file to extract the source and target language codes. Using these codes, the script generates a new TM file in a specified directory and imports the contents of the TMX file into this newly created TM. The script provides confirmation of successful creation and displays the TM's file path.

### 03_Create_File-Based_Project.ps1

This script automates the creation of a new project in SDL Trados Studio 2024 using a project template. It begins by loading the required PowerShell Toolkit modules and prompting the user to input the project name, due date, and select a template file. The script then creates the project, retrieves analysis statistics, and exports them into TSV files for each target language. Additionally, the script automates the creation of translation packages for each target language within the project, saving them in a specified directory. This script is designed to streamline the project setup process by handling multiple steps in one automated workflow.

### 04_Export_TMX.ps1

This script facilitates the export of an SDL Trados Studio Translation Memory (SDLTM) file to a TMX format. After loading the necessary PowerShell Toolkit modules, the script presents a file dialog for the user to select an SDLTM file. Once the file is selected, the script automatically generates a TMX file in the same directory, appending "_exported" to the original filename. The user is notified of the successful export, and the script concludes by waiting for user input before closing.

### unblock_script.ps1

This script is designed to unblock files that might have been flagged by Windows as potentially unsafe, typically after being downloaded from the internet. The user is prompted to enter the path to a file or a folder. If a folder is selected, the script will recursively unblock all files within that folder. If a single file is selected, only that file will be unblocked. The script attempts to unblock each file and provides feedback on whether the operation was successful or if it encountered any issues.