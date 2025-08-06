# GroupShare PowerShell Scripts

## Overview

This repository contains a set of PowerShell scripts designed to facilitate various tasks related to Trados GroupShare. The scripts provide functionalities such as managing users, projects, and translation memories, among other administrative tasks. These scripts are built upon the `GroupSharePowershellToolkit` provided by the [Trados AppStore Team](link to follow).

<u>*IMPORTANT:*</u> These scripts also makes reference to the additional module available in this repository - [GroupShareToolkit](https://github.com/paulfilkin/Powershell_scripts/tree/main/mAT_GroupShare_Powershell/Modules) - so you will need to import this additional module to be able to run these scripts.

## Scripts Summary

### 1. 00_groupshare-get-help.ps1
This script initiates a session by importing the `GroupShareToolkit` module, retrieving credentials, importing necessary GroupShare modules, and authenticating the user. It serves as a starting point for using the other scripts, ensuring that all prerequisites are loaded. I created it initially to have a quick way to load all the modules and use the `get-help` features available to help with scripting, but not do anything else. Not an essential script but I found it helpful as I was learning how to work with this so included it here!

### 2. 01_Add Credentials.ps1
Allows the user to securely add and save their GroupShare credentials and server URL in an encrypted XML file. The script prompts the user for necessary details and saves the credentials to be used by the `01_Retrieve Credentials.ps1` script.

### 3. 01_Retrieve Credentials.ps1
Enables the retrieval of stored credentials from an encrypted XML file. The script provides the user with a file dialog to select the credential file and then displays the stored credentials (except the password, which is kept secure).

### 4. 02_Sample_Features.ps1
Demonstrates a variety of features available through the GroupShare API, such as listing containers, organizations, users, translation memories (TMs), and creating new users, TMs, and projects. This script serves as a practical demonstration of how to use the `GroupShareToolkit` functions. I based this on the `Sample_Roundtrip.ps1` provided by the Trados AppStore Team and just refined it a little as I was playing... so decided to include this here too in case it was useful.

### 5. 03_Orgs_Containers_TMs.ps1
Generates a list of all organizations, their associated containers, and the translation memories (TMs) within those containers. The output is saved to a text file, providing a comprehensive overview of the structure within GroupShare.

### 6. 04_properties_of_container_and_TM_from_Org.ps1
Retrieves and displays detailed properties of a specified organization, including its containers and the TMs within those containers. This script is useful for understanding the detailed configuration and content of an organization.

### 7. 05_users_by_organization.ps1
Lists all users within a specified organization, including their roles and other key details. This script provides a comprehensive overview of user management within GroupShare.

### 8. 06_user_properties.ps1
Fetches and displays detailed properties of a specific user, including their roles within various organizations. This script might be handy for user auditing and role management.

### 9. 07_Projects_by_Organization.ps1
Lists all projects within a specified organization, grouped by the month and year of their creation. This script might be useful for project management and historical analysis of project creation.

### 10. 08_addUser_to_Org.ps1
Facilitates the creation of new users within an organization. The script prompts the user for necessary details, validates password complexity, and assigns roles, ensuring that new users are added according to best practices.

### 11. 09_project_phase_users.ps1
Retrieves and displays the phases of a specified project, grouped by language, along with the users assigned and the file names. This script may be useful for project management, allowing administrators to see who is responsible for different phases of a project.

### 12. 10_create_Project_by_Template.ps1
Enables the creation of a new project using a selected project template and a ZIP file containing the project files. This script simplifies project creation by leveraging existing templates.

### 13. 11_Activity_Report.ps1
Generates comprehensive activity reports for the last 6-months showing things like project creation and management patterns, background task execution, user activity across organizations, organizational hierarchy and relationships and resource utilisation trends.

## How to Run the Scripts

1. Clone this repository to your local machine.
2. Ensure that the `GroupShareToolkit` module is properly installed and configured in your environment.
3. Navigate to the `scripts` folder.
4. Run the desired script using PowerShell.

   ```sh
   .\10_create_Project_by_Template.ps1
   ```

Alternatively use the Autohotkey solution provided in the "[Run Powershell Scripts](https://github.com/paulfilkin/AHK-scripts/tree/main/Run%20Powershell%20Scripts)" folder.

Make sure your environment is correctly set up to find the necessary modules as described in each script. 

## Credits

These scripts were developed to extend the functionality of the GroupShare PowerShell Toolkit by the [Trados AppStore Team](#link-to-their-repository). Special thanks to the team for providing the foundational tools that made this extension possible.
