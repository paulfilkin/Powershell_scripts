; Set a custom tray icon
TraySetIcon("c:\Users\pfilkin\Documents\Scripts\AutoHotkey\Run Powershell Scripts\powershell_toolkit_icon.ico", 1, true)

; Define the hotkey (e.g., Ctrl+Shift+R)
^+r::
{
    ; Open a file selection dialog to choose the PowerShell script
    filePath := FileSelect("File3", "Select a PowerShell script to run", "", "*.ps1")

    ; If the user cancels the dialog, filePath will be empty, so we check for that
    if !filePath
        return  ; Exit the hotkey action

    ; Check if the script path starts with the specified directory
    if InStr(filePath, "c:\Users\pfilkin\Documents\StudioPowershellToolkit\") = 1
    {
        ; Run in 32-bit mode
        Run('C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -NoExit -File "' . filePath . '"')
    }
    else
    {
        ; Run in 64-bit mode
        Run('c:\Program Files\PowerShell\7\pwsh.exe -ExecutionPolicy Bypass -NoExit -File "' . filePath . '"')
    }

    return
}
