- # Trados Studio PowerShell Toolkit Scripts

  This repository contains a series of PowerShell scripts designed to automate various tasks in Trados Studio 2024. These scripts make use of the [PowerShell Toolkit modules for Trados Studio](https://github.com/RWS/Sdl-studio-powershell-toolkit), allowing you to interact with and manipulate Trados Studio resources programmatically.

  ## Prerequisites

  Before running any of the scripts, ensure you have the following:

  1. **Trados Studio 2024** installed (Professional licence is required).
  2. **PowerShell Toolkit for Trados Studio** installed and properly configured.
  3. Necessary modules available either in the `Modules` directory within the script's folder or in your PowerShell module path.
     - *Note*: you'll probably have to unblock files downloaded so I also created a [small script](https://github.com/paulfilkin/Powershell_scripts/blob/main/mAT_Studio_Powershell/Scripts/unblock_script.ps1) to unblock all files within a folder/subfolders to save time... might be useful.
  4. Also make sure your environment variables for PSModulePath are setup to use the path to the modules.  I don't use the default windows locations for my scripts so add additional variables. My scripts check the PSModulePath for the location of the modules and then looks for a valid directory that contains the `ToolkitInitializer.psm1` module by iterating through each path you set in there.
  5. You will need to use the PowerShell 5 (x86) version of Powershell for these scripts as Studio is a 32-bit application.
  
  ## Scripts Overview
  
  ### 1. `00_get-help-Studio.ps1`
  
  This script initializes the Trados Studio environment by loading the necessary PowerShell Toolkit modules. It is a simple example demonstrating how to start with the Toolkit and display help documentation for the available commands.
  
  - **Usage**: Run this script to load the required modules and get help for the Trados Studio Toolkit commands.
  - **Main Steps**:
    - Determines the script's directory and attempts to locate the necessary modules.
    - Loads the `ToolkitInitializer` module and any other required modules based on the Trados Studio version.
    - Displays help information.
  
  ### 2. `01_create_new_TM.ps1`
  
  This script creates a new Translation Memory (TM) within Trados Studio 2024 using user-defined parameters such as source language, target language, and TM name.
  
  - **Usage**: Execute this script to create a new TM by following the prompts.
  - **Main Steps**:
    - Prompts the user for source and target language codes and TM name.
    - Constructs the TM file name and saves it to a specified directory.
    - Creates the TM and notifies the user of its location.
  
  ### 3. `02_upgrade_TMX.ps1`
  
  This script upgrades a TMX file to a Trados Studio Translation Memory (TM). It reads the source and target language codes from the TMX file, creates a new TM in Trados Studio, and imports the TMX content into the new TM.
  
  - **Usage**: Run this script and provide the path to a TMX file when prompted.
  - **Main Steps**:
    - Prompts the user for the location of the TMX file.
    - Extracts language codes from the TMX file.
    - Creates a new TM and imports the TMX content into it.
  
  ### 4. `03_Create_File-Based_Project.ps1`
  
  This script automates the creation of a file-based project in Trados Studio. It uses a project template, creates the project, retrieves analysis statistics, and exports translation packages for each target language.
  
  - **Usage**: Execute this script to create a new project based on a template and generate associated translation packages.
  - **Main Steps**:
    - Prompts the user for the project name and due date.
    - Allows the user to select a project template.
    - Creates the project, retrieves analysis data, and exports translation packages.
  
  ### 5. `04_Export_TMX.ps1`
  
  This script exports the content of an SDLTM (SDL Translation Memory) file to a TMX file. It allows the user to select the SDLTM file through a file dialog and exports it to a TMX format.
  
  - **Usage**: Run this script to convert an SDLTM file to a TMX file.
  - **Main Steps**:
    - Opens a file dialog for the user to select an SDLTM file.
    - Exports the selected SDLTM file to a TMX file.
    - Notifies the user of the export's success.
  
  ## How to Run the Scripts
  
  1. Clone this repository to your local machine.
  2. Navigate to the `scripts` folder.
  3. Run the desired script using PowerShell.
  
  ```sh
  .\00_get-help-Studio.ps1
  ```
  
  Alternatively use the Autohotkey solution provided in the "[Run Powershell Scripts](https://github.com/paulfilkin/Powershell_scripts/tree/main/mAT_Studio_Powershell/Run%20Powershell%20Scripts)" folder.
  
  Make sure your environment is correctly set up to find the necessary modules as described in each script. 
  
  ## Contributing
  
  If you have improvements or additional scripts that could benefit the community, feel free to submit a pull request. Contributions are always welcome!
  
  
