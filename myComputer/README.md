# System Information Script

This PowerShell script provides a comprehensive overview of your system hardware, software, and operating system information. It includes details on processors, RAM, disk space, network adapters, installed third-party software, and more. This script is useful for quickly gathering system information for diagnostics, reporting, or inventory purposes.

## Features

- **Processor Information**: Displays the manufacturer and name of each processor installed.
- **Graphics Card Information**: Shows the manufacturer and name of each GPU.
- **RAM Information**: Lists the total, used, and free memory, along with the details of each memory slot (capacity and manufacturer).
- **Disk Information**: Reports the total, used, and free space on all fixed drives.
- **Motherboard Information**: Displays the manufacturer and product name of the motherboard.
- **BIOS Version**: Shows the BIOS manufacturer and version.
- **Network Adapter Information**: Lists each network adapter's manufacturer and description for all enabled adapters.
- **System Uptime**: Shows how long the system has been running.
- **Operating System Information**: Displays the operating system name, version, and architecture.
- **Virtualisation Support**: Checks whether the system supports hardware virtualisation.
- **Installed Third-Party Software**: Lists all installed software that didn’t come pre-installed with Windows, including the version and publisher.
- **Error Handling**: Gracefully handles missing components and outputs appropriate messages.

## Prerequisites

- PowerShell 5.1 or higher (included with Windows 10 and later by default).
- Administrator privileges may be required to gather complete system information.

## How to Use

1. Download or copy the script to your local system.
2. Open PowerShell as an Administrator.
3. Navigate to the folder where the script is located.
4. Run the script by entering the following command:

   ```powershell
   .\SystemInfo.ps1
   ```

This will output various system information to the console, formatted with coloured sections for better readability.

## Output Overview

The script will output system information grouped into the following categories:

- Processor Information
- Graphics Card(s)
- RAM Information
- Disk Information (per drive)
- Motherboard Information
- BIOS Version
- Network Adapter(s)
- System Uptime
- Operating System Information
- Virtualisation Support
- Installed Third-Party Software

Each section is visually separated and uses different foreground colours for easy distinction.

## Example Output

```
=== Processor Information ===
Intel: Intel(R) Core(TM) i7-9750H CPU @ 2.60GHz

=== Graphics Card(s) ===
NVIDIA: NVIDIA GeForce GTX 1650

=== RAM Information ===
Total: 16 GB, Used: 8.5 GB, Free: 7.5 GB
Samsung: 8 GB
Crucial: 8 GB

=== Disk C: Information ===
Drive C:: Total: 512 GB, Used: 200 GB, Free: 312 GB

=== Installed Third-Party Software ===
Google Chrome (Version: 93.0.4577.82, Publisher: Google LLC)
Microsoft Office 2019 (Version: 16.0.13029.20232, Publisher: Microsoft Corporation)
...
```

## Customisation

You can modify the script to add or remove specific components based on your requirements. For example:

- To only display certain hardware components, comment out the relevant sections of the script.
- To include additional system details, use the `Get-WmiObject` cmdlet to retrieve data from WMI or the system registry.

## Limitations

- **WMI Limitations**: Some systems may not expose certain details, such as GPU or network adapter information, due to hardware, drivers, or WMI settings.
- **Installed Software**: The list of third-party software relies on registry entries. If an application doesn’t populate these fields correctly, it may not appear in the list.
- **Performance**: Running the script on older or slower systems might take a little longer due to the number of WMI queries involved.
