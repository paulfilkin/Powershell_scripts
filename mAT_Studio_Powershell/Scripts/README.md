# README for PowerShell Script Launchers

## Overview

This folder contains two AutoHotkey scripts designed to simplify the execution of PowerShell scripts. Both scripts offer different functionality but share the same purpose of making it easier to run PowerShell scripts with elevated privileges and custom settings.

### Script 1: `powershell_runasadmin.ahk`

- **Purpose**: This script allows you to select and run any PowerShell script with administrator privileges.

- Key Features:
  - Custom tray icon for easy identification.
  - File selection dialog to choose the script.
  - Bypasses execution policy restrictions.
  - Keeps the PowerShell session open after execution.

### Script 2: `powershell_elevated.ahk`

- **Purpose**: This script checks if the selected PowerShell script has an associated scheduled task. If so, it runs the task; otherwise, it runs the script directly with administrator privileges.

- Key Features:
  - Custom tray icon for easy identification.
  - Opens file selection dialog in a predefined folder.
  - Checks for existing scheduled tasks.
  - Runs scheduled tasks or directly executes the script with UAC if no task is found.

## Requirements

- **AutoHotkey v2.x**: Both scripts are written for AutoHotkey version 2.x and may not work with earlier versions.
- **PowerShell**: Both scripts are configured to use the 32-bit version of PowerShell (`SysWOW64`).
- **Windows Task Scheduler**: The second script uses Windows Task Scheduler to check and run tasks.

## Installation

1. **AutoHotkey Installation**: Ensure that AutoHotkey v2.x is installed on your system. You can download it from the [official AutoHotkey website](https://www.autohotkey.com/).
2. **Script Location**: Save both `.ahk` files (`powershell_runasadmin.ahk` and `powershell_elevated.ahk`) in a folder of your choice.
3. **Tray Icon**: Ensure the custom icon file (`powershell_toolkit_icon.ico`) is located at `c:\Users\pfilkin\Documents\StudioPowershellToolkit\Scripts\Images\` or update the scripts to point to the correct path for your environment.
4. **Default Folder for Scheduled Script**: Modify the `defaultFolder` variable in `powershell_elevated.ahk` to point to the folder where your PowerShell scripts are stored if it differs from the default.

## Usage

### Running `powershell_runasadmin.ahk`

1. **Run the Script**: Double-click the `powershell_runasadmin.ahk` file to start the script. A custom icon should appear in your system tray.
2. **Using the Hotkey**: Press `Ctrl + Shift + R` to trigger the script. A file selection dialog will appear.
3. **Select a PowerShell Script**: In the file selection dialog, navigate to and select the PowerShell script (`.ps1`) you wish to run.
4. **Script Execution**: The selected script will be executed with administrator privileges, bypassing any execution policy restrictions.

### Running `powershell_elevated.ahk`

1. **Run the Script**: Double-click the `powershell_elevated.ahk` file to start the script. A custom icon should appear in your system tray.
2. **Using the Hotkey**: Press `Ctrl + Shift + R` to trigger the script. A file selection dialog will appear, starting in the default folder specified.
3. **Select a PowerShell Script**: In the file selection dialog, navigate to and select the PowerShell script (`.ps1`) you wish to run.
4. **Script or Task Execution**:
   - If the selected script is associated with a scheduled task, the script will run the scheduled task.
   - If no associated task is found, the script will run directly with administrator privileges, bypassing execution policy restrictions.

## Customisation

- **Hotkey**: The default hotkey for both scripts is `Ctrl + Shift + R`. You can change this by modifying the `^+r::` part of the script. Refer to the AutoHotkey documentation for different key combinations.
- **Tray Icon**: You can customise the tray icon by replacing the path to the icon file in the `TraySetIcon` command in both scripts.
- **Default Folder**: In `powershell_elevated.ahk`, modify the `defaultFolder` variable to point to the folder where your PowerShell scripts are stored.
- **Scheduled Task Name**: The `powershell_elevated.ahk` script uses the name of the PowerShell script (without the `.ps1` extension) as the task name. Ensure that your scheduled task names match this format.

## Troubleshooting

- **No PowerShell Window Appears**: If the PowerShell window does not appear, ensure that the script is running with the correct permissions, and that the file path is correctly specified.
- **Error on Execution**: If there is an error when running the PowerShell script or task, check that the task exists, the script is valid, and the execution policy is correctly bypassed.
- **Script Not Responding**: If either script is not responding to the hotkey, make sure AutoHotkey is running and that the script is active.
