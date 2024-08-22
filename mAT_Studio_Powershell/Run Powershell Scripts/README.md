# PowerShell Script Runner

This AutoHotkey script allows you to quickly select and execute PowerShell scripts by using a predefined hotkey. Depending on the location of the script you select, it will be run either in 32-bit or 64-bit mode.

## Features

- **Custom Tray Icon:** The script sets a custom tray icon for easy identification. The icon is specified in the script and is located in the path you decide to use.
  
- **Hotkey to Run PowerShell Scripts:** The script is triggered by the hotkey `Ctrl + Shift + R`. When this hotkey is pressed, a file selection dialog appears, allowing you to choose the PowerShell script you wish to run.

- **Script Execution Modes:**
  - **32-bit Mode:** If the selected script is located in the `c:\Users\[USERNAME]\Documents\StudioPowershellToolkit\` directory, it will be executed using 32-bit PowerShell.
  - **64-bit Mode:** If the selected script is located outside of the specified directory, it will be executed using 64-bit PowerShell.

## How It Works

1. **Tray Icon:** The script begins by setting a custom tray icon for easy access in the system tray.

2. **Hotkey Activation:**
   - Press `Ctrl + Shift + R` to activate the script.
   - A file selection dialog will appear. You can navigate to the `.ps1` PowerShell script file you want to run.

3. **File Path Validation:**
   - The script checks whether the selected file path starts with the directory `c:\Users\[USERNAME]\Documents\StudioPowershellToolkit\`.
   - If it does, the script runs in 32-bit mode using the PowerShell executable located in `C:\Windows\SysWOW64\WindowsPowerShell\v1.0\`.
   - If it does not, the script runs in 64-bit mode using the PowerShell 7 executable located in `c:\Program Files\PowerShell\7\`.

4. **Execution:**
   - The selected PowerShell script is executed with `-ExecutionPolicy Bypass` and `-NoExit` flags to ensure it runs with the necessary permissions and the window stays open after execution.

## Prerequisites

- **AutoHotkey v2.x:** Ensure that AutoHotkey version 2.x is installed on your system to run this script.
- **PowerShell 7 (64-bit):** The script requires PowerShell 7 to be installed in the default location (`c:\Program Files\PowerShell\7\`) for 64-bit execution.
- **Custom Tray Icon:** Make sure the custom tray icon (`powershell_toolkit_icon.ico`) exists in the specified location.

## How to Use

1. Copy the script into an `.ahk` file.
2. Run the script by double-clicking the `.ahk` file or configuring it to start with Windows.
3. Press `Ctrl + Shift + R` to open the file selection dialog.
4. Select the PowerShell script you want to execute.
5. The script will be run in the appropriate mode based on its location.

## Customisation

- **Hotkey:** You can change the hotkey by modifying the line `^+r::` in the script. Refer to AutoHotkey documentation for other hotkey combinations.
- **Tray Icon:** If you wish to use a different icon, replace the path in `TraySetIcon("...")` with your desired icon file.

